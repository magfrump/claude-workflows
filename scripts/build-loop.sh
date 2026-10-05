#!/usr/bin/env bash
# The build-loop handoff's state and checks: what the dev cycle's orchestrator
# reads before it dispatches a build brief to a build loop, collects the
# loop's result, or merges it (docs/working/plan-build-loop-handoff.md).
#
# Usage: scripts/build-loop.sh --settings
#        scripts/build-loop.sh --status BRIEF...
#        scripts/build-loop.sh -h | --help
#
#   --settings  four lines from the default branch's commit, never the working
#             tree (a build loop can write any working tree). Lines 1-3 from
#             one line of docs/dev-cycle.md; a second copy, or a file the lib's
#             FENCE_AWK refuses, leaves the default (WHY says which):
#             policy self-merge|review set|unset: WHY
#                 Set only by "Build-loop policy: self-merge" or "...: review",
#                 exactly (one trailing CR dropped); else review.
#             slots N set|default: WHY
#                 Loops at once: "Build-loop slots: N", N from 1 to 9; else 3.
#             never GLOB... set|none|malformed: WHY
#                 Paths self-merge never lands: "Self-merge never: GLOB ...",
#                 single spaces, then a blank line or the end. A glob uses
#                 letters, digits, . _ - / * ? (a trailing / ignored when
#                 comparing), has no empty, . or .. part, does not start with
#                 / or -, and is listed once. Malformed (or a file not read)
#                 turns self-merge off.
#             constraints ok N-hard M-soft|missing|none-hard|unreadable: WHY
#                 docs/constraints.md, which every loop prompt carries. A
#                 constraint is a line "H<n>: text" (hard) or "S<n>: text"
#                 (soft) at column 0, optionally after "- "; a hard one needs
#                 a "success: <observable>" line (any indent, optionally
#                 after "- ") before the next constraint, and no ID may
#                 repeat. Only "ok" lets the orchestrator dispatch.
#             A line counts as a copy when its letters alone, case folded,
#             start with the key's ("buildlooppolicy"), so markup, a table or
#             a misplaced colon cannot hide one.
#   --status  one line per brief path, in argument order, from the default
#             branch's commit:
#             ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]
#                 STATE: open, done or dropped (dev-cycle.sh --check-brief), or
#                 new when main has no file there (then "new review - absent
#                 - - 0"). POLICY: self-merge only when --settings' policy is
#                 self-merge and the brief's first "Policy:" line is exactly
#                 "Policy: self-merge"; else review. BRANCH: from the brief's
#                 first "Branch: NAME" line. LOOP: absent (no such branch),
#                 working, ready, blocked or stopped, from the branch tip
#                 (SHA, with DATE its commit date as YYYY-MM-DD; "-" when
#                 absent). A tip is a marker only when the branch is at least
#                 one commit ahead of main and the tip is an empty commit with
#                 one parent whose subject is exactly "handoff: ready",
#                 "handoff: blocked" or "handoff: stopped: REASON" (1-120
#                 printable ASCII characters, no blank at either end), alone
#                 on its first line; REASON is printed last. Any other tip is
#                 working. DISPATCHED: the brief's "Dispatched: N" (0-99), or
#                 0 without one.
#             skip BRIEF: WHY
#                 The brief cannot be read (as --check-brief), its Branch: or
#                 Dispatched: line is missing or malformed, its branch name is
#                 refused (as --check-branch), another open brief on main
#                 names the same branch (ignoring case), or the tip's subject
#                 starts "handoff:" but it is not a marker.
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

