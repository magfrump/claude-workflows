#!/usr/bin/env bats
# @category fast
# Validates the output format of business-plan-critique-market-sizing reports.
#
# Note: No example report is committed — tests will skip via load_generic_report
# if REPORT_PATH (or the default path) does not exist.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/business-plan-critique-market-sizing.md \
#     bats test/skills/business-plan-critique-market-sizing-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/business-plan-critique-market-sizing.md"
}

# --- Title ---

@test "report has a title header with Market-Sizing identifier" {
  assert_title_matches '^# .*Market.?Sizing'
}

# --- Required per-lens sections (the five lenses) ---

@test "report has TAM Definition section" {
  assert_heading_exists "TAM Definition"
}

@test "report has SAM Realism section" {
  assert_heading_exists "SAM Realism"
}

@test "report has SOM Achievability section" {
  assert_heading_exists "SOM Achievability"
}

@test "report has Market Timing section" {
  assert_heading_exists "Market Timing"
}

@test "report has Comparable Benchmarks section" {
  assert_heading_exists "Comparable Benchmarks"
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
  # TAM, SAM, SOM, Market Timing, Comparable Benchmarks,
  # Factual Foundation, Overall Assessment.
  local section_count
  section_count=$(echo "$REPORT_CONTENT" | grep -cE '^## ' || true)
  [ "$section_count" -ge 7 ]
}

# --- Per-lens verdict and confidence fields ---

@test "report contains at least one Verdict field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Verdict:\*\*'
}

@test "report contains at least one Confidence field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Confidence:\*\*'
}

@test "Verdict values use the allowed vocabulary" {
  local verdicts bad
  verdicts=$(echo "$REPORT_CONTENT" | sed -n 's/^\*\*Verdict:\*\* //p')
  [ -n "$verdicts" ] || skip "no Verdict values found"
  bad=$(echo "$verdicts" | grep -viE '^(Defensible|Plausible|Inflated|Speculative|Not Claimed)$' || true)
  [ -z "$bad" ]
}

@test "Confidence values use the allowed vocabulary" {
  local confidences bad
  confidences=$(echo "$REPORT_CONTENT" | sed -n 's/^\*\*Confidence:\*\* //p')
  [ -n "$confidences" ] || skip "no Confidence values found"
  bad=$(echo "$confidences" | grep -viE '^(High|Medium|Low)$' || true)
  [ -z "$bad" ]
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

# --- No leakage from unit-economics sibling ---

@test "report does not contain unit-economics lens headings" {
  # Unit-economics sister skill owns these lenses; this critique must stay narrow.
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*CAC Assessment'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*LTV Assessment'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Contribution Margin Assessment'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Payback Period Assessment'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Gross.?Margin Trajectory'
}

# --- No leakage from cowen-critique ---

@test "report does not contain Cowen-specific analytical sections" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{2,3} .*Argument.*Decomposed'
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{2,3} .*Boring Explanation'
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{2,3} .*Survives the Inversion'
}

# --- No leakage from yglesias-critique ---

@test "report does not contain Yglesias-specific analytical sections" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{2,3} .*Goal vs\.?\s*(the )?Mechanism'
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{2,3} .*Boring Lever'
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{2,3} .*Follow the Money'
}

# --- No leakage from reviewer skills (severity/verdict scales) ---

@test "report does not contain severity/verdict scales from reviewer skills" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Severity:\*\* (Critical|High|Medium|Low|Informational)$'
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Verified|Incorrect|Stale)$'
}
