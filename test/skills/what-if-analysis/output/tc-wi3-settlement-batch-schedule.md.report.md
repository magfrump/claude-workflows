# What-If Analysis: CR-2291, move `settle-nightly` from 01:00 to 03:00 UTC

**Proposal:** CR-2291, change the `settle-nightly` cron expression from 01:00 to 03:00 UTC to avoid the payments-cluster backup window (00:30-02:30)
**Date:** 2026-11-20
**Upstream critiques:** none

> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output. This skill is most powerful when focused on the gaps that critics miss.

**Prior Art Check:** No repository was available, so `docs/decisions/` and `docs/working/` could not be searched. No findings are tagged `[PRIOR CONSIDERATION]`.

---

## Assumptions Examined

- **Assumption:** No downstream job depends on `settle-nightly` finishing before a fixed clock time, other than the 06:00 bank cutoff and the 07:00 dashboard.
  - **Source:** implicit. The "Why 03:00 is safe" section checks only the bank cutoff and the dashboard. The CR's own Environment table lists `warehouse-sync` at 02:15, which copies `merchant_settlement` and `payouts`.
  - **If wrong:** redesign. `warehouse-sync` would run 45 minutes *before* settlement starts every night. It has to be rescheduled or chained to settlement completion.
  - **Tag:** `[NOVEL]`

- **Assumption:** 85 minutes of margin before the 06:00 cutoff is enough, including on nights when the batch fails.
  - **Source:** explicit ("leaving 85 minutes of margin"). It is computed only for a single successful run.
  - **If wrong:** redesign. The batch has already timed out twice and needed a manual rerun. The failure path is timeout, then page, then human response, then a 40-55+ minute rerun. That path no longer fits comfortably before 06:00 (see Adversarial Scenarios).
  - **Tag:** `[NOVEL]`

- **Assumption:** Which payments fall into a settlement day does not depend on the time the batch runs.
  - **Source:** explicit ("Card captures after midnight belong to the next settlement day"). It is backed by a byte-identical staging comparison.
  - **If wrong:** redesign. If the selection query is bounded by `now()`, by a "not yet settled" status, or by commit time rather than an explicit date boundary, then three hours of post-midnight activity (instead of one) changes the result. Late-committed captures and refunds or reversals arriving after midnight would be affected.
  - **Tag:** `[NOVEL]`

- **Assumption:** At 03:00 the cluster is quiet, so production runtime will match the staging runtime of 41-52 minutes.
  - **Source:** explicit (the Testing section). Staging does not reproduce the 04:00 `fraud-model-refresh` or live capture traffic.
  - **If wrong:** tweak. The runtime drifts upward but still fits before 06:00 on a single run. It becomes a redesign only when combined with the rerun-margin assumption.
  - **Tag:** `[NOVEL]`

- **Assumption:** The backup reliably finishes by 02:30.
  - **Source:** implicit (taken from the Environment table).
  - **If wrong:** tweak. If backup duration grows with the data, settlement collides with it again and the problem returns. The fix is either a later start or a dependency on backup completion.
  - **Tag:** `[NOVEL]`

- **Assumption:** The scheduler interprets the cron expression in UTC.
  - **Source:** implicit.
  - **If wrong:** tweak. If the scheduler runs in a local timezone, the run moves at DST transitions. This is easy to verify.
  - **Tag:** `[NOVEL]`

## Consequence Chains

```
→ First-order: settle-nightly no longer overlaps the backup; runtime returns to ~40-55 min
  → Second-order: warehouse-sync (02:15) now runs before settlement has written anything for the day
    → Third-order: if the sync copies full tables, the finance warehouse is permanently one
      settlement day stale; finance reconciliation and reporting silently lag a day
    → Third-order: if the sync copies "rows for settlement_date = yesterday", each night it copies
      an empty set, and the next night it targets a different date, so every day is skipped.
      The warehouse accumulates a growing gap that nobody alarms on, because the job "succeeds"
  → Second-order: settlement now finishes ~03:40-03:55, close to fraud-model-refresh at 04:00
    → Third-order: on slow nights or reruns the two jobs overlap on the cluster, recreating
      the read-contention problem the CR is meant to fix, just with a different neighbor

→ First-order: fewer timeouts and manual reruns
  → Second-order: the timeouts that still happen (lock contention, bad input data, bank-file
    generation errors) now occur at 04:00-05:00 instead of 02:00-03:00
    → Third-order: the recovery window before the 06:00 cutoff shrinks from ~5 hours to
      ~1-2 hours. A missed cutoff means merchants are paid a day late, which is a
      merchant-facing and possibly contractual incident

→ First-order: the payout file is identical to what a 01:00 run would produce (per staging)
  → Second-order: confidence that day-boundary logic is time-independent is now based on a
    static data copy, with no live post-midnight writes
    → Third-order: if the boundary is not strictly date-based, production settlements
      include extra or different rows on the first night. This surfaces as merchant
      payout disputes or reconciliation breaks days later, not during "watch the first run"
```

