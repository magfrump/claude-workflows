#!/usr/bin/env bash
# Do candidate `git status` flags stop the hook and submodule routes (SP3b-d)?
# Hermetic: temp HOME, empty global config, no system config.
# Writes fix-flags-probe.log next to this script.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$(mktemp -d "${TMPDIR:-/tmp}/fixflags.XXXXXX")"
export HOME="$P/home" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$P/empty"
mkdir -p "$HOME"; : > "$GIT_CONFIG_GLOBAL"
G() { git -c user.email=t@t -c user.name=t "$@"; }
try() {
  rm -f "$P/marks"; sleep 1; touch skills/a.txt skills/sub/s.txt
  local out
  out="$(git "$@" -- skills)"
  echo "[git $*] status='$out' marks: $(tr '\n' ' ' < "$P/marks" 2>/dev/null || echo none)"
}
{
  git --version
  git init -q "$P/sub"; echo s > "$P/sub/s.txt"; G -C "$P/sub" add .; G -C "$P/sub" commit -qm s
  git init -q "$P/r"; cd "$P/r"
  mkdir skills; echo a > skills/a.txt; G add .; G commit -qm i
  G -c protocol.file.allow=always submodule add -q "$P/sub" skills/sub; G commit -qm sub
  md=.git/modules/skills/sub
  git -C skills/sub config filter.pwn.clean "sh -c 'echo sub-clean >> $P/marks; cat'"
  echo '* filter=pwn' > "$md/info/attributes"
  for h in .git/hooks "$md/hooks"; do
    printf '#!/bin/sh\necho hook:%s >> "%s/marks"\n' "$h" "$P" > "$h/post-index-change"
    chmod +x "$h/post-index-change"
  done
  base=(-c core.quotePath=true -c core.fsmonitor=false)
  st=(status --porcelain --untracked-files=all)
  echo "1. install.sh at feba07d:"
  try "${base[@]}" "${st[@]}"
  echo "2. + --no-optional-locks -c core.hooksPath=/dev/null:"
  try --no-optional-locks "${base[@]}" -c core.hooksPath=/dev/null "${st[@]}"
  echo "3. + --ignore-submodules=all:"
  try --no-optional-locks "${base[@]}" -c core.hooksPath=/dev/null "${st[@]}" --ignore-submodules=all
} > "$here/fix-flags-probe.log" 2>&1
rm -rf "$P"
cat "$here/fix-flags-probe.log"
