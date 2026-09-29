---
name: research-plan-implement
description: >
  Route a non-trivial feature or bug fix into workflows/research-plan-implement.md (RPI): research
  doc, plan doc, plan approval, tests first, then implement. The default for any change that
  touches more than one file or whose root cause is unclear. Triggers: "add a feature",
  "implement X", "fix this bug", "build X", "make X do Y", "change how X works", "refactor X".
when: A task will change more than one file, or needs the existing code understood before it can be changed
---

> On bad output, see guides/skill-recovery.md

# Research → Plan → Implement (router)

Exists so the default development loop competes at the skill-selection layer, where a
long workflow doc otherwise loses to "just start editing." Does not re-implement the
workflow — routes into it.

## When to use

Any feature or bug fix that touches more than one file, needs the codebase understood
first, or has an unclear root cause. Skip it only for trivial edits (a typo, a config
value, a one-line fix whose cause is already known).

## Hand off to the workflow

Read and follow **`workflows/research-plan-implement.md`** end to end (installed copy:
`~/.claude/workflows/research-plan-implement.md`). Do not restate it here; this file is
a stub so the router and the workflow cannot drift apart. Its outputs are
`docs/working/research-{topic}.md`, `plan-{topic}.md` and `checkpoint-{topic}.md`, and its
hard gate is plan approval before implementation.
