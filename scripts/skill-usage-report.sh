#!/usr/bin/env bash
# Reads ~/.claude/logs/usage.jsonl and reports skill/workflow usage frequency,
# recency, and which skills/workflows have never been invoked.
# Output: ranked table to stdout.

set -euo pipefail

USAGE_LOG="${USAGE_LOG_FILE:-$HOME/.claude/logs/usage.jsonl}"
# Default to project-local directories; override with env vars for testing
SKILLS_DIR="${SKILLS_DIR:-$(cd "$(dirname "$0")/.." && pwd)/skills}"
WORKFLOWS_DIR="${WORKFLOWS_DIR:-$(cd "$(dirname "$0")/.." && pwd)/workflows}"

# --- Collect known skills and workflows ---

known_skills=()
if [ -d "$SKILLS_DIR" ]; then
  for f in "$SKILLS_DIR"/*.md; do
    [ -f "$f" ] || continue
    name="${f##*/}"
    name="${name%.md}"
    known_skills+=("skill:$name")
  done
fi

known_workflows=()
if [ -d "$WORKFLOWS_DIR" ]; then
  for f in "$WORKFLOWS_DIR"/*.md; do
    [ -f "$f" ] || continue
    name="${f##*/}"
    name="${name%.md}"
    known_workflows+=("workflow:$name")
  done
fi

all_known=(${known_skills[@]+"${known_skills[@]}"} ${known_workflows[@]+"${known_workflows[@]}"})

# --- Parse log ---

if [ ! -f "$USAGE_LOG" ] || [ ! -s "$USAGE_LOG" ]; then
  echo "No usage data found at $USAGE_LOG"
  echo ""
  if [ ${#all_known[@]} -gt 0 ]; then
    echo "Never invoked:"
    for item in "${all_known[@]}"; do
      echo "  ${item#*:} (${item%%:*})"
    done
  fi
  exit 0
fi

# Extract frequency and last-used per event+name pair
# Output: lines of "count event name last_ts"
usage_data=$(jq -r 'select(.event and .name) | [.event, .name, .ts] | @tsv' "$USAGE_LOG" \
  | awk -F'\t' '{
      key = $1 ":" $2
      count[key]++
      if ($3 > last[key]) last[key] = $3
    }
    END {
      for (k in count) {
        split(k, parts, ":")
        printf "%d\t%s\t%s\t%s\n", count[k], parts[1], parts[2], last[k]
      }
    }' \
  | sort -t$'\t' -k1,1nr -k4,4r)

# --- Build output table ---

# Track which known items were seen
declare -A seen

printf "%-30s %-10s %8s  %s\n" "Name" "Type" "Count" "Last Used"
printf "%-30s %-10s %8s  %s\n" "----" "----" "-----" "---------"

while IFS=$'\t' read -r count event name last_ts; do
  printf "%-30s %-10s %8d  %s\n" "$name" "$event" "$count" "$last_ts"
  seen["$event:$name"]=1
done <<< "$usage_data"

# --- Never-invoked items ---

never_invoked=()
for item in "${all_known[@]}"; do
  if [ -z "${seen[$item]:-}" ]; then
    never_invoked+=("$item")
  fi
done

if [ ${#never_invoked[@]} -gt 0 ]; then
  echo ""
  echo "Never invoked:"
  for item in "${never_invoked[@]}"; do
    printf "  %-30s (%s)\n" "${item#*:}" "${item%%:*}"
  done
fi
