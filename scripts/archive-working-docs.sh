#!/usr/bin/env bash
# Archive docs/working/ artifacts from a completed self-improvement run.
#
# Usage: scripts/archive-working-docs.sh [-n|--dry-run] [PREFIX]
#
# Moves all non-permanent files from docs/working/ into docs/working/archive/
# with an optional prefix (defaults to date, e.g. "2026-03-25"). Permanent
# files (hypothesis-log.md, hypothesis-backlog.md, tasks.json, feature-ideas.md, test-strategy-fact-check-skills.md,
# completed-tasks.md, problem-history.json, round-history.json, questions.md,
# questions-archive.md, and the "graduated" docs listed in PERMANENT) are left
# in place — they accumulate across runs or are cited by live files. Any other
# file still cited by a tracked file gets a warning before it is moved.
# completed-tasks.md, problem-history.json and round-history.json are
# cross-run memory for scripts/self-improvement.sh: it reads completed-tasks.md when generating
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
  # Graduated working docs. A docs/working/ file graduates here once a live
  # instruction, skill, guide, script, config, test, or decision record depends
  # on it — archive/ is gitignored, so archiving it would dangle that reference
  # in every fresh clone. Citations from docs/reviews/ or retired archive/ code
  # do not count. Added 2026-09-18 after 1c9d1af archived all of these while
  # they were still cited; the loop below warns before this can recur.
  dd-cc-isolated-loopback-redirect.md     # guides/devcontainer-setup.md §6 probes, firewall/proxy config
  triage-2026-09-17-backlog.md            # global CLAUDE.md, questions.sh, health-check.sh
  fn-trace-skill-levers-2026-08-21.md     # code-review, code-fact-check, security-reviewer skills
  dd-synthesis-fragment-composition.md    # skills/code-review/SKILL.md
  measure-fragment-composition-cost.md    # skills/code-review/SKILL.md
  dd-cc-isolated-repo-split.md            # decision 036
  dd-install-sh-gating.md                 # decision 035
  diagnosis-cc-isolated-login-dns.md      # decision log
  crb-direction1-setup.md                 # decision log
  review-canon.md                         # decision log
)

# Tracked files outside docs/working/ and archive/ that cite docs/working/$1,
# comma-joined (first three). Empty outside a git checkout.
cited_by() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  git grep -l -F "docs/working/$1" -- . ':!docs/working/**' ':!archive/**' 2>/dev/null \
    | head -3 | paste -sd, - || true
}

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
  cites="$(cited_by "$name")"
  if [ -n "$cites" ]; then
    echo "  warn  $name is still cited by: $cites — add it to PERMANENT if it has graduated" >&2
  fi
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
