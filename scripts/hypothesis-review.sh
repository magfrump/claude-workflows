#!/usr/bin/env bash
# Generate a hypothesis review questionnaire for human feedback.
#
# Reads TRACKING hypotheses from both the SI loop's hypothesis-log.md and the
# screening workflow's hypothesis-backlog.md, then prints targeted questions
# that help the human provide useful evidence.
#
# Usage:
#   scripts/hypothesis-review.sh
#
# Environment variable overrides (for testing):
#   HYPOTHESIS_LOG     — path to hypothesis-log.md
#   HYPOTHESIS_BACKLOG — path to hypothesis-backlog.md
#   FEEDBACK_FILE      — path to human feedback file

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

HYPOTHESIS_LOG="${HYPOTHESIS_LOG:-$REPO_ROOT/docs/working/hypothesis-log.md}"
HYPOTHESIS_BACKLOG="${HYPOTHESIS_BACKLOG:-$REPO_ROOT/docs/working/hypothesis-backlog.md}"
FEEDBACK_FILE="${FEEDBACK_FILE:-$REPO_ROOT/docs/human-author/feedback.md}"

# --- Parse TRACKING entries from hypothesis-log.md ---
# These are SI loop hypotheses with empty Outcome field.
parse_log_tracking() {
    [ -f "$HYPOTHESIS_LOG" ] || return 0

    while IFS= read -r line; do
        [[ "$line" != \|* ]] && continue
        echo "$line" | grep -qE '^\|\s*(Round|----)' && continue

        local outcome
        outcome=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $7); print $7}')

        # Empty outcome = TRACKING
        if [[ -z "$outcome" ]]; then
            local round task_id hypothesis window
            round=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
            task_id=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
            hypothesis=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}')
            window=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $5); print $5}')

            echo "LOG|${task_id}|${round}|${window}|${hypothesis}"
        fi
    done < "$HYPOTHESIS_LOG"
}

# --- Parse TRACKING entries from hypothesis-backlog.md ---
# These are screening hypotheses about external impact.
parse_backlog_tracking() {
    [ -f "$HYPOTHESIS_BACKLOG" ] || return 0

    while IFS= read -r line; do
        [[ "$line" != \|* ]] && continue
        echo "$line" | grep -qE '^\|\s*(ID|---)' && continue

        local status
        status=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $6); print $6}')

        if [[ "$status" == "TRACKING" ]]; then
            local id hypothesis evidence_sources
            id=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
            hypothesis=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
            evidence_sources=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}')

            echo "BACKLOG|${id}|${evidence_sources}|${hypothesis}"
        fi
    done < "$HYPOTHESIS_BACKLOG"
}

# --- Check for recent feedback ---
count_recent_feedback() {
    [ -f "$FEEDBACK_FILE" ] || { echo 0; return; }
    # Count non-empty, non-comment lines after the "## Entries" header
    local count
    count=$(sed -n '/^## Entries/,$ p' "$FEEDBACK_FILE" | grep -cvE '^\s*$|^\s*<!--' 2>/dev/null) || count=0
    echo "$count"
}

# --- Main output ---

echo ""
echo "============================================="
echo "  Hypothesis Review Questionnaire"
echo "  $(date +%Y-%m-%d)"
echo "============================================="

# Show feedback file status
feedback_count=$(count_recent_feedback)
echo ""
echo "Feedback file: $FEEDBACK_FILE"
echo "Existing entries: $feedback_count"

# Collect tracking entries
log_entries=()
while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    log_entries+=("$entry")
done < <(parse_log_tracking)

backlog_entries=()
while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    backlog_entries+=("$entry")
done < <(parse_backlog_tracking)

total=$((${#log_entries[@]} + ${#backlog_entries[@]}))

if [ "$total" -eq 0 ]; then
    echo ""
    echo "No TRACKING hypotheses found. Nothing to review."
    exit 0
fi

echo ""
echo "TRACKING hypotheses: $total (${#backlog_entries[@]} external, ${#log_entries[@]} internal)"

# --- External-impact hypotheses (from backlog) ---
# These are the high-value ones — about whether workflows/skills are useful
# outside this repo.
if [ ${#backlog_entries[@]} -gt 0 ]; then
    echo ""
    echo "---------------------------------------------"
    echo "  EXTERNAL IMPACT (hypothesis-backlog.md)"
    echo "---------------------------------------------"
    echo ""
    echo "These hypotheses are about whether this repo's output is useful in"
    echo "real projects. Your observations are the primary evidence source."
    echo ""

    for entry in "${backlog_entries[@]}"; do
        local_id=$(echo "$entry" | cut -d'|' -f2)
        evidence_sources=$(echo "$entry" | cut -d'|' -f3)
        hypothesis=$(echo "$entry" | cut -d'|' -f4-)

        echo "--- $local_id ---"
        echo "  Hypothesis: $hypothesis"
        echo "  Evidence sources: $evidence_sources"
        echo ""
        echo "  Questions to consider:"

        # Generate targeted questions based on hypothesis content
        case "$hypothesis" in
            *"never"*|*"not used"*|*"rarely"*)
                echo "  - Is this accurate? Have you used this at all?"
                echo "  - If not, is it because it's not useful, or because you forget it exists?"
                ;;
            *"used"*|*"invoked"*|*"adopted"*)
                echo "  - Have you used this in any project recently? Which ones?"
                echo "  - Did you reach for it naturally, or did you have to remember it existed?"
                ;;
            *"correlat"*|*"produce"*|*"lead"*)
                echo "  - Have you noticed any difference in outcomes when using vs. not using this?"
                echo "  - Can you point to a specific instance where it helped or didn't?"
                ;;
            *"complex"*|*"length"*|*"line count"*)
                echo "  - Does the length/complexity of this feel like a barrier?"
                echo "  - Would a shorter version be more useful, or is the detail needed?"
                ;;
            *)
                echo "  - What's your impression? Any evidence for or against?"
                echo "  - Have you seen anything relevant in your recent work?"
                ;;
        esac
        echo ""
    done
fi

# --- Internal hypotheses (from SI loop log) ---
if [ ${#log_entries[@]} -gt 0 ]; then
    echo ""
    echo "---------------------------------------------"
    echo "  INTERNAL / SI LOOP (hypothesis-log.md)"
    echo "---------------------------------------------"
    echo ""
    echo "These are from the self-improvement loop. They may be less important"
    echo "than external-impact hypotheses. Skip any that don't seem worth your time."
    echo ""

    for entry in "${log_entries[@]}"; do
        task_id=$(echo "$entry" | cut -d'|' -f2)
        round=$(echo "$entry" | cut -d'|' -f3)
        window=$(echo "$entry" | cut -d'|' -f4)
        hypothesis=$(echo "$entry" | cut -d'|' -f5-)

        echo "--- $task_id (round $round, window $window) ---"
        echo "  Hypothesis: $hypothesis"
        echo ""
        echo "  - Is this worth tracking? (If not, suggest closing it.)"
        echo "  - Any evidence for or against from your experience?"
        echo ""
    done
fi

# --- Prompt to write feedback ---
echo "============================================="
echo ""
echo "To record your observations, append to:"
echo "  $FEEDBACK_FILE"
echo ""
echo "Format: date, observation, confidence (high/medium/low/uncertain)."
echo "Reference hypothesis IDs if convenient, but don't feel obligated."
echo ""
