#!/usr/bin/env bats
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

HOOK="$HOME/.claude/hooks/log-usage.sh"

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

@test "skill with no args logs empty args string" {
  skill_input "fact-check" | bash "$HOOK"

  line=$(head -1 "$TEST_LOG")
  [ "$(echo "$line" | jq -r '.name')" = "fact-check" ]
  [ "$(echo "$line" | jq -r '.args')" = "" ]
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

# --- Non-matching reads are ignored ---

@test "reading a non-workflow file does not log" {
  read_input "/home/user/project/src/main.ts" | bash "$HOOK"
  [ ! -s "$TEST_LOG" ]
}

@test "reading a skill file does not log" {
  read_input "/home/user/project/skills/draft-review.md" | bash "$HOOK"
  [ ! -s "$TEST_LOG" ]
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
