#!/usr/bin/env bats
# Tests for the settings-wiring merge in devcontainer-config/link-claude-home.sh
# (decision 023, and amendment B which added the permissions block).
#
# The merge runs unattended at every container start against a settings.json the
# agent can also edit, so the properties that matter are the destructive ones:
#
#   1. A fresh (or absent) settings.json gets every wired hook and deny rule
#   2. Re-running never duplicates entries — the merge is exactly idempotent
#   3. Unrelated settings keys, foreign hook entries, and the user's own
#      permission rules survive untouched
#   4. {{CLAUDE_DIR}} resolves to the actual config dir, and _comment never lands
#      in settings.json
#   5. An unparseable settings.json is refused, not overwritten (it may hold real
#      user settings a crash left mangled)
#   6. CC_SKIP_HOOK_WIRING=1 leaves the file completely alone
#   7. Every command in wiring.json points at a hook that actually exists
#   8. The deny rules the guard hook's HARD tier depends on are actually wired —
#      without them that tier is a no-op for Edit/Write (amendment B)
#
# Exercises the repo's copies, not the installed ones, so the suite is hermetic.

LINKER="${LINK_CLAUDE_HOME:-$BATS_TEST_DIRNAME/../devcontainer-config/link-claude-home.sh}"
WIRING="${WIRING_JSON:-$BATS_TEST_DIRNAME/../hooks/wiring.json}"
REPO_ROOT="$BATS_TEST_DIRNAME/.."

setup() {
  TMP=$(mktemp -d)
  SRC="$TMP/src"
  DEST="$TMP/dest"
  mkdir -p "$SRC/hooks" "$DEST"
  cp "$WIRING" "$SRC/hooks/wiring.json"
  # The linker only symlinks entries that exist; stubs keep its output quiet
  # without pulling the real payload into the test.
  for d in skills workflows guides patterns scripts; do mkdir -p "$SRC/$d"; done
  touch "$SRC/CLAUDE.md"
  export CC_WORKFLOWS_DIR="$SRC" CLAUDE_CONFIG_DIR="$DEST"
  unset CC_SKIP_HOOK_WIRING
}

teardown() {
  rm -rf "$TMP"
}

# Total hook commands declared in wiring.json, for count assertions.
wired_count() {
  jq '[.hooks[][].hooks[]] | length' "$WIRING"
}

settings_count() {
  jq '[.hooks[][]?.hooks[]?] | length' "$DEST/settings.json"
}

# Total permission rules declared in wiring.json, across every mode.
wired_perm_count() {
  jq '[.permissions[][]] | length' "$WIRING"
}

settings_perm_count() {
  jq '[.permissions[]?[]?] | length' "$DEST/settings.json"
}

@test "fresh volume with no settings.json gets every wired hook and deny rule" {
  run bash "$LINKER"
  [ "$status" -eq 0 ]
  [ -f "$DEST/settings.json" ]
  [ "$(settings_count)" -eq "$(wired_count)" ]
  [ "$(settings_perm_count)" -eq "$(wired_perm_count)" ]
}

@test "merge is idempotent across repeated container starts" {
  bash "$LINKER"
  local first
  first=$(cat "$DEST/settings.json")
  bash "$LINKER"
  bash "$LINKER"
  [ "$(cat "$DEST/settings.json")" = "$first" ]
  [ "$(settings_count)" -eq "$(wired_count)" ]
  [ "$(settings_perm_count)" -eq "$(wired_perm_count)" ]
}

