# Architecture Review: `subject.py` (notify package)

**Scope:** `subject.py`, a new `notify` package concatenated into one file (7 modules, split by `# ---- file:` markers)
**Date:** 2026-11-20
**User goal:** Judge whether this change keeps the codebase structurally sound.

> ⚠️ **No code fact-check report provided.** Architectural claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

**Scope check:** In scope. The diff adds **module structure** (a new package with domain, application and infrastructure layers), **public APIs** (the `ReminderStore`, `Sender` and `Clock` protocols, plus the `SendDueReminders` use case), a **data model** (the `Reminder` entity and an implied `reminders` table) and **cross-cutting wiring** (the composition root in `notify/main.py`).

**Trust-boundary cross-reference:** Off. No `docs/reviews/security-review-*.md` exists in the repository.

---

## Dependency Map

```
notify/main.py  ──►  application/send_due_reminders  ──►  application/ports  ──►  domain/reminder
      │                                                                              ▲
      ├──►  infrastructure/smtp_sender     (stdlib smtplib, email; no notify imports)│
      ├──►  infrastructure/sql_reminders   (stdlib sqlite3) ─────────────────────────┘
      └──►  infrastructure/system_clock    (stdlib datetime only)
```

- **Domain** (`reminder.py`) imports only `dataclasses` and `datetime`. It depends on nothing else in the package.
- **Application** imports only the domain and its own ports. It never imports infrastructure.
- **Infrastructure** adapters either import the domain (`sql_reminders`) or nothing from `notify` at all. They satisfy the protocols by structural typing, so they don't import `ports.py` either.
- **`main.py`** is the only module that knows about concrete adapters.

Every dependency points inward and there are no cycles. This matches the ports-and-adapters layout described in the header comment.

## Findings

#### 1. The rule for "is this reminder due?" lives in two places, and they disagree at the boundary

**Severity:** Minor
**Location:** `subject.py:28-29` (`Reminder.is_due`), `subject.py:75-76` (use case), `subject.py:119` (SQL predicate)
**Move:** #2 Responsibility boundaries / #7 Coupling surface
**Confidence:** High

The domain says a reminder is due when `now >= due_at - lead`, which means `due_at <= now + lead`. The use case also passes `before=now + lead` to the store, and the SQL adapter applies its own check, `due_at < ?`. So the business rule is written once in the domain and again, slightly differently, in the adapter's query. A reminder whose `due_at` falls exactly on `now + lead` passes `is_due` but is never returned by the store.

The bug at that exact boundary is small. The structural problem is that the meaning of "due" now has to be kept in sync across the domain, the use case and every future `ReminderStore` adapter. Any change to the due rule (per-reminder lead times, quiet hours) would mean editing all three.

**Recommendation:** Make the port's contract explicit and minimal. Either the store is a coarse pre-filter whose `before` bound is documented as inclusive or exclusive and the domain stays the authority, or the store is trusted and `is_due` is dropped from the loop. Document which one in the `ReminderStore` docstring so other adapters implement it the same way.

#### 2. The at-least-once delivery guarantee is documented on the wrong abstraction

**Severity:** Minor
**Location:** `subject.py:39-41` (`ReminderStore` docstring), `subject.py:77-79`
**Move:** #3 Module boundary
**Confidence:** High

The `ReminderStore` docstring says delivery is at-least-once because a crash between `send` and `mark_sent` resends the reminder. That guarantee comes from the order of calls in `SendDueReminders.__call__`, not from anything the store does. A reader implementing a new store will find a note that doesn't apply to them, while someone editing the use case (for example, swapping the order to get at-most-once) gets no warning that they are changing a documented guarantee.

**Recommendation:** Move the delivery-semantics note to `SendDueReminders`, the module that actually decides it. If the store needs to say anything, it should only state that `mark_sent` commits durably before returning.

#### 3. Message wording is built in the application layer, and `Sender` is shaped like email

**Severity:** Minor
**Location:** `subject.py:48-49` (`Sender`), `subject.py:77-78`
**Move:** #4 Layer violations / #5 Interface segregation
**Confidence:** Medium

