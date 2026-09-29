---
name: pr-prep
description: >
  Route finished work into workflows/pr-prep.md before it lands: size gate, review-fix loop,
  history cleanup, verification, then a local merge (solo) or a GitHub PR. Runs code-review
  as one of its steps; use this for the whole landing, code-review alone for a review only.
  Triggers: "ready to merge", "open a PR", "ready for review", "package this up", "ship it",
  "land this branch", "wrap this up".
when: Implementation on a branch is done and the branch is about to be merged or opened for review
---

> On bad output, see guides/skill-recovery.md

# PR Prep (router)

Exists so landing a branch follows the full procedure rather than a bare review or a
bare merge. Does not re-implement the workflow — routes into it.

## When to use

A branch's implementation is complete and it is about to merge locally or go up as a
PR. The workflow picks the delivery path (local merge vs GitHub PR) in its first step.

## Hand off to the workflow

Read and follow **`workflows/pr-prep.md`** end to end (installed copy:
`~/.claude/workflows/pr-prep.md`). Do not restate it here; this file is a stub so the
router and the workflow cannot drift apart. Its review-fix loop is owned by
`workflows/review-fix-loop.md`; its reviews run through the `code-review` skill.
