---
name: codebase-onboarding
description: >
  Route orientation in an unfamiliar or long-untouched codebase into
  workflows/codebase-onboarding.md: entry points, architecture map, execution surface, key
  flows, conventions, build/test commands, known unknowns, in one orientation doc. Triggers:
  "help me understand this repo", "I just cloned this", "how is this codebase organized",
  "where does X live", "onboard me", "I'm back after a while", or a first session in a
  project with no onboarding doc.
when: Starting work in a codebase with no docs/working/onboarding-*.md and no docs/thoughts/, or returning after a long absence
---

> On bad output, see guides/skill-recovery.md

# Codebase Onboarding (router)

Exists so a first session in an unfamiliar codebase builds a reusable map before task
work starts. Does not re-implement the workflow — routes into it.

## When to use

Inherited, cloned or returned-cold codebases, and RPI research that cannot be scoped
because it is unclear where to look. Not for projects you started from scratch.

## Hand off to the workflow

Read and follow **`workflows/codebase-onboarding.md`** end to end (installed copy:
`~/.claude/workflows/codebase-onboarding.md`). Do not restate it here; this file is a
stub so the router and the workflow cannot drift apart. Its output is
`docs/working/onboarding-{project}.md`, which later RPI research loads instead of
re-exploring.
