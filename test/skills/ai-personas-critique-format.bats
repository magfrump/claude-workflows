#!/usr/bin/env bats
# Validates the output format of ai-personas-critique reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/ai-personas-critique.md bats test/skills/ai-personas-critique-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/ai-personas-critique.md"
}

# --- Title ---

@test "report has a title header with AI Personas identifier" {
  echo "$REPORT_CONTENT" | head -5 | grep -qiE '^# .*(AI Personas|Personas Critique)'
}

# --- Required header fields ---

@test "report has a User goal field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*User goal:\*\*'
}

@test "report has a Proposal field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Proposal:\*\*'
}

@test "report has a Domains field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Domains:\*\*'
}

@test "report has a Personas selected field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Personas selected:\*\*'
}

@test "report has a Personas in parallel field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Personas in parallel:\*\*'
}

# --- Persona Critiques structural section ---

@test "report has Persona Critiques section" {
  assert_section_exists "Persona Critiques"
}

@test "report has at least 3 persona subsections" {
  # Persona subsections are ### headings under ## Persona Critiques
  local persona_section persona_count
  persona_section=$(echo "$REPORT_CONTENT" | sed -n '/^## Persona Critiques/,/^## [^#]/p')
  persona_count=$(echo "$persona_section" | grep -cE '^### ' || true)
  [ "$persona_count" -ge 3 ]
}

@test "report has at most 4 persona subsections" {
  # The skill prescribes 3-4 personas; more than 4 indicates drift.
  local persona_section persona_count
  persona_section=$(echo "$REPORT_CONTENT" | sed -n '/^## Persona Critiques/,/^## [^#]/p')
  persona_count=$(echo "$persona_section" | grep -cE '^### ' || true)
  [ "$persona_count" -le 4 ]
}

# --- Per-persona fields ---

@test "each persona section has a Severity line" {
  local persona_section persona_count severity_count
  persona_section=$(echo "$REPORT_CONTENT" | sed -n '/^## Persona Critiques/,/^## [^#]/p')
  persona_count=$(echo "$persona_section" | grep -cE '^### ' || true)
  severity_count=$(echo "$persona_section" | grep -cE '^\*\*Severity:\*\*' || true)
  [ "$persona_count" -eq "$severity_count" ]
}

@test "each persona section has a Test/mitigation line" {
  local persona_section persona_count mitigation_count
  persona_section=$(echo "$REPORT_CONTENT" | sed -n '/^## Persona Critiques/,/^## [^#]/p')
  persona_count=$(echo "$persona_section" | grep -cE '^### ' || true)
  mitigation_count=$(echo "$persona_section" | grep -cE '^\*\*Test/mitigation:\*\*' || true)
  [ "$persona_count" -eq "$mitigation_count" ]
}

@test "severity values use only the allowed values" {
  local persona_section bad
  persona_section=$(echo "$REPORT_CONTENT" | sed -n '/^## Persona Critiques/,/^## [^#]/p')
  bad=$(echo "$persona_section" | sed -n 's/^\*\*Severity:\*\* //p' \
        | grep -viE '^(Fatal flaw|Significant weakness|Point to consider)$' || true)
  [ -z "$bad" ]
}

# --- Goal-Alignment Note coverage ---

@test "report contains at least one Goal-Alignment Note" {
  # The skill requires every persona section to close with one, but at minimum the
  # report must include one. (Per-persona enforcement would over-fit on heading
  # level since the canonical form uses ####.)
  echo "$REPORT_CONTENT" | grep -qiE '^#{2,4} .*Goal-Alignment Note'
}

# --- Synthesis section and subsections ---

@test "report has Synthesis section" {
  assert_section_exists "Synthesis"
}

@test "synthesis contains Convergent Findings subsection" {
  assert_heading_exists "Convergent Findings"
}

@test "synthesis contains Tensions subsection" {
  assert_heading_exists "Tensions"
}

@test "synthesis contains Ranked Concerns subsection" {
  assert_heading_exists "Ranked Concerns"
}

@test "synthesis contains Blind Spots subsection" {
  assert_heading_exists "Blind Spots"
}

@test "ranked concerns is rendered as a markdown table" {
  local ranked
  ranked=$(echo "$REPORT_CONTENT" | sed -n '/Ranked Concerns/,/^#\{2,4\} /p')
  echo "$ranked" | grep -qE '^\|.*\|'
}

# --- Stub short-circuit (legitimately valid output) ---
# If the pre-flight skipped the persona pass, the report is the single line
# "draft incomplete; persona pass skipped". All other checks would fail
# trivially in that case; tests above are scoped to fully generated reports.

# --- No leakage from sibling critic skills ---

@test "report does not contain Cowen-specific analytical section names" {
  # ai-personas-critique should not lift Cowen's fixed cognitive-move headings
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{1,4} .*Survives the Inversion'
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{1,4} .*Boring Explanation'
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{1,4} .*Argument Decomposed'
}

@test "report does not contain Yglesias-specific analytical section names" {
  # ai-personas-critique should not lift Yglesias's fixed cognitive-move headings
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{1,4} .*Goal vs\.? the Mechanism'
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{1,4} .*Boring Lever'
  ! echo "$REPORT_CONTENT" | grep -qiE '^#{1,4} .*10 Million People'
}

@test "report does not contain reviewer-style verdict scales" {
  # Personas critique uses Severity = Fatal/Significant/Point — not reviewer scales
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Verified|Incorrect|Stale)$'
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Severity:\*\* (Critical|High|Medium|Low|Informational)$'
}
