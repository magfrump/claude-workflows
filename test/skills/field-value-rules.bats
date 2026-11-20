#!/usr/bin/env bats
# @category fast
# The shared rules for reading a report's vocabulary fields and titles, tested
# on small inline reports so they hold without generated reports:
#   - field_values_off_vocab (helpers.bash): the value must lead the field, and
#     a trailing annotation may follow a space, comma, parenthesis, emphasis
#     marker or full stop ("Medium. It is recoverable" is Medium), while a value
#     glued to letters or a hyphen ("Medium-High") or preceded by text fails;
#   - field_values (eval-helpers.bash): a bold-wrapped value ("**Upgrade now.**")
#     reads as the word it wraps, for field_match and no_field alike;
#   - dependency-upgrade's effort field takes a singular unit ("About an hour");
#   - matrix-analysis's title check finds the matrix document after a chat
#     synthesis, and fails when the document's title is missing.
# Origin: docs/working/research-2026-11-20-skill-format-fields-preambles.md.

load helpers
load eval-helpers

bats_require_minimum_version 1.5.0

setup() {
  TEST_TMPDIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# --- field_values_off_vocab ---

@test "a value followed by a full stop and a sentence is from the vocabulary" {
  run field_values_off_vocab 'Low|Medium|High' <<< 'Medium. It is recoverable, but late.'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "a bare value, a parenthesised gloss and a comma annotation all pass" {
  run field_values_off_vocab 'Low|Medium|High' <<< $'High\nLow (cosmetic)\nMedium, given narrative 1\nLow.'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "a value glued to a hyphen (Medium-High) is off the vocabulary" {
  run field_values_off_vocab 'Low|Medium|High' <<< 'Medium-High (strong mechanism)'
  [ "$status" -eq 0 ]
  [ "$output" = 'Medium-High (strong mechanism)' ]
}

@test "a spaced hedge passes: the rule reads only the leading word" {
  run field_values_off_vocab 'Low|Medium|High' <<< 'Medium to High.'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "text before the value is off the vocabulary" {
  run field_values_off_vocab 'Low|Medium|High' <<< 'Probably High'
  [ "$status" -eq 0 ]
  [ "$output" = 'Probably High' ]
}

@test "a value glued to more letters is off the vocabulary" {
  run field_values_off_vocab 'Low|Medium|High' <<< 'Lowish.'
  [ "$status" -eq 0 ]
  [ "$output" = 'Lowish.' ]
}

@test "assert_field_values fails on a hedge and passes on value-dot-sentence" {
  # assert_field_values reads FINDINGS_BODY first; leave it and CLAIMS_BODY empty.
  FINDINGS_BODY="" CLAIMS_BODY=""
  REPORT_CONTENT=$'**Confidence:** Low. This only matters if the endpoint is narrow.\n**Confidence:** High'
  run assert_field_values Confidence 'High|Medium|Low'
  [ "$status" -eq 0 ]
  REPORT_CONTENT=$'**Confidence:** Medium-High'
  run assert_field_values Confidence 'High|Medium|Low'
  [ "$status" -ne 0 ]
  REPORT_CONTENT=$'**Confidence:** **High**'
  run assert_field_values Confidence 'High|Medium|Low'
  [ "$status" -eq 0 ]
}

# --- field_values: emphasis-wrapped values ---

@test "field_match reads a bold-wrapped value as the word it wraps" {
  REPORT_CONTENT=$'### Summary\n**Recommendation:** **Upgrade now.** Ship it with the handler change.'
  run assert_field Recommendation 'Upgrade now'
  [ "$status" -eq 0 ]
}

@test "no_field still catches a bold-wrapped forbidden value" {
  REPORT_CONTENT=$'**Recommendation:** *Don\'t upgrade*'
  run assert_no_field Recommendation "Don.t upgrade"
  [ "$status" -ne 0 ]
}

@test "field_match still fails when the vocabulary word is missing" {
  REPORT_CONTENT=$'**Recommendation:** Don\'t merge this PR this week.'
  run assert_field Recommendation "Defer|Don.t upgrade"
  [ "$status" -ne 0 ]
}

# --- the two format suites whose checks changed ---

# run_suite <suite> <report text> <filter>: run the format suite's tests whose
# names match <filter> against a report file holding <report text>.
run_suite() {
  [ -n "${3:-}" ] || return 2
  printf '%s\n' "$2" > "$TEST_TMPDIR/report.md"
  REPORT_PATH="$TEST_TMPDIR/report.md" run bats --tap -f "$3" "$BATS_TEST_DIRNAME/$1"
}

@test "dependency-upgrade's effort check takes a singular unit" {
  run_suite dependency-upgrade-format.bats $'### Summary\n**Estimated effort:** About an hour, with the test.' 'Estimated effort'
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok 1 summary has Estimated effort field"* ]]
  run_suite dependency-upgrade-format.bats $'### Summary\n**Estimated effort:** Small.' 'Estimated effort'
  [ "$status" -ne 0 ]
}

@test "dependency-upgrade's Recommendation must hold its value alone" {
  run_suite dependency-upgrade-format.bats $'### Summary\n**Recommendation:** Defer.' 'value alone'
  [ "$status" -eq 0 ]
  run_suite dependency-upgrade-format.bats $'### Summary\n**Recommendation:** Don\'t merge this PR this week.' 'value alone'
  [ "$status" -ne 0 ]
  run_suite dependency-upgrade-format.bats $'### Summary\n**Recommendation:** Upgrade soon. No code changes needed.' 'value alone'
  [ "$status" -ne 0 ]
}

@test "matrix-analysis's title check finds the document after the chat synthesis" {
  local report
  report=$'Stage 2 (evaluation) complete: 3/3 returned \xe2\x80\x94 synthesizing.\n\n# Folio vs Kestrel\n\nChoose Folio.\n\n# Matrix Analysis\n\n**Items:** Folio, Kestrel | **Criteria:** 3 | **Date:** 2026-11-20'
  run_suite matrix-analysis-format.bats "$report" 'title header'
  [ "$status" -eq 0 ]
}

@test "matrix-analysis's title check fails without the document's title" {
  run_suite matrix-analysis-format.bats $'# Folio vs Kestrel\n\n**Items:** Folio, Kestrel\n\nChoose Folio.' 'title header'
  [ "$status" -ne 0 ]
  [[ "$output" == *"no '# Matrix Analysis' title followed by an **Items:** line"* ]]
}

@test "matrix-analysis's title check fails when the title has no Items line after it" {
  run_suite matrix-analysis-format.bats $'# Matrix Analysis\n\nprose\nprose\nprose\nprose\n\n**Items:** Folio' 'title header'
  [ "$status" -ne 0 ]
}
