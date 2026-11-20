# Architecture Review: subject.py (order service package)

**Scope:** `subject.py`, which contains six modules from the `orders` package (`domain/model.py`, `domain/pricing.py`, `infrastructure/pg_discounts.py`, `infrastructure/pg_orders.py`, `application/ports.py`, `application/place_order.py`). The whole file is treated as the change under review.
**Date:** 2026-11-19
**User goal:** Judge whether this change keeps the codebase structurally sound.

> ⚠️ **No code fact-check report provided.** Architectural claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

**Scope check:** In scope. The file adds new modules, a new port (`OrderRepository`), a persisted data model (`Order` and `LineItem` mapped to the `orders` and `order_items` tables), and configuration loading. **Trust-boundary cross-reference:** Skipped. No `docs/reviews/security-review-*.md` exists.

---

## Dependency Map

The header comment (`subject.py:3-6`) says the architecture is layered ports and adapters. In that style, dependencies should point inward: infrastructure → application → domain.

| Module | Depends on | Direction |
|---|---|---|
| `domain/model.py` | stdlib only | ✅ pure core |
| `domain/pricing.py` | `domain.model`, **`infrastructure.pg_discounts`**, `os.environ` | ❌ core → adapter |
| `infrastructure/pg_discounts.py` | `psycopg` | ✅ adapter |
| `infrastructure/pg_orders.py` | `psycopg`, `domain.model` | ✅ adapter → core |
| `application/ports.py` | `domain.model` | ✅ |
| `application/place_order.py` | `application.ports`, `domain.model`, `domain.pricing` | ✅ directly, but ❌ transitively (through `pricing`, it reaches `psycopg` and env config) |

The order-persistence path follows the stated design: the port is in the application layer and the adapter implements it structurally. The pricing and discount path breaks it. The domain layer imports a PostgreSQL adapter, so every caller of pricing, including the use case, now depends on the database too.

---

## Findings

#### 1. Domain pricing service imports and builds a PostgreSQL adapter

**Severity:** Structural
**Location:** `subject.py:41-49` (`orders/domain/pricing.py`)
**Move:** #1 Dependency direction, #4 Layer violations
**Confidence:** High

`PricingService` imports `orders.infrastructure.pg_discounts.PostgresDiscountTable` and creates it in its own `__init__`. That makes the most stable layer (the business rules) depend on the least stable one (a psycopg-backed SQL adapter). As a result:

- `orders.domain` can't be imported, unit-tested or reused without `psycopg` installed and a reachable database.
- Moving discounts to a cache, an HTTP pricing service or a different table means editing domain code.
- `PlaceOrder` is tied to Postgres through this import even though it was carefully written against a `Protocol` for orders.

This reverses the direction the header comment says the package follows. It is also the only inward-to-outward import in the package, so this is the point where the layering starts to erode.

**Recommendation:** Define a discount port next to the code that uses it, for example `class DiscountPolicy(Protocol): def percent_for(self, customer_id: UUID) -> Decimal: ...` in `orders/domain/`. It belongs in the domain layer, not `application/ports.py`, because the domain must not import from the application layer. Then have `PricingService.__init__(self, discounts: DiscountPolicy)` receive it. `PostgresDiscountTable` already matches that shape structurally, so the adapter doesn't need to change.

#### 2. Configuration loading and connection setup inside a domain constructor

**Severity:** Coupling
**Location:** `subject.py:37, 49` (`orders/domain/pricing.py`)
**Move:** #2 Responsibility boundaries (cross-cutting concern: configuration)
**Confidence:** High

`PricingService()` reads `os.environ["ORDERS_DSN"]` and opens a database connection when it is constructed. So the domain service has three jobs: business rule, configuration source and resource lifecycle. Constructing it has a side effect: it raises `KeyError` if the variable is missing and makes a network call. This is separate from the import problem in finding 1. Even if the import were moved behind a factory, environment lookup here means configuration is spread across layers instead of being set up in one place. Every new adapter would then copy the pattern.

**Recommendation:** Move environment reading and adapter construction into a single composition root, such as `orders/main.py` or `orders/bootstrap.py`. That root builds `PostgresDiscountTable(dsn)`, `PricingService(discounts)`, `PostgresOrderRepository(dsn)` and `PlaceOrder(...)`. The domain should take only what it is given.

#### 3. The order total is set from outside the aggregate, so the domain doesn't enforce it

**Severity:** Minor
**Location:** `subject.py:28-33` (`domain/model.py`), `subject.py:125-126` (`application/place_order.py`)
**Move:** #2 Responsibility boundaries, #3 Module boundary
**Confidence:** Medium

