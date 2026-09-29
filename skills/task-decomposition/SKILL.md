---
name: task-decomposition
description: >
  Route one task that spans several subsystems into workflows/task-decomposition.md: split
  the research into independent sub-investigations, capture interface contracts, dispatch
  research subagents, reconcile, then plan and implement sequentially. Not for several
  unrelated tasks in one message (that is parallel-worktrees). Triggers: "this touches auth,
  billing and notifications", "migrate X, Y and Z to the new API", "cross-cutting change".
when: A single task needs research in several independent subsystems before it can be planned
---

> On bad output, see guides/skill-recovery.md

# Task Decomposition (router)

Exists so research on a multi-subsystem task fans out in parallel with explicit
interface contracts, rather than running sequentially and drifting. Does not
re-implement the workflow — routes into it.

## When to use

One task whose research splits into areas that can be studied independently.
Implementation stays sequential in the main agent. If the message holds several
unrelated tasks instead, use `parallel-worktrees`.

## Hand off to the workflow

Read and follow **`workflows/task-decomposition.md`** end to end (installed copy:
`~/.claude/workflows/task-decomposition.md`). Do not restate it here; keep this file a pointer and add nothing
the workflow does not say. It ends by entering
`research-plan-implement` with the synthesized research doc.
