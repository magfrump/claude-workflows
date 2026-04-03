#!/usr/bin/env bats
# @category slow
# Integration test for scripts/health-check.sh
#
# Runs the health-check script ONCE per file (not per test) and asserts
# against the cached output.  This reduces wall time from ~60s to ~10s.
#
# Compatibility: uses setup_file/teardown_file (bats-core >=1.2.0).
# On older BATS the functions are silently ignored and the lazy-init
# fallback in setup() runs the script on the first test instead.

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/scripts/health-check.sh"

# Deterministic cache path shared across all tests in this file.
# $$ is the main BATS process PID, stable across per-test subshells.
_HC_CACHE_DIR="/tmp/bats-hc-cache.$$"

_run_and_cache() {
  mkdir -p "$_HC_CACHE_DIR"
  run bash "$SCRIPT"
  printf '%s' "$output" > "$_HC_CACHE_DIR/output"
  printf '%s' "$status" > "$_HC_CACHE_DIR/status"
}

# --- bats-core >=1.2.0 hooks ------------------------------------------------

setup_file() {
  _run_and_cache
}

teardown_file() {
  rm -rf "$_HC_CACHE_DIR"
}

# --- per-test setup (also serves as fallback for older BATS) -----------------

setup() {
  if [ -f "$_HC_CACHE_DIR/output" ]; then
    HC_OUTPUT=$(cat "$_HC_CACHE_DIR/output")
    HC_STATUS=$(cat "$_HC_CACHE_DIR/status")
  else
    # Fallback: first test pays the cost; rest reuse the cache.
    _run_and_cache
    HC_OUTPUT=$(cat "$_HC_CACHE_DIR/output")
    HC_STATUS=$(cat "$_HC_CACHE_DIR/status")
  fi
}

# --- assertions --------------------------------------------------------------

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

@test "output contains Workflow complexity section" {
  echo "$HC_OUTPUT" | grep -q "Workflow complexity"
}

@test "output contains Hook script permissions section" {
  echo "$HC_OUTPUT" | grep -q "Hook script permissions"
}

@test "output ends with All checks passed" {
  echo "$HC_OUTPUT" | grep -q "All checks passed"
}
