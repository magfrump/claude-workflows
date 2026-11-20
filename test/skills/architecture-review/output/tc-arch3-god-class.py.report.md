# Architecture Review: `members/application/account_service.py` (subject.py)

> ⚠️ **No code fact-check report provided.** Architectural claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

**Scope:** `subject.py` (new module `members/application/account_service.py`, treated as the full diff)
**Date:** 2026-11-19
**User goal:** Judge whether this change keeps the codebase structurally sound.

**Scope check:** In scope. This is a new module (module structure) that adds a public application service API (public APIs). It also wires configuration, audit logging and feature flags (cross-cutting concerns), and it hard-codes how the `members` and `sessions` tables are laid out (data models).

**Trust-boundary cross-reference:** Not used. There is no `docs/reviews/security-review-*.md` in the repository.

**Context limits:** The repository holds only `subject.py`. The layering described here comes from the module's own header comment (lines 3–8). I could not inspect `members/domain/` or `members/infrastructure/`, so I can't tell whether they exist or what they already provide.

---

## Dependency Map

The header says the architecture is layered: web/worker entry points → `application/` → `domain/`, with `infrastructure/` holding the adapters for database, mail, payments and file storage.

What the module actually imports:

| Dependency | Kind | Layer it belongs to |
|---|---|---|
| `sqlite3` | DB driver | infrastructure (database adapter) |
| `smtplib`, `email.message` | Mail transport | infrastructure (mail adapter) |
| `stripe` | Payment vendor SDK | infrastructure (payments adapter) |
| `reportlab` | PDF rendering | infrastructure / presentation |
| `open("/var/log/...")` | Filesystem | infrastructure (file storage) |
| `os.environ` | Process config | composition root |
| `csv`, `io` | Serialization formats | presentation / export |
| `members.domain.*` | — | **Not imported at all** |
| `members.infrastructure.*` | — | **Not imported at all** |

So the module skips both of the layers it is supposed to sit between. It depends directly on concrete drivers and vendor SDKs, and it depends on nothing in the domain. Entry points (web, worker) will depend on `AccountService`. Through it, they pick up a dependency on every library in the table above.

---

## Findings

#### 1. The application layer talks to infrastructure directly and ignores the adapter layer

**Severity:** Structural
**Location:** `subject.py:17-24`, `30-33`, `40-43`, `72-73`, `96`, `106`, `142`
**Move:** #1 Dependency direction, #4 Layer violations
**Confidence:** High

The header says adapters for database, mail, payments and file storage live in `members/infrastructure/`. This service doesn't use them. It opens its own `sqlite3` connection, runs SMTP sessions itself, calls the `stripe` SDK, and writes to a hard-coded filesystem path. The orchestration logic is therefore welded to these specific technologies. Moving from SQLite to Postgres, from SMTP to a mail API, or from Stripe to another processor would each mean rewriting use-case code, not swapping an adapter. It also means the use cases can't be tested without a real SQLite file, a reachable SMTP host and Stripe credentials. Because this is a new module, it sets the pattern later services will copy, and it undermines the layering the header describes.

**Recommendation:** Define ports in the application or domain layer, for example `MemberRepository`, `SessionStore`, `Mailer`, `PaymentGateway` and `AuditLog`. Implement them in `members/infrastructure/` and inject them through `AccountService.__init__`. The service should import only domain types and those ports.

#### 2. One class owns nine unrelated responsibilities

**Severity:** Structural
**Location:** `subject.py:29-144`
**Move:** #2 Responsibility boundaries
**Confidence:** High

`AccountService` handles:

- credential hashing and registration
- session issuing and purging
- transactional and bulk email
- pricing and charging
- refunds
- PDF receipts
- CSV export
- signup analytics
- feature flags
- audit logging

The section comments already split it into five groups. Each group changes for a different reason and on a different schedule. Marketing changes email copy, finance changes pricing, ops changes the audit sink, and reporting changes the export columns. Every one of those edits touches the same class and the same constructor. Every consumer, including a worker that only sends reminders, then has to build the whole thing, along with SMTP, Stripe and DB configuration. Classes like this tend to grow fastest because they are where everything already lives.

**Recommendation:** Split it by use-case cluster: `RegistrationService`/`AuthService` (register, login, purge sessions), `BillingService` (charge, refund), `MemberNotifications` (welcome, renewal reminders), and `MemberReporting` (CSV, stats, receipt). Feature flags and audit should be injected collaborators, not methods on the service.

#### 3. Business rules sit in the application layer, and the domain layer goes unused

**Severity:** Structural
**Location:** `subject.py:38-39`, `55`, `59`, `76`, `90-92`, `99`
**Move:** #4 Layer violations, #2 Responsibility boundaries
**Confidence:** High

Several business rules are written as inline literals inside use-case methods:

- plan prices (`{"basic": 900, "plus": 1900}`)
- the promo discount (`0.8`)
- membership length (`365` days)
- the renewal-reminder window (`7` days)
- session lifetime (`12` hours)
- the password-hashing scheme, which is copied in both `register` and `login`

