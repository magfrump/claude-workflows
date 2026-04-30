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
        _summary_project_state "$start_round" "$end_round" "$working_dir"
        _summary_whats_new "$start_round" "$end_round" "$working_dir" "$round_history" "$completed_tasks"
        _summary_verdicts "$start_round" "$end_round" "$working_dir" "$hypothesis_log"
        _summary_gate_stats "$round_history"
        _summary_deferred_evaluation "$hypothesis_log"
        _summary_footer
    } > "$output_path"

    # Capture the next round's claim using current state as baseline. The
    # SI loop reinvokes this function after every finalize_round_log, so
    # round (end_round + 1) inherits a baseline taken at its own start
    # (= the moment round end_round wrapped up). Idempotent: an existing
    # claim file is preserved so re-runs don't rewrite the baseline.
    _capture_round_claim "$((end_round + 1))" "$working_dir" "$hypothesis_log"

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

# --- Internal: Project State section ---
# Cross-round state header that complements per-run stats. Renders, in order:
#   - Open hypotheses (from hypothesis-log.md, empty Outcome column)
#   - In-flight maintenance debt (recurring deferred tasks in round-changelog.md)
#   - Recent rejections grouped by failing gate (from round reports)
#   - Broken-pipeline status (TRACKING hypotheses in hypothesis-backlog.md)
#   - Token burn rate (N/A when token-actuals.json is absent)
#
# Each subsection degrades gracefully when its data source is missing.
_summary_project_state() {
    local start_round="$1" end_round="$2" working_dir="$3"

    echo ""
    echo "## Project State"

    _project_state_open_hypotheses "$working_dir/hypothesis-log.md"
    _project_state_maintenance_debt "$working_dir/round-changelog.md"
    _project_state_category_mix "$start_round" "$end_round" "$working_dir"
    _project_state_recent_rejections "$start_round" "$end_round" "$working_dir"
    _project_state_broken_pipelines "$working_dir/hypothesis-backlog.md"
    _project_state_token_burn "$working_dir/token-actuals.json"
}

