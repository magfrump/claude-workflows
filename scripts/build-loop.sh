#!/usr/bin/env bash
# The build-loop handoff's state and checks: what the dev cycle's orchestrator
# reads before it dispatches a build brief to a build loop, collects the
# loop's result, or merges it (docs/working/plan-build-loop-handoff.md).
#
# Usage: scripts/build-loop.sh --settings
#        scripts/build-loop.sh --status BRIEF...
#        scripts/build-loop.sh --check BRIEF... [--expect SHA]
#        scripts/build-loop.sh -h | --help
#
#   --settings  four lines from the default branch's commit, never the working
#             tree (a build loop can write any working tree). Lines 1-3 from
#             one line of docs/dev-cycle.md; a second copy, or a file the lib's
#             FENCE_AWK refuses, gives review, 3 and malformed (WHY says which):
#             policy self-merge|review set|unset: WHY
#                 Set only by "Build-loop policy: self-merge" or "...: review",
#                 exactly (one trailing CR dropped); else review. Self-merge
#                 also needs one valid never line. A never list in markup the
#                 copy count sees (bold, a list marker, an unchecked task box)
#                 counts as a copy, so self-merge is off; one it misses (a
#                 checked task box, a fence) is ignored, so self-merge rests on
#                 the valid line alone.
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
#             constraints ok N-hard M-soft|missing|none-hard|unreadable: WHY
#                 docs/constraints.md, which every loop prompt carries. A
#                 constraint is a line "H<n>: text" (hard) or "S<n>: text"
#                 (soft) at column 0, optionally after "- ", n without a
#                 leading 0; a hard one needs a "success: <observable>" line
#                 (any indent, optionally after "- ") before the next
#                 constraint or "#" heading; no ID repeats; fences are skipped.
#                 A line starting like "h1"/"s1" in letters and digits (after
#                 marks and a task box) but not exact makes the file unreadable
#                 (best effort). Only "ok" lets the orchestrator dispatch.
#             Copies are found best effort: a line counts as one when its
#             letters alone, case folded, start with the key's
#             ("buildlooppolicy"). Markup that adds letters (a checked task
#             box, a tag) can still hide a copy; only an exact line ever sets
#             a value.
#   --status  one line per brief path, in argument order, from the default
#             branch's commit (the path must also be plain in the working
#             tree, as --check-brief):
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
#                 on its first line (a second line, if any, empty); REASON is
#                 printed last. A tip on a branch not ahead of main, or whose
#                 subject does not start "handoff:", is working. DISPATCHED:
#                 the brief's "Dispatched: N" (0-99), or 0 without one.
#             skip BRIEF: WHY
#                 The brief cannot be read (as --check-brief), its Branch:
#                 line is missing or malformed or its Dispatched: line
#                 malformed, its branch name is refused (as --check-branch)
#                 or its commit count or date cannot be read; on a branch
#                 ahead of main the tip's subject (its message's first line)
#                 starts "handoff:" but it is not a marker (or the tip cannot
#                 be read); or, for
#                 an open brief only, another open brief on main (in briefs/ or
#                 closed/) names the same branch (ignoring case) or the open
#                 briefs on main could not be listed.
#   --check   the gate (D7), advisory when a loop runs it. First a state gate:
#             a git config key (common config or config.worktree, includes not
#             followed) for a filter, include, config hook, merge or diff
#             setting, core.fsmonitor, core.attributesFile, core.hooksPath,
#             gpg.*, log.showSignature, extensions.partialClone or
#             remote.*.promisor (a partial clone); an info/attributes,
#             info/grafts or shallow that is not absent or an empty file; a
#             replace ref; an origin/HEAD naming any branch but origin/main or
#             origin/master; then (once main is found) both main and master
#             present, or origin/HEAD naming another branch than the one taken.
#             Each finding prints "refuse state WHAT: WHY" and exits 2 before
#             any brief is read ("refuse state gate: WHY" when the gate's own
#             merge repository cannot be set up). Then, per brief path, in
#             argument order, one verdict line:
#             ok BRIEF TIP TREE
#                 --status reads the brief as open and its branch at TIP, at
#                 least one commit ahead of main (and TIP equals SHA when
#                 --expect is given, a full 40- or 64-hex id with exactly one
#                 brief); TREE is the merge of TIP into main as merge-tree
#                 writes it, run where no repo config or checkout attributes
#                 are read; and no changed path is denied.
#             refuse BRIEF: WHY
#                 The brief is done, dropped or new on main, its branch is
#                 absent or not ahead, it moved or could not be read again
#                 after --status read it, TIP is not SHA, the merge conflicts,
#                 or the merge (or its changed paths) could not be computed:
#                 git failed, or warned on stderr (a missing tree object), or
#                 the tree of main, TIP or a merge base is missing. Or "the
#                 merge of BRANCH names a blob the object store lacks": a
#                 regular file the merge adds or changes names an object that
#                 is absent or not a blob. Or "K of N changed paths refused in
#                 the merge of TIP (tree TREE)", when deny lines follow.
#             skip BRIEF: WHY
#                 As --status skips it.
#             After an ok line or a K of N refusal, one line per path TREE
#             changes against main (diff-tree -r --no-renames, so a rename is
#             its D and A sides), in diff-tree's order; S is its status letter
#             (A, M, D or T) and PATH is "?" unless every character is one
#             pathform allows:
#             path BRIEF S PATH
#             deny BRIEF S PATH: WHY
#                 The N rules, under either policy: a path pathform refuses
#                 (a part starting .git, any case: .github/); a mode other than 100644 or 100755
#                 on either side (a symlink or gitlink); the brief's own file,
#                 unless only its first Status: line outside a fence changes,
#                 from open to done (mode kept); and, compared lower-cased, the
#                 dev cycle's own files (the roadmap, the questions files, the
#                 idea log, docs/dev-cycle.md, anything under
#                 docs/working/briefs/ or docs/working/cycles/) and
#                 docs/constraints.md.
#
# Acts on $PWD's git repo, like dev-cycle.sh, and needs its default branch
# found by name (origin/HEAD, main or master). Writes nothing but --check's
# merge objects (merge-tree writes the merged trees and blobs into the object
# store) and its own temporary directory, removed at exit.
# Output passes through the lib's scrub (but for the start-up errors about
# perl and the lib); printed repo text is data.
# Exit: 0 every line printed (or help), and for --check every verdict line ok;
# 2 any --check verdict line or the state gate not ok; 1 bad usage, not a git
# repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name.

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

