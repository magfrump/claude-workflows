#!/usr/bin/env bats
# @category fast
# @needs-reports what-if-analysis
# Evaluates what-if-analysis output: each planted flaw found by the cognitive
# move it targets (load-bearing assumption, second-order effect, hidden
# coupling, reversibility cliff, cost of success); the genuinely reversible
# change drawn with no [REVERSIBILITY CLIFF] finding.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash what-if-analysis
#
# Then run:
#   bats test/skills/what-if-analysis-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="what-if-analysis"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted flaws, one move each ---

@test "tc-wi1: 'every consumer is idempotent' stated as fact — graded redesign/retreat, names double points or unverified idempotency; report is well-formed" {
  eval_fixture "$SKILL" "tc-wi1-order-events-queue.md"
}

@test "tc-wi2: 48h auto-close — names late repliers coming back as new tickets or metrics that only move the work" {
  eval_fixture "$SKILL" "tc-wi2-ticket-auto-close.md"
}

@test "tc-wi3: settlement moved past warehouse-sync — names the 02:15 copy running before settlement" {
  eval_fixture "$SKILL" "tc-wi3-settlement-batch-schedule.md"
}

@test "tc-wi4: 'instant and complete' rollback of in-place hash upgrade — names overwritten bcrypt hashes and tags a reversibility cliff; report is well-formed" {
  eval_fixture "$SKILL" "tc-wi4-password-hash-upgrade.md"
}

@test "tc-wi5: free tier with the same Contact us button — names support volume at 40,000 Solo accounts" {
  eval_fixture "$SKILL" "tc-wi5-free-tier-launch.md"
}

# --- Negative: a genuinely reversible change ---

@test "tc-wi6: flag-guarded client swap with rehearsed rollback — no [REVERSIBILITY CLIFF] finding; report is well-formed" {
  eval_fixture "$SKILL" "tc-wi6-http-client-swap.md"
}
