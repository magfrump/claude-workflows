#!/usr/bin/env bash
# PostToolUse hook: logs skill/agent completion events with duration and
# (when available) token totals. Pairs with hooks/log-usage.sh which records
# the start events.
#
# Input:  JSON on stdin with tool_name, tool_input, and tool_response
# Output: nothing (passthrough — never blocks tool execution)
#
# Event types emitted (decision 012 pillar 4):
#   skill_completed — pairs with a "skill" event where via == "skill_tool"
#   agent_completed — pairs with an "agent" or "agent_skill" event
#
# Pairing: consumers match by (name, project, branch) and pick the most recent
# pre-event preceding this post-event. Duration is computed as post.ts - pre.ts
# when `duration_ms` is not supplied by the tool_response.

# Never block tool execution, even on unexpected errors
trap 'exit 0' ERR

INPUT=$(cat)

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')
case "$TOOL_NAME" in
  Skill|Agent) ;;   # Only post-events for these are useful
  *) exit 0 ;;
esac

LOG_FILE="${USAGE_LOG_FILE:-$HOME/.claude/logs/usage.jsonl}"
[[ -d "${LOG_FILE%/*}" ]] || mkdir -p "${LOG_FILE%/*}"

# Optional debug logging mirrors the pre-hook for symmetry
if [[ "${USAGE_LOG_DEBUG:-}" == "1" ]]; then
  DEBUG_FILE="${LOG_FILE%.jsonl}-post-debug.jsonl"
  printf '%s\n' "$INPUT" >> "$DEBUG_FILE"
fi

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PROJECT=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "${PWD##*/}")
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# Extract timing/token data from tool_response if present. Tool responses are
# inconsistent across Claude Code versions, so we try several likely shapes
# and emit only the fields we find. Missing fields are omitted, not zero.
extract_num_field() {
  # Usage: extract_num_field <field-name>
  # Tries .tool_response.<field>, .tool_response.usage.<field>, .tool_response.metadata.<field>
  local field="$1"
  printf '%s' "$INPUT" | jq -r --arg f "$field" '
    .tool_response // {} |
    (.[$f] // .usage[$f]? // .metadata[$f]? // empty) |
    select(type == "number") | tostring
  ' 2>/dev/null
}

DURATION_MS=$(extract_num_field "duration_ms")
TOTAL_TOKENS=$(extract_num_field "total_tokens")

log_completion() {
  # Usage: log_completion <event> <name>
  local event="$1" name="$2"
  jq -n -c \
    --arg ts "$TS" \
    --arg event "$event" \
    --arg name "$name" \
    --arg project "$PROJECT" \
    --arg branch "$BRANCH" \
    --arg duration_ms "$DURATION_MS" \
    --arg total_tokens "$TOTAL_TOKENS" \
    '{ts:$ts,event:$event,name:$name,project:$project,branch:$branch}
     | (if $duration_ms != "" then . + {duration_ms: ($duration_ms | tonumber)} else . end)
     | (if $total_tokens != "" then . + {total_tokens: ($total_tokens | tonumber)} else . end)' \
    >> "$LOG_FILE"
}

case "$TOOL_NAME" in
  Skill)
    NAME=$(printf '%s' "$INPUT" | jq -r '.tool_input.skill // ""')
    [[ -n "$NAME" ]] && log_completion "skill_completed" "$NAME"
    ;;
  Agent)
    # Mirror the pre-hook's name extraction: prefer YAML frontmatter name, fall
    # back to subagent_type. This keeps pre/post events on the same key.
    AGENT_PROMPT=$(printf '%s' "$INPUT" | jq -r '.tool_input.prompt // ""')
    NAME=""
    if [[ -n "$AGENT_PROMPT" ]]; then
      NAME=$(printf '%s' "$AGENT_PROMPT" \
        | sed -n '/^---$/,/^---$/{/^name: */{ s/^name: *//; p; q; }}')
    fi
    if [[ -z "$NAME" ]]; then
      NAME=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // ""')
    fi
    [[ -n "$NAME" ]] && log_completion "agent_completed" "$NAME"
    ;;
esac

exit 0
