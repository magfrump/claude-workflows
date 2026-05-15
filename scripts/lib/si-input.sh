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

# Internal: trim leading and trailing blank lines
_trim_blank_lines() {
    local text="$1"
    # Remove leading blank lines
    text=$(echo "$text" | sed '/./,$!d')
    # Remove trailing blank lines
    text=$(echo "$text" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')
    echo "$text"
}
