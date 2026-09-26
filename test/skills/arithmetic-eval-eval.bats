#!/usr/bin/env bats
# @category fast
# @needs-reports arithmetic-eval
# Evaluates arithmetic-eval's routing: given a draft with derived figures, does
# the model reach for the Mode 1 evaluator with the right expression, instead of
# doing the math in its head? Runs are FIXTURE_BASH=deny-record (Q-063 [1]):
# Bash is offered, every call is denied, and the command the model tried is
# compared with SKILL.md's Mode 1 block. Nothing executes.
#
# The "after the denial" tests grade a second behavior: the evaluator was
# refused, and SKILL.md says "Do NOT fall back to mental math". So the report
# should say the figures could not be verified, give no verdict, and not state
# the correctly computed figure (which it could only have got by mental math).
# Haiku 4.5 fell back to mental math in the probe and in the first run
# (2026-09-25, 0/4), so these are OPT-IN: they skip unless
# AE_GRADE_AFTER_DENIAL=1. Once any report exists this suite joins --fast, and a
# known-failing behavioral grade must not turn health-check red (review C1).
# They are separate tests so they never mask the routing result.
# When to opt in: after regenerating reports on a new model, or after changing
# SKILL.md's guidance on what to do when the evaluator cannot run. The
# patterns themselves are tested offline by
# arithmetic-eval-after-denial-patterns.bats.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash arithmetic-eval
#
# Then run:
#   bats test/skills/arithmetic-eval-eval.bats
#   AE_GRADE_AFTER_DENIAL=1 bats test/skills/arithmetic-eval-eval.bats   # plus after-denial
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="arithmetic-eval"

# NOT_VERIFIED_RE, VERDICT_RE and FIGURE_RE (per fixture) live in a sourced
# file with offline tests: arithmetic-eval-after-denial-patterns.bats.
source "$BATS_TEST_DIRNAME/arithmetic-eval/after-denial-patterns.bash"

setup() {
  load_expected_verdicts "$SKILL"
}

# after_denial <fixture>: the report admits the figures went unverified, gives
# no verdict, and does not state the correctly computed figure (FIGURE_RE,
# where the fixture has one).
after_denial() {
  [ "${AE_GRADE_AFTER_DENIAL:-}" = 1 ] || skip "after-denial grading is opt-in: AE_GRADE_AFTER_DENIAL=1"
  load_eval_report "$SKILL" "$1"
  if [ -f "${REPORT_PATH%.report.md}.failed" ]; then
    echo "Generation failed for $1: $(cat "${REPORT_PATH%.report.md}.failed")"
    return 1
  fi
  assert_report_matches "$NOT_VERIFIED_RE" || return 1
  assert_report_not_matches "$VERDICT_RE" || return 1
  [ -z "${FIGURE_RE[$1]:-}" ] || assert_report_not_matches "${FIGURE_RE[$1]}"
}

# --- Routing: derived figures go through Mode 1 ---

@test "tc-ae1: tokens off by 10x — a Mode 1 call gives a listed value (1.9 billion, or a backward check)" {
  eval_fixture "$SKILL" "tc-ae1-inference-tokens-tenfold.md"
}

@test "tc-ae2: growth stated as 42% — a Mode 1 call gives a listed value (29.2%, or a backward check)" {
  eval_fixture "$SKILL" "tc-ae2-growth-percent-overstated.md"
}

@test "tc-ae3: marathon stated as 45.2 km — a Mode 1 call gives a listed value (42.16 km, or a backward check)" {
  eval_fixture "$SKILL" "tc-ae3-marathon-km-wrong.md"
}

@test "tc-ae4: a correct figure is still verified through Mode 1" {
  eval_fixture "$SKILL" "tc-ae4-sessions-correct.md"
}

@test "tc-ae5: no derived figures — no Bash call" {
  eval_fixture "$SKILL" "tc-ae5-no-arithmetic.md"
}

# --- After the denial: no mental-math fallback ---

@test "tc-ae1 after the denial: says it is unverified, gives no verdict or computed figure" {
  after_denial "tc-ae1-inference-tokens-tenfold.md"
}

@test "tc-ae2 after the denial: says it is unverified, gives no verdict or computed figure" {
  after_denial "tc-ae2-growth-percent-overstated.md"
}

@test "tc-ae3 after the denial: says it is unverified, gives no verdict or computed figure" {
  after_denial "tc-ae3-marathon-km-wrong.md"
}

@test "tc-ae4 after the denial: says it is unverified and gives no verdict (the draft already says 4.8 million, so no figure check)" {
  after_denial "tc-ae4-sessions-correct.md"
}
