#!/usr/bin/env bats
# @category fast
# Unit tests for prepend_si_input_rejected_history() from lib/si-input.sh.
#
# Verifies the new-cycle bootstrap step that prepends a
# <!-- Recent rejections (last 3 rounds): ... --> HTML-comment block to
# docs/working/si-input.md based on round-<N>-report.json files.

# `run !` and `run -N` are bats >= 1.5 features. Declaring the requirement makes
# bats enforce it (hard error on an older bats) instead of emitting BW02 and
# leaving it an open question whether the flag-carrying assertions really assert.
bats_require_minimum_version 1.5.0

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-input.sh"
  TEST_TMPDIR=$(mktemp -d)
  WORKING_DIR="$TEST_TMPDIR"
  INPUT_FILE="$TEST_TMPDIR/si-input.md"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# --- Helpers ---

write_round_report() {
  local round="$1"
  shift
  local validation_json="$1"
  local path="$WORKING_DIR/round-${round}-report.json"
  jq -n --argjson v "$validation_json" \
    --argjson r "$round" \
    '{round: $r, validation: $v}' > "$path"
}

# Build a validation map with one rejected task. Args: tid reason
rejected_entry() {
  local tid="$1" reason="$2"
  jq -n --arg tid "$tid" --arg reason "$reason" '{
    ($tid): {
      verdict: "rejected",
      verdict_detail: {reject_reason: $reason}
    }
  }'
}

# Merge two validation maps. Args: json1 json2
merge_validations() {
  jq -s '.[0] * .[1]' <(echo "$1") <(echo "$2")
}

# --- Tests ---

@test "no round reports: file is left alone (or absent stays absent)" {
  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"
  [ ! -f "$INPUT_FILE" ]
}

@test "no round reports: pre-existing file is unchanged" {
  printf '## Feedback\n\nuser notes\n' > "$INPUT_FILE"
  local before
  before=$(cat "$INPUT_FILE")
  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"
  [ "$(cat "$INPUT_FILE")" = "$before" ]
}

@test "reports exist but no rejections: file unchanged" {
  write_round_report 1 '{"task-a": {"verdict": "approved"}}'
  printf '## Feedback\n\nuser notes\n' > "$INPUT_FILE"
  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"
  run head -1 "$INPUT_FILE"
  [ "$output" = "## Feedback" ]
}

@test "single rejection: block prepended at top" {
  write_round_report 5 "$(rejected_entry task-foo 'file_scope: touched src/ outside scope')"
  printf '## Feedback\n\nexisting user content\n' > "$INPUT_FILE"

  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"

  run head -1 "$INPUT_FILE"
  [[ "$output" == "<!-- Recent rejections"* ]]

  # The task id and the reason are in the block.
  grep -q 'task-foo' "$INPUT_FILE"
  grep -q 'file_scope: touched src/ outside scope' "$INPUT_FILE"

  # Original user content is preserved.
  grep -q 'existing user content' "$INPUT_FILE"
}

@test "rejection reason: only the first line is included" {
  local reason
  reason=$(printf 'first line summary\nsecond line details\nthird line more')
  write_round_report 4 "$(rejected_entry task-multi "$reason")"

  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"

  grep -q 'first line summary' "$INPUT_FILE"
  run ! grep -q 'second line details' "$INPUT_FILE"
  ! grep -q 'third line more' "$INPUT_FILE"
}

@test "spans many rounds: only the 3 most recent are included" {
  write_round_report 1 "$(rejected_entry task-r1 'oldest')"
  write_round_report 2 "$(rejected_entry task-r2 'old')"
  write_round_report 3 "$(rejected_entry task-r3 'mid')"
  write_round_report 4 "$(rejected_entry task-r4 'newer')"
  write_round_report 5 "$(rejected_entry task-r5 'newest')"

  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"

  # Most recent three (3, 4, 5) included.
  grep -q 'task-r3' "$INPUT_FILE"
  grep -q 'task-r4' "$INPUT_FILE"
  grep -q 'task-r5' "$INPUT_FILE"

  # Older two excluded.
  run ! grep -q 'task-r1' "$INPUT_FILE"
  ! grep -q 'task-r2' "$INPUT_FILE"
}

@test "multiple rejections in same round: all included" {
  local v1 v2 both
  v1=$(rejected_entry task-a 'reason A')
  v2=$(rejected_entry task-b 'reason B')
  both=$(merge_validations "$v1" "$v2")
  write_round_report 7 "$both"

  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"

  grep -q 'task-a' "$INPUT_FILE"
  grep -q 'task-b' "$INPUT_FILE"
  grep -q 'reason A' "$INPUT_FILE"
  grep -q 'reason B' "$INPUT_FILE"
}

@test "block annotates each entry with its round number" {
  write_round_report 8 "$(rejected_entry task-z 'why')"
  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"
  grep -q 'Round 8' "$INPUT_FILE"
}

@test "idempotent: running twice produces same content" {
  write_round_report 2 "$(rejected_entry task-x 'failure mode X')"
  printf '## Feedback\n\nuser notes\n' > "$INPUT_FILE"

  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"
  local first
  first=$(cat "$INPUT_FILE")

  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"
  local second
  second=$(cat "$INPUT_FILE")

  [ "$first" = "$second" ]
}

@test "replaces prior Recent rejections block: does not stack" {
  write_round_report 2 "$(rejected_entry task-old 'old reason')"
  printf '## Feedback\n\nuser notes\n' > "$INPUT_FILE"
  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"

  # New round with different rejections.
  write_round_report 3 "$(rejected_entry task-new 'new reason')"
  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"

  # Only one comment-open marker.
  local open_count
  open_count=$(grep -c '^<!-- Recent rejections' "$INPUT_FILE")
  [ "$open_count" = "1" ]

  grep -q 'task-new' "$INPUT_FILE"
  grep -q 'user notes' "$INPUT_FILE"
}

@test "comment block does not pollute parsed sections" {
  write_round_report 1 "$(rejected_entry task-foo 'something failed')"
  printf '## Feedback\n\nthe real feedback\n\n## Priorities\n\n- priority one\n' > "$INPUT_FILE"
  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"

  parse_si_input "$INPUT_FILE"
  [[ "$SI_FEEDBACK" == *"the real feedback"* ]]
  [[ "$SI_FEEDBACK" != *"task-foo"* ]]
  [[ "$SI_PRIORITIES" == *"priority one"* ]]
  [[ "$SI_PRIORITIES" != *"Recent rejections"* ]]
}

@test "file created from scratch when missing but rejections exist" {
  write_round_report 1 "$(rejected_entry task-fresh 'fresh failure')"
  [ ! -f "$INPUT_FILE" ]
  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"
  [ -f "$INPUT_FILE" ]
  grep -q 'task-fresh' "$INPUT_FILE"
}
