> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output. This skill is most powerful when focused on the gaps that critics miss.

> **Prior Art Check:** No repository is available, so `docs/decisions/` and `docs/working/` could not be searched. No `[PRIOR CONSIDERATION]` findings are possible. All findings below come from the proposal text alone.

# What-If Analysis: CR-2291, move `settle-nightly` from 01:00 to 03:00 UTC

**Proposal:** CR-2291, change the `settle-nightly` cron from 01:00 UTC to 03:00 UTC to avoid the 00:30–02:30 backup window (Payments Core, Harrowgate Pay)
**Date:** 2026-11-20
**Upstream critiques:** none

---

## Headline

The CR's own Environment table contains a dependency that its "Why 03:00 is safe" section never mentions. **`warehouse-sync` runs at 02:15 and copies `merchant_settlement` and `payouts`.** After this change, settlement rows will not exist yet when it runs. The finance warehouse would be one settlement day behind every day, for as long as the change is in place. The proposal is labeled "Low (schedule change only)", but the schedule is the interface between three teams. That is the source of the risk.

---

## Assumptions Examined

**A1. Nothing downstream depends on settlement output being written before ~02:15.**
- **Source:** Implicit. The "Why 03:00 is safe" section checks only the bank cutoff (06:00) and the dashboard (07:00). It skips `warehouse-sync` (02:15), which is listed in the CR's own Environment table.
- **If wrong:** Redesign. Either `warehouse-sync` moves, or the two jobs need a completion-based dependency. That is a cross-team change, not a cron edit.
- **Tag:** `[NOVEL]`

**A2. The 85-minute margin is the margin that matters.**
- **Source:** Explicit ("finishes by 04:35, leaving 85 minutes of margin").
- **If wrong:** Redesign of the start time or the failure runbook. The 85 minutes is success-path margin. On the failure path (timeout, then manual rerun), the margin is near zero or negative. See Confidence Inversions.
- **Tag:** `[NOVEL]`

**A3. The 03:00–06:00 window is uncontended.**
- **Source:** Implicit. Supported by the staging test, which ran at 03:00 for five nights at 41–52 min.
- **If wrong:** Redesign. `fraud-model-refresh` starts at 04:00 and would overlap every run that takes more than 60 minutes. If it reads heavily from the payments cluster, the original contention problem moves to a new time.
- **Tag:** `[NOVEL]`

**A4. The backup reliably finishes by 02:30.**
- **Source:** Implicit (the "after the backup window closes" framing).
- **If wrong:** Tweak, if the overrun is occasional. Redesign, if full backups grow with data volume and overruns become routine. The cron has no knowledge of backup completion; this is an unenforced temporal coupling.
- **Tag:** `[NOVEL]`

**A5. The staging test represents production conditions.**
- **Source:** Explicit (five nights on a "staging copy of production").
- **If wrong:** Tweak to the evidence, not the design. The CR doesn't say whether staging also ran the backup, `warehouse-sync`, and `fraud-model-refresh`. If it didn't, the test shows the batch runs fast on an idle cluster. It doesn't show it runs fast at 03:00 in production.
- **Tag:** `[NOVEL]`

**A6. The scheduler interprets the cron expression in UTC.**
- **Source:** Implicit.
- **If wrong:** Tweak, but an ugly one. If the scheduler uses a local timezone (for example Europe/London), the job shifts by an hour across DST transitions. Every UTC margin calculation in the CR is then off by an hour for half the year.
- **Tag:** `[NOVEL]`

**A7. The settlement day boundary is defined by capture timestamp, not by run time.**
- **Source:** Explicit ("Card captures after midnight belong to the next settlement day").
- **If wrong:** Redesign. If the batch's query uses anything relative to `now()` or job start, a later start changes what is included. The byte-identical payout-file test over the same data is decent evidence this holds. Low concern.
- **Tag:** `[NOVEL]`

---

## Consequence Chains

