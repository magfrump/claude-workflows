#!/usr/bin/env bash
# Archive docs/working/ artifacts from a completed self-improvement run.
#
# Usage: scripts/archive-working-docs.sh [-n|--dry-run] [PREFIX]
#
# Moves all non-permanent files from docs/working/ into docs/working/archive/
# with an optional prefix (defaults to date, e.g. "2026-03-25"). Permanent
# files (hypothesis-log.md, incident-journal.md, tasks.json, feature-ideas.md)
# are left in place — they accumulate across runs.
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
  incident-journal.md
  tasks.json
  feature-ideas.md
  test-strategy-fact-check-skills.md
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
