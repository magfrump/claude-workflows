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
# The import walks also need python3 when a file they read holds text that is
# not well-formed UTF-8; without it they fail closed (every path is refused).
# The caller sets -euo pipefail (check_answer, brief_fields, tree_starts,
# imported_names and main_imports also set
# pipefail for themselves), cds to the repo root and sets ROOT_REAL (that root,
# symlinks resolved) before calling any file check. inrepo, dirok, skipped,
# check_brief, isimported, truthwalk (for tree or main), floor and the import walks exit 1 (need_root) unless
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
# Every script that calls scrub_reexec shares its DEV_CYCLE_SCRUBBED marker.
# Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields
# read the default branch's commit, never the working tree (check_brief also
# refuses a brief path that is not plain in the working tree, which the cycle
# writes). main_imports walks main's commit first, listing and checking the
# working tree as it goes, and then reads the working tree's own files (the
# checkout's start files and imported files main lacks, which can only add
# imports or fail it; it needs resolve_main to have found main by name);
# imported_names, checkout_md and main_checkout read the working tree at ROOT_REAL.
# Both walks also read the repository's worktree registry (import_readers),
# and reader_settings reads docs/dev-cycle.md from the default branch's commit.
#
# The gate caller contract, for floor and main_imports (the one statement of
# it; plan step 5's U2b bullet and known issue A5 point here; override row 459):
#  1. Run as above, with main found by name, under LC_ALL=C (under a UTF-8
#     locale a non-UTF-8 name on main fails the walk).
#  2. Walk a clean worktree at MAIN_SHA, final before the walk (the walk reads
#     main's blob for every path main stores, and the checkout only where main
#     lacks a path), where git ls-files prints nothing on stderr (any fails the
#     walk), under the git environment the override log names (GIT_INDEX_FILE,
#     GIT_WORK_TREE, fsmonitor, sparse checkout, core.ignoreCase, replace refs).
#  3. Refuse a checkout whose core.symlinks is false or with a
#     working-tree-encoding, filter or ident attribute on any path the walk
#     reads (.gitattributes, $GIT_DIR/info/attributes, core.attributesFile).
#     The walk checks neither item but item 2's ls-files stderr rule.
#     build-loop.sh --check does, for each self-merge brief before the walk
#     (U2b2; item 1's LC_ALL=C for the walk is its U2c floor caller's): harden and its state gate own item 2's fsmonitor and replace
#     refs; checkout_gate the rest of item 2 (a clean checkout at MAIN_SHA, the
#     GIT_* variables, core.ignoreCase, sparse checkout), core.symlinks, and
#     the attributes by their effect, not by check-attr: every regular file
#     main stores hashes, unfiltered, to main's blob (so an eol conversion
#     fails it too, and an attribute that changes no bytes does not).
#  4. Call import_reset before each gate decision and after any checkout
#     change (rows 372, 439), or when IMPORT_OUT_MAX or IMPORT_WORK_MAX
#     changes: neither walk's cache key holds them (both hold import_readers'
#     roots and homes, so HOME and IMPORT_READER_* need no reset; the
#     worktree registry is read again after a reset or when one of those
#     changes, so set them before a decision's first walk: item 9).
#  5. Ask floor about each changed path, in this shell, before main_entry,
#     and refuse the whole branch on any main_entry word but blob or absent
#     (rows 308, 324). Floor item 5 (symlinks, gitlinks) and the brief's own
#     Status change are the caller's rules; build-loop.sh's N rules apply
#     them, and pathform, under both policies before floor runs, so a path
#     pathform refuses (.github/x.yml) is denied as a path form and floor's
#     dotfile reason serves the dot paths pathform accepts (.envrc).
#  6. Read a walk only through isimported or truthwalk: IMPORTED_MAIN=error
#     reads as "not imported" to a raw membership test (row 419).
#  7. A second caller of main_checkout passes a fresh MEMO per walk and ENT,
#     and only a PATH main lacks.
#  8. Pass truthrule, isstart, ownfile, prompt_dir and prompt_bases a
#     lower-cased path (prompt_dir and prompt_bases also take the path as
#     spelled; floor, check_fix and the walks lower first; truthrule refuses an
#     upper-case letter as case).
#  9. Call reader_settings after sourcing the lib (which clears the reader
#     lists) and resolve_main, and before a decision's first walk: it sets
#     IMPORT_READER_ROOTS and IMPORT_READER_HOMES from the default branch's
#     docs/dev-cycle.md, never from the environment (the host spellings of the
#     main worktree and the host HOME: import_readers), or IMPORT_READER_WHY,
#     which fails both walks. build-loop.sh and dev-cycle.sh both call it. Never set
#     IMPORT_ROOTS or IMPORT_HOMES: they are import_readers' results.

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
writable() {
  [[ "$1" =~ ^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log)\.md$ \
    || "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]] || anybrief "$1"
}
# Code fences, read only in their plain form, so that every fence this reads is
# read the way CommonMark reads it: a line starting at column 0 with 3 or more `
# or ~ opens one (a ` fence's info string holds no `), and only a column-0 line
# of the same character, at least as long and followed by nothing but spaces or
# tabs, closes it. Any other fence-like line (indented, after a list marker, or
# a column-0 line that neither opens nor, inside a fence, is plain content) is
# ambiguous, and so is anything this reader does not model: outside a fence,
# a line that starts (after spaces or tabs) with < (an HTML block can hold a
# fence line; only a complete one-line <!-- comment --> is read), one that
# opens an HTML comment it does not close, a line starting like a link
# reference definition (after any > and list markers); and anywhere in the
# file, fenced or not, a carriage return inside a line (CommonMark ends a line
# there), a NUL byte (a caller reading the output through $(...) would lose
# it), or a byte-order mark on line 1: fence() records the first one's line number in
# `odd` (and why in `oddwhy`), and the caller refuses the whole file. A fence
# still open at the end is recorded in `fline` (its opening line) and refuses
# the file too.
# Accepted limit (decision log 69): inline constructs that span lines (an open
# tag attribute, link title, code span, emphasis, or a processing instruction,
# CDATA section or declaration opened mid-line) are not modelled, so text
# CommonMark would hide inside them is read as text. Whoever can write such a
# shape can write the answer or Status line itself; no real file has one.
# shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal
FENCE_AWK='
function run(l, ch,   n) { n = 0; while (substr(l, n + 1, 1) == ch) n++; return n }
function fenceish(l) { return l ~ /^[ \t]*(([-*+]|[0123456789]+[.)])[ \t]+)?(```|~~~)/ }
function rawhtml(l) { return l ~ /^[ \t]*</ && !(l ~ /^[ \t]*<!--/ && index(l, "-->")) }
function opencomment(l,   n, p) {  # the last <!-- on the line has no --> after it
  n = split(l, p, /<!--/)  # one linear pass; <!-- cannot overlap itself
  return n > 1 && !index(p[n], "-->")
}
function refdef(l) {  # also behind any number of blockquote and list markers
  # One anchored match strips every leading blank, > and list marker (a loop of
  # sub() calls rebuilt the line per marker: quadratic on a line of markers).
  if (match(l, /^([ \t>]|[-*+][ \t]|[0123456789]+[.)][ \t])*/)) l = substr(l, RLENGTH + 1)
  # Any line starting [ that holds ]: or never closes its [ with an unescaped ]
  # (a label that continues on the next line) counts; escapes are dropped first.
  if (substr(l, 1, 1) != "[") return 0
  gsub(/\\./, "", l)
  return index(l, "]:") || !index(l, "]")
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
  if (rawhtml(l)) { refuse("html"); return 1 }
  if (opencomment(l)) { refuse("comment"); return 1 }
  if (refdef(l)) { refuse("refdef"); return 1 }
  return 0
}
'
oddwhy() {  # the reason fence() refused a file, for a skip line
  case "$1" in
    html) echo "starts with < after any blanks (a possible raw HTML block; only a complete one-line <!-- comment --> is read)" ;;
    comment) echo "opens an HTML comment that does not close on the same line" ;;
    refdef) echo "starts like a link reference definition (its label or title can span lines)" ;;
    cr) echo "holds a carriage return that does not end it" ;;
    nul) echo "holds a NUL byte" ;;
    bom) echo "starts with a byte-order mark" ;;
    *) echo "is a fence-like line that is not a plain column-0 fence" ;;
  esac
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
# One pass over docs/dev-cycle.md (build-loop.sh's read_settings and
# reader_settings): per key, how many lines start with it once everything but
# letters is dropped and case folded (best effort: most markup, a BOM or a
# misplaced colon cannot hide a copy), the first two line numbers, whether the
# next line outside a fence after the first is blank or the end of the file
# (NEXT 1) or not, and the first line whole: "KEY COUNT FIRST SECOND NEXT<TAB>LINE".
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
# readerform PATH: a path the reader settings may name: absolute, of NAMECHARS
# alone (so no blank or control byte: U2b3a final security 3), not / alone,
# with no empty, . or .. part.
readerform() {
  local rest="${1#/}/" c
  [[ "$1" == /?* && "$1" =~ ^[$NAMECHARS]+$ ]] || return 1
  while [[ -n "$rest" ]]; do c="${rest%%/*}"; rest="${rest#*/}"; [[ -n "$c" && "$c" != . && "$c" != .. ]] || return 1; done
}
# reader_settings: the reader lists both walks take (caller contract item 9),
# from the default branch's docs/dev-cycle.md, which no loop can write:
# "Reader roots: PATH ..." names the host spellings of the repository's main
# worktree (the first git worktree list entry; import_readers re-spells the
# worktrees registered beneath it under each one), and "Reader homes: PATH ..."
# the homes of sessions on a host the container cannot see; "...: none" names
# none. Each key is one line, as "Self-merge never:" is: exact, single spaces,
# the next line outside a fence blank or the end, each PATH in readerform and
# listed once. Sets IMPORT_READER_ROOTS and IMPORT_READER_HOMES, and
# READERS_LINE (--settings' readers line). No file and no line add no reader. A
# file main_file does not read, a second copy of a key or a malformed line
# sets IMPORT_READER_WHY instead, which import_readers refuses, so both walks
# fail: the floor refuses every path and --check-fix skips. Without main found
# by name there is no settings source, so the lists stay empty. Call it in the
# caller's shell, once main is resolved.
READERS_LINE=""; IMPORT_READER_WHY=""
# shellcheck disable=SC2034  # READERS_LINE: read by build-loop.sh --settings
reader_settings() {
  local f=docs/dev-cycle.md l k c l1 l2 nx key t v p i why="" nr=0 nh=0 ps=()
  local -A cnt=() first=() second=() next=() text=() rd_seen=()
  IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""; IMPORT_READER_WHY=""
  if ! main_by_name; then READERS_LINE="readers none: no default branch found by name"; return 0; fi
  if ! main_file "$f" "$SETTINGS_AWK"; then
    if [[ "$FILE_WHY" == absent ]]; then READERS_LINE="readers none: no $f on the default branch"; return 0; fi
    why="$FILE_WHY"
  else
    while IFS= read -r l; do
      [[ -n "$l" ]] || continue
      read -r k c l1 l2 nx <<<"${l%%$'\t'*}"
      cnt[$k]="$c"; first[$k]="$l1"; second[$k]="$l2"; next[$k]="$nx"; text[$k]="${l#*$'\t'}"
    done <<<"$FILE_OUT"
    for k in roots homes; do
      [[ -n "${cnt[$k]-}" && -z "$why" ]] || continue
      key="Reader $k:"; t="${text[$k]}"; v="${t#"$key" }"
      if [[ "${cnt[$k]}" -gt 1 ]]; then why="more than one line starts \"$key\" (lines ${first[$k]} and ${second[$k]})"
      elif [[ "$t" != "$key "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then why="line ${first[$k]} is not exactly \"$key PATH ...\" with single spaces"
      elif [[ "${next[$k]}" != 1 ]]; then why="line ${first[$k]} is followed by a non-blank line outside a fence (it may continue the list)"
      elif [[ "$v" != none ]]; then
        IFS=' ' read -ra ps <<<"$v"; i=0; rd_seen=()  # not a bare $v: the shell would expand * and ?
        for p in "${ps[@]}"; do
          i=$((i + 1))
          if ! readerform "$p"; then why="line ${first[$k]} lists entry $i, which is not an absolute path of letters, digits and . _ - / with no empty, . or .. part"; break; fi
          if [[ -n "${rd_seen[$p]-}" ]]; then why="line ${first[$k]} lists entry $i twice"; break; fi
          rd_seen[$p]=1
          if [[ $k == roots ]]; then IMPORT_READER_ROOTS+="$p"$'\n'; nr=$((nr + 1)); else IMPORT_READER_HOMES+="$p"$'\n'; nh=$((nh + 1)); fi
        done
      fi
    done
  fi
  if [[ -n "$why" ]]; then
    IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""; IMPORT_READER_WHY="$why"
    READERS_LINE="readers malformed: $why, so both import walks fail"; return 0
  fi
  IMPORT_READER_ROOTS="${IMPORT_READER_ROOTS%$'\n'}"; IMPORT_READER_HOMES="${IMPORT_READER_HOMES%$'\n'}"
  if [[ -z "${cnt[roots]-}${cnt[homes]-}" ]]; then READERS_LINE='readers none: no line starts "Reader roots:" or "Reader homes:"'
  else READERS_LINE="readers $nr-roots $nh-homes set: $f on the default branch"; fi
}
# Instruction-file basenames, lower-cased: CLAUDE.md, CLAUDE.local.md,
# AGENTS.override.md and the like, GEMINI.md, SKILL.md. (A variable, quoted:
# written inline, the hermeticity lint reads the alternation as a command.)
INSTRUCTION_FILE='^(claude|agents?|gemini)(\.[abcdefghijklmnopqrstuvwxyz0123456789_-]+)?\.md$|^skill\.md$'
# The one start rule both walks use (U2a4), for a lower-cased path: an
# instruction file's name, or a .md file at any depth under a .claude/
# directory's rules/ (memory, whose names resolve against the file's own
# directory) or PROMPT_DIR's commands/, agents/, output-styles/ or skills/ (a
# command's @ names load when it runs, resolved against the session's
# directory: U2a3b L2-confirm security F2; the other three are untraced, read
# as a superset). truthrule refuses the same names; instruction_names is its
# grep prefilter, and a test holds the two equal.
PROMPT_DIR='(^|/)\.claude/(commands|agents|output-styles|skills)/'
# A start directory, any path below one, or .claude itself: main_imports
# refuses a link or gitlink there unless it is a symlinked start.
START_LINK='/\.claude(/(rules|commands|agents|output-styles|skills)(/.*)?)?$'
isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] || [[ "$1" == *.md && ( "$1" =~ $PROMPT_DIR || "/$1" == */.claude/rules/* ) ]]; }
# prompt_dir MAP LP PATH: for a start under PROMPT_DIR (LP lower-cased, PATH as
# spelled), MAP[PATH] gets LP, so a walk knows to read it against prompt_bases.
# shellcheck disable=SC2034  # pd_m is the caller's map, set by name
prompt_dir() { local -n pd_m="$1"; [[ ! "$2" =~ $PROMPT_DIR ]] || pd_m[$3]="$2"; }
# prompt_bases NAME LP PATH: array NAME gets the directories a prompt start
# also resolves its names against, where a session reading it may have
# started: the top level and the one holding each .claude/ in its path (a
# nested one too: U2a4 i1 security F3), as PATH spells them, once each. Not
# covered: a session started anywhere else (U2b's reader model).
prompt_bases() {
  local -n pb_a="$1"; local c n=0 parts=()
  pb_a=("")
  # Whole components, so .claude/.claude/ keeps both bases and .claudex is none (U2a4 i2 fact-check 1, final fact-check 31).
  IFS=/ read -r -a parts <<<"$2"
  for c in "${parts[@]}"; do
    [[ "$c" != .claude || $n -eq 0 ]] || pb_a+=("${3:0:n-1}")
    n=$(( n + ${#c} + 1 ))
  done
}
# Paths, lower-cased, that instruction files pull in with an @ import (Claude
# Code's "@path" syntax), followed transitively: such a file is read as
# instructions, so an in-cycle fix never edits it. The walk starts at every
# start file in the checkout (isstart), tracked or not (CLAUDE.local.md is usually
# gitignored), resolves each @path against the importing file's directory (and a prompt's also against prompt_bases') as
# Claude Code does (import_targets reads a superset of its names, ~/ against
# every reader home, and drops paths outside every reader root: import_readers), and reads each plain file it reaches once. It returns 1, with IMPORTED set to "error", when the start
# listing (git ls-files, untracked_md, instruction_names), lower, a file read,
# import_readers or the parser (its comment lists why) fails, the IMPORT_OUT_MAX
# or IMPORT_WORK_MAX budget is spent, or a start file's name holds a newline (its callers in scripts/ test it under if or ||, where set -e is off); an
# inrepo_here that fails skips its path. One result is cached, for the root in
# IMPORTED_DONE, keyed on import_readers' roots (ROOT_REAL first) and homes; a
# call for another reader set recomputes it, and a cached error returns 1 again.
# main_imports walks the default branch's commit instead, for the gate: it starts
# at every start file stored there (isstart) and follows an import
# into the file main stores at that path, whatever its name; a symlink there is
# followed to the path its text names. Once main's walk is done, a second phase
# walks the checkout's start files main lacks (untracked, ignored or only in
# the index) and the imported files main lacks, when each is a plain file
# there, and only appends. It refuses what it does not model, as FENCE_AWK does: a name
# listed twice or as both a file and a directory, a name holding a newline,
# symlink text that is empty, absolute, leaves
# the repo, holds a newline or a NUL, or has a .. after a symlink (on main or
# in the checkout), a prompt start (prompt_dir) main stores as a symlink, a
# link or gitlink main stores at or below a .claude/ start directory or at
# .claude (START_LINK) unless it is a symlinked start, a link to a directory
# or a gitlink, and a checkout path it would walk (a start or an import
# main lacks) that lies under a directory main stores as a symlink or gitlink
# or under any checkout ancestor but a plain searchable directory (absent
# ones and plain files excepted: nothing below them loads), or that the
# checkout holds as anything but a readable plain file, a plain directory or
# nothing (the root included),
# or a checkout listing git prints any stderr for, fail the walk, so isimported main
# answers imported for every path. A linked worktree's .git file and files
# under .git are checkout files like any other. A start file answers imported only when an import reaches it
# (floor refuses start files by truthrule). Not covered (known issue
# A5): start files under a symlinked directory or in a submodule or untracked
# nested repo, other names one file has on a case-insensitive checkout,
# checkout conversions (A5), a prompt read by a session started outside
# prompt_bases' directories, and a start that is not a regular file or
# symlink (git does not list a FIFO). The walk reads the checkout as one
# snapshot: a file swapped between its admission and its read is not seen.
# IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for
# the commit, MAIN_BY_NAME and import_readers' roots and homes in
# IMPORTED_MAIN_DONE, never the checkout, whose files it read, so a caller
# whose checkout may have changed calls import_reset (contract item 4); a
# cached error returns 1 again.
# Neither walk starts at an instruction file outside the repo, though Claude
# Code loads them and follows their imports into it: a parent directory's
# CLAUDE.md, the user's memory file (known issue A5; U2b3b2's outside starts),
# nor at a start file only another registered checkout holds (U2b3b2).
# isimported asks either walk.
IMPORTED=error; IMPORTED_DONE=""; IMPORTED_MAIN=error; IMPORTED_MAIN_DONE=""
# import_reset: the next call of either walk walks again (caller contract item 4).
import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; IMPORT_READERS_DONE=""; }
# Each walk fails once import_targets has printed more than this in all
# (characters, newlines between names counted; awk counts bytes, so it may stop
# first): the parser's work bound is per file, while the bash side's cost grows
# with everything printed (performance L2 F2). A fresh clone's walks print about
# 2 KB, /workspace's about 6 KB. A caller that changes it calls import_reset.
IMPORT_OUT_MAX=4000000
# Each walk also fails once the parser's work (the candidate and comment-splice
# characters it scans, each resolved spelling it joins, which for a
# relative name carries a root, so a longer root buys less, and one unit per
# reader root for each spelling it projects; the unit of its per-file bound
# of 50,000,000, up to about 5 s here with one root and about 9 s with 24, by
# the name's shape: U2b3a i2 fact-check) passes this in all, so N adversarial files cost one bound of charged parser
# work, not N (U2a3b L2-confirm performance P2); reading, draining and the scan
# of @-less lines (but those read while a quote is open) are not charged (L2-C7, U2a3c i2 performance F3). /workspace's walks spend about 330,600 each over its 24 reader roots (8,200 with one; 2026-10-08).
# That work grows with the square of the root count (each relative name is
# joined once per root, and each join is projected against every root), so
# the honest walks spend this bound near 570 roots and then fail closed:
# prune the registry (git worktree prune) long before (U2b3a i2 performance F1).
# Each caller root re-spells the worktrees under the main worktree, so one
# host alias about doubles the count (49 roots here: 1.5 s per walk, U2b3b1).
# A quote left open is charged per line for all its text so far, so an
# unclosed @" followed by about 90 KB with no " spends the bound and fails
# the walk (fail-closed; U2a4 confirm2 security C1, override row).
# The bound is per walk: a caller that runs both walks pays up to two. A caller
# that changes it calls import_reset.
IMPORT_WORK_MAX=50000000
# UTF-8 spaces, which end an import token as a blank does (import_targets makes
# each one a blank first): U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F,
# U+205F, U+3000 and U+FEFF (Claude Code's token ends at JavaScript's \s).
UNI_SPACES=($'\xc2\xa0' $'\xe1\x9a\x80' $'\xe2\x80\x80' $'\xe2\x80\x81' $'\xe2\x80\x82' $'\xe2\x80\x83' $'\xe2\x80\x84'
  $'\xe2\x80\x85' $'\xe2\x80\x86' $'\xe2\x80\x87' $'\xe2\x80\x88' $'\xe2\x80\x89' $'\xe2\x80\x8a' $'\xe2\x80\xa8'
  $'\xe2\x80\xa9' $'\xe2\x80\xaf' $'\xe2\x81\x9f' $'\xe3\x80\x80' $'\xef\xbb\xbf')
lower() { printf '%s' "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'; }
# The import targets in the text on stdin, for a file in directory $1 ("" at
# the top level), a relative name resolved against $1 and against each further
# directory given (a prompt's session directories: prompt_bases): one
# repo-relative path per line, case kept, each once. It
# also reads ROOT_REAL, HOME (through import_home, which sets the IMPORT_HOME*
# globals in the caller's shell unless called in a subshell), import_readers'
# IMPORT_ROOTS and IMPORT_HOMES when its memo key is current (else ROOT_REAL
# alone and import_home's home: a call outside a walk), and IMPORT_LEFT
# (what may still be printed; IMPORT_OUT_MAX when unset or empty, and as awk
# reads a number otherwise: its numeric prefix (so 1e3 is 1000 and inf no
# bound), or 0, so the first name fails it) and IMPORT_WORK_LEFT (set by a
# walk: what its IMPORT_WORK_MAX has left, which then also caps the per-file
# work bound, and a last line "/N" reports the work spent; import_work reads
# it. Unset or empty: no trailer and only the per-file bound; otherwise read
# as IMPORT_LEFT is). Both walks pass numbers. Every import walk shares these
# rules, so a change here changes --check-fix too.
# The superset claim (the one statement of it; known issue A5 and plan F11
# point here): these rules read every name Claude Code 2.1.292 can import (its
# import regex and Markdown lexer: U2a2 and U2a3b security reviews), failing
# toward "imported" rather than modelling where Markdown ends a name. Every @
# in a line starts a candidate, whatever precedes it and inside code spans and
# fences too; each prefix of the run after it, up to the first blank (a NUL or
# a UNI_SPACES space counts as one), is a candidate name, with a
# backslash-escaped space read as a space. After @" the quoted text is also
# read whole, to its closing quote on that line or a later one (the
# prompt-mention reader of Claude Code 2.1.293, @"([^"]+)", that a command's
# names go through: U2a4; untraced whether command expansion calls it). A
# line holding <!-- is also read
# with its closed HTML comments removed (Claude Code splices them), and text
# holding a byte above 0x7f is also read decoded as Claude Code decodes it (an
# invalid UTF-8 sequence becomes U+FFFD). Each candidate is trimmed of spaces,
# made absolute (ROOT/DIR/name for each reader root, $1 and each further directory, unless
# it starts with /) and resolved
# lexically, .. stopping at / as Node's path.resolve does, so a name that
# leaves the repo and re-enters it is kept; it is kept only when it lies below
# a reader root (import_readers: ROOT_REAL, every registered worktree, the
# caller's IMPORT_READER_ROOTS), and printed relative to each root holding
# it but an outer one whose path down to a nested root holding it has a dot
# component (the parser's dotnest; truthrule's dot word must keep refusing
# every such path). A relative name is resolved against each root's copy of its
# directory, so a name a session in any checkout spells is resolved as it
# would be there (its start files are another matter: below), and a ~/ name is joined
# to each reader home (this process's and IMPORT_READER_HOMES), in spelled and
# real forms. Known exceptions, where a session reading the file can import
# what these rules do not yield: a session in a checkout or under a home
# import_readers does not list (reader_settings names the host's), a
# start file only another reader root's checkout holds (untracked or ignored
# there, such as /workspace's devcontainer-config/claude-home/CLAUDE.md: the
# walks read the gate's own checkout only; U2b3b2), names
# that differ only in case on a case-insensitive file
# system (docs/reviews/override-log.md line 350), Claude Code's approved
# external includes, and any further decoding it may add (an entity, a percent
# escape). The cost is false positives: a prefix that is itself a file counts
# as imported, and so does a
# name led by an escaped space.
# It returns 1 when sed, python3, awk or import_home fails, when ROOT_REAL is
# empty, when a ~/ name appears and the home is not absolute, or when the
# candidates and comment splices run past a work bound or print past
# IMPORT_LEFT (so a pathological file fails the walk rather than stalling it).
# Re-check the superset when Claude Code changes its import grammar or its
# prompt-mention reader, how its
# runtime reads an empty or unset HOME, or how it decodes invalid UTF-8
# (test/agents-gemini-sync.bats holds a separate, older finder for where an
# import starts, not these rules).
# shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal
IMPORT_AWK='
function emit(c, keep,   i, r) {
  work += length(c); if (work > wmax) exit 3
  # Claude Code trims the name; it rejects a name led by a space first, so
  # trimming one only over-reads. KEEP skips the trim (a quoted name, below).
  if (!keep) { sub(/^ +/, "", c); sub(/ +$/, "", c) }
  if (c == "") return
  # ~/ joins the home directory (Claude Code: path.join(os.homedir(), rest)),
  # for each reader home (the home of this process first), each in its spelled
  # and real forms, since a root may be spelled either way.
  if (substr(c, 1, 2) == "~/") {
    if (substr(homes[1], 1, 1) != "/") exit 4
    for (i = 1; i <= nh; i++) if (homes[i] != "") put(homes[i] "/" substr(c, 3))
    return
  }
  if (substr(c, 1, 1) == "/") { put(c); return }
  # A session in any checkout resolves the name against its own copy of the
  # directory, so a .. can re-enter a sibling or nested worktree (U2b3a).
  for (r = 1; r <= nr; r++) for (i = 0; i <= nd; i++) put(roots[r] "/" dirs[i] "/" c)
}
function put(c,   n, i, j, k, part, st, out, h, nho) {
  # The resolved spelling is what costs (its length grows with the depth of
  # the importing file), so it is charged too, and each is resolved once per file.
  work += length(c); if (work > wmax) exit 3
  if (c in tried) return
  tried[c] = 1
  n = split(c, part, "/"); k = 0
  for (i = 1; i <= n; i++) {
    if (part[i] == "" || part[i] == ".") continue
    if (part[i] == "..") { if (k > 0) k--; continue }
    st[++k] = part[i]
  }
  out = ""; for (i = 1; i <= k; i++) out = out "/" st[i]
  # A quoted text that spans lines can resolve to a name holding a newline,
  # which no file a walk admits has (and a printed one would split in two).
  if (index(out, "\n")) return
  # Relative to every root holding it, but an outer root whose path down to a
  # nested root holding it has a dot component (dotnest): a session in a
  # worktree under /workspace/.claude/ reads the file there as a path of that
  # worktree, and the outer spelling is a dot path the floor refuses whole
  # (the dot word of truthrule: narrowing it means changing this rule too),
  # while a root nested at any other path (a stale registry entry at sub/)
  # must not take the outer path from the walk (U2b3a i1 security 1). The
  # loop over the roots is charged as work too (i1 performance F2).
  work += nr; if (work > wmax) exit 3
  nho = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i])) h[++nho] = i
  for (i = 1; i <= nho; i++) {
    for (j = 1; j <= nho; j++) if ((h[i], h[j]) in dotnest) break
    if (j > nho) show(substr(out, length(pre[h[i]]) + 1))
  }
}
function show(out) {
  if (out in seen) return
  # printed counts as the walks count: each name, a newline between names.
  seen[out] = 1; printed += length(out) + 1; if (printed - 1 > left) exit 3
  print out
}
# scan LINE CARRY: every candidate in LINE. A mention in a command may be quoted
# (@"docs/a b.md": the prompt-mention reader of Claude Code 2.1.293, @"([^"]+)",
# which spans lines): the run after the quote is read as an unquoted one, and
# the whole quoted text once, at its closing quote on this line or, when CARRY
# is set, a later one (qo marks an open quote, even an empty one, and qopen
# holds its text; each held line and each copy of qopen is charged as work), so
# prefixes never grow past a blank (U2a4 i1 security F1; final security F2,
# performance F1; confirming security F2, F4).
function scan(line, carry,   i, L, k, r) {
  L = length(line)
  for (i = 1; i <= L; i++) {
    if (substr(line, i, 1) != "@") continue
    names(line, i + 1, L)
    if (substr(line, i + 1, 1) != "\"") continue
    names(line, i + 2, L)
    r = substr(line, i + 2); work += length(r); if (work > wmax) exit 3
    k = index(r, "\"")
    if (k > 1) quoted(substr(r, 1, k - 1))
    else if (k == 0 && carry) { qo = 1; qopen = r }
  }
}
# quoted TEXT: Claude Code reads a mention through its file-name parser, which
# drops a #L5, #L2-9 or #section suffix (confirming security F1), and may not
# trim it (untraced): read the text whole and before its first #, each trimmed
# and as written.
function quoted(q,   h) {
  emit(q); emit(q, 1)
  h = index(q, "#"); if (h > 1) { emit(substr(q, 1, h - 1)); emit(substr(q, 1, h - 1), 1) }
}
function names(line, j, L,   ch, name) {
  name = ""
  for (; j <= L; j++) {
    ch = substr(line, j, 1)
    if (ch == "\\" && substr(line, j + 1, 1) == " ") { ch = " "; j++ }
    else if (ch == " " || ch == "\t" || ch == "\r") break
    name = name ch; emit(name)
  }
}
function splice(line,   o, i, j, r) {
  o = ""
  while ((i = index(line, "<!--")) > 0) {
    r = substr(line, i + 4); work += length(r); if (work > wmax) exit 3
    j = index(r, "-->"); if (j == 0) break
    o = o substr(line, 1, i - 1); line = substr(r, j + 3)
  }
  return o line
}
BEGIN {
  # IT_XDIRS: the further directories, each led by an x so "" survives split.
  nd = split(ENVIRON["IT_XDIRS"], dirs, "\n"); for (i = nd; i >= 1; i--) dirs[i] = substr(dirs[i], 2)
  dirs[0] = ENVIRON["IT_DIR"]
  # IT_ROOTS and IT_HOMES: newline-separated, ROOT_REAL and the home of this process first (import_readers).
  nr = split(ENVIRON["IT_ROOTS"], roots, "\n"); if (nr == 0 || roots[1] == "") exit 2
  for (i = 1; i <= nr; i++) pre[i] = (roots[i] == "/") ? "/" : roots[i] "/"
  for (i = 1; i <= nr; i++) for (j = 1; j <= nr; j++)
    if (length(pre[j]) > length(pre[i]) && index(pre[j], pre[i]) == 1 && index("/" substr(pre[j], length(pre[i]) + 1), "/.")) dotnest[i, j] = 1
  nh = split(ENVIRON["IT_HOMES"], homes, "\n")
  left = ENVIRON["IT_LEFT"] + 0
  wmax = 50000000; trail = (ENVIRON["IT_WORK"] != ""); if (trail && ENVIRON["IT_WORK"] + 0 < wmax) wmax = ENVIRON["IT_WORK"] + 0
}
{
  if (qo) {
    # The append copies qopen, so that copy is charged too: a quote left open
    # over many lines fails the bound rather than running quadratic time.
    work += length($0) + length(qopen); if (work > wmax) exit 3
    k = index($0, "\""); if (k) { quoted(qopen "\n" substr($0, 1, k - 1)); qo = 0; qopen = "" } else qopen = qopen "\n" $0
  }
  # The spliced line may open a quote the raw one does not.
  scan($0, 1); if (index($0, "<!--")) scan(splice($0), !qo)
}
END { if (trail) print "/" (work + 0) }'
# Well-formed UTF-8 (RFC 3629: no overlongs, surrogates or code points past
# U+10FFFF), as an awk ERE for a C-locale awk -v: it agreed with python3's
# decoding on 20,013 cases (U2a3b L2-i2 performance F1). Only text it rejects
# forks python3, since well-formed text decodes to itself.
UTF8_WELL_FORMED='^([\001-\177]|[\302-\337][\200-\277]|\340[\240-\277][\200-\277]|[\341-\354\356\357][\200-\277][\200-\277]|\355[\200-\237][\200-\277]|\360[\220-\277][\200-\277][\200-\277]|[\361-\363][\200-\277][\200-\277][\200-\277]|\364[\200-\217][\200-\277][\200-\277])*$'
# import_home: IMPORT_HOME and IMPORT_HOME_REAL (its real path) for the
# parser's ~/ names, from HOME as Claude Code's runtime (Bun) reads it: unset
# or empty, the passwd entry (Node would read an empty HOME as ""). A walk
# calls it once, so the parser's $(...) calls inherit it; it recomputes only
# when HOME itself changes (IMPORT_HOME_DONE holds a key for the HOME it was
# computed for: whether it was set, and its value). A relative home is kept, and the parser fails on a ~/ name then.
IMPORT_HOME=""; IMPORT_HOME_REAL=""; IMPORT_HOME_DONE=""
import_home() {
  local h hr="" key="x${HOME+set}:${HOME-}"
  [[ "$IMPORT_HOME_DONE" != "$key" ]] || return 0
  h="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}" || h=""
  if [[ "$h" == /* ]]; then hr="$(realpath -m -- "$h")" || return 1; fi
  IMPORT_HOME="$h"; IMPORT_HOME_REAL="${hr:-$h}"; IMPORT_HOME_DONE="$key"
}
# import_readers: the reader model's roots and homes (plan step 5, U2b3a),
# which both walks take before their cache check and key on. IMPORT_ROOTS
# holds ROOT_REAL, every path git worktree list registers for this repository
# (prunable ones too: a host path such as /home/magfrump/cw-egress-verify),
# each IMPORT_READER_ROOTS entry and, beneath each such entry, every
# registered worktree that lies beneath the main worktree (the first record),
# re-spelled there; IMPORT_HOMES holds import_home's two spellings and
# IMPORT_READER_HOMES. Each is newline-separated, ROOT_REAL or this process's
# home first, and lists every entry as written and as realpath -m reads it,
# once; an empty ROOT_REAL returns 1. IMPORT_READER_ROOTS and IMPORT_READER_HOMES are the caller's
# (contract item 9; reader_settings sets them): newline-separated absolute paths, blank lines skipped,
# for the host checkout Q-123 names and the host HOME, since sessions there
# spell this repository through them. Sourcing the lib clears them, so the
# environment never sets them. The parser prints a name relative to every
# root holding it but a dot-nested outer one (its comment says why), so a
# root can add names and hide only dot paths. It returns 1 when
# IMPORT_READER_WHY is set (reader_settings refused the settings), import_home
# or the listing fails, or a root or a caller's home is not absolute, holds a
# newline, or is / alone as written or as realpath reads it (every path would
# project into the repo). This process's own home is kept as the parser takes
# it (a relative one fails only a ~/ name), but one holding a newline is read
# as empty, which fails only a ~/ name too.
# The result, a refusal included, is memoized in IMPORT_READERS_DONE, keyed on
# ROOT_REAL, HOME, the caller's two lists and IMPORT_READER_WHY, until
# import_reset (contract item 4): the registry
# is read once per decision, so one decision sees one root set and a cache
# hit forks nothing here (U2b3a i1 performance F1, architecture F6).
# Not covered: a hostile loop can rewrite the worktree registry in the shared
# common dir, dropping a root (a Q-103 residual).
IMPORT_ROOTS=""; IMPORT_HOMES=""; IMPORT_READERS_DONE=""; IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""
# import_readers_key: IMPORT_READERS_KEY, the key import_readers memoizes on (after
# import_home), each part led by its length so no part can run into the next.
IMPORT_READERS_KEY=""
import_readers_key() {
  local a="${ROOT_REAL:-}" b="$IMPORT_HOME_DONE" c="$IMPORT_READER_ROOTS" d="$IMPORT_READER_HOMES" e="$IMPORT_READER_WHY"
  IMPORT_READERS_KEY="${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d ${#e}:$e"
}
import_readers() {
  local p rs_m="" rs_cr rs_l=() rs_w=() rs_c=() rs_r=() rs_h=() rs_x=() rs_real=() rs_ro=() rs_ho=() i n t; local -A rs_seen=()
  import_home || return 1
  import_readers_key
  # A refusal is memoized too, as an empty IMPORT_ROOTS (a result never is:
  # ROOT_REAL leads it), so a refusing decision lists the registry once (U2b3a final performance F1).
  if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi
  IMPORT_READERS_DONE="$IMPORT_READERS_KEY"; IMPORT_ROOTS=""; IMPORT_HOMES=""
  # ROOT_REAL leads the roots: an empty one would let a registered worktree lead
  # instead. reader_settings' refusal fails the walks.
  [[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1
  nul_list rs_l git worktree list --porcelain -z || return 1
  for p in "${rs_l[@]}"; do [[ "$p" != "worktree "* ]] || rs_w+=("${p#worktree }"); done
  # The first record is the main worktree, which each caller root spells on a
  # host, so the worktrees registered beneath it are spelled beneath each
  # caller root there too (U2b3a i1 architecture F4).
  [[ ${#rs_w[@]} -eq 0 ]] || rs_m="${rs_w[0]}"
  [[ -z "$IMPORT_READER_ROOTS" ]] || mapfile -t rs_c <<<"$IMPORT_READER_ROOTS"
  rs_r=("$ROOT_REAL" "${rs_w[@]}")
  for rs_cr in "${rs_c[@]}"; do
    [[ -n "$rs_cr" ]] || continue
    rs_r+=("$rs_cr"); for p in "${rs_w[@]}"; do [[ -z "$rs_m" || "$p" != "$rs_m"/* ]] || rs_r+=("$rs_cr${p#"$rs_m"}"); done
  done
  [[ -z "$IMPORT_READER_HOMES" ]] || mapfile -t rs_h <<<"$IMPORT_READER_HOMES"
  # The roots and the caller's homes, blank lines dropped, checked and then
  # resolved in one realpath call (a fork per root cost 14 ms over 24 roots).
  for p in "${rs_r[@]}" "${rs_h[@]}"; do
    [[ -n "$p" ]] || continue
    [[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1
    rs_x+=("$p")
  done
  n=${#rs_r[@]}; for p in "${rs_r[@]}"; do [[ -n "$p" ]] || n=$((n - 1)); done
  nul_list rs_real realpath -mz -- "${rs_x[@]}" || return 1
  [[ ${#rs_real[@]} -eq ${#rs_x[@]} ]] || return 1
  for i in "${!rs_x[@]}"; do
    [[ -n "${rs_real[i]//\//}" && "${rs_real[i]}" != *$'\n'* ]] || return 1
    if [[ $i -lt $n ]]; then t=r; else t=h; fi
    for p in "${rs_x[i]}" "${rs_real[i]}"; do
      [[ -z "${rs_seen[$t$p]+set}" ]] || continue
      rs_seen[$t$p]=1; if [[ $t == r ]]; then rs_ro+=("$p"); else rs_ho+=("$p"); fi
    done
  done
  # This process's own homes come first, kept as the parser reads them.
  rs_h=(); for p in "$IMPORT_HOME" "$IMPORT_HOME_REAL"; do [[ "$p" != *$'\n'* ]] || p=""; rs_h+=("$p"); done
  [[ "${rs_h[1]}" != "${rs_h[0]}" ]] || unset 'rs_h[1]'
  for p in "${rs_ho[@]}"; do [[ "$p" == "${rs_h[0]}" || "$p" == "${rs_h[1]-}" ]] || rs_h+=("$p"); done
  printf -v IMPORT_ROOTS '%s\n' "${rs_ro[@]}"; IMPORT_ROOTS="${IMPORT_ROOTS%$'\n'}"
  printf -v IMPORT_HOMES '%s\n' "${rs_h[@]}"; IMPORT_HOMES="${IMPORT_HOMES%$'\n'}"
}
import_targets() {
  local u d toks x="" s=(-e 's/\x0/ /g') LC_ALL=C roots="${ROOT_REAL:-}" homes
  import_home || return 1
  homes="$IMPORT_HOME"$'\n'"$IMPORT_HOME_REAL"
  import_readers_key
  [[ -z "$IMPORT_READERS_DONE" || "$IMPORT_READERS_DONE" != "$IMPORT_READERS_KEY" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }
  [[ $# -lt 2 ]] || x="$(printf 'x%s\n' "${@:2}")"  # the walks refuse a name holding a newline
  for u in "${UNI_SPACES[@]}"; do s+=(-e "s/$u/ /g"); done
  # Two steps, not a pipe: under pipefail awk's success would not hide a sed
  # failure, but a caller without pipefail would.
  toks="$(env LC_ALL=C sed "${s[@]}")" || return 1
  # Claude Code decodes the file as UTF-8 and turns each invalid sequence into
  # U+FFFD, so a name can hold bytes the file does not: read that spelling too
  # (python3's "replace" decoding matched Claude Code 2.1.292 on every sequence
  # probed in the binary: U2a3b L2-final and L2-confirm fact-checks).
  # LC_ALL=C above makes the byte range a byte test.
  if [[ "$toks" == *[$'\x80'-$'\xff']* ]] && ! printf '%s\n' "$toks" | env LC_ALL=C awk -v ok="$UTF8_WELL_FORMED" '$0 !~ ok { exit 1 }'; then
    d="$(printf '%s\n' "$toks" | python3 -I -c 'import sys; sys.stdout.buffer.write(sys.stdin.buffer.read().decode("utf-8", "replace").encode())')" || return 1
    [[ "$d" == "$toks" ]] || toks+=$'\n'"$d"
  fi
  # A pipe, not a here-string: bash writes a long here-string to a temp file,
  # and a failed write would read as no imports.
  # The directories, root and home go through the environment: awk -v would read
  # backslash escapes in them. IMPORT_LEFT, set by a walk, is what its
  # IMPORT_OUT_MAX budget has left, so awk stops there rather than after.
  printf '%s\n' "$toks" | env LC_ALL=C IT_DIR="$1" IT_XDIRS="$x" IT_ROOTS="$roots" IT_HOMES="$homes" \
    IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}" IT_WORK="${IMPORT_WORK_LEFT:-}" awk "$IMPORT_AWK" || return 1
}
# import_work OUT TOTAL: strips the parser's work trailer (its last line, "/N",
# printed when IMPORT_WORK_LEFT is set; a repo-relative name never starts with
# /) from the variable OUT, and adds N to the variable TOTAL. It returns 1 when
# the trailer is missing or TOTAL passes IMPORT_WORK_MAX.
import_work() {
  local -n iw_o="$1" iw_t="$2"; local iw_w="${iw_o##*/}"
  [[ "$iw_w" =~ ^[0123456789]+$ && ( "$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w" ) ]] || return 1
  iw_o="${iw_o%/*}"; iw_o="${iw_o%$'\n'}"
  (( (iw_t += iw_w) <= IMPORT_WORK_MAX ))
}
# Start names among NUL-separated paths on stdin: one grep, before
# the tree walk forks lower and a plain check per path (forking for every tracked
# file took seconds). It matches isstart's names; isstart
# stays the authority. LC_ALL=C makes -i ASCII-only. It returns 0 when no name
# matches and 1 when grep fails (grep's own no-match is 1).
instruction_names() { env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$|(^|/)\.claude/(rules|commands|agents|output-styles|skills)/.*\.md$' || [[ $? -eq 1 ]]; }
# The checkout's untracked and ignored .md files, NUL-separated: --others
# without --exclude-standard already lists ignored files.
untracked_md() { md_ls --others; }
# md_ls ARGS...: git ls-files -z ARGS over the checkout's .md files, any case (the one pathspec).
md_ls() { GIT_LITERAL_PATHSPECS=0 git ls-files -z "$@" -- ':(glob,icase)**/*.md'; }
# nul_list NAME CMD...: array NAME gets CMD's NUL-split output, or is emptied and 1 unless CMD exited 0 and its output was empty or ended in NUL.
nul_list() { local -n nl_a="$1"; shift; mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1); [[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || { nl_a=(); return 1; }; unset 'nl_a[-1]'; }
# lower_all ARGS...: each argument lower-cased and NUL-terminated, in one tr
# (lower would fork per path). Read it through nul_list: a tr that dies after a
# partial flush then fails the list rather than truncating its last name and
# dropping a start (U2a3b final N1).
lower_all() { local -; set -o pipefail; printf '%s\0' "$@" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'; }
# capped_read: the first 4 MiB + 1 bytes of stdin, the one reader both walks
# parse, for checkout files and main's blobs alike. Claude Code skips a file
# over 4 MiB, so reading only its start over-reads at worst, and a huge file a
# prefix candidate names cannot stall a walk (L2 security F2). With the word
# drain (after git cat-file) it reads the rest, so the writer never dies of
# SIGPIPE, which pipefail would report as a failed read (U2a3b L2-C5); an
# argument, not a [[ -p /dev/stdin ]] test, which needs /proc. The drain is
# time the work bound does not charge (git inflates the whole blob).
capped_read() { head -c 4194305 || return 1; [[ "${1:-}" != drain ]] || cat > /dev/null; }
# The tree walk's start candidates, NUL-separated: tracked and untracked names
# through instruction_names, failing when any of the three commands fails.
tree_starts() { local -; set -o pipefail; { git ls-files -z && untracked_md; } | instruction_names; }
# The checkout's .md files, tracked, untracked and ignored, NUL-separated (main_imports'
# phase-2 seeds); fails when git exits nonzero or prints anything on stderr,
# since an unreadable directory goes unlisted with only a warning.
checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }
# main_checkout ENT MEMO PATH, the one admission check for main_imports'
# checkout phase; ENT names the associative array of main's modes by path, and
# MEMO one of the ancestors already decided (a token's prefixes share them, so
# each costs its realpath once per walk: U2a3b L2-C6): d for a plain
# searchable directory, 2 for one absent or a plain file (nothing below it
# loads), set only once its own and every higher ancestor's main mode passed
# (PATH's own mode is checked first: main's link or gitlink at PATH answers 1).
# A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT.
# main_imports calls it only for paths main lacks.
# 0 for a readable plain checkout file to walk, 2 when nothing there loads
# (absent, below an absent ancestor or a plain file, or a plain directory), 1
# to fail the walk: an ancestor main stores as a link or gitlink, an ancestor
# that is anything else but a plain searchable directory, an unreadable plain
# file, ENT or MEMO not an associative array, or anything else at PATH.
# Callers test 1 as a refusal, never as a plain false. The plain tests are
# rawfile's and plaindir's; unlike blocker it answers 2 below a plain file and
# needs a searchable directory (a second traversal on purpose).
main_checkout() {
  local - c="$3" i st=d anc=(); local -n mc_e="$1" mc_m="$2"
  # ${x@a} on an empty array is an unbound-variable error under set -u (an
  # empty main tree, the first call's MEMO); the body reads both through :- and +set.
  # ${x[0]@a}, not ${x@a}, which costs time linear in the array's size (U2a3c
  # final performance F1: quadratic once MEMO grows with the tokens).
  set +u; [[ "${mc_e[0]@a}" == *A* && "${mc_m[0]@a}" == *A* ]] || return 1
  # Main's link or gitlink at PATH refuses before a checkout directory there is memoized as d (U2a3c final fact-check 34).
  [[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1
  # Bottom up to the nearest decided ancestor, then top down from it (U2a3c
  # i2 performance F1: top down alone rescanned every absent ancestor).
  while [[ "$c" == */* ]]; do c="${c%/*}"; if [[ -n "${mc_m[$c]+set}" ]]; then st="${mc_m[$c]}"; break; fi; anc+=("$c"); done
  for ((i = ${#anc[@]} - 1; i >= 0; i--)); do
    c="${anc[i]}"
    [[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1
    if [[ "$st" == d ]]; then
      if [[ ! -e "$c" && ! -L "$c" ]] || rawfile "$c"; then st=2
      elif ! plaindir "$c" || [[ ! -x "$c" ]]; then return 1; fi
    fi
    mc_m[$c]="$st"
  done
  [[ "$st" == d ]] || return 2
  c="$3"; [[ -e "$c" || -L "$c" ]] || return 2
  if rawfile "$c"; then [[ -r "$c" ]]; return; fi
  plaindir "$c" || return 1
  [[ ! -x "$c" ]] || mc_m[$c]=d  # a prefix candidate's directory, which longer ones pass through
  return 2
}
imported_names() {
  local - f d p lp out used=0 work=0 qi=0 seen=$'\n' queue=() recs=() xs=(); set -o pipefail
  local -A pdir=()
  need_root
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }
  # The roots never hold an empty line, so the blank line ends them.
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES" ]] && { [[ "$IMPORTED" != error ]]; return; }
  IMPORTED_DONE="$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"; IMPORTED=error
  nul_list recs tree_starts || return 1
  for f in "${recs[@]}"; do
    # seen is newline-separated: a name holding a newline could hide another start.
    [[ "$f" != *$'\n'* ]] || return 1
    lp="$(lower "$f")" || return 1
    if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi
    [[ "$seen" == *$'\n'"$f"$'\n'* ]] && continue
    seen+="$f"$'\n'; queue+=("$f"); prompt_dir pdir "$lp" "$f"
  done
  IMPORTED=$'\n'
  # An index, not a copy per pop (quadratic in the files read: override row 461).
  while [[ $qi -lt ${#queue[@]} ]]; do
    f="${queue[qi]}"; qi=$((qi + 1)); xs=(); [[ -z "${pdir[$f]+set}" ]] || prompt_bases xs "${pdir[$f]}" "$f"
    if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi
    out="$(capped_read < "$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - work)) import_targets "$d" "${xs[@]}")" \
      && import_work out work || { IMPORTED=error; return 1; }
    [[ -n "$out" ]] || continue
    (( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED=error; return 1; }
    # One lower per file, not per candidate: the superset yields many.
    lp="$(lower "$out")" || { IMPORTED=error; return 1; }; IMPORTED+="$lp"$'\n'
    while IFS= read -r p; do
      # -f first: most candidates name no file, and inrepo_here forks.
      if [[ -f "$p" && "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo_here "$p"; then seen+="$p"$'\n'; queue+=("$p"); fi
    done < <(printf '%s\n' "$out")
  done
}
# The main walk; returns 1, with IMPORTED_MAIN set to "error", so a caller
# refuses rather than reading a partial list, when main is not found by name,
# the commit's tree or the checkout's .md list (tracked and untracked) cannot
# be listed whole (nul_list, checkout_md), a tree record does not parse or has a type but
# blob, link or gitlink, a name is listed twice (git's lookups read the first
# copy), is also a directory of another listed name, or holds a newline, the
# start list's lower_all fails or comes back short, main_checkout refuses a start or an
# import main lacks, a blob or checkout file cannot be read, symlink text it
# follows is empty, absolute, leaves the repo, holds a newline or a NUL, has
# a .. after a symlink, or names a directory or a gitlink, a link or gitlink
# sits where START_LINK matches and is not a symlinked start, import_readers, the parser (its comment lists why) or a
# lower fails, or the IMPORT_OUT_MAX or IMPORT_WORK_MAX budget is spent;
# need_root exits instead.
# Phase 2 begins when queue empties: tq's checkout files then join it, and a
# path main lacks reads the checkout.
main_imports() {
  local - rec f d p i c lk out used=0 work=0 qi=0 queue=() tq=() recs=() cand=() low=() parts=() xs=() links=(); set -o pipefail  # as brief_fields
  # shellcheck disable=SC2034  # pok is main_checkout's MEMO, passed by name
  local -A ent=() seen=() dir=() pok=() pdir=()
  need_root
  import_readers || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; return 1; }
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"
  main_by_name || return 1
  nul_list recs git ls-tree -r -z --full-tree "$MAIN_SHA" || return 1
  for rec in "${recs[@]}"; do
    [[ "$rec" =~ ^([01234567]{6})\ [abcdefghijklmnopqrstuvwxyz]+\ [0123456789abcdef]{40,64}$'\t'(.+)$ ]] || return 1
    f="${BASH_REMATCH[2]}"
    [[ -z "${ent[$f]+set}" && "$f" != *$'\n'* ]] || return 1
    ent[$f]="${BASH_REMATCH[1]}"
    [[ "$f" != *.[mM][dD] ]] || cand+=("m:$f")
    [[ ! "${ent[$f]}" =~ ^1[26]0000$ ]] || links+=("$f")
  done  # then a name that is also a directory of another listed name (a crafted tree) fails:
  for f in "${!ent[@]}"; do c="$f"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ -z "${dir[$c]+set}" ]] || break; [[ -z "${ent[$c]+set}" ]] || return 1; dir[$c]=1; done; done
  # A link or gitlink at or below a .claude/ start directory (or .claude itself)
  # lists its prompts under the target's path, which isstart does not know: not
  # modelled, so it fails (U2a4 final security F1), unless the link is a
  # symlinked start (a rules file is followed, a prompt fails in the read arm);
  # a gitlink start fails too, since a checkout holds it as a directory.
  [[ ${#links[@]} -eq 0 ]] || nul_list parts lower_all "${links[@]}" || return 1
  [[ ${#parts[@]} -eq ${#links[@]} ]] || return 1
  for i in "${!parts[@]}"; do
    [[ ! "/${parts[i]}" =~ $START_LINK ]] || { isstart "${parts[i]}" && [[ "${ent[${links[i]}]}" == 120000 ]]; } || return 1
  done
  nul_list recs checkout_md || return 1
  for f in "${recs[@]}"; do [[ "$f" != *$'\n'* ]] || return 1; [[ -n "${ent[$f]+set}" ]] || cand+=("t:$f"); done
  [[ ${#cand[@]} -eq 0 ]] || nul_list low lower_all "${cand[@]}" || return 1
  [[ ${#low[@]} -eq ${#cand[@]} ]] || return 1
  for i in "${!cand[@]}"; do
    f="${low[i]:2}"
    if isstart "$f"; then
      prompt_dir pdir "$f" "${cand[i]:2}"; f="${cand[i]:2}"; c=0; [[ "${cand[i]:0:1}" == m ]] || main_checkout ent pok "$f" || c=$?
      [[ $c -ne 1 ]] || return 1; [[ $c -eq 0 ]] || continue
      seen[$f]=1; if [[ -n "${ent[$f]+set}" ]]; then queue+=("$f"); else tq+=("$f"); fi
    fi
  done
  IMPORTED_MAIN=$'\n'
  # An index, not a copy per pop, as in imported_names (override row 461).
  while [[ $qi -lt ${#queue[@]} || ${#tq[@]} -gt 0 ]]; do
    [[ $qi -lt ${#queue[@]} ]] || { queue=("${tq[@]}"); tq=(); qi=0; }  # phase 2: main's walk is done
    f="${queue[qi]}"; qi=$((qi + 1)); xs=(); [[ -z "${pdir[$f]+set}" ]] || prompt_bases xs "${pdir[$f]}" "$f"
    if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi
    case "${ent[$f]-checkout}" in
      checkout) out="$(capped_read < "$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - work)) import_targets "$d" "${xs[@]}")" \
          && import_work out work || { IMPORTED_MAIN=error; return 1; } ;;
      100644|100755) out="$(git cat-file blob "$MAIN_SHA:$f" | capped_read drain | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - work)) import_targets "$d" "${xs[@]}")" \
          && import_work out work || { IMPORTED_MAIN=error; return 1; } ;;
      120000)  # a symlink: its text names the file read, as one more import
        # A prompt's names resolve against the session, not its target's directory: not modelled.
        [[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }
        # Link text past PATH_MAX (4096) names nothing; it fails before the two whole reads below.
        i="$(git cat-file -s "$MAIN_SHA:$f")" && [[ "$i" -le 4096 ]] || { IMPORTED_MAIN=error; return 1; }
        # $(...) drops NULs, so they are counted first; the x keeps trailing
        # newlines, which $(...) would also drop.
        if ! i="$(git cat-file blob "$MAIN_SHA:$f" | tr -cd '\0' | wc -c)" || [[ "$i" -ne 0 ]] \
           || ! out="$(git cat-file blob "$MAIN_SHA:$f" && printf x)"; then IMPORTED_MAIN=error; return 1; fi
        out="${out%x}"
        if [[ -z "$out" || "$out" == *$'\n'* || "$out" == /* ]]; then IMPORTED_MAIN=error; return 1; fi
        # realpath -s reads x/.. as nothing, but the kernel follows a symlink
        # x first: a .. after a symlink on main or in the checkout fails.
        lk=""; p="$d"; mapfile -t -d / parts < <(printf '%s' "$out")
        for c in "${parts[@]}"; do
          [[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }
          p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${p:+$p/}$c" 2>/dev/null)" || p=..
          [[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1
        done
        out="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$out" 2>/dev/null)" || out=..
        [[ "$out" != .. && "$out" != ../* ]] || { IMPORTED_MAIN=error; return 1; }
        # A link to a directory or a gitlink would be dropped below, but a
        # loader may read a directory's files (untraced): it fails (confirming security F3).
        # -d reads the checkout, as -L above does (confirm2 security C3).
        [[ -z "${dir[$out]+set}" && "${ent[$out]:-}" != 160000 && ! -d "$out" ]] || { IMPORTED_MAIN=error; return 1; } ;;
      160000) continue ;;  # a gitlink: its files are not main's
    *) IMPORTED_MAIN=error; return 1 ;;
    esac
    [[ -n "$out" ]] || continue
    (( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED_MAIN=error; return 1; }
    # One lower per file, not per candidate, as in imported_names.
    i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }; IMPORTED_MAIN+="$i"$'\n'
    while IFS= read -r p; do
      [[ -n "$p" ]] || continue
      [[ -z "${seen[$p]+set}" ]] || continue
      c=0; [[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p" || c=$?  # main lacks p: admitted before it is marked seen
      [[ $c -ne 1 ]] || { IMPORTED_MAIN=error; return 1; }
      seen[$p]=1
      if [[ -n "${ent[$p]+set}" ]]; then queue+=("$p"); elif [[ $c -eq 0 ]]; then tq+=("$p"); fi
    done < <(printf '%s\n' "$out")
  done
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
  case "$1" in
    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
    tree) imported_names || return 0; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
    *) return 0 ;;
  esac
}
# The read-as-truth rule --check-fix and floor share (plan D5 items 1, 2 and 4;
# build-loop.sh's N rules read its cycle, settings and user words too, so a
# word tested before them must never match a file those words cover:
# override rows 204, 322, 348), for a lower-cased path: returns 0 with
# TRUTH_WHY set when it refuses: instr (isstart: an instruction or prompt
# file), dot (a .-prefixed component, a top-level one included), cycle
# (writable), settings (docs/dev-cycle.md), user (docs/constraints.md, the
# user's: plan D2) or record (docs/decisions/, docs/human-author/), and case
# for a path holding an upper-case letter (a caller that did not lower it).
# Each caller words the words and adds its own rules (docs/thoughts/ is the
# floor's only: a living doc an in-cycle fix may edit). truthwalk then asks
# the import walk. Run both in the caller's shell: they set TRUTH_WHY.
TRUTH_WHY=""
truthrule() {
  TRUTH_WHY=""
  if [[ "$1" == *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]]; then TRUTH_WHY="case"
  elif isstart "$1"; then TRUTH_WHY="instr"
  elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"  # the parser's dotnest omits only such paths: keep the two equal
  elif writable "$1"; then TRUTH_WHY="cycle"
  elif [[ "$1" == docs/dev-cycle.md ]]; then TRUTH_WHY="settings"
  elif [[ "$1" == docs/constraints.md ]]; then TRUTH_WHY="user"
  elif [[ "$1" =~ ^docs/(decisions|human-author)/ ]]; then TRUTH_WHY="record"
  else return 1; fi
}
# truthwalk WALK PATH: runs the import walk WALK (tree for --check-fix, main
# for floor), then asks it about PATH (any case), as isimported WALK PATH does,
# so a caller words a failed walk without knowing the order (override row 418).
# Returns 0 when the walk fails (TRUTH_WHY=walk) or reaches PATH or cannot
# lower-case it (TRUTH_WHY=imported), else 1 with TRUTH_WHY empty; an unknown WALK answers
# walk without running one. For tree or main it exits through need_root.
truthwalk() {
  TRUTH_WHY=walk
  case "$1" in main) main_imports || return 0 ;; tree) imported_names || return 0 ;; *) return 0 ;; esac
  TRUTH_WHY=imported; isimported "$1" "$2" || { TRUTH_WHY=""; return 1; }
}
# A brief's own files, keyed on its full stem $2 (YYYY-MM-DD-slug, so a slug
# shared by two dates is not a collision), for a lower-cased path $1 with
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
# The gate's own code: main's copy runs the next merge (plan D6), so a change
# to it lands only through a merge-gate- review entry, never a self-merge.
GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/'
# The self-merge floor (plan D5 items 1-4): a changed path that a self-merge never lands,
# even when the brief's Paths: lists it, because it takes effect on merge with
# no later review or later runs read it as truth. $1 is the path as the merge
# result stores it, $2 the brief's full stem and $3 the diff-tree status
# letter alone (R for R100; only A makes a review the brief's own).
# Returns 0 with FLOOR_WHY set when the floor refuses, else 1. Paths compare
# lower-cased (a case-insensitive checkout reads Docs/Roadmap.md as
# docs/roadmap.md). The caller's duties are the gate caller contract's (the
# lib's header): floor item 5, symlinks and gitlinks, is the caller's mode
# rule, and the caller judges the brief's own Status change before this.
FLOOR_WHY=""  # read by floor's caller (U2c's --check)
# shellcheck disable=SC2034
floor() {
  local lp
  need_root
  FLOOR_WHY=""
  lp="$(lower "$1")" || { FLOOR_WHY="the path could not be lower-cased"; return 0; }
  if truthrule "$lp"; then
    case "$TRUTH_WHY" in
      instr) FLOOR_WHY="an instruction or prompt file, which sessions load from the checkout" ;;
      dot) FLOOR_WHY="a dotfile or a path under a dot-directory" ;;
      user) FLOOR_WHY="the user's constraints doc, which every loop prompt carries" ;;
      record) FLOOR_WHY="a record later runs read as truth" ;;
      case) FLOOR_WHY="the path could not be lower-cased" ;;
      *) FLOOR_WHY="one of the dev cycle's own files" ;;
    esac
  elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY="the gate's own code, which lands only through a merge-gate- review entry"
  elif [[ "$lp" == docs/thoughts/* ]]; then FLOOR_WHY="a record later runs read as truth"
  elif [[ "$lp" == docs/working/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY="a working file that is not this brief's own (they carry its full stem)"
  elif [[ "$lp" == docs/reviews/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY="a review record (only an added review named STEM.md or NAME-STEM.md lands)"
  elif truthwalk main "$lp"; then
    if [[ "$TRUTH_WHY" == walk ]]; then FLOOR_WHY="the default branch's instruction files could not be walked for @ imports"
    else FLOOR_WHY="an instruction or prompt file (on the default branch, or only in the checkout) imports it with @ (directly or through another import)"; fi
  else return 1; fi
}
# The keep-or-drop answer rule, for one entry of a questions file. Prints keep,
# drop, done, open, unrecognized, dup (the heading appears more than once),
# "odd N WHY", "unbalanced N" or "quoted N" (the file cannot be trusted; N is
# the line, WHY the oddwhy reason), or nothing when the file has no such entry. A trailing CR is dropped.
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
heading($0) { count++; inside = (count == 1); header = 0; next }
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
  else if (count) print (!answered ? "open" : done ? result : "unrecognized")
}'
# One answer, from docs/working/questions.md and questions-archive.md on the
# default branch's commit, never the working tree: an answer that unblocks
# autonomous work must have reached main (plan D8), because a build loop can
# write any working tree. A file stored as anything but a regular file under
# plain directories there is not read (main_entry). It reads only git objects,
# so it needs no ROOT_REAL and adds nothing to SKIPPED.
check_answer() {
  local - a="$1" f e r hit="" where="" n why; set -o pipefail  # as brief_fields
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
    hit="$r"; where="$f"
  done
  if [[ -n "$hit" ]]; then echo "$hit $a"
  else echo "skip $a: no such entry in docs/working/questions.md or questions-archive.md on the default branch"; fi
}
