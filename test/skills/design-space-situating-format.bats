#!/usr/bin/env bats
# @category fast
# Validates the output format of design-space-situating records.
#
# Note: No example report exists yet — tests will skip via load_generic_report.
#
# Usage: Set REPORT_PATH to a generated record, then run:
#   REPORT_PATH=docs/working/situating-<slug>.md bats test/skills/design-space-situating-format.bats

load helpers

setup() {
  load_generic_report "${REPORT_PATH:-docs/working/situating.md}"
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

# --- Placement values: dimensions with named-position vocabularies ---

@test "locus of authority placement uses an allowed value" {
  local section row
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  row=$(echo "$section" | grep -iE '^\| *1 *\|.*Locus' || true)
  [ -n "$row" ] || skip "no row 1 found"
  echo "$row" | grep -qiE '(Centralized|Mixed|Distributed)'
}

@test "search/compose/emerge placement uses an allowed value" {
  local section row
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  row=$(echo "$section" | grep -iE '^\| *3 *\|' || true)
  [ -n "$row" ] || skip "no row 3 found"
  echo "$row" | grep -qiE '(Search|Compose|Emerge|Mixed)'
}

@test "modeling target placement uses an allowed value" {
  local section row
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  row=$(echo "$section" | grep -iE '^\| *4 *\|' || true)
  [ -n "$row" ] || skip "no row 4 found"
  echo "$row" | grep -qiE '(Receiver|Structure|Context)'
}

@test "formality placement uses an allowed value" {
  local section row
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  row=$(echo "$section" | grep -iE '^\| *6 *\|' || true)
  [ -n "$row" ] || skip "no row 6 found"
  echo "$row" | grep -qiE '(Tacit|Explicit|Formal)'
}

@test "social structure placement uses an allowed value" {
  local section row
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  row=$(echo "$section" | grep -iE '^\| *7 *\|' || true)
  [ -n "$row" ] || skip "no row 7 found"
  echo "$row" | grep -qiE '(Expert-led|Participatory|Community)'
}

@test "legibility placement uses an allowed value" {
  local section row
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Dimensional placements/,/^## /p')
  row=$(echo "$section" | grep -iE '^\| *8 *\|' || true)
  [ -n "$row" ] || skip "no row 8 found"
  echo "$row" | grep -qiE '(Self|Peer|Stakeholder|Machine)'
}

# --- Tensions section ---

@test "tensions section has either bullets or an explicit no-tensions line" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Tensions surfaced/,/^## /p')
  # Either at least one bullet, or the explicit "None" line
  echo "$section" | grep -qE '^- ' || echo "$section" | grep -qiE 'None.*coherent'
}

# --- Hand-off section names a downstream consumer ---

@test "hand-off names a downstream workflow or actor" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Hand-off/,$p')
  echo "$section" | grep -qiE '(DD|divergent.design|RPI|plan|implementation|diagnosis)'
}

# --- No leakage from sibling skills ---

@test "record does not contain matrix-analysis scoring rubric" {
  # Matrix-analysis uses ++/+/-/? rating cells; situating uses named placements.
  ! echo "$REPORT_CONTENT" | grep -qE '^## Comparison Matrix'
  ! echo "$REPORT_CONTENT" | grep -qE '^## Tradeoff Analysis'
}

@test "record does not contain what-if-analysis failure-mode sections" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^## Failure Modes'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## Pre.mortem'
}

@test "record does not contain tech-debt-triage cost/urgency fields" {
  ! echo "$REPORT_CONTENT" | grep -qE '^\*\*Carrying Cost:\*\*'
  ! echo "$REPORT_CONTENT" | grep -qE '^\*\*Fix Cost:\*\*'
}

@test "record does not contain reviewer-style severity/verdict scales" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Severity:\*\* (Critical|High|Medium|Low|Informational)$'
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Verified|Incorrect|Stale)$'
}

@test "record is a frame, not a recommendation — does not pick a candidate" {
  # Situating records should not contain decision-output language from DD or matrix-analysis.
  ! echo "$REPORT_CONTENT" | grep -qiE '^## Recommendation'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## Decision'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## Chosen Candidate'
}
