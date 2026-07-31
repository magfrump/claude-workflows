#!/usr/bin/env bats
# @category fast
# Validates the Soundness-Contradiction Channel contract in skills/code-review/SKILL.md
# (docs/thoughts/code-review-evaluation-state.md §1.2, decision 028):
#
#   A correctly-reasoned soundness defect can earn neither verdict-driven promotion —
#   the fact-check correctly rates an accurate comment Verified, and nothing is
#   Breaking — so on ND2 a reviewer that reached the ground-truth defect and rejected
#   the docstring defending it still filed it 🟢 (Results 15/14a), while the human
#   panel filed the same finding 🟡 and gated the merge on it. The channel lifts a
#   finding to 🟡 when a critic report quotes both the stated intent and the code's
#   actual mechanism verbatim (file:line each) and states the inversion. It is
#   terminal at 🟡 (no blocking authority for an unvalidated mechanism), excluded
#   from escalation corroboration, and is the one exception to the contextual-critic
#   owner cap.
#
# Same enforcement rationale as code-review-assurance-contract.bats: an unenforced prose
# instruction does not execute. These tests assert the contract is stated.
#
# Usage: bats test/skills/code-review-soundness-crosscheck.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  SKILL="$REPO_ROOT/skills/code-review/SKILL.md"
  [ -f "$SKILL" ] || skip "code-review SKILL.md not found at $SKILL"
  SKILL_CONTENT=$(tr -d '\r' < "$SKILL")
}

fail() { echo "$1" >&2; return 1; }

# Emit the channel section (from its heading to the next ### heading).
channel() {
  echo "$SKILL_CONTENT" | sed -n '/^### Soundness-Contradiction Channel/,/^### Rubric Status Line/p'
}

# The section with hard wraps collapsed, for assertions that span source lines.
channel_flat() {
  channel | tr '\n' ' ' | tr -s ' '
}

@test "the Soundness-Contradiction Channel section exists" {
  echo "$SKILL_CONTENT" | grep -qE '^### Soundness-Contradiction Channel' \
    || fail "no Soundness-Contradiction Channel section in SKILL.md"
}

@test "the trigger requires verbatim quotes on both sides, each with file:line" {
  channel_flat | grep -qiE 'stated intent quoted verbatim.*path/to/file:line' \
    || fail "trigger does not require the stated intent quoted verbatim with file:line"
  channel_flat | grep -qiE 'mechanism quoted or reconstructed.*path/to/file:line' \
    || fail "trigger does not require the code mechanism quoted with file:line"
  channel_flat | grep -qiE 'defeats or inverts' \
    || fail "trigger does not require the report's own inversion reasoning"
}

@test "the precision guard bars opinion-only lifts" {
  channel_flat | grep -qiE 'intent claim alone.*never qualifies' \
    || fail "no precision guard barring an intent claim alone"
  channel_flat | grep -qiE 'never from any critic.s internal severity label' \
    || fail "the guard does not bar keying on a critic's severity label"
}

@test "a qualifying finding lands in Must Address with the fixed vocabulary" {
  channel | grep -qE 'Severity: Contested-Soundness' \
    || fail "the fixed Severity vocabulary (Contested-Soundness) is not stated"
  channel_flat | grep -qE 'Source: Soundness cross-check \(found by <critic>\)' \
    || fail "the Source attribution (found by <critic>) is not stated"
  channel_flat | grep -qiE 'Must Address' \
    || fail "the destination tier (🟡 Must Address) is not named"
}

@test "🟡 is terminal: never promoted to 🔴, excluded from escalation corroboration" {
  channel_flat | grep -qiE 'terminal tier for this channel' \
    || fail "🟡 is not declared the terminal tier"
  channel_flat | grep -qiE 'never promoted to 🔴' \
    || fail "the no-🔴 rule is not stated"
  channel_flat | grep -qiE 'does not count as corroboration' \
    || fail "the channel is not excluded from escalation corroboration"
}

@test "the owner-cap exception applies regardless of which critic filed the finding" {
  channel_flat | grep -qiE 'regardless of which critic filed' \
    || fail "the channel does not apply regardless of the filing critic"
  channel_flat | grep -qiE 'one path by which a contextual-critic finding leaves 🟢' \
    || fail "the channel is not named the sole exit from the contextual 🟢 cap"
}

@test "the advisory rule names the exception, and the escalation rule excludes the lift" {
  echo "$SKILL_CONTENT" | tr '\n' ' ' | grep -qiE 'Contextual critics are advisory:.{0,700}Soundness-Contradiction Channel' \
    || fail "the 'Contextual critics are advisory' rule does not name the exception"
  # The Escalation Rule's contextual paragraph must exclude the lift from corroboration.
  echo "$SKILL_CONTENT" | sed -n '/^### Escalation Rule/,/^### Soundness-Contradiction Channel/p' \
    | tr '\n' ' ' | grep -qiE 'lifted to 🟡 by the \[Soundness-Contradiction Channel\].*does not count as escalation corroboration' \
    || fail "the Escalation Rule does not exclude Soundness lifts from corroboration"
}

@test "Stage 3 runs the soundness cross-check before producing deliverables" {
  echo "$SKILL_CONTENT" | grep -qE '^#### Soundness-contradiction cross-check \(required before producing deliverables\)' \
    || fail "Stage 3 has no required soundness cross-check step"
  echo "$SKILL_CONTENT" | sed -n '/^#### Soundness-contradiction cross-check/,/^#### /p' \
    | tr '\n' ' ' | grep -qiE 'before.*writing either deliverable' \
    || fail "the Stage-3 step does not run before the deliverables are written"
}

@test "the lift is named in the chat synthesis" {
  channel_flat | grep -qiE 'Name the lift in the chat synthesis' \
    || fail "lifts are not required to be named in the chat synthesis"
}

@test "the validation falsifier and the cap-lift bar are stated" {
  # Unvalidated mechanisms get no blocking authority; the negative controls are named.
  channel_flat | grep -qiE 'unvalidated mechanisms get no blocking authority' \
    || fail "the no-blocking-authority rationale is not stated"
  channel_flat | grep -qiE 'sim\.ts:625-628|proxy\.ts:14' \
    || fail "the negative controls (ND3 fixed docstring / md1 proxy.ts:14) are not named"
  channel_flat | grep -qiE 'until that passes.*🟡 cap must not be lifted' \
    || fail "the bar against lifting the 🟡 cap before validation is not stated"
}
