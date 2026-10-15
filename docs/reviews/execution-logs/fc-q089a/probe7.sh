#!/usr/bin/env bash
set -u; export LC_ALL=C
E=/home/node/.claude/jobs/00bcf178/tmp/fc-q089A.jPV8xH
W="$E/w7"; rm -rf "$W"; mkdir -p "$W" || exit 1; cd "$W" || exit 1
export HOME="$W/home"; mkdir -p "$HOME"; unset CLAUDE_DEVC_CONFIG_DIR
C="$W/custom"; mkdir -p "$C"
for i in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress; do cp -Rp "$E/A/devcontainer-config/$i" "$C/"; done
CLAUDE_DEVC_CONFIG_DIR="$C" "$C/cc-isolated.sh" --bless >/dev/null 2>&1; echo "bless C rc=$?"
printf 'touch %q\n' "$W/scan-ran" >> "$C/cc-exit-scan.sh"
"$C/cc-isolated.sh" --list >/dev/null 2>&1; echo "P7a tampered scan, manifests present, env unset, --list: rc=$? ran=$([ -e "$W/scan-ran" ] && echo yes || echo no)"
rm -f "$C/host-tools.sha256" "$C/manifest.sha256"
"$C/cc-isolated.sh" --list >/dev/null 2>&1; echo "P7b tampered scan, BOTH deleted, env unset, --list: rc=$? ran=$([ -e "$W/scan-ran" ] && echo yes || echo no)"
rm -f "$W/scan-ran"
CLAUDE_DEVC_CONFIG_DIR="$C" "$C/cc-isolated.sh" --list >/dev/null 2>&1; echo "P7c tampered scan, BOTH deleted, env=C, --list: rc=$? ran=$([ -e "$W/scan-ran" ] && echo yes || echo no)"
