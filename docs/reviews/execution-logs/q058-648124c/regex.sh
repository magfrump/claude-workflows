#!/bin/bash
RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/'
echo "== real processes (pgrep -af with CLAUDE_PROC_RE, this uid) =="
pgrep -u "$(id -u)" -af -- "$RE" | cut -c1-200; echo "rc=${PIPESTATUS[0]}"
echo "== all processes containing 'claude' (for shape) =="
pgrep -u "$(id -u)" -af claude | cut -c1-200
echo "== grep -E string cases =="
while IFS= read -r s; do
  if printf '%s\n' "$s" | grep -qE -- "$RE"; then r=MATCH; else r=no; fi
  printf '%-6s %s\n' "$r" "$s"
done <<'CASES'
claude
claude --resume
/home/u/.local/bin/claude -p hi
node /usr/local/bin/claude --resume
node /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js
/home/u/.local/share/claude/versions/2.1.3
/home/u/.local/share/claude/versions/2.1.3 --resume
/home/u/.vscode-server/extensions/anthropic.claude-code-2.0.1-linux-x64/resources/native-binary/claude --output-format stream-json
node /home/u/.vscode-server/extensions/anthropic.claude-code-1.0.30/resources/claude-code/cli.js
/home/u/.vscode/extensions/anthropic.claude-code-2.0.1/resources/native-binary/claude.exe --x
vim claude
vim ./claude
vim /tmp/claude
less CLAUDE.md
less ~/claude-workflows/README.md
cd /workspace/claude-workflows
bash /home/u/claude/devcontainer-config/install.sh
tail -f /var/log/claude
git -C /home/u/src/claude status
npx @anthropic-ai/claude-code
claude-code
CASES
echo "== real pgrep against argv0-renamed sleeps =="
pids=()
for a in cfcprobe/claude 'vim /tmp/cfcprobe/claude' 'less CLAUDE.md' '/w/claude-workflows/cfcprobe'; do
  ( exec -a "$a" sleep 20 ) & pids+=($!); echo "spawned $! as [$a]"
done
sleep 0.5
pgrep -u "$(id -u)" -af -- "$RE" | grep cfcprobe; echo "(end of cfcprobe matches)"
pgrep -u "$(id -u)" -af 'CLAUDE.md|claude-workflows/cfcprobe' | grep -E 'CLAUDE.md|cfcprobe' | head
kill "${pids[@]}" 2>/dev/null
