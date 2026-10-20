# Research and plan: self-improvement.sh commits for its implementer (Q-146 [1])

Brief: `docs/working/briefs/2026-10-17-q146-si-script-commits.md` (at d2cd20c3).
Workflow: research-plan-implement, no plan-approval gate; divergent design inline.

## What the code does today

- Step 3 of `scripts/self-improvement.sh` starts one background subshell per task:
  `cd "$WT_DIR"; claude -p --permission-mode acceptEdits "<prompt>"`. The prompt opens
  "You are in /away mode. Commit locally when done." and asks for descriptive commits in
  the Autonomous Commit Format. The subshell's last command is `claude`, so bash usually
  execs it, and `cleanup()` relies on the tracked PID being `claude` or its parent.
- Step 4 (validation) runs sequentially from `REPO_DIR`. Gate 1a counts
  `main..feat/rN-ID` and rejects with `no commits on branch` when it is zero.
- In a worktree or a dedicated clone the child has no Bash grant, so it cannot run
  `git commit` (F5 in `docs/working/si-trust-evidence-2026-10-14.md`): every task fails
  Gate 1a.

## Hooks: what the other git calls do

None of the script's git calls switch hooks off: `git worktree add`, `git merge "$BRANCH"
--no-edit`, the failure-pattern harvest `git commit -m`, and the rest run with whatever
the repository's config names. This repo sets no `core.hooksPath` and has no installed
git hooks (`hooks/live-verify-gate.sh` is a Claude Code PreToolUse hook, not a git hook).

So there is no existing pattern to copy, and the new commit sets its own:
`git -c core.hooksPath=/dev/null commit --no-verify`. The reason is H1. This commit runs
as the script, on a tree the child just wrote. If `REPO_DIR`'s config named a tracked
hooks directory (`core.hooksPath=hooks`, a common setup), the child could edit
`hooks/pre-commit` in its worktree, and the script's own commit would then run code the
child wrote, outside the child's permission mode. Pointing `core.hooksPath` at
`/dev/null` disables every hook, post-commit included. `--no-verify` is kept as a second,
independent switch for pre-commit and commit-msg.

Review round 1 found a wider version of the same hole. The worktree's `.git` is itself a
child-writable file. A child could point it at a git dir it made, whose config sets
`core.fsmonitor` to its own script, and then the script's `git add` would run that code
(the reviewer reproduced this). So the helper also pins the git dir. It takes the repo
(`REPO_DIR`) as a trusted argument. Round 2 found that "any entry under `worktrees/`" was
not enough: pointing `.git` at a sibling worktree's admin dir committed onto the
sibling's branch (reproduced). The helper now finds the admin dir from the repo's own
records: the `worktrees/<name>/gitdir` file whose target resolves (`pwd -P`) to this
worktree. It then requires the child's `.git` to be a regular file that points at that
same dir; anything else is a loud refusal. Every git call gets `--git-dir`/`--work-tree`
explicitly, plus `-c core.fsmonitor=false`, with `GIT_INDEX_FILE`,
`GIT_OBJECT_DIRECTORY` and `GIT_ALTERNATE_OBJECT_DIRECTORIES` unset. The child cannot write the admin dir or the common
config, since both sit outside its cwd. Gate 1e still runs child-written bats as the
script; that is a pre-existing exposure, outside this brief.

## Design choices (divergent design, seeded with the constraints)

### D1: where the commit runs

| Option | H2 loud failure | Touches trap/exec path | Cost |
|---|---|---|---|
| A. In the background subshell, after `claude` exits | needs a status file per task to reach Gate 1a | yes: `claude` stops being the last command, which changes what `cleanup()` kills | IPC plus trap risk |
| **B. In the validation loop, just before Gate 1a** | the return code feeds `REJECT_REASON` directly | no | a few lines |
| C. A separate pass between `wait` and validation | as B, but the result must be carried to the gate | no | one more loop |

B dominates: all children have exited by then (the brief's "after the child exits"), the
commit result goes straight into the task's reject reason, and the subshell's exec
behaviour, which the SIGTERM test (A2) pins, stays as it is.

### D2: where the new code lives (S8)

| Option | Large-file growth | Testable by sourcing | Matches prior art |
|---|---|---|---|
| A. Inline in `self-improvement.sh` (1929 lines) | grows it | only through the main loop | no |
| B. Append to `scripts/lib/si-functions.sh` (713 lines) | grows a file already past 400 | yes | partly |
| **C. New sourced `scripts/lib/si-commit.sh`** | none; the main script gains about 20 lines of call site | yes, alone | yes (`si-input.sh`, `si-morning-summary.sh`) |

C dominates. The main script gets only the call site in Gate 1a, the prompt change and
one `source` line.

### D3: the message file

- Name: `.si-commit-msg` at the worktree root. The child's writes are confined to its cwd
  (the worktree), so the file must be inside it. A dot name keeps it out of the way.
- Staging: `git add -A -- . ':(exclude).si-commit-msg'` from the worktree root. Files
  the repo's `.gitignore` names stay unstaged, as with any `git add -A`; in this repo that
  covers the generated `docs/working/research-*.md` and `plan-*.md`, which are local by
  convention.
- Message: the file if it is a regular file holding a non-blank character, otherwise the
  task description written to a temp file. Both are passed with `git commit -F` (the
  description is model-written text; it never goes through a shell string). The fallback
  appends a `Confidence: low` / `Notes:` trailer saying the implementer wrote no message,
  so the commit still follows the Autonomous Commit Format.
- A message path that is a symlink or not a regular file fails the task loudly instead of
  being read. A symlink would let the script, not the child, read a file outside the
  worktree into a commit message. The child cannot make one today (it has no Bash), so
  this costs one test.

### D4: outcomes and how Gate 1a names them

`si_commit_child_work WT DESC` returns 0 when it made a commit, 3 when there was nothing
to commit, and 1 on any failure, with a message on stderr naming the cause (git's stderr
included). In Gate 1a:

- 1 → reject `implementer commit failed: <why>` (H2: never silent).
- 3 with no commits on the branch → reject `no commits on branch (implementer left no
  changes)`.
- 3 with commits (a child that could commit, say in a host checkout) → pass, unchanged.
- 0 with no commits on the branch → reject `implementer commit failed: the commit did
  not land on <branch>`. This is a belt-and-braces check, added in review round 1.

The message file is deleted after a successful commit, so later gates see a clean
worktree. A multi-line git error is joined onto one line for the reject reason.

### Rejected: a per-run `--settings` grant for `git add`/`git commit`

This was the other F5 option. Q-146 answered [1] (the script commits), so it is not
reopened here.

## Plan

1. `scripts/lib/si-commit.sh`: `SI_COMMIT_MSG_FILE` and `si_commit_child_work`.
2. `scripts/self-improvement.sh`: source the lib. The implementer prompt tells the child
   to write its message to `.si-commit-msg` and never run `git commit`. Gate 1a calls the
   helper first.
3. Tests:
   - `test/si-commit-child-work.bats` (unit): message file used and not committed;
     description fallback; no change returns 3 and makes no commit; symlinked message
     file refused; hooks named by repo config do not run; a commit failure is non-zero
     and names the cause.
   - `test/scripts/self-improvement-clean-state.bats`: the implementer stub writes
     changes and a message file instead of committing, and refuses a `git commit`
     argument. New end-to-end cases: the message file's subject lands on the branch and
     the file is not committed; no message file means the description is used; no
     change means a named rejection.
4. Docs: `guides/validation-gates.md` Gate 1a, and the evidence doc's §5 item 2.

Line budget: the lib is about 70 lines and the main script gains about 25. The diff stays
well under the 400-line cap.

## Follow-on (not run here)

Q-146's live run: one self-improvement round with `REPO_DIR` a dedicated clone, never
`/workspace`, with real children. It needs the host or a clone and is filed separately.
