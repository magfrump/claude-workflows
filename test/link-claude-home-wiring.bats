#!/usr/bin/env bats
# Tests for the hook-wiring merge in devcontainer-config/link-claude-home.sh
# (decision 023).
#
# The merge runs unattended at every container start against a settings.json the
# agent can also edit, so the properties that matter are the destructive ones:
#
#   1. A fresh (or absent) settings.json gets every wired hook
#   2. Re-running never duplicates entries — the merge is exactly idempotent
#   3. Unrelated settings keys and foreign hook entries survive untouched
#   4. {{CLAUDE_DIR}} resolves to the actual config dir, and _comment never lands
#      in settings.json
#   5. An unparseable settings.json is refused, not overwritten (it may hold real
#      user settings a crash left mangled)
#   6. CC_SKIP_HOOK_WIRING=1 leaves the file completely alone
#   7. Every command in wiring.json points at a hook that actually exists
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
  jq '[to_entries[] | select(.key | startswith("_") | not)
       | .value[].hooks[]] | length' "$WIRING"
}

settings_count() {
  jq '[.hooks[][]?.hooks[]?] | length' "$DEST/settings.json"
}

@test "fresh volume with no settings.json gets every wired hook" {
  run bash "$LINKER"
  [ "$status" -eq 0 ]
  [ -f "$DEST/settings.json" ]
  [ "$(settings_count)" -eq "$(wired_count)" ]
}

@test "merge is idempotent across repeated container starts" {
  bash "$LINKER"
  local first
  first=$(cat "$DEST/settings.json")
  bash "$LINKER"
  bash "$LINKER"
  [ "$(cat "$DEST/settings.json")" = "$first" ]
  [ "$(settings_count)" -eq "$(wired_count)" ]
}

@test "unrelated settings keys and foreign hooks survive the merge" {
  cat > "$DEST/settings.json" <<'EOF'
{
  "theme": "dark",
  "effortLevel": "medium",
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "bash /user/own.sh" } ] }
    ],
    "Stop": [ { "hooks": [ { "type": "command", "command": "echo done" } ] } ]
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
}

@test "{{CLAUDE_DIR}} is substituted and _comment is stripped" {
  bash "$LINKER"
  run grep -c 'CLAUDE_DIR' "$DEST/settings.json"
  [ "$status" -ne 0 ]          # grep -c exits 1 when there are no matches
  run grep -c '_comment' "$DEST/settings.json"
  [ "$status" -ne 0 ]
  # Every wired command resolves under the real config dir.
  [ "$(jq --arg d "$DEST" '[.hooks[][]?.hooks[]? | select(.command | contains($d))] | length' "$DEST/settings.json")" -eq "$(wired_count)" ]
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
  done < <(jq -r '[to_entries[] | select(.key | startswith("_") | not)
                   | .value[].hooks[].command] | .[]' "$WIRING" \
            | sed -E 's#.*/hooks/##')
  [ "$missing" -eq 0 ]
}

@test "wiring.json declares only known hook event names" {
  run jq -r '[to_entries[] | select(.key | startswith("_") | not) | .key]
             - ["PreToolUse","PostToolUse","UserPromptSubmit","Stop","SubagentStop","Notification","SessionStart","SessionEnd","PreCompact"]
             | join(",")' "$WIRING"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
