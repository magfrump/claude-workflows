#!/usr/bin/env bats
# Validates the output format of self-eval reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/self-eval-fact-check.md bats test/skills/self-eval-format.bats

load helpers

setup() {
  load_generic_report "${REPORT_PATH:-docs/reviews/self-eval-fact-check.md}"
}

# --- Header section ---

@test "report has a title header with Self-Evaluation" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^# Self-Evaluation'
}

@test "report has a Target field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Target:\*\*'
}

@test "report has a Type field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Type:\*\*'
}

@test "report has an Evaluated date field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Evaluated:\*\*'
}

@test "report has an Evaluator field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Evaluator:\*\*'
}

# --- Automated Assessments ---

@test "report has Automated Assessments section" {
  assert_section_exists "Automated Assessments"
}

@test "automated assessments contains a table" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Automated Assessments/,/^## /p' | head -n -1)
  echo "$section" | grep -qE '^\|.*\|'
}

@test "automated assessments table has Dimension column" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Automated Assessments/,/^## /p' | head -n -1)
  echo "$section" | grep -qiE '\| *Dimension'
}

@test "automated assessments table has Score column" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Automated Assessments/,/^## /p' | head -n -1)
  echo "$section" | grep -qiE '\| *Score'
}

@test "scores use only the allowed values" {
  local section header_row score_col scores bad
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Automated Assessments/,/^## /p' | head -n -1)
  # Find which pipe-delimited column contains "Score" in the header row
  header_row=$(echo "$section" | grep -E '^\|' | head -1)
  score_col=$(echo "$header_row" | awk -F'|' '{for(i=1;i<=NF;i++) if(tolower($i) ~ /score/) print i}')
  [ -n "$score_col" ] || skip "no Score column found in table header"
  # Extract score column values from data rows (skip header and separator)
  scores=$(echo "$section" | grep -E '^\|' | grep -vE '^\|.*---' | tail -n +2 | awk -F'|' -v col="$score_col" '{print $col}' | sed 's/^ *//;s/ *$//')
  [ -n "$scores" ] || skip "no scores found"
  bad=$(echo "$scores" | grep -viE '^(Strong|Adequate|Weak)$' || true)
  [ -z "$bad" ]
}

@test "automated assessments has at least 5 dimensions" {
  local section row_count
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Automated Assessments/,/^## /p' | head -n -1)
  row_count=$(echo "$section" | grep -E '^\|' | grep -vE '^\|.*---' | tail -n +2 | wc -l)
  [ "$row_count" -ge 5 ]
}

# --- Flagged for Human Review ---

@test "report has Flagged for Human Review section" {
  assert_section_exists "Flagged for Human Review"
}

@test "human review has Counterfactual Gap subsection" {
  echo "$REPORT_CONTENT" | grep -qiE '^### Counterfactual Gap'
}

@test "human review has User-Specific Fit subsection" {
  echo "$REPORT_CONTENT" | grep -qiE '^### User.*Fit'
}

@test "human review has Condition for Value subsection" {
  echo "$REPORT_CONTENT" | grep -qiE '^### Condition.*Value'
}

@test "human review has Failure Mode subsection" {
  echo "$REPORT_CONTENT" | grep -qiE '^### Failure Mode'
}

# --- Key Questions ---

@test "report has Key Questions section" {
  assert_section_exists "Key Questions"
}

@test "key questions section has numbered items" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Key Questions/,$p')
  echo "$section" | grep -qE '^[0-9]+\.'
}
