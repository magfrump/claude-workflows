# What-If Analysis: RFC-112, Order Events from Outbox Poller to Tidewater Streams

**Proposal:** RFC-112, which replaces the `order_outbox` poller with a 12-partition Tidewater Streams `orders` topic keyed by `customer_id`
**Date:** 2026-11-20
**Upstream critiques:** none

> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output. This skill is most powerful when focused on the gaps that critics miss.

**Prior Art Check:** No repository was available, so `docs/decisions/` and `docs/working/` could not be searched. No `[PRIOR CONSIDERATION]` findings are possible. Keywords that should be searched once a repo is available: `outbox`, `order_outbox`, `idempotent`, `dedup`, `Tidewater`, `pick ticket`, `loyalty`, `partition`, `dual-write`, `at-least-once`.

All findings below are tagged `[NOVEL]` because there is no baseline.

---

## Assumptions Examined

**A1. Every consumer is idempotent.**
- **Source:** Explicit, in "Delivery semantics."
- **If wrong:** Redesign. The decision to skip deduplication, and the "config change, not code change" claim, both rest entirely on this.
- **Tag:** `[NOVEL]`
- **Note:** The RFC's own consumer table contradicts it. See Confidence Inversions.

**A2. Per-customer ordering (one partition per `customer_id`) is sufficient. Global insert order is not needed.**
- **Source:** Implicit. The RFC never mentions that it is giving up the poller's global ordering.
- **If wrong:** Redesign for any consumer that correlates events across customers, or that relies on ordering during repartitioning.
- **Tag:** `[NOVEL]`

**A3. The order service can write to both the database and Tidewater reliably, and continue doing so after the poller is off.**
- **Source:** Implicit, in Rollout step 1 and step 3.
- **If wrong:** Redesign. This is the dual-write problem that the outbox pattern exists to solve. See Hidden Coupling C1.
- **Tag:** `[NOVEL]`

**A4. Switching a consumer from HTTP push to subscription pull is a configuration change.**
- **Source:** Explicit, in "Delivery semantics."
- **If wrong:** Tweak to the plan, but significant for the argument. Every team has to write a consumer loop, offset commits, and error handling. Once they are writing code anyway, the stated reason for skipping dedup disappears.
- **Tag:** `[NOVEL]`

**A5. Tidewater's configuration for clickstream (retention, durability, SLO, on-call) is fit for financial events.**
- **Source:** Implicit, in "already runs for clickstream data."
- **If wrong:** Redesign, or a separate cluster or tier. Clickstream tolerates loss. Orders do not.
- **Tag:** `[NOVEL]`

**A6. The outbox gives a working rollback path for 60 days.**
- **Source:** Explicit, in Rollout step 3.
- **If wrong:** Full retreat becomes impossible, or becomes a duplicate-storm event. See Reversibility Map.
- **Tag:** `[NOVEL]`

**A7. The bottleneck is the poller, not the downstream systems it throttles.**
- **Source:** Implicit, in "Expected results."
- **If wrong:** Tweak. Latency moves into the warehouse system or the email provider instead of disappearing.
- **Tag:** `[NOVEL]`

**A8. The rollout fits safely in Q4.**
- **Source:** Implicit, from "Target: Q4."
- **If wrong:** Tweak, but timing matters. Today is 2026-11-20, which puts the November peak now or imminent. A two-week dual-write followed by four serial cutovers lands squarely in peak season.
- **Tag:** `[NOVEL]`

---

## Consequence Chains

**Outcome 1: At-least-once delivery replaces the poller's row-locked, effectively once-only delivery.**
```
→ First-order: Consumers occasionally receive the same event twice (crash before commit, rebalance replay)
  → Second-order: loyalty-accrual adds points twice for one order.paid (an increment is not idempotent)
    → Third-order: Customers spend the phantom points. Clawback becomes a customer-service and finance problem, not a data fix.
  → Second-order: fulfilment-bridge creates two pick tickets
    → Third-order: Two physical shipments. Inventory decrements twice, causing false stock-outs and real cost per duplicate.
  → Second-order: invoice-mailer sends duplicate receipts
    → Third-order: Customers assume a double charge. Support tickets and chargeback inquiries follow.
  → Second-order: analytics-sink appends duplicates
    → Third-order: Revenue dashboards overstate paid orders. Finance reconciliation fails against the payments system.
```

