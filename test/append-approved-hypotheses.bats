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
