#!/usr/bin/env bats
# @category fast
# Unit tests for _project_state_recent_rejections in
# scripts/lib/si-morning-summary.sh: rejection clustering by
# <failure_mode, primary_file_touched> with maintenance-signal callout.

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/lib/log-format.sh"
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-morning-summary.sh"

  TEST_TMPDIR=$(mktemp -d)
  WORKING_DIR="$TEST_TMPDIR/working"
  mkdir -p "$WORKING_DIR"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# --- Fixture helpers ---

# Write a tasks-round-N.json from an array of "id|file_path" strings.
write_tasks() {
  local round="$1"
  shift
  local entries=""
  local entry id file
  for entry in "$@"; do
    id="${entry%%|*}"
    file="${entry#*|}"
    if [ -n "$entries" ]; then
      entries="${entries},"
    fi
    if [ -n "$file" ]; then
      entries="${entries}{\"id\":\"${id}\",\"description\":\"x\",\"files_touched\":[\"${file}\"],\"independent\":true}"
    else
      entries="${entries}{\"id\":\"${id}\",\"description\":\"x\",\"files_touched\":[],\"independent\":true}"
    fi
  done
  echo "[${entries}]" > "$WORKING_DIR/tasks-round-${round}.json"
}

# Write a round report from "tid|verdict|gate1=status1,gate2=status2,..." rows.
# Use verdict="rejected" with gate=...=fail to flag a rejection.
write_report() {
  local round="$1"
  shift
  local validation_entries=""
  local row tid verdict gates gate_pairs gate_pair k v
  for row in "$@"; do
    tid="${row%%|*}"
    row="${row#*|}"
    verdict="${row%%|*}"
    gates="${row#*|}"
    gate_pairs="\"verdict\":\"${verdict}\""
    IFS=',' read -ra gate_pair_arr <<< "$gates"
    for gate_pair in "${gate_pair_arr[@]}"; do
      [ -z "$gate_pair" ] && continue
      k="${gate_pair%%=*}"
      v="${gate_pair#*=}"
      gate_pairs="${gate_pairs},\"${k}\":\"${v}\""
    done
    if [ -n "$validation_entries" ]; then
      validation_entries="${validation_entries},"
    fi
    validation_entries="${validation_entries}\"${tid}\":{${gate_pairs}}"
  done
  echo "{\"validation\":{${validation_entries}}}" > "$WORKING_DIR/round-${round}-report.json"
}

# --- Tests ---

@test "no rejections in scope emits placeholder" {
  write_report 1 "t1|approved|tests=pass"
  run _project_state_recent_rejections 1 1 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No rejections this run."* ]]
}

@test "single gate with multiple files renders sub-counts" {
  write_tasks 1 "t1|workflows/rpi-plan.md" "t2|workflows/rpi-plan.md" \
                "t3|workflows/dd.md" "t4|workflows/pr-prep.md"
  write_report 1 \
    "t1|rejected|tests=fail" \
    "t2|rejected|tests=fail" \
    "t3|rejected|tests=fail" \
    "t4|rejected|tests=fail"
  run _project_state_recent_rejections 1 1 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"- **tests**: 4 (rpi-plan.md: 2, dd.md: 1, pr-prep.md: 1)"* ]]
}

@test "multiple gates each get their own grouped line" {
  write_tasks 1 "t1|workflows/a.md" "t2|workflows/b.md" "t3|workflows/c.md"
  write_report 1 \
    "t1|rejected|tests=fail" \
    "t2|rejected|tests=fail" \
    "t3|rejected|lint=fail"
  run _project_state_recent_rejections 1 1 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  # tests has higher count, should appear first
  local tests_line lint_line
  tests_line=$(echo "$output" | grep -n "tests" | head -1 | cut -d: -f1)
  lint_line=$(echo "$output" | grep -n "lint" | head -1 | cut -d: -f1)
  [ -n "$tests_line" ]
  [ -n "$lint_line" ]
  [ "$tests_line" -lt "$lint_line" ]
  [[ "$output" == *"- **tests**: 2 (a.md: 1, b.md: 1)"* ]]
  [[ "$output" == *"- **lint**: 1 (c.md: 1)"* ]]
}

