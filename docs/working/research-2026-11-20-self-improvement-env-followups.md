# Research: self-improvement.sh environment follow-ups

Brief: `docs/working/briefs/2026-11-20-self-improvement-env-followups.md` (at 2a79d39b).
Branch: `fix/self-improvement-env-followups`. Policy: self-merge. Paths: `scripts/self-improvement.sh`, `test/`.

Failure-pattern grep: FP-063, FP-185
Failure-pattern skip: both fixes port existing ones with no new cause: the GIT_LITERAL_PATHSPECS=0 call guard is wt_base's (and ensure_worktree_dir's), and the TMPDIR move follows FP-185's .claude/ ask-on-write move of the worktrees (b3e25cf1, 7b46a90e)

## Reproduction

`bats` on a copy of `test/scripts/self-improvement-clean-state.bats` with setup's `unset GIT_LITERAL_PATHSPECS` replaced by `export GIT_LITERAL_PATHSPECS=1`: 10 of 21 cases failed (A1, A3, A5, the five Q146 cases, and the two cases with a bare `git check-ignore` assertion in the test itself).

## (a) The failing call

- Not in `self-improvement.sh` itself: `si_commit_child_work` (`scripts/lib/si-commit.sh:94`, sourced by the script) stages with `git add -A -- . ":(exclude).si-commit-msg"`. Under literal pathspecs the exclude is a literal file name that matches nothing, so `git add` fails, every task is rejected ("implementer commit failed: git add failed"), and nothing merges. That is why A1/A3/A5 and Q146 fail.
- No other git call in the main loop takes a magic pathspec (`git status -- .worktrees`, `git add "$FP_LIB"` and `git diff main..BRANCH` are literal-safe; `git show main:FILE` is a revision).
- Options inside Paths: (1) prefix the call site, `GIT_LITERAL_PATHSPECS=0 si_commit_child_work ...` (bash exports a prefix assignment to a function's commands for its duration), as `wt_base` and `ensure_worktree_dir` prefix their one `check-ignore`; (2) unset the variable script-wide. Only two options, so no divergent design: (1) is the brief's named pattern (S3) and narrower. Picked (1).
- For the cycle, outside Paths: the guard more naturally belongs inside `scripts/lib/si-commit.sh` (its `g` array), which would also cover `test/si-commit-child-work.bats` callers; a candidate follow-up, not done here.
- Tests: setup's `unset` is gone; the file's own two `git check-ignore` assertions carry `GIT_LITERAL_PATHSPECS=0`, as the script does. New case: an exported `GIT_LITERAL_PATHSPECS=1` still commits and merges task a with its message file (pass verdict, no `.si-commit-msg` in history). The whole file passes with the variable exported and unset.

## (b) The TMPDIR fallback

Design choice (divergent design, three-plus options), seeded with the brief and docs/constraints.md:

| Option | What it means | Verdict |
|---|---|---|
| `.worktrees/si-tmp` via `ensure_worktree_dir` | reuse the existing setup and ignore check | picked |
| the session temp dir | e.g. a `/tmp/claude-$uid` guess | out: no defined session dir when TMPDIR is unset; bare /tmp may be denied (FP-063) |
| a new repo-root ignored dir | e.g. `.si-tmp/` | out: needs `.gitignore`, outside Paths |
| refuse when TMPDIR is unusable | fail closed, owner exports TMPDIR | out: new owner step for a launch that works today (S10) |

Path A: the first dominates (S3 reuse, H2 fails closed through `ensure_worktree_dir`, no owner ask, inside Paths).

- An exported writable `TMPDIR` still wins (unchanged condition).
- The fallback runs `ensure_worktree_dir "$REPO_DIR" si-tmp "or export TMPDIR ..."` even with an explicit `WORKTREE_BASE`, so the directory is never visible to git; `ensure_worktree_dir` gained an optional third argument for the way forward its errors name.
- The block moved up from after the `si-run-id.txt` write to just after the worktree setup, so a refusal leaves nothing but `.worktrees/` behind (it needed nothing in between; no mktemp runs earlier).
- The name `si-tmp` takes neither the build loops' `wt-*` names nor this script's `si-wt-*` worktree names, so no cleanup or worktree sweep touches it.
- Tests (the stub `claude` records its `TMPDIR`): an exported one is used and no `si-tmp` is made; unset, and unwritable, both land in `.worktrees/si-tmp` with no `.claude/` and a clean status; a non-ignoring `.worktrees/.gitignore` with an explicit `WORKTREE_BASE` refuses naming `export TMPDIR`, before `si-run-id.txt`.
- Each new case was run against the pre-change script: the four new cases (literal pathspecs, unset, unwritable, refusal) fail there.

## Docs naming `.claude/tmp` for this script

- `docs/working/si-trust-evidence-2026-10-14.md:43` says `TMPDIR` "falls back to `REPO_DIR/.claude/tmp`". Outside Paths (and a dated evidence record): for the cycle, not edited.
- `docs/roadmap.md:89` names it in the Now item this brief closes; the cycle's to update.
- Nothing under `guides/` names it.
- The script's header now lists `TMPDIR` and its fallback; the block's comment says why it moved.

## Constraint notes

- S8: `self-improvement.sh` (2,000+ lines) grows by 8 net lines, mostly the required comments; trimmed to the minimum.
- H3: all tests are hermetic (stubbed `claude`, fixture repo under `BATS_TEST_TMPDIR`).

## Review

- Health check (`scripts/health-check.sh`) on 6b1ddd23: all checks passed.
- Round 1 (fresh reviewer on 6b1ddd23): nothing at medium. Fixed: (low) the fallback's ignore check probed `si-tmp-x`, a name the run never uses, so an ignore file of `si-tmp-*` passed while `si-tmp/` showed in status; it now probes `si-tmp/tmp-x`, inside the directory, with a case. (low) `.worktrees/si-tmp` as a symbolic link: git's check-ignore refuses a path beyond a link, and a `[ -L ]` test backs it up, with a case; the "git could not say" error now names the way forward too. (low) the `WORKTREE_BASE` comment now says the fallback still sets up `.worktrees/`. (nit) a writable regular file as `TMPDIR` falls back instead of aborting at the first mktemp, with a case. (nit) the call-site comment points at the local `ensure_worktree_dir`. The new cases fail on 6b1ddd23 and pass now; the suite passes with `GIT_LITERAL_PATHSPECS=1` exported and unset.
