# Q-075: what `self-improvement.sh` can write, measured

**Date:** 2026-10-14 · **Commit read:** f66fd9f2 (main) · **Roadmap:** Next #1
**Question (Q-075):** list every path, config, hook, credential and git ref the loop
can write outside its own working docs. Run it once hermetically, with every
env-overridable destination redirected, and diff the setup before and after.

## Verdict

- **The script itself is safe to run, and the probe proves it** (§2). Its own writes stay
  inside `REPO_DIR`, `WORKTREE_BASE` and `TMPDIR`, and all three can be redirected.
  A full stubbed run against a clone left `/workspace`'s refs, worktrees, config and
  hooks byte-identical, and wrote nothing to a redirected HOME. There is one
  exception: `git worktree prune` acts on the whole repo (F4).
- **The `claude -p` children are not bounded by the script.** What a child can write
  depends on its cwd's Claude Code settings, and there are only two outcomes:
  - **cwd = `/workspace`.** The project allowlist applies. `Bash(bats test:*)`
    together with `acceptEdits` gives the child arbitrary code execution as the
    `node` uid, and cc-isolated has no Bash sandbox to stop it (F1, F2).
  - **cwd = a worktree or clone.** `.claude/` is gitignored, so there is no
    allowlist, and the child cannot run `git commit` (F5, checked live). Every task
    would fail Gate 1a, after the run has spent its tokens.
- So **"resume as is" doesn't work either way**: in a worktree the loop is inert, and
  with the allowlist it is unconfined. How to give implementers commit rights without
  a general exec grant is the user's call. It is filed as a question; see §5.

## 1. Write inventory: the script and its libs

Read in full: `scripts/self-improvement.sh` (1929 lines) and `scripts/lib/{si-functions,si-input,si-morning-summary,json-utils,preflight}.sh`.
**Probe** = the stubbed run in §2 observed the write.

| What it writes | Path (defaults) | Override | Tracked? | Probe |
|---|---|---|---|---|
| Run id, round reports, round history, problem history, test baseline, validation logs, morning summary, contrastive-note cache, completed-tasks log, hypothesis log | `REPO_DIR/docs/working/{si-run-id.txt, round-N-report.json, round-history.json, problem-history.json, test-baseline.txt, validation-round-N.log, morning-summary.md, contrastive-note-round-N.json, completed-tasks.md, hypothesis-log.md}` | `REPO_DIR` | all gitignored | yes |
| Ideas and tasks files (written by children; `rm -f` first) | `REPO_DIR/docs/working/{feature-ideas,tasks}-round-N.*` | `REPO_DIR` | gitignored | yes |
| Lineage plan stubs | `REPO_DIR/docs/working/rN-<task>-plan.md` | `REPO_DIR` | **untracked, not ignored** | no (only fires when `round-changelog.md` exists) |
| Review archive, a copy of **all** of the worktree's `docs/reviews/*.md` | `REPO_DIR/docs/working/reviews/round-N/<task>/` | `REPO_DIR` | gitignored, never pruned | yes, **1317 files and 36 MB per task** (F6) |
| Failure-pattern harvest plus a **commit on main** | `REPO_DIR/docs/thoughts/failure-patterns.md` | `REPO_DIR` | tracked | yes |
| Task worktrees | `WORKTREE_BASE-<task>` (default `REPO_DIR/.claude/wt-<task>`) | `WORKTREE_BASE` | ignored | yes, all removed |
| Task branches `feat/rN-<task>`: created, `-D` on reject, `-d` after merge, kept on `conflict_unresolved` | `REPO_DIR` refs | `REPO_DIR` | refs | yes; canary branches survived |
| **Merges into HEAD** (must be `main` at start; not rechecked), `merge --abort` on its own failed merges | `REPO_DIR` main | `REPO_DIR` | refs and working tree | yes: 2 merges and 1 commit (F3) |
| **`git worktree prune`**, repo-wide | `REPO_DIR/.git/worktrees/*` | none | git admin | **yes: pruned a canary registration the run didn't create (F4)** |
| `mktemp` round log, schema stderr, self-eval baseline dirs (with a copy of `skills/`), jq temp files | `TMPDIR` (falls back to `REPO_DIR/.claude/tmp`) | `TMPDIR` | n/a | yes, all cleaned. The 9 leftovers in `TMPDIR` came from the bats suite (`cc-gitdir.sh` stderr files, empty dirs), not from the loop |
| Full `bats test/` runs: once at start, once per task | whatever the suite writes | `HOME`, `TMPDIR` | n/a | nothing landed outside the probe dir, with HOME redirected |

