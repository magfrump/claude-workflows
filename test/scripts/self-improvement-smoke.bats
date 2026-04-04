#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031
# SC2030/SC2031: BATS runs each @test in a subshell; ROUND_LOG_FILE is
# intentionally set and consumed within the same test block.
#
# Smoke test for scripts/self-improvement.sh main execution flow.
#
# Exercises the sequence of exported functions that the main loop wires
# together (init_round_log → update_round_log → validate_task_json →
# record_gate → print_round_summary → finalize_round_log), using pre-built
# fixture files instead of live git/Claude operations.
#
# Catches wiring bugs (wrong variable, missing call, wrong order) that
# individual unit tests cannot detect.
#
# Usage: bats test/scripts/self-improvement-smoke.bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

setup() {
  source "$REPO_ROOT/scripts/self-improvement.sh"

  TEST_TMPDIR=$(mktemp -d)
  WORKING_DIR="$TEST_TMPDIR"
  ROUND_HISTORY="$TEST_TMPDIR/round-history.json"
  echo '[]' > "$ROUND_HISTORY"

  # --- Fixture: feature-ideas markdown (divergent-design output) ---
  cat > "$TEST_TMPDIR/feature-ideas-round-1.md" <<'IDEAS'
## 1. Diverge — Candidate Feature Ideas
1. **Add Logging** — structured JSON logging for all scripts
2. **Retry Logic** — exponential backoff for flaky operations

## 2. Diagnose — Problems and Constraints
### Concrete problems
**P1. Scripts lack structured logging**, making debugging hard.
**P2. Flaky operations fail silently** with no retry mechanism.

### Non-obvious constraints
- **Constraint:** must not add new runtime dependencies

## 3. Match and Prune
| # | Idea | P1 | P2 |
|---|------|:--:|:--:|
| 1 | Add Logging | ✓ | ✗ |
| 2 | Retry Logic | ✗ | ✓ |

### Survivors
- **#1 Add Logging** — structured JSON logging for all scripts
- **#2 Retry Logic** — exponential backoff for flaky operations
IDEAS

  # --- Fixture: tasks JSON (Claude-generated task list) ---
  cat > "$TEST_TMPDIR/tasks-round-1.json" <<'TASKS'
[
  {
    "id": "add-logging",
    "description": "Add structured JSON logging to all shell scripts",
    "files_touched": ["scripts/self-improvement.sh"],
    "independent": true,
    "hypothesis": "Logging will reduce mean debug time by 50%",
    "hypothesis_window": 3
  },
  {
    "id": "retry-logic",
    "description": "Add exponential backoff retry wrapper for flaky operations",
    "files_touched": ["scripts/self-improvement.sh"],
    "independent": true
  }
]
TASKS
}

teardown() {
  rm -rf "$TEST_TMPDIR"
  if [ -n "${ROUND_LOG_FILE:-}" ] && [ -f "$ROUND_LOG_FILE" ]; then
    rm -f "$ROUND_LOG_FILE"
  fi
}

# ---------------------------------------------------------------
# Main smoke test: drive the full round sequence with fixtures
# ---------------------------------------------------------------

