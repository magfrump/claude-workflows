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

# Shared path-classification helpers (used by _resolve_hypothesis_target).
# shellcheck source=skill-paths.sh
source "$(dirname "${BASH_SOURCE[0]}")/skill-paths.sh"

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
        _summary_action_block "$hypothesis_log" "$end_round"
        _summary_failure_modes_this_cycle "$start_round" "$end_round" "$working_dir"
        _summary_project_state "$start_round" "$end_round" "$working_dir"
        _summary_whats_new "$start_round" "$end_round" "$working_dir" "$round_history" "$completed_tasks"
        _summary_gate_stats "$round_history"
        _summary_deferred_evaluation "$hypothesis_log" "$end_round" "$working_dir"
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

# --- Internal: count of matured, still-open deferred hypotheses ---
# Returns the integer number of hypothesis-log rows that _summary_deferred_evaluation
# would surface as questions for the same (log, current_round): rows that are
# open (empty Outcome), not Scope=internal-si, and whose maturity window has
# elapsed. It deliberately reuses _row_is_open_deferred plus the same column-
# location calls and Outcome-column fallback (7) as _summary_deferred_evaluation,
# so the action block's N is equal to the question count below it by construction
# (the feedback-continuity property — the top block must not claim a different
# count than the section it points to). Echoes 0 when the log is missing.
_count_matured_deferred() {
    local hypothesis_log="$1"
    local current_round="${2:-0}"

    [ -f "$hypothesis_log" ] || { echo 0; return; }

    local scope_col outcome_col
    scope_col=$(_locate_scope_col "$hypothesis_log")
    outcome_col=$(_locate_log_col "$hypothesis_log" "Outcome")
    [[ "$outcome_col" -gt 0 ]] || outcome_col=7

    local count=0
    local line
    while IFS= read -r line; do
        _row_is_open_deferred "$line" "$current_round" "$scope_col" "$outcome_col" || continue
        count=$((count + 1))
    done < "$hypothesis_log"
    echo "$count"
}

# --- Internal: top-of-summary "What You Need To Do" action block ---
# Sits immediately below Run Overview so a returning user finds their single
# primary action within the first screenful instead of scrolling past the full
# open-hypothesis list. The one action that needs the user is answering the
# matured deferred hypothesis questions (the "Deferred Evaluation Questions"
# section); everything else in the summary is informational. The count comes
# from _count_matured_deferred, which shares the deferred section's filter, so
# the N named here always matches the number of questions below.
_summary_action_block() {
    local hypothesis_log="$1"
    local current_round="${2:-0}"

    local matured
    matured=$(_count_matured_deferred "$hypothesis_log" "$current_round")

    echo ""
    echo "## What You Need To Do"
    echo ""
    if [ "$matured" -eq 0 ]; then
        echo "Nothing needs your input right now — no deferred hypotheses have matured for evaluation this cycle. The sections below are informational; skim at your leisure."
        return
    fi

    local noun="questions"
    [ "$matured" -eq 1 ] && noun="question"
    echo "**Answer the ${matured} matured deferred hypothesis ${noun}** in the \"Deferred Evaluation Questions\" section below. That is the one action that needs you this cycle; everything else in this summary is informational."
}

