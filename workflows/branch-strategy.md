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

## Conflict prevention

Before starting a new feature branch, scan open feature branches for file overlap. Heavy overlap is a strong signal to sequence rather than parallelize — two branches editing the same files will conflict on merge into `dev`, and resolving those conflicts cancels out the parallelism gains.

**Check overlap with an existing feature branch:**
```bash
git diff --name-only main..feat/existing-feature
```

**Scan all open feature branches at once:**
```bash
for b in $(git branch --list 'feat/*' | tr -d ' *'); do
  echo "=== $b ==="; git diff --name-only main..$b;
done
```

**Heuristics:**
1. **No overlap** → parallelize freely.
2. **Light overlap** (1-2 shared files, different sections) → proceed with awareness; merge the more invasive branch first so the second rebases against settled code.
3. **Heavy overlap** (3+ shared files, or overlapping sections in the same file) → sequence: finish and merge one before starting the next, or combine them into a single feature branch.

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

This is disruptive (anyone else with dev checked out needs to reset), so use sparingly. The final
`git push --force-with-lease origin dev` replaces a shared branch in place — that pointer swap is a
**gated operation requiring explicit human approval** (see Operating Modes in CLAUDE.md), regardless
of away/active mode. When you want the rebuild to be inspected before it lands on the shared branch,
use the **Integration branch refresh** procedure below instead — it produces a fresh reviewable
branch rather than overwriting `dev`.

## Integration branch refresh

**The standard process for consolidating every open PR into one testable integration branch.** This is
a first-class procedure with the same standing as [research-plan-implement](research-plan-implement.md)
or [pr-prep](pr-prep.md): when the task is "pull all the in-flight work together and resolve the
conflicts," follow this named process rather than improvising a one-off merge each time.

