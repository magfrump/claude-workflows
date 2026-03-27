#!/usr/bin/env bats
# Unit tests for validate_task_json() from self-improvement.sh
#
# Usage: bats test/validate-task-json.bats

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/self-improvement.sh"

  TEST_TMPDIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Helper: write a tasks JSON array to a temp file and echo the path
write_tasks() {
  local f="$TEST_TMPDIR/tasks.json"
  echo "$1" > "$f"
  echo "$f"
}

# --- Test 1: A fully valid task passes validation ---

@test "valid task passes validation" {
  local f
  f=$(write_tasks '[{
    "id": "t1",
    "description": "Add a widget",
    "files_touched": ["scripts/self-improvement.sh"],
    "independent": true
  }]')

  result=$(validate_task_json "$f")
  count=$(echo "$result" | jq 'length')
  [ "$count" -eq 1 ]

  tid=$(echo "$result" | jq -r '.[0].id')
  [ "$tid" = "t1" ]
}

# --- Test 2: Task missing id is rejected ---

@test "task missing id is rejected" {
  local f
  f=$(write_tasks '[{
    "description": "No id here",
    "files_touched": ["scripts/self-improvement.sh"],
    "independent": true
  }]')

  result=$(validate_task_json "$f")
  count=$(echo "$result" | jq 'length')
  [ "$count" -eq 0 ]
}

# --- Test 3: Glob pattern in files_touched is rejected ---

@test "glob pattern in files_touched is rejected" {
  local f
  f=$(write_tasks '[{
    "id": "t-glob",
    "description": "Uses a glob",
    "files_touched": ["src/*.sh"],
    "independent": false
  }]')

  result=$(validate_task_json "$f")
  count=$(echo "$result" | jq 'length')
  [ "$count" -eq 0 ]
}

# --- Test 4: Non-existent parent directory is rejected ---

@test "non-existent parent directory in files_touched is rejected" {
  local f
  f=$(write_tasks '[{
    "id": "t-nodir",
    "description": "Bad path",
    "files_touched": ["totally/fake/dir/file.sh"],
    "independent": true
  }]')

  result=$(validate_task_json "$f")
  count=$(echo "$result" | jq 'length')
  [ "$count" -eq 0 ]
}
