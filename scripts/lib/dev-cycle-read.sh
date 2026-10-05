#!/bin/bash
# The dev cycle's reader, used by scripts/dev-cycle.sh and kept apart so the
# planned scripts/build-loop.sh can share it: the output scrub, the plain-file
# and path-form rules, and the cycle's own file names.
#
# Sourced, never run: it only defines functions and variables. Each script
# sources it from its own directory (never from the repo it acts on), so a copy
# of scripts/ with its lib/ is self-contained. The caller sets -euo pipefail,
# cds to the repo root and sets ROOT_REAL (that root, symlinks resolved) before
# calling any file check. inrepo, dirok and skipped exit 1 (need_root) unless
# ROOT_REAL is set, is the current directory and is a repository's top level;
# while ROOT_REAL is unset, rawfile, plaindir and blocker read nothing as plain.
# Call the exiting checks in the caller's shell, not inside $(...) or
# `local x="$(...)"`, where an exit ends only the subshell. skipped records each
# blocked input in SKIPPED and SKIP_AT. Every script that calls scrub_reexec
# shares its DEV_CYCLE_SCRUBBED marker.

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
