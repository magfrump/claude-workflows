---
name: parallel-worktrees
description: >
  Route a message that bundles 2+ independent tasks into workflows/parallel-worktrees.md:
  restate them as a numbered list, route each item on its own, implement independent items in
  parallel git worktrees, then review and merge each item as soon as it is clean. Triggers:
  "a few things:", "couple of bugs", "here's the feedback", a numbered or bulleted list of
  asks, several distinct requests in one message.
when: One message contains two or more tasks that share no files, state or ordering
---

> On bad output, see guides/skill-recovery.md

# Parallel Worktrees (router)

Exists so a batch of independent asks is split and fanned out instead of collapsing into
one sequential pass. Does not re-implement the workflow — routes into it.

## When to use

Ask: "do these share files or an order?" No → this skill. Yes → one task, so use
`research-plan-implement` or `task-decomposition`.

## Hand off to the workflow

Read and follow **`workflows/parallel-worktrees.md`** end to end (installed copy:
`~/.claude/workflows/parallel-worktrees.md`). Do not restate it here; this file is a stub
so the router and the workflow cannot drift apart. It includes the manual `git worktree
add` fallback for when Agent-tool worktree isolation fails.
