#!/usr/bin/env bats
# @category fast
# Validates the two ASSURANCE contracts in skills/code-review/SKILL.md that the
# measurement program established as missing (docs/thoughts/code-review-evaluation-state.md):
#
#   §1.3  ✅ Confirmed Good is a claim requiring evidence, cross-checked against the
#         fact-check report. On the MD1 diff two of three model tiers filed the branch's
#         actual blocking defect under Confirmed Good, and in one of them the
#         disconfirming observation was recorded verbatim in that same run's own
#         fact-check report.
#   §1.4  A single run's clean verdict is one sample, not an attestation. 🔴-band
#         self-agreement across replicates is 0.14–0.25.
#
# Both contracts live in prose, and this repo's standing evidence (the override log that
# went unwritten for nine runs because only prose asked for it) is that an unenforced
# instruction does not execute. These tests are the enforcement. They assert the *contract*
# is stated; the rubric shape it implies is asserted against the golden fixture in
# test/skills/code-review-format-contract.bats.
#
# Usage: bats test/skills/code-review-assurance-contract.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  SKILL="$REPO_ROOT/skills/code-review/SKILL.md"
  [ -f "$SKILL" ] || skip "code-review SKILL.md not found at $SKILL"
  SKILL_CONTENT=$(tr -d '\r' < "$SKILL")
}

fail() { echo "$1" >&2; return 1; }

# Emit one "### <heading>" section, excluding the next heading line.
subsection() {
  echo "$SKILL_CONTENT" | sed -n "/^#\+ .*$1/,/^### /p" | sed '$d'
}

# ---------------------------------------------------------------
# §1.3 — Confirmed Good must carry evidence
# ---------------------------------------------------------------

@test "the skill has a Confirmed-Good claim section" {
  echo "$SKILL_CONTENT" | grep -qiE '^### Confirmed Good is a claim, not an output' \
    || fail "no '### Confirmed Good is a claim, not an output' section in $SKILL"
}

@test "the rubric template's Confirmed Good table carries an Evidence column" {
  # Guards the template directly. The golden-vs-template sync test in
  # code-review-format-contract.bats guards that the fixture keeps up with it.
  echo "$SKILL_CONTENT" \
    | grep -qE '^\|[[:space:]]*Item[[:space:]]*\|[[:space:]]*Verdict[[:space:]]*\|[[:space:]]*Evidence[[:space:]]*\|' \
    || fail "Confirmed Good template table has no Evidence column"
}

@test "Confirmed Good evidence reuses the Evidence-grounding format, not a second one" {
  # The failure mode this guards is a parallel citation vocabulary that no checker knows.
  subsection 'Confirmed Good is a claim' | grep -qiE 'Evidence grounding' \
    || fail "the Confirmed-Good section does not defer to the Evidence-grounding format"
}

@test "an ungrounded Confirmed Good row is dropped, not filed as an Unverified Finding" {
  # ⚠️ Unverified Findings is the demotion channel for would-be 🔴/🟡 findings. A
  # confirmation that cannot be grounded is not a finding at all.
  local s
  s=$(subsection 'Confirmed Good is a claim')
  echo "$s" | grep -qiE 'Unverified Findings' \
    || fail "the section does not say what happens to an ungrounded row"
  echo "$s" | grep -qiE '(drop|delete)' \
    || fail "the section does not require dropping an ungrounded row"
}

@test "universally quantified confirmations require an enumeration, not one instance" {
  subsection 'Confirmed Good is a claim' | grep -qiE 'enumeration' \
    || fail "no enumeration requirement for exhaustiveness claims"
}

@test "Stage 3 runs a Confirmed-Good cross-check before the deliverables" {
  echo "$SKILL_CONTENT" | grep -qiE '^#+ Confirmed-Good cross-check' \
    || fail "Stage 3 has no Confirmed-Good cross-check step"
  echo "$SKILL_CONTENT" | grep -qiE '^#+ Confirmed-Good cross-check.*before producing deliverables' \
    || fail "the cross-check is not pinned to run before the deliverables are written"
}

