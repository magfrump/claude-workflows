#!/bin/bash
# Pre-fix replays: T58 against ea2c8fb's install.sh; install-host suite at 66891a7 (pre-648124c).
SP=/tmp/claude-1000/-workspace/7630264d-3947-4203-a0ec-b9ffcc3a4e06/scratchpad/x
L=/workspace/docs/reviews/execution-logs/q058-r1-prefix-replays.log
: > "$L"
for c in ea2c8fb 66891a7; do
  rm -rf "$SP/tree-$c"; mkdir -p "$SP/tree-$c"
  git -C /workspace archive "$c" | tar -xf - -C "$SP/tree-$c"
done
{
  echo "## $(date -u +%FT%TZ) T58 (from b4fd792's test file) against ea2c8fb install.sh"
  # b4fd792's install-host.bats, with CONFIG_SRC pointed at ea2c8fb's devcontainer-config; only T58 run.
  mkdir -p "$SP/tree-ea2c8fb/test"
  git -C /workspace show b4fd792:test/install-host.bats \
    | sed "s|^  CONFIG_SRC=.*|  CONFIG_SRC=\"$SP/tree-ea2c8fb/devcontainer-config\"|" > "$SP/tree-ea2c8fb/test/t58.bats"
  cd "$SP/tree-ea2c8fb" && bats -f 'T58' test/t58.bats
  echo "exit=$?"
  echo
  echo "## $(date -u +%FT%TZ) install-host.bats at 66891a7 (pre-648124c), this shell (LC_ALL=$LC_ALL, locale uninstalled)"
  cd "$SP/tree-66891a7" && bats test/install-host.bats test/cc-isolated-functions.bats test/link-claude-home-wiring.bats test/hooks/*.bats
  echo "exit=$?"
} >> "$L" 2>&1
grep -v setlocale "$L" | grep -E '^(##|exit=|not ok|ok [0-9]+ T58|1\.\.)' | head -80
echo "not-ok count at 66891a7: $(sed -n '/66891a7/,$p' "$L" | grep -c '^not ok')"
