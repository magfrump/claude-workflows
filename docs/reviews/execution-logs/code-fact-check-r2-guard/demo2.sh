#!/bin/bash
# A worktree-shaped name created as a symlink to the config dir in the same command.
G=/workspace/.claude/wt-guard/hooks/guard-trusted-writes.py
S=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/fc-guard-r2
T=$(mktemp -d); export HOME="$T/home"; mkdir -p "$HOME/.claude"; export CC_WEB_TAINT_DIR="$T/taint"; unset CLAUDE_CONFIG_DIR
C='cd ~ && ln -s . .claude/wt-q && echo PWNED > .claude/wt-q/settings.json'
p=$(jq -n -c --arg c "$C" '{"session_id":"clean","tool_name":"Bash","tool_input":{"command":$c}}')
echo "command: $C"
echo "new guard output: [$(python3 "$G" <<<"$p")]"
echo "old guard decision: [$(python3 "$S/old-guard.py" <<<"$p" | jq -r .hookSpecificOutput.permissionDecision)]"
( eval "$C" ); echo "shell exit=$?"
echo "settings.json now: $(cat "$HOME/.claude/settings.json")"
rm -rf "$T"
