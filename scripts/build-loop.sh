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
#   --settings  five lines from the default branch's commit, never the working
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
#             readers N-roots M-homes set|none|malformed: WHY
#                 The extra readers both import walks model (the lib's
#                 reader_settings): "Reader roots: PATH ..." (host spellings
#                 of the main worktree) and "Reader homes: PATH ..." (host
#                 homes), or "...: none". Each is one line, single spaces,
#                 the next line outside a fence blank or the end; a PATH is
#                 absolute, not / alone, of letters, digits and . _ - / with
#                 no empty, . or .. part, listed once. none: no file or no
#                 such line. malformed (a second copy, a bad line, or a file
#                 not read) fails both walks, so the floor refuses every path;
#                 its WHY ends "; both import walks fail".
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
#             present, or origin/HEAD naming another branch than the one taken;
#             then the gate's own merge repository not set up ("refuse state
#             gate: WHY"); then main's commit, or a tree or blob of its tree,
#             that does not hash to its id or cannot be read ("refuse state
#             objects: WHY"; every file the gate reads from main is one).
#             Each finding prints "refuse state WHAT: WHY" and exits 2 before
#             the settings or any brief is read. Then, per brief path, in
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
#                 absent or not ahead, TIP is not SHA, the merge conflicts,
#                 or the merge (or its changed paths) could not be computed:
#                 git failed, or warned on stderr (a missing tree object), or
#                 the tree of main, TIP or a merge base is missing. Or "the
#                 merge of BRANCH names a blob the object store lacks": a
#                 regular file the merge adds or changes names an object that
#                 is absent or not a blob. Or "an object of BRANCH's tip or of
#                 its merge does not hash to its id, or could not be read":
#                 the tip's commit, or a tree or blob of its tree or of TREE
#                 (gitlinks aside), read back and re-hashed (git checks no
#                 object's hash when it reads one, so a rewritten object
#                 file would pass for the committed one). Or "K of N changed paths refused in
#                 the merge of TIP (tree TREE)", when deny lines follow. Or,
#                 for a brief --status reads as self-merge, "a self-merge
#                 brief needs --check run from a clean checkout of the
#                 default branch's commit; WHY" (the text up to "; " is
#                 fixed, but a WHY naming a read failure is not one a clean
#                 checkout cures; path and deny lines follow it as they
#                 follow a K of N refusal):
#                 the checkout --check runs from (the self-merge floor reads
#                 it) has its HEAD at another commit; a repo-local git
#                 variable set (GIT_DIR, GIT_WORK_TREE, GIT_INDEX_FILE,
#                 GIT_CONFIG and the like; the caller's GIT_CONFIG_PARAMETERS
#                 and GIT_CONFIG_COUNT pairs, GIT_NO_REPLACE_OBJECTS and
#                 GIT_PREFIX aside); core.symlinks false, core.ignoreCase or
#                 core.sparseCheckout true (a value git cannot read as a
#                 boolean stops git itself first: exit 1, no line); an
#                 index entry marked skip-worktree, assume-unchanged or
#                 unmerged; a change git status shows (untracked files
#                 aside), or git status failing or warning; an untracked
#                 nested repository, or a gitlink's path that is a symlink,
#                 cannot be listed or holds files; a regular file main stores whose
#                 name holds a newline, starts with a quote or ends with a
#                 CR (the byte comparison cannot read it); or a regular file
#                 whose bytes are not main's blob (a filter,
#                 working-tree-encoding, ident or eol conversion); or a
#                 listing or hash of these that fails. Untracked and ignored
#                 files are allowed. The merge's own refusals above (a
#                 conflict, a missing blob...) come first; this one replaces
#                 only the verdict line, so a loop running --check from its
#                 own branch still gets the path lines. A review brief does
#                 not read the checkout.
#             skip BRIEF: WHY
#                 As --status skips it.
#             After an ok line, a K of N refusal or a checkout refusal, one line per path TREE
#             changes against main (diff-tree -r --no-renames, so a rename is
#             its D and A sides), in diff-tree's order; S is its status letter
#             (A, M, D or T) and PATH is "?" unless every character is one
#             pathform allows:
#             path BRIEF S PATH
#             deny BRIEF S PATH: WHY
#                 The N rules, under either policy: a path pathform refuses
#                 (a part starting .git, any case: .github/); a mode other
#                 than 100644 or 100755 on either side (a symlink or
#                 gitlink); the brief's own file, unless only its first
#                 Status: line outside a fence changes,
#                 from open to done (mode kept); and, compared lower-cased, the
#                 dev cycle's own files (the roadmap, the questions files, the
#                 idea log, docs/dev-cycle.md, anything under
#                 docs/working/briefs/ or docs/working/cycles/, or either
#                 as a file) and docs/constraints.md, or a path below one of
#                 those names.
#                 Then the S rules, for a brief --status reads as self-merge,
#                 on each path the N rules pass but the brief's own file
#                 (first match): the self-merge floor (the lib's floor:
#                 instruction and prompt files and what they import with @,
#                 a path below the name of an instruction or prompt file
#                 or of an imported .md file, dot paths, the gate's own code, the user's and the
#                 cycle's records, a working doc or review that is not the
#                 brief's own; a walk that fails refuses every path, its
#                 reason saying where, with a PATH outside pathform's
#                 characters shown as ?; not run when the verdict already refuses for the
#                 checkout, so a loop's advisory run
#                 from its own branch can print a path the floor would
#                 refuse as a path line); a glob of --settings' never
#                 line, compared lower-cased, * and ? within one part, matching
#                 the path or a directory above it; and a path neither listed
#                 in the brief's first "Paths:" line nor one of its own files
#                 (docs/working/{research,plan,checkpoint,handoff,
#                 test-strategy}-STEM.md, an added docs/reviews/STEM.md or
#                 NAME-STEM.md; the allowlist takes these only when the
#                 whole path is lower case, though the floor passes any
#                 case). "Paths: PATH ..." lists paths
#                 pathform allows, with single spaces, each once, compared
#                 exactly (a trailing / makes a directory, matched at a part
#                 boundary; unlike a never glob, an entry without one matches
#                 that file alone); "Paths: none" or no line lists none; any
#                 other line is malformed, and only own files land.
#
# Acts on $PWD's git repo, like dev-cycle.sh, and needs its default branch
# found by name (origin/HEAD, main or master). Writes nothing but --check's
# merge objects (merge-tree writes the merged trees and blobs into the object
# store) and its own temporary directory, removed at exit.
# Output passes through the lib's scrub (but for the start-up errors about
# perl and the lib); printed repo text is data.
# Exit: 0 every line printed (or help), and for --check every verdict line ok;
# 2 any --check verdict line or the state gate not ok. A --check can also stop
# part way, after the lines of the briefs before, with 1 (need_root) or a
# failed command's own status: a caller reads any exit but 0 as nothing
# decided. 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, a
# failed mktemp (--check; no line printed), or no default branch found by name.

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
# --check refuses planted state before any git call reads an object (resolve_main
# does); gate_start runs the rest of its startup.
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
resolve_main || true
main_by_name || { echo "build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none" >&2; exit 1; }
# The reader lists both import walks take, from main's settings (the lib's
# caller contract item 9), before any walk; --settings prints its line. Not
# read_settings below: without this call the walks model no host reader.
# gate_start calls it once main's objects are checked.
[[ "$MODE" == check ]] || reader_settings

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
# list_entries LINE KEY WORD FORM: the list-line grammar Self-merge never: and
# a brief's Paths: share. LINE is exactly "KEY: none" or "KEY: E ..." with
# single spaces (WORD names E in the reason), and each E, a trailing / dropped,
# passes FORM (globform or pathform) and is listed once. Sets LIST (the
# entries as written, a trailing / kept; empty for none) or LIST_WHY, and
# LIST_BAD to form (the line's shape) or entry (an entry), or empty.
LIST=(); LIST_WHY=""; LIST_BAD=""
list_entries() {
  local v="${1#"$2": }" e i=0
  local -A seen=()
  LIST=(); LIST_WHY=""; LIST_BAD=""
  # Split on single spaces only; FORM then refuses any other blank in an entry.
  if [[ "$1" != "$2: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then LIST_WHY="is not exactly \"$2: ${3^^} ...\" with single spaces"; LIST_BAD=form; return 0; fi
  [[ "$v" != none ]] || return 0
  IFS=' ' read -ra LIST <<<"$v"  # not a bare $v: the shell would expand * and ? against files
  for e in "${LIST[@]}"; do
    i=$((i + 1))
    if ! "$4" "${e%/}"; then LIST_WHY="lists entry $i, which is not an allowed $3 form"; break; fi
    if [[ -n "${seen[${e%/}]-}" ]]; then LIST_WHY="lists entry $i twice"; break; fi
    seen[${e%/}]=1
  done
  [[ -z "$LIST_WHY" ]] || { LIST=(); LIST_BAD=entry; }
}
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
  local f=docs/dev-cycle.md where l k c l1 l2 nx t v why never_ok=""
  local -A cnt=() first=() second=() next=() text=()
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
      t="${text[never]}"; v="${t#Self-merge never: }"
      list_entries "$t" "Self-merge never" glob globform; why="$LIST_WHY"
      # The form reason comes first, then the next line, then the entries.
      if [[ "$LIST_BAD" != form && "${next[never]}" != 1 ]]; then why="is followed by a non-blank line outside a fence (it may continue the list)"; fi
      if [[ -n "$why" ]]; then NEVER_LINE="never malformed: line ${first[never]} $why"
      elif [[ ${#LIST[@]} -eq 0 ]]; then never_ok=1; NEVER_LINE="never none: line ${first[never]} $where lists none"
      else never_ok=1; NEVER=("${LIST[@]}"); NEVER_LINE="never $v set: line ${first[never]} $where"; fi
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
# --status for one brief, as values (rows 496, 512): STATUS[line] is the line
# --status prints, and for an "ok" line STATUS holds its fields by name
# (state, policy, branch, loop, sha, date, dispatched, reason) and ahead, the
# branch's commit count past main. brief_fields' BRIEF is the brief as read
# here (check_line takes Paths: from it, so no second read). Call it in the
# caller's own shell.
declare -A STATUS=()
status_fields() {
  local a="$1" out st br sha ahead date loop kind reason="" pol=review disp=0
  STATUS=()
  open_shared
  out="$(check_brief "$a")"
  [[ "$out" == "ok "* ]] || { STATUS[line]="$out"; return; }
  read -r _ _ st _ <<<"$out"
  if [[ "$st" == new ]]; then
    STATUS=([line]="ok $a new review - absent - - 0" [state]=new [policy]=review [branch]=- [loop]=absent [sha]=- [ahead]=0 [date]=- [dispatched]=0 [reason]="")
    return
  fi
  brief_fields "$a" || { STATUS[line]="skip $a: the brief is not read"; return; }
  if [[ -z "${BRIEF[branch]+set}" ]]; then STATUS[line]="skip $a: no Branch: line on the default branch"; return; fi
  if [[ ! "${BRIEF[branch]}" =~ ^Branch:\ ([^\ ]+)$ ]]; then STATUS[line]="skip $a: its first Branch: line is not exactly \"Branch: NAME\""; return; fi
  br="${BASH_REMATCH[1]}"
  if [[ -n "${BRIEF[dispatched]+set}" ]]; then
    [[ "${BRIEF[dispatched]}" =~ ^Dispatched:\ (0|[123456789][0123456789]?)$ ]] \
      || { STATUS[line]="skip $a: its first Dispatched: line is not exactly \"Dispatched: N\" with N from 0 to 99"; return; }
    disp="${BASH_REMATCH[1]}"
  fi
  [[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge
  if [[ "$st" == open && "$OPEN_SHARED" == error ]]; then STATUS[line]="skip $a: the open briefs on the default branch could not be listed"; return; fi
  if [[ "$st" == open && "$OPEN_SHARED" == *$'\n'"$(lower "$br")"$'\n'* ]]; then
    STATUS[line]="skip $a: another open brief on the default branch names the same branch (compared ignoring case)"; return
  fi
  out="$(check_branch "$br")"
  sha=- ahead=0 date=- loop=absent
  case "$out" in
    "absent "*) ;;
    "ok "*) read -r _ _ sha ahead date <<<"$out"; loop=working ;;
    *) STATUS[line]="skip $a: Branch: ${out#*: }"; return ;;
  esac
  if [[ "$ahead" -gt 0 ]]; then
    kind="$(marker_kind "$sha")"
    case "$kind" in
      bad\ *) STATUS[line]="skip $a: the tip of $br starts \"handoff:\" but is not a marker: ${kind#bad }"; return ;;
      stopped\ *) loop=stopped; reason="${kind#stopped }" ;;
      *) loop="$kind" ;;
    esac
  fi
  STATUS=([line]="ok $a $st $pol $br $loop $sha $date $disp${reason:+ $reason}" [state]="$st" [policy]="$pol" [branch]="$br"
    [loop]="$loop" [sha]="$sha" [ahead]="$ahead" [date]="$date" [dispatched]="$disp" [reason]="$reason")
}
status_line() { status_fields "$1"; echo "${STATUS[line]}"; }

# merge_result's own repository, set up once per run in GATE_TMP (the caller's
# mktemp -d, removed at exit): a git dir with no config but the repo's object
# format, no modules/, info/ or shallow, and an empty directory to run in, so
# merge-tree reads none of the repo's config (a submodule repository under
# .git/modules is never opened), no checkout's .gitattributes (git 2.39 reads
# one from the current directory even under --work-tree), and only the repo's
# object store (GIT_OBJECT_DIRECTORY, where it also writes). GATE_ENV unsets the
# repo-local variables (GIT_COMMON_DIR and the like) that would point it back.
GATE_TMP=""; GATE_ENV=()
# callervar NAME: a repo-local variable (git rev-parse --local-env-vars) the
# gate keeps: the caller's config pairs, which harden extends and trusts
# (GIT_CONFIG_PARAMETERS, GIT_CONFIG_COUNT), and GIT_NO_REPLACE_OBJECTS, which
# this script sets. GIT_CONFIG is not one: git config then reads that one file
# instead of every scope (gate_repo unsets it; checkout_gate refuses it).
callervar() { [[ "$1" == GIT_CONFIG_PARAMETERS || "$1" == GIT_CONFIG_COUNT || "$1" == GIT_NO_REPLACE_OBJECTS ]]; }
gate_repo() {
  local fmt v
  GATE_ENV=(env)
  for v in $(git rev-parse --local-env-vars); do callervar "$v" || GATE_ENV+=(-u "$v"); done
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
# store_check REV...: every object a decision reads from REV hashes to its id
# (rows 492, 503). git checks no hash when it reads an object, so a same-uid
# writer that rewrites an object file behind its id (loose or packed) would
# change what the gate reads, and only fsck would notice. Each REV (a commit
# or a tree), its root tree, and every tree and blob below it (a gitlink names
# another repository's commit) are read in one cat-file --batch and re-hashed
# by one perl, for sha1 or sha256. Returns 1 on a mismatch, a missing object
# or a failed read. A writer racing between this check and a later read is
# not caught (R8's family, Q-103).
store_check() {
  local r alg
  case "$(git rev-parse --show-object-format)" in sha1) alg=1 ;; sha256) alg=256 ;; *) return 1 ;; esac
  # One object name per line, each once.
  { for r in "$@"; do
      printf '%s\n' "$r" "$r^{tree}"
      git ls-tree -r -t --full-tree --format='%(objecttype) %(objectname)' "$r" | awk '$1 != "commit" { print $2 }' || exit 1
    done; } | awk '!seen[$0]++' | git cat-file --batch \
    | env LC_ALL=C ALG="$alg" perl -e 'use Digest::SHA; binmode STDIN; my $n = 0;
      while (defined(my $h = <STDIN>)) {
        my ($id, $t, $s) = $h =~ /^([0-9a-f]+) ([a-z]+) ([0-9]+)\n\z/ or exit 1;  # "NAME missing" too
        read(STDIN, my $b, $s) == $s && (getc(STDIN) // "") eq "\n" or exit 1;
        Digest::SHA->new($ENV{ALG})->add("$t $s\0", $b)->hexdigest eq $id or exit 1;
        $n++;
      }
      exit($n ? 0 : 1)'
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
# plus docs/working/briefs and docs/working/cycles, as files or anything under them) and the
# constraints doc (its user word) compare lower-cased, as a case-insensitive
# checkout reads Docs/Roadmap.md as the roadmap; so does a path below one of
# those names (docs/roadmap.md/x, which main may lack, would keep the cycle
# from writing the file: row 523). srules adds the S rules.
DENY=""
nrules() {
  local ob d="$7"
  DENY=""
  if ! pathform "$6"; then DENY="not an allowed path form (letters, digits and . _ - / only; no leading - or /; no empty, . or .. part; no part starting .git)"
  elif [[ ! "$2 $3" =~ ^(000000|100644|100755)\ (000000|100644|100755)$ ]]; then DENY="a symlink, gitlink or other non-file entry on one side (only modes 100644 and 100755 land)"
  elif [[ "$6" == "$1" ]]; then
    { [[ "$5" == M && "$2" == "$3" ]] && ob="$(own_blob "$1")" && [[ "$4" == "$ob" ]]; } \
      || DENY="this brief: only its first Status: line outside a fence may change, from open to done"
  else
    # $7 is lower-cased, so the case word cannot fire; instr and dot, tested
    # before cycle, match no cycle file, docs/dev-cycle.md or docs/constraints.md
    # today (T14 fails if one ever hides a covered file outside briefs/ and
    # cycles/, which the fallback below still denies; truthrule names this third consumer).
    truthrule "$7" || true
    case "$TRUTH_WHY" in
      cycle|settings) DENY="one of the dev cycle's own files" ;;
      user) DENY="the user's constraints doc, which every loop prompt carries" ;;
      *) [[ ! "$7" =~ ^docs/working/(briefs|cycles)(/|$) ]] || DENY="one of the dev cycle's own files" ;;
    esac
    while [[ -z "$DENY" && "$d" == */* ]]; do
      d="${d%/*}"; truthrule "$d" || true
      [[ ! "$TRUTH_WHY" =~ ^(cycle|settings|user)$ ]] || DENY="a path below the name of one of the dev cycle's own files or the constraints doc"
    done
  fi
}
# The brief's Paths: line (plan D5's allowlist), from BRIEF[paths]: as
# list_entries reads "Paths: PATH ...", each entry pathform's, a trailing /
# making it a directory; "Paths: none", or no line, lists none. Sets PATHS
# or, for a malformed line, PATHS_WHY (which lands only the brief's own files).
PATHS=(); PATHS_WHY=""
read_paths() {
  PATHS=(); PATHS_WHY=""
  [[ -n "${BRIEF[paths]+set}" ]] || return 0
  list_entries "${BRIEF[paths]}" Paths path pathform
  PATHS=("${LIST[@]}"); PATHS_WHY="$LIST_WHY"
}
# NEVER's globs as regexes for a lower-cased path (a denylist, so case folds):
# * and ? match within one part, and a glob matches the path or any directory
# above it (a trailing / changes nothing). Set once, after read_settings.
NEVER_RES=()
never_res() {
  local g c i re
  NEVER_RES=()
  for g in "${NEVER[@]}"; do
    g="$(lower "${g%/}")"; re=""
    for ((i = 0; i < ${#g}; i++)); do
      c="${g:i:1}"
      case "$c" in '*') re+='[^/]*' ;; '?') re+='[^/]' ;; .) re+='\.' ;; *) re+="$c" ;; esac
    done
    NEVER_RES+=("^$re(/|\$)")
  done
}
# The S rules (plan D5; a self-merge brief only) for a changed path the N rules
# passed that is not the brief's own file (the N rules alone judge that one):
# $1 the brief's full stem, $2 the path, $3 its lower-cased spelling, $4
# diff-tree's status letter, $5 the checkout's refusal, if any. Sets DENY, first match winning: the floor (only
# when $5 is empty: it walks the checkout), a Self-merge never: glob, then the
# allowlist (Paths:, or ownfile). The allowlist widens nothing by case: Paths:
# entries compare exactly, and an own file counts only when the whole path is
# lower case (ownfile folds nothing, and its review pattern would take any
# letter in NAME, so this test is what keeps NAME lower case).
srules() {
  local i e
  DENY=""
  if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then DENY="$FLOOR_WHY"; return 0; fi
  for i in "${!NEVER_RES[@]}"; do
    [[ ! "$3" =~ ${NEVER_RES[$i]} ]] || { DENY="matched by ${NEVER[$i]} in the Self-merge never: line of docs/dev-cycle.md"; return 0; }
  done
  [[ "$2" != "$3" ]] || ! ownfile "$2" "$1" "$4" || return 0
  [[ -z "$PATHS_WHY" ]] || { DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"; return 0; }
  for e in "${PATHS[@]}"; do
    [[ "$2" != "$e" && ( "$e" != */ || "$2" != "$e"* ) ]] || return 0
  done
  DENY="neither listed in the brief's Paths: line nor one of its own files"
}
# The checkout --check runs from, which a self-merge brief's floor walk (srules)
# reads: the parts of the gate caller contract's items 2 and 3 (the lib's
# header) a checkout can break. Item 2's fsmonitor and replace refs are harden's
# and the state gate's, and its ls-files stderr rule is the walk's own. Sets
# CHECKOUT_WHY to why the checkout fails, or empties it; returns 1 on a
# failure. check_line calls it for each self-merge brief once the merge and
# its changed paths are read, before the N rules and the floor walk run per
# path, so it is final before that walk. Item 3 is
# checked by its effect, not by predicting it with check-attr: every regular
# file main stores must hash, unfiltered, to main's blob, so no conversion (a
# filter, working-tree-encoding, ident or eol attribute from any attributes
# source, the user's global ones included, which harden hides from the gate's
# own git) changed what a session reads there. Untracked and ignored files
# are allowed: the walk reads them as they are. A nested repository's files
# are not walk starts (rows 366, 373), so an untracked one, or a gitlink
# checked out with any file, fails. Needs GATE_TMP.
CHECKOUT_WHY=""
checkout_gate() {
  # The C locale: under UTF-8 a regex . does not match an invalid byte, so a
  # record with such a name would fail to parse (and be refused as unreadable).
  local -x LC_ALL=C  # exported: tr, awk and git run under it too
  local v x rc r n p ps=() ids=() re=$'^([01234567]{6}) [a-z]+ ([0123456789abcdef]+)\t(.*)$'
  CHECKOUT_WHY=""
  for v in $(git rev-parse --local-env-vars); do
    # GIT_PREFIX only names a subdirectory for an alias; the script cds to the top level.
    [[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v" \
      || { CHECKOUT_WHY="$v is set, so git can read another work tree, index, object store or config file"; return 1; }
  done
  x="$(git rev-parse --verify -q 'HEAD^{commit}')" || x="unreadable"
  [[ "$x" == "$MAIN_SHA" ]] || { CHECKOUT_WHY="the checkout's HEAD is $x, not the default branch's commit $MAIN_SHA"; return 1; }
  for v in "core.symlinks false: a symlink is checked out as a file holding its text" \
    "core.ignoreCase true: a case-insensitive checkout" "core.sparseCheckout true: a sparse checkout"; do
    # rc above 1 is a defensive branch: git refuses a bad boolean before any command runs.
    rc=0; x="$(git config --type=bool --get "${v%% *}" 2>/dev/null)" || rc=$?
    r="${v#* }"
    [[ "$rc" -le 1 ]] || { CHECKOUT_WHY="${v%% *} could not be read"; return 1; }
    [[ "$x" != "${r%%:*}" ]] || { CHECKOUT_WHY="${v%% *} is $r"; return 1; }
  done
  # ls-files -v tags each entry: H is plain; S is skip-worktree, lower case is
  # assume-unchanged (git status skips a change under either), M is unmerged.
  # perl -0 reads NUL-ended records, so a name holding a newline is one entry.
  n="$(git ls-files -v -z | LC_ALL=C perl -0ne '$n++ unless /^H /; END { print $n + 0 }')" \
    || { CHECKOUT_WHY="the checkout's index could not be listed"; return 1; }
  [[ "$n" == 0 ]] || { CHECKOUT_WHY="the checkout's index marks entries skip-worktree, assume-unchanged or unmerged"; return 1; }
  # To a file: bash would warn on stderr about the NULs a $(...) drops.
  git status --porcelain=v1 -z --untracked-files=no --ignore-submodules=none > "$GATE_TMP/status" 2>"$GATE_TMP/err" && [[ ! -s "$GATE_TMP/err" ]] \
    || { CHECKOUT_WHY="git status failed or warned in the checkout"; return 1; }
  [[ ! -s "$GATE_TMP/status" ]] || { CHECKOUT_WHY="the checkout's index or tracked files differ from that commit (git status)"; return 1; }
  # Without --exclude-standard every untracked file is listed, ignored ones too,
  # and a nested repository as its directory with a trailing / (no file name
  # holds a /). Listed to a file first, so the listing's own status is
  # checked apart from the count (a pipe's status mixes the two).
  git ls-files -z --others > "$GATE_TMP/others" || { CHECKOUT_WHY="the checkout's untracked files could not be listed"; return 1; }
  x="$(tr '\0' '\n' < "$GATE_TMP/others" | awk '/\/$/ { n++ } END { print n + 0 }')" || x=x
  [[ "$x" == 0 ]] || { CHECKOUT_WHY="the checkout holds an untracked nested repository, whose instruction files the walk does not read"; return 1; }
  git ls-tree -r -z --full-tree "$MAIN_SHA" > "$GATE_TMP/tree" || { CHECKOUT_WHY="the default branch's tree could not be listed"; return 1; }
  while IFS= read -r -d '' r; do
    [[ "$r" =~ $re ]] || { CHECKOUT_WHY="the default branch's tree could not be read"; return 1; }
    p="${BASH_REMATCH[3]}"
    case "${BASH_REMATCH[1]}" in
      100644|100755) ;;
      # git status compares a link's text to its blob unconverted (core.symlinks is true here).
      120000) continue ;;
      160000)
        if [[ -L "$p" ]] || { [[ -e "$p" ]] && ! x="$(ls -A -- "$p" 2>/dev/null)"; }; then
          CHECKOUT_WHY="a gitlink's path in the checkout is a symlink or cannot be listed"; return 1
        fi
        [[ ! -e "$p" || -z "$x" ]] || { CHECKOUT_WHY="a gitlink is checked out with files, whose instruction files the walk does not read"; return 1; }
        continue ;;
      *) CHECKOUT_WHY="the default branch's tree could not be read"; return 1 ;;
    esac
    # hash-object --stdin-paths reads a line: a newline splits a name, a
    # leading " is unquoted and a trailing CR dropped, so another file is hashed.
    [[ "$p" != *$'\n'* && "$p" != \"* && "$p" != *$'\r' ]] \
      || { CHECKOUT_WHY="a file on the default branch has a name the byte comparison cannot read (a newline, a leading quote or a trailing CR)"; return 1; }
    ids+=("${BASH_REMATCH[2]}"); ps+=("$p")
  done < "$GATE_TMP/tree"
  [[ ${#ps[@]} -gt 0 ]] || return 0
  # --stdin-paths: one hash-object for every file (one per path cost a process each).
  x="$(printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths 2>/dev/null)" \
    || { CHECKOUT_WHY="the checkout's files could not be hashed"; return 1; }
  [[ "$x" == "$(printf '%s\n' "${ids[@]}")" ]] \
    || { CHECKOUT_WHY="a file's checked-out bytes are not the default branch's blob (a filter, working-tree-encoding, ident or eol conversion)"; return 1; }
}
# The gate's startup once the top level has run state_gate, resolve_main and
# main_by_name, in this order, each refusal a "refuse state" line and exit 2
# before any setting or brief is read: the default branch unambiguous
# (default_gate); the gate's merge repository (GATE_TMP, removed at exit);
# main's commit and tree re-hashed (store_check); then the reader lists both
# walks take, --settings' values, the never globs and the open briefs (once,
# in this shell). The repository rule: main's files and refs, the branch tips
# and the checkout are read in the real repository; the merge computations
# (merge-base, merge-tree, diff-tree, the blob checks) run through gate_git.
gate_start() {
  default_gate || exit 2
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
  gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
  store_check "$MAIN_SHA" || { echo "refuse state objects: the default branch's commit or an object of its tree does not hash to its id, or could not be read"; exit 2; }
  reader_settings; read_settings; never_res; open_shared
}
# --check for one brief: "ok BRIEF TIP TREE" or "refuse BRIEF: K of N changed
# paths refused in the merge of TIP (tree TREE)", then a "path BRIEF S PATH" or
# "deny BRIEF S PATH: WHY" line per path the merge changes against main
# (diff-tree's status letter S, in its order; PATH is "?" unless every
# character is one pathform allows); or one skip or refuse line (from
# status_line, then the gate's own reasons). It runs in the caller's shell, so
# an exit (need_root's) ends the run, and set -e applies to its own lines but
# not inside a helper called in a condition (floor and its walk, brief_fields,
# checkout_gate, nul_list) or in $(...), which refuse by their own guards.
# Nothing but its locals and the walk caches it resets may carry from one
# brief to the next: each helper empties its own globals before use (DENY,
# PATHS and PATHS_WHY, LIST, LIST_WHY and LIST_BAD, STATUS, BRIEF, CHECKOUT_WHY, FLOOR_WHY,
# TRUTH_WHY).
check_line() {
  # Contract item 1 (the floor's walk); exported, so its children run under it too.
  local -x LC_ALL=C
  local a="$1" out st pol br sha tree meta p shown co stem rc=0 i nd=0 rows=() oms=() nms=() nos=() ss=() ps=() lps=() ids=()
  import_reset  # caller contract item 4: no walk cache outlives a decision
  status_fields "$a"
  [[ "${STATUS[line]}" == "ok "* ]] || { echo "${STATUS[line]}"; return; }
  st="${STATUS[state]}"; pol="${STATUS[policy]}"; br="${STATUS[branch]}"; sha="${STATUS[sha]}"
  if [[ "$st" != open ]]; then echo "refuse $a: the brief is $st on the default branch; only an open brief merges"; return; fi
  if [[ "${STATUS[loop]}" == absent ]]; then echo "refuse $a: its branch $br does not exist"; return; fi
  if [[ "${STATUS[ahead]}" -eq 0 ]]; then echo "refuse $a: its branch $br has no commit the default branch lacks"; return; fi
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
  # Every record read whole: two NUL-ended fields each (bytes after the last
  # NUL are not counted; git's own output never ends that way).
  if [[ "$(tr -cd '\000' < "$GATE_TMP/diff" | wc -c)" -ne $((2 * ${#ps[@]})) ]]; then echo "refuse $a: the paths the merge of $br changes could not be read"; return; fi
  # merge-tree passes a side's unchanged blob by id without reading it, so a
  # blob the store lacks would land unseen: every regular file the merge adds
  # or changes must name a blob present in the store (a missing subtree already
  # failed diff-tree).
  if [[ ${#ids[@]} -gt 0 ]] && { ! out="$(printf '%s\n' "${ids[@]}" | gate_git cat-file --batch-check='%(objecttype)')" \
    || [[ "$(printf '%s\n' "$out" | grep -cx blob)" -ne ${#ids[@]} ]]; }; then
    echo "refuse $a: the merge of $br names a blob the object store lacks"; return
  fi
  # The tip's objects and the merge's, re-hashed (main's were, in gate_start).
  if ! store_check "$sha" "$tree"; then echo "refuse $a: an object of $br's tip or of its merge does not hash to its id, or could not be read"; return; fi
  # A self-merge brief's checkout (contract items 2 and 3), checked once the
  # merge's paths are read and before the S rules (srules), whose floor walk
  # runs per path below only when co is empty (never over a checkout refused
  # here); its refusal replaces the verdict line only, so the path and deny lines
  # still print (a loop's advisory run from its own branch learns them). Run
  # per brief, so each decision sees the checkout as it is: about 0.3 s here,
  # times the self-merge briefs passed to one --check.
  co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"; fi
  # The S rules' inputs: the brief as status_fields read it from main's commit.
  stem="${a##*/}"; stem="${stem%.md}"
  [[ "$pol" != self-merge ]] || read_paths
  if [[ ${#ps[@]} -eq 0 ]]; then echo "${co:-ok $a $sha $tree}"; return; fi
  # One lower-casing pass for every path (a tr per path cost 1 to 2.5 ms each).
  if ! nul_list lps lower_all "${ps[@]}" || [[ ${#lps[@]} -ne ${#ps[@]} ]]; then echo "refuse $a: the paths the merge of $br changes could not be lower-cased"; return; fi
  for i in "${!ps[@]}"; do
    p="${ps[$i]}"; shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"
    nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"
    [[ -n "$DENY" || "$pol" != self-merge || "$p" == "$a" ]] || srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"
    if [[ -n "$DENY" ]]; then nd=$((nd + 1)); rows+=("deny $a ${ss[$i]} $shown: $DENY"); else rows+=("path $a ${ss[$i]} $shown"); fi
  done
  if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi
  printf '%s\n' "${rows[@]}"
}

case "$MODE" in
  status)
    read_settings
    for a in "${ARGS[@]}"; do status_line "$a"; done
    ;;
  settings)
    read_settings
    printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE" "$READERS_LINE"
    ;;
  check)
    gate_start
    fails=0
    for a in "${ARGS[@]}"; do
      # In this shell, not $(...): the floor's need_root exit ends the run, and
      # check_line's import_reset is what keeps one brief's walk from the next.
      check_line "$a" > "$GATE_TMP/line"; cat "$GATE_TMP/line"
      [[ "$(head -c 3 "$GATE_TMP/line")" == "ok " ]] || fails=1
    done
    [[ "$fails" -eq 0 ]] || exit 2
    ;;
esac
