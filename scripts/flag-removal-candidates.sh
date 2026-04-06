#!/usr/bin/env bash
# Flags low-value skills/workflows as removal candidates based on:
#   1. REFUTED and INCONCLUSIVE-EXPIRED hypotheses in hypothesis-log.md
#   2. (Optional) Low-usage or never-invoked items from skill-usage-report.sh
#
# Output: Markdown report to stdout listing candidates with evidence and
# recommended actions. No auto-removal — human judgment required.
#
# Options:
#   --with-usage           Also run skill-usage-report.sh and include usage data
#   --usage-threshold=N    Flag items with fewer than N invocations (default: 2)
#   --hypothesis-log=PATH  Override path to hypothesis-log.md
#   --help                 Show this help message

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Defaults
HYPOTHESIS_LOG="$REPO_ROOT/docs/working/hypothesis-log.md"
WITH_USAGE=false
USAGE_THRESHOLD=2

# Parse options
for arg in "$@"; do
  case "$arg" in
    --with-usage) WITH_USAGE=true ;;
    --usage-threshold=*) USAGE_THRESHOLD="${arg#--usage-threshold=}" ;;
    --hypothesis-log=*) HYPOTHESIS_LOG="${arg#--hypothesis-log=}" ;;
    --help)
      sed -n '2,/^$/{ s/^# //; s/^#$//; p }' "$0"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# --- Hypothesis log analysis ---

hypothesis_candidates=()
hypothesis_evidence=()
hypothesis_outcomes=()

if [ ! -f "$HYPOTHESIS_LOG" ]; then
  echo "Warning: hypothesis log not found at $HYPOTHESIS_LOG" >&2
else
  # Parse markdown table rows for REFUTED or INCONCLUSIVE-EXPIRED outcomes.
  # Table format: | Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Status Date | Evidence |
  while IFS='|' read -r _ round task_id hypothesis window checked outcome status_date evidence _; do
    # Trim whitespace
    outcome="$(echo "$outcome" | xargs)"
    task_id="$(echo "$task_id" | xargs)"
    evidence="$(echo "$evidence" | xargs)"

    if [ "$outcome" = "REFUTED" ] || [ "$outcome" = "INCONCLUSIVE-EXPIRED" ]; then
      hypothesis_candidates+=("$task_id")
      hypothesis_evidence+=("$evidence")
      hypothesis_outcomes+=("$outcome")
    fi
  done < <(tail -n +3 "$HYPOTHESIS_LOG")
  # tail -n +3 skips the header and separator rows
fi

# --- Usage data analysis (optional) ---

usage_low=()
usage_low_counts=()
usage_low_last=()
usage_never=()

if [ "$WITH_USAGE" = true ]; then
  USAGE_SCRIPT="$SCRIPT_DIR/skill-usage-report.sh"
  if [ ! -x "$USAGE_SCRIPT" ]; then
    echo "Warning: skill-usage-report.sh not found or not executable at $USAGE_SCRIPT" >&2
  else
    usage_output="$("$USAGE_SCRIPT" 2>/dev/null)" || true

    # Parse the tabular section (skip header lines, stop at blank line)
    in_table=false
    while IFS= read -r line; do
      # Detect start of table after header
      if [[ "$line" =~ ^----  ]]; then
        in_table=true
        continue
      fi
      # Blank line ends table section
      if [ -z "$line" ]; then
        in_table=false
        continue
      fi

      if [ "$in_table" = true ]; then
        # Columns are printf-aligned, parse by position
        name="$(echo "$line" | awk '{print $1}')"
        count="$(echo "$line" | awk '{print $3}')"

        if [ -n "$count" ] && [ "$count" -lt "$USAGE_THRESHOLD" ] 2>/dev/null; then
          last="$(echo "$line" | awk '{print $4}')"
          usage_low+=("$name")
          usage_low_counts+=("$count")
          usage_low_last+=("$last")
        fi
      fi

      # Parse "Never invoked:" section
      if [[ "$line" =~ ^"  " ]] && [[ "$line" =~ \(skill\)$ || "$line" =~ \(workflow\)$ ]]; then
        item_name="$(echo "$line" | sed 's/^ *//' | awk '{print $1}')"
        item_type="$(echo "$line" | sed 's/.*(\(.*\))/\1/')"
        usage_never+=("$item_name ($item_type)")
      fi
    done <<< "$usage_output"
  fi
