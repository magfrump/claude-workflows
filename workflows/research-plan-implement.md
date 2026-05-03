---
value-justification: "Replaces jumping straight to implementation without understanding existing code, which causes rework and accidental breakage."
---

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
- **→ Bug Diagnosis**: For bugs in code you already understand, the **Bug Diagnosis workflow** (`bug-diagnosis.md`) is faster — it skips the plan approval gate and iterates rapidly between hypothesis and test. Use RPI for bugs in unfamiliar code where you need to build a mental model first; use bug-diagnosis when you can already point to the likely area. If RPI research reveals the root cause, you can skip to bug-diagnosis's Fix and Verify steps rather than writing a full plan.
- **← From Bug Diagnosis**: If debugging stalls after 3+ failed hypotheses, pivot here. The failed hypotheses become input to RPI research — they document what the bug *isn't*, narrowing the search space.
- **← From Testing**: When usability testing identifies a feature to build or bug to fix, load the findings report (`user-testing-workflow.md` Phase 4) as input to RPI research. The severity-rated issues and prioritization matrix replace broad exploration — scope research to the specific problem testing surfaced, don't re-derive what testing already established. Reference the findings doc from your research and plan docs for traceability.

## Working documents

This workflow produces markdown artifacts in `docs/working/` within the project:

- `docs/working/research-{topic}.md` — what Claude learned about the relevant codebase
- `docs/working/plan-{topic}.md` — the implementation plan
- `docs/working/checkpoint-{topic}.md` — curated context artifact for implementation session handoff (generated at the end of the plan phase)

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

**Done when...**
- [ ] Scope is stated in one sentence that a teammate could read without additional context
- [ ] The scope clearly identifies the specific question, feature, or fix this loop addresses
- [ ] If this is a multi-loop session, the scope is distinct from previous loops

### 2. Research (essential) — understand before proposing

Read the relevant parts of the codebase and produce a research doc in `docs/working/`. Optional copy-paste scaffolds for common research types (new feature, bug, refactor) are available in `guides/research-scaffolds.md`. The doc must begin with the standard three-line header described below, then include the body sections that follow.

**Header (required, top of file — three lines, in this order):**

- **Goal**: One sentence — what this loop is trying to achieve. This is the same one-sentence scope statement from step 1.
- **Project state**: One sentence — branch context, written as `<what this branch delivers> · <position in larger initiative, or "standalone"> · <blocked on, or "not blocked">`. Same three facts the old multi-field lead block carried, compressed to one scannable line.
- **Task status**: Lifecycle keyword from `in-progress | blocked | paused | complete`, optionally followed by a free-form phase note in parens (e.g., `in-progress (research drafted, plan next)`). The keyword is required; the parenthetical is optional but recommended whenever a phase note would help a re-reader orient.

The header mirrors the sub-agent goal-preamble pattern (see `patterns/orchestrated-review.md`) but applies it to the working doc itself: three named anchors that pin the doc to the user's outcome, the branch's place in the broader effort, and the doc's lifecycle. The intent is drift surfacing — every mid-task re-read should re-verify these three lines against reality. Update the **Task status** line whenever the doc is read or revised; if any line no longer matches reality, fix it before doing anything else with the doc. The header lives in the spec rather than as an optional pre-block precisely so the convention survives maintenance — no linter is needed when the required body content is what enforces it.

After the header, the body must include:

- **What exists**: Which files, functions, and patterns are relevant. Not just names — summarize what they do and how they connect.
- **Invariants**: What must not break. Existing APIs, data contracts, auth flows, caching layers, conventions other code depends on.
- **Prior art**: Does the codebase already solve a similar problem? If so, describe that solution — the new implementation should be consistent with it unless there's a reason to diverge.
- **Gotchas**: Anything surprising, non-obvious, or fragile in the relevant code.

The research must be thorough. Read the actual implementations, not just signatures. If the research is wrong, everything downstream will be wrong.

**Confidence-provenance tags**: When stating facts in the research doc, tag claims with their evidential basis so reviewers can quickly assess reliability:
- **[observed]** — directly verified by reading code, running tests, or checking output. These are the load-bearing facts.
- **[inferred]** — logically derived from observed evidence but not directly confirmed. Example: "function X is called only from Y [inferred from grep — no dynamic dispatch observed]."
- **[assumed]** — believed true but not yet verified. Example: "the API rate limit is 100 req/s [assumed from docs — not tested]."

