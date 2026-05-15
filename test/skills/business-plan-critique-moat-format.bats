#!/usr/bin/env bats
# Validates the output format of business-plan-critique-moat reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/business-plan-critique-moat.md \
#     bats test/skills/business-plan-critique-moat-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/business-plan-critique-moat.md"
}

# --- Title ---

@test "report has a title header with Moat identifier" {
  assert_title_matches '^# .*Moat'
}

# --- Required analytical sections (the five lenses) ---

@test "report has Moat Type Assessment section" {
  assert_heading_exists "Moat Type"
}

@test "report has Distribution Channel Assessment section" {
  assert_heading_exists "Distribution Channel"
}

@test "report has Switching Cost Assessment section" {
  assert_heading_exists "Switching Cost"
}

@test "report has Network Effect Assessment section" {
  assert_heading_exists "Network Effect"
}

@test "report has Competitive Response Assessment section" {
  assert_heading_exists "Competitive Response"
}

@test "report has Factual Foundation section" {
  assert_heading_exists "Factual Foundation"
}

@test "report has Overall Assessment section" {
  assert_section_exists "Overall Assessment"
}

# --- Structural requirements ---

@test "report has at least 6 sections" {
  local section_count
  section_count=$(echo "$REPORT_CONTENT" | grep -cE '^## ' || true)
  [ "$section_count" -ge 6 ]
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
  bad=$(echo "$verdicts" | grep -viE '^(Durable|Plausible|Weak|Absent|Not Claimed)$' || true)
  [ -z "$bad" ]
}

@test "Confidence values use the allowed vocabulary" {
  local confidences bad
  confidences=$(echo "$REPORT_CONTENT" | sed -n 's/^\*\*Confidence:\*\* //p')
  [ -n "$confidences" ] || skip "no Confidence values found"
  bad=$(echo "$confidences" | grep -viE '^(High|Medium|Low)$' || true)
  [ -z "$bad" ]
}

# --- No leakage from sister unit-economics skill ---

@test "report does not contain unit-economics lens headings" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{2,4} .*(CAC Assessment|LTV Assessment|Contribution Margin Assessment|Payback Period Assessment|Gross-Margin Trajectory)'
}

@test "report does not lean on CAC/LTV/payback/margin terminology as primary lenses" {
  # A passing mention is fine; the skill must not be using the unit-economics
  # vocabulary as its primary analytical frame. Block the obvious phrases that
  # would indicate scope creep into the sister skill.
  ! echo "$REPORT_CONTENT" | grep -qiE '\bLTV/CAC ratio\b'
  ! echo "$REPORT_CONTENT" | grep -qiE '\bcontribution margin per customer\b'
  ! echo "$REPORT_CONTENT" | grep -qiE '\bpayback period\b.*\bmonths\b.*\bbenchmark\b'
}

# --- No leakage from neighboring critique skills ---

@test "report does not contain Cowen-specific analytical sections" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Argument Decomposed'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Survives the Inversion'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Boring Explanation'
}

@test "report does not contain Yglesias-specific analytical sections" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Goal vs.*Mechanism'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Boring Lever'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Follow the Money'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Org Chart'
}

# --- No leakage from reviewer skills ---

@test "report does not contain code-reviewer severity scales" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Severity:\*\* (Critical|High|Medium|Low|Informational)$'
}