**Outcome 1: settlement no longer contends with the backup.**
```
→ First-order: runtime returns to ~40–55 min; no more backup-induced timeouts
  → Second-order: settlement now completes ~03:40–03:55 instead of ~01:40–01:55 (pre-backup) / ~02:10–02:35 (today)
    → Third-order: warehouse-sync at 02:15 copies the PREVIOUS day's merchant_settlement/payouts every night;
                   the finance warehouse is permanently one day stale
      → Fourth-order: morning reconciliation (payout file vs. warehouse) mismatches daily → false alarms, or
                      finance quietly learns to ignore the mismatch, which masks real discrepancies
      → Fourth-order: month-end — the last settlement day of the month lands in the warehouse on the 2nd,
                      after (or during) close; Nov 30 → Dec 1 is ten days away
    → Third-order: if the merchant dashboard (07:00) reads from the warehouse rather than
                   merchant_settlement directly, merchants see yesterday's settlement — directly
                   contradicting the "as today" claim. The CR doesn't say which source the dashboard uses.
```

**Outcome 2: on-call no longer does manual reruns at night.**
```
→ First-order: fewer pages for timeouts
  → Second-order: when a failure does happen, it happens at ~04:00–04:35 instead of ~02:30, with the bank cutoff 1.5–2 hours away instead of 3.5+
    → Third-order: the rerun runbook, written for a world with hours of slack, is now executed under time pressure,
                   at the lowest-alertness hour of the night; a missed cutoff means merchants are paid a day late
```

**Outcome 3: settlement moves into the 03:00–06:00 window.**
```
→ First-order: settlement runs alone for its first hour
  → Second-order: any run longer than 60 min overlaps fraud-model-refresh at 04:00
    → Third-order: if fraud-model-refresh is read-heavy, the overlap lengthens both jobs; a stale fraud model at
                   start of business is a Risk-team problem that Payments Core caused
    → Third-order: runtime growth with merchant/volume growth pushes the overlap from occasional to routine,
                   recreating the original problem at a different time
```

**Side observation (already true today):** With current 70–95 min runtimes, settlement finishes 02:10–02:35. That straddles `warehouse-sync` at 02:15. The two timeout-and-rerun nights would certainly have finished after it. The warehouse may already have received partial or missing settlement data on some nights over the past month. This is worth checking independently of the CR. It is also evidence the coupling is real and nobody has noticed it.

---

## Coupling Analysis

| Coupling | Visibility | Notes |
|---|---|---|
| `warehouse-sync` (02:15) reads settlement output | **Invisible.** Purely temporal; no dependency edge, only clock times. Listed in the CR's table but not reasoned about. | The most important finding. Breaks silently: the sync "succeeds" with stale data. |
| Settlement start depends on backup completion | **Invisible.** Temporal; enforced only by a 30-minute gap in two cron schedules owned by different teams. | If the database team shifts or extends the backup, nobody tells Payments Core. |
| `fraud-model-refresh` (04:00) shares cluster capacity | **Invisible.** Shared resource. | The same class of coupling that caused this CR in the first place. |
| Merchant dashboard (07:00) data source | **Unknown.** | Visible if it reads `merchant_settlement` directly; inherits the warehouse staleness if it reads the warehouse. |
| On-call runbook timing assumptions | **Invisible.** Behavioral/process. | "Keep runbook unchanged" assumes the runbook's implied slack still exists. |
| Scheduler timezone semantics | **Visible** in config, but unexamined. | Determines whether the margin math holds year-round. |
| Sponsor bank cutoff (06:00) | Visible, explicit. | Correctly handled on the success path. |

---

## Confidence Inversions

**"85 minutes of margin."**
Inversion: a run fails late. The CR says the batch has timed out twice. Assume the timeout fires at roughly the old worst case. Under contention with `fraud-model-refresh`, failure is detected around 04:35. The page goes out, and the engineer wakes, logs in, and diagnoses: realistically 15–30 minutes. Start the rerun at ~05:00. Even an uncontended 40–55 minute rerun ends at 05:40–05:55, and that rerun is contended, because `fraud-model-refresh` is running. Any slip at all misses 06:00. **At 01:00, the same failure left about three hours of slack. The change trades frequent, low-stakes failures for rare, high-stakes ones.** That may still be the right trade, but the CR presents it as pure gain.

**"Risk class: Low (schedule change only)."**
Inversion: the schedule *is* the integration contract between Payments Core, Data Platform, Risk, Merchant Experience, and the database team. A code change would get a diff review. A schedule change rewires five teams' implicit agreements with no diff for anyone else to see.

**"The staging test shows 41–52 minutes."**
Inversion: staging at 03:00 had no backup tail, no `fraud-model-refresh`, and no production read traffic. The result then shows only that the batch is fast in isolation, which was already known from pre-backup history. It doesn't validate the 03:00 production slot.

---

## Adversarial Scenarios

