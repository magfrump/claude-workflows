# Research: Convergence Detection for self-improvement.sh

## Scope
Add convergence detection so the self-improvement loop stops when divergent design recycles previously-addressed problems.

## What exists
- `self-improvement.sh` (301 lines): Orchestrates a multi-round loop with 6 steps. Terminates on "DONE", MAX_ROUNDS, or empty tasks.
- Step 1 invokes divergent-design workflow, which produces `feature-ideas-round-N.md` with a "## 2. Diagnose" section listing problems as `**P1. Short title.** Description...`
- `docs/working/completed-tasks.md`: Tracks what tasks were approved each round.
- No `round-history.json` exists yet.

## Invariants
- Must not break existing termination conditions (DONE, MAX_ROUNDS).
- Must not change the divergent-design workflow itself.
- The 7-gate validation pipeline must remain intact.
- `round-history.json` must be valid JSON.

## Prior art
- The script already uses `jq` for JSON parsing (tasks files).
- The script already uses `claude -p` for judgment calls (Step 1, 2, conflict resolution, self-eval).

## Gotchas
- Problem descriptions are free-form text. Exact string matching won't detect semantic equivalence (e.g., "session continuity is fragile" vs "cross-session context is lost"). Need semantic comparison.
- The feature-ideas file may not exist or may start with "DONE" — convergence check should happen only when the file exists and has content.
- The Diagnose section format uses `**P1. Title.**` pattern but this is convention, not enforced.
