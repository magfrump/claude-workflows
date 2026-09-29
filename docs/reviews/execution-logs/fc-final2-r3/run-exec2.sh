#!/usr/bin/env bash
S=/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad
cd /workspace/.claude/wt-agents-md || exit 1
L=$S/exec2.log; : > "$L"
run(){ echo "\$ $* # cwd=$PWD $(date -u +%FT%TZ)" >> "$L"; bash -c "$*" >> "$L" 2>&1; echo "exit=$?" >> "$L"; }
# bytes and chars of the nine imported workflows as of main
run 'tot=0; ch=0; for f in $(git show main:AGENTS.md | grep -oE "@\./workflows/[a-z-]+\.md" | sed "s|@\./||"); do b=$(git show main:$f | wc -c); c=$(git show main:$f | python3 -c "import sys; print(len(sys.stdin.read()))"); echo "$f $b $c"; tot=$((tot+b)); ch=$((ch+c)); done; echo "bytes=$tot chars=$ch chars/4=$((ch/4))"'
run 'sed -n "200,230p" scripts/health-check.sh'
run 'grep -c "\*\*[a-z-]*\.md\*\*" AGENTS.md GEMINI.md; grep -oE "\`[a-z-]+\.md\`" global-instructions/CLAUDE.md | sort -u | head -20'
run 'grep -n "extract_workflows" scripts/health-check.sh'
run 'grep -nE "global-instructions/CLAUDE.md|CLAUDE.md" install.sh | head -10'
run 'grep -nE "Read|tool_name|workflows" hooks/log-usage.sh | head -20'
run 'sed -n "1,20p" docs/decisions/log.md | grep -n "47" ; grep -nE "^\| 47 " docs/decisions/log.md'
