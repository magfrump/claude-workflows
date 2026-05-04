- **Goal**: Add a lineage helper to `scripts/lib/si-functions.sh` that, given a task's `files_touched`, greps `docs/working/round-changelog.md` for prior tasks that touched any of the same files and prepends that list to the task's plan doc. Wire it into the validate-task path so it runs as a side effect of `validate_task_json`.
- **Project state**: r1 SI task on `feat/r1-round-changelog-lineage`; only `scripts/lib/si-functions.sh` may be modified (plus this plan doc). Existing helper inventory in si-functions.sh: `validate_task_json`, `check_convergence_threshold`, `print_gate_stats`. The SI loop calls `validate_task_json` from `scripts/self-improvement.sh:594` between task generation and worktree launch.
- **Task status**: in-progress (planning)

## Design

Three new helpers, layered:

1. **`find_task_lineage <changelog> <file>...`** — pure read. Walks `round-changelog.md` with awk, tracks the current `## Round N` header, and emits `Round N: task-id` for any `- **task-id**` line whose body contains any of the given files (matched by full path OR basename, since the changelog mixes both styles). Dedupes (round, task-id) pairs. No-ops when changelog is missing or no files supplied.

2. **`prepend_lineage_to_plan <changelog> <plan_path> <file>...`** — calls `find_task_lineage`. If empty, returns silently (no file written, no noise). If non-empty, writes a `## Lineage` section listing the prior rounds/tasks. If `plan_path` already exists, prepends in place; otherwise creates a stub with just the lineage section that Claude's RPI flow will extend.

3. **Wiring in `validate_task_json`** — at the bottom of the per-task loop, for each task that passes all schema/files checks, derive the plan path (`<working_dir>/r<ROUND>-<task_id>-plan.md`) and call `prepend_lineage_to_plan`. Round number and working dir are extracted from the tasks-file path (`<dir>/tasks-round-<N>.json`). If the path doesn't match the convention (e.g., bats tests pass `<tmp>/tasks.json`), skip seeding silently so existing tests keep passing.

## Why this placement

- `validate_task_json` is the only si-functions.sh entry already called between task generation and worktree launch in `self-improvement.sh`. Without modifying `self-improvement.sh` (out of scope), this is the single hook point where lineage seeding can ride along.
- Per-task seeding semantics fall out naturally: a task that fails validation is skipped from the loop before reaching the seeding tail, so we don't seed plan stubs for rejected tasks.
- The pattern matches `_score_task_legibility` / `_summary_task_legibility` (compute + render) — compute lineage once, write a small per-task artifact.

## Risk / fallbacks

- **Changelog missing** → `find_task_lineage` returns empty; no file written. Safe in fresh repos and in tests.
- **No prior matches** → no plan stub created; Claude's RPI flow writes the plan from scratch as before.
- **Tasks-file path off-convention** (bats tests, manual invocation) → seeding skipped silently; validation behavior unchanged.
- **Plan doc already exists** (re-run scenario) → prepended once; subsequent runs would re-prepend, potentially duplicating. Mitigation: detect an existing `## Lineage` header at the top and skip re-prepending.
- **Worktree visibility**: the stub is created in the main repo's `docs/working/` and is untracked, so it won't be present inside the per-task worktree. That's a known limitation requiring a follow-up in `self-improvement.sh` (out of scope here) to copy the stub into the worktree after `git worktree add`. Documented explicitly so a future round can wire that step.

## Test impact

Existing `test/validate-task-json.bats` writes tasks JSON to `$TEST_TMPDIR/tasks.json`. The convention parser won't extract a round from that path, so the seeding branch is skipped — tests remain green without modification.

`test/function-inventory.bats` hardcodes 9 expected functions; the new helpers (`find_task_lineage`, `prepend_lineage_to_plan`) are not added to that list because tests are out of file scope here. The existing assertion still passes (all 9 originals are present). A follow-up round can extend the inventory.

## Follow-ups (out of scope here)

- `scripts/self-improvement.sh`: copy the seeded plan stub into the per-task worktree after `git worktree add` so Claude's RPI flow can extend it (currently the stub lives only in the main repo's `docs/working/` and isn't visible inside the worktree).
- `test/function-inventory.bats`: add `find_task_lineage` and `prepend_lineage_to_plan` to the expected inventory.
- Targeted bats coverage for the new helpers (changelog-driven and idempotent-prepend cases).
