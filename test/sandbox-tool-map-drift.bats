#!/usr/bin/env bats
# @category fast
# Guards H4 of docs/decisions/014-secure-tool-guidance-layers.md: the
# sandbox tool map (guides/sandbox-tool-map.md) must not silently drift
# from the live permission settings.
#
# The guide carries machine-readable marker lines:
#   allow-prefix: X  -> asserts Bash(X:*) IS in permissions.allow
#   deny-prefix: X   -> asserts Bash(X:*) is NOT in permissions.allow
# Both checks are exact-entry matches on the broad Bash(X:*) form, so
# narrower surviving entries (e.g. Bash(hyperfine --version:*)) don't
# count as the tool being allowed.
#
# Settings-dependent tests skip cleanly when ~/.claude/settings.json or
# jq is unavailable (other machines, CI). Override the settings path with
# CLAUDE_SETTINGS_FILE for fixture-based testing.
#
# The allow list lives only on the host (the repo ships no settings file
# with permissions.allow), so inside the sandbox the two drift checks
# always skip and only a host run constrains the guide. Set
# REQUIRE_LIVE_SETTINGS=1 on the host to turn those skips into failures,
# so a host run cannot report green without having compared anything.
# The fixture tests at the bottom prove each check can go red, so a skip
# is the only way the live checks pass without comparing.
#
# Usage: bats test/sandbox-tool-map-drift.bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/.."
  GUIDE="$REPO_ROOT/guides/sandbox-tool-map.md"
  SETTINGS="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"
}

# Skip (not fail) when the environment can't support a live comparison.
require_live_settings() {
  local why=""
  if ! command -v jq >/dev/null 2>&1; then
    why="jq not available"
  elif [ ! -f "$SETTINGS" ]; then
    why="no settings file at $SETTINGS"
  elif ! jq -e '.permissions.allow' "$SETTINGS" >/dev/null 2>&1; then
    why="settings file has no permissions.allow array"
  fi
  [ -z "$why" ] && return 0
  if [ "${REQUIRE_LIVE_SETTINGS:-}" = 1 ]; then
    echo "REQUIRE_LIVE_SETTINGS=1 but $why"
    return 1
  fi
  skip "$why"
}

# Exact-match lookup of Bash(<prefix>:*) in permissions.allow.
allow_entry_present() {
  local prefix="$1"
  jq -e --arg entry "Bash($prefix:*)" \
    '.permissions.allow | index($entry)' "$SETTINGS" >/dev/null
}

@test "guide exists and contains machine-readable drift markers" {
  [ -f "$GUIDE" ]
  local n_allow n_deny
  n_allow=$(grep -c '^allow-prefix: ' "$GUIDE" || true)
  n_deny=$(grep -c '^deny-prefix: ' "$GUIDE" || true)
  [ "$n_allow" -gt 0 ] || {
    echo "No allow-prefix markers found in $GUIDE"
    return 1
  }
  [ "$n_deny" -gt 0 ] || {
    echo "No deny-prefix markers found in $GUIDE"
    return 1
  }
}

check_allowed() {
  require_live_settings || return 1
  local missing="" checked=0 prefix
  while IFS= read -r prefix; do
    checked=$((checked + 1))
    if ! allow_entry_present "$prefix"; then
      missing+="  Bash($prefix:*)"$'\n'
    fi
  done < <(grep '^allow-prefix: ' "$GUIDE" | cut -d' ' -f2-)

  # Guard: ensure we actually found markers to check
  [ "$checked" -gt 0 ] || {
    echo "No allow-prefix markers found — check test setup"
    return 1
  }

  if [ -n "$missing" ]; then
    echo "Guide claims these are allowed, but settings lack them ($checked checked):"
    echo "$missing"
    echo "Fix: update guides/sandbox-tool-map.md (table + markers) to match settings."
    return 1
  fi
}

check_removed() {
  require_live_settings || return 1
  local present="" checked=0 prefix
  while IFS= read -r prefix; do
    checked=$((checked + 1))
    if allow_entry_present "$prefix"; then
      present+="  Bash($prefix:*)"$'\n'
    fi
  done < <(grep '^deny-prefix: ' "$GUIDE" | cut -d' ' -f2-)

  # Guard: ensure we actually found markers to check
  [ "$checked" -gt 0 ] || {
    echo "No deny-prefix markers found — check test setup"
    return 1
  }

  if [ -n "$present" ]; then
    echo "Guide claims these are removed, but settings allow them ($checked checked):"
    echo "$present"
    echo "Fix: update guides/sandbox-tool-map.md (table + markers) to match settings."
    return 1
  fi
}

@test "prefixes the guide claims allowed exist in live permissions.allow" {
  check_allowed
}

@test "prefixes the guide claims removed have no broad allow entry" {
  check_removed
}

# --- the checks are not blind: each goes red on a drifted fixture ---

# Build a settings fixture holding Bash(X:*) for every allow-prefix marker,
# plus any extra entries given as arguments.
write_fixture() {
  SETTINGS="$BATS_TEST_TMPDIR/settings.json"
  grep '^allow-prefix: ' "$GUIDE" | cut -d' ' -f2- \
    | jq -R '"Bash(" + . + ":*)"' \
    | jq -s '{permissions: {allow: (. + $ARGS.positional)}}' --args "$@" \
    > "$SETTINGS"
}

@test "fixture: a settings file matching the guide passes both checks" {
  write_fixture
  run check_allowed
  [ "$status" -eq 0 ]
  run check_removed
  [ "$status" -eq 0 ]
}

@test "fixture: a missing entry the guide claims allowed fails the allow check" {
  write_fixture
  local first
  first=$(grep -m1 '^allow-prefix: ' "$GUIDE" | cut -d' ' -f2-)
  jq --arg e "Bash($first:*)" '.permissions.allow -= [$e]' "$SETTINGS" \
    > "$SETTINGS.new" && mv "$SETTINGS.new" "$SETTINGS"
  run check_allowed
  [ "$status" -eq 1 ]
  [[ "$output" == *"Bash($first:*)"* ]]
}

@test "fixture: an allow entry for a prefix the guide calls removed fails the removed check" {
  local denied
  denied=$(grep -m1 '^deny-prefix: ' "$GUIDE" | cut -d' ' -f2-)
  write_fixture "Bash($denied:*)"
  run check_removed
  [ "$status" -eq 1 ]
  [[ "$output" == *"Bash($denied:*)"* ]]
}

@test "REQUIRE_LIVE_SETTINGS=1 turns a missing settings file into a failure" {
  SETTINGS="$BATS_TEST_TMPDIR/absent.json"
  REQUIRE_LIVE_SETTINGS=1 run check_allowed
  [ "$status" -eq 1 ]
  [[ "$output" == *"no settings file"* ]]
}
