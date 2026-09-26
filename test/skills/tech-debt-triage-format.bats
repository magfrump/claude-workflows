#!/usr/bin/env bats
# @category fast
# @needs-reports tech-debt-triage
# Validates the output format of tech-debt-triage reports.
#
# Note: No example report exists yet — tests will skip via load_generic_report.
#
# Usage: Set REPORT_PATH to a generated report, then run:
#   REPORT_PATH=path/to/report.md bats test/skills/tech-debt-triage-format.bats

load helpers

setup() {
  resolve_skill_report tech-debt-triage tc-td1-discount-rules.md
  load_generic_report "$REPORT_PATH"
}

# --- Header section ---

@test "report has a title header with Tech Debt Triage" {
  assert_title_matches '^#{1,2} .*Tech Debt Triage'
}

@test "report has a Location field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Location:\*\*'
}

@test "report has a Nature field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Nature:\*\*'
}

@test "report has a Cost of Deferral field" {
  echo "$REPORT_CONTENT" | grep -qE '\*\*Cost of Deferral:\*\*'
}

@test "cost of deferral uses +X per Y or inert form" {
  # Accept either "+<number> ... per <unit>" or an inert marker (+0 ... inert).
  echo "$REPORT_CONTENT" | grep -E '\*\*Cost of Deferral:\*\*' \
    | grep -qiE '(\+[0-9]+(\.[0-9]+)?.*\bper\b|\+0.*inert|\binert\b)'
}

# --- Required sections ---

@test "report has Carrying Cost section" {
  assert_heading_exists "Carrying Cost"
}

@test "carrying cost uses allowed values" {
  # SKILL.md: "### Carrying Cost: {High / Medium / Low}". The value is the
  # heading's, as a whole word: the old unanchored check matched "low" inside
  # "follow" anywhere on any line naming Carrying Cost.
  local headings bad
  headings=$(echo "$REPORT_CONTENT" | grep -E '^#{2,4} Carrying Cost' || true)
  [ -n "$headings" ]
  bad=$(echo "$headings" | grep -vE '^#{2,4} Carrying Cost:[[:space:]]*\**(High|Medium|Low)\**([^[:alpha:]]|$)' || true)
  [ -z "$bad" ] || { echo "Carrying Cost headings without a High/Medium/Low value: $bad"; return 1; }
}

@test "report has Fix Cost section" {
  assert_heading_exists "Fix Cost"
}

@test "fix cost has Scope field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Scope:\*\*.*\b(localized|cross-cutting|systemic)\b'
}

@test "fix cost has Effort field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Effort:\*\*.*\b(hours|days|weeks)\b'
}

@test "fix cost has Risk field" {
  echo "$REPORT_CONTENT" | grep -qiE '\*\*Risk:\*\*.*\b(low|medium|high)\b'
}

@test "report has Urgency Triggers section" {
  assert_heading_exists "Urgency Triggers"
}

@test "report has Recommendation section" {
  assert_heading_exists "Recommendation"
}

@test "recommendation uses one of the four allowed values" {
  # SKILL.md: each **Recommendation:** is exactly one of the four values,
  # verbatim. Every such line must lead with one and name no other.
  local lines line n v
  lines=$(echo "$REPORT_CONTENT" | grep -E '^[[:space:]]*\*\*Recommendation:\*\*' || true)
  [ -n "$lines" ]
  while IFS= read -r line; do
    echo "$line" | grep -qE '^[[:space:]]*\*\*Recommendation:\*\*[[:space:]]*\**(Fix now|Fix opportunistically|Carry intentionally|Defer and monitor)\**([^[:alpha:]]|$)' \
      || { echo "Not led by an allowed value: $line"; return 1; }
    n=0
    for v in 'Fix now' 'Fix opportunistically' 'Carry intentionally' 'Defer and monitor'; do
      [[ "$line" == *"$v"* ]] && n=$((n + 1))
    done
    [ "$n" -eq 1 ] || { echo "More than one verdict: $line"; return 1; }
  done <<< "$lines"
}

# --- No leakage ---

@test "report does not use dependency-upgrade recommendation verbs" {
  # Guard against borrowed enums from the dependency-upgrade skill, which is the
  # nearest decision-helper sibling and the most likely source of vocabulary drift.
  ! echo "$REPORT_CONTENT" | grep -qE '\*\*Recommendation:\*\* (Upgrade now|Upgrade soon|Don.t upgrade)\b'
}

@test "report does not contain fact-check verdict language" {
  ! echo "$REPORT_CONTENT" | grep -qiE '^\*\*Verdict:\*\* (Accurate|Mostly accurate|Disputed|Inaccurate|Unverified)$'
}
