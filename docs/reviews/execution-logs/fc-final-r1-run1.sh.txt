#!/usr/bin/env bash
cd /workspace/.claude/wt-agents-md || exit 1
S=/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc
echo "run at $(date -Iseconds) cwd=$(pwd) head=$(git rev-parse --short HEAD)"
if diff <(sed -n '/^find_imports()/,/^}/p' test/agents-gemini-sync.bats | grep -v shellcheck) "$S/fi.sh"; then echo "FINDER IDENTICAL TO BATS"; fi
. "$S/fi.sh"
echo "--- cases.md"; find_imports "$S/cases.md"
echo "--- AGENTS.md"; find_imports AGENTS.md; echo "rc=$?"
echo "--- global-instructions/CLAUDE.md"; find_imports global-instructions/CLAUDE.md; echo "rc=$?"
git show main:AGENTS.md > "$S/oldagents.md"
echo "--- old AGENTS.md match count"; find_imports "$S/oldagents.md" | wc -l
echo "old @./workflows lines: $(grep -c '@\./workflows' "$S/oldagents.md")"
echo "--- pos/neg from bats"
sed -n "/cat > \"\$pos\" <<'EOF'/,/^EOF/p" test/agents-gemini-sync.bats | sed '1d;$d' > "$S/pos.md"
sed -n "/cat > \"\$neg\" <<'EOF'/,/^EOF/p" test/agents-gemini-sync.bats | sed '1d;$d' > "$S/neg.md"
echo "pos lines: $(wc -l < "$S/pos.md")  neg lines: $(wc -l < "$S/neg.md")"
find_imports "$S/pos.md"; echo "pos matches: $(find_imports "$S/pos.md" | wc -l)"
find_imports "$S/neg.md"; echo "neg matches: $(find_imports "$S/neg.md" | wc -l)"
echo "--- chars of 9 imported files (main)"
tot=0
for f in $(grep -o '@\./workflows/[a-z-]*\.md' "$S/oldagents.md" | sed 's|@\./||'); do
  n=$(git show "main:$f" | wc -c); echo "$f $n"; tot=$((tot+n))
done
echo "total=$tot tokens=$((tot/4))"
echo "--- bats file"
timeout 120 bats test/agents-gemini-sync.bats; echo "bats rc=$?"
echo "--- extract_workflows"
sed -n '200,225p' scripts/health-check.sh
