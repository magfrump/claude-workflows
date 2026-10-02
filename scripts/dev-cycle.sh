#!/usr/bin/env bash
# Gather the mechanical signals for one dev cycle into a markdown digest.
#
# The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps on
# top of this digest. Everything that needs no judgment lives here, because
# steps that only prose asks for do not run (scripts/questions.sh header; Q-074).
#
# Usage: scripts/dev-cycle.sh [--since=YYYY-MM-DD] [--sample=N]
#        scripts/dev-cycle.sh --check-path PATH-OR-GLOB...
#        scripts/dev-cycle.sh --check-write PATH...
#        scripts/dev-cycle.sh --check-brief PATH...
#        scripts/dev-cycle.sh --check-branch NAME...
#        scripts/dev-cycle.sh --check-fix PATH...
#        scripts/dev-cycle.sh --check-answer Q-NNN...
#
#   --since   start of the cycle window: commits whose committer date, in the
#             committer's own time zone (git's %cs), is on or after this date.
#             Default: the date in the newest cycle-YYYY-MM-DD.md in docs/working/cycles
#             that is a plain file, a real date and not future-dated (only its name is read), else
#             14 days ago. The digest says which.
#   --sample  how many merges to sample for the spot-check (default 2).
#   --check-path  instead of a digest, apply the dev-cycle skill's rule for paths
#             taken from repo text: "ok <path>" for each file that may be read (a
#             tracked file, or a gitignored one under docs/working/; at most 50
#             per argument), "skip <arg or match>: <reason>" otherwise.
#   --check-write  the same for one of the cycle's own bookkeeping files
#             (roadmap, questions files, idea log, cycle records, open briefs and
#             briefs/closed/); the file need not exist yet.
#   --check-brief  for a build brief path (docs/working/briefs/[closed/]
#             YYYY-MM-DD-<slug>.md): "ok <path> new" when the default branch has no file
#             there (not landed, or moved to closed/), else "ok <path>
#             open|done|dropped <commit>" from its first unfenced "Status:" line
#             on the default branch and the commit in its first-parent history
#             that last added or removed a "Status: " line there (a merge
#             commit, the branch's own commit after a fast-forward, or a later
#             move or quoted Status line); "skip <path>: <reason>" otherwise,
#             including a brief the reader cannot trust, naming the line and
#             the reason: a code fence never closed or not in plain column-0
#             form, a line starting (after blanks) with < or leaving a <!--
#             open, a line starting like a link reference definition, a stray
#             carriage return, or a byte-order mark on line 1.
#   --check-branch  "ok <name> <commit> <n> <YYYY-MM-DD>" for a brief's branch
#             that exists (n: its commits not on the default branch; the date
#             of its tip commit), "absent <name>" for
#             one that does not, "skip <name>: <reason>" for a name outside
#             letters, digits, . _ - /, starting with -, not a valid branch name
#             (HEAD, refs/...) or the default branch. The commit is
#             refs/heads/<name>'s own, never a same-named tag's.
#   --check-fix  "ok <path>" for a file an in-cycle fix may edit: a tracked .md
#             file under docs/ (not working/, human-author/, reviews/,
#             decisions/, dev-cycle.md, a dot-directory or an instruction file)
#             or README.md; "skip <path>: <reason>" otherwise.
#   --check-answer  "<option> Q-NNN" for a keep-or-drop-or-done question, read
#             from docs/working/questions.md or its archive: keep, drop, done,
#             open (not marked ANSWERED yet) or unrecognized (answered, but no
#             answer line was found, or the first one's text does not start
#             with one of the options); "skip Q-NNN:
#             <reason>" when it cannot be read (no such entry, a duplicate
#             heading, a code fence never closed or not in plain column-0
#             form, a line starting (after blanks) with < or leaving a <!--
#             open, a line starting like a link reference definition, a stray
#             carriage return, a byte-order mark on line 1, a question heading
#             inside a fence, a questions file
#             that is not plain).
#   --check-brief and --check-branch need a default branch found by name
#   (origin/HEAD, main or master): they read its commit.
#
# Every revisit trigger is printed every run (an output line over 4096 bytes is cut);
# nothing carries forward.
# Acts on $PWD's git repo (like questions.sh), so the installed copy serves any
# project. Read-only: writes nothing to the repo (one temp file, removed on exit).
# Exit: 0 digest printed (or, for the check modes, every argument answered: a
# skip is an answer, not an error); 1 bad usage, not a git repo, no perl, or no
# default branch (for the digest, --check-brief and --check-branch); a failed step exits non-zero mid-digest. Printed repo text is data.

