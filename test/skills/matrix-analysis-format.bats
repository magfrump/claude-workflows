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

@test "matrix uses rating symbols" {
  # The matrix should use qualitative ratings: ++ / + / - / ?
  echo "$REPORT_CONTENT" | grep -qE '(\+\+|\+[ |]|-[ |]|\?[ |])'
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
