#!/usr/bin/env bats
# @category fast
# Validates the Executable-Defect Channel contract in skills/code-review/SKILL.md
# (docs/working/fn-trace-skill-levers-2026-08-21.md, lever 4):
#
#   Two e8 benchmark misses were findings the pipeline found and correctly diagnosed,
#   then demoted to 🟢 by provenance rules alone — a Critical-rated invalid ERB template
#   whose critic had itself named the one-command verification, and a unanimous
#   fact-check top-risk claim demoted because its verdict was Unverifiable. The channel
#   grants an evidence-gated lift (mirroring the Soundness-Contradiction Channel), and
#   the mapping change makes Unverifiable an evidence state rather than a severity.
#
# Same enforcement rationale as code-review-soundness-crosscheck.bats: an unenforced
# prose instruction does not execute. These tests assert the contract is stated.
#
# Usage: bats test/skills/code-review-executable-defect.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  SKILL="$REPO_ROOT/skills/code-review/SKILL.md"
  [ -f "$SKILL" ] || skip "code-review SKILL.md not found at $SKILL"
  SKILL_CONTENT=$(tr -d '\r' < "$SKILL")
  FLAT=$(echo "$SKILL_CONTENT" | tr '\n' ' ' | tr -s ' ')
}

fail() { echo "$1" >&2; return 1; }

# Emit the channel section (from its heading to the next ### heading).
channel() {
  echo "$SKILL_CONTENT" | sed -n '/^### Executable-Defect Channel/,/^### Rubric Status Line/p'
}

channel_flat() {
  channel | tr '\n' ' ' | tr -s ' '
}

@test "the Executable-Defect Channel section exists" {
  echo "$SKILL_CONTENT" | grep -qE '^### Executable-Defect Channel' \
    || fail "no Executable-Defect Channel section"
}

@test "the trigger requires determinism, a named sandbox verification, and a quoted mechanism" {
  channel_flat | grep -qiE 'deterministic.*failure' \
    || fail "trigger does not require a deterministic failure"
  channel_flat | grep -qiE 'concrete verification executable in the review sandbox' \
    || fail "trigger does not require a named sandbox-executable verification"
  channel | grep -qE 'path/to/file:line' \
    || fail "trigger does not require the mechanism quoted with path:line"
}

@test "the verification is run first with executed-mode provenance" {
  channel_flat | grep -qiE 'run the verification first' \
    || fail "the channel does not run the verification before placing the finding"
  channel_flat | grep -qiE 'command, cwd, exit code, timestamp' \
    || fail "executed-mode provenance requirements are not carried"
}

@test "confirmed findings map by native severity; unexecutable ones lift to terminal amber" {
  channel_flat | grep -qiE 'native severity as if filed by a core critic' \
    || fail "a confirmed defect does not map by native severity"
  channel_flat | grep -qiE 'Unexecuted-Deterministic' \
    || fail "no Unexecuted-Deterministic severity tag for the blocked-execution path"
  channel_flat | grep -qiE '🟡 is terminal on this path' \
    || fail "the unexecuted lift is not declared terminal at amber"
}

@test "a refuted finding is never lifted" {
  channel_flat | grep -qiE 'Refutes the finding.*no lift' \
    || fail "the refutation path is missing or lifts anyway"
}

@test "the precision guard excludes unnamed-trigger failures" {
  channel_flat | grep -qiE 'cannot name concretely does not qualify' \
    || fail "no precision guard against vague might-crash findings"
}

@test "Stage 3 carries the executable-defect cross-check as a required pre-deliverable pass" {
  echo "$SKILL_CONTENT" | grep -qE '^#### Executable-defect cross-check \(required before producing deliverables\)' \
    || fail "no required executable-defect cross-check in Stage 3"
  FLAT_XC=$(echo "$SKILL_CONTENT" | sed -n '/^#### Executable-defect cross-check/,/^#### Contrastive note/p' | tr '\n' ' ' | tr -s ' ')
  echo "$FLAT_XC" | grep -qiE 'unattempted verification.*skipped required check' \
    || fail "the cross-check does not make unattempted verifications a skipped check"
}

@test "Unverifiable is declared an evidence state, not a severity" {
  echo "$FLAT" | grep -qiE 'Unverifiable is an evidence state, not a severity' \
    || fail "the severity-mapping does not carry the Unverifiable evidence-state rule"
  echo "$FLAT" | grep -qiE 'Unverified-High-Risk' \
    || fail "no Unverified-High-Risk mapping for blocking-grade Unverifiable claims"
}

@test "both contextual-critic exit paths are named and exclusive" {
  echo "$FLAT" | grep -qiE 'the only paths by which a contextual-critic finding leaves' \
    || fail "the advisory rule does not enumerate its exit paths exclusively"
}
