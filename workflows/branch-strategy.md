---
value-justification: "Replaces ad-hoc branch management with a structured strategy for high-throughput async development, preventing merge conflicts and lost work."
---

# Branch Strategy Guide

## Overview

This strategy is designed for a workflow where:
- One developer produces many features per day (10+), often interdependent
- A reviewer in a different timezone approves PRs in batches
- Features need to be tested together before any individual PR is merged to main

The model: **dev is a disposable integration branch. Features branch off main. PRs target main via squash-merge. Main flows forward into dev via merge (not rebase).**

## Branch roles

**main** — The reviewed, approved codebase. Only receives squash-merged PRs that have passed review. Never commit directly to main.

**dev** — Your working integration branch. All features merge here first so you can test them together. Dev is always ahead of main. Its commit history will be messy — that's fine, it's not the source of truth for history. The PRs are.

**feat/\*** — Individual feature branches. Branch off main, develop on the branch, open a PR to main when ready for review.

## Branch structure

```
main          ← stable, production-ready
  ├── feat/feature-a   (branched off main)
  ├── feat/feature-b   (branched off main)
  └── dev              ← integration branch, features merged here for testing
```

## Rules

1. **Feature branches always branch off `main`**, not `dev`. This keeps them independent and reviewable.
2. **Never commit directly to `dev`** — only merge feature branches in.
3. **Resolve conflicts on `dev`**, not on feature branches. Feature branches stay clean.
4. **`dev` is disposable.** If it gets too messy, delete and recreate it from `main` + re-merge all active feature branches.
5. **Merge `main` into `dev`** periodically to keep it current after PRs land on main.

## Daily workflow

### Starting a feature
```bash
git checkout main && git pull
git checkout -b feat/my-feature
```

**Done when...**
- [ ] The feature branch is created from an up-to-date `main` (not from `dev` or another feature branch)
- [ ] The branch name follows the `feat/` prefix convention

### Working on the feature
Follow the research-plan-implement workflow. Commit frequently on the feature branch. When the feature is working:

```bash
# Merge into dev for integration testing
git checkout dev
git merge feat/my-feature --no-edit
# Test everything together on dev
npm run build && npm run lint
```

If a feature branch has conflicts with dev, resolve them during the merge into dev. The feature branch itself stays untouched.

**Done when...**
- [ ] The feature branch is merged into `dev`
- [ ] Build and lint pass on `dev` after the merge
- [ ] Any merge conflicts were resolved on `dev`, not on the feature branch
- [ ] The feature branch itself has no merge commits from `dev`

### Opening a PR
When ready for review, push the feature branch and open a PR targeting main:

```bash
git checkout feat/my-feature
git push -u origin feat/my-feature
```

The PR diff will show your feature's changes relative to main. The reviewer sees a clean, focused changeset even though dev has many other commits.

**Done when...**
- [ ] The feature branch is pushed to origin
- [ ] A PR is open targeting `main` (not `dev`)
- [ ] The PR diff shows only this feature's changes relative to `main`

### After PRs are approved and merged to main

When your coworker approves and merges PRs (typically in a batch during their work day):

```bash
# Pull updated main
git checkout main && git pull

# Merge main INTO dev (not rebase)
git checkout dev
git merge main --no-edit

# Delete merged feature branches
git branch -d feat/landed-feature
git push origin --delete feat/landed-feature
```

**Why merge, not rebase:** Squash-merge on the PR destroys the original commit identities. If you rebase dev onto main, git tries to replay commits whose content is already on main (via the squash), producing phantom conflicts. Merge avoids this — git recognizes the integrated work and merges cleanly.

The merge commit is noise in dev's history, but dev's history is already noisy. The clean history lives in the PRs.

**Done when...**
- [ ] `main` is pulled and up to date
- [ ] `main` is merged into `dev` (not rebased)
- [ ] Merged feature branches are deleted locally and remotely

### Continuing work after merging main into dev

After merging main into dev, your existing feature branches are still based on main — which is fine. Since features branch off main, they stay independent.

**If you need the latest main changes on your feature branch:**
```bash
git checkout feat/my-feature
git rebase main
```

## Handling many feature branches (10+)

With high feature output, some practical patterns:

**Don't keep stale branches.** Once a PR is merged, delete the feature branch locally and remotely.

