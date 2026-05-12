# Plan: Self-eval skip cause one-liner in morning summary

- **Goal**: Surface the existing self_eval gate skip reason as a one-liner per task in the morning summary so readers can see which tasks bypassed self-eval and why.
- **Project state**: Round-2 re-attempt on branch `feat/r2-self-eval-skip-cause-one-liner`. Round-1 was rejected for file_scope sprawl (investigation files). This re-attempt edits only `scripts/lib/si-morning-summary.sh`.
- **Task status**: complete

## Scope (locked)

Only `scripts/lib/si-morning-summary.sh` may be modified. No new skill, no new
gate, no rewrite of the self-eval entry point in `scripts/self-improvement.sh`.

## Change

In `_summary_whats_new`, for each approved and each rejected task, after the
task line is printed, check the round report JSON:

- If `validation[tid].self_eval == "skip"`, emit a sub-bullet:
  `  - self_eval skipped: <reason>`
- Reason source order:
  1. `validation[tid].self_eval_detail.reason` (future-proof — uses any
     existing detail field if present)
  2. Static fallback: `"no skill/workflow files changed"` (the only path that
     currently records `skip` in `scripts/self-improvement.sh:946-948`)

Add one helper `_self_eval_skip_line "$report" "$tid"` that prints the
sub-bullet line (or nothing when self_eval is not "skip"). Called from both
the approved-task loop and the rejected-task loop in `_summary_whats_new`.

## Out of scope

- Modifying `scripts/self-improvement.sh` to record a skip reason in JSON
  (would expand scope). The morning summary uses what's already in the JSON
  plus a documented static fallback for the only current skip path.
- New summary subsection ("Skipped Self-Eval"). Keeping it inline keeps the
  per-task context where the reader is already looking.
- Counting / aggregating skip reasons across rounds.
