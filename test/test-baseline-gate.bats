#!/usr/bin/env bats
# @category fast
# Unit tests for the test-gate baseline helpers in scripts/lib/si-functions.sh:
#   tap_failing_names, tap_new_failures
#
# These back the failure-isolation fix for the `tests` gate: a pre-existing
# failure on the base commit must not reject tasks that didn't cause it.
#
# Usage: bats test/test-baseline-gate.bats

load lib/hermetic-env

# These tests index into "${lines[@]}" from `run bash -c ...`; an un-installed
# ambient locale would make bash's setlocale warning the first captured line.
pin_hermetic_locale

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-functions.sh"
  TEST_TMPDIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Representative TAP with two failures, out of order, with a directive.
sample_tap() {
  cat <<'TAP'
1..4
ok 1 first thing works
not ok 2 pivot workflows exist
ok 3 another thing
not ok 4 schema is valid # custom directive
TAP
}

# --- tap_failing_names ---

@test "tap_failing_names extracts only failing test names, sorted+unique" {
  run bash -c 'source "'"$BATS_TEST_DIRNAME"'/../scripts/lib/si-functions.sh"; '"$(declare -f sample_tap)"'; sample_tap | tap_failing_names'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "pivot workflows exist" ]
  [ "${lines[1]}" = "schema is valid" ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "tap_failing_names strips the TAP # directive from the name" {
  result=$(printf 'not ok 7 some test # skip reason\n' | tap_failing_names)
  [ "$result" = "some test" ]
}

@test "tap_failing_names emits nothing for an all-green suite" {
  result=$(printf '1..2\nok 1 a\nok 2 b\n' | tap_failing_names)
  [ -z "$result" ]
}

@test "tap_failing_names dedupes a name that fails in two worktree orderings" {
  # Same test, different TAP numbers (the exact bug that sank the May run).
  result=$(printf 'not ok 43 pivot workflows exist\nnot ok 55 pivot workflows exist\n' | tap_failing_names)
  [ "$result" = "pivot workflows exist" ]
}

# --- tap_new_failures ---

@test "tap_new_failures: failure already in baseline is NOT new" {
  printf 'pivot workflows exist\n' > "$TEST_TMPDIR/baseline.txt"
  result=$(printf 'not ok 2 pivot workflows exist\n' | tap_new_failures "$TEST_TMPDIR/baseline.txt")
  [ -z "$result" ]
}

@test "tap_new_failures: failure absent from baseline IS new" {
  printf 'pivot workflows exist\n' > "$TEST_TMPDIR/baseline.txt"
  result=$(printf 'not ok 9 schema is valid\n' | tap_new_failures "$TEST_TMPDIR/baseline.txt")
  [ "$result" = "schema is valid" ]
}

@test "tap_new_failures: baseline failure ignored, new failure surfaced together" {
  printf 'pivot workflows exist\n' > "$TEST_TMPDIR/baseline.txt"
  result=$(printf 'not ok 1 pivot workflows exist\nnot ok 2 schema is valid\n' | tap_new_failures "$TEST_TMPDIR/baseline.txt")
  [ "$result" = "schema is valid" ]
}

@test "tap_new_failures: empty baseline file means every failure is new" {
  : > "$TEST_TMPDIR/baseline.txt"
  result=$(printf 'not ok 1 a test\n' | tap_new_failures "$TEST_TMPDIR/baseline.txt")
  [ "$result" = "a test" ]
}

@test "tap_new_failures: missing baseline file means every failure is new" {
  result=$(printf 'not ok 1 a test\n' | tap_new_failures "$TEST_TMPDIR/nonexistent.txt")
  [ "$result" = "a test" ]
}

@test "tap_new_failures: green suite produces no new failures even with empty baseline" {
  : > "$TEST_TMPDIR/baseline.txt"
  result=$(printf '1..1\nok 1 fine\n' | tap_new_failures "$TEST_TMPDIR/baseline.txt")
  [ -z "$result" ]
}

@test "tap_new_failures: task that FIXED a baseline failure introduces nothing new" {
  printf 'pivot workflows exist\nschema is valid\n' > "$TEST_TMPDIR/baseline.txt"
  # Worktree now only fails one of the two baseline tests (fixed the other).
  result=$(printf 'not ok 3 pivot workflows exist\n' | tap_new_failures "$TEST_TMPDIR/baseline.txt")
  [ -z "$result" ]
}
