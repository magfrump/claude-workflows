S=/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc3
cd /workspace/.claude/wt-agents-md || exit 1
date -u +%FT%TZ
for f in pos neg probe; do echo "== $f"; timeout 10 bash $S/fi.sh $S/$f.md; echo "rc=$?"; done
echo "== AGENTS"; timeout 10 bash $S/fi.sh AGENTS.md; echo rc=$?
echo "== GLOBAL"; timeout 10 bash $S/fi.sh global-instructions/CLAUDE.md; echo rc=$?
git show main:AGENTS.md > $S/oldagents.md
echo "== old AGENTS"; timeout 10 bash $S/fi.sh $S/oldagents.md; echo rc=$?
echo "== old @./workflows count"; grep -c '@\./workflows' $S/oldagents.md
echo "== @ in global"; grep -n '@' global-instructions/CLAUDE.md
echo "== @ in AGENTS"; grep -n '@' AGENTS.md
echo "== sizes"
total=0
for p in $(grep -o '@\./workflows/[a-z-]*\.md' $S/oldagents.md | sed 's|@\./||'); do
  c=$(git show main:$p | wc -c); m=$(git show main:$p | wc -m); echo "$p bytes=$c chars=$m"; total=$((total+c)); tm=$((tm+m))
done
echo "total bytes=$total chars=$tm tokens(bytes/4)=$((total/4)) tokens(chars/4)=$((tm/4))"
echo "== head diff agents/gemini"
diff <(tail -n +4 AGENTS.md) <(tail -n +4 GEMINI.md); echo diffrc=$?
echo "== bats"
timeout 120 bats test/agents-gemini-sync.bats; echo batsrc=$?
