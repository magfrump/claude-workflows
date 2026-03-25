#!/usr/bin/env bats
# Validates that cowen-critique reports exhibit distinctive analytical
# dimensions — the cognitive moves that make a Cowen-style critique Cowen-style.
#
# These are keyword/pattern checks against generated report content, not
# LLM-based evaluation.  Each test corresponds to one of the 9 cognitive moves
# defined in skills/cowen-critique.md.
#
# Usage:
#   REPORT_PATH=docs/reviews/cowen-critique.md bats test/skills/cowen-critique-dimensions.bats

load helpers

setup() {
  load_generic_report "docs/reviews/cowen-critique.md"
  source "${BATS_TEST_DIRNAME}/cowen-critique/expected-dimensions.bash"
}

# --- Dimension coverage (one test per cognitive move) ---

@test "dimension: boring explanation (move 1)" {
  assert_dimension_present "boring_explanation" "${COWEN_DIMENSIONS[boring_explanation]}"
}

@test "dimension: inversion / stress test (move 2)" {
  assert_dimension_present "inversion" "${COWEN_DIMENSIONS[inversion]}"
}

@test "dimension: revealed vs stated preferences (move 3)" {
  assert_dimension_present "revealed_preferences" "${COWEN_DIMENSIONS[revealed_preferences]}"
}

@test "dimension: logical extreme (move 4)" {
  assert_dimension_present "logical_extreme" "${COWEN_DIMENSIONS[logical_extreme]}"
}

@test "dimension: cross-domain analogy (move 5)" {
  assert_dimension_present "cross_domain_analogy" "${COWEN_DIMENSIONS[cross_domain_analogy]}"
}

@test "dimension: market signals (move 6)" {
  assert_dimension_present "market_signal" "${COWEN_DIMENSIONS[market_signal]}"
}

@test "dimension: claim decomposition (move 7)" {
  assert_dimension_present "decomposition" "${COWEN_DIMENSIONS[decomposition]}"
}

@test "dimension: contingent assumptions (move 8)" {
  assert_dimension_present "contingent_assumptions" "${COWEN_DIMENSIONS[contingent_assumptions]}"
}

@test "dimension: uncertainty calibration (move 9)" {
  assert_dimension_present "uncertainty_calibration" "${COWEN_DIMENSIONS[uncertainty_calibration]}"
}

# --- Aggregate coverage ---

@test "at least 7 of 9 dimensions present" {
  local hits=0
  for dim in "${!COWEN_DIMENSIONS[@]}"; do
    if echo "$REPORT_CONTENT" | grep -qiE "${COWEN_DIMENSIONS[$dim]}"; then
      hits=$((hits + 1))
    fi
  done
  [ "$hits" -ge 7 ]
}
