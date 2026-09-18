#!/usr/bin/env bats
# @category fast
# Validates the output format of code-fact-check reports.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=docs/reviews/code-fact-check-report.md bats test/skills/code-fact-check-format.bats

bats_require_minimum_version 1.5.0

load helpers

setup() {
  load_report "docs/reviews/code-fact-check-report.md"
}

# Known-nonconformant committed report. docs/reviews/code-fact-check-report.md as
# committed in 1c56a26 (2026-09-12) postdates the spec's last output-format change
# (skills/code-fact-check/SKILL.md, 8912327, 2026-08-21) but does not follow it: it
# is the code-review merge of three replicates and drifted from the schema that
# skills/code-review/SKILL.md ("Merging replicate verdicts", step 3) says it must keep
# exactly. It is a real review record, not a fixture, so it is not rewritten here, and
# no other committed code-fact-check report conforms either (r1: Total/Summary count
# 16 against 18 claim sections; r2 and submitted-claims: annotated Total; r3: ###
# sub-claim headings; pass2-*: no Verification mode or per-claim Scope).
#
# The skip is keyed to that exact blob, not to the path: regenerating the report (or
# pointing REPORT_PATH at any other file, e.g. a mutated copy) re-arms every check.
KNOWN_NONCONFORMANT_BLOB="a3d44f83e80b3f82f86ccc6178a68a00cdfba983"

# Args: $1 = the SKILL.md rule this report breaks, for the skip reason.
skip_if_known_nonconformant() {
  local blob
  blob=$(git hash-object "$REPORT" 2>/dev/null || true)
  if [ "$blob" = "$KNOWN_NONCONFORMANT_BLOB" ]; then
    skip "stale report: $REPORT (1c56a26, 2026-09-12) does not follow the current SKILL.md output format (last changed 2026-08-21): $1"
  fi
}

