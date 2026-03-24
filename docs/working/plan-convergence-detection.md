# Plan: Convergence Detection for self-improvement.sh

## Scope
Add convergence detection after divergent design generates ideas, comparing diagnosed problems against prior rounds.

## Approach
Insert a convergence-check step between Step 1 (idea generation) and Step 2 (task filtering). Extract problem summaries from the DD output, compare against all prior rounds stored in `round-history.json`, and terminate if >70% overlap. Use Claude for semantic comparison since problems are free-form text.

## Steps

### Step 1: Initialize round-history.json (~5 lines)
At script startup, create `round-history.json` if it doesn't exist (empty object `{}`).

### Step 2: Extract problems from DD output (~15 lines)
After Step 1 (idea generation) succeeds and before the DONE check, use Claude to extract problem summaries from `feature-ideas-round-N.md` as a JSON array of short problem descriptions.

### Step 3: Compare against prior rounds (~20 lines)
If round-history.json has prior entries, use Claude to assess what percentage of current problems overlap with previously-addressed problems. If >70%, print convergence message and break.

### Step 4: Store current round's problems (~5 lines)
Append current round's problems to round-history.json using jq.

### Step 5: Write summary doc (~1 line)

## Testing strategy
- Verify script passes shellcheck
- Verify round-history.json is created as valid JSON
- Manual review of the convergence logic flow

## Risks
- Claude extraction of problems may be inconsistent across runs. Mitigated by asking for short one-line summaries.
- Semantic overlap assessment is subjective. The 70% threshold is a tunable parameter.
