#!/bin/bash
# board.sh: the cross-project board, unit 1 (the listing). Host only, no LLM.
# Reads a registry of repos and prints each one's open `you:` questions as its
# default branch's commit holds them (plan D8: an answer counts once it reaches
# main, so the board shows what the dev cycle reads, never a working tree).
# Design: docs/working/research-2026-11-12-host-board-answer-route.md sections
# 3 and 6, and docs/working/research-2026-11-12-host-board-listing.md; owner
# guide: guides/cross-project-board.md.
#
# Usage: ~/.claude/scripts/board.sh        (no arguments; answering is units 2-3)
# Registry: BOARD_REGISTRY, else ~/.config/claude-board/repos: one absolute
# repo path per line; blank lines and lines starting # are skipped.
# Run log: one line per run appended to ~/.local/state/claude-board/runs.log.
# Exit: 0 every project read; 1 a bad registry line, an unreadable project, no
# project listed or the run log not written; 2 the run refused before reading
# any repo (a missing file beside this script, no perl, no registry, arguments).
#
# Trust (H1): the repos are container-writable, so nothing from them runs here.
# questions.sh and the lib are the copies beside this script (the installed,
# install-reviewed ones on the host), every git call runs under the lib's
# git_harden, only git objects are read (no working tree, so no filter runs),
# and everything printed passes through the lib's scrub.
set -euo pipefail
export LC_ALL=C
HERE="$(cd -- "$(dirname -- "$0")" && pwd -P)"
SELF="$HERE/${0##*/}"
QS="$HERE/questions.sh"
LIB="$HERE/lib/dev-cycle-read.sh"
die() { echo "board: $*" >&2; exit 2; }
for f in "$QS" "$LIB"; do
  [[ -f "$f" ]] || die "refusing to run: $f is missing (questions.sh and lib/dev-cycle-read.sh must sit beside board.sh)"
done
[[ $# -eq 0 ]] || die "takes no arguments yet: answering from the board is not built (units 2 and 3)"
command -v perl >/dev/null 2>&1 || die "refusing to run: perl is missing, and the output scrub needs it"
# shellcheck source=lib/dev-cycle-read.sh
source "$LIB"
scrub_reexec "$SELF"
# Away from every repo before the first git call, so no repo's config is read
# unhardened; then drop an inherited GIT_DIR and the like, and harden.
cd /
# shellcheck disable=SC2046  # one variable name per line
unset $(git rev-parse --local-env-vars)
git_harden
REG="${BOARD_REGISTRY:-$HOME/.config/claude-board/repos}"
[[ -f "$REG" ]] || die "no registry at $REG: write one absolute repo path per line (guides/cross-project-board.md)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/claude-board.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

# First line of $1 holding a refusal (✗), else its first line; temp paths read
# as the repo's own.
first_refusal() {
  local l
  l="$(printf '%s\n' "$1" | grep -a -m1 '✗' || printf '%s\n' "$1" | head -n1)"
  l="${l#"${l%%[! ]*}"}"
  printf '%s' "${l//"$2/"/docs/working/}"
}

# One project's block. Runs in its own subshell (it cds and sets MAIN_*);
# returns 3 after printing why the project is unreadable.
repo() {
  local n="$1" p="$2" d="$TMP/$1" f e out id route slug r watches=0 shown=0 lines=""
  mkdir "$d"
  printf '\n== %s\n' "$p"
  cd -- "$p"
  if ! resolve_main || ! main_by_name; then
    echo "   UNREADABLE: no branch named main or master (nor origin/HEAD's), so no default branch to read"; return 3
  fi
  for f in questions questions-archive watching; do
    e="$(main_entry "docs/working/$f.md")"
    case "$e" in
      blob) git cat-file blob "$MAIN_SHA:docs/working/$f.md" > "$d/$f.md" \
              || { echo "   UNREADABLE: docs/working/$f.md could not be read from $MAIN"; return 3; } ;;
      absent) [[ "$f" == watching ]] || { echo "   no questions doc on main ($MAIN has no docs/working/$f.md)"; return 3; } ;;
      *) echo "   UNREADABLE: $(entry_why "$e" "docs/working/$f.md")"; return 3 ;;
    esac
  done
  qs() { ( cd -- "$d" && QUESTIONS_LIVE="$d/questions.md" QUESTIONS_ARCHIVE="$d/questions-archive.md" \
           QUESTIONS_WATCHING="$d/watching.md" bash "$QS" "$@" ); }
  if ! out="$(qs check 2>&1)"; then
    echo "   UNREADABLE (questions.sh check: $(first_refusal "$out" "$d"))"; return 3
  fi
  if ! out="$(qs open 2>"$d/err")"; then
    echo "   UNREADABLE (questions.sh open: $(first_refusal "$(cat -- "$d/err")" "$d"))"; return 3
  fi
  while IFS=$'\t' read -r id route slug; do
    case "$route" in
      deferred|trigger) watches=$((watches + 1)); continue ;;
      you:*)
        # open lists an ANSWERED live entry until its repo archives it: drop
        # those, but never drop one silently on a skip (an unread file).
        r="$(check_answer "$id")"
        case "$r" in
          "open $id") ;;
          keep\ *|drop\ *|done\ *|unrecognized\ *) continue ;;
          *) echo "   UNREADABLE $id (check_answer: $r)"; return 3 ;;
        esac ;;
    esac
    # Any other route (agent, say) is shown as printed rather than hidden.
    lines+="$(printf '   %s  %-16s  %s' "$id" "$route" "$slug")"$'\n'
    shown=$((shown + 1))
  done < <(printf '%s\n' "$out" | awk -F'  +' 'NF >= 2 { print $1 "\t" $2 "\t" $3 }')
  printf '   main %s · %d open watch%s\n' "$(git log -1 --format=%cd --date=short "$MAIN_SHA")" \
    "$watches" "$([[ $watches -eq 1 ]] || echo es)"
  if [[ $shown -eq 0 ]]; then echo "   nothing open for you"; else printf '%s' "$lines"; fi
  echo "$shown" > "$TMP/$n.count"
}

