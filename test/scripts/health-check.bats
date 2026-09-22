#!/usr/bin/env bats
# @category slow
# Integration test for scripts/health-check.sh
#
# Runs the health-check script ONCE per file (not per test) and asserts
# against the cached output. Negative tests at the bottom run separately
# since they inject broken fixture files.
#
# Compatibility: uses setup_file/teardown_file (bats-core >=1.2.0).
# On older BATS the functions are silently ignored and the lazy-init
# fallback in setup() runs the script on the first test instead.

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/scripts/health-check.sh"

# Recursion guard (Q-023): health-check.sh gate 5 runs every bats suite,
# including this one, so a health-check launched from here must not run gate 5
# again. Exported so every `run bash "$SCRIPT"` below inherits it. Gate 5's own
# ordering is tested further down with a stub runner.
export HEALTH_CHECK_SKIP_BATS=1

# Deterministic cache path shared across all tests in this file.
_HC_CACHE_DIR="/tmp/bats-hc-cache.$$"

_run_and_cache() {
  mkdir -p "$_HC_CACHE_DIR"
  run bash "$SCRIPT"
  printf '%s' "$output" > "$_HC_CACHE_DIR/output"
  printf '%s' "$status" > "$_HC_CACHE_DIR/status"
}

setup_file() {
  _run_and_cache
}

teardown_file() {
  rm -rf "$_HC_CACHE_DIR"
}

setup() {
  if [ -f "$_HC_CACHE_DIR/output" ]; then
    HC_OUTPUT=$(cat "$_HC_CACHE_DIR/output")
    HC_STATUS=$(cat "$_HC_CACHE_DIR/status")
  else
    _run_and_cache
    HC_OUTPUT=$(cat "$_HC_CACHE_DIR/output")
    HC_STATUS=$(cat "$_HC_CACHE_DIR/status")
  fi
}

# --- assertions (use cached output) ----------------------------------------

@test "health-check exits 0 on this repo" {
  echo "$HC_OUTPUT"
  [ "$HC_STATUS" -eq 0 ]
}

@test "output contains Repo Health Check title" {
  echo "$HC_OUTPUT" | grep -q "Repo Health Check"
}

@test "output contains Skill YAML frontmatter section" {
  echo "$HC_OUTPUT" | grep -q "Skill YAML frontmatter"
}

@test "output contains Workflow cross-references section" {
  echo "$HC_OUTPUT" | grep -q "Workflow cross-references"
}

@test "output contains MD file consistency section" {
  echo "$HC_OUTPUT" | grep -q "MD file consistency"
}

@test "output contains Fixture expected-verdicts section" {
  echo "$HC_OUTPUT" | grep -q "expected-verdicts"
}

@test "output contains BATS tests section" {
  echo "$HC_OUTPUT" | grep -q "BATS tests"
}

@test "output contains shellcheck section" {
  echo "$HC_OUTPUT" | grep -q "shellcheck"
}

@test "output contains Workflow value-justification section" {
  echo "$HC_OUTPUT" | grep -q "Workflow value-justification"
}

@test "output contains Hook script permissions section" {
  echo "$HC_OUTPUT" | grep -q "Hook script permissions"
}

@test "output ends with All checks passed" {
  echo "$HC_OUTPUT" | grep -q "All checks passed"
}

# ── Negative tests: broken skill files ──────────────────────────────────────
#
# Hermetic: each test copies the real skills/ into $BATS_TEST_TMPDIR/skills,
# injects its broken fixture there, and points health-check.sh at the copy via
# HEALTH_CHECK_SKILLS_DIR. Nothing is written under the real repo, so an
# interrupted run cannot leave a fixture in skills/ (where every consuming
# project would load it as a skill) and concurrent runs cannot race on it.
# The copy is complete so the only difference from the real tree is the
# fixture, and each assertion greps for the message naming that fixture, so
# the failure is attributable to it alone.

REAL_SKILLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/skills"

# Copy skills/ to an isolated tree and print its path. The basename must stay
# "skills": skill names are derived from the /skills/ path component.
_isolated_skills_dir() {
  local dir="$BATS_TEST_TMPDIR/skills"
  cp -R "$REAL_SKILLS_DIR" "$dir"
  printf '%s' "$dir"
}

