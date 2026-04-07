# Research → Plan → Implement Workflow

## When to use
- Any feature implementation that touches more than one file
- Bug fixes where the root cause isn't immediately obvious
- Any task where Claude needs to understand existing code before changing it

This is the most common workflow. When in doubt, use this one.

## When to pivot

- **→ Spike**: If research reveals a feasibility question you can't answer by reading code. Your research doc's invariants become context for the spike.
- **→ Divergent Design**: If research surfaces 3+ viable approaches, invoke DD as a sub-procedure. DD's decision feeds back into your plan.
- **← From Spike**: Load the spike's RPI seed section as a head start on research.
- **← From Onboarding**: The onboarding doc's architecture map replaces broad exploration. Start research scoped to your specific task.
- **→ Bug Diagnosis**: For bugs in code you already understand, `bug-diagnosis.md` is faster — it skips plan approval and iterates rapidly. Use RPI for bugs in unfamiliar code. If RPI research reveals the root cause, skip to bug-diagnosis's Fix and Verify steps.
- **← From Bug Diagnosis**: If debugging stalls after 3+ failed hypotheses, pivot here. Failed hypotheses become input documenting what the bug *isn't*.

## Working documents

This workflow produces markdown artifacts in `docs/working/`:

- `docs/working/research-{topic}.md` — what Claude learned about the relevant codebase
- `docs/working/plan-{topic}.md` — the implementation plan

These files are **committed to the repo** but treated as disposable. They exist to support the current task and give collaborators visibility. If something has lasting value, move it to `docs/thoughts/` or `docs/decisions/`.

To collapse working docs in GitHub diffs, add `docs/working/** linguist-generated` to `.gitattributes`.

## Process

### 1. Scope (essential) — define what this loop covers

State the scope in one sentence: what specific question, feature, or fix is this loop addressing?

In a multi-loop session, each loop gets its own scope and can build on previous artifacts.

**Done when...**
- [ ] Scope is stated in one sentence that a teammate could read without additional context
- [ ] The scope clearly identifies the specific question, feature, or fix this loop addresses
- [ ] If this is a multi-loop session, the scope is distinct from previous loops

### 2. Research (essential) — understand before proposing

Read the relevant codebase and produce a research doc in `docs/working/` with:

- **Scope**: The one-sentence scope from step 1.
- **What exists**: Which files, functions, and patterns are relevant — summarize what they do and how they connect.
- **Invariants**: What must not break. Existing APIs, data contracts, auth flows, conventions.
- **Prior art**: Does the codebase already solve a similar problem? Describe it.
- **Gotchas**: Anything surprising, non-obvious, or fragile.

Read actual implementations, not just signatures. If the research is wrong, everything downstream will be wrong.

**Design decisions during research**: If research reveals 3+ viable approaches, invoke **Divergent Design** (`divergent-design.md`) before proceeding. DD's output becomes input to the plan. DD's 80% confidence threshold governs the design decision; RPI's implementation gate (step 4) still applies independently.

**Human checkpoint**: The user should review the research doc — cheapest place to fix misunderstandings. However, Claude should proceed to planning immediately. The gate on **implementation** is firm; the gate on **planning** is soft.