**Outcome 2: Consumers scale horizontally.**
```
→ First-order: Teams add instances (or autoscale) at peak
  → Second-order: Each scale event triggers a partition rebalance, which replays from the last committed offset
    → Third-order: Duplicates (Chain 1) concentrate at peak, when volume is highest and humans are busiest
  → Second-order: Instances beyond 12 per subscription sit idle. Parallelism is capped by partition count.
    → Third-order: The planned move to 24 partitions remaps customer_id→partition, which breaks per-customer ordering for in-flight events during the transition
```

**Outcome 3: Latency drops from minutes to seconds.**
```
→ First-order: Events arrive at consumers in bursts at full producer rate
  → Second-order: The warehouse system and email provider receive peak load undamped. The poller was acting as an accidental rate limiter.
    → Third-order: Downstream 429s or timeouts lead to consumer retries without dedup, which produce more duplicates or a head-of-line-blocked partition
  → Second-order: order.refunded can now be processed before a slow order.paid finishes. This happens if a consumer processes concurrently within a partition, or after a repartition.
    → Third-order: loyalty-accrual removes points that were never added, giving a negative balance or a silently clamped refund
```

---

## Coupling Analysis

**C1. Atomicity between the order transaction and the event (invisible, behavioral).**
Today the event row commits in the same transaction as the order, so an event exists if and only if the order exists. Under the new design the Tidewater write happens outside that transaction, which opens two gaps:
- The order commits and the topic write fails. The event is lost.
- The topic write succeeds and the order transaction rolls back. This produces a phantom `order.paid` for an order that does not exist, which leads to a pick ticket for nothing.

During dual-write the poller masks the first gap. After the poller is switched off, nothing reconciles. `order_outbox` keeps being written, but nobody reads it.

**C2. Consumers' implicit reliance on no-duplicate delivery (invisible, behavioral contract).**
The poller's row lock means consumers have probably never seen a duplicate in production. Their "idempotency" is therefore untested, not proven. They depend on current behavior, not on a documented contract.

**C3. Global ordering assumptions (invisible, convention).**
Some consumers may rely on cross-customer insert order. Examples: analytics-sink partitioning lake files by arrival time, or fulfilment-bridge batching. The RFC does not audit this.

**C4. Shared Tidewater cluster with clickstream (visible as infrastructure, invisible as a load correlation).**
Clickstream peaks exactly when orders peak. Noisy-neighbor effects, broker quotas, and infrastructure-group maintenance windows are now in the order path. Ownership of the order-delivery SLO moves to a team that did not sign up for it.

**C5. Retention window versus consumer outage (visible in config, unexamined).**
The poller's table held unsent events indefinitely. If Tidewater retention is tuned for clickstream (for example, hours or a few days), a consumer down past retention loses orders permanently.

**C6. Cutover position mapping (invisible, temporal).**
When a consumer switches from poller to topic, nothing maps "last outbox row delivered" to "first topic offset to read." The team has to pick one of two failure modes:
- Overlap, which produces duplicates in non-idempotent consumers.
- Gap, which loses events.

**C7. Poller "sent" state (invisible).**
Rollback to the poller depends on how rows are marked as delivered. That depends on whether marking is global or per-consumer, which the RFC does not say. If the poller is off, rows accumulate unmarked.

---

## Confidence Inversions

**"Every consumer is idempotent." This is the most confident claim in the RFC, and its own table refutes it.**
- `invoice-mailer` *sends an email*. A second send is a second email.
- `loyalty-accrual` *adds points*. An increment applied twice is double.
- `fulfilment-bridge` *creates a pick ticket*. A second create is a second ticket, unless the warehouse system enforces a unique external order key, and nobody has said it does.
- `analytics-sink` *appends*. An append is the canonical non-idempotent operation.

Scenario: on Black Friday, `loyalty-accrual` autoscales from 4 to 8 instances. The rebalance replays about 30 seconds of `order.paid` events per partition. Thousands of customers get double points, and the problem is noticed days later when finance reconciles liability. None of the four consumers is idempotent as described. Each may become idempotent if its downstream enforces a natural key, but that needs to be verified per consumer, not asserted.