@test "the cross-check reads the fact-check report, including incidental observations" {
  local s
  s=$(subsection 'Confirmed Good is a claim')
  echo "$s" | grep -qiE 'fact-check report' \
    || fail "the cross-check does not name the fact-check report as its source"
  # The observed miss was a contradicting detail recorded in passing under a claim the
  # fact-check itself marked Verified — scanning only the "problem" verdicts misses it.
  echo "$s" | grep -qiE '(in passing|different claim|marked Verified)' \
    || fail "the cross-check does not cover observations outside the flagged verdicts"
}

@test "a contradicted confirmation is neither silently dropped nor silently promoted" {
  local s
  s=$(subsection 'Confirmed Good is a claim')
  echo "$s" | grep -qE '🟡 Must Address' \
    || fail "no destination tier specified for a contradicted confirmation"
  echo "$s" | grep -qE 'Contested' \
    || fail "no severity specified for a contradicted confirmation"
  echo "$s" | grep -qE '🔴' \
    || fail "the section does not say whether a contested row can reach 🔴"
  echo "$s" | grep -qiE 'chat synthesis' \
    || fail "a revoked confirmation is not required to be surfaced in the synthesis"
}

@test "the contested-confirmation channel does not feed the escalation rule" {
  # Escalation is a separate, deliberately conservative mechanism; a revoked over-claim
  # must not become a back door into blocking status.
  subsection 'Confirmed Good is a claim' \
    | grep -qiE 'not count as corroboration|does not count as corroboration' \
    || fail "the section does not exclude contested rows from escalation corroboration"
}

@test "Important Reminders carries the Confirmed-Good contract" {
  echo "$SKILL_CONTENT" | sed -n '/^## Important Reminders/,$p' \
    | grep -qiE 'Confirmed Good.*claim, not an output' \
    || fail "Important Reminders does not carry the Confirmed-Good contract"
}

# ---------------------------------------------------------------
# §1.4 — a single run's clean verdict is not an attestation
# ---------------------------------------------------------------

LABEL='absence of findings is not an attestation'

@test "the passing status line carries the single-sample label" {
  echo "$SKILL_CONTENT" | grep -qE "Status: ✅ PASSES REVIEW\*\* — single-sample review; $LABEL" \
    || fail "the ✅ PASSES REVIEW status line does not carry the single-sample label"
}

@test "the chat synthesis carries the label when the run is clean" {
  local s
  s=$(echo "$SKILL_CONTENT" | sed -n '/Single-sample label (required when the run is clean)/,/^Choose exactly one/p')
  [ -n "$s" ] || fail "no single-sample label requirement in the chat-synthesis spec"
  echo "$s" | grep -qiE 'merge' \
    || fail "the label is not tied to the clean/merge next action"
  echo "$s" | grep -qF "$LABEL" \
    || fail "the chat-synthesis label text does not match the standing label"
}

@test "the label cites the replicate-disagreement evidence behind it" {
  echo "$SKILL_CONTENT" | grep -qE '0\.14–0\.25|0\.14-0\.25' \
    || fail "the single-sample label is asserted without its measured basis"
}

@test "the hedging stays proportionate — a standing label, not a paragraph everywhere" {
  # Deliberately loose upper bound. The point is to catch the label metastasizing into
  # per-section hedging, which would dilute it exactly where it is load-bearing.
  local n
  n=$(echo "$SKILL_CONTENT" | grep -cF "$LABEL" || true)
  [ "$n" -ge 2 ] || fail "the label appears $n time(s); expected it on both the status line and the synthesis"
  [ "$n" -le 6 ] || fail "the label appears $n times — that is hedging, not a standing label"
}

@test "the label is not attached to a failing verdict" {
  # `run !` rather than a bare `!`: a leading `!` on a non-final command does not
  # fail a bats test, so the bare form would assert nothing (SC2314).
  run ! grep -qE "DOES NOT PASS.*$LABEL" "$SKILL"
  run ! grep -qE "CONDITIONAL PASS.*$LABEL" "$SKILL"
}
