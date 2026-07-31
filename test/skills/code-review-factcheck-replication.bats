#!/usr/bin/env bats
# @category fast
# Validates the k=3 fact-check replication contract in skills/code-review/SKILL.md
# (docs/thoughts/code-review-evaluation-state.md §1.1, decision log row 26):
#
#   The fact-check verdict is the pipeline's only 🔴-promotion channel and is the least
#   stable judgment in it (Result 14a: the same defect rated Incorrect by one run and
#   Mostly Accurate by another, on identical input). Stage 1 therefore runs three
#   replicates on byte-identical prompts and merges most-severe-wins, logging
#   per-replicate verdicts so the disagreement rate is a tracked metric.
#
# Same enforcement rationale as code-review-assurance-contract.bats: an unenforced prose
# instruction does not execute. These tests assert the contract is stated.
#
# Usage: bats test/skills/code-review-factcheck-replication.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  SKILL="$REPO_ROOT/skills/code-review/SKILL.md"
  [ -f "$SKILL" ] || skip "code-review SKILL.md not found at $SKILL"
  SKILL_CONTENT=$(tr -d '\r' < "$SKILL")
}

fail() { echo "$1" >&2; return 1; }

# Emit the Stage 1 section (from its heading to the next ### heading).
stage1() {
  echo "$SKILL_CONTENT" | sed -n '/^### Stage 1: Code Fact-Check/,/^### Fact-Check Gate/p'
}

# Stage 1 with hard wraps collapsed, for assertions that span source lines.
stage1_flat() {
  stage1 | tr '\n' ' ' | tr -s ' '
}

@test "Stage 1 runs the fact-check as three replicates" {
  echo "$SKILL_CONTENT" | grep -qE '^### Stage 1: Code Fact-Check \(k=3 replicated\)' \
    || fail "Stage 1 heading does not declare k=3 replication"
  stage1 | grep -qiE 'Spawn \*\*three\*\* agents' \
    || fail "Stage 1 does not spawn three fact-check agents"
}

@test "replicate prompts are byte-identical except the output path" {
  stage1 | grep -qiE 'byte-identical' \
    || fail "Stage 1 does not require byte-identical replicate prompts"
  stage1 | grep -qiE 'only.*(difference|permitted).*|(difference|permitted).*only' \
    || fail "Stage 1 does not pin the output path as the only permitted prompt difference"
}

@test "replicates write per-replicate report paths and the merged report is canonical" {
  stage1 | grep -qE 'code-fact-check-report-r<N>\.md' \
    || fail "no per-replicate report path in Stage 1"
  stage1 | grep -qE 'code-fact-check-report\.md' \
    || fail "the canonical merged report path is not named"
  # The Output Locations tree must list the replicate files so they persist for audit.
  echo "$SKILL_CONTENT" | grep -qE 'code-fact-check-report-r1\.md' \
    || fail "Output Locations does not list the replicate reports"
}

@test "the merge aggregator is most-severe-wins, not majority" {
  stage1 | grep -qiE 'most.severe' \
    || fail "no most-severe-wins rule in the merge step"
  stage1_flat | grep -qiE 'majority vote is explicitly the wrong aggregator' \
    || fail "the merge step does not reject majority vote as the aggregator"
}

@test "the severity order is stated and runs Incorrect-high first, Verified last" {
  # The order is load-bearing: it defines what 'most severe' means mechanically.
  stage1_flat | grep -qE 'Incorrect \(high confidence\)`? > `?Incorrect \(medium confidence\)`? > `?Stale`? > `?Mostly Accurate`? > `?Unverifiable`? > `?Verified' \
    || fail "the verdict severity order is missing or misordered"
}

@test "every merged claim records per-replicate verdicts" {
  stage1 | grep -qiE 'Replicate verdicts:' \
    || fail "merged claims do not carry a per-replicate verdict line"
}

@test "the merged report ends with a Verdict stability section reporting the agreement rate" {
  stage1 | grep -qiE '## Verdict stability' \
    || fail "no Verdict stability section required in the merged report"
  stage1 | grep -qiE 'agreement rate' \
    || fail "the disagreement/agreement rate is not a required output"
}

@test "the k-reduction falsifier is stated (>=90% agreement on >=20 claims -> k=2)" {
  stage1 | grep -qiE '90%.*20|≥90%.*≥20' \
    || fail "§1.1's falsifier (agreement >=90% on a >=20-claim sample drops k to 2) is not carried"
}

@test "fewer than two substantive replicates blocks the merge" {
  stage1_flat | grep -qiE 'at least \*{0,2}two\*{0,2} substantive' \
    || fail "the checkpoint does not require at least two substantive reports"
}

@test "the Confirmed-Good cross-check scans the per-replicate reports too" {
  # Decision 25 marked this the out-of-scope gap; k=3 closes it only if the cross-check
  # reads observations a losing replicate recorded.
  echo "$SKILL_CONTENT" | grep -qE 'code-fact-check-report-r\*\.md' \
    || fail "the Confirmed-Good cross-check does not name the per-replicate reports"
}
