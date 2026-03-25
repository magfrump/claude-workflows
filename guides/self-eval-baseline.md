# Self-Eval Baseline Guide

How to apply the self-eval skill to existing skills and produce baseline reports.

## Purpose

A **baseline report** captures how a skill scores today — before any improvements. Baselines serve two goals:

1. **Prioritize work.** Weak scores surface the highest-leverage improvements across the skill portfolio.
2. **Measure progress.** After improving a skill, re-run self-eval and compare against the baseline.

## Prerequisites

- The evaluation rubric exists at `docs/evaluation-rubric.md`.
- The self-eval skill exists at `skills/self-eval.md`.
- The target skill or workflow exists in `skills/` or `workflows/`.

## How to Run a Baseline

### 1. Pick the target

Choose a skill or workflow to evaluate. Baselines are most valuable for skills that are actively used or about to be improved.

### 2. Invoke self-eval

Run the self-eval skill on the target:

```
/self-eval fact-check
```

Or provide a path:

```
/self-eval skills/fact-check.md
```

The skill reads the rubric, gathers context (sibling skills, test evidence, git history, pipeline references), and produces a structured report.

### 3. Review the output

The report lands at `docs/reviews/self-eval-{target-name}.md`. It contains:

- **Automated Assessments** — 5 dimensions scored Strong/Adequate/Weak with justifications.
- **Flagged for Human Review** — 4 dimensions with structured prompts (no scores — these require human judgment).
- **Key Questions** — 2–3 synthesis questions highlighting the most important things to think about.

### 4. Complete the human-review sections

The automated report is half the evaluation. For each flagged dimension, read the prompts and answer the questions. Record your answers inline or in a separate review session. This is where the evaluation becomes actionable — the automated scores identify structural properties, but human judgment determines whether the skill actually matters for your work.

### 5. Commit the baseline

Commit the report to `docs/reviews/`. It becomes the reference point for future comparisons.

## Running Baselines in Batch

To evaluate multiple skills, run self-eval on each one sequentially. Each run produces an independent report. Batch baselines are useful when:

- Starting a new improvement cycle and need to prioritize across skills.
- Onboarding to a codebase and want to understand which tools are mature vs. probationary.
- A significant change (new pipeline, new skill) may have shifted scores for existing skills.

## Comparing Against a Baseline

After improving a skill, re-run self-eval on the same target. Compare:

- Did any automated scores change? (Check justifications, not just labels.)
- Are the human-review prompts still asking the right questions, or has the skill evolved past them?
- Did new key questions emerge?

The diff between baseline and current report is the measurable impact of the improvement work.

## Tips

- **Don't inflate scores.** A baseline with honest Weak scores is more useful than one padded to Adequate. The point is to see where you are, not where you wish you were.
- **Freshness matters.** Baselines reflect a point in time. If the skill, its tests, or its pipeline change significantly, the baseline may be stale. Re-run rather than relying on an old report.
- **Human-review dimensions are load-bearing.** A skill can score Strong on all automated dimensions and still be low-value if the counterfactual gap is small or user-specific fit is poor. Don't skip the human review.
