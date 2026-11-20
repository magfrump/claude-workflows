# API Consistency Review: subject.go (dead-letter queue config field)

**Scope:** `subject.go`. The diff is the two `BEGIN/END CHANGE UNDER REVIEW` blocks (lines 24–26 and 57–61).
**Date:** 2026-11-19

> ⚠️ **No code fact-check report provided.** API documentation claims have not been independently verified against implementation. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

---

## Baseline Conventions

The repo has only one source file, `subject.go`. There are no tests, sample `worker.yaml` files or docs. The baseline therefore comes from the existing `Config` schema and the `Load` / `applyDefaults` / `validate` flow.

- **Consumers:** The package doc (lines 3–4) says operators maintain their own `worker.yaml` files and the loader is shared by every deployment. The real public contract is the YAML schema, and any config that loads today is a config consumers rely on.
- **YAML keys:** snake_case throughout (`broker_url`, `queue_name`, `poll_interval`, `visibility_ttl`, `metrics_addr`, `shutdown_timeout`).
- **Go field names:** PascalCase, mapped directly to the YAML key (`QueueName` ↔ `queue_name`). Fields that hold the name of a queue use a `Name` suffix: `QueueName string`.
- **Required vs. defaulted:** Only the two connection essentials, `broker_url` and `queue_name`, are required. Every tuning or optional knob gets a default in `applyDefaults` (`concurrency`, `poll_interval`, `visibility_ttl`, `metrics_addr`, `shutdown_timeout`).
- **Error format:** `config: <yaml_key> is required` or `config: <yaml_key> must be ..., got ...`. Errors use the `config:` prefix and the YAML key name, not the Go field name.
- **Versioning:** The schema has no `version` key and no migration mechanism.

---

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `dead_letter_queue` | YAML config key | `queue_name`, `broker_url`, `metrics_addr` | `subject.go:17-23` | Partly consistent. snake_case matches, but the sibling that holds a queue's name is `queue_name` (with `_name`). This key holds the same kind of value without the suffix. |
| `DeadLetterQueue` | Go struct field (exported) | `QueueName`, `BrokerURL`, `MetricsAddr` | `subject.go:17-22` | Partly consistent. PascalCase and the mapping to the YAML key match, but the sibling is `QueueName`, not `Queue`. |
| `"config: dead_letter_queue is required"` | error message | `"config: broker_url is required"`, `"config: queue_name is required"` | `subject.go:49,52` | Consistent. Same prefix, same YAML-key wording, same `errors.New` style. |

---

## Findings

#### 1. A new required config key makes every existing `worker.yaml` fail to load

**Severity:** Breaking
**Location:** `subject.go:57-61` (also `subject.go:25`, `subject.go:29-45`)
**Move:** #3 Trace the consumer contract; #6 Assess the versioning impact
**Confidence:** High

`validate()` now rejects any config where `dead_letter_queue` is empty. `applyDefaults()` doesn't set a value for it, so every config file written before this change will fail in `Load`. That includes every operator-maintained `worker.yaml` the package doc mentions. Those workers will exit at startup with `config: dead_letter_queue is required` as soon as they upgrade. Adding a required field to the input schema is a breaking change under move #6.

It also goes against the file's own pattern. Only the connection essentials (`broker_url`, `queue_name`) are required, and every added knob gets a default in `applyDefaults`. The schema has no version key, so operators get no migration path or warning before the hard failure.

**Recommendation:** Make the field optional to keep this change backward-compatible. Two ways to do it:
- Treat `""` as "dead-lettering disabled" and drop the required check.
- Set a default in `applyDefaults`, for example `c.QueueName + ".dlq"`. Note this only works if defaulting runs while `QueueName` is known and the default queue exists on the broker.

If a DLQ really must be mandatory, ship that as an announced breaking change with a release note and a migration step, not as a silent new requirement.

#### 2. The key and field omit the `_name` / `Name` suffix that the sibling queue field uses

**Severity:** Minor
**Location:** `subject.go:25`
**Move:** #2 Check naming against the grain
**Confidence:** Medium

Precedent: queue-name fields use a `Name` / `_name` suffix (`QueueName` / `yaml:"queue_name"`), used in `subject.go:18`

The new field holds the same kind of value as `queue_name`: a string naming a queue on the broker. It's spelled `dead_letter_queue` / `DeadLetterQueue`, though. An operator who has learned `queue_name` might reasonably guess `dead_letter_queue_name`. The shorter form could also suggest a structured value, like a nested queue config block, rather than a plain name. The impact is small because there's only one sibling to compare against. Once this key ships in operator files it becomes the precedent, so it's cheapest to settle now.

**Recommendation:** Consider `dead_letter_queue_name` / `DeadLetterQueueName` to mirror `queue_name` / `QueueName`. If the team prefers the shorter form, make that a deliberate choice, because future queue-name keys will copy it.

#### 3. The meaning of an empty dead-letter queue value is undefined

**Severity:** Informational
**Location:** `subject.go:25`, `subject.go:58`
**Move:** #8 Verify the nullability contract
**Confidence:** Medium

As written, `""` is invalid, so the question doesn't come up. If finding 1 is fixed by making the field optional, though, `""` gets a meaning: either "disabled" or "use the default". That needs to be stated in a comment on the field. None of the existing `Config` fields have doc comments, but each one's empty-value behavior is visible in `applyDefaults`. A disabled-when-empty field would be the first one whose empty value means "off" rather than "use the default", and that difference isn't obvious from the code. The diff also doesn't guard against `dead_letter_queue` being set equal to `queue_name`, which would send failed messages back into the main queue. That's worth a validation check, but it's a behavior concern more than a consistency one.

**Recommendation:** Add a one-line comment on the field describing what an empty value does. Optionally, reject `DeadLetterQueue == QueueName` in `validate()` using the existing error style, for example `config: dead_letter_queue must differ from queue_name`.

---

## What Looks Good

- **YAML key casing:** `dead_letter_queue` is snake_case like every other key.
- **Error message:** `config: dead_letter_queue is required` matches the existing required-field messages exactly: same `config:` prefix, the YAML key rather than the Go name, and `errors.New`.
- **Placement:** The field sits at the end of the struct and the check comes after the existing ones in `validate()`, so existing validation errors still appear in the same order.
- **Mapping:** The Go field name maps cleanly to its YAML tag, like the existing fields.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | New required key breaks all existing `worker.yaml` files | Breaking | `subject.go:57-61` | High |
| 2 | Missing `_name` / `Name` suffix compared with `queue_name` / `QueueName` | Minor | `subject.go:25` | Medium |
| 3 | Empty-value meaning undefined; no guard against DLQ == main queue | Informational | `subject.go:25,58` | Medium |

---

## Overall Assessment

On the surface the change matches the file's conventions: the casing, struct tag style and error wording are all right. The problem is the contract. Every config added so far either is a connection essential or has a default, and this change adds a hard requirement with no default or migration path. Every operator's existing `worker.yaml` will fail to load after the upgrade. This is easy to fix in place: make the field optional by defaulting it or treating empty as disabled, and document what an empty value means. Settling the `_name` suffix question before release would also stop this key from setting an inconsistent precedent for future queue-name keys. As written, the consumer impact is high, because every deployment fails at startup when it picks up this version.
