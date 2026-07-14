#!/usr/bin/env bats
# @category fast
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
  load_generic_report "docs/reviews/cowen-critique.md"
}

# --- Title ---

@test "report has a title header with Cowen identifier" {
  assert_title_matches '^# .*Cowen.*Critique'
}

# --- Required analytical sections (cognitive moves) ---
# SKILL.md prescribes level-2 (##) headings in the output file. Use
# assert_section_exists where the section name is fixed; use
# assert_heading_exists where a regex pattern is needed (e.g. for an
# embedded comma).

@test "report has The Argument Decomposed section" {
  # Heading is "## The Argument, Decomposed" — comma breaks an exact match,
  # so use the regex helper.
  assert_heading_exists "Argument.*Decomposed"
}

@test "report has What Survives the Inversion section" {
  assert_section_exists "What Survives the Inversion"
}

@test "report has Factual Foundation section" {
  assert_section_exists "Factual Foundation"
}

@test "report has The Boring Explanation section" {
  assert_section_exists "The Boring Explanation"
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
