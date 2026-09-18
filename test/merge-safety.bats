#!/usr/bin/env bats
# @category fast
# Unit tests for the merge-safety helpers in scripts/lib/si-functions.sh:
#   require_clean_main, merge_landed
#
# Regression: the merge step inferred "conflict resolved" from the absence of
# unmerged paths. A merge git REFUSES (dirty tree) also leaves zero unmerged
# paths, so an unmerged branch was recorded as merged and logged as completed.
#
# Usage: bats test/merge-safety.bats

load lib/hermetic-env

# Output assertions below match stderr text; keep setlocale noise out of it.
pin_hermetic_locale

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-functions.sh"
  # Hermetic git: no user/system config (signing, hooks, default branch).
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  REPO=$(mktemp -d)
  cd "$REPO" || return 1
  git init -q -b main
  echo a > f && git add f && git commit -qm init
  # A task branch that edits the tracked file f.
  git switch -qc task && echo b > f && git commit -qam task && git switch -q main
}

teardown() {
  rm -rf "$REPO"
}

# --- merge_landed ---

@test "merge_landed is false for a merge git refused over a dirty tree" {
  echo dirty > f
  run git merge task --no-edit
  [ "$status" -ne 0 ]
  # The old check's signal: no unmerged paths. It reads as "resolved"...
  [ -z "$(git diff --name-only --diff-filter=U)" ]
  # ...but the branch never landed.
  run merge_landed task
  [ "$status" -ne 0 ]
}

@test "merge_landed is false while a resolved merge is staged but uncommitted" {
  git switch -qc other main && echo c > f && git commit -qam other && git switch -q main
  git merge -q other --no-edit
  run git merge task --no-edit
  [ "$status" -ne 0 ]
  echo resolved > f && git add f   # resolved, never committed
  [ -z "$(git diff --name-only --diff-filter=U)" ]
  run merge_landed task
  [ "$status" -ne 0 ]
}

@test "merge_landed is true after a clean merge" {
  git merge -q task --no-edit
  run merge_landed task
  [ "$status" -eq 0 ]
}

# --- require_clean_main ---

@test "require_clean_main passes on clean main, ignoring untracked files" {
  echo scratch > untracked.txt
  run require_clean_main
  [ "$status" -eq 0 ]
}

@test "require_clean_main refuses when HEAD is not main" {
  git switch -q task
  run require_clean_main
  [ "$status" -eq 1 ]
  [[ "$output" == *"HEAD is 'task'"* ]]
}

@test "require_clean_main refuses a modified tracked file" {
  echo dirty > f
  run require_clean_main
  [ "$status" -eq 1 ]
  [[ "$output" == *"uncommitted changes"* ]]
}

@test "require_clean_main refuses a staged change" {
  echo new > g && git add g
  run require_clean_main
  [ "$status" -eq 1 ]
}
