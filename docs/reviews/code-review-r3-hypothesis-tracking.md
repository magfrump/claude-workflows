# Code Review: Hypothesis Tracking

**Branch:** feat/r3-hypothesis-tracking
**Reviewed:** 2026-03-23
**Status:** CONDITIONAL PASS

## Summary

This branch adds a hypothesis tracking system to the self-improvement loop: each task gets a falsifiable prediction at creation time, and after N rounds the hypotheses are evaluated by Claude and logged. The core idea is sound and addresses a real gap (no feedback loop on whether changes actually helped). The implementation has a few shell scripting issues that should be fixed before merge, and some design concerns worth discussing.

## Findings

### Must Fix

| # | Finding | Location |
|---|---|---|
| R1 | **Variable injection in jq filters.** `$TASK_ID` is interpolated via shell expansion into jq filter strings (`.id==\"$TASK_ID\"`). If a task ID ever contained double quotes or backslashes, this would produce a jq syntax error or unexpected behavior. Use `jq --arg tid "$TASK_ID" '.[] | select(.id==$tid) | ...'` instead. | self-improvement.sh:54-55 |
| R2 | **Pipe characters in hypothesis text break markdown table.** The hypothesis text is inserted directly into a markdown table row on line 75. If a hypothesis contains `|` (which is plausible in natural language, e.g., "this or that"), the table formatting breaks. Escape or replace `|` with `\|` before appending. Similarly, the evidence field from the Claude evaluation could contain pipes. | self-improvement.sh:75 |
| R3 | **`2>&1` on the `claude -p` call mixes stderr into evaluation output.** If `claude` emits warnings or errors to stderr, they get merged into `$EVAL_RESULT`, which the `grep -oP` on line 70 then searches. This could cause false matches or bury the actual verdict. Capture stderr separately (e.g., `2>/dev/null` or `2>>"$log_file"`). | self-improvement.sh:68 |

### Must Address

| # | Finding | Location | Author note |
|---|---|---|---|
| A1 | **`grep -oP` is not portable.** The `-P` (PCRE) flag is a GNU grep extension. If this script ever runs on macOS or a minimal container, it will fail. Consider using `sed` or `grep -oE` with an adjusted pattern. The pattern `HYPOTHESIS_VERDICT: \K.*` can be rewritten as `sed -n 's/.*HYPOTHESIS_VERDICT: //p'`. | self-improvement.sh:70 | -- |
| A2 | **Retrofitted hypotheses in tasks.json are not real predictions.** The diff adds `hypothesis` and `hypothesis_window` to all five existing tasks that were created before this feature existed. These hypotheses were never actual predictions -- they were written after the fact. This undermines the integrity of the hypothesis log if these tasks later get evaluated. Either mark them with a flag like `"retroactive": true` so the evaluator knows, or remove them and only apply hypothesis tracking to newly created tasks. | docs/working/tasks.json | -- |
| A3 | **No guard against `ELIGIBLE` being empty or containing unexpected whitespace.** The `for TASK_ID in $ELIGIBLE` loop relies on word-splitting. If `jq` outputs empty strings or lines with spaces, this silently misbehaves. Consider using `mapfile` or a `while read` loop for safer iteration. | self-improvement.sh:43 | -- |

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
