#!/usr/bin/env bats
# @category fast
# @needs-reports design-space-situating
# Validates the output format of design-space-situating records.
#
# Note: No example report exists yet — tests will skip via load_generic_report.
#
# Usage: Set REPORT_PATH to a generated record, then run:
#   REPORT_PATH=docs/working/situating-<slug>.md bats test/skills/design-space-situating-format.bats

# `run !` and `run -N` are bats >= 1.5 features. Declaring the requirement makes
# bats enforce it (hard error on an older bats) instead of emitting BW02 and
# leaving it an open question whether the flag-carrying assertions really assert.
bats_require_minimum_version 1.5.0

load helpers

setup() {
  resolve_skill_report design-space-situating tc-dss1-partner-webhook-payloads.md
  load_generic_report "$REPORT_PATH"
}

# --- Title and header ---

@test "record has a Situating Record title" {
  assert_title_matches '^# .*Situating Record'
}

@test "record has a Date field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Date:\*\*'
}

# --- Required top-level sections ---

@test "record has Decision under situating section" {
  assert_heading_exists "Decision under situating"
}

@test "record has Situating paragraph section" {
  assert_heading_exists "Situating paragraph"
}

@test "record has Dimensional placements section" {
  assert_heading_exists "Dimensional placements"
}

@test "record has Tensions surfaced section" {
  assert_heading_exists "Tensions surfaced"
}

@test "record has Hand-off section" {
  assert_heading_exists "Hand-off"
}

# --- Situating paragraph has substantive content ---

@test "situating paragraph has at least 3 sentences of prose" {
  local para
  para=$(echo "$REPORT_CONTENT" | sed -n '/^## Situating paragraph/,/^## /p' | sed '1d;$d')
  # Count sentence-ending punctuation followed by space or EOL
  local sentences
  sentences=$(echo "$para" | grep -oE '[.!?]( |$)' | wc -l)
  [ "$sentences" -ge 3 ]
}

# --- Dimensional placements: table presence and all 8 dimensions ---

@test "dimensional placements section contains a markdown table" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  echo "$section" | grep -qE '^\|.*\|.*\|'
}

@test "placements table mentions Locus of authority" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  echo "$section" | grep -qiE 'Locus of authority'
}

@test "placements table mentions Orientation in time" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  echo "$section" | grep -qiE 'Orientation in time'
}

@test "placements table mentions Search / Compose / Emerge" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  echo "$section" | grep -qiE 'Search.*Compose.*Emerge'
}

@test "placements table mentions Modeling target" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  echo "$section" | grep -qiE 'Modeling target'
}

@test "placements table mentions Reversibility" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  echo "$section" | grep -qiE 'Reversibility'
}

@test "placements table mentions Formality" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  echo "$section" | grep -qiE 'Formality'
}

@test "placements table mentions Social structure" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  echo "$section" | grep -qiE 'Social structure'
}

@test "placements table mentions Legibility" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  echo "$section" | grep -qiE 'Legibility'
}

@test "placements table has 8 data rows" {
  # Count data rows in the placements table: lines starting with "| " followed
  # by a digit 1-8 (the dimension number column). Excludes header and divider.
  local section count
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  count=$(echo "$section" | grep -cE '^\| *[1-8] *\|' || true)
  [ "$count" -eq 8 ]
}

# --- Placement values: the Placement column, not the row ---
#
# Grading the whole row matched the dimension's own name (row 3's "Search /
# Compose / Emerge" satisfies Search|Compose|Emerge, row 6's "Formality"
# satisfies Formal), so a row with an empty or off-vocabulary placement passed.
# SKILL.md's table is "| # | Dimension | Placement | Rationale |": the third
# cell holds the value. "Mixed" and "N/A — does not constrain" are allowed on
# any dimension when warranted.

# placement_cell <n>: the Placement cell of row <n> of the placements table.
placement_cell() {
  echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p' \
    | awk -F'|' -v n="$1" '{ k = $2; gsub(/[ \t*]/, "", k) } k == n { print $4; exit }'
}

# assert_placement <n> <ERE>: row <n>'s Placement cell matches <ERE>, Mixed or N/A.
assert_placement() {
  local cell
  cell="$(placement_cell "$1")"
  [ -n "${cell//[[:space:]]/}" ] || { echo "row $1 has no Placement cell"; return 1; }
  echo "$cell" | grep -qiE "\b($2|Mixed)\b|N/A" || { echo "row $1 placement '$cell' is not one of /$2/"; return 1; }
}