**Batch your PR openings.** Rather than opening 10 individual PRs, consider grouping related features into 3-4 larger PRs at end of day. This is a tradeoff — larger PRs are harder to review but reduce the reviewer's context-switching. Given a timezone offset, 3-4 well-described PRs are easier to process overnight than 10 small ones.

**Name branches to indicate dependency.** If feat/B depends on feat/A, name them to make it clear: `feat/auth-1-model`, `feat/auth-2-api`, `feat/auth-3-ui`. In the PR description, note "depends on #N, review after that merges."

**Check for subset relationships.** Before merging a feature into dev, check if one branch already contains another's commits:
```bash
git merge-base --is-ancestor feat/branch-a feat/branch-b
```
If branch A is an ancestor of branch B, you only need to merge B.

**Periodically verify dev ↔ main divergence.** If the gap gets very large (50+ unmerged commits), it's worth checking:
```bash
git log --oneline main..dev | wc -l
```
A large gap means merge conflicts become more likely and PRs become harder to review. If the gap is growing faster than review can close it, discuss review cadence with your coworker.

## Setting up or resetting dev

If dev gets stale, broken, or tangled, recreate it from scratch:

```bash
git checkout main && git pull
git checkout -b dev-new main

# Merge only the feature branches that are still active
git merge feat/active-a --no-edit
git merge feat/active-b --no-edit
# Resolve conflicts at each step if needed

# Replace dev
git branch -D dev
git branch -m dev-new dev
git push --force-with-lease origin dev
```

This is disruptive (anyone else with dev checked out needs to reset), so use sparingly.

## Stale-branch triage (advisory)

When a feature branch has gone more than 7 days without a merge or rebase, run a quick self-check. **This is advisory, not a process gate** — nothing in this workflow refuses to merge or open a PR for a stale branch. The trigger exists because branches that quietly accumulate for weeks tend to be the ones that produce phantom conflicts, get re-discovered as duplicates of newer work, or stay open after the underlying need has changed. A 60-second check is cheaper than rebasing a month-old branch onto a moved main.

Use `git for-each-ref --sort=-committerdate refs/heads/feat/* --format='%(committerdate:relative) %(refname:short)'` to see which feature branches are oldest.

For each branch past the 7-day mark, answer three questions:

1. **Still relevant?** — Does the feature still match current priorities? Has the underlying problem changed, been solved another way, or been deprioritized?
2. **Still owner?** — Am I still the right person to land this, or has someone else picked it up (or should they)?
3. **Still highest priority?** — Compared to the other branches I'm carrying right now, is this one I'd actually pick up next?

Pick one of three outcomes:

- **Action** — Rebase onto main and either merge into dev or open the PR now. Activity resets the implicit clock. Use this when all three answers are yes.
- **Defer** — Close the PR (if open), delete the branch, and capture the work as an issue or note so it isn't lost. Use this when "still relevant?" or "still owner?" is no. Deferring is not failure; it's freeing the branch list for the work you're actually doing.
- **Mark watching** — Explicitly accept "do nothing this week." Refresh the date stamp with an empty commit so the branch's stalled state is documented as intentional, not forgotten:
  ```bash
  git commit --allow-empty -m "chore: still watching feat/my-feature"
  ```
  Use this when the work is genuinely paused (waiting on a dependency, a decision, or a planned later milestone) and you want it to stay parked without auto-triggering the triage next week.

The point of the third outcome is that "I checked and the right answer is to wait" is a valid answer. The triage exists to make stale-branch state visible, not to force premature defer-or-merge decisions.

## Quick reference

| Action | Command |
|---|---|
| Start a feature | `git checkout -b feat/name main` |
| Integrate feature for testing | `git checkout dev && git merge feat/name --no-edit` |
| Open PR | Push feature branch, PR targets main |
| After PRs merge to main | `git checkout dev && git merge main --no-edit` |
| Delete merged branch | `git branch -d feat/name && git push origin --delete feat/name` |
| Check dev divergence | `git log --oneline main..dev \| wc -l` |
| Check branch subset | `git merge-base --is-ancestor feat/a feat/b` |
| Reset dev | Delete dev, create from main, re-merge active features |
| List feature branches by age | `git for-each-ref --sort=-committerdate refs/heads/feat/* --format='%(committerdate:relative) %(refname:short)'` |
| Keep a paused branch parked | `git commit --allow-empty -m "chore: still watching feat/name"` |
