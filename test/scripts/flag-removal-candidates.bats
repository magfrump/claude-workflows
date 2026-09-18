#!/usr/bin/env bats
# Tests for scripts/flag-removal-candidates.sh
#
# Central use cases:
#   1. Flags REFUTED / INCONCLUSIVE-EXPIRED rows from the hypothesis log,
#      locating the Outcome column by header name (the schema has grown from
#      8 to 11 columns; positional parsing silently flagged nothing)
#   2. Auto-detects the latest round from round-history.json, which is a
#      JSON array of round objects
#   3. Maps a flagged task ID to skill files in both layouts

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/scripts/flag-removal-candidates.sh"

setup() {
  TEST_DIR=$(mktemp -d)
  export HYPOTHESIS_LOG_FILE="$TEST_DIR/hypothesis-log.md"
  export ROUND_HISTORY_FILE="$TEST_DIR/round-history.json"
  export SKILLS_DIR="$TEST_DIR/skills"
  export WORKFLOWS_DIR="$TEST_DIR/workflows"
  export GUIDES_DIR="$TEST_DIR/guides"
  mkdir -p "$SKILLS_DIR" "$WORKFLOWS_DIR" "$GUIDES_DIR"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# Current 11-column header, as written by append_approved_hypotheses in
# scripts/lib/si-functions.sh.
write_current_log() {
  cat > "$HYPOTHESIS_LOG_FILE" <<'EOF'
# Hypothesis Log

| Round | Task ID | Hypothesis | Source | Window | Evaluator | Requires | Checked at Round | Outcome | Status Date | Evidence |
|-------|---------|------------|--------|--------|-----------|----------|------------------|---------|-------------|----------|
| 3 | zz-refuted-task | Refuted hyp | planner | 3 | agent | | 6 | REFUTED | 2026-09-01 | no effect seen |
| 3 | zz-expired-task | Expired hyp | planner | 3 | human | | 6 | INCONCLUSIVE-EXPIRED | 2026-09-01 | window lapsed |
| 4 | zz-confirmed-task | Confirmed hyp | planner | 3 | agent | | 7 | CONFIRMED | 2026-09-02 | worked |
| 5 | zz-open-task | Open hyp | planner | 3 | agent | | 8 | | | |
EOF
}

@test "flags REFUTED and INCONCLUSIVE-EXPIRED rows in the current 11-column log" {
  write_current_log
  run bash "$SCRIPT" --round=9
  [ "$status" -eq 0 ]
  [[ "$output" == *"zz-refuted-task [REFUTED]"* ]]
  [[ "$output" == *"zz-expired-task [INCONCLUSIVE-EXPIRED]"* ]]
  [[ "$output" == *"Evidence: no effect seen"* ]]
  [[ "$output" == *"Hypothesis: Refuted hyp"* ]]
  [[ "$output" != *"zz-confirmed-task"* ]]
  [[ "$output" != *"zz-open-task"* ]]
  [[ "$output" == *"2 candidate(s) flagged"* ]]
}

@test "an escaped pipe in hypothesis text does not shift the Outcome column" {
  write_current_log
  printf '%s\n' '| 6 | zz-pipe-task | Uses a \| b | planner | 3 | agent | | 9 | REFUTED | 2026-09-03 | piped |' \
    >> "$HYPOTHESIS_LOG_FILE"
  run bash "$SCRIPT" --round=9
  [ "$status" -eq 0 ]
  [[ "$output" == *"zz-pipe-task [REFUTED]"* ]]
  [[ "$output" == *'Hypothesis: Uses a \| b'* ]]
  [[ "$output" == *"Evidence: piped"* ]]
}

@test "still reads the legacy 8-column log" {
  cat > "$HYPOTHESIS_LOG_FILE" <<'EOF'
| Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Status Date | Evidence |
|-------|---------|------------|--------|------------------|---------|-------------|----------|
| 1 | zz-legacy-task | Legacy hyp | 3 | 4 | REFUTED | 2026-05-01 | legacy evidence |
EOF
  run bash "$SCRIPT" --round=9
  [ "$status" -eq 0 ]
  [[ "$output" == *"zz-legacy-task [REFUTED]"* ]]
  [[ "$output" == *"Evidence: legacy evidence"* ]]
}

@test "auto-detects the latest round from the round-history array" {
  write_current_log
  printf '[{"round":3,"outcome":"complete"},{"round":12,"outcome":"complete"},{"round":7}]\n' \
    > "$ROUND_HISTORY_FILE"
  run bash "$SCRIPT" --markdown
  [ "$status" -eq 0 ]
  [[ "$output" == *"# Removal Candidates — Round 12"* ]]
}

@test "round falls back to ? when round-history is an empty array" {
  write_current_log
  echo '[]' > "$ROUND_HISTORY_FILE"
  run bash "$SCRIPT" --markdown
  [ "$status" -eq 0 ]
  [[ "$output" == *"# Removal Candidates — Round ?"* ]]
}

@test "maps a flagged task ID to a directory-layout skill" {
  write_current_log
  mkdir -p "$SKILLS_DIR/zz-refuted-task"
  touch "$SKILLS_DIR/zz-refuted-task/SKILL.md"
  run bash "$SCRIPT" --round=9
  [ "$status" -eq 0 ]
  [[ "$output" == *"Files: "*"zz-refuted-task/SKILL.md"* ]]
}
