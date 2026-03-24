---
Last verified: 2026-03-23
Relevant paths:
  - skills/draft-review.md
  - skills/fact-check.md
  - skills/cowen-critique.md
  - skills/yglesias-critique.md
---

# Self-Evaluation: draft-review

**Target:** `skills/draft-review.md` | **Type:** Skill (orchestrator) | **Evaluated:** 2026-03-23
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | The pipeline produces structured artifacts (verification rubric with red/amber/green tiers, fact-check report, critic critiques) whose structural properties are mechanically checkable. However, assessing synthesis quality -- whether convergence analysis is accurate, whether rubric tier assignments are correct -- requires human judgment. A test with a draft containing planted errors could verify the pipeline dispatches correctly and the rubric contains expected items, but synthesis quality remains subjective. |
| Trigger clarity | Strong | The description provides specific trigger phrases ("review this draft", "fact-check and critique this", "give me feedback on this") that are unambiguous. No other skill in the repo orchestrates multi-stage prose review. The boundary with code-review is clear (prose vs. code). Standalone critic skills (cowen-critique, yglesias-critique) could overlap for users who want a single perspective, but the description explicitly handles this: "for multiple perspectives on a piece of writing." |
| Overlap and redundancy | Strong | No other skill orchestrates multi-stage draft review. The code-review orchestrator follows the same architectural pattern but targets a completely different domain (code changes vs. prose drafts). Matrix-analysis is a different kind of orchestrator (criteria-based comparison, not staged review pipeline). The individual critic skills it composes are distinct from it -- draft-review adds sequential staging, convergence analysis, and rubric generation that none of the component skills provide. |
| Test coverage | Adequate | No automated tests exist in `test/`. However, the pipeline has been run at least once on real work: commit 96a3ed5 ("docs: Add review artifacts from draft-review orchestrator") produced fact-check, critic, and verification rubric artifacts that are present in `docs/reviews/`. The existing `docs/reviews/verification-rubric.md` demonstrates the rubric output format in practice. The `full-evaluation.md` also contains a prior manual evaluation of this skill. This is real-world usage evidence without automated tests -- adequate but not strong. |
| Pipeline readiness | Strong | Draft-review *is* the pipeline. It composes fact-check (exists), cowen-critique (exists), and yglesias-critique (exists) into a functioning multi-stage review. Both critic skills list `fact-check` in their `requires` block, confirming the dependency chain. The skill is also standalone viable -- it is the entry point users invoke directly. No missing infrastructure. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the tool does:** Draft-review orchestrates a multi-stage prose review pipeline. It runs a fact-check pass first, optionally gates on high-confidence inaccuracies, then dispatches critic agents in parallel (auto-discovered from `skills/`), then synthesizes all results into a freeform chat summary and a structured verification rubric with red/amber/green status tracking. It supports ensemble mode for higher confidence through convergence analysis.

**What generic prompting achieves:** Asking Claude "review this draft thoroughly" would produce a single-pass review covering facts and argumentation together, without separation of concerns. Specific elements that generic prompting would likely miss: (1) sequential fact-check-then-critique staging that prevents critics from building on unchecked facts, (2) parallel independent critic dispatch ensuring critics don't anchor on each other, (3) convergence analysis across multiple critic perspectives, (4) the structured verification rubric with tier assignment rules and status tracking, (5) the fact-check gate pattern that prevents wasted compute on drafts with known errors.

**What built-in tools cover:** No built-in Claude Code capability orchestrates multi-agent draft review. The built-in verification-coordinator handles code verification, not prose review.

**Questions for the reviewer:**
- How much of draft-review's value comes from the pipeline architecture (staging, independence, convergence) vs. the specific synthesis and rubric output?
- Is the gap "the orchestrator coordinates agents the user couldn't coordinate manually" or "the orchestrator ensures a process the user would otherwise shortcut"?
- Under what conditions is the gap largest -- complex drafts with many checkable claims, or shorter pieces where a single-pass review might suffice?

### User-Specific Fit

