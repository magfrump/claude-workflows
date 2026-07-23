#!/usr/bin/env bats
# @category fast
# Unit tests for the code-review gate helpers in scripts/lib/si-functions.sh:
#   parse_code_review_red     — extract the red-finding count from skill output
#   code_review_gate_verdict  — turn that count into a pass/fail verdict
#
# The gate itself (Gate 1h in self-improvement.sh) runs the code-review skill
# headless and asks it to emit a "CODE_REVIEW_RED: <n>" sentinel; these helpers
# parse it and decide the gate. Testing them in isolation mirrors the
# tap_new_failures coverage that backs Gate 1e (see test-baseline-gate.bats).
#
# Usage: bats test/code-review-gate.bats

load lib/hermetic-env

# These tests capture command substitution output; pin the locale so bash's
# setlocale warning can't leak into a captured value.
pin_hermetic_locale

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-functions.sh"
}

# ---------------------------------------------------------------
# parse_code_review_red
# ---------------------------------------------------------------

@test "parse_code_review_red extracts the count from a clean sentinel" {
  result=$(printf 'rubric...\nCODE_REVIEW_RED: 3\n' | parse_code_review_red)
  [ "$result" = "3" ]
}

@test "parse_code_review_red handles zero" {
  result=$(printf 'all green\nCODE_REVIEW_RED: 0\n' | parse_code_review_red)
  [ "$result" = "0" ]
}

@test "parse_code_review_red tolerates extra whitespace" {
  result=$(printf 'CODE_REVIEW_RED:    5\n' | parse_code_review_red)
  [ "$result" = "5" ]
}

@test "parse_code_review_red takes the LAST sentinel when several appear" {
  # A chatty run may echo the format twice; the final line is authoritative.
  result=$(printf 'CODE_REVIEW_RED: 9\nmore text\nCODE_REVIEW_RED: 1\n' | parse_code_review_red)
  [ "$result" = "1" ]
}

@test "parse_code_review_red emits nothing when no sentinel is present" {
  result=$(printf 'the model forgot the format line\n' | parse_code_review_red)
  [ -z "$result" ]
}

# ---------------------------------------------------------------
# code_review_gate_verdict
# ---------------------------------------------------------------

@test "code_review_gate_verdict passes on zero red findings" {
  run code_review_gate_verdict 0
  [ "$status" -eq 0 ]
}

@test "code_review_gate_verdict fails on one or more red findings" {
  run code_review_gate_verdict 1
  [ "$status" -ne 0 ]
  run code_review_gate_verdict 7
  [ "$status" -ne 0 ]
}

@test "code_review_gate_verdict fails closed on a non-integer count" {
  # A garbage count must not wave the task through — fail closed.
  run code_review_gate_verdict "oops"
  [ "$status" -ne 0 ]
  run code_review_gate_verdict ""
  [ "$status" -ne 0 ]
}
