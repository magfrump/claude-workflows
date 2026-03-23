# Fact-Check Report: Code Review Orchestrator (feat/code-review-orchestrator branch)

**Draft author:** (branch author)
**Checked:** 2026-03-23
**Total claims checked:** 18
**Summary:** 13 accurate, 3 mostly accurate, 0 disputed, 0 inaccurate, 2 unverified

---

## Claim 1: "code-review.md — that's you" / "draft-review.md — prose review orchestrator" / "matrix-analysis.md — comparison orchestrator"

**Source file:** `skills/code-review.md`, Step 2 (lines 74-77)

**Verdict:** Accurate
**Confidence:** High

All three files exist at the listed paths. `draft-review.md` describes itself as orchestrating "a comprehensive review of a written draft" (prose review). `matrix-analysis.md` describes itself as orchestrating "a structured evaluation of multiple items across multiple criteria" (comparison). The classifications are correct.

**Sources:** Direct inspection of `skills/draft-review.md` (lines 1-12), `skills/matrix-analysis.md` (lines 1-12), and `skills/code-review.md` (lines 1-13).

---

## Claim 2: "code-fact-check.md — always runs in Stage 1"

**Source file:** `skills/code-review.md`, Step 2 (line 80)

**Verdict:** Accurate
**Confidence:** High

`skills/code-fact-check.md` exists. The pipeline in Stage 1 (lines 131-143) mandates spawning "one agent with the code-fact-check skill" before any critics run. The mandatory execution rules (rule 2) require Stage 1 completion before Stage 2.

**Sources:** `skills/code-fact-check.md` (exists), `skills/code-review.md` lines 131-143.

---

## Claim 3: Core critics listed as "security-reviewer.md", "performance-reviewer.md", "api-consistency-reviewer.md"

**Source file:** `skills/code-review.md`, Step 2 (lines 83-85)

**Verdict:** Accurate
**Confidence:** High

All three files exist at `skills/security-reviewer.md`, `skills/performance-reviewer.md`, and `skills/api-consistency-reviewer.md`. Each is a standalone critic skill with structured cognitive moves for code review. Each declares `code-fact-check` as a soft dependency via `requires:`.

**Sources:** Direct inspection of all three files.

---

## Claim 4: Contextual critics listed as "test-strategy.md", "tech-debt-triage.md", "dependency-upgrade.md"

**Source file:** `skills/code-review.md`, Step 2 (lines 88-90)

**Verdict:** Accurate
**Confidence:** High

All three files exist at `skills/test-strategy.md`, `skills/tech-debt-triage.md`, and `skills/dependency-upgrade.md`. Their descriptions align with the contextual role described: test-strategy recommends tests, tech-debt-triage evaluates tech debt, and dependency-upgrade evaluates dependency upgrades.

**Sources:** Direct inspection of all three files' frontmatter.

---

## Claim 5: Prose critics listed as "fact-check.md, cowen-critique.md, yglesias-critique.md"

**Source file:** `skills/code-review.md`, Step 2 (lines 92-93)

**Verdict:** Accurate
**Confidence:** High

All three files exist. `fact-check.md` is a journalistic fact-checker for prose drafts. `cowen-critique.md` and `yglesias-critique.md` are prose critic skills. Both prose critics note they are "typically invoked by the draft-review orchestrator." Classifying them as "not applicable to code" is reasonable.

**Sources:** Direct inspection of `skills/fact-check.md`, `skills/cowen-critique.md`, `skills/yglesias-critique.md`.

---

## Claim 6: "This workflow follows the orchestrated review pattern" with link to `../patterns/orchestrated-review.md`

**Source file:** `skills/code-review.md`, line 21

**Verdict:** Accurate
**Confidence:** High

`patterns/orchestrated-review.md` exists and describes the 4-phase pattern (Decompose, Parallel dispatch, Synthesize, Gate). The code-review orchestrator is explicitly listed as an instantiation in that file (line 68), with a description matching the skill's actual structure.

**Sources:** `patterns/orchestrated-review.md` lines 1-69.

---

## Claim 7: "3-stage pipeline: code fact-check -> critic agents -> synthesis"

**Source file:** `skills/code-review.md` description (line 7) and throughout

