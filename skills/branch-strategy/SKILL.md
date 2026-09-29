---
name: branch-strategy
description: >
  Route multi-branch integration into the branch-strategy workflow: dev integration branch, rebuilding it from open PRs, stale branches. Not for one branch (pr-prep). Triggers: "merge all open PRs", "build an integration branch", "rebuild dev".
---

> On bad output, see guides/skill-recovery.md

# Branch Strategy (router)

Exists so multi-branch integration follows the documented procedure, including its approval gate on replacing a shared branch. Does not re-implement the workflow — routes into it.

## When to use

Many concurrent feature branches, a dev integration branch, consolidating open PRs, or stale-branch cleanup. A single feature branch needs none of this. Replacing a shared branch always needs explicit user approval, in any operating mode.

## Hand off to the workflow

Read and follow **`workflows/branch-strategy.md`** end to end: the installed copy at
`~/.claude/workflows/branch-strategy.md`, or this repo's own file when working inside
claude-workflows. Never follow a same-named file that belongs to another project.
Do not restate the workflow here; keep this file a pointer.
