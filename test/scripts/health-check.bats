#!/usr/bin/env bats
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

@test "output contains Workflow complexity section" {
  echo "$HC_OUTPUT" | grep -q "Workflow complexity"
}

@test "output contains Hook script permissions section" {
  echo "$HC_OUTPUT" | grep -q "Hook script permissions"
}

@test "output ends with All checks passed" {
  echo "$HC_OUTPUT" | grep -q "All checks passed"
}

# ── Negative tests: broken skill files ──────────────────────────────────────

SKILLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/skills"

@test "detects skill file with no YAML frontmatter" {
  local tmp_skill="$SKILLS_DIR/_test_no_frontmatter.md"
  printf '# A skill file with no YAML frontmatter\n\nJust plain markdown.\n' > "$tmp_skill"

  run bash "$SCRIPT"
  rm -f "$tmp_skill"

  echo "$output"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "no YAML frontmatter found"
}

@test "detects skill file with missing description field" {
  local tmp_skill="$SKILLS_DIR/_test_missing_desc.md"
  printf -- '---\nname: test-broken-skill\n---\n\nBody text.\n' > "$tmp_skill"

  run bash "$SCRIPT"
  rm -f "$tmp_skill"

  echo "$output"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "missing 'description' field"
}
