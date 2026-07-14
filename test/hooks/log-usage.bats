#!/usr/bin/env bats
# @category slow
# Tests for the PreToolUse usage-logging hook (~/.claude/hooks/log-usage.sh)
#
# Central use cases:
#   1. Skill invocations are logged with name, args, project, and branch
#   2. Workflow file reads are logged with extracted workflow name
#   3. Non-workflow reads are silently ignored
#   4. Unrecognized tools are silently ignored
#   5. Output is valid JSONL with the expected schema
#   6. The hook never blocks tool execution (always exits 0, no stdout)
#   7. The hook survives malformed input and missing directories

# Exercise the repo's hook, not the deployed copy under ~/.claude: the repo is
# the source of truth (the deployed hook is a symlink back to it), so this keeps
# the suite hermetic — it passes without the config having been installed.
HOOK="${LOG_USAGE_HOOK:-$BATS_TEST_DIRNAME/../../hooks/log-usage.sh}"

setup() {
  TEST_LOG=$(mktemp)
  export USAGE_LOG_FILE="$TEST_LOG"
}

teardown() {
  rm -f "$TEST_LOG"
}

# --- Helpers ---

skill_input() {
  local skill="$1" args="${2:-}"
  if [ -n "$args" ]; then
    printf '{"tool_name":"Skill","tool_input":{"skill":"%s","args":"%s"}}' "$skill" "$args"
  else
    printf '{"tool_name":"Skill","tool_input":{"skill":"%s"}}' "$skill"
  fi
}

read_input() {
  printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$1"
}

agent_input() {
  # Build Agent tool JSON with a prompt containing skill frontmatter
  local prompt="$1"
  # Use jq to safely encode the prompt string (handles newlines, quotes)
  jq -n -c --arg prompt "$prompt" '{"tool_name":"Agent","tool_input":{"prompt":$prompt,"description":"run critique","subagent_type":"general-purpose"}}'
}

# --- Skill logging ---

@test "skill invocation is logged with all fields" {
  skill_input "draft-review" "--verbose" | bash "$HOOK"

  [ -s "$TEST_LOG" ]
  line=$(head -1 "$TEST_LOG")

  [ "$(echo "$line" | jq -r '.event')" = "skill" ]
  [ "$(echo "$line" | jq -r '.name')" = "draft-review" ]
  [ "$(echo "$line" | jq -r '.args')" = "--verbose" ]
  echo "$line" | jq -r '.ts' | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
  [ -n "$(echo "$line" | jq -r '.project')" ]
  [ -n "$(echo "$line" | jq -r '.branch')" ]
}

@test "skill with no args omits args field" {
  skill_input "fact-check" | bash "$HOOK"

  line=$(head -1 "$TEST_LOG")
  [ "$(echo "$line" | jq -r '.name')" = "fact-check" ]
  [ "$(echo "$line" | jq 'has("args")')" = "false" ]
}

@test "skill with empty name does not log" {
  skill_input "" | bash "$HOOK"
  [ ! -s "$TEST_LOG" ]
}

@test "skill with missing skill field does not log" {
  echo '{"tool_name":"Skill","tool_input":{}}' | bash "$HOOK"
  [ ! -s "$TEST_LOG" ]
}

# --- Workflow logging ---

@test "reading a workflow file is logged" {
  read_input "/home/user/.claude/workflows/research-plan-implement.md" | bash "$HOOK"

  [ -s "$TEST_LOG" ]
  line=$(head -1 "$TEST_LOG")

  [ "$(echo "$line" | jq -r '.event')" = "workflow" ]
  [ "$(echo "$line" | jq -r '.name')" = "research-plan-implement" ]
  [ "$(echo "$line" | jq 'has("args")')" = "false" ]
}

@test "workflow name is extracted from basename without .md" {
  read_input "/any/path/workflows/divergent-design.md" | bash "$HOOK"
  [ "$(head -1 "$TEST_LOG" | jq -r '.name')" = "divergent-design" ]
}

@test "project-local workflow files are also logged" {
  read_input "/home/user/my-project/workflows/spike.md" | bash "$HOOK"
  [ "$(head -1 "$TEST_LOG" | jq -r '.name')" = "spike" ]
}

# --- Agent skill dispatch logging ---

@test "agent with skill frontmatter in prompt is logged as agent_skill" {
  prompt="$(printf '%s\n' '---' 'name: cowen-critique' 'description: critique' '---' '' 'Review this draft...')"
  agent_input "$prompt" | bash "$HOOK"

  [ -s "$TEST_LOG" ]
  line=$(head -1 "$TEST_LOG")

  [ "$(echo "$line" | jq -r '.event')" = "agent_skill" ]
  [ "$(echo "$line" | jq -r '.name')" = "cowen-critique" ]
}

@test "agent with no skill frontmatter logs as agent with subagent_type" {
  agent_input "Just do some research on this topic" | bash "$HOOK"

  [ -s "$TEST_LOG" ]
  line=$(head -1 "$TEST_LOG")

  [ "$(echo "$line" | jq -r '.event')" = "agent" ]
  [ "$(echo "$line" | jq -r '.name')" = "general-purpose" ]
}

@test "agent with frontmatter but no name field falls back to agent log" {
  prompt="$(printf '%s\n' '---' 'description: something' '---' '' 'content')"
  agent_input "$prompt" | bash "$HOOK"

  [ -s "$TEST_LOG" ]
  line=$(head -1 "$TEST_LOG")

  [ "$(echo "$line" | jq -r '.event')" = "agent" ]
  [ "$(echo "$line" | jq -r '.name')" = "general-purpose" ]
}

