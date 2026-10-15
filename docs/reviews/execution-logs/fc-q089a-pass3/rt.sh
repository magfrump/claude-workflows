#!/usr/bin/env bash
# shellcheck disable=SC2010  # recorded reviewer probe, kept as run; gate 6 only
# Runtime probes, fact-check pass 3 (q089a). Run: rt.sh <probe-root>. Everything under <probe-root>/rt.
set -u
P="$1"; [ -d "$P/head/devcontainer-config" ] || { echo "no tree"; exit 2; }
R="$P/rt"; rm -rf "$R"; mkdir -p "$R/bin" "$R/home" "$R/tmp" || exit 2
export HOME="$R/home" TMPDIR="$R/tmp"
printf '#!/usr/bin/env bash\nexit 0\n' > "$R/bin/devcontainer"; chmod +x "$R/bin/devcontainer"
PATH="$R/bin:$PATH"
SRC="$P/head/devcontainer-config"
mk() { # mk <dir>: installed layout
  local d="$1"; rm -rf "$d"; mkdir -p "$d/egress"
  echo '{"name":"x"}' > "$d/devcontainer.json"; echo 'FROM node:22' > "$d/Dockerfile"
  echo '#!/bin/bash' > "$d/init-firewall.sh"; echo '#!/usr/bin/python3' > "$d/cc-sni-proxy.py"
  echo '#!/usr/bin/env bash' > "$d/link-claude-home.sh"; echo 'api.anthropic.com' > "$d/egress/base.txt"
  cp "$SRC/cc-isolated.sh" "$SRC/cc-exit-scan.sh" "$SRC/cc-gitdir.sh" "$SRC/cc-push.sh" "$d/"
  CLAUDE_DEVC_CONFIG_DIR="$d" bash "$d/cc-isolated.sh" --bless >/dev/null
}
ws="$R/ws"; mkdir -p "$ws"
D="$R/cfg"; export CLAUDE_DEVC_CONFIG_DIR="$D"

echo "### P-a: only cc-exit-scan.sh changed"
mk "$D"; echo '# a' >> "$D/cc-exit-scan.sh"
bash "$D/cc-isolated.sh" --list 2>&1 | grep 'Host tools'
bash "$D/cc-push.sh" --help >/dev/null 2>"$R/a.err"; echo "cc-push --help exit=$? stderr=$(cat "$R/a.err")"

echo "### P-b: only cc-gitdir.sh changed"
mk "$D"; echo '# b' >> "$D/cc-gitdir.sh"
bash "$D/cc-isolated.sh" --list 2>&1 | grep 'Host tools'
bash "$D/cc-push.sh" --help >/dev/null 2>"$R/b.err"; echo "cc-push --help exit=$? stderr=$(cat "$R/b.err")"
bash "$D/cc-isolated.sh" "$ws" >/dev/null 2>"$R/b2.err"; echo "launch exit=$?"; head -1 "$R/b2.err"

echo "### P-c: only cc-push.sh changed"
mk "$D"; echo '# c' >> "$D/cc-push.sh"
bash "$D/cc-isolated.sh" --list 2>&1 | grep 'Host tools'
bash "$D/cc-push.sh" --help >/dev/null 2>"$R/c.err"; echo "cc-push --help exit=$? stderr=$(cat "$R/c.err")"
bash "$D/cc-isolated.sh" "$ws" 2>&1 | grep -E 'WARNING|ERROR' ; echo "(launch: no refusal expected)"

echo "### P-d: cc-exit-scan.sh AND cc-push.sh changed: does --list name cc-push?"
mk "$D"; echo '# d' >> "$D/cc-exit-scan.sh"; echo '# d' >> "$D/cc-push.sh"
bash "$D/cc-isolated.sh" --list 2>&1 | grep -A3 'Host tools'

echo "### P-e: cc-gitdir.sh missing + cc-exit-scan.sh changed: does the loop continue past the missing file?"
mk "$D"; rm "$D/cc-gitdir.sh"; echo '# e' >> "$D/cc-exit-scan.sh"
bash "$D/cc-isolated.sh" "$ws" >/dev/null 2>"$R/e.err"; echo "launch exit=$?"; cat "$R/e.err"
echo "### P-e2: cc-exit-scan.sh a symlink (to the blessed copy), cc-gitdir.sh changed"
mk "$D"; cp "$D/cc-exit-scan.sh" "$R/es.real"; rm "$D/cc-exit-scan.sh"; ln -s "$R/es.real" "$D/cc-exit-scan.sh"; echo '# e2' >> "$D/cc-gitdir.sh"
bash "$D/cc-isolated.sh" "$ws" >/dev/null 2>"$R/e2.err"; echo "launch exit=$?"; head -3 "$R/e2.err"