## Coupling Analysis

| Coupling | Visibility | Effect of this CR |
|---|---|---|
| `warehouse-sync` (02:15, Data Platform) reads `merchant_settlement` and `payouts` | **Invisible.** It is an implicit temporal contract: "settlement is done by 02:15." It is listed in the CR's own table but not analyzed. | Broken every night. This is the most serious finding. Note that it is *already* fragile today: at 70-95 min, a 01:00 run finishes 02:10-02:35, so the sync has probably been racing settlement since last month's backup change. Check the warehouse for partial or missing days over the past month. |
| `fraud-model-refresh` (04:00, Risk) uses the payments cluster | Visible in the table. The contention is invisible. | New overlap on slow nights and reruns. |
| Backup completion (02:30, Database team) | **Invisible.** It is a timing assumption with no enforced dependency. | The CR replaces one wall-clock coupling with another. If the backup grows, the collision returns. |
| On-call manual-rerun runbook | Invisible. The runbook implicitly assumes hours of slack. | The runbook is "unchanged," but its time budget is not. It probably needs an explicit "if not complete by X, escalate or use partial-file procedure" step. |
| Merchant dashboard (07:00) | Visible | Fine if it reads `merchant_settlement` directly. If it reads from the finance warehouse, it inherits the `warehouse-sync` staleness. Confirm with Merchant Experience. |
| Settlement-day selection logic vs. run time | **Invisible.** It is a behavioral property of the query. | Must be verified in code, not inferred from a static-data test. |

## Confidence Inversions

- **"Risk class: Low (schedule change only)."** This is the most confident claim, and it is the one most likely to suppress review. Schedule changes in a batch chain are exactly where temporal couplings break. Inverted: a "no code change" CR silently breaks the finance warehouse feed owned by another team, and nobody from Data Platform was asked because the risk class said low.
- **"85 minutes of margin."** Inverted: suppose the 03:00 run hangs or times out. With the timeout set near the worst-case runtime, that happens around 04:35. Add a page plus 10-20 minutes for response, then a rerun of 50-60 minutes now contending with `fraud-model-refresh`. The file is ready around 05:40-05:55. One more hiccup, such as a slow rerun or file-upload trouble, and the cutoff is missed. Today the same failure is recovered with hours to spare. Two timeouts in a month means this is not a rare path.
- **"Byte-identical payout file."** Inverted: the test held the data constant, so it proves only that the code has no wall-clock *formatting* dependence. It cannot show that the *row set* is time-independent under live writes. Late-committed 23:5x captures, or refunds and chargebacks booked after midnight, could be picked up differently if the query uses `status`, commit time, or `now()`.

## Adversarial Scenarios

1. **Batch failure on a bad night (realistic, roughly 5-10% of nights given recent history).** The run times out, the on-call engineer is slow to wake at 04:40, and the rerun runs alongside the fraud refresh. The payout file misses 06:00, every merchant settles a day late, and support and possibly bank-penalty consequences follow. Today's 01:00 slot absorbs this; 03:00 does not.
2. **Backup overrun (realistic within months).** Payments-cluster data grows and the full backup creeps to 03:15 on month-end nights. Settlement is back under backup load on exactly the busiest nights, when runtime is longest. That is the scenario where the shrunken failure margin matters most.
3. **Downstream discovery lag.** `warehouse-sync` keeps "succeeding," and finance notices stale or missing settlement data only at month-end close, two to four weeks after the change. Backfilling then requires Data Platform work and finance restatement.

## Reversibility Map

- **1 week:** Restore the cron expression. Trivial.
- **1 month:** Still trivial for the change itself. Any warehouse gaps created in the meantime are harm already done (they need a backfill), not a property of reversing the schedule.
- **6 months:** Still trivial. If downstream teams have rescheduled their jobs to after 03:00 settlement, those later slots still work with a 01:00 settlement, so rollback needs nobody else's work.

