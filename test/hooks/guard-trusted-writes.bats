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
  jq -n -c --arg s "$1" '{"session_id":$s,"tool_name":"WebFetch"}' | python3 "$MARK" >/dev/null
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

# --- Q-048 [2] withdrawn: agent worktree paths count as `.claude` like any other ---
# The worktree exemption was tried and withdrawn (2026-09-23) after three review
# passes each found bypasses. A `.claude/wt-*` or `.claude/worktrees/<name>` path
# is an ordinary `.claude` indicator, so a worktree Bash write that names a policy
# file is denied. Every bypass pinned in passes 1-3 stays here as a deny test.

# A real git repo with two real agent worktrees under its .claude/, outside
# HOME. Sets REPO.
worktree_layout() {
  REPO="$TEST_TMPDIR/repo"
  mkdir -p "$REPO"
  git -C "$REPO" init -q
  git -C "$REPO" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
  git -C "$REPO" worktree add -q "$REPO/.claude/wt-foo" -b wt-foo
  git -C "$REPO" worktree add -q "$REPO/.claude/worktrees/foo" -b wt-foo2
  [ -f "$REPO/.claude/wt-foo/.git" ] && [ -f "$REPO/.claude/worktrees/foo/.git" ]
}

assert_all_deny() {  # each arg is a command that must be denied
  local c
  for c in "$@"; do
    guard "$(bash_payload "$c")"
    [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$output")" = deny ] \
      || { echo "not denied: $c -> $output"; return 1; }
  done
}

@test "Q-048 withdrawn: a Bash write into a real .claude/wt-* worktree's hooks/ or settings is denied" {
  worktree_layout
  assert_all_deny \
    "echo x > $REPO/.claude/wt-foo/hooks/x.sh" \
    "cp /tmp/a $REPO/.claude/wt-foo/hooks/x.py" \
    "sed -i s/a/b/ $REPO/.claude/wt-foo/settings.json"
}

@test "Q-048 withdrawn: a Bash write into a real .claude/worktrees/<name> worktree's hooks/ is denied" {
  worktree_layout
  guard "$(bash_payload "cp /tmp/a $REPO/.claude/worktrees/foo/hooks/x.py")"
  assert_decision deny
}

@test "Q-048 withdrawn: a worktree CLAUDE.md Bash write is denied (.claude is a home indicator)" {
  worktree_layout
  guard "$(bash_payload "echo x >> $REPO/.claude/wt-foo/CLAUDE.md")"
  assert_decision deny
  taint sess1
  guard "$(bash_payload "echo x >> $REPO/.claude/wt-foo/CLAUDE.md" sess1)"
  assert_decision deny
}

@test "Q-048: a relative worktree path is not exempt (no cwd at hook time)" {
  worktree_layout
  assert_all_deny \
    'echo x >> .claude/worktrees/foo/hooks/x.sh' \
    "cd $REPO && echo x > .claude/wt-foo/settings.json"
}

@test "Q-048: a worktree path that does not exist, or is not a git worktree, is not exempt" {
  worktree_layout
  mkdir -p "$REPO/.claude/wt-plain"
  assert_all_deny \
    "echo x > $REPO/.claude/wt-missing/hooks/x.sh" \
    "echo x > $REPO/.claude/wt-plain/settings.json" \
    'echo x > /srv/repo/.claude/wt-foo/hooks/x.sh'
}

@test "Q-048 bypass: quote-split '..' after a worktree segment is denied" {
  worktree_layout
  mkdir -p "$HOME/.claude/wt-x"
  local lh="$HOME"
  assert_all_deny \
    'cd ~ && echo x > .claude/wt-x"/.."/settings.json' \
    "cd ~ && echo x > .claude/wt-x'/..'/settings.json" \
    'cd ~ && echo x > .claude/wt-x"/../hooks/"evil.sh' \
    'cd ~ && echo x > .claude/wt-x/."".//settings.json' \
    'cd ~ && echo x > .claude/wt-x/.""./settings.json' \
    'mkdir -p "$HOME"/.claude/wt-y && echo {} > "$HOME"/.claude/wt-y"/../"settings.local.json' \
    "echo x > '$lh'/.claude/wt-x'/..'/hooks/evil.sh" \
    "echo x > \"$lh\"/.claude/wt-x\"/..\"/settings.json" \
    'echo x > ".claude/wt-z"/../settings.json' \
    "echo x > $REPO/.claude/wt-foo\"/..\"/settings.json" \
    "echo x > $REPO/.claude/wt-foo'/../../..'$HOME/.claude/settings.json"
}