@test "locus of authority placement uses an allowed value" {
  assert_placement 1 'Centralized|Distributed'
}

@test "orientation in time placement names a direction and a shape" {
  assert_placement 2 'Backward|Forward'
  assert_placement 2 'Snapshot|Process'
}

@test "search/compose/emerge placement uses an allowed value" {
  assert_placement 3 'Search|Compose|Emerge'
}

@test "modeling target placement uses an allowed value" {
  assert_placement 4 'Receiver|Structure|Context'
}

@test "reversibility placement uses an allowed value" {
  assert_placement 5 'Cheap|Expensive'
}

@test "formality placement uses an allowed value" {
  assert_placement 6 'Tacit|Explicit|Formal'
}

@test "social structure placement uses an allowed value" {
  assert_placement 7 'Expert-led|Participatory|Community'
}

@test "legibility placement uses an allowed value" {
  assert_placement 8 'Self|Peer|Stakeholder|Machine'
}

# --- Tensions section ---

@test "tensions section has either bullets or an explicit no-tensions line" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Tensions surfaced/,/^## /p')
  # Either at least one bullet, or the explicit "None" line
  echo "$section" | grep -qE '^- ' || echo "$section" | grep -qiE 'None.*coherent'
}

# --- Hand-off section names the downstream consumer that applies ---
#
# SKILL.md's template lists all three consumers (DD's diagnosis step, RPI's plan
# step, direct implementation) and then says "Name which one applies here", so
# a record that pastes the template names all three and chooses none. Lines of
# the template are dropped before looking for the named consumer.

@test "hand-off names which downstream consumer applies, beyond the template" {
  local section own
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Hand-off/,/^## /p' | sed '1d' | grep -v '^## ')
  own=$(echo "$section" | grep -viE \
      -e '^[[:space:]]*This record is a frame, not a decision\. It is intended as input to one of:[[:space:]]*$' \
      -e "^[[:space:]]*- DD's diagnosis step \(step 2\) — the constraints become testable[[:space:]]*$" \
      -e "^[[:space:]]*- RPI's plan step — the decision's actual scope is now named[[:space:]]*$" \
      -e '^[[:space:]]*- direct implementation — name the implementer and the first concrete next step[[:space:]]*$' \
      -e '^[[:space:]]*Name which one applies here\.[[:space:]]*$' || true)
  echo "$own" | grep -qiE '(\bDD\b|divergent.design|\bRPI\b|plan step|implement)'
}

# --- No leakage from sibling skills ---

@test "record does not contain matrix-analysis scoring rubric" {
  # Matrix-analysis uses ++/+/-/? rating cells; situating uses named placements.
  run ! grep -qE '^## Comparison Matrix' <<< "$REPORT_CONTENT"
  ! echo "$REPORT_CONTENT" | grep -qE '^## Tradeoff Analysis'
}

@test "record does not contain what-if-analysis failure-mode sections" {
  run ! grep -qiE '^## Failure Modes' <<< "$REPORT_CONTENT"
  ! echo "$REPORT_CONTENT" | grep -qiE '^## Pre.mortem'
}

@test "record does not contain tech-debt-triage cost/urgency fields" {
  run ! grep -qE '^\*\*Carrying Cost:\*\*' <<< "$REPORT_CONTENT"
  ! echo "$REPORT_CONTENT" | grep -qE '^\*\*Fix Cost:\*\*'
}

@test "record does not contain reviewer-style severity/verdict scales" {
  run ! grep -qiE '^\*\*Severity:\*\* (Critical|High|Medium|Low|Informational)$' <<< "$REPORT_CONTENT"
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Verified|Incorrect|Stale)$'
}

@test "record is a frame, not a recommendation — does not pick a candidate" {
  # Situating records should not contain decision-output language from DD or matrix-analysis.
  run ! grep -qiE '^## Recommendation' <<< "$REPORT_CONTENT"
  # Only DD's decision-record headings; the required "## Decision under situating" must pass.
  run ! grep -qiE '^## Decision( and rationale)?[[:space:]]*$' <<< "$REPORT_CONTENT"
  ! echo "$REPORT_CONTENT" | grep -qiE '^## Chosen Candidate'
}
