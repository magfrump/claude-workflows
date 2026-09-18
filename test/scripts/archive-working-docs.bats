#!/usr/bin/env bats
# @category slow
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

@test "running-questions docs are permanent" {
  # questions.md is the live queue the global instructions name by path, and
  # health-check gate 14 fails when it is absent. Archiving it drops still-OPEN
  # entries out of the queue; archiving questions-archive.md moves the answered
  # history into the gitignored archive/, out of version control.
  echo "# Running questions" > "$TEST_DIR/docs/working/questions.md"
  echo "# Answered questions" > "$TEST_DIR/docs/working/questions-archive.md"

  cd "$TEST_DIR"
  run bash "$SCRIPT" "pfx"
  [ "$status" -eq 0 ]

  [ -f docs/working/questions.md ]
  [ -f docs/working/questions-archive.md ]
  [ ! -f docs/working/archive/pfx-questions.md ]
  [ ! -f docs/working/archive/pfx-questions-archive.md ]
}

@test "graduated working docs are permanent" {
  echo "dd" > "$TEST_DIR/docs/working/dd-cc-isolated-loopback-redirect.md"
  echo "tri" > "$TEST_DIR/docs/working/triage-2026-09-17-backlog.md"

  cd "$TEST_DIR"
  run bash "$SCRIPT" "pfx"
  [ "$status" -eq 0 ]
  [ -f docs/working/dd-cc-isolated-loopback-redirect.md ]
  [ -f docs/working/triage-2026-09-17-backlog.md ]
}

@test "warns before archiving a file a tracked doc still cites" {
  # 1c9d1af archived docs that guides and CLAUDE.md still cited; archive/ is
  # gitignored, so those references dangled in every fresh clone.
  cd "$TEST_DIR"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  git init -q
  echo "see docs/working/plan-foo.md" > README.md
  git add README.md

  run bash "$SCRIPT" --dry-run "pfx"
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn  plan-foo.md is still cited by: README.md"* ]]
  # An uncited file gets no warning.
  [[ "$output" != *"warn  summary-bar.md"* ]]
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

@test "exits cleanly with no archive when only permanent files exist" {
  # Edge case: a self-improvement round produces no working docs (e.g., all
  # tasks rejected). Only permanent files remain — nothing to archive.
  # Remove archivable files created by setup(), leaving only permanent files.
  rm -f "$TEST_DIR/docs/working/plan-foo.md" "$TEST_DIR/docs/working/summary-bar.md"

  cd "$TEST_DIR"
  run bash "$SCRIPT" "empty-round"
  [ "$status" -eq 0 ]

  # Permanent files must still be in place
  [ -f docs/working/hypothesis-log.md ]
  [ -f docs/working/tasks.json ]

  # No files should have been archived (archive dir may exist but must be empty)
  if [ -d docs/working/archive ]; then
    [ -z "$(ls -A docs/working/archive)" ]
  fi

  # Output should report 0 files archived
  [[ "$output" == *"Archived 0 files"* ]]
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
