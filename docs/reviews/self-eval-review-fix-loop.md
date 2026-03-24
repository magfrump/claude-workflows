# Self-Evaluation: review-fix-loop

**Target:** `workflows/review-fix-loop.md` | **Type:** Workflow | **Evaluated:** 2026-03-24
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | As a multi-step iterative process, the workflow's value lies in convergence dynamics across loops -- testing whether "findings decrease over iterations" requires running full review skills multiple times on real code. There is no structured output to validate mechanically; the artifacts are the review skills' outputs, not the workflow's own. |
| Trigger clarity | Strong | The "When to use" section specifies a concrete, unambiguous situation: after a feature branch is complete and before merge, when review artifacts exist or should be generated. This is clearly distinct from RPI (building the feature), pr-prep (packaging for async review), and spike (feasibility exploration). The sequencing is intuitive: RPI then review-fix-loop then pr-prep. |
| Overlap and redundancy | Adequate | There is meaningful overlap with pr-prep's "Self-review" step (Step 2), which also involves running critic skills against the branch and fixing issues. However, review-fix-loop is a dedicated iterative loop with triage tiers and convergence tracking, while pr-prep treats self-review as one step in a larger packaging process. The overlap is in triggering situation rather than substance -- pr-prep is about preparing presentation for a reviewer, while review-fix-loop is about driving quality through iteration. The boundary could be clearer. |
| Test coverage | Weak | No test files reference this workflow. No example output artifacts exist. Only one git commit mentions the workflow (the commit that added it). No evidence of real-world usage beyond the creation commit. The workflow is in a probationary state. |
| Pipeline readiness | Strong | Fully standalone viable. The workflow composes existing review skills (code-review, self-eval, fact-check) but does not depend on any pipeline to function. It can be followed with any subset of available review skills. It also naturally chains with RPI (upstream) and pr-prep (downstream), forming a clear three-stage progression for feature development. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does:** Defines an iterative loop for running review skills against a feature branch, triaging findings into severity tiers, fixing them in tier order, running tests, and re-running reviews until findings converge. The key structural contributions are: the triage tier system (Must Fix / Must Address / Consider), the explicit convergence criterion (finding count should strictly decrease), the anti-patterns section, and the guidance to verify review findings against actual code before fixing.

**What ad-hoc process achieves:** Without this workflow, someone would run a code review, fix the obvious issues, maybe run the review again. The ad-hoc version would likely miss: (1) the systematic triage by severity tier that prevents wasting effort on style issues before correctness bugs are fixed, (2) the explicit convergence check that tells you when to stop or when to escalate to a different workflow, (3) the guidance to verify findings before fixing (reviews hallucinate), and (4) the insight that fixes reveal deeper issues that earlier reviews missed because surface problems masked them.

**What built-in tools cover:** No built-in Claude Code capability covers iterative review loops. Built-in review tools are single-pass.

**Questions for the reviewer:**
- How much of the workflow's value comes from the triage tier discipline vs. the iteration structure vs. the anti-patterns guidance?
- When you have used review-fix loops informally, did you naturally triage by severity, or did you tend to fix issues in the order you encountered them?
- Is the "reviews get more useful as the code gets cleaner" insight genuinely non-obvious, or would you have done this anyway?

### User-Specific Fit

**Triggering situations:**
- Completing a feature branch and wanting to harden it before merge
- Having generated review artifacts that revealed issues worth systematically addressing
- Wanting to go from "works" to "passes review" with structured iteration

**Questions for the reviewer:**
- How often do you complete a feature branch and then do a structured quality-improvement pass before merge? Is this a regular step or something you do only for high-stakes changes?
- When you do review-fix iterations, do you typically do 1 pass or 2-3? The workflow assumes 2-3 is typical -- does that match your experience?
- Is this workflow something you would reach for proactively, or would it mainly be useful when prompted by an agent that notices the pattern?
- Note: this workflow is not listed in the CLAUDE.md workflow index (unlike RPI, divergent-design, spike, pr-prep, etc.). Is that an oversight or a signal about its current integration level?

### Condition for Value

**Stated or inferred conditions:**
1. Review skills (code-review, self-eval, fact-check) must exist and work well enough to produce actionable findings.
2. The user must have a pattern of iterating on quality after initial implementation, not just shipping the first working version.
3. The feature branch must be large enough that a single review pass is insufficient -- trivial changes don't need an iterative loop.

**Automated findings:**
- code-review skill: EXISTS (skills/code-review.md)
- self-eval skill: EXISTS (skills/self-eval.md)
- fact-check skill: EXISTS (skills/fact-check.md)
- BATS test infrastructure: EXISTS (test/skills/)
- Workflow is NOT referenced in CLAUDE.md global instructions (unlike 7 of the 8 other workflows)
- No evidence of real-world usage in git history

**Questions for the reviewer:**
- Are conditions 1-3 all met today? Specifically, do the review skills produce findings actionable enough to drive a multi-iteration loop?
- The workflow being absent from CLAUDE.md means agents won't discover it unless explicitly directed. Is this intentional (the workflow is too new / untested) or an oversight worth fixing?
- Does the workflow justify itself for your typical branch sizes, or is it mainly valuable for large multi-file features?

### Failure Mode Gracefulness

**Output structure:** The workflow does not produce its own artifacts -- it operates on review artifacts produced by the skills it invokes. The commit history serves as the audit trail. This means failure detection depends on the quality of the underlying review skills.

**Potential silent failures:**
1. **False convergence:** Reviews stop finding issues not because the code is clean, but because the review skills have blind spots. The workflow's convergence criterion (finding count decreases) would signal "done" even though real issues remain undetected.
2. **Hallucinated findings leading to unnecessary changes:** The workflow warns about this ("reviews can hallucinate") and tells users to verify findings, but if the user trusts the workflow's structure too much, they might skip verification and make changes that degrade the code.
3. **Tier misjudgment:** The triage step requires judgment about which tier a finding belongs in. A Must Fix classified as Consider could be deferred inappropriately.
4. **Thrashing without convergence:** The workflow warns about this (anti-pattern: >3-4 loops) but doesn't provide a mechanical check. A user could keep iterating without noticing that findings aren't converging.

**Pipeline mitigations:** The workflow composes review skills that have their own failure mitigation (e.g., code-review's fact-check gate, structured rubrics with severity levels). The multi-skill approach provides some cross-validation.

**Questions for the reviewer:**
- Which failure mode concerns you most: false convergence (stopping too early) or thrashing (not stopping)?
- Have you observed cases where review skills hallucinate findings that led to unnecessary or harmful code changes?
- Is the "verify findings against actual code" step realistic in practice, or does it add too much friction to follow consistently?

---

## Key Questions

1. **Is this workflow distinct enough from pr-prep to justify separate existence?** Both involve running review skills against a branch and fixing issues. The review-fix-loop adds iteration structure and triage tiers; pr-prep adds commit cleanup, PR description, and reviewer-facing packaging. Could pr-prep's self-review step simply reference review-fix-loop as a sub-procedure, or would that over-complicate pr-prep?

2. **Should this workflow be added to the CLAUDE.md index?** It is currently the only workflow not listed there. If it is ready for use, the omission means agents will never suggest it. If it is not ready, what would make it ready -- a successful real-world use, or something else?

3. **Does the iterative structure provide enough value over "run code-review, fix the findings, done"?** The workflow's core thesis is that single-pass review is insufficient because fixes reveal deeper issues. This is plausible but unvalidated -- has this actually been the experience with the existing review skills?
