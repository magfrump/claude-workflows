#!/usr/bin/env bats
# Validates the output format of tech-debt-triage reports.
#
# Note: No example report exists yet — tests will skip via load_generic_report.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=path/to/report.md bats test/skills/tech-debt-triage-format.bats

load helpers

setup() {
  load_generic_report "${REPORT_PATH:-docs/working/tech-debt-triage.md}"
}

# --- Header section ---

@test "report has a title header with Tech Debt Triage" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^#{1,2} .*Tech Debt Triage'
}

@test "report has a Location field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Location:\*\*'
}

@test "report has a Nature field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Nature:\*\*'
}

# --- Required sections ---

@test "report has Carrying Cost section" {
  assert_heading_exists "Carrying Cost"
}

@test "carrying cost uses allowed values" {
  echo "$REPORT_CONTENT" | grep -iE 'Carrying Cost' | grep -qiE '(High|Medium|Low)'
}

@test "report has Fix Cost section" {
  assert_heading_exists "Fix Cost"
}

@test "fix cost has Scope field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Scope:\*\*.*\b(localized|cross-cutting|systemic)\b'
}

@test "fix cost has Effort field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Effort:\*\*.*\b(hours|days|weeks)\b'
}

@test "fix cost has Risk field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Risk:\*\*.*\b(low|medium|high)\b'
}

@test "report has Urgency Triggers section" {
  assert_heading_exists "Urgency Triggers"
}

@test "report has Recommendation section" {
  assert_heading_exists "Recommendation"
}

@test "recommendation uses allowed values" {
  echo "$REPORT_CONTENT" | grep -iE '(Recommendation|^Fix now|^Fix opportunistically|^Carry intentionally|^Defer and monitor)' | grep -qiE '(Fix now|Fix opportunistically|Carry intentionally|Defer and monitor)'
}
