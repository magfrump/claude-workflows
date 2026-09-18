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

# shellcheck source=lib/log-format.sh
source "$REPO_ROOT/scripts/lib/log-format.sh"
# For _locate_log_col (header-name column lookup). Sourcing only defines
# functions; it has no top-level side effects.
# shellcheck source=lib/si-morning-summary.sh
source "$REPO_ROOT/scripts/lib/si-morning-summary.sh"

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
ROUND_HISTORY="${ROUND_HISTORY_FILE:-${REPO_ROOT}/docs/working/round-history.json}"
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
  # round-history.json is a JSON array of round objects (self-improvement.sh
  # initialises it to [] and appends each finalized round log).
  if [ -f "$ROUND_HISTORY" ] && command -v jq >/dev/null 2>&1; then
    ROUND=$(jq -r 'map(.round) | max // empty' "$ROUND_HISTORY" 2>/dev/null || true)
  fi
  if [ -z "$ROUND" ]; then
    ROUND="?"
  fi
fi

# --- Parse hypothesis log for REFUTED and INCONCLUSIVE-EXPIRED entries ---
# Each line is a markdown table row; extract task ID, outcome, and evidence.
# Columns are located by header name, not position: the schema has grown
# (decision 012 added Evaluator + Requires, then Source), and a positional
# read silently took Evaluator as Outcome. Fallbacks are the legacy 8-column
# positions (awk field indices; field 1 is the empty text before the first |).
declare -a candidate_tasks=()
declare -A candidate_outcome=()
declare -A candidate_evidence=()
declare -A candidate_hypothesis=()

tid_col=$(_locate_log_col "$HYPOTHESIS_LOG" "Task ID")
hyp_col=$(_locate_log_col "$HYPOTHESIS_LOG" "Hypothesis")
outcome_col=$(_locate_log_col "$HYPOTHESIS_LOG" "Outcome")
evidence_col=$(_locate_log_col "$HYPOTHESIS_LOG" "Evidence")
[[ "$tid_col" -gt 0 ]] || tid_col=3
[[ "$hyp_col" -gt 0 ]] || hyp_col=4
[[ "$outcome_col" -gt 0 ]] || outcome_col=7
[[ "$evidence_col" -gt 0 ]] || evidence_col=9

# Emit "task_id<US>outcome<US>hypothesis<US>evidence" (US = \x1f) for
# flagged rows. Escaped pipes (\|, as append_approved_hypotheses writes them
# in hypothesis text) are masked before splitting so they don't shift columns.
while IFS=$'\x1f' read -r task_id outcome hypothesis evidence; do
  [ -n "$task_id" ] || continue
  candidate_tasks+=("$task_id")
  candidate_outcome["$task_id"]="$outcome"
  candidate_evidence["$task_id"]="$evidence"
  candidate_hypothesis["$task_id"]="$hypothesis"
done < <(awk -F'|' -v tc="$tid_col" -v hc="$hyp_col" -v oc="$outcome_col" -v ec="$evidence_col" '
    function field(i,   v) {
        v = $i
        gsub(/^[ \t]+|[ \t]+$/, "", v)
        gsub(/\036/, "\\|", v)
        return v
    }
    /^\|/ {
        # Assigning $0 re-splits the masked line on FS.
        line = $0
        gsub(/\\\|/, "\036", line)
        $0 = line
        outcome = field(oc)
        if (outcome != "REFUTED" && outcome != "INCONCLUSIVE-EXPIRED") next
        printf "%s\037%s\037%s\037%s\n", field(tc), outcome, field(hc), field(ec)
    }
' "$HYPOTHESIS_LOG")

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
      # Flat files (<dir>/<name>.md) plus directory-layout skills
      # (<dir>/<name>/SKILL.md), matched on the directory name.
      for f in "$dir"/*.md "$dir"/*/SKILL.md; do
        [ -f "$f" ] || continue
        basename_f="${f##*/}"
        [ "$basename_f" = "SKILL.md" ] && { basename_f="${f%/SKILL.md}"; basename_f="${basename_f##*/}"; }
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
