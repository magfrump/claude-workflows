#!/usr/bin/env bash
# fc-q089a1 iteration-2 probes. $1 = probe root (mktemp -d, holding src/ = git archive b3b37e16). Aborts without it.
set -u
P="${1:?probe root}"; [ -d "$P/src/devcontainer-config" ] || { echo "no $P/src"; exit 99; }
export HOME="$P/home" TMPDIR="$P/tmp" LC_ALL=C
mkdir -p "$HOME" "$TMPDIR"
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
run() { echo "\$ $*"; timeout 30 "$@" 2>&1; echo "[rc=$?]"; }

echo "== Q1: refusal layout, two changed files + cc-push changed; launcher dir != CLAUDE_DEVC_CONFIG_DIR"
D="$P/q1/inst"; mkinst "$D"; mkdir -p "$P/q1/ws" "$P/q1/other"
CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --bless >/dev/null
echo '# t' >> "$D/cc-exit-scan.sh"; echo '# t' >> "$D/cc-gitdir.sh"; echo '# t' >> "$D/cc-push.sh"
CLAUDE_DEVC_CONFIG_DIR="$P/q1/other" timeout 30 bash "$D/cc-isolated.sh" "$P/q1/ws" > "$P/q1/out" 2>&1; echo "[rc=$?]"
cat -A "$P/q1/out"
echo "-- run the printed bless hint verbatim (line 2 of the hint block)"
hint="$(grep -- '--bless$' "$P/q1/out" | tail -1 | sed 's/^ *//')"; echo "hint: $hint"
( eval "$hint" ) > "$P/q1/bless.out" 2>&1; echo "[hint rc=$?]"; grep 'Blessed host tools' "$P/q1/bless.out"
CLAUDE_DEVC_CONFIG_DIR="$D" timeout 30 bash "$D/cc-isolated.sh" --list 2>&1 | grep 'Host tools'
[ -e "$P/q1/other/host-tools.sha256" ] && echo "other dir blessed (WRONG)" || echo "other dir untouched"

echo "== Q2: manifest-format check against every shape"
D="$P/q2/cfg"; mkinst "$D"; export CLAUDE_DEVC_CONFIG_DIR="$D"
bash "$D/cc-isolated.sh" --bless >/dev/null; cp "$D/host-tools.sha256" "$P/q2/good"
vh() { bash -c 'source "$1/cc-isolated.sh"; verify_host_tools "$1" cc-exit-scan.sh cc-gitdir.sh cc-push.sh' _ "$D" 2>&1; echo "[rc=$?]"; }
echo "-- a: as written by bless"; cat -A "$D/host-tools.sha256"; vh
echo "-- b: empty file"; : > "$D/host-tools.sha256"; vh
echo "-- c: no trailing newline"; printf '%s' "$(cat "$P/q2/good")" > "$D/host-tools.sha256"; vh
echo "-- d: trailing blank line"; { cat "$P/q2/good"; echo; } > "$D/host-tools.sha256"; vh
echo "-- e: CRLF"; sed 's/$/\r/' "$P/q2/good" > "$D/host-tools.sha256"; vh
echo "-- f: duplicate entry"; { cat "$P/q2/good"; head -1 "$P/q2/good"; } > "$D/host-tools.sha256"; vh
echo "-- g: one entry dropped"; tail -n +2 "$P/q2/good" > "$D/host-tools.sha256"; vh
echo "-- h: mode 000 as uid $(id -u)"; cp "$P/q2/good" "$D/host-tools.sha256"; chmod 000 "$D/host-tools.sha256"; vh; chmod 644 "$D/host-tools.sha256"
echo "-- i: sha256sum binary-mode '*' marker"; sed 's/  / */' "$P/q2/good" > "$D/host-tools.sha256"; vh
echo "-- j: uppercase hex"; tr 'a-f' 'A-F' < "$P/q2/good" | sed 's/ *\(CC\)/  cc/' > "$D/host-tools.sha256"; head -1 "$D/host-tools.sha256"; vh
cp "$P/q2/good" "$D/host-tools.sha256"
echo "-- k: does bless's own output pass for every PAYLOAD host tool name?"; bash -c 'source "$1/cc-isolated.sh"; host_tool_files' _ "$D" | grep -vE '^[A-Za-z0-9._-]+$' || echo "all names match [A-Za-z0-9._-]+"

echo "== Q3: --list shapes"
echo "-- a: match"; bash "$D/cc-isolated.sh" --list 2>&1 | grep -A2 'Host tools'
echo "-- b: missing manifest"; mv "$D/host-tools.sha256" "$P/q2/held"; bash "$D/cc-isolated.sh" --list 2>&1 | grep -A2 'host tools'
echo "-- c: dangling symlink manifest"; ln -s "$P/q2/nowhere" "$D/host-tools.sha256"; bash "$D/cc-isolated.sh" --list 2>&1 | grep -iA2 'host tools'; rm "$D/host-tools.sha256"
echo "-- d: symlink to a good manifest"; ln -s "$P/q2/held" "$D/host-tools.sha256"; bash "$D/cc-isolated.sh" --list 2>&1 | grep -iA2 'host tools'; rm "$D/host-tools.sha256"
mv "$P/q2/held" "$D/host-tools.sha256"
echo "-- e: CHANGED (scan + cc-push)"; echo '# z' >> "$D/cc-exit-scan.sh"; echo '# z' >> "$D/cc-push.sh"; bash "$D/cc-isolated.sh" --list 2>&1 | grep -A3 'Host tools'
echo "-- f: malformed"; bash "$D/cc-isolated.sh" --bless >/dev/null; printf 'junk\r\n' >> "$D/host-tools.sha256"; bash "$D/cc-isolated.sh" --list 2>&1 | grep -A3 'Host tools'
echo "-- g: unset CLAUDE_DEVC_CONFIG_DIR (default dir under redirected HOME)"; ( unset CLAUDE_DEVC_CONFIG_DIR; bash "$D/cc-isolated.sh" --list 2>&1 | grep -i 'host tools' )

echo "== Q4: boundary_note — a re-bless with the boundary unchanged leaves blessed_hash and verified-live intact"
D="$P/q4/cfg"; mkinst "$D"; export CLAUDE_DEVC_CONFIG_DIR="$D"; mkdir -p "$P/q4/ws"
bash "$D/cc-isolated.sh" --bless | grep 'Blessed config'
bash -c 'source "$1/cc-isolated.sh"; record_verified_live' _ "$D"; m0=$(sha256sum < "$D/manifest.sha256")
echo '# t' >> "$D/cc-exit-scan.sh"
timeout 30 bash "$D/cc-isolated.sh" "$P/q4/ws" 2>&1 | tail -1
bash "$D/cc-isolated.sh" --bless | grep 'Blessed config\|Verified live\|Changed since'
[ "$(sha256sum < "$D/manifest.sha256")" = "$m0" ] && echo "manifest.sha256 byte-identical" || echo "manifest.sha256 CHANGED"
