#!/usr/bin/env bats
# @category fast
# Unit tests for append_approved_hypotheses() from lib/si-functions.sh

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-functions.sh"
  TEST_TMPDIR=$(mktemp -d)
  TASKS="$TEST_TMPDIR/tasks.json"
  LOG="$TEST_TMPDIR/hypothesis-log.md"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

write_tasks() {
  echo "$1" > "$TASKS"
}

@test "creates log with header when absent and appends row" {
  write_tasks '[{"id":"task-a","description":"x","files_touched":["a"],"independent":true,"hypothesis":"foo will happen","hypothesis_window":2}]'
  append_approved_hypotheses 3 "$TASKS" "$LOG" "task-a"

  grep -q '^# Hypothesis Log' "$LOG"
  grep -q '^| Round | Task ID | Hypothesis | Source | Window | Evaluator | Requires | Checked at Round' "$LOG"
  # Row schema: round | tid | hyp | source | window | evaluator | requires | checked_at | ...
  # Older tasks (no source/evaluator/requires) emit empty cells for those columns.
  grep -qE '^\| 3 \| task-a \| foo will happen \|  \| 2 \|  \|  \| 5 \|' "$LOG"
}

@test "uses default window of 3 when value is non-numeric" {
  write_tasks '[{"id":"task-b","description":"x","files_touched":["a"],"independent":true,"hypothesis":"bar","hypothesis_window":"oops"}]'
  append_approved_hypotheses 2 "$TASKS" "$LOG" "task-b"
  grep -qE '^\| 2 \| task-b \| bar \|  \| 3 \|  \|  \| 5 \|' "$LOG"
}

@test "skips tasks without a hypothesis and warns" {
  write_tasks '[{"id":"task-c","description":"x","files_touched":["a"],"independent":true}]'
  run append_approved_hypotheses 1 "$TASKS" "$LOG" "task-c"
  [[ "$output" == *"no hypothesis recorded"* ]]
  # No data row should exist (just header).
  ! grep -qE '^\| 1 \|' "$LOG"
}

@test "only approved tasks are logged" {
  write_tasks '[
    {"id":"task-a","description":"x","files_touched":["a"],"independent":true,"hypothesis":"alpha","hypothesis_window":1},
    {"id":"task-b","description":"x","files_touched":["a"],"independent":true,"hypothesis":"beta","hypothesis_window":1}
  ]'
  append_approved_hypotheses 1 "$TASKS" "$LOG" "task-a"
  grep -q 'alpha' "$LOG"
  ! grep -q 'beta' "$LOG"
}

@test "appends without glomming when existing log lacks trailing newline" {
  printf '# Hypothesis Log\n\n| Round | Task ID | Hypothesis | Source | Window | Evaluator | Requires | Checked at Round | Outcome | Status Date | Evidence |\n|-|-|-|-|-|-|-|-|-|-|-|\n| 1 | old | old hyp |  | 1 | user |  | 2 | CONFIRMED | | done |' > "$LOG"
  write_tasks '[{"id":"task-a","description":"x","files_touched":["a"],"independent":true,"hypothesis":"new hyp","hypothesis_window":1}]'
  append_approved_hypotheses 2 "$TASKS" "$LOG" "task-a"
  # The new row must be on its own line, not appended to the previous row.
  grep -qE '^\| 2 \| task-a \| new hyp \|' "$LOG"
}

@test "pipe characters in hypothesis text are escaped" {
  write_tasks '[{"id":"task-p","description":"x","files_touched":["a"],"independent":true,"hypothesis":"a | b","hypothesis_window":1}]'
  append_approved_hypotheses 1 "$TASKS" "$LOG" "task-p"
  grep -q 'a \\| b' "$LOG"
}

# --- decision 012 pillar 1: evaluator + requires columns ---

