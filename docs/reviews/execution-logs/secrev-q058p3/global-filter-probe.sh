#!/usr/bin/env bash
# Pass 3: does git archive run a GLOBAL filter driver assigned by a COMMITTED
# .gitattributes, past git_state_gate (which reads only local config +
# .git/info/attributes) and the repo_git flags at 516124d? Hermetic: temp HOME,
# no system config, throwaway repo. Writes global-filter-probe.log next to this.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$(mktemp -d "${TMPDIR:-/tmp}/gfilter.XXXXXX")"
export HOME="$P/home" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$P/gcfg"; mkdir -p "$HOME"
G(){ git -c user.email=t@t -c user.name=t "$@"; }
R(){ local r="$1"; shift; git --no-optional-locks -C "$r" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"; }
{
  git --version
  printf '#!/bin/sh\necho GLOBAL-SMUDGE-RAN >> "%s/marks"\ncat\n' "$P" > "$P/gs.sh"; chmod +x "$P/gs.sh"
  printf '[filter "pwn"]\n\tsmudge = %s/gs.sh\n\tclean = cat\n' "$P" > "$GIT_CONFIG_GLOBAL"
  git init -q "$P/r"; mkdir -p "$P/r/skills"; echo committed > "$P/r/skills/a.txt"
  printf 'skills/a.txt filter=pwn\n' > "$P/r/.gitattributes"   # COMMITTED, not info/attributes
  G -C "$P/r" add -A; G -C "$P/r" commit -qm i
  : > "$P/marks"
  echo "git_state_gate local-config/attributes read (empty = gate passes):"
  git --no-pager -c core.hooksPath=/dev/null config --file "$P/r/.git/config" --no-includes --get-regexp '^(filter\.|core\.fsmonitor|include)' || true
  echo "  .git/info/attributes non-empty: $([ -s "$P/r/.git/info/attributes" ] && echo yes || echo no)"
  R "$P/r" -c tar.umask=022 archive --format=tar HEAD -- skills | tar -xO >/dev/null 2>&1
  echo "archive marks: $(cat "$P/marks" 2>/dev/null || echo none)"
} > "$here/global-filter-probe.log" 2>&1
find "$P" -maxdepth 0 -type d >/dev/null
cat "$here/global-filter-probe.log"