echo "### P-f: manifest missing: early return unchanged"
mk "$D"; rm "$D/host-tools.sha256"
bash "$D/cc-isolated.sh" "$ws" >/dev/null 2>"$R/f.err"; echo "launch exit=$?"; head -1 "$R/f.err"

echo "### P-g: custom install dir, CLAUDE_DEVC_CONFIG_DIR unset; boundary changed in the launcher's dir"
L="$R/custom"; mk "$L"; echo '# g' >> "$L/cc-exit-scan.sh"; echo 'iptables -P INPUT ACCEPT' >> "$L/init-firewall.sh"
( unset CLAUDE_DEVC_CONFIG_DIR; bash "$L/cc-isolated.sh" "$ws" >/dev/null 2>"$R/g.err"; echo "launch exit=$?" ); cat "$R/g.err"
echo "--- then the suggested bless, and a relaunch"
( unset CLAUDE_DEVC_CONFIG_DIR; CLAUDE_DEVC_CONFIG_DIR="$L" bash "$L/cc-isolated.sh" --bless 2>&1 | grep -E 'Changed since|^[<>]' )
( unset CLAUDE_DEVC_CONFIG_DIR; bash "$L/cc-isolated.sh" "$ws" >/dev/null 2>"$R/g2.err"; echo "relaunch exit=$?"; grep -c 'refusing to run the session-exit scan' "$R/g2.err" )

echo "### P-h: first mktemp fails (config dir read-only)"
mk "$D"; hm="$(sha256sum "$D/manifest.sha256" "$D/host-tools.sha256")"; chmod 555 "$D"
bash "$D/cc-isolated.sh" --bless >/dev/null 2>"$R/h.err"; echo "bless exit=$?"; cat "$R/h.err"; chmod 755 "$D"
[ "$hm" = "$(sha256sum "$D/manifest.sha256" "$D/host-tools.sha256")" ] && echo "manifests unchanged"
ls -A "$D" | grep -E '^\.(manifest|host-tools)\.' || echo "no temp files"

echo "### P-i: second mktemp fails (PATH shim), via --bless and via --register"
cat > "$R/bin/mktemp" <<'SH'
#!/usr/bin/env bash
c="$TMPDIR/mktemp.count"; n=$(( $(cat "$c" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$c"
case "$*" in *.host-tools.*) echo "shim: mktemp failing on host-tools" >&2; exit 1 ;; esac
exec /usr/bin/mktemp "$@"
SH
chmod +x "$R/bin/mktemp"
mk "$D"; hm="$(sha256sum "$D/manifest.sha256" "$D/host-tools.sha256")"
bash "$D/cc-isolated.sh" --bless >/dev/null 2>"$R/i.err"; echo "bless exit=$?"; cat "$R/i.err"
[ "$hm" = "$(sha256sum "$D/manifest.sha256" "$D/host-tools.sha256")" ] && echo "manifests unchanged"
ls -A "$D" | grep -E '^\.(manifest|host-tools)\.' || echo "no temp files"
git -C "$ws" init -q 2>/dev/null
bash "$D/cc-isolated.sh" --register "$ws" > "$R/i2.out" 2>"$R/i2.err"; echo "register exit=$?"; tail -2 "$R/i2.out"; cat "$R/i2.err"
ls -A "$D" | grep -E '^\.(manifest|host-tools)\.' || echo "no temp files"
rm -f "$R/bin/mktemp"

echo "### P-j: bash temp-env assignment on a function call (scoping, leak, nested \$(...))"
bash -c 'set -euo pipefail; V=outer; cd_() { echo "${V:-unset}"; }; f() { echo "in f: $V / nested: $(cd_)"; return 1; }
if ! V=inner f; then echo "f failed as expected"; fi; echo "after: $V"
unset V; if ! V=inner f; then :; fi; echo "after (was unset): ${V-UNSET}"'
echo "--- same under --posix (not how the script runs)"
bash --posix -c 'V=outer; f() { :; }; V=inner f; echo "posix after: $V"'
echo "### done"
