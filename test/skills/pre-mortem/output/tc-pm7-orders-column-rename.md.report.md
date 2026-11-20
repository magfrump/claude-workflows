ℹ️ **No upstream what-if analysis provided.** These failure narratives come directly from the proposal. For sharper narratives, run `what-if-analysis` first and provide its output. This skill works best when seeded with assumptions and coupling points that have already been mapped.

ℹ️ **Prior Art Check skipped.** No repository is available, so `docs/decisions/` and `docs/working/` were not searched. No narrative carries a `[PRIOR CONSIDERATION]` tag.

ℹ️ **Invented specifics.** The proposal does not name the database engine, the existing indexes and constraints on `cust_ref`, or any change-data-capture setup. Where a narrative depends on one of these, the root cause says **Assumes:**. Each such assumption is a question to answer during review.

---

# Pre-Mortem: Rename `orders.cust_ref` → `orders.customer_id`

**Proposal:** Rename `orders.cust_ref` to `orders.customer_id` via expand-and-contract (Orders team, status: for review)
**Date:** 2026-11-19
**Upstream what-if analysis:** none

*It is May 2027. The migration has been declared a failure: one customer-facing incident, one finance incident, and a column that still exists twice. This is the review.*

---

## Failure Narratives

### 1. The Equality Check That Couldn't See NULL

- **Root cause:** The daily verification query from Plan §3 was written as `SELECT count(*) FROM orders WHERE cust_ref <> customer_id`. Under SQL three-valued logic, `x <> NULL` evaluates to NULL, not TRUE. Every row where `customer_id` was still NULL was silently excluded, so the query could only catch rows where both columns held different non-null values. That case almost never happens.
- **Chain of consequences:**
  1. On night two, the backfill was killed by a routine database failover. It was restarted from its last *logged* batch boundary, not its last *committed* one. About 15,000 rows in the id range committed between the log write and the crash were never backfilled.
  2. Separately, the support team's admin tool corrects the customer on mis-attributed orders by writing `UPDATE orders SET cust_ref = ...` directly. It does not go through the Orders service, so it never wrote `customer_id`. (The proposal's claim that writes go "to both columns" holds only for the Orders service.) About 40 such corrections landed during the soak. Each left `customer_id` holding the old, wrong customer.
  3. The equality query returned 0 every day for six weeks. The on-call took that as proof the columns matched.
  4. Invoicing switched reads in week 2 of Plan §4. Its monthly run produced 15,000 invoices with no customer attached. It failed them into a dead-letter queue, which nobody watched during the month-end close.
  5. The 40 support-corrected orders were invoiced to the *original*, wrong customers. Three of those customers were businesses that disputed the charges.
- **Observable outcome:** The equality alert stayed green throughout. On the 1st of the month, the invoicing dead-letter queue went from about 0 to 15,000 messages. Finance found a $410K gap between booked orders and issued invoices. Three B2B customers received invoices for orders that belonged to other customers. That is a data-privacy disclosure (order contents and amounts), not just a billing error.
- **Plausibility:** Plausible
- **Severity:** High
- **Mitigation:** Rewrite the Plan §3 verification query as `WHERE cust_ref IS DISTINCT FROM customer_id` (or `NOT (cust_ref <=> customer_id)` on MySQL). Add a separate `WHERE customer_id IS NULL` count to the same alert. Before Plan §2 ships, inventory every writer of `orders.cust_ref` by querying the database's statement log or audit log for `UPDATE`/`INSERT` touching the column. Add that inventory to the runbook. The minimum is a trigger that keeps the two columns in sync for writers outside the Orders service.

### 2. The Read Switch That Found No Index

- **Root cause:** Plan §1 adds `customer_id` as a bare nullable column, and nothing in the plan creates an index on it. **Assumes:** `cust_ref` has an index (and possibly a foreign key to `customers`), because the lookups "orders for customer X" and the reported joins depend on it.
- **Chain of consequences:**
  1. Steps 1–3 passed every check. The column existed and the values matched.
  2. Fulfilment, the first consumer, enabled `orders_read_customer_id`. Its "open orders for customer" query, which runs on every warehouse pick-list refresh, changed from an index seek to a sequential scan over 9M rows.
  3. Query time went from about 4 ms to about 2.8 s. At peak, connection-pool waits stacked up behind it.
  4. Database CPU went from 35% to 95%. The Orders service's own writes slowed down, and checkout latency degraded for every customer, not just those using fulfilment.
  5. The on-call found the cause in 25 minutes and turned the flag off. Creating the index without blocking writes then took a separate change window, which pushed the read-switch schedule back a week.