fi

# --- Generate report ---

echo "# Removal Candidates Report"
echo ""
echo "Generated: $(date -Iseconds)"
echo ""

has_candidates=false

# Hypothesis-based candidates
if [ ${#hypothesis_candidates[@]} -gt 0 ]; then
  has_candidates=true
  echo "## Failed Hypotheses"
  echo ""
  echo "These features had hypotheses that were **refuted** or **expired without evidence**,"
  echo "suggesting the feature may not be delivering expected value."
  echo ""

  for i in "${!hypothesis_candidates[@]}"; do
    task="${hypothesis_candidates[$i]}"
    outcome="${hypothesis_outcomes[$i]}"
    evidence="${hypothesis_evidence[$i]}"

    echo "### \`$task\`"
    echo ""
    echo "- **Outcome:** $outcome"
    echo "- **Evidence:** $evidence"

    if [ "$outcome" = "REFUTED" ]; then
      echo "- **Recommended action:** Review whether the feature should be revised or removed. The hypothesis was explicitly disproven."
    else
      echo "- **Recommended action:** Review whether the feature is actually being used. The hypothesis expired without evidence of impact."
    fi
    echo ""
  done
fi

# Usage-based candidates
if [ ${#usage_low[@]} -gt 0 ] || [ ${#usage_never[@]} -gt 0 ]; then
  has_candidates=true
  echo "## Low/No Usage"
  echo ""
  echo "These items have low or zero recorded invocations (threshold: <$USAGE_THRESHOLD)."
  echo ""

  if [ ${#usage_low[@]} -gt 0 ]; then
    echo "### Low Usage"
    echo ""
    echo "| Name | Invocations | Last Used |"
    echo "|------|-------------|-----------|"
    for i in "${!usage_low[@]}"; do
      echo "| ${usage_low[$i]} | ${usage_low_counts[$i]} | ${usage_low_last[$i]} |"
    done
    echo ""
  fi

  if [ ${#usage_never[@]} -gt 0 ]; then
    echo "### Never Invoked"
    echo ""
    for item in "${usage_never[@]}"; do
      echo "- $item"
    done
    echo ""
  fi

  echo "- **Recommended action:** Investigate whether these items serve a purpose not captured in usage logs (e.g., referenced by other scripts, used indirectly). If genuinely unused, consider removal."
  echo ""
fi

# Cross-reference section
if [ "$WITH_USAGE" = true ] && [ ${#hypothesis_candidates[@]} -gt 0 ] && { [ ${#usage_low[@]} -gt 0 ] || [ ${#usage_never[@]} -gt 0 ]; }; then
  # Find items that appear in both hypothesis failures and low/no usage
  cross_ref=()
  all_usage_items=(${usage_low[@]+"${usage_low[@]}"} ${usage_never[@]+"${usage_never[@]}"})
  for task in "${hypothesis_candidates[@]}"; do
    for usage_item in "${all_usage_items[@]}"; do
      # Check if task ID appears in the usage item name (fuzzy match)
      if [[ "$usage_item" == *"$task"* ]] || [[ "$task" == *"$usage_item"* ]]; then
        cross_ref+=("$task")
        break
      fi
    done
  done

  if [ ${#cross_ref[@]} -gt 0 ]; then
    echo "## High-Confidence Candidates"
    echo ""
    echo "These items appear in **both** failed hypotheses and low/no usage lists,"
    echo "making them strong removal candidates."
    echo ""
    for item in "${cross_ref[@]}"; do
      echo "- \`$item\`"
    done
    echo ""
  fi
fi

if [ "$has_candidates" = false ]; then
  echo "No removal candidates found."
  echo ""
fi

echo "---"
echo "*This report is advisory. All removal decisions require human judgment.*"
