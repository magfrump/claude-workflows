#!/usr/bin/env bats
# Validates the output format of architecture-review reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/architecture-review.md bats test/skills/architecture-review-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/architecture-review.md"
  count_findings
}

# --- Header section ---

@test "report has a title header" {
  assert_title_matches '^# .*Architecture.*Review'
}

@test "report has a Scope field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Scope:\*\*'
}

@test "report has a Date field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Date:\*\*'
}

# --- Dependency Map ---

@test "report has Dependency Map section" {
  assert_section_exists "Dependency Map"
}

# --- Findings section ---

@test "report has Findings section" {
  assert_section_exists "Findings"
}

@test "report has at least one finding" {
  [ "$FINDING_COUNT" -gt 0 ]
}

@test "each finding has a Severity line" {
  assert_field_per_finding "Severity"
}

@test "severity values use only the allowed values" {
  assert_field_values "Severity" "Structural|Coupling|Minor|Informational"
}

@test "each finding has a Location line" {
  assert_field_per_finding "Location"
}

@test "each finding has a Move line" {
  assert_field_per_finding "Move"
}

@test "each finding has a Confidence line" {
  assert_field_per_finding "Confidence"
}

@test "confidence levels use only the allowed values" {
  assert_field_values "Confidence" "High|Medium|Low"
}

@test "each finding has a Recommendation line" {
  assert_field_per_finding "Recommendation"
}

# --- Ending sections ---

@test "report has What Looks Good section" {
  assert_section_exists "What Looks Good"
}

@test "report has Summary Table section" {
  assert_section_exists "Summary Table"
}

@test "report has Overall Assessment section" {
  assert_section_exists "Overall Assessment"
}

# --- No leakage from neighboring skills ---

@test "report does not contain fact-check verdict language" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Mostly accurate|Disputed|Inaccurate|Unverified)$'
}

@test "report does not use security-reviewer severity scale" {
  # Architecture findings use Structural/Coupling/Minor/Informational, NOT
  # security's Critical/High/Medium/Low. Any **Severity:** line whose value is
  # exactly "Critical" or "High" indicates leakage from security-reviewer.
  local bad
  bad=$(echo "${FINDINGS_BODY:-$REPORT_CONTENT}" | sed -n 's/^\*\*Severity:\*\* //p' | grep -iE '^(Critical|High)$' || true)
  [ -z "$bad" ]
}

@test "report does not use api-consistency Breaking/Inconsistent severities" {
  # Architecture findings should not borrow api-consistency-reviewer's severity vocabulary.
  local bad
  bad=$(echo "${FINDINGS_BODY:-$REPORT_CONTENT}" | sed -n 's/^\*\*Severity:\*\* //p' | grep -iE '^(Breaking|Inconsistent)$' || true)
  [ -z "$bad" ]
}
