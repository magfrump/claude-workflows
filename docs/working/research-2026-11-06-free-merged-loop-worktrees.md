# Research: free a finished loop's worktree and branch

- **Goal**: Once a build loop's branch has merged, its locked worktree goes away so step 1's `git branch -d` can delete the branch, and the existing backlog clears the same way.
- **Problem framing**: `--start` locks a worktree and nothing ever unlocks it, so every finished loop leaves about 90 MB, a registered worktree and an undeletable branch behind. Considered and discarded: "the branch cleanup in step 1 is broken": `branch -d` is right to refuse a checked-out branch, and loosening it would be the wrong fix.
- **Project state**: delivers a `--free-worktrees` mode and step 1's call to it · standalone (dev cycle iteration 2026-11-06-0851) · not blocked (cite: docs/working/briefs/2026-11-06-free-merged-loop-worktrees.md)
- **Task status**: complete (implemented; review-fix loop closed, see docs/reviews/code-review-rubric-2026-11-06-refactor-free-merged-loop-worktrees.md)

## Motive, measured (S5)

On 2026-11-06, read from `git worktree list --porcelain` and `du` on `/workspace` [observed]:

- 38 registered worktrees; 35 carry `--start`'s lock reason, 3 do not (`/workspace`, `wt-q096b`, the q125 one).
- Of the 35: 32 have a merged branch and a closed `done` brief, and all 32 are clean (`git status --porcelain` empty). They hold 2.85 GiB. The other 3 are live or unmerged: `2026-11-03-q125-verify-check` (blocked), `2026-11-05-d6-block-into-image` (ready, unmerged), and this loop's own.
- The disk is 86% full, so 2.85 GiB alone is not urgent. The real cost is the merged branches `branch -d` refuses every cycle. The brief also names the import walks' reader set, but brief 2026-11-03-import-walk-plain ended that: no walk reads the worktree list now, only `--merge` and dispatch do. The motive holds; it is housekeeping, not an emergency.

## What exists

- `dispatch()` in `scripts/build-loop.sh`: `--start` makes the branch at main's commit and `git worktree add --lock --reason "build-loop dispatch of STEM at TIP, UTC TIME"`. `--prompt` replaces the lock. Both run under the flock on `build-loop-dispatch.lock`.
- `wt_of`, `ended`, `steal`: read one branch's worktree and lock. `ended` already parses the lock's TIP.
- `status_fields`: reads a brief's state, branch and tip from main's commit. `check_brief` accepts `briefs/` and `briefs/closed/` paths; a path main lacks reads `new`. A deleted branch reads `absent` (`check_branch`).
- Step 1 of `skills/dev-cycle/SKILL.md`: `worktree list`, `worktree prune`, then `for-each-ref --merged`, `--check-branch`, and `branch -d` for names no slot-holding brief names.
- Skill and gate ship together: the installed `skills/dev-cycle` and `/opt/claude-workflows/scripts/build-loop.sh` are both root-owned image copies [observed], so a skill calling the new mode never runs against an image without it.

## Invariants

