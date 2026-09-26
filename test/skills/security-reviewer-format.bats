#!/usr/bin/env bats
# @category fast
# @needs-reports security-reviewer
# Validates the output format of security-reviewer reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/security-review.md bats test/skills/security-reviewer-format.bats

load helpers

setup() {
  resolve_skill_report security-reviewer tc-sec4-fail-open-auth.go
  load_generic_report "$REPORT_PATH"
  count_findings
}

# --- Header section ---

@test "report has a title header" {
  assert_title_matches '^# .*Security.*Review'
}

@test "report has a Scope field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Scope:\*\*'
}

@test "report has a Date field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Date:\*\*'
}

# --- Trust Boundary Map ---

@test "report has Trust Boundary Map section" {
  assert_section_exists "Trust Boundary Map"
}

# --- Findings section ---

@test "report has Findings section" {
  assert_section_exists "Findings"
}

@test "report has at least one finding or states none" {
  assert_findings_or_none_stated
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

@test "each finding has a Boundary line" {
  # SKILL.md anchoring rule: every finding cross-references a Trust Boundary
  # Map label (e.g., B1) or uses "Internal — no boundary" with justification.
  assert_field_per_finding "Boundary"
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

@test "report has Endorsement Claims section" {
  # SKILL.md replaced free-form "What Looks Good" praise with atomic, falsifiable
  # Endorsement Claims and no longer offers the old heading, so it no longer counts.
  assert_section_exists "Endorsement Claims"
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