# --- Internal: per-category task mix across the run ---
# Reads each round's tasks-round-N.json and counts tasks per category. The
# allowed values are feature/maintenance/data-pipeline; tasks without a
# category land in "uncategorized". The signal we want to surface is feature
# work crowding out maintenance and data-pipeline repairs.
_project_state_category_mix() {
    local start_round="$1" end_round="$2" working_dir="$3"

    echo ""
    echo "### Task Category Mix"
    echo ""

    local feature=0 maintenance=0 datapipeline=0 uncategorized=0
    local rounds_with_tasks=0
    for round_num in $(seq "$start_round" "$end_round"); do
        local tasks_file="$working_dir/tasks-round-${round_num}.json"
        [ -f "$tasks_file" ] || continue
        rounds_with_tasks=$((rounds_with_tasks + 1))

        local counts
        counts=$(jq -r '
            [.[] | .category // "uncategorized"] |
            "\([.[] | select(. == "feature")] | length) " +
            "\([.[] | select(. == "maintenance")] | length) " +
            "\([.[] | select(. == "data-pipeline")] | length) " +
            "\([.[] | select(. == "uncategorized" or (. != "feature" and . != "maintenance" and . != "data-pipeline"))] | length)"
        ' "$tasks_file" 2>/dev/null) || counts="0 0 0 0"

        feature=$((feature + $(echo "$counts" | awk '{print $1}')))
        maintenance=$((maintenance + $(echo "$counts" | awk '{print $2}')))
        datapipeline=$((datapipeline + $(echo "$counts" | awk '{print $3}')))
        uncategorized=$((uncategorized + $(echo "$counts" | awk '{print $4}')))
    done

    if [ "$rounds_with_tasks" -eq 0 ]; then
        echo "No task data for this run."
        return
    fi

    local total=$((feature + maintenance + datapipeline + uncategorized))
    if [ "$total" -eq 0 ]; then
        echo "No tasks in this run."
        return
    fi

    echo "- feature: ${feature}"
    echo "- maintenance: ${maintenance}"
    echo "- data-pipeline: ${datapipeline}"
    if [ "$uncategorized" -gt 0 ]; then
        echo "- uncategorized: ${uncategorized}"
    fi

    # Interpretation hints: surface imbalance when at least some tasks are
    # categorized. "Crowding out" = feature dominates the categorized pool
    # while maintenance + data-pipeline are starved.
    local categorized=$((feature + maintenance + datapipeline))
    if [ "$categorized" -eq 0 ]; then
        echo ""
        echo "All tasks uncategorized — planner is not yet assigning categories."
    elif [ "$categorized" -ge 3 ] && [ $((feature * 2)) -gt $((categorized)) ] && [ $((maintenance + datapipeline)) -lt "$feature" ]; then
        local feature_pct=$(( (feature * 100) / categorized ))
        echo ""
        echo "Feature work is ${feature_pct}% of categorized tasks — maintenance and data-pipeline may be getting crowded out."
    fi
}

# --- Internal: list hypotheses still tracking (empty Outcome column) ---
_project_state_open_hypotheses() {
    local hypothesis_log="$1"

    echo ""
    echo "### Open Hypotheses"
    echo ""

    if [ ! -f "$hypothesis_log" ]; then
        echo "Open hypotheses: 0 (no hypothesis log found)"
        return
    fi

    # Emit "task_id|round|hypothesis" for rows whose Outcome column is empty.
    local rows
    rows=$(awk -F'|' '
        /^\|/ {
            if ($0 ~ /^\|[ \t]*(Round|----)/) next
            round = $2; tid = $3; hyp = $4; outcome = $7
            gsub(/^[ \t]+|[ \t]+$/, "", round)
            gsub(/^[ \t]+|[ \t]+$/, "", tid)
            gsub(/^[ \t]+|[ \t]+$/, "", hyp)
            gsub(/^[ \t]+|[ \t]+$/, "", outcome)
            if (outcome == "" && tid != "") {
                printf "%s|%s|%s\n", tid, round, hyp
            }
        }
    ' "$hypothesis_log")

    local count
    count=$(printf '%s\n' "$rows" | grep -c . || true)

    echo "Open hypotheses: ${count}"
    if [ "$count" -eq 0 ]; then
        return
    fi

    echo ""
    while IFS='|' read -r tid round hyp; do
        [ -z "$tid" ] && continue
        # Trim hypothesis to first sentence or 80 chars, whichever comes first.
        local short="${hyp%%.*}"
        if [ "${#short}" -gt 80 ]; then
            short="${short:0:77}..."
        fi
        echo "- **${tid}** (round ${round}): ${short}"
    done <<< "$rows"
}

# --- Internal: tasks that have been deferred across multiple rounds ---
# Parses round-changelog.md "### Tasks deferred" sections and surfaces task
# IDs that appear in ≥2 rounds. The signal is: this task keeps slipping, and
# is accumulating context cost / merge-conflict risk each round it sits.
_project_state_maintenance_debt() {
    local changelog="$1"

    echo ""
    echo "### In-flight Maintenance Debt"
    echo ""

    if [ ! -f "$changelog" ]; then
        echo "No round-changelog.md; debt not tracked."
        return
    fi

    # Walk the file, tracking whether we're inside a "Tasks deferred" block,
    # and emit one line per "- **task-id**" bullet found inside such blocks.
    local task_ids
    task_ids=$(awk '
        /^### Tasks deferred/ { in_block = 1; next }
        /^### / { in_block = 0; next }
        /^## / { in_block = 0; next }
        in_block && /^- \*\*/ {
            line = $0
            sub(/^- \*\*/, "", line)
            sub(/\*\*.*/, "", line)
            if (line != "") print line
        }
    ' "$changelog" | sort | uniq -c | sort -rn)

    local debt_lines
    debt_lines=$(echo "$task_ids" | awk '$1 >= 2 { count = $1; $1 = ""; sub(/^ /, ""); printf "- **%s** — deferred in %d rounds\n", $0, count }')

    if [ -z "$debt_lines" ]; then
        echo "No recurring deferrals."
    else
        echo "$debt_lines"
    fi
}

# --- Internal: rejected tasks in this run, grouped by failing gate ---
_project_state_recent_rejections() {
    local start_round="$1" end_round="$2" working_dir="$3"

    echo ""
    echo "### Recent Rejections by Failure Mode"
    echo ""

    # Collect "gate<TAB>task_id" pairs across all rejected tasks in this run.
    local pairs=""
    for round_num in $(seq "$start_round" "$end_round"); do
        local report="$working_dir/round-${round_num}-report.json"
        [ -f "$report" ] || continue

        local round_pairs
        round_pairs=$(jq -r '
            .validation // {} | to_entries[] |
            select(.value.verdict == "rejected") |
            .key as $tid |
            (.value | to_entries[] | select(.key != "verdict" and .value == "fail") | .key) as $gate |
            "\($gate)\t\($tid)"
        ' "$report" 2>/dev/null) || true

        if [ -n "$round_pairs" ]; then
            pairs="${pairs}${round_pairs}"$'\n'
        fi
    done

    pairs=$(printf '%s' "$pairs" | grep -v '^$' || true)
    if [ -z "$pairs" ]; then
        echo "No rejections this run."
        return
    fi

    # Group by gate, render "gate: N (task1, task2)".
    local prev_gate="" gate_tasks="" gate_count=0
    while IFS=$'\t' read -r gate tid; do
        if [ "$gate" != "$prev_gate" ]; then
            if [ -n "$prev_gate" ]; then
                echo "- **${prev_gate}**: ${gate_count} (${gate_tasks})"
            fi
            prev_gate="$gate"
            gate_tasks="$tid"
            gate_count=1
        else
            gate_tasks="${gate_tasks}, ${tid}"
            gate_count=$((gate_count + 1))
        fi
    done < <(printf '%s\n' "$pairs" | sort)

    if [ -n "$prev_gate" ]; then
        echo "- **${prev_gate}**: ${gate_count} (${gate_tasks})"
    fi
}

# --- Internal: TRACKING hypotheses from the backlog (broken pipelines) ---
# Surfaces unresolved structural questions like the skill-usage logging gap.
# A row is "broken-pipeline" if its Status column contains "TRACKING" with no
# other status modifier (CONFIRMED/REFUTED/INCONCLUSIVE entries are skipped).
_project_state_broken_pipelines() {
    local backlog="$1"

    echo ""
    echo "### Broken Pipelines (TRACKING)"
    echo ""

    if [ ! -f "$backlog" ]; then
        echo "No hypothesis backlog found."
        return
    fi

    local rows
    rows=$(awk -F'|' '
        /^\|/ {
            if ($0 ~ /^\|[ \t]*(ID|----)/) next
            id = $2; hyp = $3; status = $6
            gsub(/^[ \t]+|[ \t]+$/, "", id)
            gsub(/^[ \t]+|[ \t]+$/, "", hyp)
            gsub(/^[ \t]+|[ \t]+$/, "", status)
            # Strip markdown bold so "**TRACKING**" matches "TRACKING".
            gsub(/\*\*/, "", status)
            if (status == "TRACKING" && id != "") {
                printf "%s|%s\n", id, hyp
            }
        }
    ' "$backlog")

    if [ -z "$rows" ]; then
        echo "No tracking hypotheses."
        return
    fi

    while IFS='|' read -r id hyp; do
        [ -z "$id" ] && continue
        local short="${hyp%%.*}"
        if [ "${#short}" -gt 100 ]; then
            short="${short:0:97}..."
        fi
        echo "- **${id}**: ${short}"
    done <<< "$rows"
}

# --- Internal: token burn rate (N/A until r2-token-tracking-narrow ships) ---
# Renders N/A when the actuals file is absent so this header can land
# without depending on that task. When the file exists, future work in the
# token-tracking task will replace this branch with a real computation.
_project_state_token_burn() {
    local actuals="$1"

    echo ""
    echo "### Token Burn Rate"
    echo ""

    if [ ! -f "$actuals" ]; then
        echo "Token burn rate: N/A (token-actuals data not available)"
        return
    fi

    echo "Token burn rate: N/A (token-actuals renderer not yet implemented)"
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

# --- Internal: count deferred (open) hypotheses ---
# Mirrors the row filter used by _summary_deferred_evaluation: pipe-table
# rows whose Outcome column (col 7) is empty, excluding internal-si scope.
# Returns just the count to stdout.
_count_deferred_hypotheses() {
    local hypothesis_log="$1"
    [ -f "$hypothesis_log" ] || { echo 0; return; }

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
        [[ -n "$outcome" ]] && continue

        if [[ "$scope_col" -gt 0 ]]; then
            local scope
            scope=$(echo "$line" | awk -F'|' -v c="$scope_col" '{gsub(/^[ \t]+|[ \t]+$/, "", $c); print $c}')
            [[ "$scope" == "internal-si" ]] && continue
        fi
        count=$((count + 1))
    done < "$hypothesis_log"
    echo "$count"
}

# --- Internal: capture a falsifiable claim for an upcoming round ---
# Writes round-N-claim.json containing claim text, type, and baseline
# metric values taken at capture time. Idempotent — existing files are
# preserved so the baseline reflects the original round-start moment
# even if the morning summary is regenerated mid-run.
#
# Claim type implemented: deferred_hypothesis_closure. Future types can
# be added by extending the case switch in _evaluate_round_claim.
_capture_round_claim() {
    local round="$1" working_dir="$2" hypothesis_log="$3"
    local claim_file="$working_dir/round-${round}-claim.json"
    [ -f "$claim_file" ] && return 0
    [ -d "$working_dir" ] || return 0

    local baseline
    baseline=$(_count_deferred_hypotheses "$hypothesis_log")

    jq -n \
        --argjson round "$round" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --argjson baseline "$baseline" \
        '{
            round: $round,
            captured_at: $ts,
            claim: "close >=1 deferred hypothesis",
            type: "deferred_hypothesis_closure",
            params: {min_closures: 1, baseline_deferred_count: $baseline}
        }' > "$claim_file" 2>/dev/null || rm -f "$claim_file"
}

# --- Internal: evaluate a round's claim and emit a VERDICT line ---
# Reads round-N-claim.json, recomputes the claim's metric against the
# current state, and prints a single markdown bullet starting with the
# token "confirmed", "refuted", "inconclusive", or "no-claim". The
# leading token is significant: _summary_verdicts pattern-matches on it
# to tally the aggregate counts.
_evaluate_round_claim() {
    local round="$1" working_dir="$2" hypothesis_log="$3"
    local claim_file="$working_dir/round-${round}-claim.json"

    if [ ! -f "$claim_file" ]; then
        echo "- **VERDICT (round ${round})**: no-claim — round predates claim capture"
        return 0
    fi

    local claim_type baseline min_closures claim_text
    claim_type=$(jq -r '.type // ""' "$claim_file" 2>/dev/null)
    claim_text=$(jq -r '.claim // ""' "$claim_file" 2>/dev/null)
    baseline=$(jq -r '.params.baseline_deferred_count // 0' "$claim_file" 2>/dev/null)
    min_closures=$(jq -r '.params.min_closures // 1' "$claim_file" 2>/dev/null)
    [[ "$baseline" =~ ^[0-9]+$ ]] || baseline=0
    [[ "$min_closures" =~ ^[0-9]+$ ]] || min_closures=1

    local current verdict reason target
    case "$claim_type" in
        deferred_hypothesis_closure)
            current=$(_count_deferred_hypotheses "$hypothesis_log")
            target=$(( baseline - min_closures ))
            if [ ! -f "$hypothesis_log" ]; then
                verdict="inconclusive"
                reason="hypothesis log unavailable"
            elif [ "$baseline" -eq 0 ]; then
                verdict="inconclusive"
                reason="baseline was 0 — no deferred hypotheses to close"
            elif [ "$current" -le "$target" ]; then
                verdict="confirmed"
                reason="deferred hypotheses ${baseline} -> ${current} (closed >=${min_closures})"
            elif [ "$current" -ge "$baseline" ]; then
                verdict="refuted"
                reason="deferred hypotheses ${baseline} -> ${current} (no net closures)"
            else
                verdict="inconclusive"
                reason="deferred hypotheses ${baseline} -> ${current} (decrease below threshold of ${min_closures})"
            fi
            ;;
        *)
            verdict="inconclusive"
            reason="unknown claim type: ${claim_type}"
            ;;
    esac

    echo "- **VERDICT (round ${round})**: ${verdict} — claim \"${claim_text}\": ${reason}"
}

# --- Internal: per-round verdicts section ---
# Prints VERDICT bullets for each round in the window plus an aggregate
# tally. A persistent inconclusive-rate (>=50% of evaluated rounds) is
# itself a metric: it suggests the claim type does not exercise the
# actual round-design loop and the claim framework needs revision.
_summary_verdicts() {
    local start_round="$1" end_round="$2" working_dir="$3" hypothesis_log="$4"

    echo ""
    echo "## Round Claim Verdicts"
    echo ""
    echo "Each round captures a falsifiable claim at its start and is graded"
    echo "against current artifacts at round end. Persistent inconclusive"
    echo "verdicts indicate a flawed round-design loop."
    echo ""

    local confirmed=0 refuted=0 inconclusive=0 noclaim=0
    for round_num in $(seq "$start_round" "$end_round"); do
        local line
        line=$(_evaluate_round_claim "$round_num" "$working_dir" "$hypothesis_log")
        echo "$line"
        case "$line" in
            *": confirmed "*) confirmed=$((confirmed + 1)) ;;
            *": refuted "*)   refuted=$((refuted + 1)) ;;
            *": inconclusive "*) inconclusive=$((inconclusive + 1)) ;;
            *": no-claim "*)  noclaim=$((noclaim + 1)) ;;
        esac
    done

    local evaluated=$((confirmed + refuted + inconclusive))
    echo ""
    echo "Aggregate: ${confirmed} confirmed, ${refuted} refuted, ${inconclusive} inconclusive"
    if [ "$noclaim" -gt 0 ]; then
        echo "(${noclaim} round(s) without a claim file — predate claim capture)"
    fi

    if [ "$evaluated" -gt 0 ] && [ $((inconclusive * 2)) -ge "$evaluated" ]; then
        echo ""
        echo "Note: inconclusive verdicts are >=50% of evaluated rounds. The"
        echo "current claim type may not exercise the actual round-design"
        echo "loop — consider revising the claim framework."
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
