#!/bin/bash
# Probe: installed-layout dir; tamper cc-exit-scan.sh + cc-push.sh; what cc-push's refusal names
# vs what the bless then accepts. Also launcher refusal output and upgrade bless from an old layout.
set -u
P="$1"
W="$(mktemp -d "$P/_tmp/probe1.XXXXXX")" || exit 9
[ -d "$W" ] || exit 9
cd "$W" || exit 9
mkdir -p home stub cfg
printf '#!/bin/sh\nexit 0\n' > stub/devcontainer; chmod +x stub/devcontainer
export HOME="$W/home" TMPDIR="$W" CC_PUSH_CLONES_DIR="$W/clones" LC_ALL=C PATH="$W/stub:/usr/bin:/bin"
D="$W/cfg"; export CLAUDE_DEVC_CONFIG_DIR="$D"
SRC="$P/devcontainer-config"
cp -r "$SRC"/devcontainer.json "$SRC"/Dockerfile "$SRC"/init-firewall.sh "$SRC"/cc-sni-proxy.py "$SRC"/link-claude-home.sh "$SRC"/cc-isolated.sh "$SRC"/cc-exit-scan.sh "$SRC"/cc-gitdir.sh "$SRC"/cc-push.sh "$SRC"/egress "$D/"
echo "== bless 1"; bash "$D/cc-isolated.sh" --bless >/dev/null; echo "exit=$?"
echo '# t' >> "$D/cc-exit-scan.sh"; echo '# t' >> "$D/cc-push.sh"
echo "== cc-push --help with scan+push changed"; bash "$D/cc-push.sh" --help; echo "exit=$?"
echo "== launcher launch with scan+push changed"; mkdir -p ws; bash "$D/cc-isolated.sh" "$W/ws"; echo "exit=$?"
echo "== --list"; bash "$D/cc-isolated.sh" --list; echo "exit=$?"
echo "== bless 2 (what it accepts)"; bash "$D/cc-isolated.sh" --bless | head -12; echo "exit=${PIPESTATUS[0]}"
echo "== upgrade path: old layout blessed by the 4ab9a51f launcher, new payload copied, bless as install.sh:607 does"
U="$W/up"; mkdir -p "$U"
cp -r "$P/_old/devcontainer-config"/{devcontainer.json,Dockerfile,init-firewall.sh,cc-sni-proxy.py,link-claude-home.sh,cc-isolated.sh,cc-exit-scan.sh,cc-gitdir.sh,cc-push.sh,egress} "$U/"
CLAUDE_DEVC_CONFIG_DIR="$U" bash "$U/cc-isolated.sh" --bless >/dev/null; echo "old bless exit=$?"; ls "$U"/*.sha256
cp -r "$SRC"/{devcontainer.json,Dockerfile,init-firewall.sh,cc-sni-proxy.py,link-claude-home.sh,cc-isolated.sh,cc-exit-scan.sh,cc-gitdir.sh,cc-push.sh} "$U/"
echo "-- new launcher before bless (launch):"; CLAUDE_DEVC_CONFIG_DIR="$U" bash "$U/cc-isolated.sh" "$W/ws"; echo "exit=$?"
echo "-- bless:"; CLAUDE_DEVC_CONFIG_DIR="$U" "$U/cc-isolated.sh" --bless | head -20; echo "exit=${PIPESTATUS[0]}"
echo "-- cc-push --help after:"; bash "$U/cc-push.sh" --help >/dev/null; echo "exit=$?"
echo "-- launch after:"; CLAUDE_DEVC_CONFIG_DIR="$U" bash "$U/cc-isolated.sh" "$W/ws" 2>&1 | grep -i 'host-tool\|WARNING' ; echo "done"
