#!/usr/bin/env bats
# Validates the output format of bug-diagnosis logs.
#
# The bug-diagnosis skill produces a structured diagnosis log with a Reproduction
# section, one or more numbered Hypothesis sections (each with Statement, Test,
# Result, Verdict, Confidence fields), and a Conclusion section.
#
# Usage: Set REPORT_PATH to a generated log, then run:
#   REPORT_PATH=docs/reviews/bug-diagnosis.md bats test/skills/bug-diagnosis-format.bats

load helpers

setup() {
  load_generic_report "${REPORT_PATH:-docs/reviews/bug-diagnosis.md}"
  count_findings
}

# --- Header section ---

@test "report has a title header with Bug Diagnosis identifier" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^# .*Bug Diagnosis'
}

@test "report has a Date field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Date:\*\*'
}

@test "report has a Scope field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Scope:\*\*'
}

# --- Required process sections ---

@test "report has Reproduction section" {
  assert_section_exists "Reproduction"
}

@test "report has Hypotheses section" {
  assert_section_exists "Hypotheses"
}

@test "report has Conclusion section" {
  assert_section_exists "Conclusion"
}

# --- Hypothesis structure ---

@test "report has at least one hypothesis" {
  [ "$FINDING_COUNT" -gt 0 ]
}

@test "each hypothesis has a Statement field" {
  assert_field_per_finding "Statement"
}

@test "each hypothesis has a Test field" {
  assert_field_per_finding "Test"
}

@test "each hypothesis has a Result field" {
  assert_field_per_finding "Result"
}

@test "each hypothesis has a Verdict field" {
  assert_field_per_finding "Verdict"
}

@test "verdict values use only the allowed values" {
  # CONFIRMED / REFUTED / INCONCLUSIVE are the canonical verdicts.
  # INCONCLUSIVE is distinct from REFUTED — "never tried" is not the same as
  # "tried and failed". This rule prevents the most common diagnostic error.
  assert_field_values "Verdict" "CONFIRMED|REFUTED|INCONCLUSIVE"
}

@test "each hypothesis has a Confidence field" {
  assert_field_per_finding "Confidence"
}

@test "confidence levels use only the allowed values" {
  assert_field_values "Confidence" "High|Medium|Low"
}

# --- Conclusion content ---

@test "conclusion names a root cause" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Root cause:\*\*'
}

@test "conclusion names a fix" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Fix:\*\*'
}

# --- Structural requirements ---

@test "report has at least 3 sections" {
  local section_count
  section_count=$(echo "$REPORT_CONTENT" | grep -cE '^## ' || true)
  [ "$section_count" -ge 3 ]
}

# --- No leakage from sibling skills ---

@test "report does not contain reviewer-style severity scale" {
  # Severity belongs to security/performance reviews, not diagnosis logs.
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Severity:\*\* (Critical|High|Medium|Low|Informational)$'
}

@test "report does not contain fact-check verdict scale" {
  # Diagnosis verdicts are CONFIRMED/REFUTED/INCONCLUSIVE, not Accurate/Disputed/etc.
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Mostly accurate|Disputed|Inaccurate|Unverified)$'
}

@test "report does not contain tech-debt recommendation language" {
  # Bug diagnosis is not a triage recommendation.
  ! echo "$REPORT_CONTENT" | grep -qiE '^(Fix now|Fix opportunistically|Carry intentionally|Defer and monitor)$'
}
