#!/bin/bash
# Run the bats suite against the new hook and against the 970e525 hook.
set -u
W=/workspace/.claude/wt-guard
L=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/fc/logs
mkdir -p "$L"
date -Is > "$L/ts.txt"
cd "$W" || exit
bats test/hooks/guard-trusted-writes.bats > "$L/bats-new.txt" 2>&1; echo "new exit=$?" >> "$L/ts.txt"
# old hook: build a temp tree with old hook + new tests
O=$(mktemp -d)
mkdir -p "$O/hooks" "$O/test/hooks" "$O/test/lib"
git show 970e525:hooks/guard-trusted-writes.py > "$O/hooks/guard-trusted-writes.py"
cp hooks/web-taint-mark.py "$O/hooks/"
cp test/hooks/guard-trusted-writes.bats "$O/test/hooks/"
cp -r test/lib/. "$O/test/lib/"
cd "$O" || exit
bats test/hooks/guard-trusted-writes.bats > "$L/bats-old.txt" 2>&1; echo "old exit=$?" >> "$L/ts.txt"
date -Is >> "$L/ts.txt"
