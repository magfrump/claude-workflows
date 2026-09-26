#!/usr/bin/env bats
# @category fast
# @needs-reports business-plan-critique-market-sizing
# Evaluates business-plan-critique-market-sizing output: each flawed plan must
# draw a failing lens verdict and name its planted flaw; the sound short plan
# must be critiqued (not skipped) without an Inflated verdict; the stub must get
# only the pre-flight skip line.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash business-plan-critique-market-sizing
#
# Then run:
#   bats test/skills/business-plan-critique-market-sizing-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="business-plan-critique-market-sizing"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- One planted flaw per lens ---

@test "tc-mkt1: TAM from the animal-health product market — failing verdict, names the category misfit; report is well-formed" {
  eval_fixture "$SKILL" "tc-mkt1-veterinary-inventory.md"
}

@test "tc-mkt2: SAM counts FedRAMP/StateRAMP-gated agencies — failing verdict, names the certification gate" {
  eval_fixture "$SKILL" "tc-mkt2-public-records-redaction.md"
}

@test "tc-mkt3: 1%-of-SAM SOM with no path — failing verdict, names the missing beachhead or sales math" {
  eval_fixture "$SKILL" "tc-mkt3-accounts-payable.md"
}

@test "tc-mkt4: why-now built on decade-long trends — failing verdict, names the missing trigger" {
  eval_fixture "$SKILL" "tc-mkt4-landscaping-scheduling.md"
}

@test "tc-mkt5: comp set of three \$100M winners — failing verdict, names selection bias; report is well-formed" {
  eval_fixture "$SKILL" "tc-mkt5-construction-project-management.md"
}

# --- Negatives (stub pre-flight) ---

@test "tc-mkt6: short sound plan — not skipped, no Inflated verdict; report is well-formed" {
  eval_fixture "$SKILL" "tc-mkt6-physio-insurer-billing.md"
}

@test "tc-mkt7: stub pitch — skip line only, no lens sections or verdicts" {
  eval_fixture "$SKILL" "tc-mkt7-pet-insurance-marketplace.md"
}
