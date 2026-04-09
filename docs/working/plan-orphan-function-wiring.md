# Plan: Orphan Function Wiring

## Research Findings

The task identified 4 orphan functions: `check_convergence_threshold`, `auto_expire_hypotheses`, `get_hypothesis_quality_guide`, `print_hypothesis_summary`.

After research, the actual status is:

| Function | Status | Action |
|----------|--------|--------|
| `check_convergence_threshold` | Defined in si-functions.sh line 99, never called | Wire into self-improvement.sh convergence check (line 660) |
| `auto_expire_hypotheses` | **Removed** per decision 009 | No action — does not exist in codebase |
| `get_hypothesis_quality_guide` | **Removed** per decision 009 | No action — does not exist in codebase |
| `print_hypothesis_summary` | Already called from evaluate-hypotheses.sh (line 113) and print-round-summary.sh (line 71) | No action — not an orphan |

Decision 009 (`docs/decisions/009-human-feedback-integration.md`) documents why `auto_expire_hypotheses` and `get_hypothesis_quality_guide` were intentionally removed: auto-expiry penalizes external-impact hypotheses, and the quality guide steered toward internal metrics.

## Implementation

Replace the inline integer comparison in self-improvement.sh:
```bash
# Before:
if [ -n "$OVERLAP_RESULT" ] && [ "$OVERLAP_RESULT" -ge "$CONVERGENCE_THRESHOLD" ]; then

# After:
if [ -n "$OVERLAP_RESULT" ] && check_convergence_threshold "$OVERLAP_RESULT" "$CONVERGENCE_THRESHOLD"; then
```

This is a behavior-preserving change — `check_convergence_threshold` does the same `>=` comparison with added input validation (returns 1 for non-integer input, which is equivalent to the existing `[ -n "$OVERLAP_RESULT" ]` guard).

## Hypothesis Evaluation

The health check (check 10) dynamically scans si-functions.sh for defined functions and warns about any not called from entry-point scripts. After this change, `check_convergence_threshold` will be detected as called from self-improvement.sh, eliminating the only remaining orphan warning.

The function will execute during any self-improvement run that reaches the convergence check (Step 1b, round 2+), satisfying the hypothesis that at least 1 of the 4 functions will be executed in a real workflow run.
