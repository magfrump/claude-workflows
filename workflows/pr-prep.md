# PR Preparation Workflow

*The self-review and cleanup steps follow the [orchestrated review pattern](../patterns/orchestrated-review.md), with commits/files as the units of review.*

## When to use
Before opening any pull request, especially when the reviewer is in a different timezone or unfamiliar with the libraries used.

## Process

> **Tiers:** (essential) = every time · (recommended) = most tasks · (advanced) = complex or high-stakes work

### 1. Clean up commit history (recommended)

```bash
git rebase -i origin/main
```

Squash WIP commits into logical chunks. Each commit in the final history should represent one coherent change that could be reviewed independently. Good commit sequence for a feature:

1. `feat: add data model for X` (reviewable alone)
2. `feat: add API endpoint for X` (builds on 1, reviewable with context)
3. `feat: add UI for X` (builds on 1-2)
4. `test: add tests for X` (or interleaved with the above)

### 2. Verify CI passes locally (essential)

Run whatever checks the project has: lint, build, tests. Fix anything broken. Do not leave this for the reviewer to discover.

### 3. Review-fix loop (advanced)

Run review skills and iterate until clean. This is required, not optional.

**a. Generate reviews.** Run in parallel:
- **Code review** (`/code-review`) — multi-critic structural review of the diff vs main
- **Self-eval** (`/self-eval <target>`) — rubric assessment of any new or modified skills/workflows

**b. Triage and fix.** Read each review artifact. Work through findings in tier order:

| Tier | Meaning | Action |
|------|---------|--------|
| Must Fix | Correctness bugs, false passes, wrong behavior | Fix before proceeding |
| Must Address | Fragility, inconsistency, misleading tests | Fix or explicitly acknowledge |
| Consider | Style, duplication, future-proofing | Fix if cheap, otherwise note for later |

For each finding: confirm it's real by reading the code, then fix. Commit in coherent batches referencing finding IDs (e.g., `fix: Address code review findings A2-A5`).

**c. Run tests.** After fixing findings, re-run the test suite. Fixes often surface latent bugs — a tightened assertion may expose a helper bug, a scoping fix may reveal a silent false pass. Fix test breakage as separate commits.

**d. Re-review.** Run the same review skills again. Compare against prior findings: are they resolved? Did fixes introduce new ones? Did reviewers surface issues previously masked?

**e. Exit or repeat.** Exit when no Must Fix items remain and Must Address items are resolved or explicitly acknowledged. Repeat if new findings appear. Each loop should be strictly smaller than the last — if findings aren't converging after 3-4 loops, the problem is architectural (use divergent-design or RPI, not more review loops).

See `workflows/review-fix-loop.md` for extended discussion of loop dynamics and anti-patterns.

### 4. Write the PR description (essential)

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

### 5. Annotate the diff (advanced)

If the PR includes code in languages or libraries the reviewer may not know well, add **PR comments on your own PR** explaining non-obvious sections. This is cheaper than back-and-forth across timezones.

### 6. Size check (recommended)

If the PR exceeds ~500 lines changed, consider whether it can be split. Look for:
- A preparatory refactor that can land independently
- Infrastructure/model changes separate from UI changes
- A minimal first PR that adds the feature behind a flag, with polish in a follow-up

If it genuinely can't be split, note this in the PR description and suggest a review order for the files.

## Appendix: Post-PR Reflection

See [`guides/post-pr-retrospective.md`](../guides/post-pr-retrospective.md) for reflection questions, timing guidance, and links to referenced artifacts.
