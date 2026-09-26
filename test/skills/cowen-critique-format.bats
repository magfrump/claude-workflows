#!/usr/bin/env bats
# @category fast
# @needs-reports cowen-critique
# Validates the output format of cowen-critique reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/cowen-critique.md bats test/skills/cowen-critique-format.bats

# `run !` and `run -N` are bats >= 1.5 features. Declaring the requirement makes
# bats enforce it (hard error on an older bats) instead of emitting BW02 and
# leaving it an open question whether the flag-carrying assertions really assert.
bats_require_minimum_version 1.5.0

load helpers

setup() {
  resolve_skill_report cowen-critique tc-cow1-library-visits.md
  load_generic_report "$REPORT_PATH"
}

# --- Title ---

@test "report has a title header with Cowen identifier" {
  # SKILL.md puts the no-fact-check warning (up to 5 lines) above the title,
  # so the default 5-line window would fail a report that follows the skill.
  assert_title_matches '^# .*Cowen.*Critique' 12
}

# --- Sections (SKILL.md "How to Structure the Critique") ---
# SKILL.md lists 9 sections and says to omit one with nothing substantive to
# say, so no single move section is required. What it does require: level-2
# headings with the given names ("never rename a section you do use"), the
# section-body keyword each section names, an Overall Assessment that closes
# with a one-line **Load-bearing objection:**, and enough sections to rank
# objections across.

# Every level-2 heading is one of SKILL.md's section names.
SECTION_NAMES_RE='^## ((The )?Argument,? Decomposed|What Survives the Inversion|Factual Foundation|(The )?Boring Explanation|Revealed vs\.? Stated|(The )?Analogy|Contingent Assumptions|What the Market Says|Overall Assessment)([[:space:]]*[:—–-].*)?[[:space:]]*$'

# "<heading ERE>|<keyword ERE>[&&<keyword ERE>]": the word SKILL.md tells each
# section's body to use, so downstream tooling can identify the move.
SECTION_KEYWORDS=(
    "(The )?Argument,? Decomposed|sub-?claim"
    "What Survives the Inversion|inversion"
    "(The )?Boring Explanation|boring"
    "Revealed vs\.? Stated|revealed"
    "(The )?Analogy|analogy"
    "Contingent Assumptions|contingent"
    "What the Market Says|market"
)

# Body of the "## " section whose heading matches $1 (ERE), up to the next "## ".
section_body() {
  echo "$REPORT_CONTENT" | awk -v title="$1" '
    /^## / { if (inside) exit; if (tolower(substr($0, 4)) ~ tolower(title)) { inside = 1; next } }
    inside { print }
  '
}

@test "every section uses a SKILL.md section name" {
  local bad
  bad=$(echo "$REPORT_CONTENT" | grep -E '^## ' | grep -viE "$SECTION_NAMES_RE" || true)
  [ -z "$bad" ] || { echo "Renamed or unknown sections: $bad"; return 1; }
}

@test "report has at least 3 SKILL.md sections" {
  # Two or more move sections plus the Overall Assessment: fewer is not a
  # critique the closer could rank objections across.
  local n
  n=$(echo "$REPORT_CONTENT" | grep -ciE "$SECTION_NAMES_RE" || true)
  [ "$n" -ge 3 ]
}

@test "report has Overall Assessment section" {
  assert_section_exists "Overall Assessment"
}

@test "Overall Assessment closes with a Load-bearing objection line" {
  local body
  body="$(section_body "Overall Assessment")"
  echo "$body" | grep -qE '^[[:space:]]*\*\*Load-bearing objection:\*\*[[:space:]]*[^[:space:]]'
}

@test "each section present uses the keyword SKILL.md names for it" {
  local entry heading kws kw body
  for entry in "${SECTION_KEYWORDS[@]}"; do
    heading="${entry%%|*}" kws="${entry#*|}"
    echo "$REPORT_CONTENT" | grep -qiE "^## ${heading}" || continue
    body="$(section_body "$heading")"
    while [ -n "$kws" ]; do
      kw="${kws%%&&*}"
      echo "$body" | grep -qiE "$kw" || { echo "Section '$heading' lacks '$kw'"; return 1; }
      [[ "$kws" == *"&&"* ]] && kws="${kws#*&&}" || kws=""
    done
  done
}

# --- No leakage from reviewer / fact-check / yglesias skills ---

@test "report does not contain severity/verdict scales from reviewer skills" {
  run ! grep -qiE '^\*\*Severity:\*\* (Critical|High|Medium|Low|Informational)$' <<< "$REPORT_CONTENT"
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Verified|Incorrect|Stale)$'
}

@test "report does not contain yglesias mechanism-critique section headings" {
  # Cowen critiques focus on argument rigor, not mechanism feasibility.
  # These are yglesias-critique's prescribed section names.
  run ! grep -qiE '^## .*Goal vs\.? the Mechanism' <<< "$REPORT_CONTENT"
  run ! grep -qiE '^## .*Boring Lever' <<< "$REPORT_CONTENT"
  run ! grep -qiE '^## Follow the Money' <<< "$REPORT_CONTENT"
  run ! grep -qiE '^## .*Cost Disease' <<< "$REPORT_CONTENT"
  run ! grep -qiE '^## .*Scale Test' <<< "$REPORT_CONTENT"
  run ! grep -qiE '^## .*Org Chart' <<< "$REPORT_CONTENT"
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Adoption Survival'
}