n=0; projects=0; bad=0; total=0
while IFS= read -r line || [[ -n "$line" ]]; do
  n=$((n + 1))
  line="${line%$'\r'}"; line="${line#"${line%%[! $'\t']*}"}"; line="${line%"${line##*[! $'\t']}"}"
  [[ -z "$line" || "$line" == \#* ]] && continue
  why=""
  if [[ "$line" != /* ]]; then why="not an absolute path"
  elif [[ ! -d "$line" ]]; then why="not a directory"
  elif ! err="$(git -C "$line" rev-parse --git-dir 2>&1 >/dev/null)"; then why="not a git repository (git: ${err%%$'\n'*})"
  fi
  if [[ -n "$why" ]]; then printf 'REGISTRY LINE %d: %s: %s\n' "$n" "$why" "$line"; bad=$((bad + 1)); continue; fi
  projects=$((projects + 1))
  # Not under if or ||, which would switch errexit off inside the subshell.
  set +e; ( set -e; repo "$n" "$line" ); rc=$?; set -e
  if [[ $rc -ne 0 ]]; then
    [[ $rc -eq 3 ]] || echo "   UNREADABLE: the board stopped reading this repo (exit $rc)"
    bad=$((bad + 1))
  else
    total=$((total + $(cat -- "$TMP/$n.count")))
  fi
done < "$REG"

status=0
[[ $bad -eq 0 && $projects -gt 0 ]] || status=1
[[ $projects -gt 0 ]] || echo "board: the registry $REG lists no project"
printf '\n%d project%s, %d open for you, %d unreadable or refused; exit %d\n' "$projects" \
  "$([[ $projects -eq 1 ]] || echo s)" "$total" "$bad" "$status"
echo "To answer, write Q-NNN: <answer> in that repo's session; answering from the board is not built yet."
LOG_DIR="$HOME/.local/state/claude-board"
if ! { mkdir -p -- "$LOG_DIR" && printf '%s projects=%d open=%d unreadable=%d exit=%d\n' \
         "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$projects" "$total" "$bad" "$status" >> "$LOG_DIR/runs.log"; }; then
  echo "board: could not append to $LOG_DIR/runs.log" >&2; status=1
fi
exit "$status"
