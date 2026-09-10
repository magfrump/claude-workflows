#!/usr/bin/env bats
# @category fast
# Tests for the PreToolUse live-verification gate (hooks/live-verify-gate.sh).
#
# The gate blocks a `git commit` that carries a cc-isolated enforcement file
# (what the trust manifest hashes) unless the commit message names its live
# verification status with a `Live-verified:` trailer. Everything else — other
# commands, other files, malformed input — must be a silent exit 0.

load ../lib/hermetic-env

pin_hermetic_locale

HOOK="$BATS_TEST_DIRNAME/../../hooks/live-verify-gate.sh"

setup() {
  TEST_TMPDIR=$(mktemp -d)
  REPO="$TEST_TMPDIR/repo"
  mkdir -p "$REPO/devcontainer-config/egress" "$REPO/src"
  git -C "$REPO" init -q
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name t
  echo base > "$REPO/devcontainer-config/egress/base.txt"
  echo code > "$REPO/src/a.txt"
  git -C "$REPO" add -A
  git -C "$REPO" -c commit.gpgsign=false commit -qm init
  cd "$REPO" || exit 1
}

teardown() {
  cd / && rm -rf "$TEST_TMPDIR"
}

payload() {
  jq -n -c --arg c "$1" '{"tool_name":"Bash","tool_input":{"command":$c}}'
}

stage_enforcement() {
  echo widened >> devcontainer-config/egress/base.txt
  git add devcontainer-config/egress/base.txt
}

@test "blocks a commit of an enforcement file with no Live-verified trailer" {
  stage_enforcement
  run bash "$HOOK" <<< "$(payload 'git commit -m "feat: widen egress"')"
  [ "$status" -eq 2 ]
  [[ "$output" == *"Live-verified:"* ]]
  [[ "$output" == *"devcontainer-config/egress/base.txt"* ]]
}

@test "passes when the -m message carries the trailer" {
  stage_enforcement
  run bash "$HOOK" <<< "$(payload 'git commit -m "feat: widen egress" -m "Live-verified: 3f2a9c0e1b7d4a6f"')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "passes when the trailer is an explicit 'no' with a reason" {
  stage_enforcement
  run bash "$HOOK" <<< "$(payload 'git commit -m "fix: rule order

Live-verified: no — sandbox has no Docker; run cc-isolated --probe-only after install.sh"')"
  [ "$status" -eq 0 ]
}

@test "reads the trailer from a -F message file" {
  stage_enforcement
  printf 'fix: rules\n\nLive-verified: 3f2a9c0e1b7d4a6f\n' > "$TEST_TMPDIR/msg"
  run bash "$HOOK" <<< "$(payload "git commit -F $TEST_TMPDIR/msg")"
  [ "$status" -eq 0 ]
  run bash "$HOOK" <<< "$(payload "git commit --file=$TEST_TMPDIR/msg")"
  [ "$status" -eq 0 ]
}

@test "blocks when the -F message file lacks the trailer" {
  stage_enforcement
  printf 'fix: rules\n' > "$TEST_TMPDIR/msg"
  run bash "$HOOK" <<< "$(payload "git commit -F $TEST_TMPDIR/msg")"
  [ "$status" -eq 2 ]
}

@test "ignores commits that touch no enforcement file" {
  echo more >> src/a.txt
  git add src/a.txt
  run bash "$HOOK" <<< "$(payload 'git commit -m "docs: unrelated"')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "counts unstaged tracked changes when -a is given" {
  echo widened >> devcontainer-config/egress/base.txt   # NOT staged
  run bash "$HOOK" <<< "$(payload 'git commit -m "x"')"
  [ "$status" -eq 0 ]
  run bash "$HOOK" <<< "$(payload 'git commit -am "x"')"
  [ "$status" -eq 2 ]
}

@test "every manifest-hashed file is in the enforcement set" {
  # Keep the hook's regex in step with cc-isolated.sh's enforcement_files().
  local f
  for f in Dockerfile devcontainer.json init-firewall.sh cc-sni-proxy.py link-claude-home.sh cc-isolated.sh egress/python.txt; do
    mkdir -p "$(dirname "devcontainer-config/$f")"
    echo x > "devcontainer-config/$f"
    git add "devcontainer-config/$f"
    run bash "$HOOK" <<< "$(payload 'git commit -m "x"')"
    [ "$status" -eq 2 ] || { echo "not gated: $f"; return 1; }
    git reset -q "devcontainer-config/$f"
    rm -f "devcontainer-config/$f"
  done
}

@test "ignores non-commit git commands and non-git commands" {
  stage_enforcement
  run bash "$HOOK" <<< "$(payload 'git status')"
  [ "$status" -eq 0 ]
  run bash "$HOOK" <<< "$(payload 'git diff --cached')"
  [ "$status" -eq 0 ]
  run bash "$HOOK" <<< "$(payload 'echo commit')"
  [ "$status" -eq 0 ]
}

@test "leaves an --amend --no-edit alone" {
  stage_enforcement
  run bash "$HOOK" <<< "$(payload 'git commit --amend --no-edit')"
  [ "$status" -eq 0 ]
}

@test "malformed input, missing command, and the disable switch all exit 0" {
  stage_enforcement
  run bash "$HOOK" <<< 'not json'
  [ "$status" -eq 0 ]
  run bash "$HOOK" <<< '{"tool_name":"Bash","tool_input":{}}'
  [ "$status" -eq 0 ]
  CC_LIVE_VERIFY_GATE_DISABLE=1 run bash "$HOOK" <<< "$(payload 'git commit -m x')"
  [ "$status" -eq 0 ]
}
