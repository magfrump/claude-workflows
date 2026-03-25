#!/usr/bin/env bats
# Validates that yglesias-critique reports exhibit distinctive analytical
# dimensions — the cognitive moves that make a Yglesias-style critique
# Yglesias-style.
#
# These are keyword/pattern checks against generated report content, not
# LLM-based evaluation.  Each test corresponds to one of the 8 analytical
# dimensions derived from the 9 cognitive moves in skills/yglesias-critique.md.
#
# Usage:
#   REPORT_PATH=docs/reviews/yglesias-critique.md bats test/skills/yglesias-critique-dimensions.bats

load helpers

setup() {
  load_generic_report "docs/reviews/yglesias-critique.md"
  source "${BATS_TEST_DIRNAME}/yglesias-critique/expected-dimensions.bash"
}

# --- Dimension coverage (one test per cognitive move) ---

@test "dimension: goal vs mechanism (move 1)" {
  assert_dimension_present "goal_vs_mechanism" "${YGLESIAS_DIMENSIONS[goal_vs_mechanism]}"
}

@test "dimension: boring lever (move 2)" {
  assert_dimension_present "boring_lever" "${YGLESIAS_DIMENSIONS[boring_lever]}"
}

@test "dimension: follow the money (move 3)" {
  assert_dimension_present "follow_money" "${YGLESIAS_DIMENSIONS[follow_money]}"
}

@test "dimension: political survival (move 4)" {
  assert_dimension_present "political_survival" "${YGLESIAS_DIMENSIONS[political_survival]}"
}

@test "dimension: cost disease (move 5)" {
  assert_dimension_present "cost_disease" "${YGLESIAS_DIMENSIONS[cost_disease]}"
}

@test "dimension: scale test (move 6)" {
  assert_dimension_present "scale_test" "${YGLESIAS_DIMENSIONS[scale_test]}"
}

@test "dimension: org chart / implementation (move 7)" {
  assert_dimension_present "org_chart" "${YGLESIAS_DIMENSIONS[org_chart]}"
}

@test "dimension: popular version (move 8)" {
  assert_dimension_present "popular_version" "${YGLESIAS_DIMENSIONS[popular_version]}"
}

# --- Aggregate coverage ---

@test "at least 6 of 8 dimensions present" {
  local hits=0
  for dim in "${!YGLESIAS_DIMENSIONS[@]}"; do
    if echo "$REPORT_CONTENT" | grep -qiE "${YGLESIAS_DIMENSIONS[$dim]}"; then
      hits=$((hits + 1))
    fi
  done
  [ "$hits" -ge 6 ]
}
