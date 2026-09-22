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
#      permissions.deny, Claude Code #39344). A path that is HARD only after
#      resolve() is named by no deny rule, so the hook denies it itself (N1).
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
  # The config dir defaults to $HOME/.claude; an inherited CLAUDE_CONFIG_DIR
  # (the sandbox sets one) would make the temp ~/.claude non-global.
  unset CLAUDE_CONFIG_DIR
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

# --- Q-026: a project's own .claude/ is SOFT, not HARD-and-deferred ---
# The deny rules name only the global config dir, so a deferred project path
# had no gate at all. It now asks in a tainted session.

@test "Write to a project .claude/settings.local.json asks when tainted" {
  taint sess1
  guard "$(file_payload Write "/proj/.claude/settings.local.json" sess1)"
  assert_decision ask
}

@test "Write to a project .claude/settings.local.json defers when untainted" {
  guard "$(file_payload Write "/proj/.claude/settings.local.json" sess1)"
  assert_defer
}

@test "Edit to a project .claude/hooks file asks when tainted" {
  taint sess1
  guard "$(file_payload Edit "/proj/.claude/hooks/foo.sh" sess1)"
  assert_decision ask
}

@test "Write to the global ~/.claude/settings.local.json still defers when tainted" {
  taint sess1
  # shellcheck disable=SC2088
  guard "$(file_payload Write "~/.claude/settings.local.json" sess1)"
  assert_defer
}

@test "Write to the global dir via an absolute HOME path still defers when tainted" {
  taint sess1
  guard "$(file_payload Write "$HOME/.claude/hooks/foo.sh" sess1)"
  assert_defer
}

@test "CLAUDE_CONFIG_DIR is the global dir when set" {
  taint sess1
  # Without CLAUDE_CONFIG_DIR this path is a project .claude/ (SOFT -> ask);
  # naming it as the config dir makes it HARD (defer to the deny rules).
  guard "$(file_payload Write "$TEST_TMPDIR/alt/.claude/settings.json" sess1)"
  assert_decision ask
  CLAUDE_CONFIG_DIR="$TEST_TMPDIR/alt/.claude" guard "$(file_payload Write "$TEST_TMPDIR/alt/.claude/settings.json" sess1)"
  assert_defer
}

# --- Q-035: Bash CLAUDE.md is HARD only when qualified as the global file ---

@test "a heredoc commit message naming a bare CLAUDE.md is not denied (untainted)" {
  guard "$(bash_payload $'cat > "$TMPDIR/msg" <<EOF\ndocs: update CLAUDE.md routing\nEOF')"
  assert_defer
}

@test "a heredoc naming a bare CLAUDE.md asks, not denies, when tainted" {
  taint sess1
  guard "$(bash_payload $'cat > "$TMPDIR/msg" <<EOF\ndocs: update CLAUDE.md routing\nEOF' sess1)"
  assert_decision ask
}

@test "read-only commands on a project CLAUDE.md are not denied" {
  guard "$(bash_payload "rg -n install CLAUDE.md")"
  assert_defer
  guard "$(bash_payload "wc -l CLAUDE.md > out")"
  assert_defer
}

@test "a Bash write to a project CLAUDE.md asks when tainted" {
  taint sess1
  guard "$(bash_payload "echo x >> CLAUDE.md" sess1)"
  assert_decision ask
}

@test "a Bash write to the global ~/.claude/CLAUDE.md is still denied" {
  guard "$(bash_payload "echo x >> ~/.claude/CLAUDE.md")"
  assert_decision deny
}

@test "a Bash write to ~/CLAUDE.md, \$HOME/CLAUDE.md or \${HOME}/CLAUDE.md is denied" {
  guard "$(bash_payload "echo x > ~/CLAUDE.md")"
  assert_decision deny
  guard "$(bash_payload 'echo x > $HOME/CLAUDE.md')"
  assert_decision deny
  guard "$(bash_payload 'echo x > ${HOME}/CLAUDE.md')"
  assert_decision deny
}

@test "a Bash write to the literal home path CLAUDE.md is denied" {
  guard "$(bash_payload "echo x > $HOME/CLAUDE.md")"
  assert_decision deny
}

@test "a Bash write to global-instructions/CLAUDE.md stays denied (2026-09-12 review)" {
  guard "$(bash_payload "cp /tmp/x global-instructions/CLAUDE.md")"
  assert_decision deny
}

# --- R1: every spelling of the global CLAUDE.md is denied (co-occurrence) ---
# Each of these returned no opinion (untainted) or ask (tainted) at 4c7a2bb.

