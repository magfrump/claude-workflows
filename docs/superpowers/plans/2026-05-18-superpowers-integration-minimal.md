# Superpowers Integration — Minimal Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address the two most-cited pain points (parallel debugging-workflow drift, code-review-vs-verification overlap) with minimal restructuring. Land enough to observe the integration's effect for ~a month before deciding whether the larger restructure (in the deferred `2026-05-18-superpowers-integration.md`) is actually needed.

**Architecture:** Two surgical changes.
- **Change 1:** Remove parallel debugging implementation. Delete `workflows/bug-diagnosis.md` and `skills/bug-diagnosis/`; redirect references to `superpowers:systematic-debugging`; resolve the failure-pattern-library write-side severance.
- **Change 2:** Add one explicit verification gate in pr-prep. A single line invoking `superpowers:verification-before-completion` before the review-fix-loop, so analytical critique is preceded by executed evidence.

**What's deferred (and why):** Phase 0 (assumption-divergence record), Phase 1 (RPI direction), Phase 3 (RPI restructure), Phase 4 implementation (CI/hooks + verification subagent + failure-mode-keyed gates), Phase 5 (full CLAUDE.md routing update), cross-project rollout. All preserved in the deferred bigger plan. Decision: observe the minimal change in real use before committing to those.

**Tech Stack:** Markdown edits, bash for ref-finding. No compilation.

---

## Phase A — Remove parallel debugging implementation

### Task A.1: Inventory `bug-diagnosis` references

**Files:**
- Create: `docs/working/bug-diagnosis-cleanup-inventory.md`

- [ ] **Step 1: Generate the full reference list**

Run: `grep -rln "bug-diagnosis\|bug_diagnosis" --include="*.md" /home/magfrump/claude-workflows`
Expected: ~77 files (many with multiple references).

- [ ] **Step 2: Classify every reference into one of five categories**

- **Routing reference** (any `| <activate> |` table entry, decision-tree row, or workflow-trigger pointer): redirect to `superpowers:systematic-debugging`.
- **Composition note** (cross-workflow handoff lines like "from bug-diagnosis → RPI"): redirect to `superpowers:systematic-debugging → research phase of RPI`.
- **Composition-narrative-inside-workflow** (a *section* of another workflow file describing how it interacts with bug-diagnosis): judgment call — usually rewrite to reference `superpowers:systematic-debugging`; if the narrative depended on bug-diagnosis-specific structure that doesn't exist in systematic-debugging, delete or simplify.
- **Historical reference** (working docs, completed-tasks, hypothesis-log, decision records, self-eval reports, `docs/thoughts/`, `docs/human-author/`): leave as-is — dated artifacts.
- **Skill description** (`guides/skill-creation.md`, `guides/README.md`): redirect to `superpowers:systematic-debugging`.

Write the classification to the inventory doc as a four-column table: File · Line · Category · Action.

- [ ] **Step 3: Flag failure-pattern library references specifically**

The inventory must call out every reference to `docs/thoughts/failure-patterns.md` and to the "Failure-pattern grep" / "FP-NNN" audit token. These are addressed in Task A.2, separately.

- [ ] **Step 4: Commit**

```bash
git add docs/working/bug-diagnosis-cleanup-inventory.md
git commit -m "docs(working): inventory bug-diagnosis references for minimal cleanup"
```

### Task A.2: Resolve the failure-pattern library write-side severance

`docs/thoughts/failure-patterns.md` has two live couplings: RPI's research step grep audit token (read-side) and pr-prep's `fix(...)` commit check (advisory). The write-side lives in bug-diagnosis step 8. `superpowers:systematic-debugging` has no equivalent step. Without this task, the library decays.

**Recommended option (for minimal plan): Option B — move grep-and-append discipline into RPI/pr-prep lifecycle gates.** Reasons: (1) preserves cumulative-pattern-learning loop at lowest cost; (2) decouples the discipline from any single skill, so future debugging-tool changes don't re-sever it; (3) read-side already exists in RPI, so this only adds the write-side.

