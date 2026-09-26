#!/usr/bin/env bats
# @category fast
# @needs-reports self-eval
# Evaluates self-eval output: each planted fixture scores its one weak dimension
# Weak (test coverage, overlap, trigger clarity); a well-tested distinct skill is
# not marked Weak on test coverage or overlap; and with no rubric in the repo
# the skill stops instead of scoring from memory.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash self-eval
#
# Then run:
#   bats test/skills/self-eval-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="self-eval"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted weaknesses ---

@test "tc-se1: no tests, no outputs — Test coverage Weak; report is well-formed" {
  eval_fixture "$SKILL" "tc-se1-no-tests-no-outputs"
}

@test "tc-se2: duplicates sql-migration-review — Overlap Weak, names the sibling; report is well-formed" {
  eval_fixture "$SKILL" "tc-se2-duplicates-migration-review"
}

@test "tc-se3: 'use when helpful' trigger — Trigger clarity Weak; report is well-formed" {
  eval_fixture "$SKILL" "tc-se3-vague-trigger"
}

# --- Negatives ---

@test "tc-se4: tested, with example output, distinct — Test coverage Strong/Adequate, no Weak on coverage or overlap" {
  eval_fixture "$SKILL" "tc-se4-well-tested-distinct"
}

@test "tc-se5: rubric missing — stops with the repo-only message, scores nothing" {
  eval_fixture "$SKILL" "tc-se5-rubric-missing"
}
