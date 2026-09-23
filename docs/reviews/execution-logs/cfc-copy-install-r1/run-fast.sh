#!/usr/bin/env bash
S=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/fc
cd /workspace/.claude/wt-copyinstall || exit 9
date -u +%FT%TZ
env -u CLAUDECODE bash scripts/run-tests.sh --fast > "$S/logs/run-tests-fast.txt" 2>&1
rc=$?
echo "exit=$rc ok=$(grep -c '^ok' "$S/logs/run-tests-fast.txt") notok=$(grep -c '^not ok' "$S/logs/run-tests-fast.txt")"
tail -5 "$S/logs/run-tests-fast.txt"
