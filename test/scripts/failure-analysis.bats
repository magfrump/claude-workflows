#!/usr/bin/env bats
# Tests for scripts/failure-analysis.sh
#
# Validates failure analysis output format, graceful handling of missing/empty
# data, and correctness of each output section.

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/scripts/failure-analysis.sh"

setup() {
  TEST_TMPDIR=$(mktemp -d)
  export ROUND_HISTORY="$TEST_TMPDIR/round-history.json"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# --- Helpers ---

write_history() {
  cat > "$ROUND_HISTORY"
}

# --- Graceful handling ---

@test "missing file prints 'No round history found' and exits 0" {
  rm -f "$ROUND_HISTORY"

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "No round history found"
}

@test "empty array prints 'No round history found' and exits 0" {
  echo '[]' > "$ROUND_HISTORY"

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "No round history found"
}

# --- Section headers ---

@test "output contains all three section headers" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "task-a": { "schema": "pass", "tests": "pass", "verdict": "approved" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "=== Gate Rejection Frequency ==="
  echo "$output" | grep -q "=== Failure by Task Type ==="
  echo "$output" | grep -q "=== Re-attempt Success Rate ==="
}

# --- Gate rejection frequency ---

@test "gate failures are counted correctly" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "task-a": { "schema": "fail", "tests": "fail", "verdict": "rejected" },
      "task-b": { "schema": "fail", "shellcheck": "pass", "verdict": "rejected" }
    }
  },
  {
    "round": 2,
    "validation": {
      "task-c": { "tests": "fail", "verdict": "rejected" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  # schema failed 2 times, tests failed 2 times
  echo "$output" | grep "schema" | grep -q "2"
  echo "$output" | grep "tests" | grep -q "2"
}

@test "no gate failures shows placeholder" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "task-a": { "schema": "pass", "tests": "pass", "verdict": "approved" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "(no gate failures recorded)"
}

# --- Task type failures ---

@test "task type rejections grouped by id prefix" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "feat-login": { "tests": "fail", "verdict": "rejected" },
      "feat-signup": { "schema": "fail", "verdict": "rejected" },
      "fix-typo": { "tests": "fail", "verdict": "rejected" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  # "feat" prefix should have 2 rejections
  echo "$output" | grep "feat" | grep -q "2"
  # "fix" prefix should have 1 rejection
  echo "$output" | grep "fix" | grep -q "1"
}

@test "all approved shows no-rejections placeholder" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "task-a": { "schema": "pass", "verdict": "approved" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "(no task rejections recorded)"
}

# --- Re-attempt success rate ---

@test "re-attempts are detected and rates calculated" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "task-a": { "tests": "fail", "verdict": "rejected" },
      "task-b": { "tests": "fail", "verdict": "rejected" }
    }
  },
  {
    "round": 2,
    "validation": {
      "task-a": { "tests": "pass", "verdict": "approved" },
      "task-b": { "tests": "fail", "verdict": "rejected" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "First-attempt pass rate:"
  echo "$output" | grep -q "Re-attempt pass rate:"
  # 1 of 2 re-attempts passed = 50%
  echo "$output" | grep "Re-attempt pass rate:" | grep -q "50%"
}

@test "no re-attempts shows placeholder" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "task-a": { "tests": "pass", "verdict": "approved" },
      "task-b": { "tests": "fail", "verdict": "rejected" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "(no re-attempts recorded)"
}

@test "re-attempts with higher rate shows HIGHER label" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "task-a": { "tests": "fail", "verdict": "rejected" },
      "task-b": { "tests": "fail", "verdict": "rejected" },
      "task-c": { "tests": "fail", "verdict": "rejected" }
    }
  },
  {
    "round": 2,
    "validation": {
      "task-a": { "tests": "pass", "verdict": "approved" },
      "task-b": { "tests": "pass", "verdict": "approved" },
      "task-c": { "tests": "pass", "verdict": "approved" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "HIGHER"
}

# --- Source line ---

@test "output ends with source file reference" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "task-a": { "verdict": "approved" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Source:.*1 rounds"
}

# --- Comprehensive fixture ---

@test "multi-round fixture produces complete output" {
  write_history <<'JSON'
[
  {
    "round": 1,
    "validation": {
      "feat-auth": { "schema": "pass", "tests": "fail", "shellcheck": "pass", "verdict": "rejected" },
      "fix-typo": { "schema": "pass", "tests": "pass", "shellcheck": "pass", "verdict": "approved" },
      "refactor-utils": { "schema": "fail", "verdict": "rejected" }
    }
  },
  {
    "round": 2,
    "validation": {
      "feat-auth": { "schema": "pass", "tests": "pass", "shellcheck": "pass", "verdict": "approved" },
      "refactor-utils": { "schema": "pass", "tests": "fail", "verdict": "rejected" },
      "feat-logging": { "schema": "pass", "tests": "pass", "verdict": "approved" }
    }
  },
  {
    "round": 3,
    "validation": {
      "refactor-utils": { "schema": "pass", "tests": "pass", "verdict": "approved" }
    }
  }
]
JSON

  run bash "$SCRIPT"

  [ "$status" -eq 0 ]

  # All three sections present
  echo "$output" | grep -q "=== Gate Rejection Frequency ==="
  echo "$output" | grep -q "=== Failure by Task Type ==="
  echo "$output" | grep -q "=== Re-attempt Success Rate ==="

  # Gate counts: tests failed 2x, schema failed 1x
  echo "$output" | grep "tests" | head -1 | grep -q "2"
  echo "$output" | grep "schema" | head -1 | grep -q "1"

  # Source line
  echo "$output" | grep -q "3 rounds"
}
