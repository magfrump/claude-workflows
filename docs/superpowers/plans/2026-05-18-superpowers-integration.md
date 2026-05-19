# Superpowers Deep-Integration Implementation Plan

> **STATUS — 2026-05-18: DEFERRED.** Per critique findings and user decision, scoped down to a minimal version. **Active execution plan:** `docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md`. This larger plan is preserved as context for a future decision after observing the minimal version's effect for a period. Do not execute this plan directly; see the minimal plan for what to ship now.

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `superpowers` the substrate for general development methodology in this repo, with this repo's skills layered on top as domain-specific extensions (critics, decision helpers, code review orchestration). Stop maintaining parallel implementations of plan-then-execute and debug-loop, and formalize where this repo's contributions sit relative to superpowers' flow.

**Architecture:** Three-layer model.
- **Layer 1 (substrate):** superpowers skills — brainstorming, writing-plans, executing-plans / subagent-driven-development, systematic-debugging, test-driven-development, verification-before-completion, requesting-code-review, receiving-code-review.
- **Layer 2 (composition):** thin local workflows that compose Layer 1 with project-specific phases. RPI becomes "research phase + writing-plans". `pr-prep` becomes "verification-before-completion + review-fix-loop + branch close."
- **Layer 3 (domain extensions):** this repo's unique skills — code/prose critics, decision helpers, orchestrators (`code-review`, `draft-review`).

**Tech Stack:** Markdown files; bash for ref-finding; no code compilation. Verification is by routing-tree integrity, self-eval rubric, and ad-hoc dry-runs of updated workflows.

---

## Critique response (added 2026-05-18 after adversarial review)

Full critique: `docs/reviews/critique-superpowers-integration-plan.md`. Verdict was **"not ready to execute as-is."** Ten findings (1 Critical, 6 Major, 3 Minor) plus four persona critiques plus four what-if assumptions plus five pre-mortem narratives.

### Incorporated directly

- **Finding 1 (Critical) — failure-pattern library write side severed.** Added Task 2.4. Phase 2 must answer where the write side lives before deletion ships.
- **Finding 4 (Major) — RPI restructure dumps load-bearing primitives.** Added Task 3.0 inventory sub-task before the rewrite. Every load-bearing primitive in current 502-line RPI must be assigned a home (retained / moved to a local skill / moved to a template / deleted with reason).
- **Finding 5 (Major) — Phase 2 grep estimate wrong.** Corrected "~17 files" to "~77 files" and added a fifth classification category (composition-narrative-inside-workflow).
- **Finding 7 (Major) — author-user convergence on locked decisions.** Added "Strongest argument against" sub-sections to Phase 0, Phase 1, and Phase 4 decisions.

### Surfaced for user decision (not edited unilaterally — these change locked decisions or the plan's overall shape)

