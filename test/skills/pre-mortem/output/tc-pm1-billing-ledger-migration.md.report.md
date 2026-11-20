# Pre-Mortem: Billing ledger migration, Postgres 11 → Keel

**Proposal:** Move the billing ledger from Postgres to Keel (Billing Platform team, cutover Saturday 14 March, 02:00 UTC)
**Date:** 2026-11-19
**Upstream what-if analysis:** none

> ℹ️ **No upstream what-if analysis provided.** These narratives come directly from the proposal. For sharper narratives, run `what-if-analysis` first and provide its output. This skill works best when seeded with assumptions and coupling points that are already mapped.

> **Prior art check:** Skipped at the user's request, since no repository is available. No `[PRIOR CONSIDERATION]` tags are applied.

> **Date check before booking the window:** 14 March was a Saturday in 2026, and that date has passed. 14 March 2027 is a Sunday. Confirm the intended year and weekday before Customer Support books the maintenance window.

---

## Failure Narratives

### 1. The One-Way Door

**Root cause:** The Rollback section treats rollback as a config flip: point `LEDGER_DSN` at Postgres, make it writable, restart. Once maintenance mode lifts on 14 March, though, nothing carries writes from Keel back to Postgres. Every write made during the soak exists only in Keel. The two staging rehearsals checked that the flip worked, not what data it returned to.

**Chain of consequences:**
1. Monday 23 March, soak day 9, 14:40 UTC, weekday peak. A Keel-side issue pushes ledger p99 from about 40 ms to 1.8 s, and the billing API error rate reaches 3%.
2. The on-call engineer is on the normal rotation and is not one of the four who rehearsed. They open the wiki runbook. Its trigger is "if Keel misbehaves," so they execute it. It works exactly as rehearsed and takes 11 minutes.
3. Postgres comes back writable with the ledger as it stood at 02:00 on 14 March. About nine days of invoices, payments, credit notes and adjustments are not in the live database.
4. The Postgres invoice-ID sequence resumes from its 14 March value. New invoices are issued under numbers already used for invoices emailed to customers during the soak.
5. Customers who paid between 14 and 23 March now show open balances. Credit notes issued during the soak have disappeared.
6. Keel recovers 40 minutes later. Rolling forward again would discard the post-rollback Postgres writes. The team now has two divergent ledgers and no tool to merge them.

**Observable outcome:** Support receives "I already paid" and "why do I have two invoices numbered INV-0419xxx" tickets within hours. Finance halts the 1 April invoice run. About four engineer-days plus finance staff go into hand-reconciling two ledgers. Duplicate invoice numbers must be voided and reissued, which is an audit finding in jurisdictions that require sequential numbering.

**Plausibility:** Plausible. The chance of something triggering rollback during a two-week soak on a newly adopted service is perhaps 20–30%. If rollback runs after the first post-cutover write, divergence is certain.
**Severity:** High

**Mitigation:** Rewrite the **Rollback** section to pick one of two designs, and state the choice explicitly:
- **(a) Reverse replication:** run change-capture from Keel to Postgres for the whole soak, show its lag on the soak dashboard, and allow rollback only when lag is under 60 s.
- **(b) Forward-fix only:** declare rollback valid only inside the step 4 maintenance window, before maintenance mode lifts. After that, the runbook says forward-fix only and names who can declare an exception.

Under either design, the wiki runbook's first step becomes a data-state check, not the DSN flip.

---

### 2. Thirty Days Hath April

**Root cause:** `ledger_schema.sql` maps Postgres `interval` to a fixed-duration Keel type, either seconds or days. Postgres stores `'1 mon'` as a calendar month. Keel stores 2,592,000 seconds, which is 30 days. The finance systems lead reviewed the mapping as a type table, not as billing-period arithmetic. Step 3 verification compares only per-customer checksums of *existing invoice totals*. Those totals were computed by Postgres and copied over, so they match perfectly.

**Chain of consequences:**
1. Verification passes for five nights. Cutover succeeds. Soak dashboards (p99, error rate, run duration) stay green.
2. The soak window (14–28 March) contains no monthly invoice run. The last run was on 1 March, on Postgres.
3. Step 6 starts "after 28 March." Postgres is snapshotted to cold storage and shut down on 30 March.
4. On 1 April the invoice run executes on Keel for the first time. For each subscription, period end = period start + `billing_period` = 1 March + 30 days = 31 March.
5. The proration logic sees a one-day gap between the 31 March period end and the 1 April run date. It adds a one-day prorated line to roughly 18,000 monthly subscriptions and starts the next period on 31 March. Every later period drifts further.
6. The run finishes in 37 minutes, inside the two-hour window, so every dashboard says it succeeded.

