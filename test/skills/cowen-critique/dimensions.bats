#!/usr/bin/env bats
# @category fast
# Validates that a generated cowen-critique report covers the expected semantic
# dimensions. Report-dependent: scripts/run-tests.sh gates this suite with the
# *-format/*-eval suites, so it only runs when generated reports exist. The
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
  # Anchored to this file, not the cwd: the old cwd-relative default read a
  # stale committed docs/reviews/ artifact (or skipped when none existed), so
  # no change to the skill could turn this suite red.
  local default="$BATS_TEST_DIRNAME/output/tc-cow7-farmers-market.md.report.md"
  local report="${REPORT_PATH:-$default}"
  # generate-reports.bash leaves <fixture>.failed when the run failed; the
  # report beside it is not a critique and must not be scored (or skipped).
  if [ -f "${report%.report.md}.failed" ]; then
    echo "Generation failed for $report: $(cat "${report%.report.md}.failed")" >&2
    return 1
  fi
  load_generic_report "$report"
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
