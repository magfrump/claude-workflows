#!/bin/bash
# Shared utility functions for the self-improvement loop.
# Sourced by scripts/self-improvement.sh — do not execute directly.
#
# Functions:
#   validate_task_json   — Schema-validate a tasks JSON file
#   check_convergence_threshold — Compare overlap % against a threshold
#   print_gate_stats     — Print per-gate pass/fail/skip rates from round history
#   detect_duplicate_candidates — Surface candidate-vs-prior matches for a round
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

# --- Duplicate-candidate detector ---
# Surfaces candidate-vs-prior matches by keyword overlap. Runs after DD has
# written feature-ideas-round-$round.md, before the SI loop's task-filtering
# (prune) step — gives the round a chance to review near-duplicates without
# auto-pruning anything.
#
# Args:
#   $1 = round number
#   $2 = working directory (e.g., docs/working)
#
# Reads:
#   $2/feature-ideas-round-$1.md            (current round's candidates)
#   $2/feature-ideas-round-*.md             (prior rounds, current excluded)
#   $2/archive/*feature-ideas-round-*.md    (archived prior cycles)
#   $2/completed-tasks.md                   (running list of approved work)
#   $2/archive/*completed-tasks.md          (archived completed-task lists)
#
# Writes:
#   $2/duplicates-round-$1.md   Report of flagged candidates with prior matches
#
# Stdout: one summary line. Exits 0 even when no priors exist or no flags.
#
# Env vars:
#   DUPLICATE_OVERLAP_THRESHOLD  Percent of candidate-name keywords (4+ chars,
#                                stopwords stripped) that must appear in a
#                                prior file to flag as a near-duplicate
#                                (default: 50).
detect_duplicate_candidates() {
    local round=$1
    local working_dir=$2
    local current_file="$working_dir/feature-ideas-round-${round}.md"
    local report="$working_dir/duplicates-round-${round}.md"
    local threshold="${DUPLICATE_OVERLAP_THRESHOLD:-50}"

    if [ ! -f "$current_file" ]; then
        echo "  Duplicate detector: no ideas file at $current_file, skipping" >&2
        return 0
    fi

    # Collect prior files. Bash leaves a glob literal in place when no match;
    # the -f test filters those out, so the four globs are safe even when the
    # archive directory or earlier rounds don't exist.
    local prior_files=()
    local pattern f
    for pattern in \
        "$working_dir"/feature-ideas-round-*.md \
        "$working_dir"/archive/*feature-ideas-round-*.md \
        "$working_dir"/completed-tasks.md \
        "$working_dir"/archive/*completed-tasks.md
    do
        for f in $pattern; do
            [ -f "$f" ] || continue
            # Skip the current round's own ideas file
            [ "$f" -ef "$current_file" ] && continue
            prior_files+=("$f")
        done
    done

    # Stopword list. Includes generic English filler plus SI-domain words that
    # would otherwise match every candidate (e.g. "round", "task", "skill").
    # Without this filter, names like "Round-N task summary" trigger spurious
    # high-overlap matches against any prior round's metadata.
    local stopwords='this|that|with|when|from|will|does|been|have|each|over|into|than|then|some|such|also|where|what|which|while|after|before|other|these|those|there|their|about|because|between|across|during|under|using|used|onto|just|should|would|could|might|must|need|needs|make|makes|made|takes|take|gets|sets|puts|lets|mode|file|files|line|lines|task|tasks|round|rounds|step|steps|note|notes|idea|ideas|word|words|case|cases|rule|rules|tool|tools|kind|sort|type|types|item|items|name|names|part|parts|side|sides|time|times|year|years|good|done|long|same|less|more|much|most|many|both|here|even|self|like|true|false|null|none|external|internal|skill|skills|workflow|workflows|repo|repos|main|head|prior|next|new|old'

    # Build report header.
    {
        echo "# Duplicate Candidate Report — Round ${round}"
        echo ""
        echo "_Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)_"
        echo ""
        echo "Threshold: ≥${threshold}% of candidate-name keywords appearing in a prior file."
        echo "Sources scanned: ${#prior_files[@]} prior file(s)."
        echo ""
        echo "Surfaces possible near-duplicates for review before pruning. This report"
        echo "is informational — no candidates have been pruned automatically."
        echo ""
    } > "$report"

    if [ "${#prior_files[@]}" -eq 0 ]; then
        echo "_No prior files found; nothing to compare against._" >> "$report"
        echo "  Duplicate detector: no prior files; wrote empty report"
        return 0
    fi

    # Extract candidate header lines: "<n>. **[TAG] Name** — desc..." or
    # "<n>. **Name** — desc...". The DD diverge step uses one numbered list
    # entry per candidate, with the name in bold.
    local candidates_tmp
    candidates_tmp=$(mktemp)
    grep -E '^[[:space:]]*[0-9]+\.[[:space:]]+\*\*[^*]+\*\*' "$current_file" > "$candidates_tmp" || true

    local total_candidates=0 flagged_candidates=0
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        total_candidates=$((total_candidates + 1))

        # Pull bolded name; strip optional [TAG] prefix that the DD prompt
        # asks Claude to attach (e.g. "[EXTERNAL]" / "[INTERNAL]").
        local name
        name=$(echo "$line" | sed -n 's/.*\*\*\([^*]*\)\*\*.*/\1/p' | sed 's/^\[[^]]*\][[:space:]]*//')
        [ -z "$name" ] && continue

        # Tokenize the name into a deduped keyword set. The trailing `|| true`
        # absorbs the exit-1 grep returns when every token is a stopword,
        # which would otherwise trip the parent script's pipefail.
        local keywords kw_count
        keywords=$(echo "$name" \
            | tr '[:upper:]' '[:lower:]' \
            | tr -c 'a-z0-9' '\n' \
            | awk 'length($0) >= 4' \
            | { grep -Evw "$stopwords" || true; } \
            | sort -u)
        kw_count=$(echo "$keywords" | grep -c . || true)

        # Skip candidates whose name reduces to fewer than 2 substantive
        # tokens — overlap percentages are meaningless on 1-token sets.
        if [ "$kw_count" -lt 2 ]; then
            continue
        fi

        local matches="" prior prior_lower matched pct hit_line basename_prior
        for prior in "${prior_files[@]}"; do
            prior_lower=$(tr '[:upper:]' '[:lower:]' < "$prior")
            matched=0
            while IFS= read -r kw; do
                [ -z "$kw" ] && continue
                if echo "$prior_lower" | grep -qw "$kw"; then
                    matched=$((matched + 1))
                fi
            done <<< "$keywords"

            pct=$(( (matched * 100) / kw_count ))
            if [ "$pct" -ge "$threshold" ]; then
                basename_prior=$(basename "$prior")
                # Try to surface a context snippet by searching for the longest
                # keyword in the prior file (case-insensitive). Falls back to
                # the file name only if no snippet is found.
                local longest_kw
                longest_kw=$(echo "$keywords" | awk '{ print length, $0 }' | sort -rn | head -1 | cut -d' ' -f2-)
                hit_line=""
                if [ -n "$longest_kw" ]; then
                    hit_line=$(grep -i -m1 -F "$longest_kw" "$prior" 2>/dev/null | head -c 200 | tr -d '\n' || true)
                fi
                if [ -n "$hit_line" ]; then
                    matches+="- **${pct}%** overlap with \`${basename_prior}\`: ${hit_line}"$'\n'
                else
                    matches+="- **${pct}%** overlap with \`${basename_prior}\`"$'\n'
                fi
            fi
        done

        if [ -n "$matches" ]; then
            flagged_candidates=$((flagged_candidates + 1))
            {
                echo "## ${name}"
                echo ""
                printf '%s\n' "$matches"
            } >> "$report"
        fi
    done < "$candidates_tmp"
    rm -f "$candidates_tmp"

    {
        echo "---"
        echo ""
        echo "**Summary:** ${flagged_candidates} of ${total_candidates} candidate(s) flagged at ≥${threshold}% keyword overlap."
    } >> "$report"

    echo "  Duplicate detector: ${flagged_candidates}/${total_candidates} flagged (report: $report)"
}
