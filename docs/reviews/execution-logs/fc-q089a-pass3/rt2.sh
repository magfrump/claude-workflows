#!/usr/bin/env bash
# shellcheck disable=SC2010  # recorded reviewer probe, kept as run; gate 6 only
# P-i redo: shim installed AFTER the initial bless. Run: rt2.sh <probe-root>
set -u
P="$1"; [ -d "$P/head/devcontainer-config" ] || exit 2
R="$P/rt2"; rm -rf "$R"; mkdir -p "$R/bin" "$R/home" "$R/tmp" "$R/shim" || exit 2
export HOME="$R/home" TMPDIR="$R/tmp"
printf '#!/usr/bin/env bash\nexit 0\n' > "$R/bin/devcontainer"; chmod +x "$R/bin/devcontainer"
PATH="$R/bin:$PATH"; SRC="$P/head/devcontainer-config"
D="$R/cfg"; export CLAUDE_DEVC_CONFIG_DIR="$D"; mkdir -p "$D/egress"
echo '{"name":"x"}' > "$D/devcontainer.json"; echo 'FROM node:22' > "$D/Dockerfile"
echo '#!/bin/bash' > "$D/init-firewall.sh"; echo '#!/usr/bin/python3' > "$D/cc-sni-proxy.py"
echo '#!/usr/bin/env bash' > "$D/link-claude-home.sh"; echo 'api.anthropic.com' > "$D/egress/base.txt"; echo 'pypi.org' > "$D/egress/python.txt"
cp "$SRC/cc-isolated.sh" "$SRC/cc-exit-scan.sh" "$SRC/cc-gitdir.sh" "$SRC/cc-push.sh" "$D/"
bash "$D/cc-isolated.sh" --bless >/dev/null || { echo "initial bless failed"; exit 2; }
hm="$(sha256sum "$D/manifest.sha256" "$D/host-tools.sha256")"
cat > "$R/shim/mktemp" <<'SH'
#!/usr/bin/env bash
case "$*" in *.host-tools.*) echo "shim: mktemp failing on host-tools" >&2; exit 1 ;; esac
exec /usr/bin/mktemp "$@"
SH
chmod +x "$R/shim/mktemp"
echo "### --bless with the second mktemp failing"
PATH="$R/shim:$PATH" bash "$D/cc-isolated.sh" --bless > "$R/b.out" 2>"$R/b.err"; echo "bless exit=$?"; grep -v setlocale "$R/b.err"; echo "stdout lines: $(wc -l < "$R/b.out")"
[ "$hm" = "$(sha256sum "$D/manifest.sha256" "$D/host-tools.sha256")" ] && echo "manifests unchanged"
ls -A "$D" | grep -E '^\.(manifest|host-tools)\.' || echo "no temp files"
echo "### --register with the second mktemp failing"
ws="$R/ws"; mkdir -p "$ws"; git -C "$ws" init -q
PATH="$R/shim:$PATH" bash "$D/cc-isolated.sh" --register "$ws" --profile python > "$R/r.out" 2>"$R/r.err"; echo "register exit=$?"
tail -3 "$R/r.out"; grep -v setlocale "$R/r.err"
grep -c 'Next launch rebuilds' "$R/r.out"
ls -A "$D" | grep -E '^\.(manifest|host-tools)\.' || echo "no temp files"
[ "$hm" = "$(sha256sum "$D/manifest.sha256" "$D/host-tools.sha256")" ] && echo "manifests unchanged (profile file written: $(ls "$D/projects" 2>/dev/null))"
echo "### done"
