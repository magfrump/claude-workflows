#!/usr/bin/env bats
# @category fast
# Evaluates design-space-situating output: each decision brief framed wrongly on
# one dimension has that misframing surfaced against the brief's own facts; the
# well-framed brief draws no misframing or re-frame hand-off.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash design-space-situating
#
# Then run:
#   bats test/skills/design-space-situating-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="design-space-situating"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted misframings, one dimension each ---

@test "tc-dss1: 24-month partner contract framed as revisit-later — names the reversal cost to partners; record is well-formed" {
  eval_fixture "$SKILL" "tc-dss1-partner-webhook-payloads.md"
}

@test "tc-dss2: one architect sets swap rules for 1,100 nurses — names nurse participation or overridden ward practice" {
  eval_fixture "$SKILL" "tc-dss2-ward-shift-swaps.md"
}

@test "tc-dss3: fraud rules built for today and handed over as-is — names the snapshot against a shifting attack mix" {
  eval_fixture "$SKILL" "tc-dss3-card-fraud-rules.md"
}

@test "tc-dss4: head roaster's judgment written into a formal controller spec — names tacit knowledge being formalised; record is well-formed" {
  eval_fixture "$SKILL" "tc-dss4-roast-profile-automation.md"
}

@test "tc-dss5: control-room dashboard scored for the board — names what operators lose to the roll-up" {
  eval_fixture "$SKILL" "tc-dss5-pumping-station-dashboard.md"
}

# --- Negative: a well-framed decision ---

@test "tc-dss6: well-framed build-cache hosting — no misframing or re-frame hand-off; record is well-formed" {
  eval_fixture "$SKILL" "tc-dss6-build-cache-hosting.md"
}
