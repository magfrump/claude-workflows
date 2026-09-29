#!/usr/bin/env bash
# Replays health-check.sh extract_workflows regex on the three files; run from worktree root
set -u
date -u +%FT%TZ
grep -n 'GLOBAL_MD=' scripts/health-check.sh
ext() { { grep -oE '(\*\*|`)(@\./workflows/)?[a-z][-a-z0-9]*\.md(\*\*|`)' "$1" || true; } | sed 's/\*\*//g; s/`//g; s|@\./workflows/||' | sort -u; }
S=$(mktemp -d)
git show main:AGENTS.md > "$S/legacy-agents.md"
for f in global-instructions/CLAUDE.md AGENTS.md GEMINI.md "$S/legacy-agents.md"; do
  echo "-- $f raw match delimiter counts:"
  grep -oE '(\*\*|`)(@\./workflows/)?[a-z][-a-z0-9]*\.md(\*\*|`)' "$f" | cut -c1-2 | sort | uniq -c
  echo "-- $f extracted:"; ext "$f" | tr '\n' ' '; echo
done
echo "-- bold .md filenames in global-instructions/CLAUDE.md: $(grep -c '\*\*[a-z-]*\.md\*\*' global-instructions/CLAUDE.md)"
rm -rf "$S"
