#!/usr/bin/env bats
# @category slow
# scripts/run-tests.sh: the locale pin, FILE... selection, category + FILE
# filtering and --failed. Runs a copy of the script in a throwaway repo layout
# whose test/ holds small fixture suites, with the real bats, so --failed reads
# real bats run logs. The real suite never runs.

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
  T="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$T/scripts" "$T/test/skills" "$T/test/lib" "$T/test/sub"
  cp "$REPO_ROOT/scripts/run-tests.sh" "$T/scripts/"
  cp "$REPO_ROOT/test/skills/runner-contract.bash" "$T/test/skills/"
  cp "$REPO_ROOT/test/lib/hermetic-env.bash" "$T/test/lib/"

  # Fixture suites are written with printf, not a heredoc: this file's own
  # bats preprocessor would rewrite any line that starts with @test.
  # alpha: one test that fails until $T/fixed exists.
  fixture alpha.bats fast \
    '@test "alpha steady" { true; }' \
    '@test "alpha flaky" { [ -f "$BATS_TEST_DIRNAME/../fixed" ]; }'
  # gamma: fails when a bash subprocess prints a setlocale warning into $output.
  fixture gamma.bats fast \
    '@test "gamma clean output" { run bash -c "echo hi"; [ "$output" = hi ]; }'
  fixture sub/beta.bats slow '@test "beta steady" { true; }'
  LOG_DIR="$T/.bats/.bats/run-logs"
  AGED=0
}

# fixture <path under test/> <category> <line...>: write a fixture suite.
fixture() {
  local path="$T/test/$1" category="$2"
  shift 2
  printf '%s\n' '#!/usr/bin/env bats' "# @category $category" "$@" > "$path"
}

# in_runner [VAR=value...] -- [args...]: run the copied runner in a clean
# environment plus the given assignments. The fixture bats must not inherit
# this suite's own bats state: its exported BATS_* vars and bats_* functions
# make it resolve test names against this file, bats prepends its libexec
# dir to PATH (whose `bats` skips the setup the real one does), and fd 3 is
# this run's TAP stream.
in_runner() {
  local assigns=() path
  path=":$PATH:"
  path="${path//":$BATS_LIBEXEC:"/:}"
  path="${path#:}"
  path="${path%:}"
  while [[ $# -gt 0 && "$1" != -- ]]; do assigns+=("$1"); shift; done
  shift
  run env -i PATH="$path" HOME="$HOME" TMPDIR="$BATS_TEST_TMPDIR" "${assigns[@]}" \
    bash "$T/scripts/run-tests.sh" "$@" 3>&-
}

# runner [args...]: in_runner under a working locale.
runner() {
  in_runner LC_ALL=C.UTF-8 -- "$@"
}

# age_logs: rename every unaged run log to an old, ordered timestamp. bats names
# logs by the second, so two runs within one second would share (or misorder)
# a log; the tests run far faster than that.
age_logs() {
  local f
  for f in "$LOG_DIR"/*.log; do
    [[ "$(basename "$f")" == 2000-* ]] && continue
    AGED=$((AGED + 1))
    mv "$f" "$LOG_DIR/2000-01-01 00:00:$(printf '%02d' "$AGED") UTC.log"
  done
}

@test "locale: an uninstalled LC_ALL is replaced with C.UTF-8 and reported" {
  in_runner LC_ALL=xx_XX.UTF-8 -- test/gamma.bats
  [ "$status" -eq 0 ]
  [[ "$output" == *"Locale xx_XX.UTF-8 is not installed; running with LC_ALL=C.UTF-8"* ]]
  [[ "$output" == *"ok 1 gamma clean output"* ]]
}

@test "locale: an uninstalled LANG (LC_ALL unset) is pinned too" {
  in_runner LANG=xx_XX.UTF-8 -- test/gamma.bats
  [ "$status" -eq 0 ]
  [[ "$output" == *"Locale xx_XX.UTF-8 is not installed"* ]]
}

@test "locale: a working locale is left alone" {
  runner test/gamma.bats
  [ "$status" -eq 0 ]
  [[ "$output" != *"is not installed"* ]]
  [[ "$output" == *"ok 1 gamma clean output"* ]]
}

@test "FILE: only the named suites run (repo-relative and absolute paths)" {
  runner test/gamma.bats "$T/test/sub/beta.bats"
  [ "$status" -eq 0 ]
  [[ "$output" == *"1..2"* ]]
  [[ "$output" == *"gamma clean output"* ]]
  [[ "$output" == *"beta steady"* ]]
  [[ "$output" != *"alpha"* ]]
}

@test "FILE: a missing file or one outside test/ is an error" {
  runner test/nope.bats
  [ "$status" -eq 1 ]
  [[ "$output" == *"no such test file: test/nope.bats"* ]]

  echo '# @category fast' > "$T/outside.bats"
  runner outside.bats
  [ "$status" -eq 1 ]
  [[ "$output" == *"not under test/: outside.bats"* ]]
}

@test "FILE: an untagged named suite fails the tag check" {
  printf '%s\n' '#!/usr/bin/env bats' '@test "u" { true; }' > "$T/test/untagged.bats"
  runner test/untagged.bats
  [ "$status" -eq 1 ]
  [[ "$output" == *'no "# @category fast|slow" tag in'*untagged.bats* ]]
}

@test "category + FILE: the category flag filters the named files" {
  runner --slow test/alpha.bats test/sub/beta.bats
  [ "$status" -eq 0 ]
  [[ "$output" == *"1..1"* ]]
  [[ "$output" == *"beta steady"* ]]
  [[ "$output" != *"alpha"* ]]
}

@test "every run records a log under .bats/ whatever the first file's directory" {
  runner test/sub/beta.bats
  [ "$status" -eq 0 ]
  [ -f "$T/.bats/run-log-anchor" ]
  [ "$(ls "$LOG_DIR" | wc -l)" -eq 1 ]
  [ ! -e "$T/test/sub/.bats" ]
}

@test "--failed re-runs only the last run's failures, then reports none left" {
  runner
  [ "$status" -ne 0 ]
  [[ "$output" == *"not ok"*"alpha flaky"* ]]
  age_logs

  touch "$T/fixed"
  runner --failed
  [ "$status" -eq 0 ]
  [[ "$output" == *"=== Re-running failed all tests ==="* ]]
  [[ "$output" == *"1..1"* ]]
  [[ "$output" == *"ok 1 alpha flaky"* ]]
  [[ "$output" != *"alpha steady"* ]]
  [[ "$output" != *"beta"* ]]
  age_logs

  runner --failed
  [ "$status" -eq 0 ]
  [[ "$output" == *"--failed: no failed tests in the last recorded run"* ]]
  [[ "$output" != *"1..1"* ]]
}

@test "--failed narrowed by category leaves out failures outside it" {
  runner
  [ "$status" -ne 0 ]
  age_logs
  runner --failed --slow
  [ "$status" -eq 0 ]
  [[ "$output" == *"no failed tests in the last recorded run"* ]]
}

@test "--failed with no recorded run is an error" {
  runner --failed
  [ "$status" -eq 1 ]
  [[ "$output" == *"--failed: no recorded run"* ]]
}
