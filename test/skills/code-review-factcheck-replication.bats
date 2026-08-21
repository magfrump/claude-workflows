#!/usr/bin/env bats
# @category fast
# Validates the k=3 fact-check replication contract in skills/code-review/SKILL.md
# (docs/thoughts/code-review-evaluation-state.md §1.1, decision log row 27):
#
#   A fact-check Incorrect verdict is one of the two verdict-driven blocking channels
#   (state doc §1.0: fact-check Incorrect or api-consistency Breaking) — the only one
#   reachable by documentation-class findings — and it is the least stable judgment in
#   the pipeline (Result 14a: the same defect rated Incorrect by one run and
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
  stage1_flat | grep -qE 'Incorrect \(high confidence\)`? > `?Incorrect \(medium confidence\)`? > `?Incorrect \(low confidence\)`? > `?Stale`? > `?Mostly Accurate`? > `?Unverifiable`? > `?Verified' \
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
  # reads observations a losing replicate recorded. Scoped to the cross-check section:
  # a global grep also matches the stale-replicate guard and Stage-3 audit prose, so
  # deleting the cross-check amendment would still pass (2026-07-31 review, C3).
  local section
  section=$(echo "$SKILL_CONTENT" | sed -n '/^#### Confirmed-Good cross-check/,/^#### Soundness-contradiction cross-check/p')
  [ -n "$section" ] || fail "Confirmed-Good cross-check section not found"
  echo "$section" | tr '\n' ' ' | tr -s ' ' | grep -qiE 'per-replicate report.*matched by .?Commit:' \
    || fail "the Confirmed-Good cross-check does not scan Commit-matched per-replicate reports"
}

@test "the merged-report header mandates the fields Gate 1h parses" {
  # Cross-artifact contract (2026-07-31 review, A9): Gate 1h in
  # scripts/self-improvement.sh sed-parses these literal field names; the merge
  # spec must mandate them on the MERGED report, and the gate must read them.
  stage1_flat | grep -qE '\*\*Commit:\*\* <reviewed HEAD short SHA>' \
    || fail "merge spec does not mandate the merged-report **Commit:** field"
  stage1_flat | grep -qE '\*\*Replication:\*\* k=3' \
    || fail "merge spec does not mandate the **Replication:** field"
  stage1_flat | grep -qE 'k=2 \(one replicate failed\)' \
    || fail "the degraded-path vocabulary is not stated"
  local gate="$REPO_ROOT/scripts/self-improvement.sh"
  [ -f "$gate" ] || skip "self-improvement.sh not found"
  grep -qE 'Replication:' "$gate" || fail "Gate 1h does not parse **Replication:**"
  grep -qE 'Commit:' "$gate" || fail "Gate 1h does not parse the Commit line"
}

@test "the section-extraction end anchors exist (no silent extract-to-EOF)" {
  # Tech-debt D1 (2026-07-31): if the end heading is renamed, sed extracts to EOF
  # and every scoped assertion can false-green against unrelated text.
  echo "$SKILL_CONTENT" | grep -qE '^### Fact-Check Gate' \
    || fail "stage1() end anchor '### Fact-Check Gate' missing - extraction unbounded"
}

@test "replication is loop-aware: k=1 on loop passes per decision 031, k=3 standalone" {
  # Decision 031 (config C2) overrules the blanket k=3 mandate: k=1 per pass inside
  # the review-fix loop, defensible only paired with the 2-consecutive-clean rule;
  # k=3 remains the standalone single-pass protocol (no across-pass resampling).
  stage1_flat | grep -qiE 'loop-aware \(decision 031' \
    || fail "Stage 1 does not declare loop-aware replication per decision 031"
  stage1_flat | grep -qE 'k=1 \(loop pass, decision 031\)' \
    || fail "the k=1 loop-pass Replication header vocabulary is not stated"
  stage1_flat | grep -qiE '2 consecutive clean passes|2-consecutive-clean' \
    || fail "k=1 is not tied to the 2-consecutive-clean pairing"
  stage1_flat | grep -qiE 'k=3 protocol below applies to standalone' \
    || fail "k=3 is not scoped to standalone single-pass reviews"
  echo "$SKILL_CONTENT" | sed -n '/^## Important Reminders/,$p' | tr '\n' ' ' | tr -s ' ' \
    | grep -qiE 'loop-aware \(decision 031\)' \
    || fail "Important Reminders does not carry the loop-aware replication rule"
}

@test "a rich shared brief is required and shared verbatim across replicates" {
  # MD1-R1 replication (experiment-md1-r1-replication-2026-07-30.md): lean generic
  # replicate prompts collapsed the fact-check channel (0/9 cross-file hits vs 3/3
  # under rich briefs). The brief must exist, be identical across replicates, and
  # direct verification against the code that exercises each claim.
  stage1_flat | grep -qiE 'one rich shared brief' \
    || fail "no rich-shared-brief requirement in Stage 1"
  stage1_flat | grep -qiE 'claims that particularly need checking' \
    || fail "the claims-needing-checking list is not required"
  stage1_flat | grep -qiE 'code that actually exercises it' \
    || fail "the verify-against-exercising-code directive is missing"
  stage1_flat | grep -qiE 'never brief quality' \
    || fail "the uniformity-vs-quality clarification is missing"
}

@test "annotations merge by union and survive a lost verdict contest" {
  stage1 | grep -qiE 'Replicate annotations:' \
    || fail "merged claims do not carry a Replicate annotations field"
  stage1_flat | grep -qiE 'annotations merge by union' \
    || fail "the merge step does not declare annotation union"
  stage1_flat | grep -qiE 'never dropped because its replicate lost the verdict contest' \
    || fail "the merge step does not protect losing replicates' annotations"
}

@test "replicate escalations aggregate into an Escalations section" {
  stage1 | grep -qiE '## Escalations' \
    || fail "no Escalations section required in the merged report"
  stage1_flat | grep -qiE 'routing contract' \
    || fail "the Escalations section is not declared a routing contract"
}

@test "unrouted escalations are force-surfaced by the dead-letter rule" {
  stage1_flat | grep -qiE 'Dead-letter rule' \
    || fail "no dead-letter rule for unrouted escalations"
  stage1_flat | grep -qiE 'Unrouted-Escalation' \
    || fail "unrouted escalations do not land as tagged Must Address rows"
  stage1_flat | grep -qiE '(🟡|Must Address).*terminal|terminal.*(🟡|Must Address)' \
    || fail "the dead-letter lift is not declared terminal at Must Address"
}
