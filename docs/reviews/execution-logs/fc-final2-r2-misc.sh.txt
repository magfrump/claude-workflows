#!/usr/bin/env bash
cd "$(dirname "$0")/../../.."
date -u +%FT%TZ
echo "## timeout 20 claude --version"; timeout 20 claude --version; echo "exit=$?"
echo "## cmp of AGENTS.md and GEMINI.md below line 3"
cmp <(tail -n +4 AGENTS.md) <(tail -n +4 GEMINI.md) && echo identical
echo "## main:AGENTS.md with @./workflows/ stripped vs AGENTS.md"
diff <(git show main:AGENTS.md | sed 's|@\./workflows/||g') AGENTS.md && echo "no other difference"
echo "## root instructions file present?"; ls ./CLAUDE.md; echo "exit=$?"