@test "Q-048 bypass: a quote before /.claude or a second '=' does not exempt a home worktree" {
  mkdir -p "$HOME/.claude/wt-x"
  local lh="$HOME"
  assert_all_deny \
    'echo x > "$HOME"/.claude/wt-x/settings.json' \
    "echo x > \"$lh\"/.claude/wt-x/settings.json" \
    "echo x > a=b=$lh/.claude/wt-x/settings.json" \
    'echo x > "$HOME"/.claude/wt-x/hooks/x.sh'
}

@test "Q-048 bypass: a quoted parent of a wt-shaped CLAUDE_CONFIG_DIR is denied" {
  mkdir -p "$TEST_TMPDIR/srv/repo/.claude/wt-cfg"
  export CLAUDE_CONFIG_DIR="$TEST_TMPDIR/srv/repo/.claude/wt-cfg"
  assert_all_deny \
    "echo x > \"$TEST_TMPDIR/srv/repo\"/.claude/wt-cfg/settings.json" \
    "echo x > $TEST_TMPDIR/srv/repo/.claude/wt-cfg/settings.json"
}

@test "Q-048 bypass: a symlinked worktree dir is not exempt" {
  worktree_layout
  ln -s "$HOME/.claude" "$REPO/.claude/wt-link"
  ln -s "$REPO/.claude/wt-foo" "$REPO/.claude/wt-alias"
  mkdir -p "$HOME/.claude"
  assert_all_deny \
    'cd ~ && ln -s . .claude/wt-q && echo PWNED > .claude/wt-q/settings.json' \
    "echo x > $REPO/.claude/wt-link/settings.json" \
    "echo x > $REPO/.claude/wt-alias/settings.json"
}

@test "Q-048: a real worktree inside the config dir is not exempt" {
  worktree_layout
  git -C "$REPO" worktree add -q "$HOME/.claude/wt-home" -b wt-home
  [ -f "$HOME/.claude/wt-home/.git" ]
  assert_all_deny \
    "echo x > $HOME/.claude/wt-home/settings.json" \
    "echo x > $HOME/.claude/wt-home/hooks/x.sh"
}

@test "Q-048: a symlink inside a worktree that leads out of it is not exempt" {
  worktree_layout
  mkdir -p "$HOME/.claude"
  ln -s "$HOME/.claude" "$REPO/.claude/wt-foo/cfg"
  assert_all_deny "echo x > $REPO/.claude/wt-foo/cfg/settings.json"
}

@test "Q-048: a '..' after a worktree segment is still denied" {
  worktree_layout
  local c
  for c in \
    "echo x > $REPO/.claude/wt-foo/../hooks/x.sh" \
    "echo x > $REPO/.claude/wt-foo/sub/../../settings.json" \
    "cp /tmp/a $REPO/.claude/worktrees/foo/../../.claude/hooks/x" \
    "cd $REPO/.claude/worktrees/.. && cp /tmp/a hooks/x" \
    'echo x > .claude/wt-foo/../CLAUDE.md'; do
    guard "$(bash_payload "$c")"
    [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$output")" = deny ] \
      || { echo "not denied: $c -> $output"; return 1; }
  done
}

@test "Q-048: a worktree path under ~, \$HOME or the literal home config dir is still denied" {
  local c
  for c in \
    'echo x > ~/.claude/wt-foo/hooks/x.sh' \
    'echo x > $HOME/.claude/wt-foo/hooks/x.sh' \
    'echo x > ${HOME}/.claude/worktrees/foo/hooks/x.sh' \
    "echo x > $HOME/.claude/wt-foo/hooks/x.sh" \
    "echo x > $HOME/.claude/wt-foo/../hooks/x.sh" \
    "echo x > $HOME//.claude/wt-foo/CLAUDE.md" \
    'echo x > /a/../.claude/wt-foo/hooks/x.sh'; do
    guard "$(bash_payload "$c")"
    [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$output")" = deny ] \
      || { echo "not denied: $c -> $output"; return 1; }
  done
}

