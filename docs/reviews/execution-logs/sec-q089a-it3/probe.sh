#!/usr/bin/env bash
# Security it3 probes. $1 = probe root (must exist). Everything hermetic.
set -u
R="$1"; [ -d "$R/src" ] || { echo "no root"; exit 1; }
cd "$R" || exit 1
export HOME="$R/home" TMPDIR="$R/tmp" CC_PUSH_CLONES_DIR="$R/clones" CLAUDE_DEVC_CONFIG_DIR="$R/cfg" LC_ALL=C
export PATH="$R/bin:/usr/local/bin:/usr/bin:/bin"
S="$R/src/devcontainer-config"
mk() { # mk DIR: installed-style copy of the four host-side files, blessed host-tools.sha256
  rm -rf "$1"; mkdir -p "$1"
  cp "$S/cc-push.sh" "$S/cc-gitdir.sh" "$S/cc-isolated.sh" "$S/cc-exit-scan.sh" "$1/"
  (cd "$1" && sha256sum cc-exit-scan.sh cc-gitdir.sh cc-push.sh > host-tools.sha256)
}
run() { local n="$1"; shift; local out rc; out="$(timeout 20 "$@" 2>&1)"; rc=$?; echo "[$n] rc=$rc"; printf '%s\n' "$out" | head -8 | sed 's/^/    /'; }
D="$R/inst"
mk "$D"; run Q1-baseline-help bash "$D/cc-push.sh" --help
mk "$D"; sed -i 's/^\([0-9a-f]*\)  cc-push.sh$/\1 *cc-push.sh/' "$D/host-tools.sha256"; grep -c '\*cc-push' "$D/host-tools.sha256"
run Q2-binary-mode-line bash "$D/cc-push.sh" --help
mk "$D"; tr a-f A-F < "$D/host-tools.sha256" | sed 's/  CC-/  cc-/; s/SCAN/scan/; s/GITDIR/gitdir/; s/PUSH/push/; s/\.SH/.sh/; s/EXIT/exit/' > "$D/h2"; mv "$D/h2" "$D/host-tools.sha256"; head -1 "$D/host-tools.sha256"
run Q3a-uppercase-hex-C bash "$D/cc-push.sh" --help
loc="$(locale -a 2>/dev/null | grep -iE '^(en_US|C)\.utf-?8$' | head -1)"; echo "utf8 locale: ${loc:-none}"
[ -n "$loc" ] && run Q3b-uppercase-hex-utf8 env LC_ALL="$loc" bash "$D/cc-push.sh" --help
mk "$D"; rm "$D/host-tools.sha256"; mkfifo "$D/host-tools.sha256"; run Q4-fifo-manifest bash "$D/cc-push.sh" --help
mk "$D"; rm "$D/host-tools.sha256"; mkdir "$D/host-tools.sha256"; run Q5-dir-manifest bash "$D/cc-push.sh" --help
# Q6: an executable line ABOVE the check runs (documented limit).
mk "$D"; awk -v t="touch $R/q6-above-ran" '{ print } /^safe_path$/ { print t }' "$S/cc-push.sh" > "$D/cc-push.sh"; rm -f "$R/q6-above-ran"
run Q6-tamper-above-check bash "$D/cc-push.sh" --help; [ -e "$R/q6-above-ran" ] && echo "    Q6 above-check line RAN (expected, documented)"
# Q7: exported function shadows sha256sum, tampered cc-gitdir.sh.
mk "$D"; good="$(grep ' cc-gitdir.sh$' "$D/host-tools.sha256" | cut -d' ' -f1)"; echo "touch $R/q7-gitdir-ran" >> "$D/cc-gitdir.sh"; rm -f "$R/q7-gitdir-ran"
run Q7a-no-shim bash "$D/cc-push.sh" --help; [ -e "$R/q7-gitdir-ran" ] && echo "    Q7a payload RAN" || echo "    Q7a payload not run"
pushhash="$(grep ' cc-push.sh$' "$D/host-tools.sha256" | cut -d' ' -f1)"
fn="() { local x; x=\"\$(cat)\"; case \"\$x\" in *q7-gitdir-ran*) echo \"$good  -\" ;; *) echo \"$pushhash  -\" ;; esac; }"
run Q7b-exported-fn-shim env "BASH_FUNC_sha256sum%%=$fn" bash "$D/cc-push.sh" --help; [ -e "$R/q7-gitdir-ran" ] && echo "    Q7b payload RAN (exported-function bypass)" || echo "    Q7b payload not run"
# Q10: copy that dropped its check: --list labelling, and it runs.
mk "$D"; awk '/^CC_PUSH_DIR=/{skip=1} skip && /^fi$/ {skip=0; next} !skip' "$S/cc-push.sh" | sed 's|^source "\$CC_PUSH_DIR/cc-gitdir.sh"|source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"|' > "$D/cc-push.sh"
grep -c 'verify_host_tools "\$CC_PUSH_DIR"' "$D/cc-push.sh"
run Q10a-list env CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --list
run Q10b-dropped-check-runs bash "$D/cc-push.sh" --help
# Q12: hint quoting for an awkward dir name.
D2="$R/in st'x"; mk "$D2"; echo '# edit' >> "$D2/cc-gitdir.sh"; run Q12-hint-quoting bash "$D2/cc-push.sh" --help