**1. Peak-volume week. Realistic and imminent.**
Today is Friday 2026-11-20. "Change the cron on a Tuesday" most plausibly means 2026-11-24. Black Friday is 11-27 and Cyber Monday is 11-30. Assume card volume on those settlement days is 2–3× normal and runtime scales even sub-linearly. Uncontended runtime could reach 70–110 minutes, ending 04:10–04:50, with heavy `fraud-model-refresh` overlap. One timeout on any of those nights almost certainly misses the 06:00 cutoff, for the largest settlement days of the year. The first production runs of a new schedule would also be its hardest. Month-end (11-30 → 12-01) lands in the same week, which amplifies the warehouse-staleness impact on finance close.

**2. Backup overrun.**
Full backups grow with the data. The database team chose 00:30 because of replica rotation constraints, which suggests the window is already tight. A 30–45 minute overrun puts settlement right back under backup load, the exact condition this CR exists to escape. The bank cutoff now gives far less room to absorb the resulting slowdown. Likelihood: 10–20% of nights at some point in the next year seems plausible if backup volume trends upward. Today nothing would detect it, because the cron doesn't check.

**3. Silent stale warehouse.**
Assume nobody on Data Platform or Finance reads CR-2291. The sync keeps succeeding and the numbers look plausible: they're real, just a day old. The first person to notice is a finance analyst at month-end, or an auditor. By then, reports, exports, and possibly accruals have been built on day-lagged data. Likelihood: high, unless someone explicitly coordinates. Severity: moderate to high, depending on what finance does with the warehouse.

---

## Reversibility Map

| Timepoint | What reversal requires | Difficulty |
|---|---|---|
| **1 week** | Restore the cron expression. The backup contention problem returns. Warehouse rows written during the week were a day stale but are self-healing, since each sync copies the full tables. Any reports generated during the week may need re-running. | Easy |
| **1 month** | Same cron revert. But by now Data Platform has probably moved `warehouse-sync` later to fix the staleness, maybe also Merchant Experience or others. Reverting settlement alone is safe. Unwinding the downstream moves requires coordination. Finance may have adjusted reconciliation processes around the lag. | Moderate |
| **6 months** | The overnight schedule has re-settled around settlement-at-03:00. Other jobs may have been placed in the freed 01:00–02:30 slot, possibly by teams who never knew it was freed by this CR. Reverting means renegotiating the night with all of them, and the backup conflict still exists. | Moderate–Hard |

**Cliff edge:** The first downstream team that reschedules in response to this change, most likely `warehouse-sync`. From that point the revert is no longer a one-line config change owned by one team. The gradient is otherwise gentle. The cron change itself is trivially reversible. What isn't reversible is everyone else's adaptation to it.

Note also that reverting doesn't restore a good state. 01:00 is still broken by the backup. "Rollback = restore the old cron" is technically true, but it rolls back to a known-bad configuration.

---

## Cost of Success

Picture the world where everything works. Settlement runs at 03:00 in ~45 minutes. `warehouse-sync` has been moved to 04:30. Pages are rare. Compared with today:

- **Recovery cost.** Failure-path slack before the bank cutoff drops from several hours to under an hour. The system pages less often, but each page is more consequential.
- **Optionality cost.** The 03:00–06:00 window was the last uncrowded stretch before the bank cutoff. Settlement, `fraud-model-refresh`, and a relocated `warehouse-sync` now share it. Runtime growth from merchant and volume growth comes straight out of the remaining margin. There is no later slot left to move to.
- **Complexity cost.** The overnight chain still works through clock offsets rather than dependencies, now with tighter gaps: backup end 02:30 → settlement 03:00 → sync later. Each gap is a silent contract between teams.
- **Opportunity cost.** Taking the cheap cron fix defers the structural fix. Two options remain open: dependency-triggered scheduling (start settlement on backup completion, start sync on settlement completion), or pointing settlement's reads at a replica not involved in the backup.

---

## Findings Summary

