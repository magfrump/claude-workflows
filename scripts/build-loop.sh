#!/usr/bin/env bash
# The build-loop handoff's state and checks: what the dev cycle's orchestrator
# reads before it dispatches a build brief to a build loop, collects the
# loop's result, or merges it (docs/working/plan-build-loop-handoff.md).
#
# Usage: scripts/build-loop.sh --settings
#
#   --settings  three lines, from the default branch's commit (never the
#             working tree, which a build loop can write):
#             policy self-merge|review set|unset: WHY
#                 docs/dev-cycle.md's policy. It is set only when exactly one
#                 line, outside code fences, starts "Build-loop policy:" and
#                 reads exactly "Build-loop policy: self-merge" or
#                 "Build-loop policy: review" (one trailing CR is dropped).
#                 Any other case, or a malformed never line, means review.
#             slots N set|default: WHY
#                 How many build loops may run at once: one line
#                 "Build-loop slots: N" with N from 1 to 9, else 3.
#             never GLOB... set|none|malformed: WHY
#                 Paths self-merge never lands, as one line
#                 "Self-merge never: GLOB ..." (single spaces; each glob uses
#                 letters, digits, . _ - / * ?, with an optional trailing /;
#                 no . or .. part, no .git, not starting / or -; none twice).
#                 A malformed line, or a settings file that is not read,
#                 turns self-merge off.
#             A line counts as a settings line when it starts with the key
#             (any case) after any blanks, > and list markers, so a quoted or
#             indented copy is a second line, not a hidden one. A file the
#             reader cannot trust (a fence never closed or not in plain
#             column-0 form, a line starting with < other than a one-line
#             <!-- comment -->, an open <!--, a line like a link reference
#             definition, a stray CR, a byte-order mark; see FENCE_AWK in the
#             lib) is not read at all.
#
# Acts on $PWD's git repo, like dev-cycle.sh, and needs its default branch
# found by name (origin/HEAD, main or master). Read-only: writes nothing.
# Output passes through the lib's scrub; printed repo text is data.
# Exit: 0 every line printed; 1 bad usage, not a git repo, no perl or
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
  -h|--help) sed -n '2,39p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  '') usage "no mode given" ;;
  *) usage "unknown option: $1" ;;
esac

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
# shellcheck disable=SC2034  # read by the lib's file rules
ROOT_REAL="$(pwd -P)"
export GIT_LITERAL_PATHSPECS=1
resolve_main || true
main_by_name || { echo "build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none" >&2; exit 1; }

# A file on main for the readers below: sets FILE_WHY and returns 1 when it is
# absent ("absent"), stored as anything but a regular file under plain
# directories, or refused by FENCE_AWK; otherwise FILE_OUT holds what the awk
# program $2 printed over it (FENCE_AWK is prepended; the program prints "odd N
# WHY" or "unbalanced N" when the file cannot be trusted).
FILE_OUT=""; FILE_WHY=""
main_file() {
  local f="$1" e n why
  FILE_OUT=""; FILE_WHY=""
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    notdir\ *) FILE_WHY="${e#notdir } is not a directory on the default branch"; return 1 ;;
    *) FILE_WHY="$f is not a regular file on the default branch"; return 1 ;;
  esac
  FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")"
  case "$FILE_OUT" in
    odd\ *) read -r _ n why <<<"$FILE_OUT"; FILE_WHY="line $n of $f $(oddwhy "$why"), so the file is not read"; return 1 ;;
    unbalanced\ *) FILE_WHY="the code fence opened at line ${FILE_OUT#unbalanced } of $f is never closed, so the file is not read"; return 1 ;;
  esac
}

# One pass over docs/dev-cycle.md: per key, how many lines start with it (after
# blanks, > and list markers, any case), the first two line numbers and the
# first line whole: "KEY COUNT FIRST SECOND<TAB>LINE".
# shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal
SETTINGS_AWK='
{ sub(/\r$/, "") }
fence($0) { next }
{
  s = $0
  if (match(s, /^([ \t>]|[-*+][ \t]|[0123456789]+[.)][ \t])*/)) s = substr(s, RLENGTH + 1)
  s = tolower(s); k = ""
  if (index(s, "build-loop policy:") == 1) k = "policy"
  else if (index(s, "build-loop slots:") == 1) k = "slots"
  else if (index(s, "self-merge never:") == 1) k = "never"
  if (k != "") { c[k]++; if (c[k] == 1) { l1[k] = NR; t[k] = $0 } else if (c[k] == 2) l2[k] = NR }
}
END {
  if (odd) print "odd " odd " " oddwhy
  else if (infence) print "unbalanced " fline
  else for (k in c) print k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) "\t" t[k]
}'
# Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (the globs, or empty) and
# NEVER_LINE from main's commit. POLICY and NEVER are
# for the modes that judge a brief (--status, then the gate).
POLICY=review; POLICY_LINE=""; SLOTS_LINE=""; NEVER=""; NEVER_LINE=""
# shellcheck disable=SC2034  # POLICY and NEVER: see above
read_settings() {
  local f=docs/dev-cycle.md where l k c l1 l2 t v g i why never_ok=1 parts=()
  local -A cnt=() first=() second=() text=() seen=()
  where="of $f on the default branch"
  if ! main_file "$f" "$SETTINGS_AWK"; then
    [[ "$FILE_WHY" == absent ]] && why="no $f on the default branch" || why="$FILE_WHY"
    POLICY_LINE="policy review unset: $why"; SLOTS_LINE="slots 3 default: $why"
    # An absent file sets nothing; one that is not read turns self-merge off.
    if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi
  else
    while IFS= read -r l; do
      [[ -n "$l" ]] || continue
      read -r k c l1 l2 <<<"${l%%$'\t'*}"
      cnt[$k]="$c"; first[$k]="$l1"; second[$k]="$l2"; text[$k]="${l#*$'\t'}"
    done <<<"$FILE_OUT"
    many() { echo "more than one line starts \"$1\" (lines ${first[$2]} and ${second[$2]})"; }
    # Self-merge never: first, because a malformed line turns self-merge off.
    if [[ -z "${cnt[never]-}" ]]; then NEVER_LINE='never none: no line starts "Self-merge never:"'
    elif [[ "${cnt[never]}" -gt 1 ]]; then NEVER_LINE="never malformed: $(many 'Self-merge never:' never)"; never_ok=""
    else
      t="${text[never]}"; v="${t#Self-merge never: }"; why=""
      if [[ "$t" != "Self-merge never: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
        why='is not exactly "Self-merge never: GLOB ..." with single spaces'
      else
        i=0
        read -ra parts <<<"$v"  # not a bare $v: the shell would expand * and ? against files
        for g in "${parts[@]}"; do
          i=$((i + 1))
          if ! pathform "${g%/}" glob; then why="lists entry $i, which is not an allowed glob form"; break; fi
          if [[ -n "${seen[$g]-}" ]]; then why="lists entry $i twice"; break; fi
          seen[$g]=1
        done
      fi
      if [[ -n "$why" ]]; then NEVER_LINE="never malformed: line ${first[never]} $why"; never_ok=""
      else NEVER="$v"; NEVER_LINE="never $v set: line ${first[never]} $where"; fi
    fi
    if [[ -z "${cnt[policy]-}" ]]; then POLICY_LINE='policy review unset: no line starts "Build-loop policy:"'
    elif [[ "${cnt[policy]}" -gt 1 ]]; then POLICY_LINE="policy review unset: $(many 'Build-loop policy:' policy)"
    elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]; then
      v="${BASH_REMATCH[1]}"
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but the Self-merge never: line is malformed, so self-merge is off"
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
