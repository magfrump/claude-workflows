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

init_usage_hook pre

log_event() {
  # Usage: log_event <event> <name> [args] [via]
  # `via` distinguishes how the event was observed. Existing event types
  # ("skill", "workflow", "agent", ...) are unchanged for backward compat with
  # scripts/skill-usage-report.sh. Consumers wanting invocation-count
  # preconditions (decision 012 pillar 4) should filter on
  # `via == "skill_tool"` rather than counting raw event entries.
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

# Path-classification helpers live in scripts/lib/skill-paths.sh so the same
# rule set is shared between this hook, scripts/health-check.sh, and
# scripts/lib/si-morning-summary.sh.
# shellcheck source=../scripts/lib/skill-paths.sh
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../scripts/lib/skill-paths.sh"

case "$TOOL_NAME" in
  Skill)
    SKILL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_input.skill // ""')
    if [[ -n "$SKILL_NAME" ]]; then
      SKILL_ARGS=$(printf '%s' "$INPUT" | jq -r '.tool_input.args // ""')
      log_event "skill" "$SKILL_NAME" "$SKILL_ARGS" "skill_tool"
    fi
    ;;
  Read)
    FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""')
    # Check skills first — a path like claude-workflows/skills/x.md contains
    # both "workflows" and "skills"; the more specific match should win.
    if [[ "$FILE_PATH" == */skills/* ]]; then
      SKILL_NAME=$(extract_skill_name "$FILE_PATH")
      if [[ -n "$SKILL_NAME" ]]; then
        log_event "skill" "$SKILL_NAME" "" "file_read"
      fi
    elif [[ "$FILE_PATH" == */workflows/* ]]; then
      WORKFLOW_NAME=$(extract_workflow_name "$FILE_PATH")
      if [[ -n "$WORKFLOW_NAME" ]]; then
        log_event "workflow" "$WORKFLOW_NAME" "" "file_read"
      fi
    elif [[ "$FILE_PATH" == */commands/* ]]; then
      CMD_NAME=$(extract_command_name "$FILE_PATH")
      if [[ -n "$CMD_NAME" ]]; then
        log_event "command" "$CMD_NAME" "" "file_read"
      fi
    fi
    ;;
  Agent)
    # Detect sub-agent dispatches that include skill content (YAML frontmatter)
    AGENT_PROMPT=$(printf '%s' "$INPUT" | jq -r '.tool_input.prompt // ""')
    if [[ -n "$AGENT_PROMPT" ]]; then
      # Try extracting a skill/agent name from YAML frontmatter in the prompt
      AGENT_SKILL=$(extract_agent_name_from_prompt "$AGENT_PROMPT")
      if [[ -n "$AGENT_SKILL" ]]; then
        log_event "agent_skill" "$AGENT_SKILL" "" "agent_dispatch"
      else
        # Log agent dispatches with a subagent_type if present
        AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // ""')
        if [[ -n "$AGENT_TYPE" ]]; then
          AGENT_DESC=$(printf '%s' "$INPUT" | jq -r '.tool_input.description // ""')
          log_event "agent" "$AGENT_TYPE" "$AGENT_DESC" "agent_dispatch"
        fi
      fi
    fi
    ;;
esac

exit 0
