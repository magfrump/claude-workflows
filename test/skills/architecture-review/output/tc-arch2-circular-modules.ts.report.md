# Architecture Review: subject.ts (storefront `customers` / `billing` / `checkout`)

**Scope:** `subject.ts`, a single file that joins five module files using `// ==== file: ... ====` markers. I treated the whole file as the diff.
**Date:** 2026-11-19
**User goal:** Judge whether this change keeps the codebase structurally sound.

> ⚠️ **No code fact-check report provided.** Architectural claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

**Scope check:** In scope. The diff adds module structure (`src/customers`, `src/billing`, `src/checkout`), public APIs (each module's `index.ts`), and data models (`Customer`, `Invoice`).

**Trust-boundary cross-reference:** Not run. There is no `docs/reviews/security-review-*.md` in the repository.

---

## Dependency Map

```
src/checkout/placeOrder.ts ──► src/customers (canPlaceOrder)
                           └─► src/billing   (issueInvoice)

src/customers/customer.ts  ──► src/billing   (outstandingBalanceCents)
src/billing/invoice.ts     ──► src/customers (getCustomer)
```

- `checkout` is the orchestrating layer. Its dependencies point the right way, into the two feature modules.
- `customers` and `billing` depend on each other through their `index.ts` barrels. That is a **direct two-module cycle**.
- The file header describes them as two separate feature modules, each with its own public API. Because of the cycle, they cannot be built, tested or reasoned about apart from each other.

---

## Findings

#### 1. Circular dependency between `customers` and `billing`

**Severity:** Structural
**Location:** `subject.ts:11` (`src/customers/customer.ts`) and `subject.ts:42` (`src/billing/invoice.ts`)
**Move:** #1 Map the dependency direction; #7 Measure the coupling surface
**Confidence:** High

`customers/customer.ts` imports `outstandingBalanceCents` from `../billing`, and `billing/invoice.ts` imports `getCustomer` from `../customers`. The result:

- Neither module can be unit-tested, extracted or replaced without bringing the other along.
- Any change to either public surface can ripple back to its own source.
- The cycle runs through barrel files, so it only works at runtime because both imports are used inside function bodies, not at module-evaluation time. Adding one top-level use (a constant computed from an import, a class that extends an imported base, an eagerly built registry) will produce `undefined` bindings or TDZ errors that depend on import order and are hard to diagnose.

The two-module layout the file header describes is, in practice, one module.

**Recommendation:** Break the cycle by moving the credit-check policy out of `customers` (see Finding 2). After that, `customers` becomes a leaf, and `billing → customers` and `checkout → {customers, billing}` form an acyclic graph.

#### 2. Credit-limit policy sits in `customers` but needs billing data

**Severity:** Structural
**Location:** `subject.ts:32-36` (`canPlaceOrder` in `src/customers/customer.ts`)
**Move:** #2 Assess responsibility boundaries; #4 Check for layer violations
**Confidence:** High

`canPlaceOrder` combines three things: customer standing (`suspended`, `creditLimitCents`), billing state (outstanding balance) and order intent (`orderCents`). That is an ordering policy, not a customer-record concern. Putting it in `customers` is the only reason `customers` imports `billing`, so this misplacement is the root cause of Finding 1.

It also gives `customers` a second reason to change. Any change to credit rules (pending orders, grace periods, per-tier limits) now edits the customer-records module and may pull in more billing APIs.

`checkout` already depends on both modules and is the only caller, which makes it the natural owner.

**Recommendation:** Move `canPlaceOrder` into `src/checkout`, for example as a `creditPolicy.ts` there, built from `getCustomer` and `outstandingBalanceCents`. Remove it from `customers/index.ts`. `customers` then exposes only record access.

#### 3. `getCustomer` returns the stored object by reference

**Severity:** Coupling
**Location:** `subject.ts:20-30` (`getCustomer` / `saveCustomer`)
**Move:** #3 Audit the module boundary; #7 Measure the coupling surface
**Confidence:** Medium

`getCustomer` returns the object held in the private `customers` map. Any consumer, including `billing` and `checkout`, can change `suspended` or `creditLimitCents` directly without going through `saveCustomer`.

The module's real contract is therefore "shared mutable state," not "read and save through an API." Swapping the `Map` for a database-backed repository would silently change behaviour for any caller that relies on in-place mutation. That fails the test of whether the implementation can be replaced behind the same interface. `Invoice` objects in `billing` have the same exposure (`issueInvoice` returns the stored object).

**Recommendation:** Return copies or `Readonly<Customer>` / `Readonly<Invoice>`. Make all state changes go through explicit functions (`saveCustomer`, `markPaid`, a future `suspendCustomer`).

#### 4. `Invoice.billingEmail` copies customer data with unstated semantics

**Severity:** Minor
**Location:** `subject.ts:49`, `subject.ts:55-61`
**Move:** #3 Audit the module boundary (data model)
**Confidence:** Medium

`Invoice` stores `billingEmail`, copied from `Customer.email` when the invoice is issued. This is the only reason `issueInvoice` calls `getCustomer`, so `billing` depends on the whole `Customer` shape to read one field (stamp coupling).

Copying can be correct: an invoice often should record the address at issue time. But the data model doesn't say whether this is a deliberate historical snapshot or a cache that is supposed to stay in sync. Downstream consumers of `Invoice` will each assume one or the other.

**Recommendation:** If the copy is intended, document it as an issue-time snapshot. Also consider having the caller (`checkout`) pass `billingEmail` into `issueInvoice`. That leaves `billing` depending only on simple data and removes its import of `customers`, so `billing` becomes a leaf too.

#### 5. Module-level singleton stores leave no seam for substitution

**Severity:** Informational
**Location:** `subject.ts:20`, `subject.ts:52`
**Move:** #1 Map the dependency direction; #8 Evaluate extension points
**Confidence:** Medium

Both modules keep their state in module-scoped constants (`const customers = new Map`, `const invoices = []`), and their exported functions close over those constants. There is no repository interface or injection point, so moving to real persistence means rewriting every exported function. Tests also share global state across cases.

This is fine for a prototype, but this diff sets the pattern that later modules will copy.

**Recommendation:** When persistence arrives, add a small repository interface per module and have checkout or the composition root wire it in. It doesn't need to block this change.

#### 6. `placeOrder` exposes billing's `Invoice` type through an inferred return type

**Severity:** Informational
**Location:** `subject.ts:85`
**Move:** #3 Audit the module boundary
**Confidence:** Low

`placeOrder` has no declared return type, so it returns `Invoice` by inference. Every caller of checkout is then coupled to billing's internal data shape, and changes to `Invoice` spread past checkout without anyone noticing. Separately, `export { Customer, ... }` and `export { Invoice, ... }` re-export interfaces as values. Under `isolatedModules` / `verbatimModuleSyntax` these should be `export type`.

**Recommendation:** Declare an explicit return type, such as `Invoice` deliberately or a smaller `OrderConfirmation`. Use `export type` for interface re-exports.

---

## What Looks Good

- **Barrel-based public surfaces.** Each module exposes its API through `index.ts`, and cross-module imports go through the barrels (`../billing`, `../customers`) rather than reaching into internal files. The boundaries are clear, which made the cycle easy to see.
- **The orchestration layer is in the right place.** `checkout/placeOrder.ts` coordinates the two feature modules without either knowing about checkout. Its dependencies point the right way.
- **Storage is private.** The `customers` map and `invoices` array are not exported. The weakness is the references returned to callers (Finding 3), not the storage itself.
- **Small, focused files.** Apart from `canPlaceOrder`, each module sticks to one responsibility: records versus invoices.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Circular dependency `customers` ↔ `billing` | Structural | `subject.ts:11, 42` | High |
| 2 | Credit-limit policy sits in `customers` but needs billing data | Structural | `subject.ts:32-36` | High |
| 3 | `getCustomer` returns the stored object by reference | Coupling | `subject.ts:20-30` | Medium |
| 4 | `billingEmail` copies customer data with unstated semantics | Minor | `subject.ts:49, 55-61` | Medium |
| 5 | Module-level singleton stores leave no seam for substitution | Informational | `subject.ts:20, 52` | Medium |
| 6 | Inferred return type exposes `Invoice` through checkout; interface re-exports should be `export type` | Informational | `subject.ts:85, 39, 79` | Low |

---

## Overall Assessment

As written, this change does **not** keep the codebase structurally sound. It sets up `customers` and `billing` as separate modules, then makes them depend on each other. That cancels the separation and leaves a runtime cycle that is fragile to import order.

It can be fixed without restructuring, because the cause is one misplaced function. `canPlaceOrder` is an ordering policy, not a customer-record concern. Moving it into `checkout`, which already depends on both modules and is its only caller, makes `customers` a leaf and removes the cycle. Optionally, also have `checkout` pass `billingEmail` into `issueInvoice` so `billing` becomes a leaf too.

The most important concern is the `customers` ↔ `billing` cycle. Fix it before merging, and handle the reference-leak issue (Finding 3) before more consumers start relying on in-place mutation.
