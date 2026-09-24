#!/usr/bin/env bats
# @category fast
# Evaluates ai-personas-critique output against the flaw each planted draft
# carries (severity plus a pattern naming the flaw), and the stub pre-flight on
# the two negatives: a stub prints only the skip line, a short complete draft
# gets the full critique.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash ai-personas-critique
#
# Then run:
#   bats test/skills/ai-personas-critique-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="ai-personas-critique"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted flaws, one per persona lens ---

@test "tc-per1: camera pilot at worst sites — Fatal/Significant, names regression to the mean or a comparison group; report is well-formed" {
  eval_fixture "$SKILL" "tc-per1-red-light-cameras.md"
}

@test "tc-per2: bonus on resolved-ticket count — Fatal/Significant, names Goodhart or gaming the metric" {
  eval_fixture "$SKILL" "tc-per2-support-bonus-plan.md"
}

@test "tc-per3: SMS-only recovery and phone change on name/DOB — Fatal/Significant, names SIM swap or social engineering; report is well-formed" {
  eval_fixture "$SKILL" "tc-per3-account-recovery-redesign.md"
}

@test "tc-per4: three specialists at 50x volume — Fatal/Significant, names the volume or the bottleneck" {
  eval_fixture "$SKILL" "tc-per4-marketplace-dispute-desk.md"
}

@test "tc-per5: no-show model on insurance and distance — Fatal/Significant, names the disparate burden" {
  eval_fixture "$SKILL" "tc-per5-clinic-overbooking-model.md"
}

# --- Negatives: the stub pre-flight ---

@test "tc-per6: stub memo — prints the skip line and no critique sections" {
  eval_fixture "$SKILL" "tc-per6-transit-fare-memo.md"
}

@test "tc-per7: short complete pilot — not skipped, no Fatal flaw; report is well-formed" {
  eval_fixture "$SKILL" "tc-per7-library-sunday-pilot.md"
}
