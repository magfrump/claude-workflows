# Self-Evaluation: review-fix-loop

**Target:** `workflows/review-fix-loop.md` | **Type:** Workflow (reference material for pr-prep) | **Evaluated:** 2026-03-24
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | The workflow is reference material describing loop dynamics and anti-patterns. Its value is conceptual (helping the user understand *why* the loop converges and *what* to avoid). There is no structured output to validate mechanically -- the artifacts belong to the review skills it references, and the process guidance is inherently judgment-dependent. |
| Trigger clarity | Strong | The document is explicitly scoped as reference material for pr-prep Step 3, not a standalone workflow. It says "It should not be run as a standalone workflow -- use pr-prep." This eliminates trigger ambiguity entirely: the user follows pr-prep, and pr-prep links here for extended discussion. CLAUDE.md's workflow index now describes pr-prep as including "a required review-fix loop," which reinforces this. |
| Overlap and redundancy | Strong | Now that the document is positioned as reference material for pr-prep rather than a standalone workflow, overlap concerns are resolved. It does not compete with pr-prep for the user's attention; it supplements it. The loop procedure lives in pr-prep Step 3; review-fix-loop.md provides the "why" (loop dynamics, anti-patterns, relationship to RPI) that would bloat pr-prep if included inline. This is a clean separation of procedure from rationale. |
| Test coverage | Weak | No test files reference this workflow. No example output artifacts exist. The git history shows one commit creating the workflow and several code-review artifacts that reference it, but no evidence of the loop dynamics being exercised in practice (i.e., a branch that went through multiple review-fix iterations with documented convergence). Probationary state. |
| Pipeline readiness | Strong | The workflow is embedded in pr-prep as a required sub-step (Step 3). pr-prep is a well-established workflow referenced in CLAUDE.md. The pipeline exists and is functional: pr-prep sequences commit cleanup, CI verification, review-fix loop, PR description, annotation, and size check. The review-fix loop composes code-review and self-eval skills, both of which exist. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does:** Provides reference material explaining why iterative review-fix loops converge (early reviews are dominated by surface issues that mask deeper ones), what anti-patterns to avoid (fixing Consider items before Must Fix; skipping the test run between fix and re-review), how the loop relates to other workflows (complements RPI, embedded in pr-prep), and what artifacts it operates on. The procedure itself lives in pr-prep Step 3.

**What ad-hoc process achieves:** Without this document, someone following pr-prep Step 3 would have the procedure but not the rationale. They would know *what* to do (run reviews, triage, fix, retest, re-review) but might not understand *why* the iteration matters (fixes reveal deeper issues) or when to stop vs. escalate (convergence ceiling signals architectural problems). The anti-patterns section is the most likely unique value -- "don't fix style before correctness" is obvious in theory but easy to violate in practice when findings arrive in an unordered list.

**What built-in tools cover:** No built-in Claude Code capability covers iterative review loop rationale.

**Questions for the reviewer:**
- Is the "loop dynamics" insight (each iteration operates on a higher-quality baseline) something you internalized already, or does having it written down actually change behavior?
- When you have done review-fix loops in practice, did you encounter the anti-patterns described here? Would having them documented have prevented them?
- Is the document's value primarily as a teaching artifact (read once, internalize, rarely revisit) or as active reference material (consulted during each pr-prep run)?

### User-Specific Fit

**Triggering situations:**
- Following pr-prep Step 3 and wanting to understand the loop dynamics more deeply
- Encountering a situation where review findings are not converging and needing guidance on when to stop
- Onboarding to the workflow system and wanting to understand why pr-prep has an iterative review step

**Questions for the reviewer:**
- How often do you actually consult reference material during a pr-prep run, vs. just following the procedure in pr-prep Step 3 directly?
- Is this document's value front-loaded (useful when first learning the workflow system) or ongoing (useful each time you hit a non-converging loop)?
- Does the relationship-to-other-workflows section (how review-fix-loop connects RPI to pr-prep) add value, or is that connection already obvious from reading both workflows?

