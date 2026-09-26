#!/usr/bin/env bats
# @category fast
# @needs-reports cowen-critique
# Evaluates cowen-critique skill output: each planted-flaw draft must draw the
# cognitive move that catches its flaw (checked by naming the specific fact the
# flaw turns on), the stub must get only the pre-flight skip line, and the
# short complete draft must get a full, well-formed critique.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash cowen-critique
#
# Then run:
#   bats test/skills/cowen-critique-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="cowen-critique"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted flaws: one cognitive move each ---

@test "tc-cow1: library visits — boring explanation names the cut opening hours; report is well-formed" {
  eval_fixture "$SKILL" "tc-cow1-library-visits.md"
}

@test "tc-cow2: office return — revealed preference names the empty office / desk occupancy; report is well-formed" {
  eval_fixture "$SKILL" "tc-cow2-office-return.md"
}

@test "tc-cow3: school calendar — names the long summer as historically or locally contingent" {
  eval_fixture "$SKILL" "tc-cow3-school-calendar.md"
}

@test "tc-cow4: open plan — inversion reads chat growth as a substitute for talking in person" {
  eval_fixture "$SKILL" "tc-cow4-open-plan.md"
}

@test "tc-cow5: office conversions — asks why no developer has taken the claimed margin" {
  eval_fixture "$SKILL" "tc-cow5-office-conversions.md"
}

# --- Pre-flight negatives ---

@test "tc-cow6: stub draft — skip line only, no critique sections or warning" {
  eval_fixture "$SKILL" "tc-cow6-transit-fares.md"
}

@test "tc-cow7: short complete draft — not skipped; report is well-formed" {
  eval_fixture "$SKILL" "tc-cow7-farmers-market.md"
}
