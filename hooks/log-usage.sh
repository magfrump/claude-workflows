#!/usr/bin/env bash
# PreToolUse hook: logs skill invocations, workflow file reads, and
# sub-agent skill dispatches to JSONL.
# Input: JSON on stdin with tool_name and tool_input
# Output: nothing (passthrough — never blocks tool execution)

# Never block tool execution, even on unexpected errors
trap 'exit 0' ERR

# Read stdin once, reuse for multiple extractions
INPUT=$(cat)

# Extract tool_name first for early exit — most tools are not logged
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
case "$TOOL_NAME" in
  Skill|Read|Agent) ;;  # These are logged — continue
  *) exit 0 ;;          # Everything else — skip all work
esac

LOG_FILE="${USAGE_LOG_FILE:-$HOME/.claude/logs/usage.jsonl}"
[[ -d "${LOG_FILE%/*}" ]] || mkdir -p "${LOG_FILE%/*}"

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Use git toplevel basename so worktrees resolve to the same project name
PROJECT=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "${PWD##*/}")
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

log_event() {
  # Usage: log_event <event> <name> [args]
  local event="$1" name="$2" args="${3:-}"
  jq -n -c \
    --arg ts "$TS" \
    --arg event "$event" \
    --arg name "$name" \
    --arg args "$args" \
    --arg project "$PROJECT" \
    --arg branch "$BRANCH" \
    'if $args == "" then {ts:$ts,event:$event,name:$name,project:$project,branch:$branch}
     else {ts:$ts,event:$event,name:$name,args:$args,project:$project,branch:$branch} end' \
    >> "$LOG_FILE"
}

case "$TOOL_NAME" in
  Skill)
    SKILL_NAME=$(echo "$INPUT" | jq -r '.tool_input.skill // ""')
    if [ -n "$SKILL_NAME" ]; then
      SKILL_ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // ""')
      log_event "skill" "$SKILL_NAME" "$SKILL_ARGS"
    fi
    ;;
  Read)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
    if [[ "$FILE_PATH" == */workflows/*.md ]]; then
      WORKFLOW_NAME="${FILE_PATH##*/}"
      WORKFLOW_NAME="${WORKFLOW_NAME%.md}"
      log_event "workflow" "$WORKFLOW_NAME"
    fi
    ;;
  Agent)
    # Detect sub-agent skill dispatches by looking for YAML frontmatter
    # with a name: field in the agent prompt (skill content pasted in)
    AGENT_SKILL=$(echo "$INPUT" | jq -r '.tool_input.prompt // ""' \
      | sed -n '/^---$/,/^---$/{/^name: */{ s/^name: *//; p; q; }}')
    if [ -n "$AGENT_SKILL" ]; then
      log_event "skill" "$AGENT_SKILL"
    fi
    ;;
esac

exit 0
