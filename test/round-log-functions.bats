#!/usr/bin/env bats
# @category slow
# Unit tests for JSON state management functions from self-improvement.sh:
#   init_round_log, update_round_log, record_gate, finalize_round_log, cleanup
#
# Usage: bats test/round-log-functions.bats

setup() {
  # Source self-improvement.sh for its functions without running the main loop.
  # The main-execution guard (if [[ BASH_SOURCE == $0 ]]) prevents the
  # top-level loop from executing when sourced.
  source "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"

  # Set up temp directory structure that finalize_round_log expects
  TEST_TMPDIR=$(mktemp -d)
  WORKING_DIR="$TEST_TMPDIR"
  ROUND_HISTORY="$TEST_TMPDIR/round-history.json"
  echo '[]' > "$ROUND_HISTORY"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
  # Clean up any leftover round log file
  if [ -n "${ROUND_LOG_FILE:-}" ] && [ -f "$ROUND_LOG_FILE" ]; then
    rm -f "$ROUND_LOG_FILE"
  fi
}

# --- (a) init_round_log creates valid JSON with expected fields ---

@test "init_round_log creates valid JSON" {
  init_round_log 1
  # File should exist and contain valid JSON
  [ -f "$ROUND_LOG_FILE" ]
  jq empty "$ROUND_LOG_FILE"
}

@test "init_round_log sets round number" {
  init_round_log 3
  result=$(jq '.round' "$ROUND_LOG_FILE")
  [ "$result" -eq 3 ]
}

