# Self-Evaluation: pr-prep

**Target:** `workflows/pr-prep.md` | **Type:** Workflow | **Evaluated:** 2026-03-24
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | As a multi-step process workflow, testing requires evaluating process adherence and artifact quality (PR descriptions, commit histories, review loops) rather than structured output. No mechanical check can assess whether a PR was "well-prepared" — this requires human judgment on the resulting PR and review cycle. |
| Trigger clarity | Strong | Trigger is unambiguous: "before opening any pull request." Every developer knows when they're about to open a PR. No overlap with other workflows — RPI feeds into pr-prep, and review-fix-loop is explicitly subordinate to it (Step 3 reference material). |
| Overlap and redundancy | Strong | No substantive overlap with other workflows. review-fix-loop.md is explicitly scoped as reference material for pr-prep Step 3, not a competing workflow. The workflow occupies a unique position as the final gate before code leaves the developer — upstream workflows (RPI, spike, DD) feed into it, and no other workflow covers PR packaging. |
| Test coverage | Weak | No test files in `test/` reference pr-prep. No example output artifacts (e.g., a model PR description) exist in `docs/reviews/`. Git history shows real usage (7 commits mentioning pr-prep, including tier annotations and review-fix loop integration), but no structured evidence of effectiveness. |
| Pipeline readiness | Strong | Standalone viable and well-integrated into the workflow ecosystem. RPI explicitly directs users to pr-prep after implementation. pr-prep itself composes skills (`/code-review`, `/self-eval`) in Step 3. review-fix-loop.md exists as supporting reference. The workflow functions both as a standalone checklist and as the natural terminal step in the RPI pipeline. |

---

## Flagged for Human Review

### Counterfactual Gap

- **What the workflow does**: Defines a 6-step process for preparing PRs: clean commit history, verify CI, run a review-fix loop (code review + self-eval → fix → retest → re-review), write a structured PR description, annotate the diff, and check PR size. Includes tier annotations (essential/recommended/advanced) and a post-PR reflection appendix.
- **What ad-hoc process achieves**: Without this workflow, a developer would likely push code, write a brief PR description, and hope for the best. The review-fix loop (Step 3) would almost certainly be skipped — self-reviewing with structured tools before requesting external review is not a natural behavior. The tiered approach and reflection appendix would also be absent.
- **What built-in tools cover**: Claude Code's built-in capabilities can create commits and open PRs, but they don't enforce a preparation process or self-review loop.
- **Questions for the reviewer**:
  - How much of the value comes from the review-fix loop (Step 3) vs. the other steps? Would you follow the essential steps without the workflow doc?
  - Is the gap "the workflow adds steps I wouldn't think of" or "the workflow ensures I don't skip steps I know I should do"?
  - How much has the tiered annotation system changed your behavior — do you actually use the tiers to calibrate effort?

### User-Specific Fit

- **Triggering situations**: Every time you open a PR, with tier-based scoping for effort level.
- **Questions for the reviewer**:
  - How often do you open PRs? Is this frequency increasing or decreasing?
  - Do you follow the full workflow, or do you typically skip to essential steps?
  - Has the review-fix loop (the advanced step) caught real issues that would have reached the reviewer?
  - Does the async-timezone motivation (mentioned in "When to use") match your actual review setup?

### Condition for Value

- **Stated or inferred conditions**: (1) The user opens PRs regularly. (2) The `/code-review` and `/self-eval` skills exist and function for the review-fix loop to work. (3) The user benefits from structured self-review before external review.
- **Automated findings**: The `/code-review` skill EXISTS (`skills/code-review.md`). The `/self-eval` skill EXISTS (`skills/self-eval.md`). The `review-fix-loop.md` reference doc EXISTS. RPI workflow references pr-prep as the terminal step — the pipeline is connected.
- **Questions for the reviewer**:
  - Are all conditions met today? Specifically, does `/code-review` produce useful findings in practice?
  - Is the review-fix loop (advanced tier) something you actually run, or is it aspirational?
  - If you only use the essential steps, is the workflow still earning its place vs. a mental checklist?

### Failure Mode Gracefulness

- **Output structure**: The workflow produces PR artifacts (commit history, PR description, review artifacts). Failures would manifest as: poorly structured PRs that still pass the checklist mechanically, review-fix loops that don't converge, or skipped steps that the workflow didn't prevent.
- **Potential silent failures**: The biggest risk is "checklist compliance without substance" — going through the motions of the review-fix loop without actually improving the PR. A developer could run `/code-review`, see findings, make superficial fixes, and declare convergence. The workflow's convergence check ("each loop should be strictly smaller") mitigates this somewhat.
- **Pipeline mitigations**: The review-fix loop has a built-in escape hatch: "if findings aren't converging after 3-4 loops, the problem is architectural." The tier system allows graceful degradation — essential steps are minimal, advanced steps are opt-in.
- **Questions for the reviewer**:
  - Have you experienced the review-fix loop not converging? What happened?
  - Have you seen cases where following the workflow produced a PR that still needed significant reviewer feedback?
  - Is the tier system working as intended — do you actually calibrate effort based on tiers?

---

## Key Questions

1. **Is the review-fix loop (Step 3) the workflow's core value proposition?** If so, does it work well enough in practice to justify the workflow's existence, or would the essential steps alone (verify CI, write PR description) be sufficient without a dedicated workflow?

2. **Does the tier system change behavior?** The essential/recommended/advanced annotations are a distinctive feature. If users naturally calibrate effort without them, the tiers add complexity without value. If users tend to either skip everything or do everything, the tiers may not be hitting the middle ground they target.

3. **Is there a feedback loop on effectiveness?** The post-PR reflection appendix (plan accuracy, skipped steps, time vs. estimate) is designed to improve future usage, but there's no evidence of reflection artifacts in the repo. Is this step actually being used?