@test "Q-048: a worktree path does not mask a real .claude indicator elsewhere" {
  worktree_layout
  local c
  for c in \
    "cp $REPO/.claude/wt-foo/hooks/a ~/.claude/hooks/a" \
    "cp $REPO/.claude/wt-foo/settings.json ~/.claude/" \
    "cd ~/.claude && cp $REPO/.claude/wt-foo/hooks/a hooks/a" \
    "cp $REPO/.claude/wt-foo/x $REPO/.claude/wt-foo/.claude/hooks/x" \
    "echo x > $REPO/.claude/wt-foo/CLAUDE.md; echo y > ~/CLAUDE.md"; do
    guard "$(bash_payload "$c")"
    [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$output")" = deny ] \
      || { echo "not denied: $c -> $output"; return 1; }
  done
}

@test "Q-048: CLAUDE_CONFIG_DIR set to a wt-shaped dir is not exempt" {
  export CLAUDE_CONFIG_DIR="$TEST_TMPDIR/.claude/wt-cfg"
  guard "$(bash_payload "echo x > $TEST_TMPDIR/.claude/wt-cfg/settings.json")"
  assert_decision deny
}

# --- Q-048 pass-2/pass-3 routes (kept as deny tests after the withdrawal) ---
# Routes out of a worktree through a later word (`cd ..`, `../x`), a same-command
# root swap, a command-derived parent, `-t..`, brace expansion, `env -C`, or a
# link-creating tool. The exemption these defeated is gone; they must stay denied.

@test "Q-048 gate: cd into a worktree then '..' reaches the parent project's .claude: denied" {
  worktree_layout
  local wt="$REPO/.claude/wt-foo"
  assert_all_deny \
    "cd $wt && cd .. && echo x > settings.json" \
    "cd $wt && cd .. && echo x > hooks/x.sh" \
    "cd $wt; cd ../; cp /tmp/a settings.local.json" \
    "cd $wt && echo x > ../settings.json" \
    "cd $wt && echo x > ../hooks/x.sh" \
    "pushd $wt && echo x > .\"\"./settings.json" \
    "cd $wt && bats test/hooks/x.bats > out.txt"
}

@test "Q-048 gate: the cd/'..' routes are denied in a tainted session too (were deferred)" {
  worktree_layout
  taint sess1
  guard "$(bash_payload "cd $REPO/.claude/wt-foo && cd .. && echo x > settings.json" sess1)"
  assert_decision deny
  guard "$(bash_payload "cd $REPO/.claude/wt-foo && echo x > ../settings.json" sess1)"
  assert_decision deny
}

@test "Q-048 gate: replacing a worktree root in the same command is not exempt (time of check)" {
  worktree_layout
  mkdir -p "$HOME/.claude"
  local wt="$REPO/.claude/wt-foo"
  # $(cd;pwd) is literal command text here, not for this shell to run.
  # shellcheck disable=SC2016
  assert_all_deny \
    "rm -rf $wt && ln -s \"\$(cd;pwd)\" $wt && echo x > $wt/CLAUDE.md" \
    "mv $wt $TEST_TMPDIR/x && ln -s ~/.cla?de $wt && echo > $wt/settings.json" \
    "rm -rf $wt && ln -s /tmp/x $wt && echo x > $wt/settings.json" \
    "rm -rf $wt && ln -s /tmp/x $wt && echo x > $wt/hooks/evil.sh" \
    "/bin/rm -r $wt; /bin/ln -s /tmp/x $wt; cp /tmp/a $wt/settings.json"
}

@test "Q-048 gate: a worktree root whose parent is derived by the command is not exempt" {
  worktree_layout
  local wt="$REPO/.claude/wt-foo"
  assert_all_deny \
    "echo x > \$(dirname $wt)/settings.json" \
    "cp /tmp/a \`dirname $wt\`/hooks/x.sh" \
    "echo $wt | sed 's,/[^/]*\$,,' | xargs -I% cp /tmp/a %/settings.json" \
    "python3 -c 'import os,sys; os.rename(sys.argv[1], \"/tmp/y\")' $wt; cp /tmp/a $wt/settings.json" \
    "sh -c 'l\"\"n -s /tmp/x $wt'; echo x > $wt/settings.json" \
    "cp /tmp/a $wt/x; cp /tmp/b settings.json"
}

@test "Q-048 withdrawn: plain absolute worktree policy writes are denied, look-alike words or not" {
  worktree_layout
  local wt="$REPO/.claude/wt-foo"
  assert_all_deny \
    "echo x > $wt/hooks/x.sh" \
    "cp /x/rmdata/a $wt/hooks/x.sh" \
    "echo --cdn > $wt/hooks/x.sh" \
    "cp /srv/cd-tools/a $wt/settings.json"
}