Reads outside `REPO_DIR`: `$HOME/.claude/logs/usage.jsonl` (`USAGE_LOG_FILE`), `/opt/claude-workflows` (the root-owned review skill), and `--seed-file`.
**Credentials, git config and hooks:** the script writes none of them.
**Installed copy:** `~/.claude/scripts/self-improvement.sh` matches the repo's copy byte for byte. Its default `REPO_DIR` is `~/.claude`, which is not a git repo, so `require_clean_main` refuses before the first write. Checked on a copy: it refused, and wrote nothing.

## 2. The hermetic run

Probe scripts: `$CLAUDE_JOB_DIR/tmp/q075/{probe.sh,stub-claude.sh}` (scratch; not committed).

- **Setup:** a `--no-hardlinks` clone of f66fd9f2. `claude` on PATH was a stub that logs each call and plays the part each prompt expects:
  - ideas, problems, tasks, two implementers (each committing a `fix:`), self-eval with its baseline, code-review (the nonced sentinel plus a rubric), solved-problems, and the FP harvest;
  - round 2 answers `DONE`.
- **Redirected:** `HOME`, `TMPDIR`, `REPO_DIR` and `WORKTREE_BASE` pointed into the probe dir, with `GIT_CONFIG_NOSYSTEM=1`.
- **Canaries:** a branch, and a stale worktree registration.
- **Real bats ran,** not stubbed.
- **Result:** exit 0 in 1367 s, almost all of it three full bats passes.
  - 12 claude calls, none unmatched.
  - Round 1: 2 launched, 2 approved, 2 merged, plus the FP-harvest commit. Round 2 stopped as exhausted.
- **Diff, `/workspace` git state:** refs, worktree list, local config and the hooks dir are identical before and after.
- **Diff, whole filesystem:** `find -newer` across `/`, `/workspace` and `/home/node/.claude` found 6 paths, none from the loop:
  - `~/.npm/_logs` and the npm cache: Claude Code's own `npm view @anthropic-ai/claude-code` update check, with `cwd /home/node`;
  - `/run/cc-sni-proxy/proxy.log`;
  - this session's task output;
  - `/workspace/.git`'s mtime, from my own `git -C /workspace` reads during the window.
- **Diff, redirected HOME:** empty after the run.
- **Diff, the clone:** main advanced by exactly the two merges and the harvest commit. The canary branch and the user branch survived. **The canary worktree registration was pruned.**

**Not covered by the stub:** what real children write. That is §3.

## 3. The children: 12 `claude -p` call sites

| Call | cwd | Flags |
|---|---|---|
| ideas, tasks, merge-conflict resolver, FP harvest | `REPO_DIR` | `acceptEdits` |
| problem extraction, convergence overlap, solved problems, contrastive note | `REPO_DIR` | none |
| implementer, self-eval (branch) | worktree | `acceptEdits` |
| self-eval (baseline) | `mktemp -d` | `acceptEdits` |
| code-review gate | worktree | `acceptEdits --add-dir /opt/claude-workflows --model opus` |

What bounds a child, as measured here (cc-isolated, 2026-10-14):

