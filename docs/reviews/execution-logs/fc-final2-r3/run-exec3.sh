#!/usr/bin/env bash
S=/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad
cd /workspace/.claude/wt-agents-md || exit 1
L=$S/exec3.log; : > "$L"
run(){ echo "\$ $* # cwd=$PWD $(date -u +%FT%TZ)" >> "$L"; bash -c "$*" >> "$L" 2>&1; echo "exit=$?" >> "$L"; }
GI=global-instructions/CLAUDE.md
run "grep -nE '^[[:space:]]*(\`\`\`\`|~~~)' AGENTS.md $GI; grep -nE '^[[:space:]]*\`\`\`.*\`\`\`' AGENTS.md $GI; echo done"
run "sed -n '1,14p' hooks/log-usage.sh"
# differential probe over the adversarial cases (finder vs verbatim CC extractor)
run "cd $S/cases && for f in *.md; do fin=\$(source ../finder.sh; find_imports \$f | tr '\n' '|'); cc=\$(timeout 20 node ../cc-extract.js \$f); printf '%-24s finder=[%s]  cc=%s\n' \"\${f%.md}\" \"\$fin\" \"\$cc\"; done"
run "cd $S && for f in pos neg; do echo \$f; timeout 20 node cc-extract.js \$f.md; source finder.sh; find_imports \$f.md | wc -l; done"
run "node --version; claude --version"