@test "unrelated settings keys, foreign hooks, and user permissions survive the merge" {
  cat > "$DEST/settings.json" <<'EOF'
{
  "theme": "dark",
  "effortLevel": "medium",
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "bash /user/own.sh" } ] }
    ],
    "Stop": [ { "hooks": [ { "type": "command", "command": "echo done" } ] } ]
  },
  "permissions": {
    "allow": [ "Bash(shellcheck:*)" ],
    "deny": [ "Read(~/.ssh/**)" ]
  }
}
EOF
  run bash "$LINKER"
  [ "$status" -eq 0 ]

  [ "$(jq -r .theme "$DEST/settings.json")" = "dark" ]
  [ "$(jq -r .effortLevel "$DEST/settings.json")" = "medium" ]
  # The user's own Bash hook and their Stop event are both still there.
  [ "$(jq '[.hooks.PreToolUse[].hooks[] | select(.command == "bash /user/own.sh")] | length' "$DEST/settings.json")" -eq 1 ]
  [ "$(jq '.hooks.Stop | length' "$DEST/settings.json")" -eq 1 ]
  # ...alongside ours.
  [ "$(settings_count)" -eq "$(( $(wired_count) + 2 ))" ]

  # We merge only the modes we declare: the user's allow list is untouched, and
  # their own deny entry survives alongside ours.
  [ "$(jq -r '.permissions.allow | join(",")' "$DEST/settings.json")" = "Bash(shellcheck:*)" ]
  [ "$(jq '[.permissions.deny[] | select(. == "Read(~/.ssh/**)")] | length' "$DEST/settings.json")" -eq 1 ]
  [ "$(settings_perm_count)" -eq "$(( $(wired_perm_count) + 2 ))" ]
}

@test "{{CLAUDE_DIR}} is substituted and _comment is stripped" {
  bash "$LINKER"
  run grep -c 'CLAUDE_DIR' "$DEST/settings.json"
  [ "$status" -ne 0 ]          # grep -c exits 1 when there are no matches
  run grep -c '_comment' "$DEST/settings.json"
  [ "$status" -ne 0 ]
  # Every wired command resolves under the real config dir.
  [ "$(jq --arg d "$DEST" '[.hooks[][]?.hooks[]? | select(.command | contains($d))] | length' "$DEST/settings.json")" -eq "$(wired_count)" ]
  # ...and so do the deny rules that name the config dir.
  [ "$(jq --arg d "$DEST" '[.permissions.deny[] | select(contains($d))] | length' "$DEST/settings.json")" \
    -eq "$(jq '[.permissions.deny[] | select(contains("{{CLAUDE_DIR}}"))] | length' "$WIRING")" ]
}

@test "an unparseable settings.json is refused, not overwritten" {
  printf '{not json' > "$DEST/settings.json"
  run bash "$LINKER"
  [ "$status" -eq 0 ]                                  # never aborts the start
  [ "$(cat "$DEST/settings.json")" = '{not json' ]     # left byte-identical
  [[ "$output" == *"not valid JSON"* ]]
}

@test "CC_SKIP_HOOK_WIRING=1 leaves settings.json untouched" {
  printf '{"theme":"light"}\n' > "$DEST/settings.json"
  CC_SKIP_HOOK_WIRING=1 run bash "$LINKER"
  [ "$status" -eq 0 ]
  [ "$(cat "$DEST/settings.json")" = '{"theme":"light"}' ]
}

@test "every command in wiring.json points at a hook that exists" {
  # Guards the failure mode decision 023 was written about: a wiring entry whose
  # target is missing is inert, and nothing else in the suite would notice.
  local missing=0 script
  while IFS= read -r script; do
    [ -e "$REPO_ROOT/hooks/$script" ] || { echo "missing hook: $script"; missing=1; }
  done < <(jq -r '[.hooks[][].hooks[].command] | .[]' "$WIRING" \
            | sed -E 's#.*/hooks/##')
  [ "$missing" -eq 0 ]
}

@test "wiring.json declares only known hook event names" {
  run jq -r '[.hooks | keys[]]
             - ["PreToolUse","PostToolUse","UserPromptSubmit","Stop","SubagentStop","Notification","SessionStart","SessionEnd","PreCompact"]
             | join(",")' "$WIRING"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "wiring.json declares only known permission modes" {
  run jq -r '[.permissions | keys[]] - ["allow","ask","deny"] | join(",")' "$WIRING"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "the deny rules the guard hook's HARD tier depends on are wired" {
  # guard-trusted-writes.py DEFERS on HARD paths for Edit/Write (a hook "ask"
  # would override permissions.deny — Claude Code issue #39344), so if these
  # rules go missing the guard silently stops protecting those paths via the
  # file tools and nothing else in the suite notices. Decision 023 amendment B.
  bash "$LINKER"
  local rule
  for rule in "Edit($DEST/settings*.json)" "Write($DEST/settings*.json)" \
              "Edit($DEST/hooks/**)" "Write($DEST/hooks/**)" \
              "Edit($DEST/CLAUDE.md)" "Write($DEST/CLAUDE.md)" \
              "Edit(~/CLAUDE.md)" "Write(~/CLAUDE.md)"; do
    [ "$(jq --arg r "$rule" '[.permissions.deny[] | select(. == $r)] | length' "$DEST/settings.json")" -eq 1 ] || {
      echo "missing deny rule: $rule"
      return 1
    }
  done
}
