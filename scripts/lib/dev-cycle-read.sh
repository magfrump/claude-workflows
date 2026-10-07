#!/bin/bash
# The dev cycle's reader, used by scripts/dev-cycle.sh and kept apart so
# scripts/build-loop.sh can share it: the output scrub, the plain-file
# and path-form rules, the cycle's own file names, the Markdown shapes the
# readers refuse (FENCE_AWK), the brief, branch and answer checks, the
# instruction-file import walks, and the default branch.
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
# check_brief, isimported and the import walks exit 1 (need_root) unless
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
# writes). main_imports reads main's commit first and then the working tree
# (the checkout's start files and imported files main lacks, which can only
# add imports or fail it; it needs resolve_main to have found main by name);
# imported_names, checkout_md and main_checkout read the working tree at ROOT_REAL.

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
writable() {
  [[ "$1" =~ ^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log)\.md$ \
    || "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]] || isbrief "$1" || isclosed "$1"
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
  if ! isbrief "$a" && ! isclosed "$a"; then
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
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"
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
# branch found by name (main_by_name).
check_branch() {
  local a="$1" sha
  if ! main_by_name; then echo "skip ${a//$'\n'/ }: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run"; return; fi
  if [[ ! "$a" =~ ^[$NAMECHARS]+$ || "$a" == -* ]]; then echo "skip ${a//$'\n'/ }: not an allowed branch name"
  elif ! git check-ref-format "refs/heads/$a" || ! git check-ref-format --branch "$a" >/dev/null 2>&1 \
    || [[ "$a" == HEAD || "$a" == refs/* ]]; then echo "skip $a: not a valid branch name"
  elif [[ "$a" == "$MAIN" ]]; then echo "skip $a: the default branch"
  else
    sha="$(git show-ref --verify --hash "refs/heads/$a" 2>/dev/null || true)"
    [[ -z "$sha" ]] || sha="$(git rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null || true)"
    if [[ -n "$sha" ]]; then echo "ok $a $sha $(git rev-list --count "$MAIN_SHA..$sha") $(git log -1 --format=%cs "$sha")"
    else echo "absent $a"; fi
  fi
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
# Instruction-file basenames, lower-cased: CLAUDE.md, CLAUDE.local.md,
# AGENTS.override.md and the like, GEMINI.md, SKILL.md. (A variable, quoted:
# written inline, the hermeticity lint reads the alternation as a command.)
INSTRUCTION_FILE='^(claude|agents?|gemini)(\.[abcdefghijklmnopqrstuvwxyz0123456789_-]+)?\.md$|^skill\.md$'
# Paths, lower-cased, that instruction files pull in with an @ import (Claude
# Code's "@path" syntax), followed transitively: such a file is read as
# instructions, so an in-cycle fix never edits it. The walk starts at every
# instruction file in the checkout, tracked or not (CLAUDE.local.md is usually
# gitignored), resolves each @path against the importing file's directory as
# Claude Code does (import_targets reads a superset of its names, ~/ against
# this process's HOME, and drops paths outside the repo), and reads each plain file it reaches once. It returns 1, with IMPORTED set to "error", when the start
# listing (git ls-files, untracked_md, instruction_names), lower, a file read,
# import_home or the parser (its comment lists why) fails, the IMPORT_OUT_MAX
# or IMPORT_WORK_MAX budget is spent, or a start file's name holds a newline (its callers in scripts/ test it under if or ||, where set -e is off); an
# inrepo_here that fails skips its path. One result is cached, for the root in
# IMPORTED_DONE; a call for another ROOT_REAL recomputes it, and a cached error
# returns 1 again.
# main_imports walks the default branch's commit instead, for the gate: it starts
# at every instruction file stored there (and every .md under a .claude/rules/
# directory at any depth, which Claude Code also loads) and follows an import
# into the file main stores at that path, whatever its name; a symlink there is
# followed to the path its text names. Once main's walk is done, a second phase
# walks the checkout's start files main lacks (untracked, ignored or only in
# the index) and the imported files main lacks, when each is a plain file
# there, and only appends. It refuses what it does not model, as FENCE_AWK does: a name
# listed twice or as both a file and a directory, a name holding a newline,
# symlink text that is empty, absolute, leaves
# the repo, holds a newline or a NUL, or has a .. after a symlink (on main or
# in the checkout), and a checkout path it would walk (a start or an import
# main lacks) that lies under a directory main stores as a symlink or gitlink
# or under an unsearchable directory, or that the checkout holds as anything
# but a readable plain file, a plain directory or nothing (the root included),
# or a checkout listing git prints any stderr for, fail the walk, so isimported main
# answers imported for every path. A linked worktree's .git file and files
# under .git are checkout files like any other. A start file answers imported only when an import reaches it
# (U2a4's floor names start files by its own rules). Not covered (known issue
# A5): start files under a symlinked directory or in a submodule or untracked
# nested repo, other names one file has on a case-insensitive checkout,
# checkout conversions (A5), command files (.claude/commands/*.md, whose
# @ names Claude Code loads when the command runs: U2a3b L2-confirm security
# F2; U2a4's shared start predicate), and a start that is not a regular file or
# symlink (git does not list a FIFO). The walk reads the checkout as one
# snapshot: a file swapped between its admission and its read is not seen.
# IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for
# the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, never the checkout,
# whose files it read, so a caller whose checkout may have changed (a file
# added or edited) sets IMPORTED_MAIN_DONE="" to walk again, and a cached
# error returns 1 again. A caller that changes HOME clears both
# IMPORTED_DONE and IMPORTED_MAIN_DONE (both caches are keyed without it).
# Neither walk starts at an instruction file outside the repo, though Claude
# Code loads them and follows their imports into it: a parent directory's
# CLAUDE.md, the user's memory file (known issue A5; the reader set is U2b's).
# isimported asks either walk.
IMPORTED=error; IMPORTED_DONE=""; IMPORTED_MAIN=error; IMPORTED_MAIN_DONE=""
# Each walk fails once import_targets has printed more than this in all
# (characters, newlines between names counted; awk counts bytes, so it may stop
# first): the parser's work bound is per file, while the bash side's cost grows
# with everything printed (performance L2 F2). A fresh clone's walks print about
# 2 KB, /workspace's about 6 KB. A caller that changes it clears IMPORTED_DONE
# and IMPORTED_MAIN_DONE before walking again.
IMPORT_OUT_MAX=4000000
# Each walk also fails once the parser's work (the candidate and comment-splice
# characters it scans, the unit of its per-file bound of 50,000,000, about 5 s)
# passes this in all, so N adversarial files cost one bound of charged parser
# work, not N (U2a3b L2-confirm performance P2); reading, draining and the scan
# of @-less lines are not charged (L2-C7, U2a3c i2 performance F3). /workspace's walks spend about 8,100 each (2026-10-07).
# The bound is per walk: a caller that runs both walks pays up to two. A caller
# that changes it clears both caches, as for IMPORT_OUT_MAX.
IMPORT_WORK_MAX=50000000
# UTF-8 spaces, which end an import token as a blank does (import_targets makes
# each one a blank first): U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F,
# U+205F, U+3000 and U+FEFF (Claude Code's token ends at JavaScript's \s).
UNI_SPACES=($'\xc2\xa0' $'\xe1\x9a\x80' $'\xe2\x80\x80' $'\xe2\x80\x81' $'\xe2\x80\x82' $'\xe2\x80\x83' $'\xe2\x80\x84'
  $'\xe2\x80\x85' $'\xe2\x80\x86' $'\xe2\x80\x87' $'\xe2\x80\x88' $'\xe2\x80\x89' $'\xe2\x80\x8a' $'\xe2\x80\xa8'
  $'\xe2\x80\xa9' $'\xe2\x80\xaf' $'\xe2\x81\x9f' $'\xe3\x80\x80' $'\xef\xbb\xbf')
lower() { printf '%s' "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'; }
# The import targets in the text on stdin, for a file in directory $1 ("" at
# the top level): one repo-relative path per line, case kept, each once. It
# also reads ROOT_REAL, HOME (through import_home, which sets the IMPORT_HOME*
# globals in the caller's shell unless called in a subshell) and IMPORT_LEFT
# (what may still be printed; IMPORT_OUT_MAX when unset or empty, and 0 when
# not a number, so the first name fails it) and IMPORT_WORK_LEFT (set by a
# walk: what its IMPORT_WORK_MAX has left, which then also caps the per-file
# work bound, and a last line "/N" reports the work spent; import_work reads
# it. Unset or empty: no trailer and only the per-file bound; not a number: 0,
# so the first candidate fails it). Every import walk shares these
# rules, so a change here changes --check-fix too.
# The superset claim (the one statement of it; known issue A5 and plan F11
# point here): these rules read every name Claude Code 2.1.292 can import (its
# import regex and Markdown lexer: U2a2 and U2a3b security reviews), failing
# toward "imported" rather than modelling where Markdown ends a name. Every @
# in a line starts a candidate, whatever precedes it and inside code spans and
# fences too; each prefix of the run after it, up to the first blank (a NUL or
# a UNI_SPACES space counts as one), is a candidate name, with a
# backslash-escaped space read as a space. A line holding <!-- is also read
# with its closed HTML comments removed (Claude Code splices them), and text
# holding a byte above 0x7f is also read decoded as Claude Code decodes it (an
# invalid UTF-8 sequence becomes U+FFFD). Each candidate is trimmed of spaces,
# made absolute (ROOT_REAL/$1/name unless it starts with /) and resolved
# lexically, .. stopping at / as Node's path.resolve does, so a name that
# leaves the repo and re-enters it is kept; it is kept only when it lies below
# ROOT_REAL, and printed repo-relative. A ~/ name is joined to this process's
# home (import_home), in its spelled and real forms. Known exceptions, where a
# session reading the file can import what these rules do not yield: a session
# whose home differs from this process's (its ~/ names), a session in another
# checkout of the repo (an absolute name into that checkout, or a relative one
# that re-enters through its directory; the reader set is U2b's), names that differ only in case on a case-insensitive file
# system (docs/reviews/override-log.md line 350), Claude Code's approved
# external includes, and any further decoding it may add (an entity, a percent
# escape). The cost is false positives: a prefix that is itself a file counts
# as imported, and so does a
# name led by an escaped space.
# It returns 1 when sed, python3, awk or import_home fails, when ROOT_REAL is
# empty, when a ~/ name appears and the home is not absolute, or when the
# candidates and comment splices run past a work bound or print past
# IMPORT_LEFT (so a pathological file fails the walk rather than stalling it).
# Re-check the superset when Claude Code changes its import grammar, how its
# runtime reads an empty or unset HOME, or how it decodes invalid UTF-8
# (test/agents-gemini-sync.bats holds a separate, older finder for where an
# import starts, not these rules).
# shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal
IMPORT_AWK='
function emit(c) {
  work += length(c); if (work > wmax) exit 3
  # Claude Code trims the name; it rejects a name led by a space first, so
  # trimming one only over-reads.
  sub(/^ +/, "", c); sub(/ +$/, "", c)
  if (c == "") return
  # ~/ joins the home directory (Claude Code: path.join(os.homedir(), rest)),
  # also spelled through its real path, since ROOT_REAL is real.
  if (substr(c, 1, 2) == "~/") {
    if (substr(home, 1, 1) != "/") exit 4
    if (homereal != home) put(homereal "/" substr(c, 3))
    c = home "/" substr(c, 3)
  }
  put(c)
}
function put(c,   n, i, k, part, st, out) {
  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
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
  if (index(out, pre) != 1 || length(out) <= length(pre)) return
  out = substr(out, length(pre) + 1)
  if (out in seen) return
  # printed counts as the walks count: each name, a newline between names.
  seen[out] = 1; printed += length(out) + 1; if (printed - 1 > left) exit 3
  print out
}
function scan(line,   i, j, L, ch, name) {
  L = length(line)
  for (i = 1; i <= L; i++) {
    if (substr(line, i, 1) != "@") continue
    name = ""
    for (j = i + 1; j <= L; j++) {
      ch = substr(line, j, 1)
      if (ch == "\\" && substr(line, j + 1, 1) == " ") { ch = " "; j++ }
      else if (ch == " " || ch == "\t" || ch == "\r") break
      name = name ch; emit(name)
    }
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
  dir = ENVIRON["IT_DIR"]; root = ENVIRON["IT_ROOT"]; home = ENVIRON["IT_HOME"]; homereal = ENVIRON["IT_HOME_REAL"]
  left = ENVIRON["IT_LEFT"] + 0; pre = (root == "/") ? "/" : root "/"; if (root == "") exit 2
  wmax = 50000000; trail = (ENVIRON["IT_WORK"] != ""); if (trail && ENVIRON["IT_WORK"] + 0 < wmax) wmax = ENVIRON["IT_WORK"] + 0
}
{ scan($0); if (index($0, "<!--")) scan(splice($0)) }
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
import_targets() {
  local u d toks s=(-e 's/\x0/ /g') LC_ALL=C
  import_home || return 1
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
  # dir, root and home go through the environment: awk -v would read
  # backslash escapes in them. IMPORT_LEFT, set by a walk, is what its
  # IMPORT_OUT_MAX budget has left, so awk stops there rather than after.
  printf '%s\n' "$toks" | env LC_ALL=C IT_DIR="$1" IT_ROOT="${ROOT_REAL:-}" IT_HOME="$IMPORT_HOME" IT_HOME_REAL="$IMPORT_HOME_REAL" \
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
# Instruction-file names among NUL-separated paths on stdin: one grep, before
# the tree walk forks lower and a plain check per path (forking for every tracked
# file took seconds). It matches INSTRUCTION_FILE's names; the walk's own test
# stays the authority. LC_ALL=C makes -i ASCII-only. It returns 0 when no name
# matches and 1 when grep fails (grep's own no-match is 1).
instruction_names() { env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$' || [[ $? -eq 1 ]]; }
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
# loads), set only once its own and every higher ancestor's main mode passed.
# A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT.
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
  set +u; [[ "${mc_e@a}" == *A* && "${mc_m@a}" == *A* ]] || return 1
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
  local - f d p lp out used=0 work=0 seen=$'\n' queue=() recs=(); set -o pipefail
  need_root
  [[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }
  IMPORTED_DONE="$ROOT_REAL"; IMPORTED=error
  nul_list recs tree_starts || return 1
  for f in "${recs[@]}"; do
    # seen is newline-separated: a name holding a newline could hide another start.
    [[ "$f" != *$'\n'* ]] || return 1
    lp="$(lower "${f##*/}")" || return 1
    if [[ ! "$lp" =~ $INSTRUCTION_FILE ]] || ! inrepo_here "$f"; then continue; fi
    [[ "$seen" == *$'\n'"$f"$'\n'* ]] && continue
    seen+="$f"$'\n'; queue+=("$f")
  done
  import_home || return 1
  IMPORTED=$'\n'
  while [[ ${#queue[@]} -gt 0 ]]; do
    f="${queue[0]}"; queue=("${queue[@]:1}")
    if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi
    out="$(capped_read < "$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - work)) import_targets "$d")" \
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
# follows is empty, absolute, leaves the repo, holds a newline or a NUL, or has
# a .. after a symlink, import_home, the parser (its comment lists why) or a
# lower fails, or the IMPORT_OUT_MAX or IMPORT_WORK_MAX budget is spent;
# need_root exits instead.
# Phase 2 begins when queue empties: tq's checkout files then join it, and a
# path main lacks reads the checkout.
main_imports() {
  local - rec f d p i c lk out used=0 work=0 queue=() tq=() recs=() cand=() low=() parts=(); set -o pipefail  # as brief_fields
  # shellcheck disable=SC2034  # pok is main_checkout's MEMO, passed by name
  local -A ent=() seen=() dir=() pok=()
  need_root
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"
  main_by_name || return 1
  nul_list recs git ls-tree -r -z --full-tree "$MAIN_SHA" || return 1
  for rec in "${recs[@]}"; do
    [[ "$rec" =~ ^([01234567]{6})\ [abcdefghijklmnopqrstuvwxyz]+\ [0123456789abcdef]{40,64}$'\t'(.+)$ ]] || return 1
    f="${BASH_REMATCH[2]}"
    [[ -z "${ent[$f]+set}" && "$f" != *$'\n'* ]] || return 1
    ent[$f]="${BASH_REMATCH[1]}"
    [[ "$f" != *.[mM][dD] ]] || cand+=("m:$f")
  done  # then a name that is also a directory of another listed name (a crafted tree) fails:
  for f in "${!ent[@]}"; do c="$f"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ -z "${dir[$c]+set}" ]] || break; [[ -z "${ent[$c]+set}" ]] || return 1; dir[$c]=1; done; done
  nul_list recs checkout_md || return 1
  for f in "${recs[@]}"; do [[ "$f" != *$'\n'* ]] || return 1; [[ -n "${ent[$f]+set}" ]] || cand+=("t:$f"); done
  [[ ${#cand[@]} -eq 0 ]] || nul_list low lower_all "${cand[@]}" || return 1
  [[ ${#low[@]} -eq ${#cand[@]} ]] || return 1
  for i in "${!cand[@]}"; do
    f="${low[i]:2}"
    if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]; then
      f="${cand[i]:2}"; c=0; [[ "${cand[i]:0:1}" == m ]] || main_checkout ent pok "$f" || c=$?
      [[ $c -ne 1 ]] || return 1; [[ $c -eq 0 ]] || continue
      seen[$f]=1; if [[ -n "${ent[$f]+set}" ]]; then queue+=("$f"); else tq+=("$f"); fi
    fi
  done
  import_home || return 1
  IMPORTED_MAIN=$'\n'
  while [[ ${#queue[@]} -gt 0 || ${#tq[@]} -gt 0 ]]; do
    [[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }  # phase 2: main's walk is done
    f="${queue[0]}"; queue=("${queue[@]:1}")
    if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi
    case "${ent[$f]-checkout}" in
      checkout) out="$(capped_read < "$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - work)) import_targets "$d")" \
          && import_work out work || { IMPORTED_MAIN=error; return 1; } ;;
      100644|100755) out="$(git cat-file blob "$MAIN_SHA:$f" | capped_read drain | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - work)) import_targets "$d")" \
          && import_work out work || { IMPORTED_MAIN=error; return 1; } ;;
      120000)  # a symlink: its text names the file read, as one more import
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
        [[ "$out" != .. && "$out" != ../* ]] || { IMPORTED_MAIN=error; return 1; } ;;
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
# failed walk runs the walk first (imported_names or main_imports, under if). Run it in the caller's shell: the walk exits
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
