# Plan: free a finished loop's worktree and branch

- **Goal**: Once a build loop's branch has merged, its locked worktree goes away so step 1's `git branch -d` can delete the branch, and the existing backlog clears the same way.
- **Project state**: delivers a `--free-worktrees` mode and step 1's call to it · standalone · not blocked (cite: docs/working/briefs/2026-11-06-free-merged-loop-worktrees.md)
- **Task status**: complete

Research: docs/working/research-2026-11-06-free-merged-loop-worktrees.md

## Steps

1. `scripts/build-loop.sh`: `--free-worktrees` (`free_worktrees`, `free_one`), `lock_behind` out of `ended`, `dispatch_lock` out of the `start|prompt` arm; header, usage, exit and writes text.
2. `skills/dev-cycle/SKILL.md`: step 1 only, before the branch deletion.
3. `test/scripts/build-loop-free.bats`: the brief's four cases, the live-loop case, closed-brief reads, each failure path.
4. Review-fix loop, whole health check, status line.

## Pre-mortem (gate code)

Assume this shipped and removed something it should not have. The families of way past the rule:

| Family | Failure story | What stops it | Residual |
|---|---|---|---|
| Fresh dispatch reads as merged | `--start`'s branch sits at main's commit, so it is an ancestor and clean | brief open; tip must be past the lock's TIP | none known |
| Brief closed under a live loop | The owner marks a brief dropped while its loop runs | a merged tip at the lock's TIP, or one that is no handoff marker, is `kept`; an unmerged branch is `hold` | a loop that went on past its own marker, merged, under a closed brief, with a clean tree: its next commit fails loudly, and only ignored files are lost |
| Lock text planted or stale | A hand lock imitating the reason; a reason with trailing text | anchored whole-reason match; the brief and branch must still agree | a same-uid process copying the reason exactly (S1: out of scope) |
| Brief lookup confusion | STEM from the lock is path-shaped; another brief's status is read; two briefs share a branch | `check_brief`'s pathform and anybrief; the brief must name this branch | none known |
| Work outside git's dirty check | An ignored file holds work; `status.showUntrackedFiles=no` hides an untracked one; a worktree nested in the ignored `.claude/` | `-c status.showUntrackedFiles=normal`; `kept` when a listed worktree is inside | ignored files: accepted, follows the brief, and RPI's working docs are disposable |
| Dispatch race | `--prompt` retakes a worktree during removal | shared flock | `--merge` does not take the flock, and reads these worktrees' git directories: a removal under it can make it refuse, fail closed: a self-merge retries next iteration, and an approved merge's refusal may be filed `stopped` |
| Failure leaves a worse state | Remove refuses after unlock; relock fails | relock with the original reason; the line says when it failed | an unlocked finished worktree: safe, and no longer considered by the mode, so it stays until someone reads the `kept` line. A remove failing part way can leave the directory part removed and unregistered: the line says the lock could not go back, and no later run names it. A run killed between unlock and remove prints no line, and the worktree stays unlocked and unnamed: safe, and rare (a first run on a clone of 35 took 4 to 26 s against 120 s, and 77 s on a starved CPU) |
| Wrong repository | A `GIT_DIR`-style variable or a non-main default | `caller_gate` (added for this mode: the state gate alone has no such check, fact-check claim 7a) and `default_gate` before anything is listed | none known |
