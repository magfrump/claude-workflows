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

# Shared preamble + agent-name helper. Same setup as log-usage.sh; sets
# trap, reads INPUT, gates TOOL_NAME, and populates TS/PROJECT/BRANCH/LOG_FILE.
# shellcheck source=lib/usage-common.sh
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/usage-common.sh"

init_usage_hook post

log_completion() {
  # Usage: log_completion <event> <name> <duration_ms> <total_tokens>
  # Empty numeric strings are omitted from the JSON record.
  local event="$1" name="$2" duration_ms="$3" total_tokens="$4"
  jq -n -c \
    --arg ts "$TS" \
    --arg event "$event" \
    --arg name "$name" \
    --arg project "$PROJECT" \
    --arg branch "$BRANCH" \
    --arg duration_ms "$duration_ms" \
    --arg total_tokens "$total_tokens" \
    '{ts:$ts,event:$event,name:$name,project:$project,branch:$branch}
     | (if $duration_ms != "" then . + {duration_ms: ($duration_ms | tonumber)} else . end)
     | (if $total_tokens != "" then . + {total_tokens: ($total_tokens | tonumber)} else . end)' \
    >> "$LOG_FILE"
}

# Pick a numeric field from tool_response from any of three likely locations.
# Used inside the single-pass jq below.
PICK_NUM='def pick(f): (.tool_response // {}) | (.[f] // .usage[f]? // .metadata[f]? // null) | if type == "number" then tostring else "" end;'

case "$TOOL_NAME" in
  Skill)
    # One jq pass extracts: skill name, duration_ms, total_tokens. Joined
    # with ASCII Unit Separator so empty fields are preserved by `read`.
    IFS=$'\x1f' read -r NAME DURATION_MS TOTAL_TOKENS < <(printf '%s' "$INPUT" \
      | jq -r "$PICK_NUM"' [(.tool_input.skill // ""), pick("duration_ms"), pick("total_tokens")] | join("")')
    [[ -n "$NAME" ]] && log_completion "skill_completed" "$NAME" "$DURATION_MS" "$TOTAL_TOKENS"
    ;;
  Agent)
    # One jq pass extracts: prompt (base64), subagent_type, duration_ms,
    # total_tokens. Name resolution mirrors the pre-hook: prefer the YAML
    # `name:` from the prompt, fall back to subagent_type.
    IFS=$'\x1f' read -r AGENT_PROMPT_B64 AGENT_TYPE DURATION_MS TOTAL_TOKENS < <(printf '%s' "$INPUT" \
      | jq -r "$PICK_NUM"' [(.tool_input.prompt // "" | @base64),
                            (.tool_input.subagent_type // ""),
                            pick("duration_ms"),
                            pick("total_tokens")] | join("")')
    AGENT_PROMPT=$(printf '%s' "$AGENT_PROMPT_B64" | base64 -d 2>/dev/null)
    NAME=$(extract_agent_name_from_prompt "$AGENT_PROMPT")
    [[ -z "$NAME" ]] && NAME="$AGENT_TYPE"
    [[ -n "$NAME" ]] && log_completion "agent_completed" "$NAME" "$DURATION_MS" "$TOTAL_TOKENS"
    ;;
esac

exit 0
