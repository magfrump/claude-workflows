#!/bin/bash
# Pre-run input parser for the self-improvement loop.
# Reads a structured markdown file with user feedback, priorities,
# off-limits topics, and context for injection into the DD prompt.
#
# Sourced by scripts/self-improvement.sh — do not execute directly.
#
# Functions:
#   parse_si_input — Parse si-input.md and export section variables
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

# Internal: trim leading and trailing blank lines
_trim_blank_lines() {
    local text="$1"
    # Remove leading blank lines
    text=$(echo "$text" | sed '/./,$!d')
    # Remove trailing blank lines
    text=$(echo "$text" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')
    echo "$text"
}
