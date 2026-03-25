#!/usr/bin/env bats
# Unit tests for validate_task_json from self-improvement.sh
#
# Usage: bats test/validate-task-json.bats

setup() {
  # Source self-improvement.sh for its functions without running the main loop.
  # The main-execution guard (if [[ BASH_SOURCE == $0 ]]) prevents the
  # top-level loop from executing when sourced.
  source "$BATS_TEST_DIRNAME/../self-improvement.sh"

  # Create a temp directory for test JSON files
  TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Helper: write a JSON array with one task object to a temp file
write_task() {
  local file="$TEST_TMPDIR/tasks.json"
  echo "[$1]" > "$file"
  echo "$file"
}

# --- (a) valid task passes ---

@test "valid task passes validation" {
  local tfile
  tfile=$(write_task '{
    "id": "test-task-1",
    "description": "A valid test task",
    "files_touched": ["self-improvement.sh"],
    "independent": true
  }')
  run validate_task_json "$tfile"
  [ "$status" -eq 0 ]
  # Output should contain the task (array length 1)
  echo "$output" | jq -e 'length == 1'
}

# --- (b) missing id rejected ---

@test "missing id is rejected" {
  local tfile
  tfile=$(write_task '{
    "description": "Task without an id",
    "files_touched": ["self-improvement.sh"],
    "independent": true
  }')
  run validate_task_json "$tfile"
  [ "$status" -eq 0 ]
  # Output should be an empty array (task rejected)
  echo "$output" | jq -e 'length == 0'
}

# --- (c) empty files_touched rejected ---

@test "empty files_touched is rejected" {
  local tfile
  tfile=$(write_task '{
    "id": "empty-ft",
    "description": "Task with empty files_touched",
    "files_touched": [],
    "independent": true
  }')
  run validate_task_json "$tfile"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e 'length == 0'
}

# --- (d) glob pattern in files_touched rejected ---

@test "glob pattern in files_touched is rejected" {
  local tfile
  tfile=$(write_task '{
    "id": "glob-ft",
    "description": "Task with glob in files_touched",
    "files_touched": ["src/*.sh"],
    "independent": true
  }')
  run validate_task_json "$tfile"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e 'length == 0'
}

# --- (e) non-existent parent directory rejected ---

@test "non-existent parent directory is rejected" {
  local tfile
  tfile=$(write_task '{
    "id": "bad-dir",
    "description": "Task with non-existent parent dir",
    "files_touched": ["/no/such/directory/file.sh"],
    "independent": true
  }')
  run validate_task_json "$tfile"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e 'length == 0'
}

# --- (f) non-boolean independent rejected ---

@test "non-boolean independent is rejected" {
  local tfile
  tfile=$(write_task '{
    "id": "non-bool",
    "description": "Task with string independent",
    "files_touched": ["self-improvement.sh"],
    "independent": "yes"
  }')
  run validate_task_json "$tfile"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e 'length == 0'
}
