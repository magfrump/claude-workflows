#!/usr/bin/env bats
# Validates the output format of yglesias-critique reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/yglesias-critique.md bats test/skills/yglesias-critique-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/yglesias-critique.md"
}

# --- Title ---

@test "report has a title header with Yglesias identifier" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^# .*Yglesias.*Critique'
}

# --- Required analytical sections (cognitive moves) ---

@test "report has The Goal vs the Mechanism section" {
  assert_heading_exists "Goal vs.*Mechanism"
}

@test "report has The Boring Lever section" {
  assert_heading_exists "Boring Lever"
}

@test "report has Follow the Money section" {
  assert_heading_exists "Follow the Money"
}

@test "report has Factual Foundation section" {
  assert_heading_exists "Factual Foundation"
}

@test "report has Overall Assessment section" {
  assert_section_exists "Overall Assessment"
}

# --- Structural requirements ---

@test "report has at least 5 sections" {
  local section_count
  section_count=$(echo "$REPORT_CONTENT" | grep -cE '^## ' || true)
  [ "$section_count" -ge 5 ]
}

# --- No leakage ---

@test "report does not contain severity/verdict scales from reviewer skills" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Severity:\*\* (Critical|High|Medium|Low|Informational)$'
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Verified|Incorrect|Stale)$'
}

@test "report does not contain Cowen-specific analytical sections" {
  # Yglesias critiques focus on policy mechanism, not intellectual stress-testing
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Survives the Inversion'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Boring Explanation'
}
