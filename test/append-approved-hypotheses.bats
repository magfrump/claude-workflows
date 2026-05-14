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
  grep -q '^| Round | Task ID | Hypothesis' "$LOG"
  grep -qE '^\| 3 \| task-a \| foo will happen \| 2 \| 5 \|' "$LOG"
}

@test "uses default window of 3 when value is non-numeric" {
  write_tasks '[{"id":"task-b","description":"x","files_touched":["a"],"independent":true,"hypothesis":"bar","hypothesis_window":"oops"}]'
  append_approved_hypotheses 2 "$TASKS" "$LOG" "task-b"
  grep -qE '^\| 2 \| task-b \| bar \| 3 \| 5 \|' "$LOG"
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
  printf '# Hypothesis Log\n\n| Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Status Date | Evidence |\n|-|-|-|-|-|-|-|-|\n| 1 | old | old hyp | 1 | 2 | CONFIRMED | | done |' > "$LOG"
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
