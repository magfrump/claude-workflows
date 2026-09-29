---
name: review-fix-loop
description: >
  Route acting on code-review findings into workflows/review-fix-loop.md: triage by tier,
  fix, record declined findings in the override log, re-review only the delta, stop at 3
  iterations or 2 clean passes. Triggers: "fix the review findings", "address the review",
  "iterate until clean", "re-review", "the review came back red", "work through the rubric".
when: A code-review rubric exists for the current branch and its findings are being fixed or declined
---

> On bad output, see guides/skill-recovery.md

# Review-Fix Loop (router)

Exists so fixing review findings follows the convergence rules (tiers, override-log
rows, delta re-review, iteration cap) instead of an open-ended fix-and-rerun cycle.
Does not re-implement the workflow — routes into it.

## When to use

After a `code-review` run on a branch, whenever its findings are being worked. Usually
entered from `pr-prep` step 3, but applies whenever a rubric is being acted on.

## Hand off to the workflow

Read and follow **`workflows/review-fix-loop.md`** end to end (installed copy:
`~/.claude/workflows/review-fix-loop.md`). Do not restate it here; this file is a stub so
the router and the workflow cannot drift apart. The tier definitions it acts on live in
`skills/code-review/references/rubric.md`.
