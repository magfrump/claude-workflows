#!/usr/bin/env bats
# @category fast
# Unit tests for decision 012 pillar 1 precondition gate helpers in
# scripts/lib/si-morning-summary.sh:
#   _resolve_hypothesis_target
#   _count_invocations
#   _check_metric_logged
#   _days_since_round
#   _evaluate_script_preconditions

setup() {
  # log-format.sh defines the printf helpers the summary script expects.
  source "$BATS_TEST_DIRNAME/../scripts/lib/log-format.sh"
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-morning-summary.sh"

  TEST_TMPDIR=$(mktemp -d)
  WORKING_DIR="$TEST_TMPDIR/working"
  mkdir -p "$WORKING_DIR/rounds" "$WORKING_DIR/archive"

  USAGE_LOG_FILE="$TEST_TMPDIR/usage.jsonl"
  export USAGE_LOG_FILE
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Helper: write a tasks-round-N.json into the working dir
write_tasks() {
  local round="$1" json="$2"
  echo "$json" > "$WORKING_DIR/tasks-round-$round.json"
}

# Helper: write a round report with a timestamp
write_round_report() {
  local round="$1" ts="$2"
  echo "{\"round\":$round,\"timestamp\":\"$ts\"}" > "$WORKING_DIR/rounds/round-$round-report.json"
}

# Helper: append one invocation row to the usage log
log_invocation() {
  local event="$1" name="$2" via="$3"
  shift 3
  local extra="${1:-}"
  if [ -n "$extra" ]; then
    echo "{\"event\":\"$event\",\"name\":\"$name\",\"via\":\"$via\",$extra}" >> "$USAGE_LOG_FILE"
  else
    echo "{\"event\":\"$event\",\"name\":\"$name\",\"via\":\"$via\"}" >> "$USAGE_LOG_FILE"
  fi
}

# --- _resolve_hypothesis_target ---

@test "resolves skill from SKILL.md-dir layout" {
  write_tasks 1 '[{"id":"t","description":"x","files_touched":["skills/foo/SKILL.md"],"independent":true}]'
  run _resolve_hypothesis_target 1 t "$WORKING_DIR"
  [ "$output" = "skill:foo" ]
}

@test "resolves skill from flat skills/foo.md layout" {
  write_tasks 1 '[{"id":"t","description":"x","files_touched":["skills/foo.md"],"independent":true}]'
  run _resolve_hypothesis_target 1 t "$WORKING_DIR"
  [ "$output" = "skill:foo" ]
}

@test "resolves workflow target" {
  write_tasks 1 '[{"id":"t","description":"x","files_touched":["workflows/bar.md"],"independent":true}]'
  run _resolve_hypothesis_target 1 t "$WORKING_DIR"
  [ "$output" = "workflow:bar" ]
}

@test "resolves multiple targets and dedupes" {
  write_tasks 1 '[{"id":"t","description":"x","files_touched":["skills/foo/SKILL.md","workflows/bar.md","skills/foo/SKILL.md"],"independent":true}]'
  run _resolve_hypothesis_target 1 t "$WORKING_DIR"
  [[ "$output" == *"skill:foo"* ]]
  [[ "$output" == *"workflow:bar"* ]]
  # Dedup: should only have 2 lines, not 3
  [ "$(echo "$output" | wc -l)" -eq 2 ]
}

@test "returns empty for tasks with no skill/workflow paths" {
  write_tasks 1 '[{"id":"t","description":"x","files_touched":["scripts/foo.sh"],"independent":true}]'
  run _resolve_hypothesis_target 1 t "$WORKING_DIR"
  [ -z "$output" ]
}

@test "returns empty when tasks file is missing" {
  run _resolve_hypothesis_target 99 t "$WORKING_DIR"
  [ -z "$output" ]
}

@test "falls back to archive when current tasks file is absent" {
  echo '[{"id":"t","description":"x","files_touched":["skills/foo/SKILL.md"],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-01-01-tasks-round-7.json"
  run _resolve_hypothesis_target 7 t "$WORKING_DIR"
  [ "$output" = "skill:foo" ]
}

# --- _count_invocations ---

@test "counts skill invocations via skill_tool" {
  for _ in 1 2 3; do log_invocation skill foo skill_tool; done
  run _count_invocations "skill:foo"
  [ "$output" = "3" ]
}

@test "ignores file_read entries for skill targets" {
  log_invocation skill foo skill_tool
  log_invocation skill foo file_read
  log_invocation skill foo file_read
  run _count_invocations "skill:foo"
  [ "$output" = "1" ]
}

@test "workflow targets count file_read entries (fallback channel)" {
  log_invocation workflow bar file_read
  log_invocation workflow bar file_read
  run _count_invocations "workflow:bar"
  [ "$output" = "2" ]
}

@test "sums across multiple targets" {
  log_invocation skill foo skill_tool
  log_invocation skill foo skill_tool
  log_invocation workflow bar file_read
  local targets
  targets=$(printf 'skill:foo\nworkflow:bar')
  run _count_invocations "$targets"
  [ "$output" = "3" ]
}

@test "returns 0 when log is missing" {
  USAGE_LOG_FILE="$TEST_TMPDIR/nope.jsonl"
  run _count_invocations "skill:foo"
  [ "$output" = "0" ]
}

@test "returns 0 for empty target list" {
  log_invocation skill foo skill_tool
  run _count_invocations ""
  [ "$output" = "0" ]
}

# --- _check_metric_logged ---

@test "metric_logged passes when field is present on a matching entry" {
  log_invocation skill foo skill_tool '"duration_ms":1500'
  run _check_metric_logged "skill:foo" "duration_ms"
  [ "$status" -eq 0 ]
}

@test "metric_logged fails when no matching entry has the field" {
  log_invocation skill foo skill_tool
  run _check_metric_logged "skill:foo" "duration_ms"
  [ "$status" -ne 0 ]
}

@test "metric_logged scopes to the named target" {
  log_invocation skill foo skill_tool '"duration_ms":1500'
  run _check_metric_logged "skill:other" "duration_ms"
  [ "$status" -ne 0 ]
}

# --- _days_since_round ---

@test "_days_since_round returns elapsed days from round timestamp" {
  local ten_days_ago
  ten_days_ago=$(date -u -d "10 days ago" +%Y-%m-%dT%H:%M:%SZ)
  write_round_report 3 "$ten_days_ago"
  run _days_since_round 3 "$WORKING_DIR"
  # Allow ±1 day for clock boundaries
  [ "$output" -ge 9 ] && [ "$output" -le 11 ]
}

@test "_days_since_round echoes -1 when report missing" {
  run _days_since_round 99 "$WORKING_DIR"
  [ "$output" = "-1" ]
}

@test "_days_since_round uses NOW_EPOCH override for determinism" {
  # Round at epoch 1000, now at epoch 1000 + 5*86400 → 5 days
  write_round_report 1 "1970-01-01T00:16:40Z"  # epoch 1000
  NOW_EPOCH=$((1000 + 5 * 86400))
  export NOW_EPOCH
  run _days_since_round 1 "$WORKING_DIR"
  [ "$output" = "5" ]
}

# --- _evaluate_script_preconditions ---

@test "preconditions met → ready-for-verdict recommendation" {
  write_tasks 1 '[{"id":"t","description":"x","files_touched":["skills/foo/SKILL.md"],"independent":true}]'
  for _ in $(seq 1 10); do log_invocation skill foo skill_tool; done
  run _evaluate_script_preconditions 1 t "invocations=5" "$WORKING_DIR"
  [[ "$output" == *"MET"* ]]
  [[ "$output" == *"ready for CONFIRMED/REFUTED"* ]]
}

@test "preconditions unmet → INCONCLUSIVE recommendation" {
  write_tasks 1 '[{"id":"t","description":"x","files_touched":["skills/foo/SKILL.md"],"independent":true}]'
  log_invocation skill foo skill_tool
  run _evaluate_script_preconditions 1 t "invocations=5" "$WORKING_DIR"
  [[ "$output" == *"UNMET"* ]]
  [[ "$output" == *"INCONCLUSIVE"* ]]
  [[ "$output" == *"1/5"* ]]
}

@test "no requires declared → ready-now recommendation" {
  write_tasks 1 '[{"id":"t","description":"x","files_touched":["skills/foo/SKILL.md"],"independent":true}]'
  run _evaluate_script_preconditions 1 t "" "$WORKING_DIR"
  [[ "$output" == *"none declared"* ]]
}

@test "unresolvable target → switch-evaluator recommendation" {
  write_tasks 1 '[{"id":"t","description":"x","files_touched":["scripts/foo.sh"],"independent":true}]'
  run _evaluate_script_preconditions 1 t "invocations=1" "$WORKING_DIR"
  [[ "$output" == *"unresolvable"* ]]
  [[ "$output" == *"switch evaluator"* ]]
}

@test "unknown requires key is surfaced and forces INCONCLUSIVE" {
  write_tasks 1 '[{"id":"t","description":"x","files_touched":["skills/foo/SKILL.md"],"independent":true}]'
  log_invocation skill foo skill_tool
  run _evaluate_script_preconditions 1 t "invocations=1;sparkles=true" "$WORKING_DIR"
  [[ "$output" == *"unknown keys"* ]]
  [[ "$output" == *"sparkles"* ]]
  [[ "$output" == *"INCONCLUSIVE"* ]]
}

@test "all three precondition kinds can combine and all must pass" {
  write_tasks 1 '[{"id":"t","description":"x","files_touched":["skills/foo/SKILL.md"],"independent":true}]'
  log_invocation skill foo skill_tool '"duration_ms":1500'
  local ten_days_ago
  ten_days_ago=$(date -u -d "10 days ago" +%Y-%m-%dT%H:%M:%SZ)
  write_round_report 1 "$ten_days_ago"
  run _evaluate_script_preconditions 1 t "invocations=1;metric_logged=duration_ms;days_elapsed=7" "$WORKING_DIR"
  [[ "$output" == *"ready for CONFIRMED/REFUTED"* ]]
}

@test "combined preconditions report each check separately when one fails" {
  write_tasks 1 '[{"id":"t","description":"x","files_touched":["skills/foo/SKILL.md"],"independent":true}]'
  log_invocation skill foo skill_tool
  local ten_days_ago
  ten_days_ago=$(date -u -d "10 days ago" +%Y-%m-%dT%H:%M:%SZ)
  write_round_report 1 "$ten_days_ago"
  # invocations met (1≥1), metric_logged NOT met (no duration_ms in the only entry),
  # days_elapsed met (10≥7) → recommendation should be INCONCLUSIVE citing the metric
  run _evaluate_script_preconditions 1 t "invocations=1;metric_logged=duration_ms;days_elapsed=7" "$WORKING_DIR"
  [[ "$output" == *"invocations≥1: MET"* ]]
  [[ "$output" == *"metric_logged=duration_ms: UNMET"* ]]
  [[ "$output" == *"days_elapsed≥7: MET"* ]]
  [[ "$output" == *"INCONCLUSIVE"* ]]
}
