#!/usr/bin/env bats
# @category slow
# Regression tests for the worktree/branch run-tracking cleanup helper added to
# close the four SI worktree/branch cleanup gaps.
#
# Focus: untrack_worktree_and_branch (gap 3) — after a worktree/branch pair is
# deliberately disposed of (deleted, or retained for manual recovery), it must
# be dropped from RUN_WORKTREES/RUN_BRANCHES so the EXIT trap stops re-processing
# it. The helper must be safe under `set -u`, including the drain-to-empty case
# (an empty `RUN_*` array read without the `${arr[@]:-}` guard would abort the
# whole run under `set -euo pipefail`).
#
# Usage: bats test/worktree-cleanup-functions.bats

setup() {
  # Source self-improvement.sh for its functions without running the main loop.
  # The main-execution guard (if [[ BASH_SOURCE == $0 ]]) prevents the
  # top-level loop from executing when sourced.
  source "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
}

@test "untrack removes the targeted pair and leaves the others in order" {
  RUN_WORKTREES=("/wt/a" "/wt/b" "/wt/c")
  RUN_BRANCHES=("feat/a" "feat/b" "feat/c")

  untrack_worktree_and_branch "/wt/b" "feat/b"

  [ "${RUN_WORKTREES[*]}" = "/wt/a /wt/c" ]
  [ "${RUN_BRANCHES[*]}" = "feat/a feat/c" ]
}

@test "untrack draining the last tracked pair leaves both arrays empty under set -u" {
  set -u
  RUN_WORKTREES=("/wt/only")
  RUN_BRANCHES=("feat/only")

  untrack_worktree_and_branch "/wt/only" "feat/only"

  [ "${#RUN_WORKTREES[@]}" -eq 0 ]
  [ "${#RUN_BRANCHES[@]}" -eq 0 ]
}

@test "untrack is safe to call when the arrays are already empty (set -u guard)" {
  set -u
  RUN_WORKTREES=()
  RUN_BRANCHES=()

  # Exercises the ${arr[@]:-} guard directly: an unguarded empty-array read
  # here would abort under set -u rather than no-op.
  untrack_worktree_and_branch "/wt/none" "feat/none"

  [ "${#RUN_WORKTREES[@]}" -eq 0 ]
  [ "${#RUN_BRANCHES[@]}" -eq 0 ]
}

@test "untrack of an untracked pair is a no-op (no accidental drops)" {
  RUN_WORKTREES=("/wt/a")
  RUN_BRANCHES=("feat/a")

  untrack_worktree_and_branch "/wt/missing" "feat/missing"

  [ "${RUN_WORKTREES[*]}" = "/wt/a" ]
  [ "${RUN_BRANCHES[*]}" = "feat/a" ]
}