You don't need to tag every sentence — use tags on claims that downstream decisions depend on, especially invariants and gotchas. The tags are most valuable when they surface [assumed] claims that could invalidate the plan if wrong. A research doc with no [assumed] tags is either very thorough or hasn't been honest about its uncertainty.

If a previous loop's research doc covers overlapping territory, update it rather than creating a new file — but clearly mark what's new or changed.

**Research sufficiency signals**: Research can expand indefinitely, especially in unfamiliar codebases. These signals help you judge when you've learned enough to plan effectively. They are additive guidance — not a gate or a mandatory checklist. Use them to calibrate effort, not to block progress.

*Minimum coverage* — before moving to the plan step, confirm you have:
- **Entry points traced**: You can name the function(s) or path(s) where execution enters the code you'll change, and you've read their implementations (not just signatures).
- **Invariants documented**: The research doc's Invariants section has at least one entry backed by specific code references ([observed] tags).
- **Prior art checked**: You searched for existing solutions to similar problems in the codebase and either documented what you found or noted that nothing relevant exists.

*Stop-researching signals* — if any of these are true, you likely have enough context to plan:
- **Diminishing returns**: New files you read confirm what you already know rather than revealing new constraints or connections.
- **All [assumed] tags investigated**: Every [assumed] claim in your research doc has either been promoted to [observed]/[inferred] or explicitly noted as acceptable risk for planning purposes.
- **Scope creep detected**: You're exploring code paths that are interesting but not required by the scope statement from step 1. Re-read your scope and stop if the current line of investigation doesn't serve it.

When you move from research to planning, optionally note in the research doc how the transition was triggered (e.g., "Moved to plan: diminishing returns after tracing 3 callers" or "Moved to plan: all invariants observed"). This makes it possible to evaluate whether research duration is well-calibrated across sessions.

**Design decisions during research**: If research reveals a genuine design choice — multiple viable approaches, an architectural fork, a library selection — invoke the **Divergent Design workflow** (`divergent-design.md`) as a sub-procedure before proceeding to the plan step. DD's output (a documented decision in `docs/decisions/`) becomes an input to the plan. DD's 80% confidence threshold governs whether the *design decision* can be resolved autonomously; RPI's implementation gate (step 4) still applies independently. In other words: DD may resolve the "what approach" question without user input, but the user still reviews the plan before implementation begins.

Signals that you've hit a design decision:
- Research surfaces 3+ viable approaches with non-obvious tradeoffs
- The "right" approach depends on constraints you can't fully evaluate (team preferences, future roadmap, performance targets)
- You're tempted to pick an approach and justify it rather than comparing alternatives

**Human checkpoint**: The user should review the research doc — this is the cheapest place to fix misunderstandings. However, this checkpoint should not block progress. Claude should proceed to the plan step immediately after producing the research doc. If the user provides corrections to the research later, the plan may need to be revised or scrapped, and that's acceptable — a plan built on wrong research is cheap to discard, but idle time waiting for review is expensive.

The gate on **implementation** is firm: do not implement until the plan has been reviewed and approved. The gate on **planning** is soft: plan speculatively, expect revision.

