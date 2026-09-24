#!/bin/bash
# Hermetic: source only agent_gate + vis from install.sh into a subshell with stubbed pgrep/docker.
D=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/cfc-q058
W=$(mktemp -d "$D/esc.XXXXXX")
export HOME="$W/home" TMPDIR="$W/tmp" CLAUDE_HOME_DIR="$W/home/.claude" CLAUDE_DEVC_CONFIG_DIR="$W/cfg" CLAUDE_DEVC_BIN_DIR="$W/bin"
unset CLAUDECODE
mkdir -p "$HOME" "$TMPDIR" "$W/stub"
SRCF=/workspace/.claude/wt-copyinstall/devcontainer-config/install.sh
# Extract function defs (vis, CLAUDE_PROC_RE, agent_gate)
{
  sed -n '/^vis() {/,/^}/p' "$SRCF"
  grep '^CLAUDE_PROC_RE=' "$SRCF"
  sed -n '/^agent_gate() {/,/^}/p' "$SRCF"
} > "$W/fns.sh"
run() { # $1 pgrep body, $2 docker body
  printf '#!/bin/bash\n%s\n' "$1" > "$W/stub/pgrep"; printf '#!/bin/bash\n%s\n' "$2" > "$W/stub/docker"
  chmod +x "$W/stub/pgrep" "$W/stub/docker"
  ( PATH="$W/stub:$PATH"; set -euo pipefail; . "$W/fns.sh"; agent_gate "WHAT" ) 2>&1; echo "[exit $?]"
}
echo "== ESC in pgrep cmdline =="
run $'printf "99 /x/claude \\033]0;pwned\\007 \\033[2J\\n"; exit 0' 'exit 0' | od -c | grep -c '033' ; run $'printf "99 /x/claude \\033[2J\\n"; exit 0' 'exit 0' | cat -v
echo "== ESC in container name =="
run 'exit 1' $'printf "evil\\033[31m cc-project=1\\n"; exit 0' | cat -v
echo "== docker fails with ESC on stderr (two lines) =="
run 'exit 1' $'printf "line1 \\033[31mred\\nline2\\n" >&2; exit 1' | cat -v
echo "== docker blank lines on stdout, exit 0 =="
run 'exit 1' $'printf "\\n\\n"; exit 0' | cat -v
echo "== pgrep exit 2 =="
run 'exit 2' 'exit 0' | cat -v
echo "== pgrep lists own \$\$ only =="
( PATH="$W/stub:$PATH"; printf '#!/bin/bash\necho "$PPID bash /x/claude"; exit 0\n' > "$W/stub/pgrep"; chmod +x "$W/stub/pgrep"; printf '#!/bin/bash\nexit 0\n' > "$W/stub/docker"; bash -c ". '$W/fns.sh'; set -euo pipefail; agent_gate WHAT; echo passed" ) 2>&1 | cat -v
echo "== docker hangs 30s (timeout 20) =="
s=$(date +%s); run 'exit 1' 'sleep 30; exit 0' | cat -v; echo "elapsed $(( $(date +%s) - s ))s"
rm -rf "$W"
