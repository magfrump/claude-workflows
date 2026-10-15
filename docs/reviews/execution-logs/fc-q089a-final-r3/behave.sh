#!/usr/bin/env bash
# Behaviour probes for code-fact-check q089a final r3 (afe1ae59). Hermetic: an
# installed layout in a fresh mktemp dir; HOME/TMPDIR/CLAUDE_DEVC_CONFIG_DIR/
# CC_PUSH_CLONES_DIR redirected; devcontainer stubbed.
set -u
BASE=/home/node/.claude/jobs/00bcf178/tmp
REPO=/workspace/.claude/wt-q089
export LC_ALL=C
d="$(mktemp -d "$BASE/fcr3-beh.XXXXXX")" || exit 1
cd "$d" || exit 1
mkdir -p src home tmp cfg stub clones ws
git -C "$REPO" archive afe1ae59 devcontainer-config | tar -x -C src || exit 1
printf '#!/usr/bin/env bash\nexit 0\n' > stub/devcontainer; chmod +x stub/devcontainer
export HOME="$d/home" TMPDIR="$d/tmp" CLAUDE_DEVC_CONFIG_DIR="$d/cfg" CC_PUSH_CLONES_DIR="$d/clones" PATH="$d/stub:$PATH"
for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh \
         cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh; do cp "src/devcontainer-config/$f" cfg/; done
cp -r src/devcontainer-config/egress cfg/egress
L="$d/cfg/cc-isolated.sh"; P="$d/cfg/cc-push.sh"
run() { echo "\$ $*"; timeout 60 "$@" 2>&1; echo "[exit=$?]"; }
echo "=== $(date -u +%FT%TZ) dir=$d"
run bash "$L" --bless >/dev/null
cp cfg/host-tools.sha256 good.h
echo '# t' >> cfg/cc-exit-scan.sh
echo "--- B1 tampered scan: --help / unknown flag / --probe-only / --register"
run bash "$L" --help | tail -2
run bash "$L" --bogus | head -1
run bash "$L" --probe-only "$d/ws" | head -2
run bash "$L" --register "$d/ws" --profile python | head -2
cp src/devcontainer-config/cc-exit-scan.sh cfg/
echo "--- B2 missing host manifest: refusal has no 'also changed' line (manifest-level reason)"
rm cfg/host-tools.sha256
run bash "$L" "$d/ws"
echo "--- B3 malformed host manifest: same"
printf 'junk\n' > cfg/host-tools.sha256
run bash "$L" "$d/ws"
echo "--- B4 cc-push exits 1 before parsing (--help) when manifest is: missing / symlink / unreadable / malformed / ok"
rm cfg/host-tools.sha256; run bash "$P" --help | head -3
ln -s "$d/good.h" cfg/host-tools.sha256; run bash "$P" --help | head -3; rm cfg/host-tools.sha256
cp good.h cfg/host-tools.sha256; chmod 000 cfg/host-tools.sha256
if [ "$(id -u)" -ne 0 ]; then run bash "$P" --help | head -3; fi
chmod 644 cfg/host-tools.sha256
printf 'junk\n' > cfg/host-tools.sha256; run bash "$P" --help | head -3
cp good.h cfg/host-tools.sha256; run bash "$P" --help | head -1
echo "--- B5 cc-push via PATH symlink resolves its own dir"
ln -s "$P" stub/cc-push; run cc-push --help | head -1
echo "--- B6 changed cc-push: launch warns; probe/register also warn; bless/list do not"
echo '# p' >> cfg/cc-push.sh
run bash "$L" "$d/ws" | grep -n 'WARNING\|refusing'
run bash "$L" --list | grep -n 'WARNING\|cc-push'
run bash "$L" --bless | grep -n 'WARNING'
echo "--- B7 boundary-unchanged re-bless keeps blessed_hash"
h1="$(sha256sum < cfg/manifest.sha256)"; run bash "$L" --bless >/dev/null; h2="$(sha256sum < cfg/manifest.sha256)"
[ "$h1" = "$h2" ] && echo "manifest.sha256 identical after host-tool-only re-bless"
echo "--- B8 bless_cmd with CLAUDE_DEVC_CONFIG_DIR unset (default dir) in --list"
( unset CLAUDE_DEVC_CONFIG_DIR; timeout 60 bash "$L" --list 2>&1 | sed -n '2p'; echo "[exit=$?]" )
