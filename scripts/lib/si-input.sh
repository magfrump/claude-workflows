#!/bin/bash
# Pre-run input parser for the self-improvement loop.
# Reads a structured markdown file with user feedback, priorities,
# off-limits topics, and context for injection into the DD prompt.
#
# Sourced by scripts/self-improvement.sh — do not execute directly.
#
# Functions:
#   parse_si_input — Parse si-input.md and export section variables
#   parse_si_priority_hypotheses — Extract user-supplied (priority, hypothesis)
#       pre-commitment pairs from SI_PRIORITIES; emits JSON to stdout
#   prepend_si_input_rejected_history — New-cycle bootstrap: prepend an
#       HTML-comment block at the top of si-input.md listing the last
#       3 rounds' rejected task IDs and first-line rejection reasons
#
# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: this file should be sourced, not executed directly" >&2
    exit 1
fi

# --- Pre-run input parser ---
# Reads a markdown file with ## Feedback, ## Priorities, ## Off-limits,
# ## Context sections and exports their content as shell variables.
#
# Args: $1 = path to si-input.md
# Exports: SI_FEEDBACK, SI_PRIORITIES, SI_OFF_LIMITS, SI_CONTEXT
# Returns: 0 if file exists (even with empty sections), 1 if missing
parse_si_input() {
    local input_file="${1:-}"

    # Initialize all variables to empty
    SI_FEEDBACK=""
    SI_PRIORITIES=""
    SI_OFF_LIMITS=""
    SI_CONTEXT=""

    if [[ -z "$input_file" || ! -f "$input_file" ]]; then
        echo "  No SI input file found (optional). Running without user input." >&2
        return 1
    fi

    echo "  Reading pre-run input from: $input_file" >&2

    # Extract text under each ## heading, stopping at the next ## heading or EOF.
    # Strips HTML comments and leading/trailing blank lines.
    local current_section=""
    local section_text=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Detect section headings
        if [[ "$line" =~ ^##[[:space:]]+(.*) ]]; then
            # Save previous section
            _save_si_section "$current_section" "$section_text"
            # Start new section
            current_section="${BASH_REMATCH[1]}"
            section_text=""
            continue
        fi

        # Skip HTML comments
        [[ "$line" =~ ^\s*\<!-- ]] && continue
        [[ "$line" =~ ^.*--\>$ ]] && continue

        # Skip the top-level heading
        [[ "$line" =~ ^#[[:space:]] ]] && continue

        # Accumulate text
        section_text+="$line"$'\n'
    done < "$input_file"

    # Save final section
    _save_si_section "$current_section" "$section_text"

    # Trim leading/trailing blank lines from each variable
    SI_FEEDBACK=$(_trim_blank_lines "$SI_FEEDBACK")
    SI_PRIORITIES=$(_trim_blank_lines "$SI_PRIORITIES")
    SI_OFF_LIMITS=$(_trim_blank_lines "$SI_OFF_LIMITS")
    SI_CONTEXT=$(_trim_blank_lines "$SI_CONTEXT")

    return 0
}

# Internal: save section text to the appropriate variable
_save_si_section() {
    local heading="${1:-}"
    local text="${2:-}"

    case "${heading,,}" in
        feedback)    SI_FEEDBACK="$text" ;;
        priorities)  SI_PRIORITIES="$text" ;;
        off-limits)  SI_OFF_LIMITS="$text" ;;
        context)     SI_CONTEXT="$text" ;;
    esac
}

