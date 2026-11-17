# Research: a build loop may merge the default branch into its own branch

Brief: `docs/working/briefs/2026-11-16-loop-may-merge-default-in.md` (at 554186327c2f). Policy: review. Branch: `fix/loop-may-merge-default-in`.

## What the code does

- `loop_prompt()` in `scripts/build-loop.sh` prints the loop prompt for `--start` and `--prompt`. Its last-but-one line ended "never send your branch to a remote, merge, open a pull request or publish".
- The gate's `check_line` (`--check`, `--merge`) computes `merge-tree MAIN_SHA TIP` (`merge_result`) and judges `diff-tree MAIN_SHA RESULT`. A conflict refuses with "refuse BRIEF: BRANCH conflicts with the default branch". So what the gate judges is the merge result against main, whatever history the branch carries.
- The fix(...) count is `rev-list TIP ^MAIN_SHA`: commits brought in from main by a merge are not counted.
- The two "merge the default branch into HEAD first" refusals the brief cites (`:2129`, `:2407`) belong to `--cycle-diff` and `--land-cycle`, the orchestrator's chore branch, not to a loop. They show the same remedy the loop now gets.
- `$MAIN` (the resolved default branch name, main or master) is set by the state gate before `--start`/`--prompt` print the prompt, so the prompt names `refs/heads/$MAIN`, not a hard-coded `main`.

## Gotchas

Failure-pattern grep: FP-023
- FP-023 (a bats `run !` assertion that was vacuous without a version floor): the new test uses plain `[[ ]]` matches, the file already has `bats_require_minimum_version 1.5.0`, and the new test was run against the old `scripts/build-loop.sh` and fails there (line "missing: never send your branch to a remote, merge into the default branch ...").

Failure-pattern skip: the slip is an ambiguous prompt word read two ways, already recorded as philosophy-research feedback F-009; there is no code root cause or symptom a future grep would match.

- "push" must not appear in `scripts/build-loop.sh` (T20, `test/scripts/build-loop-check.bats` "never push"); the new text avoids it and keeps "never send your branch to a remote" verbatim, so the existing assertion in `build-loop-dispatch.bats` still matches.

## Design notes

No choice here has 3 or more viable options, so no divergent design ran. One-line notes:
- Where the rule goes: in the same prompt line (the brief puts every other prompt line out of scope), not in the stopped marker's stop-condition list.
- The command: `git merge --no-edit refs/heads/$MAIN`, git's default strategy (no `-s` or `-X`), matching how the dev-cycle skill merges main into its own WT (step 9). No rerere or `--no-verify` flags: a loop's hooks may run.
- The forbidding clause reads "merge into any branch but your own" (review round 1, should-fix 1: "merge into the default branch or any other branch" also covered the loop's own branch and left a second reading). The allowance says "the default branch, and no other branch", with the conflict refusal as its example trigger, and "re-run pr-prep's review-fix loop" names which review.
- On an unresolvable conflict: `git merge --abort`, then `handoff: stopped: REASON`, as the brief asks. `--abort` leaves the branch at its tip, so nothing half-merged is committed.

The "Only add commits: never reset, rebase or otherwise move your branch below $5" rule still holds: a merge adds a commit whose first parent is the loop's tip, so the dispatch commit stays an ancestor. The new test asserts that line is still in the prompt.

## Pre-mortem (gate code: `scripts/build-loop.sh` is in GATE_CODE)

What a loop could now do that it could not before, and what bounds it:

1. **Merge some other branch than the default branch in** (another loop's branch, a stale chore branch). The prompt forbids it ("and no other branch"). If a loop does it anyway, `--check` and `--merge` judge `diff-tree MAIN_SHA merge-result`, so every path the other branch brings shows in the changed-path list the owner reviews, and on a self-merge brief is held to `Paths:` and the floor. Its fix(...) commits are counted too (`rev-list TIP ^MAIN_SHA`). Residual: on a review brief the owner must notice the foreign paths in `--check`'s list; that was already so for any commit a loop makes.
2. **Resolve a conflict by dropping main's side** (`-X ours`, or hand-resolving toward its own lines). The prompt names the default strategy and says a conflict that cannot be resolved without discarding a side is a stop. If a loop discards main's change anyway, the merge result against main shows that file as changed back, which `--check` lists; on a self-merge brief it is outside `Paths:` unless the file is in scope. Residual: an in-scope file reverted to the branch's version is visible only as a diff, not flagged; the review-fix loop and the owner's review are the check.
3. **Merge a moved main mid-run, then the orchestrator's main moves again.** `--check`/`--merge` run from main's current commit and recompute the merge, so a stale merge is judged afresh; a new conflict refuses again as before.
4. **Criss-cross history** (merging main in twice around another merge). `merge-tree --write-tree` handles several merge bases with a virtual base; a conflict there refuses. No new acceptance path.
5. **A conflicted merge's commit trips the live-verify commit hook** (`hooks/live-verify-gate.sh`; review round 1, should-fix 2; friction, not a bypass). The hook judges `git diff --cached` against HEAD and ignores MERGE_HEAD, so a hand-resolved merge whose main side changed an enforcement file under `devcontainer-config/` asks for a `Live-verified:` trailer the loop cannot honestly give. The loop then stops, which is what it did before this change, so nothing gets worse; the fix (judge only the MERGE_HEAD side in the hook) is an enforcement file outside this brief, offered as a follow-up idea in the marker.
6. **A loop on a master repo runs `git merge main`.** The prompt prints the resolved name (`refs/heads/$MAIN`), so it names the real default branch.

None of these widens what reaches main without the gate: merging into the default branch stays forbidden by the prompt and is in any case only done by the orchestrator's `--merge`. The merge of this change needs the owner's approval (a `merge-gate-` entry).

## Doc check (acceptance criterion 5)

- `docs/working/plan-build-loop-handoff.md` line 243 quoted the rule ("never push, merge, open a PR or publish"): amended in place with a dated note naming this brief.
- `skills/`, `workflows/` and `docs/dev-cycle.md` do not quote the rule; `skills/dev-cycle/SKILL.md` does not quote or describe the prompt's merge rule (its "merge main into WT" text, step 9, is the orchestrator's own chore branch); unchanged.

## Verification

- `scripts/confine-tests.sh --probe`: exit 3, first line "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So tests ran through `scripts/run-tests.sh` plus `scripts/hermeticity-lint --root .`.
- `scripts/run-tests.sh --jobs 4 test/scripts/build-loop*.bats`: 176 tests, 0 failures. `board.bats`, `convention-migrations.bats`, `questions-doc.bats` (the other files naming the script or plan): 0 failures.
- `scripts/hermeticity-lint --root .`: exit 0, 145 files, no unstubbed network spawns.
- The new test runs `--start` and then `--prompt` (after a marker) and checks the rule in both prompts.
- The new test fails against the old `scripts/build-loop.sh` (checked by swapping the file in and back).
