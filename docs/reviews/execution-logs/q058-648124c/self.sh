#!/bin/bash
D=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/cfc-q058
RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/'
mkdir -p "$D/co/claude/devcontainer-config"
printf '#!/usr/bin/env bash\nsleep 15\n' > "$D/co/claude/devcontainer-config/install.sh"
chmod +x "$D/co/claude/devcontainer-config/install.sh"
bash "$D/co/claude/devcontainer-config/install.sh" & p1=$!
"$D/co/claude/devcontainer-config/install.sh" & p2=$!
(cd "$D/co/claude" && ./devcontainer-config/install.sh) & p3=$!
sleep 0.5
echo "spawned $p1 $p2 $p3; all install.sh processes:"
pgrep -af 'co/claude/devcontainer-config/install.sh|devcontainer-config/install.sh' | grep -v pgrep
echo "matches of CLAUDE_PROC_RE among them:"
pgrep -af -- "$RE" | grep 'install.sh' ; echo "(end)"
kill $p1 $p2 2>/dev/null; pkill -P $p3 2>/dev/null; kill $p3 2>/dev/null
pkill -f "$D/co/claude/devcontainer-config/install.sh" 2>/dev/null
pkill -f '^/usr/bin/env bash ./devcontainer-config/install.sh$' 2>/dev/null
pkill -f '^bash ./devcontainer-config/install.sh$' 2>/dev/null
rm -rf "$D/co"
