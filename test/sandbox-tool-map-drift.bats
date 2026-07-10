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
# Usage: bats test/sandbox-tool-map-drift.bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/.."
  GUIDE="$REPO_ROOT/guides/sandbox-tool-map.md"
  SETTINGS="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"
}

# Skip (not fail) when the environment can't support a live comparison.
require_live_settings() {
  command -v jq >/dev/null 2>&1 || skip "jq not available"
  [ -f "$SETTINGS" ] || skip "no settings file at $SETTINGS"
  jq -e '.permissions.allow' "$SETTINGS" >/dev/null 2>&1 \
    || skip "settings file has no permissions.allow array"
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

@test "prefixes the guide claims allowed exist in live permissions.allow" {
  require_live_settings
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

@test "prefixes the guide claims removed have no broad allow entry" {
  require_live_settings
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
