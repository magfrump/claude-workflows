#!/usr/bin/env bash
# probe-q125-bwrap.sh — HOST-side feasibility probe for Q-125 (run on the host,
# not in a container; needs Docker and network for one apt install).
#
# Answers, before any image rebuild: does Claude Code's bwrap argv work in a
# container started with devcontainer-config/seccomp-cc-sandbox.json on this
# kernel and LSM? Runs a throwaway debian:bookworm container per variant:
#   A  the Q-125 profile, cc-isolated's caps    (the design)
#   B  Docker's default profile                  (control: T1 should FAIL)
#   C  A + --security-opt systempaths=unconfined (fallback if A/T1 fails on /proc)
# Tests, run as an unprivileged user inside each container:
#   T1  bwrap with a FRESH /proc (Claude Code's default argv)
#   T2  bwrap with --bind /proc /proc (enableWeakerNestedSandbox's argv)
#   T3  under T2: is a /dev/null-masked file still readable via /proc/<pid>/root?
#       ("LEAK" = weaker mode cannot protect .credentials.json)
#   T4  nothing else widened: unshare -m without a user namespace, and root mount,
#       must still be refused
# Writes nothing outside its own temp dir; removes it on exit.
set -euo pipefail

BRANCH="${1:-feat/q125-cc-isolated-sandbox}"
repo="$(git rev-parse --show-toplevel)"
tmp="$(mktemp -d)" || { echo "mktemp failed" >&2; exit 1; }
if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then echo "no temp dir" >&2; exit 1; fi
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

git -C "$repo" show "$BRANCH:devcontainer-config/seccomp-cc-sandbox.json" > profile.json

cat > inner.sh <<'INNER'
set -u
apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq bubblewrap util-linux >/dev/null 2>&1 \
  || { echo "INFO apt install failed"; exit 0; }
useradd -m u
echo "INFO lsm=$(cat /proc/self/attr/current 2>/dev/null || echo none) kernel=$(uname -r)"
echo "INFO bwrap=$(bwrap --version) setuid=$( [ -u /usr/bin/bwrap ] && echo yes || echo no)"
BW='bwrap --new-session --die-with-parent --unshare-net --ro-bind / / --dev /dev --unshare-pid --unshare-user --cap-drop ALL'
r() { if su u -s /bin/sh -c "$2" >/tmp/out 2>&1; then echo "RESULT $1 pass"; else echo "RESULT $1 FAIL: $(tail -1 /tmp/out)"; fi; }
r T1-fresh-proc "$BW --proc /proc -- true"
r T2-bind-proc  "$BW --bind /proc /proc -- true"
su u -s /bin/sh -c 'echo SECRET > ~/secret; sleep 60 >/dev/null 2>&1 & echo $! > ~/pid'
pid="$(cat /home/u/pid)"
leak="$(su u -s /bin/sh -c "$BW --ro-bind /dev/null /home/u/secret --bind /proc /proc -- sh -c 'cat /home/u/secret; cat /proc/$pid/root/home/u/secret' 2>&1")"
case "$leak" in *SECRET*) echo "RESULT T3-weaker-mode LEAK (masked file readable via /proc/$pid/root)";; *) echo "RESULT T3-weaker-mode no-leak: $leak";; esac
if su u -s /bin/sh -c 'unshare -m true' >/dev/null 2>&1; then echo "RESULT T4-unshare-m-no-userns WIDENED"; else echo "RESULT T4-unshare-m-no-userns refused (good)"; fi
if mount -t tmpfs none /mnt >/dev/null 2>&1; then echo "RESULT T4-root-mount WIDENED"; else echo "RESULT T4-root-mount refused (good)"; fi
INNER

run() {
  local label="$1"; shift
  echo "=== $label"
  docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW "$@" -v "$tmp/inner.sh:/inner.sh:ro" \
    debian:bookworm bash /inner.sh 2>&1 | sed "s/^/$label /"
}
run A --security-opt "seccomp=$tmp/profile.json"
run B
run C --security-opt "seccomp=$tmp/profile.json" --security-opt systempaths=unconfined
echo "=== host: $(uname -r); apparmor_restrict_unprivileged_userns=$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || echo n/a); max_user_namespaces=$(cat /proc/sys/user/max_user_namespaces 2>/dev/null || echo n/a)"
