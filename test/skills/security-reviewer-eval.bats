#!/usr/bin/env bats
# @category fast
# @needs-reports security-reviewer
# Evaluates security-reviewer skill output against expected severities, the
# mechanism or fix each fixture's planted defect calls for, and the absence of
# Critical/High findings on the clean negatives.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash security-reviewer
#
# Then run:
#   bats test/skills/security-reviewer-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="security-reviewer"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Injection / trust-boundary defects ---

@test "tc-sec1: ORDER BY injection — Critical/High, names SQLi or a sort allowlist" {
  eval_fixture "$SKILL" "tc-sec1-sql-injection.py"
}

@test "tc-sec3: path traversal — Critical/High, names ../ escape or a containment check" {
  eval_fixture "$SKILL" "tc-sec3-path-traversal.go"
}

@test "tc-sec6: pickle cookie — Critical, names code execution" {
  eval_fixture "$SKILL" "tc-sec6-unsafe-deserialization.py"
}

# --- Access-control defects ---

@test "tc-sec2: missing ownership check — Critical/High, names IDOR or org scoping" {
  eval_fixture "$SKILL" "tc-sec2-missing-ownership-check.ts"
}

@test "tc-sec4: fail-open auth — Critical/High, names fail-open/deny; report is well-formed" {
  eval_fixture "$SKILL" "tc-sec4-fail-open-auth.go"
}

# --- Secrets / randomness ---

@test "tc-sec5: Math.random reset token — Critical/High, names a CSPRNG" {
  eval_fixture "$SKILL" "tc-sec5-predictable-reset-token.js"
}

# --- Clean negatives ---

@test "tc-sec7: allowlisted dynamic query — no Critical/High; report is well-formed" {
  eval_fixture "$SKILL" "tc-sec7-clean-dynamic-query.ts"
}

@test "tc-sec8: argv exec with hex-validated sha — no Critical/High" {
  eval_fixture "$SKILL" "tc-sec8-clean-exec.go"
}