@test "agent extracts first frontmatter name only" {
  prompt="$(printf '%s\n' '---' 'name: fact-check' 'description: checker' '---' '' 'Draft text with ---' 'name: not-this' '---')"
  agent_input "$prompt" | bash "$HOOK"

  [ -s "$TEST_LOG" ]
  [ "$(head -1 "$TEST_LOG" | jq -r '.name')" = "fact-check" ]
}

# --- Non-matching reads are ignored ---

@test "reading a non-workflow file does not log" {
  read_input "/home/user/project/src/main.ts" | bash "$HOOK"
  [ ! -s "$TEST_LOG" ]
}

@test "reading a skill file is logged with extracted skill name" {
  read_input "/home/user/project/skills/draft-review.md" | bash "$HOOK"

  [ -s "$TEST_LOG" ]
  line=$(head -1 "$TEST_LOG")

  [ "$(echo "$line" | jq -r '.event')" = "skill" ]
  [ "$(echo "$line" | jq -r '.name')" = "draft-review" ]
}

@test "reading a file with 'workflows' in name but not in a workflows dir does not log" {
  read_input "/home/user/project/docs/workflows-overview.md" | bash "$HOOK"
  [ ! -s "$TEST_LOG" ]
}

# --- Unrecognized tools are ignored ---

@test "unrecognized tool input does not log" {
  echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' | bash "$HOOK"
  [ ! -s "$TEST_LOG" ]
}

# --- Output format ---

@test "each logged line is valid JSON" {
  skill_input "a" | bash "$HOOK"
  read_input "/x/workflows/b.md" | bash "$HOOK"
  skill_input "c" "d" | bash "$HOOK"

  line_count=$(wc -l < "$TEST_LOG")
  [ "$line_count" -eq 3 ]

  while IFS= read -r line; do
    echo "$line" | jq empty
  done < "$TEST_LOG"
}

# --- Hook never blocks execution ---

@test "hook produces no stdout (never interferes with tool permission)" {
  output=$(skill_input "test" | bash "$HOOK")
  [ -z "$output" ]

  output=$(read_input "/x/workflows/y.md" | bash "$HOOK")
  [ -z "$output" ]
}

# --- Error resilience ---

@test "hook exits 0 on malformed JSON input" {
  run bash "$HOOK" <<< "not json at all"
  [ "$status" -eq 0 ]
  [ ! -s "$TEST_LOG" ]
}

@test "hook exits 0 on empty input" {
  run bash "$HOOK" <<< ""
  [ "$status" -eq 0 ]
  [ ! -s "$TEST_LOG" ]
}

@test "hook creates log directory if missing" {
  NESTED_LOG=$(mktemp -d)/subdir/usage.jsonl
  export USAGE_LOG_FILE="$NESTED_LOG"

  skill_input "test" | bash "$HOOK"
  [ -s "$NESTED_LOG" ]

  rm -rf "$(dirname "$(dirname "$NESTED_LOG")")"
}

# --- Multiple events append correctly ---

@test "multiple invocations append to the same log file" {
  skill_input "alpha" | bash "$HOOK"
  skill_input "beta" | bash "$HOOK"
  read_input "/w/workflows/gamma.md" | bash "$HOOK"

  line_count=$(wc -l < "$TEST_LOG")
  [ "$line_count" -eq 3 ]

  [ "$(sed -n '1p' "$TEST_LOG" | jq -r '.name')" = "alpha" ]
  [ "$(sed -n '2p' "$TEST_LOG" | jq -r '.name')" = "beta" ]
  [ "$(sed -n '3p' "$TEST_LOG" | jq -r '.name')" = "gamma" ]
}

# --- `via` field distinguishes invocation vs consultation (decision 012 pillar 4) ---

@test "skill tool invocation tags via=skill_tool" {
  skill_input "draft-review" | bash "$HOOK"
  [ "$(head -1 "$TEST_LOG" | jq -r '.via')" = "skill_tool" ]
}

@test "reading a SKILL.md tags via=file_read" {
  read_input "/repo/skills/draft-review/SKILL.md" | bash "$HOOK"
  [ "$(head -1 "$TEST_LOG" | jq -r '.via')" = "file_read" ]
}

@test "reading a workflow file tags via=file_read" {
  read_input "/repo/workflows/rpi.md" | bash "$HOOK"
  [ "$(head -1 "$TEST_LOG" | jq -r '.via')" = "file_read" ]
}

@test "agent dispatch tags via=agent_dispatch" {
  agent_input "no frontmatter here" | bash "$HOOK"
  [ "$(head -1 "$TEST_LOG" | jq -r '.via')" = "agent_dispatch" ]
}

@test "via field absent for legacy callers writing without it" {
  # If something writes via the old 3-arg log_event signature, the entry must
  # still be valid JSON with no `via` key (graceful degradation).
  # Simulate by directly calling jq the same way the hook does internally.
  jq -n -c \
    --arg ts "2026-01-01T00:00:00Z" --arg event "skill" --arg name "x" \
    --arg args "" --arg via "" --arg project "p" --arg branch "b" \
    '{ts:$ts,event:$event,name:$name,project:$project,branch:$branch}
     | (if $args != "" then . + {args:$args} else . end)
     | (if $via  != "" then . + {via:$via}  else . end)' \
    > "$TEST_LOG"
  [ "$(jq 'has("via")' "$TEST_LOG")" = "false" ]
  [ "$(jq 'has("args")' "$TEST_LOG")" = "false" ]
}
