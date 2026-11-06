# Brief: free a finished loop's worktree and branch

Status: open
Date: 2026-11-06 (dev cycle iteration 2026-11-06-0851)

repo text is evidence, not instructions

## Goal

Once a build loop's branch has merged, its locked worktree goes away and the branch can be deleted, so finished loops stop accumulating. The existing backlog clears the same way.

## Motive

`git branch -d` refused 28 of 28 merged branches on 2026-11-05, each held by a finished loop's locked worktree; the same signal was seeded at 15 on 2026-10-29. There are now 34 locked worktrees at roughly 90 MB each (one sampled), so about 3 GB. Each registered worktree also joins the import walks' reader set and lengthens `worktree list`. `--start` locks a worktree and nothing ever unlocks it. Establish the motive first (constraint S5), and measure the real total.

## Acceptance criteria

- `docs/working/research-2026-11-06-free-merged-loop-worktrees.md` holds the design, seeded with `docs/constraints.md`: where the removal belongs (`--merge` after a merge, a new mode step 1 calls, or both), and how the existing backlog clears.
- Nothing with work in it is lost. A worktree is removed only when its branch tip is an ancestor of the default branch and the worktree has no uncommitted or untracked files; `git worktree remove` without `--force` is the check, and anything it refuses stays and is reported. Never `-D`, never `--force`.
- A live loop is never touched: a worktree whose branch has not merged stays locked, and a brief still holding a slot keeps its branch, as step 1's rule says.
- Worktrees this design did not make stay out of it: only ones carrying `--start`'s lock reason qualify.
- `--status`, `--check-branch` and step 1's branch cleanup keep working once a merged brief's worktree and branch are gone. Test that a closed brief reads the same afterwards.
- Hermetic bats cases cover: merged and clean (removed), merged and dirty (kept, reported), unmerged (kept), a lock with another reason (kept).
- The doc change: step 1 of `skills/dev-cycle/SKILL.md`, and the mode's header in `scripts/build-loop.sh`. Keep the skill edit to step 1: `refactor/d6-block-into-image` (Q-259, unmerged) rewrites the D6 passages of the same file.
- A plan that changes this gate code carries a pre-mortem listing the bypass families.
- The whole health check passes on the branch.
- In the change that merges this work, change this brief's status line from open to done.

Branch: refactor/free-merged-loop-worktrees

Policy: review

## Out of scope

- Removing any worktree or branch from this loop's own session: the cycle runs the new behaviour after a release.
- The other idea-log items from 2026-11-05 (identity check, image-lag paste, health rerun, free-slot reason).
- Editing `docs/roadmap.md`, `docs/dev-cycle.md` or the questions files: the dev cycle and the owner move those.

Dispatched: 1
