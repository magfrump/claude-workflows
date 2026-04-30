# r1-hypothesis-first-task-gate — Plan

## Goal

Add a `hypothesis_present` early gate to the self-improvement validator
pipeline. Every selected task record must carry, before any
implementation tokens are spent:

- `hypothesis` — one-sentence falsifiable claim
- `success_criterion` — explicit check that decides confirm vs. refute
- `token_budget` — positive integer estimate of implementation tokens

Tasks lacking any of the three fail the gate and are dropped before
worktree creation. Trivial cases (renames, mechanical fixes) satisfy the
gate with a minimal claim plus a small estimate — the gate checks
*presence and shape*, not ambition.

## Context

Pipeline stages in `scripts/self-improvement.sh`:

1. Idea generation (DD prompt) → `feature-ideas-round-N.md`
2. Filter into tasks (claude prompt) → `tasks-round-N.json`
2b. Schema validation via `validate_task_json` (lib/si-functions.sh)
3. Worktree creation + parallel implementation
4. Validation gates
5. Merge

`validate_task_json` is in `scripts/lib/si-functions.sh`, which is
**outside** the file scope for this round. So the new gate is added
inline in `self-improvement.sh` as **step 2c**, sitting between schema
validation and worktree creation. The `hypothesis_present` gate name
matches the task description and is consistent with existing gate
conventions (`schema`, `commits`, `diff_size`, `file_scope`, etc.).

Both upstream prompts must change so the new fields are produced:

- The **idea-generation** prompt (DD) needs a directive that each
  surviving idea declares a one-sentence falsifiable hypothesis with an
  explicit success criterion and a rough token-budget estimate.
- The **task-filtering** prompt needs the new fields in its JSON output
  contract, so they make it into `tasks-round-N.json`.

## Implementation steps

1. Update task-filtering prompt JSON contract to include `hypothesis`,
   `success_criterion`, and `token_budget`.
2. Update idea-generation prompt to require these per surviving idea.
3. Add **Step 2c: hypothesis_present gate** after schema validation.
   Iterate `TASK_IDS`, check the three fields with `jq` type+length
   checks, drop failures, record gate pass/fail with structured detail
   via existing `record_gate` / `record_gate_detail` helpers. Mirror the
   schema-rejection control flow: rebuild `TASK_IDS` / `TASK_COUNT` from
   the filtered list; if zero tasks remain, `update_round_log` with a
   new outcome `"all_hypothesis_rejected"` and `continue`.
4. Update file-header comment listing outputs (line ~37) with the new
   gate so future readers find it.

## Invariants preserved

- Existing schema validator still runs first; new gate only sees tasks
  that already passed schema.
- `record_gate` / `record_gate_detail` write to the same round-log JSON
  schema, so morning-summary and gate-stats dashboards pick up the new
  gate automatically.
- No change to `validate_task_json` (out of scope).
- No change to validation gates 1a–1g (the gate runs *before*
  implementation, not after).

## Out of scope

- Updating bats tests (test/ directory is outside file scope).
- Separately validating the *quality* of the hypothesis (non-empty +
  positive integer is enough; semantic quality is for later rounds).
- Plumbing the hypothesis into `hypothesis-log.md` — that already
  happens elsewhere when tasks are merged; this gate just guards entry.
