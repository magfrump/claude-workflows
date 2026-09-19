#!/usr/bin/env bats
# @category fast
# Tests for the UserPromptSubmit batch-feedback routing reminder
# (hooks/batch-feedback-routing-reminder.sh).
#
# The hook must print its one reminder line for a prompt that lists 2+ items
# (numbered, bulleted, or an explicit "a few things" phrasing), stay silent on a
# single task, and never fail: malformed input is a silent exit 0.

HOOK="$BATS_TEST_DIRNAME/../../hooks/batch-feedback-routing-reminder.sh"

prompt_payload() {
  jq -n -c --arg p "$1" '{"prompt":$p}'
}

@test "two numbered items fire the reminder" {
  run bash "$HOOK" <<< "$(prompt_payload $'1. fix the export button\n2. add a CSV option')"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Routing reminder"* ]]
}

@test "two hyphen bullets fire the reminder" {
  run bash "$HOOK" <<< "$(prompt_payload $'- header overlaps on mobile\n- export is broken')"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Routing reminder"* ]]
}

@test "two • bullets fire the reminder even in the C locale" {
  # `[-*•]` as a bracket expression never matched '•' under LC_ALL=C, where it
  # is three separate bytes; this is the locale grep falls back to when the
  # inherited LC_ALL names a locale that is not installed.
  run env LC_ALL=C LANG=C bash "$HOOK" <<< "$(prompt_payload $'• header overlaps\n• export is broken')"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Routing reminder"* ]]
}

@test "an explicit multi-item phrasing fires the reminder" {
  run bash "$HOOK" <<< "$(prompt_payload 'A few things: the header, the export, and the footer.')"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Routing reminder"* ]]
}

@test "a single task stays silent" {
  run bash "$HOOK" <<< "$(prompt_payload 'Fix the login timeout bug.')"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Routing reminder"* ]]
}

@test "a single bullet stays silent" {
  run bash "$HOOK" <<< "$(prompt_payload $'- just this one thing')"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Routing reminder"* ]]
}

@test "malformed input and an empty prompt exit 0 silently" {
  run bash "$HOOK" <<< 'not json'
  [ "$status" -eq 0 ]
  [[ "$output" != *"Routing reminder"* ]]
  run bash "$HOOK" <<< '{}'
  [ "$status" -eq 0 ]
  [[ "$output" != *"Routing reminder"* ]]
}
