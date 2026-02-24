# Research → Plan → Implement Workflow

## When to use
- Any feature implementation that touches more than one file
- Bug fixes where the root cause isn't immediately obvious
- Any task where Claude needs to understand existing code before changing it
- Default workflow for non-trivial development work

This is the most common workflow. When in doubt, use this one.

## Working documents

This workflow produces markdown artifacts in `docs/working/` within the project:

- `docs/working/research-{topic}.md` — what Claude learned about the relevant codebase
- `docs/working/plan-{topic}.md` — the implementation plan

These files are **committed to the repo** but treated as disposable. They exist to support the current task and to give collaborators visibility into Claude's understanding. They are freely overwritten or replaced as work progresses. If something in a working doc has lasting value, move it to `docs/thoughts/` (living knowledge) or `docs/decisions/` (finalized decisions).

To keep working docs out of PR diffs by default, add this to the project's `.gitattributes`:

```
docs/working/** linguist-generated
```

This collapses them in GitHub's diff view — reviewers can still expand them for additional context but aren't expected to review them thoroughly. A template is available at `templates/gitattributes-snippet.txt` in this repo.

The `{topic}` naming is flexible — use whatever makes the file findable during the session. Short kebab-case descriptors are fine: `research-auth-flow.md`, `plan-inline-edit-api.md`.

## Process

### 1. Scope — define what this loop covers

Before researching, state the scope of this iteration in one sentence: what specific question, feature, or fix is this loop addressing? 

In a multi-loop session, each loop gets its own scope. A loop can build on the previous one's artifacts, but the scope should be clear enough that the research and plan docs can be evaluated independently.

### 2. Research — understand before proposing

Read the relevant parts of the codebase and produce a research doc in `docs/working/`. This document should include:

- **Scope**: The one-sentence scope from step 1.
- **What exists**: Which files, functions, and patterns are relevant. Not just names — summarize what they do and how they connect.
- **Invariants**: What must not break. Existing APIs, data contracts, auth flows, caching layers, conventions other code depends on.
- **Prior art**: Does the codebase already solve a similar problem? If so, describe that solution — the new implementation should be consistent with it unless there's a reason to diverge.
- **Gotchas**: Anything surprising, non-obvious, or fragile in the relevant code.

The research must be thorough. Read the actual implementations, not just signatures. If the research is wrong, everything downstream will be wrong.

If a previous loop's research doc covers overlapping territory, update it rather than creating a new file — but clearly mark what's new or changed.

**Human checkpoint**: The user should review the research doc — this is the cheapest place to fix misunderstandings. However, this checkpoint should not block progress. Claude should proceed to the plan step immediately after producing the research doc. If the user provides corrections to the research later, the plan may need to be revised or scrapped, and that's acceptable — a plan built on wrong research is cheap to discard, but idle time waiting for review is expensive.

The gate on **implementation** is firm: do not implement until the plan has been reviewed and approved. The gate on **planning** is soft: plan speculatively, expect revision.

### 3. Plan — specify the implementation steps

Produce a plan doc in `docs/working/`. Include:

- **Scope**: Same scope statement, linking to the research doc.
- **Approach**: 2-3 sentences on the high-level strategy, referencing findings from research.
- **Steps**: Numbered list of concrete implementation actions. Each step should be:
  - Specific enough that someone could do it without re-reading the research
  - Small enough to be one commit
  - Ordered by dependency (what must exist before what)
- **Testing strategy**: How to verify the implementation works. Specific test cases, not "add tests."
- **Risks**: What could go wrong, what's uncertain, what you'd want a reviewer to scrutinize.

### 4. Annotate — human reviews and approves before implementation

This is the hard gate. Research and planning can proceed speculatively, but **implementation does not begin until the user has reviewed the plan** (and any pending research feedback has been incorporated).

The user reviews the plan and provides corrections — either by editing the plan doc inline or by describing changes conversationally. Either method is fine; what matters is that the plan is revised before implementation begins.

If the user's research feedback invalidates the plan, discard and rewrite the plan rather than patching it. A fresh plan on corrected research is better than a Frankenstein revision.

Common annotations:
- Corrections: "Step 3 should use X instead of Y because..."
- Clarifications: "Step 5 is ambiguous — do you mean A or B?"
- Additions: "You're missing a step: we also need to update Z"
- Scope changes: "Drop steps 6-8, that's a separate task"

Claude revises the plan doc based on feedback. This cycle repeats until the user is satisfied. Two rounds is typical; more than three suggests the research phase missed something — consider going back to step 2.

### 5. Implement — follow the plan

Implement the plan one step at a time. Commit after each step with a message referencing the plan: `feat: add user model (per plan-inline-edit-api step 1)`.

If a step turns out to be wrong or incomplete during implementation, **stop and update the plan doc first** rather than improvising. The plan is the shared source of truth — silent deviations undermine the review process.

**Context management**: If the session context is getting heavy (many prior loops, large amount of code read), consider starting a fresh session and loading the plan doc. The plan should contain everything needed to implement without the prior conversational context. But this is a judgment call, not a hard rule — if context is still fresh and the task is flowing, continue in the same session.

### 6. Verify and loop

- Run all project checks (lint, build, tests)
- Update `docs/thoughts/` if the implementation revealed new understanding worth preserving
- If there's another loop to do in this session, return to step 1 with a new scope
- If this was the final loop, proceed to the pr-prep workflow if opening a PR

## When to skip or abbreviate

- **Trivial changes** (typo fixes, config tweaks, single-line bug fixes): Skip entirely, just make the change.
- **Changes where you already understand the code**: Skip research, go straight to plan. Or update an existing research doc rather than writing from scratch.
- **Urgent hotfixes**: Abbreviate to a mental plan, but write a retroactive decision doc if the fix was non-obvious.
- **Continuation of a previous session's work**: If research and plan docs already exist and are still accurate, pick up from where implementation left off. Verify the docs are still current before proceeding.
