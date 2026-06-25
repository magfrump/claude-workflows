#!/usr/bin/env bats
# @category fast
# Validates the output format of yglesias-critique reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/yglesias-critique.md bats test/skills/yglesias-critique-format.bats

load helpers

setup() {
  load_generic_report "docs/reviews/yglesias-critique.md"
}

# --- Title ---

@test "report has a title header with Yglesias identifier" {
  assert_title_matches '^# .*Yglesias.*Critique'
}

# --- Required analytical sections (cognitive moves) ---
# SKILL.md prescribes level-2 (##) headings in the output file. Use
# assert_section_exists where the section name is fixed; use
# assert_heading_exists where a regex pattern is needed (e.g. for an
# embedded period).

@test "report has The Goal vs the Mechanism section" {
  # Heading is "## The Goal vs. the Mechanism" — period breaks a strict
  # literal match, so use the regex helper.
  assert_heading_exists "Goal vs\\.? the Mechanism"
}

@test "report has The Boring Lever section" {
  assert_section_exists "The Boring Lever"
}

@test "report has Follow the Money section" {
  assert_section_exists "Follow the Money"
}

@test "report has Factual Foundation section" {
  assert_section_exists "Factual Foundation"
}

@test "report has The Scale Test section" {
  assert_section_exists "The Scale Test"
}

@test "report has The Org Chart section" {
  assert_section_exists "The Org Chart"
}

@test "report has Adoption Survival section" {
  assert_section_exists "Adoption Survival"
}

@test "report has Overall Assessment section" {
  assert_section_exists "Overall Assessment"
}

# --- Structural requirements ---

@test "report has at least 5 sections" {
  local section_count
  section_count=$(echo "$REPORT_CONTENT" | grep -cE '^## ' || true)
  [ "$section_count" -ge 5 ]
}

# --- No leakage from reviewer / fact-check / sister critique skills ---

@test "report does not contain severity/verdict scales from reviewer skills" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Severity:\*\* (Critical|High|Medium|Low|Informational)$'
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Verified|Incorrect|Stale)$'
}

@test "report does not contain cowen-critique section headings" {
  # Yglesias critiques focus on mechanism feasibility, not argument rigor.
  # These are cowen-critique's prescribed level-2 section names.
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Argument,? Decomposed'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Survives the Inversion'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## The Boring Explanation'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## Revealed vs\.? Stated'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## The Analogy'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## Contingent Assumptions'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## What the Market Says'
}

@test "report does not contain ai-personas-critique structural headings" {
  # ai-personas-critique uses a Goal-Alignment-by-persona structure that
  # would indicate the wrong skill ran.
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Persona Selection'
  ! echo "$REPORT_CONTENT" | grep -qiE '^## .*Persona [0-9]+:'
}
