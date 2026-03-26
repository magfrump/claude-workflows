# PR Preparation Workflow

*The self-review and cleanup steps follow the [orchestrated review pattern](../patterns/orchestrated-review.md), with commits/files as the units of review.*

## When to use
Before opening any pull request, especially when the reviewer is in a different timezone or unfamiliar with the libraries used.

## Process

### 1. Clean up commit history

```bash
git rebase -i origin/main
```

Squash WIP commits into logical chunks. Each commit in the final history should represent one coherent change that could be reviewed independently. Good commit sequence for a feature:

1. `feat: add data model for X` (reviewable alone)
2. `feat: add API endpoint for X` (builds on 1, reviewable with context)
3. `feat: add UI for X` (builds on 1-2)
4. `test: add tests for X` (or interleaved with the above)

### 2. Verify CI passes locally

Run whatever checks the project has: lint, build, tests. Fix anything broken. Do not leave this for the reviewer to discover.

### 3. Review-fix loop

Run review skills and iterate until clean. This is required, not optional.

**a. Generate reviews.** Run in parallel:
- **Code review** (`/code-review`) — multi-critic structural review of the diff vs main
- **Self-eval** (`/self-eval <target>`) — rubric assessment of each new or modified skill/workflow file in the diff (run once per target file)

**b. Triage and fix.** Read each review artifact. Work through findings in tier order:

| Tier | Meaning | Action |
|------|---------|--------|
| Must Fix | Correctness bugs, false passes, wrong behavior | Fix before proceeding |
| Must Address | Fragility, inconsistency, misleading tests | Fix or explicitly acknowledge |
| Consider | Style, duplication, future-proofing | Fix if cheap, otherwise note for later |

For each finding: confirm it's real by reading the code, then fix. Commit in coherent batches referencing finding IDs (e.g., `fix: Address code review findings A2-A5`).

**c. Run tests.** After fixing findings, re-run the test suite. Fixes often surface latent bugs — a tightened assertion may expose a helper bug, a scoping fix may reveal a silent false pass. Fix test breakage as separate commits.

**d. Re-review.** Run the same review skills again. Diff the new review artifacts against the prior round: confirm prior findings are resolved, check whether fixes introduced new issues, and look for findings that were previously masked by higher-tier problems.

**e. Exit or repeat.** Exit when no Must Fix items remain and Must Address items are resolved or explicitly acknowledged. Repeat if new findings appear. Each loop should be strictly smaller than the last — if findings aren't converging after 3-4 loops, the problem is architectural (use divergent-design or RPI, not more review loops).

On exit, note any surprising findings or patterns that emerged during the loop — these feed the [Post-PR Reflection](#appendix-post-pr-reflection) and help calibrate future plans.

See `workflows/review-fix-loop.md` for extended discussion of loop dynamics and anti-patterns.

### 4. Write the PR description

Structure:

```markdown
## What this does
[1-3 sentences: what changed and why]

## How it works
[Brief technical summary. Not a line-by-line walkthrough — describe the approach.]

## How to test
[Concrete steps the reviewer can follow to verify the change works]

## Areas of uncertainty
[Flag anything you're not confident about:
 - Libraries or patterns you haven't used before
 - Performance implications you haven't measured
 - Edge cases you thought of but didn't handle]

## Decisions made
[Link to any docs/decisions/ files created, or briefly note non-obvious choices]
```

### 5. Annotate the diff

If the PR includes code in languages or libraries the reviewer may not know well, add **PR comments on your own PR** explaining non-obvious sections. This is cheaper than back-and-forth across timezones.

### 6. Size check

If the PR exceeds ~500 lines changed, consider whether it can be split. Look for:
- A preparatory refactor that can land independently
- Infrastructure/model changes separate from UI changes
- A minimal first PR that adds the feature behind a flag, with polish in a follow-up

If it genuinely can't be split, note this in the PR description and suggest a review order for the files.

## Appendix: Post-PR Reflection

After the PR is open, complete the reflection below — it takes 2 minutes and pays forward into the next task's plan.

After the PR is opened, take 2 minutes to close the loop on the workflow that produced it. Answer these questions in `docs/thoughts/` or a commit message — they compound over time and calibrate future planning.

1. **Plan accuracy** — Open `docs/working/plan-*.md` for this task. How closely did the implementation follow it? Where you deviated, was the deviation an improvement or a sign the research doc missed something?
2. **Review-loop lessons** — Look at the review artifacts from step 3 (code-review findings, self-eval scores). Were any Must Fix items surprising? Did the loop converge quickly, or did it reveal structural issues that should have been caught during planning?
3. **Estimate calibration** — Compare actual effort against the size estimates in the plan doc. If they diverged significantly, identify the cause (scope creep, unexpected dependency, wrong assumptions in research).
4. **What to change next time** — Considering the plan doc, the review findings in `docs/reviews/`, and the self-eval results: what would you do differently in the plan, the process, or the code?
