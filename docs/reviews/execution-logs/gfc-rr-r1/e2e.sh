#!/bin/bash
# End-to-end: hook decision at HEAD, then actually run the command under a fake HOME,
# and show where the bytes landed. Never touches the real ~/.claude.
set -u
P=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/gfc-rr-r1
HOOK=/workspace/.claude/wt-guard/hooks/guard-trusted-writes.py
T=$(mktemp -d "$P/e2e-XXXX"); export HOME="$T/home"; mkdir -p "$HOME/.claude"
R="$T/repo"; mkdir -p "$R"
git -C "$R" init -q; git -C "$R" -c user.name=t -c user.email=t@t commit -q --allow-empty -m i
git -C "$R" worktree add -q "$R/.claude/wt-foo" -b a 2>/dev/null
echo "# e2e $(date -u +%FT%TZ) HOME=$HOME cwd=$T"
decide() { jq -n --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c},session_id:"s"}' \
  | CC_WEB_TAINT_DIR="$T/taint" python3 "$HOOK" | jq -r '.hookSpecificOutput.permissionDecision // empty'; }
try() {
  local c="$1"; local d; d=$(decide "$c"); echo "CMD: $c"; echo "  hook decision: ${d:-defer (no output)}"
  ( cd "$T" && bash -c "$c" ) 2>&1 | sed 's/^/  run: /'
}
C1="cd $R/.claude/wt-foo && cd .. && echo '{\"hooks\":\"PWNED\"}' > settings.json"
try "$C1"; echo "  project settings now: $(cat $R/.claude/settings.json 2>&1)"
C2="rm -rf $R/.claude/wt-foo && ln -s \"\$(cd;pwd)\" $R/.claude/wt-foo && echo PWNED > $R/.claude/wt-foo/CLAUDE.md"
git -C "$R" worktree add -q "$R/.claude/wt-foo" -b b 2>/dev/null || true
try "$C2"; echo "  ~/CLAUDE.md now: $(cat $HOME/CLAUDE.md 2>&1)"