If user prefers Option A (wrap systematic-debugging) or Option C (deprecate library entirely), this task changes shape — see deferred plan's Task 2.4 for those options.

**Files:**
- Modify: `workflows/pr-prep.md` (add write-side check)
- Modify: `docs/thoughts/failure-patterns.md` (update header)
- Create: `docs/decisions/NNN-failure-pattern-library-after-bug-diagnosis-removal.md`

- [ ] **Step 1: Add write-side to pr-prep**

In `workflows/pr-prep.md`, find the existing advisory `fix(...)` commit check (around line 43). Update it so the workflow itself *prompts the agent to append an FP-NNN entry* when a `fix(...)` commit lacks one — rather than pointing the user back to bug-diagnosis step 8. The exact edit:

Replace any line containing `"return to bug-diagnosis.md step 8 and append the entry before opening the PR"` with: `"append a new FP-NNN entry to docs/thoughts/failure-patterns.md describing the root cause and the symptom that led you to it. Use the existing entries as the format reference. Do not skip this step — the library's value compounds only if it's appended to."`

- [ ] **Step 2: Update the failure-patterns.md header**

Currently says `Relevant paths: workflows/bug-diagnosis.md`. Update to: `Relevant paths: workflows/pr-prep.md (write-side: append FP-NNN on fix commits) · workflows/research-plan-implement.md (read-side: grep audit token in research phase)`.

The header's "Append-only one-line log of root-caused bugs from workflows/bug-diagnosis.md" line should be replaced with: "Append-only one-line log of root-caused bugs. Append from pr-prep when a fix commit ships; grep from research phase to surface relevant prior patterns."

- [ ] **Step 3: Write the decision record**

Create `docs/decisions/NNN-failure-pattern-library-after-bug-diagnosis-removal.md`. Find next NNN with `ls docs/decisions/ | grep -E '^[0-9]{3}-' | sort | tail -3`. Content:

```markdown
# NNN: Failure-pattern library after bug-diagnosis removal

## Context
Bug-diagnosis workflow and skill removed in favor of superpowers:systematic-debugging. The failure-pattern library at docs/thoughts/failure-patterns.md had its write-side in bug-diagnosis step 8.

## Options considered
A. Wrap superpowers:systematic-debugging with a local pre/post step.
B. Move grep-and-append discipline into RPI (read) and pr-prep (write).
C. Deprecate the library entirely.

## Decision
**Option B.** Lowest cost preservation of the cumulative-pattern-learning loop. Decouples discipline from any single skill.

## Consequences
- pr-prep workflow now owns the write-side prompt.
- Header of failure-patterns.md updated to reflect new paths.
- Read-side (RPI research grep audit) unchanged.
```

- [ ] **Step 4: Commit**

```bash
git add workflows/pr-prep.md docs/thoughts/failure-patterns.md docs/decisions/NNN-failure-pattern-library-after-bug-diagnosis-removal.md
git commit -m "refactor: re-home failure-pattern library write-side from bug-diagnosis to pr-prep"
```

### Task A.3: Update routing and composition references

**Files:**
- Modify: every file flagged "routing" or "composition" or "composition-narrative-inside-workflow" or "skill description" in Task A.1's inventory.

- [ ] **Step 1: Update `CLAUDE.md` Debugging defaults section**

Find the lines:

> The standalone `bug-diagnosis.md` workflow is deprecated — use these defaults directly.

and at the end of the section:

> For complex bugs that need a formal diagnosis log, the template and full process remain available in `workflows/bug-diagnosis.md`.

Replace both with a single forward-pointer:

> Invoke `superpowers:systematic-debugging` for the core diagnostic loop. The numbered principles below are the local extension — the 3-failed-hypothesis escape hatch with handoff-doc emission, and the bug-diagnosis-to-RPI handoff path. These principles complement systematic-debugging, which provides the loop itself.

The numbered debugging principles (1-6) stay unchanged.

