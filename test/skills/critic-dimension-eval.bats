#!/usr/bin/env bats
# Semantic dimension coverage tests for critic skills.
#
# Checks that existing critic fixture outputs cover the expected analytical
# dimensions defined in each critic's dimension manifest. Each dimension is
# verified by keyword presence (case-insensitive grep).
#
# Usage:
#   bats test/skills/critic-dimension-eval.bats
#   COWEN_REPORT_PATH=path/to/report.md bats test/skills/critic-dimension-eval.bats
#   YGLESIAS_REPORT_PATH=path/to/report.md bats test/skills/critic-dimension-eval.bats

load helpers

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Load a dimension manifest and count how many dimensions the report covers.
# Sets COVERED_COUNT, TOTAL_COUNT, and MISSING_DIMS.
# Args: $1 = associative-array name prefix (COWEN or YGLESIAS)
#        $2 = report content variable
check_dimension_coverage() {
  local prefix="$1"
  local content="$2"
  COVERED_COUNT=0
  TOTAL_COUNT=0
  MISSING_DIMS=""

  local -n dims="${prefix}_DIMENSIONS"
  for dim in "${!dims[@]}"; do
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    if echo "$content" | grep -qiE "${dims[$dim]}"; then
      COVERED_COUNT=$((COVERED_COUNT + 1))
    else
      MISSING_DIMS="${MISSING_DIMS}  - ${dim}\n"
    fi
  done
}

# ---------------------------------------------------------------------------
# Cowen-critique dimension tests
# ---------------------------------------------------------------------------

setup_cowen() {
  COWEN_REPORT="${COWEN_REPORT_PATH:-docs/reviews/cowen-critique.md}"
  if [ ! -f "$COWEN_REPORT" ]; then
    skip "No Cowen report found at $COWEN_REPORT — generate one first"
  fi
  COWEN_CONTENT=$(tr -d '\r' < "$COWEN_REPORT")
  if [ -z "$COWEN_CONTENT" ]; then
    skip "Cowen report is empty"
  fi
  source "$(dirname "$BATS_TEST_FILENAME")/cowen-critique-dimensions.bash"
}

@test "cowen: boring explanation dimension is covered" {
  setup_cowen
  echo "$COWEN_CONTENT" | grep -qiE "${COWEN_DIMENSIONS[boring_explanation]}"
}

@test "cowen: inversion dimension is covered" {
  setup_cowen
  echo "$COWEN_CONTENT" | grep -qiE "${COWEN_DIMENSIONS[inversion]}"
}

@test "cowen: revealed preferences dimension is covered" {
  setup_cowen
  echo "$COWEN_CONTENT" | grep -qiE "${COWEN_DIMENSIONS[revealed_preferences]}"
}

@test "cowen: logical extreme dimension is covered" {
  setup_cowen
  echo "$COWEN_CONTENT" | grep -qiE "${COWEN_DIMENSIONS[logical_extreme]}"
}

@test "cowen: cross-domain analogy dimension is covered" {
  setup_cowen
  echo "$COWEN_CONTENT" | grep -qiE "${COWEN_DIMENSIONS[cross_domain_analogy]}"
}

@test "cowen: market signal dimension is covered" {
  setup_cowen
  echo "$COWEN_CONTENT" | grep -qiE "${COWEN_DIMENSIONS[market_signal]}"
}

@test "cowen: decomposition dimension is covered" {
  setup_cowen
  echo "$COWEN_CONTENT" | grep -qiE "${COWEN_DIMENSIONS[decomposition]}"
}

@test "cowen: contingent assumptions dimension is covered" {
  setup_cowen
  echo "$COWEN_CONTENT" | grep -qiE "${COWEN_DIMENSIONS[contingent_assumptions]}"
}

@test "cowen: calibrated uncertainty dimension is covered" {
  setup_cowen
  echo "$COWEN_CONTENT" | grep -qiE "${COWEN_DIMENSIONS[calibrated_uncertainty]}"
}