@test "smoke: full round sequence produces a valid round report" {
  local round=1

  # Step 1: Initialize round log
  init_round_log "$round"
  [ -f "$ROUND_LOG_FILE" ]
  jq empty "$ROUND_LOG_FILE"

  # Step 2: Record idea generation (simulates Step 1 of main loop)
  local ideas_file="$TEST_TMPDIR/feature-ideas-round-1.md"
  [ -f "$ideas_file" ]
  update_round_log '.ideas' '{"generated": true, "count": 2, "file": "feature-ideas-round-1.md"}'

  # Step 3: Validate task JSON (simulates Step 2 of main loop)
  local tasks_file="$TEST_TMPDIR/tasks-round-1.json"
  local valid_tasks
  valid_tasks=$(validate_task_json "$tasks_file")
  local task_count
  task_count=$(echo "$valid_tasks" | jq 'length')
  [ "$task_count" -eq 2 ]

  # Record task metadata
  local task_ids
  task_ids=$(echo "$valid_tasks" | jq '[.[].id]')
  update_round_log '.tasks' "{\"count\": $task_count, \"ids\": $task_ids}"

  # Step 4: Record validation gates for each task (simulates Step 4)
  for tid in "add-logging" "retry-logic"; do
    record_gate "$tid" "schema"   "pass"
    record_gate "$tid" "commits"  "pass"
    record_gate "$tid" "diff_size" "pass"
    record_gate "$tid" "file_scope" "pass"
    record_gate "$tid" "critical_files" "pass"
    record_gate "$tid" "tests"    "pass"
    record_gate "$tid" "shellcheck" "pass"
    record_gate "$tid" "self_eval" "skip"
  done

  # Approve first task, reject second (to test both paths)
  record_gate "add-logging" "verdict" "approved"
  record_gate "retry-logic" "verdict" "rejected"
  record_gate "retry-logic" "tests"   "fail"

  # Step 5: Record merge results (simulates Step 5)
  update_round_log '.merges' '{"add-logging": "clean"}'

  # Step 6: Print round summary (simulates Step 6)
  local validation_log="$TEST_TMPDIR/validation-round-1.log"
  touch "$validation_log"
  run print_round_summary "$round" "$validation_log"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Round 1"* ]]
  [[ "$output" == *"launched"* ]]
  [[ "$output" == *"approved"* ]]

  # Summary should be written to the log file
  [ -s "$validation_log" ]

  # Step 7: Mark round complete and finalize
  update_round_log '.outcome' '"completed"'
  finalize_round_log "$round"

  # --- Assertions on the produced round report ---

  local report="$TEST_TMPDIR/round-1-report.json"
  [ -f "$report" ]
  jq empty "$report"

  # Round number
  local rnum
  rnum=$(jq '.round' "$report")
  [ "$rnum" -eq 1 ]

  # Outcome
  local outcome
  outcome=$(jq -r '.outcome' "$report")
  [ "$outcome" = "completed" ]

  # Ideas were recorded
  local ideas_generated
  ideas_generated=$(jq '.ideas.generated' "$report")
  [ "$ideas_generated" = "true" ]

  # Tasks were recorded
  local tasks_count
  tasks_count=$(jq '.tasks.count' "$report")
  [ "$tasks_count" -eq 2 ]

  # Validation gates exist for both tasks
  jq -e '.validation["add-logging"].verdict' "$report"
  jq -e '.validation["retry-logic"].verdict' "$report"

  # Verdicts are correct
  local v1 v2
  v1=$(jq -r '.validation["add-logging"].verdict' "$report")
  v2=$(jq -r '.validation["retry-logic"].verdict' "$report")
  [ "$v1" = "approved" ]
  [ "$v2" = "rejected" ]

  # Merge recorded for approved task
  local merge_status
  merge_status=$(jq -r '.merges["add-logging"]' "$report")
  [ "$merge_status" = "clean" ]

  # --- Assertions on round-history.json ---

  jq empty "$ROUND_HISTORY"
  local history_len
  history_len=$(jq 'length' "$ROUND_HISTORY")
  [ "$history_len" -eq 1 ]

  local history_round
  history_round=$(jq '.[0].round' "$ROUND_HISTORY")
  [ "$history_round" -eq 1 ]
}

# ---------------------------------------------------------------
# Verify convergence check integrates with round log state
# ---------------------------------------------------------------

@test "smoke: convergence threshold integrates with round flow" {
  init_round_log 2

  # Simulate a round that converged (overlap above threshold)
  update_round_log '.ideas' '{"generated": true, "count": 3, "file": "feature-ideas-round-2.md"}'

  # check_convergence_threshold is a pure function; verify it works
  # in the context of a live round log session
  run check_convergence_threshold 80 70
  [ "$status" -eq 0 ]

  # Mark as exhausted (what the main loop does on convergence)
  update_round_log '.outcome' '"exhausted"'

  local outcome
  outcome=$(jq -r '.outcome' "$ROUND_LOG_FILE")
  [ "$outcome" = "exhausted" ]

  # Clean up without finalizing (convergence exits early)
  rm -f "$ROUND_LOG_FILE"
  ROUND_LOG_FILE=""
}

