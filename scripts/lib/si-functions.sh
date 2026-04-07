#!/bin/bash
# si-functions.sh — Library of functions extracted from self-improvement.sh
# Sourced by self-improvement.sh; not intended to be run directly.
#
# These functions expect the following globals to be set by the caller:
#   ROUND_LOG_FILE  — path to the current round's temp log file
#   WORKING_DIR     — path to docs/working directory
#   ROUND_HISTORY   — path to round-history.json

# --- JSON logging helpers ---

# Clean up temp files on early exit
cleanup() {
    if [ -n "$ROUND_LOG_FILE" ] && [ -f "$ROUND_LOG_FILE" ]; then
        rm -f "$ROUND_LOG_FILE"
    fi
}

# Initialize a round log object as a temp file; sets ROUND_LOG_FILE
init_round_log() {
    local round=$1
    ROUND_LOG_FILE=$(mktemp)
    jq -n --argjson round "$round" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{round: $round, timestamp: $ts, ideas: {}, tasks: {}, validation: {}, merges: {}, outcome: "incomplete"}' \
        > "$ROUND_LOG_FILE"
}

# Update a top-level field in the round log
update_round_log() {
    local path=$1 value=$2
    local tmp
    tmp=$(mktemp)
    jq --argjson v "$value" "$path = \$v" "$ROUND_LOG_FILE" > "$tmp" && mv "$tmp" "$ROUND_LOG_FILE"
}

# Record a gate result for a task
record_gate() {
    local task_id=$1 gate=$2 status=$3
    local tmp
    tmp=$(mktemp)
    jq --arg tid "$task_id" --arg g "$gate" --arg s "$status" \
        '.validation[$tid][$g] = $s' "$ROUND_LOG_FILE" > "$tmp" && mv "$tmp" "$ROUND_LOG_FILE"
}

# Record structured failure details for a gate
# Args: $1 = task_id, $2 = gate name, $3 = JSON object with detail fields
record_gate_detail() {
    local task_id=$1 gate=$2 detail_json=$3
    local detail_key="${gate}_detail"
    local tmp
    tmp=$(mktemp)
    jq --arg tid "$task_id" --arg dk "$detail_key" --argjson detail "$detail_json" \
        '.validation[$tid][$dk] = $detail' "$ROUND_LOG_FILE" > "$tmp" && mv "$tmp" "$ROUND_LOG_FILE"
}

# Write per-round report and append to round-history.json
finalize_round_log() {
    local round=$1
    # Write per-round report
    cp "$ROUND_LOG_FILE" "$WORKING_DIR/round-${round}-report.json"

    # Append to round-history.json
    local tmp
    tmp=$(mktemp)
    jq --slurpfile entry "$ROUND_LOG_FILE" '. += $entry' "$ROUND_HISTORY" > "$tmp" && mv "$tmp" "$ROUND_HISTORY"

    rm -f "$ROUND_LOG_FILE"
}

