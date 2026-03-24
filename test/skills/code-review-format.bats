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
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^# Code Review Rubric'
}

@test "report has a Scope field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Scope:\*\*'
}

@test "report has a Reviewed date field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Reviewed:\*\*'
}

@test "report has a Status field with emoji indicator" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Status:.*[🔴🟡✅]'
}

# --- Tiered sections ---

@test "report has Must Fix section" {
  echo "$REPORT_CONTENT" | grep -qE '^## 🔴 Must Fix'
}

@test "report has Must Address section" {
  echo "$REPORT_CONTENT" | grep -qE '^## 🟡 Must Address'
}

@test "report has Consider section" {
  echo "$REPORT_CONTENT" | grep -qE '^## 🟢 Consider'
}

@test "report has Confirmed Good section" {
  echo "$REPORT_CONTENT" | grep -qiE '^## .*[✅].*Confirmed Good'
}

# --- Status line validity ---

@test "status uses one of the allowed values" {
  echo "$REPORT_CONTENT" | grep -qiE '(DOES NOT PASS|CONDITIONAL PASS|PASSES REVIEW)'
}

# --- Table structure ---

@test "Must Fix section contains a table or (None)" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## 🔴 Must Fix/,/^## /p' | head -n -1)
  echo "$section" | grep -qE '(\|.*\||\(None\))'
}

@test "Must Address section contains a table or (None)" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## 🟡 Must Address/,/^## /p' | head -n -1)
  echo "$section" | grep -qE '(\|.*\||\(None\))'
}

# --- No leakage ---

@test "report does not contain draft-review language" {
  ! echo "$REPORT_CONTENT" | grep -qiE 'PASSES VERIFICATION'
}
