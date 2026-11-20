#!/usr/bin/env bats
# @category fast
# assert_recommendation_per_tiered_finding (helpers.bash), used by the
# architecture-review and ui-visual-review format suites: every finding whose
# Severity is not Informational needs its own Recommendation line. A count
# comparison let an Informational finding's Recommendation stand in for a
# tiered finding's missing one (review of fix/skill-verdict-drift, S3).

load helpers

setup() {
  TEST_TMPDIR=$(mktemp -d)
}

teardown() {
  rm -rf -- "$TEST_TMPDIR"
}

# report <finding>...: each argument is "Severity|has-rec" (has-rec 1 or 0).
report() {
  local spec n=0
  {
    printf '%s\n\n%s\n\n' '# Review' '## Findings'
    for spec in "$@"; do
      n=$((n + 1))
      printf '#### %s. Finding %s\n\n**Severity:** %s\n\nBody.\n\n' "$n" "$n" "${spec%%|*}"
      [ "${spec#*|}" = 1 ] && printf '**Recommendation:** Fix it.\n\n'
    done
    printf '%s\n\nAll good.\n' '## What Looks Good'
  } > "$TEST_TMPDIR/r.md"
  REPORT_CONTENT="$(cat "$TEST_TMPDIR/r.md")"
  count_findings
}

@test "passes when every tiered finding has a Recommendation" {
  report "Major|1" "Minor|1" "Informational|0"
  assert_recommendation_per_tiered_finding
}

@test "fails a tiered finding without one, even when an Informational finding has one" {
  report "Major|0" "Informational|1"
  run assert_recommendation_per_tiered_finding
  [ "$status" -ne 0 ]
  [[ "$output" == *"#### 1. Finding 1"* ]]
}

@test "fails a Minor finding without one" {
  report "Critical|1" "Minor|0"
  run assert_recommendation_per_tiered_finding
  [ "$status" -ne 0 ]
  [[ "$output" == *"#### 2. Finding 2"* ]]
}

@test "reads ### finding headings too" {
  # shellcheck disable=SC2034  # read by count_findings (helpers.bash)
  REPORT_CONTENT="$(printf '%s\n' '# Review' '' '## Findings' '' '### 1. A' '' '**Severity:** Structural' '' 'Body.' '' '## Summary Table')"
  count_findings
  run assert_recommendation_per_tiered_finding
  [ "$status" -ne 0 ]
  [[ "$output" == *"### 1. A"* ]]
}

@test "accepts Informational with trailing text and the **Recommendation**: form" {
  # shellcheck disable=SC2034  # read by count_findings (helpers.bash)
  REPORT_CONTENT="$(printf '%s\n' '# Review' '' '### Findings' '' '#### A' '' '**Severity:** Informational (hardening note)' '' 'Body.' '' '#### B' '' '**Severity:** Minor' '' '**Recommendation**: Fix it.' '' '### What Looks Good')"
  count_findings
  assert_recommendation_per_tiered_finding
}