# --- Internal: top-of-summary "Failure Modes This Cycle" block ---
# Aggregates gate-fail (gate, task_id) pairs across rounds in scope and emits
# the top 3 gates by distinct-task count. Sits near the top (just below the
# "What You Need To Do" action block) so an operator skimming the summary sees
# the dominant failure mode at a glance, without needing to scroll into the
# per-round detail.
#
# Dedupe rule: a (gate, task_id) pair is counted once even if it fails across
# multiple rounds — repeated failures of the same task against the same gate
# are one signal (this task keeps tripping that gate), not many.
#
# When there are no gate failures in scope, prints a placeholder line so the
# section's presence is consistent and operators don't wonder whether the
# block was skipped or just empty.
_summary_failure_modes_this_cycle() {
    local start_round="$1" end_round="$2" working_dir="$3"

    echo ""
    echo "## Failure Modes This Cycle"
    echo ""

    local pairs=""
    local round_num report round_pairs
    for round_num in $(seq "$start_round" "$end_round"); do
        report="$working_dir/round-${round_num}-report.json"
        [ -f "$report" ] || continue

        round_pairs=$(jq -r '
            .validation // {} | to_entries[] |
            .key as $tid |
            (.value | to_entries[] |
              select(.key != "verdict"
                     and (.value | type) == "string"
                     and .value == "fail") |
              .key) as $gate |
            "\($gate)\t\($tid)"
        ' "$report" 2>/dev/null) || round_pairs=""

        if [ -n "$round_pairs" ]; then
            pairs="${pairs}${round_pairs}"$'\n'
        fi
    done

    pairs=$(printf '%s' "$pairs" | grep -v '^$' || true)
    if [ -z "$pairs" ]; then
        echo "No gate failures this cycle."
        return
    fi

    # Dedupe (gate, task) so a task retried across rounds counts once per
    # gate. Then group by gate, count distinct tasks, sort desc, top 3.
    local top
    top=$(printf '%s\n' "$pairs" | sort -u | awk -F'\t' '
        {
            gates[$1]++
            if (tasks[$1] == "") {
                tasks[$1] = $2
            } else {
                tasks[$1] = tasks[$1] ", " $2
            }
        }
        END {
            for (g in gates) {
                printf "%d\t%s\t%s\n", gates[g], g, tasks[g]
            }
        }
    ' | sort -k1,1 -rn -s | head -3)

    echo "Top gate-fail patterns aggregated across this cycle's rounds (top 3):"
    echo ""
    local count gate task_list
    while IFS=$'\t' read -r count gate task_list; do
        [ -z "$gate" ] && continue
        echo "- **${gate}**: ${count} task(s) (${task_list})"
    done <<< "$top"
}

# --- Internal: Project State section ---
# Cross-round state header that complements per-run stats. Renders, in order:
#   - Open hypotheses (from hypothesis-log.md, empty Outcome column)
#   - Recurring maintenance debt (tasks deferred across multiple rounds in round-changelog.md)
#   - Recent rejections grouped by failing gate (from round reports)
#   - Broken-pipeline status (TRACKING hypotheses in hypothesis-backlog.md)
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

    # Outcome shifts position when the schema grows (decision 012 added
    # Evaluator + Requires columns, then Source). Look it up by name from the
    # header so the parser tolerates both old and new layouts.
    local outcome_col source_col
    outcome_col=$(_locate_log_col "$hypothesis_log" "Outcome")
    source_col=$(_locate_log_col "$hypothesis_log" "Source")
    # Fallback to 7 (pre-decision-012 layout) when the header is missing or
    # doesn't contain the column — keeps legacy logs readable.
    [[ "$outcome_col" -gt 0 ]] || outcome_col=7

    # Emit "task_id|round|hypothesis|source" for rows whose Outcome is empty.
    local rows
    rows=$(awk -F'|' -v oc="$outcome_col" -v sc="$source_col" '
        /^\|/ {
            if ($0 ~ /^\|[ \t]*(Round|----)/) next
            round = $2; tid = $3; hyp = $4; outcome = $(oc)
            src = (sc > 0) ? $(sc) : ""
            gsub(/^[ \t]+|[ \t]+$/, "", round)
            gsub(/^[ \t]+|[ \t]+$/, "", tid)
            gsub(/^[ \t]+|[ \t]+$/, "", hyp)
            gsub(/^[ \t]+|[ \t]+$/, "", outcome)
            gsub(/^[ \t]+|[ \t]+$/, "", src)
            if (outcome == "" && tid != "") {
                printf "%s|%s|%s|%s\n", tid, round, hyp, src
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
    while IFS='|' read -r tid round hyp src; do
        [ -z "$tid" ] && continue
        # Trim hypothesis to first sentence or 80 chars, whichever comes first.
        local short="${hyp%%.*}"
        if [ "${#short}" -gt 80 ]; then
            short="${short:0:77}..."
        fi
        # Tag planner-authored hypotheses so the user reviews framing for
        # optimism bias before evaluating (decision 012 pillar 3). Legacy
        # rows with empty Source get no tag — we can't infer provenance.
        local tag=""
        if [ "$src" = "planner" ]; then
            tag=" *[planner-authored — review framing]*"
        fi
        echo "- **${tid}** (round ${round}): ${short}${tag}"
    done <<< "$rows"
}

# --- Internal: tasks that have been deferred across multiple rounds ---
# Parses round-changelog.md "### Tasks deferred" sections and surfaces task
# IDs that appear in ≥2 rounds. The signal is: this task keeps slipping, and
# is accumulating context cost / merge-conflict risk each round it sits.
_project_state_maintenance_debt() {
    local changelog="$1"

    echo ""
    echo "### Recurring Maintenance Debt"
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

# --- Internal: rejected tasks in this run, grouped by (gate, primary file) ---
# Reads each round's report for rejected (gate, task_id) pairs and joins with
# tasks-round-N.json to look up the rejected task's primary file (basename of
# files_touched[0]). Output groups rejections by gate AND by the file under
# the gate, so the operator sees not just "which gate is failing" but "which
# files are repeatedly tripping it":
#
#   - **tests**: 6 (rpi-plan.md: 3, dd.md: 2, pr-prep.md: 1)
#
# Tasks whose tasks file is missing or whose files_touched is empty fall back
# to "unknown" so the rejection still counts but is visibly under-attributed.
#
# Maintenance signal: any file whose total rejection count across the cycle
# is >=3 gets a trailing callout line so the operator can consider queueing
# a maintenance task before the file accumulates more debt.
_project_state_recent_rejections() {
    local start_round="$1" end_round="$2" working_dir="$3"

    echo ""
    echo "### Recent Rejections by Failure Mode"
    echo ""

    # Collect "gate<TAB>file_basename<TAB>task_id" triples for rejected tasks.
    # Dedupe at the (gate, file, tid) level so a task retried across rounds
    # against the same gate doesn't get double-counted.
    local triples=""
    local round_num report tasks_file round_triples
    for round_num in $(seq "$start_round" "$end_round"); do
        report="$working_dir/round-${round_num}-report.json"
        tasks_file="$working_dir/tasks-round-${round_num}.json"
        [ -f "$report" ] || continue

        if [ -f "$tasks_file" ]; then
            round_triples=$(jq -r --slurpfile tasks "$tasks_file" '
                .validation // {} | to_entries[] |
                select(.value.verdict == "rejected") |
                .key as $tid |
                (($tasks[0] | map(select(.id == $tid)) | first) // null) as $task |
                ((($task.files_touched // [])[0]) // "unknown") as $file_path |
                (if $file_path == "" then "unknown" else ($file_path | split("/") | last) end) as $file_base |
                (.value | to_entries[] | select(.key != "verdict" and .value == "fail") | .key) as $gate |
                "\($gate)\t\($file_base)\t\($tid)"
            ' "$report" 2>/dev/null) || round_triples=""
        else
            round_triples=$(jq -r '
                .validation // {} | to_entries[] |
                select(.value.verdict == "rejected") |
                .key as $tid |
                (.value | to_entries[] | select(.key != "verdict" and .value == "fail") | .key) as $gate |
                "\($gate)\tunknown\t\($tid)"
            ' "$report" 2>/dev/null) || round_triples=""
        fi

        if [ -n "$round_triples" ]; then
            triples="${triples}${round_triples}"$'\n'
        fi
    done

    triples=$(printf '%s' "$triples" | grep -v '^$' || true)
    if [ -z "$triples" ]; then
        echo "No rejections this run."
        return
    fi

    # Aggregate via awk: one pass produces both the grouped output and the
    # maintenance signals. SUBSEP composes the (gate, file) key safely since
    # both fields are tab-delimited inputs that never contain SUBSEP (0x1c).
    printf '%s\n' "$triples" | sort -u | awk -F'\t' '
        {
            gate = $1
            file = $2
            gate_count[gate]++
            key = gate SUBSEP file
            gate_file_count[key]++
            file_total[file]++
            if (!seen_gate[gate]++) {
                gates[++gn] = gate
            }
            if (!seen_gate_file[key]++) {
                files_in_gate[gate] = (files_in_gate[gate] == "" ? file : files_in_gate[gate] "\t" file)
            }
        }
        END {
            # Sort gates by total count desc, name asc.
            for (i = 1; i <= gn; i++) {
                for (j = i + 1; j <= gn; j++) {
                    if (gate_count[gates[j]] > gate_count[gates[i]] ||
                        (gate_count[gates[j]] == gate_count[gates[i]] && gates[j] < gates[i])) {
                        t = gates[i]; gates[i] = gates[j]; gates[j] = t
                    }
                }
            }
            for (i = 1; i <= gn; i++) {
                g = gates[i]
                fn_ = split(files_in_gate[g], farr, "\t")
                # Sort files within the gate by count desc, name asc.
                for (a = 1; a <= fn_; a++) {
                    for (b = a + 1; b <= fn_; b++) {
                        ka = g SUBSEP farr[a]; kb = g SUBSEP farr[b]
                        if (gate_file_count[kb] > gate_file_count[ka] ||
                            (gate_file_count[kb] == gate_file_count[ka] && farr[b] < farr[a])) {
                            t = farr[a]; farr[a] = farr[b]; farr[b] = t
                        }
                    }
                }
                fstr = ""
                for (a = 1; a <= fn_; a++) {
                    f = farr[a]
                    fstr = fstr (fstr == "" ? "" : ", ") f ": " gate_file_count[g SUBSEP f]
                }
                printf "- **%s**: %d (%s)\n", g, gate_count[g], fstr
            }

            # Maintenance signals: files with >=3 total rejections across the
            # cycle, regardless of which gate(s) they failed against.
            mn = 0
            for (f in file_total) {
                if (file_total[f] >= 3) maint[++mn] = f
            }
            for (i = 1; i <= mn; i++) {
                for (j = i + 1; j <= mn; j++) {
                    if (maint[j] < maint[i]) {
                        t = maint[i]; maint[i] = maint[j]; maint[j] = t
                    }
                }
            }
            if (mn > 0) print ""
            for (i = 1; i <= mn; i++) {
                printf "- Maintenance signal: %s has 3+ recent rejections - consider a maintenance task\n", maint[i]
            }
        }
    '
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

# --- Internal: emit a sub-bullet when self_eval was skipped for a task ---
# Prints "  - self_eval skipped: <reason>" (no trailing newline beyond echo)
# when validation[tid].self_eval == "skip" in the round report. Silent
# otherwise.
#
# Reason source order:
#   1. validation[tid].self_eval_detail.reason — future-proof; surfaces any
#      detail field if a future skip path starts recording one.
#   2. Static fallback "no skill/workflow files changed" — the only path that
#      currently writes a skip status (scripts/self-improvement.sh: the
#      else-branch when CHANGED_SKILLS is empty).
_self_eval_skip_line() {
    local report="$1" tid="$2"
    [ -f "$report" ] || return 0
    [ -n "$tid" ] || return 0

    local status
    status=$(jq -r --arg tid "$tid" '.validation[$tid].self_eval // ""' "$report" 2>/dev/null) || return 0
    [ "$status" = "skip" ] || return 0

    local reason
    reason=$(jq -r --arg tid "$tid" \
        '.validation[$tid].self_eval_detail.reason // "no skill/workflow files changed"' \
        "$report" 2>/dev/null)
    [ -z "$reason" ] && reason="no skill/workflow files changed"

    echo "  - self_eval skipped: ${reason}"
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
            _self_eval_skip_line "$report" "$tid"
        done

        # List rejected tasks with failure reasons
        local rejected_ids
        rejected_ids=$(jq -r '.validation | to_entries[] | select(.value.verdict == "rejected") | .key' "$report" 2>/dev/null) || true

        for tid in $rejected_ids; do
            local failing_gate
            failing_gate=$(jq -r --arg tid "$tid" '.validation[$tid] | to_entries[] | select(.value == "fail" and .key != "verdict") | .key' "$report" 2>/dev/null | head -1) || failing_gate="unknown"
            echo "- REJECTED: **${tid}** (failed: $failing_gate)"
            _self_eval_skip_line "$report" "$tid"
        done

        # Contrastive note: pair one approved + one rejected addressing a
        # similar problem and surface a 1-2 sentence diff. No-op when
        # either verdict list is empty or no clear shared-problem pair
        # exists. See _compute_contrastive_pair.
        _compute_contrastive_pair "$round_num" "$working_dir"
        _emit_contrastive_note "$round_num" "$working_dir"
    done
}

# --- Internal: compute a contrastive approved/rejected pair for one round ---
# Writes contrastive-note-round-N.json to working_dir. Idempotent: a parseable
# cache file is preserved so re-runs don't re-invoke claude.
#
# Direct application of OMAC's Contrastive Comparator structural idea to the
# SI loop: pair tasks with a shared underlying problem but divergent verdicts
# so the next round's planner can absorb the lesson when setting priorities.
#
# Cache record shapes:
#   Pair found:  {approved_id, rejected_id, note, round, generated_at}
#   Skip:        {skip: true, reason, round, generated_at}
#
# Skip cases (all silent — emit no markdown):
#   - report or tasks file missing
#   - either verdict list empty (no contrast to draw)
#   - claude CLI unavailable
#   - claude returns no parseable JSON
#   - claude judges no clear shared-problem pair exists
_compute_contrastive_pair() {
    local round="$1" working_dir="$2"
    local cache_file="$working_dir/contrastive-note-round-${round}.json"
    local report="$working_dir/round-${round}-report.json"
    local tasks_file="$working_dir/tasks-round-${round}.json"

    if [ -f "$cache_file" ] && jq empty "$cache_file" 2>/dev/null; then
        return 0
    fi

    [ -f "$report" ] || return 0
    [ -f "$tasks_file" ] || return 0

    local approved_ids rejected_ids
    approved_ids=$(jq -r '.validation // {} | to_entries[] | select(.value.verdict == "approved") | .key' "$report" 2>/dev/null)
    rejected_ids=$(jq -r '.validation // {} | to_entries[] | select(.value.verdict == "rejected") | .key' "$report" 2>/dev/null)

    if [ -z "$approved_ids" ] || [ -z "$rejected_ids" ]; then
        _write_contrastive_skip "$cache_file" "$round" "round had only one verdict type"
        return 0
    fi

    if ! command -v claude >/dev/null 2>&1; then
        _write_contrastive_skip "$cache_file" "$round" "claude CLI not available"
        return 0
    fi

    # Build per-verdict JSON arrays the prompt can quote verbatim. Approved
    # entries carry id/description/files/category; rejected entries also
    # carry the first failing gate from the round report.
    local approved_ids_json rejected_ids_json
    approved_ids_json=$(printf '%s\n' "$approved_ids" | jq -R . | jq -sc '[.[] | select(length > 0)]')
    rejected_ids_json=$(printf '%s\n' "$rejected_ids" | jq -R . | jq -sc '[.[] | select(length > 0)]')

    local approved_payload rejected_payload
    approved_payload=$(jq -c --argjson ids "$approved_ids_json" '
        [ .[] | select(.id as $id | $ids | index($id)) |
          {id, description, files_touched, category: (.category // null)} ]
    ' "$tasks_file" 2>/dev/null) || approved_payload="[]"

    rejected_payload=$(jq -c --argjson ids "$rejected_ids_json" --slurpfile rep "$report" '
        [ .[] | select(.id as $id | $ids | index($id)) |
          .id as $id |
          ($rep[0].validation[$id] // {}) as $v |
          {id, description, files_touched, category: (.category // null),
           failing_gate: ([ $v | to_entries[] | select(.key != "verdict" and (.value | type) == "string" and .value == "fail") | .key ] | first // "unknown")} ]
    ' "$tasks_file" 2>/dev/null) || rejected_payload="[]"

    if [ "$approved_payload" = "[]" ] || [ "$rejected_payload" = "[]" ]; then
        _write_contrastive_skip "$cache_file" "$round" "tasks file did not contain matching task ids"
        return 0
    fi

    local prompt="You are a contrastive-pair selector for a self-improvement loop.

Round ${round} produced both APPROVED and REJECTED tasks. Find the single
clearest pair where ONE approved task and ONE rejected task were addressing
a SIMILAR underlying problem (similar goal, similar subsystem, similar files
touched, or similar mechanism). Then in 1-2 sentences explain what differed
between the approaches such that one passed validation and the other failed.

If no pair shares a clearly similar underlying problem, return skip rather
than forcing one — a forced pair is worse than no pair.

APPROVED TASKS (JSON):
${approved_payload}

REJECTED TASKS (JSON, includes the failing gate):
${rejected_payload}

Output ONLY a single JSON object on one line. No prose, no code fences.
- Pair found:
  {\"approved_id\":\"<id>\",\"rejected_id\":\"<id>\",\"note\":\"<1-2 sentences on what differed>\"}
- No clear shared-problem pair:
  {\"skip\":true,\"reason\":\"<short>\"}"

    local raw judgment
    raw=$(claude -p "$prompt" 2>/dev/null | tr -d '\r') || raw=""
    judgment=$(printf '%s' "$raw" | grep -oE '\{[^{}]*"(approved_id|skip)"[^{}]*\}' | head -1) || judgment=""

    if [ -z "$judgment" ] || ! echo "$judgment" | jq empty 2>/dev/null; then
        _write_contrastive_skip "$cache_file" "$round" "claude returned no parseable JSON"
        return 0
    fi

    # Tag the cache with round + timestamp metadata, preserving claude's keys.
    echo "$judgment" | jq \
        --argjson round "$round" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '. + {round: $round, generated_at: $ts}' \
        > "$cache_file" 2>/dev/null || rm -f "$cache_file"
}

# --- Internal: write a skip-shaped cache file ---
_write_contrastive_skip() {
    local cache_file="$1" round="$2" reason="$3"
    jq -n \
        --argjson round "$round" \
        --arg reason "$reason" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{skip: true, reason: $reason, round: $round, generated_at: $ts}' \
        > "$cache_file" 2>/dev/null || rm -f "$cache_file"
}

# --- Internal: render the contrastive note for a round ---
# Reads contrastive-note-round-N.json and emits a single markdown subsection
# bullet when a pair was found. Silent no-op for skip / missing / malformed
# caches so the surrounding round block stays clean.
_emit_contrastive_note() {
    local round="$1" working_dir="$2"
    local cache_file="$working_dir/contrastive-note-round-${round}.json"

    [ -f "$cache_file" ] || return 0
    jq empty "$cache_file" 2>/dev/null || return 0

    local skip
    skip=$(jq -r '.skip // false' "$cache_file" 2>/dev/null)
    [ "$skip" = "true" ] && return 0

    local approved_id rejected_id note
    approved_id=$(jq -r '.approved_id // ""' "$cache_file" 2>/dev/null)
    rejected_id=$(jq -r '.rejected_id // ""' "$cache_file" 2>/dev/null)
    note=$(jq -r '.note // ""' "$cache_file" 2>/dev/null)

    if [ -z "$approved_id" ] || [ -z "$rejected_id" ] || [ -z "$note" ]; then
        return 0
    fi

    echo ""
    echo "**Contrastive note** (approved **${approved_id}** vs rejected **${rejected_id}**): ${note}"
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
# Surfaces hypotheses whose evaluation window has matured and which still
# have an empty Outcome — i.e. rows where Outcome is empty AND
# Round + Window <= current_round. Rows whose window has not yet matured
# are tracked in the "Open Hypotheses" section instead, so they aren't
# asked about prematurely.
#
# Skips rows whose Scope is "internal-si" when that column exists — those
# are SI-infrastructure hypotheses evaluated within the loop, not via
# real-world user observations. The Scope column is optional.
#
# If current_round is omitted or non-numeric, the round-window check is
# bypassed and every empty-Outcome row surfaces (legacy behaviour). Rows
# with non-numeric Round or Window also bypass the check so older logs
# still surface.
_summary_deferred_evaluation() {
    local hypothesis_log="$1"
    local current_round="${2:-0}"
    local working_dir="${3:-}"

    echo ""
    echo "## Deferred Evaluation Questions"
    echo ""

    if [ ! -f "$hypothesis_log" ]; then
        echo "No hypothesis log found."
        return
    fi

    local scope_col outcome_col evaluator_col requires_col source_col
    scope_col=$(_locate_scope_col "$hypothesis_log")
    outcome_col=$(_locate_log_col "$hypothesis_log" "Outcome")
    evaluator_col=$(_locate_log_col "$hypothesis_log" "Evaluator")
    requires_col=$(_locate_log_col "$hypothesis_log" "Requires")
    source_col=$(_locate_log_col "$hypothesis_log" "Source")
    # Pre-decision-012 logs put Outcome at column 7. Fall back so older
    # in-tree logs keep parsing until they are migrated.
    [[ "$outcome_col" -gt 0 ]] || outcome_col=7

    # Pre-aggregate the usage log once. Downstream precondition checks
    # (_count_invocations / _check_metric_logged) read from the resulting
    # lookup tables instead of spawning jq per (target × precondition).
    _preaggregate_usage_log

    # Classification pass: split the matured-open rows into two groups so the
    # few that are actually ready for a verdict aren't buried under the wall of
    # not-yet-evaluable ones (discoverability-on-creation, semantic-distance,
    # progressive-disclosure). Both groups are buffered with their full body so
    # the emit pass can number them continuously 1..N — the total stays equal to
    # _count_matured_deferred, the feedback-continuity invariant the action
    # block depends on. Nothing is dropped; the deferred group is only collapsed
    # behind a count + <details>, never deleted (invert-the-thesis mitigation).
    #
    # Ready = script-evaluator whose preconditions are MET now (or none declared);
    # _evaluate_script_preconditions signals this via exit 0. Deferred = unmet/
    # unresolvable script rows plus user-evaluator rows, which need real-world
    # observation the user may not yet have and so aren't autonomously ready.
    local -a ready_lines deferred_lines
    local ready_count=0 deferred_count=0
    local -a fields
    while IFS= read -r line; do
        _row_is_open_deferred "$line" "$current_round" "$scope_col" "$outcome_col" || continue

        _split_row_fields "$line" fields
        local round task_id hypothesis evaluator requires hyp_src
        round="${fields[1]:-}"
        task_id="${fields[2]:-}"
        hypothesis="${fields[3]:-}"
        evaluator=$(_pick_col fields "$evaluator_col")
        requires=$(_pick_col fields "$requires_col")
        hyp_src=$(_pick_col fields "$source_col")

        local hyp_tag=""
        if [ "$hyp_src" = "planner" ]; then
            hyp_tag=" *[planner-authored — review framing]*"
        fi
        local header="**${task_id}** (round ${round}): \"${hypothesis}\"${hyp_tag}"

        if [[ "$evaluator" == "script" ]]; then
            # Capture the precondition report and its readiness exit code. Run in
            # a subshell via $(...); the pre-aggregated lookup tables are global
            # and fork into it, so the fast path is preserved.
            local report rc
            report=$(_evaluate_script_preconditions "$round" "$task_id" "$requires" "$working_dir")
            rc=$?
            if [ "$rc" -eq 0 ]; then
                ready_count=$((ready_count + 1))
                ready_lines+=("${header}"$'\n'"${report}")
            else
                deferred_count=$((deferred_count + 1))
                deferred_lines+=("${header}"$'\n'"${report}")
            fi
        else
            deferred_count=$((deferred_count + 1))
            local questions
            questions=$(_generate_questions "$hypothesis")
            deferred_lines+=("${header}"$'\n'"   *(awaiting your observations)*"$'\n'"${questions}")
        fi
    done < "$hypothesis_log"

    local total=$((ready_count + deferred_count))
    if [ "$total" -eq 0 ]; then
        echo "No open hypotheses to evaluate."
        return
    fi

    # Emit pass. Numbering is continuous across both groups (ready first), so
    # `grep -cE '^[0-9]+\.'` over this output equals _count_matured_deferred.
    local n=0 item
    if [ "$ready_count" -gt 0 ]; then
        echo "### Ready for a Verdict (${ready_count})"
        echo ""
        echo "Preconditions are met for these — read the check report and record a"
        echo "CONFIRMED / REFUTED / INCONCLUSIVE outcome in hypothesis-log.md."
        echo ""
        for item in "${ready_lines[@]}"; do
            n=$((n + 1))
            printf '%s. %s\n' "$n" "$item"
            echo ""
        done
    fi

    if [ "$deferred_count" -gt 0 ]; then
        local noun="hypotheses"
        [ "$deferred_count" -eq 1 ] && noun="hypothesis"
        echo "### Not Yet Evaluable (${deferred_count})"
        echo ""
        # Collapse the wall behind a count + expandable block: every row stays
        # reachable (expand to view), but it no longer crowds out the ready few.
        # In a plain terminal the <summary> line still front-loads the count.
        echo "<details>"
        echo "<summary>${deferred_count} open ${noun} not yet ready for a verdict — they need real-world usage or have unmet preconditions. Expand to view.</summary>"
        echo ""
        for item in "${deferred_lines[@]}"; do
            n=$((n + 1))
            printf '%s. %s\n' "$n" "$item"
            echo ""
        done
        echo "</details>"
    fi
}

# --- Internal: strip "<dir>/" prefix from a path, whether absolute or relative ---
# `${path##*/skills/}` only strips when "skills/" appears mid-path; for already-
# relative inputs (skills/foo.md) the substitution is a no-op, so fall back to
# the leading-prefix form. Used to keep the skills/workflows path-classification
# rules in one place.
# --- Internal: extract skill/workflow targets from a task's files_touched ---
# Args: $1 = round, $2 = task_id, $3 = working_dir
# Output: zero or more lines of "skill:NAME" or "workflow:NAME" (deduped)
# Side effect: none. Empty output means the target is unresolvable from this
# task's files_touched (no skill/workflow paths, or task file missing).
_resolve_hypothesis_target() {
    local round="$1" tid="$2" working_dir="$3"
    [ -z "$working_dir" ] && return 0

    # Try current-round file first, then archived copies. The archive prefix is
    # date-stamped, so glob and take the most recent.
    local tasks_file=""
    local candidate
    for candidate in "$working_dir/tasks-round-$round.json" \
                     "$working_dir"/archive/*tasks-round-"$round".json; do
        if [ -f "$candidate" ]; then
            tasks_file="$candidate"
            break
        fi
    done
    [ -f "$tasks_file" ] || return 0

    # Path classification is shared with hooks/log-usage.sh via skill-paths.sh
    # so the target name matches what the logger writes to usage.jsonl.
    jq -r --arg id "$tid" '
        .[] | select(.id == $id) | .files_touched[]?
    ' "$tasks_file" 2>/dev/null | while IFS= read -r path; do
        [ -z "$path" ] && continue
        local classified
        classified=$(classify_skill_path "$path")
        # Workflows are routed through file_read in _count_invocations, so they
        # are valid targets here even though the doc strings emphasise skills.
        case "$classified" in
            skill:*|workflow:*) printf '%s\n' "$classified" ;;
        esac
    done | sort -u
}

# --- Internal: pre-aggregate the usage log into lookup tables ---
# One jq pass over usage.jsonl emits per-(event,name) facts that the
# precondition helpers below consult in constant time:
#   _LOG_INVOKE_COUNTS["$kind:$name"]   — total invocation count
#   _LOG_METRIC_FLAGS["$kind:$name:$f"] — non-empty when field f was logged
# Without pre-aggregation, every (hypothesis × target × precondition)
# spawned its own jq pass that re-scanned the whole log.
# Idempotent: call repeatedly without side effects beyond resetting the
# tables. Tests that call _count_invocations / _check_metric_logged
# directly skip pre-aggregation and fall back to a per-call jq pass.
_preaggregate_usage_log() {
    declare -gA _LOG_INVOKE_COUNTS=()
    declare -gA _LOG_METRIC_FLAGS=()
    _LOG_AGGREGATED=1

    local log="${USAGE_LOG_FILE:-$HOME/.claude/logs/usage.jsonl}"
    [ -f "$log" ] || return 0

    local typ ev name extra key
    while IFS=$'\t' read -r typ ev name extra; do
        case "$typ" in
            INVOKE)
                key="$ev:$name"
                _LOG_INVOKE_COUNTS["$key"]=$(( ${_LOG_INVOKE_COUNTS["$key"]:-0} + 1 ))
                ;;
            METRIC)
                _LOG_METRIC_FLAGS["$ev:$name:$extra"]=1
                ;;
        esac
    done < <(jq -r '
        # Emit one INVOKE row per relevant entry; bash sums them.
        (if (.event == "skill" and .via == "skill_tool")
            or (.event == "workflow" and .via == "file_read") then
            "INVOKE\t\(.event)\t\(.name)"
         else empty end),
        # Emit METRIC rows for any non-null duration_ms / total_tokens
        # on a skill/workflow entry — the original _check_metric_logged
        # matched .event == kind, so we mirror that here.
        (select((.event == "skill" or .event == "workflow")
                and (.duration_ms? // null) != null)
            | "METRIC\t\(.event)\t\(.name)\tduration_ms"),
        (select((.event == "skill" or .event == "workflow")
                and (.total_tokens? // null) != null)
            | "METRIC\t\(.event)\t\(.name)\ttotal_tokens")
    ' "$log" 2>/dev/null)
}

# --- Internal: count invocations of one or more targets in the usage log ---
# Skills are counted with via == "skill_tool" (real Skill-tool calls).
# Workflows have no skill_tool channel, so file_read serves as the proxy —
# documented so it's clear this is a deliberate fallback, not a bug.
# Args: $1 = newline-separated target list (kind:name)
# Output: a single integer (total count across all listed targets)
_count_invocations() {
    local targets="$1"
    [ -z "$targets" ] && { echo 0; return; }

    # Fast path: pre-aggregation done, read from the lookup table.
    if [ "${_LOG_AGGREGATED:-0}" = "1" ]; then
        local total=0
        local line
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            [ -z "${line#*:}" ] && continue
            total=$(( total + ${_LOG_INVOKE_COUNTS["$line"]:-0} ))
        done <<< "$targets"
        echo "$total"
        return
    fi

    # Fallback: no pre-aggregation, scan the log per target.
    local log="${USAGE_LOG_FILE:-$HOME/.claude/logs/usage.jsonl}"
    [ -f "$log" ] || { echo 0; return; }
    local total=0
    local line
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local kind="${line%%:*}"
        local name="${line#*:}"
        [ -z "$name" ] && continue
        local via_filter=".via == \"skill_tool\""
        [ "$kind" = "workflow" ] && via_filter=".via == \"file_read\""
        local count
        count=$(jq -c --arg e "$kind" --arg n "$name" \
            "select(.event == \$e and .name == \$n and $via_filter)" \
            "$log" 2>/dev/null | wc -l)
        total=$((total + count))
    done <<< "$targets"
    echo "$total"
}

# --- Internal: check whether a named field is present in any log entry ---
# Args: $1 = target list, $2 = field name (e.g. "duration_ms", "total_tokens")
# Returns 0 if at least one entry has the named field with a non-null value.
_check_metric_logged() {
    local targets="$1" field="$2"
    [ -z "$targets" ] && return 1

    # Fast path: pre-aggregation done, read from the lookup table.
    if [ "${_LOG_AGGREGATED:-0}" = "1" ]; then
        local line
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            [ -z "${line#*:}" ] && continue
            [ -n "${_LOG_METRIC_FLAGS["$line:$field"]:-}" ] && return 0
        done <<< "$targets"
        return 1
    fi

    # Fallback: no pre-aggregation, scan the log per target.
    local log="${USAGE_LOG_FILE:-$HOME/.claude/logs/usage.jsonl}"
    [ -f "$log" ] || return 1
    local line
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local kind="${line%%:*}"
        local name="${line#*:}"
        [ -z "$name" ] && continue
        local matches
        matches=$(jq -c --arg e "$kind" --arg n "$name" --arg f "$field" '
            select(.event == $e and .name == $n and has($f) and (.[$f] != null))
        ' "$log" 2>/dev/null | head -1)
        [ -n "$matches" ] && return 0
    done <<< "$targets"
    return 1
}

# --- Internal: days elapsed since a given round was recorded ---
# Looks up the round report's `timestamp` field and computes whole days
# elapsed since now. Echoes -1 if the round report is missing or has no
# timestamp (caller treats -1 as "unresolvable"). NOW_EPOCH can be set in
# tests to make the function deterministic.
_days_since_round() {
    local round="$1" working_dir="$2"
    [ -z "$working_dir" ] && { echo -1; return; }

    local report=""
    local candidate
    for candidate in "$working_dir/rounds/round-$round-report.json" \
                     "$working_dir/round-$round-report.json" \
                     "$working_dir"/archive/*round-"$round"-report.json; do
        if [ -f "$candidate" ]; then
            report="$candidate"
            break
        fi
    done
    [ -f "$report" ] || { echo -1; return; }

    local round_ts
    round_ts=$(jq -r '.timestamp // empty' "$report" 2>/dev/null)
    [ -z "$round_ts" ] && { echo -1; return; }

    local now_epoch round_epoch
    now_epoch="${NOW_EPOCH:-$(date -u +%s)}"
    round_epoch=$(date -u -d "$round_ts" +%s 2>/dev/null) || { echo -1; return; }
    echo $(( (now_epoch - round_epoch) / 86400 ))
}

# --- Internal: run the precondition gate for a script-evaluator hypothesis ---
# Args: $1 = round, $2 = task_id, $3 = requires-flattened string
#       (key=val;key=val), $4 = working_dir
# Output: a multi-line report block emitted to stdout, indented to fit under
# the row header in _summary_deferred_evaluation. The script never writes to
# the hypothesis log — the user reviews this report and decides the outcome.
#
# Exit code (readiness signal consumed by _summary_deferred_evaluation):
#   0 = ready for a verdict now (all preconditions MET, or none declared)
#   1 = not yet evaluable (precondition UNMET / unresolvable target / unknown key)
# The exit code is purely additive — every output string this function printed
# before is unchanged, so callers that only inspect stdout are unaffected.
_evaluate_script_preconditions() {
    local round="$1" tid="$2" requires_str="$3" working_dir="$4"
    echo "   Evaluator: script"

    # Resolve target from the task's files_touched. Empty target = unresolvable.
    local targets
    targets=$(_resolve_hypothesis_target "$round" "$tid" "$working_dir")
    if [ -z "$targets" ]; then
        echo "   Target: unresolvable (no skill/workflow in files_touched)"
        echo "   → Recommendation: switch evaluator to \"user\" or restate the hypothesis"
        return 1
    fi
    echo "   Target(s): $(echo "$targets" | tr '\n' ',' | sed 's/,$//;s/,/, /g')"

    if [ -z "$requires_str" ]; then
        echo "   Preconditions: none declared"
        echo "   → Recommendation: this hypothesis can be evaluated now if signal is sufficient"
        return 0
    fi

    # Parse the flattened requires string. Unknown keys are surfaced so the
    # planner can fix a typo rather than have the gate silently ignore it.
    local req_metric="" req_invocations="" req_days="" req_unknown=""
    local -a pairs
    IFS=';' read -ra pairs <<< "$requires_str"
    local pair key val
    for pair in "${pairs[@]}"; do
        key="${pair%%=*}"
        val="${pair#*=}"
        key="${key// /}"
        val="${val# }"; val="${val% }"
        case "$key" in
            metric_logged) req_metric="$val" ;;
            invocations)   req_invocations="$val" ;;
            days_elapsed)  req_days="$val" ;;
            "") ;;
            *) req_unknown="${req_unknown:+$req_unknown, }$key" ;;
        esac
    done

    local all_met=1
    local reasons=""
    local checks=""

    if [ -n "$req_invocations" ]; then
        local actual
        actual=$(_count_invocations "$targets")
        if [ "$actual" -ge "$req_invocations" ]; then
            checks="${checks}   - invocations≥${req_invocations}: MET (current: ${actual})"$'\n'
        else
            all_met=0
            checks="${checks}   - invocations≥${req_invocations}: UNMET (current: ${actual})"$'\n'
            reasons="${reasons:+$reasons; }invocations short (${actual}/${req_invocations})"
        fi
    fi

    if [ -n "$req_metric" ]; then
        if _check_metric_logged "$targets" "$req_metric"; then
            checks="${checks}   - metric_logged=${req_metric}: MET"$'\n'
        else
            all_met=0
            checks="${checks}   - metric_logged=${req_metric}: UNMET (no entries with this field)"$'\n'
            reasons="${reasons:+$reasons; }metric ${req_metric} never logged"
        fi
    fi

    if [ -n "$req_days" ]; then
        local elapsed
        elapsed=$(_days_since_round "$round" "$working_dir")
        if [ "$elapsed" -lt 0 ]; then
            all_met=0
            checks="${checks}   - days_elapsed≥${req_days}: UNRESOLVABLE (no round timestamp)"$'\n'
            reasons="${reasons:+$reasons; }round timestamp unavailable"
        elif [ "$elapsed" -ge "$req_days" ]; then
            checks="${checks}   - days_elapsed≥${req_days}: MET (current: ${elapsed})"$'\n'
        else
            all_met=0
            checks="${checks}   - days_elapsed≥${req_days}: UNMET (current: ${elapsed})"$'\n'
            reasons="${reasons:+$reasons; }only ${elapsed}/${req_days} days elapsed"
        fi
    fi

    if [ -n "$req_unknown" ]; then
        all_met=0
        checks="${checks}   - unknown keys in requires: ${req_unknown}"$'\n'
        reasons="${reasons:+$reasons; }unknown precondition keys: ${req_unknown}"
    fi

    [ -n "$checks" ] && printf '%s' "$checks"

    if [ "$all_met" -eq 1 ]; then
        echo "   → Recommendation: preconditions met, ready for CONFIRMED/REFUTED verdict"
        return 0
    else
        echo "   → Recommendation: mark INCONCLUSIVE in hypothesis-log.md (${reasons})"
        return 1
    fi
}

# --- Internal: split a pipe-delimited markdown row into a fields array ---
# Writes into the array name passed by reference. Fields are trimmed of
# leading/trailing whitespace. Indexing matches awk's `-F'|'` convention:
# fields[0] is the empty string before the leading "|", so awk's $N maps
# to fields[N-1] when N>=1.
# Args: $1 = row, $2 = array variable name (nameref)
_split_row_fields() {
    local line="$1"
    local -n out_ref="$2"
    local -a raw
    IFS='|' read -ra raw <<< "$line"
    out_ref=()
    local f trimmed
    for f in "${raw[@]}"; do
        trimmed="${f#"${f%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
        out_ref+=("$trimmed")
    done
}

# Pick column `col` (1-based, awk-style) from a pre-split fields array.
# Returns empty when col == 0 (the convention _locate_log_col uses for
# "not found"), so callers can fold the absent-column branch into one call.
# Args: $1 = array name (nameref), $2 = 1-based column
_pick_col() {
    local -n arr_ref="$1"
    local col="$2"
    [[ "$col" -gt 0 ]] || return 0
    printf '%s' "${arr_ref[$((col-1))]:-}"
}

# --- Internal: locate a named column's index in the log header ---
# Returns the 1-based awk field index of a named column in the first header
# row, or 0 if the column is absent. The header is identified as the line
# starting with a pipe AND containing " Round " (a column every header has),
# so we don't match hypothesis text that happens to mention the column name.
# Args: $1 = hypothesis log path, $2 = column name to locate
_locate_log_col() {
    local hypothesis_log="$1" col_name="$2"
    local idx
    idx=$(awk -F'|' -v col="$col_name" '
        /^\|/ && / Round / {
            for (i = 1; i <= NF; i++) {
                gsub(/^[ \t]+|[ \t]+$/, "", $i)
                if ($i == col) { print i; exit }
            }
            exit
        }
    ' "$hypothesis_log")
    echo "${idx:-0}"
}

# Backward-compatible wrapper. Several call sites used this before
# _locate_log_col existed; keep the name to minimise diff churn.
_locate_scope_col() {
    _locate_log_col "$1" "Scope"
}

# --- Internal: shared row filter for deferred-question scans ---
# Returns 0 (true) if the row should be surfaced as a deferred question:
#   - is a data row (not header / separator)
#   - has a non-empty Task ID
#   - has an empty Outcome (column index supplied by caller)
#   - is not Scope=internal-si (when that column exists)
#   - has Round + Window <= current_round (when current_round > 0 and
#     both Round and Window parse as integers)
#
# Returns 1 otherwise. current_round=0 disables the round-window check
# so legacy callers behave unchanged. outcome_col defaults to 7 to keep
# the function callable from older code paths that don't supply it.
_row_is_open_deferred() {
    local line="$1"
    local current_round="${2:-0}"
    local scope_col="${3:-0}"
    local outcome_col="${4:-7}"

    [[ "$line" != \|* ]] && return 1
    [[ "$line" =~ ^\|[[:space:]]*(Round|----) ]] && return 1

    local -a fields
    _split_row_fields "$line" fields

    local round task_id window outcome
    round="${fields[1]:-}"
    task_id="${fields[2]:-}"
    window="${fields[4]:-}"
    outcome=$(_pick_col fields "$outcome_col")

    [[ -z "$task_id" ]] && return 1
    [[ -n "$outcome" ]] && return 1

    if [[ "$scope_col" -gt 0 ]]; then
        local scope
        scope=$(_pick_col fields "$scope_col")
        [[ "$scope" == "internal-si" ]] && return 1
    fi

    # Round-window gate: only apply when caller supplied a positive
    # current_round AND both round/window parse as non-negative integers.
    # Otherwise keep legacy behaviour (surface on empty outcome alone).
    if [[ "$current_round" =~ ^[0-9]+$ ]] && [[ "$current_round" -gt 0 ]] \
       && [[ "$round" =~ ^[0-9]+$ ]] && [[ "$window" =~ ^[0-9]+$ ]]; then
        if (( round + window > current_round )); then
            return 1
        fi
    fi

    return 0
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