It rebuilds the integration branch from the canonical set of in-flight work — **all open PRs** — in a
conflict-aware, reviewable way. Reach for it when `dev` has drifted far from the PRs (local branches
deleted, stale, or out of sync with what's actually under review), when phantom conflicts keep
recurring, or on a regular cadence to keep the integration branch honest. It is the heavier sibling of
the lightweight [Setting up or resetting dev](#setting-up-or-resetting-dev) reset above, which re-merges
only the *local* feature branches you happen to be carrying.

### When to use

This is the **standard process** for consolidating every in-flight PR into one testable branch — not
an ad-hoc merge to improvise each time. Route a request here whenever it asks to pull all the open
work together and resolve the conflicts. Trigger phrasings that should land on this procedure:

- "merge all open PRs"
- "build an integration branch"
- "integrate everything and resolve conflicts"
- "rebuild / refresh dev from the open PRs"
- "test all the open PRs together"

Each maps onto the numbered procedure below: enumerate the open PRs (step 1), build a fresh reviewable
branch off `main` (step 2), merge each PR head and resolve conflicts (steps 3–5), verify the
integrated branch (step 6), and promote only through the approval gate (step 7). If a request instead
names a small set of *local* feature branches to re-merge — rather than the canonical open-PR set —
use the lighter **Setting up or resetting dev** reset above.

The procedure is built around four failure-driven invariants (see *Why this shape* below). Keep them
in mind as you run the steps — every step exists to uphold one of them.

### Procedure

**1. Enumerate all open PRs.** The open PRs — not your local branch list — are the source of truth for
what's in flight. Local branches lie (deleted after a stale checkout, never fetched, renamed).

```bash
gh pr list --state open --json number,headRefName,baseRefName,title \
  --jq '.[] | "\(.number)\t\(.headRefName)\t\(.title)"'
```

Record the list. This is the set you are integrating.

**2. Build on a fresh, reviewable branch — never in place.** Create a new integration branch off an
up-to-date `main`, named so the *previous* integration branch is preserved untouched for reference
(pass the date in; don't compute it):

```bash
git checkout main && git pull
git fetch origin
git checkout -b dev-refresh-<YYYY-MM-DD> main
```

Building fresh means the entire conflict resolution lands as an inspectable diff against `main`. The
existing shared `dev` is not touched, so nothing the team depends on moves until a human approves it.

**3. Merge each open PR's head branch in.** Go oldest-first, or in dependency order if branch names
encode it (`feat/auth-1-model` before `feat/auth-2-api`). Merge from the remote ref so you integrate
exactly what's under review, not a stale local copy:

```bash
git fetch origin <headRef>
git merge origin/<headRef> --no-edit
```

Merge one PR at a time and stop at the first conflict — resolve it (step 4) before moving on, so each
resolution is attributable to a single PR.

**4. Resolve conflicts using the prior integration branch as reference *only*.** When a hunk
conflicts, recover the intent of the earlier resolution from **two** sources — the resolved *code* and
the recorded *rationale*:

```bash
git show <previous-integration-branch>:<path>                 # what the hunk resolved to last time
grep -n -A8 '<path>' docs/working/integration-conflicts.md    # why it was resolved that way
```

`git show` returns the resolved code but not the reasoning; the rationale log
([`docs/working/integration-conflicts.md`](../docs/working/integration-conflicts.md)) records *why* —
which side was authoritative, what was intentionally dropped, and what would make the resolution go
stale. Read both, then **re-verify every hunk against the current content of both sides before
accepting it.** Prior resolutions go stale: a PR may have been revised after the last refresh, a branch
force-updated, a conflicting PR closed. Blind-applying an old resolution silently reintroduces dropped
changes or resurrects reverted ones. Treat the old resolution as a hint, re-derive the merge from the
two *current* sides, and confirm the result reflects both.

**Then record the rationale.** After resolving each conflict, append an entry to the rationale log so
the *next* refresh can recover your reasoning — not just your resulting code. Use the template in
[`docs/working/integration-conflicts.md`](../docs/working/integration-conflicts.md); keep the `path:`
line intact so the grep above finds it on the next build:

> ### \<YYYY-MM-DD> · dev-refresh-\<YYYY-MM-DD>
> - **path:** `<path>`  ·  **PR:** #\<n> `<headRef>`  ·  **region:** \<what conflicted>
> - **resolution:** \<what the hunk became>  ·  **rationale:** \<why this side / what was dropped>
> - **staleness signal:** \<what change to either side would make this resolution wrong>

The log entry is the durable complement to `git show`: the resolved code lives in the branch, the
reasoning behind it lives in the log. Without it, every refresh re-derives the same reasoning from
scratch (or replays it blind).

**5. Fold in PRs not yet on the previous integration branch.** Some open PRs are newer than the last
refresh and have no prior resolution to reference. After replaying the known set, merge these in and
resolve their conflicts from first principles:

```bash
# PR heads present now but absent from the previous integration branch:
# compare your enumerated list (step 1) against what the old branch already contained.
git merge origin/<new-headRef> --no-edit
```

Record a rationale entry (step 4) for each of these too, marking `origin: first-principles` since
there is no prior resolution to reference — the next refresh will then have the reasoning on hand.

**6. Verify the integrated branch.** Run the full build/lint/test on the fresh branch — this is the
first time all current PRs have been tested together.

```bash
npm run build && npm run lint   # plus the project's test command
```

**7. Promote only through the approval gate.** Push the fresh branch as its **own ref** and open it
for inspection. The conflict resolution is now a reviewable diff:

```bash
git push -u origin dev-refresh-<YYYY-MM-DD>
```

Do **not** force-push over the shared `dev` to swap it in. Replacing the team's integration branch
pointer is an irreversible-for-others operation and requires explicit human approval per the Operating
Modes gate — the same gate that governs force-push, `reset --hard`, and branch deletion. Until that
approval, the fresh branch stands alone as the reviewable artifact; it does not disrupt anyone with
the old `dev` checked out.

Because that promotion is the most irreversible-for-others action in this workflow, the request for
approval is not a bare "OK to swap `dev`?" — the prompt that asks for it must satisfy the
[requesting-user-input checklist](../patterns/requesting-user-input.md#the-checklist). And because the
action cannot be cleanly undone, its **error-recoverability** content is load-bearing (checklist §3,
"Using this pattern"): the prompt must name the point of no return explicitly. A conforming prompt:

> Integration refresh `dev-refresh-<YYYY-MM-DD>` is built and green. Promoting it means force-pushing
> over the shared `dev`, which moves the branch every teammate has checked out and discards the
> resolution currently on `dev`. Pick one:
>   - **Promote now (force-push `dev`)** → I run `git push --force-with-lease origin dev` pointing
>     `dev` at the refresh; the old `dev` tip leaves the shared ref.
>   - **Keep as a separate ref** → nothing is force-pushed; `dev-refresh-<YYYY-MM-DD>` stays up for
>     review and the team's `dev` is left untouched.
>   - **Abort — something's off** → tell me what to change; nothing is pushed.
>
> This force-push cannot be cleanly undone: teammates with `dev` checked out must reset to the new
> tip, and the previous `dev` history survives only in local reflogs. Capture the current tip
> (`git rev-parse origin/dev`) first if you want a recovery point.

The prompt carries all three checklist properties: the three named options are the **signifier**; each
option's "→ I run… / nothing is pushed" clause is the **conceptual model**; and the closing "cannot be
cleanly undone… capture the current tip first" sentence is the load-bearing **error-recoverability**
content naming the point of no return. The human picking **Promote now** is the explicit approval the
Operating Modes gate requires — the prompt is how that approval is solicited, not a relaxation of the
gate.

### Why this shape (failure-driven)

Each rule below exists because the naive version of this procedure has burned someone:

- **Never force-push over shared branches outside the approval gate.** Rebuilding by force-pushing
  `dev` in place silently rebases everyone else's checkout and destroys the old resolution before
  anyone can compare against it. The refresh instead produces a *new* branch; the shared-pointer swap
  is gated on human approval (Operating Modes), not done automatically — even in `/away` mode.
- **Prior resolutions are reference only.** The previous integration branch is a memory aid, not a
  patch to replay. Branches and PRs change between refreshes, so a resolution that was correct last
  week can drop or resurrect changes this week. Every hunk is re-verified against both current sides.
- **Build on a fresh reviewable branch.** Doing the merge on a throwaway, date-stamped branch makes
  the conflict resolution an inspectable diff *before* anything lands. A reviewer (or you, later) can
  audit exactly how each conflict was resolved instead of trusting an in-place mutation.
- **Rationale outlives code.** `git show <previous-integration-branch>:<path>` recovers *what* a hunk
  resolved to, never *why*. The next refresh then either blind-applies a now-stale resolution or
  re-derives reasoning that was already done. Recording each resolution's rationale in
  [`docs/working/integration-conflicts.md`](../docs/working/integration-conflicts.md) — and grepping
  it before resolving — makes the *intent* recoverable: authoritative side, intentionally dropped
  changes, and the staleness signal that says when to distrust it. The code reference and the
  rationale log are complements, keyed on the same `<path>`.

**Done when...**
- [ ] All open PRs were enumerated from `gh pr list` (not from the local branch list)
- [ ] The refresh was built on a fresh, date-stamped branch off `main`; the previous integration branch is untouched and available for reference
- [ ] Each open PR head was merged in; conflicts were resolved by re-verifying each hunk against both current sides, using the prior integration branch only as a reference
- [ ] Before resolving each conflict, `docs/working/integration-conflicts.md` was grepped for the path's prior rationale; after resolving, a new entry (path, resolution, why, staleness signal) was appended
- [ ] PRs absent from the previous integration branch were folded in and resolved from first principles (their rationale entries marked `origin: first-principles`)
- [ ] Build, lint, and tests pass on the fresh branch
- [ ] The fresh branch was pushed as its own ref for inspection; the shared `dev` was **not** force-pushed without explicit human approval
- [ ] If promotion over the shared `dev` was requested, the approval prompt satisfied the [requesting-user-input checklist](../patterns/requesting-user-input.md#the-checklist) — it named the available actions (signifier), stated what force-pushing `dev` would change (conceptual model), and made the irreversibility load-bearing: that the force-push cannot be cleanly undone and how to capture a recovery point first (error recoverability)

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
| Reset dev (lightweight, gated force-push) | Delete dev, create from main, re-merge active features |
| Integration branch refresh (PR-driven, reviewable) — triggers: "merge all open PRs", "build an integration branch", "integrate everything and resolve conflicts" | `gh pr list --state open`, fresh `dev-refresh-<date>` off main, merge each PR head, verify, push as new ref |
| List open PRs to integrate | `gh pr list --state open --json number,headRefName,baseRefName,title` |
| Reference a prior conflict resolution | `git show <previous-integration-branch>:<path>` (the resolved *code* — reference only, re-verify each hunk) |
| Recover *why* a hunk was resolved before | `grep -n -A8 '<path>' docs/working/integration-conflicts.md` (the *rationale* — pairs with `git show`) |
| Record a conflict resolution's rationale | Append an entry to `docs/working/integration-conflicts.md` (path, resolution, why, staleness signal) |
| List feature branches by age | `git for-each-ref --sort=-committerdate refs/heads/feat/* --format='%(committerdate:relative) %(refname:short)'` |
| Keep a paused branch parked | `git commit --allow-empty -m "chore: still watching feat/name"` |