@test "evaluator and requires columns are populated when task has them" {
  write_tasks '[{
    "id":"task-ev","description":"x","files_touched":["a"],"independent":true,
    "hypothesis":"latency stays below threshold","hypothesis_window":2,
    "evaluator":"script",
    "requires":{"metric_logged":"latency_p95","invocations":10}
  }]'
  append_approved_hypotheses 4 "$TASKS" "$LOG" "task-ev"
  # Row: round | tid | hyp | source | window | evaluator | requires | checked_at | ...
  grep -qE '^\| 4 \| task-ev \| latency stays below threshold \|  \| 2 \| script \| metric_logged=latency_p95;invocations=10 \| 6 \|' "$LOG"
}

@test "user-evaluator with no requires emits empty requires cell" {
  write_tasks '[{
    "id":"task-u","description":"x","files_touched":["a"],"independent":true,
    "hypothesis":"user notices something","hypothesis_window":3,
    "evaluator":"user"
  }]'
  append_approved_hypotheses 1 "$TASKS" "$LOG" "task-u"
  grep -qE '^\| 1 \| task-u \| user notices something \|  \| 3 \| user \|  \| 4 \|' "$LOG"
}

# --- decision 012 pillar 3: hypothesis_source column ---

@test "hypothesis_source column is populated when task carries it" {
  write_tasks '[{
    "id":"task-src","description":"x","files_touched":["a"],"independent":true,
    "hypothesis":"the user attached this","hypothesis_window":2,
    "hypothesis_source":"user","evaluator":"user"
  }]'
  append_approved_hypotheses 2 "$TASKS" "$LOG" "task-src"
  grep -qE '^\| 2 \| task-src \| the user attached this \| user \| 2 \| user \|' "$LOG"
}

@test "planner-source hypothesis is logged with planner in Source cell" {
  write_tasks '[{
    "id":"task-plan","description":"x","files_touched":["a"],"independent":true,
    "hypothesis":"the planner invented this","hypothesis_window":1,
    "hypothesis_source":"planner","evaluator":"user"
  }]'
  append_approved_hypotheses 1 "$TASKS" "$LOG" "task-plan"
  grep -qE '^\| 1 \| task-plan \| the planner invented this \| planner \| 1 \| user \|' "$LOG"
}

@test "missing hypothesis_source leaves the cell empty (legacy task)" {
  write_tasks '[{"id":"task-old","description":"x","files_touched":["a"],"independent":true,"hypothesis":"legacy","hypothesis_window":1}]'
  append_approved_hypotheses 1 "$TASKS" "$LOG" "task-old"
  grep -qE '^\| 1 \| task-old \| legacy \|  \| 1 \|' "$LOG"
}

# --- Q-047: Run column (which self-improvement run a row belongs to) ---

@test "new log header ends with a Run column and rows carry the run id" {
  write_tasks '[{"id":"task-r","description":"x","files_touched":["a"],"independent":true,"hypothesis":"ran","hypothesis_window":1}]'
  append_approved_hypotheses 2 "$TASKS" "$LOG" "task-r" "2026-09-21"
  grep -qE '^\| Round \|.*\| Evidence \| Run \|$' "$LOG"
  grep -qE '^\|-+\|.*\|-+\|-+\|$' "$LOG"
  grep -qE '^\| 2 \| task-r \| ran \|.*\| 2026-09-21 \|$' "$LOG"
}

@test "omitted run id leaves the Run cell empty" {
  write_tasks '[{"id":"task-n","description":"x","files_touched":["a"],"independent":true,"hypothesis":"norun","hypothesis_window":1}]'
  append_approved_hypotheses 1 "$TASKS" "$LOG" "task-n"
  grep -qE '^\| 1 \| task-n \| norun \|.*\|  \|$' "$LOG"
}

