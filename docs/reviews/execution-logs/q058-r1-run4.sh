#!/bin/bash
L=/workspace/docs/reviews/execution-logs/q058-r1-four-suites.log
cd /workspace/.claude/wt-copyinstall || exit 9
date -u +%FT%TZ > "$L.ts"
echo "cwd=$(pwd)" >> "$L.ts"
echo "cmd=bats test/install-host.bats test/cc-isolated-functions.bats test/link-claude-home-wiring.bats test/hooks/*.bats" >> "$L.ts"
bats test/install-host.bats test/cc-isolated-functions.bats test/link-claude-home-wiring.bats test/hooks/*.bats > "$L" 2>&1
echo "exit=$?" >> "$L"
grep -v setlocale "$L" | head -1
grep -c '^ok ' "$L"
grep '^not ok' "$L" | head
tail -1 "$L"
ls test/hooks/*.bats | wc -l