# ---------------------------------------------------------------
# Verify hypothesis eligibility check works with fixture tasks
# ---------------------------------------------------------------

@test "smoke: hypothesis eligibility filters fixture tasks correctly" {
  # Use the fixture tasks from setup (round 1 tasks, checked at round 4)
  local tasks_file="$TEST_TMPDIR/tasks-round-1.json"

  # At round 4, window=3 tasks from round 1 should be eligible (4-1 >= 3)
  local eligible
  eligible=$(get_eligible_hypotheses 4 1 < "$tasks_file")

  # add-logging has hypothesis + window=3, round 4-1=3 >= 3 → eligible
  echo "$eligible" | grep -q "add-logging"

  # retry-logic has no hypothesis → not eligible
  ! echo "$eligible" | grep -q "retry-logic"
}

# ---------------------------------------------------------------
# Verify task validation rejects bad tasks in integration context
# ---------------------------------------------------------------

@test "smoke: task validation rejects invalid tasks alongside valid ones" {
  # Create a mixed fixture with valid and invalid tasks
  cat > "$TEST_TMPDIR/mixed-tasks.json" <<'MIXED'
[
  {
    "id": "good-task",
    "description": "A well-formed task",
    "files_touched": ["scripts/self-improvement.sh"],
    "independent": true
  },
  {
    "id": "bad-glob",
    "description": "Uses a glob pattern",
    "files_touched": ["src/*.sh"],
    "independent": true
  },
  {
    "description": "Missing id field",
    "files_touched": ["scripts/self-improvement.sh"],
    "independent": true
  }
]
MIXED

  init_round_log 1

  # Validate — should keep only good-task
  local valid_tasks
  valid_tasks=$(validate_task_json "$TEST_TMPDIR/mixed-tasks.json" 2>/dev/null)
  local count
  count=$(echo "$valid_tasks" | jq 'length')
  [ "$count" -eq 1 ]

  local tid
  tid=$(echo "$valid_tasks" | jq -r '.[0].id')
  [ "$tid" = "good-task" ]

  # Wire into round log (the integration part)
  local task_ids
  task_ids=$(echo "$valid_tasks" | jq '[.[].id]')
  update_round_log '.tasks' "{\"count\": $count, \"ids\": $task_ids}"

  # Verify round log has correct task count
  local logged_count
  logged_count=$(jq '.tasks.count' "$ROUND_LOG_FILE")
  [ "$logged_count" -eq 1 ]

  rm -f "$ROUND_LOG_FILE"
  ROUND_LOG_FILE=""
}

# ---------------------------------------------------------------
# Multi-round: verify round-history accumulates across rounds
# ---------------------------------------------------------------

@test "smoke: two sequential rounds accumulate in round-history.json" {
  for round in 1 2; do
    init_round_log "$round"
    update_round_log '.ideas' "{\"generated\": true, \"count\": $round, \"file\": \"feature-ideas-round-${round}.md\"}"
    update_round_log '.tasks' "{\"count\": $round, \"ids\": [\"task-r${round}\"]}"
    record_gate "task-r${round}" "schema" "pass"
    record_gate "task-r${round}" "verdict" "approved"
    update_round_log '.outcome' '"completed"'
    finalize_round_log "$round"
  done

  jq empty "$ROUND_HISTORY"
  local history_len
  history_len=$(jq 'length' "$ROUND_HISTORY")
  [ "$history_len" -eq 2 ]

  # Round numbers are correct and in order
  local r1 r2
  r1=$(jq '.[0].round' "$ROUND_HISTORY")
  r2=$(jq '.[1].round' "$ROUND_HISTORY")
  [ "$r1" -eq 1 ]
  [ "$r2" -eq 2 ]

  # Each round's report file exists
  [ -f "$TEST_TMPDIR/round-1-report.json" ]
  [ -f "$TEST_TMPDIR/round-2-report.json" ]
}
