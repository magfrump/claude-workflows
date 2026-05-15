#!/usr/bin/env bats
# @category fast
# Unit tests for _summary_stale_inconclusive in
# scripts/lib/si-morning-summary.sh.
#
# Covers the threshold logic:
#   - window-elapsed counting (>= 5 rounds past round + window)
#   - evidence-window check (task_id absent from round reports in the
#     [current_round-2 .. current_round] window)
#   - boundary cases at the threshold edges
#   - outcome filter (only "INCONCLUSIVE", not INCONCLUSIVE-EXPIRED/CONFIRMED/REFUTED/empty)
#   - missing-input handling

setup() {
  # log-format.sh defines printf helpers other sourced functions expect.
  source "$BATS_TEST_DIRNAME/../scripts/lib/log-format.sh"
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-morning-summary.sh"

  TEST_TMPDIR=$(mktemp -d)
  WORKING_DIR="$TEST_TMPDIR/working"
  mkdir -p "$WORKING_DIR"
  LOG="$WORKING_DIR/hypothesis-log.md"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Write a hypothesis log with the current decision-012+ header and a list of
# pipe-delimited data rows (passed as a single string with newlines).
write_log() {
  local rows="$1"
  {
    echo "# Hypothesis Log"
    echo ""
    echo "| Round | Task ID | Hypothesis | Source | Window | Evaluator | Requires | Checked at Round | Outcome | Status Date | Evidence |"
    echo "|-------|---------|------------|--------|--------|-----------|----------|------------------|---------|-------------|----------|"
    printf '%s\n' "$rows"
  } > "$LOG"
}

# Write a round report keyed by the task_ids referenced as recent evidence.
write_report() {
  local round="$1"
  shift
  local validation="{"
  local first=1
  local tid
  for tid in "$@"; do
    if [ $first -eq 1 ]; then
      first=0
    else
      validation+=","
    fi
    validation+="\"$tid\":{\"verdict\":\"approved\"}"
  done
  validation+="}"
  echo "{\"round\":$round,\"validation\":$validation}" \
    > "$WORKING_DIR/round-${round}-report.json"
}

# --- Window-elapsed boundary ---

@test "surfaces row when elapsed exactly 5 rounds" {
  # round=2, window=3, current=10 -> elapsed = 10 - 2 - 3 = 5 (qualifies)
  write_log "| 2 | hyp-elapsed-5 | A claim about feature X. |  | 3 | user |  | 5 | INCONCLUSIVE |  | precondition unmet |"
  run _summary_stale_inconclusive "$LOG" 10 "$WORKING_DIR"
  [[ "$output" == *"hyp-elapsed-5"* ]]
  [[ "$output" == *"elapsed 5"* ]]
}

@test "does not surface row when elapsed only 4 rounds" {
  # round=2, window=3, current=9 -> elapsed = 4 (just below threshold)
  write_log "| 2 | hyp-elapsed-4 | A claim about feature Y. |  | 3 | user |  | 5 | INCONCLUSIVE |  | precondition unmet |"
  run _summary_stale_inconclusive "$LOG" 9 "$WORKING_DIR"
  [[ "$output" != *"hyp-elapsed-4"* ]]
  [[ "$output" == *"No stale INCONCLUSIVE hypotheses"* ]]
}

@test "surfaces row when elapsed well past 5 rounds" {
  write_log "| 1 | hyp-elapsed-10 | A long-stale claim. |  | 2 | user |  | 3 | INCONCLUSIVE |  | never tried |"
  run _summary_stale_inconclusive "$LOG" 13 "$WORKING_DIR"
  [[ "$output" == *"hyp-elapsed-10"* ]]
  [[ "$output" == *"elapsed 10"* ]]
}

# --- Evidence-window boundary ---

@test "does not surface row when task_id appears in current_round-2 report" {
  # Stale-by-time, but a recent report mentions it -> excluded
  write_log "| 1 | hyp-recent | Was inconclusive. |  | 2 | user |  | 3 | INCONCLUSIVE |  | precondition unmet |"
  write_report 8 hyp-recent     # current-2 = 8 if current = 10
  run _summary_stale_inconclusive "$LOG" 10 "$WORKING_DIR"
  [[ "$output" != *"- **hyp-recent**"* ]]
  [[ "$output" == *"No stale INCONCLUSIVE hypotheses"* ]]
}

@test "surfaces row when task_id last seen at current_round-3 (just outside window)" {
  write_log "| 1 | hyp-outside | Was inconclusive. |  | 2 | user |  | 3 | INCONCLUSIVE |  | precondition unmet |"
  write_report 7 hyp-outside    # current-3 = 7 if current = 10, outside [8..10]
  run _summary_stale_inconclusive "$LOG" 10 "$WORKING_DIR"
  [[ "$output" == *"- **hyp-outside**"* ]]
}

@test "exact whole-line match: task_id substring in another id does not count as recent" {
  # foo appears as part of foo-retry in a recent report; foo itself
  # has not been referenced. Should still surface foo as stale.
  write_log "| 1 | foo | Was inconclusive. |  | 2 | user |  | 3 | INCONCLUSIVE |  | x |"
  write_report 10 foo-retry
  run _summary_stale_inconclusive "$LOG" 10 "$WORKING_DIR"
  [[ "$output" == *"- **foo**"* ]]
}

@test "evidence-window scan clamps to round 1 when current_round is small" {
  # current_round=2 -> start_r would be 0; clamp to 1. Stale gate also
  # applies: with window=0 the row is elapsed 2 (not yet 5), so no row
  # surfaces. This test verifies no crash with tiny current_round.
  write_log "| 1 | small-current | Small-current case. |  | 0 | user |  | 1 | INCONCLUSIVE |  | x |"
  run _summary_stale_inconclusive "$LOG" 2 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No stale INCONCLUSIVE hypotheses"* ]]
}

# --- Outcome filter ---

@test "ignores rows with CONFIRMED outcome regardless of staleness" {
  write_log "| 1 | hyp-confirmed | Confirmed claim. |  | 2 | user |  | 3 | CONFIRMED |  | evidence found |"
  run _summary_stale_inconclusive "$LOG" 20 "$WORKING_DIR"
  [[ "$output" != *"hyp-confirmed"* ]]
  [[ "$output" == *"No stale INCONCLUSIVE hypotheses"* ]]
}

@test "ignores rows with REFUTED outcome regardless of staleness" {
  write_log "| 1 | hyp-refuted | Refuted claim. |  | 2 | user |  | 3 | REFUTED |  | refuted |"
  run _summary_stale_inconclusive "$LOG" 20 "$WORKING_DIR"
  [[ "$output" != *"hyp-refuted"* ]]
}

@test "ignores rows with INCONCLUSIVE-EXPIRED outcome (already handled)" {
  write_log "| 1 | hyp-expired | Expired claim. |  | 2 | user |  | 3 | INCONCLUSIVE-EXPIRED | 2026-04-06 | window expired |"
  run _summary_stale_inconclusive "$LOG" 20 "$WORKING_DIR"
  [[ "$output" != *"hyp-expired"* ]]
}

@test "ignores rows with empty Outcome (still tracking)" {
  write_log "| 1 | hyp-empty | Still tracking. |  | 2 | user |  | 3 |  |  |  |"
  run _summary_stale_inconclusive "$LOG" 20 "$WORKING_DIR"
  [[ "$output" != *"hyp-empty"* ]]
}

# --- Multiple rows, mixed verdicts ---

@test "surfaces only the qualifying INCONCLUSIVE row from a mixed log" {
  write_log "| 1 | a-conf | Confirmed. |  | 2 | user |  | 3 | CONFIRMED |  | x |
| 1 | b-stale | Stale inc. |  | 2 | user |  | 3 | INCONCLUSIVE |  | x |
| 1 | c-fresh | Fresh inc. |  | 2 | user |  | 12 | INCONCLUSIVE |  | x |
| 1 | d-refuted | Refuted. |  | 2 | user |  | 3 | REFUTED |  | x |"
  # current=10: b-stale qualifies (elapsed=7); c-fresh is too fresh
  # (elapsed=10-1-12 = -3, so window not yet closed at all).
  run _summary_stale_inconclusive "$LOG" 10 "$WORKING_DIR"
  [[ "$output" == *"b-stale"* ]]
  [[ "$output" != *"a-conf"* ]]
  [[ "$output" != *"c-fresh"* ]]
  [[ "$output" != *"d-refuted"* ]]
}

# --- Recommendation prose ---

@test "emits reframe/archive recommendation only when at least one candidate exists" {
  write_log "| 1 | hyp-stale | Stale. |  | 2 | user |  | 3 | INCONCLUSIVE |  | x |"
  run _summary_stale_inconclusive "$LOG" 10 "$WORKING_DIR"
  [[ "$output" == *"reframe"* ]]
  [[ "$output" == *"archive"* ]]
  [[ "$output" == *"docs/thoughts/hypothesis-archive.md"* ]]
}

@test "does not emit reframe prose when no candidates surface" {
  write_log "| 1 | hyp-confirmed | x. |  | 2 | user |  | 3 | CONFIRMED |  | x |"
  run _summary_stale_inconclusive "$LOG" 10 "$WORKING_DIR"
  [[ "$output" != *"Recommend either"* ]]
  [[ "$output" == *"No stale INCONCLUSIVE hypotheses"* ]]
}

# --- Section header always present ---

@test "always emits the section heading" {
  write_log "| 1 | hyp | A claim. |  | 2 | user |  | 3 | INCONCLUSIVE |  | x |"
  run _summary_stale_inconclusive "$LOG" 10 "$WORKING_DIR"
  [[ "$output" == *"## Stale INCONCLUSIVE — archive candidates"* ]]
}

# --- Missing-input handling ---

@test "emits friendly message when hypothesis log is missing" {
  run _summary_stale_inconclusive "$WORKING_DIR/does-not-exist.md" 10 "$WORKING_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No hypothesis log found"* ]]
}

