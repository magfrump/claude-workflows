#!/usr/bin/env bats
# @category fast
# @needs-reports fact-check
# Edge-case / negative-fixture tests for the fact-check skill.
# Verifies graceful handling of degenerate inputs: empty files, binary content,
# no-claims input, and extremely short input.
#
# These tests focus on structural properties of the output — not LLM reasoning.
# They complement the eval tests (fact-check-eval.bats) which check via
# eval_fixture / expected-verdicts.

load eval-helpers

SKILL="fact-check"

# --- Helpers ---

# Load a report for an edge-case fixture.
# Sets REPORT_CONTENT, CLAIM_COUNT, REPORT_PATH.
# Skips if the report hasn't been generated yet (scripts/run-tests.sh drops this
# suite, like *-format/*-eval, when no generated reports exist at all).
# Fails when generate-reports.bash left <fixture>.failed: every assertion below
# is absence-only (no claims, no verdicts, no critique), so a dead run's empty
# or junk report would otherwise pass all of them — the same fail-closed rule
# eval_fixture applies.
load_edge_report() {
  load_eval_report "$SKILL" "$1"
  local failed_marker="${REPORT_PATH%.report.md}.failed"
  if [ -f "$failed_marker" ]; then
    echo "Generation failed for $1: $(cat "$failed_marker")" >&2
    return 1
  fi
}

# Assert the report contains no verdict sections (no hallucinated claims).
# fact-check heads each verdict '## Verdict for C<N>:' (skills/fact-check/SKILL.md).
assert_no_claim_sections() {
  local sections
  sections=$(echo "$REPORT_CONTENT" | grep -cE "$(claim_heading_re "$SKILL")" || true)
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

# Assert the report indicates graceful handling: text acknowledging there's
# nothing to check / input cannot be processed. A blank report does not count —
# the generate-reports.bash runner prompt never permits a zero-byte report (the
# SKILL.md allows one only "when the orchestrator allows it"), and a blank
# report is also what a failed or truncated run leaves behind.
assert_graceful_output() {
  if [ -z "${REPORT_CONTENT//[[:space:]]/}" ]; then
    echo "Report is blank: no acknowledgement that there was nothing to check."
    return 1
  fi

  # Non-empty report should contain a recognizable "nothing to check" indication.
  # We look for a broad set of phrases an LLM might use.
  if echo "$REPORT_CONTENT" | grep -qiE \
    'no (checkable |factual |verifiable )?claims|nothing to (check|verify|fact.check)|cannot (process|analyze|fact.check)|not (prose|text|readable)|empty|no content|0 claims|zero claims|unable to (identify|find|extract)'; then
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

# --- tc-7.1: Empty file ---

@test "tc-7.1 empty: report has zero claims" {
  load_edge_report "tc-7.1-empty.md"
  assert_max_claims 0
}

@test "tc-7.1 empty: no hallucinated claim sections" {
  load_edge_report "tc-7.1-empty.md"
  assert_no_claim_sections
}

@test "tc-7.1 empty: no verdict fields present" {
  load_edge_report "tc-7.1-empty.md"
  assert_no_verdicts
}

@test "tc-7.1 empty: output indicates graceful handling" {
  load_edge_report "tc-7.1-empty.md"
  assert_graceful_output
}

@test "tc-7.1 empty: no critique language" {
  load_edge_report "tc-7.1-empty.md"
  assert_no_critique
}

# --- tc-7.2: No checkable claims (meeting notes) ---

@test "tc-7.2 no-claims: report has zero claims" {
  load_edge_report "tc-7.2-no-claims.md"
  assert_max_claims 0
}

@test "tc-7.2 no-claims: no hallucinated claim sections" {
  load_edge_report "tc-7.2-no-claims.md"
  assert_no_claim_sections
}

@test "tc-7.2 no-claims: no verdict fields present" {
  load_edge_report "tc-7.2-no-claims.md"
  assert_no_verdicts
}

@test "tc-7.2 no-claims: output indicates graceful handling" {
  load_edge_report "tc-7.2-no-claims.md"
  assert_graceful_output
}

@test "tc-7.2 no-claims: no critique language" {
  load_edge_report "tc-7.2-no-claims.md"
  assert_no_critique
}

# --- tc-7.3: Binary content ---

@test "tc-7.3 binary: report has zero claims" {
  load_edge_report "tc-7.3-binary-content.md"
  assert_max_claims 0
}

@test "tc-7.3 binary: no hallucinated claim sections" {
  load_edge_report "tc-7.3-binary-content.md"
  assert_no_claim_sections
}

@test "tc-7.3 binary: no verdict fields present" {
  load_edge_report "tc-7.3-binary-content.md"
  assert_no_verdicts
}

@test "tc-7.3 binary: output indicates graceful handling" {
  load_edge_report "tc-7.3-binary-content.md"
  assert_graceful_output
}

@test "tc-7.3 binary: no critique language" {
  load_edge_report "tc-7.3-binary-content.md"
  assert_no_critique
}

# --- tc-7.4: Extremely short (vague one-liner) ---

@test "tc-7.4 extremely-short: report has zero claims" {
  load_edge_report "tc-7.4-extremely-short.md"
  assert_max_claims 0
}

@test "tc-7.4 extremely-short: no hallucinated claim sections" {
  load_edge_report "tc-7.4-extremely-short.md"
  assert_no_claim_sections
}

@test "tc-7.4 extremely-short: no verdict fields present" {
  load_edge_report "tc-7.4-extremely-short.md"
  assert_no_verdicts
}

@test "tc-7.4 extremely-short: output indicates graceful handling" {
  load_edge_report "tc-7.4-extremely-short.md"
  assert_graceful_output
}

@test "tc-7.4 extremely-short: no critique language" {
  load_edge_report "tc-7.4-extremely-short.md"
  assert_no_critique
}
