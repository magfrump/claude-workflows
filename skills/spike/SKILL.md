---
name: spike
description: >
  Route a feasibility question into workflows/spike.md: timeboxed, throwaway branch, recorded verdict. Not for building something already known to work (research-plan-implement). Triggers: "can we use X", "is X feasible", "will X work", "proof of concept".
---

> On bad output, see guides/skill-recovery.md

# Spike (router)

Exists so feasibility questions get a timebox and a recorded verdict instead of turning into unplanned implementation. Does not re-implement the workflow — routes into it.

## When to use

The question is "can this work?" or "how does X behave?" and cannot be answered by reading the code. If the answer is known and the task is to build it, use `research-plan-implement`.

## Hand off to the workflow

Read and follow **`workflows/spike.md`** end to end: the installed copy at
`~/.claude/workflows/spike.md`, or this repo's own file when working inside
claude-workflows. Never follow a same-named file that belongs to another project.
Do not restate the workflow here; keep this file a pointer.
