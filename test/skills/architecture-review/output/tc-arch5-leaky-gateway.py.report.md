# Architecture Review: subject.py (checkout payment port, use case, adapter)

**Scope:** `subject.py` (a single file joining three modules: `checkout/application/ports.py`, `checkout/application/place_order.py` and `checkout/infrastructure/stripe_gateway.py`)
**Date:** 2026-11-19
**User goal:** Judge whether this change keeps the codebase structurally sound.

> ⚠️ **No code fact-check report provided.** Architectural claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

**Scope check:** In scope. The diff adds new modules (module structure), adds a new abstract port and a `PlaceOrder` use case (public APIs), and adds the `CheckoutResult` DTO (data model).

**Trust-boundary cross-reference:** Not active. No `docs/reviews/security-review-*.md` file exists.

---

## Dependency Map

The header comment says the design is **ports and adapters**. The application layer (`checkout/application/`) owns the use cases and the ports. The infrastructure layer (`checkout/infrastructure/`) holds the adapters.

Intended direction:

```
infrastructure/stripe_gateway.py ──► application/ports.py ◄── application/place_order.py
```

Actual direction:

```
infrastructure/stripe_gateway.py ──► application/ports.py ──► stripe (vendor SDK)
                    │                        ▲
                    └──► stripe              │
application/place_order.py ──────────────────┘──► stripe (vendor SDK)
```

The adapter correctly depends inward on the port. But both application modules import `stripe` directly. So the core depends on the vendor SDK, which defeats the stated architecture. Every layer, including the "abstract" one, now depends on Stripe.

---

## Findings

#### 1. The port's signature uses Stripe SDK types, so the application core depends on the vendor

**Severity:** Structural
**Location:** `subject.py:14`, `subject.py:17-24` (`checkout/application/ports.py`)
**Move:** #1 Dependency direction, #3 Module boundary
**Confidence:** High

`PaymentGateway` is supposed to be the application's provider-neutral abstraction. Instead it imports `stripe` and declares `charge(...) -> stripe.PaymentIntent` and `refund(intent: stripe.PaymentIntent) -> stripe.Refund`. That makes the most stable module in the design depend on the most volatile one: a third-party SDK whose types change with its own releases.

Consequences:
- Any other implementation (Adyen, Braintree, an in-memory fake for tests) would have to build and return Stripe objects. In practice that is impossible, so the port has only one real implementation.
- A Stripe SDK upgrade that changes `PaymentIntent` breaks the application layer, not just the adapter.

Moving the vendor logic into `infrastructure/` buys nothing while the port itself names the vendor.

**Recommendation:** Define application-owned value types in `ports.py`, for example `ChargeResult(status, payment_ref, risk: RiskLevel)` plus a `PaymentDeclined` exception or result variant. Have `StripeGateway` translate Stripe objects into them. `refund` should take the application's `payment_ref: str`, not a Stripe intent. Afterwards, `ports.py` should not import `stripe` at all.

#### 2. `PlaceOrder` reads Stripe's object graph and exceptions directly

**Severity:** Structural
**Location:** `subject.py:30`, `subject.py:48-58` (`checkout/application/place_order.py`)
**Move:** #4 Layer violations, #7 Coupling surface (content coupling)
**Confidence:** High

The use case contains several pieces of Stripe-specific knowledge:
- It catches `stripe.error.CardError` and reads `e.user_message`.
- It interprets Stripe's status string `"requires_action"`.
- It walks `intent.latest_charge.outcome.risk_level == "elevated"`.

These are business decisions (decline, needs 3DS, flag for review) written in the vendor's vocabulary, so the business rules sit inside Stripe's data model. Changing providers, or Stripe renaming or moving `outcome.risk_level`, means rewriting checkout logic. The rule "elevated risk needs manual review" can't be unit-tested without building Stripe objects or mocks shaped like them.

**Recommendation:** Move all of this translation into `StripeGateway`. The adapter should map `CardError` to the port's decline type, `requires_action` to an application-level `AUTH_REQUIRED` status, and Stripe's risk levels to an application `RiskLevel` enum. `PlaceOrder` should then branch only on port-defined types, and its `import stripe` should go away.

#### 3. The use case relies on a contract the port never states (`expand: ["latest_charge"]`)

**Severity:** Coupling
**Location:** `subject.py:56-57` (use case) vs. `subject.py:80` (adapter)
**Move:** #6 Substitutability, #7 Coupling surface
**Confidence:** High

`PlaceOrder` dereferences `intent.latest_charge.outcome`. That only works because `StripeGateway.charge` happens to pass `"expand": ["latest_charge"]`. Without the expansion, Stripe returns `latest_charge` as an ID string, and the attribute access fails at runtime.

