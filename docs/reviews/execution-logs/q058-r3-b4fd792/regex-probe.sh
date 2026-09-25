#!/usr/bin/env bash
# Spawns short-lived perl processes that rewrite their own command line
# ($0 = "<shape>", which Linux shows in /proc/PID/cmdline) to candidate
# Claude Code shapes, then asks the real pgrep, with the exact flags and
# CLAUDE_PROC_RE of install.sh agent_gate at b4fd792, which ones match.
RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/'
shapes=(
  'claude'
  'claude --resume'
  '/usr/local/bin/claude --resume'
  'node /usr/local/bin/claude --resume'
  'node /usr/lib/node_modules/@anthropic-ai/claude-code/cli.js'
  '/usr/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe -p hi'
  '/home/u/.local/share/claude/versions/2.0.14'
  '/home/u/.local/share/claude/versions/2.0.14 --resume'
  '/home/u/.vscode-server/extensions/anthropic.claude-code-2.0.0/resources/native-binary/claude --output-format stream-json'
  'claude-code --resume'
  'npx @anthropic-ai/claude-code'
  'bun /home/u/node_modules/@anthropic-ai/claude-code/cli.js'
  'bash /home/u/claude-workflows/devcontainer-config/install.sh'
  'bash /home/u/claude/devcontainer-config/install.sh'
  'vim ./claude'
  'vim claude'
  'python3 -m claude_agent_sdk'
)
pids=()
for s in "${shapes[@]}"; do
  perl -e '$0 = shift; sleep 20' "$s" & pids+=($!)
done
sleep 1
echo "== pgrep -u $(id -u) -af -- CLAUDE_PROC_RE, restricted to the probe PIDs"
matched="$(pgrep -u "$(id -u)" -af -- "$RE")"
for i in "${!pids[@]}"; do
  p=${pids[$i]}
  shown="$(tr '\0' ' ' < /proc/$p/cmdline)"
  if printf '%s\n' "$matched" | awk -v p="$p" '$1==p{f=1} END{exit !f}'; then r=MATCH; else r=miss; fi
  printf '%-5s | cmdline: %s\n' "$r" "$shown"
done
kill "${pids[@]}" 2>/dev/null; wait 2>/dev/null
echo "done"
