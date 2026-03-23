#!/usr/bin/env bats
# Validates the output format of code-fact-check reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/code-fact-check-report.md bats test/skills/code-fact-check-format.bats

load helpers

setup() {
  load_report "docs/reviews/code-fact-check-report.md"
}

# --- Header section ---

@test "report has a title header" {
  echo "$REPORT_CONTENT" | head -5 | grep -qE '^# Code Fact-Check Report'
}

@test "report has a Repository field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Repository:\*\*'
}

@test "report has a Scope field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Scope:\*\*'
}

@test "report has a Checked date field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Checked:\*\*'
}

@test "report has Total claims checked field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Total claims checked:\*\*'
}

@test "report has a Summary line with verdict counts" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Summary:\*\*.*verified.*incorrect'
}

# --- Claim sections ---

@test "claims are numbered sequentially starting at 1" {
  first_claim=$(echo "$REPORT_CONTENT" | grep -m1 -oE '^## Claim [0-9]+' | grep -oE '[0-9]+')
  [ "$first_claim" = "1" ]
}

@test "each claim section has a Location line with file:line format" {
  assert_field_per_claim "Location"
  local locations bad
  locations=$(echo "$REPORT_CONTENT" | sed -n 's/^\*\*Location:\*\* //p')
  bad=$(echo "$locations" | grep -vE '[a-zA-Z0-9_./-]+:[0-9]+' || true)
  [ -z "$bad" ]
}

@test "each claim section has a Type line" {
  assert_field_per_claim "Type"
}

@test "claim types use only the allowed values" {
  assert_field_values "Type" "Behavioral|Performance|Architectural|Invariant|Configuration|Reference|Staleness"
}

@test "each claim section has a Verdict line" {
  assert_field_per_claim "Verdict"
}

@test "verdicts use only the allowed values" {
  assert_field_values "Verdict" "Verified|Mostly accurate|Stale|Incorrect|Unverifiable"
}

@test "each claim section has a Confidence line" {
  assert_field_per_claim "Confidence"
}

@test "confidence levels use only the allowed values" {
  assert_field_values "Confidence" "High|Medium|Low"
}

@test "each claim section has an Evidence line with file:line format" {
  assert_field_per_claim "Evidence"
  local evidence bad
  evidence=$(echo "$REPORT_CONTENT" | sed -n 's/^\*\*Evidence:\*\* //p')
  bad=$(echo "$evidence" | grep -vE '[a-zA-Z0-9_./-]+:[0-9]+' || true)
  [ -z "$bad" ]
}

# --- Claims Requiring Attention section ---

@test "report has Claims Requiring Attention section" {
  echo "$REPORT_CONTENT" | grep -qE '^## Claims Requiring Attention'
}

@test "attention section has Incorrect subsection if any incorrect claims" {
  if echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* Incorrect'; then
    echo "$ATTENTION_SECTION" | grep -qE '^### Incorrect'
  fi
}

@test "attention section has Stale subsection if any stale claims" {
  if echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* Stale'; then
    echo "$ATTENTION_SECTION" | grep -qE '^### Stale'
  fi
}

@test "attention section has Mostly Accurate subsection if any MA claims" {
  if echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* Mostly accurate'; then
    echo "$ATTENTION_SECTION" | grep -qE '^### Mostly Accurate'
  fi
}

@test "attention section has Unverifiable subsection if any UV claims" {
  if echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* Unverifiable'; then
    echo "$ATTENTION_SECTION" | grep -qE '^### Unverifiable'
  fi
}

# --- Ordering ---

@test "claims are ordered sequentially" {
  assert_claims_sequential
}

# --- No review leakage ---

@test "report does not contain code review language" {
  ! echo "$REPORT_CONTENT" | grep -qiE '(should refactor|code smell|technical debt|needs cleanup|poor style)'
}

# --- Verdict scale isolation (cross-skill TC-X1) ---

@test "report never uses fact-check-only verdicts" {
  local bad
  bad=$(echo "$REPORT_CONTENT" | sed -n 's/^\*\*Verdict:\*\* //p' | grep -iE '^(Accurate|Disputed|Inaccurate|Unverified)$' || true)
  [ -z "$bad" ]
}
