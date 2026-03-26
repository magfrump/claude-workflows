# Research → Plan → Implement Workflow

## When to use
- Any feature implementation that touches more than one file
- Bug fixes where the root cause isn't immediately obvious
- Any task where Claude needs to understand existing code before changing it
- Default workflow for non-trivial development work

This is the most common workflow. When in doubt, use this one.

## When to pivot

- **→ Spike**: If research reveals a feasibility question you can't answer by reading code, pivot to a spike. Your research doc's invariants and relevant files become context for defining the spike question.
- **→ Divergent Design**: If research surfaces 3+ viable approaches (see step 2 for signals), invoke DD as a sub-procedure. Carry your research doc's constraints into DD's diagnosis step; DD's decision feeds back into your plan.
- **← From Spike**: When a spike recommends "proceed," load its RPI seed section as a head start on research — don't re-derive what the spike already learned.
- **← From Onboarding**: The onboarding doc's architecture map and key flows replace the "explore from scratch" part of research. Start research scoped to your specific task, not the whole codebase.

## Working documents

This workflow produces markdown artifacts in `docs/working/` within the project:

- `docs/working/research-{topic}.md` — what Claude learned about the relevant codebase
- `docs/working/plan-{topic}.md` — the implementation plan

These files are **committed to the repo** but treated as disposable. They exist to support the current task and to give collaborators visibility into Claude's understanding. They are freely overwritten or replaced as work progresses. If something in a working doc has lasting value, move it to `docs/thoughts/` (living knowledge) or `docs/decisions/` (finalized decisions).

**Freshness tracking**: Because RPI working docs are disposable per-task artifacts, they do not need `Last verified` or `Relevant paths` fields. If a research doc is promoted to `docs/thoughts/` for long-term reference, add those fields at promotion time. See `guides/doc-freshness.md` for the freshness tracking heuristic.

To keep working docs out of PR diffs by default, add this to the project's `.gitattributes`:

```
docs/working/** linguist-generated
```

This collapses them in GitHub's diff view — reviewers can still expand them for additional context but aren't expected to review them thoroughly. A template is available at `templates/gitattributes-snippet.txt` in this repo.

The `{topic}` naming is flexible — use whatever makes the file findable during the session. Short kebab-case descriptors are fine: `research-auth-flow.md`, `plan-inline-edit-api.md`.

## Process

### 1. Scope (essential) — define what this loop covers

Before researching, state the scope of this iteration in one sentence: what specific question, feature, or fix is this loop addressing? 

In a multi-loop session, each loop gets its own scope. A loop can build on the previous one's artifacts, but the scope should be clear enough that the research and plan docs can be evaluated independently.

### 2. Research (essential) — understand before proposing

Read the relevant parts of the codebase and produce a research doc in `docs/working/`. This document should include:

- **Scope**: The one-sentence scope from step 1.
- **What exists**: Which files, functions, and patterns are relevant. Not just names — summarize what they do and how they connect.
- **Invariants**: What must not break. Existing APIs, data contracts, auth flows, caching layers, conventions other code depends on.
- **Prior art**: Does the codebase already solve a similar problem? If so, describe that solution — the new implementation should be consistent with it unless there's a reason to diverge.
- **Gotchas**: Anything surprising, non-obvious, or fragile in the relevant code.

The research must be thorough. Read the actual implementations, not just signatures. If the research is wrong, everything downstream will be wrong.

If a previous loop's research doc covers overlapping territory, update it rather than creating a new file — but clearly mark what's new or changed.

**Design decisions during research**: If research reveals a genuine design choice — multiple viable approaches, an architectural fork, a library selection — invoke the **Divergent Design workflow** (`divergent-design.md`) as a sub-procedure before proceeding to the plan step. DD's output (a documented decision in `docs/decisions/`) becomes an input to the plan. DD's 80% confidence threshold governs whether the *design decision* can be resolved autonomously; RPI's implementation gate (step 4) still applies independently. In other words: DD may resolve the "what approach" question without user input, but the user still reviews the plan before implementation begins.

Signals that you've hit a design decision:
- Research surfaces 3+ viable approaches with non-obvious tradeoffs
- The "right" approach depends on constraints you can't fully evaluate (team preferences, future roadmap, performance targets)
- You're tempted to pick an approach and justify it rather than comparing alternatives

**Human checkpoint**: The user should review the research doc — this is the cheapest place to fix misunderstandings. However, this checkpoint should not block progress. Claude should proceed to the plan step immediately after producing the research doc. If the user provides corrections to the research later, the plan may need to be revised or scrapped, and that's acceptable — a plan built on wrong research is cheap to discard, but idle time waiting for review is expensive.

