#!/usr/bin/env bash
# PreToolUse hook: logs skill invocations and workflow file reads to JSONL
# Input: JSON on stdin with tool_name and tool_input
# Output: nothing (passthrough — never blocks tool execution)

# Never block tool execution, even on unexpected errors
trap 'exit 0' ERR

LOG_FILE="${USAGE_LOG_FILE:-$HOME/.claude/logs/usage.jsonl}"
mkdir -p "$(dirname "$LOG_FILE")"

# Single jq call to extract all fields — one per line to avoid delimiter issues
PARSED=$(jq -r '[.tool_name, .tool_input.skill, .tool_input.args, .tool_input.file_path] | map(. // "") | .[]')
TOOL_NAME=$(sed -n '1p' <<< "$PARSED")
SKILL_NAME=$(sed -n '2p' <<< "$PARSED")
SKILL_ARGS=$(sed -n '3p' <<< "$PARSED")
FILE_PATH=$(sed -n '4p' <<< "$PARSED")

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PROJECT="${PWD##*/}"
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

case "$TOOL_NAME" in
  Skill)
    if [ -n "$SKILL_NAME" ]; then
      jq -n -c \
        --arg ts "$TS" \
        --arg event "skill" \
        --arg name "$SKILL_NAME" \
        --arg args "$SKILL_ARGS" \
        --arg project "$PROJECT" \
        --arg branch "$BRANCH" \
        '{ts:$ts,event:$event,name:$name,args:$args,project:$project,branch:$branch}' \
        >> "$LOG_FILE"
    fi
    ;;
  Read)
    if [[ "$FILE_PATH" == */workflows/*.md ]]; then
      WORKFLOW_NAME="${FILE_PATH##*/}"
      WORKFLOW_NAME="${WORKFLOW_NAME%.md}"
      jq -n -c \
        --arg ts "$TS" \
        --arg event "workflow" \
        --arg name "$WORKFLOW_NAME" \
        --arg project "$PROJECT" \
        --arg branch "$BRANCH" \
        '{ts:$ts,event:$event,name:$name,project:$project,branch:$branch}' \
        >> "$LOG_FILE"
    fi
    ;;
esac

exit 0