@test "file with 3+ rejections triggers maintenance signal" {
  write_tasks 1 "t1|workflows/hot.md" "t2|workflows/hot.md" "t3|workflows/hot.md"
  write_report 1 \
    "t1|rejected|tests=fail" \
    "t2|rejected|tests=fail" \
    "t3|rejected|tests=fail"
  run _project_state_recent_rejections 1 1 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"- **tests**: 3 (hot.md: 3)"* ]]
  [[ "$output" == *"- Maintenance signal: hot.md has 3+ recent rejections - consider a maintenance task"* ]]
}

@test "file with only 2 rejections produces no maintenance signal" {
  write_tasks 1 "t1|workflows/warm.md" "t2|workflows/warm.md"
  write_report 1 \
    "t1|rejected|tests=fail" \
    "t2|rejected|tests=fail"
  run _project_state_recent_rejections 1 1 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"- **tests**: 2 (warm.md: 2)"* ]]
  [[ "$output" != *"Maintenance signal"* ]]
}

@test "maintenance signal triggers when file spans multiple gates" {
  write_tasks 1 "t1|workflows/x.md" "t2|workflows/x.md" "t3|workflows/x.md"
  write_report 1 \
    "t1|rejected|tests=fail" \
    "t2|rejected|lint=fail" \
    "t3|rejected|format=fail"
  run _project_state_recent_rejections 1 1 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"- Maintenance signal: x.md has 3+ recent rejections - consider a maintenance task"* ]]
}

@test "missing tasks file falls back to unknown" {
  # Report only, no tasks-round-1.json
  write_report 1 "t1|rejected|tests=fail" "t2|rejected|tests=fail"
  run _project_state_recent_rejections 1 1 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"- **tests**: 2 (unknown: 2)"* ]]
}

@test "empty files_touched falls back to unknown" {
  write_tasks 1 "t1|"
  write_report 1 "t1|rejected|tests=fail"
  run _project_state_recent_rejections 1 1 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"- **tests**: 1 (unknown: 1)"* ]]
}

@test "rejections across multiple rounds aggregate into one cluster set" {
  write_tasks 1 "t1|workflows/a.md"
  write_tasks 2 "t2|workflows/a.md" "t3|workflows/b.md"
  write_report 1 "t1|rejected|tests=fail"
  write_report 2 "t2|rejected|tests=fail" "t3|rejected|tests=fail"
  run _project_state_recent_rejections 1 2 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"- **tests**: 3 (a.md: 2, b.md: 1)"* ]]
}

@test "same task rejected in two rounds counts once per (gate, file)" {
  write_tasks 1 "t1|workflows/dup.md"
  write_tasks 2 "t1|workflows/dup.md"
  write_report 1 "t1|rejected|tests=fail"
  write_report 2 "t1|rejected|tests=fail"
  run _project_state_recent_rejections 1 2 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"- **tests**: 1 (dup.md: 1)"* ]]
  # No maintenance signal — only one unique rejection
  [[ "$output" != *"Maintenance signal"* ]]
}

@test "uses basename of first file in files_touched as primary" {
  # Multi-file tasks: primary = first file's basename
  write_tasks 1 "t1|workflows/nested/deep/plan.md"
  write_report 1 "t1|rejected|tests=fail"
  run _project_state_recent_rejections 1 1 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"- **tests**: 1 (plan.md: 1)"* ]]
}

@test "header is always emitted even when there are rejections" {
  write_tasks 1 "t1|workflows/x.md"
  write_report 1 "t1|rejected|tests=fail"
  run _project_state_recent_rejections 1 1 "$WORKING_DIR"
  [[ "$output" == *"### Recent Rejections by Failure Mode"* ]]
}
