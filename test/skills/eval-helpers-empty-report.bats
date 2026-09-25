#!/usr/bin/env bats
# @category fast
# eval_fixture must not score a failed generation as a pass. generate-reports.bash
# leaves an empty report when claude fails, and the absence-only checks
# (no_severity:, no_verdict:, no_field:, no_pattern:) all pass on empty text, so
# every clean-negative fixture would pass on a dead run. Only max_claims:0
# fixtures (an empty input file) may legitimately have an empty report.

load eval-helpers

bats_require_minimum_version 1.5.0

setup() {
  TEST_TMPDIR=$(mktemp -d)
  mkdir -p "$TEST_TMPDIR/demo/output"
  cat > "$TEST_TMPDIR/demo/expected-verdicts.bash" <<'EOF'
declare -gA EXPECTED_VERDICT KEY_CHECK
EXPECTED_VERDICT["tc-clean.py"]="None"
KEY_CHECK["tc-clean.py"]="no_severity:Critical|High;no_pattern:injection"
EXPECTED_VERDICT["tc-empty-input.js"]="None"
KEY_CHECK["tc-empty-input.js"]="max_claims:0"
EOF
  # eval_fixture resolves verdicts and reports relative to the suite's
  # directory; point it at the throwaway skill instead.
  BATS_TEST_DIRNAME="$TEST_TMPDIR"
  load_expected_verdicts demo
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "an empty report fails a clean-negative fixture" {
  : > "$TEST_TMPDIR/demo/output/tc-clean.py.report.md"
  run eval_fixture demo tc-clean.py
  [ "$status" -ne 0 ]
  [[ "$output" == *"Empty report for tc-clean.py"* ]]
}

@test "a non-empty clean report still passes the same fixture" {
  printf '# Security Review\n\nNo findings.\n' > "$TEST_TMPDIR/demo/output/tc-clean.py.report.md"
  run eval_fixture demo tc-clean.py
  [ "$status" -eq 0 ]
}

@test "an empty report still passes a max_claims:0 fixture" {
  : > "$TEST_TMPDIR/demo/output/tc-empty-input.js.report.md"
  run eval_fixture demo tc-empty-input.js
  [ "$status" -eq 0 ]
}
