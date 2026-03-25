# Running Self-Eval Baseline Reports

## Purpose

This guide shows how to use the `self-eval` skill to produce baseline evaluation reports for existing skills and workflows. Baseline reports establish a starting point for tracking quality over time and surface dimensions that need human review.

## Prerequisites

- The self-eval skill exists at `skills/self-eval.md`
- The evaluation rubric exists at `docs/evaluation-rubric.md`
- Reports are saved to `docs/reviews/self-eval-{target-name}.md`

## How to run self-eval on a skill

Invoke the self-eval skill with a target:

```
/self-eval code-fact-check
/self-eval cowen-critique
/self-eval code-review
```

Or specify a path:

```
/self-eval skills/code-fact-check.md
```

The skill handles both skills and workflows. It reads the rubric at runtime (not from memory), gathers context from sibling files and test evidence, then produces a structured report.

## What the report contains

Each report has two sections:

### Automated assessments (5 dimensions, scored)

| Dimension | What it checks |
|---|---|
| Testability investment | How much work to build meaningful tests |
| Trigger clarity | Whether users know when to invoke the skill |
| Overlap and redundancy | Whether another tool already does this |
| Test coverage | What evidence exists that the tool works |
| Pipeline readiness | Whether the tool fits into an existing pipeline |

These produce Strong / Adequate / Weak scores with justifications.

### Human-judgment dimensions (4 dimensions, not scored)

| Dimension | What it asks |
|---|---|
| Counterfactual gap | How much worse without this tool? |
| User-specific fit | How relevant to actual work patterns? |
| Condition for value | What must be true for this to earn its place? |
| Failure mode gracefulness | When it's wrong, how easy to tell? |

These produce structured prompts for the human reviewer, not scores. The skill cannot assess these reliably — they require domain knowledge and usage experience.

## Baseline examples

Three baseline reports were produced on 2026-03-24 to demonstrate the skill across different tool types:

### 1. code-fact-check (standalone skill)

**Report:** `docs/reviews/self-eval-code-fact-check.md`

code-fact-check verifies that code comments match actual implementation. It's a specialized standalone skill that also serves as a pipeline stage for the code-review orchestrator. This evaluation tests self-eval on a tool with low testability investment and clear pipeline dependencies.

### 2. cowen-critique (critic skill)

**Report:** `docs/reviews/self-eval-cowen-critique.md`

cowen-critique applies Tyler Cowen's intellectual framework to stress-test prose drafts. It's a critic skill composed by the draft-review orchestrator. This evaluation tests self-eval on a tool where quality assessment is inherently subjective and overlap with a sibling critic (yglesias-critique) must be carefully analyzed.

### 3. code-review (orchestrator skill)

**Report:** `docs/reviews/self-eval-code-review.md`

code-review orchestrates multiple code critic agents (code-fact-check, security-reviewer, performance-reviewer, api-consistency-reviewer) into a multi-stage review pipeline. This evaluation tests self-eval on an orchestrator — a tool whose value is in coordination rather than direct analysis.

## Interpreting results

**Automated scores** are starting points, not verdicts. A "Weak" score with clear justification is more useful than an inflated "Adequate." Check the justification column — it explains _why_ and makes the score actionable.

**Human-review prompts** are the most important part. Each prompt includes:
- What automated analysis found that's relevant
- Specific questions the reviewer should answer
- Context for making the assessment (triggering situations, pipeline dependencies, failure modes)

**Key Questions** at the end of each report highlight the 2-3 most important things the reviewer should think about.

## Running a batch

To evaluate all skills, run self-eval on each one individually. The skill processes one target at a time. For a full sweep:

```bash
for skill in skills/*.md; do
  echo "Evaluating: $skill"
  # Invoke self-eval on $skill
done
```

The self-improvement pipeline (`self-improvement.sh`, Gate 1g) automatically runs self-eval on changed skills and rejects branches with 2+ Weak automated scores.

## When to re-run

Re-run self-eval when:
- A skill or workflow has been significantly modified
- Pipeline dependencies have changed (new orchestrator built, existing one removed)
- Test coverage has changed (new tests written, fixtures added)
- Periodic reassessment (the rubric recommends this for all tools)

Check staleness using the freshness fields in each report's YAML frontmatter — see `guides/doc-freshness.md`.
