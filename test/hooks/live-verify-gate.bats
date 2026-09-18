#!/usr/bin/env bats
# @category fast
# Tests for the PreToolUse live-verification gate (hooks/live-verify-gate.sh).
#
# The gate blocks a `git commit` that carries a cc-isolated enforcement file
# (what the trust manifest hashes) unless the commit message names its live
# verification status with a `Live-verified:` trailer. Everything else — other
# commands, other files, malformed input — must be a silent exit 0.
#
# Two things beyond that behaviour are pinned here (Q-009):
#
#   1. The narrowing. A diff confined to comment and blank lines is let through
#      without a trailer, because it cannot change what the container may reach.
#      The rule is "no change to any NON-COMMENT line", NOT "no change to
#      hostnames" — commenting OUT a live allowlist entry deletes a non-comment
#      line and must still block. The tests below pin both directions, plus the
#      structural cases (a new file whose text is all comments still blocks).
#   2. Installed-ness. Eleven tests exercising the script say nothing about
#      whether it is wired into the live settings.json, which is how it can fall
#      out again silently. The last test reads (never writes) the live settings.

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

@test "a comment-only edit to an egress list passes without a trailer" {
  printf '# a note about why this list is short\n' >> devcontainer-config/egress/base.txt
  git add devcontainer-config/egress/base.txt
  run bash "$HOOK" <<< "$(payload 'git commit -m "docs: annotate the egress list"')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "a diff that changes a comment AND a real line still blocks" {
  printf '# a note\nexample.com\n' >> devcontainer-config/egress/base.txt
  git add devcontainer-config/egress/base.txt
  run bash "$HOOK" <<< "$(payload 'git commit -m "feat: widen egress"')"
  [ "$status" -eq 2 ]
}

@test "commenting OUT an existing allowlist line still blocks" {
  # The removed line is non-comment, which is the whole point of the rule being
  # "no change to any non-comment line" rather than "no change to hostnames".
  printf '#base\n' > devcontainer-config/egress/base.txt
  git add devcontainer-config/egress/base.txt
  run bash "$HOOK" <<< "$(payload 'git commit -m "chore: disable an entry"')"
  [ "$status" -eq 2 ]
}

@test "a pure whitespace or blank-line change passes" {
  printf '\n\n' >> devcontainer-config/egress/base.txt
  git add devcontainer-config/egress/base.txt
  run bash "$HOOK" <<< "$(payload 'git commit -m "style: spacing"')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "adding a NEW enforcement file whose content is all comments still blocks" {
  printf '# nothing but comments, for now\n' > devcontainer-config/egress/python.txt
  git add devcontainer-config/egress/python.txt
  run bash "$HOOK" <<< "$(payload 'git commit -m "feat: add a python egress list"')"
  [ "$status" -eq 2 ]
}

@test "the -a path honors the narrowing too" {
  printf '# a note\n' >> devcontainer-config/egress/base.txt    # NOT staged
  run bash "$HOOK" <<< "$(payload 'git commit -am "docs: annotate"')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  printf 'example.com\n' >> devcontainer-config/egress/base.txt # now substantive
  run bash "$HOOK" <<< "$(payload 'git commit -am "feat: widen"')"
  [ "$status" -eq 2 ]
}

@test "a // comment-only change to devcontainer.json passes" {
  printf '{\n  "name": "cc-isolated"\n}\n' > devcontainer-config/devcontainer.json
  git add devcontainer-config/devcontainer.json
  git -C "$REPO" -c commit.gpgsign=false commit -qm "add devcontainer.json"
  printf '{\n  // why this name: it is what cc-isolated --list prints\n  "name": "cc-isolated"\n}\n' \
    > devcontainer-config/devcontainer.json
  git add devcontainer-config/devcontainer.json
  run bash "$HOOK" <<< "$(payload 'git commit -m "docs: explain the name"')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "the gate is wired into the live settings.json" {
  # Eleven behaviour tests above say nothing about whether the hook is actually
  # installed — A7's still-true half. This one reads (never writes) the live
  # settings file so a silent uninstall turns the suite red.
  local wiring="$BATS_TEST_DIRNAME/../../hooks/wiring.json"
  local config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  local settings="$config_dir/settings.json"

  command -v jq >/dev/null 2>&1 || skip "jq not installed — cannot read wiring.json or settings.json"
  [ -f "$wiring" ] || skip "hooks/wiring.json not found — nothing to compare against"
  [ -f "$settings" ] || skip "no settings.json at $settings — not a wired container"

  # Resolve {{CLAUDE_DIR}} exactly as scripts/health-check.sh's check_hook_wiring does.
  local want
  want="$(jq -r '.hooks[][].hooks[].command' "$wiring" \
          | sed "s#{{CLAUDE_DIR}}#$config_dir#g" \
          | grep -F 'live-verify-gate.sh')"
  [ -n "$want" ] || { echo "wiring.json no longer declares live-verify-gate.sh"; return 1; }

  jq -e --arg c "$want" \
     '[.hooks[]?[]?.hooks[]? | select(.command == $c)] | length > 0' \
     "$settings" >/dev/null 2>&1 \
     || { echo "not wired in $settings; expected command: $want"; return 1; }
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
