#!/usr/bin/env bash
set -u
P="${1:?}"; [ -d "$P/inst dir" ] || exit 99
export HOME="$P/home" TMPDIR="$P/tmp" CC_PUSH_CLONES_DIR="$P/clones" LC_ALL=C CLAUDE_DEVC_CONFIG_DIR="$P/cfg"
D="$P/inst dir"
cp "$D/cc-push.sh" "$P/push.bak2"
echo "== P6b overwrite that replaces the check (lines 198-206) with a touch; run --help"
awk -v m="$P/drop-ran" 'NR==198{print "touch \"" m "\""} NR>=198 && NR<=206 {next} {print}' "$P/push.bak2" > "$D/cc-push.sh"
timeout 30 bash "$D/cc-push.sh" --help > /dev/null 2>"$P/6b.err"; echo "[exit=$?] stderr: $(cat "$P/6b.err")"
echo "drop-ran exists? $([ -e "$P/drop-ran" ] && echo yes || echo no)"
cp "$P/push.bak2" "$D/cc-push.sh"
timeout 30 bash "$D/cc-push.sh" --help > /dev/null; echo "[restored, exit=$?]"
