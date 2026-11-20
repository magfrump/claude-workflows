> ⚠️ **No code fact-check report provided.** Architectural claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

# Architecture Review: `subject.py` (new `notify` package)

**Scope:** `subject.py`, which holds seven concatenated modules of a new `notify/` feature package, reviewed as the full change
**Date:** 2026-11-19
**User goal:** Judge whether this change keeps the codebase structurally sound.

**Scope check:** This change is in scope under three categories. It adds new modules (module structure), new public classes and Protocol ports (public APIs), and a new `Reminder` entity plus a `reminders` table it relies on (data models). It does not touch cross-cutting concerns beyond its own composition root.

**Trust-boundary cross-reference:** I found no `docs/reviews/security-review-*.md`, so this step was skipped.

## Dependency Map

```
main.py ──► application.send_due_reminders ──► application.ports ──► domain.reminder
   │                                                                      ▲
   └──► infrastructure.{smtp_sender, sql_reminders, system_clock} ────────┘ (sql_reminders only)
```

- `domain.reminder` depends only on the standard library. It is the most stable module.
- `application.ports` and `send_due_reminders` depend only on the domain and on `typing`/`datetime`. Neither imports any infrastructure code.
- Infrastructure adapters depend on the domain (`sql_reminders`) or on nothing in the project (`smtp_sender`, `system_clock`). They satisfy the ports structurally, through `Protocol`, without importing them.
- `main.py` is the only module that knows about concrete adapters.

Every dependency points inward and there are no cycles. The comment at the top of the file says the design is "ports and adapters", and the import graph matches that.

## Findings

#### 1. The "already sent" rule exists only in the SQL schema, and the model can't express it

**Severity:** Structural
**Location:** `subject.py:17-24` (`Reminder`), `subject.py:34-35` (`ReminderSource`), `subject.py:103` (`WHERE sent = 0`)
**Move:** #2 Responsibility boundaries, #5 Interface segregation / port design
**Confidence:** High

The rule "a reminder is sent once" lives only in the adapter's query (`sent = 0`). Nothing in the domain, the ports or the use case represents it. `ReminderSource` is read-only, so the use case can't tell the source that a reminder went out. `Reminder` also has no identity field, so even a new `mark_sent(...)` port would have nothing reliable to point at. As written, nothing sets `sent = 1`, so every run re-sends every pending reminder. Fixing that needs coordinated changes to the entity, the port, the use case and every adapter. A second adapter (for example in-memory or an HTTP API) would have to rediscover the rule from the SQL. This is a lifecycle business rule placed in infrastructure, and the data model is missing the identity it needs.

**Recommendation:** Give `Reminder` an identity (`id`). Then either add an acknowledgment operation such as `mark_sent(reminder_id)` to the port, or split it into a `ReminderSource` plus a `ReminderLedger`/`SentRecorder` port. The use case should call it after `Sender.send` succeeds, so the send-once policy is stated in the application layer and adapters only store it.

#### 2. Timezone handling for `datetime` isn't stated in the domain or port contracts

**Severity:** Coupling
**Location:** `subject.py:21`, `subject.py:35`, `subject.py:43`, `subject.py:104-107`, `subject.py:116`
**Move:** #6 Substitutability, #7 Coupling surface
**Confidence:** Medium

`Clock.now()`, `ReminderSource.pending(before=...)` and `Reminder.due_at` are all typed only as `datetime`. Nothing says whether they are timezone-aware, or in which zone. The adapters chose differently and implicitly:
- `SystemClock` returns aware UTC.
- `SqlReminderSource` builds `due_at` from whatever ISO string is stored, which could be naive or have any offset.
- `SqlReminderSource` also compares `before.isoformat()` as a string against the stored text.

So whether the adapters can stand in for each other depends on an unwritten agreement about storage format. Swap the clock or the store and you may get a `TypeError` in `is_due` or wrong comparisons. The detailed failure modes are a correctness matter for code-review. The structural point is that the contract the ports define is missing a field everyone depends on.

**Recommendation:** Define the contract in the domain. Either require aware UTC datetimes and validate in `Reminder.__post_init__`, or introduce a small `Instant`/UTC type. Document the same requirement on `Clock` and `ReminderSource`, so each adapter normalises at its edge.

