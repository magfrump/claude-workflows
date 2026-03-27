# Self-Evaluation: divergent-design

**Target:** `workflows/divergent-design.md` | **Type:** Workflow | **Evaluated:** 2026-03-24
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | Completion signals define mechanically checkable structural properties (8+ candidates, matrix completeness, 3-5 survivors, stress-test application). However, evaluating whether the decision is genuinely better than ad-hoc requires counterfactual comparison — hard to construct for a workflow. |
| Trigger clarity | Strong | "When to use" lists specific situations (architectural decisions, library selection, premature convergence risk). Clearly positioned as sub-procedure of RPI with explicit pivot guidance. No confusing overlap — matrix-analysis handles evaluation of pre-existing options, DD handles generating candidates first. |
| Overlap and redundancy | Strong | The diverge phase (generating 8-15 candidates including naive/do-nothing/unconstrained) is unique — no other workflow or skill covers structured ideation. Evaluation-phase overlap with matrix-analysis is real but partial and well-documented; DD's value is primarily upstream of where matrix-analysis operates. |
| Test coverage | Weak | No automated tests in `test/`. No formal example outputs in `docs/reviews/`. Real-world usage is evidenced by `docs/decisions/003-critic-moves-in-divergent-design.md` (a decision produced via DD), but no test infrastructure exists. |
| Pipeline readiness | Strong | Standalone viable for any design decision. Also integrated as a sub-procedure of RPI (documented in both workflows' pivot sections). No pipeline dependency — works independently or composed. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does**: DD enforces a structured diverge→diagnose→match→decide process. The diverge phase generates 8-15 candidates (including deliberately "wrong" ones), the diagnose phase specifies testable constraints, match-and-prune creates a compatibility matrix, and the tradeoff matrix includes a stress-test pass using adapted critic cognitive moves. The 80% confidence threshold gates autonomous decisions.

**What ad-hoc process achieves**: Without DD, the default is "pick the first approach that seems reasonable" or at best "consider 2-3 options informally." Generic prompting could produce a pros/cons list but wouldn't reliably enforce: (a) generating deliberately wrong/naive candidates, (b) separating generation from evaluation, (c) structured stress-testing with cognitive moves, or (d) the confidence-gated decision point.

**What built-in tools cover**: No built-in Claude Code capability covers structured design exploration. The built-in approach would be conversational back-and-forth about options.

**Questions for the reviewer**:
- How much of DD's value comes from the diverge phase (forcing 8+ candidates) vs. the stress-test pass (adapted critic moves)? If the diverge phase is the key differentiator, is the stress-test pass adding proportional value or just weight?
- In your actual DD sessions, how often has a "deliberately wrong" candidate led to a genuine insight vs. being discarded as expected?
- Under what conditions is the gap largest — complex architectural decisions, or does it also help for smaller design choices?

### User-Specific Fit

**Triggering situations**: Architectural decisions, library/tool selection, major feature design, any decision where the first idea might not be best. Also triggered as a sub-procedure from RPI when research surfaces 3+ viable approaches.

**Questions for the reviewer**:
- How often do you face genuine design decisions (vs. straightforward implementation)?
- Is the frequency increasing as the workflow/skill repo matures, or decreasing as patterns stabilize?
- Do you actually invoke DD explicitly, or does it happen implicitly when you ask Claude to help with a decision?
- Is the full 5-step process proportionate to most of your decisions, or do you more often need a lighter version?

### Condition for Value

**Stated or inferred conditions**: DD requires design decisions worth the overhead of a structured process. It assumes the user faces decisions where premature convergence is a real risk — not all decisions qualify.

**Automated findings**:
- RPI workflow references DD as a sub-procedure: EXISTS (`workflows/research-plan-implement.md` pivot section)
- Decision docs produced by DD: EXISTS (`docs/decisions/003-critic-moves-in-divergent-design.md`)
- Stress-test pass (recent addition): EXISTS in the workflow
- No pipeline dependency — standalone viable

**Questions for the reviewer**:
- Are the conditions met today? Do you regularly face decisions where premature convergence is a genuine risk?
- Has DD become overhead for decisions that don't warrant the full process? Is there a need for a "DD-lite" path?
- The stress-test pass was a recent addition (decision 003). Has it justified its weight in practice?

### Failure Mode Gracefulness

**Output structure**: DD produces numbered candidate lists, compatibility matrices (✓/~/✗/⚠), tradeoff matrices with effort/risk/coverage/downside columns, and a final decision doc in `docs/decisions/`. The structured artifacts make the reasoning chain visible and auditable.

**Potential silent failures**:
- The diverge phase could produce 15 superficially different but substantively identical candidates, creating an illusion of thorough exploration
- The diagnose phase could miss non-obvious constraints, leading to a well-structured but poorly-grounded evaluation
- Stress-test moves could produce plausible-sounding but shallow critique that doesn't actually reveal new information
- The 80% confidence assessment is self-reported and could be miscalibrated

**Pipeline mitigations**: DD's output feeds into RPI's plan step, which has a human review gate. The decision doc is committed and visible for future scrutiny. But within the DD process itself, there's no external check — it's self-contained.

**Questions for the reviewer**:
- Have you observed the "superficially diverse but substantively identical" failure in the diverge phase?
- When DD produced a decision you later regretted, where did the process fail — diverge, diagnose, match, or tradeoff?
- Is the 80% confidence threshold well-calibrated in practice, or does DD tend to over- or under-estimate confidence?

---

## Key Questions

1. **Is the full DD process proportionate?** The workflow has grown (stress-test pass, completion signals, pivot guidance). For genuine architectural decisions it's clearly valuable, but is there a risk of it becoming too heavy for medium-sized design choices? Would a "DD-lite" variant (diverge + quick matrix, skip stress-test) be worth adding?

2. **Does the diverge phase actually produce diverse candidates in practice?** The requirement for naive/do-nothing/unconstrained candidates is well-designed in theory. The key empirical question is whether Claude (or the user) actually generates substantively different approaches, or whether the candidates cluster around 2-3 real options with cosmetic variations.

3. **What's the right test investment?** The completion signals are well-defined and mechanically checkable, making structural testing feasible. But the real value proposition — "DD produces better decisions than ad-hoc" — is extremely hard to test. Is structural testing sufficient, or does DD need real-world A/B comparison?