- **Meta-question A — scope down? (Persona 2 + verdict's recommendation).** Ship only Phase 2 (with the failure-pattern fix) + a one-line pr-prep edit invoking `verification-before-completion` before the review-fix-loop. Observe for a month. Decide whether RPI restructure, Phase 4 paths, and cross-project rollout are actually needed based on real usage data rather than pre-restructure dialogue. The critique argues this is ~10% of the current plan's complexity and addresses ~80% of the cited pain.
- **Meta-question B — re-litigate Phase 0 framing? (Finding 2).** The "complementary not redundant" conclusion was pre-loaded by asymmetric axis framing. A symmetric framing ("what behavior does each prevent at commit time?") might force a different conclusion: that `code-review`'s scope should narrow to un-executable concerns (architecture, API consistency, naming) and `verification-before-completion` handles everything executable. If true, Phase 4's design space collapses.
- **Meta-question C — Phase 4 lock vs Phase 5 routing contradiction (Finding 3).** Option A = Path 8 (failure-mode-keyed gates) is locked, but Phase 5's routing edits use Path 1/3 vocabulary. Either downgrade Phase 4 to "leaning, final lock when follow-up plan starts" or split Phase 5 into 5a (substrate registration, safe) and 5b (Path-8 gate vocabulary, deferred).
- **Meta-question D — plan-location override mechanism (Finding 6).** "User preferences override the default" is a verbal convention. Where is the override encoded? Suggestion: encode it in the CLAUDE.md routing entry for RPI itself (`save to docs/working/plan-{topic}.md`), not as a separate convention. Also: pr-prep's `find` commands hardcode `docs/working/` — they need to know.
- **Meta-question E — Path 11 + iterative-spec-discovery conflict (Finding 10).** Path 11 was locked into Option A, but the iterative-spec-discovery workstream was deferred. On iterative-spec-discovery-shaped work, Path 11 will rubber-stamp a verification subagent that read the (incomplete) spec. Either defer Path 11 alongside the spec-discovery workstream so they land together, or add a suppression rule.
- **Meta-question F — executable end-to-end test? (Persona 1).** Phase 6 has no executable verification — cold-start traces are mental simulation; self-eval is judgment-based. The skeptical-platform-engineer persona argues for a runnable Claude Code session that exercises the composition on a toy task with a golden expected trace. This would catch the failures Findings 1, 3, 6 introduce, which Phase 6 will not.
- **Finding 6 (Major) routing override** — see Meta-question D.
- **Finding 8 (Minor) — AGENTS.md/GEMINI.md mirror edits not specified.** Recommended action is to add explicit diff snippets in Tasks 2.2 and 5.1; deferring because it's tied to whether Meta-question A scopes the plan down.
- **Finding 9 (Minor) — Phase 6 cold-start traces are happy-path only.** Recommended action is to add failure-path traces (3-failed-hypothesis escape hatch, stale fresh implementation session); deferring because it's also tied to whether the plan scopes down.

### How to proceed

Answer Meta-question A first. If "yes, scope down": this plan gets replaced with a much smaller one and Meta-questions B–F are mostly moot. If "no, proceed as planned": Meta-questions B–F all need answers before Phase 5 ships.

---

## Phase 0 — Analysis: assumption differences in code review

Before any restructuring, document where this repo's `code-review` and superpowers' `requesting-code-review` / `receiving-code-review` sit on different mental models. This becomes the rationale section in the updated `CLAUDE.md` and prevents future drift.

### Task 0.1: Write the assumption-divergence note

**Files:**
- Create: `docs/decisions/NNN-code-review-vs-superpowers-review.md` (NNN = next available decision number)

- [ ] **Step 1: Find next decision number**

Run: `ls docs/decisions/ | grep -E '^[0-9]{3}-' | sort | tail -3`
Pick the next integer.

- [ ] **Step 2: Write the decision doc**

Content must cover all five axes below explicitly. Do not paraphrase loosely — each axis is a real divergence the agent needs to reason about at runtime.

```markdown
# NNN: Code review — LLM-as-reviewer vs. LLM-as-reviewee

## Context
This repo ships `code-review` (orchestrator over security/perf/API/architecture/UI critics) plus a `review-fix-loop.md` workflow. Superpowers ships `requesting-code-review` and `receiving-code-review`. Both claim review-time territory but operate on different assumptions.

## The five divergences

### 1. Who is the reviewer?
- **This repo:** *the LLM is the reviewer.* `code-review` dispatches critic sub-agents that produce structured Markdown critiques. No human is in the loop until the critique is read.
- **Superpowers:** *a human (or external agent) is the reviewer.* `requesting-code-review` prepares the agent to receive external review; `receiving-code-review` governs how to respond to it.

### 2. What counts as evidence?
- **This repo:** analytical reasoning over a diff is sufficient. Critics infer behavior from code structure; they do not require running the code.
- **Superpowers:** `verification-before-completion` requires *executed* evidence — test runs, captured output. Analytical inference is not sufficient for a completion claim.

### 3. When does review happen?
- **This repo:** pre-PR, as a self-check before the human reviewer sees the diff. PR-prep embeds it in the review-fix loop.
- **Superpowers:** at PR boundary or feedback receipt. The agent's job before that point is verification, not critique.

### 4. What does "rigor" mean?
- **This repo:** breadth — multiple critic lenses in parallel, structured rubric, red/amber/green status. Rigor = covered the angles.
- **Superpowers:** depth — technical verification of feedback claims, refusing to capitulate to incorrect feedback. Rigor = did not perform agreement.

### 5. What is the failure mode each guards against?
- **This repo:** shipping a diff that has a defect a critic would have caught. Counterfactual: a human reviewer is missing or fast.
- **Superpowers:** sycophantic compliance — accepting reviewer feedback uncritically, breaking working code to satisfy a comment, claiming "done" without proof. Counterfactual: the agent rationalizes its way out of verification.

## Decision

They are **complementary, not redundant**. They guard different failure modes and operate at different lifecycle points:

- Pre-PR (this repo): `code-review` runs the critic ensemble as a self-check.
- Pre-completion claim (superpowers): `verification-before-completion` requires executed evidence.
- Receiving feedback (superpowers): `receiving-code-review` governs response rigor.

The CLAUDE.md routing must make this distinction explicit so the agent doesn't substitute one for the other.

## Consequences
- `code-review` keeps its current scope (LLM-driven critic ensemble).
- `pr-prep` workflow must call `verification-before-completion` before invoking `code-review` — analytical critique without executed evidence is insufficient.
- `receiving-code-review` triggers on any external review feedback, including from `code-review`'s own output when the agent acts on it.

## Strongest argument against this decision (added per critique Finding 7)

The five-axis divergence framing is **asymmetric** in a way that pre-loaded the "complementary" conclusion. Axis 5 ("what failure mode each guards against") describes `code-review` by its failure-class *output* (a defect that slips) and `verification-before-completion` by its agent-behavior *output* (sycophancy). A symmetric question — "what behavior does each prevent in the agent right before commit?" — would show heavy overlap: both fire pre-PR, both demand the agent stop and check, and `code-review` calls itself out for being purely analytical, which is precisely the failure `verification-before-completion` exists to refuse.

The honest alternative conclusion: `code-review`'s scope should **narrow** to un-executable concerns (architecture, API consistency, naming) — concerns no test run can verify. Anything executable belongs to `verification-before-completion`. Under this framing, the Phase 4 design space collapses dramatically; there's no "complementary" composition because the two skills do different jobs by construction.

If this alternative is correct, the whole rest of the plan inherits a wrong framing. Re-litigating Phase 0 is Meta-question B in the Critique Response section.
```

- [ ] **Step 3: Commit**

```bash
git add docs/decisions/NNN-code-review-vs-superpowers-review.md
git commit -m "docs(decisions): record divergence between code-review and superpowers review skills"
```

---

## Phase 1 — Decision: RPI restructure vs. deprecate

This phase produces a decision record; no workflow files change yet. The decision gates Phase 3.

### Task 1.1: Lay out the three RPI options

**Files:**
- Create: `docs/decisions/NNN-rpi-restructure-vs-deprecate.md`

- [ ] **Step 1: Write the options document with explicit rationale**

```markdown
# NNN: RPI — restructure as composition, deprecate, or keep parallel

## Context
RPI (`workflows/research-plan-implement.md`, 502 lines) is the default router for non-trivial work in this repo. It has four phases: research → plan → review gate → implement. Superpowers ships `writing-plans` (plan-writing) and `executing-plans` / `subagent-driven-development` (execution). Significant overlap.

## Differences worth preserving

RPI has structure superpowers does not:
- **Research phase** — read code, write research doc at `docs/working/research-{topic}.md` with "Files read" and "Last verified" for staleness tracking.
- **Plan review gate** — explicit checkpoint with the user before implementation begins.
- **/away handoff format** — autonomous-mode commit format with `Confidence:` and `Notes:` lines.
- **Composition hooks** — DD↔RPI, Spike→RPI, Bug-diagnosis→RPI handoffs are wired into CLAUDE.md.

Superpowers has structure RPI does not:
- **TDD-first task granularity** — every implementation step is "write failing test → run → implement → run → commit".
- **Subagent-driven-development** — fresh subagent per task with two-stage review.
- **Verification-before-completion gate** — evidence required before "done."

## Options

### Option A: Full deprecate RPI
Delete `workflows/research-plan-implement.md`. Route the decision tree directly to `superpowers:writing-plans`.
- **Pros:** Single source of truth. No drift.
- **Cons:** Lose the research phase, the review gate, the staleness-tracked research docs, and the /away handoff format. Existing `docs/working/` plans become orphans. CLAUDE.md routing becomes shallower.

### Option B: Keep RPI parallel
Leave RPI as-is, cross-reference superpowers as an alternative.
- **Pros:** Zero migration cost.
- **Cons:** Two competing plan-writing flows. Agent has to choose. Drift continues. Defeats the integration goal.

### Option C: Restructure RPI as composition (recommended)
RPI becomes a thin shell that:
1. Owns the **research phase** (this repo's unique contribution).
2. Hands off to `superpowers:writing-plans` for plan-writing.
3. Hands off to `superpowers:subagent-driven-development` or `superpowers:executing-plans` for execution.
4. Owns the **plan review gate** between phases 2 and 3.
5. Preserves /away handoff conventions.

RPI shrinks from 502 lines to ~150. The plan template and TDD discipline live in superpowers; the research-doc template and review gate live in RPI.

- **Pros:** Preserves what this repo adds without duplicating what superpowers handles. Aligns with the three-layer architecture.
- **Cons:** Migration cost — existing in-flight RPI plans at `docs/working/` need to either complete under the old format or migrate. Plan-doc location changes (`docs/working/` → `docs/superpowers/plans/`) unless we override.

## Decision

**Option C.** Rationale:
- The research phase is genuinely additive — superpowers assumes brainstorming has already produced a clear spec, but in unfamiliar codebases the research is half the work.
- The review gate matches the user's `/active` mode preference (approval before plan lock-in).
- The cost of B is ongoing drift; the cost of A is loss of real capability.

## Path-dependent follow-ups
- Decide whether plans live at `docs/working/` (existing) or `docs/superpowers/plans/` (superpowers default). Recommend keeping `docs/working/` and overriding the superpowers default — the user already has muscle memory.
- Decide whether research docs stay at `docs/working/research-*.md` or move under `docs/superpowers/research/`. Recommend keeping current path.

## Strongest argument against this decision (added per critique Finding 7)

Phase 1's Options A, B, C have six pros/cons total between them, but the rationale text under "Decision: Option C" uses arguments that don't appear in any of the lists ("the research phase is genuinely additive — superpowers assumes brainstorming has already produced a clear spec"). That argument should have been a *con* on Option A (deprecate) — its absence is a sign the comparison was constructed to support C.

The strongest case for **Option A (full deprecate)** that Phase 1 didn't make: most of RPI's "research phase" content is duplicating `superpowers:brainstorming` (spec elicitation) plus general code-reading discipline that doesn't need a workflow at all. If a future contributor reads CLAUDE.md and learns to invoke brainstorming + writing-plans, they'd produce work of equivalent quality without RPI's 502-line scaffold. The cost of Option A is real but is one-time (in-flight plan migration); the cost of Option C is **ongoing** (a thin RPI shell that confuses contributors about whether to think of plans as a superpowers thing or a local thing, and that has to be maintained as superpowers evolves).

Option C's strongest specific weakness: the inventory in Task 3.0 may surface that most of what's "load-bearing" in RPI is duplicated in superpowers skills the plan didn't read closely enough. If the inventory comes back with >50% of primitives marked "redundant with superpowers, delete," the right answer is to abandon Option C mid-execution and switch to Option A.
```

- [ ] **Step 2: Commit**

```bash
git add docs/decisions/NNN-rpi-restructure-vs-deprecate.md
git commit -m "docs(decisions): pick Option C — RPI restructured as composition over superpowers"
```

---

## Phase 2 — Cleanup: remove bug-diagnosis workflow and skill

The CLAUDE.md "Debugging defaults" section already supersedes the bug-diagnosis workflow. The skill duplicates `superpowers:systematic-debugging`. Both should go; references redirect to `superpowers:systematic-debugging`.

### Task 2.1: Inventory all bug-diagnosis references

**Files:**
- Read: every file in the grep output below.

- [ ] **Step 1: Generate the full reference list**

Run: `grep -rln "bug-diagnosis\|bug_diagnosis" --include="*.md" /home/magfrump/claude-workflows`
Expected: list of **~77 files** (verified by critique). Includes `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `workflows/bug-diagnosis.md`, `skills/bug-diagnosis/SKILL.md`, `docs/workflow-selection.md`, `docs/workflow-dependency-graph.md`, `guides/workflow-selection.md`, `workflows/codebase-onboarding.md`, `workflows/pr-prep.md`, `workflows/research-plan-implement.md`, `guides/skill-creation.md`, `guides/README.md`, `docs/decisions/008-hypothesis-screening-workflow.md`, `docs/reviews/self-eval-bug-diagnosis.md`, plus working-doc files (`docs/working/*`, `docs/thoughts/*`, `docs/human-author/feedback.md`). Many files have multiple references each.

- [ ] **Step 2: Classify each reference**

Five categories (not four — the fifth was missed in the original draft and is the only category that can't be mechanically redirected):

- **Routing reference** (any `| <activate> |` table entry, decision-tree row, or workflow-trigger pointer): redirect to `superpowers:systematic-debugging`.
- **Composition note** (cross-workflow handoff lines like "from bug-diagnosis → RPI"): redirect to `superpowers:systematic-debugging → research phase of RPI`.
- **Composition-narrative-inside-workflow** (a *section* of another workflow file describing how it interacts with bug-diagnosis, e.g., RPI's "← From Bug Diagnosis" subsection): may need to be **deleted entirely** rather than redirected, because the destination workflow (RPI) is itself being restructured in Phase 3 and the composition path may no longer make sense. Treat each instance as a judgment call.
- **Historical reference** (working docs, completed-tasks, hypothesis-log, decision records, self-eval reports): leave as-is — these are dated artifacts and rewriting them rewrites history.
- **Skill description in `guides/skill-creation.md` or `guides/README.md`**: redirect to `superpowers:systematic-debugging`.

Write the classification to `docs/working/bug-diagnosis-cleanup-inventory.md` so the next steps have a checklist. The inventory should also flag any reference to the **failure-pattern library** (`docs/thoughts/failure-patterns.md`) — that loop is addressed by new Task 2.4.

- [ ] **Step 3: Commit the inventory**

```bash
git add docs/working/bug-diagnosis-cleanup-inventory.md
git commit -m "docs(working): inventory bug-diagnosis references for cleanup"
```

### Task 2.2: Update routing and composition references

**Files:**
- Modify: each file classified as "routing" or "composition" in Task 2.1's inventory.

- [ ] **Step 1: Update `CLAUDE.md` "Debugging defaults" section**

The section currently says:
> The standalone `bug-diagnosis.md` workflow is deprecated — use these defaults directly.

and at the end:
> For complex bugs that need a formal diagnosis log, the template and full process remain available in `workflows/bug-diagnosis.md`.

Replace both with a single forward-pointer:
> The standalone `bug-diagnosis.md` workflow and skill have been removed in favor of `superpowers:systematic-debugging`. The principles below are the local extension to that skill — the 3-failed-hypothesis escape hatch with handoff-doc emission, and the bug-diagnosis-to-RPI handoff path.

The numbered debugging principles (1-6) stay. They are this repo's contribution and complement systematic-debugging's loop.

- [ ] **Step 2: Update `AGENTS.md` and `GEMINI.md`**

These are mirrors of `CLAUDE.md` for other harnesses. Apply the same edit. If they have harness-specific notes, preserve those.

- [ ] **Step 3: Update workflow cross-references**

For each of `workflows/codebase-onboarding.md`, `workflows/pr-prep.md`, `docs/workflow-selection.md`, `docs/workflow-dependency-graph.md`, `guides/workflow-selection.md`, `guides/skill-creation.md`, `guides/README.md`:
- Find each reference to `bug-diagnosis` (skill or workflow).
- Replace with `superpowers:systematic-debugging`.
- If the reference described composition with another workflow (e.g., "bug-diagnosis → RPI"), update the composition narrative to match: `superpowers:systematic-debugging → RPI research phase` with the handoff-doc emission requirement preserved.

- [ ] **Step 4: Verify nothing else points at the removed paths**

Run: `grep -rn "workflows/bug-diagnosis\|skills/bug-diagnosis" --include="*.md" /home/magfrump/claude-workflows | grep -v "docs/working\|docs/thoughts\|docs/decisions\|docs/reviews\|docs/human-author"`
Expected: no output. (Historical references in those directories are intentionally preserved.)

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md AGENTS.md GEMINI.md workflows/codebase-onboarding.md workflows/pr-prep.md docs/workflow-selection.md docs/workflow-dependency-graph.md guides/
git commit -m "refactor(routing): redirect bug-diagnosis references to superpowers:systematic-debugging"
```

### Task 2.3: Delete the workflow and skill

**Files:**
- Delete: `workflows/bug-diagnosis.md`
- Delete: `skills/bug-diagnosis/` (whole directory)

- [ ] **Step 1: Confirm no live references remain**

Run: `grep -rln "workflows/bug-diagnosis.md\|skills/bug-diagnosis" --include="*.md" /home/magfrump/claude-workflows | grep -v "docs/working\|docs/thoughts\|docs/decisions\|docs/reviews\|docs/human-author"`
Expected: no output.

- [ ] **Step 2: Delete the files**

```bash
git rm workflows/bug-diagnosis.md
git rm -r skills/bug-diagnosis/
```

- [ ] **Step 3: Verify**

Run: `ls workflows/bug-diagnosis.md skills/bug-diagnosis/ 2>&1`
Expected: "No such file or directory" for both.

- [ ] **Step 4: Commit**

```bash
git commit -m "refactor: remove bug-diagnosis workflow and skill (superseded by superpowers:systematic-debugging)"
```

### Task 2.4: Decide and act on the failure-pattern library (added per critique Finding 1)

**Critical:** `docs/thoughts/failure-patterns.md` has *two* live couplings to bug-diagnosis. (1) RPI's research step contains a mandatory "Failure-pattern grep" sub-step with a `Done when` checkbox. (2) `pr-prep.md` runs an advisory check that counts `fix(...)` commits vs. new `FP-NNN` entries and tells the user to "return to bug-diagnosis.md step 8 and append the entry before opening the PR." The **write side** lives in bug-diagnosis step 8, which Task 2.3 deletes. `superpowers:systematic-debugging` has no equivalent step. Without this task, the library decays into a fossil that the read-side audits forever.

**Files:**
- Read: `docs/thoughts/failure-patterns.md` (note its self-declared `Relevant paths: workflows/bug-diagnosis.md`)
- Read: `workflows/research-plan-implement.md` (the read-side grep at line ~117)
- Read: `workflows/pr-prep.md` (the advisory check at line ~43)

- [ ] **Step 1: Pick one of three options**

(a) **Wrap superpowers:systematic-debugging with a local pre/post step** that does grep-and-append. Documented as the "local extension" the new CLAUDE.md text already alludes to. Highest preservation of current discipline; modest doc work.

(b) **Move the grep-and-append discipline into RPI/pr-prep themselves** — read on research (already there), write on pr-prep when a fix commit lacks an entry. Couples the discipline to lifecycle gates rather than to debugging specifically.

(c) **Deprecate the failure-pattern library entirely.** Remove the read-side from RPI, remove the write-side check from pr-prep, mark `docs/thoughts/failure-patterns.md` as archived. Lowest carrying cost; loses the cumulative-pattern-learning loop the library was built for.

- [ ] **Step 2: Apply the choice**

Document the decision in `docs/decisions/NNN-failure-pattern-library-after-bug-diagnosis-removal.md`. Update the read-side (RPI) and write-side (pr-prep or new wrapper or archive) consistently in the *same commit* as Task 2.3's deletion.

- [ ] **Step 3: Update `docs/thoughts/failure-patterns.md`'s header**

The current header says `Relevant paths: workflows/bug-diagnosis.md`. Update to reflect the chosen option (new wrapper path, RPI/pr-prep paths, or "archived").

- [ ] **Step 4: Commit**

```bash
git add docs/decisions/NNN-failure-pattern-library-after-bug-diagnosis-removal.md docs/thoughts/failure-patterns.md <read-side and write-side files>
git commit -m "refactor: re-home failure-pattern library after bug-diagnosis removal (option N)"
```

**Do not ship Phase 2 commits without this task.** The verification grep in Task 2.2 step 4 explicitly excludes `docs/thoughts/`, so it will not catch the broken read/write loop.

---

## Phase 3 — Restructure RPI as composition (gated on Phase 1 decision)

This phase only executes if Phase 1 chose Option C. If Option A or B was chosen, replace with the corresponding sub-plan.

### Task 3.0: Inventory load-bearing primitives in current RPI (added per critique Finding 4 + Persona 4)

**Critical:** the original Task 3.1 ("research-doc template" = 4 sections, 20 lines) is far smaller than what current RPI actually contains. The 502-line file holds at minimum: a four-line drift-surfacing header (Goal · Problem framing · Project state · Task status), the `[observed]`/`[inferred]`/`[assumed]` tag convention, research-sufficiency signals, DD invocation triggers, the **failure-pattern grep audit token**, the `## Files read` section with `Last verified:` for staleness tracking, the plan-doc structure (Approach, Steps, Implementation order, Size estimate, Estimated/Actual context cost, Test specification table, Failure modes considered, Risks), the test-strategy auto-invoke sub-step, the checkpoint generation ritual, the codebase freshness check (`git log --since=<plan-write-time>`) on fresh implementation sessions, and the `/away` context-cost budget protocol. None of these are in `superpowers:writing-plans`.

**Files:**
- Read: `workflows/research-plan-implement.md` (entire 502 lines)
- Create: `docs/working/rpi-primitive-inventory.md`

- [ ] **Step 1: Enumerate every named primitive in current RPI**

Read end-to-end. For each named primitive (header, tag convention, audit token, sub-step ritual, freshness check, protocol), record:
- Where it appears (line range)
- What it does
- Whether `superpowers:writing-plans` or any other superpowers skill provides an equivalent

- [ ] **Step 2: Assign a destination for each primitive**

Four destinations:
- **Preserved in the new RPI shell** (its purpose is cross-phase composition, e.g., the plan-review gate).
- **Moved to a new local extension skill** (e.g., a `research-discipline` skill that wraps `superpowers:writing-plans` with the audit tokens and tag conventions).
- **Moved to a local template** (e.g., the research-doc template, the plan-doc structure).
- **Deleted as redundant with superpowers** (with explicit reason — "writing-plans already enforces this in step N").

Document choices in `docs/working/rpi-primitive-inventory.md` as a four-column table: Primitive · Current location · Destination · Reason.

- [ ] **Step 3: Build a retained-and-dropped summary for the decision record**

This is the breadcrumb future-self needs (Persona 4). The summary lists every dropped primitive with its reason, so a contributor reading the Phase 3 commit six months later can reconstruct intent without re-reading the 502-line original.

- [ ] **Step 4: Commit the inventory**

```bash
git add docs/working/rpi-primitive-inventory.md
git commit -m "docs(working): inventory load-bearing primitives in current RPI before restructure"
```

Tasks 3.1 and 3.2 below now operate against this inventory rather than against my prior abbreviated template.

### Task 3.1: Extract the research phase template

The research phase is RPI's unique contribution. Pull it out into a standalone artifact so superpowers' `writing-plans` can be cleanly chained after.

**Files:**
- Create: `templates/research-doc-template.md`
- Read: `workflows/research-plan-implement.md` (entire file)

- [ ] **Step 1: Identify the research-phase content in RPI**

Read `workflows/research-plan-implement.md` and find the section covering Phase 1 (research). Note the required fields: "Files read", "Last verified", "Open questions", "Recommended next step."

- [ ] **Step 2: Write the standalone template**

```markdown
# Research Doc Template

Save research outputs to `docs/working/research-{topic}.md`. The template enforces freshness tracking and explicit handoff to the planning phase.

## Required sections

### Files read
- `path/to/file.ext:LINE-LINE` — one-line note on what was learned

### Last verified
YYYY-MM-DD

### Findings
[Free-form. The substance of the research.]

### Open questions
- [Question]: [why it matters, who can answer it]

### Recommended next step
- [ ] Brainstorm spec (invoke `superpowers:brainstorming`)
- [ ] Write plan directly (invoke `superpowers:writing-plans`)
- [ ] Pivot to spike (invoke `workflows/spike.md`)
- [ ] Pivot to divergent-design (invoke `workflows/divergent-design.md`)
```

- [ ] **Step 3: Commit**

```bash
git add templates/research-doc-template.md
git commit -m "feat(templates): extract research-doc template from RPI"
```

### Task 3.2: Rewrite RPI as a composition shell

**Files:**
- Modify: `workflows/research-plan-implement.md` (rewrite, target ~150 lines from current 502)

- [ ] **Step 1: Write the new RPI**

New RPI structure:

```markdown
# Research → Plan → Implement (RPI)

> RPI is the **composition shell** for non-trivial work in this codebase. It owns the research phase and the plan-review gate; it delegates plan-writing and execution to superpowers skills.

## When to use
[Existing trigger conditions from the CLAUDE.md decision tree row 5.]

## Phase 1: Research
1. Read the relevant code. Surface-level reading (signatures only) is not acceptable.
2. Write `docs/working/research-{topic}.md` using `templates/research-doc-template.md`.
3. Stop. Show the research doc to the user for sign-off.

**Pivot signals:** if research surfaces a design fork → invoke `workflows/divergent-design.md`. If research can't answer the feasibility question → invoke `workflows/spike.md`. If research reveals an unfamiliar codebase → invoke `workflows/codebase-onboarding.md`.

## Phase 2: Plan
1. Invoke `superpowers:writing-plans`.
2. Override the default save location to `docs/working/plan-{topic}.md` instead of `docs/superpowers/plans/`.
3. The plan must cite the research doc and quote any preserved findings (e.g., "What this bug isn't" sections from a prior debugging handoff).

## Phase 3: Plan review gate
In `/active` mode: stop and wait for user approval of the plan before any code changes.
In `/away` mode: proceed, but commit the plan separately before starting implementation so the user can review it later.

## Phase 4: Implement
Invoke `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans`.

Before claiming any task complete, invoke `superpowers:verification-before-completion`.

## Composition handoffs
- Bug-diagnosis → RPI: if `superpowers:systematic-debugging` hits its 3-failed-hypothesis escape hatch, the handoff doc at `docs/working/handoff-diagnosis-{bug}.md` becomes input to RPI's Phase 1. Open the research doc with the "What this bug isn't" section copied verbatim.
- Spike → RPI: load the spike's RPI-seed section as Phase 1 starter input.
- DD → RPI: load the decision record as a constraint section in the plan.
- RPI → PR-prep: when implementation is complete, invoke `workflows/pr-prep.md`.
```

- [ ] **Step 2: Verify routing references still resolve**

Run: `grep -rln "research-plan-implement\|research-plan-implement.md" --include="*.md" /home/magfrump/claude-workflows | head`
For each reference, confirm the description still matches the new shorter shell.

- [ ] **Step 3: Commit**

```bash
git add workflows/research-plan-implement.md
git commit -m "refactor(rpi): restructure as composition shell over superpowers:writing-plans + executing-plans"
```

### Task 3.3: Run self-eval against the restructured RPI

**Files:**
- Create: `docs/reviews/self-eval-rpi-restructured.md`

- [ ] **Step 1: Invoke `self-eval` skill on `workflows/research-plan-implement.md`**

The skill auto-scores five structural dimensions and flags four judgment dimensions for human review.

- [ ] **Step 2: Address any "Weak" dimensions before declaring Phase 3 complete**

- [ ] **Step 3: Commit**

```bash
git add docs/reviews/self-eval-rpi-restructured.md
git commit -m "docs(reviews): self-eval restructured RPI"
```

---

## Phase 4 — Verification-before-completion vs. pr-prep: divergence options

The user asked for a fuller divergence than the original four-path sketch. A dedicated exploration produced **twelve candidate paths** plus three substantive findings about the source skills that constrain the design space. **Do not implement yet** — Phase 4 produces only the decision artifact.

### Source-file findings that reshape the design space

1. **`verification-before-completion` is a gate *function*, not a workflow.** It fires on linguistic triggers ("Great!", "Done!", "Should pass") and its iron law is *executed evidence only*. It is scope-agnostic — nothing in the skill picks per-step vs per-task vs per-branch. Most of the real design space lives in *who chooses the scope and how*, not in the skill itself.
2. **`code-review`'s critics are analytical, not executed.** They infer from diff structure and do not run code. The central divergence with `verification-before-completion` is what counts as evidence. The original four paths glossed this; it is the load-bearing fork.
3. **`pr-prep` is much larger than verification.** Env scan, size check, pre-mortem fallback, review-fix loop, commit hygiene, PR description, retrospective, post-merge. "Replace pr-prep with verification" discards substantial non-verification content.

### The twelve candidate paths (full text in divergence doc)

Full file: `docs/superpowers/plans/2026-05-18-divergence-verification-vs-pr-prep.md`.

- **Path 1:** Per-task verification gate + branch-scope pr-prep (both run).
- **Path 2:** Replace pr-prep with verification + review-fix-loop chain.
- **Path 3:** Two-gate model with explicit inner-gate / outer-gate naming.
- **Path 4:** Defer; keep both, no enforcement.
- **Path 5:** Hook-enforced per-commit verification (verification runs from a git hook, not from agent invocation).
- **Path 6:** CI-as-verification-authority; pr-prep narrows to packaging only.
- **Path 7:** pr-prep as the *audit log* of verification (inverted relationship — pr-prep becomes a read-side roll-up rather than a workflow containing verification).
- **Path 8:** Split verification by failure-mode — three named gates, each guarding a different failure (sycophancy, regression, scope creep).
- **Path 9:** Verification embedded in commit-message trailers (`Verified-By:` line with evidence pointer).
- **Path 10:** Delete pr-prep entirely; absorb everything into a PR description template.
- **Path 11:** Verification as a parallel subagent to implementation (independent verifier challenges the implementer's claims to break single-agent verification optimism).
- **Path 12:** Two-track pr-prep — fast track when verification evidence is strong; full track otherwise.

### Paths flagged as non-obvious

- **Path 7 (audit log):** inverts the relationship. Reframes "verification doesn't happen" as "verification isn't visible." Worth special consideration because it changes what the integration *means*, not just how it composes.
- **Path 8 (failure-mode-keyed gates):** the only path that routes by *which failure* rather than by lifecycle position. Aligns with Phase 0's argument that `code-review` and superpowers' review skills guard different failures.
- **Path 11 (verification subagent):** the only path that responds to a critique of `verification-before-completion` *itself* — single-agent verification optimism, where the implementer's theory biases their tests.

### Open questions for the user before this decision can land

1. Which failure mode hurts most in practice — chat-discipline lapses, local-vs-CI drift, verification invisibility, gate-confusion, or single-agent verification optimism? The answer routes between Paths 3, 5/6, 7, and 11 respectively.
2. Tooling-investment budget — markdown-only constrains hard. Paths 5, 6, 9 require hooks or CI changes; Paths 7, 10, 12 are documentation-only.
3. Should verification be visible to human reviewers, or only to the agent? Controls Paths 7, 9.
4. Is `pr-prep`'s review-fix loop pulling its weight uniformly across PRs, or is it overkill for small ones? Controls Path 12 viability.

### Task 4.1: Record the decision

**Decision (locked 2026-05-18):** **Option A — Path 6 + Path 11 + Path 8.**

- **Path 6 (CI-as-verification-authority), local-first variant** guards against local-vs-CI environment drift, the most concrete observed blocker. Implementation note (added 2026-05-18 per user): GitHub Actions and equivalents are currently degraded under industry-wide AI-driven dev volume; the default execution venue is **local hooks running a CI-equivalent suite**, with remote CI as fallback only. This folds Path 5 (hook-enforced verification) back into the chosen set as the *mechanism* for Path 6, not a competing path.
- **Path 11 (verification subagent)** guards against single-agent verification optimism. Note: the user's most-cited instance of #2 turned out to be an upstream spec-discovery problem (now tracked at `docs/thoughts/iterative-spec-discovery.md`), but Path 11 still has independent value for implementer-bias in well-specified work.
- **Path 8 (failure-mode-keyed gates)** addresses gate-confusion at the routing level rather than just naming (Path 3's lighter approach).

Path 12 was eliminated because its fast-track creates the opposite failure the user actually experiences — under-reviewed small changes that accumulate consolidation work. Uniform review cost is acceptable.

### Strongest argument against this decision (added per critique Finding 7)

Three weaknesses the lock-in didn't stress-test:

1. **Path 11 + iterative-spec-discovery interaction (Finding 10).** Path 11's verification subagent reads a spec to produce its independent verification. On iterative-spec-discovery-shaped work — where the tests *are* the emerging spec — the subagent gets an incomplete spec and writes verification that rubber-stamps incomplete tests. The deferred iterative-spec-discovery workstream means Path 11 ships before the failure it can't handle is addressed. The fix is either to defer Path 11 alongside the workstream or to add an explicit suppression rule on iterative work.
2. **Path 8 vocabulary contradicts Phase 5 routing (Finding 3).** Option A locks Path 8 (failure-mode-keyed gate naming) but Phase 5's routing edits use Path 1/3 lifecycle-position vocabulary. When the follow-up Path-8 plan lands, it will need to tear out Phase 5's edits and rewrite them. Either downgrade Phase 4 to "leaning, final lock when follow-up plan starts" or split Phase 5 explicitly.
3. **The local-first CI/hooks framing has not been pressure-tested with the user.** Path 6's local-first variant is a major implementation choice that emerged in one round of dialogue. Worth sitting with: is the hook-based local CI actually how the user wants to work day-to-day, or was it a constraint stated under conditions (GitHub Actions overload) that may not persist? If GH Actions stabilizes, remote-CI-first might be preferable.

- [ ] **Step 1: Write the decision record**

Create `docs/decisions/NNN-verification-vs-pr-prep.md` capturing:
- The four open questions and the user's answers.
- The eliminated paths and why (Path 12's wrong-direction, Path 10's uniform-cost-is-fine, Path 3's "lighter than Path 8 on the same failure").
- The chosen composition (6 + 11 + 8) and the failure mode each addresses.
- A pointer to the iterative-spec-discovery thoughts doc for the separated workstream.
- Path-dependent follow-ups (see Step 3).

- [ ] **Step 2: Commit**

```bash
git add docs/decisions/NNN-verification-vs-pr-prep.md
git commit -m "docs(decisions): adopt Option A for verification-vs-pr-prep (Paths 6 + 11 + 8)"
```

- [ ] **Step 3: Open a follow-up implementation plan**

Save to `docs/superpowers/plans/YYYY-MM-DD-verification-option-a-implementation.md`. Scope includes, at minimum:

1. **Path 6 (local-first CI gate):** wire a hook-based local CI runner that executes the test suite on commit (pre-commit) and/or push (pre-push); `pr-prep` blocks branch-close on green local run; remote CI is the escalation path, not the default. CLAUDE.md routing names "local CI / hooks" as the authority for the regression-drift failure mode. **Scope is cross-project, not just this repo** — the user wants to retrofit this pattern onto other projects. Tooling investment: likely `pre-commit` framework or equivalent (`lefthook`, `husky`), a shared runner script, and optionally `act` to run gh-actions workflows locally for projects that already have remote CI. Open sub-questions: which hook framework (one choice for portability vs. per-project freedom), whether to package the pattern as a plugin/skill/template in this repo so retrofitting is one-shot rather than per-project bespoke, what's the green/red rule, how to handle slow tests (split into pre-commit fast / pre-push full), how the remote-CI fallback gets invoked when local environment can't run.

2. **Path 11 (verification subagent):** define a subagent dispatch pattern that takes the spec (research doc + plan) and the implementation diff and produces an independent verification report. Wire into `superpowers:subagent-driven-development` task structure. Open sub-questions: when does it fire (every task or selected tasks?), what's the convergence/disagreement protocol, how to brief the subagent so it doesn't inherit the implementer's theory.

3. **Path 8 (failure-mode-keyed gates):** restructure CLAUDE.md routing so gates are named by failure mode (e.g., "regression gate," "sycophancy gate," "scope-creep gate") rather than lifecycle position. Map each named gate to its enforcing mechanism (CI / verification-before-completion / verification-subagent / code-review critic ensemble). Cross-reference the Phase 0 decision record.

The follow-up plan is **out of scope for this plan**. Open it when execution of the main integration plan reaches Phase 5 or earlier if the user wants Phase 4 to land first.

---

## Phase 5 — Update CLAUDE.md routing

Make superpowers skills first-class in the routing tables. Add the assumption-divergence note inline so the agent reads it at session start.

### Task 5.1: Update the workflow decision tree

**Files:**
- Modify: `CLAUDE.md` (sections: "Workflow decision tree", "Skill routing", "Debugging defaults")

- [ ] **Step 1: Update the workflow decision tree row 5 (RPI)**

Old:
> | 5 | **Non-trivial feature or bug fix** ... | `research-plan-implement.md` | The default. ... |

New:
> | 5 | **Non-trivial feature or bug fix** ... | `research-plan-implement.md` (composition over `superpowers:writing-plans` + `superpowers:subagent-driven-development`) | The default. RPI owns the research phase and plan-review gate; superpowers owns plan-writing and execution. If RPI research reveals a design fork, invoke DD inline. If research reveals root cause of a bug, skip to Fix & Verify (see debugging defaults below). |

- [ ] **Step 2: Update the "Skill routing" section**

Add a new sub-section *above* the existing routing table:

```markdown
### Superpowers substrate (load first)

Treat these as the substrate for general development methodology. Local workflows compose over them rather than reimplementing them:

| Trigger | Skill | When |
|---------|-------|------|
| Multi-step task with a spec — about to plan or implement | `superpowers:writing-plans` | Invoked by RPI's Phase 2. Can also be invoked directly when no research phase is needed. |
| Plan exists and ready to execute | `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` | Invoked by RPI's Phase 4. |
| About to claim a task complete | `superpowers:verification-before-completion` | Inner gate. Fires before every completion claim. Refuses analytical inference; requires executed evidence. |
| Any bug, test failure, or unexpected behavior | `superpowers:systematic-debugging` | Supersedes the deleted local `bug-diagnosis`. The "Debugging defaults" section below is the local extension. |
| Receiving code-review feedback (human or from `code-review` orchestrator output) | `superpowers:receiving-code-review` | Governs technical rigor and pushback on incorrect feedback. |
```

- [ ] **Step 3: Update "Debugging defaults" section header**

Replace the deprecation line:
> These principles apply to **all** bug-fixing work, whether inside RPI or standalone. The standalone `bug-diagnosis.md` workflow is deprecated — use these defaults directly.

With:
> These principles are the **local extension** to `superpowers:systematic-debugging`. Invoke that skill for the diagnostic loop itself; the principles below add the 3-failed-hypothesis escape hatch and the handoff-to-RPI path that systematic-debugging does not specify.

- [ ] **Step 4: Add a "Code review vs. external review" note**

After the existing `code-review` row in the skill routing table, add:

```markdown
**Composition note (code-review vs. superpowers review skills):** This repo's `code-review` is **LLM-as-reviewer** — a self-critique pass before the human sees the diff. Superpowers' `requesting-code-review` and `receiving-code-review` are **LLM-as-reviewee** — preparing for external review and responding rigorously. They are complementary: run `code-review` as part of pr-prep; invoke `receiving-code-review` when external feedback (including from `code-review`'s own output) arrives. See `docs/decisions/NNN-code-review-vs-superpowers-review.md` for the full divergence map.
```

- [ ] **Step 5: Mirror edits to AGENTS.md and GEMINI.md**

These are harness-mirrors. Apply the same edits, preserving any harness-specific notes.

- [ ] **Step 6: Commit**

```bash
git add CLAUDE.md AGENTS.md GEMINI.md
git commit -m "feat(routing): make superpowers substrate first-class in workflow decision tree"
```

---

## Phase 6 — Verification of the integration

### Task 6.1: Routing smoke test

**Files:**
- Read: `CLAUDE.md` end-to-end after edits.

- [ ] **Step 1: Re-read CLAUDE.md from a cold-start perspective**

Pretend you have just loaded the file with no prior context. Trace through:
- "I need to fix a bug" → debugging defaults → systematic-debugging
- "I need to add a feature" → decision tree row 5 → RPI → research phase → writing-plans → subagent-driven-development → verification-before-completion
- "I'm about to open a PR" → pr-prep → review-fix-loop → code-review

If any handoff in those traces dead-ends or contradicts another rule, fix it.

- [ ] **Step 2: Verify all referenced files exist**

Run:
```bash
grep -oE '(workflows|skills|templates|guides|docs)/[a-zA-Z0-9_/-]+\.md' CLAUDE.md | sort -u | while read f; do test -e "$f" || echo "MISSING: $f"; done
```
Expected: no "MISSING" output.

- [ ] **Step 3: Commit any fixes**

```bash
git add -p
git commit -m "fix(routing): repair broken cross-references found in cold-start trace"
```

### Task 6.2: Self-eval pass

- [ ] **Step 1: Run `self-eval` on the restructured `workflows/research-plan-implement.md`**

Expected output: `docs/reviews/self-eval-rpi-restructured.md` (already produced in Task 3.3, but re-run after Phase 5 edits land).

- [ ] **Step 2: Run `self-eval` on `CLAUDE.md` itself if the rubric supports CLAUDE.md targets**

If not supported, skip — `self-eval` is skill/workflow-focused.

- [ ] **Step 3: Address any Weak ratings before declaring the integration complete.**

### Task 6.3: Open PR

- [ ] **Step 1: Invoke `workflows/pr-prep.md`**

This is itself a real-world test of the integration: pr-prep should now call `verification-before-completion` (if Phase 4 Path 3 has been implemented in a follow-up) or proceed as before (if Phase 4 is still in decision-only state).

- [ ] **Step 2: Commit and push final state**

---

## Out of scope (explicitly deferred)

- **Phase 4 chosen-path implementation** — this plan only produces the divergence document and frames the decision. Implementation of whichever of the twelve paths is chosen lands in a follow-up plan after the user answers the four open questions.
- **Migrating existing `docs/working/plan-*.md` artifacts to the new RPI structure** — they were written under the old RPI and should be allowed to complete or expire naturally.
- **Adopting `superpowers:test-driven-development` as a routed skill in CLAUDE.md** — TDD is implied by `superpowers:writing-plans`' task structure. Consider promoting it to the routing table only if the agent is observed skipping the TDD steps in writing-plans tasks.
- **Adopting `superpowers:brainstorming` as a routed skill** — already in the available-skills list and auto-triggers from its own description. No routing change needed unless we observe under-triggering.
- **Replacing this repo's `skill-creator` references with `superpowers:writing-skills`** — both ship as plugins; this repo does not own either. Leave as-is.
- **Iterative spec discovery (test-driven spec emergence)** — explicitly separated as its own workstream. Observation captured at `docs/thoughts/iterative-spec-discovery.md`. The failure pattern (spec is distributed across N incrementally-written tests; the aggregate diverges from intent even though each test is locally correct) is not a verification-gate problem and does not belong in this plan's Phase 4 candidate set.
- **Cross-project rollout of the local-first CI/hooks pattern** — Path 6's implementation has scope beyond this repo (retrofitting existing projects). The follow-up plan for Option A will need to decide whether the pattern is packaged as a plugin/skill/template *in this repo* and applied per-project, or just documented as a convention. Either way, the per-project retrofitting work is its own workstream after the pattern stabilizes.

## Self-review

**Spec coverage:**
- Restructure or deprecate RPI in favor of superpowers flow → Phase 1 (decision) + Phase 3 (Option C implementation).
- Remove bug-diagnosis workflow and skill, replace references with systematic-debugging → Phase 2 (full inventory, redirect, delete).
- Diverge on possibilities for verification-before-completion vs pr-prep → Phase 4 (twelve candidate paths in `docs/superpowers/plans/2026-05-18-divergence-verification-vs-pr-prep.md`; **decision locked: Option A = Paths 6 + 11 + 8**; implementation deferred to a follow-up plan).
- Extract differences in assumption between LLM-driven code review and superpowers' implied process → Phase 0 (five-axis divergence note).

**Placeholder check:** Three decision records use `NNN-` filename prefixes; this is intentional — the executor picks the next free integer at write time. All other paths and content are concrete.

**Type consistency:** Single template file (`templates/research-doc-template.md`). Phase 3 references it; Phase 6 verifies it exists. No naming drift.
