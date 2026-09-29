---
name: research-plan-implement
description: >
  Route a feature or unclear bug that spans files into workflows/research-plan-implement.md. Not for one-line fixes, several unrelated asks (parallel-worktrees) or choosing among 3+ approaches (divergent-design). Triggers: "implement X", "add a feature", "fix this bug".
---

> On bad output, see guides/skill-recovery.md

# Research → Plan → Implement (router)

Exists so the default development loop competes at the skill-selection layer, where a long workflow doc otherwise loses to "just start editing." Does not re-implement the workflow — routes into it.

## When to use

Any feature or bug fix that touches more than one file, needs the codebase understood first, or has an unclear root cause. Not for trivial edits (a typo, a config value, a one-line fix whose cause is known); not for a message holding several unrelated tasks (`parallel-worktrees`); not for a choice among 3+ approaches (`divergent-design`, which feeds its decision back here). Its hard gate is plan approval before implementation.

## Hand off to the workflow

Read and follow **`workflows/research-plan-implement.md`** end to end: the installed copy at
`~/.claude/workflows/research-plan-implement.md`, or this repo's own file when working inside
claude-workflows. Never follow a same-named file that belongs to another project.
Do not restate the workflow here; keep this file a pointer.
