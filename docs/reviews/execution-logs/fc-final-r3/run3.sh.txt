cd /workspace/.claude/wt-agents-md || exit 1
S=/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc3
date -u +%FT%TZ
echo "== GLOBAL_MD def"; grep -n 'GLOBAL_MD=' scripts/health-check.sh
eval "$(sed -n '/^extract_workflows() {/,/^}/p' scripts/health-check.sh)"
for f in global-instructions/CLAUDE.md AGENTS.md GEMINI.md $S/oldagents.md; do echo "== extract $f"; extract_workflows "$f" | tr '\n' ' '; echo; done
echo "== bold .md in global"; grep -cE '\*\*[a-z][-a-z0-9]*\.md\*\*' global-instructions/CLAUDE.md
echo "== install links global"; grep -n 'global-instructions/CLAUDE.md' install.sh | head -5
echo "== 5ee8315 regex"; git show 5ee8315:test/agents-gemini-sync.bats | grep -n 'grep -nE'
echo "== missing-file behaviour"; source $S/fi.sh /dev/null >/dev/null; m=$(find_imports /nonexistent/x.md 2>&1); echo "rc=$? out=[$m]"