**Done when...**
- [ ] Research doc exists in `docs/working/` with all required sections (Scope, What exists, Invariants, Prior art, Gotchas)
- [ ] Actual implementations were read, not just signatures or file names
- [ ] Every invariant listed can be verified by pointing to specific code that depends on it
- [ ] If 3+ viable approaches surfaced, a Divergent Design sub-procedure was invoked (or a note explains why it wasn't needed)

### 3. Plan (essential) — specify the implementation steps

Produce a plan doc in `docs/working/` with:

- **Scope**: Same scope statement, linking to the research doc.
- **Approach**: 2-3 sentences on the high-level strategy.
- **Steps**: Numbered implementation actions. Each step should be specific enough to implement without re-reading research, small enough to be one commit, and ordered by dependency.
- **Size estimate**: Rough size per step (e.g., "~50 lines in new file"). Flag any step that would push a file past **500 lines**.
- **Test specification**: One entry per test case:

  | Test case | Expected behavior | Level | Diagnostic expectation |
  |-----------|------------------|-------|----------------------|
  | *Scenario* | *What should happen* | *unit / integration / characterization / property* | *What failure output should show* |

  Choose test level based on isolation needs. For each test, specify what information should be visible on failure — not just pass/fail, but enough to diagnose without re-running.

- **Risks**: What could go wrong, what's uncertain.

**Done when...**
- [ ] Plan doc exists in `docs/working/` with all required sections (Scope, Approach, Steps, Size estimate, Test specification, Risks)
- [ ] Each step is specific enough that someone could implement it without re-reading the research doc
- [ ] Each step is small enough to be one commit
- [ ] Test specification includes at least one test case per behavioral requirement
- [ ] No single step would push a file past 500 lines without an explicit note

### 4. Annotate (recommended) — human reviews before implementation

This is the hard gate. **Implementation does not begin until the user has reviewed the plan.**

The user provides corrections by editing the plan or describing changes conversationally. Claude revises accordingly. Two rounds is typical; more than three suggests research missed something.

**Done when...**
- [ ] User has explicitly approved the plan (not just the research)
- [ ] All user corrections have been incorporated into the plan doc (not just acknowledged conversationally)
- [ ] If research feedback invalidated the plan, the plan was rewritten from scratch rather than patched
- [ ] Plan doc reflects the final agreed approach — no unresolved "TBD" or "discuss" markers remain

### 5. Implement (essential) — tests first, then code

#### Test-first gate

Write the tests from the plan's test specification first. Commit separately: `test: add tests for X (per plan-Y step N)`. These tests should fail initially.

**Human checkpoint**: User reviews test code before implementation. Include a bulleted summary of what each test verifies. Like the research checkpoint, proceed if no response — but flag that tests haven't been reviewed.

#### Implementation

Implement one step at a time. Commit after each: `feat: add user model (per plan-inline-edit-api step 1)`.

If a step turns out wrong, **update the plan doc first** rather than improvising. Keep files under **500 lines** — split before continuing if approaching the limit.

**Context management**: If context is heavy, start a fresh session and load the plan doc. Write a handoff doc first (see step 6).

**Done when...**
- [ ] All plan steps are implemented with one commit per step
- [ ] Tests from the test specification pass
- [ ] Each commit message references the plan (e.g., "per plan-X step N")
- [ ] Any deviations from the plan were written back to the plan doc before implementation continued
- [ ] No file exceeds 500 lines without an explicit justification

### 6. Verify and loop (recommended)

- Run all project checks (lint, build, tests)
- Update `docs/thoughts/` if implementation revealed new understanding
- If another loop, return to step 1; if final, proceed to pr-prep workflow

**Done when...**
- [ ] All project checks pass (lint, build, tests)
- [ ] `docs/thoughts/` updated if implementation revealed new understanding worth preserving
- [ ] If another loop follows, new scope is defined; if final loop, PR prep is ready to begin
- [ ] If ending mid-task, a handoff doc exists in `docs/working/handoff-{topic}.md`

#### Session handoff (when ending mid-task)

Save to `docs/working/handoff-{topic}.md`:

```markdown
# Handoff: {topic}
Date: {YYYY-MM-DD} | Branch: {current branch}

## Accomplished
- [What was completed — reference commit hashes or plan steps]

## Remaining
- [Which plan step you're on and what's left]

## Open questions
- [Decisions deferred, ambiguities, things needing human input]

## Next action
- [Concrete first action — not "continue implementing" but "implement step 4, starting with the handler in src/api/"]
```

## When to skip or abbreviate

- **Trivial changes** (typos, config, single-line fixes): Skip entirely.
- **Code already understood**: Skip research or update existing doc.
- **Urgent hotfixes**: Mental plan, but write a retroactive decision doc if non-obvious.
- **Continuation**: If research/plan docs exist and a handoff doc is available, load it and resume.

## Variant: Refactoring

RPI applies with these modifications:

**Research additions**: Document current behavior (inputs, outputs, side effects) as the specification to preserve. Map callers and dependents. Check existing test coverage — if insufficient, writing characterization tests is step 1 of the plan.

**Plan additions**: Each step must leave the codebase working. Characterization tests come first if coverage is insufficient. Separate mechanical changes (renames, moves) from judgmental changes (restructuring abstractions).

**Implementation additions**: Run tests after every step, not just at the end. Use language-level refactoring tools when available.
