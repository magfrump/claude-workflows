#!/usr/bin/env bats
# @category fast
# Unit tests for si_commit_child_work (scripts/lib/si-commit.sh): the loop
# commits each implementer's work for it, since the children have no Bash grant
# to run git commit (Q-146 [1]). The main-loop wiring (Gate 1a) is pinned by
# test/scripts/self-improvement-clean-state.bats.
#
# Usage: bats test/si-commit-child-work.bats

bats_require_minimum_version 1.5.0

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-commit.sh"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  export TMPDIR="$BATS_TEST_TMPDIR"
  # A task worktree of a repo, as the loop makes them.
  REPO="$BATS_TEST_TMPDIR/repo"
  WT="$BATS_TEST_TMPDIR/wt"
  git init -q -b main "$REPO"
  echo base > "$REPO/a.txt"
  git -C "$REPO" add . && git -C "$REPO" commit -qm init
  git -C "$REPO" worktree add -q "$WT" -b feat/t main
  BASE=$(git -C "$WT" rev-parse HEAD)
}

commit_work() { si_commit_child_work "$WT" "$1" "$REPO"; }

@test "the child's message file becomes the commit message and is not committed" {
  echo changed > "$WT/a.txt"
  echo new > "$WT/b.txt"
  printf 'feat: from the child\n\nConfidence: high\n' > "$WT/$SI_COMMIT_MSG_FILE"
  run commit_work "task description"
  [ "$status" -eq 0 ]
  [ "$(git -C "$REPO" rev-list --count main..feat/t)" -eq 1 ]
  [ "$(git -C "$WT" log -1 --format=%s)" = "feat: from the child" ]
  git -C "$WT" log -1 --format=%B | grep -qx 'Confidence: high'
  run git -C "$WT" ls-tree -r --name-only HEAD
  [[ "$output" == *"b.txt"* ]]
  [[ "$output" != *"$SI_COMMIT_MSG_FILE"* ]]
  [ "$(git -C "$WT" show HEAD:a.txt)" = changed ]
  # Removed once used, so later gates see a clean worktree.
  [ ! -e "$WT/$SI_COMMIT_MSG_FILE" ]
  [ -z "$(git -C "$WT" status --porcelain)" ]
}

@test "with no message file the task description is the message" {
  echo changed > "$WT/a.txt"
  run commit_work "fix: the task description"
  [ "$status" -eq 0 ]
  [ "$(git -C "$WT" log -1 --format=%s)" = "fix: the task description" ]
  git -C "$WT" log -1 --format=%B | grep -qx 'Confidence: low'
}

@test "a blank message file falls back to the task description" {
  echo changed > "$WT/a.txt"
  printf '  \n\n' > "$WT/$SI_COMMIT_MSG_FILE"
  run commit_work "fix: fallback"
  [ "$status" -eq 0 ]
  [ "$(git -C "$WT" log -1 --format=%s)" = "fix: fallback" ]
}

@test "a description that looks like shell is only ever message text" {
  echo changed > "$WT/a.txt"
  # shellcheck disable=SC2016
  run commit_work 'x $(touch pwned) `touch pwned2`'
  [ "$status" -eq 0 ]
  [ ! -e "$WT/pwned" ] && [ ! -e "$WT/pwned2" ] && [ ! -e pwned ]
  # shellcheck disable=SC2016
  [ "$(git -C "$WT" log -1 --format=%s)" = 'x $(touch pwned) `touch pwned2`' ]
}

@test "no change returns 3 and makes no commit, even with a message file" {
  echo 'feat: nothing' > "$WT/$SI_COMMIT_MSG_FILE"
  run commit_work "task"
  [ "$status" -eq 3 ]
  [ "$(git -C "$WT" rev-parse HEAD)" = "$BASE" ]
}

@test "a symlinked message file is refused, not read" {
  echo changed > "$WT/a.txt"
  echo 'secret' > "$BATS_TEST_TMPDIR/outside"
  ln -s "$BATS_TEST_TMPDIR/outside" "$WT/$SI_COMMIT_MSG_FILE"
  run commit_work "task"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a regular file"* ]]
  [ "$(git -C "$WT" rev-parse HEAD)" = "$BASE" ]
}