@test "log with a pre-Run header is migrated in place, old rows untouched" {
  printf '# Hypothesis Log\n\n| Round | Task ID | Hypothesis | Source | Window | Evaluator | Requires | Checked at Round | Outcome | Status Date | Evidence |\n|-|-|-|-|-|-|-|-|-|-|-|\n| 1 | old | old hyp |  | 1 | user |  | 2 | | | |\n' > "$LOG"
  write_tasks '[{"id":"task-m","description":"x","files_touched":["a"],"independent":true,"hypothesis":"migrated","hypothesis_window":1}]'
  append_approved_hypotheses 3 "$TASKS" "$LOG" "task-m" "2026-09-21"
  grep -qE '^\| Round \|.*\| Evidence \| Run \|$' "$LOG"
  grep -qxF '|-|-|-|-|-|-|-|-|-|-|-|-----|' "$LOG"
  grep -qxF '| 1 | old | old hyp |  | 1 | user |  | 2 | | | |' "$LOG"
  grep -qE '^\| 3 \| task-m \| migrated \|.*\| 2026-09-21 \|$' "$LOG"
}

@test "migration is idempotent: a second append does not add a second Run column" {
  write_tasks '[{"id":"task-a","description":"x","files_touched":["a"],"independent":true,"hypothesis":"one","hypothesis_window":1},{"id":"task-b","description":"x","files_touched":["a"],"independent":true,"hypothesis":"two","hypothesis_window":1}]'
  append_approved_hypotheses 1 "$TASKS" "$LOG" "task-a" "r1"
  append_approved_hypotheses 2 "$TASKS" "$LOG" "task-b" "r1"
  [ "$(grep -c ' Run |' "$LOG")" -eq 1 ]
  [ "$(grep -o '| Run |' "$LOG" | wc -l)" -eq 1 ]
}

# --- R5: migration keeps the log's inode and mode; no-op paths do not write ---

@test "migration preserves the log's file mode and inode" {
  printf '# Hypothesis Log\n\n| Round | Task ID | Hypothesis | Source | Window | Evaluator | Requires | Checked at Round | Outcome | Status Date | Evidence |\n|-|-|-|-|-|-|-|-|-|-|-|\n' > "$LOG"
  chmod 0644 "$LOG"
  local inode_before
  inode_before=$(stat -c %i "$LOG")
  _migrate_hypothesis_log_run_column "$LOG"
  grep -qE '^\| Round \|.*\| Evidence \| Run \|$' "$LOG"
  [ "$(stat -c %a "$LOG")" = "644" ]
  [ "$(stat -c %i "$LOG")" = "$inode_before" ]
  # No temp file is left behind.
  [ "$(find "$TEST_TMPDIR" -name 'hypothesis-log.md.*' | wc -l)" -eq 0 ]
}

@test "migration is a true no-op when the header already has a Run cell" {
  printf '| Round | Task ID | Run |\n|-|-|-|\n' > "$LOG"
  chmod 0644 "$LOG"
  touch -d '2000-01-01 00:00:00' "$LOG"
  local before
  before=$(stat -c '%i %Y %a' "$LOG")
  _migrate_hypothesis_log_run_column "$LOG"
  [ "$(stat -c '%i %Y %a' "$LOG")" = "$before" ]
}

@test "migration is a true no-op when no header row is found" {
  printf '# Hypothesis Log\n\nno table yet\n' > "$LOG"
  chmod 0644 "$LOG"
  touch -d '2000-01-01 00:00:00' "$LOG"
  local before
  before=$(stat -c '%i %Y %a' "$LOG")
  _migrate_hypothesis_log_run_column "$LOG"
  [ "$(stat -c '%i %Y %a' "$LOG")" = "$before" ]
}

# --- A6(a): the default run id is unique per run, not per day ---

@test "si_default_run_id is date plus time of day and passes the run-id charset" {
  local id
  id=$(si_default_run_id)
  [[ "$id" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}$ ]]
  [[ "$id" =~ ^[A-Za-z0-9._-]+$ ]]
}

@test "si_default_run_id differs for two runs started on the same day" {
  date() { [ "$1" = "+%F-%H%M%S" ] && echo "2026-09-21-${FAKE_TIME}"; }
  local a b
  a=$(FAKE_TIME=010203 si_default_run_id)
  b=$(FAKE_TIME=235959 si_default_run_id)
  [ "$a" = "2026-09-21-010203" ]
  [ "$b" = "2026-09-21-235959" ]
  [ "$a" != "$b" ]
}
