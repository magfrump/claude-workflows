#!/bin/bash
# The dev cycle's reader, used by scripts/dev-cycle.sh and kept apart so
# scripts/build-loop.sh can share it: the output scrub, the plain-file
# and path-form rules, the cycle's own file names, the Markdown shapes the
# readers refuse (FENCE_AWK), the brief, branch and answer checks, the
# instruction-file import walks, the read-as-truth rule and self-merge floor
# they serve, and the default branch.
#
# Sourced, never run: it only defines functions and variables. Each script
# sources it from its own directory (never from the repo it acts on), so a copy
# of scripts/ with its lib/ is self-contained. A change here must pass
# test/scripts/dev-cycle.bats and build-loop.sh's suites (build-loop-*.bats).
# The caller sets -euo pipefail (check_answer, brief_fields and the import
# walks also set pipefail for themselves), cds to the repo root and sets ROOT_REAL (that root,
# symlinks resolved) before calling any file check. inrepo, dirok, skipped,
# check_brief, isimported and the import walks (truthwalk, and floor for a
# path its earlier rules pass, through them; a call the walk's caches answer
# checks only that ROOT_REAL is set) exit 1 (need_root) unless
# ROOT_REAL is set, is the current directory and is a repository's top level;
# while ROOT_REAL is unset, rawfile, plaindir and blocker read nothing as plain.
# imported_names and main_imports return 1 when the walk fails: call them under
# if or ||. Call the exiting checks in the caller's shell, not inside $(...) or
# `local x="$(...)"`, where an exit ends only the subshell. skipped records each
# blocked input in SKIPPED and SKIP_AT. The caller runs resolve_main once per
# process (a second call re-reads main); check_brief, check_branch and
# check_answer skip every argument unless it returned 0 with main found by name
# (main_entry and brief_fields answer error). check_brief, check_branch and
# check_answer answer with one printed line per argument that can echo repo
# text: print it through scrub, read it as `out="$(check_brief ...)"` under
# set -e (which stops when need_root exits; `if out=...` and `< <(...)` would
# carry on), and treat any line that is not a positive answer as a refusal.
# A caller that also reads ANSWER_HEADING (check_answer's side value: the
# entry's heading) runs check_answer in its own shell, its output to a file,
# since a $(...) would drop the value; check_answer reaches no need_root (it
# reads only git objects), so nothing exits there, and set -e need not hold
# (build-loop.sh calls it inside a condition).
# Every script that calls scrub_reexec shares its DEV_CYCLE_SCRUBBED marker.
# Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields
# read the default branch's commit, never the working tree (check_brief also
# refuses a brief path that is not plain in the working tree, which the cycle
# writes). main_imports walks main's commit first, listing and checking the
# working tree as it goes, and then reads the working tree's own files (the
# checkout's start files and imported files main lacks, which can only add
# imports or fail it; it needs resolve_main to have found main by name);
# imported_names reads the working tree at ROOT_REAL. Neither walk reads
# anything outside the checkout and main's commit (brief
# 2026-11-03-import-walk-plain). reader_settings reads docs/dev-cycle.md from
# the default branch's commit, for build-loop.sh --settings alone.
#
# The gate caller contract, for floor and main_imports (the one statement of
# it; plan step 5's U2b bullet and known issue A5 point here; override row 459):
#  1. Run as above, with main found by name, under LC_ALL=C (under a UTF-8
#     locale a non-UTF-8 name on main fails the walk).
#  2. Walk a clean worktree at MAIN_SHA, final before the walk (the walk reads
#     main's blob for every path main stores, and the checkout only where main
#     lacks a path), with no GIT_DIR, GIT_WORK_TREE, GIT_INDEX_FILE,
#     GIT_OBJECT_DIRECTORY or GIT_COMMON_DIR pointing git elsewhere. The walk
#     checks none of this: a failed listing fails it, and git's warnings (a
#     directory it cannot read, whose untracked starts are skipped) do not;
#     build-loop.sh --check checks the rest for each self-merge brief before
#     the walk (checkout_gate; its check_line runs the walk under item 1's
#     LC_ALL=C).
#  3. (Dropped by brief 2026-11-01-relax-gate-git-state: a checkout's
#     conversions, core.symlinks, sparse or case-insensitive checkout and
#     nested repositories are allowed, as the walk reads main's blob for
#     every path main stores.)
#  4. Call import_reset before each gate decision and after any checkout
#     change (rows 372, 439): neither walk's cache key holds the checkout
#     (both hold ROOT_REAL and HOME, so a change of either needs no reset).
#  5. Ask floor about each changed path, in this shell. A caller that reads
#     a path from main by name asks floor before main_entry, and refuses the
#     whole branch on any main_entry word but blob or absent (rows 308, 324);
#     build-loop.sh reads diff-tree -r of main and the merge instead, where a
#     symlink or gitlink above a path is a changed entry of its own. Floor
#     item 5 (symlinks, gitlinks) and the brief's own Status change are the
#     caller's rules; build-loop.sh's N rules apply them, and pathform, for
#     a self-merge (only there do its S rules run floor), and floor runs only
#     on a path they pass, so a path pathform refuses (.github/x.yml) is
#     denied as a path form and floor's dotfile reason serves the dot paths
#     pathform accepts (.envrc). A review or --approved merge, which the
#     owner reviews, lands symlinks, gitlinks and parts starting .git other
#     than .git itself (.github/, .gitignore).
#  6. Read a walk only through isimported or truthwalk (or, inside the lib,
#     walk_has once that walk succeeded): IMPORTED_MAIN=error reads as "not
#     imported" to a raw membership test (row 419).
#  7. (Dropped by brief 2026-11-03-import-walk-plain, with main_checkout.)
#  8. Pass truthrule, truthwalk and isstart a lower-cased path (floor lowers
#     first unless its caller passes the lowered path, and check_fix and the
#     walks lower first; truthrule refuses an upper-case letter as case,
#     truthwalk as imported). ownfile folds no case: floor passes it the
#     lowered path, build-loop.sh's srules only an all-lower-case one.
#  9. (Dropped by brief 2026-11-03-import-walk-plain: the walks take no reader
#     lists, and reader_settings only words --settings' readers line.)

