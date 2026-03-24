# Code Review: Hypothesis Tracking

**Branch:** feat/r3-hypothesis-tracking
**Reviewed:** 2026-03-23
**Status:** PASS (after review-fix loop)

## Summary

This branch adds a hypothesis tracking system to the self-improvement loop: each task gets a falsifiable prediction at creation time, and after N rounds the hypotheses are evaluated by Claude and logged. The core idea is sound and addresses a real gap (no feedback loop on whether changes actually helped). The implementation has a few shell scripting issues that should be fixed before merge, and some design concerns worth discussing.

## Findings

### Must Fix

| # | Finding | Location |
|---|---|---|
| R1 | **FIXED.** Variable injection in jq filters. Now uses `jq --arg tid "$TASK_ID"` for safe variable passing. | self-improvement.sh:56-57 |
| R2 | **FIXED.** Pipe characters in hypothesis/evidence text. Now escapes `|` to `\|` before appending to the markdown table. | self-improvement.sh:79-81 |
| R3 | **FIXED.** stderr on `claude -p` call. Changed `2>&1` to `2>/dev/null`. | self-improvement.sh:70 |

### Must Address

| # | Finding | Location | Author note |
|---|---|---|---|
| A1 | **FIXED.** Replaced `grep -oP` with portable `sed -n 's/.*HYPOTHESIS_VERDICT: //p'`. Also replaced `xargs` trimming with `sed` (addresses C5). | self-improvement.sh:72-77 | -- |
| A2 | **FIXED.** Added `"retroactive": true` flag to all five pre-existing tasks. Updated the jq filter to skip retroactive hypotheses during evaluation. | docs/working/tasks.json, self-improvement.sh:40 | -- |
| A3 | **FIXED.** Replaced `for TASK_ID in $ELIGIBLE` with `while IFS= read -r TASK_ID` loop with empty-line guard. | self-improvement.sh:44-45 | -- |

### Consider

| # | Suggestion |
|---|---|
| C1 | **Move `HYPOTHESIS_LOG` definition outside the loop.** It is defined on every iteration of the outer round loop (line 21) but is constant. Define it once before the `for ROUND` loop alongside other path variables for clarity. |
| C2 | **Add the hypothesis log to `.gitignore` or document whether it should be committed.** The log accumulates evaluation results across runs. If the script is run multiple times on the same repo, old entries persist. Clarify the intended lifecycle. |
| C3 | **Consider logging skipped hypotheses.** When a task is not found in `completed-tasks.md` (line 50), it is silently skipped. A debug-level log entry would make it easier to diagnose why a hypothesis was never evaluated. |
| C4 | **The Claude evaluation prompt could be more constrained.** The prompt asks Claude to "review the repo state, git log, completed-tasks.md, and validation logs" but does not specify which files to look at or provide the relevant content inline. This makes the evaluation non-deterministic and dependent on what Claude decides to explore. Consider passing the relevant evidence (e.g., the completed-tasks.md entry, recent validation logs) directly in the prompt. |
| C5 | **`xargs` for whitespace trimming (lines 71-72) can mangle special characters.** If the evidence summary contains quotes or backslashes, `xargs` will interpret them. A safer trim would be `sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`. |
| C6 | **All hypothesis windows are hardcoded to 3.** The prompt tells the LLM to use `hypothesis_window: 3` as default, and all existing tasks use 3. Consider whether the window should vary by task type (e.g., structural changes might be evaluable sooner than process changes). |

## What Works Well

- The overall design is well-motivated: adding a feedback loop to the self-improvement process so it can learn whether its changes actually help.
- The deduplication check (line 45, `grep -qF` against the log) prevents re-evaluating hypotheses that have already been recorded.
- The completion gate (line 50, checking `completed-tasks.md`) correctly avoids evaluating hypotheses for tasks that were never merged.
- The fallback to `INCONCLUSIVE` when evaluation parsing fails (line 70) is a reasonable default that avoids blocking the pipeline.
- The markdown table format for the hypothesis log is human-readable and easy to review.
- The `|| true` guards on lines 41 and 68 correctly prevent `set -e` from killing the script on expected failures.