@test "cowen: economic lens dimension is covered" {
  setup_cowen
  echo "$COWEN_CONTENT" | grep -qiE "${COWEN_DIMENSIONS[economic_lens]}"
}

@test "cowen: meets minimum dimension coverage threshold" {
  setup_cowen
  check_dimension_coverage "COWEN" "$COWEN_CONTENT"
  if [ "$COVERED_COUNT" -lt "$COWEN_MIN_DIMENSIONS" ]; then
    echo "Coverage: ${COVERED_COUNT}/${TOTAL_COUNT} (minimum: ${COWEN_MIN_DIMENSIONS})"
    echo -e "Missing dimensions:\n${MISSING_DIMS}"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Yglesias-critique dimension tests
# ---------------------------------------------------------------------------

setup_yglesias() {
  YGLESIAS_REPORT="${YGLESIAS_REPORT_PATH:-docs/reviews/yglesias-critique.md}"
  if [ ! -f "$YGLESIAS_REPORT" ]; then
    skip "No Yglesias report found at $YGLESIAS_REPORT — generate one first"
  fi
  YGLESIAS_CONTENT=$(tr -d '\r' < "$YGLESIAS_REPORT")
  if [ -z "$YGLESIAS_CONTENT" ]; then
    skip "Yglesias report is empty"
  fi
  source "$(dirname "$BATS_TEST_FILENAME")/yglesias-critique-dimensions.bash"
}

@test "yglesias: goal vs mechanism dimension is covered" {
  setup_yglesias
  echo "$YGLESIAS_CONTENT" | grep -qiE "${YGLESIAS_DIMENSIONS[goal_vs_mechanism]}"
}

@test "yglesias: boring lever dimension is covered" {
  setup_yglesias
  echo "$YGLESIAS_CONTENT" | grep -qiE "${YGLESIAS_DIMENSIONS[boring_lever]}"
}

@test "yglesias: follow the money dimension is covered" {
  setup_yglesias
  echo "$YGLESIAS_CONTENT" | grep -qiE "${YGLESIAS_DIMENSIONS[follow_the_money]}"
}

@test "yglesias: political survival dimension is covered" {
  setup_yglesias
  echo "$YGLESIAS_CONTENT" | grep -qiE "${YGLESIAS_DIMENSIONS[political_survival]}"
}

@test "yglesias: cost disease dimension is covered" {
  setup_yglesias
  echo "$YGLESIAS_CONTENT" | grep -qiE "${YGLESIAS_DIMENSIONS[cost_disease]}"
}

@test "yglesias: scale test dimension is covered" {
  setup_yglesias
  echo "$YGLESIAS_CONTENT" | grep -qiE "${YGLESIAS_DIMENSIONS[scale_test]}"
}

@test "yglesias: org chart dimension is covered" {
  setup_yglesias
  echo "$YGLESIAS_CONTENT" | grep -qiE "${YGLESIAS_DIMENSIONS[org_chart]}"
}

@test "yglesias: popular version dimension is covered" {
  setup_yglesias
  echo "$YGLESIAS_CONTENT" | grep -qiE "${YGLESIAS_DIMENSIONS[popular_version]}"
}

@test "yglesias: factual calibration dimension is covered" {
  setup_yglesias
  echo "$YGLESIAS_CONTENT" | grep -qiE "${YGLESIAS_DIMENSIONS[factual_calibration]}"
}

@test "yglesias: policy lens dimension is covered" {
  setup_yglesias
  echo "$YGLESIAS_CONTENT" | grep -qiE "${YGLESIAS_DIMENSIONS[policy_lens]}"
}

@test "yglesias: meets minimum dimension coverage threshold" {
  setup_yglesias
  check_dimension_coverage "YGLESIAS" "$YGLESIAS_CONTENT"
  if [ "$COVERED_COUNT" -lt "$YGLESIAS_MIN_DIMENSIONS" ]; then
    echo "Coverage: ${COVERED_COUNT}/${TOTAL_COUNT} (minimum: ${YGLESIAS_MIN_DIMENSIONS})"
    echo -e "Missing dimensions:\n${MISSING_DIMS}"
    return 1
  fi
}
