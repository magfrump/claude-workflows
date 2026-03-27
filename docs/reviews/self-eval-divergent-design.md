# Self-Evaluation: divergent-design

**Target:** `workflows/divergent-design.md` | **Type:** Workflow | **Evaluated:** 2026-03-24
**Evaluator:** Automated (self-eval skill) — human review required for flagged dimensions

---

## Automated Assessments

| Dimension | Score | Justification |
|---|---|---|
| Testability investment | Adequate | Structural properties are checkable (did it generate 8-15 candidates? include "wrong" ones? apply 2-4 stress-test moves? produce a decision doc?), but evaluating whether the divergent process produced a genuinely better decision than ad-hoc requires counterfactual comparison and human judgment. |
| Trigger clarity | Strong | Triggers are specific and well-calibrated: "architectural decisions," "library selection," "premature convergence risk." RPI explicitly defines pivot signals (3+ viable approaches, can't fully evaluate constraints, temptation to justify rather than compare). No confusing overlap with other workflows — spike is "can this work?" while DD is "which approach is best?" |
| Overlap and redundancy | Strong | The diverge→diagnose→match→decide process is unique. Matrix-analysis overlaps on the evaluation phase but not the diverge or diagnosis phases — DD is a full decision-making workflow while matrix-analysis is an evaluation tool. No built-in capability covers structured divergent design. |
| Test coverage | Adequate | No automated tests exist. However, real-world usage is documented: decision docs 003, 004, and 005 all show DD was used, with 003 explicitly about DD's own design. The decision docs represent DD's expected output artifacts (step 5). Missing: preserved intermediate artifacts (diverge lists, compatibility matrices) that would demonstrate steps 1-4. |
| Pipeline readiness | Strong | Standalone viable and well-integrated. Invocable from within RPI (explicit pivot signals in RPI step 2). Also referenced by pr-prep (architectural problems) and codebase-onboarding (structural conflicts). Multiple entry points, no orphaned dependencies. |

---

## Flagged for Human Review

### Counterfactual Gap

**What the workflow does**: DD enforces a structured divergent-then-convergent design process: generate 8-15 candidates (including deliberately "wrong" ones), diagnose specific constraints (hard vs. soft), match candidates against constraints via compatibility matrix, build a tradeoff matrix with a stress-test pass using 7 adapted cognitive moves, then document the decision. The diverge phase (generating many candidates before evaluating any) is the core differentiator.

**What ad-hoc process achieves**: Without DD, the typical approach is "think of 2-3 obvious options, evaluate them loosely, pick the one that feels best." This misses: (1) unconventional candidates that might be superior, (2) systematic constraint diagnosis, (3) structured stress-testing via cognitive moves. The "do nothing" and "ideal if effort were free" requirements specifically combat anchoring bias.

**What built-in tools cover**: No built-in Claude Code capability does structured divergent design. The code-simplifier agent operates on existing code, not design decisions.

**Questions for the reviewer**:
- How much of DD's value comes from the diverge phase (generating candidates you wouldn't have considered) vs. the structured evaluation (stress-test moves, compatibility matrix)?
- When you've used DD (decisions 003, 004, 005), did the diverge phase surface candidates that changed the outcome? Or did the eventual winner come from your initial intuition?
- Under what conditions is the gap largest — complex architectural decisions, or does it also help for smaller design choices?

### User-Specific Fit

**Triggering situations**: Architectural decisions about feature structure or patterns; library/tool selection; major feature design with multiple viable approaches; any decision where premature convergence is a risk. Also triggered as a sub-procedure from RPI when research reveals design ambiguity.

**Questions for the reviewer**:
- How often do genuine multi-approach design decisions arise in your current work (workflows repo, board game digitization, other projects)?
- Is the frequency increasing as projects mature, or decreasing as foundational decisions get made?
- Do you actually invoke DD when the situation arises, or do you sometimes skip it for speed?
- The stress-test pass (added in decision 003) made DD heavier — has this changed when you reach for it?

### Condition for Value

**Stated or inferred conditions**: DD requires a decision with multiple viable approaches and enough complexity to justify the structured process. It needs a user willing to generate deliberately "wrong" candidates and work through a multi-step evaluation.

**Automated findings**:
- RPI (which triggers DD): EXISTS and is the backbone workflow
- Decision docs using DD: EXISTS (003, 004, 005) — confirmed real-world usage
- Stress-test cognitive moves (added per decision 003): INTEGRATED into the workflow
- No external dependencies required

**Questions for the reviewer**:
- Is the full DD process (all 5 steps) worth the overhead for most decisions, or do you often abbreviate?
- The tier annotations mark steps 1, 2, and 5 as essential and steps 3-4 as recommended — does this match your experience of where value concentrates?
- Is DD an investment that's pulling toward better decisions, or has it become rote process that you'd do roughly as well without?

### Failure Mode Gracefulness

**Output structure**: DD produces a decision document (docs/decisions/NNN-title.md) with context, options considered, decision, rationale, and consequences. Intermediate artifacts (candidate list, compatibility matrix, tradeoff matrix) are working documents that may or may not be preserved.

**Potential silent failures**:
- The diverge phase producing 15 superficially different but substantively identical candidates (creative-looking but actually anchored)
- The stress-test pass applying moves superficially — asking "what happens at 10x?" and answering "it scales fine" without actually analyzing scaling behavior
- Premature convergence disguised as structured process — going through the motions while already committed to a preferred option
- Constraint diagnosis missing a non-obvious hard constraint that invalidates the chosen approach

**Pipeline mitigations**: The 80% confidence threshold for autonomous decision is a safeguard — genuinely unclear tradeoffs get escalated to the user. The "when to pivot" section connects DD to spike (for feasibility validation) which can catch infeasible candidates. Decision docs create a reviewable trail.

**Questions for the reviewer**:
- Have you observed any of the silent failure modes above in practice?
- When reviewing decision docs, can you tell whether the DD process was genuinely followed vs. rubber-stamped?
- Is the 80% confidence threshold well-calibrated, or does it trigger too often / too rarely?

---

## Key Questions

1. **Is the stress-test pass earning its weight?** Decision 003 added cognitive moves to DD's evaluation phase. This made the workflow more thorough but also heavier. Has this addition demonstrably improved decision quality, or does it add overhead without changing outcomes for most decisions?

2. **Are the intermediate artifacts worth preserving?** DD's decision docs capture the final decision but not the diverge list, compatibility matrix, or tradeoff matrix. If these were preserved, they'd provide stronger evidence of process quality and enable better self-evaluation. Is the lack of intermediate artifact preservation a design choice or an oversight?

3. **Where does DD's value concentrate across its tiers?** Steps 1-2 (diverge, diagnose) are marked essential; steps 3-4 (match, tradeoff matrix) are recommended. If most value comes from forcing divergent thinking and constraint diagnosis, the recommended steps may be overhead for simpler decisions — or they may be where the stress-test pass catches what intuition misses.
