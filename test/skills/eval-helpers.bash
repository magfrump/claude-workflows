# Shared helpers for fact-check and code-fact-check eval BATS tests.
# Load with: load eval-helpers

# Load expected verdicts for a skill. Must be called before eval_fixture.
# Declares global associative arrays.
# Args: $1 = skill name (fact-check or code-fact-check)
load_expected_verdicts() {
  local skill="$1"
  local verdicts_file="${BATS_TEST_DIRNAME}/${skill}/expected-verdicts.bash"
  if [ ! -f "$verdicts_file" ]; then
    echo "expected-verdicts.bash not found for skill: $skill" >&2
    return 1
  fi
  # Source in current scope — declare -A in the file creates the arrays here
  # shellcheck disable=SC1090  # Path is dynamic but always expected-verdicts.bash
  source "$verdicts_file"
}

# Load a generated report for a given fixture.
# Sets: REPORT_CONTENT, CLAIM_COUNT, REPORT_PATH
# Skips the test if the report hasn't been generated yet.
load_eval_report() {
  local skill="$1" fixture="$2"
  REPORT_PATH="${BATS_TEST_DIRNAME}/${skill}/output/${fixture}.report.md"

  if [ ! -f "$REPORT_PATH" ]; then
    skip "No report for ${fixture} — run generate-reports.bash first"
  fi
  if [ ! -s "$REPORT_PATH" ]; then
    # Empty report = 0 claims. Don't skip — let assertions run so that
    # negative test fixtures (e.g., empty-file inputs) actually verify
    # the max_claims:0 expectation instead of silently passing via skip.
    REPORT_CONTENT=""
    CLAIM_COUNT=0
    return 0
  fi

  REPORT_CONTENT="$(cat "$REPORT_PATH")"
  CLAIM_COUNT=$(echo "$REPORT_CONTENT" | grep -cE '^## Claim [0-9]+' || true)
}

# All-in-one: load report + run all checks for a fixture.
# This avoids associative array subscript issues in BATS by doing all lookups
# inside this function where the arrays are in scope.
# Args: $1 = skill, $2 = fixture filename
eval_fixture() {
  local skill="$1" fixture="$2"

  load_eval_report "$skill" "$fixture"

  # Look up expected values — quoting keys to avoid arithmetic interpretation
  # shellcheck disable=SC2153  # EXPECTED_VERDICT and KEY_CHECK are sourced from expected-verdicts.bash
  local expected_verdict="${EXPECTED_VERDICT["$fixture"]}"
  # shellcheck disable=SC2153
  local key_check="${KEY_CHECK["$fixture"]}"

  if [ -z "$key_check" ]; then
    echo "No KEY_CHECK entry for fixture: $fixture"
    return 1
  fi

  # Run each check (separated by ;; in KEY_CHECK values)
  local old_ifs="$IFS"
  IFS=';;'
  for check in $key_check; do
    # Skip empty tokens from IFS splitting
    [ -n "$check" ] || continue
    case "$check" in
      verdict_match)
        assert_verdict "$expected_verdict"
        ;;
      cites_pattern:*)
        local pattern="${check#cites_pattern:}"
        assert_report_matches "$pattern"
        ;;
      no_critique)
        assert_no_critique
        ;;
      max_claims:*)
        local n="${check#max_claims:}"
        assert_max_claims "$n"
        ;;
      min_claims:*)
        local n="${check#min_claims:}"
        assert_min_claims "$n"
        ;;
      web_search_used)
        # With --tools restriction, web search is the only tool available
        # for fact-check, so if we got results, search was used.
        # For explicit verification, check that sources are cited.
        assert_report_matches "Sources"
        ;;
      format_check)
        # Delegate to the format BATS suite (fact-check-format.bats or code-fact-check-format.bats)
        REPORT_PATH="$REPORT_PATH" bats "${BATS_TEST_DIRNAME}/${skill}-format.bats" || return 1
        ;;
      *)
        echo "Unknown check type: $check"
        return 1
        ;;
    esac
  done
  IFS="$old_ifs"
}

# --- Individual assertion functions ---

# Assert the report contains a verdict matching one of the allowed values.
# Args: $1 = pipe-separated allowed verdicts (e.g., "Accurate|Mostly accurate")
#       "Any" matches anything; "skip" skips the verdict check.
assert_verdict() {
  local allowed="$1"
  [ "$allowed" = "Any" ] && return 0
  [ "$allowed" = "skip" ] && return 0

  local verdicts
  verdicts=$(echo "$REPORT_CONTENT" | sed -n 's/^\*\*Verdict:\*\* //p')
  [ -n "$verdicts" ] || { echo "No verdicts found in report"; return 1; }

  # For single-claim fixtures, check the verdict directly.
  # For multi-claim fixtures, at least one verdict must match.
  local found=false
  while IFS= read -r v; do
    # Strip trailing whitespace/carriage returns
    v=$(echo "$v" | tr -d '\r' | sed 's/[[:space:]]*$//')
    if echo "$v" | grep -qiE "^(${allowed})$"; then
      found=true
      break
    fi
  done <<< "$verdicts"

  if [ "$found" = false ]; then
    echo "Expected verdict matching /${allowed}/, got: $(echo "$verdicts" | tr '\n' ', ')"
    return 1
  fi
}

# Assert the report body matches a case-insensitive pattern.
assert_report_matches() {
  local pattern="$1"
  if ! echo "$REPORT_CONTENT" | grep -qiE "$pattern"; then
    echo "Report does not match pattern: $pattern"
    return 1
  fi
}

# Assert the report does not contain critique/argument-quality language.
assert_no_critique() {
  local bad
  bad=$(echo "$REPORT_CONTENT" | grep -iE '(should consider|weak argument|poor reasoning|could be stronger|needs improvement|argument quality)' || true)
  if [ -n "$bad" ]; then
    echo "Report contains critique language: $bad"
    return 1
  fi
}

# Assert claim count is at most N.
assert_max_claims() {
  local max="$1"
  if [ "$CLAIM_COUNT" -gt "$max" ]; then
    echo "Expected at most $max claims, got $CLAIM_COUNT"
    return 1
  fi
}

# Assert claim count is at least N.
assert_min_claims() {
  local min="$1"
  if [ "$CLAIM_COUNT" -lt "$min" ]; then
    echo "Expected at least $min claims, got $CLAIM_COUNT"
    return 1
  fi
}
