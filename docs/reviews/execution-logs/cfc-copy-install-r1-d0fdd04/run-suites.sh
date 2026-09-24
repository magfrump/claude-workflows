#!/usr/bin/env bash
S=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/fc
W=/workspace/.claude/wt-copyinstall
cd "$W" || exit 9
date -u +%FT%TZ
for t in test/link-claude-home-wiring.bats test/cc-isolated-functions.bats test/guide-index-sync.bats test/cross-reference-integrity.bats test/fixture-hermeticity.bats; do
  out="$S/logs/$(basename "$t").txt"
  env -u CLAUDECODE bats "$t" > "$out" 2>&1
  echo "$t exit=$? ok=$(grep -c '^ok' "$out") notok=$(grep -c '^not ok' "$out")"
done
out="$S/logs/hooks-suite.txt"
env -u CLAUDECODE bats test/hooks/*.bats > "$out" 2>&1
echo "test/hooks exit=$? ok=$(grep -c '^ok' "$out") notok=$(grep -c '^not ok' "$out") files=$(ls test/hooks/*.bats | wc -l)"