@test "emits friendly message when current_round is zero" {
  write_log "| 1 | hyp | A claim. |  | 2 | user |  | 3 | INCONCLUSIVE |  | x |"
  run _summary_stale_inconclusive "$LOG" 0 "$WORKING_DIR"
  [[ "$output" == *"cannot evaluate staleness"* ]]
}

@test "emits friendly message when current_round is non-numeric" {
  write_log "| 1 | hyp | A claim. |  | 2 | user |  | 3 | INCONCLUSIVE |  | x |"
  run _summary_stale_inconclusive "$LOG" "abc" "$WORKING_DIR"
  [[ "$output" == *"cannot evaluate staleness"* ]]
}

# --- Non-integer round/window in a row ---

@test "skips rows where round is non-integer" {
  write_log "| TBD | hyp-bad-round | A claim. |  | 2 | user |  | 3 | INCONCLUSIVE |  | x |"
  run _summary_stale_inconclusive "$LOG" 10 "$WORKING_DIR"
  [[ "$output" != *"hyp-bad-round"* ]]
}

@test "skips rows where window is non-integer" {
  write_log "| 1 | hyp-bad-window | A claim. |  | TBD | user |  | 3 | INCONCLUSIVE |  | x |"
  run _summary_stale_inconclusive "$LOG" 10 "$WORKING_DIR"
  [[ "$output" != *"hyp-bad-window"* ]]
}

# --- Output format ---

@test "renders the per-row entry with task_id, round, window, elapsed, and hypothesis text" {
  write_log "| 2 | hyp-format | A meaningful claim about thing Z. |  | 3 | user |  | 5 | INCONCLUSIVE |  | precondition unmet |"
  run _summary_stale_inconclusive "$LOG" 12 "$WORKING_DIR"
  [[ "$output" == *"- **hyp-format** (round 2, window 3, elapsed 7): A meaningful claim about thing Z"* ]]
}
