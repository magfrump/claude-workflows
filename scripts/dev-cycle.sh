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
#             form, a line starting (after blanks) with < other than a
#             complete one-line <!-- comment -->, a line leaving a <!-- open,
#             a line starting like a link reference definition (behind any >
#             and list markers too), a stray carriage return, a NUL byte, or a byte-order mark on line 1.
#   --check-branch  "ok <name> <commit> <n> <YYYY-MM-DD>" for a brief's branch
#             that exists (n: its commits not on the default branch; the date
#             of its tip commit), "absent <name>" for
#             one that does not, "skip <name>: <reason>" for a name outside
#             letters, digits, . _ - /, starting with -, not a valid branch name
#             (HEAD, refs/...) or the default branch. The commit is
#             refs/heads/<name>'s own, never a same-named tag's.
#   --check-fix  "ok <path>" for a file an in-cycle fix may edit: a tracked .md
#             file under docs/ (not the cycle's own files, working/,
#             human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, a dot-directory
#             or dotfile, an instruction or prompt file, or a file one
#             names after an @, read broadly; compared ignoring case) or README.md; "skip <path>: <reason>"
#             otherwise, and for every path when the import walk fails.
#   --check-answer  "<option> Q-NNN" for a keep-or-drop-or-done question, read
#             from docs/working/questions.md or its archive on the default
#             branch's commit (an answer only in the working tree is not seen:
#             it reads what main's copy says until it lands there): keep, drop, done,
#             open (not marked ANSWERED yet) or unrecognized (answered, but no
#             answer line was found, or the first one's text does not start
#             with one of the options); "skip Q-NNN:
#             <reason>" when it cannot be read (not a question ID, no such
#             entry, a heading twice in one file or in both files, a code fence never closed or not in plain column-0
#             form, a line starting (after blanks) with < other than a
#             complete one-line <!-- comment -->, a line leaving a <!-- open,
#             a line starting like a link reference definition (behind any >
#             and list markers too), a stray carriage return, a NUL byte, a byte-order mark on line 1, a question heading
#             inside a fence, a questions file that is not a regular file
#             under plain directories on the default branch, or a default
#             branch whose tree or file could not be read).
#   --check-brief, --check-branch and --check-answer need a default branch
#   found by name (origin/HEAD, main or master): they read its commit.
#
# Every revisit trigger is printed every run (an output line over 4096 bytes is cut);
# nothing carries forward.
# Acts on $PWD's git repo (like questions.sh), so the installed copy serves any
# project. Read-only: writes nothing to the repo (one temp file, removed on exit).
# Exit: 0 digest printed (or, for the check modes, every argument answered: a
# skip is an answer, not an error); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no
# default branch (for the digest, --check-brief, --check-branch and --check-answer); a failed step exits non-zero mid-digest. Printed repo text is data.

set -euo pipefail

