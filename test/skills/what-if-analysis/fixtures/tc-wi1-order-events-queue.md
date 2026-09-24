# RFC-112: Move order events from the outbox poller to Tidewater Streams

**Author:** Platform team · **Status:** Proposed · **Target:** Q4

## Summary

Order events (`order.placed`, `order.paid`, `order.refunded`, `order.shipped`)
are published today by a single outbox poller that reads the `order_outbox`
table every two seconds and calls each downstream consumer over HTTP, one event
at a time, in insert order. The poller is our slowest moving part: at the
November peak it fell 11 minutes behind, and it cannot run as more than one
instance because it relies on a row lock to avoid sending an event twice.

We propose replacing the poller with Tidewater Streams, the managed partitioned
log our infrastructure group already runs for clickstream data. Producers write
to a `orders` topic with 12 partitions keyed by `customer_id`; each consumer
reads its own subscription and scales horizontally.

## Current consumers

| Consumer | What it does with an event |
|---|---|
| `invoice-mailer` | Sends the customer a receipt email for `order.paid` |
| `loyalty-accrual` | Adds points to the customer's balance for `order.paid`, removes them for `order.refunded` |
| `fulfilment-bridge` | Creates a pick ticket in the warehouse system for `order.paid` |
| `analytics-sink` | Appends every event to the data lake |

## Delivery semantics

Tidewater Streams delivers at least once. A consumer that crashes after doing
its work but before committing its offset will see the same event again after
restart, and a partition rebalance can replay up to the last committed offset.

This is fine for us. Every consumer is idempotent, so a redelivered event is
harmless: processing it a second time leaves the system in the same state as
processing it once. We will therefore not add a deduplication table or an
event-ID check on the consumer side, which keeps the migration to a
configuration change for each team rather than a code change.

## Rollout

1. Dual-write: the order service writes to both `order_outbox` and the
   `orders` topic for two weeks.
2. Consumers switch their input one at a time, starting with `analytics-sink`.
3. Once all four consumers read from Tidewater, the poller is switched off.
   `order_outbox` stays in place, with the order service still writing to it,
   for 60 days, so any consumer can be pointed back at the poller.

## Expected results

- End-to-end event latency at peak falls from minutes to under two seconds.
- Each consumer can scale on its own; the single-poller bottleneck goes away.
- The platform team stops maintaining the poller (roughly one on-call page a
  week today).

## Costs

Tidewater is billed per partition-hour. Twelve partitions at our volume adds
about $410 a month, which is less than one engineer-day of poller maintenance.

## Open items

- Partition count may need to rise to 24 before next November.
- `analytics-sink` wants the raw event payload schema versioned; tracked
  separately.
