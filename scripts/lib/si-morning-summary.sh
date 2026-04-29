#!/bin/bash
# Post-run morning summary generator for the self-improvement loop.
# Produces a single readable document after overnight autonomous execution,
# surfacing what was built, gate statistics, and deferred hypothesis
# evaluation questions for the user.
#
# Sourced by scripts/self-improvement.sh — do not execute directly.
#
# Functions:
#   generate_morning_summary — Produce the morning summary markdown file
#
# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: this file should be sourced, not executed directly" >&2
    exit 1
fi

# --- Internal: per-round task counts ---
# Returns "launched approved rejected" for a given round report.
# Prefers .summary.* (written at end of round); falls back to deriving from
# .validation when .summary is absent (e.g. all_rejected early exits skip
# summary writing, or run was canceled mid-round).
_round_counts() {
    local report="$1"
    jq -r '
        if (.summary // null) != null and (.summary.launched // null) != null then
            "\(.summary.launched // 0) \(.summary.approved // 0) \(.summary.rejected // 0)"
        else
            ([.validation // {} | to_entries[] | select(.value.verdict != null)] | length) as $launched |
            ([.validation // {} | to_entries[] | select(.value.verdict == "approved")] | length) as $approved |
            ([.validation // {} | to_entries[] | select(.value.verdict == "rejected")] | length) as $rejected |
            "\($launched) \($approved) \($rejected)"
        end
    ' "$report" 2>/dev/null || echo "0 0 0"
}

# --- Internal: gates with high failure rates for a round ---
# Returns space-separated gate names where >=50% of launched tasks failed
# that gate. "Launched" = tasks whose validation has a verdict set, so
# pre-launch schema rejects are excluded. Only string-typed gate entries
# are considered; "_detail" objects and the "verdict" key itself are
# filtered out. "skip" status does not count as a failure.
#
# Why: a gate failing on the majority of launched tasks is more likely an
# environmental regression (broken tool, missing binary, network outage)
# than every task happening to break the same way. Surfacing this in the
# round-summary line lets the operator notice and run health-check even
# when the pre-round health check is bypassed.
_round_high_failure_gates() {
    local report="$1"
    [ -f "$report" ] || { echo ""; return; }

    # 50% threshold encoded as integer math: fails * 2 >= launched.
    jq -r '
        (.validation // {}) as $v |
        ([$v | to_entries[] | select(.value.verdict != null)] | length) as $launched |
        if $launched == 0 then empty
        else
            [ $v
              | to_entries[]
              | select(.value.verdict != null)
              | .value
              | to_entries[]
              | select(.key != "verdict" and (.value | type) == "string")
            ]
            | group_by(.key)
            | map({
                gate: .[0].key,
                fails: ([.[] | select(.value == "fail")] | length)
              })
            | map(select((.fails * 2) >= $launched))
            | .[].gate
        end
    ' "$report" 2>/dev/null | tr '\n' ' ' | sed 's/ *$//'
}

# --- Morning summary generator ---
# Reads round reports, completed tasks, and hypothesis log to produce
# a single post-run summary document.
#
# Args: $1 = start_round (integer)
#       $2 = end_round (integer, inclusive — last round that completed)
#       $3 = output_path (where to write the summary)
#       $4 = working_dir (path to docs/working)
# Returns: 0 on success, 1 on missing arguments
generate_morning_summary() {
    local start_round="${1:-}"
    local end_round="${2:-}"
    local output_path="${3:-}"
    local working_dir="${4:-}"

    if [[ -z "$start_round" || -z "$end_round" || -z "$output_path" || -z "$working_dir" ]]; then
        echo "Usage: generate_morning_summary <start_round> <end_round> <output_path> <working_dir>" >&2
        return 1
    fi

    local round_history="$working_dir/round-history.json"
    local completed_tasks="$working_dir/completed-tasks.md"
    local hypothesis_log="$working_dir/hypothesis-log.md"

    {
        _summary_header "$start_round" "$end_round" "$working_dir"
        _summary_whats_new "$start_round" "$end_round" "$working_dir" "$round_history" "$completed_tasks"
        _summary_gate_stats "$round_history"
        _summary_deferred_evaluation "$hypothesis_log"
        _summary_footer
    } > "$output_path"

    echo "  Morning summary written to: $output_path"
}

# --- Internal: header with run overview ---
_summary_header() {
    local start_round="$1" end_round="$2" working_dir="$3"
    local total_attempted=0 total_approved=0 total_rejected=0

    for round_num in $(seq "$start_round" "$end_round"); do
        local report="$working_dir/round-${round_num}-report.json"
        [ -f "$report" ] || continue

        local counts launched approved rejected
        counts=$(_round_counts "$report")
        launched=$(echo "$counts" | awk '{print $1}')
        approved=$(echo "$counts" | awk '{print $2}')
        rejected=$(echo "$counts" | awk '{print $3}')

        total_attempted=$((total_attempted + launched))
        total_approved=$((total_approved + approved))
        total_rejected=$((total_rejected + rejected))
    done

    local rounds_completed=$(( end_round - start_round + 1 ))
    local approval_pct=0
    if [ "$total_attempted" -gt 0 ]; then
        approval_pct=$(( (total_approved * 100) / total_attempted ))
    fi

    cat <<EOF
# Morning Summary — $(date +%Y-%m-%d)

## Run Overview
- Rounds completed: $rounds_completed (rounds ${start_round}-${end_round})
- Total tasks attempted: $total_attempted
- Tasks approved: $total_approved (${approval_pct}%)
- Tasks rejected: $total_rejected
EOF
}

# --- Internal: per-round task listings ---
_summary_whats_new() {
    local start_round="$1" end_round="$2" working_dir="$3"
    local round_history="$4" completed_tasks="$5"

    echo ""
    echo "## What's New"

    for round_num in $(seq "$start_round" "$end_round"); do
        local report="$working_dir/round-${round_num}-report.json"
        [ -f "$report" ] || continue

        local counts launched approved
        counts=$(_round_counts "$report")
        launched=$(echo "$counts" | awk '{print $1}')
        approved=$(echo "$counts" | awk '{print $2}')

        local high_failure_gates round_suffix=""
        high_failure_gates=$(_round_high_failure_gates "$report")
        if [ -n "$high_failure_gates" ]; then
            round_suffix=" (likely infrastructure issue — consider running scripts/health-check.sh)"
        fi

        echo ""
        echo "### Round $round_num ($launched tasks, $approved approved)$round_suffix"
        echo ""

        # List approved tasks with summaries
        local task_ids
        task_ids=$(jq -r '.validation | to_entries[] | select(.value.verdict == "approved") | .key' "$report" 2>/dev/null) || true

        for tid in $task_ids; do
            # Try to find summary in completed-tasks.md
            local summary=""
            if [ -f "$completed_tasks" ]; then
                summary=$(grep -A0 "\*\*${tid}\*\*" "$completed_tasks" 2>/dev/null | sed 's/^- \*\*[^*]*\*\*: //' | head -1) || true
            fi
            # Fall back to summary file
            if [ -z "$summary" ] && [ -f "$working_dir/summary-${tid}.md" ]; then
                summary=$(head -1 "$working_dir/summary-${tid}.md" 2>/dev/null) || true
            fi

            if [ -n "$summary" ]; then
                echo "- **${tid}**: $summary"
            else
                echo "- **${tid}**: (no summary available)"
            fi
        done

        # List rejected tasks with failure reasons
        local rejected_ids
        rejected_ids=$(jq -r '.validation | to_entries[] | select(.value.verdict == "rejected") | .key' "$report" 2>/dev/null) || true

        for tid in $rejected_ids; do
            local failing_gate
            failing_gate=$(jq -r --arg tid "$tid" '.validation[$tid] | to_entries[] | select(.value == "fail" and .key != "verdict") | .key' "$report" 2>/dev/null | head -1) || failing_gate="unknown"
            echo "- REJECTED: **${tid}** (failed: $failing_gate)"
        done
    done
}

# --- Internal: gate statistics ---
_summary_gate_stats() {
    local round_history="$1"

    echo ""
    echo "## Gate Statistics"
    echo ""

    if [ ! -f "$round_history" ]; then
        echo "No round history available."
        return
    fi

    # Use print_gate_stats if available (sourced from si-functions.sh)
    if declare -f print_gate_stats >/dev/null 2>&1; then
        print_gate_stats "$round_history" 2>/dev/null || echo "No gate data available."
    else
        echo "Gate stats function not available."
    fi
}

# --- Internal: deferred hypothesis evaluation ---
# Surfaces hypotheses with empty Outcome as deferred user questions.
# Skips rows whose Scope is "internal-si" — those are SI-infrastructure
# hypotheses evaluated within the loop using gate stats and round reports,
# not via real-world user observations. The Scope column is optional; if
# it is absent (older log files), every empty-outcome row surfaces as
# before.
_summary_deferred_evaluation() {
    local hypothesis_log="$1"

    echo ""
    echo "## Deferred Evaluation Questions"
    echo ""
    echo "These hypotheses are still open. They cannot be evaluated autonomously"
    echo "because meaningful evidence requires real-world usage. Please answer"
    echo "when you have observations."
    echo ""

    if [ ! -f "$hypothesis_log" ]; then
        echo "No hypothesis log found."
        return
    fi

    # Locate the Scope column in the table header (1-based awk index, or 0
    # if the column is absent). Match the header by anchoring on a
    # well-known column name to avoid mistaking a hypothesis row that
    # happens to contain "Scope" for the header.
    local scope_col=0
    scope_col=$(awk -F'|' '
        /^\|/ && / Round / && / Scope / {
            for (i = 1; i <= NF; i++) {
                gsub(/^[ \t]+|[ \t]+$/, "", $i)
                if ($i == "Scope") { print i; exit }
            }
        }
    ' "$hypothesis_log")
    scope_col="${scope_col:-0}"

    local count=0
    while IFS= read -r line; do
        [[ "$line" != \|* ]] && continue
        echo "$line" | grep -qE '^\|\s*(Round|----)' && continue

        local outcome
        outcome=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $7); print $7}')

        # Empty outcome = still tracking
        [[ -n "$outcome" ]] && continue

        if [[ "$scope_col" -gt 0 ]]; then
            local scope
            scope=$(echo "$line" | awk -F'|' -v c="$scope_col" '{gsub(/^[ \t]+|[ \t]+$/, "", $c); print $c}')
            [[ "$scope" == "internal-si" ]] && continue
        fi

        local round task_id hypothesis
        round=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
        task_id=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
        hypothesis=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}')

        count=$((count + 1))
        echo "${count}. **${task_id}** (round ${round}): \"${hypothesis}\""

        _generate_questions "$hypothesis"
        echo ""
    done < "$hypothesis_log"

    if [ "$count" -eq 0 ]; then
        echo "No open hypotheses to evaluate."
    fi
}

# --- Internal: generate targeted questions for a hypothesis ---
_generate_questions() {
    local hypothesis="$1"

    case "$hypothesis" in
        *"never"*|*"not used"*|*"rarely"*)
            echo "   - Is this accurate? Have you used this at all?"
            echo "   - If not, is it because it's not useful, or because you forgot it exists?"
            ;;
        *"used"*|*"invoked"*|*"adopted"*|*"activated"*)
            echo "   - Have you used this in any project recently?"
            echo "   - Did you reach for it naturally, or did you have to remember it existed?"
            ;;
        *"reduce"*|*"fewer"*|*"less"*|*"lower"*)
            echo "   - Have you noticed any difference in the predicted direction?"
            echo "   - Can you point to a specific instance?"
            ;;
        *"prevent"*|*"catch"*|*"flag"*|*"surface"*)
            echo "   - Has this caught or surfaced anything useful?"
            echo "   - Would you have noticed the issue without it?"
            ;;
        *)
            echo "   - What's your impression? Any evidence for or against?"
            echo "   - Have you seen anything relevant in your recent work?"
            ;;
    esac
}

# --- Internal: footer ---
_summary_footer() {
    echo ""
    echo "## Recording Your Responses"
    echo ""
    echo "Update \`docs/working/si-input.md\` with your feedback for the next run."
    echo "Reference task IDs if convenient."
}