# --- Extract priority+hypothesis pre-commitment pairs (decision 012 pillar 3) ---
# Parses SI_PRIORITIES (or $1 if given) looking for:
#
#     - <priority text>
#       - hypothesis: <hypothesis text>
#         [optional continuation lines indented further]
#
# Emits a JSON array of {"priority": "...", "hypothesis": "..."} objects to
# stdout. Only top-level bullets with an attached `hypothesis:` sub-bullet are
# emitted; free-form prose and bullets without hypothesis attachments are
# skipped here (they remain visible to the planner through the unmodified
# SI_PRIORITIES injection).
#
# Why a separate channel: the planner currently sees SI_PRIORITIES as a
# free-form blob. Pillar 3 adds a structured side-channel so user-attached
# hypotheses can be inherited verbatim instead of being paraphrased into new
# planner-authored ones.
#
# Args: $1 = priorities text (defaults to $SI_PRIORITIES)
# Stdout: JSON array (empty array if no pairs found)
parse_si_priority_hypotheses() {
    local priorities_text="${1:-${SI_PRIORITIES:-}}"
    if [ -z "$priorities_text" ]; then
        echo "[]"
        return 0
    fi

    # Walk the priorities text with a small state machine. We emit
    # priority<TAB>hypothesis lines from awk and let jq build the JSON so
    # quoting/escaping stays correct without hand-rolling it in awk.
    local pairs
    pairs=$(awk '
        function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
        function flush() {
            if (priority != "" && hypothesis != "") {
                printf "%s\t%s\n", priority, hypothesis
            }
            priority = ""; hypothesis = ""; in_hyp = 0
        }
        # Top-level bullet (no leading whitespace): new priority
        /^[-*][ \t]+/ {
            flush()
            line = $0
            sub(/^[-*][ \t]+/, "", line)
            priority = trim(line)
            next
        }
        # Indented "- hypothesis:" sub-bullet under the current priority
        /^[ \t]+[-*][ \t]+[Hh]ypothesis:/ {
            if (priority == "") next
            line = $0
            sub(/^[ \t]+[-*][ \t]+[Hh]ypothesis:[ \t]*/, "", line)
            hypothesis = trim(line)
            in_hyp = 1
            next
        }
        # Continuation of hypothesis: indented but not a new bullet
        in_hyp && /^[ \t]+[^- *\t]/ {
            line = trim($0)
            if (line != "") hypothesis = hypothesis " " line
            next
        }
        # Blank line ends a hypothesis continuation but keeps the priority open
        # for another sub-bullet (none defined yet — placeholder for future
        # fields like "owner:" or "deadline:").
        /^[ \t]*$/ { in_hyp = 0 }
        END { flush() }
    ' <<< "$priorities_text")

    if [ -z "$pairs" ]; then
        echo "[]"
        return 0
    fi

    printf '%s\n' "$pairs" | jq -R -s '
        split("\n") | map(select(length > 0)) |
        map(split("\t")) |
        map({priority: .[0], hypothesis: .[1]})
    '
}

# --- New-cycle bootstrap: prepend recent-rejections HTML comment block ---
# Reads round-<N>-report.json files in the working dir, collects rejected
# tasks from the 3 most recent rounds, and prepends a <!-- Recent rejections
# (last 3 rounds): ... --> block at the top of si-input.md. Replaces any
# prior such block so the function is idempotent.
#
# The block lives BEFORE any "## " section heading, so parse_si_input's
# state machine treats it as preamble and discards it — user-editable
# sections (Feedback / Priorities / Off-limits / Context) are untouched.
#
# Args:
#   $1 = path to si-input.md
#   $2 = working dir containing round-<N>-report.json files
# Returns:
#   0 always (no-op if no rejections found)
prepend_si_input_rejected_history() {
    local input_file="${1:-}"
    local working_dir="${2:-}"

    if [[ -z "$input_file" || -z "$working_dir" || ! -d "$working_dir" ]]; then
        return 0
    fi

    # Collect the 3 most recent round numbers that have report files.
    local recent_rounds
    recent_rounds=$(
        for report in "$working_dir"/round-*-report.json; do
            [ -f "$report" ] || continue
            local base="${report##*/}"
            base="${base#round-}"
            base="${base%-report.json}"
            # Skip if not a positive integer.
            [[ "$base" =~ ^[0-9]+$ ]] || continue
            echo "$base"
        done | sort -n | tail -3
    )

    if [ -z "$recent_rounds" ]; then
        return 0
    fi

    # Build "round<TAB>task_id<TAB>first-line-of-reason" rows for rejected
    # tasks. Task IDs within a round come out in jq's iteration order; rounds
    # come out oldest-first across the recent_rounds list.
    local rows=""
    local round
    while IFS= read -r round; do
        [ -n "$round" ] || continue
        local report="$working_dir/round-${round}-report.json"
        [ -f "$report" ] || continue
        local round_rows
        round_rows=$(jq -r --arg round "$round" '
            (.validation // {}) | to_entries[] |
            select(.value.verdict == "rejected") |
            .key as $tid |
            ((.value.verdict_detail.reject_reason // "") | split("\n")[0]) as $reason |
            "\($round)\t\($tid)\t\($reason)"
        ' "$report" 2>/dev/null) || round_rows=""
        if [ -n "$round_rows" ]; then
            rows="${rows}${round_rows}"$'\n'
        fi
    done <<< "$recent_rounds"

    rows=$(printf '%s' "$rows" | grep -v '^$' || true)
    if [ -z "$rows" ]; then
        return 0
    fi

    # Compose the comment block.
    local block
    block="<!-- Recent rejections (last 3 rounds):"$'\n'
    local line round_n tid reason
    while IFS=$'\t' read -r round_n tid reason; do
        [ -n "$round_n" ] || continue
        line="  Round ${round_n}: ${tid}"
        if [ -n "$reason" ]; then
            line="${line} — ${reason}"
        fi
        block="${block}${line}"$'\n'
    done <<< "$rows"
    block="${block}-->"$'\n'

    # Write the new block to a temp file, then append the existing file's
    # content (minus any prior "Recent rejections" block at its top).
    local tmpfile
    tmpfile=$(mktemp "${input_file}.XXXXXX")
    printf '%s' "$block" > "$tmpfile"

    if [ -f "$input_file" ]; then
        # If the first line starts a prior block, skip up to and including
        # the line that closes it, plus one optional blank separator.
        local first_line=""
        IFS= read -r first_line < "$input_file" || true
        if [[ "$first_line" == "<!-- Recent rejections"* ]]; then
            awk '
                BEGIN { stripped = 0; skip_blank = 0 }
                !stripped && /^-->$/ { stripped = 1; skip_blank = 1; next }
                !stripped { next }
                skip_blank { skip_blank = 0; if ($0 == "") next }
                { print }
            ' "$input_file" >> "$tmpfile"
        else
            cat "$input_file" >> "$tmpfile"
        fi
    fi

    mv "$tmpfile" "$input_file"

    return 0
}

# Internal: trim leading and trailing blank lines
_trim_blank_lines() {
    local text="$1"
    # Remove leading blank lines
    text=$(echo "$text" | sed '/./,$!d')
    # Remove trailing blank lines
    text=$(echo "$text" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')
    echo "$text"
}
