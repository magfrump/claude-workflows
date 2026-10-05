#!/bin/bash
# The dev cycle's reader, used by scripts/dev-cycle.sh and kept apart so the
# planned scripts/build-loop.sh can share it: the output scrub, the plain-file
# and path-form rules, the cycle's own file names, the Markdown shapes the
# readers refuse (FENCE_AWK), the brief, branch and answer checks, the
# instruction-file import walk, and the default branch.
#
# Sourced, never run: it only defines functions and variables. Each script
# sources it from its own directory (never from the repo it acts on), so a copy
# of scripts/ with its lib/ is self-contained. A change here must pass
# test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/
# once that second caller lands. The
# caller sets -euo pipefail,
# cds to the repo root and sets ROOT_REAL (that root, symlinks resolved) before
# calling any file check. inrepo, dirok, skipped, check_brief and
# the import walk (imported_names) exit 1 (need_root) unless ROOT_REAL is set,
# is the current directory and is a repository's top level; while ROOT_REAL is
# unset, rawfile, plaindir and blocker read nothing as plain. Call the exiting
# checks in the caller's shell, not inside $(...) or `local x="$(...)"`, where
# an exit ends only the subshell. skipped records each blocked input in SKIPPED
# and SKIP_AT. The caller runs resolve_main once per process (a second call
# re-reads main); check_brief, check_branch and check_answer skip every
# argument unless it returned 0 with main found by name. check_brief,
# check_branch and check_answer answer with one printed line per argument that
# can echo repo text: print it through scrub, read it as `out="$(check_brief ...)"` under
# set -e (which stops when need_root exits; `if out=...` and `< <(...)` would
# carry on), and treat any line that is not a positive answer as a refusal.
# Every script that calls scrub_reexec shares its DEV_CYCLE_SCRUBBED marker.
# Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields
# read the default branch's commit, never the working tree (check_brief also
# refuses a brief path that is not plain in the working tree, which the cycle
# writes); imported_names reads the working tree at ROOT_REAL.

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
inrepo() { need_root; [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }
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
writable() {
  [[ "$1" =~ ^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log)\.md$ \
    || "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ \
    || "$1" =~ ^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]] || isbrief "$1"
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
# The default branch, set by resolve_main (below). check_brief, check_branch
# and check_answer read its commit, so they answer only when it was found by name, never for the
# current branch's fallback or before resolve_main has succeeded.
MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""
main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }
# How a path is stored in the default branch's commit, so that a file read from
# it is never a symlink's target text, a gitlink or a tree, and no directory
# above it is a symlink: prints "blob" (a regular file, mode 100644 or 100755),
# "absent", "notfile" (the path is some other kind of entry), "notdir PART"
# (PART, a directory above the path, is stored as something else) or "error"
# (no default branch found by name, ls-tree failed, or the tree lists a name
# twice, which git's own reads resolve to the first copy: never read as absent). One ls-tree
# call lists the path and every directory above it (-t: trees too; --full-tree:
# paths from the top level, whatever the current directory). The caller has checked
# main_by_name and the path's form (pathform, so ls-tree prints it unquoted).
main_entry() {
  local p="" rest="$1" out mode path dup="" want=()
  local -A m=()
  main_by_name || { echo error; return; }
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
# default branch found by name, a path pathform refuses, no regular file there
# on main by main_entry, or the blob could not be read). The callers judge the
# values. Call it in the caller's own shell: it sets globals.
declare -gA BRIEF=(); BRIEF_ODD=""
brief_fields() {
  local out l
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
  if ! isbrief "$a" && [[ ! "$a" =~ ^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; then
    echo "skip $a: not a build brief (docs/working/briefs/[closed/]YYYY-MM-DD-<slug>.md)"; return
  fi
  if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi
  # Only a regular file counts: a symlink's blob is its target text, not a
  # brief, and a gitlink or tree is not a brief either.
  e="$(main_entry "$a")"
  case "$e" in
    absent) echo "ok $a new"; return ;;
    blob) ;;
    notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch"; return ;;
    error) echo "skip $a: the default branch's tree could not be read"; return ;;
    *) echo "skip $a: not a regular file on the default branch"; return ;;
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
# Claude Code does (~/ and absolute paths lead outside the repo and are not
# followed), and reads each plain file it reaches once. A token may follow any
# byte but a letter or digit (so user@host is not one); it ends at a blank, \, #,
# a backtick, ( ) [ or ], and loses trailing punctuation and emphasis marks
# (*, _, ~), so @docs/my_notes.md and **@docs/x.md** both read whole.
# Over-reading (a code span) only over-refuses. One result is cached, for the
# root in IMPORTED_DONE; a call for another ROOT_REAL recomputes it.
IMPORTED=$'\n'; IMPORTED_DONE=""
IMPORT_RE='(^|[^[:alnum:]])@[^][:space:]\\#`()]+'
lower() { printf '%s' "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'; }
imported_names() {
  local f t d p seen=$'\n' queue=()
  need_root
  [[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && return; IMPORTED_DONE="$ROOT_REAL"; IMPORTED=$'\n'
  while IFS= read -r -d '' f; do
    if [[ ! "$(lower "${f##*/}")" =~ $INSTRUCTION_FILE ]] || ! inrepo "$f"; then continue; fi
    [[ "$seen" == *$'\n'"$f"$'\n'* ]] && continue
    seen+="$f"$'\n'; queue+=("$f")
  # One grep keeps only instruction-file basenames before the loop forks lower
  # and inrepo per path (forking for every tracked file took seconds). It
  # matches INSTRUCTION_FILE's names; the loop's own test stays the authority.
  # LC_ALL=C makes -i ASCII-only. --others without --exclude-standard already
  # lists ignored files, so one untracked listing covers both.
  done < <({ git ls-files -z
             GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'; } \
           | env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$' || true)
  while [[ ${#queue[@]} -gt 0 ]]; do
    f="${queue[0]}"; queue=("${queue[@]:1}")
    if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi
    while IFS= read -r t; do
      t="${t#*@}"
      while [[ "$t" == *[.,\;:!?*_~] ]]; do t="${t%?}"; done
      [[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue
      p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$t" 2>/dev/null)" || continue
      [[ "$p" != ..* ]] || continue
      IMPORTED+="$(lower "$p")"$'\n'
      if [[ "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo "$p"; then seen+="$p"$'\n'; queue+=("$p"); fi
    done < <(env LC_ALL=C grep -oE "$IMPORT_RE" -- "$f" || true)
  done
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
  local a="$1" f e r hit="" where="" n why
  if [[ ! "$a" =~ ^Q-[0123456789]+$ ]]; then echo "skip ${a//$'\n'/ }: not a question ID (Q- and digits)"; return; fi
  if ! main_by_name; then echo "skip $a: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run"; return; fi
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    e="$(main_entry "$f")"
    case "$e" in
      absent) continue ;;
      blob) ;;
      notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch, so $f is not read"; return ;;
      error) echo "skip $a: the default branch's tree could not be read, so $f is not read"; return ;;
      *) echo "skip $a: $f is not a regular file on the default branch, so no entry in it is read"; return ;;
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