@test "init_round_log sets timestamp in ISO 8601 format" {
  init_round_log 1
  ts=$(jq -r '.timestamp' "$ROUND_LOG_FILE")
  [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "init_round_log includes all expected top-level keys" {
  init_round_log 1
  for key in round timestamp ideas tasks validation merges outcome; do
    jq -e "has(\"$key\")" "$ROUND_LOG_FILE"
  done
}

@test "init_round_log sets outcome to incomplete" {
  init_round_log 1
  result=$(jq -r '.outcome' "$ROUND_LOG_FILE")
  [ "$result" = "incomplete" ]
}

@test "init_round_log initializes object fields as empty objects" {
  init_round_log 1
  for key in ideas tasks validation merges; do
    result=$(jq ".$key | length" "$ROUND_LOG_FILE")
    [ "$result" -eq 0 ]
  done
}

# --- (b) update_round_log modifies a field without corrupting others ---

@test "update_round_log sets a string field" {
  init_round_log 1
  update_round_log '.outcome' '"success"'
  result=$(jq -r '.outcome' "$ROUND_LOG_FILE")
  [ "$result" = "success" ]
}

@test "update_round_log preserves other fields" {
  init_round_log 2
  update_round_log '.outcome' '"success"'
  # round number should be unchanged
  result=$(jq '.round' "$ROUND_LOG_FILE")
  [ "$result" -eq 2 ]
  # all top-level keys should still exist
  for key in round timestamp ideas tasks validation merges outcome; do
    jq -e "has(\"$key\")" "$ROUND_LOG_FILE"
  done
}

@test "update_round_log sets a nested object value" {
  init_round_log 1
  update_round_log '.ideas' '{"idea-1": "refactor logging"}'
  result=$(jq -r '.ideas["idea-1"]' "$ROUND_LOG_FILE")
  [ "$result" = "refactor logging" ]
}

@test "update_round_log produces valid JSON after multiple updates" {
  init_round_log 1
  update_round_log '.outcome' '"in-progress"'
  update_round_log '.tasks' '{"t1": "done"}'
  update_round_log '.merges' '{"pr-42": true}'
  jq empty "$ROUND_LOG_FILE"
  # Verify all three updates stuck
  [ "$(jq -r '.outcome' "$ROUND_LOG_FILE")" = "in-progress" ]
  [ "$(jq -r '.tasks.t1' "$ROUND_LOG_FILE")" = "done" ]
  [ "$(jq '.merges["pr-42"]' "$ROUND_LOG_FILE")" = "true" ]
}

# --- (c) record_gate appends gate results correctly ---

@test "record_gate records a single gate result" {
  init_round_log 1
  record_gate "task-1" "lint" "pass"
  result=$(jq -r '.validation["task-1"].lint' "$ROUND_LOG_FILE")
  [ "$result" = "pass" ]
}

@test "record_gate records multiple gates for the same task" {
  init_round_log 1
  record_gate "task-1" "lint" "pass"
  record_gate "task-1" "test" "fail"
  [ "$(jq -r '.validation["task-1"].lint' "$ROUND_LOG_FILE")" = "pass" ]
  [ "$(jq -r '.validation["task-1"].test' "$ROUND_LOG_FILE")" = "fail" ]
}

@test "record_gate records gates for different tasks" {
  init_round_log 1
  record_gate "task-1" "lint" "pass"
  record_gate "task-2" "lint" "fail"
  [ "$(jq -r '.validation["task-1"].lint' "$ROUND_LOG_FILE")" = "pass" ]
  [ "$(jq -r '.validation["task-2"].lint' "$ROUND_LOG_FILE")" = "fail" ]
}

@test "record_gate preserves existing round log fields" {
  init_round_log 5
  update_round_log '.outcome' '"in-progress"'
  record_gate "task-1" "lint" "pass"
  [ "$(jq '.round' "$ROUND_LOG_FILE")" -eq 5 ]
  [ "$(jq -r '.outcome' "$ROUND_LOG_FILE")" = "in-progress" ]
}

# --- (d) finalize_round_log produces per-round report and appends to history ---

@test "finalize_round_log creates per-round report file" {
  init_round_log 1
  update_round_log '.outcome' '"success"'
  finalize_round_log 1
  [ -f "$WORKING_DIR/round-1-report.json" ]
  jq empty "$WORKING_DIR/round-1-report.json"
}

@test "finalize_round_log per-round report contains correct data" {
  init_round_log 2
  update_round_log '.outcome' '"success"'
  record_gate "task-1" "lint" "pass"
  finalize_round_log 2
  [ "$(jq '.round' "$WORKING_DIR/round-2-report.json")" -eq 2 ]
  [ "$(jq -r '.outcome' "$WORKING_DIR/round-2-report.json")" = "success" ]
  [ "$(jq -r '.validation["task-1"].lint' "$WORKING_DIR/round-2-report.json")" = "pass" ]
}

@test "finalize_round_log appends entry to round-history.json" {
  init_round_log 1
  update_round_log '.outcome' '"success"'
  finalize_round_log 1
  # round-history.json should be an array with one entry
  [ "$(jq 'length' "$ROUND_HISTORY")" -eq 1 ]
  [ "$(jq '.[0].round' "$ROUND_HISTORY")" -eq 1 ]
}

@test "finalize_round_log appends multiple rounds to history" {
  init_round_log 1
  update_round_log '.outcome' '"success"'
  finalize_round_log 1

  init_round_log 2
  update_round_log '.outcome' '"partial"'
  finalize_round_log 2

  [ "$(jq 'length' "$ROUND_HISTORY")" -eq 2 ]
  [ "$(jq '.[0].round' "$ROUND_HISTORY")" -eq 1 ]
  [ "$(jq '.[1].round' "$ROUND_HISTORY")" -eq 2 ]
}

@test "finalize_round_log removes the temp round log file" {
  init_round_log 1
  local log_path="$ROUND_LOG_FILE"
  finalize_round_log 1
  [ ! -f "$log_path" ]
}

# --- cleanup ---

@test "cleanup removes ROUND_LOG_FILE when it exists" {
  init_round_log 1
  local log_path="$ROUND_LOG_FILE"
  [ -f "$log_path" ]
  cleanup
  [ ! -f "$log_path" ]
}

@test "cleanup is safe when ROUND_LOG_FILE is empty" {
  ROUND_LOG_FILE=""
  run cleanup
  [ "$status" -eq 0 ]
}

@test "cleanup is safe when ROUND_LOG_FILE points to nonexistent file" {
  ROUND_LOG_FILE="/tmp/nonexistent-round-log-$$"
  run cleanup
  [ "$status" -eq 0 ]
}
