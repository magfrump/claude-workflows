#!/usr/bin/env bats
# @category fast
# @needs-reports yglesias-critique
# Evaluates yglesias-critique output: each planted-flaw draft's critique must
# name the specific way the mechanism fails, the stub must get only the
# pre-flight skip line, and the short complete draft must get a full critique.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash yglesias-critique
#
# Then run:
#   bats test/skills/yglesias-critique-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="yglesias-critique"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted mechanism flaws ---

@test "tc-ygl1: class-size cap — names the teacher-quality drain; report is well-formed" {
  eval_fixture "$SKILL" "tc-ygl1-class-size-cap.md"
}

@test "tc-ygl2: down-payment grants — names capitalization into prices" {
  eval_fixture "$SKILL" "tc-ygl2-down-payment-grants.md"
}

@test "tc-ygl3: rail extension — names the per-mile cost growth" {
  eval_fixture "$SKILL" "tc-ygl3-rail-extension.md"
}

@test "tc-ygl4: apprenticeship guarantee — names the employer-capacity limit at scale; report is well-formed" {
  eval_fixture "$SKILL" "tc-ygl4-apprenticeship-guarantee.md"
}

@test "tc-ygl5: regional housing portal — names the missing lead agency" {
  eval_fixture "$SKILL" "tc-ygl5-regional-housing-portal.md"
}

# --- Pre-flight negatives ---

@test "tc-ygl6: stub draft — skip line only, no critique sections" {
  eval_fixture "$SKILL" "tc-ygl6-parking-minimums.md"
}

@test "tc-ygl7: short complete draft — not skipped; report is well-formed" {
  eval_fixture "$SKILL" "tc-ygl7-library-fines.md"
}
