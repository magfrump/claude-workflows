---
Last verified: 2026-03-24
Relevant paths:
  - skills/code-fact-check.md
  - skills/code-review.md
  - test/skills/code-fact-check-eval.bats
  - test/skills/code-fact-check-format.bats
  - test/skills/code-fact-check/eval-criteria.md
  - docs/reviews/code-fact-check-report.md
---

# Self-Evaluation: code-fact-check

**Target:** `skills/code-fact-check.md` | **Type:** Skill | **Evaluated:** 2026-03-24
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Strong | Produces highly structured output (verdicts, confidence levels, evidence citations per claim). Test fixtures with deliberately wrong comments and known correct verdicts already exist in `test/skills/code-fact-check/`, making mechanical verification straightforward. |
| Trigger clarity | Adequate | The frontmatter lists clear trigger phrases ("verify the comments", "check the docs against the code", "audit documentation accuracy") and the skill is explicit about what it does and does not do. However, standalone invocation is uncommon — users rarely think "I need to fact-check my comments" unprompted. The primary trigger path is via the code-review orchestrator, where selection is automatic. |
| Overlap and redundancy | Strong | No other skill in the repo verifies documentation claims against code behavior. The prose fact-check skill (`fact-check.md`) operates on written drafts, not codebases — the analytical moves are structurally parallel but substantively distinct (searching for evidence in code vs. searching for evidence in external sources). The code critic skills (security-reviewer, performance-reviewer, api-consistency-reviewer) evaluate code quality, not documentation accuracy. |
| Test coverage | Adequate | Substantial test infrastructure exists: format tests (`code-fact-check-format.bats`), eval tests (`code-fact-check-eval.bats`), 20+ fixture files covering 8 categories, and detailed eval criteria (`eval-criteria.md`). A real-world output artifact exists at `docs/reviews/code-fact-check-report.md`. However, there is no evidence in git history that the eval harness has been run end-to-end with passing results — the infrastructure is built but execution evidence is missing. |
| Pipeline readiness | Strong | The code-review orchestrator (`skills/code-review.md`) exists and is functional. It explicitly invokes code-fact-check as Stage 1 before dispatching critic agents. All three code critic skills (security-reviewer, performance-reviewer, api-consistency-reviewer) list code-fact-check in their `requires` block and are designed to consume its output. The skill is also standalone viable — it can be invoked directly on any codebase with useful results. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the tool does:** Systematically scans code comments, docstrings, and documentation for checkable claims (behavioral, performance, architectural, invariant, configuration, reference, staleness), then reads the actual implementation to verify each claim. Produces a structured report with verdicts, confidence levels, and evidence citations.

**What generic prompting achieves:** Asking Claude "check whether the comments in these files match the code" would likely catch some obvious mismatches. However, without the skill file, the analysis would lack: (1) the systematic taxonomy of claim types that ensures nothing is skipped, (2) the calibrated verdict scale (verified/mostly accurate/stale/incorrect/unverifiable) that distinguishes degrees of wrongness, (3) the structured evidence citation format, and (4) the explicit instruction to read implementations rather than relying on function names or type signatures.

**What built-in tools cover:** Claude Code has no built-in capability specifically for verifying documentation against code. General code review would touch on this incidentally but not systematically.

**Questions for the reviewer:**
- How much of the skill's value comes from the systematic claim taxonomy vs. the structured output format? Would a simpler "check comments against code" prompt with a verdict template capture 80% of the value?
- Is the gap "catches claims you'd miss" or "ensures consistency you'd otherwise forget"? The taxonomy of 7 claim types suggests the former, but in practice, how often do the less obvious types (staleness signals, reference claims) actually surface real problems?
- Under what conditions is the gap largest? Likely: large PRs with many comment changes, codebases with extensive docstrings, or after major refactors where comments may have gone stale.

### User-Specific Fit

**Triggering situations:**
- Running a code review (via the code-review orchestrator) on PRs or branch diffs
- Auditing documentation accuracy after a refactor
- Verifying that comments in an unfamiliar codebase are trustworthy
- Pre-merge verification that changed code still matches its documentation

