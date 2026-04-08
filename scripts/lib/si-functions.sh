#!/bin/bash
# Shared utility functions for the self-improvement loop.
# Sourced by scripts/self-improvement.sh — do not execute directly.
#
# Functions:
#   validate_task_json   — Schema-validate a tasks JSON file
#   check_convergence_threshold — Compare overlap % against a threshold
#   print_hypothesis_summary — Print hypothesis status dashboard to stdout
#   get_eligible_hypotheses — Find tasks whose hypothesis window has elapsed

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: this file should be sourced, not executed directly" >&2
    exit 1
fi

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

# --- Hypothesis summary dashboard ---
# Reads docs/working/hypothesis-log.md, parses hypothesis entries, counts by
# status, identifies hypotheses approaching their evaluation window, and prints
# a formatted summary table to stdout.
# Args: $1 = current_round (integer, optional — derived from log if omitted)
#       $2 = hypothesis_log path (optional — defaults to docs/working/hypothesis-log.md)
# Stdout: formatted summary table
# Returns 1 if the hypothesis log is missing or has no entries.
print_hypothesis_summary() {
    local current_round="${1:-}"
    local repo_root
    repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    local log_file="${2:-$repo_root/docs/working/hypothesis-log.md}"

    if [ ! -f "$log_file" ]; then
        echo "No hypothesis log found at $log_file" >&2
        return 1
    fi

    # Parse markdown table rows (skip header and separator lines)
    # Fields: Round | Task ID | Hypothesis | Window | Checked at Round | Outcome | Status Date | Evidence
    local entries=()
    local line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # Skip non-table lines and header/separator rows
        [[ "$line" != \|* ]] && continue
        # Skip header row (contains "Round") and separator row (contains "---")
        echo "$line" | grep -qE '^\|\s*(Round|----)' && continue

        entries+=("$line")
    done < "$log_file"

    if [ ${#entries[@]} -eq 0 ]; then
        echo "No hypothesis entries found." >&2
        return 1
    fi

    # Count by status
    local confirmed=0 refuted=0 inconclusive=0 tracking=0
    local -a tracking_entries=()

    for entry in "${entries[@]}"; do
        # Extract fields by splitting on |
        local round task_id window outcome
        round=$(echo "$entry" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
        task_id=$(echo "$entry" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
        window=$(echo "$entry" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $5); print $5}')
        outcome=$(echo "$entry" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $7); print $7}')

        # Default window to 3 if empty
        if [[ -z "$window" || ! "$window" =~ ^[0-9]+$ ]]; then
            window=3
        fi

        case "$outcome" in
            CONFIRMED) confirmed=$((confirmed + 1)) ;;
            REFUTED) refuted=$((refuted + 1)) ;;
            INCONCLUSIVE-EXPIRED) inconclusive=$((inconclusive + 1)) ;;
            *)
                tracking=$((tracking + 1))
                tracking_entries+=("$round|$task_id|$window")
                ;;
        esac
    done

    local total=$((confirmed + refuted + inconclusive + tracking))

    # Determine current round if not provided: use max round from log
    if [[ -z "$current_round" || ! "$current_round" =~ ^[0-9]+$ ]]; then
        current_round=0
        for entry in "${entries[@]}"; do
            local r
            r=$(echo "$entry" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
            if [[ "$r" =~ ^[0-9]+$ ]] && [ "$r" -gt "$current_round" ]; then
                current_round=$r
            fi
        done
    fi

    # Print summary
    echo ""
    echo "=== Hypothesis Dashboard ==="
    echo ""
    printf "%-24s %s\n" "STATUS" "COUNT"
    printf "%-24s %s\n" "------------------------" "-----"
    printf "%-24s %d\n" "CONFIRMED" "$confirmed"
    printf "%-24s %d\n" "REFUTED" "$refuted"
    printf "%-24s %d\n" "INCONCLUSIVE-EXPIRED" "$inconclusive"
    printf "%-24s %d\n" "TRACKING" "$tracking"
    printf "%-24s %s\n" "------------------------" "-----"
    printf "%-24s %d\n" "TOTAL" "$total"

    # Identify hypotheses approaching or past their evaluation window
    if [ ${#tracking_entries[@]} -gt 0 ]; then
        echo ""
        echo "Active hypotheses:"
        printf "  %-30s %-8s %-8s %s\n" "TASK ID" "ROUND" "WINDOW" "EVAL STATUS"
        printf "  %-30s %-8s %-8s %s\n" "------------------------------" "--------" "--------" "-----------"
        for te in "${tracking_entries[@]}"; do
            local r tid w eval_round remaining eval_status
            r=$(echo "$te" | cut -d'|' -f1)
            tid=$(echo "$te" | cut -d'|' -f2)
            w=$(echo "$te" | cut -d'|' -f3)

            if [[ "$r" =~ ^[0-9]+$ ]]; then
                eval_round=$((r + w))
                remaining=$((eval_round - current_round))
            else
                eval_round="?"
                remaining="?"
            fi

            if [[ "$remaining" == "?" ]]; then
                eval_status="unknown"
            elif [ "$remaining" -le 0 ]; then
                eval_status="OVERDUE (due round $eval_round)"
            elif [ "$remaining" -eq 1 ]; then
                eval_status="DUE NEXT ROUND ($eval_round)"
            else
                eval_status="due round $eval_round ($remaining rounds)"
            fi

            printf "  %-30s %-8s %-8s %s\n" "$tid" "$r" "$w" "$eval_status"
        done
    fi
    echo ""
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
