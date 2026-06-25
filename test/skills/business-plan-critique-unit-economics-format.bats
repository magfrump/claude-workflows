#!/usr/bin/env bats
# @category fast
# Validates the output format of business-plan-critique-unit-economics reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/business-plan-critique-unit-economics.md \
#     bats test/skills/business-plan-critique-unit-economics-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/business-plan-critique-unit-economics.md"
}

# --- Title ---

@test "report has a title header identifying it as a unit-economics critique" {
  assert_title_matches '^# .*Unit.?Economics.*Critique'
}

# --- Required per-lens sections ---

@test "report has CAC Assessment section" {
  assert_heading_exists "CAC Assessment"
}

@test "report has LTV Assessment section" {
  assert_heading_exists "LTV Assessment"
}

@test "report has Contribution Margin Assessment section" {
  assert_heading_exists "Contribution Margin Assessment"
}

@test "report has Payback Period Assessment section" {
  assert_heading_exists "Payback Period Assessment"
}

@test "report has Gross-Margin Trajectory Assessment section" {
  assert_heading_exists "Gross.?Margin Trajectory Assessment"
}

# --- Required supporting sections ---

@test "report has Factual Foundation section" {
  assert_heading_exists "Factual Foundation"
}

@test "report has Overall Assessment section" {
  assert_section_exists "Overall Assessment"
}

# --- Structural requirements ---

@test "report has at least 7 top-level sections" {
  # CAC, LTV, Contribution Margin, Payback, Gross-Margin Trajectory,
  # Factual Foundation, Overall Assessment.
  local section_count
  section_count=$(echo "$REPORT_CONTENT" | grep -cE '^## ' || true)
  [ "$section_count" -ge 7 ]
}

# --- No leakage from moat-critique sibling ---

@test "report does not contain moat-critique section headings" {
  # Moat sister skill owns these lenses; this critique must stay narrow.
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Moat Type Assessment'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Distribution Channel Assessment'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Switching Cost Assessment'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Network Effect Assessment'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Competitive Response Assessment'
}

# --- No leakage from cowen-critique ---

@test "report does not contain Cowen-specific analytical sections" {
  # Cowen critiques focus on intellectual rigor, not unit-economics math.
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{2,3} .*Argument.*Decomposed'
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{2,3} .*Boring Explanation'
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{2,3} .*Survives the Inversion'
}

# --- No leakage from yglesias-critique ---

@test "report does not contain Yglesias-specific analytical sections" {
  # Yglesias critiques focus on policy mechanism, not per-customer math.
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{2,3} .*Goal vs\.?\s*(the )?Mechanism'
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{2,3} .*Boring Lever'
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{2,3} .*Follow the Money'
}

# --- No leakage from reviewer skills (severity/verdict scales) ---

@test "report does not contain severity/verdict scales from reviewer skills" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Severity:\*\* (Critical|High|Medium|Low|Informational)$'
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Verified|Incorrect|Stale)$'
}
