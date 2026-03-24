# Shared helpers for fact-check and code-fact-check BATS tests.
# Load with: load helpers  (from the same directory)

# Call in setup() to load the report and precompute common values.
# Args: $1 = default report path
load_report() {
  REPORT="${REPORT_PATH:-$1}"
  if [ ! -f "$REPORT" ]; then
    skip "No report found at $REPORT — generate one first"
  fi
  REPORT_CONTENT=$(cat "$REPORT")
  CLAIM_COUNT=$(echo "$REPORT_CONTENT" | grep -cE '^## Claim [0-9]+' || true)
  if [ "$CLAIM_COUNT" -eq 0 ]; then
    skip "Report has no claims"
  fi
  ATTENTION_SECTION=$(echo "$REPORT_CONTENT" | sed -n '/^## Claims Requiring/,$p')
}

# Assert that every claim section has a given field (e.g., "Verdict", "Confidence").
assert_field_per_claim() {
  local field="$1"
  local field_count
  field_count=$(echo "$REPORT_CONTENT" | grep -cE "^\\*\\*${field}:\\*\\*" || true)
  [ "$CLAIM_COUNT" -eq "$field_count" ]
}

# Assert every value of a field matches an allowed-values regex.
# Uses grep -v to find violations (no -oP dependency).
# Args: $1 = field name, $2 = case-insensitive regex of allowed values
assert_field_values() {
  local field="$1" allowed="$2"
  local values bad
  values=$(echo "$REPORT_CONTENT" | sed -n "s/^\\*\\*${field}:\\*\\* //p")
  [ -n "$values" ] || skip "no ${field} values found"
  bad=$(echo "$values" | grep -viE "^(${allowed})$" || true)
  [ -z "$bad" ]
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
