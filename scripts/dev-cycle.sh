#!/usr/bin/env bash
# Gather the mechanical signals for one dev cycle into a markdown digest.
#
# The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps on
# top of this digest. Everything that needs no judgment lives here, because
# steps that only prose asks for do not run (scripts/questions.sh header; Q-074).
#
# Usage: scripts/dev-cycle.sh [--since=YYYY-MM-DD] [--sample=N]
#
#   --since   start of the cycle window: merges committed on or after this date.
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
# U+202A-202E, U+2066-2069) and tag characters (U+E0000-E007F). Byte patterns
# under LC_ALL=C, so invalid UTF-8 in a file name cannot make perl warn or die.
scrub() {
  LC_ALL=C perl -pe 's/\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xAA-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]//g; tr/\000-\010\013-\037\177//d'
}
exec > >(scrub) 2> >(scrub >&2)

SINCE=""
SAMPLE=2
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) SINCE="${2:?--since needs a date}"; shift 2 ;;
    --since=*) SINCE="${1#--since=}"; shift ;;
    --sample) SAMPLE="${2:?--sample needs a number}"; shift 2 ;;
    --sample=*) SAMPLE="${1#--sample=}"; shift ;;
    -h|--help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ "$SAMPLE" =~ ^[0-9]+$ ]] || { echo "--sample must be a non-negative integer" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # before the cd: relative paths work
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
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
  [[ -f "$f" ]] || continue
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
echo "Window: since $SINCE (from $source_note). Merges and commits: those on \`$MAIN\` at ${MAIN_SHA:0:7} committed on or after $SINCE, filtered by date after a full walk. Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree."

echo
echo "## 1. Activity"
# Walk all of history and filter by committer date afterwards: `--since` stops
# at the first old-dated commit, so one such commit hid every merge after it.
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
  [[ -f "$f" ]] || continue
  grep -q '^## Revisit triggers' "$f" || continue
  found=1
  echo
  d="$(git log -1 --format=%ad --date=short -- "$f")"
  # A newline in a file name would otherwise print a line of its own.
  echo "### ${f//$'\n'/ } (last committed on this branch: ${d:-never, uncommitted})"
  trig < "$f" | sed 's/^/> /'
done
if [[ -f docs/decisions/log.md ]]; then
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
if [[ -f docs/working/questions.md && -f "$QS" ]]; then
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
if [[ -f docs/roadmap.md ]]; then
  d="$(git log -1 --format=%ad --date=short -- docs/roadmap.md)"
  echo "docs/roadmap.md last committed on this branch: ${d:-never, uncommitted}. Its Next section:"
  echo
  awk '/^## Next/ { on = 1; next } on && /^## / { exit } on && NF { print "> " $0 }' docs/roadmap.md
else
  echo "No docs/roadmap.md yet — create it this cycle from the template in the dev-cycle skill."
fi