**"This keeps the migration to a configuration change."**
Inverted, it is a code change for every team (pull loop, offset commit, error and poison handling). Once each team is writing code, adding an `event_id` check is a marginal cost. The trade-off that justified skipping dedup does not exist.

**"Any consumer can be pointed back at the poller."**
Inverted: the poller restarts against 60 days of unmarked rows and replays everything, or it needs a manually set cursor that nobody has built. The rollback path itself generates the duplicate storm.

**"$410 a month is less than one engineer-day."**
This compares infrastructure cost against poller maintenance. It omits four teams' consumer rewrites, the dedup work that will be added after the first incident, and the cost of a single duplicate-shipment incident.

---

## Adversarial Scenarios

1. **Peak-season rebalance storm (likely ~20–30% if rolled out in Q4).** Autoscaling or a broker restart during peak replays committed-offset windows across all subscriptions at once. Realistic worst case: hundreds to low thousands of duplicate pick tickets and double loyalty credits in an hour. These are physically and financially irreversible once shipped or spent.

2. **Silent event loss after poller shutdown (~10–20% over the 60 days).** A transient Tidewater produce error, a timeout treated as success, or a deploy that drops in-memory buffers loses `order.paid` events. Realistic worst case: paid orders never shipped, discovered only through customer complaints, because nothing compares `order_outbox` to the topic.

3. **Hot customer or hot partition (~10–20%).** A B2B or marketplace account places a burst of orders. Its partition is serial per consumer, so its lag reproduces the 11-minute November problem for that slice. A poison message on that partition blocks it entirely, or is skipped silently depending on per-team error handling.

---

## Reversibility Map

| Timepoint | What reversal requires | Difficulty |
|---|---|---|
| **During dual-write (week 1–2)** | Stop the topic writes. The poller is still authoritative. | Easy |
| **1 week after a consumer cuts over** | Point it back at the poller, but the cutover position (C6) must be reconstructed. Any duplicate shipments or points already issued stay issued. | Moderate, and individual side effects are irreversible from day one |
| **1 month after poller off** | Restart the poller against ~30 days of unmarked rows. That needs a hand-set cursor per consumer, or it causes a massive replay into non-idempotent consumers. The poller code has gone unexercised and its on-call knowledge has decayed. | Hard |
| **Day 60, when the outbox is retired** | **⚠️ Cliff edge.** No fallback source of truth and no way to reconcile topic loss. Consumers' code is now Tidewater-only. | Effectively irreversible |

Additional cliff: **the 12→24 repartition.** This is a one-way remap of keys to partitions, and it breaks ordering during the transition. It cannot be undone without another remap.

---

## Cost of Success

Suppose everything works: latency is under two seconds, the poller is gone, and teams scale independently. What is worse than today?

- **Complexity:** Event delivery is now four separate consumer implementations with four separate interpretations of retry, offset commit, and poison handling. Previously there was one central behavior.
- **Maintenance:** The weekly page does not disappear. It moves to the infrastructure group (Tidewater) and to four consumer teams (lag, rebalance, and duplicate incidents). The platform team's gain is partly an accounting shift.
- **Optionality:** Partition count and the `customer_id` key are hard to change later. Any future need for ordering by order or merchant, or exactly-once semantics, means another migration. Schema versioning (an open item) becomes much harder after four consumers are bound to the raw payload.
- **Guarantee loss:** Moving from transactional outbox to dual-write quietly gives up atomic event publication. The organisation may not notice this is gone until an incident.

---

## Findings Summary

