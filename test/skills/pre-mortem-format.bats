#!/usr/bin/env bats
# @category fast
# @needs-reports pre-mortem
# Validates the output format of pre-mortem reports.
#
# Default target: the generated report for tc-pm1-billing-ledger-migration.md
# (resolve_skill_report in helpers.bash); REPORT_PATH overrides it.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/pre-mortem.md bats test/skills/pre-mortem-format.bats

# `run !` and `run -N` are bats >= 1.5 features. Declaring the requirement makes
# bats enforce it (hard error on an older bats) instead of emitting BW02 and
# leaving it an open question whether the flag-carrying assertions really assert.
bats_require_minimum_version 1.5.0

load helpers

setup() {
  resolve_skill_report pre-mortem tc-pm1-billing-ledger-migration.md
  load_generic_report "$REPORT_PATH"
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
#
# SKILL.md: "3–5 narratives. For each, use these fields": Root cause, Chain of
# consequences, Observable outcome, Plausibility, Severity, and exactly one of
# Mitigation / Revisit trigger as the closing line. Each field is counted over
# the narratives (everything above the Recommendations heading), and every
# count must equal the number of narratives, so one complete narrative no
# longer covers four incomplete ones.

# narratives_text: the report above its Recommendations heading.
narratives_text() {
  echo "$REPORT_CONTENT" | awk '/^#+ .*Recommendations/ { exit } { print }'
}

# field_count <field ERE>: "**<field>:**" lines (optionally bulleted) there.
field_count() {
  narratives_text | grep -ciE "^[[:space:]]*([-*+][[:space:]]+)?\*\*($1):\*\*" || true
}

@test "report has 3 to 5 failure narratives" {
  local n
  n=$(field_count 'Root cause')
  [ "$n" -ge 3 ] && [ "$n" -le 5 ] || { echo "$n narratives (Root cause fields)"; return 1; }
}

@test "every narrative has each required field" {
  local n f c
  n=$(field_count 'Root cause')
  [ "$n" -ge 1 ]
  for f in 'Chain of consequences' 'Observable outcome' 'Plausibility' 'Severity'; do
    c=$(field_count "$f")
    [ "$c" -eq "$n" ] || { echo "$n narratives but $c **$f:** fields"; return 1; }
  done
}

@test "every narrative has exactly one closing action line (Mitigation or Revisit trigger)" {
  local n c
  n=$(field_count 'Root cause')
  c=$(field_count 'Mitigation|Revisit trigger')
  [ "$n" -ge 1 ] && [ "$c" -eq "$n" ] || { echo "$n narratives but $c Mitigation/Revisit trigger lines"; return 1; }
}

# The vocabulary word must LEAD the value; a trailing annotation is allowed.
# SKILL.md ("Calibrate severity and plausibility honestly") defines the labels
# with glosses — "Likely (>50%)", "High (significant cost, slow recovery)" — while
# its output template shows the bare word, so both forms are spec. The
# annotation rule is the same one assert_field_values applies repo-wide
# (helpers.bash). Anything else — an off-vocabulary word such as bare "Unlikely",
# or text before the word — fails. (The old presence check also accepted bare
# "Unlikely", which this one rejected; SKILL.md's enum has no such value.)
@test "Plausibility values use only the allowed vocabulary" {
  local values bad
  values=$(echo "$REPORT_CONTENT" | sed -n 's/^[*-]* *\*\*Plausibility:\*\* //p')
  [ -n "$values" ] || { echo "no Plausibility values found"; return 1; }
  bad=$(echo "$values" | grep -viE '^(Likely|Plausible|Unlikely-but-catastrophic)([ ,(*].*)?$' || true)
  [ -z "$bad" ]
}

@test "Severity values use only the allowed vocabulary" {
  local values bad
  values=$(echo "$REPORT_CONTENT" | sed -n 's/^[*-]* *\*\*Severity:\*\* //p')
  [ -n "$values" ] || { echo "no Severity values found"; return 1; }
  bad=$(echo "$values" | grep -viE '^(Low|Medium|High|Catastrophic)([ ,(*].*)?$' || true)
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
  ! echo "$REPORT_CONTENT" | grep -qiE '\*\*(Mitigation|Revisit trigger):\*\* (monitor in production|watch this carefully|keep an eye on it|be careful during rollout|document this|add tests|improve test coverage|do a phased rollout|add a runbook)\.?\s*$'
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
