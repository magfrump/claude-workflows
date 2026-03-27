# Workflow Selection Guide

A prescriptive decision tree for choosing the right workflow given a task type. Start at the top and follow the first matching condition.

## Quick-Start Decision Tree

```
Is this a brand-new or unfamiliar codebase?
  YES → codebase-onboarding
  NO  ↓

Is the task a bug fix?
  YES → Is the bug in code you already understand?
          YES → bug-diagnosis
          NO  → research-plan-implement (research phase will build context)
  NO  ↓

Is the question "can this work?" or "how does this behave?"
  YES → spike
  NO  ↓

Is the task a decision with multiple viable options?
  YES → divergent-design
  NO  ↓

Does the task touch 3+ subsystems that can be investigated independently?
  YES → task-decomposition
  NO  ↓

Is this a non-trivial feature or change?
  YES → research-plan-implement
  NO  → Just do it (no workflow needed)
```

### Supporting workflows (apply on top of the above)

- **Ready to open a PR?** → [pr-prep](../workflows/pr-prep.md) (includes [review-fix-loop](../workflows/review-fix-loop.md))
- **Running multiple independent tasks?** → [parallel-sessions](parallel-sessions.md) guide
- **Managing many feature branches with async review?** → [branch-strategy](../workflows/branch-strategy.md)
- **Need to plan and run a usability test?** → [user-testing-workflow](../workflows/user-testing-workflow.md)

## Disambiguation: Similar Workflows

### Bug-diagnosis vs Research-plan-implement (for bugs)

| Factor | [bug-diagnosis](../workflows/bug-diagnosis.md) | [research-plan-implement](../workflows/research-plan-implement.md) |
|---|---|---|
| You understand the relevant code | Yes | No |
| Hypothesis available quickly | Yes | Not yet |
| Plan approval gate | No — fast iteration loop | Yes — human reviews plan |
| Typical duration | Minutes | Session+ |

**Rule of thumb:** If you can form a hypothesis within 5 minutes of reading the bug report, use bug-diagnosis. If you need to understand unfamiliar subsystems first, use research-plan-implement.

### Spike vs Divergent-design (for exploration)

| Factor | [spike](../workflows/spike.md) | [divergent-design](../workflows/divergent-design.md) |
|---|---|---|
| Core question | "Can this work?" / "How does X behave?" | "Which option should we pick?" |
| Output | Proof-of-concept + findings | Ranked candidates with tradeoff analysis |
| Scope | Single approach, timeboxed (30 min default) | 8–15 candidates, structured pruning |
| Branch | Throwaway | Working branch |

**Rule of thumb:** If you're testing feasibility of one idea, use spike. If you're choosing between multiple viable approaches, use divergent-design.

### Task-decomposition vs Research-plan-implement (for large tasks)

| Factor | [task-decomposition](../workflows/task-decomposition.md) | [research-plan-implement](../workflows/research-plan-implement.md) |
|---|---|---|
| Subsystems involved | 3+ independent areas | Any (often 1–2 areas) |
| Parallelizable | Yes — sub-agents investigate independently | Sequential phases |
| Best when | Sub-investigations don't depend on each other | Research must inform a single coherent plan |

**Rule of thumb:** If the task naturally splits into independent questions that different agents could answer in parallel, use task-decomposition. If the research needs to build a single coherent picture before planning, use research-plan-implement.

## Workflow Reference

| Workflow | One-line summary |
|---|---|
| [research-plan-implement](../workflows/research-plan-implement.md) | Default loop: research → plan → review → implement |
| [divergent-design](../workflows/divergent-design.md) | Structured brainstorming for decisions with multiple options |
| [task-decomposition](../workflows/task-decomposition.md) | Split large tasks into parallel sub-investigations |
| [spike](../workflows/spike.md) | Timeboxed feasibility exploration on a throwaway branch |
| [bug-diagnosis](../workflows/bug-diagnosis.md) | Fast hypothesis-test loop for bugs in known code |
| [codebase-onboarding](../workflows/codebase-onboarding.md) | Structured orientation for unfamiliar codebases |
| [pr-prep](../workflows/pr-prep.md) | Package work for async review (includes review-fix-loop) |
| [branch-strategy](../workflows/branch-strategy.md) | High-throughput feature branches with async review |
| [user-testing-workflow](../workflows/user-testing-workflow.md) | Plan, run, and interpret usability tests |