@test "R1: quoted, doubled-slash, dot-segment and quoted-name spellings are denied" {
  local c
  for c in \
    'echo x > "$HOME"/CLAUDE.md' \
    'echo x > ~//CLAUDE.md' \
    'echo x > ~/./CLAUDE.md' \
    'echo x > ~/"CLAUDE.md"' \
    'echo x > ${HOME:-}/CLAUDE.md' \
    'echo x > ${HOME:-/root}/CLAUDE.md' \
    'echo x > $HOME/x/../CLAUDE.md' \
    'echo x > ~/.claude//CLAUDE.md' \
    'echo x > ~/.claude/./CLAUDE.md' \
    'mv /tmp/x "$HOME/.claude"/CLAUDE.md' \
    'H=~; echo x > $H/CLAUDE.md' \
    'cd ~/.claude && mv x CLAUDE.md' \
    'cd "$CLAUDE_CONFIG_DIR" && cp x claude.md'; do
    guard "$(bash_payload "$c")"
    [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$output")" = deny ] \
      || { echo "not denied: $c -> $output"; return 1; }
  done
}

@test "R1: the literal home path with a doubled slash is denied" {
  guard "$(bash_payload "echo x > $HOME//CLAUDE.md")"
  assert_decision deny
}

@test "R1: the global spellings are denied in a tainted session too (not ask)" {
  taint sess1
  guard "$(bash_payload 'echo x > "$HOME"/CLAUDE.md' sess1)"
  assert_decision deny
}

@test "R1: a heredoc whose prose names ~/.claude/CLAUDE.md is denied (accepted cost)" {
  guard "$(bash_payload $'cat > "$TMPDIR/msg" <<EOF\ndocs: update ~/.claude/CLAUDE.md\nEOF')"
  assert_decision deny
}

@test "R1: a bare CLAUDE.md with no home indicator stays SOFT" {
  guard "$(bash_payload 'cp /tmp/x docs/CLAUDE.md')"
  assert_defer
  taint sess1
  guard "$(bash_payload 'cp /tmp/x docs/CLAUDE.md' sess1)"
  assert_decision ask
}

# --- A10: settings/hooks spellings the literal fragment missed ---

@test "A10: settings/hooks spellings with .claude anywhere are denied" {
  local c
  for c in \
    'echo x > ~/.claude//settings.json' \
    'echo x > ~/.claude/./settings.json' \
    'echo x > ~/".claude"/settings.json' \
    'cd ~/.claude && echo x > settings.json' \
    'cd ~/.claude && cp x hooks/foo.sh'; do
    guard "$(bash_payload "$c")"
    [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$output")" = deny ] \
      || { echo "not denied: $c -> $output"; return 1; }
  done
}

# --- R3: HARD is exactly the linker's single {{CLAUDE_DIR}} ---

@test "R3: with CLAUDE_CONFIG_DIR elsewhere, ~/.claude is SOFT (asks when tainted)" {
  taint sess1
  export CLAUDE_CONFIG_DIR="$TEST_TMPDIR/alt"
  guard "$(file_payload Write "$HOME/.claude/settings.json" sess1)"
  assert_decision ask
  guard "$(file_payload Edit "$HOME/.claude/hooks/foo.sh" sess1)"
  assert_decision ask
  guard "$(file_payload Write "$TEST_TMPDIR/alt/settings.json" sess1)"
  assert_defer
  # ~/CLAUDE.md is named by its own deny rule, independent of the config dir.
  guard "$(file_payload Write "$HOME/CLAUDE.md" sess1)"
  assert_defer
}

@test "R3: an empty CLAUDE_CONFIG_DIR falls back to ~/.claude, as the linker does" {
  taint sess1
  CLAUDE_CONFIG_DIR="" guard "$(file_payload Write "$HOME/.claude/settings.json" sess1)"
  assert_defer
}

@test "R3: a '~' in CLAUDE_CONFIG_DIR is not expanded (the linker doesn't)" {
  taint sess1
  # shellcheck disable=SC2088
  CLAUDE_CONFIG_DIR="~/.claude" guard "$(file_payload Write "$HOME/.claude/settings.json" sess1)"
  assert_decision ask
}

@test "R3: managed-settings.json is SOFT for file tools (no deny rule covers it)" {
  taint sess1
  guard "$(file_payload Write "/etc/claude-code/managed-settings.json" sess1)"
  assert_decision ask
}

# --- R4: never ask on a global path, in the installed symlink layout ---
# ~/.claude/hooks and ~/.claude/CLAUDE.md are symlinks into a payload dir, as
# link-claude-home.sh installs them from /opt/claude-workflows.

install_layout() {
  PAYLOAD="$TEST_TMPDIR/opt/claude-workflows"
  mkdir -p "$PAYLOAD/hooks" "$HOME/.claude"
  echo '# global' > "$PAYLOAD/CLAUDE.md"
  echo 'x' > "$PAYLOAD/hooks/foo.sh"
  ln -s "$PAYLOAD/hooks" "$HOME/.claude/hooks"
  ln -s "$PAYLOAD/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  echo '{}' > "$HOME/.claude/settings.json"
}

