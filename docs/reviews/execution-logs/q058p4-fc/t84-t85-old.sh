#!/usr/bin/env bash
# Run f5e3029's T84 and T85 against 516124d's install.sh (and, as a control,
# against f5e3029's). Each tree is a git archive in a scratch dir; the bats
# file is f5e3029's in both. Hermetic: install-host.bats sets its own temp
# HOME/TMPDIR and stubs pgrep/docker.
# Usage: t84-t85-old.sh <repo> <scratch dir>
set -uo pipefail
repo="$1"; scratch="$2"
for rev in 516124d f5e3029; do
  d="$scratch/tree-$rev"
  rm -rf "$d"; mkdir -p "$d"
  git -C "$repo" archive "$rev" | tar -x -C "$d"
  git -C "$repo" show f5e3029:test/install-host.bats > "$d/test/install-host.bats"
  echo "== install.sh from $rev, tests from f5e3029 ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
  (cd "$d" && bats -f 'T8[45] ' test/install-host.bats 2>&1 | grep -vE 'setlocale' | grep -E '^(ok|not ok|1\.\.|#.*(status|output|\[))' | head -20)
done
