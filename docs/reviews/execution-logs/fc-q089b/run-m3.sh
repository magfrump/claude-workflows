#!/usr/bin/env bash
# M3: move a boundary file (init-firewall.sh) from the gate's enforcement regex to
# its host_tools regex only, then run the gate suite. $1 = log dir.
P="$(cd "$(dirname "$0")" && pwd)"
L="$1"
[ -d "$P/src" ] && [ -d "$L" ] || { echo "missing dirs"; exit 1; }
case "$P" in */tmp/fc-q089b.*) ;; *) echo "bad P"; exit 1 ;; esac
export HOME="$P/home" LC_ALL=C
{
echo "start: $(date -u +%FT%TZ)"
rm -rf "$P/mut"; cp -a "$P/src" "$P/mut"; cd "$P/mut" || exit 1
echo "cwd: $P/mut"
sed -i 's/init-firewall\\.sh|cc-sni/cc-sni/; s/^host_tools=.^devcontainer-config\/(/&init-firewall\\.sh|/' hooks/live-verify-gate.sh
grep -n -E '^(enforcement|host_tools)=' hooks/live-verify-gate.sh
echo "cmd: timeout 300 bats test/hooks/live-verify-gate.bats"
timeout 300 bats test/hooks/live-verify-gate.bats | grep -E '^(not ok|1\.\.)'; echo "exit=${PIPESTATUS[0]}"
echo "## direct: init-firewall.sh change with Host-tool-tested only"
R="$P/m3repo"; rm -rf "$R"; mkdir -p "$R/devcontainer-config"; cd "$R" || exit 1
git init -q; git config user.email t@e; git config user.name t
echo x > devcontainer-config/init-firewall.sh; git add -A
bash "$P/mut/hooks/live-verify-gate.sh" <<< "$(jq -n -c --arg c 'git commit -m x -m "Host-tool-tested: no - n/a"' '{"tool_name":"Bash","tool_input":{"command":$c}}')"
echo "exit=$?"
rm -rf "$P/mut" "$R"
} > "$L/probe-mutation-m3.log" 2>&1
cat "$L/probe-mutation-m3.log"
