## Tech Debt Triage: Nightly reconciliation loads every open order into memory

**Location:** `recon/nightly.py` (`run_nightly`)
**Nature:** Algorithmic / scaling. Memory use grows linearly with the open-order count, against a fixed 16 GB ceiling.
**Cost of Deferral:** `+0.6 GB peak RSS per month`. This is consistent across June to September, and order growth is steady and expected to continue.
**Failure Cost:** `High × Med`. On the current trend an OOM kill is close to certain within about a month. The result would be unreconciled invoices, blocked carrier payments in AP, and contractual late-payment penalties from two carriers. That means real money and damage to carrier relationships, but no data loss, and it is recoverable once the job runs.

### Carrying Cost: Low
Day to day, this debt costs almost nothing. The code is short and readable, it changes rarely (6 commits in two years), and it has caused no incidents. It runs in about 40 minutes. A carrying-cost view alone would say "carry intentionally." The risk is the deadline, not friction.

### The projection

The September data shows 1.8 GB of headroom. Extending the steady trend:

| Month | Peak RSS (projected) | Headroom |
|---|---|---|
| Oct 2026 | ~14.8 GB | 1.2 GB |
| **Nov 2026 (now)** | **~15.4 GB** | **~0.6 GB** |
| **Dec 2026** | **~16.0 GB** | **~0 GB, OOM kill** |
| Jan 2027 | ~16.6 GB | over limit |

Three caveats push the risk earlier, not later:
- The table records **monthly peak** values. A single unusually large night, such as month-end, a large carrier batch, or a holiday-season volume spike, can cross the line before the average trend does.
- Freight volume often rises in December. If it does here, the trend line understates the risk.
- The write-up has no data for October or November. **Pull those numbers today.** If they are on trend, the job is running with roughly 4% headroom right now.

### Fix Cost
- **Scope:** Localized. The change is to the matching logic in `recon/nightly.py`, plus possibly a query or index for the SQL-join option.
- **Effort:** About 3 engineer-days, as estimated.
- **Risk:** Low to medium. Matching semantics could shift slightly in a set-based rewrite: duplicate `order_ref`s, null refs, or how `_amounts_match` translates to SQL. The existing integration tests against a seeded database should catch regressions. Add a test that compares the unmatched set from the old and new implementations on the same fixture.
- **Incremental?** Yes. Batching keyed by `order_ref` can be swapped in behind the same `write_exceptions` output, and the SQL-join version can come later if wanted.

### Urgency Triggers
- **16 GB memory limit:** projected to be hit around **December 2026**, possibly sooner on a peak night. This is imminent.
- **Seasonal volume:** a likely December freight spike would arrive at the same time.
- **Q4 roadmap pressure:** the billing portal work fills Q4, so the team is busiest exactly when the job is projected to fail. An OOM incident in that period would interrupt feature work anyway, unplanned, and while late-payment penalties accumulate.

### Recommendation

**Recommendation:** Fix now

Carrying cost is low, but there is a hard, predictable deadline about a month away. The failure has a direct financial cost (carrier late-payment penalties and blocked AP), and the fix is cheap, localized, and well tested. Three engineer-days taken from the billing portal now cost less than an unplanned incident during the December close.

**Suggested next steps:**
1. **Today:** check the October and November peak RSS figures, and add an alert at about 14.5–15 GB so a bad night doesn't arrive without warning.
2. **Stopgap, if available:** if the worker's 16 GB limit can be raised temporarily, do it. Each extra 2 GB buys roughly three months. Treat it as a bridge, not a fix, because it only delays the same failure.
3. **This sprint:** implement the batched or streaming match. The change probably spans more than about 50 LOC plus test changes, so handle it as a short research-plan-implement effort with this triage as input. Keep the plan proportionate to a 3-day fix.
4. **Fix shape:** prefer the SQL join or a batched lookup over only the `order_ref`s present in tonight's invoices. That makes memory scale with invoice volume rather than with the full open-order backlog, which is the quantity that keeps growing.
