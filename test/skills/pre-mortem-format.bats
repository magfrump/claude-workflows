#!/usr/bin/env bats
# @category fast
# Validates the output format of pre-mortem reports.
#
# Note: No example report is committed — tests will skip via load_generic_report
# if REPORT_PATH (or the default path) does not exist.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/pre-mortem.md bats test/skills/pre-mortem-format.bats

# `run !` and `run -N` are bats >= 1.5 features. Declaring the requirement makes
# bats enforce it (hard error on an older bats) instead of emitting BW02 and
# leaving it an open question whether the flag-carrying assertions really assert.
bats_require_minimum_version 1.5.0

load helpers

setup() {
  load_generic_report "${REPORT_PATH:-docs/reviews/pre-mortem.md}"
}

# --- Header block ---

@test "report has a title header with Pre-Mortem" {
  assert_title_matches '^# .*Pre.?Mortem' 10
}

@test "report has a Proposal field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Proposal:\*\*'
}

@test "report has a Date field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Date:\*\*'
}

@test "report names the upstream what-if analysis used (or 'none')" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Upstream what-if analysis:\*\*'
}

# --- Failure narratives: per-narrative fields ---

@test "narratives include a Root cause field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Root cause:\*\*'
}

@test "narratives include a Chain of consequences field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Chain of consequences:\*\*'
}

@test "narratives include an Observable outcome field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Observable outcome:\*\*'
}

@test "narratives include Plausibility values from the allowed vocabulary" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Plausibility:\*\*.*\b(Likely|Plausible|Unlikely-but-catastrophic|Unlikely)\b'
}

@test "narratives include Severity values from the allowed vocabulary" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Severity:\*\*.*\b(Low|Medium|High|Catastrophic)\b'
}

# --- Required closing action line on narratives ---

@test "narratives include a required closing action line (Mitigation or Revisit trigger)" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*(Mitigation|Revisit trigger):\*\*'
}

@test "Plausibility values use only the allowed vocabulary" {
  local values bad
  values=$(echo "$REPORT_CONTENT" | sed -n 's/^[*-]* *\*\*Plausibility:\*\* //p')
  [ -n "$values" ] || skip "no Plausibility values found"
  bad=$(echo "$values" | grep -viE '^(Likely|Plausible|Unlikely-but-catastrophic)$' || true)
  [ -z "$bad" ]
}

@test "Severity values use only the allowed vocabulary" {
  local values bad
  values=$(echo "$REPORT_CONTENT" | sed -n 's/^[*-]* *\*\*Severity:\*\* //p')
  [ -n "$values" ] || skip "no Severity values found"
  bad=$(echo "$values" | grep -viE '^(Low|Medium|High|Catastrophic)$' || true)
  [ -z "$bad" ]
}

# --- Recommendations section and its groupings ---

@test "report has a Recommendations section" {
  assert_heading_exists "Recommendations"
}

@test "recommendations distinguish blockers from acknowledged risks" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Recommendations/,/^## /p')
  # Fallback: section may run to end of file
  if [ -z "$section" ]; then
    section=$(echo "$REPORT_CONTENT" | sed -n '/^## Recommendations/,$p')
  fi
  echo "$section" | grep -qiE '(must address|worth mitigating|acknowledged risks?|no.*must address)'
}

# --- Guard against generic, disallowed closing lines ---

@test "closing action lines avoid the disallowed generic phrasings" {
  # The skill explicitly disallows these as closing-line bodies because they do
  # not wire the narrative to an executable artifact. A passing mention elsewhere
  # is fine; flag only when they are the body of a Mitigation/Revisit line.
  ! echo "$REPORT_CONTENT" | grep -qiE '\*\*(Mitigation|Revisit trigger):\*\* (monitor in production|watch this carefully|keep an eye on it|be careful during rollout|document this)\.?\s*$'
}

# --- No leakage from what-if-analysis sibling ---

@test "report does not contain what-if-analysis structural sections" {
  # what-if-analysis is the prospective sibling; pre-mortem is narrative-retrospective.
  run ! grep -qiE '^## .*Assumptions Examined' <<< "$REPORT_CONTENT"
  run ! grep -qiE '^## .*Consequence Chains' <<< "$REPORT_CONTENT"
  run ! grep -qiE '^## .*Coupling Analysis' <<< "$REPORT_CONTENT"
  run ! grep -qiE '^## .*Confidence Inversions' <<< "$REPORT_CONTENT"
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Reversibility Map'
}

# --- No leakage from critique siblings ---

@test "report does not contain cowen-critique Argument Decomposed framing" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^#+ .*Argument Decomposed'
}

@test "report does not contain yglesias-critique Goal vs Mechanism framing" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^#+ .*Goal vs\.? Mechanism'
}

@test "report does not contain fact-check verdict language" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Mostly accurate|Disputed|Inaccurate|Unverified)$'
}
