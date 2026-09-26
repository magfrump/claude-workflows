#!/usr/bin/env bats
# @category fast
# @needs-reports matrix-analysis
# Validates the output format of matrix-analysis reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/matrix-analysis.md bats test/skills/matrix-analysis-format.bats

load helpers

setup() {
  resolve_skill_report matrix-analysis tc-ma1-agpl-library-in-closed-saas.md
  load_generic_report "$REPORT_PATH"
}

# --- Header section ---

@test "report has a title header" {
  assert_title_matches '^# .*Matrix.*Analysis'
}

@test "report has an Items field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Items:\*\*'
}

@test "report has a Criteria field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Criteria:\*\*'
}

@test "report has a Date field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Date:\*\*'
}

# --- Required sections ---

@test "report has Comparison Matrix section" {
  assert_section_exists "Comparison Matrix"
}

@test "report has Detailed Evaluations section" {
  assert_section_exists "Detailed Evaluations"
}

@test "report has Tradeoff Analysis section" {
  assert_heading_exists "Tradeoff"
}

@test "report has Recommendation section" {
  assert_section_exists "Recommendation"
}

# --- Matrix structure ---

@test "comparison matrix contains a markdown table" {
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Comparison Matrix/,/^## /p' | head -n -1)
  echo "$section" | grep -qE '^\|.*\|'
}

@test "comparison matrix has a table separator row" {
  # A valid markdown table has a separator row of dashes after the header.
  local section
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Comparison Matrix/,/^## /p' | head -n -1)
  echo "$section" | grep -qE '^\|[ :-]*-+[ :-]*\|'
}

@test "comparison matrix has at least two item rows" {
  # Count table rows that aren't the header or separator. The header row is the
  # first row, separator is the dash row; subsequent rows are items.
  local section item_rows
  section=$(echo "$REPORT_CONTENT" | sed -n '/^## Comparison Matrix/,/^## /p' | head -n -1)
  # Count all table rows, then subtract header + separator
  local total_rows
  total_rows=$(echo "$section" | grep -cE '^\|.*\|' || true)
  item_rows=$((total_rows - 2))
  [ "$item_rows" -ge 2 ]
}

# The Comparison Matrix table's rows, one per line, cells separated by \x1f
# with the outer pipes and surrounding spaces trimmed. Header first; the
# separator row is dropped.
matrix_rows() {
  echo "$REPORT_CONTENT" | sed -n '/^## Comparison Matrix/,/^## /p' | grep -E '^[[:space:]]*\|' \
    | grep -vE '^[[:space:]]*\|[[:space:]:|-]*$' \
    | awk '{ sub(/^[ \t]*\|/, ""); sub(/\|[ \t]*$/, ""); n = split($0, c, "|"); out = ""
             for (i = 1; i <= n; i++) { gsub(/^[ \t]+|[ \t]+$/, "", c[i]); out = out (i > 1 ? "\037" : "") c[i] }
             print out }'
}

@test "comparison matrix has at least two criterion columns" {
  # SKILL.md: "at least 2 criterion columns": every header cell but the first
  # (the item column) and an optional Overall.
  local header n=0 cell
  header="$(matrix_rows | head -1)"
  [ -n "$header" ]
  local IFS=$'\037'
  local -a cells
  read -ra cells <<< "$header"
  for cell in "${cells[@]:1}"; do
    [[ "$cell" =~ ^[*_]*[Oo]verall ]] || n=$((n + 1))
  done
  [ "$n" -ge 2 ]
}

# A rating (optionally bold/italic/code): ++ + - ? or a number such as 4, 3.5, 4/5,
# then a space, punctuation or the end of the cell.
RATING_RE='^[*_`]*(\+\+|\+|-|\?|[0-9]+(\.[0-9]+)?(/[0-9]+)?)[*_`]*([[:space:]]|$|[,:;.(])'

@test "every criterion cell of the matrix leads with a rating" {
  # SKILL.md: cells use ++ / + / - / ? (Strong / Adequate / Weak / Insufficient
  # information) or the user's numeric scale, followed by a brief rationale.
  # Only criterion cells are graded: not the item column, not Overall.
  local header rows overall=-1 i row bad=""
  header="$(matrix_rows | head -1)"
  rows="$(matrix_rows | tail -n +2)"
  [ -n "$rows" ]
  local IFS=$'\037'
  local -a h cells
  read -ra h <<< "$header"
  for i in "${!h[@]}"; do
    [[ "${h[$i]}" =~ ^[*_]*[Oo]verall ]] && overall=$i
  done
  while IFS= read -r row; do
    IFS=$'\037' read -ra cells <<< "$row"
    for i in "${!cells[@]}"; do
      [ "$i" -eq 0 ] || [ "$i" -eq "$overall" ] && continue
      if ! [[ "${cells[$i]}" =~ $RATING_RE ]]; then
        bad="${bad}${bad:+; }${cells[0]}: ${cells[$i]}"
      fi
    done
  done <<< "$rows"
  [ -z "$bad" ] || { echo "Cells without a leading rating: $bad"; return 1; }
}

# --- Detailed evaluations ---

@test "detailed evaluations have per-criterion subsections" {
  local detail_section
  detail_section=$(echo "$REPORT_CONTENT" | sed -n '/^## Detailed Evaluations/,/^## [^#]/p')
  local subsection_count
  subsection_count=$(echo "$detail_section" | grep -cE '^### ' || true)
  [ "$subsection_count" -ge 1 ]
}

# --- Evaluation Metadata ---

@test "report has Evaluation Metadata section" {
  assert_heading_exists "Evaluation Metadata"
}

# --- No leakage from sibling decision-helper skills ---

@test "report does not contain tech-debt-triage language" {
  # tech-debt-triage uses Carrying Cost / Fix Cost / Urgency Triggers and recommendation
  # verbs like "Fix now / Carry intentionally / Defer and monitor".
  ! echo "$REPORT_CONTENT" | grep -qiE '(^## .*Carrying Cost|^## .*Fix Cost|^## .*Urgency Triggers|Fix opportunistically|Carry intentionally|Defer and monitor)'
}

@test "report does not contain design-space-situating language" {
  # design-space-situating produces an eight-dimension situating record with dimensions
  # like "Locus of Authority" or "Orientation in Time".
  ! echo "$REPORT_CONTENT" | grep -qiE '(Locus of Authority|Orientation in Time|Search/Compose/Emerge|Modeling Target|situating record)'
}

@test "report does not contain what-if-analysis language" {
  # what-if-analysis produces a pre-mortem with "Assumption" / "If wrong" sections.
  ! echo "$REPORT_CONTENT" | grep -qiE '(^## .*Pre-?mortem|^## .*Failure Modes|^## .*Second-Order Effects|\*\*If wrong:\*\*)'
}
