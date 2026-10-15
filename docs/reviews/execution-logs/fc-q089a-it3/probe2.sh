#!/usr/bin/env bash
# Probe 2 for code-fact-check q089a it3: header claims of cc-push. Arg 1: probe root holding src/ and push.nocheck.
set -u
P="${1:?probe root}"; [ -d "$P/src" ] && [ -f "$P/push.nocheck" ] || { echo "abort"; exit 99; }
cd "$P" || exit 99
export HOME="$P/home" TMPDIR="$P/tmp" CC_PUSH_CLONES_DIR="$P/clones" LC_ALL=C
export PATH="$P/stub:$PATH"; export CLAUDE_DEVC_CONFIG_DIR="$P/cfg"
SRC="$P/src/devcontainer-config"
fresh() { rm -rf "$1"; mkdir -p "$1"; for f in "$SRC"/*; do b="$(basename "$f")"; [ "$b" = install.sh ] && continue; cp -r "$f" "$1/"; done
  CLAUDE_DEVC_CONFIG_DIR="$1" timeout 60 bash "$1/cc-isolated.sh" --bless >/dev/null 2>&1; }
run() { echo "\$ $*"; "$@"; echo "[exit=$?]"; echo; }
date -u +%FT%TZ
D="$P/instD"; E="$P/instE"; fresh "$D"; fresh "$E"; mkdir -p "$P/ws"
echo "== Q1 before parsing anything: a bad flag on a refusing copy exits 1, not 2"
echo '# t' >> "$D/cc-gitdir.sh"; run timeout 30 bash "$D/cc-push.sh" --no-such-flag
fresh "$D"; run timeout 30 bash "$D/cc-push.sh" --no-such-flag
echo "== Q2 a cc-push overwrite that drops its check: who reports it"
cp "$P/push.nocheck" "$D/cc-push.sh"
run timeout 30 bash "$D/cc-push.sh" --help >/dev/null
echo "-- launcher beside it (D):"; run env CLAUDE_DEVC_CONFIG_DIR="$D" timeout 60 bash "$D/cc-isolated.sh" --probe-only "$P/ws"
echo "-- launcher in another install (E), config dir D:"; run env CLAUDE_DEVC_CONFIG_DIR="$D" timeout 60 bash "$E/cc-isolated.sh" --probe-only "$P/ws"
echo "-- --list from E with config dir D:"; run env CLAUDE_DEVC_CONFIG_DIR="$D" timeout 60 bash "$E/cc-isolated.sh" --list
date -u +%FT%TZ
