# What-If Analysis: RFC-112, order events from outbox poller to Tidewater Streams

**Proposal:** RFC-112, "Move order events from the outbox poller to Tidewater Streams" (Platform team, Proposed, Target Q4)
**Date:** 2026-11-20
**Upstream critiques:** none

> ℹ️ **No upstream critique provided.** This analysis covers the full consequence space
> independently. For maximum value, run a critique skill first (e.g., `cowen-critique`) and
> provide its output. This skill is most powerful when focused on the gaps that critics miss.

**Prior Art Check:** No repository is available, so `docs/decisions/` and `docs/working/` could not be searched. No `[PRIOR CONSIDERATION]` findings are possible. All findings are tagged `[NOVEL]` because there is no baseline.

---

## Assumptions Examined

- **Assumption:** Every consumer is idempotent, so processing a redelivered event twice leaves the same state as processing it once.
  - **Source:** explicit (Delivery semantics, paragraph 2)
  - **If wrong:** redesign. All four consumers in the RFC's own table fail this test:
    - `invoice-mailer` sends a second receipt email.
    - `loyalty-accrual` "adds points" and "removes them". Those are increments, not set-to-value operations, so a replay double-credits or double-debits.
    - `fulfilment-bridge` "creates a pick ticket", so a replay creates a second ticket and possibly a second physical shipment.
    - `analytics-sink` "appends", so a replay duplicates rows in the lake.

    The decision not to add dedup or event-ID checks rests entirely on this claim.
  - **Tag:** `[NOVEL]`

- **Assumption:** The order service can write to both `order_outbox` and the `orders` topic without losing or inventing events, and later can write to the topic alone.
  - **Source:** implicit (Rollout step 1; Summary "Producers write to a `orders` topic")
  - **If wrong:** redesign. The outbox pattern exists to make the event write atomic with the order transaction. A direct topic write sits outside that transaction:
    - If the topic publish fails after the DB commit, the event is lost.
    - If the publish succeeds and the DB transaction then rolls back, a phantom event is delivered.

    Once the poller is off, nothing reconciles the two stores.
  - **Tag:** `[NOVEL]`

- **Assumption:** Switching a consumer from HTTP push to a Tidewater subscription is "a configuration change for each team rather than a code change."
  - **Source:** explicit (Delivery semantics, paragraph 2)
  - **If wrong:** tweak to the plan's cost and schedule, but not to its architecture. Today consumers expose HTTP endpoints that the poller calls. Reading a subscription needs several things they don't have now:
    - a client library
    - offset-commit placement
    - rebalance handling
    - poison-message handling
    - lag monitoring

    Unless Tidewater offers an HTTP push bridge, this is code in four services.
  - **Tag:** `[NOVEL]`

- **Assumption:** Per-`customer_id` ordering is a sufficient replacement for today's global insert order.
  - **Source:** implicit (12 partitions keyed by `customer_id`; today "one event at a time, in insert order")
  - **If wrong:** tweak for most consumers, redesign for any that depend on cross-customer or global sequence. Two examples are `analytics-sink` deriving sequence from arrival order, and any logic that correlates events across customers. Ordering also breaks entirely for events with a null or changing `customer_id`, such as guest checkout or account merges.
  - **Tag:** `[NOVEL]`

- **Assumption:** Every order event has a stable, well-distributed `customer_id`.
  - **Source:** implicit (partition key choice)
  - **If wrong:** tweak. Null keys either pile into one partition or are spread randomly, depending on client behaviour; random spreading loses ordering for those orders. Large B2B accounts create hot partitions that cap throughput no matter how far consumers scale.
  - **Tag:** `[NOVEL]`

- **Assumption:** Tidewater, built and tuned for clickstream, offers retention, durability and an operational SLA suitable for financial and fulfilment events.
  - **Source:** implicit ("the managed partitioned log our infrastructure group already runs for clickstream data")
  - **If wrong:** redesign. Clickstream is loss-tolerant and usually has short retention. Paid orders are not loss-tolerant. If retention is, say, 3–7 days, a consumer that is down longer than that loses events permanently.
  - **Tag:** `[NOVEL]`

