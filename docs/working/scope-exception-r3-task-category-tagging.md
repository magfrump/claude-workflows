# Scope Exception — r3-task-category-tagging

## Context

Round task: add a `category` field with values `feature|maintenance|data-pipeline`
to the `tasks-round-N.json` schema, update the planner so it (not the
implementer) assigns the category, and update the morning summary to report
per-category counts.

File scope for this round restricts changes to:
- `scripts/lib/si-functions.sh`
- `scripts/lib/si-morning-summary.sh`
- `docs/working/**`

## Files outside the scope that the task implies touching

### `scripts/self-improvement.sh` (lines 552–563)

The "round planner" is the inline `claude -p` prompt at
`scripts/self-improvement.sh:552-563`:

```
Output a JSON array to docs/working/tasks-round-$ROUND.json with fields:
{"id": "short-kebab-case", "description": "one paragraph task description",
"files_touched": ["list of files"], "independent": true/false}
```

To honor "the planner (not the implementer) assigns the category", this prompt
must be extended so the planner emits `category: "feature" | "maintenance" |
"data-pipeline"` for every task. Without that prompt change, the planner will
keep producing tasks with no category and the per-category counts in the
morning summary will all land in the "uncategorized" bucket.

This is a **single-line prompt edit** and is the natural follow-up. It cannot
be done in this round under the file-scope constraint.

### `test/validate-task-json.bats`

The schema-validation unit tests live here. Adding strict-when-present
category validation in `validate_task_json` deserves test coverage:
- Valid category value passes.
- Invalid category value (e.g. `"oops"`) is rejected with a clear reason.
- Missing category produces a lint warning but does not reject (so the loop
  continues to operate before the planner prompt is updated).

Likewise, `test/scripts/self-improvement-smoke.bats` fixtures should grow a
`category` field on at least one task once the planner prompt lands so the
smoke flow exercises the new behavior end-to-end.

## What this round does within scope

1. Extends `validate_task_json` in `si-functions.sh` to recognize `category`:
   - Accepts the three documented values.
   - Rejects any other non-empty value.
   - Treats absence as a lint warning, not a hard reject — keeps the loop
     running until the planner prompt update lands.
2. Adds a per-category count subsection to the morning summary
   (`si-morning-summary.sh`) that reads each round's `tasks-round-N.json`,
   groups by category, and renders counts with an "uncategorized" bucket.
3. Documents this exception so the planner-prompt follow-up is not lost.

## Why the lenient absence handling

A strict "category required" rule would reject every task on the next SI run
because the planner prompt has not been updated yet. That cuts off the very
data we want to start collecting. The lenient rule lets the morning summary
start surfacing the imbalance right away (current state: "uncategorized: N")
while making it obvious that the planner needs to be taught to assign
categories. After the planner prompt update lands, a separate follow-up can
tighten the rule from "lint warning" to "hard reject".
