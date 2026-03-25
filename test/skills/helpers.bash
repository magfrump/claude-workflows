# Shared helpers for skill output BATS tests.
# Load with: load helpers  (from the same directory)
#
# Most tests require a generated report to exist. Without one, tests skip
# gracefully. To run a specific test suite, generate the report first via
# the corresponding skill, then point REPORT_PATH at it:
#   REPORT_PATH=path/to/report.md bats test/skills/<skill>-format.bats
# To generate all reports, see test/skills/generate-reports.bash.

# Call in setup() to load a claim-based report and precompute common values.
# Args: $1 = default report path
load_report() {
  REPORT="${REPORT_PATH:-$1}"
  if [ ! -f "$REPORT" ]; then
    skip "No report found at $REPORT — generate one first"
  fi
  REPORT_CONTENT=$(tr -d '\r' < "$REPORT")
  CLAIM_COUNT=$(echo "$REPORT_CONTENT" | grep -cE '^## Claim [0-9]+' || true)
  if [ "$CLAIM_COUNT" -eq 0 ]; then
    skip "Report has no claims"
  fi
  # Extract only the claims sections (from first claim to the summary/attention
  # section) so field-counting helpers aren't thrown off by metadata fields that
  # share the same name (e.g. **Confidence:** in a report header).
  CLAIMS_BODY=$(echo "$REPORT_CONTENT" | sed -n '/^## Claim [0-9]/,/^## [^C]/p' | sed '$d')
  if [ -z "$CLAIMS_BODY" ]; then
    # Fallback: claims run to end of file (no trailing non-Claim ## heading).
    CLAIMS_BODY=$(echo "$REPORT_CONTENT" | sed -n '/^## Claim [0-9]/,$p')
  fi
  ATTENTION_SECTION=$(echo "$REPORT_CONTENT" | sed -n '/^## Claims Requiring/,$p')
}

# Call in setup() to load any report without requiring claims.
# Args: $1 = default report path
load_generic_report() {
  REPORT="${REPORT_PATH:-$1}"
  if [ ! -f "$REPORT" ]; then
    skip "No report found at $REPORT — generate one first"
  fi
  REPORT_CONTENT=$(tr -d '\r' < "$REPORT")
  if [ -z "$REPORT_CONTENT" ]; then
    skip "Report is empty"
  fi
}

# Count findings in reviewer-style reports (### N. or #### N. Title).
# Extracts FINDINGS_BODY scoped from the first finding heading to the next
# ## section (e.g., What Looks Good, Summary Table), mirroring how CLAIMS_BODY
# is scoped in load_report. Falls back to first-finding-to-EOF if no trailing
# ## heading follows the findings.
count_findings() {
  FINDING_COUNT=$(echo "$REPORT_CONTENT" | grep -cE '^#{3,4} [0-9]+\.' || true)
  # Extract from first finding to the next ## heading that isn't a finding
  FINDINGS_BODY=$(echo "$REPORT_CONTENT" | sed -nE '/^#{3,4} [0-9]+\./,/^## [^#]/p' | sed '$d')
  if [ -z "$FINDINGS_BODY" ]; then
    # Fallback: findings run to end of file (no trailing ## heading).
    FINDINGS_BODY=$(echo "$REPORT_CONTENT" | sed -nE '/^#{3,4} [0-9]+\./,$p')
  fi
}

# Assert that every finding has a given field.
# Counts only within FINDINGS_BODY (set by count_findings) to avoid
# false matches from report-level metadata sharing the same field name.
assert_field_per_finding() {
  local field="$1"
  local field_count
  field_count=$(echo "$FINDINGS_BODY" | grep -cE "^\\*\\*${field}:\\*\\*" || true)
  [ "$FINDING_COUNT" -eq "$field_count" ]
}

# Assert a section (## heading) exists in the report.
assert_section_exists() {
  local heading="$1"
  echo "$REPORT_CONTENT" | grep -qE "^## ${heading}"
}

# Assert a section (any heading level) exists, case-insensitive.
assert_heading_exists() {
  local pattern="$1"
  echo "$REPORT_CONTENT" | grep -qiE "^#{1,4} .*${pattern}"
}

# Assert that every claim section has a given field (e.g., "Verdict", "Confidence").
# Counts only within CLAIMS_BODY (set by load_report) to avoid
# false matches from report-level metadata sharing the same field name.
assert_field_per_claim() {
  local field="$1"
  local field_count
  field_count=$(echo "$CLAIMS_BODY" | grep -cE "^\\*\\*${field}:\\*\\*" || true)
  [ "$CLAIM_COUNT" -eq "$field_count" ]
}

# Assert every value of a field matches an allowed-values regex.
# Uses grep -v to find violations (no -oP dependency).
# Searches FINDINGS_BODY or CLAIMS_BODY when available, falling back to
# REPORT_CONTENT, so field matches stay scoped consistently with the
# per-finding/per-claim counters.
# Args: $1 = field name, $2 = case-insensitive regex of allowed values
assert_field_values() {
  local field="$1" allowed="$2"
  local body values bad
  if [ -n "${FINDINGS_BODY:-}" ]; then
    body="$FINDINGS_BODY"
  elif [ -n "${CLAIMS_BODY:-}" ]; then
    body="$CLAIMS_BODY"
  else
    body="$REPORT_CONTENT"
  fi
  values=$(echo "$body" | sed -n "s/^\\*\\*${field}:\\*\\* //p")
  [ -n "$values" ] || skip "no ${field} values found"
  bad=$(echo "$values" | grep -viE "^(${allowed})$" || true)
  [ -z "$bad" ]
}

# Assert the report contains at least one match for a keyword pattern.
# Used by dimension-checking tests to verify analytical perspectives.
# Args: $1 = dimension name (for error messages), $2 = grep -iE pattern
assert_dimension_present() {
  local dimension="$1" pattern="$2"
  if ! echo "$REPORT_CONTENT" | grep -qiE "$pattern"; then
    echo "Dimension '$dimension' not found — expected pattern: $pattern"
    return 1
  fi
}

# Assert claim numbers are sequential (1, 2, 3, ...).
assert_claims_sequential() {
  local numbers prev=0 n
  numbers=$(echo "$REPORT_CONTENT" | grep -oE '^## Claim [0-9]+' | grep -oE '[0-9]+')
  while IFS= read -r n; do
    [ "$n" -eq $((prev + 1)) ]
    prev=$n
  done <<< "$numbers"
}
