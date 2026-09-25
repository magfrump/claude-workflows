#!/usr/bin/env bash
# Probe: which command-line shapes does install.sh's CLAUDE_PROC_RE (b4fd792:834) match
# under the real pgrep (procps-ng)? Each shape is a perl dummy that sets $0 (which
# rewrites /proc/<pid>/cmdline on Linux) and sleeps; all are killed by PID after.
# Usage: proc-shape-probe.sh <path-to-install.sh at b4fd792>
set -u
RE="$(sed -n "s/^CLAUDE_PROC_RE='\(.*\)'$/\1/p" "$1")"
echo "RE=$RE"
shapes=(
  "claude"
  "/usr/local/bin/claude --resume"
  "node /usr/local/bin/claude --resume"
  "node /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js -p x"
  "/opt/vscode/extensions/anthropic.claude-code-2.0.0/resources/native-binary/claude"
  "/home/u/.local/share/claude/versions/2.0.14 --resume"
  "node cli.js --resume"
  "node /srv/app/node_modules/@anthropic-ai/claude-agent-sdk/cli.js --output-format stream-json"
  "claude-code"
  "bash -c while sleep 1; do cp evil /tmp/cw-host-stage.X/payload/hooks/h.sh; done"
  "vim ./claude"
)
pids=()
for s in "${shapes[@]}"; do
  perl -e '$0 = $ARGV[0]; sleep 30' "$s" &
  pids+=("$!")
done
sleep 0.5
for i in "${!shapes[@]}"; do
  if pgrep -u "$(id -u)" -af -- "$RE" | awk -v p="${pids[$i]}" '$1==p{f=1} END{exit !f}'; then m=MATCH; else m=miss; fi
  printf '%-5s  %s\n' "$m" "$(tr '\0' ' ' < "/proc/${pids[$i]}/cmdline")"
done
kill "${pids[@]}" 2>/dev/null