usage() { echo "$1 (usage: build-loop.sh --settings | --status BRIEF...)" >&2; exit 1; }
MODE=""; ARGS=()
case "${1:-}" in
  --settings) MODE=settings; [[ $# -eq 1 ]] || usage "--settings takes no arguments" ;;
  --status) MODE=status; shift; ARGS=("$@"); [[ $# -gt 0 ]] || usage "--status needs at least one brief path" ;;
  -h|--help) sed -n '2,67p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  '') usage "no mode given" ;;
  *) usage "Unknown option: $1" ;;
esac

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
# shellcheck disable=SC2034  # read by the lib's file rules
ROOT_REAL="$(pwd -P)"
# Read main's own objects: a replace ref could swap in any settings blob.
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
# everything but letters is dropped and case folded (so markup, blanks, a BOM
# or a misplaced colon cannot hide a copy), the first two line numbers, whether
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
# docs/constraints.md: "ok HARD SOFT", "nosuccess ID LINE" or "dup ID FIRST
# SECOND" (the first problem found).
# shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal
CONSTRAINTS_AWK='
{ sub(/\r$/, "") }
fence($0) { next }
/^(- )?[HS][0123456789]+: [^ \t]/ {
  id = $0; sub(/^- /, "", id); sub(/:.*/, "", id)
  if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl
  if (bad == "" && (id in seen)) bad = "dup " id " " seen[id] " " NR
  if (!(id in seen)) seen[id] = NR
  if (substr(id, 1, 1) == "H") { hard++; pend = id; pendl = NR } else { soft++; pend = "" }
  next
}
/^[ \t]*(- )?success: [^ \t]/ { pend = "" }
END {
  if (odd) print "odd " odd " " oddwhy
  else if (infence) print "unbalanced " fline
  else {
    if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl
    print (bad != "" ? bad : "ok " hard + 0 " " soft + 0)
  }
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
# each as written, a trailing / kept), NEVER_LINE and CONSTRAINTS_LINE from
# main's commit. POLICY
# and NEVER are for the modes that judge a brief (--status, then the gate).
POLICY=review; POLICY_LINE=""; SLOTS_LINE=""; NEVER=(); NEVER_LINE=""; CONSTRAINTS_LINE=""
# shellcheck disable=SC2034  # POLICY and NEVER: see above
read_settings() {
  local f=docs/dev-cycle.md where l k c l1 l2 nx t v g i why never_ok=1 parts=()
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
    # Self-merge never: first, because a malformed line turns self-merge off.
    if [[ -z "${cnt[never]-}" ]]; then NEVER_LINE='never none: no line starts "Self-merge never:"'
    elif [[ "${cnt[never]}" -gt 1 ]]; then NEVER_LINE="never malformed: $(many 'Self-merge never:' never)"; never_ok=""
    else
      t="${text[never]}"; v="${t#Self-merge never: }"; why=""
      # Split on single spaces only; globform then refuses any other blank in an entry.
      if [[ "$t" != "Self-merge never: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
        why='is not exactly "Self-merge never: GLOB ..." with single spaces'
      elif [[ "${next[never]}" != 1 ]]; then why="is followed by a non-blank line (Markdown would join it as more globs)"
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
      if [[ -n "$why" ]]; then NEVER_LINE="never malformed: line ${first[never]} $why"; never_ok=""
      else NEVER=("${parts[@]}"); NEVER_LINE="never $v set: line ${first[never]} $where"; fi
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
  f=docs/constraints.md
  if ! main_file "$f" "$CONSTRAINTS_AWK"; then
    if [[ "$FILE_WHY" == absent ]]; then CONSTRAINTS_LINE="constraints missing: no $f on the default branch"
    else CONSTRAINTS_LINE="constraints unreadable: $FILE_WHY"; fi
  else
    read -r k c l1 l2 <<<"$FILE_OUT"
    case "$k" in
      ok) if [[ "$c" -gt 0 ]]; then CONSTRAINTS_LINE="constraints ok $c-hard $l1-soft: $f on the default branch"
          else CONSTRAINTS_LINE="constraints none-hard: $f on the default branch has $l1 soft constraints and no hard one (H1: with a success: line)"; fi ;;
      nosuccess) CONSTRAINTS_LINE="constraints unreadable: hard constraint $c (line $l1) has no success: line before the next constraint" ;;
      *) CONSTRAINTS_LINE="constraints unreadable: constraint $c is listed twice (lines $l1 and $l2)" ;;
    esac
  fi
}

# The tip SHA of a brief's branch, read as a handoff marker: prints ready,
# blocked, "stopped REASON", working (no "handoff:" subject), or "bad WHY".
# The caller has checked that the branch is at least one commit ahead of main.
marker_kind() {
  local raw hdr msg subj rest l np=0 parent="" tree="" ptree r
  raw="$(git cat-file commit "$1")"
  hdr="${raw%%$'\n\n'*}"; msg=""; [[ "$raw" != *$'\n\n'* ]] || msg="${raw#*$'\n\n'}"
  subj="${msg%%$'\n'*}"
  [[ "$subj" == handoff:* ]] || { echo working; return; }
  while IFS= read -r l; do
    case "$l" in "tree "*) tree="${l#tree }" ;; "parent "*) np=$((np + 1)); parent="${l#parent }" ;; esac
  done <<<"$hdr"
  if [[ "$np" -eq 0 ]]; then echo "bad it has no parent"; return; fi
  if [[ "$np" -gt 1 ]]; then echo "bad it has $np parents"; return; fi
  ptree="$(git rev-parse --verify --quiet "$parent^{tree}" || true)"
  if [[ "$tree" != "$ptree" ]]; then echo "bad it changes files"; return; fi
  rest="${msg#"$subj"}"; rest="${rest#$'\n'}"
  if [[ "$msg" == *$'\n'* && -n "${rest%%$'\n'*}" ]]; then echo "bad its subject runs onto a second line"; return; fi
  case "$subj" in
    "handoff: ready") echo ready; return ;;
    "handoff: blocked") echo blocked; return ;;
  esac
  r="${subj#handoff: stopped: }"
  # Bytes, not characters: in the C locale the ranges below are ASCII and ${#r}
  # counts bytes (C is always installed, so setting it never warns).
  local LC_ALL=C
  if [[ "$subj" == "handoff: stopped: "* && ${#r} -le 120 && "$r" =~ ^[!-~]([\ -~]*[!-~])?$ ]]; then echo "stopped $r"
  else echo 'bad its subject is not exactly "handoff: ready", "handoff: blocked" or "handoff: stopped: REASON" (REASON: 1 to 120 printable ASCII characters, no blank at either end)'; fi
}
# Lower-cased branch names that more than one open brief on main names, each
# on its own line between newlines: such briefs are skipped (F31).
SHARED_BRANCHES=""
shared_branches() {
  local f list b
  local -A n=()
  list="$(git ls-tree --full-tree --name-only "$MAIN_SHA" -- docs/working/briefs/)"
  while IFS= read -r f; do
    if ! isbrief "$f" || [[ "$(main_entry "$f")" != blob ]] || ! brief_fields "$f"; then continue; fi
    [[ "${BRIEF[status]-}" == "Status: open" && "${BRIEF[branch]-}" =~ ^Branch:\ ([^\ ]+)$ ]] || continue
    b="$(lower "${BASH_REMATCH[1]}")"; n[$b]=$(( ${n[$b]-0} + 1 ))
  done <<<"$list"
  SHARED_BRANCHES=$'\n'
  for b in "${!n[@]}"; do [[ "${n[$b]}" -lt 2 ]] || SHARED_BRANCHES+="$b"$'\n'; done
}
status_line() {
  local a="$1" out st br sha ahead date loop kind reason="" pol=review disp=0
  out="$(check_brief "$a")"
  [[ "$out" == "ok "* ]] || { echo "$out"; return; }
  read -r _ _ st _ <<<"$out"
  if [[ "$st" == new ]]; then echo "ok $a new review - absent - - 0"; return; fi
  brief_fields "$a" || { echo "skip $a: the brief is not read"; return; }
  if [[ -z "${BRIEF[branch]+set}" ]]; then echo "skip $a: no Branch: line on the default branch"; return; fi
  if [[ ! "${BRIEF[branch]}" =~ ^Branch:\ ([^\ ]+)$ ]]; then echo "skip $a: its first Branch: line is not exactly \"Branch: NAME\""; return; fi
  br="${BASH_REMATCH[1]}"
  if [[ -n "${BRIEF[dispatched]+set}" ]]; then
    [[ "${BRIEF[dispatched]}" =~ ^Dispatched:\ (0|[123456789][0123456789]?)$ ]] \
      || { echo "skip $a: its first Dispatched: line is not exactly \"Dispatched: N\" with N from 0 to 99"; return; }
    disp="${BASH_REMATCH[1]}"
  fi
  [[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge
  if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then
    echo "skip $a: another open brief on the default branch names the same branch (compared ignoring case)"; return
  fi
  out="$(check_branch "$br")"
  case "$out" in
    "absent "*) echo "ok $a $st $pol $br absent - - $disp"; return ;;
    "ok "*) read -r _ _ sha ahead date <<<"$out" ;;
    *) echo "skip $a: Branch: ${out#*: }"; return ;;
  esac
  loop=working
  if [[ "$ahead" -gt 0 ]]; then
    kind="$(marker_kind "$sha")"
    case "$kind" in
      bad\ *) echo "skip $a: the tip of $br starts \"handoff:\" but is not a marker: ${kind#bad }"; return ;;
      stopped\ *) loop=stopped; reason=" ${kind#stopped }" ;;
      *) loop="$kind" ;;
    esac
  fi
  echo "ok $a $st $pol $br $loop $sha $date $disp$reason"
}

case "$MODE" in
  status)
    read_settings; shared_branches
    for a in "${ARGS[@]}"; do status_line "$a"; done
    ;;
  settings)
    read_settings
    printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE"
    ;;
esac
