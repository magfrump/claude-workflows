# Workflow Selection Guide

A prescriptive decision tree for choosing the right workflow given a task type. Start at the top and follow the first matching condition.

> **Canonical source:** The workflow decision tree in `CLAUDE.md` is authoritative. This guide expands on it with disambiguation tips and worked examples. If this guide and CLAUDE.md conflict, CLAUDE.md wins.

## Quick-Start Decision Tree

Evaluate triggers top-to-bottom. Take the **first match**; if none match, default to RPI.

```
Is this a brand-new or unfamiliar codebase?
  YES → codebase-onboarding
  NO  ↓

Does the task involve a design choice with 3+ viable approaches?
  YES → divergent-design
  NO  ↓

Is this a non-trivial feature or bug fix (touches >1 file, root cause unclear)?
  YES → research-plan-implement
  NO  ↓

Does the task touch multiple subsystems that can be investigated independently?
  YES → task-decomposition
  NO  ↓

Is the question "can this work?" or a feasibility/proof-of-concept question?
  YES → spike
  NO  ↓

Is the work ready to open a PR?
  YES → pr-prep (includes review-fix-loop)
  NO  ↓

Planning, running, or analyzing a usability test?
  YES → user-testing-workflow
  NO  ↓

High-throughput multi-branch development with async review?
  YES → branch-strategy
  NO  → Just do it (no workflow needed)
```

### Debugging defaults (not a separate workflow)

Bug-diagnosis is no longer a standalone workflow — its principles have been absorbed into CLAUDE.md's "Debugging defaults" section, which applies to **all** bug-fixing work (whether inside RPI or standalone). Key points:

1. Reproduce first
2. Read the error
3. Hypothesize specifically
4. Test, don't guess
5. Escape hatch at 3 failed hypotheses → pivot to RPI research
6. Fix root cause, not symptom

For complex bugs that need a formal diagnosis log, the template remains in `workflows/bug-diagnosis.md`.

## Disambiguation: Similar Workflows

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
| [codebase-onboarding](../workflows/codebase-onboarding.md) | Structured orientation for unfamiliar codebases |
| [pr-prep](../workflows/pr-prep.md) | Package work for async review (includes review-fix-loop) |
| [branch-strategy](../workflows/branch-strategy.md) | High-throughput feature branches with async review |
| [user-testing-workflow](../workflows/user-testing-workflow.md) | Plan, run, and interpret usability tests |
| [bug-diagnosis](../workflows/bug-diagnosis.md) | Deprecated as standalone; debugging defaults absorbed into CLAUDE.md |
