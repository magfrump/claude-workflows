# Self-Evaluation: pr-prep

**Target:** `workflows/pr-prep.md` | **Type:** Workflow | **Evaluated:** 2026-03-27
**Evaluator:** Automated (self-eval skill) -- human review required for flagged dimensions
**Scope:** Re-evaluation focused on the Retrospective section change (PR #20, branch feat/r1-retrospective-appendix)

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | pr-prep is a multi-step process workflow. Its quality is measured by process outcomes (clean commits, passing CI, good PR descriptions, converging review loops), not structured output. The Retrospective section is even harder to test -- its value depends on whether reflections are genuine and compound over time, which is inherently unmeasurable by automation. |
| Trigger clarity | Strong | Trigger remains unambiguous: "before opening any pull request." The Retrospective section's trigger is equally clear: "after the PR is opened." No overlap with other workflows -- RPI feeds into pr-prep, review-fix-loop is embedded within it. The rename from "Appendix: Post-PR Reflection" to "Retrospective" is a minor clarity improvement, promoting it from appendix status to a peer section. |
| Overlap and redundancy | Strong | No substantive overlap with other workflows. The Retrospective section's four questions (plan vs. reality, skipped steps, surprises, next time) are specific to the pr-prep context and don't duplicate content elsewhere. The main-branch version previously delegated to `guides/post-pr-retrospective.md`; this PR inlines the content, which eliminates a level of indirection but does not create overlap. |
| Test coverage | Weak | No automated tests reference pr-prep. No example output artifacts exist showing the workflow followed end-to-end. Git history shows active development (13+ commits mentioning pr-prep), and the workflow has clearly been used in practice (review-fix loop artifacts exist in `docs/reviews/`), but no formal documentation of end-to-end usage or retrospective outputs exist. |
| Pipeline readiness | Strong | Standalone viable and well-integrated. pr-prep is a top-level workflow invoked directly by the user. It composes `/code-review` and `/self-eval` in its review-fix loop, both of which exist. RPI explicitly references pr-prep as its downstream step. The Retrospective section is self-contained and requires no additional tooling. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does**: pr-prep is a 6-step checklist plus a retrospective for packaging work before opening a PR. The Retrospective section (the focus of this PR) asks four structured questions: plan vs. reality, skipped steps, surprises, and next time. It directs answers to `docs/thoughts/` or commit messages.

**What ad-hoc process achieves**: Without the Retrospective section, a developer finishes the PR and moves on. The specific questions this section asks -- particularly "surprises" (what was unexpected) and "plan vs. reality" (how the plan held up) -- are reflections most developers skip unless prompted. The previous version asked about "time vs. estimate," which is a more conventional retrospective question; replacing it with "surprises" is a more distinctive analytical move that targets learning rather than estimation calibration.

**What built-in tools cover**: No built-in Claude Code capability covers post-PR reflection.

**Questions for the reviewer**:
- The key change is replacing "time vs. estimate" with "surprises." Does this match your actual learning loop better? Estimation calibration has value, but it's a narrower lens than "what was unexpected."
- How much of the Retrospective's value comes from the specific questions vs. the mere act of having a prompt to reflect? Would any four reasonable questions work equally well?
- The previous main-branch version delegated to a separate guide (`guides/post-pr-retrospective.md`). This PR inlines the content. Does the indirection serve a purpose (e.g., the guide had additional context), or is inlining the right call?

### User-Specific Fit

**Triggering situations**: After every PR is opened. The Retrospective section specifically targets the post-PR moment when implementation context is freshest.

**Questions for the reviewer**:
- Do you actually complete the retrospective step after opening PRs? If so, how often -- every PR, or only complex ones?
- Has the "time vs. estimate" question (being removed) ever produced useful signal? Would you miss it?
- Do the answers end up in `docs/thoughts/` or commit messages in practice, or somewhere else (or nowhere)?
- Is the 2-minute framing realistic? Does a genuine retrospective take longer?

### Condition for Value

**Stated or inferred conditions**:
- The user must open PRs with some regularity -- likely met given active development.
- The user must actually pause to answer the questions rather than skipping the section -- this is the critical condition and the hardest to verify.
- The answers must be stored somewhere retrievable (`docs/thoughts/` or commit messages) to compound over time -- **partially met** (the infrastructure exists, but no evidence of retrospective artifacts in `docs/thoughts/`).

**Automated findings**:
- No files in `docs/thoughts/` appear to contain retrospective content (searched for plan-vs-reality, skipped-steps, surprises patterns).
- The `guides/post-pr-retrospective.md` referenced on main does not exist on the branch, suggesting it was either never created or was removed as part of this change.

**Questions for the reviewer**:
- Is the condition "user actually reflects" currently met? If not, what would make it more likely -- automation, integration into the commit flow, a lighter format?
- Is inlining the questions (vs. delegating to a guide) more likely to result in the step being followed, because there's less friction?
- Should the retrospective have a more concrete output artifact (e.g., a structured file) rather than the open-ended "docs/thoughts/ or a commit message"?

### Failure Mode Gracefulness

**Output structure**: The Retrospective section produces unstructured prose (in `docs/thoughts/` or commit messages). There is no template, no required fields, and no mechanical check for completeness.

**Potential silent failures**:
- **Perfunctory answers**: The most likely failure mode. The questions get answered with "everything went as planned" or single-word responses that provide no learning signal. This is undetectable by automation.
- **Skipped entirely**: The section is the last step and has no enforcement mechanism. Post-PR energy is low. This is detectable (no artifact) but only if someone checks.
- **Wrong storage location**: Answers scattered across commit messages, PR descriptions, and docs/thoughts/ with no consistency, making the "compound over time" benefit unrealizable.

**Pipeline mitigations**: None. The Retrospective section is purely self-directed. No downstream skill consumes its output or validates its quality.

**Questions for the reviewer**:
- Have you observed the perfunctory-answer failure mode in practice?
- Would a more structured output format (e.g., a template file) help, or would it add friction that makes the step less likely to be done at all?
- Is the lack of enforcement acceptable (retrospectives should be intrinsically motivated) or a design gap?

---

## Key Questions

1. **Does "surprises" earn its place over "time vs. estimate"?** The most substantive change in this PR is swapping an estimation-calibration question for an unexpected-events question. "Surprises" targets learning and anticipation; "time vs. estimate" targets planning accuracy. Which produces more actionable insights in the user's actual workflow?

2. **Does inlining vs. delegating matter for follow-through?** The main branch delegates to a separate guide; this PR inlines the content. The inlined version is shorter and lower-friction, but loses any extended context the guide might have provided. The guide file appears not to exist on this branch, so the practical question is: does having the questions visible in pr-prep.md itself make it more likely they get answered?

3. **Is the Retrospective section's value measurable at all?** With no structured output, no consuming pipeline, and no enforcement, the section's value depends entirely on human discipline. This is fine if the questions are genuinely useful prompts, but it means the section can never move past "Weak" on test coverage. Is that an acceptable tradeoff, or should the design be revisited to produce checkable artifacts?
