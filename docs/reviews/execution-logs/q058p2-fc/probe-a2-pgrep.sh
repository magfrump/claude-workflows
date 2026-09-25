#!/usr/bin/env bash
# Probe A2 (ec1e5bd): apply install.sh's CLAUDE_PROC_RE with the REAL pgrep
# (as agent_gate calls it: pgrep -u <uid> -af -- <re>) to throwaway processes
# whose command lines have T71's shapes. Only this probe's own PIDs are
# reported, so real sessions on the host are neither listed nor touched.
# Usage: probe-a2-pgrep.sh <path to install.sh under test>
set -uo pipefail

re="$(sed -n "s/^CLAUDE_PROC_RE='\(.*\)'\$/\1/p" "$1")"
echo "CLAUDE_PROC_RE=$re"
declare -A shape=()
spawn() {  # spawn <command line>: a sleeping perl whose /proc cmdline is <command line>
  LC_ALL=C perl -e '$0 = $ARGV[0]; sleep 60' "$1" &
  shape[$!]="$1"
}
spawn '/home/u/.local/share/claude/versions/2.1.3 --resume'
spawn 'node /x/node_modules/@anthropic-ai/claude-agent-sdk/cli.js'
spawn 'claude --resume'
spawn 'node /usr/lib/node_modules/@anthropic-ai/claude-code/cli.js'
spawn 'bash ralph-loop.sh'
spawn 'vim notes.md'
spawn 'node cli.js'
spawn 'bash /home/u/claude-workflows/devcontainer-config/install.sh'
spawn 'claude.exe'
spawn 'vim ./claude'
sleep 0.5
matched="$(pgrep -u "$(id -u)" -af -- "$re" || true)"
for pid in "${!shape[@]}"; do
  if printf '%s\n' "$matched" | awk -v p="$pid" '$1 == p {f=1} END {exit !f}'; then m=MATCH; else m=no; fi
  printf '%-6s %s\n' "$m" "${shape[$pid]}"
done | sort
kill "${!shape[@]}" 2>/dev/null
wait 2>/dev/null
exit 0
