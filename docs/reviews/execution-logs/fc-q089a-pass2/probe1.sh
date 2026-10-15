#!/bin/bash
# probe1: refusal branch notes. $1 = probe root
P="$1"; cd "$P" || exit 1
export HOME="$P/home1"; mkdir -p "$HOME"
D="$P/inst1"; rm -rf "$D"; mkdir -p "$D"
S="$P/head/devcontainer-config"
for i in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress; do cp -R "$S/$i" "$D/"; done
export CLAUDE_DEVC_CONFIG_DIR="$D"
mkdir -p "$P/ws1"
echo "== bless"; bash "$D/cc-isolated.sh" --bless >/dev/null; echo "exit=$?"
echo "== A: host tool changed only"; echo '# x' >> "$D/cc-exit-scan.sh"
bash "$D/cc-isolated.sh" "$P/ws1"; echo "exit=$?"
echo "== B: host tool changed + manifest.sha256 deleted"; mv "$D/manifest.sha256" "$P/m.bak"
bash "$D/cc-isolated.sh" "$P/ws1"; echo "exit=$?"
mv "$P/m.bak" "$D/manifest.sha256"
echo "== C: host tool changed + enforcement file missing (compute_manifest fails inside check_manifest)"; mv "$D/Dockerfile" "$P/df.bak"
bash "$D/cc-isolated.sh" "$P/ws1"; echo "exit=$?"
mv "$P/df.bak" "$D/Dockerfile"
echo "== D: --list after cc-push.sh-only change"; bash "$D/cc-isolated.sh" --bless >/dev/null; echo 'echo x' >> "$D/cc-push.sh"
bash "$D/cc-isolated.sh" --list | head -3; echo "launch:"; bash "$D/cc-isolated.sh" "$P/ws1" 2>&1 | head -3
echo "== E: launch with no env var set, from custom dir"; unset CLAUDE_DEVC_CONFIG_DIR; bash "$D/cc-isolated.sh" --bless >/dev/null 2>&1; CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --bless >/dev/null; echo '# y' >> "$D/cc-gitdir.sh"
bash "$D/cc-isolated.sh" "$P/ws1"; echo "exit=$?"
echo "== F: repo checkout dir (head/devcontainer-config) is unchecked"; export CLAUDE_DEVC_CONFIG_DIR="$D"
bash -c 'source <(sed -n "/^# --- verify_host_tools/,/^# --- end verify_host_tools/p" "$1"); verify_host_tools "$(readlink -f "$2")" cc-exit-scan.sh cc-gitdir.sh cc-push.sh; echo "repo verify rc=$?"' _ "$S/cc-isolated.sh" "$S"
echo "== G: CLAUDE_DEVC_CONFIG_DIR pointed at the repo checkout itself"
CLAUDE_DEVC_CONFIG_DIR="$S" bash -c 'source <(sed -n "/^# --- verify_host_tools/,/^# --- end verify_host_tools/p" "$1"); verify_host_tools "$(readlink -f "$2")" cc-exit-scan.sh; echo "rc=$?"' _ "$S/cc-isolated.sh" "$S"
