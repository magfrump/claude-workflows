# Workflow Selection Guide

Which workflow should you use right now? Walk through these questions in order. Take the first match.

## Decision Tree

### 1. Are you opening or preparing a pull request?

- **Yes** → [pr-prep.md](../../../.claude/workflows/pr-prep.md)
- **No** → Continue to question 2

### 2. Is this a bug fix?

- **No** → Continue to question 3
- **Yes** → Do you already understand the code where the bug likely lives?
  - **Yes** → [bug-diagnosis.md](../../../.claude/workflows/bug-diagnosis.md)
  - **No** → [research-plan-implement.md](../../../.claude/workflows/research-plan-implement.md) *(build understanding first; pivot to bug-diagnosis once you locate the area)*

### 3. Is the codebase unfamiliar to you?

- **Yes** → [codebase-onboarding.md](../../../.claude/workflows/codebase-onboarding.md) *(do this before any task-specific workflow)*
- **No** → Continue to question 4

### 4. Is this about planning or running a usability test?

- **Yes** → [user-testing-workflow.md](../../../.claude/workflows/user-testing-workflow.md)
- **No** → Continue to question 5

### 5. Is the core question "can this work?" rather than "build this"?

- **Yes** → [spike.md](../../../.claude/workflows/spike.md) *(timeboxed exploration; feeds into RPI when done)*
- **No** → Continue to question 6

### 6. Are there 3+ viable approaches with non-obvious tradeoffs?

- **Yes** → [divergent-design.md](../../../.claude/workflows/divergent-design.md) *(can also be invoked as a sub-procedure within RPI)*
- **No** → Continue to question 7

### 7. Does the task touch multiple independent subsystems?

- **Yes** → [task-decomposition.md](../../../.claude/workflows/task-decomposition.md) *(parallelizes research, keeps implementation sequential)*
- **No** → Continue to question 8

### 8. Is this a trivial change (typo, config tweak, single-line fix)?

- **Yes** → Just make the change. No workflow needed.
- **No** → [research-plan-implement.md](../../../.claude/workflows/research-plan-implement.md) *(the default)*

## Coordination Patterns

These aren't task workflows — they're used alongside the workflows above:

- **[branch-strategy.md](../../../.claude/workflows/branch-strategy.md)** — VCS coordination for high-volume development with async review. Use when running 10+ features/day across timezones.
- **[review-fix-loop.md](../../../.claude/workflows/review-fix-loop.md)** — Iterative code review sub-procedure. Called automatically by pr-prep; rarely invoked standalone.

## Quick Reference

| Signal | Workflow |
|--------|----------|
| Opening a PR | pr-prep |
| Bug in known code | bug-diagnosis |
| Bug in unknown code | research-plan-implement |
| New/unfamiliar codebase | codebase-onboarding |
| Running a usability test | user-testing-workflow |
| "Can this work?" | spike |
| Multiple viable approaches | divergent-design |
| Large task, many subsystems | task-decomposition |
| Trivial change | No workflow |
| Everything else | research-plan-implement |