The gate on **implementation** is firm: do not implement until the plan has been reviewed and approved. The gate on **planning** is soft: plan speculatively, expect revision.

### 3. Plan (essential) — specify the implementation steps

Produce a plan doc in `docs/working/`. Include:

- **Scope**: Same scope statement, linking to the research doc.
- **Approach**: 2-3 sentences on the high-level strategy, referencing findings from research.
- **Steps**: Numbered list of concrete implementation actions. Each step should be:
  - Specific enough that someone could do it without re-reading the research
  - Small enough to be one commit
  - Ordered by dependency (what must exist before what)
- **Size estimate**: For each step (or for the plan as a whole if steps are small), include a rough size estimate — e.g., "~50 lines in a new file", "~20 lines added to existing handler", "minor wiring change." These don't need to be precise; the goal is to flag when a step is unexpectedly large and to catch cases where a single file would grow beyond a reasonable size. If a step would push a file past **500 lines**, note that explicitly and consider splitting the file as part of the plan.
- **Test specification**: Tests are a design artifact, not a verification afterthought. Structure this section as a table or list with one entry per test case:

  | Test case | Expected behavior | Level | Diagnostic expectation |
  |-----------|------------------|-------|----------------------|
  | *What scenario* | *What should happen* | *unit / integration / characterization / property* | *What the failure output should show* |

  **Choosing a test level:**
  - **Unit**: Isolated function/method behavior. Use when the logic is self-contained and has no significant dependencies.
  - **Integration**: Interactions between components, databases, APIs, or external services. Use when the behavior depends on how parts connect.
  - **Characterization**: Locks in existing behavior before refactoring. Use when you need a safety net for code you're about to change (see also: Refactoring variant below).
  - **Property**: Invariants that should hold across many inputs (e.g., "output is always sorted", "round-trip encode/decode is identity"). Use when example-based tests would miss edge cases.

  Other levels (e.g., end-to-end, snapshot, contract) are valid; the `test-strategy` skill has a full taxonomy.

  **Diagnostic expectations**: For each test, specify what information should be visible on failure — not just pass/fail, but: expected vs. actual values, relevant state at the point of failure, and enough context to diagnose without re-running or reading implementation code. Examples: "show the full diff between expected and actual output", "log the request payload that triggered the error", "print the state of the queue before and after the operation."

  Avoid logging secrets, credentials, or PII in diagnostic output — use placeholder values in test fixtures for sensitive data.

  For simple features, this section can be brief (a few test cases in prose). For complex features, the table format helps ensure coverage. The human designs the test constraints; the LLM translates them into runnable test code.

- **Risks**: What could go wrong, what's uncertain, what you'd want a reviewer to scrutinize.

### 4. Annotate (recommended) — human reviews and approves before implementation

This is the hard gate. Research and planning can proceed speculatively, but **implementation does not begin until the user has reviewed the plan** (and any pending research feedback has been incorporated).

The user reviews the plan and provides corrections — either by editing the plan doc inline or by describing changes conversationally. Either method is fine; what matters is that the plan is revised before implementation begins.

If the user's research feedback invalidates the plan, discard and rewrite the plan rather than patching it. A fresh plan on corrected research is better than a Frankenstein revision.

Common annotations:
- Corrections: "Step 3 should use X instead of Y because..."
- Clarifications: "Step 5 is ambiguous — do you mean A or B?"
- Additions: "You're missing a step: we also need to update Z"
- Scope changes: "Drop steps 6-8, that's a separate task"

Claude revises the plan doc based on feedback. This cycle repeats until the user is satisfied. Two rounds is typical; more than three suggests the research phase missed something — consider going back to step 2.

### 5. Implement (essential) — tests first, then code

#### Test-first gate

Before implementing feature code, write the tests specified in the plan's test specification section. Commit the tests separately: `test: add tests for X (per plan-Y step N)`. These tests should fail — they encode the behavior that doesn't exist yet.

**Human checkpoint**: The user reviews the test code before implementation begins. This confirms the tests match their intent — catching specification mismatches is cheapest here, before implementation work is invested. Include a bulleted summary of what each test verifies alongside the test code, so the human can review intent in prose before spot-checking code. Like the research checkpoint, this should not block progress indefinitely; if the user doesn't respond promptly, proceed with implementation but flag that tests haven't been reviewed.

If test review reveals mismatches with the human's intent, revise the tests (and update the plan's test specification) before proceeding.

#### Implementation

