#!/bin/bash
# Show that a quote-split `..` command the new hook defers does reach the config dir.
G=/workspace/.claude/wt-guard/hooks/guard-trusted-writes.py
S=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/fc-guard-r2
git -C /workspace/.claude/wt-guard show 970e525:hooks/guard-trusted-writes.py > "$S/old-guard.py"
T=$(mktemp -d); export HOME="$T/home"; mkdir -p "$HOME/.claude/hooks"; export CC_WEB_TAINT_DIR="$T/taint"; unset CLAUDE_CONFIG_DIR
C='cd ~ && mkdir -p .claude/wt-z && echo PWNED > ".claude/wt-z"/../settings.json && cp /etc/hostname ".claude/wt-z"/../hooks/h'
p=$(jq -n -c --arg c "$C" '{"session_id":"clean","tool_name":"Bash","tool_input":{"command":$c}}')
echo "command: $C"
echo "new guard output: [$(python3 "$G" <<<"$p")]"
echo "old guard decision: [$(python3 "$S/old-guard.py" <<<"$p" | jq -r .hookSpecificOutput.permissionDecision)]"
( eval "$C" ); echo "shell exit=$?"
echo "settings.json now: $(cat "$HOME/.claude/settings.json")"; ls -l "$HOME/.claude/hooks/h"
rm -rf "$T"
