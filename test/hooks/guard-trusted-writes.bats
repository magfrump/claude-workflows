#!/usr/bin/env bats
# @category fast
# Tests for the PreToolUse trusted-policy guard (hooks/guard-trusted-writes.py)
# and the PostToolUse taint marker that feeds it (hooks/web-taint-mark.py).
#
# Central use cases:
#   1. A Bash write to a HARD policy path (~/.claude settings / hooks / CLAUDE.md)
#      is denied outright — including fd-prefixed and &> redirects (1>, 2>, &>),
#      which the pre-2026-09-18 redirect regex let through.
#   2. Reads that merely redirect stderr/stdout elsewhere (2>&1, >&2,
#      2>/dev/null) are NOT writes and get no decision.
#   3. A SOFT policy path is gated to "ask" only in a web-tainted session;
#      untainted it is a silent defer.
#   4. The file tools on a HARD path defer (never "ask" — an ask would override
#      permissions.deny, Claude Code #39344).
#   5. Malformed or non-object input is a silent exit 0, never a traceback.
#
# "Defer" is the hook's documented no-opinion signal: exit 0 with NO output.
# Taint is driven through CC_WEB_TAINT_DIR (read by both hooks) and HOME is a
# temp dir, so nothing here reads or writes the real ~/.claude or /tmp taint.

load ../lib/hermetic-env

pin_hermetic_locale

GUARD="$BATS_TEST_DIRNAME/../../hooks/guard-trusted-writes.py"
MARK="$BATS_TEST_DIRNAME/../../hooks/web-taint-mark.py"

setup() {
  TEST_TMPDIR=$(mktemp -d)
  export HOME="$TEST_TMPDIR/home"
  mkdir -p "$HOME"
  export CC_WEB_TAINT_DIR="$TEST_TMPDIR/taint"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# --- Helpers ---

bash_payload() {  # $1 = command, $2 = session id (default: clean)
  jq -n -c --arg c "$1" --arg s "${2:-clean}" \
    '{"session_id":$s,"tool_name":"Bash","tool_input":{"command":$c}}'
}

file_payload() {  # $1 = tool, $2 = file_path, $3 = session id (default: clean)
  jq -n -c --arg t "$1" --arg f "$2" --arg s "${3:-clean}" \
    '{"session_id":$s,"tool_name":$t,"tool_input":{"file_path":$f}}'
}

# Run the guard on stdin $1; sets $status/$output.
guard() {
  run python3 "$GUARD" <<<"$1"
}

# Assert the guard emitted the given permissionDecision.
assert_decision() {
  [ "$status" -eq 0 ]
  [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$output")" = "$1" ]
}

# Assert the guard deferred: exit 0, nothing on stdout or stderr.
assert_defer() {
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

taint() {  # mark session $1 as web-tainted via the real PostToolUse hook
  jq -n -c --arg s "$1" '{"session_id":$s,"tool_name":"WebFetch"}' | python3 "$MARK"
}

# The tilde is deliberately literal: these are command TEXT the hook must
# recognise as a protected path, not paths for this shell to expand.
# shellcheck disable=SC2088
SETTINGS="~/.claude/settings.json"
# shellcheck disable=SC2088
HOOKFILE="~/.claude/hooks/foo.sh"
# shellcheck disable=SC2088
SKILL="~/.claude/skills/foo/SKILL.md"

# --- HARD path via Bash: deny ---

@test "plain > to settings.json is denied" {
  guard "$(bash_payload "echo x > $SETTINGS")"
  assert_decision deny
}

@test ">> to settings.json is denied" {
  guard "$(bash_payload "echo x >> $SETTINGS")"
  assert_decision deny
}

@test "1> to settings.json is denied (B1 bypass)" {
  guard "$(bash_payload "echo x 1> $SETTINGS")"
  assert_decision deny
}

@test "1> with no space to settings.json is denied (B1 bypass)" {
  guard "$(bash_payload "echo x 1>$SETTINGS")"
  assert_decision deny
}

@test "2> to a hooks file is denied (B1 bypass)" {
  guard "$(bash_payload "echo x 2> $HOOKFILE")"
  assert_decision deny
}

@test "&> to settings.json is denied (B1 bypass)" {
  guard "$(bash_payload "echo x &> $SETTINGS")"
  assert_decision deny
}

@test ">& FILE (stdout+stderr to a file) to settings.json is denied" {
  guard "$(bash_payload "echo x >& $SETTINGS")"
  assert_decision deny
  guard "$(bash_payload "echo x 1>&$SETTINGS")"
  assert_decision deny
}

@test ">&- (close stdout) on a read of settings.json is not a write" {
  guard "$(bash_payload "cat $SETTINGS >&-")"
  assert_defer
}

@test "a HARD-path deny holds in an untainted session too" {
  guard "$(bash_payload "echo x > $SETTINGS" never-tainted)"
  assert_decision deny
}

# --- Redirects that are not writes: defer ---

@test "2>&1 on a read of settings.json is not a write" {
  guard "$(bash_payload "cat $SETTINGS 2>&1 | head")"
  assert_defer
}

@test ">&2 on a read of settings.json is not a write" {
  guard "$(bash_payload "jq . $SETTINGS >&2")"
  assert_defer
}

@test "2>/dev/null on a read of settings.json is not a write" {
  guard "$(bash_payload "cat $SETTINGS 2>/dev/null")"
  assert_defer
}

@test "2>/dev/null on a listing of the hooks dir is not a write" {
  guard "$(bash_payload "ls ~/.claude/hooks 2>/dev/null")"
  assert_defer
}

@test "a /dev/null redirect does not mask a later real write" {
  guard "$(bash_payload "echo x > /dev/null; echo y > $SETTINGS")"
  assert_decision deny
}

# --- SOFT path via Bash: ask only when tainted ---

@test "SOFT path write in a tainted session asks" {
  taint sess1
  [ -e "$CC_WEB_TAINT_DIR/sess1" ]
  guard "$(bash_payload "echo x >> $SKILL" sess1)"
  assert_decision ask
}

@test "SOFT path write in an untainted session defers" {
  taint other
  guard "$(bash_payload "echo x >> $SKILL" sess1)"
  assert_defer
}

@test "fd-prefixed SOFT path write in a tainted session asks" {
  taint sess1
  guard "$(bash_payload "echo x 1>> $SKILL" sess1)"
  assert_decision ask
}

# --- File tools ---

@test "Write to HARD settings.json defers (never ask; deny rules own it)" {
  taint sess1
  guard "$(file_payload Write "$SETTINGS" sess1)"
  assert_defer
}

@test "Edit to a HARD hooks file defers even when tainted" {
  taint sess1
  guard "$(file_payload Edit "$HOOKFILE" sess1)"
  assert_defer
}

@test "Write to a SOFT skill file asks when tainted" {
  taint sess1
  guard "$(file_payload Write "$SKILL" sess1)"
  assert_decision ask
}

@test "Write to a SOFT skill file defers when untainted" {
  guard "$(file_payload Write "$SKILL" sess1)"
  assert_defer
}

# --- Malformed input: silent exit 0 ---

@test "non-JSON stdin defers" {
  guard "not json"
  assert_defer
}

@test "JSON array stdin defers" {
  guard '[]'
  assert_defer
}

@test "JSON string stdin defers" {
  guard '"x"'
  assert_defer
}

@test "non-object tool_input defers" {
  guard '{"tool_name":"Bash","tool_input":"echo x"}'
  assert_defer
}

@test "null tool_input defers" {
  guard '{"tool_name":"Bash","tool_input":null}'
  assert_defer
}
