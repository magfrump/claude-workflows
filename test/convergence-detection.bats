#!/usr/bin/env bats
# @category fast
# Unit tests for check_convergence_threshold from self-improvement.sh
#
# Usage: bats test/convergence-detection.bats

setup() {
  # Source self-improvement.sh for its functions without running the main loop.
  # The main-execution guard (if [[ BASH_SOURCE == $0 ]]) prevents the
  # top-level loop from executing when sourced.
  source "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"
}

# --- (a) 0% overlap returns below threshold ---

@test "0% overlap is below default 70% threshold" {
  run check_convergence_threshold 0 70
  [ "$status" -eq 1 ]
}

# --- (b) exact-threshold 70% returns at-or-above ---

@test "exact 70% overlap meets 70% threshold" {
  run check_convergence_threshold 70 70
  [ "$status" -eq 0 ]
}

# --- (c) 100% overlap returns above ---

@test "100% overlap is above 70% threshold" {
  run check_convergence_threshold 100 70
  [ "$status" -eq 0 ]
}

# --- (d) empty/invalid input handled gracefully ---

@test "empty overlap returns below (graceful)" {
  run check_convergence_threshold "" 70
  [ "$status" -eq 1 ]
}

@test "empty threshold returns below (graceful)" {
  run check_convergence_threshold 50 ""
  [ "$status" -eq 1 ]
}

@test "missing arguments returns below (graceful)" {
  run check_convergence_threshold
  [ "$status" -eq 1 ]
}

@test "non-numeric overlap returns below (graceful)" {
  run check_convergence_threshold "abc" 70
  [ "$status" -eq 1 ]
}

@test "non-numeric threshold returns below (graceful)" {
  run check_convergence_threshold 50 "xyz"
  [ "$status" -eq 1 ]
}
