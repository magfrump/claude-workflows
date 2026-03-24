# Code Review: Self-Improvement Observability

**Branch:** feat/r1-self-improvement-observability
**Reviewed:** 2026-03-24 (round 2)
**Status:** PASSES REVIEW

## Summary

This branch adds structured JSON logging to `self-improvement.sh`, recording per-gate validation results, idea/task counts, and merge outcomes for each round. The approach is sound and the logging granularity is appropriate. All must-fix and must-address items from round 1 have been resolved.

## Findings

### Must Fix (if any)
| # | Finding | Location | Status |
|---|---|---|---|
| R1 | **No `jq` dependency check.** The script checks for `bats` and `shellcheck` before using them, but `jq` is used unconditionally throughout. | self-improvement.sh:12 | FIXED -- added `command -v jq` guard |
| R2 | **JSON built via string interpolation is fragile.** Lines constructing JSON objects by embedding shell variables directly into strings. | self-improvement.sh:107,148,447 | FIXED -- all three sites now use `jq -n` with `--argjson`/`--arg` |

### Must Address (if any)
| # | Finding | Location | Author note |
|---|---|---|---|
| A1 | **Temp files are never cleaned up on early exit.** `init_round_log` creates a temp file in `ROUND_LOG_FILE`, and helper calls create additional temp files. | self-improvement.sh:24-31 | FIXED -- added `trap cleanup EXIT ERR` handler |
| A2 | **`MERGE_STATUS` may misreport conflict resolution.** If Claude's conflict resolution also fails, the status was still recorded as resolved. | self-improvement.sh:397-411 | FIXED -- now verifies merge completed and records `conflict_unresolved` if not |
| A3 | **Missing trailing newline at end of file.** | self-improvement.sh:460 | FIXED -- file now ends with newline |

### Consider (if any)
| # | Suggestion | Status |
|---|---|---|
| C1 | The `record_gate "$TASK_ID" "commits" "pending"` call was immediately overwritten by either "pass" or "fail". | FIXED -- removed the no-op pending call |
| C2 | Each `update_round_log` and `record_gate` call spawns a new `jq` process and creates a temp file. Fine at current scale. | Acknowledged -- no change needed at current scale |
| C3 | The `finalize_round_log` function's read-modify-write pattern is not atomic. | Acknowledged -- single-instance assumption is valid |
| C4 | Gates skipped due to earlier `REJECT_REASON` are not recorded. | Acknowledged -- could improve in a follow-up |

## What Works Well

- **Helper function design is clean.** `init_round_log`, `update_round_log`, `record_gate`, and `finalize_round_log` provide a clear API that separates logging concerns from business logic. The main loop reads naturally with the logging calls interspersed.
- **Dual output strategy.** Writing both per-round report files and an append-only history file serves different use cases well: individual round debugging vs. cross-round trend analysis.
- **Gate-level granularity.** Recording pass/fail/skip per gate per task is the right level of detail. It will make it straightforward to identify which gates are rejecting the most tasks and tune thresholds.
- **Early-exit paths are handled.** The "exhausted", "no_tasks", and "all_rejected" outcomes all correctly finalize the round log before breaking or continuing, so every round gets a complete record regardless of how it terminates.
- **Merge status tracking** distinguishes clean merges from conflict-resolved ones, which is useful signal for assessing task independence.
