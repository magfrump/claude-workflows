#!/usr/bin/env bats
# Functional tests for scripts/archive-working-docs.sh
#
# Covers: archiving, permanent-file preservation, dry-run, custom prefix.
# Each test runs in an isolated temp directory with a synthetic docs/working/.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/archive-working-docs.sh"

setup() {
  TEST_DIR="$(mktemp -d)"
  mkdir -p "$TEST_DIR/docs/working"

  # Archivable files
  echo "plan content" > "$TEST_DIR/docs/working/plan-foo.md"
  echo "summary content" > "$TEST_DIR/docs/working/summary-bar.md"

  # Permanent files (subset — enough to verify they're kept)
  echo "hypothesis log" > "$TEST_DIR/docs/working/hypothesis-log.md"
  echo "tasks" > "$TEST_DIR/docs/working/tasks.json"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "archivable files are moved to archive with correct prefix" {
  cd "$TEST_DIR"
  run bash "$SCRIPT" "test-prefix"
  [ "$status" -eq 0 ]

  # Archivable files should no longer exist in docs/working/
  [ ! -f docs/working/plan-foo.md ]
  [ ! -f docs/working/summary-bar.md ]

  # They should exist in archive/ with the prefix
  [ -f docs/working/archive/test-prefix-plan-foo.md ]
  [ -f docs/working/archive/test-prefix-summary-bar.md ]

  # Content should be preserved
  [ "$(cat docs/working/archive/test-prefix-plan-foo.md)" = "plan content" ]
}

@test "permanent files are preserved and not moved" {
  cd "$TEST_DIR"
  run bash "$SCRIPT" "pfx"
  [ "$status" -eq 0 ]

  # Permanent files must still be in docs/working/
  [ -f docs/working/hypothesis-log.md ]
  [ -f docs/working/tasks.json ]

  # They must NOT appear in the archive
  [ ! -f docs/working/archive/pfx-hypothesis-log.md ]
  [ ! -f docs/working/archive/pfx-tasks.json ]

  # Output should mention keeping them
  [[ "$output" == *"keep  hypothesis-log.md"* ]]
  [[ "$output" == *"keep  tasks.json"* ]]
}

@test "dry-run shows planned moves but does not move files" {
  cd "$TEST_DIR"
  run bash "$SCRIPT" --dry-run "dry-pfx"
  [ "$status" -eq 0 ]

  # Files must still be in their original location
  [ -f docs/working/plan-foo.md ]
  [ -f docs/working/summary-bar.md ]

  # Archive directory may be created but must be empty of archived files
  [ ! -f docs/working/archive/dry-pfx-plan-foo.md ]

  # Output should indicate dry run
  [[ "$output" == *"Dry run"* ]]
  [[ "$output" == *"Would archive"* ]]
  [[ "$output" == *"move  plan-foo.md"* ]]
}

@test "custom prefix is correctly applied to archived filenames" {
  cd "$TEST_DIR"
  run bash "$SCRIPT" "v3-release"
  [ "$status" -eq 0 ]

  # Verify the custom prefix appears in the archived filenames
  [ -f docs/working/archive/v3-release-plan-foo.md ]
  [ -f docs/working/archive/v3-release-summary-bar.md ]

  # Output should reference the custom prefix
  [[ "$output" == *"prefix 'v3-release'"* ]]
}
