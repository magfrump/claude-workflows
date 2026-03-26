# Post-PR Retrospective Guide

A lightweight reflection practice that compounds over time. Takes 2–5 minutes after key moments in a PR's lifecycle.

## When to reflect

Run through these questions at any of these checkpoints:

- **After opening the PR** — while the workflow is fresh in memory. Capture plan accuracy and process observations before context fades.
- **After receiving review feedback** — compare reviewer findings against your self-eval and code review results. Did the review-fix loop ([`workflows/pr-prep.md`](../workflows/pr-prep.md) §3) catch what it should have?
- **After merge / production deployment** — did anything surface post-merge that the process should have caught earlier?

You don't need to reflect at every checkpoint. Pick whichever is most useful for the PR at hand.

## Reflection questions

Record answers in `docs/thoughts/` or in commit message bodies — wherever they'll be findable later.

### 1. Plan accuracy

How closely did the implementation follow the plan? What deviated, and was the deviation an improvement or a sign the plan missed something?

**References:** The plan doc produced during [research-plan-implement](../workflows/research-plan-implement.md) (typically in `docs/working/`).

### 2. Skipped steps

Were any workflow steps skipped or abbreviated? Was that the right call in hindsight, or did it cost time downstream?

**References:** The workflow you followed (e.g., [`pr-prep.md`](../workflows/pr-prep.md), [`research-plan-implement.md`](../workflows/research-plan-implement.md)) and its defined steps.

### 3. Time vs. estimate

How did actual effort compare to the size estimates in the plan doc? If they diverged significantly, what caused the gap?

**References:** Size/effort estimates in the plan doc (`docs/working/`).

### 4. What to change

Knowing what you know now, what would you do differently — in the plan, the process, or the code?

**References:** Review findings from [`/code-review`](../workflows/pr-prep.md) and [`/self-eval`](../workflows/pr-prep.md) artifacts (typically in `docs/reviews/`).
