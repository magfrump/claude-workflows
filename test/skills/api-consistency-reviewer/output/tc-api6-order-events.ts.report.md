> ⚠️ **No code fact-check report provided.** API documentation claims have not been independently verified against implementation. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

# API Consistency Review: `OrderCancelled` event (subject.ts)

**Scope:** `subject.ts`, lines 38–47 (the `BEGIN/END CHANGE UNDER REVIEW` block). Everything else in the file is the baseline.
**Date:** 2026-11-19

## Baseline Conventions

`subject.ts` is the only source file in the repo. The contract is published to the `orders` topic and read by fulfilment, analytics and notifications (`subject.ts:1-2`). The three existing events (`OrderCreated`, `OrderPaid`, `OrderShipped`) set these conventions:

- **Envelope:** every event is `EventEnvelope<"order.<past-participle>", Order<Verb>Data>`, with `version: 1` and a snake_case `event_id` (`subject.ts:4-9`, `34-36`).
- **Type names:** `Order<PastTense>Data` for the payload and `Order<PastTense>` for the envelope alias.
- **Field case:** every payload field is snake_case.
- **Identifiers:** references to other entities are `<entity>_id: string` (`order_id`, `customer_id`, `payment_id`).
- **Event time:** every payload has `occurred_at: string // ISO-8601 UTC` as its last field (`subject.ts:16, 24, 31`). This is the most consistently applied rule in the file: 3 of 3 events use it.
- **Money:** `<name>_cents: number` paired with `currency: string` (not relevant to this change).
- **Nullability:** no field is optional or nullable in any payload.
- **Versioning:** the envelope's `version` field is the literal type `1`. There's no other versioning mechanism.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `"order.cancelled"` | event type string | `"order.created"`, `"order.paid"`, `"order.shipped"` | `subject.ts:34-36` | Consistent: matches `order.<past-participle>` |
| `OrderCancelledData` | type | `OrderCreatedData`, `OrderPaidData`, `OrderShippedData` | `subject.ts:11, 19, 27` | Consistent |
| `OrderCancelled` | type alias | `OrderCreated`, `OrderPaid`, `OrderShipped` | `subject.ts:34-36` | Consistent |
| `order_id` | field | `order_id` (×3) | `subject.ts:12, 20, 28` | Consistent |
| `reason` | field | `carrier`, `currency` (closest bare-noun string fields; no direct analog) | `subject.ts:15, 23, 29` | Consistent in form. Its semantics are unspecified (see Finding 4) |
| `cancelled_by` | field | `customer_id`, `payment_id` (actor/entity references) | `subject.ts:13, 21` | Inconsistent: other entity references use the `<entity>_id` shape |
| `timestamp` | field | `occurred_at` (×3) | `subject.ts:16, 24, 31` | **Inconsistent:** different name *and* type/format for the same concept |

## Findings

#### 1. Event time uses `timestamp: number` (epoch ms) instead of `occurred_at: string` (ISO-8601)

**Severity:** Inconsistent
**Location:** `subject.ts:43`
**Move:** #2 Naming against the grain, #7 Asymmetry
**Confidence:** High

Precedent: `occurred_at: string // ISO-8601 UTC` used in `subject.ts:16`, `subject.ts:24`, `subject.ts:31`

All three existing order events give their event time as `occurred_at`, an ISO-8601 UTC string. The new event changes both the field name (`timestamp`) and the representation (a number in epoch milliseconds). Consumers that handle all order events the same way will hit problems:

- Analytics code that reads `event.data.occurred_at` across the `OrderEvent` union gets `undefined` for cancellations.
- Code that parses the time with an ISO parser gets a type error, or silently gets a wrong date if it coerces.
- Sorting or windowing logic that mixes the two formats breaks.
- Because `OrderEvent` is a union, TypeScript consumers can no longer read `e.data.occurred_at` without narrowing on `type` first.

**Recommendation:** Replace the field with `occurred_at: string; // ISO-8601 UTC`. This is still cheap to do because the event hasn't shipped yet. Once a consumer depends on `timestamp`, fixing it means a version bump.