**Done when...**
- [ ] Research doc exists in `docs/working/`, opens with the three-line header (Goal · Project state · Task status), and includes all required body sections (What exists, Invariants, Prior art, Gotchas)
- [ ] The Task status line accurately reflects current lifecycle (re-read it; if it lies, fix it)
- [ ] Actual implementations were read, not just signatures or file names
- [ ] Every invariant listed can be verified by pointing to specific code that depends on it
- [ ] If 3+ viable approaches surfaced, a Divergent Design sub-procedure was invoked (or a note explains why it wasn't needed)

### 3. Plan (essential) — specify the implementation steps

Produce a plan doc in `docs/working/`. The doc must begin with the same three-line header used by research docs (see step 2), then a `Research:` cross-link line, then the body sections.

**Header (required, top of file — three lines, in this order):**

- **Goal**: Same one-sentence goal as the corresponding research doc. If the goal has shifted since research was written, update both docs in lockstep.
- **Project state**: Same one-sentence project state as the corresponding research doc, refreshed if anything has moved (sibling branches landed, blockers cleared, etc.).
- **Task status**: Lifecycle keyword from `in-progress | blocked | paused | complete`, optionally followed by a free-form phase note in parens (e.g., `in-progress (plan drafted, awaiting approval)` or `in-progress (implementing step 2/5)`). The keyword is required; the parenthetical is optional but recommended whenever a phase note would help a re-reader orient.

Immediately below the header, add a `Research: <relative path or link to the research doc>` metadata line so the plan can be navigated to its research counterpart in one hop. (This replaces the old "linking to the research doc" duty that used to live in the Scope bullet.)

The header serves the same drift-surfacing purpose described in step 2: every mid-task re-read should re-verify the three lines against reality, and the Task status line should be updated whenever the doc is read or revised. Treat it as required body content — no optional pre-block, no YAML frontmatter, no linter; the spec text is the enforcement.

After the header and research link, the body must include:

- **Approach**: 2-3 sentences on the high-level strategy, referencing findings from research.
- **Steps**: Numbered list of concrete implementation actions. Each step should be:
  - Specific enough that someone could do it without re-reading the research
  - Small enough to be one commit
  - Ordered by dependency (what must exist before what)
- **Size estimate**: For each step (or for the plan as a whole if steps are small), include a rough size estimate — e.g., "~50 lines in a new file", "~20 lines added to existing handler", "minor wiring change." These don't need to be precise; the goal is to flag when a step is unexpectedly large and to catch cases where a single file would grow beyond a reasonable size. If a step would push a file past **500 lines**, note that explicitly and consider splitting the file as part of the plan.
- **Estimated context cost**: One line with rough token estimates for each phase — e.g., "Research ~20k, Implementation ~40k, Review ~15k". Typical ranges: small docs/workflow edits run ~5–15k per phase; multi-file feature work runs ~20–60k per phase; deep cross-subsystem work runs higher. Precision is not the point — the estimate is an anchor so /away mode has a concrete stop-or-pause signal when actuals overshoot. The pause threshold and reconciliation protocol live in step 6 (Implement) under "Context-cost budget (/away mode protocol)"; treat overruns as a prompt to checkpoint and reassess (start a fresh session, narrow scope, or escalate to the user), not a hard kill.
- **Actual context cost (post-implementation)**: __ (one line mirroring the estimate's structure, filled in during step 6/7 — e.g., "Research ~22k, Implementation ~75k, Review ~10k"). Capturing it in the plan artifact, not just transient logs, makes the estimate-vs-actual comparison reviewable and lets later sessions calibrate future estimates.
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

#### Checkpoint generation (final sub-step of planning)

After the plan doc is complete, generate a checkpoint artifact at `docs/working/checkpoint-{topic}.md`. This is a **curated single-file context package** designed so that an implementation session can load this one file and have everything it needs — no hunting through research docs, plan docs, or prior conversation history.

Use this template:

```markdown
# Checkpoint: {topic}
Date: {YYYY-MM-DD}
Branch: {current branch}
Research: docs/working/research-{topic}.md
Plan: docs/working/plan-{topic}.md

## Project state
- **Branch purpose**: [one sentence — what this branch delivers]
- **Position in larger initiative**: [parent epic / sibling branches / "standalone" if none]
- **Blocked on**: [external dependency, pending decision, or "nothing"]

## Key findings
[Curated subset of research — only what the implementer needs to know.
Include relevant architecture, patterns, and gotchas. Omit exploration
dead ends and background that doesn't affect implementation decisions.
Preserve confidence-provenance tags on load-bearing claims.]

## Plan
[The agreed approach and ordered steps from the plan doc.
Copy or summarize — the goal is that the implementer doesn't need
to open the plan doc separately.]

## Invariants
[What must not break. Copied from research, but filtered to only
the invariants relevant to this specific plan's steps.]

## File map
[Every file the implementer will read or modify, with a one-line
note on what they'll do there. Example:]
- `src/api/handler.go` — add new endpoint (step 2)
- `src/models/user.go` — extend User struct (step 1)
- `tests/api/handler_test.go` — add integration tests (step 3)

## Open questions
[Anything unresolved that the implementer should watch for.
Include decisions deferred during planning and assumptions
tagged [assumed] in research that haven't been verified.]
```

The checkpoint is a *derived artifact* — it contains no new information, only a curated arrangement of information from the research and plan docs. If the plan is revised after annotation (step 4), regenerate the checkpoint to match.

**Implementation sessions should load this checkpoint file as their primary context source.** The research and plan docs remain available for deep dives, but the checkpoint is the starting point. When starting a fresh implementation session, read `docs/working/checkpoint-{topic}.md` first; only consult the research or plan docs if the checkpoint doesn't answer a specific question.

**Done when...**
- [ ] Plan doc exists in `docs/working/`, opens with the three-line header (Goal · Project state · Task status) followed by a `Research:` link line, and includes all required body sections (Approach, Steps, Size estimate, Estimated context cost, Actual context cost (post-implementation) placeholder, Test specification, Risks)
- [ ] The Task status line accurately reflects current lifecycle (re-read it; if it lies, fix it)
- [ ] Each step is specific enough that someone could implement it without re-reading the research doc
- [ ] Each step is small enough to be one commit
- [ ] Test specification includes at least one test case per behavioral requirement
- [ ] No single step would push a file past 500 lines without an explicit note
- [ ] Plan doc includes an Estimated context cost line covering research, implementation, and review phases, paired with an Actual context cost (post-implementation) placeholder line awaiting the post-implementation fill-in
- [ ] Checkpoint artifact exists at `docs/working/checkpoint-{topic}.md` with all template sections populated

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

**Done when...**
- [ ] User has explicitly approved the plan (not just the research)
- [ ] All user corrections have been incorporated into the plan doc (not just acknowledged conversationally)
- [ ] If research feedback invalidated the plan, the plan was rewritten from scratch rather than patched
- [ ] Plan doc reflects the final agreed approach — no unresolved "TBD" or "discuss" markers remain
- [ ] Checkpoint artifact (`docs/working/checkpoint-{topic}.md`) has been regenerated to reflect the final approved plan

### 5. Self-check (essential) — re-read the header before implementation

Before writing any implementation code, re-read the three-line header (Goal · Project state · Task status) at the top of both the research and plan docs and verify each line still describes reality. Research, planning, and the annotation cycle can take long enough that any of the three lines can drift: a sibling branch may have landed and shifted the project state, the goal may have narrowed in response to feedback, or the Task status may still claim "research drafted" when the plan is actually approved and ready to implement. Update any line that no longer matches reality in its source doc before coding begins. This is a thirty-second check, but skipping it produces "planned for X but ended up doing Y" drift — and that drift compounds when the plan doc is later read as project memory by a future session, because a stale header silently misrepresents what the work was actually for.

**Done when...**
- [ ] Three-line header on both the research doc and the plan doc has been re-read immediately before implementation begins
- [ ] Any line (Goal, Project state, Task status) that no longer matches reality has been updated in its source doc before any implementation code is written

### 6. Implement (essential) — tests first, then code

#### Codebase freshness check (fresh session only)

When entering a **fresh session** for implementation (per the global `Fresh session for implementation` rule), the plan was written in a prior session and the underlying code may have moved while the plan sat between sessions. Step 5 re-verifies the **doc** against itself; this step re-verifies the **codebase** against the plan. Both run before any code is written.

If implementation is continuing in the **same session** that produced the plan (no `/clear` and no new session in between), the plan is fresh by construction — skip this sub-section and proceed to the Test-first gate.

In a fresh session:

1. **Re-read the plan's Project state line** — the third line of the plan doc's three-line header. If the line no longer describes reality (a sibling branch landed, a blocker cleared, scope shifted), fix it in the plan doc before continuing. This overlaps deliberately with step 5; the explicit re-read here is the trigger for the codebase check below.

2. **Find the plan's last-write time:**

   ```
   git log -1 --format=%aI -- docs/working/plan-{topic}.md
   ```

   Use the most recent commit that touched the plan doc — annotation-cycle commits (step 4) count, since they reflect the last revision of the agreed approach.

3. **Run `git log --since=<plan-write-time>` against the plan's touched files.** Enumerate the files from the plan's Steps section and the checkpoint artifact's File map (`docs/working/checkpoint-{topic}.md`):

   ```
   git log --oneline --since=<plan-write-time> -- <file1> <file2> ...
   ```

   This is the same `git log --since` primitive defined in `guides/doc-freshness.md`, applied to the plan-to-implementation handoff.

4. **Explicitly note any drift before coding.** State the result in your first session message:
   - **Empty output** → plan is fresh against the codebase, proceed to the Test-first gate.
   - **Non-empty output** → list the commits and decide per-commit whether each one invalidates the plan. Commits that touch unrelated regions of the same file are usually fine; commits that touch the same functions or behaviors the plan modifies require pausing and updating the plan (per step 6's "stop and update the plan doc first" rule) before coding.

This operationalizes the freshness convention from `guides/doc-freshness.md` for the specific case of a fresh-session plan-to-implementation handoff. Skipping it produces "implemented against a stale plan" bugs that are expensive to catch in review.

#### Test-first gate

Before implementing feature code, write the tests specified in the plan's test specification section. Commit the tests separately: `test: add tests for X (per plan-Y step N)`. These tests should fail — they encode the behavior that doesn't exist yet.

**Human checkpoint**: The user reviews the test code before implementation begins. This confirms the tests match their intent — catching specification mismatches is cheapest here, before implementation work is invested. Include a bulleted summary of what each test verifies alongside the test code, so the human can review intent in prose before spot-checking code. Like the research checkpoint, this should not block progress indefinitely; if the user doesn't respond promptly, proceed with implementation but flag that tests haven't been reviewed.

If test review reveals mismatches with the human's intent, revise the tests (and update the plan's test specification) before proceeding.

#### Implementation

Implement the plan one step at a time. Commit after each step with a message referencing the plan: `feat: add user model (per plan-inline-edit-api step 1)`.

If a step turns out to be wrong or incomplete during implementation, **stop and update the plan doc first** rather than improvising. The plan is the shared source of truth — silent deviations undermine the review process.

**File size discipline**: Keep individual files under **500 lines**. If an implementation step would push a file past this threshold, split it before continuing. This applies to both new files and modifications to existing ones — if an existing file is already near the limit, factor out a coherent subset before adding to it. The 500-line limit is a guideline, not a hard rule; a 520-line file with cohesive logic is fine, but a 700-line file signals that something should have been split earlier.

**Context management**: If the session context is getting heavy (many prior loops, large amount of code read), consider starting a fresh session and loading the checkpoint artifact (`docs/working/checkpoint-{topic}.md`). The checkpoint is designed to be the single file an implementation session needs to get started — it contains curated findings, the plan, invariants, and a file map. Only fall back to the full research or plan docs if the checkpoint doesn't answer a specific question. This is a judgment call, not a hard rule — if context is still fresh and the task is flowing, continue in the same session. When ending a session to start fresh, write a handoff doc first (see step 7, "Session handoff") so the next session knows exactly where to resume.

**Context-cost budget (/away mode protocol)**: Before each autonomous commit in /away mode, compare actual context use against the plan's "Estimated context cost" line. If actuals exceed the estimate by 2x overall, or by +50% on any single phase, pause and write a checkpoint to `docs/working/checkpoint-{topic}.md` (regenerating or updating the existing one) capturing what's done, what's left, and why the budget overshot — then stop and either narrow scope, start a fresh session against the new checkpoint, or escalate to the user. Do not proceed silently through an overrun. This clause attaches to the autonomous commit format (see CLAUDE.md `/away` mode): the budget check runs at the same cadence as the `Confidence`/`Notes` lines, so the comparison prompt lives in an already-consulted section. Once implementation finishes (clean or via early checkpoint), fill in the plan's `Actual context cost (post-implementation)` field so the estimate-vs-actual comparison is captured in the artifact rather than only in transient logs.

**Done when...**
- [ ] In a fresh implementation session, the codebase freshness check ran (`git log --since=<plan-write-time>` against the plan's touched files) and any drift was explicitly noted before coding; in a same-session implementation, the check was explicitly skipped
- [ ] All plan steps are implemented with one commit per step
- [ ] Tests from the test specification pass
- [ ] Each commit message references the plan (e.g., "per plan-X step N")
- [ ] Any deviations from the plan were written back to the plan doc before implementation continued
- [ ] No file exceeds 500 lines without an explicit justification
- [ ] In /away mode, any 2x-overall or +50%-per-phase context overrun was checkpointed and paused rather than absorbed silently
- [ ] Plan doc's `Actual context cost (post-implementation)` field is filled in (mirroring the estimate's per-phase structure)

### 7. Verify and loop (recommended)

- Run all project checks (lint, build, tests)
- Update `docs/thoughts/` if the implementation revealed new understanding worth preserving
- If there's another loop to do in this session, return to step 1 with a new scope
- If this was the final loop, proceed to the pr-prep workflow if opening a PR

**Done when...**
- [ ] All project checks pass (lint, build, tests)
- [ ] `docs/thoughts/` updated if implementation revealed new understanding worth preserving
- [ ] If another loop follows, new scope is defined; if final loop, PR prep is ready to begin
- [ ] If ending mid-task, a handoff doc exists in `docs/working/handoff-{topic}.md`

#### Session handoff (optional)

When ending a session mid-task — because context is getting heavy, you're switching to a different task, or the workday is ending — write a handoff doc so the next session can pick up without re-deriving state from scratch.

Save it to `docs/working/handoff-{topic}.md`, overwriting any previous handoff for the same topic. Use this template:

```markdown
# Handoff: {topic}
Date: {YYYY-MM-DD}
Branch: {current branch}

## Project state
- **Branch purpose**: [one sentence — what this branch delivers]
- **Position in larger initiative**: [parent epic / sibling branches / "standalone" if none]
- **Blocked on**: [external dependency, pending decision, or "nothing"]

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

## Task status
- **Lifecycle**: in-progress | blocked | paused | complete  (pick one — these are the only valid values)
- **Last commit**: `<short-hash> <subject>`  (paste the output of `git log -1 --oneline` at handoff time)
- **Verify command**: `<single shell command>`  (e.g., `pytest tests/handoff/`, `npm test -- --run`, `cargo test --lib`)
- **Expected result**: `<exact pass marker from that command>`  (e.g., `12 passed`, `All checks passed`, exit code 0)
```

The Task status block exists so a fresh session can **re-verify** the marker rather than trust it. On load, the next session should run `git log -1 --oneline` and check the hash matches **Last commit**, then run the **Verify command** and confirm the output contains the **Expected result**. If either check fails, the handoff is stale — the branch has moved or tests have regressed — and state should be re-derived from the current branch (read recent commits, re-run the test suite) rather than picking up from the handoff's narrative sections. Keep the block to these four fields; if a field can't be tied to a shell command whose output a reader can match against, it doesn't belong here.

The next session should load the handoff doc, the plan doc, and (if needed) the research doc. The handoff tells you *where you are*; the plan tells you *where you're going*; the research tells you *why*.

A handoff doc is not necessary when a session ends at a clean boundary — all plan steps complete, PR opened, or no work in progress. It's for the in-between case where conversational context would otherwise be lost.

## When to skip or abbreviate

- **Trivial changes** (typo fixes, config tweaks, single-line bug fixes): Skip entirely, just make the change.
- **Changes where you already understand the code**: Skip research, go straight to plan. Or update an existing research doc rather than writing from scratch.
- **Urgent hotfixes**: Abbreviate to a mental plan, but write a retroactive decision doc if the fix was non-obvious.
- **Continuation of a previous session's work**: If research and plan docs already exist and are still accurate, pick up from where implementation left off. If a checkpoint artifact exists (`docs/working/checkpoint-{topic}.md`), load it as your primary context source — it contains curated findings, the plan, invariants, and a file map in a single file. If a handoff doc also exists (`docs/working/handoff-{topic}.md`), load it alongside the checkpoint — the handoff tells you *where you stopped*, the checkpoint tells you *everything else*. Verify the docs are still current before proceeding.

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
