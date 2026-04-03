#!/usr/bin/env bats
# @category fast
# Guard the round-history.json data contract.
# Downstream consumers (e.g. self-improvement.sh convergence detection)
# rely on each entry having: round, timestamp, validation, outcome.

ROUND_HISTORY="$BATS_TEST_DIRNAME/../docs/working/round-history.json"

setup() {
  if [ ! -f "$ROUND_HISTORY" ]; then
    skip "round-history.json not present"
  fi
  ENTRY_COUNT=$(jq 'length' "$ROUND_HISTORY")
  if [ "$ENTRY_COUNT" -eq 0 ]; then
    skip "round-history.json is empty"
  fi
}

@test "round-history.json is valid JSON" {
  [ ! -f "$ROUND_HISTORY" ] && skip "round-history.json not present"
  jq empty "$ROUND_HISTORY"
}

@test "round-history.json is a JSON array" {
  [ ! -f "$ROUND_HISTORY" ] && skip "round-history.json not present"
  result=$(jq 'type' "$ROUND_HISTORY")
  [ "$result" = '"array"' ]
}

@test "every entry has required field: round" {
  missing=$(jq '[.[] | select(has("round") | not)] | length' "$ROUND_HISTORY")
  [ "$missing" -eq 0 ]
}

@test "every entry has required field: timestamp" {
  missing=$(jq '[.[] | select(has("timestamp") | not)] | length' "$ROUND_HISTORY")
  [ "$missing" -eq 0 ]
}

@test "every entry has required field: validation" {
  missing=$(jq '[.[] | select(has("validation") | not)] | length' "$ROUND_HISTORY")
  [ "$missing" -eq 0 ]
}

@test "every entry has required field: outcome" {
  missing=$(jq '[.[] | select(has("outcome") | not)] | length' "$ROUND_HISTORY")
  [ "$missing" -eq 0 ]
}

@test "round field is a number in every entry" {
  bad=$(jq '[.[] | select((.round | type) != "number")] | length' "$ROUND_HISTORY")
  [ "$bad" -eq 0 ]
}

@test "timestamp field is a string in every entry" {
  bad=$(jq '[.[] | select((.timestamp | type) != "string")] | length' "$ROUND_HISTORY")
  [ "$bad" -eq 0 ]
}

@test "validation field is an object in every entry" {
  bad=$(jq '[.[] | select((.validation | type) != "object")] | length' "$ROUND_HISTORY")
  [ "$bad" -eq 0 ]
}

@test "outcome field is a string in every entry" {
  bad=$(jq '[.[] | select((.outcome | type) != "string")] | length' "$ROUND_HISTORY")
  [ "$bad" -eq 0 ]
}