# --- Task JSON schema validation ---
# Validates each task in a tasks JSON file against the expected schema.
# Outputs a filtered JSON array (valid tasks only) to stdout.
# Prints rejection reasons to stderr.
# Args: $1 = path to tasks JSON file
validate_task_json() {
    local tasks_file=$1
    local valid_tasks="[]"
    local task_count
    task_count=$(jq 'length' "$tasks_file")

    for i in $(seq 0 $((task_count - 1))); do
        local task
        task=$(jq ".[$i]" "$tasks_file")
        local tid
        tid=$(echo "$task" | jq -r '.id // empty')

        # Check required fields and types
        local schema_err=""
        schema_err=$(echo "$task" | jq -r '
            def check:
                if (.id | type) != "string" or (.id | length) == 0 then "id must be a non-empty string"
                elif (.description | type) != "string" or (.description | length) == 0 then "description must be a non-empty string"
                elif (.files_touched | type) != "array" or (.files_touched | length) == 0 then "files_touched must be a non-empty array"
                elif (.independent | type) != "boolean" then "independent must be a boolean"
                else empty
                end;
            check
        ')

        if [ -n "$schema_err" ]; then
            echo "  SCHEMA REJECT [${tid:-task-$i}]: $schema_err" >&2
            continue
        fi

        # Check files_touched entries for glob patterns and valid parent directories
        local ft_errors=""
        local ft_count
        ft_count=$(echo "$task" | jq '.files_touched | length')
        for j in $(seq 0 $((ft_count - 1))); do
            local fpath
            fpath=$(echo "$task" | jq -r ".files_touched[$j]")

            # Reject glob patterns (*, ?, [)
            if echo "$fpath" | grep -qE '[*?[]'; then
                ft_errors="${ft_errors}glob pattern in files_touched: $fpath; "
                continue
            fi

            # Check parent directory exists in the repo
            local parent_dir grandparent_dir
            parent_dir=$(dirname "$fpath")
            grandparent_dir=$(dirname "$parent_dir")
            if [ "$parent_dir" != "." ] && [ ! -d "$parent_dir" ]; then
                if [ "$grandparent_dir" = "." ] || [ -d "$grandparent_dir" ]; then
                    # Single-level missing dir: warn but allow (unblocks .gitkeep creation)
                    echo "  LINT WARNING [$tid]: parent directory does not exist: $parent_dir (for $fpath)" >&2
                else
                    ft_errors="${ft_errors}parent directory does not exist: $parent_dir (for $fpath); "
                fi
            fi
        done

        if [ -n "$ft_errors" ]; then
            echo "  SCHEMA REJECT [$tid]: $ft_errors" >&2
            continue
        fi

        # Task passed validation — add to valid list
        valid_tasks=$(echo "$valid_tasks" | jq --argjson t "$task" '. += [$t]')
    done

    echo "$valid_tasks"
}

# --- Task description linter ---
# Advisory warnings for common task description failure patterns.
# Non-blocking: prints warnings to stderr and always returns 0.
# Args: $1 = path to tasks JSON file
lint_task_descriptions() {
    local tasks_file=$1
    local task_count
    task_count=$(jq 'length' "$tasks_file")

    for i in $(seq 0 $((task_count - 1))); do
        local tid desc
        tid=$(jq -r ".[$i].id" "$tasks_file")
        desc=$(jq -r ".[$i].description" "$tasks_file")
        local ft_count
        ft_count=$(jq ".[$i].files_touched | length" "$tasks_file")

        local has_sh=false
        local has_workflow_md=false
        local creates_new_sh=false

        for j in $(seq 0 $((ft_count - 1))); do
            local fpath parent_dir
            fpath=$(jq -r ".[$i].files_touched[$j]" "$tasks_file")
            parent_dir=$(dirname "$fpath")

            # (a) Parent directory doesn't exist
            if [ "$parent_dir" != "." ] && [ ! -d "$parent_dir" ]; then
                echo "  LINT WARNING [$tid]: parent directory does not exist: $parent_dir (for $fpath)" >&2
            fi

            # Track file types for cross-checks
            case "$fpath" in
                *.sh)
                    has_sh=true
                    if [ ! -f "$fpath" ]; then
                        creates_new_sh=true
                    fi
                    ;;
            esac
            case "$fpath" in
                workflows/*.md) has_workflow_md=true ;;
            esac
        done

        # (b) .sh files but description doesn't mention shellcheck
        if $has_sh; then
            if ! echo "$desc" | grep -qi 'shellcheck'; then
                echo "  LINT WARNING [$tid]: touches .sh files but description does not mention 'shellcheck'" >&2
            fi
        fi

        # (c) creates new .sh file but description doesn't mention shell safety practices
        if $creates_new_sh; then
            if ! echo "$desc" | grep -qiE 'set -euo pipefail|shellcheck'; then
                echo "  LINT WARNING [$tid]: creates new .sh file but description does not mention 'set -euo pipefail' or 'shellcheck'" >&2
            fi
        fi

        # (d) workflow .md files but description doesn't mention BATS or section
        if $has_workflow_md; then
            if ! echo "$desc" | grep -qiE 'BATS|section'; then
                echo "  LINT WARNING [$tid]: touches workflow .md files but description does not mention 'BATS' or 'section'" >&2
            fi
        fi
    done

    return 0
}

# --- Round summary printer ---
# Reads the current ROUND_LOG_FILE to print a one-line human-readable summary.
# Args: $1 = round number, $2 = validation log path
# Output format: Round N: X launched, Y approved, Z rejected (failure modes: ...)
print_round_summary() {
    local round=$1
    local validation_log=$2

    local launched approved rejected failure_modes summary_line
    launched=$(jq '[.validation | to_entries[] | select(.value.verdict != null)] | length' "$ROUND_LOG_FILE")
    approved=$(jq '[.validation | to_entries[] | select(.value.verdict == "approved")] | length' "$ROUND_LOG_FILE")
    rejected=$(jq '[.validation | to_entries[] | select(.value.verdict == "rejected")] | length' "$ROUND_LOG_FILE")

    # Extract failure modes: for each rejected task, find gates that failed
    failure_modes=$(jq -r '
        [.validation | to_entries[] | select(.value.verdict == "rejected") |
         .value | to_entries[] | select(.value == "fail" and .key != "verdict") | .key
        ] | unique | join(", ")' "$ROUND_LOG_FILE")

    if [ -z "$failure_modes" ]; then
        summary_line="Round ${round}: ${launched} launched, ${approved} approved, ${rejected} rejected"
    else
        summary_line="Round ${round}: ${launched} launched, ${approved} approved, ${rejected} rejected (failure modes: ${failure_modes})"
    fi

    echo "$summary_line"
    echo "$summary_line" >> "$validation_log"
}

# --- Convergence threshold check ---
# Pure function: compares an overlap percentage against a threshold.
# Args: $1 = overlap percentage (integer 0-100), $2 = threshold (integer 0-100)
# Returns: 0 if overlap >= threshold (at-or-above), 1 if below.
# Returns 1 (below) for empty or non-integer input.
check_convergence_threshold() {
    local overlap="${1:-}"
    local threshold="${2:-}"

    # Validate both inputs are non-empty integers
    if [[ -z "$overlap" || -z "$threshold" ]]; then
        return 1
    fi
    if ! [[ "$overlap" =~ ^[0-9]+$ && "$threshold" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    if [ "$overlap" -ge "$threshold" ]; then
        return 0
    else
        return 1
    fi
}

# --- Hypothesis window eligibility check ---
# Pure function: reads tasks JSON from stdin and outputs IDs of tasks whose
# hypothesis evaluation window has elapsed.
# Args: $1 = current_round (integer), $2 = prior_round (integer)
# Stdin: JSON array of task objects (each may have .hypothesis, .hypothesis_window, .retroactive)
# Stdout: one task ID per line for eligible tasks (empty if none)
# Returns 1 for missing/invalid arguments or malformed JSON.
get_eligible_hypotheses() {
    local current_round="${1:-}"
    local prior_round="${2:-}"

    # Validate both inputs are non-empty positive integers
    if [[ -z "$current_round" || -z "$prior_round" ]]; then
        return 1
    fi
    if ! [[ "$current_round" =~ ^[0-9]+$ && "$prior_round" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    # Read JSON from stdin; jq will fail on malformed input
    jq -r --argjson current "$current_round" --argjson prior "$prior_round" \
        '[.[] | select(.hypothesis != null and .hypothesis != "") |
          select(.retroactive != true) |
          select(($current - $prior) >= (.hypothesis_window // 3))] | .[]? | .id' \
        2>/dev/null || return 1
}
