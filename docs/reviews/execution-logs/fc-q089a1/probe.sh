#!/usr/bin/env bash
# fc-q089a1 probes. $1 = probe root (mktemp -d). Aborts without it.
set -u
P="${1:?probe root}"; [ -d "$P/src" ] || { echo "no $P/src"; exit 99; }
export HOME="$P/home" TMPDIR="$P/tmp" LC_ALL=C
SRC="$P/src/devcontainer-config"
mkstub() { mkdir -p "$1/bin"; printf '#!/usr/bin/env bash\nexit 0\n' > "$1/bin/devcontainer"; chmod +x "$1/bin/devcontainer"; }
mkinst() { # $1 dir: minimal installed layout with the real launcher + host tools
  local d="$1"; mkdir -p "$d/egress"
  echo '{"name":"x"}' > "$d/devcontainer.json"; echo 'FROM node:22' > "$d/Dockerfile"
  echo '#!/bin/bash' > "$d/init-firewall.sh"; echo '#!/usr/bin/python3' > "$d/cc-sni-proxy.py"
  echo '#!/usr/bin/env bash' > "$d/link-claude-home.sh"; echo 'api.anthropic.com' > "$d/egress/base.txt"
  cp "$SRC/cc-isolated.sh" "$SRC/cc-exit-scan.sh" "$SRC/cc-gitdir.sh" "$SRC/cc-push.sh" "$d/"
}
S="$P/stub"; mkstub "$S"; PATH="$S/bin:$PATH"

echo "== P1: --help with a tampered cc-exit-scan.sh (claim: refuses everything but --bless/--list)"
D="$P/p1/cfg"; mkinst "$D"; mkdir -p "$P/p1/ws"
CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --bless >/dev/null; echo "bless rc=$?"
echo '# t' >> "$D/cc-exit-scan.sh"
CLAUDE_DEVC_CONFIG_DIR="$D" timeout 30 bash "$D/cc-isolated.sh" --help >/dev/null 2>&1; echo "--help rc=$?"
CLAUDE_DEVC_CONFIG_DIR="$D" timeout 30 bash "$D/cc-isolated.sh" --register "$P/p1/ws" 2>&1 | head -2; echo "--register rc=${PIPESTATUS[0]}"

echo "== P2: refusal when host-tools.sha256 is missing, boundary unchanged (boundary_note text)"
D="$P/p2/cfg"; mkinst "$D"; mkdir -p "$P/p2/ws"
CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --bless >/dev/null; rm "$D/host-tools.sha256"
CLAUDE_DEVC_CONFIG_DIR="$D" timeout 30 bash "$D/cc-isolated.sh" "$P/p2/ws" 2>&1; echo "rc=$?"

echo "== P3: blessed_hash before/after A1 on the same installed files (claim: changes once on next install.sh)"
B="$P/base"; mkdir -p "$B"; git -C /workspace/.claude/wt-q089 archive 4ab9a51f devcontainer-config | tar -x -C "$B"
D="$P/p3/cfg"; mkinst "$D"
cp "$B/devcontainer-config/cc-isolated.sh" "$D/cc-isolated.sh.base"
# bless with base code (its own cc-isolated.sh is the hashed launcher, so hash the same file set: use base launcher)
cp "$D/cc-isolated.sh" "$D/cc-isolated.sh.a1"
cp "$D/cc-isolated.sh.base" "$D/cc-isolated.sh"; rm "$D/cc-isolated.sh.base"
CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --bless | grep 'Blessed config'
h_base_launcher_entries=$(wc -l < "$D/manifest.sha256"); echo "base manifest entries=$h_base_launcher_entries"; grep -c 'cc-push\|cc-gitdir\|cc-exit-scan' "$D/manifest.sha256"
cp "$D/cc-isolated.sh.a1" "$D/cc-isolated.sh"; rm "$D/cc-isolated.sh.a1"
CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --bless | grep 'Blessed config\|Changed since\|^[<>]'
echo "a1 manifest entries=$(wc -l < "$D/manifest.sha256")"; grep -c 'cc-push\|cc-gitdir\|cc-exit-scan' "$D/manifest.sha256"
CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --bless | grep 'Blessed config'
echo '# host edit' >> "$D/cc-push.sh"
CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --bless | grep 'Blessed config\|Changed since'

echo "== P4: bless failure (missing host tool) leaves manifest.sha256 unchanged too"
D="$P/p4/cfg"; mkinst "$D"
CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --bless >/dev/null
m0=$(sha256sum < "$D/manifest.sha256"); h0=$(sha256sum < "$D/host-tools.sha256")
echo 'FROM node:23' > "$D/Dockerfile"; rm "$D/cc-gitdir.sh"
CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --bless 2>&1 | tail -2; echo "rc=${PIPESTATUS[0]}"
[ "$(sha256sum < "$D/manifest.sha256")" = "$m0" ] && echo "manifest unchanged" || echo "manifest CHANGED"
[ "$(sha256sum < "$D/host-tools.sha256")" = "$h0" ] && echo "host-tools unchanged" || echo "host-tools CHANGED"
ls -A "$D" | grep '^\.' || echo "no temp files"

echo "== P5: does --list's 'Host tools: CHANGED' hint name the dir? (custom CLAUDE_DEVC_CONFIG_DIR)"
D="$P/p5/cfg"; mkinst "$D"; CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --bless >/dev/null
echo '# x' >> "$D/cc-gitdir.sh"
CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --list 2>&1 | grep -A3 'Host tools'

echo "== P6: launcher via PATH symlink resolves its own dir"
D="$P/p6/cfg"; mkinst "$D"; mkdir -p "$P/p6/bin" "$P/p6/ws"; ln -s "$D/cc-isolated.sh" "$P/p6/bin/cc-isolated"
CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --bless >/dev/null; echo '# x' >> "$D/cc-exit-scan.sh"
CLAUDE_DEVC_CONFIG_DIR="$D" timeout 30 "$P/p6/bin/cc-isolated" "$P/p6/ws" 2>&1 | head -1; echo "rc=${PIPESTATUS[0]}"
