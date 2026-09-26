#!/usr/bin/env bash
# Claim 27 probe (standalone; does not run install.sh and does not lower any limit
# outside the one scan subshell being tested). Sources install.sh's own text for
# CLAUDE_PROC_RE (:1110), ppid_of/in_lineage/procs_in_checkout (:1119-1173) and
# agent_gate (:1178-1266), extracted by line number at HEAD, under install.sh's
# `set -euo pipefail` (:26). A DEBUG trap, inherited into the $(procs_in_checkout)
# subshell by `set -T`, runs `ulimit -u 1` in THAT subshell only, just before a
# chosen command, so every later fork in the scan fails (RLIMIT_NPROC: this uid
# already has more than one process). RLIMIT_NPROC is per-process, so no other
# process in the sandbox is limited.
set -euo pipefail
SRC=/workspace/devcontainer-config/install.sh
LIB="$(mktemp "${TMPDIR:-/tmp}/c27lib.XXXX")"
{ sed -n '1110p' "$SRC"; sed -n '1119,1173p' "$SRC"; sed -n '1178,1266p' "$SRC"; } > "$LIB"
# shellcheck source=/dev/null
source "$LIB"
vis_or_die() { cat; }   # stub: vis (install.sh:160-167) is not needed to read the message
trap 'rm -f "$LIB"; rm -rf "$REPO_ROOT"' EXIT
REPO_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/c27root.XXXX")"
cd "$REPO_ROOT"                       # so this script's own scan subshell is "in the checkout"
TRIGGER="${1:-none}"; NTH="${2:-1}"
export C27_SEEN=0
trap '
  case "$TRIGGER:$BASH_COMMAND" in
    cwd:cwd=*|root:root=*|lineage:p=*)
      C27_SEEN=$((C27_SEEN + 1))
      if [ "$C27_SEEN" -eq "$NTH" ] && [ "$BASHPID" != "$$" ]; then ulimit -u 1; fi ;;
  esac' DEBUG
set -T
echo "scenario: trigger=$TRIGGER nth=$NTH (bash $BASH_VERSION, uid $(id -u))"
rc=0; out="$(procs_in_checkout)" || rc=$?
echo "procs_in_checkout rc=$rc"
printf '%s\n' "$out" | sed 's/^/  listed: /' | head -3
echo "--- agent_gate (verbatim), same trigger:"
C27_SEEN=0
agent_gate "Nothing was installed. (probe)"
echo "agent_gate returned (not refused)"
