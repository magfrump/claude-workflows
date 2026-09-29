---
name: parallel-worktrees
description: >
  Route a message bundling 2+ unrelated tasks into workflows/parallel-worktrees.md: split, route each, build in parallel worktrees. Not for one task spanning subsystems (task-decomposition). Triggers: "a few things:", "couple of bugs", a list of asks.
---

> On bad output, see guides/skill-recovery.md

# Parallel Worktrees (router)

Exists so a batch of independent asks is split and fanned out instead of collapsing into one sequential pass. Does not re-implement the workflow — routes into it.

## When to use

Ask: "do these share files or an order?" No → this skill. Yes → one task, so use `research-plan-implement` or `task-decomposition`. Each item that lands still goes through `pr-prep`.

## Hand off to the workflow

Read and follow **`workflows/parallel-worktrees.md`** end to end: the installed copy at
`~/.claude/workflows/parallel-worktrees.md`, or this repo's own file when working inside
claude-workflows. Never follow a same-named file that belongs to another project.
Do not restate the workflow here; keep this file a pointer.
