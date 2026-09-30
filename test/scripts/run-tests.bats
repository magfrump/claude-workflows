#!/usr/bin/env bats
# @category slow
# scripts/run-tests.sh: the locale pin, FILE... selection, category + FILE
# filtering, --failed and --jobs. Runs a copy of the script in a throwaway repo
# layout whose test/ holds small fixture suites, with the real bats, so
# --failed reads real bats run logs. The real suite never runs. The repo root
# has a space in its name, so every test also covers word-splitting of paths.

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
# shellcheck source=../lib/hermetic-env.bash
source "$REPO_ROOT/test/lib/hermetic-env.bash"
# A working locale for runner(): C.UTF-8 where it is installed, else C.
WORKING_LOCALE=C
locale_installed C.UTF-8 && WORKING_LOCALE=C.UTF-8

setup() {
  T="$BATS_TEST_TMPDIR/my repo"
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

teardown() {
  # Tests that park a fixture in `sleep` record its pid; end it if a failed
  # assertion left it running.
  if [[ -f "$T/sleep.pid" ]]; then
    kill "$(cat "$T/sleep.pid")" 2>/dev/null || true
  fi
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
  in_runner LC_ALL="$WORKING_LOCALE" -- "$@"
}

# runner_bg <outfile> [args...]: start the runner in the background under
# `timeout`, its output in <outfile>; $! is timeout's pid afterwards. A TERM to
# timeout reaches its whole process group, so bats' children end too and the
# run lock is released.
runner_bg() {
  local out="$1"
  shift
  timeout -s TERM 60 env -i PATH="${PATH//"$BATS_LIBEXEC:"/}" HOME="$HOME" \
    TMPDIR="$BATS_TEST_TMPDIR" LC_ALL="$WORKING_LOCALE" \
    bash "$T/scripts/run-tests.sh" "$@" > "$out" 2>&1 3>&- &
}

# wait_unlocked: wait up to 10 s for the run lock to be free.
wait_unlocked() {
  for _ in $(seq 100); do flock -n "$T/.bats/lock" true && return 0; sleep 0.1; done
  return 1
}

# wait_for <file>: wait up to 10 s for <file> to exist.
wait_for() {
  for _ in $(seq 100); do [[ -e "$1" ]] && return 0; sleep 0.1; done
  return 1
}

# sleeper_fixture <path>: a fast suite whose second test parks in a sleep
# (pid in $T/sleep.pid) and whose third fails.
sleeper_fixture() {
  fixture "$1" fast \
    '@test "s1" { true; }' \
    '@test "s2" { sleep 20 & echo $! > "$BATS_TEST_DIRNAME/../sleep.pid"; wait; }' \
    '@test "s3" { false; }'
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
  source "$REPO_ROOT/test/lib/hermetic-env.bash"
  locale_installed C.UTF-8 || skip "C.UTF-8 is not installed here (the runner pins C)"
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

@test "FILE: a missing file, a non-.bats file or one outside test/ is an error" {
  runner test/nope.bats
  [ "$status" -eq 1 ]
  [[ "$output" == *"no such test file: test/nope.bats"* ]]

  runner scripts/run-tests.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a .bats file: scripts/run-tests.sh"* ]]

  echo '# @category fast' > "$T/outside.bats"
  runner outside.bats
  [ "$status" -eq 1 ]
  [[ "$output" == *"not under test/: outside.bats"* ]]

  runner test/../outside.bats
  [ "$status" -eq 1 ]
  [[ "$output" == *"not under test/: test/../outside.bats"* ]]
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

@test "FILE: a directory or file symlink out of test/ is rejected" {
  mkdir -p "$BATS_TEST_TMPDIR/elsewhere"
  printf '%s\n' '#!/usr/bin/env bats' '# @category fast' '@test "outside" { true; }' \
    > "$BATS_TEST_TMPDIR/elsewhere/x.bats"
  ln -s "$BATS_TEST_TMPDIR/elsewhere" "$T/test/link"
  runner test/link/x.bats
  [ "$status" -eq 1 ]
  [[ "$output" == *"not under test/: test/link/x.bats"* ]]

  ln -s "$BATS_TEST_TMPDIR/elsewhere/x.bats" "$T/test/flink.bats"
  runner test/flink.bats
  [ "$status" -eq 1 ]
  [[ "$output" == *"not under test/: test/flink.bats"* ]]
  [[ "$output" != *"outside"*"ok"* ]]
}

@test "FILE: a suite named twice (or via ..) runs once, also after --" {
  runner -- test/gamma.bats test/gamma.bats test/sub/../gamma.bats
  [ "$status" -eq 0 ]
  [[ "$output" == *"1..1"* ]]
}

@test "FILE: paths with spaces in the directory and file name" {
  mkdir -p "$T/test/sub dir"
  fixture "sub dir/x y.bats" fast '@test "spaced ok" { true; }'
  runner "test/sub dir/x y.bats"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok 1 spaced ok"* ]]
}

@test "a run whose first file is in a subdirectory still records its log under .bats/" {
  runner test/sub/beta.bats
  [ "$status" -eq 0 ]
  [ -f "$T/.bats/run-log-anchor" ]
  [ "$(ls "$LOG_DIR" | wc -l)" -eq 1 ]
  grep -q "^passed $T/test/sub/beta.bats" "$LOG_DIR"/*.log
  [ "$(sed -n 1p "$T/.bats/last-run")" = "expected=1" ]
  [ "$(sed -n 3p "$T/.bats/last-run")" = "$T/test/sub/beta.bats" ]
}

@test "an unwritable .bats/ warns and runs without recording" {
  touch "$T/.bats"   # a file, so the log directory cannot be created
  runner test/gamma.bats
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING: cannot write .bats/.bats/run-logs (or flock is missing); running without recording"* ]]
  [[ "$output" == *"ok 1"* ]]
}

@test "--failed re-runs only the last run's failures, then reports none left" {
  runner
  [ "$status" -eq 1 ]   # bats' own status, passed through
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
  [[ "$output" == *"--failed: no failed tests among the selected files in the last recorded run"*"1 file(s)); nothing to re-run"* ]]
  [[ "$output" != *"1..1"* ]]
}

@test "--failed with a category flag or FILE is a usage error" {
  runner
  [ "$status" -ne 0 ]
  age_logs
  runner --failed --slow
  [ "$status" -eq 2 ]
  [[ "$output" == *"takes no --fast/--slow/--all or FILE"* ]]
  runner --failed test/alpha.bats
  [ "$status" -eq 2 ]
  [[ "$output" == *"takes no --fast/--slow/--all or FILE"* ]]
}

@test "--failed with no recorded run is an error" {
  runner --failed
  [ "$status" -eq 1 ]
  [[ "$output" == *"--failed: no recorded run"* ]]
}

@test "--failed with no recorded run is an error even when every selected suite is gated" {
  mkdir -p "$T/skills/foo"
  touch "$T/skills/foo/SKILL.md"
  rm -f "$T"/test/*.bats
  printf '%s\n' '#!/usr/bin/env bats' '# @category fast' '# @needs-reports foo' \
    '@test "gated" { true; }' > "$T/test/gated.bats"
  runner --failed
  [ "$status" -eq 1 ]
  [[ "$output" == *"--failed: no recorded run"* ]]
}

@test "--failed refuses the log of a run killed partway" {
  sleeper_fixture slow.bats
  runner_bg "$BATS_TEST_TMPDIR/killed.out" test/slow.bats
  local pid=$! rc=0
  wait_for "$T/sleep.pid"
  kill -TERM "$pid"
  wait "$pid" || rc=$?
  [ "$rc" -eq 143 ]
  wait_unlocked
  # The log holds s1 only.
  grep -q '^passed .*slow.bats.*s1' "$LOG_DIR"/*.log

  runner --failed
  [ "$status" -eq 1 ]
  [[ "$output" == *"--failed: the last run ("*") recorded 1 of 3 tests: it did not complete"* ]]
}

@test "--failed refuses the log of a run whose setup_file failed" {
  fixture sf.bats fast 'setup_file() { false; }' '@test "sf1" { true; }'
  runner test/sf.bats test/gamma.bats
  [ "$status" -eq 1 ]
  [[ "$output" == *"not ok"*"setup_file failed"* ]]
  age_logs

  runner --failed
  [ "$status" -eq 1 ]
  [[ "$output" == *"recorded 1 of 2 tests"* ]]
}

@test "a run while another holds the lock exits 1 and runs nothing" {
  sleeper_fixture slow.bats
  runner_bg "$BATS_TEST_TMPDIR/first.out" test/slow.bats
  local pid=$!
  wait_for "$T/sleep.pid"

  runner test/gamma.bats
  [ "$status" -eq 1 ]
  [[ "$output" == *"another run-tests.sh run is in progress in this checkout"* ]]
  [[ "$output" != *"gamma clean output"* ]]

  kill -TERM "$pid"
  wait "$pid" || true
  wait_unlocked
}

# parallel_shim: put a `parallel` first on PATH that logs its arguments to
# $T/parallel.args and execs the real one, so a test can see bats used it.
parallel_shim() {
  local real
  real="$(command -v parallel)" || skip "GNU parallel is not installed here"
  mkdir -p "$BATS_TEST_TMPDIR/shim"
  printf '%s\n' '#!/usr/bin/env bash' \
    "printf '%s\n' \"\$*\" >> '$T/parallel.args'" \
    "exec '$real' \"\$@\"" > "$BATS_TEST_TMPDIR/shim/parallel"
  chmod +x "$BATS_TEST_TMPDIR/shim/parallel"
  PATH="$BATS_TEST_TMPDIR/shim:$PATH"
}

@test "--jobs: a missing, zero, non-numeric or 4-digit N is a usage error" {
  runner --jobs
  [ "$status" -eq 2 ]
  [[ "$output" == *"--jobs takes a number from 1 to 999, got: (nothing)"* ]]
  runner --jobs 0 test/gamma.bats
  [ "$status" -eq 2 ]
  [[ "$output" == *"got: 0"* ]]
  runner --jobs x test/gamma.bats
  [ "$status" -eq 2 ]
  [[ "$output" == *"got: x"* ]]
  runner --jobs 1000 test/gamma.bats
  [ "$status" -eq 2 ]
  [[ "$output" == *"got: 1000"* ]]
  [[ "$output" != *"gamma clean output"* ]]
}

@test "--jobs 2 runs files through parallel, not tests within a file" {
  parallel_shim
  runner --jobs 2
  [ "$status" -eq 1 ]
  [[ "$output" == *"1..4"* ]]
  [[ "$output" == *"not ok"*"alpha flaky"* ]]
  [[ "$output" == *"ok"*"beta steady"* ]]
  [[ "$output" == *"ok"*"gamma clean output"* ]]
  [ -f "$T/parallel.args" ]
  grep -q -- '--jobs 2' "$T/parallel.args"
  grep -q -- '--no-parallelize-within-files' "$T/parallel.args"
}

@test "--jobs 1 runs serially and needs no parallel" {
  parallel_shim
  runner --jobs 1 test/gamma.bats
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok 1 gamma clean output"* ]]
  [ ! -f "$T/parallel.args" ]
}

@test "--jobs: a parallel run records a complete log that --failed re-runs from" {
  parallel_shim
  runner --jobs 2
  [ "$status" -eq 1 ]
  [ "$(sed -n 1p "$T/.bats/last-run")" = "expected=4" ]
  [ "$(grep -cE '^(passed|failed) ' "$LOG_DIR"/*.log)" -eq 4 ]
  age_logs

  touch "$T/fixed"
  runner --failed --jobs 2
  [ "$status" -eq 0 ]
  [[ "$output" == *"1..1"* ]]
  [[ "$output" == *"ok 1 alpha flaky"* ]]
  [[ "$output" != *"beta"* ]]
  age_logs

  runner --failed
  [ "$status" -eq 0 ]
  [[ "$output" == *"nothing to re-run"* ]]
}

@test "--jobs: a parallel run killed partway is refused by --failed" {
  parallel_shim
  sleeper_fixture slow.bats
  runner_bg "$BATS_TEST_TMPDIR/killed.out" --jobs 2 test/slow.bats test/gamma.bats
  local pid=$! rc=0
  wait_for "$T/sleep.pid"
  kill -TERM "$pid"
  wait "$pid" || rc=$?
  [ "$rc" -eq 143 ]
  wait_unlocked

  runner --failed
  [ "$status" -eq 1 ]
  [[ "$output" == *"--failed: the last run ("*") recorded "*" of 4 tests: it did not complete"* ]]
}

@test "--jobs: an uninstalled locale leaves no perl or citation text in the output" {
  parallel_shim
  in_runner LANG=xx_XX.UTF-8 -- --jobs 2
  [ "$status" -eq 1 ]
  [[ "$output" == *"Locale xx_XX.UTF-8 is not installed"* ]]
  [ -f "$T/parallel.args" ]
  # gamma asserts its own subprocess output is clean; the suite-level output
  # must be clean too.
  [[ "$output" == *"ok"*"gamma clean output"* ]]
  ! grep -iE 'perl|setlocale|cite|citation' <<< "$output"
}

@test "--jobs above the file count is lowered to it" {
  parallel_shim
  runner --jobs 999 test/gamma.bats test/sub/beta.bats
  [ "$status" -eq 0 ]
  grep -q -- '--jobs 2 ' "$T/parallel.args"
}

@test "--jobs: the user's PARALLEL options do not reach bats' parallel" {
  parallel_shim
  # --dry-run would run no test at all.
  in_runner LC_ALL="$WORKING_LOCALE" PARALLEL=--dry-run -- --jobs 2
  [ "$status" -eq 1 ]
  [[ "$output" == *"1..4"* ]]
  [[ "$output" == *"ok"*"beta steady"* ]]
  [ -d "$T/.bats/parallel-home" ]
}

@test "--jobs with a non-GNU parallel first on PATH warns and runs serially" {
  mkdir -p "$BATS_TEST_TMPDIR/fake"
  printf '%s\n' '#!/usr/bin/env bash' 'echo "parallel from moreutils"; exit 1' \
    > "$BATS_TEST_TMPDIR/fake/parallel"
  chmod +x "$BATS_TEST_TMPDIR/fake/parallel"
  PATH="$BATS_TEST_TMPDIR/fake:$PATH"
  runner --jobs 2 test/gamma.bats test/sub/beta.bats
  [ "$status" -eq 0 ]
  [[ "$output" == *"is not GNU parallel; running serially"* ]]
  [[ "$output" == *"ok 2 beta steady"* ]]
}

@test "--jobs without GNU parallel on PATH warns and runs serially" {
  # A PATH holding everything the current one does except parallel (and
  # bats' libexec directory, which in_runner drops too).
  local bin="$BATS_TEST_TMPDIR/noparallel" dir f
  mkdir -p "$bin"
  local IFS=:
  for dir in $PATH; do
    [[ -d "$dir" && "$dir" != "$BATS_LIBEXEC" ]] || continue
    for f in "$dir"/*; do
      [[ -x "$f" && ! -e "$bin/${f##*/}" && "${f##*/}" != parallel ]] && ln -s "$f" "$bin/${f##*/}"
    done
  done
  unset IFS
  run env -i PATH="$bin" HOME="$HOME" TMPDIR="$BATS_TEST_TMPDIR" LC_ALL="$WORKING_LOCALE" \
    bash -c 'command -v parallel || bash "$1" --jobs 2 test/gamma.bats test/sub/beta.bats' \
    _ "$T/scripts/run-tests.sh" 3>&-
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING: --jobs 2 needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially"* ]]
  [[ "$output" == *"1..2"* ]]
  [[ "$output" == *"ok 1 gamma clean output"* ]]
  [[ "$output" == *"ok 2 beta steady"* ]]
  grep -q "^passed $T/test/sub/beta.bats" "$LOG_DIR"/*.log
}
