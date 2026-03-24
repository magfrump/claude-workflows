#!/usr/bin/env bats
# Evaluates fact-check skill output against expected verdicts and behavioral checks.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash fact-check
#
# Then run:
#   bats test/skills/fact-check-eval.bats
#
# Individual fixture:
#   bats test/skills/fact-check-eval.bats --filter "tc-2.4"
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal that the new model's fact-checking behavior differs.

load eval-helpers

SKILL="fact-check"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Category 1: Claim Type Coverage ---

@test "tc-1.1: specific numbers — cites CMS/BEA data with web search" {
  eval_fixture "$SKILL" "tc-1.1-specific-numbers.md"
}

@test "tc-1.2: named policies — looks up actual SB 458 text" {
  eval_fixture "$SKILL" "tc-1.2-named-policies.md"
}

@test "tc-1.3: attributed facts — confirms MN cannabis legalization" {
  eval_fixture "$SKILL" "tc-1.3-attributed-facts.md"
}

@test "tc-1.4: causal claims — checks both magnitude and causal link" {
  eval_fixture "$SKILL" "tc-1.4-causal-claims.md"
}

@test "tc-1.5: comparisons — checks OECD pre-K data" {
  eval_fixture "$SKILL" "tc-1.5-comparisons.md"
}

@test "tc-1.6: anecdotes — marks unverifiable without fabricating" {
  eval_fixture "$SKILL" "tc-1.6-anecdotes.md"
}

# --- Category 2: Verdict Distribution ---

@test "tc-2.1: accurate — high confidence, cites Census Bureau" {
  eval_fixture "$SKILL" "tc-2.1-accurate.md"
}

@test "tc-2.2: mostly accurate — explains conflated surveys" {
  eval_fixture "$SKILL" "tc-2.2-mostly-accurate.md"
}

@test "tc-2.3: disputed — cites both UW and Berkeley studies" {
  eval_fixture "$SKILL" "tc-2.3-disputed.md"
}

@test "tc-2.4: inaccurate — France restricted, not banned" {
  eval_fixture "$SKILL" "tc-2.4-inaccurate.md"
}

@test "tc-2.5: unverified — does not fabricate source" {
  eval_fixture "$SKILL" "tc-2.5-unverified.md"
}

# --- Category 3: Non-Checkable Content ---

@test "tc-3.1: opinions — few or zero claims checked" {
  eval_fixture "$SKILL" "tc-3.1-opinions.md"
}

@test "tc-3.2: predictions — not treated as checkable" {
  eval_fixture "$SKILL" "tc-3.2-predictions.md"
}

@test "tc-3.3: mixed — checks only checkable claims (3-5)" {
  eval_fixture "$SKILL" "tc-3.3-mixed.md"
}

# --- Category 4: Ambiguity Handling ---

@test "tc-4.1: misleading — flags ambiguity in 'best healthcare'" {
  eval_fixture "$SKILL" "tc-4.1-misleading.md"
}

@test "tc-4.2: conflated stats — detects survey conflation" {
  eval_fixture "$SKILL" "tc-4.2-conflated-stats.md"
}

# --- Category 5: Output Format ---

@test "tc-5.1: multi-claim — has at least 3 claims and passes format check" {
  eval_fixture "$SKILL" "tc-5.1-multi-claim.md"
}

# --- Category 6: Behavioral Guardrails ---

@test "tc-6.1: accurate weak argument — no critique leakage" {
  eval_fixture "$SKILL" "tc-6.1-accurate-weak-argument.md"
}

@test "tc-6.3: obvious but wrong — catches Great Wall myth" {
  eval_fixture "$SKILL" "tc-6.3-obvious-but-wrong.md"
}

# --- Category 7: Edge Cases / Negative Test Fixtures ---

@test "tc-7.1: empty file — gracefully declines with zero claims" {
  eval_fixture "$SKILL" "tc-7.1-empty.md"
}

@test "tc-7.2: no checkable claims — zero claims from meeting notes" {
  eval_fixture "$SKILL" "tc-7.2-no-claims.md"
}

@test "tc-7.3: binary content — gracefully declines non-prose input" {
  eval_fixture "$SKILL" "tc-7.3-binary-content.md"
}

@test "tc-7.4: extremely short — no specific claim to check" {
  eval_fixture "$SKILL" "tc-7.4-extremely-short.md"
}
