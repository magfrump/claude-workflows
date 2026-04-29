# R3 Plan: SI Deferred Question Scope Filter

## Problem

R1's `r1-drop-task-description-linter-deferred` branch added a `Scope` column
to `docs/working/hypothesis-log.md` (values: `internal-si`, `external-workflow`)
and a TRACKING-INTERNAL convention so that internal SI hypotheses are not
surfaced as user-facing deferred questions in the morning summary.

That fix relied on hypothesis authors writing `TRACKING-INTERNAL` as the
initial outcome for internal-si hypotheses. The morning-summary parser in
`scripts/lib/si-morning-summary.sh` (function `_summary_deferred_evaluation`)
keys off an *empty* outcome to decide whether to surface a row, and never
inspects the new `Scope` column. Any internal-si hypothesis whose Outcome is
left blank — which includes pre-R1 entries like `task-description-linter` —
still gets surfaced as a deferred user question.

User feedback confirmed `task-description-linter` continues to appear as a
deferred eval question in the morning summary.

## Fix

Make the morning-summary parser the source of truth for what surfaces, by
consuming the `Scope` column directly:

1. On entry to `_summary_deferred_evaluation`, scan the table header to find
   the 1-based column index of `Scope`. If absent (older log files), index
   is `0` and behavior is unchanged.
2. For each tracking row (Outcome is empty), also extract the Scope value
   when the column exists. If Scope is `internal-si`, skip the row — these
   are evaluated inside the SI loop, not by the user.
3. External-workflow rows and rows in legacy logs without a Scope column
   continue to surface as before.

This makes the filter a property of the data (`Scope` column) rather than
the encoding convention (`TRACKING-INTERNAL` outcome), so any internal-si
hypothesis is filtered regardless of who created it or when.

## Scope

- File touched: `scripts/lib/si-morning-summary.sh`
- No changes to `hypothesis-log.md` (out of file scope and unnecessary —
  the parser change covers the failing case without rewriting data).
- No changes to `scripts/self-improvement.sh` (R1 already added the
  `emit_hypothesis` helper; this round only fixes the consumer).

## Verification

- Manual: source the script, run `_summary_deferred_evaluation` against
  R1's hypothesis-log.md, confirm `task-description-linter` is not in the
  output and at least one `external-workflow` empty-outcome row still is.
- shellcheck the file.