**Questions for the reviewer:**
- How often do you run code reviews that would benefit from automated comment verification? Is this a weekly occurrence or occasional?
- Is the frequency increasing as the codebase grows and accumulates more documentation?
- Does this serve an active goal (e.g., maintaining documentation quality, building trust in codebase comments)?
- Would you remember to invoke this standalone, or does it only realistically get used via the code-review orchestrator?

### Condition for Value

**Stated or inferred conditions:**
1. The code-review orchestrator must exist for pipeline value (Stage 1 dependency for all three critic skills).
2. The codebase being reviewed must have comments, docstrings, or documentation worth verifying.
3. For standalone value, the user must have a natural trigger to invoke it.

**Automated findings:**
- The code-review orchestrator (`skills/code-review.md`): **EXISTS** and references code-fact-check as Stage 1.
- Three critic skills that consume its output: **ALL EXIST** (security-reviewer, performance-reviewer, api-consistency-reviewer).
- Test infrastructure: **EXISTS** with fixtures and eval criteria.
- Real-world output artifact: **EXISTS** at `docs/reviews/code-fact-check-report.md`.

**Questions for the reviewer:**
- The pipeline condition is met — the orchestrator exists and the critic skills consume the output. Is the pipeline actually being used in practice, or is it infrastructure that hasn't been exercised?
- For codebases you work on, is comment density high enough that verification adds value? A codebase with sparse comments would produce thin reports.
- Is this tool an investment that justifies its maintenance cost, or could the code-review orchestrator skip it without meaningfully degrading critic quality?

### Failure Mode Gracefulness

**Output structure:** Each claim includes the exact quote, file location, claim type, verdict (5-level scale), confidence level (high/medium/low), explanatory paragraph, and evidence citations. This side-by-side structure (claim vs. evidence) makes most failures detectable on inspection — a wrong verdict is visible when the quoted claim and cited evidence don't support the stated conclusion.

**Potential silent failures:**
- **Misreading complex code paths:** The skill could trace an implementation incorrectly (e.g., missing a conditional branch) and confidently declare a claim "Verified" when it is actually stale or incorrect. This is the primary silent failure risk.
- **Incomplete search for callers/references:** For architectural claims like "only caller," the skill depends on grep-based search. If the codebase uses dynamic dispatch, string-based invocation, or cross-repo calls, the search may miss callers and falsely verify an "only caller" claim.
- **Staleness in the wrong direction:** The skill could mark a claim as "Verified" because the code currently matches, missing that both the comment and the code are wrong (the comment was written to describe intended behavior that was never implemented correctly).

**Pipeline mitigations:** When used via the code-review orchestrator, the critic skills (security-reviewer, performance-reviewer) perform their own code analysis. If code-fact-check misreads an implementation, a critic skill reading the same code may notice the discrepancy. However, the critics are explicitly told to trust the fact-check report and not re-verify, which reduces this mitigation.

**Questions for the reviewer:**
- Have you observed any silent failures in practice — cases where code-fact-check marked something "Verified" that was actually wrong?
- The instruction for critics to trust the fact-check report creates a single-point-of-failure risk. Is this tradeoff (efficiency vs. redundancy) acceptable?
- For the codebases you review, how common are the hard cases (dynamic dispatch, cross-repo calls, complex concurrency) that resist static analysis?

---

## Key Questions

1. **Pipeline utilization vs. existence:** The code-review orchestrator and all three critic skills exist and reference code-fact-check. But is the pipeline being used in real code reviews, or is it built infrastructure awaiting adoption? The answer determines whether the "Strong" pipeline readiness score translates to actual value delivery.

2. **Trust propagation risk:** Critics are told to trust the fact-check report and not re-verify. This is efficient but creates a single point of failure. If code-fact-check misreads an implementation, all downstream critics inherit that error. Is this an acceptable tradeoff, or should critics be instructed to independently verify claims that are central to their analysis?

3. **Test execution gap:** Extensive test infrastructure exists (fixtures, format tests, eval tests, eval criteria) but there is no evidence of end-to-end test execution with results. Running the eval harness against a current model would close this gap and either validate the skill or surface behavioral issues worth fixing.
