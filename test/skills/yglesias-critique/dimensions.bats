#!/usr/bin/env bats
# @category fast
# @needs-reports yglesias-critique
# Validates that a generated yglesias-critique report covers the expected semantic
# dimensions. Report-dependent: scripts/run-tests.sh runs this suite (tagged
# @needs-reports) only when this skill has generated reports. The
# offline half — each keyword is one the SKILL.md template prescribes — is
# dimensions-skill.bats, which always runs.
#
# Usage: REPORT_PATH=path/to/report.md bats test/skills/yglesias-critique/dimensions.bats
#   (defaults to the generated full-critique fixture report,
#    test/skills/yglesias-critique/output/tc-ygl7-library-fines.md.report.md —
#    produce it with: bash test/skills/generate-reports.bash yglesias-critique)

load ../helpers
load ../critic-dimensions

setup() {
  # The generated full-critique fixture report, never a committed docs/reviews/
  # artifact; resolve_skill_report (helpers.bash) fails on a missing, failed,
  # empty or stale (stamp-mismatched) report once yglesias-critique has reports.
  # shellcheck disable=SC2034  # read by resolve_skill_report
  SKILL_TESTS_DIR="$BATS_TEST_DIRNAME/.."
  resolve_skill_report yglesias-critique tc-ygl7-library-fines.md
  load_generic_report "$REPORT_PATH"
}

# --- Per-keyword dimension checks ---

@test "report contains mechanism language (The Goal vs. the Mechanism)" {
  echo "$REPORT_CONTENT" | grep -qi "mechanism"
}

@test "report contains lever language (The Boring Lever)" {
  echo "$REPORT_CONTENT" | grep -qi "lever"
}

@test "report contains money/cost language (Follow the Money)" {
  echo "$REPORT_CONTENT" | grep -qi "money"
}

@test "report contains scale language (The Scale Test)" {
  echo "$REPORT_CONTENT" | grep -qi "scale"
}

@test "report contains adoption language (Political Survival)" {
  echo "$REPORT_CONTENT" | grep -qi "adoption"
}

@test "report contains cost-disease language (The Cost Disease Check)" {
  echo "$REPORT_CONTENT" | grep -qi "cost disease"
}

@test "report contains org-chart language (The Org Chart)" {
  echo "$REPORT_CONTENT" | grep -qi "org chart"
}

# --- Aggregate check ---

@test "report covers all Yglesias semantic dimensions" {
  assert_dimension_keywords_present "$REPORT_CONTENT" "${YGLESIAS_DIMENSION_KEYWORDS[@]}"
}
