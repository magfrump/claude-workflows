---
name: spike
description: >
  Route a feasibility question into workflows/spike.md: graveyard check, one-sentence question
  with go/no-go criteria, a timebox, throwaway branch, and a findings record with an RPI or DD
  seed. For "can this work?", not "build this". Triggers: "can we use X", "is X feasible",
  "will X work", "does X support Y", "try out X", "proof of concept", "prototype", "spike".
when: The question is whether an approach, library or API can work, before committing to build with it
---

> On bad output, see guides/skill-recovery.md

# Spike (router)

Exists so feasibility questions get a timebox and a recorded verdict instead of turning
into unplanned implementation. Does not re-implement the workflow — routes into it.

## When to use

The question is "can this work?" or "how does X behave?" and cannot be answered by
reading the code. If the answer is already known and the task is to build it, use
`research-plan-implement` instead.

## Hand off to the workflow

Read and follow **`workflows/spike.md`** end to end (installed copy:
`~/.claude/workflows/spike.md`). Do not restate it here; this file is a stub so the router
and the workflow cannot drift apart. Its first step greps
`docs/thoughts/spike-graveyard.md` for prior abandoned attempts.