- `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The claim that all consumers are idempotent is false on its face for all four listed consumers. **High severity.**
- `[HIDDEN COUPLING]` `[NOVEL]` Losing transactional atomicity between order and event (dual-write) leads to lost or phantom events after the poller is off. **High severity.**
- `[HIDDEN COUPLING]` `[NOVEL]` Consumers have never been exposed to duplicates under the row-locked poller, so their idempotency is latent and untested. **High severity.**
- `[SECOND-ORDER EFFECT]` `[NOVEL]` Horizontal scaling triggers rebalances, which replay events and so produce duplicates concentrated at peak. **High severity.**
- `[HIDDEN COUPLING]` `[NOVEL]` There is no cutover offset mapping between the outbox and the topic, so each cutover overlaps (duplicates) or gaps (loss). **Medium severity.**
- `[REVERSIBILITY CLIFF]` `[NOVEL]` Rolling back to the poller after shutdown replays accumulated unmarked rows. The 60-day outbox fallback is not a working rollback as written. **High severity.**
- `[REVERSIBILITY CLIFF]` `[NOVEL]` Day 60 outbox retirement removes the only reconciliation source. **Medium severity.**
- `[REVERSIBILITY CLIFF]` `[NOVEL]` The 12→24 repartition is a one-way key remap that breaks ordering in flight. **Medium severity.**
- `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The "config change only" claim is false, because moving from push to pull is a code change. This undermines the rationale for skipping dedup. **Medium severity.**
- `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The loss of global ordering was not audited, and refund-before-paid is possible for loyalty. **Medium severity.**
- `[HIDDEN COUPLING]` `[NOVEL]` The Tidewater cluster is shared with clickstream: correlated peak load, retention and durability tuned for lossy data, and an SLO owned by another team. **Medium severity.**
- `[SECOND-ORDER EFFECT]` `[NOVEL]` Removing the poller removes accidental rate limiting into the warehouse system and email provider. **Medium severity.**
- `[SECOND-ORDER EFFECT]` `[NOVEL]` Hot partitions and poison messages recreate the lag problem per partition. **Low to medium severity.**
- `[UNEXAMINED ASSUMPTION]` `[NOVEL]` A Q4 target overlaps the current November peak. **Medium severity, timing-dependent.**
- `[SUCCESS COST]` `[NOVEL]` Delivery semantics fragment across four teams, on-call load relocates rather than disappearing, and the partition key and schema become locked in. **Low to medium severity.**
- `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The cost comparison omits consumer rewrite and incident costs. **Low severity.**

---

## Recommendations

**Must address before proceeding**
1. **Retract the idempotency claim and add consumer-side dedup.** Put a stable `event_id` in every event. Each non-analytics consumer records processed IDs, either in a dedup table or through a unique key enforced downstream. Examples: the warehouse rejects a second pick ticket per `order_id`, and loyalty uses a ledger with a unique index on `(order_id, event_type)` instead of a balance increment. For analytics-sink, dedup on `event_id` at query or compaction time.
2. **Keep the outbox as the publication mechanism.** Have a relay (outbox→Tidewater) publish the topic from `order_outbox` instead of the order service dual-writing. This preserves atomicity. The relay can be made concurrent with partition-aware claiming, which removes the single-instance limit while keeping the guarantee.
3. **Make rollback real.** Define and test, before the poller is switched off, how the poller resumes for one consumer from a given point without replaying everything.
4. **Move the rollout out of peak.** Do not start dual-write or cutovers until after the November and December peak.

**Worth mitigating**
- Define a cutover procedure per consumer: drain the poller, record the last delivered event ID, and start the subscription with dedup absorbing the overlap.
- Confirm Tidewater retention, replication, and produce-ack settings for the `orders` topic, and agree an SLO and on-call arrangement with the infrastructure group. Consider a dedicated tier.
- Add a reconciliation job comparing `order_outbox` (or orders in the database) with events consumed. Alert on gaps.
- Specify poison-message handling (dead-letter subscription) as a shared library rather than four bespoke versions.
- Add rate limiting or backpressure toward the warehouse system and the email provider.
- Plan the 12→24 repartition now, either by provisioning 24 up front or by documenting a drain-then-remap procedure. This avoids an ordering break next November.
- Audit consumers for cross-customer ordering dependencies.

**Acknowledged risks**
- Duplicate analytics rows before dedup is in place are acceptable if analytics-sink cuts over first. They are correctable after the fact. Note, though, that cutting over analytics-sink first validates nothing about the consumers where duplicates are dangerous.
- The $410 a month infrastructure cost, and a possible doubling at 24 partitions, are immaterial at this scale.
