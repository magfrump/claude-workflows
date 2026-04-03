#!/usr/bin/env bats
# Tests for lint_task_descriptions() in scripts/self-improvement.sh

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

setup() {
  # Source only the lint function by extracting it via a helper script
  # that sources self-improvement.sh in a controlled way
  TMPDIR_TEST="$(mktemp -d)"

  # Create a minimal sourcing wrapper that avoids the main loop and traps
  cat > "$TMPDIR_TEST/source-lint.sh" <<'WRAPPER'
#!/bin/bash
# Stub out functions and variables that self-improvement.sh expects at source time
ROUND_LOG_FILE=""
cleanup() { :; }
# Override trap to avoid interfering with test harness
trap - EXIT ERR
WRAPPER

  # Extract lint_task_descriptions from the script
  sed -n '/^lint_task_descriptions()/,/^}/p' "$REPO_ROOT/scripts/self-improvement.sh" \
    >> "$TMPDIR_TEST/source-lint.sh"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# --- (a) Parent directory does not exist ---

@test "lint warns when files_touched parent directory does not exist" {
  cat > "$TMPDIR_TEST/tasks.json" <<'EOF'
[
  {
    "id": "task-bad-dir",
    "description": "Add a new feature with shellcheck compliance",
    "files_touched": ["nonexistent-dir-xyz/foo.sh"],
    "independent": true
  }
]
EOF
  run bash -c "source '$TMPDIR_TEST/source-lint.sh' && lint_task_descriptions '$TMPDIR_TEST/tasks.json'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LINT WARNING"* ]]
  [[ "$output" == *"parent directory does not exist"* ]]
  [[ "$output" == *"nonexistent-dir-xyz"* ]]
}

# --- (b) .sh files without shellcheck mention ---

@test "lint warns when .sh files touched but description lacks shellcheck" {
  cat > "$TMPDIR_TEST/tasks.json" <<'EOF'
[
  {
    "id": "task-no-shellcheck",
    "description": "Refactor the build pipeline",
    "files_touched": ["scripts/build.sh"],
    "independent": true
  }
]
EOF
  run bash -c "source '$TMPDIR_TEST/source-lint.sh' && lint_task_descriptions '$TMPDIR_TEST/tasks.json'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LINT WARNING"* ]]
  [[ "$output" == *"shellcheck"* ]]
}

# --- (c) workflow .md files without BATS or section mention ---

@test "lint warns when workflow .md files touched but description lacks BATS or section" {
  # Ensure workflows/ directory exists for this test
  mkdir -p "$TMPDIR_TEST/workflows"
  cat > "$TMPDIR_TEST/tasks.json" <<'EOF'
[
  {
    "id": "task-no-bats",
    "description": "Update the research workflow",
    "files_touched": ["workflows/research.md"],
    "independent": true
  }
]
EOF
  run bash -c "cd '$TMPDIR_TEST' && source '$TMPDIR_TEST/source-lint.sh' && lint_task_descriptions '$TMPDIR_TEST/tasks.json'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LINT WARNING"* ]]
  [[ "$output" == *"workflow .md"* ]]
}

# --- Clean pass: no warnings ---

@test "lint produces no warnings for a well-formed task" {
  cat > "$TMPDIR_TEST/tasks.json" <<'EOF'
[
  {
    "id": "task-clean",
    "description": "Update build script and run shellcheck, update BATS section",
    "files_touched": ["scripts/self-improvement.sh", "workflows/dev.md"],
    "independent": true
  }
]
EOF
  run bash -c "cd '$REPO_ROOT' && source '$TMPDIR_TEST/source-lint.sh' && lint_task_descriptions '$TMPDIR_TEST/tasks.json'"
  [ "$status" -eq 0 ]
  [[ "$output" != *"LINT WARNING"* ]]
}
