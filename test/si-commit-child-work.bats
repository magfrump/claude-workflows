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
  WT="$BATS_TEST_TMPDIR/wt"
  mkdir -p "$WT"
  git -C "$WT" init -q -b main
  echo base > "$WT/a.txt"
  git -C "$WT" add . && git -C "$WT" commit -qm init
  BASE=$(git -C "$WT" rev-parse HEAD)
}

@test "the child's message file becomes the commit message and is not committed" {
  echo changed > "$WT/a.txt"
  echo new > "$WT/b.txt"
  printf 'feat: from the child\n\nConfidence: high\n' > "$WT/$SI_COMMIT_MSG_FILE"
  run si_commit_child_work "$WT" "task description"
  [ "$status" -eq 0 ]
  [ "$(git -C "$WT" rev-list --count "$BASE..HEAD")" -eq 1 ]
  [ "$(git -C "$WT" log -1 --format=%s)" = "feat: from the child" ]
  git -C "$WT" log -1 --format=%B | grep -qx 'Confidence: high'
  run git -C "$WT" ls-tree -r --name-only HEAD
  [[ "$output" == *"b.txt"* ]]
  [[ "$output" != *"$SI_COMMIT_MSG_FILE"* ]]
  [ "$(git -C "$WT" show HEAD:a.txt)" = changed ]
}

@test "with no message file the task description is the message" {
  echo changed > "$WT/a.txt"
  run si_commit_child_work "$WT" "fix: the task description"
  [ "$status" -eq 0 ]
  [ "$(git -C "$WT" log -1 --format=%s)" = "fix: the task description" ]
  git -C "$WT" log -1 --format=%B | grep -qx 'Confidence: low'
}

@test "a blank message file falls back to the task description" {
  echo changed > "$WT/a.txt"
  printf '  \n\n' > "$WT/$SI_COMMIT_MSG_FILE"
  run si_commit_child_work "$WT" "fix: fallback"
  [ "$status" -eq 0 ]
  [ "$(git -C "$WT" log -1 --format=%s)" = "fix: fallback" ]
}

@test "a description that looks like shell is only ever message text" {
  echo changed > "$WT/a.txt"
  # shellcheck disable=SC2016
  run si_commit_child_work "$WT" 'x $(touch pwned) `touch pwned2`'
  [ "$status" -eq 0 ]
  [ ! -e "$WT/pwned" ] && [ ! -e "$WT/pwned2" ] && [ ! -e pwned ]
  # shellcheck disable=SC2016
  [ "$(git -C "$WT" log -1 --format=%s)" = 'x $(touch pwned) `touch pwned2`' ]
}

@test "no change returns 3 and makes no commit, even with a message file" {
  echo 'feat: nothing' > "$WT/$SI_COMMIT_MSG_FILE"
  run si_commit_child_work "$WT" "task"
  [ "$status" -eq 3 ]
  [ "$(git -C "$WT" rev-parse HEAD)" = "$BASE" ]
}

@test "a symlinked message file is refused, not read" {
  echo changed > "$WT/a.txt"
  echo 'secret' > "$BATS_TEST_TMPDIR/outside"
  ln -s "$BATS_TEST_TMPDIR/outside" "$WT/$SI_COMMIT_MSG_FILE"
  run si_commit_child_work "$WT" "task"
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
  git -C "$WT" config core.hooksPath hooks
  echo changed > "$WT/a.txt"
  run si_commit_child_work "$WT" "task"
  [ "$status" -eq 0 ]
  [ ! -e "$BATS_TEST_TMPDIR/ran-pre-commit" ]
  [ ! -e "$BATS_TEST_TMPDIR/ran-commit-msg" ]
  [ ! -e "$BATS_TEST_TMPDIR/ran-post-commit" ]
}

@test "a failing commit is non-zero and names the cause" {
  echo changed > "$WT/a.txt"
  # No identity at all: git refuses to commit.
  unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  git -C "$WT" config user.useConfigOnly true
  run si_commit_child_work "$WT" "task"
  [ "$status" -eq 1 ]
  [[ "$output" == *"git commit failed in"* ]]
  [ "$(git -C "$WT" rev-parse HEAD)" = "$BASE" ]
}

@test "a missing worktree is a named failure" {
  run si_commit_child_work "$BATS_TEST_TMPDIR/nope" "task"
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not exist"* ]]
}
