#!/usr/bin/env bats
# Evaluates code-fact-check skill output against expected verdicts and behavioral checks.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash code-fact-check
#
# Then run:
#   bats test/skills/code-fact-check-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="code-fact-check"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Category 1: Claim Type Coverage ---

@test "tc-c1.1: behavioral — catches null vs undefined" {
  eval_fixture "$SKILL" "tc-c1.1-behavioral.js"
}

@test "tc-c1.2: performance — catches O(n) vs O(n^2)" {
  eval_fixture "$SKILL" "tc-c1.2-performance.js"
}

@test "tc-c1.3: architectural — catches false 'only caller' claim" {
  eval_fixture "$SKILL" "tc-c1.3-architectural.js"
}

@test "tc-c1.4: invariant — catches optional chaining nullability" {
  eval_fixture "$SKILL" "tc-c1.4-invariant.js"
}

@test "tc-c1.5: configuration — verifies 300s = 5min" {
  eval_fixture "$SKILL" "tc-c1.5-configuration.js"
}

@test "tc-c1.6: reference — checks issue existence" {
  eval_fixture "$SKILL" "tc-c1.6-reference.js"
}

@test "tc-c1.7: staleness — catches renamed function" {
  eval_fixture "$SKILL" "tc-c1.7-staleness.js"
}

# --- Category 2: Verdict Distribution ---

@test "tc-c2.1: verified — confirms TypeError on empty input" {
  eval_fixture "$SKILL" "tc-c2.1-verified.js"
}

@test "tc-c2.2: mostly accurate — catches sort making O(n log n)" {
  eval_fixture "$SKILL" "tc-c2.2-mostly-accurate.js"
}

@test "tc-c2.3: stale — catches 5 vs 3 retries" {
  eval_fixture "$SKILL" "tc-c2.3-stale.js"
}

@test "tc-c2.4: incorrect — catches throw vs create mismatch" {
  eval_fixture "$SKILL" "tc-c2.4-incorrect.js"
}

@test "tc-c2.5: unverifiable — thread-safety cannot be statically confirmed" {
  eval_fixture "$SKILL" "tc-c2.5-unverifiable.py"
}

# --- Category 4: Non-Checkable Content ---

@test "tc-c4: skip targets — design rationale, TODOs, etc. not checked" {
  eval_fixture "$SKILL" "tc-c4-skip-targets.js"
}

# --- Category 5: Ambiguity Handling ---

@test "tc-c5.1: partial thread safety — reports both local safety and shared-state concern" {
  eval_fixture "$SKILL" "tc-c5.1-thread-safety-partial.py"
}

@test "tc-c5.2: intended vs actual — checks against actual behavior (2 retries)" {
  eval_fixture "$SKILL" "tc-c5.2-intended-vs-actual.js"
}

# --- Category 6: Output Format ---

@test "tc-c6.1: multi-claim — has at least 5 claims and passes format check" {
  eval_fixture "$SKILL" "tc-c6.1-multi-claim.js"
}
