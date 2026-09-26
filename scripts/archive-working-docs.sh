#!/usr/bin/env bash
# Archive docs/working/ artifacts from a completed self-improvement run.
#
# Usage: scripts/archive-working-docs.sh [-n|--dry-run] [PREFIX]
#
# Moves all non-permanent files from docs/working/ into docs/working/archive/
# with an optional prefix (defaults to the run id in docs/working/si-run-id.txt,
# e.g. "2026-03-25-031500", else today's date, e.g. "2026-03-25"). Permanent
# files (hypothesis-log.md, hypothesis-backlog.md, tasks.json, feature-ideas.md, test-strategy-fact-check-skills.md,
# completed-tasks.md, problem-history.json, round-history.json, questions.md,
# questions-archive.md, and the "graduated" docs listed in PERMANENT) are left
# in place — they accumulate across runs or are cited by live files. Any other
# file still cited by a tracked file is kept in place, with a message.
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

WORKING_DIR="docs/working"

# Default prefix: the run id the self-improvement loop recorded at run start
# (si-run-id.txt, Q-047), so archived files carry the same id as that run's
# hypothesis-log Run cells even when archiving happens on a later day. Falls
# back to today's date when the file is absent or its content is unusable.
if [ -z "$PREFIX" ] && [ -f "$WORKING_DIR/si-run-id.txt" ]; then
  RUN_ID=$(head -n1 "$WORKING_DIR/si-run-id.txt")
  if [[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
    PREFIX="$RUN_ID"
  fi
fi
PREFIX="${PREFIX:-$(date +%Y-%m-%d)}"
# The prefix becomes part of a path, and the morning summary reads it back as a
# Run id; hold an explicit prefix to the same charset as the recorded one.
if ! [[ "$PREFIX" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: prefix '$PREFIX' must match [A-Za-z0-9._-]+" >&2
  exit 1
fi
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

# Tracked files that cite $1, by bare file name (so `handoff-x.md` counts as
# well as `docs/working/handoff-x.md`). Other tracked working docs count too:
# the 2026-09-18 sweep lost the triage doc's parent handoff because the only
# citer was another working doc. Excluded: the file itself, and records of
# their day (docs/reviews/, runs/) and the retired archive/ tree. Prints at most
# three citers, comma-separated. Over-matching only keeps a file, which is the
# safe direction.
cited_by() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  git grep -l -F "$1" -- . ":!docs/working/$1" ':!docs/working/archive/**' \
      ':!docs/reviews/**' ':!runs/**' ':!archive/**' 2>/dev/null \
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
    # Keep, don't move: archive/ is gitignored, so moving a cited file dangles
    # the citation in every fresh clone. A warning alone did not stop that
    # (1c9d1af); 33 such files were rescued into the tracked archive/docs/ on
    # 2026-09-26.
    echo "  keep  $name — still cited by: $cites. Add it to PERMANENT, or git mv it to archive/docs/ and update the citation" >&2
    continue
  fi
  if [ -e "$dest" ]; then
    # Two archives under one prefix (a date-only fallback run twice in a day)
    # must not overwrite the first run's copy.
    echo "  skip  $name: archive/${PREFIX}-${name} already exists" >&2
    continue
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
