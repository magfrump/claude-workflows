#!/bin/bash
# probe3: mutation-check the transitive source-set test. $1 = probe root
P="$1"; cd "$P" || exit 1
export HOME="$P/home3"; mkdir -p "$HOME"; export CLAUDE_DEVC_CONFIG_DIR="$P/cfg3"
T='every file an entry point sources'
run() { ( cd "$P/mut" && timeout 120 bats -f "$T" test/cc-isolated-functions.bats 2>&1 | grep -E '^(ok|not ok)|# ' | head -4 ); }
fresh() { rm -rf "$P/mut"; cp -R "$P/head" "$P/mut"; }
C=mut/devcontainer-config
echo "== M0 unmodified"; fresh; run
echo "== M1 drop cc-gitdir.sh from launcher list"; fresh
sed -i 's/verify_host_tools "\$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh/verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh/' $C/cc-isolated.sh; grep -n 'verify_host_tools "\$CC_ISOLATED_DIR"' $C/cc-isolated.sh; run
echo "== M2 scan sources a new helper with the dot form"; fresh
echo 'echo hi' > $C/cc-new.sh
sed -i '12a . "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-new.sh"' $C/cc-exit-scan.sh; sed -n 12,13p $C/cc-exit-scan.sh; run
echo "== M3 launcher sources a new helper inside a one-line if"; fresh
echo 'echo hi' > $C/cc-new.sh
sed -i '/^  source "\$CC_ISOLATED_DIR\/cc-exit-scan.sh"/a\  if true; then source "$CC_ISOLATED_DIR/cc-new.sh"; fi' $C/cc-isolated.sh; grep -n 'cc-new' $C/cc-isolated.sh; run
echo "== M4 plain source line of a new helper in the scan (control: should fail)"; fresh
echo 'echo hi' > $C/cc-new.sh
sed -i '12a source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-new.sh"' $C/cc-exit-scan.sh; run
echo "== M5 helper with a digit/underscore in its name"; fresh
echo 'echo hi' > $C/cc_new2.sh
sed -i '12a source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc_new2.sh"' $C/cc-exit-scan.sh; run
rm -rf "$P/mut"