#### 3. The due-time rule is written twice, in two layers

**Severity:** Minor
**Location:** `subject.py:23-24`, `subject.py:63-64`, `subject.py:103`
**Move:** #2 Responsibility boundaries
**Confidence:** High

`Reminder.is_due` (`now >= due_at - lead`) holds the business rule. The use case also turns it into a query bound (`before=now + lead`), and the SQL adapter applies its own version (`due_at < ?`, which is strict while the domain check is inclusive). The domain check after fetching makes the result correct, but the rule now lives in three places with slightly different edge behaviour. If the lead-time policy changes (for example a per-reminder lead), all three must change together.

**Recommendation:** Treat `pending(before=...)` as a coarse pre-filter only, and say so in the port's docstring. Alternatively, have the domain provide the cutoff (such as `Reminder.cutoff(now, lead)`) so the boundary is computed in one place.

#### 4. Message wording is built inside the use case

**Severity:** Minor
**Location:** `subject.py:65-66`
**Move:** #2 Responsibility boundaries, #8 Extension points
**Confidence:** Medium

`SendDueReminders` hard-codes the body text and the `%H:%M` time format. That puts presentation and locale (wording, time format, display timezone) in the application layer. Changing the wording, localising, or adding HTML or SMS formats would mean editing the use case rather than plugging in a new piece. The `Sender` port signature (`recipient, subject, body`) also assumes email, so a non-email channel would have to ignore or reinterpret `subject`.

**Recommendation:** This is fine for a first version. If more channels or locales are likely, inject a `ReminderFormatter` port, or pass the `Reminder` to the sender and let each channel adapter render it.

#### 5. Configuration is half-hard-coded in the composition root

**Severity:** Informational
**Location:** `subject.py:129-135`
**Move:** #1 Dependency direction (composition root)
**Confidence:** High

Reading the environment in `main.py` is the right place for it. However, the sender address `"reminders@example.org"` is a literal while the host comes from `SMTP_HOST`. The SQLite connection is also opened with no owner to close it. Both are small, but a composition root tends to become the template later features copy.

**Recommendation:** Read all deployment settings from config in one place (for example a small `Settings` dataclass), and make the connection's lifetime explicit with a context manager or a `close()` path.

## What Looks Good

- **Dependencies point the right way.** The domain and application layers never import `smtplib`, `sqlite3` or the system clock. Infrastructure could be replaced without touching the use case.
- **Ports are small and role-specific.** There are three single-method `Protocol`s. No adapter carries methods it doesn't need, and fakes for tests are trivial.
- **Adapters satisfy the ports structurally, without importing them,** so infrastructure isn't tied to the application module's layout.
- **Time is injected.** Because `Clock` is a port, the use case is deterministic under test.
- **There is a single composition root.** `main.py` is the only place that knows about concrete classes.
- **The entity is frozen,** and its behaviour (`is_due`) sits with its data.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Send-once rule only exists in SQL; `Reminder` has no identity and the port has no acknowledge operation | Structural | `subject.py:17-35, 103` | High |
| 2 | Timezone handling for `datetime` not stated in domain/port contracts | Coupling | `subject.py:21, 35, 43, 104-116` | Medium |
| 3 | Due-time rule duplicated across domain, use case and SQL with different edge behaviour | Minor | `subject.py:23-24, 63-64, 103` | High |
| 4 | Message wording and time format hard-coded in the use case; email-shaped `Sender` port | Minor | `subject.py:65-66, 39` | Medium |
| 5 | Mixed config sources and an unowned connection in the composition root | Informational | `subject.py:129-135` | High |

## Overall Assessment

Overall, this change sets up a sound structure. The ports-and-adapters layering it claims is real: dependencies point inward, the ports are minimal, and the composition root is clean, so the package is a good pattern to copy. The main problem is a gap in the data model and port design rather than a layering violation. The reminder's "sent" state, a core business rule, has no representation in the domain or the application layer, and `Reminder` has no identity. As a result the feature can't avoid duplicate sends without changing all layers at once. All the issues can be fixed in place with no restructuring:
1. Add an id to `Reminder` and a send-acknowledgment operation to a port, and call it from the use case.
2. Pin down the timezone contract in the domain.

Do both before other adapters or consumers start depending on the current shapes.
