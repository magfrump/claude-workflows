#!/bin/bash
# Usage: run_bats.sh <label> <hook-rev-or-HEAD>
# Runs the HEAD test file against the hook from <rev> (copied into a temp tree).
set -u
P=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/gfc-rr-r1
W=/workspace/.claude/wt-guard
label=$1; rev=$2; trev=${3:-HEAD}
mkdir -p "$P/logs" "$P/trees"
T="$P/trees/$label"
rm -rf "$T"; mkdir -p "$T"
# copy worktree test+hooks dirs
cp -r "$W/test" "$T/test"; cp -r "$W/hooks" "$T/hooks"
if [ "$trev" != HEAD ]; then git -C "$W" show "$trev:test/hooks/guard-trusted-writes.bats" > "$T/test/hooks/guard-trusted-writes.bats"; fi
echo "testrev=$trev" > "$T/TESTREV"
if [ "$rev" != HEAD ]; then
  git -C "$W" show "$rev:hooks/guard-trusted-writes.py" > "$T/hooks/guard-trusted-writes.py"
fi
date -u +%FT%TZ > "$P/logs/bats-$label.txt"
echo "cwd=$T rev=$rev cmd=bats test/hooks/guard-trusted-writes.bats" >> "$P/logs/bats-$label.txt"
( cd "$T" && bats test/hooks/guard-trusted-writes.bats ) >> "$P/logs/bats-$label.txt" 2>&1
echo "exit=$?" >> "$P/logs/bats-$label.txt"
grep -c '^ok\|^not ok' "$P/logs/bats-$label.txt"
grep '^not ok\|^exit=\|^1\.\.' "$P/logs/bats-$label.txt"
