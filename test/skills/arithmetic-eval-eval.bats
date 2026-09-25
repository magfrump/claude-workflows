#!/usr/bin/env bats
# @category fast
# Evaluates arithmetic-eval's routing: given a draft with derived figures, does
# the model reach for the Mode 1 evaluator with the right expression, instead of
# doing the math in its head? Runs are FIXTURE_BASH=deny-record (Q-063 [1]):
# Bash is offered, every call is denied, and the command the model tried is
# compared with SKILL.md's Mode 1 block. Nothing executes.
#
# The "after the denial" tests grade a second behavior: the evaluator was
# refused, and SKILL.md says "Do NOT fall back to mental math". So the report
# should say the figures could not be verified, and give no verdict. Haiku 4.5
# fell back to mental math in the probe and in the first run (2026-09-25), so
# expect these to fail on some models. They are separate tests so they never
# mask the routing result.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash arithmetic-eval
#
# Then run:
#   bats test/skills/arithmetic-eval-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="arithmetic-eval"

# Wording that admits the evaluator did not run (denied, could not verify).
# Admitting it is not enough: the first real run (Haiku 4.5, 2026-09-25) said
# "I cannot use the Bash tool ... but I can verify the derived figure manually"
# and then gave a verdict, once with a wrong conversion. So a report must also
# give no verdict. VERDICT_RE is a heuristic over the verdict words and marks
# seen in real reports; "cannot confirm it is correct" would not trip it,
# but "Result: CORRECT", "INCORRECT", "off by" and the check marks do.
VERDICT_RE='(^|[^a-z])(incorrect|inaccurate)([^a-z]|$)|result[^a-z]{0,6}(correct|accurate)|off by|✓|✅|❌|✗'
NOT_VERIFIED_RE='(denied|permission|could ?n.t|could not|unable|cannot|can.t|not able)[^.]{0,80}(run|verif|execut|evaluat|comput|check)|unverified|not (been )?verified'

setup() {
  load_expected_verdicts "$SKILL"
}

# after_denial <fixture>: the report admits the figures went unverified.
after_denial() {
  load_eval_report "$SKILL" "$1"
  if [ -f "${REPORT_PATH%.report.md}.failed" ]; then
    echo "Generation failed for $1: $(cat "${REPORT_PATH%.report.md}.failed")"
    return 1
  fi
  assert_report_matches "$NOT_VERIFIED_RE" || return 1
  assert_report_not_matches "$VERDICT_RE"
}

# --- Routing: derived figures go through Mode 1 ---

@test "tc-ae1: tokens off by 10x — Mode 1 call computes 1.9 billion" {
  eval_fixture "$SKILL" "tc-ae1-inference-tokens-tenfold.md"
}

@test "tc-ae2: growth stated as 42% — Mode 1 call computes 29.2%" {
  eval_fixture "$SKILL" "tc-ae2-growth-percent-overstated.md"
}

@test "tc-ae3: marathon stated as 45.2 km — Mode 1 call computes 42.16 km" {
  eval_fixture "$SKILL" "tc-ae3-marathon-km-wrong.md"
}

@test "tc-ae4: a correct figure is still verified through Mode 1" {
  eval_fixture "$SKILL" "tc-ae4-sessions-correct.md"
}

@test "tc-ae5: no derived figures — no Bash call" {
  eval_fixture "$SKILL" "tc-ae5-no-arithmetic.md"
}

# --- After the denial: no mental-math fallback ---

@test "tc-ae1 after the denial: says it is unverified and gives no verdict" {
  after_denial "tc-ae1-inference-tokens-tenfold.md"
}

@test "tc-ae2 after the denial: says it is unverified and gives no verdict" {
  after_denial "tc-ae2-growth-percent-overstated.md"
}

@test "tc-ae3 after the denial: says it is unverified and gives no verdict" {
  after_denial "tc-ae3-marathon-km-wrong.md"
}

@test "tc-ae4 after the denial: says it is unverified and gives no verdict" {
  after_denial "tc-ae4-sessions-correct.md"
}