set -euo pipefail

command -v perl >/dev/null || { echo "dev-cycle.sh needs perl (to scrub its output)" >&2; exit 1; }
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
if [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]]; then
  { DEV_CYCLE_SCRUBBED=1 bash "${BASH_SOURCE[0]}" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub
  exit "${PIPESTATUS[0]}"
fi

SINCE=""
SAMPLE=2
CHECK=""; CHECK_ARGS=()
need() { [[ -n "$2" ]] || { echo "$1 needs a value" >&2; exit 1; }; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) need --since "${2:-}"; SINCE="$2"; shift 2 ;;
    --since=*) SINCE="${1#--since=}"; need --since "$SINCE"; shift ;;
    --sample) need --sample "${2:-}"; SAMPLE="$2"; shift 2 ;;
    --sample=*) SAMPLE="${1#--sample=}"; need --sample "$SAMPLE"; shift ;;
    --check-path|--check-write|--check-brief|--check-branch|--check-fix|--check-answer)
      CHECK="$1"; shift; CHECK_ARGS=("$@")
      [[ ${#CHECK_ARGS[@]} -gt 0 ]] || { echo "$CHECK needs at least one argument" >&2; exit 1; }
      break ;;
    -h|--help) sed -n '2,74p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ "$SAMPLE" =~ ^[0-9]+$ ]] || { echo "--sample must be a non-negative integer" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # before the cd: relative paths work
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
ROOT_REAL="$(pwd -P)"
# A regular file reached without any symlink: its real path must be exactly the
# repo root plus the path as given, so a committed symlink (to the file or to a
# parent directory, pointing outside the checkout or into .git) is never read.
rawfile() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
# A directory the digest globs in must be plain too, or the glob would list
# names from wherever a symlinked directory points.
plaindir() { local r; [[ -d "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
# One rule decides whether an input is skipped, for files and directories alike:
# walking the path top down, the first part that exists but is not plain (a
# symlink, or not a regular file / directory) blocks it. Nothing below a blocking
# part is probed, not even whether a file exists there; the blocking part is what
# section 8 lists and what the inline note names. A newline in a name becomes a
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
inrepo() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }
# The same for a directory the digest globs in: the walk first, so nothing is
# looked up through a non-plain parent.
dirok() { [[ -z "$(blocker "$1" dir)" && -d "$1" ]]; }
skipped() { SKIP_AT="$(blocker "$1" "${2:-file}")"; [[ -n "$SKIP_AT" ]] || return 1; SKIPPED+=("$SKIP_AT"); }
skipdir() { skipped "$1" dir; }
skipnote() { echo "$1 is not read: $SKIP_AT is not a plain file or directory (section 8)."; }
# DEV_CYCLE_TODAY exists only so tests can pin the date. File names are literal,
# not pathspecs.
TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"; export GIT_LITERAL_PATHSPECS=1

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
# Every grep here runs in the C locale (set through env, which bash does not
# apply to its own locale), so a name that is not UTF-8 still passes, to be
# skipped by the form check.
exact() {  # $1 the argument: a plain path keeps only itself (not a directory's contents)
  if [[ "$1" == *[*?]* ]]; then cat; else env LC_ALL=C grep -zxF -- "$1" || true; fi
}
matches() {  # $1 pathspec, $2 the argument; NUL-separated tracked files, then ignored ones under docs/working/
  local fixed="${2%%[*?]*}"
  GIT_LITERAL_PATHSPECS=0 git ls-files -z -- "$1" | exact "$2"
  # Ignored files count only under docs/working/; skip the query when the
  # argument's fixed prefix cannot lead there (it lists every ignored match).
  if [[ "$fixed" == docs/working/* || docs/working/ == "$fixed"* ]]; then
    GIT_LITERAL_PATHSPECS=0 git ls-files -z --others --ignored --exclude-standard -- "$1" \
      | { env LC_ALL=C grep -z '^docs/working/' || true; } | exact "$2"
  fi
}
check_path() {
  local a="$1" spec m n=0 max=50
  if ! pathform "$a" glob; then echo "skip ${a//$'\n'/ }: not an allowed path form"; return; fi
  if [[ "$a" == *[*?]* ]]; then spec=":(glob)$a"; else spec=":(literal)$a"; fi
  while IFS= read -r -d '' m; do
    [[ "$a" == *[*?]* || "$m" == "$a" ]] || continue  # a plain path names one file, not a directory
    n=$((n + 1))
    if [[ $n -gt $max ]]; then echo "skip $a: matches more than $max files; the rest are not listed (narrow the glob)"; break; fi
    if ! pathform "$m"; then echo "skip ${m//$'\n'/ }: not an allowed path form"
    elif ! inrepo "$m"; then echo "skip $m: reached through a symlink, or not a regular file"
    else echo "ok $m"; fi
  done < <(matches "$spec" "$a")
  if [[ $n -gt 0 ]]; then return; fi
  if [[ "$a" != *[*?]* ]] && dirok "$a"; then echo "skip $a: a directory, not a file"
  else echo "skip $a: no tracked file (or ignored file under docs/working/) matches"; fi
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
check_write() {
  local a="$1"
  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"
  elif ! writable "$a"; then echo "skip $a: not one of the dev cycle's own files"
  elif [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"
  else echo "ok $a"; fi
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
# reference definition (after any > and list markers), a
# carriage return inside a line (CommonMark ends a line there), or a
# byte-order mark on line 1: fence() records the first one's line number in
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
  sub(/^[ \t>]*/, "", l)
  while (l ~ /^([-*+]|[0123456789]+[.)])[ \t]/) { sub(/^[^ \t]+[ \t]+/, "", l); sub(/^[ \t>]*/, "", l) }
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
    bom) echo "starts with a byte-order mark" ;;
    *) echo "is a fence-like line that is not a plain column-0 fence" ;;
  esac
}
# A brief's state, read only from the default branch's commit (never the
# working tree): its first line outside a ``` or ~~~ fence that starts with
# "Status:", which must be exactly "Status: open|done|dropped". A brief
# FENCE_AWK refuses (see its comment for every reason) is not read at all. "new" when the
# default branch has no file at that path (not landed yet, or moved to
# closed/). A closed/ path is read the same way (its state, for In flight; it
# never holds a slot).
check_brief() {
  local a="$1" st c n why
  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"; return; fi
  if ! isbrief "$a" && [[ ! "$a" =~ ^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; then
    echo "skip $a: not a build brief (docs/working/briefs/[closed/]YYYY-MM-DD-<slug>.md)"; return
  fi
  if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi
  if [[ "$(git cat-file -t "$MAIN_SHA:$a" 2>/dev/null || true)" != blob ]]; then echo "ok $a new"; return; fi
  # The whole blob is read (no early exit, which would kill git cat-file with
  # SIGPIPE under pipefail); fenced lines are skipped (FENCE_AWK).
  # shellcheck disable=SC2016  # awk code, not shell: $0 must stay literal
  st="$(git cat-file blob "$MAIN_SHA:$a" | env LC_ALL=C awk "$FENCE_AWK"'
    { sub(/\r$/, "") }
    fence($0) { next }
    !seen && /^Status:/ { seen = 1; if ($0 ~ /^Status: (open|done|dropped)$/) st = $0 }
    END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline; else if (st != "") print st }')"
  case "$st" in
    odd\ *) read -r _ n why <<<"$st"; echo "skip $a: line $n $(oddwhy "$why"), so the brief is not read"; return ;;
    unbalanced\ *) echo "skip $a: the code fence opened at line ${st#unbalanced } is never closed, so the brief is not read"; return ;;
    '') echo "skip $a: its first Status: line is not exactly Status: open, done or dropped"; return ;;
  esac
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
# The default branch is refused (the check modes that read it need it found by name).
check_branch() {
  local a="$1" sha
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
# An in-cycle fix edits documentation only: a tracked .md file under docs/,
# outside the cycle's own files, working/, human-author/ (the user's), reviews/
# and decisions/ (records), the settings file, any dot-directory, and any
# instruction file (CLAUDE.md, AGENT(S).md, GEMINI.md, SKILL.md, any case); or
# README.md. Anything else is filed.
# Instruction-file basenames, lower-cased: CLAUDE.md, CLAUDE.local.md,
# AGENTS.override.md and the like, GEMINI.md, SKILL.md. (A variable, quoted:
# written inline, the hermeticity lint reads the alternation as a command.)
INSTRUCTION_FILE='^(claude|agents?|gemini)(\.[abcdefghijklmnopqrstuvwxyz0123456789_-]+)?\.md$|^skill\.md$'
check_fix() {
  local a="$1" base low
  if [[ "$a" == *[*?]* ]]; then echo "skip ${a//$'\n'/ }: --check-fix takes one file, not a glob"; return; fi
  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"; return; fi
  base="${a##*/}"; low="$(printf '%s' "$base" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"
  if writable "$a"; then echo "skip $a: one of the cycle's own files (use --check-write)"
  elif [[ ! "$a" =~ ^docs/.*\.md$|^README\.md$ || "$a" =~ ^docs/(working|human-author|reviews|decisions)/ \
    || "$a" == docs/dev-cycle.md || "$a" == */.* || "$low" =~ $INSTRUCTION_FILE ]]; then
    echo "skip $a: in-cycle fixes edit only tracked .md documentation under docs/ (not working/, human-author/, reviews/, decisions/, dev-cycle.md, dot-directories or instruction files) and README.md; file it instead"
  else check_path "$a"; fi
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
  if (!(r == "" || r ~ /^[.,;:!)]/ || (t != r && (t == "" || substr(t, 1, 1) == "-" \
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
    rest = substr(rest, c + 2)
    if ((e = index(rest, "**")) > 0) rest = substr(rest, 1, e - 1)
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
check_answer() {
  local a="$1" f r hit="" where="" n why
  if [[ ! "$a" =~ ^Q-[0123456789]+$ ]]; then echo "skip ${a//$'\n'/ }: not a question ID (Q- and digits)"; return; fi
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    if skipped "$f"; then echo "skip $a: $SKIP_AT is not a plain file or directory, so $f is not read"; return; fi
    [[ -f "$f" ]] || continue
    r="$(env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK" "$f")"
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
  else echo "skip $a: no such entry in docs/working/questions.md or questions-archive.md"; fi
}
# Pass git only a hash for the default branch: origin/HEAD comes from the remote,
# and a branch named `--output=<path>` would reach `git log` as an option.
MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""
candidates=()
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
[[ -n "$MAIN_SHA" || -n "$CHECK" ]] || { echo "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)" >&2; exit 1; }
# The check modes run here. --check-brief and --check-branch read the default
# branch's commit, so they need one found by name (origin/HEAD, main or
# master), not the current branch; the other modes do not use it.
if [[ ( "$CHECK" == --check-brief || "$CHECK" == --check-branch ) && -z "$MAIN_BY_NAME" ]]; then
  echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1
fi
if [[ -n "$CHECK" ]]; then
  for a in "${CHECK_ARGS[@]}"; do
    case "$CHECK" in
      --check-path) check_path "$a" ;;
      --check-write) check_write "$a" ;;
      --check-brief) check_brief "$a" ;;
      --check-branch) check_branch "$a" ;;
      --check-fix) check_fix "$a" ;;
      --check-answer) check_answer "$a" ;;
    esac
  done
  exit 0