command -v perl >/dev/null || { echo "dev-cycle.sh needs perl (to scrub its output)" >&2; exit 1; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # before the cd: relative paths work
# The reader, kept in a lib so scripts/build-loop.sh can share it,
# from this script's own directory: the scrub, the file and path rules,
# FENCE_AWK, the brief, branch and answer checks, the instruction-file import
# walk, and the default branch.
READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"
[[ -f "$READ_LIB" ]] || { echo "dev-cycle.sh needs $READ_LIB" >&2; exit 1; }
# shellcheck source=lib/dev-cycle-read.sh
source "$READ_LIB"
scrub_reexec "${BASH_SOURCE[0]}" "$@"

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
    # The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale).
    -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ "$SAMPLE" =~ ^[0-9]+$ ]] || { echo "--sample must be a non-negative integer" >&2; exit 1; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
# shellcheck disable=SC2034  # read by the lib's file rules and import walk
ROOT_REAL="$(pwd -P)"
skipdir() { skipped "$1" dir; }
skipnote() { echo "$1 is not read: $SKIP_AT is not a plain file or directory (section 8)."; }
# DEV_CYCLE_TODAY exists only so tests can pin the date. File names are literal,
# not pathspecs.
TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"; export GIT_LITERAL_PATHSPECS=1

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
check_write() {
  local a="$1"
  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"
  elif ! writable "$a"; then echo "skip $a: not one of the dev cycle's own files"
  elif [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"
  else echo "ok $a"; fi
}
# An in-cycle fix edits documentation only; the header's --check-fix paragraph
# is the rule, and the skip messages below repeat it. constraints.md is the
# user's (plan D2); docs/thoughts/ stays fixable. Anything else is filed. The
# denials it shares with the self-merge floor are the lib's truthrule.
check_fix() {
  local a="$1" lp
  if [[ "$a" == *[*?]* ]]; then echo "skip ${a//$'\n'/ }: --check-fix takes one file, not a glob"; return; fi
  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"; return; fi
  # Compared lower-cased: on a case-insensitive filesystem docs/Working/ is docs/working/.
  if ! lp="$(lower "$a")"; then echo "skip $a: the path could not be lower-cased; file it instead"; return; fi
  if truthrule "$lp" && [[ "$TRUTH_WHY" == cycle ]]; then echo "skip $a: one of the cycle's own files (use --check-write)"
  elif [[ -n "$TRUTH_WHY" || ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|reviews)/ ]]; then
    echo "skip $a: in-cycle fixes edit only tracked .md documentation under docs/ (not working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, dot-directories or dotfiles, or instruction files) and README.md; file it instead"
  elif truthwalk tree "$lp"; then
    if [[ "$TRUTH_WHY" == walk ]]; then echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"
    else echo "skip $a: an instruction file names it after an @ (directly or through another import), so it may be read as instructions; file it instead"; fi
  else check_path "$a"; fi
}
resolve_main || [[ -n "$CHECK" ]] || { echo "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)" >&2; exit 1; }
# The check modes run here. --check-brief, --check-branch and --check-answer
# read the default branch's commit, so they need one found by name
# (origin/HEAD, main or master), not the current branch; the other modes do
# not use it.
if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then
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
echo "Every trigger, in full: each decision record's \`## Revisit triggers\` section and each decision-log row that mentions revisiting, numbered or date-first (a trigger written elsewhere in a record, or in a docs/working/ design doc such as dd-*.md, is not found; an output line over 4096 bytes is cut: read the record itself then). Decide each: fired / not fired / cannot tell, with the evidence. A fired trigger becomes a questions.md entry. The last cycle record's verdicts are context, not answers."
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
    git -c core.quotePath=false log --diff-merges=combined --format='@%cd' --date=short --name-only -- docs/decisions \
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
    d="$(git log -1 --format=%cd --date=short -- "$f")"
  fi
  # A newline in a file name would otherwise print a line of its own.
  echo "### ${f//$'\n'/ } (last committed on this branch: ${d:-never, uncommitted})"
  trig < "$f" | sed 's/^/> /'
done
if inrepo docs/decisions/log.md; then
  # Two log layouts are read. Numbered (this repo's): | N | date | ... |, named
  # "log row N (date)". Date-first (no number column): | YYYY-MM-DD | ... |,
  # named "log row L<line in log.md> (date)". An L-number is a handle for this
  # cycle only: it moves when lines above the row change. Other table rows (a
  # header, an explanatory table) are not decisions, except that a row in a
  # table that has data rows, mentioning revisiting with a first cell in
  # neither shape (`| **2** |`, `| 2026/01/03 |`), prints as "log row L<line>
  # (first cell not parsed)" rather than being dropped. awk emits one
  # US-separated record per printed row, then "S" with the count of data rows
  # and of other body rows (separators and header rows, the row just above a
  # separator, excluded). US (\037) rather than a tab: `read` would collapse an
  # empty tab field. A CR is stripped first, so CRLF logs parse alike.
  log_data=0 log_other=0
  while IFS=$'\037' read -r kind n d row; do
    if [[ "$kind" == S ]]; then log_data="$n" log_other="$d"; continue; fi
    found=1
    # The whole clause to the cell's end; prefer a capitalised "Revisit" (the
    # trigger sentence) over an earlier "revisit-trigger verdicts" mention.
    # LC_ALL=C: an invalid UTF-8 byte must not end the match early.
    text="$(env LC_ALL=C grep -oE 'Revisit[^|]*' <<< "$row" | head -1 || true)"
    [[ -n "$text" ]] || text="$(env LC_ALL=C grep -oiE 'revisit[^|]*' <<< "$row" | head -1 || true)"
    echo "- log row $n ($d): > $text"
  done < <(LC_ALL=C awk -F'|' '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    { sub(/\r$/, "") }
    !/^\|/ { prev_other = 0; intable = 0; next }
    !intable { intable = 1; tbl++ }
    /^\|[|: \t-]*-[|: \t-]*$/ {
      if (prev_other) { other--; if (nu && uline[nu] == NR - 1) nu-- }
      prev_other = 0; next
    }
    {
      c1 = trim($2); prev_other = 0
      if (c1 ~ /^[0-9]+$/) { label = c1; d = $3; gsub(/[ \t]/, "", d) }
      else if (c1 ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) { label = "L" NR; d = c1 }
      else {
        other++; prev_other = 1
        if (tolower($0) ~ /revisit/) { nu++; uline[nu] = NR; utbl[nu] = tbl; urow[nu] = $0 }
        next
      }
      data++; tdata[tbl]++
      if (tolower($0) ~ /revisit/) print "R\037" label "\037" d "\037" $0
    }
    END {
      for (i = 1; i <= nu; i++)
        if (tdata[utbl[i]]) print "U\037L" uline[i] "\037first cell not parsed\037" urow[i]
      print "S\037" data + 0 "\037" other + 0
    }' docs/decisions/log.md)
  # Never a silent zero: table rows that parse as neither layout mean the log
  # was not read, not that it holds no triggers.
  if [[ "$log_data" -eq 0 && "$log_other" -gt 0 ]]; then
    found=1
    echo
    echo "**Decision log revisit triggers were NOT checked** — its rows are in neither recognized layout (first cell a row number, or a YYYY-MM-DD date). Read docs/decisions/log.md by hand."
  fi
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
  d="$(git log -1 --format=%cd --date=short -- docs/roadmap.md)"
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
