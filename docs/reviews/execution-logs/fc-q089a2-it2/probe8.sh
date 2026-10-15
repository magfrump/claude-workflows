#!/usr/bin/env bash
# Mutation probe: is the self-tamper test's not-ran assertion able to fail?
set -u
P="${1:?}"; [ -d "$P/src" ] || exit 99
export HOME="$P/home" TMPDIR="$P/tmp" CC_PUSH_CLONES_DIR="$P/clones" LC_ALL=C CLAUDE_DEVC_CONFIG_DIR="$P/cfg"
S="$P/src/devcontainer-config"; d="$P/mut"; M="$P/mutmarks"
rm -rf "$d" "$M"; mkdir -p "$d" "$M"
# Mutant: the self-check block (cc-push.sh:198-206) deleted outright.
awk 'NR>=198 && NR<=206 {next} {print}' "$S/cc-push.sh" > "$d/cc-push.sh"
cp "$S/cc-gitdir.sh" "$d/"
echo "mutant has a verify call? $(grep -c 'host_tools_err=' "$d/cc-push.sh")"
(cd "$d" && sha256sum cc-gitdir.sh cc-push.sh > host-tools.sha256)
# The test's exact tamper: append a touch at EOF.
printf 'touch %q\n' "$M/push-tamper-ran" >> "$d/cc-push.sh"
for args in "--help" "--bogus-flag" "--remote $P/none.git --yes $P/no-such-checkout"; do
  timeout 30 bash "$d/cc-push.sh" $args >/dev/null 2>&1; rc=$?
  echo "args=[$args] exit=$rc marker=$([ -e "$M/push-tamper-ran" ] && echo RAN || echo absent)"
done
echo "-- same tamper placed directly below where the check was (line 198)"
awk -v m="$M/below-ran" 'NR==198{print "touch \"" m "\""} NR>=198 && NR<=206 {next} {print}' "$S/cc-push.sh" > "$d/cc-push.sh"
timeout 30 bash "$d/cc-push.sh" --help >/dev/null 2>&1; echo "exit=$? marker=$([ -e "$M/below-ran" ] && echo RAN || echo absent)"
