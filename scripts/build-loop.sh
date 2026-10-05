#!/usr/bin/env bash
# The build-loop handoff's state and checks: what the dev cycle's orchestrator
# reads before it dispatches a build brief to a build loop, collects the
# loop's result, or merges it (docs/working/plan-build-loop-handoff.md).
#
# Usage: scripts/build-loop.sh --settings
#        scripts/build-loop.sh -h | --help
#
#   --settings  three lines from the default branch's commit, never the working
#             tree (a build loop can write any working tree). Each comes from
#             one line of docs/dev-cycle.md; a second copy, or a file the lib's
#             FENCE_AWK refuses, gives review, 3 and malformed (WHY says which):
#             policy self-merge|review set|unset: WHY
#                 Set only by "Build-loop policy: self-merge" or "...: review",
#                 exactly (one trailing CR dropped); else review. Self-merge
#                 also needs a valid never line, so a list hidden in markup
#                 turns it off rather than being skipped.
#             slots N set|default: WHY
#                 Loops at once: "Build-loop slots: N", N from 1 to 9; else 3.
#             never GLOB... set|none|malformed: WHY
#                 Paths self-merge never lands: "Self-merge never: GLOB ..."
#                 (or "...: none"), single spaces, and the next line outside a
#                 fence blank or the end. A glob uses
#                 letters, digits, . _ - / * ? (a trailing / ignored when
#                 comparing), has no empty, . or .. part, does not start with
#                 / or -, and is listed once. Malformed (or a file not read)
#                 turns self-merge off.
#             Copies are found best effort: a line counts as one when its
#             letters alone, case folded, start with the key's
#             ("buildlooppolicy"). Markup that adds letters (a task box, a tag)
#             can still hide a copy; only an exact line ever sets a value.
#
# Acts on $PWD's git repo, like dev-cycle.sh, and needs its default branch
# found by name (origin/HEAD, main or master). Read-only: writes nothing.
# Output passes through the lib's scrub (but for the start-up errors about
# perl and the lib); printed repo text is data.
# Exit: 0 every line printed (or help); 1 bad usage, not a git repo, no perl or
# lib/dev-cycle-read.sh, or no default branch found by name.

set -euo pipefail

command -v perl >/dev/null || { echo "build-loop.sh needs perl (to scrub its output)" >&2; exit 1; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # before the cd: relative paths work
# The reader shared with dev-cycle.sh, from this script's own directory (never
# the target repo's scripts/lib/), so a copy of scripts/ with its lib/ is
# self-contained.
READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"
[[ -f "$READ_LIB" ]] || { echo "build-loop.sh needs $READ_LIB" >&2; exit 1; }
# shellcheck source=lib/dev-cycle-read.sh
source "$READ_LIB"
scrub_reexec "${BASH_SOURCE[0]}" "$@"

usage() { echo "$1 (usage: build-loop.sh --settings)" >&2; exit 1; }
MODE=""
case "${1:-}" in
  --settings) MODE=settings; [[ $# -eq 1 ]] || usage "--settings takes no arguments" ;;
  -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;  # the header, to its first non-comment line
  '') usage "no mode given" ;;
  *) usage "Unknown option: $1" ;;
esac

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
# shellcheck disable=SC2034  # read by the lib's file rules
ROOT_REAL="$(pwd -P)"
# Read main's own objects: a replace ref could swap in any settings blob.
# core.useReplaceRefs in the repo's config would override the variable, so a
# config-count pair turns it off. The caller's own environment is trusted: its
# `git -c` or a zero-padded GIT_CONFIG_COUNT can still win (U3b's --state).
cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))
export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1
resolve_main || true
main_by_name || { echo "build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none" >&2; exit 1; }

# A file on main: FILE_OUT is what awk program $2 (after FENCE_AWK) printed over
# it; or it returns 1 with FILE_WHY "absent" or why it was not read (main_entry,
# a failed read, or FENCE_AWK's "odd N WHY" / "unbalanced N").
FILE_OUT=""; FILE_WHY=""
main_file() {
  local f="$1" e n why
  FILE_OUT=""; FILE_WHY=""
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    notdir\ *) FILE_WHY="${e#notdir } is not a directory on the default branch"; return 1 ;;
    error) FILE_WHY="the default branch's tree could not be read for $f"; return 1 ;;
    *) FILE_WHY="$f is not a regular file on the default branch"; return 1 ;;
  esac
  FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")" \
    || { FILE_WHY="$f could not be read from the default branch"; return 1; }
  case "$FILE_OUT" in
    odd\ *) read -r _ n why <<<"$FILE_OUT"; FILE_WHY="line $n of $f $(oddwhy "$why"), so the file is not read"; return 1 ;;
    unbalanced\ *) FILE_WHY="the code fence opened at line ${FILE_OUT#unbalanced } of $f is never closed, so the file is not read"; return 1 ;;
  esac
}

