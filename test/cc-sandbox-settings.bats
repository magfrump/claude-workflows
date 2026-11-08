#!/usr/bin/env bats
# @category fast
# devcontainer-config/cc-sandbox-settings.sh and its template managed-settings.json
# (Q-125): the build-time renderer of Claude Code's managed sandbox settings, fed
# by init-firewall.sh --print-entries so the sandbox and the firewall share one
# allowlist.

setup() {
  CFG="$BATS_TEST_DIRNAME/../devcontainer-config"
  RENDER="$CFG/cc-sandbox-settings.sh"
  TEMPLATE="$CFG/managed-settings.json"
  FW="$CFG/init-firewall.sh"
  TEST_TMPDIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Entries for one profile, exactly as the Dockerfile tail produces them.
entries_for() {
  printf '%s\n' "$1" > "$TEST_TMPDIR/profile"
  CC_EGRESS_DIR="$CFG/egress" CC_EGRESS_PROFILE_FILE="$TEST_TMPDIR/profile" bash "$FW" --print-entries
}

@test "renders the template with allowedDomains filled and _comment dropped" {
  run bash -c "printf 'a.example.com\t443\n' | '$RENDER' '$TEMPLATE'"
  [ "$status" -eq 0 ]
  [ "$(jq -c '.sandbox.network.allowedDomains' <<< "$output")" = \
    '["*.github.com","*.githubusercontent.com","a.example.com","github.com","githubusercontent.com"]' ]
  [ "$(jq 'has("_comment")' <<< "$output")" = false ]
  # Everything but allowedDomains is the template, unchanged.
  [ "$(jq -S -c 'del(.sandbox.network.allowedDomains)' <<< "$output")" = \
    "$(jq -S -c 'del(._comment, .sandbox.network.allowedDomains)' "$TEMPLATE")" ]
}

@test "a zone becomes *.zone, ports are dropped, duplicates collapse" {
  run bash -c "printf '.frame.example.com\t443\nb.example.com\t22\nb.example.com\t443\n' | '$RENDER' '$TEMPLATE'"
  [ "$status" -eq 0 ]
  domains="$(jq -c '.sandbox.network.allowedDomains' <<< "$output")"
  echo "$domains"
  [[ "$domains" == *'"*.frame.example.com"'* ]]
  [ "$(jq '[.[] | select(. == "b.example.com")] | length' <<< "$domains")" -eq 1 ]
  [ "$(jq '[.[] | select(contains(":"))] | length' <<< "$domains")" -eq 0 ]
}

@test "an empty allowlist fails with nothing on stdout" {
  run bash -c "'$RENDER' '$TEMPLATE' < /dev/null 2>/dev/null"
  [ "$status" -ne 0 ]
  [ -z "$output" ]
}

@test "an entry that is not a hostname or zone fails with nothing on stdout" {
  for bad in 'evil.com/x' '*.example.com' '.two.labels' 'com' 'a.example.com"x'; do
    run bash -c "printf '%s\t443\n' '$bad' | '$RENDER' '$TEMPLATE' 2>/dev/null"
    echo "entry: $bad status: $status"
    [ "$status" -ne 0 ]
    [ -z "$output" ]
  done
}

@test "a template with no sandbox.network fails" {
  echo '{"sandbox":{}}' > "$TEST_TMPDIR/t.json"
  run bash -c "printf 'a.example.com\t443\n' | '$RENDER' '$TEST_TMPDIR/t.json'"
  [ "$status" -ne 0 ]
}

@test "every shipped egress profile renders, admitting exactly its entries plus GitHub" {
  for f in "$CFG"/egress/*.txt; do
    p="$(basename "$f" .txt)"
    entries="$(entries_for "$p")"
    run bash -c "printf '%s\n' \"\$1\" | '$RENDER' '$TEMPLATE'" _ "$entries"
    echo "profile: $p status: $status"
    [ "$status" -eq 0 ]
    want="$( { cut -f1 <<< "$entries" | sed 's/^\./*./'; printf '%s\n' github.com '*.github.com' githubusercontent.com '*.githubusercontent.com'; } | LC_ALL=C sort -u | jq -R . | jq -s -c .)"
    [ "$(jq -c '.sandbox.network.allowedDomains' <<< "$output")" = "$want" ]
  done
}

@test "the template's hardening switches are set as Q-125 specifies" {
  t="$(jq -c '.sandbox' "$TEMPLATE")"
  [ "$(jq '.enabled' <<< "$t")" = true ]
  [ "$(jq '.failIfUnavailable' <<< "$t")" = true ]
  [ "$(jq '.allowUnsandboxedCommands' <<< "$t")" = false ]
  # Decided explicitly, not left to the default (true).
  [ "$(jq '.autoAllowBashIfSandboxed' <<< "$t")" = false ]
  # Stated explicitly: managed settings only win on keys they set, so an omitted
  # switch could be flipped weaker by a user or project settings file.
  [ "$(jq '.enableWeakerNestedSandbox' <<< "$t")" = false ]
  [ "$(jq '.filesystem.disabled' <<< "$t")" = false ]
  [ "$(jq '.network.allowAllUnixSockets' <<< "$t")" = false ]
  # Things that run unsandboxed (hooks, git, the next session) must not be
  # sandbox-writable: the PATH-first elan bin dir, the web-taint state, and the
  # project files that wire hooks or execute on git.
  # shellcheck disable=SC2088  # the literal `~/` is the settings string Claude Code expands.
  for p in '~/.elan/bin' /tmp/cc-web-taint /workspace/.claude/settings.json \
           /workspace/.claude/settings.local.json /workspace/.mcp.json \
           /workspace/.git/config /workspace/.git/hooks; do
    echo "denyWrite must hold $p"
    [ "$(jq --arg p "$p" '.filesystem.denyWrite | index($p) != null' <<< "$t")" = true ]
  done
  [ "$(jq '[.filesystem.allowWrite[] | select(startswith("~/.claude"))] | length' <<< "$t")" -eq 0 ]
  [ "$(jq -r '.permissions.deny | index("Read(//home/node/.claude/.credentials.json)") != null' "$TEMPLATE")" = true ]
  [ "$(jq '.network.allowManagedDomainsOnly' <<< "$t")" = true ]
  [ "$(jq '.filesystem.denyRead | index("~/.claude/.credentials.json") != null' <<< "$t")" = true ]
  [ "$(jq '.filesystem.denyWrite | index("~/.claude/settings.json") != null' <<< "$t")" = true ]
  [ "$(jq '.filesystem.denyWrite | index("~/.claude/settings.local.json") != null' <<< "$t")" = true ]
  # Nothing re-opens the credential or ~/.claude wholesale.
  [ "$(jq '[.filesystem.allowRead // [] | .[] | select(test("credentials"))] | length' <<< "$t")" -eq 0 ]
  [ "$(jq '[.filesystem.allowWrite[] | select(. == "~/.claude" or . == "~" or . == "/")] | length' <<< "$t")" -eq 0 ]
}

@test "the Dockerfile renders managed settings in the per-project tail, root-owned" {
  df="$CFG/Dockerfile"
  tail_start="$(grep -n '^ARG CC_EGRESS_PROFILE' "$df" | cut -d: -f1)"
  render="$(grep -n 'cc-sandbox-settings.sh /usr/local/share/cc-sandbox/managed-settings.json' "$df" | cut -d: -f1)"
  [ -n "$tail_start" ] && [ -n "$render" ]
  [ "$render" -gt "$tail_start" ]
  grep -qF 'chown -R root:root /etc/claude-code' "$df"
  grep -qF 'chmod 0444 /etc/claude-code/managed-settings.json' "$df"
  grep -qE '^\s+bubblewrap \\$' "$df"
  grep -qE '^\s+socat \\$' "$df"
}
