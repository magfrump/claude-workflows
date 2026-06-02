#!/usr/bin/env bash
# Manual verification for hooks/dd-routing-reminder.sh (RPI step 3 / Test spec).
# Run from repo root: bash docs/working/verify-dd-routing-reminder.sh
# Asserts: match phrasings emit one reminder, ordinary prompts emit nothing,
# malformed/empty input is silent, and every case exits 0 (never blocks).
set -u
H="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/hooks/dd-routing-reminder.sh"
fails=0

check() {
  local label="$1" payload="$2" expect="$3" out rc got status
  out=$(printf '%s' "$payload" | bash "$H")
  rc=$?
  got="empty"; [[ -n "$out" ]] && got="reminder"
  status="OK"
  if [[ "$got" != "$expect" || "$rc" != "0" ]]; then status="FAIL"; fails=$((fails+1)); fi
  printf '%-7s exit=%s %-8s (want %-8s) | %s\n' "$status" "$rc" "$got" "$expect" "$label"
}

echo "--- MATCH cases (want reminder) ---"
check "should we use...or" '{"prompt":"Should we use Postgres or DynamoDB?"}' reminder
check "compare options"    '{"prompt":"compare these options for caching"}'  reminder
check "which approach"     '{"prompt":"which approach is better here"}'       reminder
check "X vs Y"             '{"prompt":"Postgres vs DynamoDB"}'                reminder
check "versus"             '{"prompt":"React versus Vue for this"}'          reminder

echo "--- NO-MATCH cases (want empty) ---"
check "poem"               '{"prompt":"write me a poem about the ocean"}'    empty
check "architecture alone" '{"prompt":"explain this architecture"}'          empty
check "tradeoff alone"     '{"prompt":"there is a tradeoff here"}'           empty
check "plain build"        '{"prompt":"add a CSV export button to reports"}' empty

echo "--- ROBUSTNESS (want empty, exit 0) ---"
check "empty prompt"       '{"prompt":""}'  empty
check "missing prompt"     '{"foo":"bar"}'  empty
check "malformed json"     'not json'       empty

echo "---"
if [[ "$fails" -eq 0 ]]; then echo "ALL PASS"; else echo "$fails FAILED"; exit 1; fi