fi

last_record=""; skipped_record=""
if dirok docs/working/cycles; then
  for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
    d="${f##*/cycle-}"; d="${d%.md}"
    if ! rawfile "$f"; then
      # Keep the newest skipped date (not future-dated) to warn when it is newer
      # than the record the window starts from.
      skipped "$f" && [[ "$SKIP_AT" == "$f" && "$d" > "$skipped_record" && ! "$d" > "$TODAY" ]] \
        && date -d "$d" >/dev/null 2>&1 && skipped_record="$d"
      continue
    fi
    date -d "$d" >/dev/null 2>&1 || continue  # a name that is not a real date
    [[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"  # ignore future-dated
  done
else
  skipdir docs/working/cycles || true
fi
records_skipped=${#SKIPPED[@]}
if [[ -n "$SINCE" ]]; then
  source_note="--since"
elif [[ -n "$last_record" ]]; then
  SINCE="$last_record"; source_note="the last cycle record, docs/working/cycles/cycle-$last_record.md"
  if [[ "$skipped_record" > "$last_record" ]]; then
    source_note+="; a newer record, docs/working/cycles/cycle-$skipped_record.md, was skipped as not a plain file (section 8), so this window may start too early"
  fi
else
  SINCE="$(date -d "$TODAY - 14 days" +%F)"
  if [[ $records_skipped -gt 0 ]]; then
    source_note="no readable cycle record (records, or a directory above them, were skipped as not a plain file or directory: section 8), so the default of 14 days"
  else
    source_note="no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)"
  fi
fi
if ! [[ "$SINCE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || ! date -d "$SINCE" >/dev/null 2>&1; then echo "--since must be a real YYYY-MM-DD date" >&2; exit 1; fi

echo "# Dev-cycle digest — $TODAY"
echo
echo "Window: since $SINCE (from $source_note). Merges, commits and section 7's changed files: those on \`$MAIN\` at ${MAIN_SHA:0:7} whose committer date (in the committer's time zone) is on or after $SINCE, filtered after a full walk. Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree."

echo
echo "## 1. Activity"
# Walk all of history and filter by committer date afterwards: `--since` stops
# at the first old-dated commit, so one such commit hid every merge behind it.
# %cs is the committer date as YYYY-MM-DD, which compares as a string.
merges_full="$(git log "$MAIN_SHA" --first-parent --merges --format='%cs %H %h %ad %s' --date=short | awk -v s="$SINCE" '$1 >= s')"
merges="$(printf '%s' "$merges_full" | cut -d' ' -f3-)"
n_merges="$(printf '%s' "$merges" | grep -c . || true)"
commits="$(git log "$MAIN_SHA" --format=%cs | awk -v s="$SINCE" '$1 >= s' | wc -l)"
echo
echo "$n_merges merge(s) on \`$MAIN\`'s first-parent line; $commits commit(s) reachable from it, merged branches included."
[[ -n "$merges" ]] && { echo; echo '```'; printf '%s\n' "$merges" | sed -n '1,30p'; [[ "$n_merges" -gt 30 ]] && echo "… $((n_merges - 30)) more"; echo '```'; }

printf '\n%s\n\n' "## 2. Revisit triggers"
echo "Every trigger, in full: each decision record's \`## Revisit triggers\` section and each decision-log row that mentions revisiting (a trigger written elsewhere in a record is not found; an output line over 4096 bytes is cut: read the record itself then). Decide each: fired / not fired / cannot tell, with the evidence. A fired trigger becomes a questions.md entry. The last cycle record's verdicts are context, not answers."
found=0
trig() { awk '/^## Revisit triggers/ { on = 1; next } on && /^## / { exit } on && NF { print }'; }
n_before_triggers=${#SKIPPED[@]}
decisions_glob=()
if dirok docs/decisions; then decisions_glob=(docs/decisions/[0-9][0-9][0-9]-*.md); else skipdir docs/decisions || true; fi
# Each record's last commit date, from one path-limited walk (newest first, so
# the first date seen per path wins) instead of one `git log` per record, which
# cost records x history. Merges list the files their result changed against
# every parent (combined), as a per-file `git log` counts them. A name git still
# quotes (a quote, backslash or control character) misses the map and, if it
# is in HEAD, falls back to its own lookup. Around merges the date can differ from per-file
# `git log -1`, in either direction: one walk over the whole directory does not
# simplify history per file, so a change a merge discarded, or the same change
# made on both sides, can decide the date. It is always a real commit on this
# branch that touched the record; it is shown as evidence only.
declare -A last_date=()
if [[ ${#decisions_glob[@]} -gt 0 ]]; then
  while IFS=$'\t' read -r path day; do last_date["$path"]="$day"; done < <(
    git -c core.quotePath=false log --diff-merges=combined --format='@%ad' --date=short --name-only -- docs/decisions \
      | awk '/^@/ { d = substr($0, 2); next } NF && !seen[$0]++ { print $0 "\t" d }')
fi
for f in "${decisions_glob[@]}"; do
  rawfile "$f" || { skipped "$f" || true; continue; }
  grep -q '^## Revisit triggers' "$f" || continue
  found=1
  echo
  d="${last_date[$f]-}"
  # Fall back only for a record present in HEAD's tree (one object lookup, no
  # history walk): a record the map missed (a name git quotes) that is absent
  # from HEAD prints "never, uncommitted" without a full walk to prove it (~1 s
  # per record on a 220k-commit repo), even if it was committed once and later
  # removed. A plain-named record keeps the map's date, removal included.
  if [[ -z "${last_date[$f]+set}" ]] && git cat-file -e "HEAD:$f" 2>/dev/null; then
    d="$(git log -1 --format=%ad --date=short -- "$f")"
  fi
  # A newline in a file name would otherwise print a line of its own.
  echo "### ${f//$'\n'/ } (last committed on this branch: ${d:-never, uncommitted})"
  trig < "$f" | sed 's/^/> /'
done
if inrepo docs/decisions/log.md; then
  while IFS= read -r row; do
    found=1
    n="$(awk -F'|' '{ gsub(/ /, "", $2); print $2 }' <<< "$row")"
    d="$(awk -F'|' '{ gsub(/ /, "", $3); print $3 }' <<< "$row")"
    # The whole clause to the cell's end; prefer a capitalised "Revisit" (the
    # trigger sentence) over an earlier "revisit-trigger verdicts" mention.
    text="$(grep -oE 'Revisit[^|]*' <<< "$row" | head -1 || true)"
    [[ -n "$text" ]] || text="$(grep -oiE 'revisit[^|]*' <<< "$row" | head -1 || true)"
    echo "- log row $n ($d): > $text"
  done < <(grep -E '^\| [0-9]+ \|' docs/decisions/log.md | grep -i 'revisit' || true)
else
  skipped docs/decisions/log.md || true
fi
# Name every decision input skipped here, even when other triggers printed: a
# reader of this section alone must see that some were not read.
if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]; then
  echo
  printf '%s\n' "${SKIPPED[@]:$n_before_triggers}" | sort -u | while IFS= read -r p; do
    echo "Not read: $p is not a plain file or directory (section 8); its triggers are missing above."
  done
fi
if [[ $found -eq 0 ]]; then
  if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]; then echo "No revisit triggers in the decision inputs that were read; the skipped ones above were not read."
  else echo "No revisit triggers recorded."; fi
fi

printf '\n%s\n\n' "## 3. Watched questions (trigger and deferred routes)"
QS="$SCRIPT_DIR/questions.sh"
[[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"
QA=docs/working/questions-archive.md
# questions.sh checks that the archive exists with a test that follows a
# symlink, which would answer "does this host path exist?", so the archive
# passes the same check first. It is checked once, up front, so a non-plain
# archive is listed in section 8 whatever branch below runs.
qa_at=""; skipped "$QA" && qa_at="$SKIP_AT"
nc="**Watched questions were NOT checked** —"
if skipped docs/working/questions.md; then
  echo "$nc $(skipnote docs/working/questions.md)"
elif ! inrepo docs/working/questions.md; then
  echo "No docs/working/questions.md in this repo."
elif [[ ! -f "$QS" ]]; then
  echo "$nc questions.sh was not found (next to this script or in ~/.claude/scripts)."
elif [[ -n "$qa_at" ]]; then
  SKIP_AT="$qa_at"; echo "$nc $(skipnote "$QA")"
else
  qs_err="$(mktemp)"; trap 'rm -f "$qs_err"' EXIT
  if open_q="$(bash "$QS" open 2>"$qs_err")"; then
    # `open` prints "ID  route  slug" in columns of 2+ spaces; a route can
    # contain one space ("you: judgment"), a slug can contain "trigger".
    watched="$(printf '%s\n' "$open_q" | awk -F'  +' '$2 == "trigger" || $2 == "deferred"')"
    if [[ -n "$watched" ]]; then
      while IFS= read -r line; do echo "- $line"; done <<< "$watched"
    else
      echo "None open."
    fi
    echo
    routes="$(printf '%s\n' "$open_q" | awk -F'  +' 'NF >= 2 { print $2 }' | sort | uniq -c | awk '{ c = $1; $1 = ""; printf "%s%s=%s", sep, substr($0, 2), c; sep = ", " }')"
    echo "Open by route: ${routes:-none}"
  else
    echo "$nc questions.sh open failed. Its error:"
    echo
    echo '```'; cat "$qs_err"; echo '```'
  fi
fi

printf '\n%s\n\n' "## 4. Spot-check sample"
if [[ -n "$merges" && "$SAMPLE" -gt 0 ]]; then
  # Seeded by a hash of the date: same day, same merges; different days usually
  # differ. (The raw date seeded almost nothing: dates share their first bytes.)
  seed="$(printf '%s' "$TODAY" | sha256sum | cut -c1-64)"
  printf '%s\n' "$merges" | shuf -n "$SAMPLE" --random-source=<(yes "$seed") | sed 's/^/- /'
else
  if [[ -z "$merges" ]]; then echo "No merges in the window to sample."; else echo "Sample size 0: no spot-check requested."; fi
fi

printf '\n%s\n\n' "## 5. Roadmap"
if inrepo docs/roadmap.md; then
  d="$(git log -1 --format=%ad --date=short -- docs/roadmap.md)"
  echo "docs/roadmap.md last committed on this branch: ${d:-never, uncommitted}. Its Next section:"
  echo
  awk '{ sub(/\r$/, ""); t = tolower($0) } t == "## next" || index(t, "## next ") == 1 || index(t, "## next(") == 1 { on = 1; next } on && /^## / { exit } on && NF { print "> " $0 }' docs/roadmap.md
elif skipped docs/roadmap.md; then
  skipnote docs/roadmap.md
else
  echo "No docs/roadmap.md yet — create it this cycle from the template in the dev-cycle skill."
fi

printf '\n%s\n\n' "## 6. Merges with code but no docs"
# A merge whose diff against its first parent touches files but no doc (a path
# under docs/, a *.md file, or a file named README or README.*, all any case): step 4
# checks each one (rule: undocumented is broken). Listed up to 30.
flagged=()
while read -r _ full rest; do
  [[ -n "$full" ]] || continue
  counts="$(git diff --name-only -z "$full^1" "$full" | awk -v RS='\0' 'NF { b = tolower($0); sub(/.*\//, "", b); p = tolower($0); if (p ~ /^docs\// || p ~ /\.md$/ || b == "readme" || index(b, "readme.") == 1) d++; else c++ } END { print c + 0, d + 0 }')"
  read -r n_code n_docs <<< "$counts"
  [[ "$n_code" -gt 0 && "$n_docs" -eq 0 ]] && flagged+=("- $rest ($n_code file(s), no doc change)")
done <<< "$merges_full"
if [[ ${#flagged[@]} -eq 0 ]]; then
  echo "None in the window."
else
  printf '%s\n' "${flagged[@]:0:30}"
  [[ ${#flagged[@]} -le 30 ]] || echo "… $((${#flagged[@]} - 30)) more"
fi

printf '\n%s\n\n' "## 7. Inputs for steps 4b and 5"
# Every file any first-parent commit in the window touched (a merge counts its
# diff against its first parent), not a net diff: a change reverted inside the
# window still counts. "@" lines carry each commit's date. core.quotePath=false
# prints non-ASCII names as they are; git still quotes a name holding a control
# character (so each name is one line), and the patterns below accept the quote.
changed="$(git -c core.quotePath=false log "$MAIN_SHA" --first-parent --diff-merges=first-parent --name-only --format='@%cs' -- skills workflows docs/decisions \
  | awk -v s="$SINCE" '/^@/ { on = (substr($0, 2) >= s); next } on && NF' | sort -u)"
skills_changed="$(printf '%s\n' "$changed" | grep -E '^"?(skills|workflows)/' || true)"
records_changed="$(printf '%s\n' "$changed" | grep -E '^"?docs/decisions/[0-9]{3}-[^/]*\.md"?$' || true)"
echo "Step 4b (deep-audit triggers). The model version is not in git: compare it with the last cycle record's."
for kind in skills records; do
  if [[ $kind == skills ]]; then list="$skills_changed"; label="Skill or workflow files changed on \`$MAIN\` in the window"
  else list="$records_changed"; label="Decision records added or changed on \`$MAIN\` in the window (is any a major design decision?)"; fi
  n="$(printf '%s' "$list" | grep -c . || true)"
  echo "- $label: $n"
  [[ -z "$list" ]] || printf '%s\n' "$list" | sed -n '1,20s/^/    - /p'
  [[ "$n" -le 20 ]] || echo "    - … $((n - 20)) more"
done
echo
echo "Step 5 (brainstorm triggers; the thresholds are the skill's):"
if inrepo docs/roadmap.md; then
  for sec in Now "In flight" Next; do
    n="$(awk -v h="## $sec" '{ sub(/\r$/, ""); t = tolower($0); g = tolower(h) } t == g || index(t, g " ") == 1 || index(t, g "(") == 1 { on = 1; next } on && /^## / { exit } on && /^([-*] |[0-9]+\. )/ { c++ } END { print c + 0 }' docs/roadmap.md)"
    echo "- Roadmap $sec: $n item(s)"
  done
elif skipped docs/roadmap.md; then
  echo "- $(skipnote docs/roadmap.md)"
else
  echo "- Roadmap: none yet (nothing to brief)"
fi
LOG=docs/working/idea-log.md
if inrepo "$LOG"; then
  # The skill's step 5 appends "## Brainstorm YYYY-MM-DD" after reading the log
  # (its ideas go to the roadmap); seeding appends "- <idea> (signal: …)" lines,
  # and only lines of that shape count.
  # No {n} intervals in the awk regex: mawk, Debian's default awk, lacks them.
  last_bs="$(grep -oE '^## Brainstorm [0-9]{4}-[0-9]{2}-[0-9]{2}' "$LOG" | tail -1 | cut -d' ' -f3 || true)"
  seeded="$(awk '/^## Brainstorm [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ { c = 0; next } /^- [^ ]/ && index(substr($0, 4), "(signal: ") && /\)[[:space:]]*$/ { c++ } END { print c + 0 }' "$LOG")"
  if [[ -n "$last_bs" ]] && date -d "$last_bs" >/dev/null 2>&1; then
    echo "- Last brainstorm: $last_bs ($(( ($(date -d "$TODAY" +%s) - $(date -d "$last_bs" +%s)) / 86400 )) day(s) ago)"
  else
    echo "- Last brainstorm: none recorded in $LOG"
  fi
  echo "- Ideas seeded since: $seeded"
elif skipped "$LOG"; then
  echo "- $(skipnote "$LOG")"
else
  echo "- No $LOG: no ideas seeded, no brainstorm recorded"
fi

# The dev-cycle skill also reads these; they are checked here so that a
# non-plain one is listed below like every other input.
skipped docs/dev-cycle.md || true
skipdir docs/working/briefs || true

printf '\n%s\n\n' "## 8. Skipped inputs"
if [[ ${#SKIPPED[@]} -eq 0 ]]; then
  echo "None: no input was skipped."
else
  echo "Each is a symlink, or a file or directory of the wrong kind, so it was not read; nothing below a listed directory was read or probed:"
  printf '%s\n' "${SKIPPED[@]}" | sort -u | sed 's/^/- /'
fi
