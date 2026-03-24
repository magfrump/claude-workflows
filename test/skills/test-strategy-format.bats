#!/usr/bin/env bats
# Validates the output format of test-strategy reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/test-strategy-critique.md bats test/skills/test-strategy-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/test-strategy-critique.md"
}

# --- Header section ---

@test "report has a title header" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^# .*Test Strategy'
}

@test "report has a Reviewed or Date field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*(Reviewed|Date):\*\*'
}

@test "report has a Scope field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Scope:\*\*'
}

# --- Required sections ---

@test "report has a strengths section" {
  assert_heading_exists "(What.*Good|Strengths|Test Conventions)"
}

@test "report has a coverage gaps or recommended tests section" {
  assert_heading_exists "(Coverage Gaps|Recommended Tests)"
}

# --- Structural requirements ---

@test "report has at least 3 sections" {
  local section_count
  section_count=$(echo "$REPORT_CONTENT" | grep -cE '^## ' || true)
  [ "$section_count" -ge 3 ]
}

@test "report contains numbered items in at least one section" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*[0-9]+\.'
}

# --- Summary section ---

@test "report has a Summary or Overall section" {
  assert_heading_exists "(Summary|Overall)"
}

# --- No leakage ---

@test "report does not contain fact-check verdict language" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Mostly accurate|Disputed|Inaccurate|Unverified)$'
}
