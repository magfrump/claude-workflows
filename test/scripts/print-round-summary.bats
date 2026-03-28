#!/usr/bin/env bats
# Tests for scripts/print-round-summary.sh
#
# Validates that the standalone script reads round-history.json and prints
# a human-readable table of task verdicts per round.

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/scripts/print-round-summary.sh"

setup() {
  TEST_TMPDIR=$(mktemp -d)
  export ROUND_HISTORY="$TEST_TMPDIR/round-history.json"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# --- Helpers ---

# Write a minimal round-history.json with the given content
write_history() {
  cat > "$ROUND_HISTORY"
}

# --- Basic output ---

@test "prints table header for each round" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "task-a": { "lint": "pass", "test": "pass", "verdict": "approved" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "=== Round 1 ==="
  echo "$output" | grep -q "TASK ID"
  echo "$output" | grep -q "VERDICT"
  echo "$output" | grep -q "FIRST FAILING GATE"
}

@test "approved task shows dash for first failing gate" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "task-a": { "lint": "pass", "test": "pass", "verdict": "approved" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep "task-a" | grep -q "approved"
  # The em-dash indicates no failing gate
  echo "$output" | grep "task-a" | grep -q "—"
}

@test "rejected task shows first failing gate" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "task-b": { "lint": "fail", "test": "fail", "verdict": "rejected" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep "task-b" | grep -q "rejected"
  # lint comes before test alphabetically, so it's the first failing gate
  echo "$output" | grep "task-b" | grep -q "lint"
}

@test "multiple rounds each get their own section" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "task-a": { "lint": "pass", "verdict": "approved" }
    }
  },
  {
    "round": 2,
    "validation": {
      "task-b": { "test": "fail", "verdict": "rejected" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "=== Round 1 ==="
  echo "$output" | grep -q "=== Round 2 ==="
  echo "$output" | grep -q "task-a"
  echo "$output" | grep -q "task-b"
}

@test "empty history prints no-rounds message" {
  echo '[]' > "$ROUND_HISTORY"

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "No rounds recorded"
}

@test "missing file exits with error" {
  rm -f "$ROUND_HISTORY"

  run bash "$SCRIPT"

  [ "$status" -ne 0 ]
  echo "$output" | grep -q "No round history found"
}

@test "round with no tasks shows placeholder" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {}
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "(no tasks)"
}

@test "mixed approved and rejected in same round" {
  write_history <<'JSON'
[
  {
    "round": 3,
    "validation": {
      "task-x": { "lint": "pass", "test": "pass", "verdict": "approved" },
      "task-y": { "lint": "pass", "test": "fail", "verdict": "rejected" },
      "task-z": { "lint": "fail", "verdict": "rejected" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep "task-x" | grep -q "approved"
  echo "$output" | grep "task-y" | grep -q "test"
  echo "$output" | grep "task-z" | grep -q "lint"
}