**Triggering situations:** The user has a written draft (blog post, essay, article, policy piece) and wants a comprehensive multi-perspective review before publishing or sharing. Also triggered when the user wants to combine fact-checking with substantive critique in a single pass.

**Questions for the reviewer:**
- How often do you produce written drafts that would benefit from this level of review (fact-check + multiple critics + synthesis)?
- Is the frequency increasing or decreasing?
- Does a comprehensive multi-agent review match the stage of drafts you typically want feedback on, or is it overkill for most cases?
- Would you actually remember to invoke this (vs. asking for a simpler "review this") when you have a draft ready?

### Condition for Value

**Stated or inferred conditions:** (1) The fact-check skill must exist -- it does. (2) At least one critic skill must exist -- cowen-critique and yglesias-critique both exist. (3) The user must produce written drafts that benefit from multi-perspective review. (4) The Task tool must be available for sub-agent dispatch.

**Automated findings:**
- fact-check skill: EXISTS (`skills/fact-check.md`)
- cowen-critique skill: EXISTS (`skills/cowen-critique.md`)
- yglesias-critique skill: EXISTS (`skills/yglesias-critique.md`)
- Prior pipeline execution: YES (commit 96a3ed5, artifacts in `docs/reviews/`)
- All infrastructure conditions are met today.

**Questions for the reviewer:**
- Is the remaining condition -- that you produce drafts benefiting from multi-perspective review -- met today?
- Does the overhead of a full pipeline run (multiple sub-agents, structured rubric) match the stakes of your typical drafts?
- Is this tool an active part of your writing workflow, or has it been used once and not returned to?

### Failure Mode Gracefulness

**Output structure:** Two deliverables. The freeform chat synthesis is organized by convergence signal (factual issues, structural critique, strengths, actionable guidance). The verification rubric is a structured document with red/amber/green tiers, explicit tier assignment rules, and status tracking. Both include source attribution (which agent/critic raised each point).

**Potential silent failures:**
- Biased tier assignment: the orchestrator could systematically over- or under-classify findings (e.g., putting amber items in green). The structured tier rules mitigate this, but the orchestrator applies them using judgment.
- Missed convergence: if two critics raise the same point in different language, the orchestrator might fail to detect the convergence and classify it as two green items instead of one amber item.
- Synthesis distortion: the orchestrator could misrepresent a critic's finding in the synthesis, either strengthening or weakening it. The individual critic reports are preserved as artifacts, enabling spot-checking.
- Sub-agent failure masking: the mandatory execution rules require noting failed agents, but the orchestrator could subtly compensate by filling gaps itself despite Rule 1 prohibiting this.

**Pipeline mitigations:** Individual agent outputs are saved as separate files in `docs/reviews/`, enabling the user to cross-check the synthesis against source reports. The explicit checkpoint rules require counting returned results. The fact-check gate prevents downstream waste on flawed drafts.

**Questions for the reviewer:**
- Have you observed any cases where the synthesis misrepresented a critic's findings?
- Have you cross-checked the verification rubric tier assignments against the raw critic reports?
- Is the detectable-to-silent failure ratio acceptable given that source reports are preserved for verification?

---

## Key Questions

1. **Has the full pipeline been stress-tested on complex prose?** The existing usage evidence (commit 96a3ed5) applied draft-review to a technical skill document (the code-review orchestrator), not a traditional prose draft with checkable empirical claims. The fact-check gate, ensemble mode, and convergence analysis across genuinely different critic perspectives have not been validated on the kind of input the skill is primarily designed for.

2. **Is the complexity justified by the drafts it reviews?** The skill has many code paths: fact-check gate, ensemble mode, convergence analysis, structured rubric with three tiers. For a short blog post, this may be overkill. For a long policy paper, it may be essential. What is the typical draft that triggers this, and does the pipeline's complexity match?

3. **Does the orchestrator actually follow its own mandatory execution rules?** Rules 1-5 are strict constraints (must use Task tool, must wait for checkpoints, must not fill gaps). These are architectural invariants that are difficult to verify without running the pipeline and inspecting the execution trace. A test case that verifies rule compliance would significantly increase confidence.
