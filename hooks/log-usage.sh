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
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')
case "$TOOL_NAME" in
  Skill|Read|Agent) ;;  # These are logged — continue
  *) exit 0 ;;          # Everything else — skip all work
esac

LOG_FILE="${USAGE_LOG_FILE:-$HOME/.claude/logs/usage.jsonl}"
[[ -d "${LOG_FILE%/*}" ]] || mkdir -p "${LOG_FILE%/*}"

# Optional debug logging: set USAGE_LOG_DEBUG=1 to capture raw hook input
if [[ "${USAGE_LOG_DEBUG:-}" == "1" ]]; then
  DEBUG_FILE="${LOG_FILE%.jsonl}-debug.jsonl"
  printf '%s\n' "$INPUT" >> "$DEBUG_FILE"
fi

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

# Classify a file path under a /skills/ directory.
# Returns the skill name via stdout, or nothing if it's not a skill definition.
extract_skill_name() {
  local filepath="$1"
  # Get everything after the last /skills/ segment
  local after_skills="${filepath##*/skills/}"

  # Count slashes to determine depth
  local stripped="${after_skills//[^\/]/}"
  local depth=${#stripped}

  if [[ $depth -eq 0 && "$after_skills" == *.md ]]; then
    # Direct skill file: skills/fact-check.md → fact-check
    printf '%s' "${after_skills%.md}"
  elif [[ $depth -eq 1 ]]; then
    # One level deep: skills/skill-name/SKILL.md → skill-name
    local basename="${after_skills##*/}"
    if [[ "$basename" == "SKILL.md" ]]; then
      printf '%s' "${after_skills%%/*}"
    fi
    # Other files one level deep (e.g. skills/name/README.md) are skipped
  fi
  # Deeper paths (references, fixtures, etc.) are skipped
}

# Classify a file path under a /workflows/ directory.
# Returns the workflow name via stdout, or nothing if it's not a workflow definition.
extract_workflow_name() {
  local filepath="$1"
  local after_workflows="${filepath##*/workflows/}"

  # Only match direct files (no subdirectories)
  local stripped="${after_workflows//[^\/]/}"
  if [[ ${#stripped} -eq 0 && "$after_workflows" == *.md ]]; then
    printf '%s' "${after_workflows%.md}"
  fi
}

# Classify a file path under a /commands/ directory (user-defined slash commands).
extract_command_name() {
  local filepath="$1"
  local after_commands="${filepath##*/commands/}"

  local stripped="${after_commands//[^\/]/}"
  if [[ ${#stripped} -eq 0 && "$after_commands" == *.md ]]; then
    printf '%s' "${after_commands%.md}"
  fi
}

case "$TOOL_NAME" in
  Skill)
    SKILL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_input.skill // ""')
    if [[ -n "$SKILL_NAME" ]]; then
      SKILL_ARGS=$(printf '%s' "$INPUT" | jq -r '.tool_input.args // ""')
      log_event "skill" "$SKILL_NAME" "$SKILL_ARGS"
    fi
    ;;
  Read)
    FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""')
    # Check skills first — a path like claude-workflows/skills/x.md contains
    # both "workflows" and "skills"; the more specific match should win.
    if [[ "$FILE_PATH" == */skills/* ]]; then
      SKILL_NAME=$(extract_skill_name "$FILE_PATH")
      if [[ -n "$SKILL_NAME" ]]; then
        log_event "skill" "$SKILL_NAME"
      fi
    elif [[ "$FILE_PATH" == */workflows/* ]]; then
      WORKFLOW_NAME=$(extract_workflow_name "$FILE_PATH")
      if [[ -n "$WORKFLOW_NAME" ]]; then
        log_event "workflow" "$WORKFLOW_NAME"
      fi
    elif [[ "$FILE_PATH" == */commands/* ]]; then
      CMD_NAME=$(extract_command_name "$FILE_PATH")
      if [[ -n "$CMD_NAME" ]]; then
        log_event "command" "$CMD_NAME"
      fi
    fi
    ;;
  Agent)
    # Detect sub-agent dispatches that include skill content (YAML frontmatter)
    AGENT_PROMPT=$(printf '%s' "$INPUT" | jq -r '.tool_input.prompt // ""')
    if [[ -n "$AGENT_PROMPT" ]]; then
      # Try extracting a skill/agent name from YAML frontmatter in the prompt
      AGENT_SKILL=$(printf '%s' "$AGENT_PROMPT" \
        | sed -n '/^---$/,/^---$/{/^name: */{ s/^name: *//; p; q; }}')
      if [[ -n "$AGENT_SKILL" ]]; then
        log_event "agent_skill" "$AGENT_SKILL"
      else
        # Log agent dispatches with a subagent_type if present
        AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // ""')
        if [[ -n "$AGENT_TYPE" ]]; then
          AGENT_DESC=$(printf '%s' "$INPUT" | jq -r '.tool_input.description // ""')
          log_event "agent" "$AGENT_TYPE" "$AGENT_DESC"
        fi
      fi
    fi
    ;;
esac

exit 0
