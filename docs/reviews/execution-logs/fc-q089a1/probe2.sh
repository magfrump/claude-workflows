#!/usr/bin/env bash
# --list vs actual launch, when the launcher run is the repo checkout and CLAUDE_DEVC_CONFIG_DIR names a tampered installed dir.
set -u
P="${1:?}"; [ -d "$P/p5/cfg" ] || exit 99
export HOME="$P/home" TMPDIR="$P/tmp" LC_ALL=C PATH="$P/stub/bin:$PATH"
D="$P/p5/cfg"; mkdir -p "$P/p7/ws"; git -C "$P/p7/ws" init -q
echo "-- --list (repo-checkout launcher, env -> tampered dir)"
CLAUDE_DEVC_CONFIG_DIR="$D" timeout 30 bash "$P/src/devcontainer-config/cc-isolated.sh" --list 2>&1 | grep -A2 'Host tools'
echo "-- launch (same)"
CLAUDE_DEVC_CONFIG_DIR="$D" timeout 60 bash "$P/src/devcontainer-config/cc-isolated.sh" "$P/p7/ws" > "$P/p7/launch.out" 2>&1; echo "rc=$?"
grep -c 'refusing to run the session-exit scan' "$P/p7/launch.out"; head -5 "$P/p7/launch.out"
