#!/usr/bin/env bats
# Validates the output format of fact-check reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/fact-check-report.md bats test/skills/fact-check-format.bats

load helpers

setup() {
  load_report "docs/reviews/fact-check-report.md"
}

# --- Header section ---

@test "report has a title header" {
  echo "$REPORT_CONTENT" | head -5 | grep -qE '^# Fact-Check Report:'
}

@test "report has a Checked date field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Checked:\*\*'
}

@test "report has Total claims checked field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Total claims checked:\*\*'
}

@test "report has a Summary line with verdict counts" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Summary:\*\*.*accurate.*inaccurate'
}

# --- Claim sections ---

@test "claims are numbered sequentially starting at 1" {
  first_claim=$(echo "$REPORT_CONTENT" | grep -m1 -oE '^## Claim [0-9]+' | grep -oE '[0-9]+')
  [ "$first_claim" = "1" ]
}

@test "each claim section has a Verdict line" {
  assert_field_per_claim "Verdict"
}

@test "each claim section has a Confidence line" {
  assert_field_per_claim "Confidence"
}

@test "each claim section has a Sources line" {
  local sources_count
  sources_count=$(echo "$REPORT_CONTENT" | grep -cE '^\*\*Sources?:\*\*' || true)
  [ "$CLAIM_COUNT" -eq "$sources_count" ]
}

@test "verdicts use only the allowed values" {
  assert_field_values "Verdict" "Accurate|Mostly accurate|Disputed|Inaccurate|Unverified"
}

@test "confidence levels use only the allowed values" {
  assert_field_values "Confidence" "High|Medium|Low"
}

# --- Claims Requiring Author Attention section ---

@test "report ends with Claims Requiring Author Attention section" {
  echo "$REPORT_CONTENT" | grep -qE '^## Claims Requiring Author Attention'
}

@test "attention section does not list Accurate claims" {
  local bad
  bad=$(echo "$ATTENTION_SECTION" | grep -iE '^\*\*Verdict:\*\* Accurate$' || true)
  [ -z "$bad" ]
}

# --- Ordering ---

@test "claims are ordered sequentially" {
  assert_claims_sequential
}

# --- No critique leakage ---

@test "report does not contain critique language" {
  ! echo "$REPORT_CONTENT" | grep -qiE '(should consider|weak argument|poor reasoning|could be stronger|needs improvement)'
}
