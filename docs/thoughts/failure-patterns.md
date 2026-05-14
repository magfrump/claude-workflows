# Failure Pattern Library

> Append-only one-line log of root-caused bugs from `workflows/bug-diagnosis.md`.
> Step 2 of each diagnosis greps this file for the symptom signature as a prior;
> step 8 appends a new entry once the fix is verified. Read the schema below
> before writing a new entry or grep'ing for an existing one.

Last verified: 2026-05-13
Relevant paths: workflows/bug-diagnosis.md

## When to read this file

- **Bug diagnosis step 2** greps this file by symptom keyword (e.g., `null`, `timezone`, `n+1`, `race`, `stale`) to surface prior bugs with the same observable signature. A match is a strong prior on the cause — the recorded fix shape is often the first thing to test.
- **Codebase onboarding** can skim this for institutional debugging memory: recurring failure modes, hot spots, and the fix shapes the project keeps reaching for.

## Schema

Each entry is a single markdown list item with this exact form:

    - **FP-NNN** YYYY-MM-DD symptom:<keywords> cause:<category> fix:<category> ref:<diagnosis-doc-or-commit>

Fields are whitespace-delimited. Use hyphens (not spaces) inside field values so that each `key:value` pair is a single grep-friendly token.

| Field | Example | Notes |
|---|---|---|
| `FP-NNN` | `FP-007` | Sequential, zero-padded to 3 digits. Look at the last entry to pick the next number. Stable forever — cite by ID. |
| `YYYY-MM-DD` | `2026-05-13` | Date the pattern was recorded. |
| `symptom:<keywords>` | `symptom:null-from-parseDate-tz-offset` | Hyphenated tokens drawn from the error message and observable behavior. Pick terms a future `grep` would actually try (root tokens like `null`, `timezone`, `n+1`, `race`, `stale`, plus a discriminator). |
| `cause:<category>` | `cause:incomplete-regex` | Reusable root-cause category. See "Cause vocabulary" — prefer reusing an existing category. |
| `fix:<category>` | `fix:extend-regex` | Reusable fix-shape category. See "Fix vocabulary". |
| `ref:<path-or-sha>` | `ref:docs/working/diagnosis-date-parsing.md` | Diagnosis log path or fix commit SHA — where the full reasoning lives. |

## Cause vocabulary (starter set)

Reuse an existing category when it fits. If none fit, add yours to this list in the same commit so the next diagnosis can reuse it.

- `incomplete-regex` — a pattern omits a valid input case (timezone offset, escape chars, unicode, multiline)
- `n+1-query` — one query per parent row instead of a single eager/batched fetch
- `cache-staleness` — cached value not invalidated when the source mutated
- `race-condition` — concurrent access to shared state without serialization
- `null-deref` — value was unexpectedly null/undefined at use site
- `off-by-one` — boundary condition (loop bound, slice index, range comparison)
- `stale-fixture` — test fixture or seed data drifted from current schema
- `wrong-default` — default value applied where an explicit value was expected
- `lost-error` — exception swallowed, return value not checked, error path unobserved
- `config-drift` — environment/feature-flag/config differs between expected and actual contexts

## Fix vocabulary (starter set)

- `extend-regex` — add missing branches/groups to the pattern
- `remove-eager-load` / `eager-load` — change query planner shape
- `invalidate-cache` — wire cache invalidation to the source mutation
- `serialize-access` — gate concurrent access (mutex, queue, single-writer)
- `null-guard` — handle the missing-value case at the use site
- `upstream-init` — fix where the null came from, not where it crashed
- `fix-boundary` — adjust loop/index/range condition
- `rebuild-fixture` — regenerate fixture to match current schema
- `propagate-error` — stop swallowing the error; surface it to the caller
- `align-config` — sync configuration across environments

## How to grep

```bash
# By symptom keyword (anywhere in the symptom field):
grep -i 'symptom:[^ ]*null' docs/thoughts/failure-patterns.md

# By cause category:
grep 'cause:n+1-query' docs/thoughts/failure-patterns.md

# By fix shape:
grep 'fix:invalidate-cache' docs/thoughts/failure-patterns.md

# By pattern ID:
grep -E '^- \*\*FP-007\*\*' docs/thoughts/failure-patterns.md
```

When citing a matched pattern in a diagnosis log, commit message, or hypothesis, use the form `FP-NNN`. In a bug-diagnosis hypothesis, the source-tag form is `[from prior bug FP-NNN]`.

## Patterns

<!-- Append one line per root-caused bug. Newest at the bottom. Do not edit
     past entries except to fix typos in symptom keywords (which would hurt
     future grep recall). -->

(no patterns recorded yet)
