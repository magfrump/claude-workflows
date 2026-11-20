# Research: self-improvement's default worktrees out of `.claude/`

Brief: `docs/working/briefs/2026-11-20-self-improvement-worktrees.md` (at 90f7632f).
Branch: `fix/self-improvement-worktrees`. Policy: self-merge. Paths: `scripts/self-improvement.sh`, `test/`.

## What the code did

- `scripts/self-improvement.sh` set `WORKTREE_BASE="${WORKTREE_BASE:-$REPO_DIR/.claude/wt}"`; every task worktree is `WT_DIR="$WORKTREE_BASE-$TASK_ID"` (three sites in the main loop), made by `create_task_worktree` and removed by `remove_worktree_and_branch` / the EXIT trap. Nothing else in the script assumes the worktree sits under `.claude/`.
- The header said the default was "inside the sandbox write-allowlist and gitignored (see .gitignore)": the repo `.gitignore` ignores `.claude/`.
- b3e25cf1 (Q-311, the build-loop worktree move) made `.worktrees/` in the main worktree via `scripts/build-loop.sh --worktree-base` (`wt_base`, :1905-1938): refuse a link or non-directory, `mkdir -p`, write a `.gitignore` of `*` under `set -C` when absent (an existing one is left as it is), then require that `git status` shows nothing under `.worktrees` and `git check-ignore` ignores a new `wt-x` name. The repo's own `.gitignore` is not edited. `health-check.sh` and the hermeticity adapters already skip `.worktrees/`.
- Tests naming self-improvement worktree paths: `test/scripts/self-improvement-clean-state.bats` (A2's `[ ! -d "$REPO/.claude/wt-a" ]`, Q146's `feat: change from wt-a`). The guard-hook tests' `.claude/wt-*` cases test the hook, not this script, and stay.

## Context packing

- Invariants: an explicit `WORKTREE_BASE` keeps working (tests and cron use it); `require_clean_main` runs before any write; task worktrees must never be visible to `git status` on main (an approved merge and the loop's own commits run in the main checkout).
- Avoid: calling `build-loop.sh` (gate code, and its `caller_gate` refuses this caller; brief and H1); editing the repo `.gitignore` (outside Paths:).

## Design notes (no choice with 3+ viable options)

- How to make the directory: calling `build-loop.sh --worktree-base` is ruled out by the brief and H1, and extracting `wt_base` into a shared lib needs `build-loop.sh` (out of scope), so the one surviving option is a small local copy of the same steps (`ensure_worktree_dir`). S3 tension noted: the convention (directory, `*` ignore file, ignore check) is reused, the code is duplicated; a later shared helper would need a gate-code change.
- Name prefix: `.worktrees/si-wt` (worktrees `si-wt-<task>`), not `.worktrees/wt`, so self-improvement worktrees never take the build loops' `wt-<date>-<slug>` / `wt-dev-cycle-*` names that `--free-worktrees` and the cycle read.
- Fail closed (H2): a link, non-directory, unwritable or link `.gitignore`, or an ignore setup leaving `.worktrees` visible refuses the run before any other write, naming the gap and a way forward (fix the ignore, or set `WORKTREE_BASE`).
- The check runs only when the default is in use; an explicit `WORKTREE_BASE` is used as given (the header says so), as before.
- A negation in the repo root `.gitignore` cannot re-include `.worktrees/si-wt-*` past `.worktrees/.gitignore`'s `*` (the deeper file wins), so no test for it; the visible-ignore test covers the refusal path.

## Changes

- `scripts/self-improvement.sh`: header `WORKTREE_BASE` entry and the config comment say what is true now and why the default moved; `SI_DEFAULT_WORKTREE_BASE="$REPO_DIR/.worktrees/si-wt"`; new `ensure_worktree_dir`, called right after `require_clean_main` when the default is in use.
- `test/scripts/self-improvement-clean-state.bats` (real main loop, stubbed `claude`): A2/Q146 pin the new paths; new cases: default worktrees land under `.worktrees/si-wt-*`, are ignored and leave status clean with no `.claude/` made; an existing ignoring `.gitignore` is kept; a non-ignoring `.gitignore`, a `.worktrees` symlink and a `.gitignore` symlink each refuse with a named message and no worktree; an explicit `WORKTREE_BASE` is used and makes no `.worktrees`.
- Review rounds 1-3 added the inherited-`GIT_LITERAL_PATHSPECS=1` case and two refusal cases, one per ignore read (see below).

## Docs naming `.claude/wt` (acceptance 5)

`rg -n '\.claude/wt' docs guides` finds no doc describing self-improvement's default: the hits are dated review reports (historical paths, left as they are) and `docs/roadmap.md:361` (about how orchestrators commit into `.claude/wt-*`; the roadmap is the cycle's, not edited here). Named for the cycle:
- `docs/roadmap.md:361` may want its `.claude/wt-*` wording refreshed once this lands.
- Outside the brief: `scripts/self-improvement.sh` still falls back to `TMPDIR=$REPO_DIR/.claude/tmp` when `$TMPDIR` is unset or unwritable (the same Claude Code ask-on-write applies); a candidate follow-up item.

