#!/usr/bin/env bats
# @category fast
# Evaluates tech-debt-triage output: each debt item gets the Recommendation its
# drivers call for under SKILL.md's fix-or-carry rules, and the report names the
# driver (incident count, EOL runway, memory runway, the planned work to ride
# along with, time since last change, the re-evaluation trigger). The two
# carry-type items must not be pushed to Fix now.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash tech-debt-triage
#
# Then run:
#   bats test/skills/tech-debt-triage-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="tech-debt-triage"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted items: the correct call is to act ---

@test "tc-td1: weekly-changed hot path with four incidents — Fix now, carrying cost High, names the incidents or change rate; report is well-formed" {
  eval_fixture "$SKILL" "tc-td1-discount-rules.md"
}

@test "tc-td2: stable renderer on a runtime going EOL in 87 days — Fix now, names the runway to EOL or the exam" {
  eval_fixture "$SKILL" "tc-td2-statement-renderer.md"
}

@test "tc-td3: nightly job ~3 months from its memory limit — Fix now, names the growth rate or runway; report is well-formed" {
  eval_fixture "$SKILL" "tc-td3-nightly-reconciliation.md"
}

@test "tc-td4: cheap dedup inside code FUL-1187 already rewrites — Fix opportunistically, carrying cost Medium, ties the fix to FUL-1187" {
  eval_fixture "$SKILL" "tc-td4-postcode-validation.md"
}

# --- Negatives: carry-type items that must not be pushed to Fix now ---

@test "tc-td5: ugly but untouched VAT tables — Carry intentionally, not Fix now, carrying cost Low, names how long it has been stable; report is well-formed" {
  eval_fixture "$SKILL" "tc-td5-vat-rate-tables.md"
}

@test "tc-td6: job queue only a possible second region would break — Defer/Carry, not Fix now, ties re-evaluation to the region decision; report is well-formed" {
  eval_fixture "$SKILL" "tc-td6-job-queue.md"
}
