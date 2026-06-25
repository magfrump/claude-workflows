#!/usr/bin/env bats
# @category fast
# Validates the output format of api-consistency-reviewer reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/api-consistency-review.md bats test/skills/api-consistency-reviewer-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/api-consistency-review.md"
  count_findings
}

# --- Header section ---

@test "report has a title header" {
  assert_title_matches '^# .*API.*Consistency.*Review'
}

@test "report has a Scope field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Scope:\*\*'
}

@test "report has a Date field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Date:\*\*'
}

# --- Baseline Conventions ---

@test "report has Baseline Conventions section" {
  assert_section_exists "Baseline Conventions"
}

# --- Name-Pattern Audit (required per skill body) ---

@test "report has Name-Pattern Audit section" {
  assert_section_exists "Name-Pattern Audit"
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
  assert_field_values "Severity" "Breaking|Inconsistent|Minor|Informational"
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

@test "findings have Recommendation lines" {
  # Recommendations may appear as **Recommendation:** fields or ### Recommendation headings
  local rec_count
  rec_count=$(echo "$REPORT_CONTENT" | grep -ciE '^\*\*Recommendation:\*\*|^### Recommendation' || true)
  [ "$rec_count" -gt 0 ]
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
