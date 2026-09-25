#!/usr/bin/env bash
# Run each pass-2 fix's new tests (test/install-host.bats at 516124d) against
# install.sh from the commit just before that fix. Hermetic: the suite pins
# HOME/TMPDIR/destinations into bats' temp dir and stubs pgrep/docker.
# Usage: prefix-bats.sh <worktree at 516124d>
set -uo pipefail
WT="$1"
X="$(mktemp -d "${TMPDIR:-/tmp}/q058p3-prefix.XXXXXX")"
run_against() {  # run_against <commit> <regex>
  local c="$1" re="$2" d="$X/$1"
  mkdir -p "$d/test" "$d/devcontainer-config"
  cp "$WT/test/install-host.bats" "$d/test/"
  cp -r "$WT/test/helpers" "$d/test/" 2>/dev/null || true
  git -C "$WT" show "$c:devcontainer-config/install.sh" > "$d/devcontainer-config/install.sh"
  echo "=== install.sh at $c ($(wc -l < "$d/devcontainer-config/install.sh") lines), tests matching: $re"
  bats -f "$re" "$d/test/install-host.bats" 2>&1 | grep -E '^(ok|not ok|1\.\.)'
  echo "bats exit=${PIPESTATUS[0]}"
}
date -u +%Y-%m-%dT%H:%M:%SZ
run_against f8d3f78 '^T7[56] '
run_against 99656a2 '^T7[789] '
run_against 21bf405 '^T8[012] '
run_against fa25f13 '^T83 '
run_against 516124d '^T(7[5-9]|8[0-3]) '
echo "=== T72 x5 at 516124d"
for i in 1 2 3 4 5; do bats -f '^T72 ' "$X/516124d/test/install-host.bats" 2>&1 | grep -E '^(ok|not ok)' | sed "s/^/run $i: /"; done
date -u +%Y-%m-%dT%H:%M:%SZ
rm -rf "$X"
