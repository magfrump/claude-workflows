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

# A round number recurs across SI runs, so several archived copies can exist.
@test "archive fallback prefers the newest archived copy" {
  echo '[{"id":"t","description":"x","files_touched":["skills/old/SKILL.md"],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-01-01-tasks-round-7.json"
  echo '[{"id":"t","description":"x","files_touched":["skills/new/SKILL.md"],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-03-01-tasks-round-7.json"
  run _resolve_hypothesis_target 7 t "$WORKING_DIR"
  [ "$output" = "skill:new" ]
}

@test "archive fallback skips a newer copy that lacks the task id" {
  echo '[{"id":"t","description":"x","files_touched":["skills/mine/SKILL.md"],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-01-01-tasks-round-7.json"
  echo '[{"id":"other","description":"x","files_touched":["skills/theirs/SKILL.md"],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-03-01-tasks-round-7.json"
  run _resolve_hypothesis_target 7 t "$WORKING_DIR"
  [ "$output" = "skill:mine" ]
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

@test "_days_since_round prefers the newest archived report without a task id" {
  echo '{"round":4,"timestamp":"1970-01-01T00:00:00Z"}' > "$WORKING_DIR/archive/2026-01-01-round-4-report.json"
  echo '{"round":4,"timestamp":"1970-01-03T00:00:00Z"}' > "$WORKING_DIR/archive/2026-03-01-round-4-report.json"
  NOW_EPOCH=$((10 * 86400)); export NOW_EPOCH
  run _days_since_round 4 "$WORKING_DIR"
  [ "$output" = "8" ]
}

@test "_days_since_round uses the report from the same archived run as the task" {
  echo '[{"id":"t","description":"x","files_touched":[],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-01-01-tasks-round-4.json"
  echo '[{"id":"other","description":"x","files_touched":[],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-03-01-tasks-round-4.json"
  echo '{"round":4,"timestamp":"1970-01-01T00:00:00Z"}' > "$WORKING_DIR/archive/2026-01-01-round-4-report.json"
  echo '{"round":4,"timestamp":"1970-01-03T00:00:00Z"}' > "$WORKING_DIR/archive/2026-03-01-round-4-report.json"
  NOW_EPOCH=$((10 * 86400)); export NOW_EPOCH
  run _days_since_round 4 "$WORKING_DIR" t
  [ "$output" = "10" ]
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

# --- Q-047: Run column steers lookups to the row's own run ---

@test "_find_tasks_file with a run id prefers that run's archive over a newer one" {
  echo '[{"id":"t","description":"x","files_touched":["skills/mine/SKILL.md"],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-01-01-tasks-round-7.json"
  echo '[{"id":"t","description":"x","files_touched":["skills/reused/SKILL.md"],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-03-01-tasks-round-7.json"
  run _resolve_hypothesis_target 7 t "$WORKING_DIR" 2026-01-01
  [ "$output" = "skill:mine" ]
  # Without a run id (a pre-Run row) the newest copy still wins.
  run _resolve_hypothesis_target 7 t "$WORKING_DIR"
  [ "$output" = "skill:reused" ]
}

@test "_find_tasks_file with a run id uses the live file when the live run matches" {
  echo "2026-05-05" > "$WORKING_DIR/si-run-id.txt"
  write_tasks 7 '[{"id":"t","description":"x","files_touched":["skills/live/SKILL.md"],"independent":true}]'
  echo '[{"id":"t","description":"x","files_touched":["skills/old/SKILL.md"],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-01-01-tasks-round-7.json"
  run _resolve_hypothesis_target 7 t "$WORKING_DIR" 2026-05-05
  [ "$output" = "skill:live" ]
}

@test "_find_tasks_file skips the live file of a different run when the row's run is archived" {
  echo "2026-05-05" > "$WORKING_DIR/si-run-id.txt"
  write_tasks 7 '[{"id":"t","description":"x","files_touched":["skills/live/SKILL.md"],"independent":true}]'
  echo '[{"id":"t","description":"x","files_touched":["skills/old/SKILL.md"],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-01-01-tasks-round-7.json"
  run _resolve_hypothesis_target 7 t "$WORKING_DIR" 2026-01-01
  [ "$output" = "skill:old" ]
}

@test "_find_tasks_file falls back to newest-first when the row's run has no copy" {
  echo '[{"id":"t","description":"x","files_touched":["skills/new/SKILL.md"],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-03-01-tasks-round-7.json"
  run _resolve_hypothesis_target 7 t "$WORKING_DIR" 2025-12-31
  [ "$output" = "skill:new" ]
}

@test "_days_since_round with a run id uses that run's archived report" {
  echo '{"round":4,"timestamp":"1970-01-01T00:00:00Z"}' > "$WORKING_DIR/archive/2026-01-01-round-4-report.json"
  echo '{"round":4,"timestamp":"1970-01-03T00:00:00Z"}' > "$WORKING_DIR/archive/2026-03-01-round-4-report.json"
  NOW_EPOCH=$((10 * 86400)); export NOW_EPOCH
  run _days_since_round 4 "$WORKING_DIR" "" 2026-01-01
  [ "$output" = "10" ]
}

@test "_days_since_round with a run id ignores a live report from a different run" {
  echo "2026-05-05" > "$WORKING_DIR/si-run-id.txt"
  write_round_report 4 "1970-01-09T00:00:00Z"
  echo '{"round":4,"timestamp":"1970-01-01T00:00:00Z"}' > "$WORKING_DIR/archive/2026-01-01-round-4-report.json"
  NOW_EPOCH=$((10 * 86400)); export NOW_EPOCH
  run _days_since_round 4 "$WORKING_DIR" "" 2026-01-01
  [ "$output" = "10" ]
  # 1970-01-09 is epoch day 8, so the live run's report is 2 days old.
  run _days_since_round 4 "$WORKING_DIR" "" 2026-05-05
  [ "$output" = "2" ]
}

# --- A6(b): an archived/missing si-run-id.txt does not make every run match ---

@test "_live_run_matches: empty run matches; missing or empty si-run-id.txt does not" {
  run _live_run_matches "$WORKING_DIR" ""
  [ "$status" -eq 0 ]
  run _live_run_matches "$WORKING_DIR" 2026-01-01-000000
  [ "$status" -eq 1 ]
  : > "$WORKING_DIR/si-run-id.txt"
  run _live_run_matches "$WORKING_DIR" 2026-01-01-000000
  [ "$status" -eq 1 ]
  echo "2026-01-01-000000" > "$WORKING_DIR/si-run-id.txt"
  run _live_run_matches "$WORKING_DIR" 2026-01-01-000000
  [ "$status" -eq 0 ]
  run _live_run_matches "$WORKING_DIR" 2026-01-01-000001
  [ "$status" -eq 1 ]
}

@test "_days_since_round does not take the live report as the row's run once si-run-id.txt is archived" {
  # si-run-id.txt is gone (archived). The live report belongs to some other
  # run; the task's own archived tasks file points at its paired report.
  write_round_report 4 "1970-01-09T00:00:00Z"
  echo '[{"id":"t","description":"x","files_touched":["skills/foo/SKILL.md"],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-01-01-000000-tasks-round-4.json"
  echo '{"round":4,"timestamp":"1970-01-01T00:00:00Z"}' \
    > "$WORKING_DIR/archive/2026-01-01-000000-round-4-report.json"
  NOW_EPOCH=$((10 * 86400)); export NOW_EPOCH
  # Row run id with no archived copy of its own (e.g. renamed on archive).
  run _days_since_round 4 "$WORKING_DIR" t 2026-02-02-000000
  [ "$output" = "10" ]
}

# --- A6(c): the Run cell is validated before it builds archive paths ---

@test "_find_tasks_file ignores a Run cell that would leave archive/ and falls back newest-first" {
  mkdir -p "$TEST_TMPDIR/outside"
  echo '[{"id":"t","description":"x","files_touched":["skills/evil/SKILL.md"],"independent":true}]' \
    > "$TEST_TMPDIR/outside/x-tasks-round-7.json"
  echo '[{"id":"t","description":"x","files_touched":["skills/good/SKILL.md"],"independent":true}]' \
    > "$WORKING_DIR/archive/2026-03-01-tasks-round-7.json"
  run _resolve_hypothesis_target 7 t "$WORKING_DIR" "../../outside/x"
  [ "$output" = "skill:good" ]
}

@test "_days_since_round ignores a Run cell that would leave archive/" {
  mkdir -p "$TEST_TMPDIR/outside"
  echo '{"round":4,"timestamp":"1970-01-01T00:00:00Z"}' > "$TEST_TMPDIR/outside/x-round-4-report.json"
  write_round_report 4 "1970-01-09T00:00:00Z"
  NOW_EPOCH=$((10 * 86400)); export NOW_EPOCH
  run _days_since_round 4 "$WORKING_DIR" "" "../../outside/x"
  [ "$output" = "2" ]
}
