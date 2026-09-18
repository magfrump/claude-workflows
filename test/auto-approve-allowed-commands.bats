#!/usr/bin/env bats
# @category fast
# Regression tests for hooks/auto-approve-allowed-commands.sh prefix loading.
#
# Usage: bats test/auto-approve-allowed-commands.bats

HOOK="$BATS_TEST_DIRNAME/../hooks/auto-approve-allowed-commands.sh"

setup() {
  TEST_TMPDIR=$(mktemp -d)
  # Fake $HOME so the hook reads a controlled global settings.json.
  export HOME="$TEST_TMPDIR/home"
  mkdir -p "$HOME/.claude"
  # Fake project: a git repo with its own .claude/settings.json.
  PROJECT="$TEST_TMPDIR/project"
  mkdir -p "$PROJECT/.claude"
  git -C "$PROJECT" init -q
  cd "$PROJECT" || return 1
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

run_hook() {
  printf '%s' "$1" | jq -Rs '{tool_input:{command:.}}' | bash "$HOOK"
}

@test "project allow entries are honored when the global settings.json has only a deny list" {
  # This is the production shape: global file carries permissions.deny but no
  # permissions.allow. Before the fix, grep's exit 1 on the empty global list
  # aborted the loader (set -eo pipefail) before the project file was read.
  echo '{"permissions":{"deny":["Read(~/.npmrc)"]}}' > "$HOME/.claude/settings.json"
  echo '{"permissions":{"allow":["Bash(bats test:*)"]}}' > "$PROJECT/.claude/settings.json"

  run run_hook 'bats test/foo.bats'
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision":"allow"'* ]]
}

@test "project allow entries are honored when the global settings.json has no permissions key at all" {
  echo '{"model":"x"}' > "$HOME/.claude/settings.json"
  echo '{"permissions":{"allow":["Bash(bats test:*)"]}}' > "$PROJECT/.claude/settings.json"

  run run_hook 'bats test/foo.bats'
  [ "$status" -eq 0 ]
  [[ "$output" == *'"permissionDecision":"allow"'* ]]
}

@test "a command outside every allow list still falls through to the normal prompt" {
  echo '{"permissions":{"deny":["Read(~/.npmrc)"]}}' > "$HOME/.claude/settings.json"
  echo '{"permissions":{"allow":["Bash(bats test:*)"]}}' > "$PROJECT/.claude/settings.json"

  run run_hook 'python3 -c "print(1)"'
  [ "$status" -eq 0 ]
  [[ "$output" != *'"permissionDecision":"allow"'* ]]
}

@test "a pipeline is allowed only when every component is allow-listed" {
  echo '{"permissions":{"deny":[]}}' > "$HOME/.claude/settings.json"
  echo '{"permissions":{"allow":["Bash(bats test:*)","Bash(head:*)"]}}' > "$PROJECT/.claude/settings.json"

  run run_hook 'bats test/foo.bats | head -5'
  [[ "$output" == *'"permissionDecision":"allow"'* ]]

  run run_hook 'bats test/foo.bats | python3 -c "pass"'
  [[ "$output" != *'"permissionDecision":"allow"'* ]]
}

# --- Parse failures fail closed ---
# bash runs a multi-line script one complete command at a time, so the lines
# before a syntax error still execute. An input the parser cannot read must
# fall through to the normal prompt, never be allowed as "no commands found".

@test "a command the parser cannot read falls through instead of being allowed" {
  echo '{"permissions":{"deny":[]}}' > "$HOME/.claude/settings.json"
  echo '{"permissions":{"allow":["Bash(ls:*)"]}}' > "$PROJECT/.claude/settings.json"

  run run_hook $'touch should-not-run\nls ('
  [ "$status" -eq 0 ]
  [[ "$output" != *'"permissionDecision":"allow"'* ]]
}

@test "an unparseable bash -c inner script falls through instead of being allowed" {
  echo '{"permissions":{"deny":[]}}' > "$HOME/.claude/settings.json"
  echo '{"permissions":{"allow":["Bash(ls:*)"]}}' > "$PROJECT/.claude/settings.json"

  run run_hook $'bash -c "touch should-not-run\nls ("'
  [ "$status" -eq 0 ]
  [[ "$output" != *'"permissionDecision":"allow"'* ]]
}

@test "a parseable allow-listed command is still allowed after the fail-closed change" {
  echo '{"permissions":{"deny":[]}}' > "$HOME/.claude/settings.json"
  echo '{"permissions":{"allow":["Bash(ls:*)"]}}' > "$PROJECT/.claude/settings.json"

  run run_hook $'ls -la\nls /tmp'
  [[ "$output" == *'"permissionDecision":"allow"'* ]]
}