@test "Q-048 withdrawn: a worktree write naming no policy file is not denied" {
  worktree_layout
  guard "$(bash_payload "cp /tmp/a $REPO/.claude/wt-foo/test/y.bats")"
  assert_defer
}

@test "Q-048 pass 3: -t.., brace-built '..', env -C and link-creating tools are denied" {
  worktree_layout
  local wt="$REPO/.claude/wt-foo"
  assert_all_deny \
    "echo EVIL > $wt/settings.json && env -C $wt cp $wt/settings.json -t.." \
    "mkdir -p $wt/hooks && echo EVIL > $wt/hooks/x.sh && env -C $wt cp -r $wt/hooks -t.." \
    "echo EVIL > $wt/settings.json && install -t.. $wt/settings.json" \
    "cp $wt/settings.json -t.." \
    "env -C $wt cp $wt/settings.json .{,.}" \
    "find $wt -delete && cp -P /tmp/lnkdir $wt && echo PWN > $wt/settings.json" \
    "cp -P /tmp/lnkfile $wt/settings.json && echo PWN > $wt/settings.json" \
    "git -C $wt checkout -q evil && echo PWN > $wt/hooks/evil.sh" \
    "tar -xf /tmp/e.tar -C $wt && echo PWN > $wt/settings.json" \
    "cp -rs /tmp/c $wt/c && echo PWN > $wt/c/settings.json"
}

# --- File tools inside a linked worktree under .claude/: judged relative to its root ---
# A web-tainted session asked on every Edit in a `.claude/` worktree (owner report
# 2026-11-19). The file tools now judge a path inside a VERIFIED linked worktree by
# its path relative to the worktree root; the worktree's own policy files still ask,
# and anything unverifiable keeps the blanket `.claude` SOFT. Bash is unchanged.

assert_file_decisions() {  # $1 = expected (ask|defer|deny), $2 = session, rest = paths
  local want="$1" sess="$2" f got
  shift 2
  for f in "$@"; do
    guard "$(file_payload Edit "$f" "$sess")"
    got=$(jq -r '.hookSpecificOutput.permissionDecision // empty' <<<"$output")
    [ "$status" -eq 0 ] && [ "${got:-defer}" = "$want" ] \
      || { echo "want $want, got ${got:-defer} ($status): $f -> $output"; return 1; }
  done
}

@test "worktree taint: the reproduction table (tainted and clean, both layouts, .worktrees, main checkout)" {
  worktree_layout
  git -C "$REPO" worktree add -q "$REPO/.worktrees/wt-x" -b wt-x
  taint sess1
  local f
  for f in "$REPO/.claude/worktrees/foo/chapter3.md" "$REPO/.claude/wt-foo/chapter3.md" \
           "$REPO/.claude/wt-foo/scripts/run.sh" "$REPO/.claude/worktrees/foo/sub/deep/notes.txt" \
           "$REPO/.worktrees/wt-x/chapter3.md" "$REPO/chapter3.md"; do
    assert_file_decisions defer sess1 "$f"
    assert_file_decisions defer clean "$f"
  done
}

@test "worktree taint: a worktree's own policy files still ask when tainted (both layouts)" {
  worktree_layout
  taint sess1
  local w
  for w in "$REPO/.claude/wt-foo" "$REPO/.claude/worktrees/foo"; do
    assert_file_decisions ask sess1 \
      "$w/.claude/settings.json" "$w/.claude/settings.local.json" "$w/.claude/skills/x.md" \
      "$w/.claude/notes.md" "$w/CLAUDE.md" "$w/AGENTS.md" "$w/sub/CLAUDE.local.md" \
      "$w/hooks/x.sh" "$w/hooks/lib/y.py" "$w/settings.json" "$w/settings.local.json" \
      "$w/skills/x/SKILL.md" "$w/agents/a.md" "$w/commands/c.md" "$w/memories/m.md" \
      "$w/rules/x.mdc" "$w/.git" "$w/HOOKS/x.sh"
    assert_file_decisions defer clean "$w/.claude/settings.json" "$w/hooks/x.sh" "$w/CLAUDE.md"
  done
}

