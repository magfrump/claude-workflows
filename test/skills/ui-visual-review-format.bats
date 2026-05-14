#!/usr/bin/env bats
# Validates the output format of ui-visual-review reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/ui-visual-review.md bats test/skills/ui-visual-review-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/ui-visual-review.md"
  count_findings
}

# --- Header section ---

@test "report has a title header with UI Visual Review" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^# .*UI Visual Review'
}

@test "report has a Scope field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Scope:\*\*'
}

@test "report has a Date field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Date:\*\*'
}

# --- Environment section ---

@test "report has an Environment section" {
  assert_section_exists "Environment"
}

@test "environment lists files reviewed" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Environment/,/^## /p' | head -n -1)
  echo "$section" | grep -qiE 'files reviewed'
}

@test "environment lists target viewports" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Environment/,/^## /p' | head -n -1)
  echo "$section" | grep -qiE 'viewport'
}

# --- Findings section ---

@test "report has at least one finding" {
  [ "$FINDING_COUNT" -gt 0 ]
}

@test "each finding has a Severity line" {
  assert_field_per_finding "Severity"
}

@test "severity values use only the allowed values" {
  assert_field_values "Severity" "Critical|Major|Minor|Informational"
}

@test "each finding has a Location line" {
  assert_field_per_finding "Location"
}

@test "each finding has an Issue type line" {
  assert_field_per_finding "Issue type"
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

# --- Best Practices table ---

@test "report has Best Practices Applied section" {
  assert_section_exists "Best Practices Applied"
}

@test "best practices section contains a table" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Best Practices Applied/,/^## /p' | head -n -1)
  echo "$section" | grep -qE '^\|.*\|'
}

# --- Viewport Verification Checklist ---

@test "report has Viewport Verification Checklist section" {
  assert_section_exists "Viewport Verification Checklist"
}

@test "viewport checklist has mobile entry" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Viewport Verification/,/^## /p')
  echo "$section" | grep -qiE '(mobile|360|320)'
}

@test "viewport checklist has desktop entry" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Viewport Verification/,/^## /p')
  echo "$section" | grep -qiE '(desktop|1920|1366)'
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

# --- No leakage from sibling code critics ---

@test "report does not contain fact-check verdicts" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Mostly accurate|Disputed|Inaccurate|Unverified)$'
}

@test "report does not contain security-style trust boundary map" {
  ! echo "$REPORT_CONTENT" | grep -qE '^## Trust Boundary Map'
}

@test "report does not contain performance-style data flow section" {
  ! echo "$REPORT_CONTENT" | grep -qE '^## Data Flow and Hot Paths'
}