- **Observable outcome:** Fulfilment p99 latency jumped from 40 ms to 3 s within 2 minutes of the flag flip. Database CPU saturated, and order-insert p99 rose about 6x. About 300 checkout timeouts occurred during the 25-minute window.
- **Plausibility:** Likely
- **Severity:** Medium
- **Mitigation:** Add a step 1b to Plan §1: create an index on `customer_id` that mirrors every index containing `cust_ref` (single-column and composite), built online (`CREATE INDEX CONCURRENTLY` or the engine's equivalent). Also mirror any foreign key, added as `NOT VALID` and validated after the backfill. Gate Plan §4 on a checklist item: run `EXPLAIN` on each consumer's top 5 queries against `customer_id` and confirm the plans match the `cust_ref` plans.

### 3. Nine Million "Order Updated" Events

- **Root cause:** The Plan §3 backfill issued `UPDATE`s against 9M rows. **Assumes:** `orders.updated_at` is maintained by an `ON UPDATE` clause or a trigger, and/or the table is streamed by CDC. Under either, a pure copy between two columns looks downstream like 9M real order changes.
- **Chain of consequences:**
  1. The backfill stayed under its 20% CPU budget as designed. The throttle measured primary CPU only.
  2. Every batch moved `updated_at` to "now". The analytics export, which loads rows incrementally `WHERE updated_at > last_watermark`, picked up about 1.5M rows per night instead of its usual 40K.
  3. The export pipeline took 9 hours instead of 20 minutes and missed the 07:00 freshness deadline for the sales dashboards on four consecutive mornings.
  4. The warehouse model that derives "order last modified date" for churn analysis now showed every historical order as modified that week. The reprocessing produced a 3x spike in compute cost for the month.
  5. The read replica that serves the analytics export fell 40 minutes behind under the write volume. During that window, a customer-support lookup tool that reads the same replica showed stale order states.
- **Observable outcome:** The export job ran about 35x its normal row count, and the "dashboards stale" page fired every morning of backfill week. The replica-lag panel showed 40+ minutes. Warehouse credit consumption tripled for the billing month. Every historical order's `updated_at` was destroyed, which the analytics team could not recover.
- **Plausibility:** Plausible
- **Severity:** Medium
- **Mitigation:** Before Plan §3 runs, confirm how `updated_at` is maintained and whether `orders` is in a CDC stream. If it is, write the backfill so it preserves `updated_at` explicitly (`SET customer_id = cust_ref, updated_at = updated_at`, or temporarily disable the trigger for the backfill session). Have CDC consumers filter out events where only `customer_id` changed. Extend the §3 throttle to pause when replica lag exceeds 30 seconds, not only on primary CPU.

### 4. The Flags Were Independent; the Steps Were Not

- **Root cause:** `orders_write_customer_id` (step 2) and `orders_read_customer_id` (step 4) are separate flags with no dependency enforced between them. The Rollback section says "every step reverses by turning off its flag." That is true only if flags are turned off in reverse order. Turning off the write flag while the read flag is on silently breaks every reader.
- **Chain of consequences:**
  1. In soak week 2, an unrelated incident hit: elevated lock contention on `orders`. The secondary on-call, one of the two migration owners but on their first night shift, followed the runbook's "suspect recent migration changes → disable migration flags" heuristic.
  2. They disabled `orders_write_customer_id` first, because the dual write was the newest code path touching `orders` writes. They planned to come back to the read flag and never did, because contention cleared on its own (the real cause was a long-running analytics query).
  3. From 02:10 onward, new orders were written with `customer_id = NULL`. All four consumers were reading `customer_id`.
  4. Fulfilment could not match the 1,100 overnight orders to customer shipping profiles and held them in an "unassigned" state. Invoicing skipped them.
  5. The equality alert would not fire until the next daily run, and per narrative 1 it would not have caught NULLs anyway. Customers noticed first.
- **Observable outcome:** The fulfilment "unassigned orders" count went from about 0 to 1,100 overnight. The morning pick shift found no picks for those orders, and next-day delivery was missed for every order placed after 02:10. Support received about 600 "where's my order" tickets by noon.
- **Plausibility:** Plausible
- **Severity:** High
- **Mitigation:** Make the read flag depend on the write flag in code. The Orders service and each consumer evaluate `orders_read_customer_id` as `read_flag AND write_flag`, so turning off the write flag automatically reverts reads to `cust_ref`. Rewrite the Rollback section and runbook as an explicitly ordered procedure (reads off → wait for consumers to confirm → writes off). Add a §3/§5 alert that fires within 5 minutes on any order inserted in the last 5 minutes with `customer_id IS NULL`, instead of waiting for the daily query.

### 5. The Readers Nobody Listed

- **Root cause:** Plan §4 and the CI contract tests cover exactly "the three internal consumers". The proposal's own motivation, that "every new service gets its name wrong", says the set of things touching `orders.cust_ref` is larger than the set of services the Orders team knows about. Missing from the list: the finance team's month-end reconciliation SQL (a scheduled query in the BI tool), a database view `v_customer_order_history` used by the CRM sync, and a data-science notebook job.
- **Chain of consequences:**
  1. Step 6a ("stop writing `cust_ref`") shipped. **Assumes:** `cust_ref` was declared `NOT NULL`, which was caught in staging and fixed by adding a `DROP NOT NULL` step at the last minute.
  2. Once Orders stopped writing `cust_ref`, the reconciliation query (which still selected `cust_ref`) began receiving NULL customers for every new order. It ran without errors and reported a growing "unattributed revenue" line that finance assumed was a data delay.
  3. A week later, step 6b dropped the column. The CRM sync's view became invalid (or the drop needed `CASCADE`, which silently dropped the view). The nightly CRM sync failed, and the account managers' customer-order histories froze.
  4. Restoring from the snapshot was not the clean reversal the Rollback section promised. The fix that was actually needed was to re-add the column and backfill it from `customer_id`: another 6-hour throttled job, run under incident pressure. Meanwhile the reconciliation had already closed one month with wrong figures.
- **Observable outcome:** The reconciliation report's "unattributed revenue" line grew from $0 to about $2.1M over 7 days with no error raised. The day after the drop, the CRM sync job failed with `column "cust_ref" does not exist`, and CRM order history stopped updating. Finance had to reopen a closed month.
- **Plausibility:** Plausible
- **Severity:** High
- **Mitigation:** Add a discovery gate to Plan §6, before "stop writing": (a) query the database catalog for views, functions, and triggers that reference `cust_ref`. (b) Pull 30 days of query logs (e.g., `pg_stat_statements` or the engine's equivalent) and list every distinct client, application, or role whose queries mention `cust_ref`. (c) Require that list to be zero, or every entry signed off, before 6a. Also add a §6 interim step: revoke `SELECT` on `cust_ref` for all non-Orders roles for one week before the drop. That turns unknown readers into loud, reversible errors.

---

## Recommendations

### Must address before proceeding (steps 1–3 approval)

- **Narrative 1: NULL-blind equality check.** Rewrite the §3 verification with `IS DISTINCT FROM` plus an explicit `customer_id IS NULL` count. Inventory non-Orders writers of `cust_ref` before step 2. Both are cheap, both fall within the scope being approved now, and without them the safety net the plan relies on is not real.
- **Narrative 3: backfill side effects.** Answer two questions before §3 runs: does an update bump `updated_at`, and is `orders` in a CDC stream? If either answer is yes, change the backfill. Lost `updated_at` history cannot be recovered, so this must be settled before step 3, not during it.
- **Narrative 2: missing index.** Not a blocker for steps 1–3 themselves, but the online index build belongs in step 1. Doing it then is cheapest and avoids a separate change window later.

### Worth mitigating (before step 4 / step 6 are approved)

- **Narrative 4: flag ordering.** Add the code-level dependency between the two flags and the 5-minute NULL-insert alert before any consumer turns on `orders_read_customer_id`.
- **Narrative 5: unknown readers.** Run the catalog and query-log discovery and the revoke-before-drop step as gates in §6. Also check now whether `cust_ref` is `NOT NULL`. If it is, add the `DROP NOT NULL` step to §6 explicitly; otherwise step 6a fails every order insert at 150 writes/min.
- **Rollback section accuracy.** Correct the claim that the step-6 drop is "recoverable from the snapshot." The real recovery is to re-add the column and backfill it from `customer_id`, a 6-hour job. Plan for that duration.

### Acknowledged risks

- **Stalled contract.** With weekly consumer switches plus a 30-day soak, the migration runs for about 2+ months on two named owners. If priorities shift, the table could end up permanently holding two customer-ID columns. That is arguably worse than today, because it recreates the wrong-column join risk the proposal exists to remove. This is acceptable to carry if the decision record sets a date for step 6 and assigns ownership of it. If that date passes, the default should be to finish the contract, not to leave the duplicate column in place.
- **Daily-scan cost of verification.** A full 9M-row comparison each day is modest. Once the NULL-insert alert from narrative 4 exists, it is fine to keep as is.
