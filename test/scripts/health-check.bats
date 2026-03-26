#!/usr/bin/env bats
# Integration test for scripts/health-check.sh
#
# Runs the health-check script against the live repo and verifies:
#   1. Exit code is 0 (all checks pass)
#   2. All expected section headers appear in the output
#
# Timeout: 60s — the script runs shellcheck and BATS sub-checks internally.

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/scripts/health-check.sh"

@test "health-check exits 0 on this repo" {
  run bash "$SCRIPT"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "output contains Repo Health Check title" {
  run bash "$SCRIPT"
  echo "$output" | grep -q "Repo Health Check"
}

@test "output contains Skill YAML frontmatter section" {
  run bash "$SCRIPT"
  echo "$output" | grep -q "Skill YAML frontmatter"
}

@test "output contains Workflow cross-references section" {
  run bash "$SCRIPT"
  echo "$output" | grep -q "Workflow cross-references"
}

@test "output contains MD file consistency section" {
  run bash "$SCRIPT"
  echo "$output" | grep -q "MD file consistency"
}

@test "output contains Fixture expected-verdicts section" {
  run bash "$SCRIPT"
  echo "$output" | grep -q "expected-verdicts"
}

@test "output contains BATS tests section" {
  run bash "$SCRIPT"
  echo "$output" | grep -q "BATS tests"
}

@test "output contains shellcheck section" {
  run bash "$SCRIPT"
  echo "$output" | grep -q "shellcheck"
}

@test "output contains Workflow complexity section" {
  run bash "$SCRIPT"
  echo "$output" | grep -q "Workflow complexity"
}

@test "output contains Hook script permissions section" {
  run bash "$SCRIPT"
  echo "$output" | grep -q "Hook script permissions"
}

@test "output ends with All checks passed" {
  run bash "$SCRIPT"
  echo "$output" | grep -q "All checks passed"
}
