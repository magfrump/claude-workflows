#!/usr/bin/env bats
# @category fast
# Evaluates pre-mortem output: each planted failure path narrated with a
# fitting severity; the two sound proposals draw no Catastrophic narrative, the
# low-stakes one says nothing must be addressed, and the dual-write rename draws
# no false "no dual-write" alarm.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash pre-mortem
#
# Then run:
#   bats test/skills/pre-mortem-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="pre-mortem"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted failure paths, one each ---

@test "tc-pm1: ledger cutover with no dual-write — rollback strands post-cutover writes, High/Catastrophic; report is well-formed" {
  eval_fixture "$SKILL" "tc-pm1-billing-ledger-migration.md"
}

@test "tc-pm2: checkout goes 100% into the Black Friday peak — names the 1.5x/4x gap or the freeze with no fallback, High/Catastrophic" {
  eval_fixture "$SKILL" "tc-pm2-checkout-redesign-rollout.md"
}

@test "tc-pm3: indexer author is the cutover on-call and leaves days later — names the key-person gap, Medium+" {
  eval_fixture "$SKILL" "tc-pm3-search-index-rebuild.md"
}

@test "tc-pm4: processor contract ends mid-ramp — names 30 June against the 25% ramp or the vanished rollback, High/Catastrophic; report is well-formed" {
  eval_fixture "$SKILL" "tc-pm4-payment-processor-switch.md"
}

@test "tc-pm5: self-serve returns triple volume into a manual desk — names the backlog, Medium+" {
  eval_fixture "$SKILL" "tc-pm5-self-serve-returns.md"
}

# --- Negatives: sound proposals ---

@test "tc-pm6: low-stakes typeface change — no Catastrophic, says nothing must be addressed; report is well-formed" {
  eval_fixture "$SKILL" "tc-pm6-docs-typeface-change.md"
}

@test "tc-pm7: expand-and-contract rename — no Catastrophic, no false no-dual-write alarm; report is well-formed" {
  eval_fixture "$SKILL" "tc-pm7-orders-column-rename.md"
}
