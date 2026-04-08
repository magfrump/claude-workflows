#!/usr/bin/env bash
# Flags workflows, skills, and guides that are candidates for removal or
# simplification based on evidence from the hypothesis log and optionally
# the skill-usage-report.
#
# Usage:
#   scripts/flag-removal-candidates.sh [OPTIONS]
#
# Evidence sources (per guides/subtraction-checklist.md):
#   1. Hypothesis log — REFUTED and INCONCLUSIVE-EXPIRED entries
#   2. Skill usage report — never-invoked items (optional, via --with-usage)
#
# Options:
#   --with-usage     Also run skill-usage-report.sh and include never-invoked items
#   --markdown       Output as markdown (default: plain text)
#   --round=N        Label output with round number (default: auto-detect)
#
# Exit codes:
#   0  Candidates found or no candidates
#   1  Required files missing or parse error

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- Color helpers (disabled when piped) ---
if [ -t 1 ]; then
  red()    { printf '\033[1;31m%s\033[0m\n' "$*"; }
  yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
  bold()   { printf '\033[1m%s\033[0m\n' "$*"; }
else
  red()    { printf '%s\n' "$*"; }
  yellow() { printf '%s\n' "$*"; }
  bold()   { printf '%s\n' "$*"; }
fi

# --- Parse options ---
WITH_USAGE=0
MARKDOWN=0
ROUND=""
for arg in "$@"; do
  case "$arg" in
    --with-usage) WITH_USAGE=1 ;;
    --markdown)   MARKDOWN=1 ;;
    --round=*)    ROUND="${arg#--round=}" ;;
    *)            echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# --- Configurable paths (env-var overrides for testing) ---
HYPOTHESIS_LOG="${HYPOTHESIS_LOG_FILE:-${REPO_ROOT}/docs/working/hypothesis-log.md}"
SKILLS_DIR="${SKILLS_DIR:-${REPO_ROOT}/skills}"
WORKFLOWS_DIR="${WORKFLOWS_DIR:-${REPO_ROOT}/workflows}"
GUIDES_DIR="${GUIDES_DIR:-${REPO_ROOT}/guides}"

# --- Validate required files ---
if [ ! -f "$HYPOTHESIS_LOG" ]; then
  echo "Error: hypothesis log not found at $HYPOTHESIS_LOG" >&2
  exit 1
fi

# --- Auto-detect round from round-history.json if not provided ---
if [ -z "$ROUND" ]; then
  round_history="${REPO_ROOT}/docs/working/round-history.json"
  if [ -f "$round_history" ] && command -v jq >/dev/null 2>&1; then
    ROUND=$(jq -r '.rounds | keys | map(tonumber) | max // empty' "$round_history" 2>/dev/null || true)
  fi
  if [ -z "$ROUND" ]; then
    ROUND="?"
  fi
fi

# --- Parse hypothesis log for REFUTED and INCONCLUSIVE-EXPIRED entries ---
# Each line is a markdown table row; extract task ID, outcome, and evidence.
declare -a candidate_tasks=()
declare -A candidate_outcome=()
declare -A candidate_evidence=()
declare -A candidate_hypothesis=()