@test "worktree taint: a symlinked policy name inside a worktree keeps its ask (review R1)" {
  worktree_layout
  local w="$REPO/.claude/wt-foo"
  mkdir -p "$w/docs/hk" "$w/realskills" "$w/shared-claude/rules" "$w/sub"
  echo x > "$w/docs/x.md"
  ln -s docs/x.md "$w/CLAUDE.md"
  ln -s docs/x.md "$w/AGENTS.md"
  ln -s ../docs/x.md "$w/sub/CLAUDE.local.md"
  ln -s docs/x.md "$w/settings.json"
  ln -s docs/hk "$w/hooks"
  ln -s realskills "$w/skills"
  ln -s shared-claude "$w/.claude"
  taint sess1
  assert_file_decisions ask sess1 \
    "$w/CLAUDE.md" "$w/AGENTS.md" "$w/sub/CLAUDE.local.md" "$w/settings.json" \
    "$w/hooks/x.sh" "$w/skills/x.md" "$w/.claude/rules/r.md"
  # An ordinary name pointing at an ordinary file still has no opinion.
  ln -s docs/x.md "$w/notes.md"
  assert_file_decisions defer sess1 "$w/notes.md"
}

@test "worktree taint: a relative path to a symlinked root settings.json or hooks/ keeps its ask (review A6)" {
  worktree_layout
  local w="$REPO/.claude/wt-foo"
  mkdir -p "$w/docs/hk" "$w/sub"
  echo x > "$w/docs/x.md"
  ln -s docs/x.md "$w/settings.json"
  ln -s docs/x.md "$w/settings.local.json"
  ln -s docs/hk "$w/hooks"
  taint sess1
  cd "$w"
  assert_file_decisions ask sess1 settings.json settings.local.json hooks/x.sh CLAUDE.md
  assert_file_decisions defer sess1 chapter3.md
  cd "$w/sub"
  assert_file_decisions ask sess1 ../settings.json
  cd "$REPO/.claude"
  assert_file_decisions ask sess1 wt-foo/settings.json
}

@test "worktree taint: a worktree nested in a policy folder keeps that folder's ask (review C7)" {
  worktree_layout
  git -C "$REPO" worktree add -q "$REPO/.claude/commands/.claude/wt-c" -b wt-c
  git -C "$REPO" worktree add -q "$REPO/Skills/.claude/wt-s" -b wt-s
  taint sess1
  assert_file_decisions ask sess1 "$REPO/.claude/commands/.claude/wt-c/evil.md" \
    "$REPO/Skills/.claude/wt-s/evil.md"
}

@test "worktree taint: hooks/ and settings*.json ask only at the worktree root (review A1)" {
  worktree_layout
  taint sess1
  local w="$REPO/.claude/wt-foo"
  assert_file_decisions ask sess1 "$w/hooks/x.sh" "$w/settings.json" "$w/.git"
  assert_file_decisions defer sess1 "$w/src/hooks/useX.ts" "$w/.vscode/settings.json" \
    "$w/config/settings.json"
}

@test "worktree taint: a symlink loop too deep to resolve fails closed (review C1)" {
  worktree_layout
  taint sess1
  local c="$REPO/.claude/wt-foo/c" i
  mkdir -p "$c"
  echo x > "$c/l0"
  for i in $(seq 1 1500); do ln -s "l$((i - 1))" "$c/l$i"; done
  guard "$(file_payload Edit "$c/l1500" sess1)"
  assert_decision ask
}

@test "worktree taint: HARD paths are unchanged (defer as given, deny when reached through a worktree link)" {
  worktree_layout
  mkdir -p "$HOME/.claude/hooks"
  echo '{}' > "$HOME/.claude/settings.json"
  echo x > "$HOME/.claude/CLAUDE.md"
  ln -s "$HOME/.claude/settings.json" "$REPO/.claude/wt-foo/cfg.json"
  ln -s "$HOME/.claude/hooks" "$REPO/.claude/wt-foo/hk"
  taint sess1
  assert_file_decisions defer sess1 \
    "$HOME/.claude/settings.json" "$HOME/.claude/hooks/x.sh" "$HOME/.claude/CLAUDE.md" "$HOME/CLAUDE.md"
  assert_file_decisions deny sess1 "$REPO/.claude/wt-foo/cfg.json" "$REPO/.claude/wt-foo/hk/x.sh"
  assert_file_decisions deny clean "$REPO/.claude/wt-foo/cfg.json"
}

