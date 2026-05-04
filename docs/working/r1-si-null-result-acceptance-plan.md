# Plan: SI null-result acceptance

## Problem

The SI loop's task-filter step (scripts/self-improvement.sh) currently
treats "no tasks generated" as a fall-through skip. The prompt only filters
on independence — there is no quality threshold and no explicit
permission to return zero tasks. This pressures the model to launch
low-value tasks to satisfy round cadence, especially when the surviving
backlog from divergent design is weak.

The task is to allow an explicit "no task this round — backlog has no
>threshold-quality candidate" outcome, gated by a written backlog-quality
justification so the null result is a real judgment call, not a silent
empty output.

## Scope

- scripts/self-improvement.sh (task-filter prompt + post-filter logic)
- scripts/lib/si-input.sh (no changes needed — it's a parser; SI prompts
  live in self-improvement.sh)

Out of scope: morning-summary.sh, decisions/log, idea-generation prompt
(already has a DONE/exhaustion path; the new path is for quality, not
exhaustion — they're complementary).

## Changes

### 1. Task-filter prompt (~line 552 in self-improvement.sh)

Add a quality-threshold criterion and a documented null-result option:
- Each task must clearly clear (a) cost of an autonomous Claude session
  + reviewer attention, (b) opportunity cost vs. waiting for a future
  round.
- If no surviving idea clears the threshold, write `[]` to
  tasks-round-N.json AND write a justification file at
  docs/working/no-task-justification-round-N.md that names which backlog
  ideas failed and why (e.g., "all survivors are minor wording
  refinements with negligible external impact"). Generic excuses
  ("no good ideas") are not acceptable.

### 2. Post-filter logic (~line 565 in self-improvement.sh)

After tasks file is read, when `TASK_IDS` is empty:
- Check for `no-task-justification-round-N.md`.
- If present: log outcome as `below_threshold`, embed a truncated
  justification in `.tasks` of the round log, write a line to the
  validation log, and continue to the next round.
- If absent: keep the existing `no_tasks` outcome (silent extraction
  failure, distinct from intentional null-result).

## Why this shape

- The justification file is the forcing function: a model can't trivially
  shortcut to "no tasks" without writing concrete reasons grounded in the
  actual backlog.
- Distinguishing `below_threshold` from `no_tasks` in the round log lets
  future analysis tell apart "intentional skip" from "filter broke."
- No interactive checkpoints — the script remains autonomous, matching
  the SI design constraint (memory: feedback_si_noninteractive).
- Idea-generation DONE path (existing) covers exhaustion. New null-result
  path covers quality. Both can coexist.

## Verification

- shellcheck the modified script.
- Existing bats tests (if any) should still pass.
- Manually inspect the new prompt for clarity.
