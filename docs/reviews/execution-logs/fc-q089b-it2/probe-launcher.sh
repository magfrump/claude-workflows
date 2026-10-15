#!/usr/bin/env bash
# Launcher and cc-push behaviour the guides describe, against an installed-style
# copy (no install.sh beside the scripts) under this probe root. $1 = probe root.
D="$1"
case "$D" in /home/node/.claude/jobs/00bcf178/tmp/fc-it2.*) ;; *) echo "bad D"; exit 1 ;; esac
export HOME="$D/home" LC_ALL=C
unset CLAUDE_DEVC_CONFIG_DIR
I="$D/inst"
rm -rf "$I"; mkdir -p "$I" "$HOME"
cp "$D/src/devcontainer-config/cc-isolated.sh" "$D/src/devcontainer-config/cc-exit-scan.sh" \
   "$D/src/devcontainer-config/cc-gitdir.sh" "$D/src/devcontainer-config/cc-push.sh" "$I/"
cd "$I" || exit 1
show() { echo "\$ $*"; timeout 20 "$@" > "$D/tmpd/out" 2>&1; local st=$?; head -12 "$D/tmpd/out"; echo "exit=$st"; echo; }
echo "start: $(date -u +%FT%TZ) cwd: $PWD"
echo "### A: installed copy, no host-tools.sha256 (an install that predates row 71)"
show bash "$I/cc-push.sh" --help
show bash "$I/cc-isolated.sh" --help
show bash "$I/cc-isolated.sh" --bogus-flag
show bash "$I/cc-isolated.sh"
echo "### B: host-tools.sha256 present, cc-exit-scan.sh hash wrong"
for f in cc-exit-scan.sh cc-gitdir.sh cc-push.sh; do sha256sum "$f"; done > host-tools.sha256
sed -i '1s/^./0/' host-tools.sha256
show bash "$I/cc-isolated.sh" --help
show bash "$I/cc-isolated.sh" --bogus-flag
show bash "$I/cc-isolated.sh" --profile
show bash "$I/cc-isolated.sh"
echo "### C: malformed host-tools.sha256"
echo garbage > host-tools.sha256
show bash "$I/cc-isolated.sh"
