#!/usr/bin/env bash
# Probes for code-fact-check q089a2 iteration 2. Arg 1: the probe root (mktemp -d).
set -u
P="${1:?probe root}"
[ -d "$P/src" ] || { echo "no $P/src; abort"; exit 99; }
cd "$P" || exit 99
export HOME="$P/home" TMPDIR="$P/tmp" CC_PUSH_CLONES_DIR="$P/clones" LC_ALL=C
SRC="$P/src/devcontainer-config"
D="$P/inst dir"          # installed layout, a space in the name for %q
rm -rf "$D"; mkdir -p "$D"
for f in "$SRC"/*; do
  b="$(basename "$f")"; [ "$b" = install.sh ] && continue
  cp -r "$f" "$D/"
done
export CLAUDE_DEVC_CONFIG_DIR="$P/cfg"   # deliberately NOT the install dir
mkdir -p "$P/bin"; ln -sf "$D/cc-isolated.sh" "$P/bin/cc-isolated"
run() { echo "\$ $*"; "$@"; echo "[exit=$?]"; echo; }

echo "== P0 initial bless of the install dir via the hint form"
run env CLAUDE_DEVC_CONFIG_DIR="$D" timeout 60 bash "$D/cc-isolated.sh" --bless
run timeout 30 bash "$D/cc-push.sh" --help >/dev/null

echo "== P1 refusal layout: cc-gitdir.sh changed, install dir with a space"
printf 'touch %q\n' "$P/gitdir-ran" >> "$D/cc-gitdir.sh"
run timeout 30 bash "$D/cc-push.sh" --help
echo "gitdir-ran exists? $([ -e "$P/gitdir-ran" ] && echo yes || echo no)"

echo "== P2 the printed hint, run verbatim (cc-isolated on PATH), clears the refusal and prints what changed"
hint="$(bash "$D/cc-push.sh" --help 2>&1 | sed -n 's/^    //p')"
echo "hint: $hint"
run env PATH="$P/bin:$PATH" timeout 60 bash -c "$hint"
run timeout 30 bash "$D/cc-push.sh" --help >/dev/null

echo "== P3 missing manifest: reason line carries its own bare hint"
mv "$D/host-tools.sha256" "$P/ht.bak"
run timeout 30 bash "$D/cc-push.sh" --help
mv "$P/ht.bak" "$D/host-tools.sha256"

echo "== P4 malformed manifest (CRLF line) and unreadable manifest"
cp "$D/host-tools.sha256" "$P/ht.bak"
sed -i '1s/$/\r/' "$D/host-tools.sha256"
run timeout 30 bash "$D/cc-push.sh" --help
cp "$P/ht.bak" "$D/host-tools.sha256"; chmod 000 "$D/host-tools.sha256"
run timeout 30 bash "$D/cc-push.sh" --help
chmod 644 "$D/host-tools.sha256"
run timeout 30 bash "$D/cc-push.sh" --help >/dev/null

echo "== P5 tamper above the check runs, then cc-push still refuses"
cp "$D/cc-push.sh" "$P/push.bak"
awk -v m="$P/above-ran" 'NR==121{print "touch \"" m "\""} {print}' "$P/push.bak" > "$D/cc-push.sh"
run timeout 30 bash "$D/cc-push.sh" --help
echo "above-ran exists? $([ -e "$P/above-ran" ] && echo yes || echo no)"

echo "== P6 an overwrite that drops the check runs unrefused; the launcher warns, --list reports"
awk 'NR>=198 && NR<=206 {next} {print}' "$P/push.bak" > "$D/cc-push.sh"
printf 'touch %q\n' "$P/drop-ran" >> "$D/cc-push.sh"
run timeout 30 bash "$D/cc-push.sh" --help >/dev/null
echo "drop-ran exists? $([ -e "$P/drop-ran" ] && echo yes || echo no)"
mkdir -p "$P/ws"; git -C "$P/ws" init -q 2>/dev/null
run env CLAUDE_DEVC_CONFIG_DIR="$D" PATH="/usr/bin:/bin" timeout 30 bash "$D/cc-isolated.sh" --probe-only "$P/ws"
run env CLAUDE_DEVC_CONFIG_DIR="$D" timeout 30 bash "$D/cc-isolated.sh" --list
echo "-- launcher run from another dir (repo checkout) does not see the installed cc-push"
run env CLAUDE_DEVC_CONFIG_DIR="$P/cfg" PATH="/usr/bin:/bin" timeout 30 bash "$SRC/cc-isolated.sh" --probe-only "$P/ws"
cp "$P/push.bak" "$D/cc-push.sh"

echo "== P7 header text as --help prints it (rows covering the exception)"
run timeout 30 bash "$D/cc-push.sh" --help
