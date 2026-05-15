#!/usr/bin/env bash
# PreToolUse hook: logs skill invocations, workflow file reads, and
# sub-agent skill dispatches to JSONL.
# Input: JSON on stdin with tool_name and tool_input
# Output: nothing (passthrough — never blocks tool execution)

# Shared preamble + agent-name helper. Sets up trap, reads stdin into INPUT,
# extracts TOOL_NAME (exits 0 for tools that aren't Skill/Read/Agent), and
# populates TS / PROJECT / BRANCH / LOG_FILE.
# shellcheck source=lib/usage-common.sh
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/usage-common.sh"
# Path-classification helpers shared with health-check and morning-summary.
# shellcheck source=../scripts/lib/skill-paths.sh
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../scripts/lib/skill-paths.sh"

init_usage_hook pre

# Single-pass jq fan-out per tool. Fields are joined with the ASCII Unit
# Separator (\x1f) so `read` does not coalesce consecutive empty fields the
# way IFS=$'\t' would. The prompt field is base64-encoded because Agent
# prompts contain embedded newlines that `read` would otherwise truncate.

log_event() {
  # Usage: log_event <event> <name> [args] [via]
  # `via` distinguishes how the event was observed. Event types are unchanged
  # for backward compat with scripts/skill-usage-report.sh. Filter on
  # `via == "skill_tool"` to count real Skill-tool invocations.
  #   skill_tool      — Skill tool invocation (real use)
  #   file_read       — Read of SKILL.md / workflow / command (consultation)
  #   agent_dispatch  — Agent tool dispatch
  local event="$1" name="$2" args="${3:-}" via="${4:-}"
  jq -n -c \
    --arg ts "$TS" \
    --arg event "$event" \
    --arg name "$name" \
    --arg args "$args" \
    --arg via "$via" \
    --arg project "$PROJECT" \
    --arg branch "$BRANCH" \
    '{ts:$ts,event:$event,name:$name,project:$project,branch:$branch}
     | (if $args != "" then . + {args:$args} else . end)
     | (if $via  != "" then . + {via:$via}  else . end)' \
    >> "$LOG_FILE"
}

case "$TOOL_NAME" in
  Skill)
    IFS=$'\x1f' read -r SKILL_NAME SKILL_ARGS < <(printf '%s' "$INPUT" \
      | jq -r '[.tool_input.skill // "", .tool_input.args // ""] | join("")')
    if [[ -n "$SKILL_NAME" ]]; then
      log_event "skill" "$SKILL_NAME" "$SKILL_ARGS" "skill_tool"
    fi
    ;;
  Read)
    FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""')
    # Check skills first — a path like claude-workflows/skills/x.md contains
    # both "workflows" and "skills"; the more specific match wins.
    if [[ "$FILE_PATH" == */skills/* ]]; then
      SKILL_NAME=$(extract_skill_name "$FILE_PATH")
      [[ -n "$SKILL_NAME" ]] && log_event "skill" "$SKILL_NAME" "" "file_read"
    elif [[ "$FILE_PATH" == */workflows/* ]]; then
      WORKFLOW_NAME=$(extract_workflow_name "$FILE_PATH")
      [[ -n "$WORKFLOW_NAME" ]] && log_event "workflow" "$WORKFLOW_NAME" "" "file_read"
    elif [[ "$FILE_PATH" == */commands/* ]]; then
      CMD_NAME=$(extract_command_name "$FILE_PATH")
      [[ -n "$CMD_NAME" ]] && log_event "command" "$CMD_NAME" "" "file_read"
    fi
    ;;
  Agent)
    IFS=$'\x1f' read -r AGENT_PROMPT_B64 AGENT_TYPE AGENT_DESC < <(printf '%s' "$INPUT" \
      | jq -r '[(.tool_input.prompt // "" | @base64),
                (.tool_input.subagent_type // ""),
                (.tool_input.description // "")] | join("")')
    AGENT_PROMPT=$(printf '%s' "$AGENT_PROMPT_B64" | base64 -d 2>/dev/null)
    if [[ -n "$AGENT_PROMPT" ]]; then
      AGENT_SKILL=$(extract_agent_name_from_prompt "$AGENT_PROMPT")
      if [[ -n "$AGENT_SKILL" ]]; then
        log_event "agent_skill" "$AGENT_SKILL" "" "agent_dispatch"
      elif [[ -n "$AGENT_TYPE" ]]; then
        log_event "agent" "$AGENT_TYPE" "$AGENT_DESC" "agent_dispatch"
      fi
    fi
    ;;
esac

exit 0
