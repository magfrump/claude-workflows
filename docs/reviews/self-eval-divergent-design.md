# Self-Evaluation: divergent-design

**Target:** `workflows/divergent-design.md` | **Type:** Workflow | **Evaluated:** 2026-03-26
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Weak | Evaluating whether DD produces genuinely better decisions than ad-hoc requires counterfactual comparison — inherently subjective. Structural properties (candidate count, stress-test move application, matrix completeness) can be checked mechanically, but decision quality cannot. This is a workflow, making it harder still — the artifacts are intermediate, not final. |
| Trigger clarity | Strong | "When the first idea is probably not the best idea" and "any decision where premature convergence is a risk" are specific and well-calibrated. Clear differentiation from RPI (DD is a sub-procedure for design decisions), spike (DD is for choosing among known options, spike is for feasibility unknowns), and matrix-analysis (which overlaps on evaluation but not divergence). No ambiguous overlap with other workflows. |
| Overlap and redundancy | Strong | No other workflow or built-in tool does structured divergent design. Matrix-analysis overlaps on the evaluation/tradeoff phase but not the diverge phase — which is DD's key differentiator. The stress-test pass incorporates critic-style cognitive moves (from decision 003), but these are applied to design candidates rather than written drafts, making the overlap structural rather than substantive. |
| Test coverage | Weak | No automated tests exist in `test/` for DD. No dedicated output artifacts in `docs/reviews/`. However, there is evidence of real-world usage: decision documents exist in `docs/decisions/`, and git history shows multiple commits evolving the workflow (completion signals, stress-test moves, pivot guidance). This is better than zero evidence but still falls short of even Adequate — no example outputs demonstrate the full process. |
| Pipeline readiness | Strong | Standalone viable for any architectural or design decision. Also formally integrated into RPI as a sub-procedure (RPI step 2 defines trigger signals for pivoting to DD). DD's output (a decision doc) feeds directly back into RPI's plan step. Additionally connects to spike (for feasibility validation of uncertain candidates) and pr-prep (downstream). This is a well-connected workflow with clear integration points. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does**: DD enforces a structured diverge-then-converge process: generate 8-15 candidates (including deliberately "wrong" or naive options), diagnose constraints with hard/soft distinction, match candidates against constraints via compatibility matrix, build a tradeoff matrix for survivors, then stress-test using 7 cognitive moves (boring alternative, invert the thesis, revealed preferences, push to extreme, organizational survival, scale test, implementation org chart). The 80% confidence threshold gates autonomous decisions vs. consulting the user.

**What ad-hoc process achieves**: Without DD, the typical approach is "pick the first reasonable option and start building." A developer might consider 2-3 alternatives informally. The diverge phase (8-15 candidates including deliberately bad ones) and the structured stress-test pass are the elements most likely to be skipped entirely. The constraint diagnosis step (with hard/soft distinction) would sometimes happen informally but without rigor.

**What built-in tools cover**: No built-in Claude Code capability covers structured design exploration. The matrix-analysis skill could handle the tradeoff comparison phase, but nothing generates the candidate set or runs the stress-test pass.

**Questions for the reviewer**:
- How much of DD's value comes from the diverge phase (generating options you wouldn't otherwise consider) vs. the structured evaluation (tradeoff matrix, stress tests)?
- Have you experienced a DD session where a "wrong" or naive candidate turned out to be the right approach? If not, is the 8-15 candidate requirement overhead?
- Under what conditions is the gap largest — complex architectural decisions, or does it also help for smaller design choices?

### User-Specific Fit

**Triggering situations**: Architectural decisions, library/tool selection, major feature design with multiple viable approaches, any decision where premature convergence is a risk, and as a sub-procedure within RPI when research reveals 3+ viable approaches.

**Questions for the reviewer**:
- How often do you face genuine design decisions (3+ viable approaches) vs. situations where the right approach is fairly obvious?
- Is the frequency of design decisions increasing or decreasing as the project matures?
- Do you invoke DD explicitly, or does it mainly get triggered via RPI's pivot mechanism?
- Is the full 5-step process (diverge through document) proportionate to most decisions, or do you often want a lighter-weight version?

### Condition for Value

**Stated or inferred conditions**: DD requires decisions with genuine design ambiguity. It's standalone viable (no pipeline dependency). It integrates with RPI as a sub-procedure and can invoke spike for feasibility validation.

**Automated findings**:
- RPI workflow that references DD as sub-procedure: **EXISTS** (`workflows/research-plan-implement.md` step 2)
- Spike workflow for feasibility validation: **EXISTS** (`workflows/spike.md`)
- Decision docs produced by DD sessions: **EXIST** (`docs/decisions/` directory has entries)
- Matrix-analysis skill for tradeoff phase: **EXISTS** (`skills/matrix-analysis.md`)

**Questions for the reviewer**:
- Are the conditions met today? (They appear to be — standalone viable with integration points all functioning)
- Is DD being used at the right frequency? Too often (overhead for simple decisions) or too rarely (defaulting to ad-hoc when DD would help)?
- The stress-test pass was added recently (decision 003). Has it changed the weight/overhead of the process noticeably?

### Failure Mode Gracefulness

**Output structure**: DD produces intermediate artifacts (candidate list, compatibility matrix, tradeoff matrix) and a final decision document in `docs/decisions/`. The structured matrices make thin analysis visible — a compatibility matrix with all checkmarks or a tradeoff matrix with identical scores signals shallow evaluation.

**Potential silent failures**:
- The diverge phase produces 15 superficially different but substantively identical candidates (all variations on the same approach), creating an illusion of exploration without genuine divergence.
- The stress-test pass applies cognitive moves superficially — asking "what's the boring alternative?" but accepting "there isn't one" without genuine investigation.
- The 80% confidence threshold is self-assessed, risking premature convergence when the evaluator is overconfident.
- Constraint diagnosis misses a non-obvious hard constraint, leading to a well-structured decision that fails on an unconsidered dimension.

**Pipeline mitigations**: The human checkpoint at the decision step (consult user if confidence <80%) catches some failures. RPI's plan review step provides a second checkpoint. Decision docs are committed and reviewable.

**Questions for the reviewer**:
- Have you observed the "superficially diverse candidates" failure mode in practice?
- When DD produced a decision you later regretted, what went wrong — was it the diverge phase, the constraint diagnosis, or the evaluation?
- Is the 80% confidence threshold well-calibrated, or do you find DD either decides too autonomously or escalates too often?

---

## Key Questions

1. **Weight calibration**: The stress-test pass (7 cognitive moves) adds significant depth but also weight. Is DD becoming too heavy for medium-sized decisions, or does the "when to use" section effectively filter it to decisions that warrant the full process?

2. **Diverge phase quality**: The diverge phase is DD's key differentiator — generating candidates you wouldn't otherwise consider. Is the 8-15 candidate requirement producing genuine diversity, or does it sometimes produce padding? Would a "quality over quantity" variant be more effective?

3. **Integration maturity**: DD is well-connected (RPI sub-procedure, spike for validation, decision docs as output). Is this integration working smoothly in practice, or are the handoff points (especially RPI→DD→RPI) creating friction?
