#!/usr/bin/env bash
# Does `ln -s dir/* farm/` keep going past "File exists", so the first PATH dir wins?
set -uo pipefail
T="$(mktemp -d "${TMPDIR:-/tmp}/lnfw.XXXXXX")"
mkdir -p "$T/a" "$T/b" "$T/farm" "$T/empty"
printf 'A\n' > "$T/a/x"; printf 'B\n' > "$T/b/x"; printf 'B\n' > "$T/b/y"; printf 'B\n' > "$T/b/z"
ln -s "$T/a"/* "$T/farm/"; echo "ln a rc=$?"
ln -s "$T/b"/* "$T/farm/"; echo "ln b rc=$? (x already present)"
echo "farm/x -> $(readlink "$T/farm/x"); y present: $([ -L "$T/farm/y" ] && echo yes); z present: $([ -L "$T/farm/z" ] && echo yes)"
ln -s "$T/empty"/* "$T/farm/" 2>&1; echo "empty dir: rc=$?; literal '*' link: $([ -L "$T/farm/*" ] && echo yes || echo no)"
rm -rf "$T"
