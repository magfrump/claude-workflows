#!/usr/bin/env bash
# Hermetic behaviour probes for unit B. $1 = log dir. Everything lives under this
# script's directory; HOME is redirected there.
P="$(cd "$(dirname "$0")" && pwd)"
L="$1"
[ -d "$P/src" ] && [ -d "$L" ] || { echo "missing dirs"; exit 1; }
case "$P" in */tmp/fc-q089b.*) ;; *) echo "bad P"; exit 1 ;; esac
export HOME="$P/home" LC_ALL=C
unset CLAUDE_DEVC_CONFIG_DIR CC_LIVE_VERIFY_GATE_DISABLE
GATE="$P/src/hooks/live-verify-gate.sh"
payload() { jq -n -c --arg c "$1" '{"tool_name":"Bash","tool_input":{"command":$c}}'; }
run_gate() { echo "\$ gate <<< $1"; bash "$GATE" <<< "$(payload "$1")"; echo "exit=$?"; }

# ---------------- Gate probes ----------------
{
echo "start: $(date -u +%FT%TZ)"
R="$P/gaterepo"; rm -rf "$R"; mkdir -p "$R/devcontainer-config/egress"; cd "$R" || exit 1
echo "cwd: $R"
git init -q; git config user.email t@e; git config user.name t
echo base > devcontainer-config/egress/base.txt
printf 'echo a\n' > devcontainer-config/cc-push.sh
git add -A; git -c commit.gpgsign=false commit -qm init
echo "## G1: host-tool-only real change, no trailer (header line 35 says 'no enforcement file staged -> exit 0')"
echo 'echo b' >> devcontainer-config/cc-push.sh; git add -A
run_gate 'git commit -m x'
echo "## G1b: same, with Live-verified only (header line 35 'trailer present -> exit 0')"
run_gate 'git commit -m x -m "Live-verified: no - n/a"'
echo "## G2: comment-only boundary edit + real host change, Host-tool-tested only ('and vice versa')"
echo '# note' >> devcontainer-config/egress/base.txt; git add -A
run_gate 'git commit -m x -m "Host-tool-tested: no - bats"'
echo "## G3: same, Live-verified only"
run_gate 'git commit -m x -m "Live-verified: no - n/a"'
echo "## G4: real boundary + real host, no trailer: both messages"
echo 'widened' >> devcontainer-config/egress/base.txt; git add -A
run_gate 'git commit -m x' 2>&1
echo "## G5: comment-only host edit alone"
git reset -q --hard; echo '# c' >> devcontainer-config/cc-push.sh; git add -A
run_gate 'git commit -m x'
echo "## G6: host tool via -a only"
git reset -q --hard; echo 'echo c' >> devcontainer-config/cc-push.sh
run_gate 'git commit -m x'
run_gate 'git commit -am x'
} > "$L/probe-gate.log" 2>&1

# ---------------- Mutation probes (does any gate test pin regex <-> host_tool_files?) ----------------
{
echo "start: $(date -u +%FT%TZ)"
for m in M1 M2; do
  rm -rf "$P/mut"; cp -a "$P/src" "$P/mut"; cd "$P/mut" || exit 1
  echo "cwd: $P/mut"
  if [ $m = M1 ]; then
    echo "## M1: gate host_tools regex gains an extra name (cc-extra.sh) not in host_tool_files"
    sed -i 's/cc-push\\.sh)\$'"'"'/cc-push\\.sh|cc-extra\\.sh)$'"'"'/' hooks/live-verify-gate.sh
    grep -n '^host_tools=' hooks/live-verify-gate.sh
  else
    echo "## M2: host_tool_files drops cc-gitdir.sh (gate regex unchanged)"
    sed -i '/^host_tool_files() {/,/^}/{/cc-gitdir/d}' devcontainer-config/cc-isolated.sh
    sed -n '/^host_tool_files() {/,/^}/p' devcontainer-config/cc-isolated.sh
  fi
  echo "cmd: timeout 300 bats test/hooks/live-verify-gate.bats"
  timeout 300 bats test/hooks/live-verify-gate.bats | grep -E '^(not ok|1\.\.)'; echo "exit=${PIPESTATUS[0]}"
done
rm -rf "$P/mut"
} > "$L/probe-mutation.log" 2>&1

# ---------------- Launcher / cc-push probes ----------------
{
echo "start: $(date -u +%FT%TZ)"
D="$HOME/.config/claude-devcontainer"; rm -rf "$D"; mkdir -p "$D"
for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh; do
  cp "$P/src/devcontainer-config/$f" "$D/"; done
cp -r "$P/src/devcontainer-config/egress" "$D/"
chmod +x "$D"/*.sh
export CLAUDE_DEVC_CONFIG_DIR="$D"
WS="$P/ws"; rm -rf "$WS"; mkdir -p "$WS"; git -C "$WS" init -q
cd "$P" || exit 1; echo "cwd: $P"; echo "devcontainer on PATH: $(command -v devcontainer || echo none)"
r() { echo "\$ $*"; timeout 60 "$@"; echo "exit=$?"; }
echo "## L0: bless + list (clean)"
r bash "$D/cc-isolated.sh" --bless
r bash "$D/cc-isolated.sh" --list
H0="$(sha256sum < "$D/manifest.sha256" | cut -c1-16)"; echo "blessed_hash=$H0"
echo "## L1: cc-gitdir.sh changed"
echo '# tamper' >> "$D/cc-gitdir.sh"
r bash "$D/cc-isolated.sh" "$WS"
r bash "$D/cc-isolated.sh" --probe-only "$WS"
r bash "$D/cc-isolated.sh" --help
r bash "$D/cc-isolated.sh" --list
r bash "$D/cc-push.sh" --help
echo "## L1b: plus a boundary change"
echo 'extra.example.com' >> "$D/egress/base.txt"
r bash "$D/cc-isolated.sh" "$WS"
sed -i '$d' "$D/egress/base.txt"
echo "## L2: re-bless after cc-gitdir change: blessed_hash unchanged?"
r bash "$D/cc-isolated.sh" --bless
echo "blessed_hash=$(sha256sum < "$D/manifest.sha256" | cut -c1-16) (was $H0)"
echo "## L3: cc-push.sh only changed"
echo '# tamper' >> "$D/cc-push.sh"
r bash "$D/cc-isolated.sh" "$WS"
r bash "$D/cc-isolated.sh" --list
r bash "$D/cc-push.sh" --help
echo "## L4: malformed host-tools.sha256"
bash "$D/cc-isolated.sh" --bless >/dev/null 2>&1
printf 'garbage\n' >> "$D/host-tools.sha256"
r bash "$D/cc-isolated.sh" "$WS"
r bash "$D/cc-push.sh" --help
echo "## L5: deleted manifests in installed dir (no install.sh)"
rm -f "$D/host-tools.sha256" "$D/manifest.sha256"
r bash "$D/cc-push.sh" --help
echo "## L6: repo checkout (install.sh beside, no manifests, not config dir) is unchecked"
r bash "$P/src/devcontainer-config/cc-push.sh" --help
} > "$L/probe-launcher.log" 2>&1
echo done
