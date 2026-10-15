#!/bin/bash
# Probe: with a tampered cc-exit-scan.sh, --help and a usage error are answered before the refusal.
set -u
P="$1"
W="$(mktemp -d "$P/_tmp/probe2.XXXXXX")" || exit 9
[ -d "$W" ] || exit 9
cd "$W" || exit 9
mkdir -p home cfg
export HOME="$W/home" TMPDIR="$W" LC_ALL=C CLAUDE_DEVC_CONFIG_DIR="$W/cfg"
SRC="$P/devcontainer-config"; D="$W/cfg"
cp -r "$SRC"/{devcontainer.json,Dockerfile,init-firewall.sh,cc-sni-proxy.py,link-claude-home.sh,cc-isolated.sh,cc-exit-scan.sh,cc-gitdir.sh,cc-push.sh,egress} "$D/"
bash "$D/cc-isolated.sh" --bless >/dev/null 2>&1; echo "bless exit=$?"
echo '# t' >> "$D/cc-exit-scan.sh"
bash "$D/cc-isolated.sh" --help >/dev/null 2>&1; echo "--help exit=$?"
bash "$D/cc-isolated.sh" --bogus >/dev/null 2>&1; echo "--bogus exit=$?"
bash "$D/cc-isolated.sh" --register "$W" --profile python 2>&1 | head -1; echo "--register exit=${PIPESTATUS[0]}"
bash "$D/cc-isolated.sh" --probe-only "$W" 2>&1 | head -1; echo "--probe-only exit=${PIPESTATUS[0]}"
