#!/usr/bin/env bash
S=/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad
cd /workspace/.claude/wt-agents-md || exit 1
L=$S/exec4.log; : > "$L"
run(){ echo "\$ $* # cwd=$PWD $(date -u +%FT%TZ)" >> "$L"; bash -c "$*" >> "$L" 2>&1; echo "exit=$?" >> "$L"; }
GI=global-instructions/CLAUDE.md
run "grep -cE '\*\*[a-z][-a-z0-9]*\.md\*\*' $GI; echo bold-count-above"
# Historical guards
run "git show 5ee8315:test/agents-gemini-sync.bats | grep -nE 'grep|@' | tail -8"
run "git show 7b43db2:test/agents-gemini-sync.bats | sed -n '/^find_imports/,/^}/p'"
run "git show 7b43db2:test/agents-gemini-sync.bats | grep -nE 'eq [0-9]+|grep -c'"
# Run 7b43db2's finder on the forms 2f5fba3 says it mishandled
git show 7b43db2:test/agents-gemini-sync.bats | sed -n '/^find_imports/,/^}/p' > "$S/finder-7b43.sh"
printf '%s\n' '@README' '@package.json' '@x.MD' '(@./x)' '"@../y"' '``@./y.md``' '```' '@./in/fence.md' '```' > "$S/hist.md"
run "source $S/finder-7b43.sh; find_imports $S/hist.md"
run "source $S/finder-7b43.sh; find_imports $S/old-agents.md | wc -l"
# neg heredoc line count in the current synthetic test
run "sed -n '/cat > \"\$neg\"/,/^EOF/p' test/agents-gemini-sync.bats | sed '1d;\$d' | wc -l"
