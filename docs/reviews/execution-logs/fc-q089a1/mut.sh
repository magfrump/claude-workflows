#!/usr/bin/env bash
# Mutation: drop the `|| cfg_real=...` fallback in list_projects; the --list missing-parent test must fail.
set -u
P="${1:?probe root}"; [ -d "$P/src" ] || exit 99
M="$P/mut"; rm -rf "$M"; mkdir -p "$M"; cp -r "$P/src/devcontainer-config" "$P/src/test" "$M/"
f="$M/devcontainer-config/cc-isolated.sh"
grep -c 'cfg_real="$(readlink -f -- "$(config_dir)")" || cfg_real="$(config_dir)"' "$f"
python3 -I - "$f" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read()
old='cfg_real="$(readlink -f -- "$(config_dir)")" || cfg_real="$(config_dir)"'
assert s.count(old)==1; open(p,'w').write(s.replace(old,'cfg_real="$(readlink -f -- "$(config_dir)")"'))
PY
cd "$M" && env -i PATH=/usr/bin:/bin HOME="$P/home" TMPDIR="$P/tmp" LC_ALL=C timeout 300 bats -f 'config dir.s parent is missing' test/cc-isolated-functions.bats
echo "mutant rc=$?"
cd "$P/src" && env -i PATH=/usr/bin:/bin HOME="$P/home" TMPDIR="$P/tmp" LC_ALL=C timeout 300 bats -f 'config dir.s parent is missing' test/cc-isolated-functions.bats
echo "original rc=$?"
