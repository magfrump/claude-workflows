#!/usr/bin/env bash
# Gather the mechanical signals for one dev cycle into a markdown digest.
#
# The dev-cycle skill (skills/dev-cycle/SKILL.md) runs the judgment steps —
# health triage, revisit-trigger verdicts, spot-check audits, brainstorming,
# roadmap updates — on top of this digest. Everything that needs no judgment
# lives here, because this repo's evidence is that steps only prose asks for do
# not run (scripts/questions.sh header; Q-074).
#
# Usage: scripts/dev-cycle.sh [--since YYYY-MM-DD] [--sample N]
#
#   --since   start of the cycle window. Default: the date in the newest
#             docs/working/cycles/cycle-YYYY-MM-DD.md, else 14 days ago.
#   --sample  how many merges to sample for the spot-check audit (default 2).
#
# Acts on the git repo of $PWD (like questions.sh), so the installed copy at
# ~/.claude/scripts/dev-cycle.sh serves any project. Read-only: prints to
# stdout and writes nothing.

set -euo pipefail

SINCE=""
SAMPLE=2
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) SINCE="${2:?--since needs a date}"; shift 2 ;;
    --since=*) SINCE="${1#--since=}"; shift ;;
    --sample) SAMPLE="${2:?--sample needs a number}"; shift 2 ;;
    --sample=*) SAMPLE="${1#--sample=}"; shift ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ "$SAMPLE" =~ ^[0-9]+$ ]] || { echo "--sample must be a non-negative integer" >&2; exit 1; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TODAY="$(date +%F)"
# No origin/HEAD (a local-only repo) is normal; fall back to main.
MAIN="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || true)"
[[ -n "$MAIN" ]] || MAIN=main

if [[ -z "$SINCE" ]]; then
  last=""
  for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
    [[ -f "$f" ]] || continue
    d="${f##*/cycle-}"; d="${d%.md}"
    [[ "$d" > "$last" ]] && last="$d"
  done
  SINCE="${last:-$(date -d '14 days ago' +%F)}"
fi
[[ "$SINCE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "--since must be YYYY-MM-DD" >&2; exit 1; }

echo "# Dev-cycle digest — $TODAY"
echo
echo "Window: since $SINCE, on \`$MAIN\` at $(git rev-parse --short "$MAIN")."

echo
echo "## 1. Activity"
merges="$(git log "$MAIN" --first-parent --merges --since="$SINCE" --format='%h %ad %s' --date=short)"
commits="$(git rev-list --count --since="$SINCE" "$MAIN")"
echo
echo "$(printf '%s' "$merges" | grep -c . || true) merge(s), $commits commit(s) on \`$MAIN\` in the window."
[[ -n "$merges" ]] && { echo; echo '```'; printf '%s\n' "$merges" | head -30; echo '```'; }

echo
echo "## 2. Revisit triggers"
echo
echo "Decide each: fired / not fired / cannot tell, with the evidence. A fired trigger becomes a questions.md entry."
found=0
for f in docs/decisions/[0-9][0-9][0-9]-*.md; do
  [[ -f "$f" ]] || continue
  grep -q '^## Revisit triggers' "$f" || continue
  found=1
  echo
  echo "### $f (last changed $(git log -1 --format=%ad --date=short -- "$f"))"
  awk '/^## Revisit triggers/ { on = 1; next } on && /^## / { exit } on && NF { print }' "$f"
done
if [[ -f docs/decisions/log.md ]]; then
  rows="$(grep -E '^\| [0-9]+ \|' docs/decisions/log.md | grep -i 'revisit' || true)"
  if [[ -n "$rows" ]]; then
    found=1
    echo
    echo "### docs/decisions/log.md rows"
    printf '%s\n' "$rows" | while IFS= read -r row; do
      n="$(printf '%s' "$row" | awk -F'|' '{ gsub(/ /, "", $2); print $2 }')"
      text="$(printf '%s' "$row" | grep -oiE 'revisit[^|]*' | head -1 | cut -c1-400)"
      echo "- row $n: $text"
    done
  fi
fi
[[ $found -eq 1 ]] || echo "No revisit triggers recorded."

echo
echo "## 3. Watched questions (trigger and deferred routes)"
echo
QS="$SCRIPT_DIR/questions.sh"
[[ -x "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"
if [[ -f docs/working/questions.md && -f "$QS" ]]; then
  # `open` prints "ID  route  slug" in columns of 2+ spaces; a route can
  # contain one space ("you: judgment"), a slug can contain the word "trigger".
  open_q="$(bash "$QS" open 2>/dev/null || true)"
  watched="$(printf '%s\n' "$open_q" | awk -F'  +' '$2 == "trigger" || $2 == "deferred"')"
  if [[ -n "$watched" ]]; then
    while IFS= read -r line; do echo "- $line"; done <<< "$watched"
  else
    echo "None open."
  fi
  echo
  echo "Open by route: $(printf '%s\n' "$open_q" | awk -F'  +' 'NF >= 2 { print $2 }' | sort | uniq -c | awk '{ c = $1; $1 = ""; printf "%s%s=%s", sep, substr($0, 2), c; sep = ", " }')"
else
  echo "No docs/working/questions.md (or questions.sh) in this repo."
fi

echo
echo "## 4. Spot-check sample"
echo
if [[ -n "$merges" && "$SAMPLE" -gt 0 ]]; then
  # Seeded by the date so a rerun on the same day audits the same merges.
  printf '%s\n' "$merges" | shuf -n "$SAMPLE" --random-source=<(yes "$TODAY") | sed 's/^/- /'
else
  echo "No merges in the window to sample."
fi

echo
echo "## 5. Roadmap"
echo
if [[ -f docs/roadmap.md ]]; then
  echo "docs/roadmap.md last changed $(git log -1 --format=%ad --date=short -- docs/roadmap.md 2>/dev/null || echo 'never (uncommitted)'). Its Next section:"
  echo
  awk '/^## Next/ { on = 1; next } on && /^## / { exit } on && NF { print }' docs/roadmap.md
else
  echo "No docs/roadmap.md yet — create it this cycle."
fi
