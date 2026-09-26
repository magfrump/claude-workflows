#!/usr/bin/env bats
# @category fast
# @needs-reports yglesias-critique
# Validates the output format of yglesias-critique reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/yglesias-critique.md bats test/skills/yglesias-critique-format.bats

# `run !` and `run -N` are bats >= 1.5 features. Declaring the requirement makes
# bats enforce it (hard error on an older bats) instead of emitting BW02 and
# leaving it an open question whether the flag-carrying assertions really assert.
bats_require_minimum_version 1.5.0

load helpers

setup() {
  resolve_skill_report yglesias-critique tc-ygl1-class-size-cap.md
  load_generic_report "$REPORT_PATH"
}

# --- Title ---

@test "report has a title header with Yglesias identifier" {
  # SKILL.md puts the no-fact-check warning (up to 5 lines) above the title,
  # so the default 5-line window would fail a report that follows the skill.
  assert_title_matches '^# .*Yglesias.*Critique' 12
}

# --- Sections (SKILL.md "How to Structure the Critique") ---
# SKILL.md lists 9 sections and says to omit one with nothing substantive to
# say, so no single move section is required. What it does require: level-2
# headings with the given names ("never rename a section you do use"), the
# section-body keyword each section names, an Overall Assessment that closes
# with a one-line **Load-bearing objection:**, and enough sections to rank
# objections across.

# Every level-2 heading is one of SKILL.md's section names.
SECTION_NAMES_RE='^## ((The )?Goal vs\.? the Mechanism|(The )?Boring Lever|Follow the Money|Factual Foundation|(The )?Scale Test|(The )?Org Chart|Adoption Survival|(The )?Cost Disease Check|Overall Assessment)([[:space:]]*[:—–-].*)?[[:space:]]*$'

# "<heading ERE>|<keyword ERE>[&&<keyword ERE>]": the word SKILL.md tells each
# section's body to use, so downstream tooling can identify the move.
SECTION_KEYWORDS=(
    "(The )?Goal vs\.? the Mechanism|goal&&mechanism"
    "(The )?Boring Lever|lever"
    "Follow the Money|money"
    "(The )?Scale Test|scale"
    "(The )?Org Chart|org chart"
    "Adoption Survival|adoption"
    "(The )?Cost Disease Check|cost disease"
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

# --- No leakage from reviewer / fact-check / sister critique skills ---

@test "report does not contain severity/verdict scales from reviewer skills" {
  run ! grep -qiE '^\*\*Severity:\*\* (Critical|High|Medium|Low|Informational)$' <<< "$REPORT_CONTENT"
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Verified|Incorrect|Stale)$'
}

@test "report does not contain cowen-critique section headings" {
  # Yglesias critiques focus on mechanism feasibility, not argument rigor.
  # These are cowen-critique's prescribed level-2 section names.
  run ! grep -qiE '^## .*Argument,? Decomposed' <<< "$REPORT_CONTENT"
  run ! grep -qiE '^## .*Survives the Inversion' <<< "$REPORT_CONTENT"
  run ! grep -qiE '^## The Boring Explanation' <<< "$REPORT_CONTENT"
  run ! grep -qiE '^## Revealed vs\.? Stated' <<< "$REPORT_CONTENT"
  run ! grep -qiE '^## The Analogy' <<< "$REPORT_CONTENT"
  run ! grep -qiE '^## Contingent Assumptions' <<< "$REPORT_CONTENT"
  ! echo "$REPORT_CONTENT" | grep -qiE '^## What the Market Says'
}

@test "report does not contain ai-personas-critique structural headings" {
  # ai-personas-critique uses a Goal-Alignment-by-persona structure that
  # would indicate the wrong skill ran.
  run ! grep -qiE '^## .*Persona Selection' <<< "$REPORT_CONTENT"
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Persona [0-9]+:'
}
