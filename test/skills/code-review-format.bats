#!/usr/bin/env bats
# Validates the output format of code-review rubrics.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/code-review-rubric.md bats test/skills/code-review-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/code-review-rubric.md"
}

# --- Header section ---

@test "report has a title header" {
  assert_title_matches '^# Code Review Rubric'
}

@test "report has a Scope field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Scope:\*\*'
}

@test "report has a Reviewed date field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Reviewed:\*\*'
}

@test "report has a Status field with a known status value" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Status:.*(DOES NOT PASS|CONDITIONAL PASS|PASSES REVIEW)'
}

# --- Tiered sections ---

@test "report has Must Fix section" {
  echo "$REPORT_CONTENT" | grep -qiE '^## .*Must Fix'
}

@test "report has Must Address section" {
  echo "$REPORT_CONTENT" | grep -qiE '^## .*Must Address'
}

@test "report has Consider section" {
  # Match "Consider" as a whole word so it does not also match "Considered Overrides".
  echo "$REPORT_CONTENT" | grep -qiE '^## .*\bConsider\b'
}

@test "report has Confirmed Good section" {
  echo "$REPORT_CONTENT" | grep -qiE '^## .*Confirmed Good'
}

# --- Auditability sections (override log + critic gating) ---

@test "report has Considered Overrides section" {
  echo "$REPORT_CONTENT" | grep -qiE '^## .*Considered Overrides'
}

@test "report has Skipped Core Critics section" {
  echo "$REPORT_CONTENT" | grep -qiE '^## .*Skipped Core Critics'
}

# --- Status line validity ---

@test "status uses one of the allowed values" {
  echo "$REPORT_CONTENT" | grep -qiE '(DOES NOT PASS|CONDITIONAL PASS|PASSES REVIEW)'
}

@test "status line carries an emoji indicator" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Status:.*(🔴|🟡|✅)'
}

# --- Table structure ---

@test "Must Fix section contains a table or (None)" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## .*Must Fix/,/^## /p' | head -n -1)
  echo "$section" | grep -qE '(\|.*\||\(None\))'
}

@test "Must Address section contains a table or (None)" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## .*Must Address/,/^## /p' | head -n -1)
  echo "$section" | grep -qE '(\|.*\||\(None\))'
}

@test "Considered Overrides section contains a table or the empty-state sentinel" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## .*Considered Overrides/,/^## /p' | head -n -1)
  echo "$section" | grep -qE '(\|.*\||No prior overrides matched this diff\.)'
}

@test "Skipped Core Critics section contains a table or the empty-state sentinel" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## .*Skipped Core Critics/,/^## /p' | head -n -1)
  echo "$section" | grep -qE '(\|.*\||All core critics ran; no skips applied\.)'
}

# --- No leakage from draft-review ---

@test "report does not contain draft-review verdict vocabulary" {
  # draft-review uses "PASSES VERIFICATION"; code-review uses "PASSES REVIEW".
  # Also reject "Draft Verification Rubric" / "Checked:" header fields that
  # belong to draft-review's rubric.
  ! echo "$REPORT_CONTENT" | grep -qiE '(PASSES VERIFICATION|Draft Verification Rubric|^\*\*Checked:\*\*|^\*\*Draft:\*\*)'
}
