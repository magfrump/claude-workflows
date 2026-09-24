#!/usr/bin/env bats
# @category fast
# Evaluates matrix-analysis output: one sub-agent per criterion on every run; an
# AGPL library in a closed network SaaS is rated weak on licence and not
# recommended despite leading elsewhere; a dominant option is recommended; a
# requested 1-5 scale is used instead of Strong/Adequate/Weak; and a genuine
# mirrored tie gets a conditional recommendation, not a declared winner.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash matrix-analysis
#
# Then run:
#   bats test/skills/matrix-analysis-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="matrix-analysis"

setup() {
  load_expected_verdicts "$SKILL"
}

@test "tc-ma1: AGPL library in a closed network SaaS — 4 criterion agents, licence weakness named, another library recommended; well-formed" {
  eval_fixture "$SKILL" "tc-ma1-agpl-library-in-closed-saas.md"
}

@test "tc-ma2: one CI provider best on every criterion — 3 criterion agents, recommends it; well-formed" {
  eval_fixture "$SKILL" "tc-ma2-one-ci-provider-dominates.md"
}

@test "tc-ma3: user asks for 1-5 scores — 3 criterion agents, numeric cells, no word ratings" {
  eval_fixture "$SKILL" "tc-ma3-numeric-scale-requested.md"
}

@test "tc-ma4: mirrored tie, no stated priority — 3 criterion agents, conditional recommendation, no declared winner; well-formed" {
  eval_fixture "$SKILL" "tc-ma4-mirrored-tie-no-priority.md"
}
