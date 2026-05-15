#!/bin/bash
# Shared preamble for hooks/log-usage.sh and hooks/log-usage-post.sh.
#
# Hooks run in a fresh shell on every tool call, so this file must be cheap
# to source: no top-level work besides function definitions.
#
# After sourcing, callers call `init_usage_hook <pre|post>` early on, which:
#   - Installs `trap exit 0 ERR` so the hook never blocks tool execution
#   - Reads stdin into INPUT
#   - Extracts TOOL_NAME and exits 0 if the tool is not interesting
#     (allowed tools differ per hook variant — see below)
#   - Sets TS, PROJECT, BRANCH, LOG_FILE as globals for the caller
#   - Honours USAGE_LOG_DEBUG=1 by appending raw input to a debug log

# Read stdin, set INPUT, set TOOL_NAME, gate on allowed tool names.
# Args: $1 = "pre" or "post" — selects which tools are logged.
#   pre  → Skill, Read, Agent  (these are the events the PreToolUse hook logs)
#   post → Skill, Agent        (Read has no useful completion event)
# Exits 0 (the surrounding hook script exits via `exit 0`) when the tool is
# not interesting. Otherwise returns control to the caller with TOOL_NAME set.
init_usage_hook() {
    local variant="${1:-pre}"

    trap 'exit 0' ERR
    INPUT=$(cat)

    TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')
    case "$variant:$TOOL_NAME" in
        pre:Skill|pre:Read|pre:Agent) ;;
        post:Skill|post:Agent) ;;
        *) exit 0 ;;
    esac

    LOG_FILE="${USAGE_LOG_FILE:-$HOME/.claude/logs/usage.jsonl}"
    [[ -d "${LOG_FILE%/*}" ]] || mkdir -p "${LOG_FILE%/*}"

    # Debug-log block is symmetric with itself: pre-hook writes *-debug.jsonl,
    # post-hook writes *-post-debug.jsonl. Variant decides the suffix.
    if [[ "${USAGE_LOG_DEBUG:-}" == "1" ]]; then
        local debug_suffix
        if [[ "$variant" == "post" ]]; then
            debug_suffix="-post-debug.jsonl"
        else
            debug_suffix="-debug.jsonl"
        fi
        local debug_file="${LOG_FILE%.jsonl}${debug_suffix}"
        printf '%s\n' "$INPUT" >> "$debug_file"
    fi

    # TS/PROJECT/BRANCH are globals consumed by the caller's log_event/
    # log_completion helpers. shellcheck can't see across source boundaries.
    # shellcheck disable=SC2034
    TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    # shellcheck disable=SC2034
    PROJECT=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "${PWD##*/}")
    # shellcheck disable=SC2034
    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
}

# Extract the first `name:` value from a YAML frontmatter block at the top
# of an Agent prompt. Returns empty if no frontmatter is present.
# Args: $1 = prompt string
extract_agent_name_from_prompt() {
    local prompt="$1"
    [ -z "$prompt" ] && return 0
    printf '%s' "$prompt" \
        | sed -n '/^---$/,/^---$/{/^name: */{ s/^name: *//; p; q; }}'
}
