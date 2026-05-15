#!/usr/bin/env bats
# Validates the output format of what-if-analysis reports.
#
# Note: No example report is committed — tests will skip via load_generic_report
# if REPORT_PATH (or the default path) does not exist.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/what-if-analysis.md bats test/skills/what-if-analysis-format.bats

load helpers

setup() {
  load_generic_report "${REPORT_PATH:-docs/reviews/what-if-analysis.md}"
}

# --- Header section ---

@test "report has a title header with What-If Analysis" {
  assert_title_matches '^# .*What.?If Analysis' 10
}

@test "report has a Proposal field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Proposal:\*\*'
}

@test "report has a Date field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Date:\*\*'
}

@test "report has a Mode field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Mode:\*\*'
}

@test "Mode field uses an allowed value" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Mode:\*\*.*\b(Consequence|Pre-?mortem|Full)\b'
}

@test "report names upstream critiques used (or 'none')" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Upstream critiques:\*\*'
}

# --- Required sections (the cognitive moves) ---

@test "report has an Assumptions Examined section" {
  assert_heading_exists "Assumptions Examined"
}

@test "report has a Pre-Mortem Scenarios or Failure Modes section" {
  assert_heading_exists "(Pre-?Mortem Scenarios|Failure Modes)"
}

@test "report has a Consequence Chains section (second-order effects)" {
  assert_heading_exists "(Consequence Chains|Second-Order Effects)"
}

@test "report has a Coupling Analysis section (hidden couplings)" {
  assert_heading_exists "(Coupling Analysis|Hidden Couplings?)"
}

@test "report has a Confidence Inversions section" {
  assert_heading_exists "Confidence Inversions?"
}

@test "report has an Adversarial Scenarios section" {
  assert_heading_exists "Adversarial Scenarios?"
}

@test "report has a Reversibility Map section" {
  assert_heading_exists "Reversibility"
}

@test "report has a Cost of Success section" {
  assert_heading_exists "Cost of Success"
}

@test "report has a Findings Summary section" {
  assert_heading_exists "Findings Summary"
}

@test "report has a Recommendations section" {
  assert_heading_exists "(Recommendations|Overall Assessment)"
}

# --- Per-scenario fields (Pre-Mortem Scenarios) ---

@test "pre-mortem scenarios include Plausibility values" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Plausibility:\*\*.*\b(Likely|Plausible|Unlikely-but-catastrophic|Unlikely)\b'
}

@test "pre-mortem scenarios include Severity values" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Severity:\*\*.*\b(Low|Medium|High|Catastrophic)\b'
}

# --- Per-assumption fields ---

@test "assumptions include an If wrong field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*If wrong:\*\*.*\b(tweak|redesign|full retreat)\b'
}

# --- Findings tagging ---

@test "findings summary uses the prescribed tag taxonomy" {
  local summary
  summary=$(echo "$REPORT_CONTENT" | sed -n '/^### Findings Summary/,/^## /p')
  echo "$summary" | grep -qE '\[(UNEXAMINED ASSUMPTION|NOVEL FAILURE MODE|SECOND-ORDER EFFECT|HIDDEN COUPLING|REVERSIBILITY CLIFF|SUCCESS COST|PRIOR CONSIDERATION|NOVEL)\]'
}

# --- Recommendations structure ---

@test "recommendations distinguish blockers from acknowledged risks" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Recommendations/,/^## /p')
  # Fallback: section may run to end of file
  if [ -z "$section" ]; then
    section=$(echo "$REPORT_CONTENT" | sed -n '/^## Recommendations/,$p')
  fi
  echo "$section" | grep -qiE '(must address|worth mitigating|acknowledged risks?|no.*must address)'
}

# --- No leakage from sibling skills ---

@test "report does not contain fact-check verdict language" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Mostly accurate|Disputed|Inaccurate|Unverified)$'
}

@test "report does not contain cowen-critique Argument Decomposed framing" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^#+ .*Argument Decomposed'
}

@test "report does not contain yglesias-critique Goal vs Mechanism framing" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^#+ .*Goal vs\.? Mechanism'
}

@test "report does not contain matrix-analysis Comparison Matrix framing" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^## Comparison Matrix'
}

@test "report does not contain tech-debt-triage Carrying Cost framing" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^#+ .*Carrying Cost'
}

@test "report does not contain design-space-situating dimensions framing" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^#+ .*(Locus of Authority|Orientation in Time|Reversibility Dimension)'
}