#### 2. `cancelled_by` doesn't say what kind of value it holds

**Severity:** Inconsistent
**Location:** `subject.ts:42`
**Move:** #2 Naming against the grain, #8 Nullability contract
**Confidence:** Medium

Precedent: `<entity>_id: string` for references to other entities, used in `subject.ts:13` (`customer_id`), `subject.ts:21` (`payment_id`)

Every existing field that points to another entity names that entity and ends in `_id`. `cancelled_by: string` could hold a user ID, a customer ID, a system actor name, or a role like `"customer"`, `"merchant"` or `"system"`. Consumers can't tell which from the contract. Notifications would need to know whether to look up a customer. The field is also typed as always present, but system or automatic cancellations (payment timeouts, for example) may have no human actor, so producers may end up sending `""` or a sentinel value.

**Recommendation:** If it's an identifier, follow the existing pattern (for example `cancelled_by_customer_id`, or `actor_id` plus `actor_type`). If it's a category, make it a string-literal union. Either way, say what it holds when there's no human actor.

#### 3. Adding a member to `OrderEvent` breaks exhaustive consumers

**Severity:** Minor
**Location:** `subject.ts:46` (added type). The union widening at `subject.ts:49` is a consequence of this change.
**Move:** #3 Consumer contract, #6 Versioning impact
**Confidence:** Medium

Adding a new event type to a topic is normally backward-compatible. However, TypeScript consumers that switch over `OrderEvent["type"]` with a `never` exhaustiveness check will fail to compile once they pick up this version. Runtime consumers that reject unknown `type` values will start erroring or dead-lettering when the first `order.cancelled` message is published. The envelope keeps `version: 1`. That's correct, because no existing payload changed, but it means consumers get no version signal about the new type.

**Recommendation:** Before producers start emitting the event, tell the fulfilment, analytics and notifications teams it's coming, and confirm they ignore unknown `type` values or have been updated to handle this one.

#### 4. `reason` is unconstrained free text

**Severity:** Informational
**Location:** `subject.ts:41`
**Move:** #8 Nullability contract, #1 Baseline
**Confidence:** Low

There's no existing enum-like field to compare against. `carrier` and `currency` are both plain `string`, so `reason: string` matches the file's style. Still, cancellation reasons are a field analytics will want to group by. Free text tends to turn into inconsistent values, and it's unclear whether the field may be empty.

**Recommendation:** Decide whether `reason` is a machine-readable code (a literal union, possibly with a separate optional `reason_detail`) or human-readable text, and document that in the contract.

## What Looks Good

- The event type string `"order.cancelled"` and the type names `OrderCancelledData` / `OrderCancelled` match the existing pattern exactly.
- The new event reuses `EventEnvelope` and so gets `event_id` and `version` for free, so the envelope shape is consistent.
- `order_id` is the first field, as in every sibling event.
- All new field names are snake_case, matching the baseline.
- No existing payload was changed, so the addition doesn't break existing message shapes.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | `timestamp: number` (epoch ms) instead of `occurred_at: string` (ISO-8601) | Inconsistent | `subject.ts:43` | High |
| 2 | `cancelled_by` doesn't say what it holds; breaks the `<entity>_id` pattern | Inconsistent | `subject.ts:42` | Medium |
| 3 | Union widening breaks exhaustive switches and strict runtime consumers | Minor | `subject.ts:46, 49` | Medium |
| 4 | `reason` is unconstrained free text | Informational | `subject.ts:41` | Low |

## Overall Assessment

The new event fits well at the type and envelope level: its names, event type string and envelope reuse all follow the existing pattern. The one clear problem is the event-time field. Every other order event uses `occurred_at` as an ISO-8601 string, and this one switches to `timestamp` in epoch milliseconds. That changes both the name and the format, and it directly hurts the analytics and notification consumers that process order events together. `cancelled_by` needs a clearer meaning before release. All four issues can be fixed in place now, before any consumer depends on the new event. After that, the timestamp mismatch in particular could only be fixed with a version bump.
