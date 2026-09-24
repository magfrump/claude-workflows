# Proposal: Rename `orders.cust_ref` to `orders.customer_id`

**Owner:** Orders team · **Status:** for review

## Summary

The `orders` table (about 9M rows, 150 writes per minute at peak) has a column
`cust_ref` that holds the customer's ID. Every new service gets its name wrong
at least once, and two incidents last year involved joins on the wrong column.
We will rename it to `customer_id` with an expand-and-contract migration so no
step needs downtime or a coordinated deploy.

## Plan

1. **Expand.** Add a nullable `customer_id` column. No application change.
2. **Write to both.** Deploy the Orders service so every insert and update
   writes the same value to `cust_ref` and `customer_id`, in the same
   transaction. This is controlled by the `orders_write_customer_id` flag.
3. **Backfill.** Copy `cust_ref` into `customer_id` for existing rows in batches
   of 5,000, throttled to stay under 20% of database CPU. Estimated at six hours
   off-peak. A verification query checks that the two columns are equal on every
   row, and runs again daily until the contract step.
4. **Switch reads.** Behind the `orders_read_customer_id` flag, the Orders
   service and the three internal consumers (invoicing, fulfilment, analytics
   export) read `customer_id`. Consumers switch one at a time, a week apart.
   Writes to both columns continue throughout.
5. **Soak.** 30 days with all reads on `customer_id` and writes still going to
   both columns.
6. **Contract.** Stop writing `cust_ref`, then drop it in a separate release a
   week later, after a final snapshot of the table.

## Rollback

Until step 6, every step reverses by turning off its flag: reads go back to
`cust_ref`, which has been written on every change the whole time, so nothing
is lost. The dropped column in step 6 is recoverable from the snapshot.

## Verification and ownership

- The daily equality query alerts the Orders on-call if any row differs.
- A contract test in each consumer's CI fails if it references `cust_ref` after
  its switch date.
- Two Orders engineers own the migration and are both on the on-call rotation;
  the runbook has been reviewed by the database reliability team.

## Decision requested

Approve steps 1-3 to start next sprint.