@test "R4: symlinked global CLAUDE.md and hooks defer when tainted" {
  install_layout
  taint sess1
  local f
  for f in \
    "$HOME/.claude/CLAUDE.md" \
    "$HOME/.claude/hooks/foo.sh" \
    "$HOME/.claude/hooks/new.sh" \
    "$HOME/.claude/x/../CLAUDE.md" \
    "$HOME/.claude/x/../hooks/foo.sh" \
    "$HOME/.claude//CLAUDE.md"; do
    guard "$(file_payload Edit "$f" sess1)"
    [ "$status" -eq 0 ] && [ -z "$output" ] || { echo "not deferred: $f -> $output"; return 1; }
  done
}

@test "R4: the MultiEdit tool and the path key defer on a '..' global path" {
  install_layout
  taint sess1
  guard "$(jq -n -c --arg f "$HOME/.claude/x/../CLAUDE.md" \
    '{"session_id":"sess1","tool_name":"MultiEdit","tool_input":{"path":$f}}')"
  assert_defer
}

# N1: a path that is HARD only after resolve() is not named by any deny rule,
# so a defer would leave it ungated. The hook denies it itself, tainted or not.
@test "N1: a project .claude symlinked to ~/.claude is denied on its hooks, CLAUDE.md, settings" {
  install_layout
  mkdir -p "$TEST_TMPDIR/proj"
  ln -s "$HOME/.claude" "$TEST_TMPDIR/proj/.claude"
  local f s
  for s in clean sess1; do
    [ "$s" = sess1 ] && taint sess1
    for f in hooks/foo.sh hooks/new.sh CLAUDE.md settings.json; do
      guard "$(file_payload Write "$TEST_TMPDIR/proj/.claude/$f" "$s")"
      [ "$status" -eq 0 ] && [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$output")" = deny ] \
        || { echo "not denied ($s): $f -> $output"; return 1; }
    done
  done
}

@test "N1: the payload CLAUDE.md and hooks by their real path are denied (resolve-only HARD)" {
  install_layout
  local f s
  for s in clean sess1; do
    [ "$s" = sess1 ] && taint sess1
    for f in "$PAYLOAD/CLAUDE.md" "$PAYLOAD/hooks/foo.sh" "$PAYLOAD/hooks/new.sh" \
             "$PAYLOAD/x/../CLAUDE.md"; do
      guard "$(file_payload Edit "$f" "$s")"
      [ "$status" -eq 0 ] && [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$output")" = deny ] \
        || { echo "not denied ($s): $f -> $output"; return 1; }
    done
  done
}

@test "N1: a symlinked config dir addressed by its resolved path is denied" {
  mkdir -p "$TEST_TMPDIR/real-cfg"
  ln -s "$TEST_TMPDIR/real-cfg" "$HOME/.claude"
  guard "$(file_payload Write "$TEST_TMPDIR/real-cfg/settings.json")"
  assert_decision deny
  # ...while the spelling the deny rule names still defers.
  guard "$(file_payload Write "$HOME/.claude/settings.json")"
  assert_defer
}

@test "N1: case variants are not HARD (deny rules are case-sensitive): SOFT, ask when tainted" {
  install_layout
  local f
  for f in "$HOME/.claude/HOOKS/x.sh" "$HOME/.claude/SETTINGS.JSON" \
           "$HOME/.claude/Settings.json" "$HOME/.claude/claude.md"; do
    guard "$(file_payload Write "$f")"
    [ "$status" -eq 0 ] && [ -z "$output" ] || { echo "untainted not deferred: $f -> $output"; return 1; }
  done
  taint sess1
  for f in "$HOME/.claude/HOOKS/x.sh" "$HOME/.claude/SETTINGS.JSON" \
           "$HOME/.claude/Settings.json" "$HOME/.claude/claude.md"; do
    guard "$(file_payload Write "$f" sess1)"
    [ "$status" -eq 0 ] && [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$output")" = ask ] \
      || { echo "tainted not ask: $f -> $output"; return 1; }
  done
}

@test "N1: a lexical global path still defers, tainted, in the symlink layout" {
  install_layout
  taint sess1
  local f
  for f in "$HOME/.claude/settings.json" "$HOME/.claude/settings.local.json" \
           "$HOME/.claude/hooks/foo.sh" "$HOME/.claude/CLAUDE.md" "$HOME/CLAUDE.md"; do
    guard "$(file_payload Write "$f" sess1)"
    [ "$status" -eq 0 ] && [ -z "$output" ] || { echo "not deferred: $f -> $output"; return 1; }
  done
}

@test "R4: a real (non-symlinked) project .claude still asks when tainted" {
  install_layout
  taint sess1
  mkdir -p "$TEST_TMPDIR/proj/.claude/hooks"
  guard "$(file_payload Write "$TEST_TMPDIR/proj/.claude/hooks/foo.sh" sess1)"
  assert_decision ask
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
