#!/usr/bin/env bash
# Security review pass 4: run links-probe.bats against install.sh at f5e3029,
# then L9 alone against install.sh at 516124d (to show whether f5e3029
# introduced it). Writes links-probe.log next to this script. Hermetic: see
# links-probe.bats (temp HOME/TMPDIR, stubbed pgrep/docker, empty git config).
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
wt=/workspace/.claude/wt-q058p2
old="$(mktemp -d "${TMPDIR:-/tmp}/old516.XXXXXX")"
mkdir -p "$old/devcontainer-config"
git -C "$wt" show 516124d:devcontainer-config/install.sh > "$old/devcontainer-config/install.sh"
{
  date -u +%Y-%m-%dT%H:%M:%SZ; git --version
  echo "=== install.sh at $(git -C "$wt" rev-parse --short HEAD) (f5e3029): all probes"
  bats --verbose-run --show-output-of-passing-tests "$here/links-probe.bats" 2>&1
  echo "bats exit=$?"
  echo
  echo "=== install.sh at 516124d (before f5e3029): L9 only"
  PROBE_CONFIG_SRC="$old/devcontainer-config" \
    bats --verbose-run --show-output-of-passing-tests -f 'L9' "$here/links-probe.bats" 2>&1
  echo "bats exit=$?"
} > "$here/links-probe.log" 2>&1
grep -E '^(ok|not ok|bats exit|===)' "$here/links-probe.log"
