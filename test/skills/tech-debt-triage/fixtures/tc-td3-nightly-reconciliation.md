# Debt item: nightly reconciliation loads every open order into memory

**Team:** Finance Engineering (Brackwater Freight, logistics) · **Written:** 2026-10-05 · **Raised by:** Dana K., finance engineering

## What it is

`recon/nightly.py` matches carrier invoices against open orders every night. It
loads every open order into a Python dict first and then walks the invoices.

```python
def run_nightly(db, invoices):
    open_orders = {o.id: o for o in db.query(Order).filter(Order.status != "closed").all()}
    unmatched = []
    for inv in invoices:
        order = open_orders.get(inv.order_ref)
        if order is None or not _amounts_match(order, inv):
            unmatched.append(inv)
    write_exceptions(unmatched)
```

The job runs on a worker with a hard 16 GB memory limit. The container is killed
if it goes over.

## History

- 6 commits in two years. The code is short and easy to read.
- No incidents so far. The job finishes in about 40 minutes.
- Open orders grow as the business grows, because orders stay open until the
  carrier's invoice arrives.

## Monitoring data: peak memory of the nightly job

| Month (2026) | Peak RSS |
|---|---|
| June | 12.4 GB |
| July | 13.0 GB |
| August | 13.6 GB |
| September | 14.2 GB |

Order volume has grown at the same steady rate since January, and sales expects it
to continue. If the job fails, invoices go unreconciled. Accounts payable then
cannot release carrier payments, and two of our carriers have late-payment
penalties in their contracts.

## Proposed fix

Stream the open orders in batches keyed by `order_ref` instead of loading them all.
Alternatively, push the match into a SQL join. Estimated at 3 engineer-days. The
job has integration tests against a seeded database.

## Team context

The finance engineering team has three engineers. Their Q4 roadmap is full of
feature work for the new billing portal.

Is this worth fixing?