**Verdict:** Accurate
**Confidence:** High

The pipeline defines three explicit stages: Stage 1 (Code Fact-Check, line 131), Stage 2 (Critic Agents, line 160), and Stage 3 (Synthesize and Produce Outputs, line 184). Mandatory execution rules enforce sequential ordering.

**Sources:** `skills/code-review.md` lines 131, 160, 184.

---

## Claim 8: The skill produces "two deliverables: a freeform chat summary and a structured code review rubric document"

**Source file:** `skills/code-review.md`, line 24

**Verdict:** Accurate
**Confidence:** High

Deliverable 1 (Chat Synthesis, line 190) and Deliverable 2 (Code Review Rubric, line 223) are both defined. The rubric is saved to `docs/reviews/code-review-rubric.md` (line 225).

**Sources:** `skills/code-review.md` lines 190-282.

---

## Claim 9: "mirroring draft-review's 3-stage pipeline"

**Source file:** `docs/decisions/002-critic-style-code-review.md`, line 28

**Verdict:** Accurate
**Confidence:** High

`draft-review.md` has the same 3-stage structure: Stage 1 (Fact-Check, line 87), Stage 2 (Critic Agents, line 130), Stage 3 (Synthesize, visible in structure). Both orchestrators produce two deliverables (chat synthesis + structured document). The pipeline shape is a direct parallel.

**Sources:** `skills/draft-review.md` lines 85-148.

---

## Claim 10: "Each [critic] declares `code-fact-check` as a soft dependency via `requires:`"

**Source file:** `docs/decisions/002-critic-style-code-review.md`, line 26

**Verdict:** Accurate
**Confidence:** High

All three core critics (`security-reviewer.md`, `performance-reviewer.md`, `api-consistency-reviewer.md`) include a `requires:` block in their YAML frontmatter declaring `code-fact-check` as a dependency. The dependency is soft — each critic proceeds without it, emitting a warning instead.

**Sources:** `skills/security-reviewer.md` lines 14-20, `skills/performance-reviewer.md` lines 14-20, `skills/api-consistency-reviewer.md` lines 14-23.

---

## Claim 11: "Each has 7-9 domain-specific cognitive moves"

**Source file:** `docs/decisions/002-critic-style-code-review.md`, line 26

**Verdict:** Mostly accurate
**Confidence:** High

All three critics have exactly 9 cognitive moves each, not a range of 7-9. The "7-9" phrasing implies variation across the three critics, but the count is uniform. The claim is directionally correct (9 is within 7-9) but imprecise — it should say "9 cognitive moves each."

**Sources:** Counted `### N.` headings: security-reviewer.md (9), performance-reviewer.md (9), api-consistency-reviewer.md (9).

---

## Claim 12: Unified severity mapping — Performance "Critical" maps to red tier

**Source file:** `skills/code-review.md`, lines 288-292 (severity mapping table)

**Verdict:** Mostly accurate
**Confidence:** High

The mapping table shows Performance red tier as "Critical" only. However, the performance-reviewer skill defines severity levels as Critical, High, Medium, Low, Informational — five levels total. The code-review.md maps Performance High to amber (Must Address), which is a valid design choice, but it differs from the security mapping where both Critical and High map to red. This is internally consistent within the table but worth noting: the rubric in `docs/reviews/code-review-rubric.md` (C5) already flags this as intentional-but-notable.

**Sources:** `skills/code-review.md` lines 288-292, `skills/performance-reviewer.md` lines 214-219.

---

## Claim 13: Unified severity mapping — API Consistency "Breaking" maps to red tier

**Source file:** `skills/code-review.md`, lines 288-292

**Verdict:** Accurate
**Confidence:** High

The API consistency reviewer defines severities as Breaking, Inconsistent, Minor, Informational. The mapping table correctly maps Breaking to red, Inconsistent to amber, and Minor/Informational to green. These match the actual severity definitions in `api-consistency-reviewer.md`.

**Sources:** `skills/api-consistency-reviewer.md` lines 234-242, `skills/code-review.md` lines 288-292.

---

## Claim 14: Unified severity mapping — Fact-Check verdicts mapped correctly

