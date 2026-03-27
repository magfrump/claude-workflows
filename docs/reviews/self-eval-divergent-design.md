# Self-Evaluation: divergent-design

**Target:** `workflows/divergent-design.md` | **Type:** Workflow | **Evaluated:** 2026-03-27
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | Evaluating whether a DD session produced a better decision than ad-hoc requires counterfactual comparison, which is inherently subjective. Structural properties (candidate count, stress-test move application, matrix completeness, sub-threshold routing correctness) can be checked mechanically, but the core value -- did diverging actually surface a better option? -- cannot be tested without domain expertise. |
| Trigger clarity | Strong | Triggers are specific and well-differentiated: "architectural decisions," "library or tool selection," "any decision where premature convergence is a risk." The "When to pivot" section clearly defines handoff boundaries with RPI, spike, and onboarding. The new sub-threshold paragraph further sharpens the boundary by routing trivial decisions to `docs/decisions/log.md` instead of full DD. No confusing overlap with other workflows. |
| Overlap and redundancy | Strong | No other workflow or built-in tool covers the full diverge-diagnose-match-decide structure. Matrix-analysis overlaps on the evaluation/comparison phase but does not include the diverge phase (generating 8-15 candidates including deliberately unconventional ones) or the diagnose phase (constraint specification). The overlap is in a sub-step, not the core value proposition. |
| Test coverage | Weak | No automated tests exist in `test/` for divergent-design. The workflow has been used in practice -- `docs/decisions/` contains decision records, and git history shows multiple commits referencing DD -- but there are no example output artifacts or formal test cases. The only test reference is in `test/hooks/log-usage.bats`, which tests the usage-logging hook, not DD itself. |
| Pipeline readiness | Strong | Standalone viable for any design decision. Also functions as a sub-procedure within RPI (explicitly documented with bidirectional pivot guidance). Can trigger spikes for feasibility validation. The new sub-threshold paragraph adds a downstream connection to `docs/decisions/log.md`, further integrating DD into the decision-documentation pipeline. The workflow is well-integrated into the broader ecosystem without requiring any pipeline to exist. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does**: DD enforces a structured diverge-first process: generate 8-15 candidates (including deliberately wrong/naive/unconventional ones), diagnose specific constraints (hard vs. soft), build a compatibility matrix, prune to 3-5 survivors, stress-test with 7 named cognitive moves, then decide with an 80% confidence threshold. The new sub-threshold paragraph routes trivial decisions to `docs/decisions/log.md` instead, reserving full DD for decisions with genuine tradeoffs.

**What ad-hoc process achieves**: Without DD, the default is "think of 2-3 approaches, pick the one that feels right." The diverge phase (8-15 candidates, mandatory unconventional options) and the stress-test pass (structured cognitive moves) are the elements most likely to be skipped. The sub-threshold routing wouldn't exist either -- trivial decisions would either get no documentation or inconsistently documented.

**What built-in tools cover**: No built-in Claude Code capability covers structured design exploration. The matrix-analysis skill covers structured comparison but not divergent generation.

**Questions for the reviewer**:
- How much of DD's value comes from the diverge phase (generating candidates you wouldn't otherwise consider) vs. the evaluation phase (systematic comparison)?
- Have you experienced a DD session where the diverge phase surfaced an approach that became the final decision but wouldn't have been considered otherwise?
- Does the new sub-threshold routing add genuine value (decisions that previously fell through the cracks now get logged), or is it mostly codifying what already happened informally?

### User-Specific Fit

**Triggering situations**: Architectural decisions, library/tool selection, major feature design, any decision where the first idea might not be the best. Also triggered as a sub-procedure from RPI when research surfaces 3+ viable approaches. Sub-threshold decisions are now explicitly routed to `docs/decisions/log.md`.

**Questions for the reviewer**:
- How often do you face design decisions that genuinely benefit from structured divergence vs. having an obvious best approach?
- When you've used DD, did the full process feel proportionate, or did you find yourself abbreviating steps?
- With the new sub-threshold paragraph, is the boundary between "add a log entry" and "run full DD" clear enough in practice? The criteria ("diverge phase quickly converges to a single obvious answer, no real tradeoffs, low reversal cost") seem concrete -- do they match your intuition?

