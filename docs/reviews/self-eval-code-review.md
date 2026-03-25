---
Last verified: 2026-03-24
Relevant paths:
  - skills/code-review.md
  - skills/code-fact-check.md
  - skills/security-reviewer.md
  - skills/performance-reviewer.md
  - skills/api-consistency-reviewer.md
  - patterns/orchestrated-review.md
  - test/skills/code-review-format.bats
---

# Self-Evaluation: code-review

**Target:** `skills/code-review.md` | **Type:** Skill (Orchestrator) | **Evaluated:** 2026-03-24
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | As an orchestrator, the primary output is a chat synthesis and a structured rubric document. The rubric format (red/amber/green tiers, severity mapping table) has mechanically checkable structural properties. However, testing the quality of synthesis and severity classification requires judgment. The sub-agent dispatch pattern is testable (did it spawn the right agents?) but the orchestration logic is harder to unit test. |
| Trigger clarity | Strong | "Review this code", "full code review", "review this PR" are unambiguous triggers. The description clearly distinguishes from standalone critic invocation ("for a single concern, use the standalone critic"). No confusing overlap with draft-review (code vs. prose). |
| Overlap and redundancy | Strong | No other skill orchestrates multi-perspective code review. Individual critic skills (security-reviewer, performance-reviewer, api-consistency-reviewer) are components, not competitors. draft-review is the prose equivalent — clearly distinct. The orchestrated-review pattern in `patterns/` is a shared design pattern, not a competing tool. |
| Test coverage | Adequate | Format tests exist (`test/skills/code-review-format.bats`). Multiple real-world output artifacts exist in `docs/reviews/`: rubrics (`code-review-rubric.md`), individual critic reports (`security-review.md`, `performance-review.md`, `api-consistency-review.md`), and round-specific reviews (`code-review-r1-*`, `code-review-r2-*`, `code-review-r3-*`). Strong usage evidence; formal eval tests could be added. |
| Pipeline readiness | Strong | This IS the pipeline — it orchestrates code-fact-check and three core critics, with optional contextual critics (test-strategy, tech-debt-triage, dependency-upgrade). All component skills exist. The skill also references the orchestrated-review pattern. Standalone invocation is the primary use case. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the tool does:** Orchestrates a 3-stage code review pipeline: (1) code fact-check verifies comments against implementation, (2) core critics (security, performance, API consistency) analyze in parallel, (3) synthesis combines findings into a chat summary and structured rubric with red/amber/green severity tiers, cross-critic escalation, and contextual critic auto-selection. It enforces strict ordering (fact-check before critics, critics before synthesis) and delegates all analytical work to sub-agents.

**What generic prompting achieves:** Asking Claude to "review this code" without the orchestrator would produce a single-perspective review — likely covering some security and performance concerns but missing the systematic multi-lens approach, the fact-check gate, the severity mapping, and the structured rubric. The skill's main additions: (1) mandatory multi-perspective coverage via dedicated critics, (2) fact-check-first pipeline ensuring factual accuracy before critique, (3) cross-critic convergence detection and escalation, (4) structured rubric with actionable pass/fail status, (5) contextual critic auto-selection based on diff characteristics.

**What built-in tools cover:** The built-in code-simplifier focuses on clarity and maintainability, not security/performance/consistency analysis. The verification-coordinator creates test plans, not multi-perspective reviews. Neither provides structured severity tracking or cross-critic synthesis.

**Questions for the reviewer:**
- How much value comes from the multi-perspective structure vs. the synthesis and severity mapping?
- Has the cross-critic escalation mechanism surfaced issues that a single-pass review would have missed?
- Is the 3-stage ordering (fact-check → critics → synthesis) worth the latency cost, or would parallel execution with post-hoc fact-check integration be preferable?

### User-Specific Fit

**Triggering situations:**
- Before opening a PR, wanting comprehensive multi-perspective review
- After implementing a feature, wanting to catch security, performance, and API consistency issues
- During the review-fix loop, re-running to verify issues are resolved

**Questions for the reviewer:**
- How often do you run full code reviews vs. invoking individual critics?
- Is the full orchestration worth the time for small changes, or do you mostly use it for larger PRs?
- Does the structured rubric actually help you track resolution, or do you just read the chat synthesis?
- Would you invoke this for every PR, or only for certain categories of changes?

### Condition for Value

**Stated or inferred conditions:**
1. The user does code development that benefits from multi-perspective review.
2. All component skills must exist: code-fact-check, security-reviewer, performance-reviewer, api-consistency-reviewer.
3. The Agent tool must be available for sub-agent dispatch.
4. Contextual critics (test-strategy, tech-debt-triage, dependency-upgrade) should exist for auto-selection.

**Automated findings:**
- code-fact-check: EXISTS at `skills/code-fact-check.md`.
- security-reviewer: EXISTS at `skills/security-reviewer.md`.
- performance-reviewer: EXISTS at `skills/performance-reviewer.md`.
- api-consistency-reviewer: EXISTS at `skills/api-consistency-reviewer.md`.
- Contextual critics: ALL EXIST (test-strategy, tech-debt-triage, dependency-upgrade).
- orchestrated-review pattern: EXISTS at `patterns/orchestrated-review.md`.
- Real-world output artifacts: EXIST — multiple rounds of rubrics and reviews in `docs/reviews/`.

**Questions for the reviewer:**
- Are you doing enough code development to justify the orchestration overhead?
- Do you use the contextual critics, or are the three core critics sufficient for your work?
- Is the code-review skill pulling you toward better review practices, or is it ceremony for its own sake?

### Failure Mode Gracefulness

**Output structure:** Two deliverables: (1) chat synthesis organized by cross-critic findings, per-domain findings, and actionable guidance, (2) structured rubric with red/amber/green tiers and clear pass/fail status. The rubric format makes omissions visible — empty tiers or missing critics would be noticed.

**Potential silent failures:**
1. **Weak sub-agent output passed through uncritically.** If a critic produces shallow analysis, the orchestrator may synthesize it without recognizing the lack of depth.
2. **False convergence.** Two critics flagging vaguely similar areas could be escalated when the concerns are actually distinct, inflating severity.
3. **Contextual critic under-selection.** The auto-selection heuristics (file count, line count, dependency manifest changes) are coarse — they may miss situations where contextual critics would add value.
4. **Synthesis bias toward critic consensus.** The synthesis may over-weight convergent findings and under-weight important single-critic observations.

**Pipeline mitigations:** The mandatory fact-check gate catches factual errors early. The structured rubric makes the severity classification reviewable. Individual critic reports are saved alongside the rubric for verification.

**Questions for the reviewer:**
- Have you observed shallow critic output being passed through without the orchestrator flagging it?
- Has the convergence detection produced false positives (escalating distinct concerns)?
- When you review the rubric, do you also check individual critic reports, or trust the synthesis?

---

## Key Questions

1. **Orchestrator vs. individual critics.** The skill's value proposition is the orchestration — multi-perspective coverage, convergence detection, structured tracking. If users mostly invoke individual critics directly, the orchestrator's overhead may not be justified. How often is the full pipeline used vs. standalone critics?

2. **Synthesis quality is hard to test.** The rubric structure is mechanically checkable, but whether the synthesis accurately represents sub-agent findings requires judgment. This is the most important untested dimension.

3. **Contextual critic auto-selection thresholds.** The current heuristics (10+ files, 500+ lines, dependency manifest changes) are reasonable defaults but may not match actual usage patterns. Are these thresholds calibrated to your workflow?