# The one scrub for everything printed, stdout and stderr: drops C0 controls but
# TAB and LF, DEL, C1 controls (U+0080-009F), bidi controls (U+200E/F,
# U+202A-202E, U+2066-2069), the line and paragraph separators U+2028/2029 (some
# readers split lines on them) and tag characters (U+E0000-E007F), and cuts lines
# longer than 4096 bytes as the scrub receives them (before controls are removed). Perl is pinned to bytes: PERL_UNICODE, PERL5OPT and PERLIO are
# removed (each can turn on UTF-8 decoding and switch the byte patterns off),
# -C0 is set, and both handles are binmoded. C0 goes first; after each deletion
# the search resumes 3 bytes before it (no sequence is longer than 4 bytes), so a
# control byte inside a sequence or a nested sequence cannot reassemble one;
# each search restarts near the last deletion, and the line cut bounds the
# scrub's work per line (the awk readers upstream still read a long line whole).
# Not covered: lone bytes 0x80-0x9F and overlong encodings (invalid UTF-8, which
# a UTF-8 terminal does not decode), U+061C, and invisible format characters such
# as zero-width ones, U+00AD, U+206A-206F and U+FFF9-FFFB (none can start a line).
scrub() {
  # shellcheck disable=SC2016  # perl code, not shell: $_ must stay literal
  env -u PERL_UNICODE -u PERL5OPT -u PERLIO LC_ALL=C perl -C0 -ne '
    BEGIN { $| = 1; binmode STDIN; binmode STDOUT }
    my $nl = s/\n\z//;
    $_ = substr($_, 0, 4096) . " [line cut at 4096 bytes]" if length($_) > 4096;
    $_ .= "\n" if $nl;
    tr/\000-\010\013-\037\177//d;
    my $i = 0;
    while (1) {
      pos($_) = $i;
      last unless /\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xA8-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]/g;
      my $s = $-[0];
      substr($_, $s, $+[0] - $s) = "";
      $i = $s > 3 ? $s - 3 : 0;
    }
    print'
}
# Run the body as a child whose stdout and stderr each pass through scrub as
# members of one pipeline, so the shell waits for both filters before exiting:
# a redirected digest is complete when the script returns. Each stream keeps its
# own order; merged with 2>&1 the two may interleave differently. fd 3 takes the
# outer pipe (to the outer scrub), then inside the group the child's stderr takes
# the inner pipe and its stdout goes to fd 3. Exit status: the body's (pipefail;
# scrub itself does not fail). DEV_CYCLE_SCRUBBED marks the child; a caller that
# sets it skips the scrub (an environment choice, not something repo text can do).
# scrub_reexec takes the script to re-run and its arguments, and returns only
# in the child (or when the caller already set DEV_CYCLE_SCRUBBED).
scrub_reexec() {
  [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]] || return 0
  local self="$1"; shift
  { DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub
  exit "${PIPESTATUS[0]}"
}
# A regular file reached without any symlink: its real path must be exactly the
# repo root plus the path as given, so a committed symlink (to the file or to a
# parent directory, pointing outside the checkout or into .git) is never read.
# With no ROOT_REAL nothing is plain (fail closed); need_root makes the callers
# below stop instead, outside the command substitution where blocker runs (an
# exit there would end only the subshell). The checks read paths relative to
# the current directory, so need_root also stops them when ROOT_REAL is not the
# current directory (a stale root compares one tree's files with another) or
# not a repository's top level (from a subdirectory, docs/x names sub/docs/x).
need_root() {
  [[ -n "${ROOT_REAL:-}" ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not set; the caller sets it before any file check" >&2; exit 1; }
  [[ "$ROOT_REAL" == "$(pwd -P)" ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not the current directory; the caller cds to the root it names" >&2; exit 1; }
  [[ -e .git ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not a repository's top level; the caller cds there" >&2; exit 1; }
}
rawfile() { local r; [[ -n "${ROOT_REAL:-}" && -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
# A directory dev-cycle.sh's digest globs in must be plain too, or the glob would list
# names from wherever a symlinked directory points.
plaindir() { local r; [[ -n "${ROOT_REAL:-}" && -d "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
# One rule decides whether an input is skipped, for files and directories alike:
# walking the path top down, the first part that exists but is not plain (a
# symlink, or not a regular file / directory) blocks it. Nothing below a blocking
# part is probed, not even whether a file exists there; the blocking part is what
# the digest's section 8 lists and what the inline note names. A newline in a name becomes a
# space before it is ever printed. An absent path is not skipped, just absent.
SKIPPED=(); SKIP_AT=""
blocker() {  # $1 path, $2 "file" or "dir"; prints the blocking part, or nothing
  local p="" c rest="$1"
  while [[ "$rest" == */* ]]; do
    c="${rest%%/*}"; rest="${rest#*/}"; p="${p:+$p/}$c"
    [[ -e "$p" || -L "$p" ]] || return 0
    plaindir "$p" || { printf '%s/' "$p"; return 0; }
  done
  [[ -e "$1" || -L "$1" ]] || return 0
  if [[ "$2" == dir ]]; then plaindir "$1" || printf '%s/' "$1"
  else rawfile "$1" || printf '%s' "${1//$'\n'/ }"; fi
}
# A fixed-name input is read only when no part of its path blocks it; the walk
# runs first, so nothing is looked up through a non-plain parent. (Glob items
# use rawfile directly: their directory has already passed dirok.)
inrepo() { need_root; inrepo_here "$1"; }
# inrepo for a caller that has run need_root itself (a walk, per path); it has
# no need_root of its own.
inrepo_here() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }
# The same for a directory the digest globs in: the walk first, so nothing is
# looked up through a non-plain parent.
dirok() { need_root; [[ -z "$(blocker "$1" dir)" && -d "$1" ]]; }
skipped() { need_root; SKIP_AT="$(blocker "$1" "${2:-file}")"; [[ -n "$SKIP_AT" ]] || return 1; SKIPPED+=("$SKIP_AT"); }

# The path rule for repo text (commit messages, plans, settings rows, roadmap
# brief paths), so the skill runs it instead of re-deriving it in prose:
#  - form: only letters, digits, . _ - / (and * ? in a glob), not starting with
#    / or -, no empty, . or .. component, no component starting .git (any case);
#  - scope (reads): a tracked file, or a gitignored file under docs/working/ (the
#    cycle's own working files); never any other untracked or ignored file;
#  - plain: a regular file reached without any symlink (inrepo).
# Globs are matched by git (":(glob)"), never by a shell.
# Characters are listed one by one, not as ranges, so the check does not depend
# on the caller's locale (a range like A-Z can take in other letters, and a
# Turkish locale can fold .GIT differently); setting LC_ALL here instead printed
# a setlocale warning per call when the caller's locale was not installed.
NAMECHARS='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/-'
pathform() {  # $1 path, $2 "glob" to allow * and ?
  local p="$1" rest c set="^[$NAMECHARS]+\$"
  [[ "${2:-}" == glob ]] && set="^[*?$NAMECHARS]+\$"  # * ? first: - must stay last
  [[ "$p" =~ $set && "$p" != /* && "$p" != -* ]] || return 1
  rest="$p/"
  while [[ -n "$rest" ]]; do
    c="${rest%%/*}"; rest="${rest#*/}"
    [[ -n "$c" && "$c" != "." && "$c" != ".." && "$c" != [.][gG][iI][tT]* ]] || return 1
  done
}
# The cycle's own bookkeeping files; in-cycle fixes to other files go through
# --check-fix. Anything else named in repo text (a roadmap line pointing at an
# instruction file, say) is refused, so it is never treated as a brief and
# written to. A done or dropped brief moves to briefs/closed/, so the open ones
# are all that the briefs/*.md glob lists once the move has landed.
DIGIT='[0123456789]'
SLUG='[abcdefghijklmnopqrstuvwxyz0123456789-]+'
isbrief() { [[ "$1" =~ ^docs/working/briefs/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; }
isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }
anybrief() { isbrief "$1" || isclosed "$1"; }
# A cycle record: one per day, updated in place by each iteration (dev-cycle.sh
# reads the window from these names; build-loop.sh's --main-log and
# --land-cycle read its Branch: lines).
isrecord() { [[ "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]]; }
# watching.md holds the cycle's watches (decision 040), and
# roadmap-from-questions.md the agent entries `questions.sh migrate` left for
# step 6 to fold into the roadmap and delete.
writable() {
  [[ "$1" =~ ^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log|watching|roadmap-from-questions)\.md$ ]] || isrecord "$1" || anybrief "$1"
}
# The machine grammar the readers trust (decision log row 81; brief
# 2026-11-02-relax-grammar-and-loop-prompt): column-0 key lines (Status:,
# answers, headings) outside column-0 code fences. Fences are read only in their plain form, so
# that every fence this reads is read the way CommonMark reads it: a line
# starting at column 0 with 3 or more ` or ~ opens one (a ` fence's info string
# holds no `), and only a column-0 line of the same character, at least as long
# and followed by nothing but spaces or tabs, closes it. Any other fence-like
# line (indented, after a list marker, or a column-0 line that neither opens
# nor, inside a fence, is plain content) is ambiguous, since a key line after it
# could be code to a renderer; so is, outside a fence, a line that opens an HTML
# comment it does not close (a key line could sit inside the comment; and
# questions.sh finds its <!-- index: markers anywhere in a line); and anywhere
# in the file, fenced or not, a carriage return inside a line (CommonMark ends
# a line there), a NUL byte (a caller reading the output through $(...) would
# lose it), or a byte-order mark on line 1: fence() records the first one's
# line number in `odd` (and why in `oddwhy`), and the caller refuses the whole
# file. A fence still open at the end is recorded in `fline` (its opening line)
# and refuses the file too.
# Everything else is text: an HTML block (a line starting with <, such as
# <details>), a complete one-line <!-- comment -->, a line that starts like a
# link reference definition ([1]: URL). A key line inside such a construct is
# read as a key line, though a renderer may hide it, and one between fence
# lines inside an HTML block is hidden, though a renderer shows it; either
# takes a contrived shape, which only matters against a hostile author, out of
# the threat model (docs/constraints.md S1).
# Accepted limit (decision log 69, kept by row 81): inline constructs that span
# lines (an open tag attribute, link title, code span, emphasis, or a
# processing instruction, CDATA section or declaration opened mid-line) are not
# modelled either.
# shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal
FENCE_AWK='
function run(l, ch,   n) { n = 0; while (substr(l, n + 1, 1) == ch) n++; return n }
function fenceish(l) { return l ~ /^[ \t]*(([-*+]|[0123456789]+[.)])[ \t]+)?(```|~~~)/ }
function opencomment(l,   n, p) {  # the last <!-- on the line has no --> after it
  n = split(l, p, /<!--/)  # one linear pass; <!-- cannot overlap itself
  return n > 1 && !index(p[n], "-->")
}
function refuse(why) { if (!odd) { odd = NR; oddwhy = why } }
function opens(l,   ch, n) {
  ch = substr(l, 1, 1)
  if (ch != "`" && ch != "~") return 0
  n = run(l, ch); if (n < 3) return 0
  if (ch == "`" && index(substr(l, n + 1), "`")) return 0
  fch = ch; flen = n; return 1
}
function closes(l,   n) { n = run(l, fch); return n >= flen && substr(l, n + 1) ~ /^[ \t]*$/ }
function fence(l) {  # 1: a fence line or fenced content (not text); 0: ordinary text
  if (odd) return 1   # the file is already refused: nothing after it is read
  if (index(l, "\r")) { refuse("cr"); return 1 }
  if (index(l, "\0")) { refuse("nul"); return 1 }  # $(...) drops NUL, so a printed line would not be the line read
  if (NR == 1 && substr(l, 1, 3) == "\357\273\277") { refuse("bom"); return 1 }
  if (infence) {
    if (closes(l)) infence = 0
    else if (fenceish(l) && substr(l, 1, 1) != "`" && substr(l, 1, 1) != "~") refuse("fence")
    return 1
  }
  if (opens(l)) { infence = 1; fline = NR; return 1 }
  if (fenceish(l)) { refuse("fence"); return 1 }
  if (opencomment(l)) { refuse("comment"); return 1 }
  return 0
}
'
oddwhy() {  # the reason fence() refused a file, for a skip line
  case "$1" in
    comment) echo "opens an HTML comment that does not close on the same line" ;;
    cr) echo "holds a carriage return that does not end it" ;;
    nul) echo "holds a NUL byte" ;;
    bom) echo "starts with a byte-order mark" ;;
    *) echo "is a fence-like line that is not a plain column-0 fence" ;;
  esac
}
# git_harden: every later git call in this process and its children runs
# hardened, but where a caller hands back its own setting on purpose
# (merge_ident reads the caller's global config); build-loop.sh and
# dev-cycle.sh call it once, after scrub_reexec and before their first git
# call (D6 runs both as gate code: rows 281, 495). Each pin keeps the gate's
# reads stable and its own (narrowed to these by brief
# 2026-11-01-relax-gate-git-state, research D4; the anti-forgery pins for the
# commit-graph and multi-pack-index went with it). HARDEN's config pairs
# outrank the repo's config: the objects the commit names, as gate_repo
# (which has no refs) reads them (core.useReplaceRefs there would override
# GIT_NO_REPLACE_OBJECTS); no hook or fsmonitor command, which the checkout
# could edit (H1); no core.attributesFile, as gate_repo reads none; git log's
# own date format and no signature check (a bad log.date stops git log;
# log.showSignature runs gpg.program); and no commit signing (commit.gpgSign
# runs gpg.program on a commit or merge; the gate's own merge commit also
# passes --no-gpg-sign: U4b1 i2 security F1). GIT_CONFIG_GLOBAL=/dev/null and
# GIT_CONFIG_NOSYSTEM: the user's or system merge.* settings would change the
# merge gate_repo computes and --main-log re-derives (A17); so a repository
# owned by another uid needs safe.directory some other way.
# GIT_ALLOW_PROTOCOL=none: no transport, so a lazy fetch (a partial clone's
# missing object) fails. The caller's own pairs (git -c, GIT_CONFIG_COUNT)
# still apply, git -c ones after HARDEN's. A GIT_CONFIG_COUNT that is not
# plain decimal (010 reads as 8 here and as 10 to git) exits 1. A second call
# returns at once: it would count HARDEN's pairs as the caller's
# (CALLER_COUNT).
HARDEN=(core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null log.date=default log.showSignature=false commit.gpgSign=false)
CALLER_COUNT=""
git_harden() {
  [[ -z "$CALLER_COUNT" ]] || return 0
  local c="${GIT_CONFIG_COUNT:-0}" kv
  [[ "$c" =~ ^(0|[123456789][0123456789]*)$ ]] || { echo "${0##*/}: GIT_CONFIG_COUNT is not a plain decimal count" >&2; exit 1; }
  CALLER_COUNT="$c"
  for kv in "${HARDEN[@]}"; do
    export "GIT_CONFIG_KEY_$c=${kv%%=*}" "GIT_CONFIG_VALUE_$c=${kv#*=}"; c=$((c + 1))
  done
  export GIT_CONFIG_COUNT="$c" GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=none
}
# The default branch, set by resolve_main (below). check_brief, check_branch,
# check_answer, main_entry and brief_fields read its commit, so they answer only
# when it was found by name, never for the current branch's fallback or before
# resolve_main has succeeded (main_entry and brief_fields answer error).
MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""
main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }
# How a path is stored in the default branch's commit, so that a file read from
# it is never a symlink's target text, a gitlink or a tree, and no directory
# above it is a symlink: prints "blob" (a regular file, mode 100644 or 100755),
# "absent", "notfile" (the path is some other kind of entry), "notdir PART"
# (PART, a directory above the path, is stored as something else), "badform"
# (a path pathform refuses: a .git* part such as .gitattributes, say) or "error"
# (no default branch found by name, ls-tree failed, or the tree lists a name
# twice; git's own reads would take the first copy, which may not be the one a
# check saw, so this answers error instead). Only blob reads the file, and only
# absent means there is none: every other word is a refusal. It runs
# main_by_name, then pathform, itself, before any read (so with no default
# branch even a refused form answers error; pathform also means ls-tree prints
# the name unquoted). entry_why words the refusals. One ls-tree call lists the
# path and every directory above it (-t: trees too; --full-tree: paths from the
# top level, whatever the current directory).
main_entry() {
  local p="" rest="$1" out mode path dup="" want=()
  local -A m=()
  if ! main_by_name; then echo error; return; fi
  if ! pathform "$1"; then echo badform; return; fi
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }
  while IFS=$'\t' read -r mode path; do
    [[ -n "$path" ]] || continue
    [[ -z "${m[$path]+set}" ]] || dup=1
    m["$path"]="${mode%% *}"
  done <<<"$out"
  [[ -z "$dup" ]] || { echo error; return; }
  for p in "${want[@]}"; do
    case "${m[$p]-}" in '') echo absent; return ;; 040000) ;; *) echo "notdir $p"; return ;; esac
  done
  case "${m[$1]-}" in '') echo absent ;; 100644|100755) echo blob ;; *) echo notfile ;; esac
}
# Why main_entry's word $1 is not a file to read, for a skip line. $2 is the
# path asked about, or "" (or no $2) when the skip line already names it:
# notfile and badform make it the subject ("$2 is not ..."; no subject when
# ""), error and any other word end "for $2" unless it is "", and notdir names
# only the directory above it.
# A newline in either becomes a space, so the reason stays one line.
entry_why() {
  local w="${1//$'\n'/ }" p="${2-}"
  p="${p//$'\n'/ }"
  case "$w" in
    notdir\ *) echo "${w#notdir } is not a directory on the default branch" ;;
    notfile) echo "${p:+$p is }not a regular file on the default branch" ;;
    badform) echo "${p:+$p is }not an allowed path form" ;;
    error) echo "the tree of the default branch could not be read${p:+ for $p}" ;;
    *) echo "the default branch answered $w${p:+ for $p}" ;;
  esac
}
# A brief's machine lines, read in one pass from the default branch's commit
# (never the working tree), so a brief has one parser: for each key, the first
# line outside a fence (FENCE_AWK) that starts "Status:", "Branch:", "Policy:",
# "Paths:", "Asked:" or "Dispatched:", whole, after one trailing CR is dropped.
# Sets BRIEF[status], BRIEF[branch], BRIEF[policy], BRIEF[paths], BRIEF[asked]
# and BRIEF[dispatched] (a key with no such line stays unset), each the line as
# stored but for that CR (FENCE_AWK refuses a NUL byte, which $(...) would
# drop), and empties BRIEF_ODD. Otherwise it sets no key and returns 1, with
# BRIEF_ODD "odd N WHY" (FENCE_AWK refused line N; WHY for oddwhy),
# "unbalanced N" (the fence opened at line N never closes) or "error" (no
# default branch found by name, a path pathform refuses, any main_entry answer
# but blob, its error included, or the blob could not be read). The callers judge the
# values. Call it in the caller's own shell: it sets globals.
declare -gA BRIEF=(); BRIEF_ODD=""
brief_fields() {
  # pipefail for this function only (local -), so a failed read is caught
  # whatever the caller set.
  local - out l; set -o pipefail
  BRIEF=(); BRIEF_ODD=""
  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
  # The whole blob is read (no early exit: SIGPIPE under pipefail).
  # shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal
  out="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'
    { sub(/\r$/, "") }
    fence($0) { next }
    match($0, /^(Status|Branch|Policy|Paths|Asked|Dispatched):/) {
      k = tolower(substr($0, 1, RLENGTH - 1)); if (!(k in got)) { got[k] = 1; kv[++nk] = k "\t" $0 }
    }
    END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline; else for (i = 1; i <= nk; i++) print kv[i] }')" \
    || { BRIEF_ODD=error; return 1; }
  while IFS= read -r l; do
    case "$l" in
      '') ;;
      odd\ *|unbalanced\ *) BRIEF=(); BRIEF_ODD="$l"; return 1 ;;
      *) BRIEF["${l%%$'\t'*}"]="${l#*$'\t'}" ;;
    esac
  done <<<"$out"
}
# A brief's state, read only from the default branch's commit (never the
# working tree): its Status line from brief_fields, which must be exactly
# "Status: open|done|dropped". A brief FENCE_AWK refuses (see its comment for
# every reason) is not read at all, and neither is one stored as anything but a
# regular file under plain directories (main_entry). "new" when the
# default branch has no file at that path (not landed yet, or moved to
# closed/). A closed/ path is read the same way (its state, for In flight; it
# never holds a slot).
check_brief() {
  local a="$1" st c e n why
  need_root
  if ! main_by_name; then echo "skip ${a//$'\n'/ }: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run"; return; fi
  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"; return; fi
  if ! anybrief "$a"; then
    echo "skip $a: not a build brief (docs/working/briefs/[closed/]YYYY-MM-DD-<slug>.md)"; return
  fi
  if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi
  # Only a regular file counts: a symlink's blob is its target text, not a
  # brief, and a gitlink or tree is not a brief either.
  e="$(main_entry "$a")"
  case "$e" in
    absent) echo "ok $a new"; return ;;
    blob) ;;
    *) echo "skip $a: $(entry_why "$e" "")"; return ;;
  esac
  if ! brief_fields "$a"; then
    case "$BRIEF_ODD" in
      odd\ *) read -r _ n why <<<"$BRIEF_ODD"; echo "skip $a: line $n $(oddwhy "$why"), so the brief is not read" ;;
      error) echo "skip $a: the brief could not be read from the default branch" ;;
      *) echo "skip $a: the code fence opened at line ${BRIEF_ODD#unbalanced } is never closed, so the brief is not read" ;;
    esac
    return
  fi
  st="${BRIEF[status]-}"
  if [[ ! "$st" =~ ^Status:\ (open|done|dropped)$ ]]; then
    echo "skip $a: its first Status: line is not exactly Status: open, done or dropped"; return
  fi
  # The default branch's own commit (first-parent history, a merge diffed
  # against its first parent) that last added or removed a line starting
  # "Status: " in this file: a merge commit for merged work, the branch's own
  # commit after a fast-forward; never a later Asked:/Kept: edit. Any such line
  # counts (a quoted one, or a move into closed/, which adds the file whole).
  # Repo config is switched off where it would run a command or change the
  # commit: --no-textconv (-G greps the diff, and a textconv driver would run),
  # --no-show-signature (log.showSignature runs gpg.program), --no-follow
  # (log.follow); and never anything but a full commit id (git's output can be
  # empty under a broken config, as on main: the field is then empty).
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s --no-textconv --no-show-signature --no-follow -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H --no-show-signature --no-follow "$MAIN_SHA" -- "$a")"
  if [[ -n "$c" && ! "$c" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]]; then echo "skip $a: its Status commit could not be read"; return; fi
  echo "ok $a ${st#Status: } $c"
}
# A brief's branch reaches git only as the commit show-ref finds at exactly
# refs/heads/<name>: never as an option, and never as a tag of the same name
# (git's own name lookup falls back to refs/tags/refs/heads/<name>). The last
# fields are the branch's commits not on the default branch (0: none, as for a
# fresh branch or one merged with a merge commit; a squash-merged branch keeps
# its count) and the date of its tip commit, YYYY-MM-DD in the committer's own
# time zone (as the committer set it: a future date is possible).
# The default branch is skipped, and so is every name when there is no default
# branch found by name (main_by_name), and so is a branch whose count or date
# cannot be read (a broken log.* or grep.* config, say: row 307).
check_branch() {
  local a="$1" sha n d
  if ! main_by_name; then echo "skip ${a//$'\n'/ }: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run"; return; fi
  if [[ ! "$a" =~ ^[$NAMECHARS]+$ || "$a" == -* ]]; then echo "skip ${a//$'\n'/ }: not an allowed branch name"
  elif ! git check-ref-format "refs/heads/$a" || ! git check-ref-format --branch "$a" >/dev/null 2>&1 \
    || [[ "$a" == HEAD || "$a" == refs/* ]]; then echo "skip $a: not a valid branch name"
  elif [[ "$a" == "$MAIN" ]]; then echo "skip $a: the default branch"
  else
    sha="$(git show-ref --verify --hash "refs/heads/$a" 2>/dev/null || true)"
    [[ -z "$sha" ]] || sha="$(git rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null || true)"
    if [[ -z "$sha" ]]; then echo "absent $a"
    elif n="$(git rev-list --count "$MAIN_SHA..$sha" 2>/dev/null)" && [[ "$n" =~ ^$DIGIT+$ ]] \
      && d="$(git log -1 --no-show-signature --format=%cs "$sha" 2>/dev/null)" && [[ "$d" =~ ^$DIGIT{4}-$DIGIT{2}-$DIGIT{2}$ ]]; then echo "ok $a $sha $n $d"
    else echo "skip $a: its commit count or date could not be read"; fi
  fi
}
# The lower-cased branch names that more than one open brief on main (in
# briefs/ or closed/) names, each between newlines, in OPEN_SHARED: a caller
# skips an open brief whose branch is listed (F31), and every open brief when
# it reads error. open_shared computes it once per process, from MAIN_SHA.
# One git grep finds the files with a "Status: open" line (a superset: fences
# are not modelled); brief_fields then reads only those, so every brief is
# still read through main_entry. Exit 1 is "none"; any exit above 1, a corrupt
# object's included, fails closed. A brief whose object is missing (git grep
# warns, exits 0 or 1) is not counted (row 293). Call it in the caller's shell.
OPEN_SHARED=""
open_shared() {
  local f list b rc=0
  local -A count=() BRIEF=()  # a local BRIEF: the caller's stays as it was
  [[ -z "$OPEN_SHARED" ]] || return 0
  if ! main_by_name; then OPEN_SHARED=error; return; fi
  list="$(git grep --no-color -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/)" || rc=$?
  if [[ "$rc" -gt 1 ]]; then OPEN_SHARED=error; return; fi
  while IFS= read -r f; do
    f="${f#"$MAIN_SHA":}"
    if ! anybrief "$f" || ! brief_fields "$f"; then continue; fi
    [[ "${BRIEF[status]-}" == "Status: open" && "${BRIEF[branch]-}" =~ ^Branch:\ ([^\ ]+)$ ]] || continue
    b="$(lower "${BASH_REMATCH[1]}")"; count[$b]=$(( ${count[$b]-0} + 1 ))
  done <<<"$list"
  OPEN_SHARED=$'\n'
  for b in "${!count[@]}"; do [[ "${count[$b]}" -lt 2 ]] || OPEN_SHARED+="$b"$'\n'; done
}
# The default branch: sets MAIN (its name), MAIN_SHA and MAIN_BY_NAME (1 when the
# name is origin/HEAD's, main or master, not the current branch's), and returns 1
# when MAIN_SHA is empty. Pass git only a hash for the default branch: origin/HEAD
# comes from the remote, and a branch named `--output=<path>` would reach
# `git log` as an option.
resolve_main() {
  local c sha cur origin_head candidates=()
  MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""
  origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  [[ -n "$origin_head" ]] && candidates+=("${origin_head#origin/}")
  candidates+=(main master)
  for c in "${candidates[@]}"; do
    [[ "$c" == -* ]] && continue
    # show-ref --verify takes only the exact ref, so a tag named refs/heads/<c>
    # cannot stand in for a missing branch (rev-parse would accept it).
    sha="$(git show-ref --verify --hash "refs/heads/$c" 2>/dev/null || true)"
    [[ -z "$sha" ]] || sha="$(git rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null || true)"
    if [[ -n "$sha" ]]; then MAIN="$c"; MAIN_SHA="$sha"; MAIN_BY_NAME=1; break; fi
  done
  if [[ -z "$MAIN_SHA" ]]; then
    # A repo on some other branch name: use the current branch.
    cur="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
    if [[ -n "$cur" && "$cur" != -* ]]; then
      MAIN="$cur"; MAIN_SHA="$(git rev-parse --verify --quiet HEAD 2>/dev/null || true)"
    fi
  fi
  [[ -n "$MAIN_SHA" ]]
}
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
# One pass over docs/dev-cycle.md (read_settings, reader_settings): per key, how
# many lines start with it once all but letters is dropped and case folded (best
# effort), the first two line numbers, whether the next unfenced line after the
# first is blank or the end (NEXT 1), and the first line: "KEY COUNT FIRST SECOND NEXT<TAB>LINE".
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
  else if (index(s, "readerroots") == 1) k = "roots"
  else if (index(s, "readerhomes") == 1) k = "homes"
  if (k != "") { c[k]++; if (c[k] == 1) { l1[k] = NR; t[k] = $0; nx[k] = 1; pk = k } else if (c[k] == 2) l2[k] = NR }
}
END {
  if (odd) print "odd " odd " " oddwhy
  else if (infence) print "unbalanced " fline
  else for (k in c) print k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) " " nx[k] "\t" t[k]
}'
# readerform PATH: a directory build-loop.sh names (--dir, a worktree): absolute, of NAMECHARS
# alone (so no blank or control byte: U2b3a final security 3), not / alone,
# with no empty, . or .. part.
readerform() {
  local rest="${1#/}/" c
  [[ "$1" == /?* && "$1" =~ ^[$NAMECHARS]+$ ]] || return 1
  while [[ -n "$rest" ]]; do c="${rest%%/*}"; rest="${rest#*/}"; [[ -n "$c" && "$c" != . && "$c" != .. ]] || return 1; done
}
# reader_settings: READERS_LINE, for build-loop.sh --settings alone. Until
# brief 2026-11-03-import-walk-plain, main's docs/dev-cycle.md could name
# "Reader roots:" and "Reader homes:" lines (host spellings of the checkout
# and host HOMEs) for the import walks to model; the walks now read only this
# checkout and main's commit, so the lines are ignored and never fail
# anything. The line says whether any is there, so the owner can delete it:
# "readers none: WHY" or "readers ignored: WHY". Call it after resolve_main.
READERS_LINE=""
# shellcheck disable=SC2034  # READERS_LINE: read by build-loop.sh --settings
reader_settings() {
  local f=docs/dev-cycle.md l k c l1 r="" h=""
  if ! main_by_name; then READERS_LINE="readers none: no default branch was found by name"; return 0; fi
  if ! main_file "$f" "$SETTINGS_AWK"; then
    if [[ "$FILE_WHY" == absent ]]; then READERS_LINE="readers none: no $f on the default branch"
    else READERS_LINE="readers ignored: $FILE_WHY; Reader roots and Reader homes lines are no longer read either way"; fi
    return 0
  fi
  while IFS= read -r l; do
    read -r k c l1 _ <<<"${l%%$'\t'*}"
    if [[ "$k" == roots ]]; then r="$l1"; elif [[ "$k" == homes ]]; then h="$l1"; fi
  done <<<"$FILE_OUT"
  if [[ -z "$r$h" ]]; then READERS_LINE='readers none: no line starts "Reader roots:" or "Reader homes:"'; return 0; fi
  # The first line of each key counts; a second copy is ignored with it.
  if [[ -n "$r" && -n "$h" ]]; then l="the Reader roots line (line $r) and the Reader homes line (line $h) of $f on the default branch are"; k=them
  elif [[ -n "$r" ]]; then l="the Reader roots line (line $r) of $f on the default branch is"; k=it
  else l="the Reader homes line (line $h) of $f on the default branch is"; k=it; fi
  READERS_LINE="readers ignored: $l no longer read (the import walks read only this checkout and the default branch); delete $k"
}
# Instruction-file basenames, lower-cased: CLAUDE.md, CLAUDE.local.md,
# AGENTS.override.md and the like, GEMINI.md, SKILL.md. (A variable, quoted:
# written inline, the hermeticity lint reads the alternation as a command.)
INSTRUCTION_FILE='^(claude|agents?|gemini)(\.[abcdefghijklmnopqrstuvwxyz0123456789_-]+)?\.md$|^skill\.md$'
# The one start rule both walks use (U2a4), for a lower-cased path: an
# instruction file's name, or a .md file at any depth under a .claude/
# directory's rules/ or PROMPT_DIR's commands/, agents/, output-styles/ or
# skills/ (a prompt: a command's @ names load when it runs, relative to the
# session, so a walk also resolves a prompt start's names against the repo
# root). truthrule refuses the same names.
PROMPT_DIR='(^|/)\.claude/(commands|agents|output-styles|skills)/'
isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] || [[ "$1" == *.md && ( "$1" =~ $PROMPT_DIR || "/$1" == */.claude/rules/* ) ]]; }
# The import walks, reading plain @path imports (brief
# 2026-11-03-import-walk-plain; restriction audit G55-G62). A file an
# instruction or prompt file pulls in with an @ import, directly or through
# other imports, is read as instructions, so an in-cycle fix never edits it
# (imported_names, the tree walk, for --check-fix) and a self-merge never
# lands it (main_imports, the main walk, for floor). The threat is an honest
# slip (CLAUDE.md says @docs/conventions.md and a loop edits that file); an
# import hidden on purpose is out of scope (docs/constraints.md S1). Rules
# both walks share:
#  - Starts: the start files (isstart) the walk lists, and no others. Files
#    outside the checkout that a session also loads (the user's ~/.claude,
#    an ancestor's CLAUDE.md, another worktree's, a plugin's) are not read.
#  - Names (import_targets): every @ starts a token, read up to the next
#    space, tab or CR; the token is a name, and so are the token cut before
#    its first # or ] and each of the two with trailing punctuation stripped
#    (WALK_PUNCT), so @docs/a.md#intro, [@docs/a.md](x) and **@docs/a.md**.
#    each read docs/a.md. A name led by ~/ joins HOME, one led
#    by / is absolute, and any other joins the importing file's directory
#    (a prompt start's also joins the repo root); each is resolved lexically
#    (.. stops at /) and kept only when it lands below ROOT_REAL or below the
#    main worktree (WALK_MAIN_WT: the gate runs in a worktree of its own, and
#    @/workspace/docs/x.md names a repo path for every session in the main
#    one), as a repo path. Escaped spaces, quoted @"..." mentions, Unicode spaces and HTML
#    comments are not modelled.
#  - Every name a walk reaches joins its list (lower-cased), whether or not a
#    file is there, so a self-merge cannot create an imported file either; a
#    name that is a file is read once and its names followed.
#  - No symlink is followed: a start or name main stores as a symlink, or a
#    checkout path that is a link or lies below one (rawfile), fails the walk
#    (H2). A gitlink, a directory, a FIFO or nothing at a name is skipped:
#    nothing there loads; but a name below a directory the walk cannot search
#    fails it, since a file there may load (H2).
#  - A file over IMPORT_MAX_BYTES (Claude Code's own 4 MiB limit), one that is
#    not valid UTF-8 (a NUL byte included), one that cannot be read, or a ~/
#    name while HOME is not an absolute path fails the walk (H2).
# The main walk starts at every start file main's commit stores and reads
# main's blob for each path main stores as a file; then at the checkout's
# untracked and ignored start files main lacks (CLAUDE.local.md: git ls-files
# --others, any depth; a plain regular file is read, any other shape is
# skipped, and a directory git cannot read is skipped with it), and for a name
# main lacks it reads the checkout's file. The tree walk starts at the
# checkout's tracked and untracked start files and reads the checkout only.
# A failed walk returns 1 with its list (IMPORTED, IMPORTED_MAIN) "error", so
# isimported answers imported for every path: callers test the walks under if
# or ||. Each walk caches its result, a failure included: the tree walk keyed
# on ROOT_REAL and HOME, the main walk also on MAIN_SHA and MAIN_BY_NAME, so a
# caller whose checkout may have changed calls import_reset (contract item 4).
# A cache hit forks nothing, not even need_root's check. IMPORTED_MAIN_WHY
# and IMPORTED_WHY say where a walk failed, as "KIND" or "KIND PATH" (walk_why
# words it): main (not found by name), tree (main's tree could not be listed
# or parsed), list (the checkout's files could not be listed or their names
# lower-cased), link PATH (a symlink the walk does not follow) or read PATH
# (PATH could not be read or parsed); empty after a walk that succeeds.
IMPORTED=error; IMPORTED_DONE=""; IMPORTED_WHY=""; IMPORTED_MAIN=error; IMPORTED_MAIN_DONE=""; IMPORTED_MAIN_WHY=""
IMPORT_MAX_BYTES=4194304
# walk_why WHY: the sentence for an IMPORTED_MAIN_WHY or IMPORTED_WHY word, as
# entry_why words main_entry's. A PATH shows only when every character is one
# pathform allows (check_line's rule for repo text, so a crafted name prints
# as ?: U2c2 i1 security 1).
walk_why() {
  local k="${1%% *}" d=""
  [[ "$1" != *" "* ]] || d="${1#* }"
  [[ -z "$d" || "$d" =~ ^[$NAMECHARS]+$ ]] || d="?"
  case "$k" in
    main) echo "the default branch was not found by name" ;;
    tree) echo "the default branch's tree could not be listed" ;;
    list) echo "the checkout's .md files could not be listed, or their names lower-cased" ;;
    link) echo "$d is a symlink or lies below one, which the walk does not follow" ;;
    read) echo "$d could not be read, is larger than 4 MiB or not valid UTF-8, or names ~/ while HOME is not an absolute path" ;;
    *) echo "the walk failed (${k:-no reason recorded})" ;;
  esac
}
# import_reset: the next call of either walk walks again (caller contract item 4).
import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; }
lower() { printf '%s' "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'; }
# Well-formed UTF-8 (RFC 3629: no overlongs, surrogates or code points past
# U+10FFFF; no NUL), as an awk ERE for a C-locale awk -v, which turns its
# octal escapes into bytes: it agreed with a strict UTF-8 decoder on 20,013 cases
# (U2a3b L2-i2 performance F1).
UTF8_WELL_FORMED='^([\001-\177]|[\302-\337][\200-\277]|\340[\240-\277][\200-\277]|[\341-\354\356\357][\200-\277][\200-\277]|\355[\200-\237][\200-\277]|\360[\220-\277][\200-\277][\200-\277]|[\361-\363][\200-\277][\200-\277][\200-\277]|\364[\200-\217][\200-\277][\200-\277])*$'
# The punctuation stripped from a token's end for its second name, as an awk
# bracket expression's body (] first, so it is a member): ) ] } > . , ; : ! ?,
# quotes, a backtick, * and _ (Markdown emphasis).
WALK_PUNCT='])}>.,;:!?"`*_'"'"
# The parser (import_targets): exit 2 for no absolute root, 3 for a line
# that is not well-formed UTF-8, 4 for a ~/ name with no absolute home.
# shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal
IMPORT_AWK='
function put(c,   n, i, k, part, st, out) {
  n = split(c, part, "/"); k = 0
  for (i = 1; i <= n; i++) {
    if (part[i] == "" || part[i] == ".") continue
    if (part[i] == "..") { if (k > 0) k--; continue }
    st[++k] = part[i]
  }
  out = ""; for (i = 1; i <= k; i++) out = out "/" st[i]
  if (index(out, pre) == 1 && length(out) > length(pre)) out = substr(out, length(pre) + 1)
  else if (alt != "" && index(out, alt) == 1 && length(out) > length(alt)) out = substr(out, length(alt) + 1)
  else return
  if (!(out in seen)) { seen[out] = 1; print out }
}
# names T: the names of token T: T, T cut before its first # or ] (an anchor,
# the text of a Markdown link), and each with trailing punctuation stripped.
function names(t,   c, s) {
  name(t); s = t; sub(strip, "", s); if (s != t) name(s)
  c = t; sub(/[]#].*/, "", c); if (c == t) return
  name(c); s = c; sub(strip, "", s); if (s != c) name(s)
}
function name(c) {
  if (c == "") return
  if (substr(c, 1, 2) == "~/") { if (substr(home, 1, 1) != "/") exit 4; put(home "/" substr(c, 3)); return }
  if (substr(c, 1, 1) == "/") { put(c); return }
  put(root "/" dir "/" c); if (top) put(root "/" c)
}
BEGIN {
  root = ENVIRON["IT_ROOT"]; if (substr(root, 1, 1) != "/" || root == "/") exit 2
  pre = root "/"; dir = ENVIRON["IT_DIR"]; top = (ENVIRON["IT_TOP"] != ""); home = ENVIRON["IT_HOME"]
  alt = ENVIRON["IT_MAIN_WT"]; if (alt != "") alt = alt "/"
  strip = "[" ENVIRON["IT_PUNCT"] "]+$"
}
$0 !~ ok { exit 3 }
{
  line = $0
  while ((i = index(line, "@")) > 0) {
    line = substr(line, i + 1); t = line; sub(/[ \t\r].*/, "", t)
    names(t)
  }
}'
# import_targets DIR [TOP]: the names in the text on stdin, by the rules above,
# for a file in the repo directory DIR ("" at the top level); with TOP not
# empty, a relative name also joins the repo root (a prompt start). One repo
# path per line, case kept, each once. It reads ROOT_REAL, WALK_MAIN_WT and
# IMPORT_HOME (import_home), and returns 1 when the text is not well-formed UTF-8, a ~/
# name appears while IMPORT_HOME is not absolute, ROOT_REAL is empty or /, or
# awk fails.
import_targets() {
  env LC_ALL=C IT_ROOT="${ROOT_REAL:-}" IT_DIR="$1" IT_TOP="${2:-}" IT_HOME="$IMPORT_HOME" IT_MAIN_WT="$WALK_MAIN_WT" IT_PUNCT="$WALK_PUNCT" \
    awk -v ok="$UTF8_WELL_FORMED" "$IMPORT_AWK"
}
# import_home: IMPORT_HOME, HOME's real path (ROOT_REAL is real too, so the two
# compare), or empty when HOME is unset, empty or not absolute. Each walk
# calls it first.
IMPORT_HOME=""; WALK_MAIN_WT=""
# walk_main_wt: WALK_MAIN_WT, the main worktree's real path (the parent of the
# common .git directory) when it is not ROOT_REAL, else empty; it returns 1
# when git cannot say (the walk then fails: H2). A common directory not named
# .git (a bare repository) has no main worktree.
walk_main_wt() {
  local c
  WALK_MAIN_WT=""
  c="$(git rev-parse --path-format=absolute --git-common-dir)" && [[ "$c" == /* ]] || return 1
  [[ "${c##*/}" == .git ]] || return 0
  c="$(realpath -m -- "${c%/*}")" || return 1
  [[ "$c" == / || "$c" == "${ROOT_REAL:-}" ]] || WALK_MAIN_WT="$c"
}
import_home() {
  IMPORT_HOME=""
  [[ "${HOME:-}" == /* ]] || return 0
  IMPORT_HOME="$(realpath -m -- "$HOME" 2>/dev/null)" || IMPORT_HOME=""
}
# nul_list NAME CMD...: array NAME gets CMD's NUL-split output, or is emptied and 1 unless CMD exited 0 and its output was empty or ended in NUL.
nul_list() { local -n nl_a="$1"; shift; mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1); [[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || { nl_a=(); return 1; }; unset 'nl_a[-1]'; }
# lower_all ARGS...: each argument lower-cased and NUL-terminated, in one tr
# (lower would fork per path). Read it through nul_list: a tr that dies after a
# partial flush then fails the list rather than truncating its last name and
# dropping a start (U2a3b final N1).
lower_all() { local -; set -o pipefail; printf '%s\0' "$@" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'; }
# untracked_md: the checkout's untracked and ignored .md files, any case,
# NUL-separated (--others without --exclude-standard already lists ignored
# files). git's warnings (a directory it cannot read, which it skips) are
# dropped: such a directory is skipped, as any start shape the walk does not
# read is; a failed listing still fails.
untracked_md() { GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md' 2>/dev/null; }
# walk_file ENT PATH TOP: the names in PATH (import_targets; TOP as it takes
# it), in WALK_OUT: main's blob when the associative array ENT (main's modes
# by path; empty for the tree walk) stores PATH as a file, else the checkout's
# file. Returns 2 when nothing at PATH loads (a gitlink, a directory, a FIFO,
# nothing), or 1 with WALK_WHY set when the walk must fail: a symlink at or
# above PATH, a mode it does not know, a file it cannot read or size, one over
# IMPORT_MAX_BYTES, or import_targets' refusal.
WALK_OUT=""; WALK_WHY=""; WALK_LIST=""
walk_file() {
  local -n wf_e="$1"; local - p="$2" d="" n; set -o pipefail
  [[ "$p" != */* ]] || d="${p%/*}"
  WALK_OUT=""; WALK_WHY="read $p"
  case "${wf_e[$p]-checkout}" in
    100644|100755)
      n="$(git cat-file -s "$MAIN_SHA:$p")" && [[ "$n" =~ ^[0123456789]+$ && "$n" -le $IMPORT_MAX_BYTES ]] || return 1
      WALK_OUT="$(git cat-file blob "$MAIN_SHA:$p" | import_targets "$d" "$3")" || return 1 ;;
    120000) WALK_WHY="link $p"; return 1 ;;
    160000) return 2 ;;
    checkout)
      if [[ -L "$p" ]]; then WALK_WHY="link $p"; return 1; fi
      if [[ ! -e "$p" ]]; then
        # Absent, or below a directory the walk cannot search: the nearest
        # ancestor that exists decides (a plain file there: nothing loads).
        n="$p"; while [[ "$n" == */* ]]; do n="${n%/*}"; [[ ! -e "$n" ]] || break; done
        [[ "$n" == */* || -e "$n" ]] || n=.
        [[ ! -d "$n" || -x "$n" ]] || return 1
        return 2
      fi
      [[ -f "$p" ]] || return 2
      rawfile "$p" || { WALK_WHY="link $p"; return 1; }
      [[ -r "$p" ]] && n="$(stat -c %s -- "$p")" && [[ "$n" =~ ^[0123456789]+$ && "$n" -le $IMPORT_MAX_BYTES ]] || return 1
      WALK_OUT="$(import_targets "$d" "$3" < "$p")" || return 1 ;;
    *) return 1 ;;
  esac
}
# walk_core MODE: one walk (main or tree), by the rules above: WALK_LIST gets
# the reached names, lower-cased, each on its own line between newlines, or
# "error" and WALK_WHY its word with a return of 1. Every failure is tested
# explicitly: its callers run it under if, where set -e is off.
walk_core() {
  local - mode="$1" f p i rc lp rec qi=0 nt=0 queue=() recs=() cand=() low=(); local -A ent=() seen=() top=()
  set -o pipefail
  WALK_LIST=error; WALK_WHY=list
  import_home
  walk_main_wt || return 1
  if [[ "$mode" == main ]]; then
    WALK_WHY=main; main_by_name || return 1
    WALK_WHY=tree; nul_list recs git ls-tree -r -z --full-tree "$MAIN_SHA" || return 1
    for rec in "${recs[@]}"; do
      [[ "$rec" =~ ^([01234567]{6})\ [abcdefghijklmnopqrstuvwxyz]+\ [0123456789abcdef]{40,64}$'\t'(.+)$ ]] || return 1
      f="${BASH_REMATCH[2]}"; ent[$f]="${BASH_REMATCH[1]}"
      [[ "$f" != *.[mM][dD] ]] || cand+=("$f")
    done
    WALK_WHY=list
  else
    nul_list recs git ls-files -z || return 1
    for f in "${recs[@]}"; do [[ "$f" != *.[mM][dD] ]] || cand+=("$f"); done
  fi
  nt=${#cand[@]}
  nul_list recs untracked_md || return 1
  cand+=("${recs[@]}")
  [[ ${#cand[@]} -eq 0 ]] || nul_list low lower_all "${cand[@]}" || return 1
  [[ ${#low[@]} -eq ${#cand[@]} ]] || return 1
  for i in "${!cand[@]}"; do
    f="${cand[i]}"
    isstart "${low[i]}" && [[ -z "${seen[$f]+set}" ]] || continue
    # An untracked start: main's entry wins, and only a plain regular file is read.
    [[ $i -lt $nt ]] || { [[ -z "${ent[$f]+set}" ]] && rawfile "$f"; } || continue
    seen[$f]=1; queue+=("$f"); [[ ! "${low[i]}" =~ $PROMPT_DIR ]] || top[$f]=1
  done
  WALK_LIST=$'\n'
  while [[ $qi -lt ${#queue[@]} ]]; do
    f="${queue[qi]}"; qi=$((qi + 1)); rc=0
    walk_file ent "$f" "${top[$f]-}" || rc=$?
    [[ $rc -ne 1 ]] || { WALK_LIST=error; return 1; }
    [[ $rc -eq 0 && -n "$WALK_OUT" ]] || continue
    lp="$(lower "$WALK_OUT")" || { WALK_LIST=error; WALK_WHY=list; return 1; }
    WALK_LIST+="$lp"$'\n'
    while IFS= read -r p; do [[ -n "${seen[$p]+set}" ]] || { seen[$p]=1; queue+=("$p"); }; done < <(printf '%s\n' "$WALK_OUT")
  done
  WALK_WHY=""
}
# The tree walk, over the checkout at ROOT_REAL (dev-cycle.sh --check-fix).
imported_names() {
  local key="${ROOT_REAL:-} ${HOME+x}${HOME-}"
  if [[ -n "${ROOT_REAL:-}" && "$IMPORTED_DONE" == "$key" ]]; then [[ "$IMPORTED" != error ]]; return; fi
  need_root
  IMPORTED_DONE="$key"
  if walk_core tree; then IMPORTED="$WALK_LIST"; IMPORTED_WHY=""; return 0; fi
  IMPORTED=error; IMPORTED_WHY="$WALK_WHY"; return 1
}
# The main walk, over the default branch's commit and the checkout's files
# main lacks (floor); it needs resolve_main to have found main by name.
main_imports() {
  local key="$MAIN_SHA $MAIN_BY_NAME ${ROOT_REAL:-} ${HOME+x}${HOME-}"
  if [[ -n "${ROOT_REAL:-}" && "$IMPORTED_MAIN_DONE" == "$key" ]]; then [[ "$IMPORTED_MAIN" != error ]]; return; fi
  need_root
  IMPORTED_MAIN_DONE="$key"
  if walk_core main; then IMPORTED_MAIN="$WALK_LIST"; IMPORTED_MAIN_WHY=""; return 0; fi
  IMPORTED_MAIN=error; IMPORTED_MAIN_WHY="$WALK_WHY"; return 1
}
# Whether path $2 (any case) is imported, by the walk $1 names: tree or main.
# A failed walk, a failed lower of $2, or a walk name that is neither answers
# imported (0), so a caller testing it with `if` refuses; a caller that words a
# failed walk asks truthwalk, which runs the walk first. Run it in the caller's shell: the walk exits
# through need_root and caches its result.
isimported() {
  local lp
  need_root
  lp="$(lower "$2")" || return 0
  case "$1" in main) main_imports || return 0 ;; tree) imported_names || return 0 ;; *) return 0 ;; esac
  walk_has "$1" "$lp"
}
# walk_has WALK LP: whether the list of the walk WALK names (main or tree), as
# its last call left it, holds LP, a lower-cased path: no fork. Ask it only
# after that walk succeeded (contract item 6); on an error list it answers
# 0, as isimported does, so a misplaced call refuses (final api 1).
walk_has() {
  if [[ "$1" == main ]]; then local -n wh_l=IMPORTED_MAIN; else local -n wh_l=IMPORTED; fi
  [[ "$wh_l" == error || "$wh_l" == *$'\n'"$2"$'\n'* ]]
}
# The read-as-truth rule --check-fix, floor and build-loop.sh's cycle_rules
# share (cycle_rules refuses every word but cycle, so a cycle file must never
# take an earlier word; plan D5 items 1, 2 and 4;
# build-loop.sh's N rules read its cycle, settings and user words too, so a
# word tested before them must never match a file those words cover:
# override rows 204, 322, 348), for a lower-cased path: returns 0 with
# TRUTH_WHY set when it refuses: instr (isstart: an instruction or prompt
# file), dot (a .-prefixed component, a top-level one included), cycle
# (writable), settings (docs/dev-cycle.md), user (docs/constraints.md, the
# user's: plan D2) or record (docs/decisions/, docs/human-author/, and
# docs/failure-patterns.md, the library the gate's fp_gaps compares entry
# numbers in, and its old path docs/thoughts/failure-patterns.md, which a repo
# not yet migrated still holds: an unreviewed edit or delete there would
# become the library, or drop the pending migration, at the owner's git mv),
# and case for a path holding an upper-case letter (a caller that did not
# lower it). Each caller words the words and adds its own rules; the rest of
# docs/thoughts/ is in none of them (a living doc an in-cycle fix may edit and
# a self-merge may land; brief 2026-10-31-failure-patterns-out-of-thoughts).
# truthwalk then asks the import walk. Run both in the caller's shell: they set TRUTH_WHY.
TRUTH_WHY=""
truthrule() {
  TRUTH_WHY=""
  if [[ "$1" == *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]]; then TRUTH_WHY="case"
  elif isstart "$1"; then TRUTH_WHY="instr"
  elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"
  elif writable "$1"; then TRUTH_WHY="cycle"
  elif [[ "$1" == docs/dev-cycle.md ]]; then TRUTH_WHY="settings"
  elif [[ "$1" == docs/constraints.md ]]; then TRUTH_WHY="user"
  elif [[ "$1" =~ ^docs/(decisions|human-author)/ || "$1" == docs/failure-patterns.md || "$1" == docs/thoughts/failure-patterns.md ]]; then TRUTH_WHY="record"
  else return 1; fi
}
# truthwalk WALK PATH: runs the import walk WALK (tree for --check-fix, main
# for floor), then asks it about PATH, lower-cased (contract item 8), through
# walk_has as isimported does, but with no lower (isimported's lower and root
# check cost floor ~2 ms a path: U2c1 final performance 1), so a caller
# words a failed walk without knowing the order (override row 418).
# Returns 0 when the walk fails (TRUTH_WHY=walk, with TRUTH_WHERE walk_why's
# sentence for where, or empty when the walk does not say: rows 630, 634) or reaches PATH or PATH holds
# an upper-case letter (TRUTH_WHY=imported; both callers run truthrule's case
# word first), else 1 with TRUTH_WHY empty; an unknown WALK answers
# walk without running one. For tree or main it exits through need_root when it walks.
TRUTH_WHERE=""
truthwalk() {
  TRUTH_WHY=walk; TRUTH_WHERE=""
  case "$1" in
    main) main_imports || { TRUTH_WHERE="$(walk_why "$IMPORTED_MAIN_WHY")"; return 0; } ;;
    tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE="$(walk_why "$IMPORTED_WHY")"; return 0; } ;;
    *) return 0 ;;
  esac
  TRUTH_WHY=imported
  [[ "$2" != *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]] && ! walk_has "$1" "$2" || return 0
  TRUTH_WHY=""; return 1
}
# A brief's own files, keyed on its full stem $2 (YYYY-MM-DD-slug, so a slug
# shared by two dates is not a collision), for a path $1 (it folds no case:
# floor passes it lower-cased, build-loop.sh srules as spelled) with
# diff-tree status letter $3: its working docs, docs/working/{research,plan,
# checkpoint,handoff,test-strategy}-STEM.md, and a review it adds,
# docs/reviews/STEM.md or docs/reviews/NAME-STEM.md (a modified or deleted
# review is never its own: reviews are records).
ownfile() {
  local b="${1#docs/reviews/}"
  [[ -n "$2" ]] || return 1
  if [[ "$1" =~ ^docs/working/(research|plan|checkpoint|handoff|test-strategy)-(.+)\.md$ && "${BASH_REMATCH[2]}" == "$2" ]]; then return 0; fi
  [[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]
}
# The gate's own files: a change to them lands only through a merge-gate-
# review entry, never a self-merge. The scripts because the image copy, built
# from the host checkout's HEAD, runs every merge after the next release (plan D6, D5
# item 3; Q-140 [1]); skills/dev-cycle/ because its SKILL.md holds the D6 snippet that runs
# the gate (U4c; plan D4, F52). Both reach a session only from a release, so
# here the floor is stricter than D5.
# One list for floor and build-loop.sh's --approved, which tests it on its
# own (floor does not run there); build-loop.sh's header repeats it.
GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'
# The self-merge floor (plan D5 items 1-4): a changed path that a self-merge never lands,
# even when the brief's Paths: lists it, because it takes effect on merge with
# no later review or later runs read it as truth. $1 is the path as the merge
# result stores it, $2 the brief's full stem and $3 the diff-tree status
# letter alone (R for R100; only A makes a review the brief's own), and $4,
# optional, $1 lower-cased (build-loop.sh passes it, so floor forks no
# lower: U2c1 final performance 1; floor then reads only $4, so the two must
# agree; an upper-case letter in it refuses as case).
# Returns 0 with FLOOR_WHY set to a word when the floor refuses (floor_why
# words it: row 472), else 1. Its gate word is no test of whether a merge
# touches gate code (floor runs after the rules before it, and not at all
# under --approved): test GATE_CODE for that. Paths compare
# lower-cased (a case-insensitive checkout reads Docs/Roadmap.md as
# docs/roadmap.md), and a path below a start file's name or an imported .md
# name is refused too (a directory there keeps the file from being created:
# U2c1 i1 security 1). The caller's duties are the gate caller contract's (the
# lib's header): floor item 5, symlinks and gitlinks, is the caller's mode
# rule, and the caller judges the brief's own Status change before this.
# It reads nothing but through main_imports, whose root check runs when it
# walks, so a call given $4 that main_imports' cache answers forks nothing
# but walk_why's subshell (truthwalk's) after a failed walk; the cache does not
# change within a gate decision.
# Without $4 it forks a lower per path: a caller with many paths lowers them
# in one batch, as check_line does (final performance 2).
FLOOR_WHY=""  # read by floor's caller (build-loop.sh srules)
# shellcheck disable=SC2034
floor() {
  local lp="${4-}" d
  FLOOR_WHY=""
  [[ -n "$lp" ]] || lp="$(lower "$1")" || { FLOOR_WHY=case; return 0; }
  if truthrule "$lp"; then FLOOR_WHY="$TRUTH_WHY"; [[ "$FLOOR_WHY" != settings ]] || FLOOR_WHY=cycle
  elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate
  elif [[ "$lp" == docs/working/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY=working
  elif [[ "$lp" == docs/reviews/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY=review
  elif truthwalk main "$lp"; then FLOOR_WHY="$TRUTH_WHY"  # walk (TRUTH_WHERE says where) or imported
  else
    # A directory at a start's name, or at an imported .md name (not any import's: a name such as @docs would put every path below docs/ here; override row).
    # Reached only after truthwalk main answered 1, so the walk succeeded (contract item 6).
    d="$lp"; while [[ "$d" == */* ]]; do
      d="${d%/*}"; ! isstart "$d" && { [[ "$d" != *.md ]] || ! walk_has main "$d"; } || { FLOOR_WHY=below; return 0; }
    done
    return 1
  fi
}
# floor_why WORD: the sentence for a FLOOR_WHY word, as walk_why words
# IMPORTED_MAIN_WHY's; walk reads TRUTH_WHERE, so word it before the next
# truthwalk.
floor_why() {
  case "$1" in
    instr) echo "an instruction or prompt file, which sessions load from the checkout" ;;
    dot) echo "a dotfile or a path under a dot-directory" ;;
    cycle) echo "one of the dev cycle's own files" ;;
    user) echo "the user's constraints doc, which every loop prompt carries" ;;
    record) echo "a record later runs read as truth" ;;
    case) echo "the path could not be lower-cased" ;;
    gate) echo "the gate's own code, which lands only through a merge-gate- review entry" ;;
    working) echo "a working file that is not this brief's own (they carry its full stem)" ;;
    review) echo "a review record (only an added review named STEM.md or NAME-STEM.md lands)" ;;
    walk) echo "the default branch's instruction files could not be walked for @ imports: $TRUTH_WHERE" ;;
    imported) echo "an instruction or prompt file (on the default branch, or only in the checkout) imports it with @ (directly or through another import)" ;;
    below) echo "a path below the name of an instruction or prompt file, or of a .md file one imports with @" ;;
    *) echo "refused by the self-merge floor (${1:-no reason recorded})" ;;
  esac
}
# The keep-or-drop answer rule, for one entry of a questions file. Prints keep,
# drop, done, open, unrecognized, dup (the heading appears more than once),
# "odd N WHY", "unbalanced N" or "quoted N" (the file cannot be trusted; N is
# the line, WHY the oddwhy reason), or nothing when the file has no such entry;
# after keep, drop, done, open or unrecognized, a second line holds the entry's
# heading after "### " (check_answer splits it off). A trailing CR is dropped.
# Fences are tracked across the whole file (FENCE_AWK), and no fenced line is
# read. Each of these makes the whole file a skip for every ID, naming the line
# and the reason: anything FENCE_AWK refuses (see its comment), a fence still
# open at the end, or a "### Q-NNN " heading inside a fence (questions.sh
# archive splits entries at such a line, which is how stray fences arise; one
# stray fence line flips everything after it, and two can balance again). No
# real questions file has any of them.
# An entry is answered only when its header line (the first line starting
# "**Needs:**", as questions.sh writes it) has a " · "-separated field that is
# "**Status:** ANSWERED" once blanks around the field are trimmed (the last
# Status field counts, as in questions.sh); any other entry is open, whatever its body says: the answer is
# read only after it has been recorded. The answer is the first line in the
# entry, outside fences, that starts, after an optional "- ", with "Q-NNN:" or a
# bold "**Answer:", "**Answer (" or "**Answered" label (any case); the
# recorder's line is that one (the questions protocol records the user's answer
# there), and a note above it would be read first. Its text starts after the
# label: at ":**" when the label alone is bold, else at the first ": ", and then
# ends at the bold's close if it opened inside the bold. Only the text's leading
# token decides: [1], 1 or keep; [2], 2 or drop; [3], 3 or done (a word must be
# followed by the end, punctuation or a dash). Anything else, including a hedge
# or a bracket further in, is unrecognized, and the user is asked again.
# build-loop.sh's ANSWERS_AWK (--main-log's answers class), QKEYS_AWK and
# QDIFF_AWK (--cycle-diff: also this heading rule and entry end) copy these
# labels and the header line's Status field: change all of them together (a
# label read here but not there lets --cycle-diff pass an answer: i2
# architecture 1; build-loop-orchestrator.bats checks the label regex).
# --cycle-diff runs this program itself (id Q-) for the whole-file skips.
# shellcheck disable=SC2016  # awk code, not shell: $0 and the rest must stay literal
ANSWER_AWK='
function option(span,   s, w, r, t) {
  s = tolower(span); sub(/^[ \t*]+/, "", s)
  if (substr(s, 1, 3) == "[1]") return "keep"
  if (substr(s, 1, 3) == "[2]") return "drop"
  if (substr(s, 1, 3) == "[3]") return "done"
  if (!match(s, /^(1|2|3|keep|drop|done)/)) return "unrecognized"
  w = substr(s, 1, RLENGTH); r = substr(s, RLENGTH + 1); t = r; sub(/^[ \t]+/, "", t)
  if (!(r == "" || r ~ /^[.,;:!)*]/ || (t != r && (t == "" || substr(t, 1, 1) == "-" \
      || substr(t, 1, 3) == "\342\200\224" || substr(t, 1, 3) == "\342\200\223"))))
    return "unrecognized"
  if (w == "1" || w == "keep") return "keep"
  if (w == "2" || w == "drop") return "drop"
  return "done"
}
function heading(l,   h) {
  if (substr(l, 1, 4) != "### ") return 0
  h = substr(l, 5)
  return h == id || index(h, id " ") == 1 || index(h, id "\t") == 1
}
{ sub(/\r$/, "") }
infence && /^### Q-[0123456789]+ / { if (!qline) qline = NR; inside = 0 }
fence($0) { next }
heading($0) { count++; inside = (count == 1); header = 0; if (inside) head = substr($0, 5); next }
/^(#|##|###) / { inside = 0; next }
!inside { next }
!header && /^\*\*Needs:\*\*/ {
  header = 1; v = ""; n = split($0, fld, " · ")
  for (i = 1; i <= n; i++) { f = fld[i]; sub(/^[ \t]+/, "", f); if (substr(f, 1, 12) == "**Status:** ") v = substr(f, 13) }
  sub(/[ \t]+$/, "", v); answered = (v == "ANSWERED")
  next
}
!done {
  line = $0; sub(/^- /, "", line)
  if (index(line, id ":") == 1) { result = option(substr(line, length(id) + 2)); done = 1; next }
  low = tolower(line)
  if (low !~ /^\*\*answer(:|ed| \()/) next
  rest = substr(line, 3)
  if ((c = index(rest, ":**")) > 0 && (c < (d = index(rest, ": ")) || !d)) {
    rest = substr(rest, c + 3)
  } else if ((c = index(rest, ": ")) > 0) {
    e = index(rest, "**"); inbold = !(e > 0 && e < c)   # is the bold of the label still open at ": "?
    rest = substr(rest, c + 2)
    if (inbold && (e = index(rest, "**")) > 0) rest = substr(rest, 1, e - 1)
  } else next
  result = option(rest); done = 1
}
END {
  if (odd) print "odd " odd " " oddwhy
  else if (infence) print "unbalanced " fline
  else if (qline) print "quoted " qline
  else if (count > 1) print "dup"
  else if (count) { print (!answered ? "open" : done ? result : "unrecognized"); print head }
}'
# One answer, from docs/working/questions.md and questions-archive.md on the
# default branch's commit, never the working tree: an answer that unblocks
# autonomous work must have reached main (plan D8), because a build loop can
# write any working tree. A file stored as anything but a regular file under
# plain directories there is not read (main_entry). It reads only git objects,
# so it needs no ROOT_REAL and adds nothing to SKIPPED. For any result but a
# skip (open included) it sets ANSWER_HEADING to the entry's heading text after
# "### " (as written, CR dropped; "Q-NNN · SLUG" by the questions grammar),
# else empties it; a caller that reads it (build-loop.sh --approved) calls
# check_answer in its own shell, its output to a file.
ANSWER_HEADING=""
# shellcheck disable=SC2034  # ANSWER_HEADING is read by the caller
check_answer() {
  local - a="$1" f e r hit="" where="" n why head=""; set -o pipefail  # as brief_fields
  ANSWER_HEADING=""
  if [[ ! "$a" =~ ^Q-[0123456789]+$ ]]; then echo "skip ${a//$'\n'/ }: not a question ID (Q- and digits)"; return; fi
  if ! main_by_name; then echo "skip $a: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run"; return; fi
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    e="$(main_entry "$f")"
    case "$e" in
      absent) continue ;;
      blob) ;;
      *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;
    esac
    # A failed read is a skip, never a fall-through to the other file.
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
      || { echo "skip $a: $f could not be read from the default branch"; return; }
    [[ -n "$r" ]] || continue
    if [[ "$r" == dup ]]; then echo "skip $a: more than one entry with this heading in $f"; return; fi
    case "$r" in
      odd\ *) read -r _ n why <<<"$r"; echo "skip $a: line $n of $f $(oddwhy "$why"), so no entry in $f is read"; return ;;
      unbalanced\ *) echo "skip $a: the code fence opened at line ${r#unbalanced } of $f is never closed, so no entry in $f is read"; return ;;
      quoted\ *) echo "skip $a: line ${r#quoted } of $f is a question heading inside a code fence (questions.sh archive splits entries there), so no entry in $f is read"; return ;;
    esac
    if [[ -n "$hit" ]]; then echo "skip $a: an entry with this heading in both $where and $f"; return; fi
    hit="${r%%$'\n'*}"; head="${r#*$'\n'}"; where="$f"
  done
  if [[ -n "$hit" ]]; then ANSWER_HEADING="$head"; echo "$hit $a"
  else echo "skip $a: no such entry in docs/working/questions.md or questions-archive.md on the default branch"; fi
}
