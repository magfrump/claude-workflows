#!/usr/bin/env bash
# Reads ~/.claude/logs/usage.jsonl and reports skill/workflow usage frequency,
# recency, and which skills/workflows have never been invoked.
# Output: ranked table to stdout.
#
# Options:
#   --project=NAME   Filter to a single project (default: all projects)

set -euo pipefail

# Verify jq is available (required for log parsing)
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed." >&2; exit 1; }

# Parse options
PROJECT_FILTER=""
for arg in "$@"; do
  case "$arg" in
    --project=*) PROJECT_FILTER="${arg#--project=}" ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

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

# Build jq filter: optionally restrict to a single project
JQ_FILTER='select(.event and .name)'
if [ -n "$PROJECT_FILTER" ]; then
  JQ_FILTER="select(.event and .name and .project == \"$PROJECT_FILTER\")"
fi

# Extract frequency and last-used per event+name pair, with project list
# Output: lines of "count event name last_ts projects"
# Use unit separator (\x1f) as internal key delimiter to avoid issues with
# names containing colons or other common characters
SEP=$'\x1f'
usage_data=$(jq -r "$JQ_FILTER | [.event, .name, .ts, .project] | @tsv" "$USAGE_LOG" \
  | awk -F'\t' -v sep="$SEP" '{
      key = $1 sep $2
      count[key]++
      if ($3 > last[key]) last[key] = $3
      # Track unique projects per key
      proj_key = key sep $4
      if (!(proj_key in seen_proj)) {
        seen_proj[proj_key] = 1
        if (projects[key] == "")
          projects[key] = $4
        else
          projects[key] = projects[key] ", " $4
      }
    }
    END {
      for (k in count) {
        split(k, parts, sep)
        printf "%d\t%s\t%s\t%s\t%s\n", count[k], parts[1], parts[2], last[k], projects[k]
      }
    }' \
  | sort -t$'\t' -k1,1nr -k4,4r)

# --- Build output table ---

# Track which known items were seen
declare -A seen

if [ -n "$PROJECT_FILTER" ]; then
  echo "Project: $PROJECT_FILTER"
  echo ""
fi

printf "%-30s %-10s %8s  %-20s  %s\n" "Name" "Type" "Count" "Last Used" "Projects"
printf "%-30s %-10s %8s  %-20s  %s\n" "----" "----" "-----" "---------" "--------"

if [ -n "$usage_data" ]; then
  while IFS=$'\t' read -r count event name last_ts projects; do
    printf "%-30s %-10s %8d  %-20s  %s\n" "$name" "$event" "$count" "$last_ts" "$projects"
    seen["$event:$name"]=1
  done <<< "$usage_data"
fi

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
