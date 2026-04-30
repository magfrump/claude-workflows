#!/bin/bash
# Shared utility functions for the self-improvement loop.
# Sourced by scripts/self-improvement.sh — do not execute directly.
#
# Functions:
#   validate_task_json   — Schema-validate a tasks JSON file
#   check_convergence_threshold — Compare overlap % against a threshold
#   print_gate_stats     — Print per-gate pass/fail/skip rates from round history
#
# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: this file should be sourced, not executed directly" >&2
    exit 1
fi

# Allowed values for the per-task category field. Kept as a single-source-of-
# truth string so the planner prompt, validator, and morning summary agree.
# Why three values only: avoids bikeshedding while still surfacing when feature
# work is crowding out maintenance and data-pipeline repairs.
TASK_CATEGORIES_ALLOWED="feature maintenance data-pipeline"

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

        # Check category field. Strict-when-present: invalid values reject;
        # absence is a lint warning so the loop keeps running until the
        # planner prompt is updated to emit categories. See
        # docs/working/scope-exception-r3-task-category-tagging.md.
        local category
        category=$(echo "$task" | jq -r '.category // ""')
        if [ -z "$category" ]; then
            echo "  LINT WARNING [$tid]: category missing — planner should assign one of: $TASK_CATEGORIES_ALLOWED" >&2
        elif ! echo " $TASK_CATEGORIES_ALLOWED " | grep -q " $category "; then
            echo "  SCHEMA REJECT [$tid]: category must be one of: $TASK_CATEGORIES_ALLOWED (got: $category)" >&2
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

# --- Gate stats dashboard ---
# Reads round-history.json (or a provided path) and prints per-gate pass/fail/skip
# rates aggregated across all rounds.
# Args: $1 = round_history path (optional — defaults to docs/working/round-history.json)
# Stdout: formatted gate stats table
# Returns 1 if the file is missing, empty, or not valid JSON.
print_gate_stats() {
    local repo_root
    repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    local history_file="${1:-$repo_root/docs/working/round-history.json}"

    if [ ! -f "$history_file" ]; then
        echo "No round history found at $history_file" >&2
        return 1
    fi

    # Validate JSON and extract gate stats in one jq call.
    # For each validation entry, iterate over keys that are not "verdict",
    # and count pass/fail/skip per gate name.
    local stats
    stats=$(jq -r '
        if type != "array" then error("not an array") else . end |
        [ .[] | .validation // {} | to_entries[] | .value | to_entries[] |
          select(.key != "verdict") ] |
        if length == 0 then error("no gate data") else . end |
        group_by(.key) |
        map({
            gate: .[0].key,
            pass: ([.[] | select(.value == "pass")] | length),
            fail: ([.[] | select(.value == "fail")] | length),
            skip: ([.[] | select(.value == "skip")] | length),
            total: length
        }) |
        sort_by(.gate) |
        .[] |
        "\(.gate)\t\(.pass)\t\(.fail)\t\(.skip)\t\(.total)"
    ' "$history_file" 2>/dev/null)

    if [ -z "$stats" ]; then
        echo "No gate evaluation data found." >&2
        return 1
    fi

    echo ""
    echo "=== Gate Stats (all rounds) ==="
    echo ""
    printf "%-25s %s\n" "GATE" "PASS RATE"
    printf "%-25s %s\n" "-------------------------" "-------------------"

    while IFS=$'\t' read -r gate pass fail skip total; do
        if [ "$total" -gt 0 ]; then
            local pct=$(( (pass * 100) / total ))
            local detail="${pass}/${total} pass (${pct}%)"
            if [ "$fail" -gt 0 ]; then
                detail="${detail}, ${fail} fail"
            fi
            if [ "$skip" -gt 0 ]; then
                detail="${detail}, ${skip} skip"
            fi
            printf "%-25s %s\n" "$gate" "$detail"
        fi
    done <<< "$stats"

    echo ""
}