**Observable outcome:** On 2–3 April, about 1,400 tickets arrive about an unexplained "1 day" line item. Finance's April MRR reconciliation is off by roughly 3.3% of monthly billings. Postgres is already in cold storage, so the team cannot run the same invoice run against the old system to diff the output. They must restore the snapshot to compare, which takes about a day.

**Plausibility:** Plausible. It depends on how Keel represents intervals. The structural gap is certain either way: no step in the plan ever exercises interval or money arithmetic on Keel before Postgres is gone.
**Severity:** High

**Mitigation:** Make two plan changes.
- **Step 3:** add a dry run of the full monthly invoice run on both databases, with results written to a scratch schema and diffed line by line (amount, period start/end, proration lines) across all 12 tables. Extend the checksum to payments, credit notes and adjustments, not only invoice totals.
- **Step 6:** change "after 28 March" to "after the 1 April invoice run has been reconciled by finance."

---

### 3. The Worker That Didn't Hear the Whistle

**Root cause:** Step 4 puts only the *billing API* into maintenance mode. The invoicing workers keep running. They pick up the new `LEDGER_DSN` only when restarted. Meanwhile the change-capture tool is stopped, so worker writes in that gap never reach Keel.

**Chain of consequences:**
1. At 02:00 the API enters maintenance mode and the change stream drains. At 02:06 the team stops change-capture.
2. At 02:05 the invoicing workers' scheduled late-fee and retry jobs run against Postgres. They write about 1,100 adjustment rows and about 300 payment-retry status updates.
3. At 02:09 the team flips `LEDGER_DSN`, restarts the API, and sets Postgres to read-only. The workers restart at 02:14 and switch to Keel.
4. The rows written between 02:06 and 02:14 exist only in read-only Postgres. Step 3's nightly comparison stopped at cutover, so nothing compares the two databases afterwards.
5. On Keel, the 1,100 late fees were never charged, and about 300 payment retries are marked as still pending. The workers retry those payments, double-charging a subset of customers.

**Observable outcome:** Error rate and latency are clean all weekend. About 40 customers report double charges in the following week. Finance finds the late-fee shortfall at month-end. Diagnosis needs a forensic diff against read-only Postgres. If step 6 has already decommissioned it, the team must restore the cold-storage snapshot first.

**Plausibility:** Plausible. Workers with scheduled jobs running at 02:00 UTC on a weekend are common.
**Severity:** Medium to High. Mostly recoverable, but the double charges reach real customers.

**Mitigation:** Reorder **step 4** as follows:
1. Scale the invoicing workers to zero.
2. Put the API into maintenance mode.
3. Set Postgres read-only.
4. Record Postgres's final WAL LSN.
5. Confirm change-capture has applied through that LSN, then stop it.
6. Rerun step 3's row-count and checksum comparison across all 12 tables as a go/no-go gate.
7. Flip `LEDGER_DSN` and restart the workers.

---

### 4. INV-0419882, Twice

**Root cause:** The bulk loader in step 2 copies rows with explicit primary keys. Change-capture streams rows, not sequence or identity state. Keel's sequences for `invoices.id`, the invoice-number sequence, and payment IDs stay at whatever value the bulk load left them, about two weeks behind Postgres.

**Chain of consequences:**
1. At 02:19 maintenance lifts. The first new invoice insert on Keel draws an ID that Postgres issued on 4 March, and Keel rejects it with a duplicate-key error.
2. The billing API returns 500 on invoice and payment creation. At 600 writes per minute, the error-rate dashboard is red within two minutes.
3. The on-call engineer has three options: hand-patch 12 sequences at 02:30, roll back (which brings back Narrative 1), or extend the outage.
4. If Keel's sequences cache per node, a hand patch also leaves invoice numbers non-contiguous, with gaps of hundreds between nodes. That matters where sequential invoice numbering is a legal requirement.

**Observable outcome:** A 30–90 minute write outage beyond the booked 20-minute window. Payment-provider webhooks queue or fail during it. Separately, invoice numbering has gaps that finance must explain to auditors.

