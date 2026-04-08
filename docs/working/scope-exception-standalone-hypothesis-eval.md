# Scope Exception: standalone-hypothesis-eval

## File needing modification outside allowed scope

**File:** `scripts/self-improvement.sh` (lines 267–335)

**Reason:** Step 0 of self-improvement.sh contains hypothesis evaluation logic
that is now duplicated by the `evaluate_hypotheses()` function in
`scripts/lib/si-functions.sh`. Ideally, self-improvement.sh should be updated to
call `evaluate_hypotheses "$ROUND" "$WORKING_DIR"` instead of inlining the loop.
This was not done because the file scope constraint for this task only allows
modifying `scripts/evaluate-hypotheses.sh` and `scripts/lib/si-functions.sh`.

**Recommended follow-up:** Replace lines 267–335 of self-improvement.sh with a
call to `evaluate_hypotheses "$ROUND" "$WORKING_DIR"` to eliminate duplication.