`Order` is a mutable dataclass with `total` defaulting to `0`. The use case creates the order and then assigns `order.total` itself. Nothing in the domain links `total` to `items`. Any caller can build an `Order` with a zero or stale total, or change `items` after pricing, and `PostgresOrderRepository.add` will save it to `orders.total` as given. Because `Order` is a persisted contract, the rule "total reflects priced items" now lives in the application layer and has to be repeated by every future use case that creates or edits orders.

**Recommendation:** Make the priced total part of how an `Order` is created. For example, add a factory such as `Order.place(customer_id, items, pricing)` or have `PricingService` return a priced order. Alternatively, make `total` a required constructor argument with no `0` default, and consider `frozen=True` or a tuple for `items`. A small change is enough; this is not a call for a full rich-domain rewrite.

#### 4. Ports and adapters is applied unevenly; the pattern isn't established yet

**Severity:** Informational
**Location:** `subject.py:101-108` (`application/ports.py`), `subject.py:116-120` (`application/place_order.py`)
**Move:** #5 Interface segregation, #8 Extension points
**Confidence:** Medium

`ports.py` defines one narrow, write-only port (`OrderRepository.add`). That is well sized. Discounts, however, have no port, and `PlaceOrder` depends on the concrete `PricingService`. A use case depending on a concrete domain service is normally fine, because domain services are stable. Here it isn't, only because of finding 1. Since this change effectively sets the pattern for the package, the next adapter author has two conflicting examples to copy.

**Recommendation:** After fixing finding 1, document the convention, for example in the header comment or a short ADR (architecture decision record): ports that domain services need live in `domain/`, ports that only use cases need live in `application/ports.py`, and adapters are wired only in the composition root.

#### 5. Each adapter owns its own connection, so there is no shared unit of work

**Severity:** Informational
**Location:** `subject.py:66-67` (`pg_discounts.py`), `subject.py:84-85` (`pg_orders.py`)
**Move:** #7 Coupling surface (cross-cutting concern: transaction and resource management)
**Confidence:** Medium

Each adapter opens a private `psycopg` connection, and they use different transaction modes: `autocommit=True` for discounts, explicit `transaction()` for orders. Structurally, this means transaction boundaries belong to individual adapters rather than to the use case. If a future use case needs to read the discount and write the order atomically, or write orders together with an outbox or event record, the adapter interfaces will have to change. The correctness consequences are outside this review's scope; the structural point is where the transaction boundary sits.

**Recommendation:** When a second write-path use case appears, consider injecting a shared connection or a unit-of-work abstraction from the composition root, instead of having each adapter connect from a DSN. Nothing needs to change now.

---

## What Looks Good

- **`domain/model.py` is pure.** It uses only stdlib types, and `LineItem` is a frozen value object with a derived `subtotal`. This is the right foundation for the core.
- **The `OrderRepository` port is in the right place and the right size.** It is a single-method `Protocol` in the application layer, `PostgresOrderRepository` satisfies it structurally without importing it, and the adapter depends inward on `domain.model`. This is ports and adapters done correctly.
- **`PlaceOrder` takes its dependencies through its constructor.** Once `PricingService` stops building its own adapter, the use case will be fully testable with fakes and won't need any changes.
- **SQL stays in the infrastructure layer.** No query text leaks into the domain or application modules.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Domain pricing service imports and builds a PostgreSQL adapter | Structural | `subject.py:41-49` | High |
| 2 | Configuration loading and connection setup inside a domain constructor | Coupling | `subject.py:37, 49` | High |
| 3 | Order total set from outside the aggregate, not enforced by the domain | Minor | `subject.py:28-33, 125-126` | Medium |
| 4 | Ports and adapters applied unevenly; pattern not established | Informational | `subject.py:101-120` | Medium |
| 5 | Each adapter owns its own connection; no shared unit of work | Informational | `subject.py:66-67, 84-85` | Medium |

Mapped to the code-review rubric: 🔴 Must Fix is #1, 🟡 Must Address is #2, and 🟢 Consider is #3 to #5.

---

## Overall Assessment

The change is **mostly sound, with one structural defect that undoes the architecture it claims to follow.** The order-persistence path shows the team knows the pattern: a pure model, a narrow `Protocol` port, an inward-pointing adapter and constructor injection. But `orders/domain/pricing.py` imports `PostgresDiscountTable` and reads `ORDERS_DSN` itself. That makes the domain layer depend on psycopg, a live database and environment configuration, and through it so does the `PlaceOrder` use case. This is the single most important concern.

It can be fixed in place, and cheaply. Add a `DiscountPolicy` protocol in `domain/`, inject it into `PricingService`, and move environment reading and wiring into a composition root. No adapter changes are needed, and nothing needs restructuring. Fix it before merge: it is the first outward import from the domain, and if it stays it becomes the example other modules will copy. The order-total point (finding 3) is worth handling while the pricing code is open, because it moves an invariant of a persisted contract back into the domain.
