Merge branch 'feat/build-loop-u3a2': --merge lands a self-merge brief by compare-and-swap, or a fast-forward in the worktree that has main checked out

## What this does

U3a2 of the build-loop handoff (plan step 7's U3a2 bullet), all in `scripts/build-loop.sh` and `test/scripts/build-loop-merge.bats`:
- **`--merge BRIEF --expect SHA`** (self-merge only): gate_start and check_line as `--check` runs them, with the verdict as values (VERDICT, CHANGED; row 512), then `land self-merge`. A review brief refuses.
- **The merge commit** is written by `commit-tree TREE -p MAIN -p TIP` in the gate repository, with a `Build-loop-gate: STEM` trailer; the identity comes from `git var` under `user.useConfigOnly=true` (the caller's global config read, never a host guess).
- **The move**: with main checked out nowhere, `update-ref --no-deref refs/heads/MAIN NEW MAIN_SHA` (compare-and-swap); with main checked out in W, `merge --ff-only NEW` there, with `branch.<main>.mergeOptions` cleared, no gc or maintenance, and the reflog naming the gate. The state gate and default_gate re-run just before either (row 494).
- **Worktree discovery**: `git worktree list` cross-checked against every admin dir (dot names included): HEAD resolved by git itself (`symbolic-ref`), rebase head-name and update-refs, BISECT_START. A worktree list does not show, two worktrees on main, a rebase or bisect of main, or any state git could read and the gate cannot, refuses. Bare repositories land; one listed bare with an index refuses.
- **W's checks**: its own state gate first (its config.worktree, before any command reads its work tree), its own top level and the git dir that named main, on main at MAIN_SHA, nothing in progress, clean, and nothing (ignored files included) at a path the merge adds.
- Output: `merged BRIEF TIP TREE NEW`, or `refuse BRIEF: WHY` with the path lines following.

**Workflow provenance:** RPI (plan revision 4, step 7) → U3 split before code (d5736445) → pr-prep → iteration-4 escalate → confirming pass → Q-138 interim [1] → second confirming pass.
← carried from RPI: D7 (merge-tree result + CAS), F29/F50 (W's checks), T22/T23, row 494's re-run before the move.

**Failures prevented:**
- A merge landing as a squash staged in W (`mergeOptions`), or overwriting an ignored file at an added path (reproduced in review).
- main moved by CAS under a worktree that has it checked out but that the list drops, or that a paused rebase will reset (each planted shape the reviews found refuses).
- A commit identity guessed from the passwd entry.

## Reviewer's path — start here

1. The `--merge` header block (refusal list), then `land()` and `merge_ident()`.
2. The `merge)` case at the bottom.
3. `test/scripts/build-loop-merge.bats` (7 tests): CAS, race shim, identity, ff in W, W refusals, discovery refusals, bare layouts.

## How to test

- Suites, serially: build-loop-merge 7, build-loop-check 145, build-loop-read 20, dev-cycle 79, fixtures 2/2. Mutants of each newest guard fail exactly their test (second confirming fact-check).
- `scripts/health-check.sh` passed at 02b1563b.

## Areas of uncertainty

- **Planted git state (Q-103 residuals)**: every security pass after the final found one more shape a same-uid writer could plant so land reads worktree state unlike git. Per Q-138 [1] (interim, taken in /away mode) further shapes are override rows routed to Q-103, among them a planted `core.bare` with the index deleted (Low, regression from 20de9671).
- **Honest-path false refusals, fail closed**: a separate-git-dir or submodule repository whose main worktree is on main; a symlinked HEAD; any admin dir git cannot open blocks every landing.
- Nothing calls `--merge` until U4 writes the orchestrator; U3a3 (`--approved`) reuses `land`.

Review: three iterations (i1 k=1 full panel; i2 k=1 fix range; final k=3 full panel), iteration-4 escalate → confirming pass (1 Must Fix, merge stopped for Q-138), interim batch ce38eafb, second confirming pass (k=1 fact-check + security over 20de9671..2028aa89): no Must Fix or Must Address. Rubric `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3a2.md` (loop closed at 07360526). 400 changed code lines.
