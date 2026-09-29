#!/usr/bin/env bash
# Targeted execution for code-fact-check r3 (final pass). Run from the worktree.
S=/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad
cd /workspace/.claude/wt-agents-md || exit 1
L=$S/exec.log; : > "$L"
run(){ echo "\$ $* # cwd=$PWD $(date -u +%FT%TZ)" >> "$L"; bash -c "$*" >> "$L" 2>&1; echo "exit=$?" >> "$L"; }
run "timeout 120 bats test/agents-gemini-sync.bats"
git show main:AGENTS.md > "$S/old-agents.md"
run "source $S/finder.sh; find_imports $S/old-agents.md | wc -l"
run "timeout 20 node $S/cc-extract.js $S/old-agents.md"
GI=global-instructions/CLAUDE.md
for f in AGENTS.md "$GI" GEMINI.md README.md workflows/*.md; do
  run "echo FILE $f; source $S/finder.sh; find_imports $f | wc -l; timeout 20 node $S/cc-extract.js $f"
done
# Missing-guarded-file probe: copy the test into a fake repo with no global-instructions/.
F=$S/fake; rm -rf "$F"; mkdir -p "$F/test"
cp test/agents-gemini-sync.bats "$F/test/"; cp AGENTS.md GEMINI.md "$F/"
run "cd $F && timeout 120 bats test/agents-gemini-sync.bats"