@test "detects skill file with no YAML frontmatter" {
  local skills_dir
  skills_dir="$(_isolated_skills_dir)"
  printf '# A skill file with no YAML frontmatter\n\nJust plain markdown.\n' \
    > "$skills_dir/_test_no_frontmatter.md"

  HEALTH_CHECK_SKILLS_DIR="$skills_dir" run bash "$SCRIPT"

  echo "$output"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "_test_no_frontmatter: no YAML frontmatter found"
}

@test "detects skill file with missing description field" {
  local skills_dir
  skills_dir="$(_isolated_skills_dir)"
  printf -- '---\nname: test-broken-skill\n---\n\nBody text.\n' \
    > "$skills_dir/_test_missing_desc.md"

  HEALTH_CHECK_SKILLS_DIR="$skills_dir" run bash "$SCRIPT"

  echo "$output"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "_test_missing_desc: missing 'description' field"
}

# ── Gate 5: fast-then-slow ordering (Q-023) ────────────────────────────────
#
# Sources health-check.sh (main only runs when executed) and calls check_bats
# against a stub runner via the HEALTH_CHECK_RUN_TESTS seam, so these tests
# never run the real suites. The stub logs each invocation's flag and the
# HEALTH_CHECK_SKIP_BATS it saw, and exits with STUB_FAST_RC / STUB_SLOW_RC.

_stub_runner() {
  local stub="$BATS_TEST_TMPDIR/run-tests-stub.sh"
  cat > "$stub" <<'STUB'
#!/usr/bin/env bash
printf '%s skip=%s\n' "$1" "${HEALTH_CHECK_SKIP_BATS:-unset}" >> "$STUB_LOG"
case "$1" in
  --fast) exit "${STUB_FAST_RC:-0}" ;;
  --slow) exit "${STUB_SLOW_RC:-0}" ;;
esac
exit 99
STUB
  chmod +x "$stub"
  printf '%s' "$stub"
}

# Run check_bats with the stub; prints FAIL=<n> last. Gate-5 guard unset here.
_run_check_bats() {
  local stub
  stub="$(_stub_runner)"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"
  : > "$STUB_LOG"
  run env -u HEALTH_CHECK_SKIP_BATS HEALTH_CHECK_RUN_TESTS="$stub" \
    bash -c 'source "$1"; check_bats; echo "FAIL=$FAIL"' _ "$SCRIPT"
}

@test "gate 5: runs fast then slow when both are green" {
  STUB_FAST_RC=0 STUB_SLOW_RC=0 _run_check_bats
  echo "$output"; cat "$STUB_LOG"
  [ "$status" -eq 0 ]
  [[ "$output" == *"FAIL=0"* ]]
  [ "$(cat "$STUB_LOG")" = "$(printf -- '--fast skip=1\n--slow skip=1')" ]
}

@test "gate 5: red fast blocks slow and fails the gate" {
  STUB_FAST_RC=1 STUB_SLOW_RC=0 _run_check_bats
  echo "$output"; cat "$STUB_LOG"
  [[ "$output" == *"FAIL=1"* ]]
  [[ "$output" == *"slow suites not run"* ]]
  [ "$(cat "$STUB_LOG")" = "--fast skip=1" ]
}

@test "gate 5: red slow after green fast fails the gate" {
  STUB_FAST_RC=0 STUB_SLOW_RC=1 _run_check_bats
  echo "$output"; cat "$STUB_LOG"
  [[ "$output" == *"FAIL=1"* ]]
  [[ "$output" == *"Slow BATS suites failed"* ]]
  [ "$(wc -l < "$STUB_LOG")" -eq 2 ]
}

@test "gate 5: HEALTH_CHECK_SKIP_BATS=1 skips the runner with a warning, not a pass" {
  local stub
  stub="$(_stub_runner)"
  export STUB_LOG="$BATS_TEST_TMPDIR/stub.log"
  : > "$STUB_LOG"
  run env HEALTH_CHECK_SKIP_BATS=1 HEALTH_CHECK_RUN_TESTS="$stub" \
    bash -c 'source "$1"; check_bats; echo "FAIL=$FAIL"' _ "$SCRIPT"
  echo "$output"
  [[ "$output" == *"FAIL=0"* ]]
  [[ "$output" == *"BATS gate skipped"* ]]
  [[ "$output" != *"passed"* ]]
  [ ! -s "$STUB_LOG" ]
}