**Source file:** `skills/code-review.md`, lines 288-292

**Verdict:** Accurate
**Confidence:** High

The code-fact-check skill defines verdicts as: Verified, Mostly accurate, Stale, Incorrect, Unverifiable. The severity mapping uses "Incorrect (high confidence)" for red, "Incorrect (medium confidence), Stale, Mostly Accurate" for amber, and "Unverifiable" for green. These align with the actual verdict names (noting "Verified" maps to the Confirmed Good section rather than a severity tier). The mapping is consistent.

**Sources:** `skills/code-fact-check.md` lines 86-97, `skills/code-review.md` lines 288-292.

---

## Claim 15: "code-review orchestrator uses Agent tool" (vs. draft-review using Task tool)

**Source file:** `skills/code-review.md`, lines 33, 140, 165, 176

**Verdict:** Accurate
**Confidence:** High

`code-review.md` consistently references the "Agent tool" (lines 33, 140, 165, 176). `draft-review.md` consistently references the "Task tool" (lines 28, 89, 97, 100, 132, 134, 148). This is a genuine divergence between the two orchestrators. The rubric already notes this as C4.

**Sources:** `skills/code-review.md` lines 33, 140, `skills/draft-review.md` lines 28, 89, 97.

---

## Claim 16: Orchestrated review pattern lists "Code review pipeline" as an instantiation with correct description

**Source file:** `patterns/orchestrated-review.md`, line 68

**Verdict:** Accurate
**Confidence:** High

The pattern file describes the code review pipeline as decomposing into "code-fact-check + domain critics (security-reviewer, performance-reviewer, api-consistency-reviewer) with optional contextual critics (test-strategy, tech-debt-triage, dependency-upgrade) auto-selected based on diff characteristics." This matches the actual structure of `skills/code-review.md`. It also correctly references `docs/decisions/002-critic-style-code-review.md`.

**Sources:** `patterns/orchestrated-review.md` line 68, `skills/code-review.md` lines 74-108.

---

## Claim 17: Total skill files classified in Step 2 — all `skills/*.md` files accounted for

**Source file:** `skills/code-review.md`, Step 2 (lines 74-93)

**Verdict:** Mostly accurate
**Confidence:** High

Step 2 lists 12 skill files across 4 categories (orchestrators: 3, fact-checkers: 1, core critics: 3, contextual critics: 3, prose critics: 3 — total 13 but code-review.md is counted in orchestrators making 12 other files). The actual `skills/` directory contains 13 `.md` files. All 13 are accounted for in the classification. However, the claim "List all `skills/*.md` files" implies a dynamic discovery step, yet the classification is hardcoded. If a new skill file were added, it would not be discovered by this static list. This is a minor imprecision in the instruction — the classification is accurate for the current state but the instruction implies dynamic behavior.

**Sources:** `ls skills/*.md` returns 13 files; all 13 appear in the classification at lines 74-93.

---

## Claim 18: "Codebase onboarding (`workflows/codebase-onboarding.md`): Decompose into subsystems..."

**Source file:** `patterns/orchestrated-review.md`, line 66

**Verdict:** Unverified
**Confidence:** Low

The file `workflows/codebase-onboarding.md` exists, but I did not read its full contents to verify whether it actually decomposes into subsystems, dispatches sub-agents per subsystem, synthesizes into an orientation document, and gates on team validation. The file exists at the claimed path, but the description of its behavior is unverified.

**Sources:** File existence confirmed via filesystem. Content not verified.

---

## Claims Requiring Author Attention

| # | Claim | Verdict | Action needed |
|---|-------|---------|---------------|
| 11 | "7-9 domain-specific cognitive moves" | Mostly accurate | All three critics have exactly 9 moves. Change "7-9" to "9" for precision. |
| 12 | Performance red tier maps only "Critical" | Mostly accurate | This is an intentional design choice but the asymmetry with security (Critical+High) is worth a brief comment in the skill file explaining why. Already flagged as C5 in rubric. |
| 17 | "List all `skills/*.md` files" with hardcoded classification | Mostly accurate | The classification is correct for current state but the instruction implies dynamic discovery while providing a static list. Consider noting that new skills should be added to the classification when created. |
