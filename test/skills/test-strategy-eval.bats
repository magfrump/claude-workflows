#!/usr/bin/env bats
# @category fast
# @needs-reports test-strategy
# Evaluates test-strategy skill output: each planted fixture's untested
# high-risk path must appear as an enumerated **G<n>** gap with a high-priority
# test recommended, and the negative must not list a covered branch as a gap
# or recommend any high-priority test.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash test-strategy
#
# Then run:
#   bats test/skills/test-strategy-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="test-strategy"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted gaps ---

@test "tc-ts1: remainder-cent split untested — gap named, high priority; report is well-formed" {
  eval_fixture "$SKILL" "tc-ts1-installment-split.py"
}

@test "tc-ts2: webhook retry path untested — gap names 429/5xx, backoff or MaxAttempts; high priority" {
  eval_fixture "$SKILL" "tc-ts2-webhook-client.go"
}

@test "tc-ts3: DST spring-forward branch untested — gap named, high priority" {
  eval_fixture "$SKILL" "tc-ts3-nightly-export-schedule.py"
}

@test "tc-ts4: concurrent token refresh untested — gap named, high priority; report is well-formed" {
  eval_fixture "$SKILL" "tc-ts4-token-cache.ts"
}

@test "tc-ts5: multi-page cursor loop untested — gap named, high priority" {
  eval_fixture "$SKILL" "tc-ts5-order-sync.py"
}

# --- Negative ---

@test "tc-ts6: well-tested parser — unknown-unit branch not a gap, no high priority; report is well-formed" {
  eval_fixture "$SKILL" "tc-ts6-duration-parser.py"
}