### Condition for Value

**Stated or inferred conditions:**
1. pr-prep must exist and be actively used -- this document is reference material for pr-prep Step 3.
2. The review skills (code-review, self-eval) must produce findings worth iterating on -- if reviews are always clean on the first pass, the loop rationale is moot.
3. The user must encounter situations where a single review pass is insufficient -- small or trivial changes do not benefit from loop dynamics.

**Automated findings:**
- pr-prep workflow: EXISTS and is referenced in CLAUDE.md
- code-review skill: EXISTS (skills/code-review.md)
- self-eval skill: EXISTS (skills/self-eval.md)
- CLAUDE.md now describes pr-prep as including "a required review-fix loop" -- the integration is documented
- Review artifacts from code-review runs exist in docs/reviews/ (code-review-rubric, security-review, etc.)

**Questions for the reviewer:**
- Are conditions 1-3 met today? Specifically, do your pr-prep runs typically require 2+ review-fix iterations, or do most branches pass after a single review?
- Is the document's value conditional on branch complexity (only matters for large changes) or general (the anti-patterns apply even to small branches)?
- If most branches converge in one iteration, does this document become speculative inventory -- or does it earn its place by being available for the occasional complex branch?

### Failure Mode Gracefulness

**Output structure:** The document produces no output -- it is reference material. Its "failure" would be giving advice that leads to worse outcomes than not having the advice.

**Potential silent failures:**
1. **Premature exit guidance:** The convergence criterion ("findings should strictly decrease each loop") could cause someone to stop iterating when findings decrease numerically but the remaining findings are more severe. A loop going from 10 Consider items to 3 Must Fix items is getting worse, not better, even though the count dropped.
2. **Anti-pattern list creates false confidence:** Listing two anti-patterns implies these are the main pitfalls. A user who avoids both listed anti-patterns may assume they are on track when other unlisted anti-patterns apply (e.g., fixing findings without understanding them, or not questioning whether a finding is real).
3. **Misapplied convergence ceiling guidance:** The document says "if findings aren't converging after 3-4 loops, the problem is architectural." This is in pr-prep Step 3, but review-fix-loop.md reinforces the framing. A user might incorrectly conclude their code has an architectural problem when the real issue is that the review skills are producing inconsistent or low-quality findings.

**Pipeline mitigations:** The document is embedded in pr-prep, which provides the full procedural context. pr-prep Step 3 includes the explicit instruction to "confirm it's real by reading the code" before fixing findings, which mitigates failure mode #2.

**Questions for the reviewer:**
- Have you encountered any of the silent failure modes described above in practice?
- Is the convergence criterion (finding count should decrease) too simplistic? Should it account for severity distribution, not just count?
- Does the brevity of the anti-patterns section (only two items) seem like a feature (focused) or a gap (incomplete)?

---

## Key Questions

1. **Does reference material need its own file, or should it be inline in pr-prep?** The current split puts the procedure in pr-prep Step 3 and the rationale in review-fix-loop.md. This is clean but adds a level of indirection. If the rationale is rarely consulted, the indirection cost may exceed the benefit of keeping pr-prep concise. If the rationale is frequently useful, the split is justified.

2. **Is the document's value primarily pedagogical or operational?** If pedagogical (teaches the user *why* iteration matters, then becomes background knowledge), it should be evaluated as a one-time learning aid. If operational (consulted during each pr-prep run when loops do not converge), it should be evaluated as active reference material. The answer affects how much ongoing maintenance and accuracy the document warrants.

3. **What evidence would validate the loop dynamics claim?** The core thesis -- that fixes reveal deeper issues masked by surface problems -- is plausible but unvalidated in this repo. A concrete example (a branch that went through 2-3 review-fix loops with documented improvement at each stage) would strengthen the document's credibility and provide a test case for the guidance.