**Plausibility:** Plausible, unless the staging rehearsal used live-equivalent sequence state.
**Severity:** Medium. It is loud and fast to detect, which caps the damage.

**Mitigation:** Add a sub-step to **step 4**, after the drain and before the flip. For each sequence or identity column across the 12 tables, set Keel's next value to the Postgres value plus a fixed buffer, then assert next value > `max(id)`. Add this to the staging rehearsal script. Separately, ask the finance systems lead whether Keel's sequence caching meets invoice-numbering rules, and set its cache to 1 for the invoice-number sequence if not.

---

### 5. The Tool Nobody Listed

**Root cause:** Step 4 repoints three consumers: the billing API, the invoicing workers, and the nightly export job. A fourth consumer, the collections/dunning service owned by another team, connects with its own hard-coded Postgres DSN rather than `LEDGER_DSN`. Setting Postgres to read-only does not break it, because it only reads.

**Chain of consequences:**
1. From 14 March, dunning reads a ledger frozen at cutover. Its queries succeed and its error rate is zero.
2. Customers who pay after 14 March still look overdue to dunning. It sends overdue reminders to about 2,300 of them over two weeks and auto-suspends about 90 accounts that pass the 30-day threshold.
3. The step 5 soak dashboards watch Keel, so nothing on them moves.
4. On 30 March, step 6 shuts Postgres down and dunning fails loudly. That is the first time anyone on Billing Platform learns it exists.

**Observable outcome:** Rising complaints along the lines of "I paid and you suspended me." Escalations from account managers. A gap in dunning output after decommission that the owning team traces back to the migration.

**Plausibility:** Plausible. A ledger that has served the company since before Postgres 11 went out of support almost certainly has readers that never used the shared config.
**Severity:** Medium to High. The harm reaches customers and builds silently for two weeks.

**Mitigation:** In **step 2**, sample `pg_stat_activity` (`usename`, `application_name`, `client_addr`) every 5 minutes for 7 days covering a weekday peak. Every distinct client must be either on step 4's repoint list or signed off by a named owner. In **step 4**, revoke `CONNECT` for every role except a migration role, instead of only setting read-only. Any straggler then fails on day 1 instead of serving stale data for two weeks.

---

## Recommendations

**Must address before proceeding.** None of these require moving the date. They are plan edits.
- **Narrative 1 (One-Way Door).** Rewrite the Rollback section to choose reverse replication or a "forward-fix only after maintenance lifts" rule. As written, rollback is the plan's main safety net, and after the first soak write it causes a worse incident than it prevents.
- **Narrative 2 (Thirty Days Hath April).** Add an invoice-run dry-run diff to step 3, and gate step 6 on reconciliation of the 1 April run. The soak never exercises the heaviest, most arithmetic-heavy job, and Postgres may be gone before it first runs.
- **Narrative 3 (The Worker).** Reorder step 4 so the workers stop before change-capture stops, with an LSN check and a final full-table verification gate. This is cheap and closes a silent data-loss path.

**Worth mitigating.**
- **Narrative 4 (Sequences).** Add the sequence-reset sub-step and include it in the rehearsal. It is cheap enough to do, but the failure is loud and bounded.
- **Narrative 5 (Unlisted consumer).** Run the 7-day connection audit and revoke `CONNECT` at cutover. Revisit trigger: if any connection other than the migration role appears in Postgres after 14 March 02:30 UTC, page Billing Platform.
- **On-call readiness.** Staff the soak with at least one of the four rehearsed engineers on secondary each night, so the wiki runbook is not executed cold.
- **Keel shared tenancy.** 31 March is quarter-end, and other teams on Keel may run heavy jobs that week. Confirm with the Keel platform owners that billing has reserved capacity for the 1 April run.

**Acknowledged risks.**
- **Latency.** 38 versus 31 minutes against a two-hour window is ample headroom, and the 4–6 ms per-query overhead is acceptable for this write rate.
- **Webhooks during the 20-minute window.** Acceptable if the payment providers retry on 503, which most do. Confirm their retry window is longer than the maintenance window plus Narrative 4's worst-case overrun.

**On the decision requested:** booking the window is reasonable once the three must-address edits are written into the proposal. Narrative 2's fix moves decommission past 1 April but does not move the cutover.
