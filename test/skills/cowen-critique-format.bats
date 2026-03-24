#!/usr/bin/env bats
# Validates the output format of cowen-critique reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/cowen-critique.md bats test/skills/cowen-critique-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/cowen-critique.md"
}

# --- Title ---

@test "report has a title header with Cowen identifier" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^# .*Cowen.*Critique'
}

# --- Required analytical sections (cognitive moves) ---

@test "report has The Argument Decomposed section" {
  assert_heading_exists "Argument.*Decomposed"
}

@test "report has What Survives the Inversion section" {
  assert_heading_exists "Survives the Inversion"
}

@test "report has Factual Foundation section" {
  assert_heading_exists "Factual Foundation"
}

@test "report has The Boring Explanation section" {
  assert_heading_exists "Boring Explanation"
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

@test "report does not contain policy feasibility language from yglesias" {
  # Cowen critiques focus on intellectual rigor, not policy mechanism
  ! echo "$REPORT_CONTENT" | grep -qiE '^## The Goal vs\. the Mechanism'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## The Org Chart'
}
