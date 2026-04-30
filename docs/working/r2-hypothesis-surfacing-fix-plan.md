# R2 Plan: Morning Summary Hypothesis Surfacing Fix

## Problem

`scripts/lib/si-morning-summary.sh::_summary_deferred_evaluation` only
surfaces hypothesis rows whose `Outcome` column is empty (TRACKING). It
treats `INCONCLUSIVE` as if it were resolved — but `INCONCLUSIVE` means
"window still open, not enough evidence yet" while `INCONCLUSIVE-EXPIRED`,
`CONFIRMED`, and `REFUTED` are the truly resolved states.

Result: `docs/working/morning-summary.md` surfaces only `task-description-linter`
(the single empty-outcome row) while `docs/working/hypothesis-log.md` has
~28 additional `INCONCLUSIVE` rows whose evaluation windows are still open
and whose answers depend on real-world user observations. Those questions
never reach the user.

## Fix

Two changes to `scripts/lib/si-morning-summary.sh`:

1. **Widen the surfacing predicate.** Replace the `[[ -n "$outcome" ]]`
   skip with a case match that surfaces both empty (`""`) and exact
   `INCONCLUSIVE` outcomes. `INCONCLUSIVE-EXPIRED`, `CONFIRMED`, and
   `REFUTED` continue to be skipped.

2. **Add a regression assertion.** Independent helper `_count_surfaceable_hypotheses`
   counts rows that *should* be surfaced using a separate awk pass. After
   the rendering loop, if `expected > 0` but the rendered count is `0`,
   write a `**REGRESSION**` block into the summary and return 1 from the
   function (and ultimately from `generate_morning_summary`). Self-improvement
   already invokes the generator with `|| true`, so existing runs are
   unaffected; tests calling the function directly will see the failure.

## Verification

- bats tests in `test/scripts/morning-summary-surfacing.bats`:
  - TRACKING (empty) row surfaces
  - INCONCLUSIVE row surfaces
  - INCONCLUSIVE-EXPIRED, CONFIRMED, REFUTED rows do not surface
  - Helper count function returns expected counts
  - Smoke test against production hypothesis-log.md surfaces > 5 rows
  - internal-si scope filter still works when Scope column is present
- shellcheck the modified file
- Manual: run `generate_morning_summary` against the real log and confirm
  many rows surface (vs. 1 today).

## Scope

Per the file_scope constraint, only:
- `scripts/lib/si-morning-summary.sh`
- `test/scripts/morning-summary-surfacing.bats`
- `docs/working/r2-hypothesis-surfacing-fix-plan.md` (this doc)

No changes to the production `hypothesis-log.md` (data is already correct;
the parser is what is broken).
