#!/usr/bin/env bats
# @category fast
# Evaluates business-plan-critique-moat output: each planted flaw graded Weak or
# Absent and named in the lens it targets; the stub skipped with the exact skip
# line; the short sound plan critiqued in full with no Absent lens.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash business-plan-critique-moat
#
# Then run:
#   bats test/skills/business-plan-critique-moat-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="business-plan-critique-moat"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted flaws, one lens each ---

@test "tc-moat1: head start sold as a moat — Weak/Absent, names first-mover as not durable; report is well-formed" {
  eval_fixture "$SKILL" "tc-moat1-veterinary-booking.md"
}

@test "tc-moat2: App Store and TikTok organic as the channel — Weak/Absent, names platform-owned demand or non-flat CAC" {
  eval_fixture "$SKILL" "tc-moat2-meal-planning-app.md"
}

@test "tc-moat3: switching costs with one-click export — Weak/Absent, names export, month-to-month or roadmap lock-in; report is well-formed" {
  eval_fixture "$SKILL" "tc-moat3-field-inspection-forms.md"
}

@test "tc-moat4: network effect in a single-player app — Weak/Absent, names no interaction or weak forms" {
  eval_fixture "$SKILL" "tc-moat4-household-budgeting.md"
}

@test "tc-moat5: platform incumbent assumed passive — Weak/Absent, names Convene bundling" {
  eval_fixture "$SKILL" "tc-moat5-sales-call-notes.md"
}

# --- Negatives: the stub pre-flight ---

@test "tc-moat6: stub — skip line only, no lens headings or verdicts" {
  eval_fixture "$SKILL" "tc-moat6-cold-chain-sensors.md"
}

@test "tc-moat7: short sound plan — not skipped, no Absent lens; report is well-formed" {
  eval_fixture "$SKILL" "tc-moat7-lab-compliance-software.md"
}
