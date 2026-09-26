#!/usr/bin/env bats
# @category fast
# @needs-reports fact-check
# Validates the output format of fact-check reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/fact-check-report.md bats test/skills/fact-check-format.bats

load helpers

# skills/fact-check/SKILL.md "Output format": every verdict is headed
# '## Verdict for C<N>: "<quote>"', and C<N> must appear in "## Claims identified".
VERDICT_HEADING_RE='^## Verdict for C[0-9]+'

setup() {
  # A report still using the pre-spec '## Claim N' headings would otherwise count
  # zero claims and skip every test; SKILL.md rejects any other heading scheme.
  resolve_skill_report fact-check tc-5.1-multi-claim.md
  if grep -qE '^## Claim [0-9]+' "$REPORT_PATH"; then
    echo "$REPORT_PATH uses '## Claim N' headings; fact-check SKILL.md requires '## Verdict for C<N>:'"
    return 1
  fi
  load_report "$REPORT_PATH" "$VERDICT_HEADING_RE"
}

# Claim IDs (numbers only) from the verdict headings, in document order.
verdict_ids() {
  echo "$REPORT_CONTENT" | grep -oE "$VERDICT_HEADING_RE" | grep -oE '[0-9]+$'
}

# Claim IDs (numbers only) listed in the "## Claims identified" section, in order.
# Entries are "- **C<N>** ..." per the SKILL.md template.
identified_ids() {
  echo "$REPORT_CONTENT" | sed -n '/^## Claims identified/,/^## /p' \
    | grep -oE '^- \*\*C[0-9]+\*\*' | grep -oE '[0-9]+'
}

# --- Header section ---

@test "report has a title header" {
  assert_title_matches '^# Fact-Check Report:' 5 "-qE"
}

@test "report has a Checked date field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Checked:\*\*'
}

@test "report has Total claims checked field" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Total claims checked:\*\*'
}

@test "Total claims checked header matches counted claim sections" {
  # The header field must agree with the actual number of ## Verdict for C<N> sections.
  local header_count
  header_count=$(echo "$REPORT_CONTENT" | sed -n 's/^\*\*Total claims checked:\*\* *\([0-9][0-9]*\).*/\1/p' | head -1)
  [ -n "$header_count" ] || skip "Total claims checked header not numeric"
  [ "$header_count" = "$CLAIM_COUNT" ]
}

@test "report has a Summary line with verdict counts" {
  echo "$REPORT_CONTENT" | grep -qE '^\*\*Summary:\*\*.*accurate.*inaccurate'
}

# --- Claim sections ---

@test "verdict IDs are C1..CN with no gaps or duplicates" {
  # SKILL.md: IDs are assigned in Pass 1 and a claim found in Pass 2 takes the next
  # unused ID, so the ID set is 1..N. Layout follows draft order, so an appended ID
  # may render out of numeric order — compare as a sorted set, not a sequence.
  local got want
  got=$(verdict_ids | sort -n | tr '\n' ' ')
  want=$(seq 1 "$CLAIM_COUNT" | tr '\n' ' ')
  [ "$got" = "$want" ]
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

# --- Claim ID integrity (SKILL.md "Self-check: claim ID integrity") ---

@test "Claims identified section precedes the first verdict" {
  local listed first_verdict
  listed=$(echo "$REPORT_CONTENT" | grep -nE '^## Claims identified' | head -1 | cut -d: -f1)
  first_verdict=$(echo "$REPORT_CONTENT" | grep -nE "$VERDICT_HEADING_RE" | head -1 | cut -d: -f1)
  [ -n "$listed" ]
  [ "$listed" -lt "$first_verdict" ]
}

@test "every identified claim has exactly one verdict and vice versa" {
  local listed verdicts
  listed=$(identified_ids | sort -n | tr '\n' ' ')
  verdicts=$(verdict_ids | sort -n | tr '\n' ' ')
  [ -n "$listed" ]
  [ "$listed" = "$verdicts" ]
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
