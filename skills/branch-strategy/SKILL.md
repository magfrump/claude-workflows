---
name: branch-strategy
description: >
  Route branch-management work into workflows/branch-strategy.md: features off main, a
  disposable dev integration branch, merging main into dev after squash-merges, stale-branch
  triage, and the integration-branch refresh that rebuilds dev from all open PRs. Triggers:
  "merge all open PRs", "build an integration branch", "rebuild dev", "test the open PRs
  together", "which branches are stale", "parallelize 5 features this week".
when: Work involves several concurrent feature branches, an integration branch, or consolidating open PRs
---

> On bad output, see guides/skill-recovery.md

# Branch Strategy (router)

Exists so multi-branch integration follows the documented procedure, including its
approval gate on force-pushing a shared branch. Does not re-implement the workflow —
routes into it.

## When to use

Many concurrent feature branches, a dev integration branch, consolidating open PRs, or
stale-branch cleanup. A single feature branch needs none of this.

## Hand off to the workflow

Read and follow **`workflows/branch-strategy.md`** end to end (installed copy:
`~/.claude/workflows/branch-strategy.md`). Do not restate it here; keep this file a pointer and add nothing
the workflow does not say. Replacing a shared branch always needs
explicit user approval, in any operating mode.
