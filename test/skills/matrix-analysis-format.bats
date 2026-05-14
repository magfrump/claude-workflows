#!/usr/bin/env bats
# Validates the output format of matrix-analysis reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/matrix-analysis.md bats test/skills/matrix-analysis-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/matrix-analysis.md"
}

# --- Header section ---

@test "report has a title header" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^# .*Matrix.*Analysis'
}

@test "report has an Items field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Items:\*\*'
}

@test "report has a Criteria field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Criteria:\*\*'
}

@test "report has a Date field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Date:\*\*'
}

# --- Required sections ---

@test "report has Comparison Matrix section" {
  assert_section_exists "Comparison Matrix"
}

@test "report has Detailed Evaluations section" {
  assert_section_exists "Detailed Evaluations"
}

@test "report has Tradeoff Analysis section" {
  assert_heading_exists "Tradeoff"
}

@test "report has Recommendation section" {
  assert_section_exists "Recommendation"
}

# --- Matrix structure ---

@test "comparison matrix contains a markdown table" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Comparison Matrix/,/^## /p' | head -n -1)
  echo "$section" | grep -qE '^\|.*\|'
}

@test "comparison matrix has a table separator row" {
  # A valid markdown table has a separator row of dashes after the header.
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Comparison Matrix/,/^## /p' | head -n -1)
  echo "$section" | grep -qE '^\|[ :-]*-+[ :-]*\|'
}

@test "comparison matrix has at least two item rows" {
  # Count table rows that aren't the header or separator. The header row is the
  # first row, separator is the dash row; subsequent rows are items.
  local section item_rows
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Comparison Matrix/,/^## /p' | head -n -1)
  # Count all table rows, then subtract header + separator
  local total_rows
  total_rows=$(echo "$section" | grep -cE '^\|.*\|' || true)
  item_rows=$((total_rows - 2))
  [ "$item_rows" -ge 2 ]
}

@test "matrix uses rating symbols or numeric scores" {
  # Matrix should use qualitative ratings (++/+/-/?) or numeric scores in cells.
  echo "$REPORT_CONTENT" | grep -qE '(\+\+|\+[ |]|-[ |]|\?[ |]|[0-9]+/[0-9]+|\b[1-9]\b)'
}

# --- Detailed evaluations ---

@test "detailed evaluations have per-criterion subsections" {
  local detail_section
  detail_section=$(echo "$REPORT_CONTENT" | sed -n '/^## Detailed Evaluations/,/^## [^#]/p')
  local subsection_count
  subsection_count=$(echo "$detail_section" | grep -cE '^### ' || true)
  [ "$subsection_count" -ge 1 ]
}

# --- Evaluation Metadata ---

@test "report has Evaluation Metadata section" {
  assert_heading_exists "Evaluation Metadata"
}

# --- No leakage from sibling decision-helper skills ---

@test "report does not contain tech-debt-triage language" {
  # tech-debt-triage uses Carrying Cost / Fix Cost / Urgency Triggers and recommendation
  # verbs like "Fix now / Carry intentionally / Defer and monitor".
  ! echo "$REPORT_CONTENT" | grep -qiE '(^## .*Carrying Cost|^## .*Fix Cost|^## .*Urgency Triggers|Fix opportunistically|Carry intentionally|Defer and monitor)'
}

@test "report does not contain design-space-situating language" {
  # design-space-situating produces an eight-dimension situating record with dimensions
  # like "Locus of Authority" or "Orientation in Time".
  ! echo "$REPORT_CONTENT" | grep -qiE '(Locus of Authority|Orientation in Time|Search/Compose/Emerge|Modeling Target|situating record)'
}

@test "report does not contain what-if-analysis language" {
  # what-if-analysis produces a pre-mortem with "Assumption" / "If wrong" sections.
  ! echo "$REPORT_CONTENT" | grep -qiE '(^## .*Pre-?mortem|^## .*Failure Modes|^## .*Second-Order Effects|\*\*If wrong:\*\*)'
}
