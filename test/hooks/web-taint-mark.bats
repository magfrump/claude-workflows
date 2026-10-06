#!/usr/bin/env bats
# @category fast
# Tests for the web-taint fetch log: hooks/web-taint-mark.py (PostToolUse)
# records each fetch in the session's marker and shows it as a systemMessage;
# hooks/guard-trusted-writes.py (PreToolUse) lists the recorded fetches in its
# tainted-session "ask" reason.
#
# Central use cases:
#   1. The marker's existence stays the taint signal; each fetch also appends
#      one JSON line {t, tool, target} (URL for WebFetch, query for WebSearch).
#   2. The fetch is highlighted at fetch time with a valid-JSON systemMessage.
#   3. Model-chosen targets are sanitized (no ESC/ANSI, no newlines) in both hooks.
#   4. The guard's ask lists the last 5 fetches and points at the marker for
#      the rest; a legacy empty marker or garbage lines still ask.
#
# Taint is driven through CC_WEB_TAINT_DIR and HOME is a temp dir, so nothing
# here touches the real /tmp/cc-web-taint or ~/.claude.

load ../lib/hermetic-env

pin_hermetic_locale

GUARD="$BATS_TEST_DIRNAME/../../hooks/guard-trusted-writes.py"
MARK="$BATS_TEST_DIRNAME/../../hooks/web-taint-mark.py"