None of this is in `members/domain/`, even though the header says that is where business rules belong. Two consequences follow. First, a second caller can't reuse the rules. A renewal worker or admin price-override would have to copy them or go through this god class. Second, the rules can't be tested without the database and Stripe. The duplicated hashing parameters are a drift risk: changing the iteration count in one place silently breaks login for every new account.

**Recommendation:** Move these into domain types, for example a `Plan` value object with pricing, a `Membership.renew()` that computes `renews_at`, a `SessionPolicy`, and one `PasswordHasher`. Have the service call them.

#### 4. The constructor loads configuration and mutates global vendor state

**Severity:** Coupling
**Location:** `subject.py:30-34`
**Move:** #7 Coupling surface, cross-cutting concerns
**Confidence:** High

`__init__` reads `SMTP_HOST`, `STRIPE_KEY` and `FEATURE_FLAGS` straight from the environment and assigns `stripe.api_key`, which is process-global module state. Configuration loading is a composition-root job. Doing it here has three effects:

- Every instantiation needs all three variables, even when the caller only wants `export_members_csv`.
- Creating the service has a hidden global side effect on every other Stripe user in the process.
- Wiring for tests, workers or multi-tenant setups has to go through environment manipulation.

**Recommendation:** Have the entry points (web app and worker startup) read configuration once and pass ready-built collaborators into the service. Keep `stripe.api_key` (or a configured `StripeClient`) inside the payments adapter.

#### 5. Stripe identifiers leak into the public API and the member data model

**Severity:** Coupling
**Location:** `subject.py:89`, `94`, `103`, `105-106`
**Move:** #3 Module boundary
**Confidence:** High

`charge_membership` returns a Stripe `PaymentIntent.id`, and `refund` takes one. Web and worker callers must therefore store and pass around vendor-specific identifiers. The `members` table also has a `stripe_customer` column, which puts the payment vendor into the core member record. If you change processors or add a second one, both the public surface of this service and the member schema have to change, along with every caller holding those IDs.

**Recommendation:** Return a platform-owned `PaymentId`/`ChargeResult`, and keep the vendor ID mapping inside the payments adapter, for example in a `payment_accounts` table or adapter-owned storage. `refund` should accept the platform ID.

#### 6. Schema knowledge is spread across raw SQL throughout the service

**Severity:** Coupling
**Location:** `subject.py:40-43`, `50-52`, `60-63`, `77-79`, `93-100`, `121`, `125-127`, `135-138`
**Move:** #7 Coupling surface (content coupling to the persistence layout)
**Confidence:** High

Nine SQL statements across eight methods hard-code the column names, types and storage conventions of `members` and `sessions`. One example is `monthly_signup_stats`, which relies on `created_at` being an ISO string so that `substr(..., 1, 7)` yields a month. If you rename a column, change timestamp storage, or move sessions to Redis, you'll have to hunt through use-case code. `export_members_csv` also writes a raw cursor straight into the CSV, so the export format is the table layout itself.

**Recommendation:** Hide the persistence layout behind repository methods that return domain objects, such as `find_by_email`, `due_for_renewal(before)` and `signups_by_month()`. Build the CSV from domain or read-model rows, not from a cursor.

#### 7. Audit logging is a hard-coded side effect, not an injected concern

**Severity:** Coupling
**Location:** `subject.py:141-144` (called at `46`, `102`)
**Move:** #2 Responsibility boundaries, cross-cutting concerns
**Confidence:** High

Audit is a concern that cuts across the system, but here it is a public method that writes to the literal path `/var/log/members/audit.log`. Any other service that needs auditing either has to depend on `AccountService` or copy this. The sink can't be changed per environment (tests, containers, a central log service) without editing the code. It is also only called from `register` and `charge_membership`, while `login`, `refund` and `purge_expired_sessions` skip it. That suggests no clear policy for what gets audited.

**Recommendation:** Inject an `AuditLog` port implemented in infrastructure, and decide in one place which use cases emit audit events. Domain events are one option.

#### 8. Presentation and reporting formats are mixed into the use-case service

**Severity:** Minor
**Location:** `subject.py:109-128`
**Move:** #4 Layer violations
**Confidence:** Medium

PDF layout (A4, drawing coordinates, currency formatting) and CSV serialization are output-format concerns. Putting them here makes the application layer depend on `reportlab`, and every change to receipt layout or export columns becomes an edit to the account service. `render_receipt_pdf` also never touches account state. It is a pure formatter that happens to live on this class.

**Recommendation:** Move receipt rendering into a document adapter behind a `ReceiptRenderer` port. Move export and stats into a separate reporting/query service.

#### 9. Feature flags are exposed through the account service

**Severity:** Minor
**Location:** `subject.py:34`, `91`, `131-132`
**Move:** #3 Module boundary
**Confidence:** Medium

