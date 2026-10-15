#!/usr/bin/env bash
# Probes for code-fact-check q089a iteration 3. Arg 1: the probe root (mktemp -d, holding src/).
set -u
P="${1:?probe root}"
[ -d "$P/src" ] || { echo "no $P/src; abort"; exit 99; }
cd "$P" || exit 99
export HOME="$P/home" TMPDIR="$P/tmp" CC_PUSH_CLONES_DIR="$P/clones" LC_ALL=C
mkdir -p "$HOME" "$TMPDIR" "$CC_PUSH_CLONES_DIR"
SRC="$P/src/devcontainer-config"
run() { echo "\$ $*"; "$@"; echo "[exit=$?]"; echo; }
fresh() { # fresh installed layout in $1 (no install.sh), blessed via the launcher
  rm -rf "$1"; mkdir -p "$1"
  for f in "$SRC"/*; do b="$(basename "$f")"; [ "$b" = install.sh ] && continue; cp -r "$f" "$1/"; done
  CLAUDE_DEVC_CONFIG_DIR="$1" timeout 60 bash "$1/cc-isolated.sh" --bless >/dev/null 2>&1
}
# stub devcontainer so the launcher gets past its CLI check
mkdir -p "$P/stub"; printf '#!/usr/bin/env bash\nexit 0\n' > "$P/stub/devcontainer"; chmod +x "$P/stub/devcontainer"
export PATH="$P/stub:$PATH"
D="$P/inst"; export CLAUDE_DEVC_CONFIG_DIR="$P/cfg"
date -u +%FT%TZ

echo "== P1 parity: the two marked blocks, byte for byte"
a="$(sed -n '/^# --- verify_host_tools/,/^# --- end verify_host_tools/p' "$SRC/cc-isolated.sh" | tail -n +2)"
b="$(sed -n '/^# --- verify_host_tools/,/^# --- end verify_host_tools/p' "$SRC/cc-push.sh" | tail -n +2)"
diff <(printf '%s\n' "$a") <(printf '%s\n' "$b") && echo "IDENTICAL ($(printf '%s\n' "$a" | wc -l) lines after the marker)"
echo

fresh "$D"
echo "== P2 manifest messages via the installed cc-push"
cp "$D/host-tools.sha256" "$P/h.good"
echo "-- empty"; : > "$D/host-tools.sha256"; run timeout 30 bash "$D/cc-push.sh" --help
echo "-- missing entry for cc-push.sh"; grep -v ' cc-push.sh$' "$P/h.good" > "$D/host-tools.sha256"; run timeout 30 bash "$D/cc-push.sh" --help
echo "-- duplicated entry for cc-gitdir.sh"; { cat "$P/h.good"; grep ' cc-gitdir.sh$' "$P/h.good"; } > "$D/host-tools.sha256"; run timeout 30 bash "$D/cc-push.sh" --help
echo "-- unreadable (uid $(id -u))"; cp "$P/h.good" "$D/host-tools.sha256"; chmod 000 "$D/host-tools.sha256"; run timeout 30 bash "$D/cc-push.sh" --help; chmod 644 "$D/host-tools.sha256"
echo "-- missing manifest"; rm "$D/host-tools.sha256"; run timeout 30 bash "$D/cc-push.sh" --help
echo "-- manifest a symlink"; ln -s "$P/h.good" "$D/host-tools.sha256"; run timeout 30 bash "$D/cc-push.sh" --help; rm "$D/host-tools.sha256"
echo "-- restored"; cp "$P/h.good" "$D/host-tools.sha256"; run timeout 30 bash "$D/cc-push.sh" --help >/dev/null
echo "-- grep for any remaining bare 'cc-isolated --bless' inside the reason strings of either copy"
grep -n 'echo "no host-tool manifest' "$SRC/cc-isolated.sh" "$SRC/cc-push.sh"

echo "== P3 launcher refusal indent: two launcher tools and cc-push changed"
fresh "$D"; mkdir -p "$P/ws"; git -C "$P/ws" init -q
echo '# t' >> "$D/cc-exit-scan.sh"; echo '# t' >> "$D/cc-gitdir.sh"; echo '# t' >> "$D/cc-push.sh"
CLAUDE_DEVC_CONFIG_DIR="$D" timeout 60 bash "$D/cc-isolated.sh" --probe-only "$P/ws" > "$P/l.out" 2> "$P/l.err"; echo "[exit=$?]"
echo "-- stderr, cat -A:"; cat -A "$P/l.err"
echo "-- launcher refusal with empty+missing-entry manifest:"
: > "$D/host-tools.sha256"; CLAUDE_DEVC_CONFIG_DIR="$D" timeout 60 bash "$D/cc-isolated.sh" --probe-only "$P/ws" 2>&1 | cat -A; echo
echo "-- cc-push refusal (two reasons) stderr, cat -A:"
fresh "$D"; echo '# t' >> "$D/cc-gitdir.sh"; echo '# t' >> "$D/cc-push.sh"
timeout 30 bash "$D/cc-push.sh" --help 2>&1 | cat -A; echo

echo "== P4 the while-read loop in isolation, under set -euo pipefail"
for v in 'one' $'one\ntwo' $'one\ntwo\n' '' ; do
  printf -- '-- input %q: ' "$v"
  bash -euo pipefail -c 'x="$1"; while IFS= read -r line; do printf "  %s\n" "$line"; done <<< "$x" >&2; echo "after loop rc=$?"' _ "$v" 2>&1 | cat -A
done
echo "-- does main's later 'local line' scope the loop's line? (same shape as cc-isolated main)"
bash -c 'f(){ while IFS= read -r line; do :; done <<< "a"; local line; }; f; echo "global line after f: [${line-UNSET}]"'

echo "== P5 tamper placement: does the moved touch detect a removed check?"
cp "$SRC/cc-push.sh" "$P/push.orig"
# mutant: the self-check block (CC_PUSH_DIR assignment kept) removed
awk '/^if ! host_tools_err=/ {skip=1} skip && /^fi$/ {skip=0; next} !skip {print}' "$P/push.orig" > "$P/push.nocheck"
echo "-- mutant diff:"; diff "$P/push.orig" "$P/push.nocheck"
for variant in orig nocheck; do
  for place in below-check end-of-file; do
    fresh "$D"; rm -f "$P/tamper-ran"
    if [ "$place" = below-check ]; then
      awk -v t="touch $P/tamper-ran" '/^# shellcheck source=cc-gitdir.sh$/ { print t } { print }' "$P/push.$variant" > "$D/cc-push.sh"
    else
      { cat "$P/push.$variant"; echo "touch $P/tamper-ran"; } > "$D/cc-push.sh"
    fi
    if [ "$variant" = nocheck ]; then :; fi
    timeout 30 bash "$D/cc-push.sh" --help >/dev/null 2>&1; rc=$?
    echo "variant=$variant place=$place rc=$rc tamper-ran=$([ -e "$P/tamper-ran" ] && echo yes || echo no)"
  done
done
date -u +%FT%TZ
