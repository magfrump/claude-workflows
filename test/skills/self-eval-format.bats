#!/usr/bin/env bats
# Validates the output format of self-eval reports.
#
# Note: Skips gracefully via load_generic_report when no report exists.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/self-eval-fact-check.md bats test/skills/self-eval-format.bats

load helpers

setup() {
  load_generic_report "${REPORT_PATH:-docs/reviews/self-eval-fact-check.md}"
}

# --- Header section ---

@test "report has a title header with Self-Evaluation" {
  echo "$REPORT_CONTENT" | head -15 | grep -qiE '^# Self-Evaluation'
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

@test "automated assessments table has Justification column" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Automated Assessments/,/^## /p' | head -n -1)
  echo "$section" | grep -qiE '\| *Justification'
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

@test "automated assessments table includes Testability investment row" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Automated Assessments/,/^## /p' | head -n -1)
  echo "$section" | grep -qiE '\|[[:space:]]*Testability investment[[:space:]]*\|'
}

@test "automated assessments table includes Trigger clarity row" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Automated Assessments/,/^## /p' | head -n -1)
  echo "$section" | grep -qiE '\|[[:space:]]*Trigger clarity[[:space:]]*\|'
}

@test "automated assessments table includes Overlap and redundancy row" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Automated Assessments/,/^## /p' | head -n -1)
  echo "$section" | grep -qiE '\|[[:space:]]*Overlap and redundancy[[:space:]]*\|'
}

@test "automated assessments table includes Test coverage row" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Automated Assessments/,/^## /p' | head -n -1)
  echo "$section" | grep -qiE '\|[[:space:]]*Test coverage[[:space:]]*\|'
}

@test "automated assessments table includes Pipeline readiness row" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Automated Assessments/,/^## /p' | head -n -1)
  echo "$section" | grep -qiE '\|[[:space:]]*Pipeline readiness[[:space:]]*\|'
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

@test "key questions has at least 2 numbered items" {
  local section count
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Key Questions/,$p')
  count=$(echo "$section" | grep -cE '^[0-9]+\.' || true)
  [ "$count" -ge 2 ]
}

# --- Non-leakage from reviewer/critic skills ---

@test "report does not leak Verdict field from critic skills" {
  ! echo "$REPORT_CONTENT" | grep -qE '^\*\*Verdict:\*\*'
}

@test "report does not leak Severity field from critic skills" {
  ! echo "$REPORT_CONTENT" | grep -qE '^\*\*Severity:\*\*'
}

@test "report does not contain Claim N headings from fact-check format" {
  ! echo "$REPORT_CONTENT" | grep -qE '^## Claim [0-9]+'
}