1. `[HIDDEN COUPLING]` `[NOVEL]` `warehouse-sync` (02:15) copies settlement tables before the 03:00 batch has written them, so the finance warehouse will be one settlement day stale every day. The CR's own Environment table shows this. **Severity: high.**
2. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The 85-minute margin is success-path only. Timeout plus manual rerun from a 03:00 start leaves roughly 0–30 minutes before the 06:00 cutoff, versus about three hours today. **Severity: high** (low frequency, high impact: merchants paid late).
3. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The rollout week appears to coincide with Black Friday, Cyber Monday, and month-end. That means peak volume on the first production nights of the new schedule. **Severity: high, and fixable just by picking a different week.**
4. `[HIDDEN COUPLING]` `[NOVEL]` `fraud-model-refresh` (04:00) overlaps any settlement run longer than 60 minutes. That risks recreating the original contention and degrading Risk's job. **Severity: medium**, depending on that job's cluster load.
5. `[HIDDEN COUPLING]` `[NOVEL]` Settlement start depends on the backup finishing by 02:30. The only guard is a 30-minute gap between two unrelated crons owned by different teams. **Severity: medium.**
6. `[SECOND-ORDER EFFECT]` `[NOVEL]` If the merchant dashboard reads from the warehouse, merchants see stale settlement despite the "as today" claim. **Severity: unknown until the source is confirmed; high if true.**
7. `[SECOND-ORDER EFFECT]` `[NOVEL]` The warehouse may already be receiving partial or missing settlement data on nights when the current 70–95 minute runs straddle 02:15, including both rerun nights. This is a pre-existing issue surfaced by this analysis. **Severity: medium; check regardless of the CR.**
8. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The staging test probably didn't reproduce production's 03:00–05:00 cluster load, so it doesn't validate the new slot. **Severity: low–medium** (an evidence gap, not a defect).
9. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The scheduler's timezone semantics are unverified. If they aren't UTC, the margins shift by an hour across DST. **Severity: low; easy to check.**
10. `[REVERSIBILITY CLIFF]` `[NOVEL]` The revert stops being single-team once a downstream job reschedules around the new time. Reverting also returns to a known-bad state. **Severity: low–medium.**
11. `[SUCCESS COST]` `[NOVEL]` The change consumes the last uncrowded pre-cutoff window, tightens failure-path slack, and defers a structural, dependency-based scheduling fix. **Severity: medium over time.**
12. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The settlement day boundary is based on capture timestamp, not run time. The byte-identical payout test supports this. **Severity: low.**

---

## Recommendations

**Must address before proceeding**
- **Coordinate with Data Platform on `warehouse-sync` (finding 1).** Either move it to after settlement's worst-case finish, or better, trigger it on settlement completion. Ship both changes together. The CR should not be "Low risk / no other teams" while it silently breaks a consumer listed in its own table.
- **Do not roll out the week of 2026-11-23 (finding 3).** Wait until after the 11-30/12-01 month-end settlement. Peak-volume nights shouldn't be the new schedule's first production runs.
- **Write down the failure-path timeline and adjust accordingly (finding 2).** State the batch's timeout value, the expected page-to-rerun time, and the latest safe rerun start. If the result is under ~60 minutes of slack, pick one or more mitigations:
  - an earlier start such as 02:40, if backup completion is reliable;
  - a pre-cutoff escalation rule, for example "if not complete by 05:00, escalate to secondary";
  - an automatic single retry instead of a manual one.
- **Confirm the merchant dashboard's data source (finding 6).** If it reads the warehouse, the "as today" claim is false until finding 1 is fixed.

**Worth mitigating**
- **Check `fraud-model-refresh`'s cluster load (finding 4)** with the Risk team. Watch signal: settlement runtime above 60 minutes, and refresh-job duration on overlap nights.
- **Gate settlement on backup completion rather than wall-clock time (finding 5).** Even a simple "wait for backup-done marker, max until 03:30" check would do. Watch signal: backup end time trending past 02:30.
- **Audit warehouse settlement data for the past month (finding 7),** especially the two rerun nights, regardless of whether this CR ships.
- **Verify the scheduler timezone (finding 9).** A five-minute check.
- **Track the structural fix (finding 11).** Move the overnight chain from clock offsets to completion-based dependencies. Without it, the next team to move a job will cause the same class of incident.

**Acknowledged risks**
- **Day-boundary semantics (finding 12).** The byte-identical payout-file test over identical data is adequate evidence. Carry it.
- **Reversibility (finding 10).** The cron itself is trivially reversible. Downstream adaptations are coordination costs, not data-loss risks. This is acceptable as long as the changes to dependent jobs are recorded alongside CR-2291.
- **Staging representativeness (finding 8).** Acceptable if the first production runs are watched against the runtime and overlap signals above. Re-classify the CR from "Low" to at least "Medium (cross-team schedule dependency)" so those reviews actually happen.