usage() { echo "$1 (usage: build-loop.sh --settings | --status BRIEF... | --check BRIEF... [--expect SHA])" >&2; exit 1; }
MODE=""; ARGS=(); EXPECT=""
case "${1:-}" in
  --settings) MODE=settings; [[ $# -eq 1 ]] || usage "--settings takes no arguments" ;;
  --status) MODE=status; shift; ARGS=("$@"); [[ $# -gt 0 ]] || usage "--status needs at least one brief path" ;;
  --check)
    MODE=check; shift
    while [[ $# -gt 0 ]]; do
      if [[ "$1" == --expect ]]; then
        [[ $# -ge 2 && -z "$EXPECT" ]] || usage "--expect takes one commit id, given once"
        # The full id only: a short id, a branch name or HEAD would let git pick the commit.
        [[ "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || usage "--expect takes a full 40- or 64-hex commit id"
        EXPECT="$2"; shift 2
      else ARGS+=("$1"); shift; fi
    done
    [[ ${#ARGS[@]} -gt 0 ]] || usage "--check needs at least one brief path"
    [[ -z "$EXPECT" || ${#ARGS[@]} -eq 1 ]] || usage "--expect goes with exactly one brief path" ;;
  # The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale).
  -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  '') usage "no mode given" ;;
  *) usage "Unknown option: $1" ;;
esac

# Every git call in this process, the lib's included, runs hardened. Config
# pairs outrank the repo's config: main's own objects (core.useReplaceRefs in
# the repo's config would override GIT_NO_REPLACE_OBJECTS), no hook, no
# fsmonitor command, no core.attributesFile, no commit-graph (a forged one
# changes merge bases). GIT_CONFIG_GLOBAL=/dev/null: a loop can write the
# user's ~/.gitconfig as easily as .git/config. GIT_ALLOW_PROTOCOL=none: no
# transport at all, so a lazy fetch (a partial clone's missing object) fails
# however the config was planted, even after the state gate read it. The
# caller's own environment is trusted: its `git -c` or a zero-padded
# GIT_CONFIG_COUNT can still win (U3b's --state). What the rest cannot switch
# off, --check's state gate refuses.
harden() {
  local c="${GIT_CONFIG_COUNT:-0}" kv
  for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false; do
    export "GIT_CONFIG_KEY_$c=${kv%%=*}" "GIT_CONFIG_VALUE_$c=${kv#*=}"; c=$((c + 1))
  done
  export GIT_CONFIG_COUNT="$c"
}
harden
# GIT_CONFIG_NOSYSTEM: the system config is no more the gate's than the
# user's (merge.directoryRenames there flipped a conflict: A17).
export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none
# The gate's state check (D7, F25): repo-local git state that can make the
# gate's git run a command or change what it reads, which harden does not
# switch off. Prints one "refuse state WHAT: WHY" line per finding, returns 1
# on any, and reads no object (git config --file --no-includes follows no
# include; --git-path reads no index). Keys, in the common config and this
# worktree's config.worktree: filter drivers, every merge.* and diff.* key (drivers run commands), config
# hooks, includes, core.fsmonitor, core.attributesFile, core.hooksPath, gpg and
# log.showSignature (gpg.program runs), and a partial clone (extensions.partialClone, remote.*.promisor;
# GIT_ALLOW_PROTOCOL already stops its fetch). Files: an info/attributes,
# info/grafts or shallow that is not absent or an empty regular file (each
# changes merges or history), a ref under refs/replace/, and an origin/HEAD naming any branch but
# origin/main or origin/master (resolve_main would take the default branch
# from it).
STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'
state_gate() {
  local f p out rc line bad=0 refs
  for f in config config.worktree; do
    p="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)" || { echo "refuse state $f: its path could not be read"; return 1; }
    [[ -f "$p" ]] || { [[ "$f" == config.worktree ]] && continue; echo "refuse state config: no git config file at $p"; return 1; }
    rc=0; out="$(git config --file "$p" --no-includes --name-only --get-regexp "$STATE_KEYS_RE")" || rc=$?
    if [[ "$rc" -gt 1 ]]; then echo "refuse state $f: it could not be read (git config exit $rc)"; bad=1; continue; fi
    while IFS= read -r line; do
      [[ -n "$line" ]] && { echo "refuse state $line: set in $f, it can make the gate's git run a command or change its merge"; bad=1; }
    done <<<"$out"
  done
  for f in info/attributes info/grafts shallow; do
    p="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)" || { echo "refuse state $f: its path could not be read"; return 1; }
    if [[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]; then echo "refuse state $f: present and not an empty file"; bad=1; fi
  done
  refs="$(git for-each-ref --format='%(refname)' refs/replace/)" || { echo "refuse state refs/replace: could not be listed"; return 1; }
  [[ -z "$refs" ]] || { echo "refuse state refs/replace: $(printf '%s\n' "$refs" | wc -l) replace ref(s)"; bad=1; }
  rc=0; p="$(git symbolic-ref -q refs/remotes/origin/HEAD)" || rc=$?
  if [[ "$rc" -gt 1 ]] || [[ -n "$p" && "$p" != refs/remotes/origin/main && "$p" != refs/remotes/origin/master ]]; then
    echo "refuse state origin/HEAD: it names a branch other than origin/main or origin/master"; bad=1
  fi
  return "$bad"
}
# The state gate's second half, once resolve_main has run (U3b's --state calls
# both): the default branch counts only when no other name could claim it. A
# loop can create a local master beside main (or main beside master) and point
# origin/HEAD at it, and resolve_main would follow (R7). Prints one line per
# finding, as state_gate does; returns 1 on any.
default_gate() {
  local p bad=0
  if git show-ref --verify --quiet refs/heads/main && git show-ref --verify --quiet refs/heads/master; then
    echo "refuse state default-branch: both main and master exist"; bad=1
  fi
  p="$(git symbolic-ref -q refs/remotes/origin/HEAD)" || true
  if [[ -n "$p" && "$p" != "refs/remotes/origin/$MAIN" ]]; then
    echo "refuse state default-branch: origin/HEAD names ${p#refs/remotes/}, but the default branch taken is $MAIN"; bad=1
  fi
  return "$bad"
}
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
# shellcheck disable=SC2034  # read by the lib's file rules
ROOT_REAL="$(pwd -P)"
# --check refuses planted state before any git call reads an object (resolve_main does).
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
resolve_main || true
main_by_name || { echo "build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none" >&2; exit 1; }
if [[ "$MODE" == check ]]; then default_gate || exit 2; fi

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
    *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;
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
# a BOM or a misplaced colon cannot hide a copy), the first two line numbers,
# whether the next line outside a fence after the first is blank or the end of
# the file (NEXT 1) or not, and the first line whole:
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
# docs/constraints.md: "ok HARD SOFT", "nosuccess ID LINE", "dup ID FIRST
# SECOND" or "near LINE" (the first problem found).
# shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal
CONSTRAINTS_AWK='
{ sub(/\r$/, "") }
fence($0) { next }
/^(- )?[HS][123456789][0123456789]*: [^ \t]/ {
  id = $0; sub(/^- /, "", id); sub(/:.*/, "", id)
  if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl
  if (bad == "" && (id in seen)) bad = "dup " id " " seen[id] " " NR
  if (!(id in seen)) seen[id] = NR
  if (substr(id, 1, 1) == "H") { hard++; pend = id; pendl = NR } else { soft++; pend = "" }
  next
}
{ s = $0; sub(/^([^a-zA-Z]|\[[ xX]\])*/, "", s); s = tolower(s); gsub(/[^a-z0123456789]/, "", s) }
s ~ /^[hs][0123456789]/ { if (bad == "") bad = "near " NR; next }  # looks like an ID but is not exact
/^#/ { if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl; pend = ""; next }  # a heading ends a pending one
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
# is for --status and the planned gate, NEVER for the gate.
POLICY=review; POLICY_LINE=""; SLOTS_LINE=""; NEVER=(); NEVER_LINE=""; CONSTRAINTS_LINE=""
# shellcheck disable=SC2034  # NEVER: for the planned gate
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
  f=docs/constraints.md
  if ! main_file "$f" "$CONSTRAINTS_AWK"; then
    if [[ "$FILE_WHY" == absent ]]; then CONSTRAINTS_LINE="constraints missing: no $f on the default branch"
    else CONSTRAINTS_LINE="constraints unreadable: $FILE_WHY"; fi
  else
    read -r k c l1 l2 <<<"$FILE_OUT"
    case "$k" in
      ok) if [[ "$c" -gt 0 ]]; then CONSTRAINTS_LINE="constraints ok $c-hard $l1-soft: $f on the default branch"
          else CONSTRAINTS_LINE="constraints none-hard: $f on the default branch has $l1 soft constraint(s) and no hard one (H1: with a success: line)"; fi ;;
      nosuccess) CONSTRAINTS_LINE="constraints unreadable: hard constraint $c (line $l1) has no success: line before the next constraint or \"#\" heading" ;;
      dup) CONSTRAINTS_LINE="constraints unreadable: constraint $c is listed twice (lines $l1 and $l2)" ;;
      *) CONSTRAINTS_LINE="constraints unreadable: line $c looks like a constraint but is not exactly \"H<n>: text\" or \"S<n>: text\" (optionally after \"- \", n without a leading 0)" ;;
    esac
  fi
}

# The tip SHA of a brief's branch, read as a handoff marker: prints ready,
# blocked, "stopped REASON", working (no "handoff:" subject), or "bad WHY".
# The caller has checked that the branch is at least one commit ahead of main.
marker_kind() {
  local msg subj rest p r
  # git parses the parents; the message is the raw object's text after its
  # first empty line (no header holds one), read with cat-file so no log.* or
  # i18n.* config can change or break it. A failed read answers bad, never
  # working (row 307).
  # NULs are dropped here (bash would warn on stderr); the NUL check below reads the raw object.
  if ! p="$(git rev-list --parents -n 1 "$1" 2>/dev/null)" || ! msg="$(git cat-file commit "$1" 2>/dev/null | tr -d '\000')"; then
    echo "bad its commit could not be read"; return
  fi
  if [[ "$msg" == *$'\n\n'* ]]; then msg="${msg#*$'\n\n'}"; else msg=""; fi
  read -ra p <<<"$p"; subj="${msg%%$'\n'*}"
  [[ "$subj" == handoff:* ]] || { echo working; return; }
  if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"; return; fi
  if [[ ${#p[@]} -eq 1 ]]; then echo "bad it has no parent"; return; fi
  if [[ ${#p[@]} -gt 2 ]]; then echo "bad it has $(( ${#p[@]} - 1 )) parents"; return; fi
  if [[ "$(git rev-parse --verify "$1^{tree}")" != "$(git rev-parse --verify "${p[1]}^{tree}")" ]]; then echo "bad it changes files"; return; fi
  rest="${msg#"$subj"}"; rest="${rest#$'\n'}"
  if [[ "$msg" == *$'\n'* && -n "${rest%%$'\n'*}" ]]; then echo "bad its subject runs onto a second line"; return; fi
  case "$subj" in
    "handoff: ready") echo ready; return ;;
    "handoff: blocked") echo blocked; return ;;
  esac
  r="${subj#handoff: stopped: }"
  # grep in the C locale: the ranges are ASCII bytes, and no locale is switched here.
  if [[ "$subj" == "handoff: stopped: "* ]] && printf '%s\n' "$r" | LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'; then echo "stopped $r"
  else echo 'bad its subject is not exactly "handoff: ready", "handoff: blocked" or "handoff: stopped: REASON" (REASON: 1 to 120 printable ASCII characters, no blank at either end)'; fi
}
status_line() {
  local a="$1" out st br sha ahead date loop kind reason="" pol=review disp=0
  open_shared
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
  if [[ "$st" == open && "$OPEN_SHARED" == error ]]; then echo "skip $a: the open briefs on the default branch could not be listed"; return; fi
  if [[ "$st" == open && "$OPEN_SHARED" == *$'\n'"$(lower "$br")"$'\n'* ]]; then
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

# merge_result's own repository, set up once per run in GATE_TMP (the caller's
# mktemp -d, removed at exit): a git dir with no config but the repo's object
# format, no modules/, info/ or shallow, and an empty directory to run in, so
# merge-tree reads none of the repo's config (a submodule repository under
# .git/modules is never opened), no checkout's .gitattributes (git 2.39 reads
# one from the current directory even under --work-tree), and only the repo's
# object store (GIT_OBJECT_DIRECTORY, where it also writes). GATE_ENV unsets the
# repo-local variables (GIT_COMMON_DIR and the like) that would point it back.
GATE_TMP=""; GATE_ENV=()
gate_repo() {
  local fmt v
  GATE_ENV=(env)
  for v in $(git rev-parse --local-env-vars); do [[ "$v" == GIT_CONFIG* || "$v" == GIT_NO_REPLACE_OBJECTS ]] || GATE_ENV+=(-u "$v"); done
  v="$(git rev-parse --path-format=absolute --git-path objects)" && fmt="$(git rev-parse --show-object-format)" \
    && [[ "$fmt" == sha1 || "$fmt" == sha256 ]] && mkdir "$GATE_TMP/git" "$GATE_TMP/git/refs" "$GATE_TMP/work" || return 1
  printf 'ref: refs/heads/none\n' > "$GATE_TMP/git/HEAD"
  printf '[core]\n\trepositoryformatversion = 1\n[extensions]\n\tobjectformat = %s\n' "$fmt" > "$GATE_TMP/git/config"
  GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")
}
# gate_git ARGS...: git in the gate repository, stdout passed through; returns
# git's status, or 3 when git wrote anything to stderr (a missing object can
# warn and still exit 0: R6).
gate_git() {
  local rc=0
  (cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@") 2>"$GATE_TMP/err" || rc=$?
  [[ ! -s "$GATE_TMP/err" ]] || return 3
  return "$rc"
}
# The merge of TIP into MAIN_SHA as the gate lands it (D7): prints the result
# tree; returns 1 on a conflict (a gitlink both sides moved is one, since no
# submodule repository is reachable), 2 when git failed or warned, or the
# tree of main, the tip or a merge base is missing (R6).
merge_result() {
  local out b bases rc=0
  bases="$(gate_git merge-base --all "$MAIN_SHA" "$1")" || rc=$?
  [[ "$rc" -le 1 ]] || return 2
  # shellcheck disable=SC2086  # one commit id per word
  for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done
  rc=0; out="$(gate_git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1")" || rc=$?
  [[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2
  [[ "$rc" -eq 0 ]] || return 1
  echo "${out%%$'\n'*}"
}
# The blob id the brief's own file $1 may have in the merge (F13): main's copy
# with its first Status: line outside a fence, the one brief_fields reads
# (status_line has read it as "Status: open"), reading "Status: done", every
# other byte kept (a CR at its end too). Returns non-zero when a read fails;
# the caller checks it (hash-object would hash a truncated read).
own_blob() {
  local n
  # The whole blob is read (no early exit: SIGPIPE under pipefail).
  # shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal
  n="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } !n && /^Status:/ { n = NR } END { print n + 0 }')" || return 1
  [[ "$n" -gt 0 ]] || return 1
  git cat-file blob "$MAIN_SHA:$1" | N="$n" perl -pe 's/^Status: open(\r?)$/Status: done$1/ if $. == $ENV{N}' | gate_git hash-object --no-filters --stdin
}
# The N rules (plan D5; both policies) for one changed path of brief $1:
# diff-tree's old and new modes $2 $3, new blob $4, status $5, path $6 and
# its lower-cased spelling $7. Sets DENY to why the path is refused, or
# empties it. The brief's own file is matched exactly; the cycle's files
# (truthrule's cycle and settings words: writable() and docs/dev-cycle.md,
# plus anything under docs/working/briefs/ or docs/working/cycles/) and the
# constraints doc (its user word) compare lower-cased, as a case-insensitive
# checkout reads Docs/Roadmap.md as the roadmap. U2c adds the S rules.
DENY=""
nrules() {
  local ob
  DENY=""
  if ! pathform "$6"; then DENY="not an allowed path form (letters, digits and . _ - / only; no leading - or /; no empty, . or .. part; no part starting .git)"
  elif [[ ! "$2 $3" =~ ^(000000|100644|100755)\ (000000|100644|100755)$ ]]; then DENY="a symlink, gitlink or other non-file entry on one side (only modes 100644 and 100755 land)"
  elif [[ "$6" == "$1" ]]; then
    { [[ "$5" == M && "$2" == "$3" ]] && ob="$(own_blob "$1")" && [[ "$4" == "$ob" ]]; } \
      || DENY="this brief: only its first Status: line outside a fence may change, from open to done"
  else
    # $7 is lower-cased, so the case word cannot fire; instr and dot, tested
    # before cycle, match no cycle file, docs/dev-cycle.md or docs/constraints.md
    # today (T14 fails if one ever does: truthrule names this third consumer).
    truthrule "$7" || true
    case "$TRUTH_WHY" in
      cycle|settings) DENY="one of the dev cycle's own files" ;;
      user) DENY="the user's constraints doc, which every loop prompt carries" ;;
      *) [[ ! "$7" =~ ^docs/working/(briefs|cycles)/ ]] || DENY="one of the dev cycle's own files" ;;
    esac
  fi
}
# --check for one brief: "ok BRIEF TIP TREE" or "refuse BRIEF: K of N changed
# paths refused in the merge of TIP (tree TREE)", then a "path BRIEF S PATH" or
# "deny BRIEF S PATH: WHY" line per path the merge changes against main
# (diff-tree's status letter S, in its order; PATH is "?" unless every
# character is one pathform allows); or one skip or refuse line (from
# status_line, then the gate's own reasons).
check_line() {
  local a="$1" out st br loop sha n tree meta p shown rc=0 i nd=0 rows=() oms=() nms=() nos=() ss=() ps=() lps=() ids=()
  out="$(status_line "$a")"
  [[ "$out" == "ok "* ]] || { echo "$out"; return; }
  read -r _ _ st _ br loop sha _ <<<"$out"
  if [[ "$st" != open ]]; then echo "refuse $a: the brief is $st on the default branch; only an open brief merges"; return; fi
  if [[ "$loop" == absent ]]; then echo "refuse $a: its branch $br does not exist"; return; fi
  out="$(check_branch "$br")"
  read -r _ _ _ n _ <<<"$out"
  if [[ "$out" != "ok $br $sha "* || ! "$n" =~ ^$DIGIT+$ ]]; then echo "refuse $a: its branch $br moved or could not be read again"; return; fi
  if [[ "$n" -eq 0 ]]; then echo "refuse $a: its branch $br has no commit the default branch lacks"; return; fi
  if [[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]; then echo "refuse $a: the tip of $br is $sha, not the expected $EXPECT"; return; fi
  tree="$(merge_result "$sha")" || rc=$?
  case "$rc" in
    0) ;;
    1) echo "refuse $a: $br conflicts with the default branch"; return ;;
    *) echo "refuse $a: the merge of $br could not be computed"; return ;;
  esac
  # In the gate repository, so no repo config or checkout .gitmodules hides a
  # moved gitlink (A16); --no-renames, so a rename is judged as both its sides (F6).
  if ! gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree" > "$GATE_TMP/diff"; then
    echo "refuse $a: the paths the merge of $br changes could not be listed"; return
  fi
  while IFS= read -r -d '' meta && IFS= read -r -d '' p; do
    [[ "$meta" =~ ^:([01234567]{6})\ ([01234567]{6})\ [0123456789abcdef]+\ ([0123456789abcdef]+)\ ([AMDT])$ ]] \
      || { echo "refuse $a: the paths the merge of $br changes could not be read"; return; }
    oms+=("${BASH_REMATCH[1]}"); nms+=("${BASH_REMATCH[2]}"); nos+=("${BASH_REMATCH[3]}"); ss+=("${BASH_REMATCH[4]}"); ps+=("$p")
    [[ "${nms[-1]}" != 100644 && "${nms[-1]}" != 100755 ]] || ids+=("${nos[-1]}")
  done < "$GATE_TMP/diff"
  # Every record read whole: two NUL-ended fields each.
  if [[ "$(tr -cd '\000' < "$GATE_TMP/diff" | wc -c)" -ne $((2 * ${#ps[@]})) ]]; then echo "refuse $a: the paths the merge of $br changes could not be read"; return; fi
  if [[ ${#ps[@]} -eq 0 ]]; then echo "ok $a $sha $tree"; return; fi
  # merge-tree passes a side's unchanged blob by id without reading it, so a
  # blob the store lacks would land unseen: every regular file the merge adds
  # or changes must name a blob present in the store (a missing subtree already
  # failed diff-tree).
  if [[ ${#ids[@]} -gt 0 ]] && { ! out="$(printf '%s\n' "${ids[@]}" | gate_git cat-file --batch-check='%(objecttype)')" \
    || [[ "$(printf '%s\n' "$out" | grep -cx blob)" -ne ${#ids[@]} ]]; }; then
    echo "refuse $a: the merge of $br names a blob the object store lacks"; return
  fi
  # One lower-casing pass for every path (a tr per path cost 1 to 2.5 ms each).
  if ! nul_list lps lower_all "${ps[@]}" || [[ ${#lps[@]} -ne ${#ps[@]} ]]; then echo "refuse $a: the paths the merge of $br changes could not be lower-cased"; return; fi
  for i in "${!ps[@]}"; do
    p="${ps[$i]}"; shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"
    nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"
    if [[ -n "$DENY" ]]; then nd=$((nd + 1)); rows+=("deny $a ${ss[$i]} $shown: $DENY"); else rows+=("path $a ${ss[$i]} $shown"); fi
  done
  if [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi
  printf '%s\n' "${rows[@]}"
}

case "$MODE" in
  status)
    read_settings
    for a in "${ARGS[@]}"; do status_line "$a"; done
    ;;
  settings)
    read_settings
    printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE"
    ;;
  check)
    read_settings
    open_shared  # once, in this shell: check_line runs in a subshell
    GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
    gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
    fails=0
    for a in "${ARGS[@]}"; do
      out="$(check_line "$a")"; printf '%s\n' "$out"
      [[ "$out" == "ok "* ]] || fails=1
    done
    [[ "$fails" -eq 0 ]] || exit 2
    ;;
esac
