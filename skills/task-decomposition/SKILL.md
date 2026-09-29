---
name: task-decomposition
description: >
  Route one task spanning several subsystems into the task-decomposition workflow: parallel research, then sequential build. Not for several unrelated asks (parallel-worktrees). Triggers: "this touches auth, billing and jobs", "cross-cutting change".
---

> On bad output, see guides/skill-recovery.md

# Task Decomposition (router)

Exists so research on a multi-subsystem task fans out in parallel with explicit interface contracts, rather than running sequentially and drifting. Does not re-implement the workflow — routes into it.

## When to use

One task whose research splits into areas that can be studied independently; implementation stays sequential. If the message holds several unrelated tasks instead, use `parallel-worktrees`.

## Hand off to the workflow

Read and follow **`workflows/task-decomposition.md`** end to end: the installed copy at
`~/.claude/workflows/task-decomposition.md`, or this repo's own file when working inside
claude-workflows. Never follow a same-named file that belongs to another project.
Do not restate the workflow here; keep this file a pointer.
