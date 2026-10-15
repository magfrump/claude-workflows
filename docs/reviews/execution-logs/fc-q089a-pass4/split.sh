#!/usr/bin/env bash
# shellcheck disable=SC2010  # recorded reviewer probe, kept as run; gate 6 only
# bless_manifest's split case: the second rename (manifest.sha256) fails after the first
# (host-tools.sha256) succeeded. Does the next launch fail closed? Run: split.sh <probe-root>
set -u
P="$1"; R="$P/split"; rm -rf "$R"; mkdir -p "$R/bin" "$R/home" "$R/tmp" || exit 2
export HOME="$R/home" TMPDIR="$R/tmp"
printf '#!/usr/bin/env bash\nexit 0\n' > "$R/bin/devcontainer"; chmod +x "$R/bin/devcontainer"
PATH="$R/bin:$PATH"
SRC="$P/head/devcontainer-config"
D="$R/cfg"; export CLAUDE_DEVC_CONFIG_DIR="$D"
ws="$R/ws"; mkdir -p "$ws"; git -C "$ws" init -q
mk() { rm -rf "$D"; mkdir -p "$D/egress"
  echo '{"name":"x"}' > "$D/devcontainer.json"; echo 'FROM node:22' > "$D/Dockerfile"
  echo '#!/bin/bash' > "$D/init-firewall.sh"; echo '#!/usr/bin/python3' > "$D/cc-sni-proxy.py"
  echo '#!/usr/bin/env bash' > "$D/link-claude-home.sh"; echo 'api.anthropic.com' > "$D/egress/base.txt"
  cp "$SRC/cc-isolated.sh" "$SRC/cc-exit-scan.sh" "$SRC/cc-gitdir.sh" "$SRC/cc-push.sh" "$D/"
  bash "$D/cc-isolated.sh" --bless >/dev/null; }
shim() { cat > "$R/bin/mv" <<'SH'
#!/usr/bin/env bash
case "${!#}" in */manifest.sha256) echo "shim: mv to manifest.sha256 failing" >&2; exit 1 ;; esac
exec /bin/mv "$@"
SH
chmod +x "$R/bin/mv"; }
for case_ in boundary-changed boundary-unchanged; do
  echo "### $case_: scan changed$([ $case_ = boundary-changed ] && echo ', Dockerfile changed')"
  mk; echo '# s' >> "$D/cc-exit-scan.sh"; [ $case_ = boundary-changed ] && echo 'FROM evil' >> "$D/Dockerfile"
  shim; bash "$D/cc-isolated.sh" --bless > "$R/b.out" 2>&1; echo "bless exit=$?"; grep -E 'shim|ERROR' "$R/b.out"; rm -f "$R/bin/mv"
  ls -A "$D" | grep -E '^\.(manifest|host-tools)\.' | sed 's/^/leftover: /'
  bash "$D/cc-isolated.sh" "$ws" > /dev/null 2> "$R/l.err"; echo "next launch exit=$?"; grep -E '^ERROR|refusing' "$R/l.err" | head -3
done
