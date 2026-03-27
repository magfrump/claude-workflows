# Self-Evaluation: divergent-design

**Target:** `workflows/divergent-design.md` | **Type:** Workflow | **Evaluated:** 2026-03-26
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | Workflow output is a decision doc (`docs/decisions/NNN-title.md`) plus intermediate artifacts (candidate lists, compatibility matrices, tradeoff matrices). Quality assessment — did it consider the right candidates, apply stress-tests meaningfully, reach a sound decision — requires domain expertise and subjective judgment. Structural properties (number of candidates, matrix completeness) can be checked, but these are proxies, not quality measures. |
| Trigger clarity | Strong | Triggers are specific and well-differentiated: architectural decisions, library selection, major feature design, premature convergence risk. The "When to pivot" section clearly delineates the boundary with RPI (invoked as sub-procedure when research surfaces 3+ viable approaches) and Spike (for feasibility validation). RPI explicitly documents the signals for pivoting to DD. No ambiguity with other workflows. |
| Overlap and redundancy | Strong | No other workflow covers structured option generation and comparison. RPI handles research-plan-implement but explicitly defers design decisions to DD. Task-decomposition parallelizes research but doesn't evaluate design alternatives. Spike validates feasibility of a single approach but doesn't compare multiple options. The stress-test moves (boring alternative, invert the thesis, etc.) are unique to DD and not replicated elsewhere. |
| Test coverage | Weak | No automated tests exist for this workflow. No example output artifacts (decision docs produced by following DD) are present in `docs/reviews/` or `docs/decisions/` that explicitly trace back to DD usage. Git history shows 8 commits mentioning divergent-design, but these are all workflow-improvement commits (adding completion signals, pivot guidance, tier annotations), not evidence of the workflow being used on real design decisions. The log-usage test references DD but only for hook logging mechanics, not workflow quality. |
| Pipeline readiness | Strong | DD is standalone viable — it can be invoked directly for any design decision. It is also well-integrated as a sub-procedure of RPI (RPI step 2 explicitly documents when and how to invoke DD, with clear handoff in both directions). The DD-to-Spike pivot for feasibility validation is also documented. This gives DD a clear place in the workflow ecosystem without requiring any missing infrastructure. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does**: DD enforces a structured diverge-then-converge process: generate 8-15 candidates (including deliberately unconventional ones), diagnose constraints with hard/soft labeling, prune via compatibility matrix, then stress-test survivors using 7 named cognitive moves (boring alternative, invert the thesis, revealed preferences, push to extreme, organizational survival, scale test, implementation org chart). Output is a decision doc.

**What generic prompting achieves**: Asking Claude "what are my options for X?" would likely produce 3-5 reasonable candidates, a brief pros/cons comparison, and a recommendation. Missing elements: the forced quantity (8-15 candidates including "wrong" ones), the hard/soft constraint distinction, the compatibility matrix as a pruning mechanism, and especially the named stress-test moves which introduce specific analytical lenses. The "boring alternative" and "invert the thesis" moves are particularly unlikely to emerge from generic prompting.

**What built-in tools cover**: No built-in Claude Code capability covers structured design decision-making.

**Questions for the reviewer**:
- How much of DD's value comes from the forced divergence (generating candidates you wouldn't normally consider) vs. the structured convergence (stress-test moves, matrices)?
- Is the gap "DD adds analytical moves you wouldn't think of" or "DD ensures you don't skip steps you know are valuable but tend to rush past"?
- Under what conditions is the gap largest — complex architectural decisions, or also smaller design choices?

### User-Specific Fit

**Triggering situations**: Architectural decisions, library/tool selection, major feature design where multiple approaches exist, any decision where premature convergence is a risk. Also triggered as a sub-procedure from RPI when research surfaces 3+ viable approaches.

**Questions for the reviewer**:
- How often do you face design decisions where 3+ viable approaches exist with non-obvious tradeoffs?
- When you do face such decisions, do you currently tend toward premature convergence (picking the first reasonable approach)?
- Is the frequency of these decisions increasing or decreasing as the project matures?
- Would you actually remember to invoke DD (or let RPI invoke it) when the situation arises, or would you tend to just pick an approach and proceed?

### Condition for Value

**Stated or inferred conditions**: DD requires design decisions to arise in the user's work. It requires the user to have enough context about the problem domain to evaluate candidates and stress-test results. It benefits from the RPI integration being followed (so DD gets invoked at the right moment during research).

**Automated findings**:
- RPI workflow that invokes DD as sub-procedure: EXISTS (with explicit trigger signals documented)
- Spike workflow for feasibility validation of DD candidates: EXISTS (with documented pivot path)
- Decision docs directory (`docs/decisions/`): EXISTS (with 6 decision documents and a log)
- Evidence of DD being used on real decisions: NOT FOUND (decision docs exist but none explicitly reference DD as the process used)

**Questions for the reviewer**:
- Are you currently using DD when design decisions arise, or are you making decisions through less structured means?
- If you're not using DD, is it because the decisions don't warrant it, or because you forget to invoke it?
- Would the value increase if there were a lighter-weight variant for smaller decisions (e.g., 3-5 candidates instead of 8-15)?

### Failure Mode Gracefulness

**Output structure**: DD produces a decision doc with context, options considered, decision rationale, and consequences. Intermediate artifacts include numbered candidate lists, compatibility matrices with explicit symbols (check/tilde/x/warning), and tradeoff matrices with effort/risk/coverage/downside columns.

**Potential silent failures**:
- **Premature convergence despite the process**: The candidate generation step could produce 8-15 candidates that are actually variations of 2-3 real approaches, giving an illusion of breadth. The compatibility matrix would then confirm the "winner" that was predetermined.
- **Stress-test theater**: The cognitive moves could be applied superficially — going through the motions of "boring alternative" or "invert the thesis" without genuinely challenging the leading approach. The output would look thorough but not have actually pressure-tested anything.
- **Constraint misidentification**: If hard/soft constraint labeling is wrong (a soft constraint treated as hard, or vice versa), the pruning step silently eliminates viable candidates or keeps non-viable ones.
- **Anchoring on the first compelling candidate**: Despite the process, the tradeoff matrix description and stress-test application could be unconsciously biased toward the first strong candidate identified.

**Pipeline mitigations**: DD is typically invoked within RPI, where the human reviews the plan that incorporates DD's decision. This provides a checkpoint, but the human may not re-evaluate DD's intermediate artifacts (candidate list, matrices) — they may only see the final decision doc.

**Questions for the reviewer**:
- Have you observed cases where DD produced a decision that felt rigorous but was actually predetermined?
- When you review a DD decision doc, do you look at the intermediate artifacts (matrices, candidate lists) or just the final decision and rationale?
- Which failure mode concerns you most: fake divergence, superficial stress-testing, or constraint misidentification?

---

## Key Questions

1. **Is DD being used?** Git history shows workflow improvements but no evidence of DD being applied to real design decisions. The decision docs in `docs/decisions/` don't reference DD as the process used. If DD isn't being invoked when design decisions arise, is the barrier awareness, overhead, or something else?

2. **Does the forced quantity (8-15 candidates) earn its keep?** This is DD's most distinctive feature vs. ad-hoc decision-making. Is it producing genuinely novel candidates, or is it generating padding that wastes time? The answer likely varies by decision type — worth tracking.

3. **How would you know if DD's stress-test moves were applied superficially?** The cognitive moves (boring alternative, invert the thesis, etc.) are the highest-value part of the workflow, but also the hardest to verify. A decision doc that mentions these moves isn't evidence they were applied with rigor.