while IFS='|' read -r _ _round task_id hypothesis _window _checked outcome _status_date evidence _; do
  # Trim whitespace from fields
  task_id="${task_id#"${task_id%%[![:space:]]*}"}"
  task_id="${task_id%"${task_id##*[![:space:]]}"}"
  outcome="${outcome#"${outcome%%[![:space:]]*}"}"
  outcome="${outcome%"${outcome##*[![:space:]]}"}"
  evidence="${evidence#"${evidence%%[![:space:]]*}"}"
  evidence="${evidence%"${evidence##*[![:space:]]}"}"
  hypothesis="${hypothesis#"${hypothesis%%[![:space:]]*}"}"
  hypothesis="${hypothesis%"${hypothesis##*[![:space:]]}"}"

  # Skip non-matching rows
  case "$outcome" in
    REFUTED|INCONCLUSIVE-EXPIRED) ;;
    *) continue ;;
  esac

  candidate_tasks+=("$task_id")
  candidate_outcome["$task_id"]="$outcome"
  candidate_evidence["$task_id"]="$evidence"
  candidate_hypothesis["$task_id"]="$hypothesis"
done < "$HYPOTHESIS_LOG"

# --- Map task IDs to files they likely created/modified ---
# Search for task IDs in git log commit messages to find affected files.
# Falls back to grepping the repo for references.
declare -A task_files=()
for task_id in "${candidate_tasks[@]}"; do
  files=""
  # Search skills, workflows, guides for files whose name resembles the task ID
  # Convert task ID to glob-friendly pattern (e.g., "strict-complexity-budget" -> "*strict*complexity*")
  for dir in "$SKILLS_DIR" "$WORKFLOWS_DIR" "$GUIDES_DIR"; do
    if [ -d "$dir" ]; then
      for f in "$dir"/*.md; do
        [ -f "$f" ] || continue
        basename_f="${f##*/}"
        # Check if the task ID appears as a substring in the filename
        if [[ "$basename_f" == *"${task_id}"* ]]; then
          files="${files:+${files}, }${f#"${REPO_ROOT}/"}"
        fi
      done
    fi
  done

  # Also search git log for commits mentioning this task ID
  if [ -z "$files" ] && command -v git >/dev/null 2>&1; then
    git_files=$(git -C "$REPO_ROOT" log --all --oneline --grep="$task_id" --name-only --pretty=format: 2>/dev/null \
      | grep -E '^(skills|workflows|guides)/' \
      | sort -u \
      | head -5 \
      || true)
    if [ -n "$git_files" ]; then
      files=$(echo "$git_files" | paste -sd', ' -)
    fi
  fi

  task_files["$task_id"]="${files:-<unknown — manual review needed>}"
done

# --- Collect usage data if requested ---
declare -a never_invoked=()
if [ "$WITH_USAGE" -eq 1 ]; then
  usage_script="${REPO_ROOT}/scripts/skill-usage-report.sh"
  if [ -f "$usage_script" ]; then
    # Capture the "Never invoked" section from usage report
    usage_output=$(bash "$usage_script" 2>/dev/null || true)
    in_never_section=0
    while IFS= read -r line; do
      if [[ "$line" == "Never invoked:"* ]]; then
        in_never_section=1
        continue
      fi
      if [ "$in_never_section" -eq 1 ]; then
        # Lines look like "  skill-name (skill)" — extract the name
        trimmed="${line#"${line%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
        if [ -z "$trimmed" ]; then
          in_never_section=0
          continue
        fi
        never_invoked+=("$trimmed")
      fi
    done <<< "$usage_output"
  else
    echo "Warning: skill-usage-report.sh not found at $usage_script" >&2
  fi
fi

# --- Output ---
total_candidates=$(( ${#candidate_tasks[@]} + ${#never_invoked[@]} ))

if [ "$MARKDOWN" -eq 1 ]; then
  # --- Markdown output ---
  echo "# Removal Candidates — Round ${ROUND}"
  echo ""
  echo "Date: $(date +%Y-%m-%d)"
  echo ""

  if [ ${#candidate_tasks[@]} -eq 0 ] && [ ${#never_invoked[@]} -eq 0 ]; then
    echo "No removal candidates identified."
    exit 0
  fi

  if [ ${#candidate_tasks[@]} -gt 0 ]; then
    echo "## Hypothesis-Based Candidates"
    echo ""
    for task_id in "${candidate_tasks[@]}"; do
      echo "### ${task_id}"
      echo "- **Outcome:** ${candidate_outcome[$task_id]}"
      echo "- **Affected files:** ${task_files[$task_id]}"
      echo "- **Hypothesis:** ${candidate_hypothesis[$task_id]}"
      echo "- **Evidence:** ${candidate_evidence[$task_id]}"
      echo "- **Recommendation:** _needs human review_"
      echo ""
    done
  fi

  if [ ${#never_invoked[@]} -gt 0 ]; then
    echo "## Never-Invoked Items (from usage report)"
    echo ""
    for item in "${never_invoked[@]}"; do
      echo "- ${item}"
    done
    echo ""
  fi

  echo "---"
  echo "_${total_candidates} candidate(s) flagged. See guides/subtraction-checklist.md for review procedure._"
else
  # --- Plain text output ---
  bold "Removal Candidates — Round ${ROUND}"
  echo ""

  if [ ${#candidate_tasks[@]} -eq 0 ] && [ ${#never_invoked[@]} -eq 0 ]; then
    echo "No removal candidates identified."
    exit 0
  fi

  if [ ${#candidate_tasks[@]} -gt 0 ]; then
    bold "Hypothesis-Based Candidates:"
    echo ""
    for task_id in "${candidate_tasks[@]}"; do
      yellow "  ${task_id} [${candidate_outcome[$task_id]}]"
      echo "    Files: ${task_files[$task_id]}"
      echo "    Hypothesis: ${candidate_hypothesis[$task_id]}"
      echo "    Evidence: ${candidate_evidence[$task_id]}"
      echo ""
    done
  fi

  if [ ${#never_invoked[@]} -gt 0 ]; then
    bold "Never-Invoked Items (from usage report):"
    echo ""
    for item in "${never_invoked[@]}"; do
      echo "  ${item}"
    done
    echo ""
  fi

  echo "${total_candidates} candidate(s) flagged. See guides/subtraction-checklist.md for review procedure."
fi