The use case builds the body text itself: `f"Reminder: {subject} at {due_at:%H:%M} UTC"`. The `Sender` port takes `(recipient, subject, body)`, which is email's shape. Adding SMS or push would mean either ignoring `subject` in those adapters or changing the port. Changing the wording, the time format or the language would mean editing the use case. Today, with one channel, this is acceptable and pragmatic.

**Recommendation:** Leave it for now. When a second channel or localization arrives, change `Sender.send` to accept the `Reminder` (or a small `Notification` value) and let each adapter, or a formatter port, do the rendering.

#### 4. The persisted schema and storage format exist only in a docstring

**Severity:** Informational
**Location:** `subject.py:110-123`
**Move:** #3 Module boundary (data model)
**Confidence:** Medium

`SqlReminderStore` assumes a `reminders(id, recipient, subject, due_at TEXT, sent INTEGER)` table. It also relies on `due_at` being stored as ISO-8601 text with a `+00:00` offset, because its `<` comparison works only if text order equals time order. Nothing in the diff creates that table or enforces that format.

Whoever writes reminders into this database is now bound by this contract without anything in code to point to. A row written with `Z` or with no offset would compare wrongly in the query, or make `Reminder.__post_init__` raise.

**Recommendation:** Put a schema definition or migration next to the adapter, and keep the `+00:00` text-format rule in that one place, preferably in the code that writes reminders.

#### 5. The composition root mixes environment config with a hard-coded value

**Severity:** Informational
**Location:** `subject.py:149-155`
**Move:** #4 Layer violations (configuration loading)
**Confidence:** Medium

`NOTIFY_DB` and `SMTP_HOST` come from the environment, but the sender address `"reminders@example.org"` is a literal. This is the correct place for wiring. It just sets an uneven pattern for configuration loading that later additions will copy.

**Recommendation:** Read `from_addr` from the environment too, or collect all settings into one small config object read in `build()`.

## What Looks Good

- **The dependency rule is fully respected.** The domain and application layers import nothing from infrastructure. `sqlite3`, `smtplib` and the system clock appear only in adapters and the composition root.
- **The ports are small and role-specific.** `ReminderStore` has two methods, and `Sender` and `Clock` have one each. No adapter has to implement anything it doesn't use.
- **Time is injected through `Clock`.** This keeps the use case deterministic and testable without patching.
- **The UTC rule is enforced in the domain.** `Reminder.__post_init__` checks it, so adapters can't produce a `Reminder` with a naive or non-UTC time.
- **The `Protocol` types are satisfied structurally**, so adapters don't import application code. This keeps the infrastructure → application edge out of the graph.
- **Wiring lives in a single composition root** (`main.py`), which is the only place concrete types are chosen.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | "Due" rule written in domain and SQL adapter; they differ at the boundary | Minor | `subject.py:28-29, 75-76, 119` | High |
| 2 | At-least-once note sits on `ReminderStore` but is decided by the use case | Minor | `subject.py:39-41, 77-79` | High |
| 3 | Message wording in use case; `Sender` port shaped like email | Minor | `subject.py:48-49, 77-78` | Medium |
| 4 | Schema and timestamp text format exist only in a docstring | Informational | `subject.py:110-123` | Medium |
| 5 | Hard-coded sender address next to env-driven config | Informational | `subject.py:149-155` | Medium |

## Overall Assessment

The change is structurally sound. It sets up a clean ports-and-adapters design worth keeping as the pattern for this package. Dependencies point inward, the protocols are small, side effects sit behind injected ports, and wiring happens in one place. Nothing reaches Structural or Coupling severity. Every finding can be fixed in place without restructuring.

The most important concern is Finding 1. The rule for what counts as "due" is written in both the domain and the store's query, and the two already disagree at the boundary. Each new store adapter or change to the scheduling rules would add to that drift. Before more adapters are written, decide which layer owns the rule and spell out the `ReminderStore.pending` contract.