# One pass over docs/dev-cycle.md: per key, how many lines start with it once
# everything but letters is dropped and case folded (best effort: most markup,
# a BOM or a misplaced colon cannot hide a copy), the first two line numbers, whether
# the line after the first is blank (NEXT 1) or not, and the first line whole:
# "KEY COUNT FIRST SECOND NEXT<TAB>LINE".
# shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal
SETTINGS_AWK='
{ sub(/\r$/, "") }
fence($0) { next }
{
  if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }
  s = tolower($0); gsub(/[^a-z]/, "", s); k = ""
  if (index(s, "buildlooppolicy") == 1) k = "policy"
  else if (index(s, "buildloopslots") == 1) k = "slots"
  else if (index(s, "selfmergenever") == 1) k = "never"
  if (k != "") { c[k]++; if (c[k] == 1) { l1[k] = NR; t[k] = $0; nx[k] = 1; pk = k } else if (c[k] == 2) l2[k] = NR }
}
END {
  if (odd) print "odd " odd " " oddwhy
  else if (infence) print "unbalanced " fline
  else for (k in c) print k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) " " nx[k] "\t" t[k]
}'
# A never entry: pathform's rule, but a .git* part (.github/) is allowed, since
# the list only adds refusals and must not turn self-merge off by naming one.
globform() {
  local rest="$1/" c
  [[ "$1" =~ ^[*?$NAMECHARS]+$ && "$1" != /* && "$1" != -* ]] || return 1
  while [[ -n "$rest" ]]; do
    c="${rest%%/*}"; rest="${rest#*/}"
    [[ -n "$c" && "$c" != "." && "$c" != ".." ]] || return 1
  done
}
# Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (an array of the checked globs,
# each as written, a trailing / kept) and NEVER_LINE from main's commit. POLICY
# and NEVER are for the modes that judge a brief (--status, then the gate).
POLICY=review; POLICY_LINE=""; SLOTS_LINE=""; NEVER=(); NEVER_LINE=""
# shellcheck disable=SC2034  # POLICY and NEVER: see above
read_settings() {
  local f=docs/dev-cycle.md where l k c l1 l2 nx t v g i why never_ok="" parts=()
  local -A cnt=() first=() second=() next=() text=() seen=()
  POLICY=review; NEVER=()
  where="of $f on the default branch"
  if ! main_file "$f" "$SETTINGS_AWK"; then
    [[ "$FILE_WHY" == absent ]] && why="no $f on the default branch" || why="$FILE_WHY"
    POLICY_LINE="policy review unset: $why"; SLOTS_LINE="slots 3 default: $why"
    # An absent file sets nothing; one that is not read turns self-merge off.
    if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi
  else
    while IFS= read -r l; do
      [[ -n "$l" ]] || continue
      read -r k c l1 l2 nx <<<"${l%%$'\t'*}"
      cnt[$k]="$c"; first[$k]="$l1"; second[$k]="$l2"; next[$k]="$nx"; text[$k]="${l#*$'\t'}"
    done <<<"$FILE_OUT"
    many() { echo "more than one line starts \"$1\" (lines ${first[$2]} and ${second[$2]})"; }
    # Self-merge never: first: self-merge needs a valid one (never_ok).
    if [[ -z "${cnt[never]-}" ]]; then NEVER_LINE='never none: no line starts "Self-merge never:"'
    elif [[ "${cnt[never]}" -gt 1 ]]; then NEVER_LINE="never malformed: $(many 'Self-merge never:' never)"
    else
      t="${text[never]}"; v="${t#Self-merge never: }"; why=""
      # Split on single spaces only; globform then refuses any other blank in an entry.
      if [[ "$t" != "Self-merge never: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
        why='is not exactly "Self-merge never: GLOB ..." with single spaces'
      elif [[ "${next[never]}" != 1 ]]; then why="is followed by a non-blank line outside a fence (it may continue the list)"
      elif [[ "$v" == none ]]; then parts=()
      else
        i=0
        IFS=' ' read -ra parts <<<"$v"  # not a bare $v: the shell would expand * and ? against files
        for g in "${parts[@]}"; do
          i=$((i + 1))
          if ! globform "${g%/}"; then why="lists entry $i, which is not an allowed glob form"; break; fi
          if [[ -n "${seen[${g%/}]-}" ]]; then why="lists entry $i twice"; break; fi
          seen[${g%/}]=1
        done
      fi
      if [[ -n "$why" ]]; then NEVER_LINE="never malformed: line ${first[never]} $why"
      elif [[ "$v" == none ]]; then never_ok=1; NEVER_LINE="never none: line ${first[never]} $where lists none"
      else never_ok=1; NEVER=("${parts[@]}"); NEVER_LINE="never $v set: line ${first[never]} $where"; fi
    fi
    if [[ -z "${cnt[policy]-}" ]]; then POLICY_LINE='policy review unset: no line starts "Build-loop policy:"'
    elif [[ "${cnt[policy]}" -gt 1 ]]; then POLICY_LINE="policy review unset: $(many 'Build-loop policy:' policy)"
    elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]; then
      v="${BASH_REMATCH[1]}"
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but there is no valid Self-merge never: line (\"Self-merge never: none\" for an empty list), so self-merge is off"
      else POLICY="$v"; POLICY_LINE="policy $v set: line ${first[policy]} $where"; fi
    else POLICY_LINE="policy review unset: line ${first[policy]} is not exactly \"Build-loop policy: self-merge\" or \"Build-loop policy: review\""; fi
    if [[ -z "${cnt[slots]-}" ]]; then SLOTS_LINE='slots 3 default: no line starts "Build-loop slots:"'
    elif [[ "${cnt[slots]}" -gt 1 ]]; then SLOTS_LINE="slots 3 default: $(many 'Build-loop slots:' slots)"
    elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]; then SLOTS_LINE="slots ${BASH_REMATCH[1]} set: line ${first[slots]} $where"
    else SLOTS_LINE="slots 3 default: line ${first[slots]} is not exactly \"Build-loop slots: N\" with N from 1 to 9"; fi
  fi
}

case "$MODE" in
  settings)
    read_settings
    printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE"
    ;;
esac
