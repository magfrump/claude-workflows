# Scope exception — morning-summary action block

## Constraint

This task's file scope permits only `scripts/lib/si-morning-summary.sh` and files
under `docs/working/`. No file under `test/` may be created or modified.

## What was needed but not done

The implementation adds two functions to `scripts/lib/si-morning-summary.sh`
(`_count_matured_deferred`, `_summary_action_block`) and a call site in
`generate_morning_summary`. Following TDD / the RPI test-first gate, this work
should ship with a companion bats test at:

    test/morning-summary-action-block.bats

That path is **outside the allowed file scope**, so the test file was not
committed. The full intended test content is preserved verbatim at:

    docs/working/draft-test-morning-summary-action-block.bats.txt

A follow-up task (or the next round, with test/ in scope) should move that draft
to `test/morning-summary-action-block.bats` and run it via
`scripts/run-tests.sh --fast`. The draft is already written to the repo's bats
conventions (mirrors `test/morning-summary-clusters.bats` and
`test/precondition-gate.bats`).

## Verification status of the implementation

Test execution (`bats`, `scripts/run-tests.sh`, even `bash -n`) is gated behind
interactive permission approval that is unavailable in the current /away session,
so the suite could not be run here. The implementation was instead verified by a
manual trace of each draft test case against the two new functions:

- 2 open (empty-Outcome) rows + 1 closed (Outcome=CONFIRMED) row, current_round=10
  → `_count_matured_deferred` = 2; `_summary_action_block` prints
  "**Answer the 2 matured deferred hypothesis questions** … Deferred Evaluation
  Questions …".
- 1 open + 1 closed → count 1, singular "question".
- all-closed / missing log → count 0, "Nothing needs your input …".
- Feedback-continuity: `_count_matured_deferred` and `_summary_deferred_evaluation`
  call the same `_row_is_open_deferred` predicate with identical
  (current_round, scope_col, outcome_col), so the block's N equals the number of
  numbered questions below it by construction.

## Out-of-scope latent bug (also not fixed here)

`_row_is_open_deferred` reads the maturity Window from `fields[4]` (the Source
column under the current schema; Window is `fields[5]`). The maturity gate is
therefore bypassed in practice. This is documented in
`docs/working/research-morning-summary-action-block.md` and is intentionally left
for a separate task — the action block stays consistent with the deferred section
regardless of the gate's behavior.