- A live loop is never touched. **The brief's rule alone does not give this**: `--start` puts the branch at main's commit, so a just-dispatched worktree has a tip that *is* an ancestor of main and is clean [observed: this loop's own worktree on the survey]. Ancestor plus clean would delete a loop in its first minutes. An open brief, the lock's TIP and a handoff marker at the tip are what stop it; the plan's pre-mortem names the one residual, a loop that goes on past its own marker.
- Only `--start`'s and `--prompt`'s lock reason qualifies; the match is the whole reason, anchored at both ends.
- `git worktree remove` without `--force`; never `-D`. Git refuses a locked worktree without a double `--force`, so a lock has to come off first, and goes back on if the remove refuses.
- A new mode is gated by default (`GATED`), and exit 1 means nothing decided under the D6 rules.
- `refactor/d6-block-into-image` rewrites the D6 passages: the skill edit stays in step 1.

## Prior art

`ended()` is the same question for a live branch: lock TIP is another commit and an ancestor of the tip. Its second half moves to `lock_behind` and both share it. The flock in the `start|prompt` arm moves to `dispatch_lock` for the same reason (S3). `remove_worktree_and_branch` in `scripts/lib/si-functions.sh` is a counter-example: it forces, which this brief forbids.

## Gotchas

Failure-pattern grep: FP-011, FP-013, FP-014, FP-068, FP-141 (see Prior failures section)

- `git worktree remove` does not count an ignored file as dirty, so an ignored file goes with the worktree [observed: bats case]. The brief names that command as the check, so this follows it, and the header says so. In this repo `docs/working/plan-*.md` and `research-*.md` are ignored, so a loop's unforced plan doc would go. Of the 32 backlog worktrees, the only ignored paths are `.bats/` and `__pycache__/` directories [observed]. A stricter check would keep such a worktree forever and hand the user a chore (S10); working docs are disposable by RPI's own rule, and the loop prompt force-adds the design record.
- `--status` for a closed brief reads the same STATE, POLICY and BRANCH afterwards, but LOOP goes from `working SHA DATE` to `absent - -` once the branch is deleted. Nothing reads that: step 7 acts only on STATE `open`, and In flight's check says Done never depends on the branch [observed].
- A worktree with a missing directory: `git worktree remove` would drop the entry, but a missing directory may be an unmounted disk, which is what a lock is for. It stays, reported, as `dispatch` treats it.

- Failure-pattern skip: the branch's fix(...) commits correct its own unreleased code in review; no shipped failure to record.
- A dropped brief with an unmerged branch reads `hold` every iteration and no one is told: its worktree stays, by the brief's rule that an unmerged branch stays locked. So does a done brief landed by squash, whose tip is no ancestor of main. Those are smaller, separate leaks; this brief does not cover them.

## Prior failures

- FP-011 (orphaned worktree after partial add), FP-014 (stale `worktrees` entry breaks the next add): a failed removal must leave a state the next run reads. A refused remove restores the lock; a lock that fails to go back is said on the line.
- FP-013 (exit trap reprocesses a disposed worktree): the mode reads the whole list first, then acts.
- FP-068 (gate artifacts deleted with the worktree): why the ignored-file behaviour above is written down, not left implicit.
- FP-141 (daemons inherit the lock fd): `free_worktrees 9>&-`, as `dispatch` does.

## Design

### Where the removal belongs (divergent design; Path A)

Seeded with `docs/constraints.md` and the brief. Candidates:

| Candidate | Clears backlog | H/S notes | Verdict |
|---|---|---|---|
| A. Tail of `--merge` only | No | `--merge`'s exit says whether main moved; a cleanup failure there blurs it, and it runs from GT | fails the brief |
| B. New mode, called in step 1 | Yes, on first run | S3: reuses `status_fields`, the flock, the lock grammar; one code path | **chosen** |
| C. Both | Yes | two call sites, the same rule run twice, to gain at most one iteration | B plus cost (S3) |
| D. Prose in step 1 (`git worktree unlock`, `remove`) | Yes | S4: mechanical rule in prose; H1: the rule would be judged by the orchestrator | pruned |
| E. Sweep inside `--start`/`--prompt` | Yes, slowly | runs only when dispatching, and a dispatch refusal would hide it | pruned |

B dominates: a worktree waits at most one iteration past its merge, which costs nothing, and the backlog needs no separate path.

### How the backlog clears

The same mode's first run after a release: the 32 above all pass the rule. No one-time script, no host step (S10).

### Other choices (one line each)

- Branch deletion stays in step 1's existing `branch -d` bullet: the mode deletes no branch, so slot and `--check-branch` rules stay in one place (S3).
- A worktree qualifies only if its brief reads done or dropped and names the branch (main's commit), and the branch tip has merged, is past the lock's TIP and is a handoff marker: none of these is read from the worktree's files (H1).
- `hold` and `kept` are two words so a cycle can record `kept` for the user without reading every live loop every iteration (S10).
- `kept` is exit 0: a worktree git refused is the expected report, not a failed run. Only a run that decided nothing exits 2.
- The mode takes the dispatch lock, so a `--prompt` cannot take a worktree mid-removal.

## Files read

Last verified: 2026-11-06
docs/constraints.md
docs/failure-patterns.md
docs/working/briefs/2026-11-06-free-merged-loop-worktrees.md
hooks/live-verify-gate.sh
scripts/build-loop.sh
scripts/health-check.sh
scripts/lib/dev-cycle-read.sh
scripts/lib/si-functions.sh
skills/dev-cycle/SKILL.md
test/lib/build-loop-fixtures.bash
test/scripts/build-loop-dispatch.bats
workflows/divergent-design.md
workflows/pr-prep.md
workflows/research-plan-implement.md