- [ ] **Step 2: Update `AGENTS.md` and `GEMINI.md`**

`AGENTS.md` has a line that reads: `**@./workflows/bug-diagnosis.md** — Lightweight hypothesis-test debugging loop: reproduce → isolate → hypothesize → test → fix → verify.`

Replace with: `**superpowers:systematic-debugging** — Hypothesis-test debugging loop. Local extension (3-failed-hypothesis escape hatch, RPI handoff) lives in CLAUDE.md's Debugging defaults section.`

Apply the equivalent edit to `GEMINI.md` (find the analogous line; if the phrasing is harness-specific, preserve the harness convention but update the target).

- [ ] **Step 3: Update workflow and guide cross-references**

For each file flagged routing/composition/skill-description in the inventory (excluding historical-reference files):
- Routing references → replace `bug-diagnosis` with `superpowers:systematic-debugging`.
- Composition references → preserve the composition narrative; update the destination name.
- Composition-narrative-inside-workflow → judgment call per inventory. Default to "rewrite reference, preserve narrative."
- Skill description → replace pointer.

The largest reference sites to touch: `workflows/codebase-onboarding.md`, `workflows/pr-prep.md`, `workflows/research-plan-implement.md`, `docs/workflow-selection.md`, `docs/workflow-dependency-graph.md`, `guides/workflow-selection.md`, `guides/skill-creation.md`, `guides/README.md`.

- [ ] **Step 4: Verify**

