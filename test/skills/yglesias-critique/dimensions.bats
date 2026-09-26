#!/usr/bin/env bats
# @category fast
# Validates that a generated yglesias-critique report covers the expected semantic
# dimensions. Report-dependent: scripts/run-tests.sh gates this suite with the
# *-format/*-eval suites, so it only runs when generated reports exist. The
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
  # Anchored to this file, not the cwd: the old cwd-relative default read a
  # stale committed docs/reviews/ artifact (or skipped when none existed), so
  # no change to the skill could turn this suite red.
  local default="$BATS_TEST_DIRNAME/output/tc-ygl7-library-fines.md.report.md"
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
