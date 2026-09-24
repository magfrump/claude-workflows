#!/bin/bash
# Probe the guard hook (new and old) on edge-case payloads with a temp HOME.
# (Re-saved copy of the script run at 2026-09-23T16:31:45-07:00; output in probe.txt.)
G=/workspace/.claude/wt-guard/hooks/guard-trusted-writes.py
S=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/fc
git -C /workspace/.claude/wt-guard show 970e525:hooks/guard-trusted-writes.py > "$S/old-guard.py"
T=$(mktemp -d)
export HOME="$T/home"; mkdir -p "$HOME/.claude/wt-a" "$HOME/.claude/hooks"
export CC_WEB_TAINT_DIR="$T/taint"
unset CLAUDE_CONFIG_DIR
run() {  # $1 label, $2 command
  p=$(jq -n -c --arg c "$2" '{"session_id":"clean","tool_name":"Bash","tool_input":{"command":$c}}')
  n=$(python3 "$G" <<<"$p" | jq -r '.hookSpecificOutput.permissionDecision // empty'); n=${n:-defer}
  o=$(python3 "$S/old-guard.py" <<<"$p" | jq -r '.hookSpecificOutput.permissionDecision // empty'); o=${o:-defer}
  printf '%-4s new=%-6s old=%-6s %s\n' "$1" "$n" "$o" "$2"
}
run P1 'cd ~ && echo x > .claude/wt-a/f'
run P2 'cd ~ && echo x > .claude/wt-a/hooks/x'
run P3 'cd ~ && echo x > .claude/worktrees/x/settings.json'
run P4 'echo x > ~/".claude/wt-a"/../settings.json'
run P5 "echo x > ~/'.claude/wt-a'/../settings.json"
run P6 'cd ~ && echo x > ".claude/wt-a"/../settings.json'
run P7 'cd ~ && cp /tmp/h ".claude/wt-a"/../hooks/h'
run P8 'cd ~ && echo x > ".claude/wt-a"/../CLAUDE.md'
run P9 'echo x > ~/.claude/wt-a/../settings.json'
run P10 'a=/../x/.claude/wt-a/f; echo x > $a'
run P11 'x=b=/tmp/.claude/wt-a/hooks/y; cp /tmp/q $x'
run P12 "echo x > $HOME/.claude/wt-a/hooks/x"
run P13 'echo x > /srv/.claude/wt-.claude/hooks/x'
run P14 'echo x > /srv/r/.claude/wt-a/hooks/x'
run P15 'git commit -F /tmp/msg.txt'
p=$(jq -n -c '{"session_id":"clean","tool_name":"Write","tool_input":{"file_path":"/tmp/msg.txt"}}')
echo "P16 Write /tmp/msg.txt -> $(python3 "$G" <<<"$p")(empty=defer)"
C="$T/co"; mkdir -p "$C/hooks/lib" "$C/other"; echo x > "$C/hooks/lib/a.sh"; echo x > "$C/other/b"
ln -s "$C/hooks/lib" "$HOME/.claude/hooks/lib"
ln -s "$T/nonexistent/x.sh" "$HOME/.claude/hooks/dangling.sh"
mkdir -p "$HOME/.claude/hooks/sub"; echo x > "$C/nested.sh"; ln -s "$C/nested.sh" "$HOME/.claude/hooks/sub/nested.sh"
for f in "$C/hooks/lib/a.sh" "$T/nonexistent/x.sh" "$C/nested.sh" "$C/other/b"; do
  p=$(jq -n -c --arg f "$f" '{"session_id":"clean","tool_name":"Edit","tool_input":{"file_path":$f}}')
  d=$(python3 "$G" <<<"$p" | jq -r '.hookSpecificOutput.permissionDecision // empty')
  echo "P17 Edit ${f#$T/} -> ${d:-defer}"
done
rm -rf "$HOME/.claude/hooks"; mkdir -p "$T/opt/hooks"; echo x > "$T/opt/hooks/g.py"; ln -s "$T/opt/hooks" "$HOME/.claude/hooks"
p=$(jq -n -c --arg f "$T/opt/hooks/g.py" '{"session_id":"clean","tool_name":"Edit","tool_input":{"file_path":$f}}')
d=$(python3 "$G" <<<"$p" | jq -r '.hookSpecificOutput.permissionDecision // empty'); echo "P18 Edit opt/hooks/g.py (hooks->opt) -> ${d:-defer}"
rm -rf "$T"
