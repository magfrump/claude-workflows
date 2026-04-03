#!/usr/bin/env bats
# @category fast

# Tests for print_round_summary() from scripts/self-improvement.sh
# Verifies correct count extraction, failure mode formatting, and file append.

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"

  TEST_TMPDIR=$(mktemp -d)
  export WORKING_DIR="$TEST_TMPDIR"
  ROUND_HISTORY="$TEST_TMPDIR/round-history.json"
  echo '[]' > "$ROUND_HISTORY"

  VALIDATION_LOG="$TEST_TMPDIR/validation.log"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
  if [ -n "${ROUND_LOG_FILE:-}" ] && [ -f "$ROUND_LOG_FILE" ]; then
    rm -f "$ROUND_LOG_FILE"
  fi
}

@test "all-approved round shows correct launched/approved/rejected counts" {
  init_round_log 1

  record_gate "task-a" "lint" "pass"
  record_gate "task-a" "test" "pass"
  record_gate "task-a" "verdict" "approved"

  record_gate "task-b" "lint" "pass"
  record_gate "task-b" "verdict" "approved"

  record_gate "task-c" "test" "pass"
  record_gate "task-c" "verdict" "approved"

  run print_round_summary 1 "$VALIDATION_LOG"

  [ "$status" -eq 0 ]
  [ "$output" = "Round 1: 3 launched, 3 approved, 0 rejected" ]
}

@test "mixed results with failures extracts and formats failure modes" {
  init_round_log 2

  record_gate "task-a" "lint" "pass"
  record_gate "task-a" "test" "pass"
  record_gate "task-a" "verdict" "approved"

  record_gate "task-b" "lint" "fail"
  record_gate "task-b" "test" "pass"
  record_gate "task-b" "verdict" "rejected"

  record_gate "task-c" "lint" "pass"
  record_gate "task-c" "test" "fail"
  record_gate "task-c" "verdict" "rejected"

  run print_round_summary 2 "$VALIDATION_LOG"

  [ "$status" -eq 0 ]
  [ "$output" = "Round 2: 3 launched, 1 approved, 2 rejected (failure modes: lint, test)" ]
}

@test "zero-launched round produces empty counts" {
  init_round_log 3

  run print_round_summary 3 "$VALIDATION_LOG"

  [ "$status" -eq 0 ]
  [ "$output" = "Round 3: 0 launched, 0 approved, 0 rejected" ]
}

@test "summary line is appended to the validation log file" {
  init_round_log 4

  record_gate "task-a" "lint" "pass"
  record_gate "task-a" "verdict" "approved"

  # Write a pre-existing line to confirm append (not overwrite)
  echo "previous content" > "$VALIDATION_LOG"

  print_round_summary 4 "$VALIDATION_LOG"

  # File should contain both the previous content and the new summary
  [ -f "$VALIDATION_LOG" ]
  grep -q "previous content" "$VALIDATION_LOG"
  grep -q "Round 4: 1 launched, 1 approved, 0 rejected" "$VALIDATION_LOG"
}
