#!/usr/bin/env bats
# Tests for scripts/skill-usage-report.sh
#
# Central use cases:
#   1. Reports frequency and recency of skill/workflow invocations
#   2. Cross-references with known skills and workflows directories
#   3. Lists never-invoked skills/workflows
#   4. Handles missing or empty log files gracefully
#   5. Output is a readable ranked table

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/scripts/skill-usage-report.sh"

setup() {
  TEST_LOG=$(mktemp)
  TEST_SKILLS=$(mktemp -d)
  TEST_WORKFLOWS=$(mktemp -d)
  export USAGE_LOG_FILE="$TEST_LOG"
  export SKILLS_DIR="$TEST_SKILLS"
  export WORKFLOWS_DIR="$TEST_WORKFLOWS"

  # Create some known skills/workflows
  touch "$TEST_SKILLS/fact-check.md"
  touch "$TEST_SKILLS/code-review.md"
  touch "$TEST_SKILLS/draft-review.md"
  touch "$TEST_WORKFLOWS/research-plan-implement.md"
  touch "$TEST_WORKFLOWS/spike.md"
}

teardown() {
  rm -f "$TEST_LOG"
  rm -rf "$TEST_SKILLS" "$TEST_WORKFLOWS"
}

# --- Helpers ---

add_event() {
  local event="$1" name="$2" ts="${3:-2026-03-23T10:00:00Z}" project="${4:-test}"
  printf '{"ts":"%s","event":"%s","name":"%s","project":"%s","branch":"main"}\n' \
    "$ts" "$event" "$name" "$project" >> "$TEST_LOG"
}

# --- Basic output ---

@test "reports skill frequency and recency" {
  add_event "skill" "fact-check" "2026-03-20T10:00:00Z"
  add_event "skill" "fact-check" "2026-03-22T10:00:00Z"
  add_event "skill" "fact-check" "2026-03-23T10:00:00Z"

  output=$(bash "$SCRIPT")

  echo "$output" | grep -q "fact-check"
  # Verify count appears on the fact-check row, not just anywhere (e.g., in a date)
  echo "$output" | grep "fact-check" | grep -qE '\b3\b'
  echo "$output" | grep -q "2026-03-23"
}

@test "reports workflow frequency and recency" {
  add_event "workflow" "spike" "2026-03-21T10:00:00Z"
  add_event "workflow" "spike" "2026-03-22T10:00:00Z"

  output=$(bash "$SCRIPT")

  echo "$output" | grep -q "spike"
  echo "$output" | grep "spike" | grep -q "2"
}

@test "ranks by frequency descending" {
  add_event "skill" "code-review" "2026-03-23T10:00:00Z"
  add_event "skill" "fact-check" "2026-03-20T10:00:00Z"
  add_event "skill" "fact-check" "2026-03-21T10:00:00Z"
  add_event "skill" "fact-check" "2026-03-22T10:00:00Z"

  output=$(bash "$SCRIPT")

  # fact-check (3) should appear before code-review (1)
  fact_line=$(echo "$output" | grep -n "fact-check" | head -1 | cut -d: -f1)
  review_line=$(echo "$output" | grep -n "code-review" | head -1 | cut -d: -f1)
  [ "$fact_line" -lt "$review_line" ]
}

# --- Never-invoked ---

@test "lists never-invoked skills" {
  add_event "skill" "fact-check" "2026-03-23T10:00:00Z"
  # code-review and draft-review are known but not in the log

  output=$(bash "$SCRIPT")

  echo "$output" | grep -q "Never invoked"
  echo "$output" | grep -q "code-review"
  echo "$output" | grep -q "draft-review"
}

@test "lists never-invoked workflows" {
  add_event "workflow" "spike" "2026-03-23T10:00:00Z"
  # research-plan-implement is known but not in the log

  output=$(bash "$SCRIPT")

  echo "$output" | grep -q "research-plan-implement"
}

@test "no never-invoked section when all are used" {
  add_event "skill" "fact-check"
  add_event "skill" "code-review"
  add_event "skill" "draft-review"
  add_event "workflow" "research-plan-implement"
  add_event "workflow" "spike"

  output=$(bash "$SCRIPT")

  ! echo "$output" | grep -q "Never invoked"
}

# --- Edge cases ---

@test "handles empty log file" {
  true > "$TEST_LOG"

  output=$(bash "$SCRIPT")

  echo "$output" | grep -q "No usage data"
  echo "$output" | grep -q "Never invoked"
}

@test "handles missing log file" {
  rm -f "$TEST_LOG"
  export USAGE_LOG_FILE="/tmp/nonexistent-usage-$$.jsonl"

  output=$(bash "$SCRIPT")

  echo "$output" | grep -q "No usage data"
}

@test "includes table header" {
  add_event "skill" "fact-check"

  output=$(bash "$SCRIPT")

  echo "$output" | grep -q "Name"
  echo "$output" | grep -q "Type"
  echo "$output" | grep -q "Count"
  echo "$output" | grep -q "Last Used"
}

@test "unknown items in log but not in skills dir still appear in table" {
  add_event "skill" "mystery-skill" "2026-03-23T10:00:00Z"

  output=$(bash "$SCRIPT")

  echo "$output" | grep -q "mystery-skill"
}

@test "mixed skill and workflow events are both reported" {
  add_event "skill" "fact-check" "2026-03-23T10:00:00Z"
  add_event "workflow" "spike" "2026-03-22T10:00:00Z"

  output=$(bash "$SCRIPT")

  echo "$output" | grep "fact-check" | grep -q "skill"
  echo "$output" | grep "spike" | grep -q "workflow"
}

# --- Cross-project aggregation ---

@test "shows events from all projects by default" {
  add_event "skill" "fact-check" "2026-03-23T10:00:00Z" "project-a"
  add_event "skill" "code-review" "2026-03-23T10:00:00Z" "project-b"

  output=$(bash "$SCRIPT")

  echo "$output" | grep -q "fact-check"
  echo "$output" | grep -q "code-review"
}

@test "project filter restricts to named project" {
  add_event "skill" "fact-check" "2026-03-23T10:00:00Z" "project-a"
  add_event "skill" "draft-review" "2026-03-23T10:00:00Z" "project-b"

  output=$(bash "$SCRIPT" --project=project-a)

  # fact-check should appear in the usage table with a count
  echo "$output" | grep "fact-check" | grep -qE '\b1\b'
  # draft-review was only in project-b, so it should only appear in "Never invoked"
  # and not in the usage table with a count
  ! echo "$output" | grep "draft-review" | grep -qE '\b[0-9]+\b.*20[0-9][0-9]-'
}

@test "projects column shows which projects used a skill" {
  add_event "skill" "fact-check" "2026-03-20T10:00:00Z" "project-a"
  add_event "skill" "fact-check" "2026-03-21T10:00:00Z" "project-b"

  output=$(bash "$SCRIPT")

  echo "$output" | grep "fact-check" | grep -q "project-a"
  echo "$output" | grep "fact-check" | grep -q "project-b"
}

@test "table header includes Projects column" {
  add_event "skill" "fact-check"

  output=$(bash "$SCRIPT")

  echo "$output" | grep -q "Projects"
}

@test "project filter shows filter header" {
  add_event "skill" "fact-check" "2026-03-23T10:00:00Z" "my-project"

  output=$(bash "$SCRIPT" --project=my-project)

  echo "$output" | grep -q "Project: my-project"
}