Nothing in `PaymentGateway`'s contract says this. So a second implementation, or a later edit to this adapter, could satisfy the port's type signature and still break the use case. That makes it a Liskov substitution hazard: the use case depends on adapter internals, not on the interface, and the coupling can't be seen from the port's definition.

**Recommendation:** Fixing Finding 1 fixes this as well. Once the port returns an application-owned result that includes the risk level, getting that data (including which fields to expand) becomes the adapter's private concern.

#### 4. The decline/error contract sits outside the port

**Severity:** Coupling
**Location:** `subject.py:17-24`, `subject.py:48-51`
**Move:** #6 Substitutability, #3 Module boundary
**Confidence:** Medium

The port doesn't say how a charge fails. The use case assumes failures arrive as `stripe.error.CardError`. Any other adapter that raises its own exception gets past the `except`, and `PlaceOrder` crashes instead of returning a declined `CheckoutResult`. Failure semantics are part of the abstraction and need to be stated at the port.

**Recommendation:** Declare the failure modes in `ports.py`. Either define a `PaymentDeclined(reason: str)` exception the port documents as raised, or make declines a result variant. Every adapter is then responsible for translating into it.

#### 5. `refund` takes a whole Stripe object when it needs only an identifier

**Severity:** Minor
**Location:** `subject.py:24`, `subject.py:84-85`
**Move:** #7 Coupling surface (stamp coupling), #5 Interface segregation
**Confidence:** High

The adapter only reads `intent.id`, but the port requires callers to hold a full `stripe.PaymentIntent`. A caller refunding later, such as an admin flow working from the stored `CheckoutResult.payment_ref`, would have to fetch the Stripe object again just to call `refund`. `PlaceOrder` also never uses `refund`. That's acceptable for a gateway port, but if more consumers appear, consider splitting the port into charging and refunding roles.

**Recommendation:** Change the signature to `refund(payment_ref: str) -> RefundResult`, using an application-owned result type.

#### 6. The header comment's architecture claim doesn't match the code

**Severity:** Informational
**Location:** `subject.py:4-6`
**Move:** #1 Dependency direction
**Confidence:** High

The comment says this is ports and adapters, with ports in the application layer. The directory layout follows that, but the dependency graph doesn't (Findings 1 and 2). Readers will trust the comment and assume the core is vendor-neutral. Either fix the code to match the claim, or soften the comment until it does.

**Recommendation:** Once the findings above are fixed, consider an import-linter rule such as "`checkout.application` must not import `stripe`" so the boundary is enforced automatically.

---

## What Looks Good

- **Directory layout matches the intended layering.** Ports and use cases live in `application/`, and the vendor adapter lives in `infrastructure/`. The structure is right; only the dependencies leak.
- **The adapter depends inward.** `StripeGateway` imports and implements the application's `PaymentGateway`, so infrastructure → application is the correct direction.
- **Constructor injection.** `PlaceOrder` receives a `PaymentGateway` rather than building one, so the composition root can wire in different implementations once the port is truly neutral.
- **Vendor construction stays in the adapter.** The API key and `StripeClient` setup are confined to `StripeGateway`.
- **`CheckoutResult` is vendor-neutral.** It has plain `ok`, `payment_ref`, `decline_reason` and `needs_review` fields, which is the right outward-facing contract. The port should follow the same approach.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Port's signature uses Stripe SDK types; application core depends on vendor | Structural | `subject.py:14,17-24` | High |
| 2 | `PlaceOrder` reads Stripe exceptions, statuses and object graph directly | Structural | `subject.py:30,48-58` | High |
| 3 | Use case relies on adapter's unstated `expand: ["latest_charge"]` | Coupling | `subject.py:56-57,80` | High |
| 4 | Decline/error contract sits outside the port | Coupling | `subject.py:17-24,48-51` | Medium |
| 5 | `refund` takes a full Stripe object instead of an ID | Minor | `subject.py:24,84-85` | High |
| 6 | Header comment's architecture claim doesn't match the code | Informational | `subject.py:4-6` | High |

---

## Overall Assessment

This change doesn't keep the codebase structurally sound as it stands. It has the folders and class names of ports and adapters, but not the dependency inversion that makes the pattern worth having. The port and the use case both depend on the Stripe SDK, so the abstraction protects nothing. Swapping providers, testing business rules without Stripe, or absorbing an SDK upgrade would all mean editing the application layer.

The single most important concern is that **`PaymentGateway` is defined in Stripe's types** (Finding 1). Findings 2–4 follow from it.

The good news is that this can be fixed in place without restructuring. The overall structure is already right. The fix is:
1. Add application-owned result, risk and decline types to `ports.py`.
2. Move all Stripe-to-domain translation (exceptions, statuses, risk levels, the expand parameter) into `StripeGateway`.
3. Remove `import stripe` from both application modules.