### Condition for Value

**Stated or inferred conditions**: No external dependencies. Works for any design decision. Requires that the user faces decisions with genuine tradeoffs frequently enough to justify learning and following the process.

**Automated findings**:
- RPI cross-reference: EXISTS (step 2 explicitly triggers DD)
- Spike cross-reference: EXISTS (DD can trigger spikes for feasibility validation)
- Decision docs directory: EXISTS (`docs/decisions/` has multiple decision records)
- Decision log: EXISTS (`docs/decisions/log.md` with active entries and cross-referencing guidance)
- The log.md file reciprocally references DD ("The decision emerged from (or should have gone through) the divergent-design workflow" as a criterion for promotion to full record)
- The sub-threshold paragraph's link to `log.md` is valid and the log's "when to use" criteria are consistent with DD's stated boundary

**Questions for the reviewer**:
- Is the frequency of genuine design decisions (not sub-threshold) high enough to keep DD fluent in your workflow?
- Does the sub-threshold escape hatch risk being used too liberally -- decisions that deserve full analysis ending up as one-liners in the log?
- Is the bidirectional cross-reference between DD and log.md sufficient, or should other workflows (e.g., RPI) also reference the log for sub-threshold decisions encountered during research?

### Failure Mode Gracefulness

**Output structure**: DD produces a numbered candidate list, a compatibility matrix, a tradeoff matrix, stress-test results, and a decision document in `docs/decisions/`. Sub-threshold decisions produce a row in `docs/decisions/log.md` instead. The structured matrices make thin analysis somewhat visible -- empty cells, all-identical scores, and sparse stress-test responses are detectable.

**Potential silent failures**:
- The diverge phase produces 15 candidates that are superficially different but substantively identical. The compatibility matrix would then show similar scores, masking the lack of genuine diversity.
- Stress-test moves applied superficially -- "boring alternative: no, the current approach is already simple" without genuine engagement. The structured format can mask lazy analysis.
- The 80% confidence threshold is self-assessed. A confident-sounding but wrong decision can pass the threshold and proceed without human review.
- Sub-threshold routing could silently downgrade decisions that deserve full analysis. The one-liner format in log.md provides no evidence that the boundary was correctly assessed -- there is no "I considered full DD but decided this was sub-threshold because..." field.

**Pipeline mitigations**: When invoked from RPI, the human checkpoint on the plan catches bad DD decisions before implementation. The log.md guidance says "when in doubt, start with a log entry -- you can always promote it to a full record later," which provides a recovery path for mis-classified sub-threshold decisions.

**Questions for the reviewer**:
- Have you observed the "superficially diverse but substantively identical candidates" failure mode?
- When DD produces a decision at >80% confidence, how often do you review the decision doc anyway vs. trusting the autonomous output?
- Have you encountered a decision routed to log.md that later turned out to need full analysis? How did you catch it?

---

## Key Questions

1. **Is the sub-threshold routing well-calibrated?** The new paragraph routes trivial decisions to `docs/decisions/log.md`. This directly addresses the concern raised in full-evaluation.md about DD becoming too heavy for smaller decisions. But the boundary ("diverge phase quickly converges to a single obvious answer") relies on judgment at exactly the moment when people are most tempted to shortcut. Is the risk of under-analysis (logging a decision that needed full DD) greater or lesser than the risk of over-analysis (running full DD on a trivial choice)?

2. **Does DD's value scale with codebase maturity?** As the workflow repo stabilizes and fewer genuinely novel design decisions arise, does DD's frequency of use justify its continued position as a core workflow? Or does it shift from "frequently used" to "rarely used but high-value when triggered" -- and is that acceptable?

3. **Diverge phase quality remains untestable.** The diverge phase is DD's core differentiator, but there is no mechanism to verify that candidates are genuinely diverse rather than superficial variations. The "include 2-3 approaches that feel wrong" instruction is the only safeguard. Past decision records in `docs/decisions/` could be retrospectively analyzed for candidate diversity, but this has not been done.