@test "hooks the repository's config names do not run" {
  mkdir -p "$WT/hooks"
  for h in pre-commit commit-msg post-commit; do
    printf '#!/bin/sh\ntouch "%s/ran-%s"\n' "$BATS_TEST_TMPDIR" "$h" > "$WT/hooks/$h"
    chmod +x "$WT/hooks/$h"
  done
  git -C "$REPO" config core.hooksPath hooks
  echo changed > "$WT/a.txt"
  run commit_work "task"
  [ "$status" -eq 0 ]
  [ ! -e "$BATS_TEST_TMPDIR/ran-pre-commit" ]
  [ ! -e "$BATS_TEST_TMPDIR/ran-commit-msg" ]
  [ ! -e "$BATS_TEST_TMPDIR/ran-post-commit" ]
}

@test "a .git the child repointed at its own git dir is refused before git runs" {
  # A child-made git dir whose config would run code on `git add`.
  git init -q "$WT/evil"
  printf '#!/bin/sh\ntouch "%s/ran-fsmonitor"\n' "$BATS_TEST_TMPDIR" > "$WT/fsm"
  chmod +x "$WT/fsm"
  git -C "$WT/evil" config core.fsmonitor "$WT/fsm"
  printf 'gitdir: %s/evil/.git\n' "$WT" > "$WT/.git"
  echo changed > "$WT/a.txt"
  run commit_work "task"
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not point at its own admin dir"* ]]
  [ ! -e "$BATS_TEST_TMPDIR/ran-fsmonitor" ]
}

@test "a .git repointed at a sibling worktree's admin dir commits nothing anywhere" {
  git -C "$REPO" worktree add -q "$BATS_TEST_TMPDIR/wt2" -b feat/t2 main
  printf 'gitdir: %s\n' "$(git -C "$BATS_TEST_TMPDIR/wt2" rev-parse --absolute-git-dir)" > "$WT/.git"
  echo changed > "$WT/a.txt"
  echo 'feat: injected' > "$WT/$SI_COMMIT_MSG_FILE"
  run commit_work "task"
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not point at its own admin dir"* ]]
  [ "$(git -C "$REPO" rev-list --count main..feat/t2)" -eq 0 ]
  [ "$(git -C "$REPO" rev-list --count main..feat/t)" -eq 0 ]
}

@test "a directory that is not a registered worktree is refused" {
  mkdir "$BATS_TEST_TMPDIR/plain"
  printf 'gitdir: %s\n' "$(git -C "$WT" rev-parse --absolute-git-dir)" > "$BATS_TEST_TMPDIR/plain/.git"
  run si_commit_child_work "$BATS_TEST_TMPDIR/plain" "task" "$REPO"
  [ "$status" -eq 1 ]
  [[ "$output" == *"is not a registered worktree"* ]]
}

@test "an fsmonitor the repo's config points into the tree does not run" {
  printf '#!/bin/sh\ntouch "%s/ran-fsmonitor"\n' "$BATS_TEST_TMPDIR" > "$WT/fsm"
  chmod +x "$WT/fsm"
  git -C "$REPO" config core.fsmonitor "$WT/fsm"
  echo changed > "$WT/a.txt"
  run commit_work "task"
  [ "$status" -eq 0 ]
  [ ! -e "$BATS_TEST_TMPDIR/ran-fsmonitor" ]
}

@test "a .git that escapes the worktrees dir through .. is refused" {
  local gd
  gd=$(git -C "$REPO" rev-parse --absolute-git-dir)
  printf 'gitdir: %s/worktrees/../..\n' "$gd" > "$WT/.git"
  echo changed > "$WT/a.txt"
  run commit_work "task"
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not point at its own admin dir"* ]]
}

@test "a .git that is not a regular file is refused" {
  rm "$WT/.git"
  ln -s "$(git -C "$REPO" rev-parse --absolute-git-dir)" "$WT/.git"
  run commit_work "task"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a worktree link file"* ]]
}

@test "a failing commit is non-zero and names the cause" {
  echo changed > "$WT/a.txt"
  # No identity at all: git refuses to commit.
  unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  git -C "$REPO" config user.useConfigOnly true
  run commit_work "task"
  [ "$status" -eq 1 ]
  [[ "$output" == *"git commit failed in"* ]]
  [ "$(git -C "$WT" rev-parse HEAD)" = "$BASE" ]
}

@test "a missing worktree is a named failure" {
  run si_commit_child_work "$BATS_TEST_TMPDIR/nope" "task" "$REPO"
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not exist"* ]]
}
