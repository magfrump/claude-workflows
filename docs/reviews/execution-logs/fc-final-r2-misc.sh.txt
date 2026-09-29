#!/usr/bin/env bash
# misc checks for code-fact-check final pass r2; run from worktree root
set -u
date -u +%FT%TZ
echo "== byte comparison below header"
S=$(mktemp -d)
tail -n +4 AGENTS.md > "$S/a"; tail -n +4 GEMINI.md > "$S/g"
cmp "$S/a" "$S/g" && echo "identical below line 3"
echo "== shared section headings"
grep -n '^## ' AGENTS.md
grep -n '^## Context Packing\|^## Shared Thoughts\|^## General Principles' global-instructions/CLAUDE.md
echo "== log-usage.sh event/tool matching"
grep -nE 'tool_name|Read|Skill|matcher|hook_event|workflows' hooks/log-usage.sh | head -30
echo "== Claude Code installed version and memory-import extractor"
B=$(readlink -f "$(command -v claude)")
"$B" --version
timeout 120 grep -aoE 'function yRn\(e,n\)\{.{0,1100}' "$B" | head -1
rm -rf "$S"