Implement the plan one step at a time. Commit after each step with a message referencing the plan: `feat: add user model (per plan-inline-edit-api step 1)`.

If a step turns out to be wrong or incomplete during implementation, **stop and update the plan doc first** rather than improvising. The plan is the shared source of truth — silent deviations undermine the review process.

**File size discipline**: Keep individual files under **500 lines**. If an implementation step would push a file past this threshold, split it before continuing. This applies to both new files and modifications to existing ones — if an existing file is already near the limit, factor out a coherent subset before adding to it. The 500-line limit is a guideline, not a hard rule; a 520-line file with cohesive logic is fine, but a 700-line file signals that something should have been split earlier.

**Context management**: If the session context is getting heavy (many prior loops, large amount of code read), consider starting a fresh session and loading the plan doc. The plan should contain everything needed to implement without the prior conversational context. But this is a judgment call, not a hard rule — if context is still fresh and the task is flowing, continue in the same session. When ending a session to start fresh, write a handoff doc first (see step 6, "Session handoff") so the next session knows exactly where to resume.

### 6. Verify and loop (recommended)

- Run all project checks (lint, build, tests)
- Update `docs/thoughts/` if the implementation revealed new understanding worth preserving
- If there's another loop to do in this session, return to step 1 with a new scope
- If this was the final loop, proceed to the pr-prep workflow if opening a PR

#### Session handoff (optional)

When ending a session mid-task — because context is getting heavy, you're switching to a different task, or the workday is ending — write a handoff doc so the next session can pick up without re-deriving state from scratch.

Save it to `docs/working/handoff-{topic}.md`, overwriting any previous handoff for the same topic. Use this template:

```markdown
# Handoff: {topic}
Date: {YYYY-MM-DD}
Branch: {current branch}

## Accomplished this session
- [What was completed — reference commit hashes or plan steps]

## Unfinished work
- [What remains — be specific about which plan step you're on and what's left in it]

## Open questions
- [Decisions deferred, ambiguities encountered, things that need human input]

## Key file paths
- [Files the next session should read first to rebuild context]

## Next steps
- [Concrete first action for the next session — not "continue implementing" but "implement step 4 of plan-X, starting with the handler in src/api/"]
```

The next session should load the handoff doc, the plan doc, and (if needed) the research doc. The handoff tells you *where you are*; the plan tells you *where you're going*; the research tells you *why*.

A handoff doc is not necessary when a session ends at a clean boundary — all plan steps complete, PR opened, or no work in progress. It's for the in-between case where conversational context would otherwise be lost.

## When to skip or abbreviate

- **Trivial changes** (typo fixes, config tweaks, single-line bug fixes): Skip entirely, just make the change.
- **Changes where you already understand the code**: Skip research, go straight to plan. Or update an existing research doc rather than writing from scratch.
- **Urgent hotfixes**: Abbreviate to a mental plan, but write a retroactive decision doc if the fix was non-obvious.
- **Continuation of a previous session's work**: If research and plan docs already exist and are still accurate, pick up from where implementation left off. If a handoff doc exists (`docs/working/handoff-{topic}.md`), load it first — it captures where the previous session stopped and what to do next. Verify the docs are still current before proceeding.

## Variant: Refactoring

When the task is a refactoring (restructuring code without changing behavior), RPI applies with these modifications:

### Research phase additions
- **Characterize current behavior**: Document what the code does today — inputs, outputs, side effects, error cases. This becomes the specification that the refactoring must preserve.
- **Identify callers and dependents**: Map everything that depends on the code being refactored. These are the blast radius of a mistake.
- **Check existing test coverage**: If the code has tests, they become your safety net. If it doesn't, writing characterization tests is step 1 of the plan, not an afterthought.

### Plan phase additions
- **Incremental steps are mandatory**: Each step must leave the codebase in a working state. No step should break behavior, even temporarily. If a refactoring can't be done incrementally, that's a risk worth flagging.
- **Characterization tests first**: If existing coverage is insufficient, the plan's first steps should add tests that lock in current behavior before any structural changes begin.
- **Mechanical vs. judgmental changes**: Separate steps that are mechanical (renames, moves, extract-function) from steps that involve judgment (changing abstractions, restructuring interfaces). Mechanical steps are low risk; judgmental steps need more scrutiny.

### Implementation phase additions
- **Run tests after every step**: Not just at the end. Each commit should pass the full test suite. If tests break, the step was wrong — fix the step, don't fix the tests to match the new code (unless the test was testing implementation details, not behavior).
- **Use language-level refactoring tools when available**: IDE rename, extract method, and move operations are safer than manual edits. Note in the commit when a tool was used.
