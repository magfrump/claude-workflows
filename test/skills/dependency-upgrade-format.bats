#!/usr/bin/env bats
# Validates the output format of dependency-upgrade reports.
#
# Note: No example report exists yet — tests will skip via load_generic_report.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=path/to/report.md bats test/skills/dependency-upgrade-format.bats

load helpers

setup() {
  load_generic_report "${REPORT_PATH:-docs/working/dep-upgrade.md}"
}

# --- Header section ---

@test "report has a title header with Dependency Upgrade" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^#{1,2} .*Dependency Upgrade'
}

# --- Summary section ---

@test "report has Summary section" {
  assert_heading_exists "Summary"
}

@test "summary has Recommendation field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Recommendation:\*\*.*\b(Upgrade now|Upgrade soon|Defer|Don.t upgrade)\b'
}

@test "summary has Breaking change impact field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Breaking change impact:\*\*.*\b(None|Mechanical|Moderate|Significant)\b'
}

@test "summary has Estimated effort field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Estimated effort:\*\*.*\b(minutes|hours|days)\b'
}

@test "summary has Risk field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Risk:\*\*.*\b(Low|Medium|High)\b'
}

# --- Required sections ---

@test "report has Motivation section" {
  assert_heading_exists "Motivation"
}

@test "report has Breaking Changes That Affect This Project section" {
  assert_heading_exists "Breaking Changes.*Affect"
}

@test "report has Transitive Effects section" {
  assert_heading_exists "Transitive Effects"
}

@test "report has Risk Factors section" {
  assert_heading_exists "Risk Factors"
}

@test "report has Migration Plan section" {
  assert_heading_exists "Migration Plan"
}

@test "report has If Not Upgrading section" {
  assert_heading_exists "If Not Upgrading"
}
