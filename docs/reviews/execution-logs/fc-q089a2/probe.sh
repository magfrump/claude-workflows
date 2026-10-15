#!/usr/bin/env bash
# Probes for the code-fact-check of Q-089 A2. Arg 1: the probe work dir (mktemp'd).
set -u
W="${1:?work dir}"
[ -d "$W/src/devcontainer-config" ] || { echo "no extract at $W/src"; exit 99; }
cd "$W" || exit 99
export HOME="$W/home" CLAUDE_DEVC_CONFIG_DIR="$W/cfg" TMPDIR="$W/tmp" CC_PUSH_CLONES_DIR="$W/clones" LC_ALL=C
S="$W/src/devcontainer-config"
P="$W/probes"; rm -rf "$P"; mkdir -p "$P"

inst() { # inst DIR: an installed-layout copy with a fresh host manifest
  mkdir -p "$1"; cp "$S/cc-push.sh" "$S/cc-gitdir.sh" "$1/"
  (cd "$1" && sha256sum cc-gitdir.sh cc-push.sh > host-tools.sha256)
}
show() { echo "--- $1: exit=$2"; }

# P1: tamper INSIDE the prologue (before the check, after set -euo pipefail).
d="$P/p1"; inst "$d"
awk -v m="$P/p1-prologue-ran" 'NR==118 { print "touch " m } { print }' "$S/cc-push.sh" > "$d/cc-push.sh"
out="$(timeout 20 bash "$d/cc-push.sh" --help 2>&1)"; rc=$?
show "P1 prologue tamper, --help" $rc; echo "$out" | head -3
[ -e "$P/p1-prologue-ran" ] && echo "P1 RESULT: prologue code RAN before the refusal" || echo "P1 RESULT: prologue code did not run"

# P2: tamper AFTER the check (a command on the line right after the check's fi), and at EOF.
d="$P/p2"; inst "$d"
awk -v m="$P/p2-after-ran" '{ print } NR==191 { print "touch " m }' "$S/cc-push.sh" > "$d/cc-push.sh"
printf 'touch %s\n' "$P/p2-eof-ran" >> "$d/cc-push.sh"
out="$(timeout 20 bash "$d/cc-push.sh" --help 2>&1)"; rc=$?
show "P2 post-check tamper, --help" $rc; echo "$out" | head -3
[ -e "$P/p2-after-ran" ] && echo "P2 RESULT: post-check line RAN" || echo "P2 RESULT: post-check line did not run"
[ -e "$P/p2-eof-ran" ] && echo "P2 RESULT: EOF line RAN" || echo "P2 RESULT: EOF line did not run"

# P3: a self-skipping tamper (check removed, payload added): nothing in cc-push catches it.
d="$P/p3"; inst "$d"
awk -v m="$P/p3-ran" 'NR==188 { print "if false; then" ; next } NR==193 { print; print "touch " m; next } { print }' "$S/cc-push.sh" > "$d/cc-push.sh"
out="$(timeout 20 bash "$d/cc-push.sh" --help 2>&1)"; rc=$?
show "P3 self-skipping tamper, --help" $rc
[ -e "$P/p3-ran" ] && echo "P3 RESULT: self-skipping tamper ran unrefused" || echo "P3 RESULT: refused"

# P4: host-tools.sha256 a symlink to a correct manifest.
d="$P/p4"; inst "$d"; mv "$d/host-tools.sha256" "$d/real.sha256"; ln -s real.sha256 "$d/host-tools.sha256"
out="$(timeout 20 bash "$d/cc-push.sh" --help 2>&1)"; rc=$?
show "P4 manifest symlink" $rc; echo "$out" | head -2

# P5: repo-checkout exemption. install.sh beside, no manifests -> unchecked (even with tampered gitdir).
d="$P/p5"; mkdir -p "$d"; cp "$S/cc-push.sh" "$S/cc-gitdir.sh" "$S/install.sh" "$d/"
out="$(timeout 20 bash "$d/cc-push.sh" --help 2>&1)"; rc=$?
show "P5a install.sh beside, no manifests" $rc
touch "$d/manifest.sha256"
out="$(timeout 20 bash "$d/cc-push.sh" --help 2>&1)"; rc=$?
show "P5b install.sh + manifest.sha256, no host manifest" $rc; echo "$out" | head -1
rm "$d/manifest.sha256"
out="$(CLAUDE_DEVC_CONFIG_DIR="$d" timeout 20 bash "$d/cc-push.sh" --help 2>&1)"; rc=$?
show "P5c install.sh beside but dir is CLAUDE_DEVC_CONFIG_DIR" $rc; echo "$out" | head -1

# P6: via a PATH symlink named cc-push: the installed copy's dir is the one checked.
d="$P/p6"; inst "$d"; mkdir -p "$P/bin"; ln -s "$d/cc-push.sh" "$P/bin/cc-push"
printf '\n# edited\n' >> "$d/cc-gitdir.sh"
out="$(timeout 20 bash "$P/bin/cc-push" --help 2>&1)"; rc=$?
show "P6 via symlink, tampered gitdir" $rc; echo "$out" | head -1

# P7: both files changed: both named in one refusal.
d="$P/p7"; inst "$d"; printf '\n# e\n' >> "$d/cc-gitdir.sh"; printf '\n# e\n' >> "$d/cc-push.sh"
out="$(timeout 20 bash "$d/cc-push.sh" --help 2>&1)"; rc=$?
show "P7 both changed" $rc; echo "$out"

# P8: duplicate entry for cc-push.sh in the manifest -> refused (n != 1).
d="$P/p8"; inst "$d"; grep ' cc-push.sh$' "$d/host-tools.sha256" >> "$d/host-tools.sha256"
out="$(timeout 20 bash "$d/cc-push.sh" --help 2>&1)"; rc=$?
show "P8 duplicate entry" $rc; echo "$out" | head -1

# P9: mutation of the exemption (manifest.sha256 condition removed) vs the new cc-push test's assertions.
d="$P/p9"; inst "$d"
sed 's/ && \[ ! -e "\$dir\/manifest.sha256" \]//' "$S/cc-push.sh" > "$d/cc-push.sh"
grep -c 'manifest.sha256" \]' "$d/cc-push.sh"
(cd "$d" && sha256sum cc-gitdir.sh cc-push.sh > host-tools.sha256)
touch "$d/manifest.sha256"; rm "$d/host-tools.sha256"
out="$(timeout 20 bash "$d/cc-push.sh" --help 2>&1)"; rc=$?
show "P9 mutant exemption, test's final step (no install.sh in dir)" $rc; echo "$out" | head -1
