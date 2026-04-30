#!/usr/bin/env bats
# @category fast
# Regression tests for morning-summary deferred-question surfacing.
#
# Prior bug: scripts/lib/si-morning-summary.sh surfaced only rows whose
# Outcome column was empty (TRACKING), treating INCONCLUSIVE as if it were
# resolved. This caused a single row to surface in morning-summary.md while
# ~28 INCONCLUSIVE rows in hypothesis-log.md silently went unanswered.
#
# These tests pin the fix: TRACKING and INCONCLUSIVE rows surface;
# INCONCLUSIVE-EXPIRED, CONFIRMED, and REFUTED do not. They also exercise
# the row-count regression assertion that fails when the parser produces
# zero rows despite open hypotheses existing in the log.

setup() {
  source "$BATS_TEST_DIRNAME/../../scripts/lib/si-morning-summary.sh"

  TEST_TMPDIR=$(mktemp -d)
  WORKING_DIR="$TEST_TMPDIR"

  # Minimal companions used by the other summary sections.
  echo '[]' > "$TEST_TMPDIR/round-history.json"
  : > "$TEST_TMPDIR/completed-tasks.md"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Write a fixture log with one row of each outcome type.
write_mixed_outcomes_log() {
  cat > "$TEST_TMPDIR/hypothesis-log.md" <<'EOF'
# Hypothesis Log

| Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Status Date | Evidence |
|-------|---------|------------|--------|------------------|---------|-------------|----------|
| 1 | tracking-task | Empty outcome means tracking. | 3 | 2 | | | |
| 1 | inconclusive-task | Window is still open with no verdict. | 3 | 4 | INCONCLUSIVE | | Some evidence so far. |
| 1 | inconclusive-expired-task | Expired without resolution. | 3 | 4 | INCONCLUSIVE-EXPIRED | 2026-01-01 | |
| 1 | confirmed-task | Confirmed by evidence. | 3 | 4 | CONFIRMED | | Confirmed evidence. |
| 1 | refuted-task | Refuted by evidence. | 3 | 4 | REFUTED | | Refuted evidence. |
EOF
}

# --- Surfacing predicate ---

@test "TRACKING (empty outcome) row is surfaced" {
  write_mixed_outcomes_log
  generate_morning_summary 1 1 "$TEST_TMPDIR/summary.md" "$WORKING_DIR"
  grep -q "tracking-task" "$TEST_TMPDIR/summary.md"
}

@test "INCONCLUSIVE row is surfaced" {
  write_mixed_outcomes_log
  generate_morning_summary 1 1 "$TEST_TMPDIR/summary.md" "$WORKING_DIR"
  grep -q "inconclusive-task" "$TEST_TMPDIR/summary.md"
}

@test "INCONCLUSIVE-EXPIRED row is NOT surfaced" {
  write_mixed_outcomes_log
  generate_morning_summary 1 1 "$TEST_TMPDIR/summary.md" "$WORKING_DIR"
  ! grep -q "inconclusive-expired-task" "$TEST_TMPDIR/summary.md"
}

@test "CONFIRMED row is NOT surfaced" {
  write_mixed_outcomes_log
  generate_morning_summary 1 1 "$TEST_TMPDIR/summary.md" "$WORKING_DIR"
  ! grep -q "confirmed-task" "$TEST_TMPDIR/summary.md"
}

@test "REFUTED row is NOT surfaced" {
  write_mixed_outcomes_log
  generate_morning_summary 1 1 "$TEST_TMPDIR/summary.md" "$WORKING_DIR"
  ! grep -q "refuted-task" "$TEST_TMPDIR/summary.md"
}

@test "summary numbering covers exactly 2 surfaced rows" {
  write_mixed_outcomes_log
  generate_morning_summary 1 1 "$TEST_TMPDIR/summary.md" "$WORKING_DIR"
  surfaced=$(grep -cE '^[0-9]+\. \*\*' "$TEST_TMPDIR/summary.md")
  [ "$surfaced" -eq 2 ]
}

# --- Helper count function ---

@test "_count_surfaceable_hypotheses counts TRACKING and INCONCLUSIVE only" {
  write_mixed_outcomes_log
  result=$(_count_surfaceable_hypotheses "$TEST_TMPDIR/hypothesis-log.md" 0)
  [ "$result" -eq 2 ]
}

@test "_count_surfaceable_hypotheses returns 0 for fully-resolved logs" {
  cat > "$TEST_TMPDIR/hypothesis-log.md" <<'EOF'
# Hypothesis Log

| Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Status Date | Evidence |
|-------|---------|------------|--------|------------------|---------|-------------|----------|
| 1 | done-1 | Done. | 3 | 4 | CONFIRMED | | x |
| 1 | done-2 | Done. | 3 | 4 | REFUTED | | x |
| 1 | done-3 | Done. | 3 | 4 | INCONCLUSIVE-EXPIRED | 2026-01-01 | |
EOF
  result=$(_count_surfaceable_hypotheses "$TEST_TMPDIR/hypothesis-log.md" 0)
  [ "$result" -eq 0 ]
}

@test "_count_surfaceable_hypotheses returns 0 when log file is missing" {
  result=$(_count_surfaceable_hypotheses "$TEST_TMPDIR/no-such-file.md" 0)
  [ "$result" -eq 0 ]
}

# --- internal-si scope filter still applies ---

@test "internal-si scope rows are filtered out when Scope column exists" {
  cat > "$TEST_TMPDIR/hypothesis-log.md" <<'EOF'
# Hypothesis Log

| Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Status Date | Evidence | Scope |
|-------|---------|------------|--------|------------------|---------|-------------|----------|-------|
| 1 | external-task | External hypothesis. | 3 | 2 | | | | external-workflow |
| 1 | internal-task | Internal hypothesis. | 3 | 2 | | | | internal-si |
| 1 | external-inconclusive | Still open externally. | 3 | 2 | INCONCLUSIVE | | | external-workflow |
| 1 | internal-inconclusive | Still open internally. | 3 | 2 | INCONCLUSIVE | | | internal-si |
EOF
  generate_morning_summary 1 1 "$TEST_TMPDIR/summary.md" "$WORKING_DIR"
  grep -q "external-task" "$TEST_TMPDIR/summary.md"
  grep -q "external-inconclusive" "$TEST_TMPDIR/summary.md"
  ! grep -q "internal-task" "$TEST_TMPDIR/summary.md"
  ! grep -q "internal-inconclusive" "$TEST_TMPDIR/summary.md"
}

# --- End-to-end behavior ---

@test "empty/no-open log writes 'No open hypotheses' and returns 0" {
  cat > "$TEST_TMPDIR/hypothesis-log.md" <<'EOF'
# Hypothesis Log

| Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Status Date | Evidence |
|-------|---------|------------|--------|------------------|---------|-------------|----------|
| 1 | done-task | Resolved. | 3 | 4 | CONFIRMED | | x |
EOF
  run generate_morning_summary 1 1 "$TEST_TMPDIR/summary.md" "$WORKING_DIR"
  [ "$status" -eq 0 ]
  grep -q "No open hypotheses to evaluate." "$TEST_TMPDIR/summary.md"
}

@test "missing log file does not trigger regression assertion" {
  # No hypothesis-log.md written.
  run generate_morning_summary 1 1 "$TEST_TMPDIR/summary.md" "$WORKING_DIR"
  [ "$status" -eq 0 ]
  grep -q "No hypothesis log found." "$TEST_TMPDIR/summary.md"
}

# --- Regression assertion ---

@test "assertion fires when loop produces 0 rows but log has open rows" {
  # Simulate a parser regression by replacing the inner loop's outcome
  # extractor with one that misreads every row as resolved. The independent
  # counter still sees the open rows and triggers the assertion.
  write_mixed_outcomes_log

  # Override _summary_deferred_evaluation's per-row case to never match,
  # by swapping in a stub that returns a function whose loop emits nothing
  # but whose helper still sees open rows. Simplest reliable approach:
  # override _count_surfaceable_hypotheses to lie about the count being
  # high while ALSO writing a log whose outcomes happen to be all-resolved.
  cat > "$TEST_TMPDIR/hypothesis-log.md" <<'EOF'
# Hypothesis Log

| Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Status Date | Evidence |
|-------|---------|------------|--------|------------------|---------|-------------|----------|
| 1 | done | Done. | 3 | 4 | CONFIRMED | | x |
EOF
  _count_surfaceable_hypotheses() { echo 5; }
  export -f _count_surfaceable_hypotheses

  run generate_morning_summary 1 1 "$TEST_TMPDIR/summary.md" "$WORKING_DIR"
  [ "$status" -eq 1 ]
  grep -q "REGRESSION" "$TEST_TMPDIR/summary.md"
}

# --- Smoke test against real production log ---

@test "production hypothesis-log.md surfaces multiple rows (smoke)" {
  local prod_log="$BATS_TEST_DIRNAME/../../docs/working/hypothesis-log.md"
  if [ ! -f "$prod_log" ]; then
    skip "no production hypothesis-log.md present"
  fi
  cp "$prod_log" "$TEST_TMPDIR/hypothesis-log.md"
  generate_morning_summary 1 1 "$TEST_TMPDIR/summary.md" "$WORKING_DIR"

  surfaced=$(awk '
    /^## Deferred Evaluation Questions/ { in_section=1; next }
    /^## / && in_section { in_section=0 }
    in_section && /^[0-9]+\. \*\*/ { count++ }
    END { print count + 0 }
  ' "$TEST_TMPDIR/summary.md")

  # Pre-fix: surfaced was 1. Post-fix: must be substantially higher to
  # reflect the dozens of INCONCLUSIVE rows whose windows are still open.
  [ "$surfaced" -gt 5 ]
}