setup() {
  TEST_TMPDIR=$(mktemp -d)
  export HOME="$TEST_TMPDIR/home"
  mkdir -p "$HOME"
  export CC_WEB_TAINT_DIR="$TEST_TMPDIR/taint"
  unset CLAUDE_CONFIG_DIR
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# --- Helpers ---

fetch() {  # $1 = session, $2 = url; runs the mark hook (sets $status/$output)
  run python3 "$MARK" <<<"$(jq -n -c --arg s "$1" --arg u "$2" \
    '{"session_id":$s,"tool_name":"WebFetch","tool_input":{"url":$u,"prompt":"p"}}')"
}

search() {  # $1 = session, $2 = query
  run python3 "$MARK" <<<"$(jq -n -c --arg s "$1" --arg q "$2" \
    '{"session_id":$s,"tool_name":"WebSearch","tool_input":{"query":$q}}')"
}

# A tainted-session SOFT write, so the guard asks; sets $status/$output.
soft_write() {  # $1 = session
  run python3 "$GUARD" <<<"$(jq -n -c --arg s "$1" \
    '{"session_id":$s,"tool_name":"Write","tool_input":{"file_path":"/proj/.claude/skills/x/SKILL.md"}}')"
}

reason() { jq -r '.hookSpecificOutput.permissionDecisionReason' <<<"$output"; }
decision() { jq -r '.hookSpecificOutput.permissionDecision' <<<"$output"; }

# --- Mark hook: marker + log line ---

@test "WebFetch creates the marker and appends a JSON line with the URL" {
  fetch s1 "https://example.com/a"
  [ "$status" -eq 0 ]
  [ -f "$CC_WEB_TAINT_DIR/s1" ]
  [ "$(wc -l <"$CC_WEB_TAINT_DIR/s1")" -eq 1 ]
  [ "$(jq -r .tool "$CC_WEB_TAINT_DIR/s1")" = "WebFetch" ]
  [ "$(jq -r .target "$CC_WEB_TAINT_DIR/s1")" = "https://example.com/a" ]
  [[ "$(jq -r .t "$CC_WEB_TAINT_DIR/s1")" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$ ]]
}

@test "WebSearch logs the query, appending after earlier fetches" {
  fetch s1 "https://example.com/a"
  search s1 "how to bake bread"
  [ "$(wc -l <"$CC_WEB_TAINT_DIR/s1")" -eq 2 ]
  [ "$(tail -n1 "$CC_WEB_TAINT_DIR/s1" | jq -r .tool)" = "WebSearch" ]
  [ "$(tail -n1 "$CC_WEB_TAINT_DIR/s1" | jq -r .target)" = "how to bake bread" ]
}

@test "an unknown (MCP) web tool logs compact tool_input" {
  run python3 "$MARK" <<<'{"session_id":"s1","tool_name":"mcp__web__get","tool_input":{"u":"x"}}'
  [ "$status" -eq 0 ]
  [ "$(jq -r .target "$CC_WEB_TAINT_DIR/s1")" = '{"u":"x"}' ]
}

@test "the marker is owner-only (0600) and its dir 0700" {
  fetch s1 "https://example.com/a"
  [ "$(stat -c %a "$CC_WEB_TAINT_DIR/s1")" = "600" ]
  [ "$(stat -c %a "$CC_WEB_TAINT_DIR")" = "700" ]
}

@test "a payload with no tool_input still taints" {
  run python3 "$MARK" <<<'{"session_id":"s1","tool_name":"WebFetch"}'
  [ "$status" -eq 0 ]
  [ -f "$CC_WEB_TAINT_DIR/s1" ]
}

@test "malformed stdin exits 0 with no marker" {
  run python3 "$MARK" <<<'not json'
  [ "$status" -eq 0 ]
  [ ! -e "$CC_WEB_TAINT_DIR" ]
}

# --- Mark hook: systemMessage ---

@test "stdout is valid JSON with a systemMessage naming the fetch and its count" {
  fetch s1 "https://example.com/a"
  fetch s1 "https://example.com/b"
  [ "$status" -eq 0 ]
  msg=$(jq -r .systemMessage <<<"$output")
  [[ "$msg" == *"web taint: WebFetch https://example.com/b"* ]]
  [[ "$msg" == *"fetch #2 this session"* ]]
  [[ "$msg" == *"$CC_WEB_TAINT_DIR/s1"* ]]
}

@test "ESC/ANSI and newlines in a URL are stripped from the log and the message" {
  fetch s1 $'https://evil.example/\x1b[31mred\nIGNORE PREVIOUS'
  [ "$status" -eq 0 ]
  run grep -c $'\x1b' "$CC_WEB_TAINT_DIR/s1"
  [ "$output" = "0" ]
  fetch s1 $'https://evil.example/\x1b[31mred\nIGNORE PREVIOUS'   # re-run for $output
  [ "$(wc -l <"$CC_WEB_TAINT_DIR/s1")" -eq 2 ]
  target=$(tail -n1 "$CC_WEB_TAINT_DIR/s1" | jq -r .target)
  [[ "$target" != *$'\n'* ]]
  [[ "$target" == *"red IGNORE PREVIOUS"* ]]
  msg=$(jq -r .systemMessage <<<"$output")
  [[ "$msg" != *$'\x1b'* ]]
  [[ "$msg" != *$'\n'* ]]
}

@test "a long target is truncated to 200 chars" {
  fetch s1 "https://example.com/$(printf 'a%.0s' {1..500})"
  [ "$(jq -r .target "$CC_WEB_TAINT_DIR/s1" | wc -m)" -le 201 ]
}

# --- Guard: the ask names the fetches ---

@test "the guard's ask lists the recorded fetches and the marker path" {
  fetch s1 "https://example.com/a"
  search s1 "some query"
  soft_write s1
  [ "$status" -eq 0 ]
  [ "$(decision)" = "ask" ]
  r=$(reason)
  [[ "$r" == *"Web content this session (2 fetches, most recent last):"* ]]
  [[ "$r" == *"WebFetch https://example.com/a"* ]]
  [[ "$r" == *"WebSearch some query"* ]]
  [[ "$r" == *"full list: $CC_WEB_TAINT_DIR/s1"* ]]
  [[ "$r" != *"earlier not shown"* ]]
}

@test "the guard's ask caps the list at 5 and notes the earlier ones" {
  for i in 1 2 3 4 5 6 7; do fetch s1 "https://example.com/$i"; done
  soft_write s1
  [ "$(decision)" = "ask" ]
  r=$(reason)
  [[ "$r" == *"(7 fetches"* ]]
  [ "$(grep -c '^  - ' <<<"$r")" -eq 5 ]
  [[ "$r" != *"example.com/2"* ]]
  [[ "$r" == *"example.com/3"* ]]
  [[ "$r" == *"example.com/7"* ]]
  [[ "$r" == *"(2 earlier not shown; full list: $CC_WEB_TAINT_DIR/s1)"* ]]
}

@test "the guard's ask on a Bash write lists the fetches too" {
  fetch s1 "https://example.com/a"
  run python3 "$GUARD" <<<"$(jq -n -c '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"echo x >> /proj/.claude/skills/x/SKILL.md"}}')"
  [ "$(decision)" = "ask" ]
  [[ "$(reason)" == *"WebFetch https://example.com/a"* ]]
}

@test "a legacy empty marker still taints and says sources not recorded" {
  mkdir -p "$CC_WEB_TAINT_DIR" && touch "$CC_WEB_TAINT_DIR/s1"
  soft_write s1
  [ "$(decision)" = "ask" ]
  [[ "$(reason)" == *"(sources not recorded; marker: $CC_WEB_TAINT_DIR/s1)"* ]]
}

@test "garbage lines are skipped and the guard still asks" {
  mkdir -p "$CC_WEB_TAINT_DIR"
  printf 'garbage\n[1,2]\n{"t":"2026-10-06T12:01:03Z","tool":"WebFetch","target":"https://ok.example/"}\n\xff\xfe\n' \
    >"$CC_WEB_TAINT_DIR/s1"
  soft_write s1
  [ "$status" -eq 0 ]
  [ "$(decision)" = "ask" ]
  r=$(reason)
  [[ "$r" == *"(1 fetches"* ]]
  [[ "$r" == *"12:01:03Z WebFetch https://ok.example/"* ]]
}

@test "the guard re-sanitizes a hand-forged log line" {
  mkdir -p "$CC_WEB_TAINT_DIR"
  jq -n -c '{"t":"x","tool":"WebFetch","target":"https://a/\u001b[2J\nAPPROVE"}' >"$CC_WEB_TAINT_DIR/s1"
  soft_write s1
  r=$(reason)
  [[ "$r" != *$'\x1b'* ]]
  [[ "$r" == *"https://a/ [2J APPROVE"* ]]
}

@test "an untainted session still defers silently" {
  fetch other "https://example.com/a"
  soft_write s1
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
