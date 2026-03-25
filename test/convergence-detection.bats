#!/usr/bin/env bats
# Tests for the convergence threshold comparison extracted from self-improvement.sh.
#
# Central use cases:
#   (a) 0% overlap → below threshold
#   (b) exact-threshold overlap → at-or-above (converged)
#   (c) 100% overlap → above threshold (converged)
#   (d) empty/missing inputs → gracefully returns not-converged

LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../lib" && pwd)"

setup() {
  source "$LIB_DIR/convergence.sh"
}

# --- (a) 0% overlap returns below threshold ---

@test "0% overlap is below default 70% threshold" {
  run check_convergence_threshold 0 70
  [ "$status" -eq 1 ]
}

@test "0% overlap is below 1% threshold" {
  run check_convergence_threshold 0 1
  [ "$status" -eq 1 ]
}

# --- (b) exact-threshold overlap returns at-or-above ---

@test "exact threshold (70/70) returns converged" {
  run check_convergence_threshold 70 70
  [ "$status" -eq 0 ]
}

@test "exact threshold (50/50) returns converged" {
  run check_convergence_threshold 50 50
  [ "$status" -eq 0 ]
}

@test "one below threshold (69/70) returns not converged" {
  run check_convergence_threshold 69 70
  [ "$status" -eq 1 ]
}

# --- (c) 100% overlap returns above threshold ---

@test "100% overlap is above 70% threshold" {
  run check_convergence_threshold 100 70
  [ "$status" -eq 0 ]
}

@test "100% overlap is above 100% threshold (exact match)" {
  run check_convergence_threshold 100 100
  [ "$status" -eq 0 ]
}

# --- (d) empty problem sets handled gracefully ---

@test "empty overlap returns not converged" {
  run check_convergence_threshold "" 70
  [ "$status" -eq 1 ]
}

@test "empty threshold returns not converged" {
  run check_convergence_threshold 70 ""
  [ "$status" -eq 1 ]
}

@test "both empty returns not converged" {
  run check_convergence_threshold "" ""
  [ "$status" -eq 1 ]
}

@test "non-numeric overlap returns not converged" {
  run check_convergence_threshold "abc" 70
  [ "$status" -eq 1 ]
}

@test "non-numeric threshold returns not converged" {
  run check_convergence_threshold 70 "xyz"
  [ "$status" -eq 1 ]
}
