---
name: pr-prep
description: >
  Route a finished branch into the pr-prep workflow: review-fix loop, cleanup, then local merge or PR. Not for a review with no landing (code-review). Triggers: "ready to merge", "open a PR", "ready for review", "package this up", "land this branch".
---

> On bad output, see guides/skill-recovery.md

# PR Prep (router)

Exists so landing a branch follows the full procedure rather than a bare review or a bare merge. Does not re-implement the workflow — routes into it.

## When to use

A branch's implementation is complete and it is about to merge locally or go up as a PR. For a review with nothing to land, use `code-review` directly. Merging into `main`, pushing, and opening a PR follow the Operating Modes approval rules in the global instructions. The review-fix loop inside it has no router of its own: it runs only inside this workflow.

## Hand off to the workflow

Read and follow **`workflows/pr-prep.md`** end to end: the installed copy at
`~/.claude/workflows/pr-prep.md`, or this repo's own file when working inside
claude-workflows. Never follow a same-named file that belongs to another project.
Do not restate the workflow here; keep this file a pointer.