@test "worktree taint: symlinks that leave the worktree, or a symlinked root, keep the ask" {
  worktree_layout
  mkdir -p "$HOME/.claude/projects/p/memory" "$REPO/.claude/wt-foo/docs"
  ln -s "$HOME/.claude" "$REPO/.claude/wt-foo/cfg"           # into the config dir
  ln -s "$REPO/.claude" "$REPO/.claude/wt-foo/proj"           # into the project's .claude
  ln -s "$REPO/.claude/wt-foo/docs" "$REPO/.claude/wt-foo/d"  # stays inside: ordinary
  ln -s "$REPO/.claude/wt-foo" "$REPO/.claude/wt-alias"       # a symlinked root
  ln -s "$HOME/.claude" "$REPO/.claude/wt-home-link"          # a root that is the config dir
  taint sess1
  assert_file_decisions ask sess1 \
    "$REPO/.claude/wt-foo/cfg/projects/p/memory/MEMORY.md" \
    "$REPO/.claude/wt-foo/proj/notes.md" \
    "$REPO/.claude/wt-alias/chapter3.md" \
    "$REPO/.claude/wt-home-link/projects/p/memory/MEMORY.md"
  assert_file_decisions defer sess1 "$REPO/.claude/wt-foo/d/chapter3.md"
}

@test "worktree taint: '..' out of a worktree keeps the ask; '..' that stays inside does not" {
  worktree_layout
  taint sess1
  assert_file_decisions ask sess1 \
    "$REPO/.claude/wt-foo/../notes.md" \
    "$REPO/.claude/wt-foo/../settings.json" \
    "$REPO/.claude/worktrees/foo/../../wt-foo/chapter3.md" \
    "$REPO/.claude/wt-foo/sub/../../wt-foo-not/x.md"
  assert_file_decisions defer sess1 "$REPO/.claude/wt-foo/sub/../chapter3.md"
}

@test "worktree taint: an unverifiable worktree root fails closed (keeps the ask)" {
  worktree_layout
  taint sess1
  local c="$REPO/.claude"
  mkdir -p "$c/wt-plain" "$c/wt-dangling" "$c/wt-noback" "$c/wt-dirgit/.git" "$c/wt-linkgit" \
           "$c/wt-sub" "$TEST_TMPDIR/fake/worktrees/x" "$c/wt-copied"
  echo "gitdir: $TEST_TMPDIR/nowhere/worktrees/x" > "$c/wt-dangling/.git"
  echo "gitdir: $TEST_TMPDIR/fake/worktrees/x" > "$c/wt-noback/.git"      # back-pointer elsewhere
  echo "$TEST_TMPDIR/elsewhere/.git" > "$TEST_TMPDIR/fake/worktrees/x/gitdir"
  ln -s "$c/wt-foo/.git" "$c/wt-linkgit/.git"                           # .git is a symlink
  echo "gitdir: $REPO/.git/modules/sub" > "$c/wt-sub/.git"              # not a worktrees/ dir
  cp "$c/wt-foo/.git" "$c/wt-copied/.git"                               # wt-foo's pointer, wrong dir
  assert_file_decisions ask sess1 \
    "$c/wt-plain/chapter3.md" "$c/wt-missing/chapter3.md" "$c/wt-dangling/chapter3.md" \
    "$c/wt-noback/chapter3.md" "$c/wt-dirgit/chapter3.md" "$c/wt-linkgit/chapter3.md" \
    "$c/wt-sub/chapter3.md" "$c/wt-copied/chapter3.md" "$c/worktrees/chapter3.md" \
    "$c/wt-foo" "$c/worktrees/foo"
}

@test "worktree taint: an unreadable .git file fails closed (keeps the ask)" {
  [ "$(id -u)" -ne 0 ] || skip "root reads a mode-000 file"
  worktree_layout
  taint sess1
  chmod 000 "$REPO/.claude/wt-foo/.git"
  assert_file_decisions ask sess1 "$REPO/.claude/wt-foo/chapter3.md"
  chmod 644 "$REPO/.claude/wt-foo/.git"
  assert_file_decisions defer sess1 "$REPO/.claude/wt-foo/chapter3.md"
}

@test "worktree taint: a worktree in or holding the config dir keeps the ask" {
  worktree_layout
  git -C "$REPO" worktree add -q "$HOME/.claude/wt-home" -b wt-home
  taint sess1
  assert_file_decisions ask sess1 "$HOME/.claude/wt-home/chapter3.md"
  # CLAUDE_CONFIG_DIR inside a worktree: that worktree is not judged relative to its root.
  mkdir -p "$REPO/.claude/wt-foo/cfg"
  CLAUDE_CONFIG_DIR="$REPO/.claude/wt-foo/cfg" assert_file_decisions ask sess1 "$REPO/.claude/wt-foo/chapter3.md"
  assert_file_decisions defer sess1 "$REPO/.claude/wt-foo/chapter3.md"
}

