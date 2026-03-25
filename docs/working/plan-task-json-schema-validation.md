# Plan: Task JSON Schema Validation

## Scope
Add `validate_task_json` between Step 2 and Step 3 of `self-improvement.sh`. See [research](research-task-json-schema-validation.md).

## Approach
Add a bash function `validate_task_json` that takes a task JSON file path and outputs a filtered JSON array containing only valid tasks. Invalid tasks get logged with clear error messages. The function uses jq for all checks.

## Steps

1. **Add `validate_task_json` function** (~40 lines in the helper functions section near line 78)
   - Accept task file path as argument
   - Use jq to check each task for: id (string, non-empty), description (string, non-empty), files_touched (array, non-empty), independent (boolean)
   - Check files_touched entries for glob patterns (*, ?, [)
   - Check parent directories of files_touched entries exist in the repo
   - Output valid tasks as JSON array; print rejection reasons to stderr
   - Return count of rejected tasks via exit code or stdout protocol

2. **Insert validation call between Step 2 and Step 3** (~15 lines after line 464)
   - Call `validate_task_json` on the tasks file
   - Filter tasks file to only valid tasks
   - Update `TASK_IDS`, `TASK_COUNT`, `TASK_IDS_JSON` variables
   - Record a "schema" gate result for each task
   - Log rejected tasks to the validation log
   - If no tasks remain after filtering, skip to next round

## Testing strategy
- The function can be tested by creating sample JSON files with:
  - Missing `id` field → rejected
  - Empty `files_touched` array → rejected
  - `independent` as string instead of boolean → rejected
  - Glob pattern in `files_touched` → rejected
  - Non-existent parent directory in `files_touched` → rejected
  - Valid task → passes

## Risks
- jq expressions for type checking need to be precise (e.g., `type == "string"` vs truthy checks)
- Parent directory check must handle nested paths correctly
