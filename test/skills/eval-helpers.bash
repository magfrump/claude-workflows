# Shared helpers for skill eval BATS tests (fact-check, code-fact-check, and
# every skill with a fixture set under test/skills/<skill>/fixtures/).
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

# ERE matching one claim heading in a skill's report. Each skill's SKILL.md fixes
# the shape: fact-check heads verdicts '## Verdict for C<N>: "..."'; code-fact-check
# heads claims '## Claim <N>' (sub-claims '## Claim <N>a').
# Args: $1 = skill name
claim_heading_re() {
  case "$1" in
    fact-check) echo '^## Verdict for C[0-9]+' ;;
    *) echo '^## Claim [0-9]+' ;;
  esac
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
  CLAIM_COUNT=$(echo "$REPORT_CONTENT" | grep -cE "$(claim_heading_re "$skill")" || true)
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

  # Run each check (separated by ;; in KEY_CHECK values). Every check runs and
  # any failure fails the call, so the result holds under bats' `run` and in
  # conditionals, not only under a test body's errexit.
  local checks check failed=""
  IFS=';' read -ra checks <<< "$key_check"
  for check in "${checks[@]}"; do
    # Skip empty tokens from IFS splitting
    [ -n "$check" ] || continue
    case "$check" in
      verdict_match)
        assert_verdict "$expected_verdict" || failed=1
        ;;
      severity_match)
        assert_severity "$expected_verdict" || failed=1
        ;;
      no_severity:*)
        assert_no_severity "${check#no_severity:}" || failed=1
        ;;
      no_verdict:*)
        assert_no_verdict "${check#no_verdict:}" || failed=1
        ;;
      field_match:*)
        local spec="${check#field_match:}"
        assert_field "${spec%%=*}" "${spec#*=}" || failed=1
        ;;
      no_field:*)
        local spec="${check#no_field:}"
        assert_no_field "${spec%%=*}" "${spec#*=}" || failed=1
        ;;
      cites_pattern:*)
        local pattern="${check#cites_pattern:}"
        assert_report_matches "$pattern" || failed=1
        ;;
      no_pattern:*)
        assert_report_not_matches "${check#no_pattern:}" || failed=1
        ;;
      no_critique)
        assert_no_critique || failed=1
        ;;
      max_claims:*)
        local n="${check#max_claims:}"
        assert_max_claims "$n" || failed=1
        ;;
      min_claims:*)
        local n="${check#min_claims:}"
        assert_min_claims "$n" || failed=1
        ;;
      web_search_used)
        # With --tools restriction, web search is the only tool available
        # for fact-check, so if we got results, search was used.
        # For explicit verification, check that sources are cited.
        assert_report_matches "Sources" || failed=1
        ;;
      format_check)
        # Delegate to the format BATS suite (fact-check-format.bats or code-fact-check-format.bats)
        REPORT_PATH="$REPORT_PATH" bats "${BATS_TEST_DIRNAME}/${skill}-format.bats" || failed=1
        ;;
      *)
        echo "Unknown check type: $check"
        failed=1
        ;;
    esac
  done
  [ -z "$failed" ]
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
  verdicts=$(field_values Verdict)
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

# Assert at least one finding carries a severity from the allowed set. Reviewer
# skills tag each finding "**Severity:** <tier>", sometimes with a trailing
# qualifier ("High (executed)"), so only the leading word is compared.
# Args: $1 = pipe-separated allowed severities (e.g., "Critical|High")
assert_severity() {
  local allowed="$1"
  [ "$allowed" = "Any" ] && return 0

  local severities
  severities=$(field_values Severity)
  [ -n "$severities" ] || { echo "No **Severity:** lines found in report"; return 1; }

  if ! echo "$severities" | grep -qiE "^(${allowed})([^[:alpha:]]|$)"; then
    echo "Expected a severity matching /${allowed}/, got: $(echo "$severities" | tr '\n' ', ')"
    return 1
  fi
}

# Assert no finding carries a severity from the given set — the false-positive
# check for clean fixtures. A report with no **Severity:** lines passes.
# Args: $1 = pipe-separated forbidden severities (e.g., "Critical|High")
assert_no_severity() {
  local forbidden="$1" hits
  hits=$(field_values Severity \
    | grep -iE "^(${forbidden})([^[:alpha:]]|$)" || true)
  if [ -n "$hits" ]; then
    echo "Expected no severity matching /${forbidden}/, got: $(echo "$hits" | tr '\n' ', ')"
    return 1
  fi
}

# Assert no **Verdict:** line carries a value from the given set — the
# false-positive check for sound fixtures in skills that grade lenses
# (business-plan-critique-moat's Durable/Plausible/Weak/Absent). A report with
# no **Verdict:** lines passes. Only the leading word(s) are compared, as in
# assert_no_severity.
# Args: $1 = pipe-separated forbidden verdicts (e.g., "Weak|Absent")
assert_no_verdict() {
  local forbidden="$1" hits
  hits=$(field_values Verdict \
    | grep -iE "^(${forbidden})([^[:alpha:]]|$)" || true)
  if [ -n "$hits" ]; then
    echo "Expected no verdict matching /${forbidden}/, got: $(echo "$hits" | tr '\n' ', ')"
    return 1
  fi
}

# Values of every "**<Field>:** value" line in the report, one per line, with
# \r stripped. The label may sit at the start of the line or after a list
# bullet ("- **Severity:** High"), since some skills' templates (pre-mortem,
# what-if-analysis) lay their graded fields out as bullets. Used by every
# field-reading check: Verdict, Severity, and field_match's arbitrary fields
# (tech-debt-triage's **Recommendation:**, test-strategy's **Priority:**).
# Args: $1 = field name, e.g. "Recommendation"
field_values() {
  local field="$1"
  echo "$REPORT_CONTENT" | tr -d '\r' \
    | sed -E -n "s/^[[:space:]]*([-*+][[:space:]]+)?\*\*${field}:\*\* //p"
}

# Assert at least one **<Field>:** line starts with one of the allowed values.
# Check syntax: field_match:Recommendation=Fix now|Fix opportunistically
# Args: $1 = field name, $2 = pipe-separated allowed values
assert_field() {
  local field="$1" allowed="$2" values
  values=$(field_values "$field")
  [ -n "$values" ] || { echo "No **${field}:** lines found in report"; return 1; }
  if ! echo "$values" | grep -qiE "^(${allowed})([^[:alpha:]]|$)"; then
    echo "Expected a ${field} matching /${allowed}/, got: $(echo "$values" | tr '\n' ', ')"
    return 1
  fi
}

# Assert no **<Field>:** line starts with one of the forbidden values. A report
# without the field passes. Check syntax: no_field:Recommendation=Fix now
# Args: $1 = field name, $2 = pipe-separated forbidden values
assert_no_field() {
  local field="$1" forbidden="$2" hits
  hits=$(field_values "$field" | grep -iE "^(${forbidden})([^[:alpha:]]|$)" || true)
  if [ -n "$hits" ]; then
    echo "Expected no ${field} matching /${forbidden}/, got: $(echo "$hits" | tr '\n' ', ')"
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

# Assert the report body does not match a case-insensitive pattern — e.g. a
# stub draft's report must not carry the full critique's section headings, and a
# complete short draft's report must not carry the stub-skip line.
assert_report_not_matches() {
  local pattern="$1" hits
  hits=$(echo "$REPORT_CONTENT" | grep -iE "$pattern" || true)
  if [ -n "$hits" ]; then
    echo "Report matches forbidden pattern /${pattern}/: $(echo "$hits" | head -3)"
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
