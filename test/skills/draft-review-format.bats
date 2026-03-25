#!/usr/bin/env bats
# Validates the output format of draft-review verification rubrics.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/verification-rubric.md bats test/skills/draft-review-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/verification-rubric.md"
}

# --- Header section ---

@test "report has a title header" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^# .*Verification Rubric'
}

@test "report has a Draft field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Draft:\*\*'
}

@test "report has a Checked date field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Checked:\*\*'
}

@test "report has a Status field with a known status value" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Status:.*(DOES NOT PASS|CONDITIONAL PASS|PASSES VERIFICATION)'
}

# --- Tiered sections ---

@test "report has Must Fix section" {
  echo "$REPORT_CONTENT" | grep -qiE '^## .*Must Fix'
}

@test "report has Must Address section" {
  echo "$REPORT_CONTENT" | grep -qiE '^## .*Must Address'
}

@test "report has Consider section" {
  echo "$REPORT_CONTENT" | grep -qiE '^## .*Consider'
}

@test "report has Verified section" {
  echo "$REPORT_CONTENT" | grep -qiE '^## .*Verified'
}

# --- Status line validity ---

@test "status uses one of the allowed values" {
  echo "$REPORT_CONTENT" | grep -qiE '(DOES NOT PASS|CONDITIONAL PASS|PASSES VERIFICATION)'
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

# --- No leakage ---

@test "report does not contain code review language" {
  ! echo "$REPORT_CONTENT" | grep -qiE '(should refactor|code smell|technical debt|PASSES REVIEW)'
}
