#!/usr/bin/env bats
# @category fast
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

# --- decision 012 pillar 1: evaluator + requires fields ---

@test "valid evaluator=script passes" {
  local f
  f=$(write_tasks '[{
    "id": "t-ev",
    "description": "x",
    "files_touched": ["scripts/self-improvement.sh"],
    "independent": true,
    "evaluator": "script"
  }]')
  result=$(validate_task_json "$f")
  [ "$(echo "$result" | jq 'length')" -eq 1 ]
}

@test "invalid evaluator value is rejected" {
  local f
  f=$(write_tasks '[{
    "id": "t-bad-ev",
    "description": "x",
    "files_touched": ["scripts/self-improvement.sh"],
    "independent": true,
    "evaluator": "robot"
  }]')
  result=$(validate_task_json "$f")
  [ "$(echo "$result" | jq 'length')" -eq 0 ]
}

@test "missing evaluator is a lint warning, not a rejection" {
  local f
  f=$(write_tasks '[{
    "id": "t-no-ev",
    "description": "x",
    "files_touched": ["scripts/self-improvement.sh"],
    "independent": true
  }]')
  # Capture stdout (valid tasks) and stderr (warnings) separately so we can
  # assert both "warning fires" and "task survives" independently.
  local stderr_file
  stderr_file=$(mktemp)
  local stdout
  stdout=$(validate_task_json "$f" 2>"$stderr_file")
  grep -q "evaluator missing" "$stderr_file"
  [ "$(echo "$stdout" | jq 'length')" -eq 1 ]
  rm -f "$stderr_file"
}

@test "valid requires object with all three keys passes" {
  local f
  f=$(write_tasks '[{
    "id": "t-req",
    "description": "x",
    "files_touched": ["scripts/self-improvement.sh"],
    "independent": true,
    "evaluator": "script",
    "requires": {"metric_logged": "latency_p95", "invocations": 10, "days_elapsed": 7}
  }]')
  result=$(validate_task_json "$f")
  [ "$(echo "$result" | jq 'length')" -eq 1 ]
}

@test "requires with unknown key is rejected" {
  local f
  f=$(write_tasks '[{
    "id": "t-bad-key",
    "description": "x",
    "files_touched": ["scripts/self-improvement.sh"],
    "independent": true,
    "evaluator": "script",
    "requires": {"sparkles": true}
  }]')
  result=$(validate_task_json "$f")
  [ "$(echo "$result" | jq 'length')" -eq 0 ]
}

@test "requires.invocations as non-integer is rejected" {
  local f
  f=$(write_tasks '[{
    "id": "t-frac",
    "description": "x",
    "files_touched": ["scripts/self-improvement.sh"],
    "independent": true,
    "evaluator": "script",
    "requires": {"invocations": 3.7}
  }]')
  result=$(validate_task_json "$f")
  [ "$(echo "$result" | jq 'length')" -eq 0 ]
}

@test "requires as non-object is rejected" {
  local f
  f=$(write_tasks '[{
    "id": "t-str-req",
    "description": "x",
    "files_touched": ["scripts/self-improvement.sh"],
    "independent": true,
    "evaluator": "script",
    "requires": "invocations:10"
  }]')
  result=$(validate_task_json "$f")
  [ "$(echo "$result" | jq 'length')" -eq 0 ]
}
