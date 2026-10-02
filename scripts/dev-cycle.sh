#!/usr/bin/env bash
# Gather the mechanical signals for one dev cycle into a markdown digest.
#
# The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps on
# top of this digest. Everything that needs no judgment lives here, because
# steps that only prose asks for do not run (scripts/questions.sh header; Q-074).
#
# Usage: scripts/dev-cycle.sh [--since=YYYY-MM-DD] [--sample=N]
#
#   --since   start of the cycle window: commits whose committer date, in the
#             committer's own time zone (git's %cs), is on or after this date.
#             Default: the date in the newest docs/working/cycles/cycle-YYYY-MM-DD.md
#             (only its file name is read), else 14 days ago. The digest says which.
#   --sample  how many merges to sample for the spot-check (default 2).
#
# Every revisit trigger is printed in full every run; nothing carries forward.
# Acts on $PWD's git repo (like questions.sh), so the installed copy serves any
# project. Read-only: writes nothing to the repo (one temp file, removed on exit).
# Exit: 0 digest printed; 1 bad usage, not a git repo, no default branch or no
# perl; a failed step exits non-zero mid-digest. Printed repo text is data.

set -euo pipefail

command -v perl >/dev/null || { echo "dev-cycle.sh needs perl (to scrub its output)" >&2; exit 1; }
# The one scrub for everything printed, stdout and stderr: drops C0 controls but
# TAB and LF, DEL, C1 controls (U+0080-009F), bidi controls (U+200E/F,
# U+202A-202E, U+2066-2069) and tag characters (U+E0000-E007F), and cuts lines
# longer than 4096 input bytes. Perl is pinned to bytes: PERL_UNICODE, PERL5OPT and PERLIO are
# removed (each can turn on UTF-8 decoding and switch the byte patterns off),
# -C0 is set, and both handles are binmoded. C0 goes first; after each deletion
# the search resumes 3 bytes before it (no sequence is longer than 4 bytes), so a
# control byte inside a sequence or a nested sequence cannot reassemble one;
# each pass is local, and the line cut bounds the total work. Not covered: lone
# bytes 0x80-0x9F and overlong encodings (invalid UTF-8, which a UTF-8 terminal
# does not decode), U+061C, U+2028/2029, and invisible format characters such as
# zero-width ones, U+00AD, U+206A-206F and U+FFF9-FFFB (none can start a line).
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
      last unless /\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xAA-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]/g;
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
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) SINCE="${2:?--since needs a date}"; shift 2 ;;
    --since=*) SINCE="${1#--since=}"; shift ;;
    --sample) SAMPLE="${2:?--sample needs a number}"; shift 2 ;;
    --sample=*) SAMPLE="${1#--sample=}"; shift ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ "$SAMPLE" =~ ^[0-9]+$ ]] || { echo "--sample must be a non-negative integer" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # before the cd: relative paths work
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
ROOT_REAL="$(pwd -P)"
# A regular file whose real path stays inside the repo: a committed symlink (to
# the file or a parent directory) must not make the digest print text from
# outside the checkout.
inrepo() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL"/* ]]; }
# DEV_CYCLE_TODAY exists only so tests can pin the date. File names are literal,
# not pathspecs.
TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"; export GIT_LITERAL_PATHSPECS=1
# Pass git only a hash for the default branch: origin/HEAD comes from the remote,
# and a branch named `--output=<path>` would reach `git log` as an option.
MAIN=""; MAIN_SHA=""
candidates=()
origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
[[ -n "$origin_head" ]] && candidates+=("${origin_head#origin/}")
candidates+=(main master)
for c in "${candidates[@]}"; do
  [[ "$c" == -* ]] && continue
  sha="$(git rev-parse --verify --quiet "refs/heads/$c^{commit}" 2>/dev/null || true)"
  if [[ -n "$sha" ]]; then MAIN="$c"; MAIN_SHA="$sha"; break; fi
done
if [[ -z "$MAIN_SHA" ]]; then
  # A repo on some other branch name: use the current branch.
  cur="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  if [[ -n "$cur" && "$cur" != -* ]]; then
    MAIN="$cur"; MAIN_SHA="$(git rev-parse --verify --quiet HEAD 2>/dev/null || true)"
  fi
fi
[[ -n "$MAIN_SHA" ]] || { echo "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)" >&2; exit 1; }

last_record=""
for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
  inrepo "$f" || continue
  d="${f##*/cycle-}"; d="${d%.md}"
  [[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"  # ignore future-dated
done
if [[ -n "$SINCE" ]]; then
  source_note="--since"
elif [[ -n "$last_record" ]]; then
  SINCE="$last_record"; source_note="the last cycle record, docs/working/cycles/cycle-$last_record.md"
else
  SINCE="$(date -d "$TODAY - 14 days" +%F)"
  source_note="no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)"
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
echo "Every trigger, in full. Decide each: fired / not fired / cannot tell, with the evidence. A fired trigger becomes a questions.md entry. The last cycle record's verdicts are context, not answers."
found=0
trig() { awk '/^## Revisit triggers/ { on = 1; next } on && /^## / { exit } on && NF { print }'; }
for f in docs/decisions/[0-9][0-9][0-9]-*.md; do
  inrepo "$f" || continue
  grep -q '^## Revisit triggers' "$f" || continue
  found=1
  echo
  d="$(git log -1 --format=%ad --date=short -- "$f")"
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
fi
[[ $found -eq 1 ]] || echo "No revisit triggers recorded."

printf '\n%s\n\n' "## 3. Watched questions (trigger and deferred routes)"
QS="$SCRIPT_DIR/questions.sh"
[[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"
if inrepo docs/working/questions.md && [[ -f "$QS" ]]; then
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
    echo "Open by route: $(printf '%s\n' "$open_q" | awk -F'  +' 'NF >= 2 { print $2 }' | sort | uniq -c | awk '{ c = $1; $1 = ""; printf "%s%s=%s", sep, substr($0, 2), c; sep = ", " }')"
  else
    echo "**questions.sh open failed** — watched questions were NOT checked. Its error:"
    echo
    echo '```'; cat "$qs_err"; echo '```'
  fi
else
  echo "No docs/working/questions.md (or questions.sh) in this repo."
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
  awk '{ t = tolower($0) } t == "## next" || index(t, "## next ") == 1 || index(t, "## next(") == 1 { on = 1; next } on && /^## / { exit } on && NF { print "> " $0 }' docs/roadmap.md
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
skills_changed="$(printf '%s\n' "$changed" | grep -E '^"?(skills/.*/SKILL\.md|workflows/[^/]*\.md)"?$' || true)"
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
    n="$(awk -v h="## $sec" '{ t = tolower($0); g = tolower(h) } t == g || index(t, g " ") == 1 || index(t, g "(") == 1 { on = 1; next } on && /^## / { exit } on && /^([-*] |[0-9]+\. )/ { c++ } END { print c + 0 }' docs/roadmap.md)"
    echo "- Roadmap $sec: $n item(s)"
  done
else
  echo "- Roadmap: none yet (0 items ready for 6b)"
fi
LOG=docs/working/idea-log.md
if inrepo "$LOG"; then
  # The skill's step 5 appends "## Brainstorm YYYY-MM-DD" after reading the log
  # (its ideas go to the roadmap); seeding appends "- <idea> (signal: …)" lines,
  # and only lines of that shape count.
  # No {n} intervals in the awk regex: mawk, Debian's default awk, lacks them.
  last_bs="$(grep -oE '^## Brainstorm [0-9]{4}-[0-9]{2}-[0-9]{2}' "$LOG" | tail -1 | cut -d' ' -f3 || true)"
  seeded="$(awk '/^## Brainstorm [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ { c = 0; next } /^- [^ ].*\(signal: .*\)[[:space:]]*$/ { c++ } END { print c + 0 }' "$LOG")"
  if [[ -n "$last_bs" ]] && date -d "$last_bs" >/dev/null 2>&1; then
    echo "- Last brainstorm: $last_bs ($(( ($(date -d "$TODAY" +%s) - $(date -d "$last_bs" +%s)) / 86400 )) day(s) ago)"
  else
    echo "- Last brainstorm: none recorded in $LOG"
  fi
  echo "- Ideas seeded since: $seeded"
else
  echo "- No $LOG: no ideas seeded, no brainstorm recorded"
fi
