# R3: Make `scope` a required field on tasks-round-N.json

## Problem

Tasks emitted by the planner step lack a `scope` tag distinguishing
external-impact work from internal-SI plumbing. Hypotheses authored against
internal-SI tasks then leak into the morning-summary "deferred questions"
section meant for the human. R2's `internal-si-deferred-questions-tag-audit`
was a one-shot backfill of this — the recurring fix is to require the tag at
task creation, so leakage cannot happen in the first place.

The morning-summary parser (`scripts/lib/si-morning-summary.sh:545+`) already
filters on `Scope` when present in the hypothesis log; the gap is that tasks
are not required to declare scope, so hypothesis rows are written without it.

## Change

1. **`scripts/lib/si-functions.sh` — `validate_task_json`.** Add a strict
   required check: each task must have a `scope` field whose value is one
   of `external`, `internal-si`, `infra`. Missing or invalid → SCHEMA REJECT.
   Mirror the existing `TASK_CATEGORIES_ALLOWED` constant pattern.

2. **`scripts/self-improvement.sh` — planner prompt (~line 552).** Add the
   `scope` field to the JSON-schema spec in the prompt and instruct the
   planner to populate it. Also document the enum and the rationale (so the
   planner emits the correct value rather than guessing).

## Differences from `category` field

`category` is strict-when-present (lint warning if missing) per the comment
at si-functions.sh:60. `scope` is strict-required (reject if missing) because
the leakage being fixed is silent — a missing scope today gets treated as
external by the deferred-question harvester, surfacing internal-SI noise to
the human. There is no graceful-degradation reason to allow absence.

## Test impact

`test/scripts/self-improvement-smoke.bats` includes fixtures that lack
`scope`. With this change:

- "smoke: full round sequence" expects 2 valid tasks → will fail (both lack scope)
- "smoke: task validation rejects invalid tasks alongside valid ones" expects
  1 valid task → will fail (good-task lacks scope, so 0 valid)

The test file is outside this task's file-scope constraint. Documented in
`docs/working/scope-exception-r3-tasks-schema-scope-required.md`.

## Verification

1. Source `scripts/lib/si-functions.sh` and run `validate_task_json` on a
   fixture with all three valid scopes, missing scope, and invalid scope.
2. Confirm rejection messages are correctly attributed.
3. Confirm `shellcheck` passes on both modified files.
