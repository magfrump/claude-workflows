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

  # Isolate usage-log reads: _summary_deferred_evaluation pre-aggregates the
  # usage log to evaluate script-evaluator preconditions.
  USAGE_LOG_FILE="$TEST_TMPDIR/usage.jsonl"
  export USAGE_LOG_FILE

  HYP_LOG="$WORKING_DIR/hypothesis-log.md"

  # Stub the claude CLI so no sourced morning-summary function (e.g.
  # _compute_contrastive_pair) can ever reach the real one (live LLM call
  # + sandbox network prompt). Enforced by test/fixture-hermeticity.bats.
  mkdir -p "$BATS_TEST_TMPDIR/stub-bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$BATS_TEST_TMPDIR/stub-bin/claude"
  chmod +x "$BATS_TEST_TMPDIR/stub-bin/claude"
  PATH="$BATS_TEST_TMPDIR/stub-bin:$PATH"
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

# ---------------------------------------------------------------------------
# _summary_deferred_evaluation: the property restructure.
#
# The deferred section must surface the matured / precondition-MET hypotheses
# (ready for a verdict) as the actionable few at the top and collapse the
# not-yet-evaluable ones behind a count + expandable <details> list. Three
# usability properties are under test:
#   - discoverability-on-creation: the ready few appear first, above the wall
#   - semantic-distance / feedback-continuity: the numbered total still equals
#     _count_matured_deferred (the action block's N)
#   - progressive-disclosure + collapse-not-delete: the rest stay reachable in
#     a collapsed block, none dropped
# ---------------------------------------------------------------------------

# Schema matches the current hypothesis-log layout the script parses by name.
write_hyp_header() {
  {
    echo "# Hypothesis Log"
    echo ""
    echo "| Round | Task ID | Hypothesis | Source | Window | Evaluator | Requires | Checked at Round | Outcome | Status Date | Evidence |"
    echo "|-|-|-|-|-|-|-|-|-|-|-|"
  } > "$HYP_LOG"
}

# Open user-evaluated row (empty Outcome) — always lands in the deferred group.
append_user_row() {
  local tid="$1" hyp="$2"
  echo "| 1 | ${tid} | ${hyp} |  | 2 | user |  |  |  |  |  |" >> "$HYP_LOG"
}

# Open script-evaluated row with a Requires string. Pair with write_tasks +
# log_inv to drive its preconditions MET (ready) or UNMET (deferred).
append_script_row() {
  local tid="$1" hyp="$2" requires="$3"
  echo "| 1 | ${tid} | ${hyp} |  | 2 | script | ${requires} |  |  |  |  |" >> "$HYP_LOG"
}

# Closed row (Outcome filled) — excluded from the matured-open subset entirely.
append_closed_row() {
  local tid="$1" hyp="$2"
  echo "| 1 | ${tid} | ${hyp} |  | 2 | user |  |  | CONFIRMED |  |  |" >> "$HYP_LOG"
}

# Append one skill invocation to the isolated usage log.
log_inv() {
  local name="$1"
  echo "{\"event\":\"skill\",\"name\":\"${name}\",\"via\":\"skill_tool\"}" >> "$USAGE_LOG_FILE"
}

@test "progressive-disclosure: open user rows collapse into a counted <details> block, all reachable" {
  write_hyp_header
  append_user_row u1 "first user hyp"
  append_user_row u2 "second user hyp"
  append_user_row u3 "third user hyp"
  run _summary_deferred_evaluation "$HYP_LOG" 10 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"### Not Yet Evaluable (3)"* ]]
  [[ "$output" == *"<details>"* ]]
  [[ "$output" == *"</details>"* ]]
  # collapse-not-delete: every hypothesis still present
  [[ "$output" == *"u1"* ]]
  [[ "$output" == *"u2"* ]]
  [[ "$output" == *"u3"* ]]
}

@test "discoverability-on-creation: a precondition-MET script row appears under Ready, before the collapsed wall" {
  write_hyp_header
  append_script_row s1 "ready script hyp" "invocations=1"
  append_user_row u1 "buried user hyp"
  append_user_row u2 "buried user hyp two"
  # s1 resolves to skill:foo and has 1+ invocation → preconditions MET.
  write_tasks 1 "s1|skills/foo/SKILL.md"
  log_inv foo
  run _summary_deferred_evaluation "$HYP_LOG" 10 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"### Ready for a Verdict (1)"* ]]
  [[ "$output" == *"ready for CONFIRMED/REFUTED"* ]]
  # Ordering: the Ready heading precedes the collapsed Not-Yet-Evaluable block.
  local ready_line wall_line
  ready_line=$(echo "$output" | grep -n "### Ready for a Verdict" | head -1 | cut -d: -f1)
  wall_line=$(echo "$output" | grep -n "### Not Yet Evaluable" | head -1 | cut -d: -f1)
  [ -n "$ready_line" ]
  [ -n "$wall_line" ]
  [ "$ready_line" -lt "$wall_line" ]
}

@test "feedback-continuity: numbered total equals _count_matured_deferred for a mixed log" {
  write_hyp_header
  append_script_row s1 "ready script hyp" "invocations=1"
  append_script_row s2 "blocked script hyp" "invocations=5"
  append_user_row u1 "user hyp"
  append_closed_row c1 "closed hyp"
  # s1 MET (1≥1), s2 UNMET (1<5); both resolve to skill:foo.
  write_tasks 1 "s1|skills/foo/SKILL.md" "s2|skills/foo/SKILL.md"
  log_inv foo

  local n q
  n=$(_count_matured_deferred "$HYP_LOG" 10)
  q=$(_summary_deferred_evaluation "$HYP_LOG" 10 "$WORKING_DIR" | grep -cE '^[0-9]+\.')
  [ "$n" -eq 3 ]
  [ "$q" -eq 3 ]
}

@test "collapse-not-delete: a precondition-UNMET script row is collapsed, not promoted to Ready" {
  write_hyp_header
  append_script_row s1 "blocked script hyp" "invocations=5"
  write_tasks 1 "s1|skills/foo/SKILL.md"
  log_inv foo  # only 1 invocation; needs 5 → UNMET
  run _summary_deferred_evaluation "$HYP_LOG" 10 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  # No ready group at all, but the row is still present inside the wall.
  [[ "$output" != *"### Ready for a Verdict"* ]]
  [[ "$output" == *"### Not Yet Evaluable (1)"* ]]
  [[ "$output" == *"s1"* ]]
  [[ "$output" == *"INCONCLUSIVE"* ]]
}

@test "zero open rows emits the no-op line and no group headers" {
  write_hyp_header
  append_closed_row c1 "closed one"
  append_closed_row c2 "closed two"
  run _summary_deferred_evaluation "$HYP_LOG" 10 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No open hypotheses to evaluate."* ]]
  [[ "$output" != *"### Ready for a Verdict"* ]]
  [[ "$output" != *"<details>"* ]]
}

@test "missing hypothesis log degrades gracefully" {
  run _summary_deferred_evaluation "$WORKING_DIR/nope.md" 10 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Deferred Evaluation Questions"* ]]
  [[ "$output" == *"No hypothesis log found."* ]]
}

@test "_evaluate_script_preconditions exit code: 0 when MET, 1 when UNMET" {
  write_tasks 1 "s1|skills/foo/SKILL.md"
  log_inv foo
  run _evaluate_script_preconditions 1 s1 "invocations=1" "$WORKING_DIR"
  [ "$status" -eq 0 ]
  run _evaluate_script_preconditions 1 s1 "invocations=5" "$WORKING_DIR"
  [ "$status" -eq 1 ]
}
