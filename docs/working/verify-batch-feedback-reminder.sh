#!/usr/bin/env bash
# Manual verification for hooks/batch-feedback-routing-reminder.sh.
# Run from repo root: bash docs/working/verify-batch-feedback-reminder.sh
# Asserts: multi-item batches emit one reminder, single tasks emit nothing,
# malformed/empty input is silent, and every case exits 0 (never blocks).
set -u
H="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/hooks/batch-feedback-routing-reminder.sh"
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
check "numbered list"      '{"prompt":"Feedback:\n1. export button broken\n2. header overlaps on mobile\n3. add CSV"}' reminder
check "bullet list"        '{"prompt":"- fix the login timeout\n- the avatar is blurry"}'           reminder
check "a few things"       '{"prompt":"A few things: the modal is broken and the footer is misaligned"}' reminder
check "three bugs"         '{"prompt":"I have three bugs for you to look at today"}'                 reminder
check "the following"      '{"prompt":"Please address the following issues from testing"}'           reminder
check "batch of feedback"  '{"prompt":"Got a batch of feedback from the user test"}'                 reminder
check "couple of bugs"     '{"prompt":"a couple of bugs cropped up in review"}'                      reminder

echo "--- NO-MATCH cases (want empty) ---"
check "single bug"         '{"prompt":"the export button is broken, please fix it"}'                 empty
check "single feature"     '{"prompt":"add a CSV export button to the reports page"}'                empty
check "one numbered step"  '{"prompt":"Step 1. open the file and read it"}'                          empty
check "prose w/ number"    '{"prompt":"there are 3 users affected by this single login bug"}'        empty
check "explain question"   '{"prompt":"why is latency spiking only on tuesdays"}'                    empty

echo "--- ROBUSTNESS (want empty, exit 0) ---"
check "empty prompt"       '{"prompt":""}'  empty
check "missing prompt"     '{"foo":"bar"}'  empty
check "malformed json"     'not json'       empty

echo "---"
if [[ "$fails" -eq 0 ]]; then echo "ALL PASS"; else echo "$fails FAILED"; exit 1; fi
