# PR Preparation Workflow

*The self-review and cleanup steps follow the [orchestrated review pattern](../patterns/orchestrated-review.md), with commits/files as the units of review.*

## When to use
Before opening any pull request, especially when the reviewer is in a different timezone or unfamiliar with the libraries used.

## Process

The process has two phases: **content** (is the code right?) and **packaging** (is the PR presentable?). Complete Phase 1 before starting Phase 2 — packaging work gets thrown away if content issues force a split or architectural rethink.

See [decision 007](../docs/decisions/007-two-phase-pr-prep.md) for why this ordering was chosen.

### Phase 1: Content

#### 1. Gate checks

Run these concurrently — both are fast, and either failing changes the plan:

**a. Size check.** If the PR exceeds ~500 lines changed, consider whether it can be split before doing any other prep work. Look for:
- A preparatory refactor that can land independently
- Infrastructure/model changes separate from UI changes
- A minimal first PR that adds the feature behind a flag, with polish in a follow-up

If it genuinely can't be split, note this in the PR description (step 6) and suggest a review order for the files.

**b. Dependent PR check.** If this branch builds on other unmerged PRs, verify they've been merged or that this PR's base is set correctly. If dependencies haven't landed, decide whether to wait, rebase onto a dev integration branch, or open as a stacked PR with a clear note. Skip this check for standalone branches.

**Completion criteria:**
- [ ] PR is under 500 lines changed, OR PR description includes size justification and suggested file review order
- [ ] No unmerged dependency PRs block this branch, OR base is set correctly for stacking

#### 2. Open draft PR

Push the branch and open a draft PR. This serves two purposes:
- CI starts running in parallel with your review-fix work (saves waiting at step 5a)
- Reviewers in other timezones get async visibility into in-progress work

Skip if the project doesn't use CI or if you're the sole contributor and prefer to push later.

#### 3. Review-fix loop

Run review skills and iterate until clean. This is required, not optional.

**a. Generate reviews.** Run skills in parallel; perform manual checks while waiting for results:
- **Code review** (`/code-review`) — multi-critic structural review of the diff vs main
- **Self-eval** (`/self-eval <target>`) — rubric assessment of any new or modified skills/workflows
- **Documentation check** (manual) — if the PR changes public APIs, config options, or user-facing behavior, verify corresponding docs are updated (README, inline docs, decision records). Skip for internal refactors with no external surface.
- **Dependency audit** (manual) — if the PR introduces or upgrades dependencies, check license compatibility, package size, and maintenance status. Flag unmaintained or unfamiliar packages. Skip if no dependency changes.

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

**Completion criteria:**
- [ ] Review artifacts exist in `docs/reviews/` for each review skill run
- [ ] No Must Fix findings remain open
- [ ] All Must Address findings are resolved or explicitly acknowledged in the PR description
- [ ] Final review loop introduced no new Must Fix or Must Address findings
- [ ] Review artifacts committed to the branch (see [PR Review Doc Inclusion guide](../guides/pr-review-doc-inclusion.md))

### Phase 2: Packaging

#### 4. Clean up commit history

```bash
git rebase -i origin/main
```

Squash WIP commits into logical chunks. Each commit in the final history should represent one coherent change that could be reviewed independently. Good commit sequence for a feature:

1. `feat: add data model for X` (reviewable alone)
2. `feat: add API endpoint for X` (builds on 1, reviewable with context)
3. `feat: add UI for X` (builds on 1-2)
4. `test: add tests for X` (or interleaved with the above)

**Completion criteria:**
- [ ] No WIP, fixup, or squash commits remain in the branch
- [ ] Each commit message follows conventional format (`feat:`, `fix:`, `refactor:`, etc.)
- [ ] Each commit represents one coherent, independently reviewable change

#### 5. Verify and annotate (parallelizable)

These two steps have no dependency on each other and can run concurrently.

**a. Verify CI passes.** Run whatever checks the project has: lint, build, tests. This runs on the rebased, reviewed code — the final form the reviewer will see. Fix anything broken. If you opened a draft PR in step 2, push the rebased branch to trigger CI remotely.

**b. Annotate the diff.** If the PR includes code in languages or libraries the reviewer may not know well, add **PR comments on your own PR** explaining non-obvious sections. This is cheaper than back-and-forth across timezones.

**Completion criteria:**
- [ ] All project checks pass (lint, build, tests)
- [ ] No new warnings introduced (for projects that treat warnings as errors)
- [ ] If PR uses unfamiliar libraries or patterns, at least one explanatory PR comment exists
- [ ] If no unfamiliar code, annotation step is explicitly skipped (not forgotten)

#### 6. Write the PR description

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

For UI changes, capture before/after screenshots or a short recording and include them in the description. The reviewer may not be able to run the UI locally — visual evidence eliminates a round-trip.

**Completion criteria:**
- [ ] All five sections are present (What this does, How it works, How to test, Areas of uncertainty, Decisions made)
- [ ] Each section contains at least one substantive sentence (not a placeholder)

## Retrospective

After the PR is opened, take 2 minutes to close the loop on the workflow that produced it. Answer these in `docs/thoughts/` or a commit message — they compound over time.

1. **Plan vs. reality** — How closely did the implementation follow the plan? Where did it deviate, and was the deviation an improvement or a sign the plan missed something?
2. **Skipped steps** — Were any workflow steps skipped or abbreviated? Why, and was that the right call in hindsight?
3. **Surprises** — What was unexpected — in the codebase, the tooling, the requirements, or the review feedback? What would have helped you anticipate it?
4. **Next time** — Knowing what you know now, what would you do differently in the plan, the process, or the code?

**Completion criteria:**
- [ ] At least one of the four questions answered with more than one sentence
- [ ] Answer stored in `docs/thoughts/` or a commit message (not lost)
