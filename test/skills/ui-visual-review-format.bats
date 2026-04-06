#!/usr/bin/env bats
# Validates the output format of ui-visual-review reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/ui-visual-review.md bats test/skills/ui-visual-review-format.bats

load helpers

setup() {
  load_generic_report "${REPORT_PATH:-docs/reviews/ui-visual-review.md}"
}

# --- Header section ---

@test "report has a title header with UI Visual Review" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^# UI Visual Review'
}

@test "report has a Summary section" {
  assert_section_exists "Summary"
}

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

# --- Severity sections ---

@test "report has at least one severity section" {
  echo "$REPORT_CONTENT" | grep -qiE '^## (Critical|Major|Minor) Issues'
}

# --- Findings format ---

@test "each issue has a Problem field" {
  local issues
  issues=$(echo "$REPORT_CONTENT" | grep -cE '^\*\*Problem:\*\*' || true)
  [ "$issues" -gt 0 ]
}

@test "each issue has a Fix field or code block" {
  # Issues should have either a **Fix:** field or a code block with the fix
  local fixes code_blocks total
  fixes=$(echo "$REPORT_CONTENT" | grep -cE '^\*\*Fix:\*\*' || true)
  code_blocks=$(echo "$REPORT_CONTENT" | grep -cE '^```' || true)
  total=$((fixes + code_blocks))
  [ "$total" -gt 0 ]
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

# --- No leakage from other skill types ---

@test "report does not contain fact-check verdicts" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Mostly accurate|Disputed|Inaccurate|Unverified)$'
}

@test "report does not contain security severity levels" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Severity:\*\* (Critical|High|Medium|Low|Informational)$'
}
