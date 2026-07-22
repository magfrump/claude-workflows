#!/usr/bin/env bats
# @category fast
# Validates the structure of the arithmetic-eval SKILL.md itself.
#
# Judgment call: arithmetic-eval is a *utility* skill — it does not produce a
# standalone Markdown report. Its "output" is an inline tagged line
# ([arithmetic-eval] EXPR → RESULT) embedded in whatever other artifact Claude
# is producing (a fact-check, a cost estimate, a code review note).
#
# Because there is no report artifact to validate, this test instead verifies
# that the SKILL.md file itself contains the required structural elements that
# make the skill usable and safe:
#   - both modes (bare arithmetic, scientific computing) are documented
#   - the security allowlist and blocked-construct list are present
#   - the canonical python3 invocation pattern appears
#   - at least one worked example is shown for each mode
#   - the output-tagging convention ([arithmetic-eval]) is prescribed
#
# This is content-validation rather than report-validation. Other skill tests
# load a generated report via load_report / load_generic_report; this one
# operates directly on the SKILL.md source.
#
# Usage: bats test/skills/arithmetic-eval-format.bats

# `run !` and `run -N` are bats >= 1.5 features. Declaring the requirement makes
# bats enforce it (hard error on an older bats) instead of emitting BW02 and
# leaving it an open question whether the flag-carrying assertions really assert.
bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  SKILL_PATH="$REPO_ROOT/skills/arithmetic-eval/SKILL.md"
  if [ ! -f "$SKILL_PATH" ]; then
    skip "arithmetic-eval SKILL.md not found at $SKILL_PATH"
  fi
  SKILL_CONTENT=$(tr -d '\r' < "$SKILL_PATH")
}

# --- Frontmatter ---

@test "skill has name: arithmetic-eval in frontmatter" {
  echo "$SKILL_CONTENT" | head -20 | grep -qE '^name: arithmetic-eval$'
}

@test "skill has a description field" {
  echo "$SKILL_CONTENT" | head -30 | grep -qE '^description:'
}

@test "description mentions both modes (bare arithmetic and scientific)" {
  # Pull frontmatter body and check it references both modes
  local fm
  fm=$(echo "$SKILL_CONTENT" | awk '/^---$/ { n++; next } n==1 { print } n>=2 { exit }')
  echo "$fm" | grep -qiE '(bare arithmetic|simple.*arithmetic|numbers and operators)'
  echo "$fm" | grep -qiE 'scientific'
}

@test "skill has a when: or trigger: field" {
  local fm
  fm=$(echo "$SKILL_CONTENT" | awk '/^---$/ { n++; next } n==1 { print } n>=2 { exit }')
  echo "$fm" | grep -qE '^(when|trigger):'
}

# --- Mode documentation ---

@test "skill documents Mode 1 (bare arithmetic)" {
  echo "$SKILL_CONTENT" | grep -qiE '^## Mode 1.*Bare Arithmetic'
}

@test "skill documents Mode 2 (scientific computing)" {
  echo "$SKILL_CONTENT" | grep -qiE '^## Mode 2.*Scientific Computing'
}

# --- Canonical invocation pattern ---

@test "skill prescribes python3 -c invocation for bare arithmetic" {
  echo "$SKILL_CONTENT" | grep -qE 'python3 -c'
}

@test "skill prescribes the [arithmetic-eval] output tag" {
  echo "$SKILL_CONTENT" | grep -qF '[arithmetic-eval]'
}

@test "skill prescribes an AST allowlist evaluator for bare arithmetic" {
  # Mode 1 evaluates through a Python AST walk (no eval), not a regex or shell eval.
  echo "$SKILL_CONTENT" | grep -qE 'import ast'
  echo "$SKILL_CONTENT" | grep -qE 'ast\.parse'
  echo "$SKILL_CONTENT" | grep -qiE '(allowlist|AST)'
}

@test "bare arithmetic is fed as inert heredoc stdin, not interpolated" {
  # Security-critical: the expression must never be pasted into shell/python source.
  echo "$SKILL_CONTENT" | grep -qE "<<'EXPREOF'"
}

# --- Security ---

@test "skill has an Approved modules list" {
  echo "$SKILL_CONTENT" | grep -qiE '^#{2,4} .*Approved modules?'
}

@test "approved-modules list includes core scientific libraries" {
  # At minimum these should be named; users will lean on them most.
  echo "$SKILL_CONTENT" | grep -qE '\bnumpy\b'
  echo "$SKILL_CONTENT" | grep -qE '\bscipy\b'
  echo "$SKILL_CONTENT" | grep -qE '\bpandas\b'
  echo "$SKILL_CONTENT" | grep -qE '\bstatistics\b'
  echo "$SKILL_CONTENT" | grep -qE '\bmath\b'
}

@test "skill has a Blocked constructs section" {
  echo "$SKILL_CONTENT" | grep -qiE '^#{2,4} .*Blocked'
}

@test "static gate rejects code-execution sinks" {
  # The AST gate (check.py) bans these names/attrs so a misled script can't exec.
  echo "$SKILL_CONTENT" | grep -qE '"exec"'
  echo "$SKILL_CONTENT" | grep -qE '"eval"'
  echo "$SKILL_CONTENT" | grep -qE 'subprocess'
  echo "$SKILL_CONTENT" | grep -qE 'system'
  echo "$SKILL_CONTENT" | grep -qE '__import__'
}

@test "network egress is neutered at runtime" {
  # confine.py disables the socket layer on the non-bwrap tiers.
  echo "$SKILL_CONTENT" | grep -qE '\bsocket\b'
  echo "$SKILL_CONTENT" | grep -qiE 'network (disabled|egress)'
}

@test "filesystem writes are contained (runtime) and read-only open is the gate rule" {
  # Read-mode open() is allowed; the runtime layer blocks writes outside scratch.
  echo "$SKILL_CONTENT" | grep -qiE 'write.*(block|outside scratch)'
  echo "$SKILL_CONTENT" | grep -qE 'literal read mode'
}

@test "Mode 2 runs the gated script under an OS sandbox" {
  echo "$SKILL_CONTENT" | grep -qE '\bbwrap\b'
  echo "$SKILL_CONTENT" | grep -qE 'check\.py'
}

# --- Rules ---

@test "skill has a Rules section" {
  echo "$SKILL_CONTENT" | grep -qiE '^## Rules'
}

@test "rules forbid falling back to mental math on rejection" {
  echo "$SKILL_CONTENT" | grep -qiE '(do NOT fall back|never.*mental math|not.*mental math)'
}

# --- Examples ---

@test "skill has at least one Mode 1 worked example" {
  echo "$SKILL_CONTENT" | grep -qiE '^#{2,4} .*Example'
  # Mode 1 is a python3 -c evaluator fed by a heredoc.
  echo "$SKILL_CONTENT" | grep -qE 'python3 -c'
}

@test "skill has at least one Mode 2 worked example" {
  # Scientific example uses a throwaway mktemp dir + gated script.py (not a fixed /tmp path).
  echo "$SKILL_CONTENT" | grep -qE 'mktemp -d'
  echo "$SKILL_CONTENT" | grep -qE '\$AE/script\.py'
}

# --- No leakage of report-style scaffolding ---

@test "skill does not prescribe a report-style structure" {
  # arithmetic-eval is a utility, not a report producer. If someone adds report
  # scaffolding (Verdict/Confidence/Claim sections) the skill is being misused.
  run ! grep -qE '^## Claim [0-9]+' <<< "$SKILL_CONTENT"
  ! echo "$SKILL_CONTENT" | grep -qE '^\*\*Verdict:\*\*'
}
