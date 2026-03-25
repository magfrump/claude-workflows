#!/usr/bin/env bats
# Validates that cowen-critique reports cover the expected semantic dimensions.
#
# Usage: REPORT_PATH=path/to/report.md bats test/skills/cowen-critique/dimensions.bats
#   (defaults to docs/reviews/cowen-critique.md)

load ../helpers
load ../critic-dimensions

setup() {
  load_generic_report "docs/reviews/cowen-critique.md"
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