- **Edit/Write.** `acceptEdits` auto-accepts writes under cwd and `--add-dir`. **Live check:** a Write to `.git/probe-written.txt` was *denied* as a sensitive path. Writes outside cwd are denied in `-p`. `permissions.deny` and `guard-trusted-writes.py` cover `~/.claude` settings, hooks and CLAUDE.md.
- **Bash.** A command runs only if the settings allowlist or `auto-approve-allowed-commands.sh` approves it. Anything else is denied in `-p`. **Live check:** `git add a.txt && git commit -m test` was denied in a repo with no project settings.
- **Claude Code's own state** goes to the real HOME: a transcript per cwd under `~/.claude/projects/<slug>/` (live check: one appeared), and the usage log via `log-usage.sh` whenever a child uses Skill, Read or Agent.

## 4. Findings

| # | Sev | Finding | Evidence |
|---|---|---|---|
| F1 | High | A child whose cwd is `/workspace` can write a `.bats` file (auto-accepted) and then run it under `Bash(bats test:*)`, which `.claude/settings.json` allows and the hook approves. That is arbitrary code as `node`: the whole home dir, other sessions' worktrees, readable credentials. The guard hook inspects tool-call text, not what a test file does. `bash scripts/run-tests.sh` (`.claude/settings.json`) is the same shape, but there the hook gives no decision, so it was not shown to be approved | hook test: `bats test/evil.bats` → `allow` from `/workspace` |
| F2 | High | The same children can force-delete any branch in the shared repo: `git -C /workspace branch:*` is allowed, and that covers other sessions' build-loop branches | hook test: `git -C /workspace branch -D main` → `allow` |
| F3 | Med | The loop's defaults merge into the **shared checkout's** main, and HEAD is checked once, at start. Other sessions switch `/workspace`'s branch (memory), so a mid-run switch sends merges to the wrong branch. Landing also skips today's rules: pr-prep, the health-check gate, and the user's approval for gate code | script, step 5; probe: 3 commits on main |
| F4 | Med | `git worktree prune` is repo-wide. `/home/magfrump/cw-egress-verify` is missing *inside the container* but is a host worktree, so a run from `/workspace` would delete its admin dir and break that worktree on the host | probe canary; `git worktree list` shows it `prunable` |
| F5 | Med (function) | In worktrees there are no project settings, so implementers cannot commit and the code-review child cannot run `git diff`. Every task fails Gate 1a after the round has paid for ideas, planning and implementation | live haiku check: commit denied |
| F6 | Low | Each task copies every committed review (1317 files, 36 MB) into a gitignored archive that is never pruned: about 0.5 GB for a 3-round, 5-task run. The advisory replication check reads a stale committed fact-check report (5ee8315) every time | probe |
| F7 | Low | Children add a transcript dir per worktree under `~/.claude/projects/`, and their Skill, Read and Agent use lands in `usage.jsonl`. The morning summary and script-evaluated hypotheses read that log, so the loop's own activity counts as usage evidence | live check; `si-morning-summary.sh:1230` |

## 5. What would make a first real run safe

1. **Point `REPO_DIR` at a dedicated clone** (the probe shows the override works). That removes F3 and F4 for the shared repo, and F1 and F2 too, since a clone has no `.claude/settings.json`. Its approved work comes back to `/workspace` through the usual review-and-merge path.
2. **Decide how implementers get to commit (F5): decided and built.** Q-146 was answered [1] on 2026-10-15: the script commits for the child. Since `feat/q146-si-script-commits`, each child writes `.si-commit-msg`, and Gate 1a's `si_commit_child_work` (`scripts/lib/si-commit.sh`) commits for it, so the children get no new grant. The options were:
   - a narrow per-run settings file for the children (`--settings` with exactly `git add`/`git commit`), without the bats grant from F1;
   - have the script commit on the child's behalf after it exits;
   - keep the loop dormant.
3. Before any run from a checkout that has worktrees: scope `prune` to the run's own registrations (F4), and copy only the reviews this run wrote (F6).

The live run Q-075 imagines, with real children, should happen only after (1) and (2). (2) is now done; (1) is that run's own setup.
Done before them, it would show either the inert loop (F5) or the unconfined one (F1).
