#!/usr/bin/env bats
# Validates the output format of performance-reviewer reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/performance-review.md bats test/skills/performance-reviewer-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/performance-review.md"
  count_findings
}

# --- Header section ---

@test "report has a title header" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^# .*Performance.*Review'
}

@test "report has a Scope field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Scope:\*\*'
}

@test "report has a Date field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Date:\*\*'
}

# --- Data Flow and Hot Paths ---

@test "report has Data Flow and Hot Paths section" {
  assert_section_exists "Data Flow and Hot Paths"
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
  assert_field_values "Severity" "Critical|High|Medium|Low|Informational"
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

# --- No leakage ---

@test "report does not contain fact-check language" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Mostly accurate|Disputed|Inaccurate|Unverified)$'
}