- **Assumption:** The 60-day fallback works: "any consumer can be pointed back at the poller."
  - **Source:** explicit (Rollout step 3)
  - **If wrong:** tweak, but it is the only safety net, so the tweak must exist before cutover. See the Reversibility Map.
  - **Tag:** `[NOVEL]`

- **Assumption:** Raising the partition count from 12 to 24 is a routine open item.
  - **Source:** explicit (Open items)
  - **If wrong:** tweak. On a keyed topic, changing the partition count remaps keys to new partitions. Events for a customer can then sit in two partitions at once, and ordering breaks during the transition. The RFC also says the change may be needed "before next November", which is right before peak.
  - **Tag:** `[NOVEL]`

## Consequence Chains

**Outcome 1: consumers scale horizontally**

```
→ First-order: consumers autoscale with load instead of being bottlenecked by one poller
  → Second-order: every scale-up and scale-down triggers a partition rebalance, and each
    rebalance replays from the last committed offset
    → Third-order: duplicates are not rare edge cases. They cluster at peak, exactly when
      autoscaling is busiest. Peak day brings bursts of duplicate receipts, double loyalty
      credits and duplicate pick tickets.
  → Second-order: downstream systems (warehouse API, email provider) see up to 12× the
    concurrency the poller ever sent them. The poller was a de facto rate limiter.
    → Third-order: after any consumer outage, the catch-up surge hits the warehouse system
      or trips the email provider's rate limits. Retries then trigger more redelivery and
      more duplicates.
```

**Outcome 2: latency falls from minutes to under two seconds**

```
→ First-order: events reach consumers in about 2 s at peak
  → Second-order: failure isolation changes shape. One poison event (bad payload, warehouse
    rejects it) blocks its whole partition, which holds ~1/12 of customers, while the
    other 11 partitions keep flowing.
    → Third-order: the headline lag metric looks healthy while a subset of customers get
      no receipts and no pick tickets. The RFC has no dead-letter policy, so the team must
      choose under pressure between blocking the partition and skipping an event, possibly
      silently dropping a paid order.
  → Second-order: paid → refunded sequences that used to be spread over minutes now land
    within seconds of each other.
    → Third-order: if a consumer processes paid and refunded but commits only the paid
      offset before a rebalance, the replay applies the refund twice. The customer is left
      with a negative loyalty balance.
```

**Outcome 3: platform team stops maintaining the poller**

```
→ First-order: about one on-call page a week disappears for the platform team
  → Second-order: operational responsibility for delivery spreads across four consumer
    teams (lag, offsets, rebalances) and the infrastructure group (Tidewater itself)
    → Third-order: "did order X's event get delivered?" used to be answerable with a
      SELECT on order_outbox. Now it means checking committed offsets in four
      subscriptions. Incident triage time goes up, and nobody owns end-to-end delivery.
```

## Coupling Analysis