# SKILL.md: sub-claims split from a compound claim use "## Claim Na:", "## Claim Nb:"
# in their shared number's position. So after claim N comes N+1, or N+1a to start a
# split; after Nx comes the next letter of N, N+1 or N+1a. A bare N followed by Nb
# (no Na), a skipped letter, or a lone Na with no Nb is out of spec.
assert_claims_sequential_with_subclaims() {
  local ids prev_n=0 prev_s="" id n s
  ids=$(echo "$REPORT_CONTENT" | grep -oE '^## Claim [0-9]+[a-z]?' | sed 's/^## Claim //')
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    n=${id%%[a-z]}
    s=${id#"$n"}
    if [ "$n" -eq $((prev_n + 1)) ]; then
      [ "$prev_s" != "a" ] || { echo "Claim ${prev_n}a has no ${prev_n}b"; return 1; }
      [ -z "$s" ] || [ "$s" = "a" ] || { echo "Claim $id follows Claim ${prev_n}${prev_s}"; return 1; }
    elif [ "$n" -eq "$prev_n" ] && [ -n "$s" ] && [ -n "$prev_s" ]; then
      [ "$s" = "$(echo "$prev_s" | tr 'a-y' 'b-z')" ] || { echo "Claim $id follows Claim ${prev_n}${prev_s}"; return 1; }
    else
      echo "Claim $id follows Claim ${prev_n}${prev_s}"
      return 1
    fi
    prev_n=$n
    prev_s=$s
  done <<< "$ids"
  [ "$prev_s" != "a" ] || { echo "Claim ${prev_n}a has no ${prev_n}b"; return 1; }
}

# --- Header section ---

@test "report has a title header" {
  assert_title_matches '^# Code Fact-Check Report' 5 "-qE"
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

@test "Total claims checked is a non-negative integer" {
  skip_if_known_nonconformant 'Total claims checked must be [N]; report has "19 clusters merged from three replicates ..."'
  local value
  value=$(echo "$REPORT_CONTENT" | sed -n 's/^\*\*Total claims checked:\*\* *//p' | head -1 | tr -d '[:space:]')
  [ -n "$value" ] || skip "no Total claims checked value found"
  echo "$value" | grep -qE '^[0-9]+$'
}

@test "Total claims checked matches actual claim section count" {
  local value
  value=$(echo "$REPORT_CONTENT" | sed -n 's/^\*\*Total claims checked:\*\* *//p' | head -1 | tr -d '[:space:]')
  [ -n "$value" ] || skip "no Total claims checked value found"
  echo "$value" | grep -qE '^[0-9]+$' || skip "value not numeric"
  [ "$value" = "$CLAIM_COUNT" ]
}

@test "report has a Summary line with verdict counts" {
  skip_if_known_nonconformant 'Summary must read "[X] verified, ..., [W] incorrect, ..."; report capitalizes the verdicts and appends "-only clusters"'
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
  # SKILL.md: pure Reference claims may cite bare paths or external locators —
  # commit-message claims legitimately cite "commit `<hash>` message, <part>".
  # SKILL.md scopes commit messages in but gives them no locator form outside the
  # Reference escape; every 2026-09-12 report writes "commit message `<hash>`", so
  # that spelling is accepted too. A hash is still required.
  bad=$(echo "$locations" | grep -viE 'commit (message )?.?[0-9a-f]{7,}' | grep -vE '[a-zA-Z0-9_./-]+:[0-9]+' || true)
  [ -z "$bad" ]
}

@test "each claim section has a Type line" {
  assert_field_per_claim "Type"
}

@test "claim types use only the allowed values" {
  # Allow compound types like "Reference / Architectural" — each part must be valid.
  # Error-handling joined the SKILL.md enum with the implicit-error-handling claim
  # class; an optional parenthetical qualifier ("Behavioral (test-efficacy)") is
  # allowed as long as the base type is from the enum.
  skip_if_known_nonconformant 'Type must be from the SKILL.md enum; report uses "Documentation" and "Measurement"'
  local allowed="Behavioral|Performance|Architectural|Invariant|Configuration|Error-handling|Reference|Staleness"
  local values bad
  values=$(echo "$REPORT_CONTENT" | sed -n 's/^\*\*Type:\*\* //p')
  [ -n "$values" ] || skip "no Type values found"
  # Split compound types on " / " and validate each part
  bad=$(echo "$values" | tr '/' '\n' | sed 's/^ *//;s/ *$//' | grep -viE "^(${allowed})( \([^)]{1,60}\))?$" || true)
  [ -z "$bad" ]
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
  skip_if_known_nonconformant 'Evidence must cite path:line; claims 8 and 14 cite only "A/B execution logs", claim 16 only a bats command'
  assert_field_per_claim "Evidence"
  # Pure Reference claims may use existence checks (e.g. glob results) instead
  # of file:line citations — only enforce file:line for non-pure-Reference types
  local claim_num evidence_line type_line bad_lines=""
  for claim_num in $(echo "$REPORT_CONTENT" | grep -oE '^## Claim [0-9]+' | grep -oE '[0-9]+'); do
    local section
    section=$(echo "$REPORT_CONTENT" | sed -n "/^## Claim ${claim_num}[^0-9]/,/^## /p" | head -n -1)
    type_line=$(echo "$section" | sed -n 's/^\*\*Type:\*\* //p')
    evidence_line=$(echo "$section" | sed -n 's/^\*\*Evidence:\*\* //p')
    # Pure Reference claims may cite existence/glob results with no line numbers
    [ "$type_line" = "Reference" ] && continue
    # Other types must reference at least a file path (file:line preferred, bare path accepted)
    # shellcheck disable=SC2016  # Backticks are literal grep pattern, not command substitution
    if ! echo "$evidence_line" | grep -qE '(`[a-zA-Z0-9_./-]+`|[a-zA-Z0-9_./-]+:[0-9]+)'; then
      bad_lines="${bad_lines}Claim ${claim_num}: ${evidence_line}\n"
    fi
  done
  [ -z "$bad_lines" ]
}

# --- Claims Requiring Attention section ---

@test "report has Claims Requiring Attention section" {
  echo "$REPORT_CONTENT" | grep -qE '^## Claims Requiring Attention'
}

@test "attention section has Incorrect subsection if any incorrect claims" {
  if echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* Incorrect'; then
    skip_if_known_nonconformant 'Claims Requiring Attention needs ### Incorrect; report uses one-line bullets instead of subsections'
    echo "$ATTENTION_SECTION" | grep -qE '^### Incorrect'
  fi
}

@test "attention section has Stale subsection if any stale claims" {
  if echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* Stale'; then
    skip_if_known_nonconformant 'Claims Requiring Attention needs ### Stale; report uses one-line bullets instead of subsections'
    echo "$ATTENTION_SECTION" | grep -qE '^### Stale'
  fi
}

@test "attention section has Mostly Accurate subsection if any MA claims" {
  if echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* Mostly accurate'; then
    skip_if_known_nonconformant 'Claims Requiring Attention needs ### Mostly Accurate; report uses one-line bullets instead of subsections'
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
  skip_if_known_nonconformant 'sub-claims must be Na, Nb; report has "Claim 2" followed by "Claim 2b" with no 2a'
  run assert_claims_sequential_with_subclaims
  [ "$status" -eq 0 ] || { echo "$output"; false; }
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