## Review rounds

- Round 1 (dispatch 1): check-ignore refused under an inherited `GIT_LITERAL_PATHSPECS=1` (the dev-cycle reader exports it); fixed as `wt_base` does, with a test.
- Round 2 (dispatch 2, after merging main): no high. Medium: either ignore read could be deleted with every test still passing; added two refusal cases each caught by only one read (a `.gitignore` of `.gitignore` and `wt-*`, and one of `si-wt-*`), confirmed by mutation (each mutant fails exactly its case). Low: check-ignore tests one representative name, so an existing ignore of itself plus only some names (`.gitignore` and `si-wt-?`) passes; named as a known gap in the comment (`wt_base` shares it; a fresh `*` file has none). Nits: "same directory" corrected (build-loop roots `.worktrees` at git's main worktree, this at `REPO_DIR`); "explicit WORKTREE_BASE" reworded to "other than the default".
- Round 3: nothing at medium. Low: the gap example above was wrong (a lone `si-wt-?` refuses, as the `.gitignore` shows in status); corrected in the comment and here. Nit: the suite's bare `git check-ignore` assertions fail under an inherited `GIT_LITERAL_PATHSPECS=1`; `setup()` now unsets it (the one test that needs it sets it again). Round 4 (self-review of a8f1210f: a comment example, one `unset` in `setup()`, doc lines): clean; the touched suites pass, including the new cases run with `GIT_LITERAL_PATHSPECS=1` exported.
- For the cycle (pre-existing, also fails at 90f7632f): with `GIT_LITERAL_PATHSPECS=1` exported, 8 other clean-state cases (A1, A3, A5, five Q146) fail, so some other git call in the script's main loop breaks under literal pathspecs; untraced, a candidate item (the suite's new unset hides them, but a real run with the variable exported would still hit it).
- For the cycle, outside Paths: `hooks/guard-trusted-writes.py` exempts the old self-improvement worktree names under `.claude/`; nothing in `scripts/` makes them now, so its "(this harness's)" comment is stale (gate code, not edited here). The TMPDIR fallback above stays a candidate item.

## Verification

- `bats test/scripts/self-improvement-clean-state.bats`: 21/21 pass after round 2.
- After merging main, before the round-2 edits: the ten suites that source or run the script (adding `test/si-clean-state.bats` and `test/cc-isolated-functions.bats` to the list below): 325/325 pass.
- `bats` over the suites that source the script (smoke, worktree-cleanup-functions, function-inventory, round-log-functions, claude-headless-flags, validate-task-json, convergence-detection): 79/79 pass.
- `scripts/hermeticity-lint --root .`: passes. `shellcheck`: info-level only, same classes as before.
- Final gate at a8f1210f: five touched suites 55/55, `scripts/hermeticity-lint --root .` passes, `scripts/health-check.sh` "All checks passed." (exit 0).

Failure-pattern grep: FP-062, FP-185
Failure-pattern skip: both fix(...) commits port existing fixes: the path move follows b3e25cf1 (FP-185, worktrees under .claude/ asking on writes), and the GIT_LITERAL_PATHSPECS=0 guard copies build-loop.sh wt_base, a review-caught port slip with no new cause
