#!/usr/bin/env bats
# Edge-case / negative-fixture tests for the code-fact-check skill.
# Verifies graceful handling of degenerate inputs: empty files, binary content,
# no-comments code, and extremely short code.
#
# These tests focus on structural properties of the output — not LLM reasoning.
# They complement the eval tests (code-fact-check-eval.bats) which check via
# eval_fixture / expected-verdicts.

load eval-helpers

SKILL="code-fact-check"

# --- Helpers ---

# Load a report for an edge-case fixture.
# Sets REPORT_CONTENT, CLAIM_COUNT, REPORT_PATH.
# Skips if the report hasn't been generated yet.
load_edge_report() {
  load_eval_report "$SKILL" "$1"
}

# Assert the report contains no ## Claim sections (no hallucinated claims).
assert_no_claim_sections() {
  local sections
  sections=$(echo "$REPORT_CONTENT" | grep -cE '^## Claim [0-9]+' || true)
  if [ "$sections" -gt 0 ]; then
    echo "Expected zero claim sections, found $sections"
    return 1
  fi
}

# Assert the report does not contain verdict fields (nothing to judge).
assert_no_verdicts() {
  local verdicts
  verdicts=$(echo "$REPORT_CONTENT" | grep -cE '^\*\*Verdict:\*\*' || true)
  if [ "$verdicts" -gt 0 ]; then
    echo "Expected no verdict fields, found $verdicts"
    return 1
  fi
}

# Assert the report does not use fact-check-only verdicts.
# Code-fact-check has its own verdict scale; fact-check verdicts should never appear.
assert_no_cross_skill_verdicts() {
  # Only relevant if the report has content
  [ -z "$REPORT_CONTENT" ] && return 0

  local bad
  bad=$(echo "$REPORT_CONTENT" | sed -n 's/^\*\*Verdict:\*\* //p' \
    | grep -iE '^(Accurate|Disputed|Inaccurate|Unverified)$' || true)
  if [ -n "$bad" ]; then
    echo "Report uses fact-check-only verdicts: $bad"
    return 1
  fi
}

# Assert the report indicates graceful handling — either an empty report
# or text acknowledging there's nothing to check / input cannot be processed.
assert_graceful_output() {
  # Empty report content is a valid graceful response (skill produced nothing).
  [ -z "$REPORT_CONTENT" ] && return 0

  # Non-empty report should contain a recognizable "nothing to check" indication.
  if echo "$REPORT_CONTENT" | grep -qiE \
    'no (checkable |verifiable )?claims|nothing to (check|verify)|cannot (process|analyze)|not (code|readable|parseable)|empty|no content|no comments|no docstrings|0 claims|zero claims|unable to (identify|find|extract)'; then
    return 0
  fi

  # Also accept a report with a total-claims header showing 0.
  if echo "$REPORT_CONTENT" | grep -qiE '(total claims|claims found|claims checked)[^0-9]*0'; then
    return 0
  fi

  echo "Report does not indicate graceful handling of degenerate input."
  echo "First 5 lines: $(echo "$REPORT_CONTENT" | head -5)"
  return 1
}

# --- tc-c8.1: Empty file ---

@test "tc-c8.1 empty: report has zero claims" {
  load_edge_report "tc-c8.1-empty.js"
  assert_max_claims 0
}

@test "tc-c8.1 empty: no hallucinated claim sections" {
  load_edge_report "tc-c8.1-empty.js"
  assert_no_claim_sections
}

@test "tc-c8.1 empty: no verdict fields present" {
  load_edge_report "tc-c8.1-empty.js"
  assert_no_verdicts
}

@test "tc-c8.1 empty: output indicates graceful handling" {
  load_edge_report "tc-c8.1-empty.js"
  assert_graceful_output
}

@test "tc-c8.1 empty: no critique language" {
  load_edge_report "tc-c8.1-empty.js"
  assert_no_critique
}

@test "tc-c8.1 empty: no cross-skill verdict leakage" {
  load_edge_report "tc-c8.1-empty.js"
  assert_no_cross_skill_verdicts
}

# --- tc-c8.2: No comments (uncommented code) ---

@test "tc-c8.2 no-comments: report has zero claims" {
  load_edge_report "tc-c8.2-no-comments.js"
  assert_max_claims 0
}

@test "tc-c8.2 no-comments: no hallucinated claim sections" {
  load_edge_report "tc-c8.2-no-comments.js"
  assert_no_claim_sections
}

@test "tc-c8.2 no-comments: no verdict fields present" {
  load_edge_report "tc-c8.2-no-comments.js"
  assert_no_verdicts
}

@test "tc-c8.2 no-comments: output indicates graceful handling" {
  load_edge_report "tc-c8.2-no-comments.js"
  assert_graceful_output
}

@test "tc-c8.2 no-comments: no critique language" {
  load_edge_report "tc-c8.2-no-comments.js"
  assert_no_critique
}

@test "tc-c8.2 no-comments: no cross-skill verdict leakage" {
  load_edge_report "tc-c8.2-no-comments.js"
  assert_no_cross_skill_verdicts
}

# --- tc-c8.3: Binary content ---

@test "tc-c8.3 binary: report has zero claims" {
  load_edge_report "tc-c8.3-binary-content.js"
  assert_max_claims 0
}

@test "tc-c8.3 binary: no hallucinated claim sections" {
  load_edge_report "tc-c8.3-binary-content.js"
  assert_no_claim_sections
}

@test "tc-c8.3 binary: no verdict fields present" {
  load_edge_report "tc-c8.3-binary-content.js"
  assert_no_verdicts
}

@test "tc-c8.3 binary: output indicates graceful handling" {
  load_edge_report "tc-c8.3-binary-content.js"
  assert_graceful_output
}

@test "tc-c8.3 binary: no critique language" {
  load_edge_report "tc-c8.3-binary-content.js"
  assert_no_critique
}

@test "tc-c8.3 binary: no cross-skill verdict leakage" {
  load_edge_report "tc-c8.3-binary-content.js"
  assert_no_cross_skill_verdicts
}

# --- tc-c8.4: Extremely short (single assignment) ---

@test "tc-c8.4 extremely-short: report has zero claims" {
  load_edge_report "tc-c8.4-extremely-short.js"
  assert_max_claims 0
}

@test "tc-c8.4 extremely-short: no hallucinated claim sections" {
  load_edge_report "tc-c8.4-extremely-short.js"
  assert_no_claim_sections
}

@test "tc-c8.4 extremely-short: no verdict fields present" {
  load_edge_report "tc-c8.4-extremely-short.js"
  assert_no_verdicts
}

@test "tc-c8.4 extremely-short: output indicates graceful handling" {
  load_edge_report "tc-c8.4-extremely-short.js"
  assert_graceful_output
}

@test "tc-c8.4 extremely-short: no critique language" {
  load_edge_report "tc-c8.4-extremely-short.js"
  assert_no_critique
}

@test "tc-c8.4 extremely-short: no cross-skill verdict leakage" {
  load_edge_report "tc-c8.4-extremely-short.js"
  assert_no_cross_skill_verdicts
}
