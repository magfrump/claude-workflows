# Proposal: Move the billing ledger from Postgres to Keel

**Owner:** Billing Platform team · **Target cutover:** Saturday 14 March, 02:00 UTC

## Summary

The billing ledger (invoices, payments, credit notes, adjustments) lives in a
single Postgres 11 instance that is out of vendor support in June. We will move
it to Keel, the managed distributed SQL service the rest of the company adopted
last year. The ledger holds 41M rows across 12 tables and takes about 3,200
writes per minute at the weekday peak, 600 per minute overnight on weekends.

## Plan

1. **Schema port (done).** The Keel schema mirrors Postgres table for table.
   Types that differ (money, interval) are mapped in `ledger_schema.sql`, and
   the mapping has been reviewed by the finance systems lead.
2. **Initial copy (week of 2 March).** A snapshot of Postgres is loaded into
   Keel with the vendor's bulk loader. We then run the change-capture tool to
   stream Postgres changes into Keel until the cutover, so Keel stays within a
   few seconds of Postgres.
3. **Verification (9-13 March).** A nightly job compares row counts and a
   per-customer checksum of invoice totals between the two databases. We will
   not cut over unless five consecutive nights match.
4. **Cutover (14 March, 02:00 UTC).** Put the billing API into maintenance mode
   for up to 20 minutes. Let the change stream drain. Stop the change-capture
   tool. Flip the `LEDGER_DSN` config value on the billing API and the invoicing
   workers to Keel. Take the API out of maintenance mode. Postgres is set to
   read-only and left running.
5. **Soak (14-28 March).** Keel serves all reads and writes. Dashboards for p99
   latency, error rate and invoice-run duration are already built.
6. **Decommission (after 28 March).** Final Postgres snapshot to cold storage,
   then shut the instance down.

## Rollback

If Keel misbehaves at any point during the soak, we flip `LEDGER_DSN` back to
Postgres, make Postgres writable again, and restart the billing API and the
workers. This takes about ten minutes and has been rehearsed twice in staging.
The rollback runbook lives in the team wiki.

## Risk notes

- **Latency.** Keel adds 4-6 ms per query in our load tests. The monthly invoice
  run on 1 April is the heaviest job; we measured it at 38 minutes on Keel
  against 31 on Postgres, well inside its two-hour window.
- **Team.** Four engineers on the Billing Platform team have run the staging
  rehearsal. On-call during the soak follows the normal rotation.
- **Downstream.** The finance data warehouse reads from a nightly export job;
  that job is repointed at Keel as part of step 4.

## Decision requested

Approve the 14 March cutover date so we can book the maintenance window with
Customer Support.
