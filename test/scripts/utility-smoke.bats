#!/usr/bin/env bats
# @category slow
# Smoke tests for utility scripts that previously had zero dedicated coverage.
# Catches broken scripts after refactoring.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

# --- archive-working-docs.sh ---

@test "archive-working-docs.sh exits non-zero with error when docs/working is missing" {
  # Run from a temp directory where docs/working does not exist
  cd "$BATS_TEST_TMPDIR"
  run bash "$REPO_ROOT/scripts/archive-working-docs.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"docs/working not found"* ]]
}

# --- skill-usage-report.sh ---

@test "skill-usage-report.sh runs without error on the current repo" {
  # Point at an empty log so the script doesn't depend on user-specific data
  export USAGE_LOG_FILE="/tmp/nonexistent-smoke-test-$$.jsonl"
  run bash "$REPO_ROOT/scripts/skill-usage-report.sh"
  [ "$status" -eq 0 ]
}
