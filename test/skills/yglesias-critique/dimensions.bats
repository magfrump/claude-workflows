#!/usr/bin/env bats
# Validates that yglesias-critique reports cover the expected semantic dimensions.
#
# Usage: REPORT_PATH=path/to/report.md bats test/skills/yglesias-critique/dimensions.bats
#   (defaults to docs/reviews/yglesias-critique.md)

load ../helpers
load ../critic-dimensions

setup() {
  load_generic_report "docs/reviews/yglesias-critique.md"
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