@test "worktree taint: case variants of the root shape are not worktree roots" {
  worktree_layout
  git -C "$REPO" worktree add -q "$REPO/.Claude/wt-c" -b wt-c
  git -C "$REPO" worktree add -q "$REPO/.claude/WT-c" -b wt-c2
  taint sess1
  assert_file_decisions ask sess1 "$REPO/.claude/WT-c/chapter3.md"
  # .Claude is no root, and SOFT matches `.claude` case-folded: it still asks.
  assert_file_decisions ask sess1 "$REPO/.Claude/wt-c/chapter3.md"
}

@test "worktree taint: relative gitdir pointers (worktree.useRelativePaths) are verified" {
  worktree_layout
  local g
  g=$(sed 's/^gitdir: //' "$REPO/.claude/wt-foo/.git")
  echo "gitdir: ../../.git/worktrees/$(basename "$g")" > "$REPO/.claude/wt-foo/.git"
  echo "../../../.claude/wt-foo/.git" > "$g/gitdir"
  [ "$(git -C "$REPO/.claude/wt-foo" rev-parse --show-toplevel)" = "$REPO/.claude/wt-foo" ]
  taint sess1
  assert_file_decisions defer sess1 "$REPO/.claude/wt-foo/chapter3.md"
  assert_file_decisions ask sess1 "$REPO/.claude/wt-foo/CLAUDE.md"
}

@test "worktree taint: Write, MultiEdit and the path key follow the same rule" {
  worktree_layout
  taint sess1
  guard "$(file_payload Write "$REPO/.claude/wt-foo/chapter3.md" sess1)"
  assert_defer
  guard "$(jq -n -c --arg f "$REPO/.claude/worktrees/foo/chapter3.md" \
    '{"session_id":"sess1","tool_name":"MultiEdit","tool_input":{"path":$f}}')"
  assert_defer
  guard "$(file_payload MultiEdit "$REPO/.claude/wt-foo/.claude/settings.json" sess1)"
  assert_decision ask
}

@test "worktree taint: Bash in a worktree is unchanged (still denied on policy names)" {
  worktree_layout
  taint sess1
  guard "$(bash_payload "echo x > $REPO/.claude/wt-foo/hooks/x.sh" sess1)"
  assert_decision deny
  guard "$(bash_payload "echo x > $REPO/.claude/wt-foo/CLAUDE.md" sess1)"
  assert_decision deny
}

# --- Q-050 [2]: resolve-only HARD is denied, including per-file hook links ---
# The README's bare-host layout: ~/.claude/CLAUDE.md links to the checkout's
# global-instructions/CLAUDE.md, and ~/.claude/hooks/ is a REAL dir holding
# some hooks as per-file symlinks into the checkout and others as copies (N12).

bare_host_layout() {
  CHECKOUT="$TEST_TMPDIR/claude-workflows"
  mkdir -p "$CHECKOUT/global-instructions" "$CHECKOUT/hooks" "$HOME/.claude/hooks"
  echo '# global' > "$CHECKOUT/global-instructions/CLAUDE.md"
  echo 'x' > "$CHECKOUT/hooks/linked.sh"
  echo 'x' > "$CHECKOUT/hooks/copied.py"
  echo 'x' > "$CHECKOUT/hooks/unwired.sh"
  ln -s "$CHECKOUT/global-instructions/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  ln -s "$CHECKOUT/hooks/linked.sh" "$HOME/.claude/hooks/linked.sh"
  cp "$CHECKOUT/hooks/copied.py" "$HOME/.claude/hooks/copied.py"
}

@test "Q-050: the checkout CLAUDE.md behind a symlinked ~/.claude/CLAUDE.md is denied" {
  bare_host_layout
  local s
  for s in clean sess1; do
    [ "$s" = sess1 ] && taint sess1
    guard "$(file_payload Edit "$CHECKOUT/global-instructions/CLAUDE.md" "$s")"
    assert_decision deny
  done
}

@test "Q-050 / N12: a per-file symlinked hook's checkout target is denied" {
  bare_host_layout
  local s t
  for s in clean sess1; do
    [ "$s" = sess1 ] && taint sess1
    for t in Edit Write MultiEdit; do
      guard "$(file_payload "$t" "$CHECKOUT/hooks/linked.sh" "$s")"
      [ "$status" -eq 0 ] && [ "$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$output")" = deny ] \
        || { echo "not denied ($s, $t) -> $output"; return 1; }
    done
  done
  guard "$(file_payload Edit "$CHECKOUT/x/../hooks/linked.sh")"
  assert_decision deny
}

