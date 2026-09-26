#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2034  # a saved review probe: dynamic source path; kept verbatim as run
# Claim 27(a) probe: procs_in_checkout (install.sh:1119-1173, sourced verbatim) with a
# `readlink` shell function that fails for every /proc entry except a chosen one.
set -euo pipefail
SRC=/workspace/devcontainer-config/install.sh
LIB="$(mktemp "${TMPDIR:-/tmp}/c27lib.XXXX")"; REPO_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/c27root.XXXX")"
trap 'rm -f "$LIB"; rm -rf "$REPO_ROOT"' EXIT
sed -n '1119,1173p' "$SRC" > "$LIB"; source "$LIB"
run() { rc=0; out="$(procs_in_checkout)" || rc=$?; echo "$1: rc=$rc"; }
# The shim runs inside $(readlink ...), a child of the scan subshell, so the scan
# subshell's PID is this child's PPid.
readlink() { local k v scan=""; while read -r k v; do [ "$k" = PPid: ] && scan=$v; done < /proc/$BASHPID/status
  if [ "$ALLOW" = self ] && [ "$1" = "/proc/$scan/cwd" ]; then command readlink "$@"; else return 1; fi; }
ALLOW=self; run "every entry fails except the scan subshell's own"
ALLOW=none; run "every entry fails, own included"
unset -f readlink; run "no shim"
