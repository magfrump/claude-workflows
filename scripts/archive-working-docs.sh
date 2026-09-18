#!/usr/bin/env bash
# Archive docs/working/ artifacts from a completed self-improvement run.
#
# Usage: scripts/archive-working-docs.sh [-n|--dry-run] [PREFIX]
#
# Moves all non-permanent files from docs/working/ into docs/working/archive/
# with an optional prefix (defaults to date, e.g. "2026-03-25"). Permanent
# files (hypothesis-log.md, hypothesis-backlog.md, tasks.json, feature-ideas.md, test-strategy-fact-check-skills.md,
# completed-tasks.md, problem-history.json, round-history.json, questions.md,
# questions-archive.md) are left in place — they accumulate across runs. The last three are cross-run memory for
# scripts/self-improvement.sh: it reads completed-tasks.md when generating
# ideas (so archiving it makes the next run re-propose finished work),
# problem-history.json for convergence detection, and round-history.json for
# prior-round verdicts. All three are re-created empty when absent, so
# archiving them is silent amnesia rather than a visible error.
#
# Options:
#   -n, --dry-run   Show what would be moved without moving anything

set -euo pipefail

DRY_RUN=false
PREFIX=""

for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRY_RUN=true ;;
    -*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *) PREFIX="$arg" ;;
  esac
done

PREFIX="${PREFIX:-$(date +%Y-%m-%d)}"

WORKING_DIR="docs/working"
ARCHIVE_DIR="$WORKING_DIR/archive"

if [ ! -d "$WORKING_DIR" ]; then
  echo "Error: $WORKING_DIR not found. Run from repo root." >&2
  exit 1
fi

# Files that persist across runs — never archive these
PERMANENT=(
  hypothesis-log.md
  hypothesis-backlog.md
  tasks.json
  feature-ideas.md
  test-strategy-fact-check-skills.md
  # Cross-run memory for scripts/self-improvement.sh — see header comment.
  completed-tasks.md
  problem-history.json
  round-history.json
  # The running-questions doc (global-instructions/CLAUDE.md, "Running
  # questions document"). questions.md is the live queue — archiving it drops
  # OPEN entries and turns health-check gate 14 red; questions-archive.md is the
  # answered history, and archive/ is gitignored, so moving it there takes that
  # history out of version control. `scripts/questions.sh archive` already
  # prunes answered entries, so neither file needs this script's help.
  questions.md
  questions-archive.md
)

is_permanent() {
  local name="$1"
  for p in "${PERMANENT[@]}"; do
    [ "$name" = "$p" ] && return 0
  done
  return 1
}

if $DRY_RUN; then
  echo "Dry run — no files will be moved."
  echo ""
fi

mkdir -p "$ARCHIVE_DIR"

count=0
for f in "$WORKING_DIR"/*; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"

  if is_permanent "$name"; then
    echo "  keep  $name"
    continue
  fi

  dest="$ARCHIVE_DIR/${PREFIX}-${name}"
  if $DRY_RUN; then
    echo "  move  $name -> archive/${PREFIX}-${name}"
  else
    mv -- "$f" "$dest"
    echo "  move  $name -> archive/${PREFIX}-${name}"
  fi
  count=$((count + 1))
done

echo ""
if $DRY_RUN; then
  echo "Would archive $count files to $ARCHIVE_DIR/ with prefix '$PREFIX'."
else
  echo "Archived $count files to $ARCHIVE_DIR/ with prefix '$PREFIX'."
fi
