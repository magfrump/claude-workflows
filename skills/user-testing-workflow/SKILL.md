---
name: user-testing-workflow
description: >
  Route usability-test work into workflows/user-testing-workflow.md: scoping and recruitment
  spec, task and moderator-script design, a hypothesis-framed pilot, session templates,
  severity-rated analysis, SUS scoring and a findings report. Triggers: "user test",
  "usability test", "moderator script", "test this with users", "analyze the session notes",
  "SUS score", "recruit participants".
when: Planning, running or analyzing a usability test with real or recruited users
---

> On bad output, see guides/skill-recovery.md

# User Testing (router)

Exists so usability tests follow the HCI-grounded protocol rather than improvised
sessions. Does not re-implement the workflow — routes into it.

## When to use

Designing a test, writing a moderator script, piloting, or turning session notes into
findings. For reviewing a UI's layout without users, use `ui-visual-review` instead.

## Hand off to the workflow

Read and follow **`workflows/user-testing-workflow.md`** end to end (installed copy:
`~/.claude/workflows/user-testing-workflow.md`). Do not restate it here; this file is a
stub so the router and the workflow cannot drift apart. Its findings report lands at
`docs/working/testing-findings-{topic}.md`.
