#!/bin/bash
# shellcheck disable=SC2010  # recorded reviewer probe, kept as run; gate 6 only
# probe2: bless failure paths via PATH shims for mktemp / mv. $1 = probe root
P="$1"; cd "$P" || exit 1
export HOME="$P/home2"; mkdir -p "$HOME"
D="$P/inst2"; rm -rf "$D"; mkdir -p "$D"
S="$P/head/devcontainer-config"
for i in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress; do cp -R "$S/$i" "$D/"; done
export CLAUDE_DEVC_CONFIG_DIR="$D"
bash "$D/cc-isolated.sh" --bless >/dev/null || exit 9
M0="$(cat "$D/manifest.sha256")"; H0="$(cat "$D/host-tools.sha256")"
echo '# a' >> "$D/cc-push.sh"; echo '# b' >> "$D/init-firewall.sh"
SH="$P/shim"; rm -rf "$SH"; mkdir -p "$SH"
REALMK="$(command -v mktemp)"; REALMV="$(command -v mv)"
cat > "$SH/mktemp" <<S
#!/bin/bash
case "\$*" in *host-tools*) exit 1 ;; esac
exec "$REALMK" "\$@"
S
chmod +x "$SH/mktemp"
echo "== A: second mktemp fails"
PATH="$SH:$PATH" bash "$D/cc-isolated.sh" --bless > "$P/logs/p2a.out" 2>&1; echo "exit=$?"; tail -3 "$P/logs/p2a.out"
ls -a "$D" | grep -E '^\.(manifest|host-tools)\.' || echo "(no temp files)"
[ "$(cat "$D/manifest.sha256")" = "$M0" ] && echo "manifest unchanged" || echo "manifest CHANGED"
rm -f "$D"/.manifest.* "$D"/.host-tools.*
rm "$SH/mktemp"
cat > "$SH/mv" <<S
#!/bin/bash
case "\$*" in *manifest.sha256*) exit 1 ;; esac
exec "$REALMV" "\$@"
S
chmod +x "$SH/mv"
echo "== B: second mv (manifest) fails"
PATH="$SH:$PATH" bash "$D/cc-isolated.sh" --bless > "$P/logs/p2b.out" 2>&1; echo "exit=$?"; tail -3 "$P/logs/p2b.out"
ls -a "$D" | grep -E '^\.(manifest|host-tools)\.' || echo "(no temp files)"
[ "$(cat "$D/manifest.sha256")" = "$M0" ] && echo "manifest unchanged" || echo "manifest CHANGED"
[ "$(cat "$D/host-tools.sha256")" = "$H0" ] && echo "host-tools unchanged" || echo "host-tools CHANGED"
echo "== C: leftover temp file affects compute_manifest?"
bash "$D/cc-isolated.sh" --bless > /dev/null 2>&1; echo "rebless exit=$?"
grep -c '\.manifest\.' "$D/manifest.sha256" || true
ls -a "$D" | grep -E '^\.(manifest|host-tools)\.' || echo "(no temp files)"