Run: `grep -rln "workflows/bug-diagnosis\|skills/bug-diagnosis" --include="*.md" /home/magfrump/claude-workflows | grep -v "docs/working\|docs/thoughts\|docs/decisions\|docs/reviews\|docs/human-author"`
Expected: no output. (Historical references in those directories are intentionally preserved.)

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md AGENTS.md GEMINI.md workflows/codebase-onboarding.md workflows/research-plan-implement.md docs/workflow-selection.md docs/workflow-dependency-graph.md guides/
git commit -m "refactor(routing): redirect bug-diagnosis references to superpowers:systematic-debugging"
```

### Task A.4: Delete the workflow and skill

**Files:**
- Delete: `workflows/bug-diagnosis.md`
- Delete: `skills/bug-diagnosis/`

- [ ] **Step 1: Confirm no live references remain**

Run: `grep -rln "workflows/bug-diagnosis.md\|skills/bug-diagnosis" --include="*.md" /home/magfrump/claude-workflows | grep -v "docs/working\|docs/thoughts\|docs/decisions\|docs/reviews\|docs/human-author"`
Expected: no output.

- [ ] **Step 2: Delete**

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

---

## Phase B — Add verification gate to pr-prep

### Task B.1: Insert `verification-before-completion` invocation before review-fix-loop

**Files:**
- Modify: `workflows/pr-prep.md`

- [ ] **Step 1: Locate the review-fix-loop invocation in pr-prep**

Run: `grep -n "review-fix\|review_fix" workflows/pr-prep.md`
Find the line(s) where the workflow invokes or references `workflows/review-fix-loop.md` (or the analogous composition step).

- [ ] **Step 2: Insert the verification gate immediately before**

Add a new sub-step or line above the review-fix-loop invocation:

> **Before running review-fix-loop, invoke `superpowers:verification-before-completion`.** Analytical critique from the loop's critic ensemble is not a substitute for executed evidence. Verification must run first; if it fails (tests don't pass, claims can't be backed by output), do not proceed to the critic ensemble — fix the underlying issue first.

- [ ] **Step 3: Commit**

```bash
git add workflows/pr-prep.md
git commit -m "feat(pr-prep): require verification-before-completion before review-fix-loop"
```

---

## Phase C — Minimal verification

### Task C.1: Smoke-test the changed routing

- [ ] **Step 1: Re-read CLAUDE.md**

Read end-to-end. Trace through three scenarios:
1. "I need to fix a bug" → debugging defaults → `superpowers:systematic-debugging`. Confirm no dangling reference to `workflows/bug-diagnosis.md` or `skills/bug-diagnosis/`.
2. "I'm about to open a PR" → pr-prep → `superpowers:verification-before-completion` → review-fix-loop. Confirm the verification step is unambiguous.
3. "3 hypotheses failed, I need to pivot to RPI" → `superpowers:systematic-debugging` produces handoff doc → RPI research phase reads "What this bug isn't" section. Confirm the handoff narrative still resolves (this is the failure-path trace the critique flagged).

If any trace dead-ends or contradicts itself, fix the routing.

- [ ] **Step 2: Verify all referenced files exist**

Run:
```bash
grep -oE '(workflows|skills|templates|guides|docs)/[a-zA-Z0-9_/-]+\.md' CLAUDE.md AGENTS.md GEMINI.md | sort -u | while read f; do test -e "$f" || echo "MISSING: $f"; done
```
Expected: no "MISSING" output.

- [ ] **Step 3: Verify failure-pattern library write-side is wired**

Read `workflows/pr-prep.md`'s failure-pattern advisory check. Confirm it now points at the in-workflow append prompt rather than at the deleted bug-diagnosis step 8.

- [ ] **Step 4: Commit any fixes**

```bash
git add -p
git commit -m "fix(routing): repair cross-references found in minimal-plan smoke test"
```

---

## Phase D — Observation period

This phase is not a task. It's the **decision gate** before re-opening the deferred bigger plan.

### Signals to watch for over the next ~month of use

**Evidence the minimal change was sufficient (don't expand scope):**
- `superpowers:systematic-debugging` handles debugging cleanly; the deleted local skill is not missed.
- The `verification-before-completion` gate in pr-prep actually fires and catches things the critic ensemble was previously rubber-stamping.
- The failure-pattern library continues accumulating entries (post-Task A.2 wiring works).
- No new contributor confusion about which workflow to invoke for what.

**Evidence the bigger plan is needed (re-open `2026-05-18-superpowers-integration.md`):**
- RPI's 502-line scaffolding produces friction in actual sessions — primitives mentioned but not used, or used but not understood.
- The "complementary not redundant" framing of code-review-vs-verification breaks down in practice (one is doing the other's job).
- The local-vs-CI drift that Path 6 was designed to fix actually manifests.
- Multiple invocations of `superpowers:writing-plans` produce work that's worse than current RPI in observable ways.

### When to revisit

After the observation period (~1 month, calendar-flex), re-read this plan, the deferred plan, the critique, and `docs/thoughts/iterative-spec-discovery.md`. Decide:
- Ship the bigger plan with critique fixes integrated.
- Ship a third version informed by what was actually observed.
- Stay minimal indefinitely.

Capture observations during the period in `docs/thoughts/minimal-integration-observations.md` (create on first observation, not now).

---

## Self-review

**Spec coverage:**
- Remove parallel debugging implementation → Phase A.
- Address failure-pattern library write-side severance → Task A.2 (Option B chosen).
- Add executed-evidence gate before analytical critique → Phase B.
- Set up observation period before broader restructure → Phase D.

**Placeholder check:** One `NNN-` filename prefix in Task A.2 step 3, intentional — executor picks the next free integer at write time. All other paths concrete.

**Type consistency:** Single edit target for the pr-prep verification gate (Phase B); same file is also edited in Task A.2 for the failure-pattern write-side. Both edits should land in the order Task A.2 → Phase B to avoid merge conflicts in pr-prep.md.

**What this plan does NOT do** (intentionally, per scope-down decision):
- Restructure RPI (deferred plan Phase 3).
- Decide verification-vs-pr-prep composition beyond the single-line edit (deferred plan Phase 4).
- Update CLAUDE.md's substrate-registration routing tables (deferred plan Phase 5).
- Touch AGENTS.md or GEMINI.md beyond the bug-diagnosis line (deferred plan Phase 5).
- Set up CI/hooks, verification subagent, or failure-mode-keyed gates (Path 6/11/8 — follow-up plan after deferred main plan).
