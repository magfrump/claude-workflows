#!/usr/bin/env bats
# @category fast
# @needs-reports business-plan-critique-unit-economics
# Evaluates business-plan-critique-unit-economics output: each planted-flaw
# fixture must be named under the lens that owns it, the stub must get only the
# skip line, and the short sound plan must get a full, well-formed critique
# without a false complaint.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash business-plan-critique-unit-economics
#
# Then run:
#   bats test/skills/business-plan-critique-unit-economics-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="business-plan-critique-unit-economics"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted flaws, one lens each ---

@test "tc-ue1: blended CAC hides founder network — names it, recomputes paid CAC; report is well-formed" {
  eval_fixture "$SKILL" "tc-ue1-dental-scheduling-saas.md"
}

@test "tc-ue2: LTV on revenue — names margin weighting, recomputes LTV" {
  eval_fixture "$SKILL" "tc-ue2-fresh-pet-food-subscription.md"
}

@test "tc-ue3: CS and implementation booked as fixed — names them as per-account costs; report is well-formed" {
  eval_fixture "$SKILL" "tc-ue3-construction-project-software.md"
}

@test "tc-ue4: payback vs funding ask — names the working-capital gap" {
  eval_fixture "$SKILL" "tc-ue4-hr-compliance-platform.md"
}

@test "tc-ue5: margin expansion on undemonstrated automation — names the lever as unproven" {
  eval_fixture "$SKILL" "tc-ue5-bookkeeping-service.md"
}

# --- Negatives: the stub pre-flight ---

@test "tc-ue6: stub plan — skip line only, no critique headings" {
  eval_fixture "$SKILL" "tc-ue6-waste-hauling-marketplace.md"
}

@test "tc-ue7: short sound plan — not skipped, well-formed, no false blended-CAC complaint" {
  eval_fixture "$SKILL" "tc-ue7-veterinary-inventory-saas.md"
}
