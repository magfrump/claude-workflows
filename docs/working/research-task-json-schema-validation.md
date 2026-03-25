# Research: Task JSON Schema Validation

## Scope
Add a `validate_task_json` function to `self-improvement.sh` that validates task JSON schema between Step 2 (task filtering) and Step 3 (implementation).

## What exists
- `self-improvement.sh` line 428-446: Step 2 asks Claude to output task JSON with fields: `id`, `description`, `files_touched`, `independent`, `hypothesis`, `hypothesis_window`
- Line 449-464: Basic existence checks (file exists, task IDs non-empty)
- Line 472+: Step 3 begins parallel worktree implementation
- Line 561-579: Gate 1c uses `files_touched` for scope enforcement — if missing, behavior is unpredictable

## Invariants
- The validation must happen after `TASK_IDS` is set (line 457) and before Step 3 (line 472)
- Must use `jq` only (no additional dependencies — jq is already required at line 12)
- Must not break the existing pipeline flow — rejected tasks should be filtered out, not cause script exit
- Must preserve `TASK_IDS`, `TASK_COUNT`, `TASK_IDS_JSON` variables for downstream use
- The `record_gate` and round log functions should be used for consistency

## Prior art
- Gates 1a-1g in Step 4 follow a pattern: check condition, set `REJECT_REASON`, call `record_gate`
- The script already validates jq availability at line 12

## Gotchas
- `files_touched` entries containing glob patterns would cause gate 1c's `grep -qF` to match incorrectly
- Parent directory check needs to run against the repo, not the worktree (worktrees don't exist yet at validation time)
- Need to update `TASK_IDS` after filtering so Step 3 doesn't launch rejected tasks
