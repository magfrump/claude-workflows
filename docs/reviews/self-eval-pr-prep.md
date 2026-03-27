# Self-Evaluation: pr-prep

**Target:** `workflows/pr-prep.md` (as refined by PR #23) | **Type:** Workflow | **Evaluated:** 2026-03-27
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | pr-prep is a multi-step process workflow whose outputs are a cleaned commit history, review artifacts, a PR description, and a retrospective note. None of these have mechanically checkable correctness criteria — quality assessment requires human judgment about whether the commit structure is logical, the PR description is useful, and the retrospective is insightful. Constructing a meaningful test would require a realistic branch with planted deficiencies, plus a rubric for evaluating the outputs. |
| Trigger clarity | Strong | The trigger is maximally clear: "Before opening any pull request." Every developer knows when this moment arrives. No other workflow in the repo competes for this trigger — RPI covers implementation, divergent-design covers decisions, spike covers feasibility, and pr-prep covers the final packaging. CLAUDE.md's index reinforces this with an accurate one-line summary. |
| Overlap and redundancy | Strong | pr-prep occupies a unique niche: post-implementation, pre-review packaging. The review-fix loop (Step 3) delegates to the code-review and self-eval skills rather than reimplementing their logic. The retrospective appendix (refined in this PR to inline the questions rather than point to `guides/post-pr-retrospective.md`) connects back to RPI artifacts without duplicating RPI itself. review-fix-loop.md is explicitly positioned as reference material, not a competing workflow. No other workflow or skill covers commit cleanup, PR description structure, diff annotation, or size checking. |
| Test coverage | Weak | No automated tests reference pr-prep in the `test/` directory. Git history shows 13+ commits mentioning pr-prep, indicating substantial real-world iteration and refinement. Review artifacts for the review-fix-loop sub-step exist (`self-eval-review-fix-loop.md`, `code-review-review-fix-loop.md`), and code-review artifacts from pr-prep runs exist in `docs/reviews/`. However, no formal test cases or example "gold standard" PR descriptions are documented. Probationary state per rubric. |
| Pipeline readiness | Strong | Fully standalone viable as a top-level workflow. It also functions as a pipeline endpoint: RPI step 6 explicitly says "proceed to the pr-prep workflow if opening a PR." It composes two skills (code-review, self-eval) in Step 3, both of which exist and are functional. It references review-fix-loop.md as companion material. The post-PR retrospective appendix (now inlined) references RPI plan artifacts and review findings, closing the feedback loop across workflows. No missing infrastructure. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does:** Defines a 6-step process for PR preparation — commit cleanup, local CI, iterative review-fix loop (code-review + self-eval, triage by tier, fix, retest, re-review until converged), PR description writing with structured sections, diff annotation for unfamiliar libraries, and size checking. The PR #23 refinements sharpen the self-eval instruction (run once per target file), add specificity to the re-review step (diff artifacts against prior round), thread surprising findings from the loop exit into the retrospective, and inline the retrospective questions rather than pointing to a separate guide.

**What ad-hoc process achieves:** Without this workflow, a developer would push code and write a freeform PR description. Some would run CI locally; few would systematically iterate on code review findings, write "areas of uncertainty" sections, annotate their own diff, or compare actual effort against plan estimates. The review-fix loop orchestration (Step 3) and the retrospective (Appendix) are the two components least likely to emerge from ad-hoc behavior.

**What built-in tools cover:** GitHub's PR templates provide description structure. Built-in Claude Code capabilities do not cover iterative review-fix orchestration or retrospective integration with RPI plan artifacts.

**Questions for the reviewer:**
- The PR #23 change inlines the retrospective questions that previously lived in `guides/post-pr-retrospective.md`. Does having them directly in pr-prep.md increase the likelihood you actually answer them, or was the indirection not the real barrier?
- How much of the workflow's value comes from Step 3 (review-fix loop) vs. the surrounding steps? If you dropped Steps 1, 4, 5, and 6 but kept Step 3 and the retrospective, would the outcome be materially worse?
- Is the gap between "follow pr-prep" and "wing it" largest for this meta-repo (skills/workflows), or for application codebases with more testable behavior?

### User-Specific Fit

**Triggering situations:**
- Before opening any PR — the workflow is designed for universal application
- Especially when the reviewer is in a different timezone or unfamiliar with the libraries used
- After completing an RPI implementation loop (RPI step 6 points here explicitly)

**Questions for the reviewer:**
- How frequently do you open PRs? The branch-strategy workflow implies high throughput (10+ features/day). Does pr-prep's ceremony scale to that volume, or do you abbreviate for small PRs?
- The refined retrospective now asks 4 specific questions. Are you actually answering them, or do they feel like homework? Has a retrospective answer ever changed your next plan?
- The "skipped steps" question that was in `post-pr-retrospective.md` is no longer present in the inlined version (the 4 questions cover plan accuracy, review-loop lessons, estimate calibration, and what to change). Was that question valuable, or is its removal an improvement?

### Condition for Value

**Stated or inferred conditions:**
1. The user opens PRs as part of their workflow.
2. The `/code-review` and `/self-eval` skills exist and function for Step 3.
3. RPI plan artifacts exist in `docs/working/` for the retrospective to reference.
4. The user has reviewers who benefit from structured PR descriptions and annotations.
5. The user returns to retrospective answers when planning future tasks (otherwise the retrospective is write-only).

**Automated findings:**
- `/code-review` skill: EXISTS (`skills/code-review.md`)
- `/self-eval` skill: EXISTS (`skills/self-eval.md`)
- `review-fix-loop.md` companion doc: EXISTS (`workflows/review-fix-loop.md`)
- RPI workflow: EXISTS (`workflows/research-plan-implement.md`)
- `guides/post-pr-retrospective.md`: EXISTS (the standalone guide that pr-prep's appendix now supersedes for the inline case)
- Example review artifacts: EXIST in `docs/reviews/` (code-review rubrics, self-eval reports)
- All infrastructure dependencies are met.

**Questions for the reviewer:**
- Condition 5 is the weakest link. Do you read previous retrospectives when starting a new RPI research phase? If not, the retrospective's compounding value is theoretical.
- Is the retrospective's value conditional on project maturity? Early in a project, plans are often wrong for novel reasons; the retrospective may not help calibrate. Later, when patterns repeat, calibration becomes more valuable.
- The PR #23 change inlines the retrospective content into pr-prep rather than pointing to a separate guide. This means the guide (`post-pr-retrospective.md`) and the appendix now have overlapping content. Is the guide still needed, or should it be deprecated?

### Failure Mode Gracefulness

**Output structure:** The workflow produces multiple independent artifacts: a cleaned commit history, passing CI, review artifacts (from the loop), a structured PR description, and a retrospective note. Each is inspectable on its own. The review-fix loop produces `docs/reviews/` artifacts with structured findings, making issues detectable.

**Potential silent failures:**
1. **Review-fix loop false convergence.** The loop could converge on "no findings" because the review skills have blind spots, not because the code is clean. The PR #23 refinement to "diff the new review artifacts against the prior round" makes this slightly more detectable (you'd notice the same artifact structure with fewer findings), but the fundamental risk remains.
2. **Retrospective as ritual.** The inlined 4 questions could become a rote exercise — answers are written but never read. The compounding value ("they compound over time and calibrate future planning") depends entirely on a feedback loop that the workflow does not enforce.
3. **Commit cleanup data loss.** Step 1 uses `git rebase -i`, which can drop commits if done carelessly. No safeguard is mentioned (e.g., "create a backup branch before rebasing").
4. **Self-eval scope creep.** The refined instruction "run once per target file" in Step 3a could lead to many self-eval runs on a large PR, each generating a report. Whether all those reports get triaged in Step 3b is unclear.

**Pipeline mitigations:** Human PR review downstream provides a final check on missed issues. The retrospective's "review-loop lessons" question (question 2) could surface false convergence if the reviewer finds issues the loop missed. The rebase risk is mitigated by git's reflog (recoverable, but not mentioned in the workflow).

**Questions for the reviewer:**
- Have you experienced review-fix loop false convergence in practice? Did the human reviewer catch what the loop missed?
- Has the rebase step ever caused data loss? Would a "create a safety branch" instruction be helpful or unnecessary ceremony?
- For the self-eval scope: on a PR touching 3-4 workflow/skill files, did running self-eval on each feel proportionate, or did it generate more artifacts than you could meaningfully triage?

---

## Key Questions

1. **Does inlining the retrospective questions increase completion rates?** The main change in PR #23 moves from a pointer (`guides/post-pr-retrospective.md`) to inline content. The hypothesis is that reducing indirection increases the likelihood of reflection. But the standalone guide offers additional context (timing guidance, multiple checkpoints, the "skipped steps" question). Is the tradeoff worth it, and should the standalone guide be deprecated or kept as extended reference?

2. **Is the retrospective's compounding value realized in practice?** The retrospective appendix is pr-prep's most distinctive feature compared to a standard PR checklist. Its value depends on a feedback loop: write retrospective answers, read them when planning the next task, adjust behavior. If that loop isn't closing, the retrospective is overhead. What evidence exists that retrospective answers have influenced subsequent plans?

3. **Does the refined self-eval instruction ("run once per target file") create proportionate work?** For PRs that touch many skill/workflow files, this could generate a large number of self-eval reports. The review-fix loop's triage step (3b) assumes a manageable number of findings to work through. Is there a natural ceiling on how many self-eval targets are practical per PR, and should the workflow say so?
