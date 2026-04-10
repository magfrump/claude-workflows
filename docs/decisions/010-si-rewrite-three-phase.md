# Decision 010: Self-Improvement Rewrite — Three-Phase Model

**Date:** 2026-04-09
**Status:** Accepted

## Context

The SI system ran 7 rounds producing 36 tasks (33 approved), but an epistemic DD analysis revealed structural failures that undermined its ability to deliver value:

1. **Hypothesis evaluation timing mismatch**: Hypotheses were evaluated between rounds, but rounds run in batches with no gap for real-world usage. ~50% of "REFUTED" hypotheses were actually never tested (preconditions unmet).

2. **Feature surfacing gap**: Features built for the user (dry-run mode, hypothesis dashboard, resolution sprint) were never communicated. Nothing in the loop surfaced new capabilities to the human.

3. **Measurement infrastructure mismatch**: Hooks/usage.jsonl could only capture tool invocations, not human workflow behavior. Many hypotheses required observing human behavior but had no way to do so.

4. **Missing user-in-the-loop**: The system had no mechanism for user input before execution or communication of results after. But the system's core use case is autonomous overnight execution — interactive checkpoints would defeat the purpose.

## Decision

Restructure the SI system around three phases:

1. **Pre-run input** (`docs/working/si-input.md`): User provides feedback, priorities, off-limits constraints, and context before kicking off the overnight run.

2. **Autonomous execution**: Fully non-interactive multi-round loop. No inter-round hypothesis evaluation. No features that require human awareness to function. Tasks no longer require falsifiable hypothesis attachments.

3. **Post-run morning summary** (`docs/working/morning-summary.md`): Single output document surfacing what was built per round, gate statistics, and deferred hypothesis evaluation questions for user confirmation.

All hypothesis evaluation is deferred to the morning summary, where the user can weigh in on whether changes delivered value.

## What was removed

- Inter-round hypothesis evaluation (Step 0)
- Hypothesis screening context injection (Step 0c)
- Per-task hypothesis/hypothesis_window/retroactive fields
- Advisory task linting (never blocking, unclear value)
- 6 satellite scripts: hypothesis-screen.sh, evaluate-hypotheses.sh, hypothesis-calibration.sh, search-external-ideas.sh, print-round-summary.sh, hypothesis-review.sh
- 3 functions from si-functions.sh: evaluate_hypotheses, get_eligible_hypotheses, print_hypothesis_summary

## What was preserved

- DD idea generation prompt (including external-impact requirement)
- Task filtering and JSON schema validation
- Parallel worktree implementation
- 7-gate validation pipeline
- Merge and conflict resolution
- Round logging infrastructure
- hypothesis-log.md as historical record (read-only by morning summary)

## Consequences

- The system can no longer evaluate hypotheses autonomously. This is intentional — the evaluations were unreliable and produced misleading signal.
- Users must fill in si-input.md before runs for the system to benefit from their feedback. The system degrades gracefully if the file is missing.
- The morning summary creates a natural feedback loop: user reads summary, updates si-input.md, runs next overnight session.
- Net reduction of ~2,000+ lines across the SI system.
