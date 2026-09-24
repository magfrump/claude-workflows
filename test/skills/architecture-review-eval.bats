#!/usr/bin/env bats
# @category fast
# Evaluates architecture-review skill output against expected severities and the
# structural concepts each fixture's planted defect calls for, plus two clean
# negatives (a sound ports-and-adapters package, and an internal-only patch that
# should take the Scope Check skip path).
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash architecture-review
#
# Then run:
#   bats test/skills/architecture-review-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="architecture-review"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted defects ---

@test "tc-arch1: domain imports infrastructure — Structural, names dependency direction" {
  eval_fixture "$SKILL" "tc-arch1-domain-imports-infra.py"
}

@test "tc-arch2: circular module dependency — Structural, names the cycle" {
  eval_fixture "$SKILL" "tc-arch2-circular-modules.ts"
}

@test "tc-arch3: god class — Structural/Coupling, names single responsibility" {
  eval_fixture "$SKILL" "tc-arch3-god-class.py"
}

@test "tc-arch4: fat interface — Coupling/Minor, names interface segregation" {
  eval_fixture "$SKILL" "tc-arch4-fat-interface.py"
}

@test "tc-arch5: leaky gateway — Coupling/Structural, names the vendor leak" {
  eval_fixture "$SKILL" "tc-arch5-leaky-gateway.py"
}

# --- Clean negatives ---

@test "tc-arch6: clean ports and adapters — no Structural or Coupling finding" {
  eval_fixture "$SKILL" "tc-arch6-clean-ports-adapters.py"
}

@test "tc-arch7: internal-only patch — Scope Check skip note, no tiered finding" {
  eval_fixture "$SKILL" "tc-arch7-internal-fix.patch"
}
