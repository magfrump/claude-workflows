Merge branch 'feat/build-loop-u4b1': the dev-cycle skill's orchestrator frame (Rules, settings, steps 0-1, drift check), commit signing off in HARDEN, a bounded health-check lock wait

## What this does

U4b1 of the build-loop handoff (plan step 10; U4b split before code into U4b1 and U4b2, note in the plan):
- **`skills/dev-cycle/SKILL.md`, the orchestrator's frame.**
  - Intro, plus a by-hand fallback until the D6 block lands (Q-140). The fallback names its gap: with no `--state` run, nothing refuses repository config that `hg` cannot switch off.
  - Rules:
    - D13's own directory, and a worktree per iteration.
    - The D6 call form, and how to read its output. `refuse d6:` means nothing ran. A `build-loop.sh` answer is exit 0, or exit 2 with the lines its mode documents. Any other exit, or a timeout, is a stop, filed once, with no record written.
    - The orchestrator's own git as one `hg` line: the snippet's environment plus the lib's `HARDEN` pairs, pinned by the git_harden test.
    - What `hg` does not switch off, and `--state` re-run before the iteration's commits.
    - Identity set per command as `GIT_AUTHOR_*`/`GIT_COMMITTER_*`.
    - D11.
  - Settings are read only through `--settings`, and the constraints doc is named (D2). `--check-fix` runs again before staging (rows 764, 769, 771).
  - A pending D6 block section.
  - Step 0:
    - `--state`, then `--main-log` from the main worktree.
    - The 40-zeros bootstrap, but only when main's first-parent history never held a `Main at:` line (a rewrite of main is the residual routed to U4b2).
    - `answers` lines are listed for the user; `other` lines block dispatch and get one entry each.
    - The worktree, created then; it is removed with `--force` after the land or on a stop.
    - The digest.
  - Step 1: D14's quiesce scope, and the health check run with `HEALTH_CHECK_LOCK_WAIT=3600`.
  - Step 4's drift check and step 4b's constraints dimension (D2, F57).
- **`HARDEN` gains `commit.gpgSign=false`** (lib, the D6 snippet's `G`, SKILL.md's `hg`). Before it, a loop that planted `commit.gpgSign` in `.git/config` passed `--state`, and the orchestrator's commits ran `gpg`. No other HARDEN user commits with a signature. build-loop.sh's header now refers to the lib's list instead of an unpinned copy of it.
- **`scripts/health-check.sh` takes `HEALTH_CHECK_LOCK_WAIT`** (plain seconds, at most 7 digits). It waits that long for the lock (`flock -w`); past it, it exits 75 having run nothing (row 750).
- **`workflows/pr-prep.md`**: the quiesce covers this task's subagents, and processes are stopped by PID only (D14).

**Workflow provenance:** RPI (plan revision 4, step 10; U4b split before code) → pr-prep: three iterations, then the iteration-4 gate's escalate to a confirming pass. That pass stopped the merge (Q-142). A second confirming pass ran under Q-142's interim [1].
← carried from RPI: D2, D6, D11, D13 and D14. Rows 702, 704, 720, 726, 727, 735, 736, 742, 744, 750, 764, 769 and 771, the hand-offs of U3b1-U4a.

**Corrections to branch commit bodies:**
- 0cd86cc0 says "only `--state` refuses ... commit signing". That is false: `--state` never refused `commit.gpgSign`, and 4c911717 fixed it in `HARDEN`.
- 4c911717's "the pin test now counts 10 pairs": 10 is the `GIT_CONFIG_COUNT`, the caller's one pair plus HARDEN's 9.
- ea59b0c3's process-group stop of the health check was replaced in 923f7d26 by `HEALTH_CHECK_LOCK_WAIT`.
- c67ffd62's "bootstrap only when main's history never held a Main at: line" held only with 6c22e5d3's flags; its "(flock's timer)" is the script's own bound.

## Reviewer's path — start here

1. SKILL.md's intro and Rules: the D6 Rule, the hardened-git Rule and its `hg` line.
2. Step 0 (the start of an iteration), then step 1's first bullet.
3. `take_lock` in `scripts/health-check.sh`, and the last test of `test/scripts/health-check-lock.bats`.
4. The `HARDEN` line in `scripts/lib/dev-cycle-read.sh` and the git_harden test in `test/scripts/build-loop-orchestrator.bats`.

## How to test

- Suites, run serially: orchestrator 27, check 146, read 20, merge 12, dispatch 4, dev-cycle 79, health-check 32, health-check-lock 3. shellcheck is clean, and `scripts/health-check.sh` passed at 923f7d26.
- The pin test fails on each mutant the fact-checkers made: the pair dropped from each copy, an environment variable dropped, a second `hg` line, pairs swapped. The lock-wait test fails on the script before it.

## Areas of uncertainty

- **Q-142 is open for the user** (interim [1] applied). [2] would revert the forced removal and the history-based bootstrap. [3] would leave worktrees for the user to remove.
- **Q-140 still blocks U4c** (the D6 block). Until it lands, the skill runs by hand, and the orchestrator steps cannot run.
- **U4b2 owes** the items in the override rows dated 2026-10-13 on this branch:
  - the Flow and description;
  - steps 6-10, step 7's pr-prep land and record template, and the hard-coded 3 slots;
  - the SINCE read, with `--no-edit` on the merge of main into WT, and rerere;
  - whether the chore commit goes through a gated mode, and the place of the `--state` re-run.
- **Interim /away calls:**
  - the U4b split;
  - `commit.gpgSign` added to `HARDEN` rather than to the state gate's refusals;
  - the one-hour lock wait;
  - identity from the environment, else the global config read in-script.

Review converged as follows:
- **Iteration 1** (k=1 fact-check): two behavioural Incorrects, short-circuited. `hg` was credited with stopping filters and signing, and `--state` with refusing exported variables. Fixed.
- **Iteration 2** (k=1 fact-check over the fix range; full panel on the branch): `--state` was credited with refusing signing (fixed in `HARDEN`). Also fixed: identity outranked by a planted `author.*`, the fallback's gap and scope, stop and record wording, exit codes, worktree removal.
- **Iteration 3**, the final pass (k=3 fact-check, 75.7% agreement, fix first; full panel with architecture): a PID stop left the health check's `flock` child running, and `--state`'s exit 1 had two routes. Fixed. Then a bootstrap fail-open and the skill encoding `take_lock`'s process tree were fixed by `HEALTH_CHECK_LOCK_WAIT`.
- **Confirming pass** (k=1 fact-check, security): E1, a stop-path removal that ran a planted filter, stopped the merge (Q-142). Interim [1] fixed it in c67ffd62.
- **Second confirming pass** (k=1 fact-check, security): E1 closed; E2's remainder (a path-limited `log -G` skipped a merge) fixed in 6c22e5d3 with check_brief's log flags, verified by execution and a clean lite review.
- Rubric: `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4b1.md`. Override rows dated 2026-10-13 for this branch. 264 changed code lines.

Single-sample review; absence of findings is not an attestation.

Confidence: medium
Notes: merged under Q-142's interim [1] (the Q-138 / Q-141 precedent); the user may still answer [2] or [3].

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019UpfX7SZK8HDDreexNffjp