| Coupling | Visibility | Consequence |
|---|---|---|
| Order transaction ↔ event publication (the transactional outbox guarantee) | **Invisible.** It is a property of the current design, not a listed dependency. | Dual-write breaks atomicity, so events can be lost or invented (see Assumptions). |
| Poller as rate limiter for warehouse API and email provider | **Invisible** (behavioural) | Removing serialisation exposes downstreams to parallel load and catch-up surges. |
| Order events ↔ clickstream on shared Tidewater infrastructure | **Visible to infra, invisible to the RFC** | Clickstream also peaks in November. Noisy-neighbour contention, broker incidents or quota limits caused by clickstream now degrade order delivery. Infra's on-call priorities were set for loss-tolerant data. |
| Poller ↔ per-consumer routing during the one-at-a-time switch | **Invisible** (temporal) | When consumer N switches, the poller must stop calling it at exactly the offset where the subscription starts. If the poller keeps calling, events are delivered twice. If the subscription starts late, events fall in the gap and are lost. The poller may be minutes behind at that moment, so the two positions are not naturally aligned. |
| Poller's "sent" marking ↔ rollback | **Invisible** (behavioural) | The poller uses row locks or sent markers. Once it is off, unsent rows accumulate. Pointing a consumer back means either a backlog flood or a manual watermark mapping topic offsets to outbox IDs. |
| Consumers' HTTP endpoints ↔ fallback plan | **Invisible** (cross-team) | Rollback needs four teams to keep endpoints they no longer use deployed and working for 60 days. Nothing in the RFC requires that. |
| `analytics-sink` ↔ arrival order and uniqueness | **Invisible** (convention) | Downstream lake queries may assume one row per event and insert-ordered sequence. Both assumptions break. |
| Partition count ↔ key-to-partition mapping | **Visible** (config), but its consequence is unacknowledged | Repartitioning to 24 breaks per-customer ordering during the transition. |

## Confidence Inversions

**"Every consumer is idempotent."** This is the RFC's most confident claim and the one it acts on by removing safeguards. Inverting it takes no hypothetical: the consumer table describes non-idempotent operations. The concrete scenario: during the first post-cutover peak, `fulfilment-bridge` autoscales from 3 to 10 instances. Six rebalances in an hour each replay a few seconds of `order.paid` events, producing a few hundred duplicate pick tickets. The warehouse ships some of them twice. Finance absorbs the cost of the goods and support handles the complaints. In parallel, loyalty balances drift, and nobody can reconstruct the drift because there is no event-ID log.

**"A configuration change for each team."** Suppose that in practice each team needs a sprint to add a Tidewater client, offset handling and lag alerts. The four switches then serialise behind team roadmaps, and the two-week dual-write stretches to months. That keeps the riskiest state, dual-write without reconciliation, open longer. The Q4 target slips into or past the holiday freeze.

**"Under two seconds at peak."** The 11-minute lag came from serial HTTP calls. Under Tidewater, latency is bounded by the slowest consumer per partition. If the warehouse system's p99 is around 1 s, a hot B2B partition still lags minutes at peak. The RFC will have traded a global bottleneck for 12 smaller ones, one of which is overloaded.

**"$410 a month is less than one engineer-day."** The direct bill is likely right. Not counted: consumer code changes in four teams, the dedup work this analysis says is needed, doubled partition cost at 24, and the infrastructure group's added on-call load. The cost comparison isn't wrong, but it covers only one line item.

## Adversarial Scenarios

1. **The rollout collides with peak (about 20–30% likely).** Today is 2026-11-20 and the target is Q4. The November peak, where the poller fell 11 minutes behind, is a week away, and December is high-volume shipping season. If dual-write or the first consumer switch happens near peak, every rebalance-replay and cutover-gap problem shows up at maximum volume and with change freezes limiting fixes. Realistic worst case: the team stays half-migrated through the holidays, with some consumers on each path and dual-write running unreconciled.

2. **A Tidewater incident or retention shortfall (about 10–15% likely over a year).** A broker incident triggered by clickstream load, or a consumer down over a long weekend, exceeds retention. Realistic worst case: a few hours of `order.paid` events are never delivered to `fulfilment-bridge`. Paid orders don't ship, and there is no unread outbox to replay from, because the outbox was decommissioned or its rows were never marked against topic offsets.

3. **The topic publish fails while the DB commit succeeds (about 10–20% likely to occur at least once a quarter).** A transient network error or Tidewater throttling at peak causes the order service's publish call to fail after commit. Without the outbox poller as backstop, the event is gone. Realistic worst case: a slow, silent trickle of paid-but-unfulfilled orders, found only through customer complaints.

## Reversibility Map

