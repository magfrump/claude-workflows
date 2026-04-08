#!/usr/bin/env bash
# Reads ~/.claude/logs/usage.jsonl and reports skill/workflow usage frequency,
# recency, and which skills/workflows have never been invoked.
# Output: ranked table to stdout.
#
# Usage:
#   scripts/skill-usage-report.sh [OPTIONS]
#
# Options:
#   --project=NAME   Filter to a single project (default: all projects)
#   --markdown        Output as markdown summary report

set -euo pipefail

# Verify jq is available (required for log parsing)
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed." >&2; exit 1; }

# Parse options
PROJECT_FILTER=""
MARKDOWN=0
for arg in "$@"; do
  case "$arg" in
    --project=*) PROJECT_FILTER="${arg#--project=}" ;;
    --markdown) MARKDOWN=1 ;;
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
  if [ "$MARKDOWN" -eq 1 ]; then
    echo "# Skill Usage Report"
    echo ""
    echo "No usage data found at \`$USAGE_LOG\`"
    echo ""
    if [ ${#all_known[@]} -gt 0 ]; then
      echo "## Unused Skills & Workflows"
      echo ""
      for item in "${all_known[@]}"; do
        echo "- ${item#*:} (${item%%:*})"
      done
    fi
  else
    echo "No usage data found at $USAGE_LOG"
    echo ""
    if [ ${#all_known[@]} -gt 0 ]; then
      echo "Never invoked:"
      for item in "${all_known[@]}"; do
        echo "  ${item#*:} (${item%%:*})"
      done
    fi
  fi
  exit 0
fi

# Extract frequency and last-used per event+name pair, with project list
# Output: lines of "count event name last_ts projects"
# Use unit separator (\x1f) as internal key delimiter to avoid issues with
# names containing colons or other common characters
SEP=$'\x1f'
usage_data=$(jq -r --arg pf "$PROJECT_FILTER" \
  'select(.event and .name and (if $pf != "" then .project == $pf else true end)) | [.event, .name, .ts, .project] | @tsv' "$USAGE_LOG" \
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

# --- Compute date range from log ---

date_range=""
if [ -n "$usage_data" ]; then
  earliest=$(jq -r --arg pf "$PROJECT_FILTER" \
    'select(.event and .name and .ts and (if $pf != "" then .project == $pf else true end)) | .ts' "$USAGE_LOG" \
    | sort | head -1)
  latest=$(jq -r --arg pf "$PROJECT_FILTER" \
    'select(.event and .name and .ts and (if $pf != "" then .project == $pf else true end)) | .ts' "$USAGE_LOG" \
    | sort | tail -1)
  if [ -n "$earliest" ] && [ -n "$latest" ]; then
    date_range="${earliest} to ${latest}"
  fi
fi

# --- Compute workflow completion rates ---
# The hook logs workflow *reads* (file opens), not explicit start/finish events.
# As a rough proxy: count unique branches per workflow — a branch that read a
# workflow likely attempted to follow it.  Without explicit completion signals
# this is the best available heuristic.

declare -A wf_branches  # workflow -> unique branch count
declare -A wf_total     # workflow -> total reads

if [ -n "$usage_data" ]; then
  while IFS=$'\t' read -r _count event name _last_ts _projects; do
    if [ "$event" = "workflow" ]; then
      wf_total["$name"]=$_count
    fi
  done <<< "$usage_data"

  # Count unique branches per workflow from raw log
  if [ ${#wf_total[@]} -gt 0 ]; then
    while IFS=$'\t' read -r wf_name branch_count; do
      wf_branches["$wf_name"]=$branch_count
    done < <(jq -r --arg pf "$PROJECT_FILTER" \
      'select(.event == "workflow" and .name and (if $pf != "" then .project == $pf else true end)) | [.name, .branch] | @tsv' "$USAGE_LOG" \
      | sort -u | awk -F'\t' '{ count[$1]++ } END { for (k in count) printf "%s\t%d\n", k, count[k] }')
  fi
fi

# --- Build output ---

declare -A seen

if [ "$MARKDOWN" -eq 1 ]; then
  # --- Markdown output ---

  echo "# Skill Usage Report"
  echo ""

  if [ -n "$PROJECT_FILTER" ]; then
    echo "**Project:** $PROJECT_FILTER"
    echo ""
  fi

  if [ -n "$date_range" ]; then
    echo "**Date range:** $date_range"
    echo ""
  fi

  echo "## Invocation Counts"
  echo ""
  echo "| Name | Type | Count | Last Used | Projects |"
  echo "|------|------|------:|-----------|----------|"

  if [ -n "$usage_data" ]; then
    while IFS=$'\t' read -r count event name last_ts projects; do
      echo "| $name | $event | $count | $last_ts | $projects |"
      seen["$event:$name"]=1
    done <<< "$usage_data"
  fi

  # Never-invoked
  never_invoked=()
  for item in "${all_known[@]}"; do
    if [ -z "${seen[$item]:-}" ]; then
      never_invoked+=("$item")
    fi
  done

  if [ ${#never_invoked[@]} -gt 0 ]; then
    echo ""
    echo "## Unused Skills & Workflows"
    echo ""
    for item in "${never_invoked[@]}"; do
      echo "- ${item#*:} (${item%%:*})"
    done
  fi

  # Workflow completion rates
  echo ""
  echo "## Workflow Completion Rates"
  echo ""

  if [ ${#wf_total[@]} -gt 0 ]; then
    echo "| Workflow | Reads | Unique Branches | Reads/Branch |"
    echo "|----------|------:|----------------:|-------------:|"
    for wf in $(echo "${!wf_total[@]}" | tr ' ' '\n' | sort); do
      reads=${wf_total[$wf]}
      branches=${wf_branches[$wf]:-0}
      if [ "$branches" -gt 0 ]; then
        ratio=$(awk "BEGIN { printf \"%.1f\", $reads / $branches }")
      else
        ratio="—"
      fi
      echo "| $wf | $reads | $branches | $ratio |"
    done
    echo ""
    echo "_Note: Hook logs record workflow file reads, not explicit start/finish events. Reads/Branch approximates engagement depth._"
  else
    echo "_No workflow usage data available._"
  fi

else
  # --- Plain text output (original) ---

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

  # Never-invoked items
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
fi
