# Research: What-If Analysis Skill

**Scope:** Design a what-if/counterfactual analysis skill that explores consequences and failure modes of proposed changes. Differentiated from existing critique skills by focusing on consequence exploration and second-order effects.

## What Exists

### Current Critique Skills
- **cowen-critique** — Quality/argument critique via economist reasoning patterns (boring explanation, inversion, revealed preferences, cross-domain analogy, market signals, decomposition, contingent assumptions, calibrated uncertainty)
- **yglesias-critique** — Policy feasibility critique (goal vs mechanism, boring lever, follow money, political survival, cost disease, scale test, org chart, popular version)
- **draft-review** — Orchestrator coordinating fact-check + critics into rubric
- **code-review pipeline** — code-fact-check + security/performance/api-consistency reviewers

### Gap Identified
External skill audit (2026-04-08) identified what-if/counterfactual analysis as MEDIUM priority gap. Source: K-Dense-AI's "what-if-oracle" skill. Audit noted it "may be better as a cognitive move within existing skills than a standalone skill" but the task spec calls for a standalone skill.

## Key Differentiation

**Existing critique skills ask:** "Is this good? Is this correct? Does this work?"
**What-if analysis asks:** "What breaks if our assumptions are wrong? What are the second-order consequences? What would need to be true for this to fail?"

Existing skills evaluate *quality*. What-if evaluates *consequences and robustness*. The overlap is in assumption-surfacing (Cowen move #8 — contingent assumptions), but what-if goes further: it traces the *cascading effects* of those assumptions being wrong, rather than just noting they're contingent.

## Invariants
- Must follow skill format: YAML frontmatter (name, description, when, requires), cognitive moves, output structure, output location, tone
- 7-9 distinctive cognitive moves
- Output to `docs/reviews/what-if-analysis.md`
- Can accept optional upstream input (fact-check, other critiques) but doesn't require it
- Must not duplicate existing cognitive moves — must be genuinely novel analytical patterns

## Prior Art
- Pre-mortem technique (Gary Klein): Imagine the project has failed, work backwards to identify causes
- Scenario planning (Shell/RAND): Identify key uncertainties, build divergent scenarios
- Failure mode analysis (FMEA): Systematic enumeration of failure modes, effects, and criticality
- Red teaming: Adversarial analysis of assumptions and plans
- Second-order thinking (Howard Marks): What happens after the first-order effect?

## Hypothesis Testability
The skill output should explicitly tag findings that represent "unexamined assumptions" or "novel failure modes" not surfaced by quality-focused critique skills. This makes it possible to compare against Cowen/Yglesias critique outputs on the same artifact to evaluate whether the what-if skill found something new.
