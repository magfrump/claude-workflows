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

@test "Total claims checked header matches counted claim sections" {
  # The header field must agree with the actual number of ## Claim N sections.
  local header_count
  header_count=$(echo "$REPORT_CONTENT" | sed -n 's/^\*\*Total claims checked:\*\* *\([0-9][0-9]*\).*/\1/p' | head -1)
  [ -n "$header_count" ] || skip "Total claims checked header not numeric"
  [ "$header_count" = "$CLAIM_COUNT" ]
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
  sources_count=$(echo "$CLAIMS_BODY" | grep -cE '^\*\*Sources?:\*\*' || true)
  [ "$CLAIM_COUNT" -eq "$sources_count" ]
}

@test "each claim section has a Provenance line" {
  assert_field_per_claim "Provenance"
}

@test "each claim section has a Scrutiny line" {
  assert_field_per_claim "Scrutiny"
}

@test "each claim section has a Citation line" {
  assert_field_per_claim "Citation"
}

@test "verdicts use only the allowed values" {
  # Six allowed verdicts — the five-rung scale plus Secondary-only for
  # attributed quotes lacking a primary source. See skills/fact-check/SKILL.md
  # "Quote attribution" and the verdict↔provenance mapping table.
  assert_field_values "Verdict" "Accurate|Mostly accurate|Disputed|Inaccurate|Unverified|Secondary-only"
}

@test "confidence levels use only the allowed values" {
  assert_field_values "Confidence" "High|Medium|Low"
}

@test "provenance tags use only the allowed values" {
  # Tags may appear bare or in brackets — accept both. See skills/fact-check/SKILL.md
  # "Provenance Tags": observed | inferred | assumed.
  assert_field_values "Provenance" "\[?observed\]?|\[?inferred\]?|\[?assumed\]?"
}

@test "scrutiny tags use only the allowed values" {
  # Tags may appear bare or in brackets — accept both. See skills/fact-check/SKILL.md
  # "Scrutiny Tags": abstract | deep-read | inferred.
  assert_field_values "Scrutiny" "\[?abstract\]?|\[?deep-read\]?|\[?inferred\]?"
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

# --- Verdict scale isolation (cross-skill TC-X1) ---

@test "report never uses code-fact-check-only verdicts" {
  # The sibling skill code-fact-check uses Verified/Stale/Incorrect/Unverifiable.
  # fact-check must never emit those — they signal verdict-scale leakage between
  # the two skills' output formats.
  local bad
  bad=$(echo "$CLAIMS_BODY" | sed -n 's/^\*\*Verdict:\*\* //p' | grep -iE '^(Verified|Stale|Incorrect|Unverifiable)$' || true)
  [ -z "$bad" ]
}
