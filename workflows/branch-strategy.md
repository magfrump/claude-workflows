# Branch Strategy Guide

## Overview

This strategy is designed for a workflow where:
- One developer produces many features per day (10+), often interdependent
- A reviewer in a different timezone approves PRs in batches
- Features need to be tested together before any individual PR is merged to main

The model: **dev is a rolling integration branch. Features branch off dev. PRs merge to main via squash-merge. Main flows forward into dev via merge (not rebase).**

## Branch roles

**main** — The reviewed, approved codebase. Only receives squash-merged PRs that have passed review. Never commit directly to main.

**dev** — Your working integration branch. All features merge here first so you can test them together. Dev is always ahead of main. Its commit history will be messy — that's fine, it's not the source of truth for history. The PRs are.

**feat/\*** — Individual feature branches. Branch off dev, develop on the branch, open a PR to main when ready for review. Keep the PR's commit history clean (interactive rebase before opening the PR).

## Daily workflow

### Starting a feature
```bash
git checkout dev && git pull
git checkout -b feat/my-feature dev
```

### Working on the feature
Follow the research-plan-implement workflow. Commit frequently on the feature branch. When the feature is working:

```bash
# Merge into dev for integration testing
git checkout dev
git merge feat/my-feature
# Test everything together on dev
npm run build && npm run lint
```

### Opening a PR
When ready for review, clean up the feature branch history and open a PR targeting main:

```bash
git checkout feat/my-feature
# Clean up commits for the reviewer
git rebase -i dev
# Push and open PR against main
git push -u origin feat/my-feature
```

The PR diff will show your feature's changes relative to main. The reviewer sees a clean, focused changeset even though dev has 50 other commits.

### After PRs are approved and merged to main

When your coworker approves and merges PRs (typically in a batch during their work day):

```bash
# Pull updated main
git checkout main && git pull

# Merge main INTO dev (not rebase)
git checkout dev
git merge main
```

**Why merge, not rebase:** Squash-merge on the PR destroys the original commit identities. If you rebase dev onto main, git tries to replay commits whose content is already on main (via the squash), producing phantom conflicts. Merge avoids this — git recognizes the integrated work and merges cleanly.

The merge commit is noise in dev's history, but dev's history is already noisy. The clean history lives in the PRs.

### Continuing work after merging main into dev

After merging main into dev, your existing feature branches may be based on an older dev. You have two options:

**If the feature branch has no conflicts with new main content** (common): Just keep working. The PR diff against main will be correct regardless.

**If you need the latest main changes on your feature branch:**
```bash
git checkout feat/my-feature
git rebase dev
# or, if you just want the specific new content:
git merge dev
```

## Handling many feature branches (10+)

With high feature output, some practical patterns:

**Don't keep stale branches.** Once a PR is merged, delete the feature branch locally and remotely:
```bash
git branch -d feat/merged-feature
git push origin --delete feat/merged-feature
```

**Batch your PR openings.** Rather than opening 10 individual PRs, consider grouping related features into 3-4 larger PRs at end of day. This is a tradeoff — larger PRs are harder to review but reduce the reviewer's context-switching. Given a timezone offset, 3-4 well-described PRs are easier to process overnight than 10 small ones.

**Name branches to indicate dependency.** If feat/B depends on feat/A, name them to make it clear: `feat/auth-1-model`, `feat/auth-2-api`, `feat/auth-3-ui`. In the PR description, note "depends on #N, review after that merges."

**Periodically verify dev ↔ main divergence.** If the gap gets very large (50+ unmerged commits), it's worth checking:
```bash
git log --oneline main..dev | wc -l
```
A large gap means merge conflicts become more likely and PRs become harder to review. If the gap is growing faster than review can close it, discuss review cadence with your coworker.

## Resetting dev (emergency procedure)

If dev gets into a bad state (botched merges, tangled conflicts), you can recreate it:

```bash
# Start fresh from main
git checkout main && git pull
git checkout -b dev-new main

# Cherry-pick or merge only unmerged feature branches
git merge feat/unmerged-1
git merge feat/unmerged-2
# ...

# Replace dev
git branch -D dev
git branch -m dev-new dev
git push --force-with-lease origin dev
```

This is disruptive (anyone else with dev checked out needs to reset), so use sparingly.

## Quick reference

| Action | Command |
|---|---|
| Start a feature | `git checkout -b feat/name dev` |
| Integrate feature for testing | `git checkout dev && git merge feat/name` |
| Open PR | Clean up with `git rebase -i dev`, push, PR targets main |
| After PRs merge to main | `git checkout dev && git merge main` |
| Delete merged branch | `git branch -d feat/name && git push origin --delete feat/name` |
| Check dev divergence | `git log --oneline main..dev \| wc -l` |