## Tech Debt Triage: Nightly reconciliation loads every open order into memory

**Location:** `recon/nightly.py` (`run_nightly`)
**Nature:** Scalability. An algorithm that is unbounded in memory is running against a hard resource limit.
**Cost of Deferral:** `+0.6 GB peak RSS per month`. Headroom shrinks at the same rate.
**Failure Cost:** `High × High`. On the current trend the job crosses 16 GB within weeks. Once it does, it fails every night until fixed. Accounts payable can't release carrier payments, and two carrier contracts carry late-payment penalties.

### Carrying Cost: Medium
Day to day this code costs almost nothing. It is short, readable, rarely changed (6 commits in two years), and has caused no incidents. What it carries is a known expiry date. The monitoring shows a steady +0.6 GB per month (12.4 → 13.0 → 13.6 → 14.2 GB). Order growth is steady and sales expects it to continue, so the trend line is credible.

| Month | Peak RSS | Headroom vs 16 GB |
|---|---|---|
| Sep (actual) | 14.2 GB | 1.8 GB |
| Oct (projected) | ~14.8 GB | ~1.2 GB |
| Nov (projected) | ~15.4 GB | ~0.6 GB |
| Dec (projected) | ~16.0 GB | ~0 |

The write-up is dated 2026-10-05 and today is 2026-11-20. If the trend held, the job is already running within about 0.6 GB of the kill limit. These are monthly peaks, so any single night with an unusual spike could cross the line earlier. Examples are a month-end backlog, a carrier batching invoices late, or holiday-season freight.

### Fix Cost
- **Scope:** Localized. The change is `run_nightly` plus its integration tests.
- **Effort:** About 3 engineer-days, per the estimate. That is roughly 1–2% of the team's quarter (3 engineers × ~13 weeks).
- **Risk:** Low. A SQL join or batched lookup could subtly change match semantics, such as duplicate `order_ref`s or null refs. The existing integration tests against a seeded database should catch this, provided they include unmatched and mismatched-amount cases.
- **Incremental?** Yes. A partial step is available today: load only the columns `_amounts_match` needs (id, amounts, currency) instead of full ORM objects, and stop materializing the full list before building the dict. This likely cuts peak memory substantially in well under a day. The full fix (SQL join or batching) can follow.

### Urgency Triggers
- **The 16 GB kill limit.** Projected for about December 2026 and possibly sooner. This trigger is already imminent.
- **Deterministic failure mode.** Once memory crosses the limit, this is not a flaky one-off. Every subsequent nightly run is killed, so the backlog of unreconciled invoices grows daily until someone ships a fix under pressure.
- **Contractual penalties.** Delayed carrier payments trigger late-payment terms with two carriers.
- **Q4 roadmap pressure.** The billing portal work means an emergency fix in December would displace feature work at the worst moment, rather than a planned 3 days now.

### Recommendation

**Recommendation:** Fix now

An urgency trigger is imminent: the measured growth rate puts the job at the memory limit around December. The failure cost is severe and recurring, since it blocks accounts payable and incurs contractual penalties. The fix is cheap (about 3 days), localized, and covered by integration tests. A planned 3-day fix now is far cheaper than an incident-driven fix in the middle of the Q4 billing-portal push.

**Immediate actions, in order:**
1. **Pull current peak-RSS numbers for October and November today.** The write-up stops at September. If November is at or above about 15.4 GB, treat the fix as urgent this week.
2. **Optional stopgap:** if the worker's memory limit can be raised (for example to 24–32 GB), do it now. At +0.6 GB per month that buys months of runway. It is insurance, not a substitute for the fix, because the growth continues.
3. **Ship the column-projection quick win.** Load only the needed fields and skip the intermediate list. This buys headroom with minimal risk.
4. **Ship the full fix.** Prefer the SQL join, which pushes the match to the database and removes the memory dependency on order volume. Batching is the fallback if the match logic in `_amounts_match` is hard to express in SQL.

**Routing:** The fix touches `recon/nightly.py` and its tests, and it requires choosing between two approaches (SQL join vs batched streaming). It therefore exceeds the trivial-fix threshold. Hand it to the research-plan-implement workflow with this triage as input, but keep the research phase short. The main open questions are whether `_amounts_match` translates cleanly to SQL and whether the seeded test data covers the edge cases.
