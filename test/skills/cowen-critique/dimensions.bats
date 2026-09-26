#!/usr/bin/env bats
# @category fast
# @needs-reports cowen-critique
# Validates that a generated cowen-critique report covers the expected semantic
# dimensions. Report-dependent: scripts/run-tests.sh runs this suite (tagged
# @needs-reports) only when this skill has generated reports. The
# offline half — each keyword is one the SKILL.md template prescribes — is
# dimensions-skill.bats, which always runs.
#
# Usage: REPORT_PATH=path/to/report.md bats test/skills/cowen-critique/dimensions.bats
#   (defaults to the generated full-critique fixture report,
#    test/skills/cowen-critique/output/tc-cow7-farmers-market.md.report.md —
#    produce it with: bash test/skills/generate-reports.bash cowen-critique)

load ../helpers
load ../critic-dimensions

setup() {
  # The generated full-critique fixture report, never a committed docs/reviews/
  # artifact; resolve_skill_report (helpers.bash) fails on a missing, failed,
  # empty or stale (stamp-mismatched) report once cowen-critique has reports.
  # shellcheck disable=SC2034  # read by resolve_skill_report
  SKILL_TESTS_DIR="$BATS_TEST_DIRNAME/.."
  resolve_skill_report cowen-critique tc-cow7-farmers-market.md
  load_generic_report "$REPORT_PATH"
}

# --- Per-keyword dimension checks ---

@test "report contains inversion language (What Survives the Inversion)" {
  echo "$REPORT_CONTENT" | grep -qi "inversion"
}

@test "report contains boring-explanation language (The Boring Explanation)" {
  echo "$REPORT_CONTENT" | grep -qi "boring"
}

@test "report contains revealed-preference language (Revealed vs. Stated)" {
  echo "$REPORT_CONTENT" | grep -qi "revealed"
}

@test "report contains analogy language (Cross-domain Analogy)" {
  echo "$REPORT_CONTENT" | grep -qi "analogy"
}

@test "report contains contingent-assumptions language" {
  echo "$REPORT_CONTENT" | grep -qi "contingent"
}

@test "report contains market-signal language (What the Market Says)" {
  echo "$REPORT_CONTENT" | grep -qi "market"
}

@test "report contains sub-claim decomposition language" {
  echo "$REPORT_CONTENT" | grep -qi "sub-claim"
}

# --- Aggregate check ---

@test "report covers all Cowen semantic dimensions" {
  assert_dimension_keywords_present "$REPORT_CONTENT" "${COWEN_DIMENSION_KEYWORDS[@]}"
}
