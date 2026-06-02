# Checkpoint: morning-summary-action-block
Date: 2026-06-02
Branch: feat/r1-morning-summary-action-block
Research: docs/working/research-morning-summary-action-block.md
Plan: docs/working/plan-morning-summary-action-block.md

## Project state
- **Branch purpose**: Add a top "What You Need To Do" action block to the SI morning summary naming the single primary action (answer the N matured deferred hypothesis questions).
- **Position in larger initiative**: standalone.
- **Blocked on**: nothing.

## Key findings
- `generate_morning_summary` (si-morning-summary.sh:90) writes sections in fixed order; the user-action section (`_summary_deferred_evaluation`, `## Deferred Evaluation Questions`) is second-to-last, below the full open-hypothesis list — the discoverability problem. [observed]
- `_summary_deferred_evaluation` (line 893) is the authority on the matured subset: it filters rows with `_row_is_open_deferred "$line" "$current_round" "$scope_col" "$outcome_col"` (line 1338) and emits one numbered question per surviving row. `current_round` == `$end_round`. [observed]
- Reusing that exact predicate in a counting helper makes the top block's N equal the questions count by construction (feedback-continuity). [inferred]
- Out-of-scope latent bug: `_row_is_open_deferred` reads `window` from `fields[4]` (Source) instead of `fields[5]` (Window) under the current schema, so the maturity gate is effectively bypassed. NOT fixed here — the block stays consistent with the section regardless. [inferred]

## Plan
1. `_count_matured_deferred <log> <current_round>` — count rows passing `_row_is_open_deferred`, same column-location + Outcome-fallback(7) as the deferred section; echo 0 if log missing.
2. `_summary_action_block <log> <current_round>` — emit `## What You Need To Do` with 0/1/N-keyed message pointing at "Deferred Evaluation Questions".
3. Wire `_summary_action_block "$hypothesis_log" "$end_round"` after `_summary_header` in `generate_morning_summary`.
4. New bats test `test/morning-summary-action-block.bats` (@category fast): 0/1/N wording, consistency (block N == question count), missing-log graceful path.

Order: `1 → 2 → 3 → 4` (strictly sequential).

## Invariants
- Block count == deferred-questions count (shared predicate).
- File is sourced, not executed — functions only, no top-level execution.
- Graceful degradation when hypothesis-log.md is missing.

## File map
- `scripts/lib/si-morning-summary.sh` — add two functions + one call site (steps 1-3).
- `test/morning-summary-action-block.bats` — new test file (step 4).

## Open questions
- None blocking. The window-column bug is deliberately deferred to a follow-up task.