| Timepoint | State | What reversal requires |
|---|---|---|
| **1 week** | Dual-write; possibly `analytics-sink` switched | Point `analytics-sink` back at the poller and stop topic writes. Easy. The only residue is duplicate or out-of-order rows in the lake, which is a consequence, not a reversal cost. |
| **1 month** | All consumers on Tidewater; poller off for about 1–2 weeks; outbox still written | Moderate and not as the RFC describes. The poller has no idea which outbox rows each consumer has already seen through the topic. Someone must compute a per-consumer watermark from committed offsets, or the poller will resend weeks of backlog: thousands of duplicate receipts and pick tickets. Consumer teams must still have working HTTP endpoints. |
| **6 months** | Past the 60-day window | Hard. The outbox writes have probably been removed, poller code may be deleted, and consumer HTTP endpoints have probably been retired. Reversal means rebuilding the poller path and getting four teams to restore endpoints. |

**Cliff edges:**

- **Poller switch-off (Rollout step 3).** From this moment, reverting any consumer needs an offset-to-outbox reconciliation that nobody has built. This is when "point it back at the poller" stops being a configuration change. `[REVERSIBILITY CLIFF]`
- **Consumer teams retiring their HTTP endpoints.** This can happen at any time after their switch, under each team's control, and nothing in the RFC forbids it. After that, rollback requires another party's work. `[REVERSIBILITY CLIFF]`
- **End of the 60-day window.** The RFC doesn't say whether removing the outbox writes is its own reviewed change. If it is, it isn't a cliff of this proposal. If it happens automatically or by cleanup ticket, it is. That is worth stating explicitly.

## Cost of Success

Picture it working perfectly: events flow in under two seconds, consumers autoscale, and the poller is gone. What is worse about that world than today?

- **Complexity cost:** Delivery state lives in four sets of consumer offsets on shared infrastructure instead of one queryable table. "Was this event delivered?" becomes a cross-team investigation. `[SUCCESS COST]`
- **Maintenance cost:** The one weekly page doesn't vanish. It splits into lag alerts per consumer, rebalance tuning, dead-letter handling and partition-count management, owned by five groups instead of one. `[SUCCESS COST]`
- **Optionality cost:** Order processing is now coupled to the infrastructure group's roadmap for a system designed around clickstream. Retention, quotas, upgrades and SLA are their decisions. Changing the partition key later, for example to `order_id`, is a full topic migration. `[SUCCESS COST]`
- **Audit cost:** The outbox table was a durable, transactional record of every event the business emitted. Unless Tidewater retention is long, that record now exists only in the data lake, which has duplicates. `[SUCCESS COST]`

## Findings Summary

1. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The idempotency claim is false for all four listed consumers. Removing dedup turns at-least-once delivery into duplicate emails, double loyalty credits and debits, duplicate pick tickets and duplicate lake rows.
2. `[HIDDEN COUPLING]` `[NOVEL]` Dual-write drops the transactional outbox guarantee, so event loss or phantom events become possible, and this becomes permanent once the poller is off.
3. `[SECOND-ORDER EFFECT]` `[NOVEL]` Autoscaling causes rebalances, which cause replays. Duplicates concentrate at peak.
4. `[HIDDEN COUPLING]` `[NOVEL]` The per-consumer cutover has no defined handoff offset between poller and subscription. The result is a gap (loss) or an overlap (duplicates).
5. `[HIDDEN COUPLING]` `[NOVEL]` The poller is a de facto rate limiter for the warehouse API and email provider. Parallel consumers and catch-up surges can overload them.
6. `[SECOND-ORDER EFFECT]` `[NOVEL]` A poison event blocks one partition (about 1/12 of customers) while the aggregate lag looks fine. No dead-letter policy is defined.
7. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` Tidewater's retention, durability and SLA were set for clickstream, not orders. There is also noisy-neighbour coupling with clickstream peaks.
8. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` Moving from HTTP push to stream pull is code, not configuration, in four services.
9. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` Keying by `customer_id` fails for null or merged customers and creates hot partitions for large accounts. Global insert order is lost.
10. `[SECOND-ORDER EFFECT]` `[NOVEL]` Repartitioning to 24 breaks per-customer ordering during the transition, likely right before peak.
11. `[REVERSIBILITY CLIFF]` `[NOVEL]` At poller switch-off, rollback needs a watermark reconciliation that doesn't exist.
12. `[REVERSIBILITY CLIFF]` `[NOVEL]` When consumer teams retire HTTP endpoints, rollback depends on other teams' work, and nothing governs when that happens.
13. `[UNEXAMINED ASSUMPTION]` `[NOVEL]` The Q4 target overlaps the November and December peak and the holiday change freeze.
14. `[SUCCESS COST]` `[NOVEL]` Delivery ownership is diffused, and the transactional audit trail is lost.
15. `[SUCCESS COST]` `[NOVEL]` The cost comparison omits consumer-team engineering, dedup work, 24-partition pricing and infrastructure on-call load.

## Recommendations

**Must address before proceeding**

- **Replace the idempotency claim with actual idempotency (findings 1, 3).** Give every event a stable `event_id`, which the outbox row ID already provides. Then make each consumer idempotent:
  - `invoice-mailer`: dedup sends on `event_id`.
  - `loyalty-accrual`: record applied `event_id`s in the same transaction as the balance change.
  - `fulfilment-bridge`: make ticket creation an upsert on `order_id` or `event_id` in the warehouse system.
  - `analytics-sink`: write with `event_id` as a dedup key.

  This changes the migration from "configuration" to "code" for each team. Say so in the RFC.
- **Keep the outbox as the source of truth (finding 2).** Have the topic fed from `order_outbox` by a relay or CDC instead of a second direct write from the order service. That preserves atomicity with the order transaction and still removes the single-instance HTTP bottleneck.
- **Define the cutover handoff per consumer (finding 4).** Specify the exact outbox ID or topic offset where the poller stops calling consumer N and the subscription starts. Verify zero gap with a count reconciliation. With idempotent consumers, deliberately overlapping by a margin becomes safe.
- **Move the schedule off peak (finding 13).** Start dual-write after the holiday freeze, not inside Q4's peak weeks.

**Worth mitigating**

- **Confirm Tidewater fitness with the infrastructure group (finding 7).** Get retention of at least 14 days for `orders`, an on-call priority for order topics, and isolation or quotas from clickstream. Watch signal: consumer lag in relation to retention.
- **Throttle downstream calls (finding 5).** Add per-consumer concurrency limits toward the warehouse API and email provider, and rate-limit catch-up.
- **Add a dead-letter policy and per-partition lag alerts (finding 6),** not just aggregate lag.
- **Write the rollback runbook now (findings 11, 12).** Cover how to compute a poller watermark from committed offsets. Require consumer teams to keep HTTP endpoints until the 60-day window closes, and make outbox-write removal a separately reviewed change.
- **Partitioning (findings 9, 10).** Decide the null-`customer_id` behaviour explicitly. If 24 partitions are likely, create the topic with 24 now. Partition-hour cost is small next to a pre-peak repartition.
- **Run a 2-week dual-write reconciliation job,** comparing outbox IDs against topic contents, as the gate for the first consumer switch.

**Acknowledged risks**

- **Loss of global cross-customer ordering (part of finding 9).** None of the listed consumers appears to need it beyond per-customer order. Confirm with `analytics-sink` and accept it.
- **Diffused ownership and higher triage cost (finding 14).** This is the inherent price of a partitioned log. It is acceptable if the platform team publishes a "trace an event" runbook across subscriptions.
- **Direct Tidewater cost (finding 15).** Even at 24 partitions, about $820 a month is immaterial next to the poller's on-call burden. The understated cost is engineering time, which the must-address items make explicit.

If you want concrete failure stories for the top risks, such as the duplicate-shipment peak or the silent lost-event trickle, run `pre-mortem` on RFC-112 with this analysis as input.