**The gradient is flat. There are no reversibility cliffs.** The risk in this CR lies in its consequences while it runs, not in undoing it.

## Cost of Success

Suppose everything works: settlement runs at 03:00, finishes by 04:00, there are no timeouts, and `warehouse-sync` has been rescheduled. The world is worse than today in these ways:

- **Optionality cost:** The overnight window for settlement is now pinned between the backup end (02:30) and the bank cutoff (06:00), with the fraud refresh in the middle. Any future growth in runtime (more merchants, more captures) has much less room. Previously the batch could grow to roughly 4-5 hours; now growth beyond about 2 hours threatens the cutoff on failure nights.
- **Complexity and maintenance cost:** Three wall-clock couplings (backup end, `warehouse-sync`, fraud refresh) are maintained by four teams with no enforced dependencies. Each future schedule change by any of them must be cross-checked by hand.
- **Operational cost:** Failures now page on-call deeper in the night, with a hard deadline attached, which raises incident stress.

## Findings Summary

- `[HIDDEN COUPLING]` `[NOVEL]` `warehouse-sync` at 02:15 would run before settlement every night. The finance warehouse becomes stale by a day or silently skips days, depending on how the sync selects rows. It may already be racing settlement since the backup change.
- `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The 85-minute margin covers a successful run only. The failure-plus-rerun path, which has occurred twice recently, barely fits before 06:00.
- `[UNEXAMINED ASSUMPTION]` `[NOVEL]` Settlement-day selection was verified only on static data. Time-independence under live post-midnight writes is unproven.
- `[SECOND-ORDER EFFECT]` `[NOVEL]` Slow runs and reruns now overlap `fraud-model-refresh` at 04:00, recreating cluster contention.
- `[HIDDEN COUPLING]` `[NOVEL]` The new start time depends on the backup ending by 02:30, with nothing enforcing it. Backup growth brings the original problem back.
- `[HIDDEN COUPLING]` `[NOVEL]` The 07:00 dashboard may read from the warehouse. If so, it inherits the staleness. This is unverified.
- `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The scheduler's cron timezone is assumed to be UTC.
- `[SUCCESS COST]` `[NOVEL]` Headroom for future runtime growth shrinks sharply, and the overnight chain grows more wall-clock couplings across four teams.
- (Reversibility: flat. No cliffs.)

If concrete failure narratives would help, for example to brief Data Platform or the on-call rotation, run `pre-mortem` on this CR using this analysis as input.

## Recommendations

**Must address before proceeding:**
1. **Coordinate with Data Platform on `warehouse-sync`.** Move it after settlement, or better, trigger it on settlement completion. Do this before the cron change ships, not after. Also audit the warehouse for partial or missing settlement days since last month's backup change, because the race likely already exists.
2. **Recompute the margin for the failure path.** Write down the latest time a rerun can start and still make 06:00 (roughly 04:45-05:00). Make sure the job timeout and alerting fire early enough for that deadline. Add an explicit escalation step to the runbook (for example, "if no file by 05:15, contact the sponsor bank or use the fallback procedure"). If the math doesn't close, choose an earlier start such as 02:35, or start on backup completion rather than at a fixed time.
3. **Verify the day-boundary logic in code.** Confirm the selection query uses an explicit settlement-date bound and not `now()`, status, or commit time. Alternatively, run a staging test that replays live post-midnight writes. Then compare the first production run against a shadow computation before sending the file.

**Worth mitigating:**
- **Fraud-refresh overlap:** Track settlement end time versus 04:00 and alert if settlement is still running at 04:00. Tell Risk about the change.
- **Backup overrun:** Add an alert if the backup is still running at 03:00, or make settlement wait on a backup-complete signal.
- **Dashboard source:** Confirm with Merchant Experience whether the 07:00 refresh reads the cluster or the warehouse.
- **Timezone check:** Confirm the scheduler's cron timezone is UTC.

**Acknowledged risks:**
- **Later on-call pages.** Failures now page later in the night. This is acceptable if the escalation deadline above is defined.
- **Reduced headroom for runtime growth.** This is acceptable for now. Revisit when runtime trends past about 70 minutes.

**Reclassify the risk class.** The CR should not stay "Low." The change itself is trivial and fully reversible, but it touches a cross-team batch chain with a hard external deadline.