@test "Q-050: a repo hook file with no link into ~/.claude/hooks is not denied" {
  bare_host_layout
  guard "$(file_payload Edit "$CHECKOUT/hooks/unwired.sh")"
  assert_defer
  # A copy installed into ~/.claude/hooks does not tie the checkout file to it.
  guard "$(file_payload Edit "$CHECKOUT/hooks/copied.py")"
  assert_defer
  taint sess1
  guard "$(file_payload Edit "$CHECKOUT/hooks/copied.py" sess1)"
  assert_defer
}

@test "Q-050: with a regular-file ~/.claude/CLAUDE.md copy, the checkout file is not denied" {
  bare_host_layout
  rm "$HOME/.claude/CLAUDE.md"
  cp "$CHECKOUT/global-instructions/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  guard "$(file_payload Edit "$CHECKOUT/global-instructions/CLAUDE.md")"
  assert_defer
  # It is still a CLAUDE.md, so a tainted session gets the SOFT ask.
  taint sess1
  guard "$(file_payload Edit "$CHECKOUT/global-instructions/CLAUDE.md" sess1)"
  assert_decision ask
}

@test "N15: the resolved-path deny reason does not send the user to a denied path" {
  bare_host_layout
  guard "$(file_payload Edit "$CHECKOUT/hooks/linked.sh")"
  assert_decision deny
  local reason
  reason=$(jq -r '.hookSpecificOutput.permissionDecisionReason' <<<"$output")
  [[ "$reason" != *"~/.claude path"* ]] || { echo "$reason"; return 1; }
  [[ "$reason" == *"outside Claude"* ]] || { echo "$reason"; return 1; }
  guard "$(bash_payload "echo x > $SETTINGS")"
  reason=$(jq -r '.hookSpecificOutput.permissionDecisionReason' <<<"$output")
  [[ "$reason" == *"outside Claude"* ]] || { echo "$reason"; return 1; }
}

@test "A5: the file-tool deny reason says Bash is not the way round it" {
  bare_host_layout
  guard "$(file_payload Edit "$CHECKOUT/hooks/linked.sh")"
  assert_decision deny
  local reason
  reason=$(jq -r '.hookSpecificOutput.permissionDecisionReason' <<<"$output")
  [[ "$reason" == *"Bash"* ]] || { echo "$reason"; return 1; }
  [[ "$reason" == *"outside Claude"* ]] || { echo "$reason"; return 1; }
}

@test "A1/A2: the Bash deny reason fits project files and only suggests prose files" {
  # The same text fires for a project's own .claude/settings.json, which
  # Edit/Write can change, so it must not say Claude can't write it at all.
  guard "$(bash_payload "echo x > .claude/settings.json")"
  assert_decision deny
  local reason
  reason=$(jq -r '.hookSpecificOutput.permissionDecisionReason' <<<"$output")
  [[ "$reason" != *"Claude cannot write these"* ]] || { echo "$reason"; return 1; }
  [[ "$reason" == *"Edit or Write"* ]] || { echo "$reason"; return 1; }
  [[ "$reason" == *"outside Claude"* ]] || { echo "$reason"; return 1; }
  # A2: the file advice is for prose passed as data, never a file to run.
  [[ "$reason" == *"git commit -F"* && "$reason" == *"--body-file"* ]] || { echo "$reason"; return 1; }
  [[ "$reason" != *"pass the file instead"* ]] || { echo "$reason"; return 1; }
  [[ "$reason" != *"script"* && "$reason" != *" run "* ]] || { echo "$reason"; return 1; }
}

@test "C1: an unreadable ~/.claude/hooks entry does not stop the linked-hook scan" {
  [ "$(id -u)" -ne 0 ] || skip "root reads through chmod 000"
  bare_host_layout
  # Links into a mode-000 dir make is_dir() raise PermissionError. Several of
  # them, so directory order almost surely puts one before linked.sh.
  mkdir -p "$TEST_TMPDIR/locked/sub"
  local i
  for i in 0 1 2 3 4 5 6 7 8 9 a b c d e f; do
    ln -s "$TEST_TMPDIR/locked/sub" "$HOME/.claude/hooks/$i-bad"
  done
  chmod 000 "$TEST_TMPDIR/locked"
  guard "$(file_payload Edit "$CHECKOUT/hooks/linked.sh")"
  chmod 755 "$TEST_TMPDIR/locked"
  assert_decision deny
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
