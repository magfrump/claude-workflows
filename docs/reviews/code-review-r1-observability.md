# Code Review: Self-Improvement Observability

**Branch:** feat/r1-self-improvement-observability
**Reviewed:** 2026-03-23
**Status:** CONDITIONAL PASS

## Summary

This branch adds structured JSON logging to `self-improvement.sh`, recording per-gate validation results, idea/task counts, and merge outcomes for each round. The approach is sound and the logging granularity is appropriate. There are a few robustness issues around JSON construction via string interpolation and temp file cleanup that should be addressed before merge.

## Findings

### Must Fix (if any)
| # | Finding | Location |
|---|---|---|
| R1 | **No `jq` dependency check.** The script checks for `bats` and `shellcheck` before using them, but `jq` is used unconditionally throughout. If `jq` is missing, `set -e` will abort the script with an unhelpful error on the first `init_round_log` call. Add an early guard: `command -v jq &>/dev/null \|\| { echo "Error: jq is required"; exit 1; }` | self-improvement.sh:22 |
| R2 | **JSON built via string interpolation is fragile.** Lines 95, 134, and 428 construct JSON objects by embedding shell variables directly into strings (e.g., `"{\"count\": $IDEA_COUNT, ...}"`). If any variable is empty or contains unexpected characters, the result is invalid JSON. Use `jq -n` with `--argjson`/`--arg` to construct these values safely, consistent with how `init_round_log` already works. | self-improvement.sh:95,134,428 |

### Must Address (if any)
| # | Finding | Location | Author note |
|---|---|---|---|
| A1 | **Temp files are never cleaned up on early exit.** `init_round_log` creates a temp file in `ROUND_LOG_FILE`, and every `update_round_log`/`record_gate` call creates additional temp files. If the script exits early (via `set -e` or signal), these accumulate in `/tmp`. Add a `trap` handler to clean up `ROUND_LOG_FILE` on EXIT/ERR. | self-improvement.sh:24 | -- |
| A2 | **`MERGE_STATUS` may misreport conflict resolution.** On line 384, if `git merge` fails, `MERGE_STATUS` is set to `"conflict_resolved"` -- but if Claude's conflict resolution prompt also fails, the status is still recorded as resolved. The `||` block's return status is not checked. Either verify the merge actually completed (check `git diff --check`) or record a third state like `"conflict_unresolved"`. | self-improvement.sh:383-392 | -- |
| A3 | **Missing trailing newline at end of file.** The file does not end with a newline (visible in the diff as `\ No newline at end of file`). This is a minor POSIX compliance issue but can cause problems with some tools. | self-improvement.sh:437 | -- |

### Consider (if any)
| # | Suggestion |
|---|---|
| C1 | The `record_gate "$TASK_ID" "commits" "pending"` call at line 196 is immediately overwritten by either "pass" or "fail" a few lines later. It adds noise without observable value -- the "pending" state is never persisted to disk. Consider removing it. |
| C2 | Each `update_round_log` and `record_gate` call spawns a new `jq` process and creates a temp file. For a script running 5 rounds with multiple tasks, this could mean dozens of `jq` invocations per round. This is fine at current scale, but if round counts or task counts grow, consider batching updates or accumulating in shell variables and writing once. |
| C3 | The `finalize_round_log` function appends to `round-history.json` by reading the entire file with `jq --slurpfile` and rewriting it. Over many runs this file will grow, and the read-modify-write pattern is not atomic. For now this is fine, but document the assumption that only one instance of the script runs at a time. |
| C4 | Gates that are skipped due to an earlier `REJECT_REASON` are not recorded at all (they don't appear in the validation object). This means a task rejected at gate 1a will have no entries for gates 1b-1g. Consider recording "skipped_due_to_prior_failure" or similar so the log always shows the full gate list, making it easier to aggregate pass rates per gate across rounds. |

## What Works Well

- **Helper function design is clean.** `init_round_log`, `update_round_log`, `record_gate`, and `finalize_round_log` provide a clear API that separates logging concerns from business logic. The main loop reads naturally with the logging calls interspersed.
- **Dual output strategy.** Writing both per-round report files and an append-only history file serves different use cases well: individual round debugging vs. cross-round trend analysis.
- **Gate-level granularity.** Recording pass/fail/skip per gate per task is the right level of detail. It will make it straightforward to identify which gates are rejecting the most tasks and tune thresholds.
- **Early-exit paths are handled.** The "exhausted", "no_tasks", and "all_rejected" outcomes all correctly finalize the round log before breaking or continuing, so every round gets a complete record regardless of how it terminates.
- **Merge status tracking** distinguishes clean merges from conflict-resolved ones, which is useful signal for assessing task independence.
