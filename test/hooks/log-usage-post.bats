#!/usr/bin/env bats
# @category slow
# Tests for the PostToolUse usage-logging hook (hooks/log-usage-post.sh)
#
# Central use cases:
#   1. Skill completion emits skill_completed with name + timestamp
#   2. Duration and token totals are captured when tool_response supplies them
#   3. Missing duration/tokens degrade gracefully (fields omitted, not zero)
#   4. Agent completion mirrors the pre-hook's name extraction
#   5. Unrecognized tools are silently ignored (Bash, Read, others)
#   6. Output is valid JSONL; hook never blocks tool execution

# Repo-relative, not the deployed ~/.claude copy — see the note in
# log-usage.bats. Keeps the suite hermetic.
HOOK="${LOG_USAGE_POST_HOOK:-$BATS_TEST_DIRNAME/../../hooks/log-usage-post.sh}"

setup() {
  TEST_LOG=$(mktemp)
  export USAGE_LOG_FILE="$TEST_LOG"
}

teardown() {
  rm -f "$TEST_LOG"
}

# --- Helpers ---

skill_post() {
  local skill="$1" duration_ms="${2:-}" total_tokens="${3:-}"
  jq -n -c \
    --arg s "$skill" --arg d "$duration_ms" --arg t "$total_tokens" \
    '{tool_name:"Skill", tool_input:{skill:$s},
      tool_response: (
        ({}
         | if $d != "" then . + {duration_ms: ($d|tonumber)} else . end
         | if $t != "" then . + {total_tokens: ($t|tonumber)} else . end)
      )}'
}

agent_post_subagent() {
  local subagent_type="$1" duration_ms="${2:-}"
  jq -n -c --arg st "$subagent_type" --arg d "$duration_ms" \
    '{tool_name:"Agent", tool_input:{prompt:"plain text",subagent_type:$st},
      tool_response: (if $d != "" then {duration_ms:($d|tonumber)} else {} end)}'
}

# --- Skill completion ---

@test "skill completion emits skill_completed event" {
  skill_post "draft-review" "1500" "8000" | bash "$HOOK"
  [ -s "$TEST_LOG" ]
  line=$(head -1 "$TEST_LOG")
  [ "$(echo "$line" | jq -r '.event')" = "skill_completed" ]
  [ "$(echo "$line" | jq -r '.name')" = "draft-review" ]
}

@test "skill completion captures duration_ms when supplied" {
  skill_post "fact-check" "2345" | bash "$HOOK"
  [ "$(head -1 "$TEST_LOG" | jq -r '.duration_ms')" = "2345" ]
}

@test "skill completion captures total_tokens when supplied" {
  skill_post "fact-check" "" "9999" | bash "$HOOK"
  [ "$(head -1 "$TEST_LOG" | jq -r '.total_tokens')" = "9999" ]
}

@test "missing duration and tokens are omitted, not zeroed" {
  skill_post "fact-check" | bash "$HOOK"
  line=$(head -1 "$TEST_LOG")
  [ "$(echo "$line" | jq 'has("duration_ms")')" = "false" ]
  [ "$(echo "$line" | jq 'has("total_tokens")')" = "false" ]
}

@test "skill completion with no skill name does not log" {
  echo '{"tool_name":"Skill","tool_input":{},"tool_response":{}}' | bash "$HOOK"
  [ ! -s "$TEST_LOG" ]
}

# --- Agent completion ---

@test "agent completion uses subagent_type when no frontmatter" {
  agent_post_subagent "general-purpose" "5000" | bash "$HOOK"
  line=$(head -1 "$TEST_LOG")
  [ "$(echo "$line" | jq -r '.event')" = "agent_completed" ]
  [ "$(echo "$line" | jq -r '.name')" = "general-purpose" ]
  [ "$(echo "$line" | jq -r '.duration_ms')" = "5000" ]
}

@test "agent completion prefers frontmatter name over subagent_type" {
  # Mirrors the pre-hook: YAML frontmatter `name:` wins
  prompt=$'---\nname: critic-agent\n---\n\nbody'
  jq -n -c --arg p "$prompt" \
    '{tool_name:"Agent",tool_input:{prompt:$p,subagent_type:"general-purpose"},
      tool_response:{duration_ms:100}}' \
    | bash "$HOOK"
  [ "$(head -1 "$TEST_LOG" | jq -r '.name')" = "critic-agent" ]
}

# --- Tool filtering ---

@test "Bash completion is silently ignored" {
  echo '{"tool_name":"Bash","tool_input":{"command":"ls"},"tool_response":{}}' | bash "$HOOK"
  [ ! -s "$TEST_LOG" ]
}

@test "Read completion is silently ignored" {
  echo '{"tool_name":"Read","tool_input":{"file_path":"/x"},"tool_response":{}}' | bash "$HOOK"
  [ ! -s "$TEST_LOG" ]
}

# --- Resilience ---

@test "hook exits 0 on malformed JSON" {
  echo 'not json at all' | bash "$HOOK"
  [ "$?" -eq 0 ]
}

@test "hook exits 0 on empty input" {
  echo '' | bash "$HOOK"
  [ "$?" -eq 0 ]
}

@test "hook produces no stdout" {
  output=$(skill_post "draft-review" "100" | bash "$HOOK")
  [ -z "$output" ]
}

@test "each logged line is valid JSON" {
  skill_post "draft-review" "100" "200" | bash "$HOOK"
  agent_post_subagent "general-purpose" "50" | bash "$HOOK"
  while IFS= read -r line; do
    echo "$line" | jq . >/dev/null
  done < "$TEST_LOG"
}

# --- Pairing with pre-events ---

@test "post-event name matches pre-event name for the same skill" {
  # If a consumer wants to pair pre+post, the name field must be identical.
  PRE_HOOK="${LOG_USAGE_HOOK:-$BATS_TEST_DIRNAME/../../hooks/log-usage.sh}"
  printf '%s' '{"tool_name":"Skill","tool_input":{"skill":"draft-review","args":"hello"}}' | bash "$PRE_HOOK"
  skill_post "draft-review" "100" | bash "$HOOK"
  [ "$(sed -n '1p' "$TEST_LOG" | jq -r '.name')" = "draft-review" ]
  [ "$(sed -n '2p' "$TEST_LOG" | jq -r '.name')" = "draft-review" ]
  [ "$(sed -n '1p' "$TEST_LOG" | jq -r '.event')" = "skill" ]
  [ "$(sed -n '2p' "$TEST_LOG" | jq -r '.event')" = "skill_completed" ]
}
