#!/usr/bin/env bats
# @category fast
# eval_fixture must not score a failed generation as a pass. generate-reports.bash
# leaves an empty report when claude fails, and the absence-only checks
# (no_severity:, no_verdict:, no_field:, no_pattern:) all pass on empty text, so
# every clean-negative fixture would pass on a dead run. The generator records
# the failure in <fixture>.failed, which eval_fixture honors even when the report
# holds text. Only max_claims:0 fixtures (an empty input file) may legitimately
# have an empty report without one.

load eval-helpers

bats_require_minimum_version 1.5.0

setup() {
  TEST_TMPDIR=$(mktemp -d)
  # A throwaway repo layout: eval_fixture reads <skills_test_dir>/demo/ and
  # stamps against ../../skills/demo/, so both live under TEST_TMPDIR.
  SK="$TEST_TMPDIR/test/skills"
  mkdir -p "$SK/demo/output" "$SK/demo/fixtures" "$TEST_TMPDIR/skills/demo"
  cp "$BATS_TEST_DIRNAME/runner-contract.bash" "$SK/"
  echo "# demo skill" > "$TEST_TMPDIR/skills/demo/SKILL.md"
  echo "FIXTURE_TOOLS=none" > "$SK/demo/runner.bash"
  echo "query = 'SELECT 1'" > "$SK/demo/fixtures/tc-clean.py"
  : > "$SK/demo/fixtures/tc-empty-input.js"
  cat > "$SK/demo/expected-verdicts.bash" <<'EOF'
declare -gA EXPECTED_VERDICT KEY_CHECK
EXPECTED_VERDICT["tc-clean.py"]="None"
KEY_CHECK["tc-clean.py"]="no_severity:Critical|High;no_pattern:injection;cites_pattern:no findings"
EXPECTED_VERDICT["tc-empty-input.js"]="None"
KEY_CHECK["tc-empty-input.js"]="max_claims:0"
EOF
  # eval_fixture resolves verdicts and reports relative to the suite's
  # directory; point it at the throwaway skill instead.
  # shellcheck disable=SC2034  # read by eval-helpers.bash
  BATS_TEST_DIRNAME="$SK"
  # max_claims:0 alone is an absence check; allowlist it like the real ones.
  # shellcheck disable=SC2034  # read by eval-helpers.bash
  NEGATIVE_ONLY_ALLOWLIST=(demo/tc-empty-input.js)
  load_expected_verdicts demo
}

# stamp <fixture>: the provenance stamp generate-reports.bash would write.
stamp() {
  report_stamp "$SK" demo "$1" > "$SK/demo/output/$1.stamp"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "an empty report fails a clean-negative fixture" {
  : > "$SK/demo/output/tc-clean.py.report.md"
  stamp tc-clean.py
  run eval_fixture demo tc-clean.py
  [ "$status" -ne 0 ]
  [[ "$output" == *"Empty report for tc-clean.py"* ]]
}

@test "a non-empty clean report still passes the same fixture" {
  printf '# Security Review\n\nNo findings.\n' > "$SK/demo/output/tc-clean.py.report.md"
  stamp tc-clean.py
  run eval_fixture demo tc-clean.py
  [ "$status" -eq 0 ]
}

@test "an empty report still passes a max_claims:0 fixture" {
  : > "$SK/demo/output/tc-empty-input.js.report.md"
  stamp tc-empty-input.js
  run eval_fixture demo tc-empty-input.js
  [ "$status" -eq 0 ]
}

@test "a whitespace-only report fails a clean-negative fixture" {
  printf '   \n\n' > "$SK/demo/output/tc-clean.py.report.md"
  stamp tc-clean.py
  run eval_fixture demo tc-clean.py
  [ "$status" -ne 0 ]
  [[ "$output" == *"Empty report"* ]]
}

@test "a .failed marker fails the fixture even when the report has text" {
  echo "Not logged in · Please run /login" > "$SK/demo/output/tc-clean.py.report.md"
  stamp tc-clean.py
  echo "the result event is an error" > "$SK/demo/output/tc-clean.py.failed"
  run eval_fixture demo tc-clean.py
  [ "$status" -ne 0 ]
  [[ "$output" == *"Generation failed for tc-clean.py: the result event is an error"* ]]
}

@test "a .failed marker fails a max_claims:0 fixture too" {
  : > "$SK/demo/output/tc-empty-input.js.report.md"
  stamp tc-empty-input.js
  echo "claude exited 1" > "$SK/demo/output/tc-empty-input.js.failed"
  run eval_fixture demo tc-empty-input.js
  [ "$status" -ne 0 ]
}
