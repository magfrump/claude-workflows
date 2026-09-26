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

  # Stub the claude CLI so no sourced self-improvement function can ever
  # reach the real one (live LLM call + sandbox network prompt).
  # Convention enforced by test/fixture-hermeticity.bats.
  mkdir -p "$BATS_TEST_TMPDIR/stub-bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$BATS_TEST_TMPDIR/stub-bin/claude"
  chmod +x "$BATS_TEST_TMPDIR/stub-bin/claude"
  PATH="$BATS_TEST_TMPDIR/stub-bin:$PATH"
}

@test "untrack removes the targeted pair and leaves the others in order" {
  RUN_WORKTREES=("/wt/a" "/wt/b" "/wt/c")
  RUN_BRANCHES=("feat/a" "feat/b" "feat/c")

  untrack_worktree_and_branch "/wt/b" "feat/b"

  [ "${RUN_WORKTREES[*]}" = "/wt/a /wt/c" ]
  [ "${RUN_BRANCHES[*]}" = "feat/a feat/c" ]
}

# The two set -u tests below cannot catch a missing ${arr[@]:-} guard: bash
# >= 4.4 no longer aborts on an empty-array expansion under set -u, and
# BASH_COMPAT does not bring the old behaviour back (mutation-checked
# 2026-09-26: removing every :- guard kept this suite green). They pin the
# drain and empty-array no-op behaviour, which is what they can constrain.
@test "untrack draining the last tracked pair leaves both arrays empty" {
  set -u
  RUN_WORKTREES=("/wt/only")
  RUN_BRANCHES=("feat/only")

  untrack_worktree_and_branch "/wt/only" "feat/only"

  [ "${#RUN_WORKTREES[@]}" -eq 0 ]
  [ "${#RUN_BRANCHES[@]}" -eq 0 ]
}

@test "untrack is a no-op when the arrays are already empty" {
  set -u
  RUN_WORKTREES=()
  RUN_BRANCHES=()

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
