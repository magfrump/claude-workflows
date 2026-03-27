# Self-Evaluation: pr-prep

**Target:** `workflows/pr-prep.md` | **Type:** Workflow | **Evaluated:** 2026-03-24
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | As a multi-step process workflow, pr-prep's value lies in process adherence (commit cleanup, review loops, PR description quality) — none of which produce mechanically checkable output. Testing would require subjective assessment of whether the PR description is "good enough" or whether the commit history is "logical," which demands domain expertise. |
| Trigger clarity | Strong | The trigger is unambiguous: "before opening any pull request." Every developer knows when they're about to open a PR. The workflow doesn't overlap with any other workflow's trigger — RPI ends at implementation, and pr-prep begins where RPI leaves off. |
| Overlap and redundancy | Adequate | The review-fix loop (Step 3) is explicitly extracted into `workflows/review-fix-loop.md`, but that document declares itself reference material for pr-prep, not a standalone workflow — so this is deliberate decomposition, not redundancy. There is some overlap with the built-in verification-coordinator agent (both care about test coverage), but pr-prep is much broader. The PR description template overlaps with `gh pr create` conventions but adds structure (uncertainty, decisions) that generic templates lack. |
| Test coverage | Weak | No automated tests exist in `test/`. No example output artifacts demonstrate a completed pr-prep run. Git history shows commits developing and refining pr-prep (review-fix loop integration, retrospective appendix, completion signals), indicating iterative design — but no documented usage on a real PR with before/after evidence. |
| Pipeline readiness | Strong | Standalone viable — pr-prep is a top-level workflow invoked directly by the user, not a pipeline stage. It composes existing skills (`/code-review`, `/self-eval`) in its review-fix loop, and those skills exist and function. It also references `workflows/review-fix-loop.md` as supporting material. All dependencies are present. |

---

## Flagged for Human Review

### Counterfactual Gap

- **What the workflow does**: Sequences six steps for PR preparation: commit cleanup, local CI, a review-fix loop (using code-review and self-eval skills), PR description writing, diff annotation, and size checking. Includes completion signals for each phase and a post-PR retrospective appendix.
- **What ad-hoc process achieves**: Without the workflow, a developer would likely: push code, write a brief PR description, maybe squash commits. They'd skip the review-fix loop entirely, write a thinner PR description (no "areas of uncertainty" or "decisions made" sections), and not do a size check or self-annotation pass. The retrospective step would almost certainly be skipped.
- **What built-in tools cover**: The built-in verification-coordinator covers test verification but not commit cleanup, PR description, or iterative review loops. `gh pr create` provides a PR template but not the structured sections or the pre-submission review process.
- **Questions for the reviewer**:
  - How much of the workflow's value comes from the review-fix loop (which orchestrates existing skills) vs. the surrounding ceremony (commit cleanup, PR description, size check)?
  - Is the gap "pr-prep adds steps you'd forget" or "pr-prep raises the quality floor of steps you'd do anyway"?
  - Under what conditions is the gap largest — solo work? Cross-timezone review? Unfamiliar codebases?

### User-Specific Fit

- **Triggering situations**: Before opening any pull request, especially cross-timezone or when using unfamiliar libraries.
- **Questions for the reviewer**:
  - How often do you open PRs? Is this a daily, weekly, or less frequent activity?
  - Do you currently follow a pre-PR checklist, or is pr-prep formalizing something you already do informally?
  - Is the full 6-step process appropriate for your typical PR size, or do you find yourself skipping steps for small changes?
  - Would you actually remember to invoke this workflow, or does it need a hook/reminder?

### Condition for Value

- **Stated or inferred conditions**: (1) The user opens PRs regularly. (2) The code-review and self-eval skills exist and work. (3) The user values structured self-review before human review.
- **Automated findings**:
  - `/code-review` skill: EXISTS (`skills/code-review.md`)
  - `/self-eval` skill: EXISTS (`skills/self-eval.md`)
  - `workflows/review-fix-loop.md` supporting material: EXISTS
  - Completion signals in workflow phases: PRESENT (added in commit 18aaa70)
- **Questions for the reviewer**:
  - Are the conditions met today? Specifically, do you trust the code-review and self-eval skills enough to make the review-fix loop worthwhile?
  - If the review skills produce noisy or unreliable output, does the loop amplify that noise (re-reviewing bad reviews) or still add value through the fix-and-retest cycle?
  - Is the retrospective appendix something you've actually used, or is it aspirational?

### Failure Mode Gracefulness

- **Output structure**: The workflow doesn't produce a single output artifact — it produces a trail of commits, review artifacts in `docs/reviews/`, and a PR description. Failures manifest as process breakdowns rather than bad documents.
- **Potential silent failures**:
  - The review-fix loop converges on "no findings" not because the code is good, but because the review skills have blind spots. The user trusts the clean review and skips manual inspection.
  - Commit cleanup (interactive rebase) could silently drop changes if done carelessly — the workflow trusts the user to do this correctly.
  - The PR description template could be filled in perfunctorily ("What this does: implements the feature") — the workflow has no quality gate on description content.
  - The size check threshold (~500 lines) is advisory with no enforcement mechanism.
- **Pipeline mitigations**: The review-fix loop uses multiple review skills in parallel (code-review, self-eval), which provides some cross-validation. The test re-run step catches regressions that reviews miss. But no mitigation exists for perfunctory PR descriptions or false convergence in reviews.
- **Questions for the reviewer**:
  - Have you observed the review-fix loop converging prematurely (declaring "clean" when issues remain)?
  - Is the commit cleanup step a net positive, or does it introduce risk of lost work?
  - Which failure mode concerns you most: false confidence from clean reviews, or perfunctory PR descriptions?

---

## Key Questions

1. **Is the review-fix loop the load-bearing step?** If the code-review and self-eval skills were removed, would the remaining steps (commit cleanup, CI, PR description, size check) still justify a dedicated workflow — or would they be a simple checklist that doesn't need workflow machinery?

2. **Does the retrospective appendix get used?** The post-PR reflection is a valuable feedback mechanism in theory, but it requires discipline to complete after the PR is already open. Is this actually happening, or is it dead weight that should be removed or made more lightweight?

3. **Should pr-prep scale to PR size?** The workflow applies the same 6-step process to a 20-line bugfix and a 500-line feature. Would a "light" vs. "full" mode improve adoption, or does the overhead of deciding which mode to use outweigh the time saved?