`is_enabled` is part of `AccountService`'s public surface even though it has nothing to do with accounts. Callers who want a flag check will start depending on this service for it, which spreads coupling to this class. Separately, the `spring_promo` check inside `charge_membership` ties a time-limited marketing campaign to the core charge flow.

**Recommendation:** Inject a `FeatureFlags` collaborator and drop `is_enabled` from this class. Put promotions in the pricing domain object (Finding 3) so campaigns don't require edits to the billing use case.

#### 10. The plan catalogue is a closed lookup inside the method

**Severity:** Minor
**Location:** `subject.py:90`
**Move:** #8 Extension points
**Confidence:** Medium

Adding a plan means editing `charge_membership`, and an unknown plan surfaces as a raw `KeyError` from inside the use case. With two plans this is tolerable. But plans usually multiply, and other places such as receipts and exports will need the same catalogue.

**Recommendation:** Fold this into the `Plan` domain type from Finding 3, for example a `PlanCatalog` that can later be backed by configuration or the database.

#### 11. Email construction is duplicated and coupled to the transport

**Severity:** Minor
**Location:** `subject.py:68-86`
**Move:** #2 Responsibility boundaries
**Confidence:** Medium

Two methods each build an `EmailMessage` with the same hard-coded sender and manage their own SMTP sessions. Message content, sender identity and transport are all decided in the use-case layer. A change of sender or transport means touching both methods, and any new notification will copy the pattern a third time.

**Recommendation:** Use a `Mailer` port, for example `send(to, template, context)`, and keep templates and sender configuration outside the service.

#### 12. `register` runs its side effects inline and synchronously

**Severity:** Informational
**Location:** `subject.py:44-47`
**Move:** #7 Coupling surface
**Confidence:** Medium

After committing, `register` sends the welcome email and writes the audit log inline. Registration therefore depends on the SMTP host being up and on the audit path being writable. This is a structural observation about temporal coupling between the core write and its follow-on effects. Robustness is code-review's concern.

**Recommendation:** Consider having `register` emit a `MemberRegistered` event, or enqueue the follow-up work for the worker entry point. The header says such a worker already exists.

---

## What Looks Good

- **Use cases are named methods with simple signatures.** `register(email, password) -> int` and `login(...) -> str | None` exchange plain data, which is the loosest kind of coupling (data coupling). Those signatures can survive the refactors above unchanged.
- **The module states its intended layering** in the header. That gives a clear target to refactor toward and documents the convention for later modules.
- **The section comments already mark the right split points.** They map almost one-to-one onto the services proposed in Finding 2.
- **No circular dependencies:** the module imports nothing from the `members` package.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Application layer talks to infrastructure directly, skipping the adapter layer | Structural | `subject.py:17-24, 30-33` | High |
| 2 | One class owns nine unrelated responsibilities | Structural | `subject.py:29-144` | High |
| 3 | Business rules in the application layer; domain layer unused | Structural | `subject.py:38-39, 55, 59, 76, 90-92, 99` | High |
| 4 | Constructor loads env config and mutates global Stripe state | Coupling | `subject.py:30-34` | High |
| 5 | Stripe IDs leak into the public API and member schema | Coupling | `subject.py:89-106` | High |
| 6 | Schema knowledge spread across raw SQL | Coupling | `subject.py:40-138` | High |
| 7 | Audit is a hard-coded file sink, not an injected concern | Coupling | `subject.py:141-144` | High |
| 8 | PDF/CSV/reporting formats mixed into the use-case service | Minor | `subject.py:109-128` | Medium |
| 9 | Feature flags exposed through the account service | Minor | `subject.py:34, 91, 131-132` | Medium |
| 10 | Plan catalogue is a closed lookup inside the method | Minor | `subject.py:90` | Medium |
| 11 | Email construction duplicated and coupled to the transport | Minor | `subject.py:68-86` | Medium |
| 12 | `register` runs its side effects inline and synchronously | Informational | `subject.py:44-47` | Medium |

**Rubric mapping (if used under code-review):** 🔴 Must Fix: 1, 2, 3 · 🟡 Must Address: 4, 5, 6, 7 · 🟢 Consider: 8–12

---

## Overall Assessment

No: this change does not keep the codebase structurally sound. Each line works on its own terms. The problem is that the module contradicts the layered architecture its own header describes. It skips the domain layer entirely, skips the infrastructure adapters, and gathers auth, billing, notifications, documents, reporting, flags and audit into one class built from environment variables. Because it is a new module, the damage is in the precedent: later services will copy this shape, and the web and worker entry points will couple to Stripe, SQLite, SMTP and reportlab through it.

The fix doesn't require restructuring the whole system, only this module before it lands:

1. Extract ports and inject adapters (Findings 1, 4, 7).
2. Move pricing, renewal, session and hashing rules into `members/domain/` (Finding 3).
3. Split the class along the boundaries its section comments already draw (Finding 2).

The most important concern is Finding 1. As long as the service imports `sqlite3`, `smtplib` and `stripe` directly, the stated layering exists only in the header comment.
