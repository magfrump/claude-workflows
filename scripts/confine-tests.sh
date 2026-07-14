#!/usr/bin/env bash
# Run a test command with the network denied at the kernel level.
#
# This is layer 2 of decision 017 — the GROUND TRUTH that scripts/hermeticity-lint
# can only approximate. A network namespace is inherited by every descendant
# process, so unlike pytest-socket / nock / gock (all in-process monkeypatches)
# it also denies a subprocess `curl` and a C-extension socket. It is
# language-agnostic by construction: it does not know or care whether the command
# is bats, pytest, cargo test, or vitest.
#
# Usage:
#   scripts/confine-tests.sh -- <test command...>
#   scripts/confine-tests.sh --probe          # check the primitive, print verdict
#   scripts/confine-tests.sh --no-loopback -- <cmd>
#
# WHERE THIS RUNS
#   CI and dev hosts. NOT inside the cc-isolated devcontainer: decision 017
#   finding 1 — that container has zero effective capabilities and seccomp blocks
#   CLONE_NEWUSER, so no namespace can be created. The runner detects this and
#   FAILS LOUDLY rather than running your tests unconfined.
#
# WHY IT NEVER DEGRADES QUIETLY
#   The 014 layer-3 spike's own pre-mortem predicted "platform pulls the rug —
#   the harness gets bypassed instead of fixed", and that is exactly what
#   happened within four days. A guard that silently stops guarding is worse than
#   no guard: it converts a loud failure into a false green. So a missing
#   primitive is a hard error (exit 3), never a warning.
#
# LOOPBACK
#   A fresh netns comes up with `lo` DOWN. Suites that spin a local server
#   (httptest, mockito, msw, a bats fixture server) need it UP, so we raise it by
#   default. Loopback is not egress; the namespace has no route off the host.
#
#   --no-loopback keeps `lo` down. It is NOT simply "a stricter profile": bwrap
#   raises `lo` itself and cannot be told not to, so the flag forces the
#   `unshare` primitive, which denies the network and nothing else — no
#   read-only rootfs, no private /tmp, no pid namespace, and the tests run as
#   uid 0. You are trading filesystem confinement for loopback denial. The
#   script says so at runtime, and refuses outright when unshare is unusable.
#
# THE RUNNER'S OWN NETWORK
#   Denial applies to the whole process tree, including any dependency fetch the
#   test command triggers. Pre-warm caches first (`go mod download`, `cargo
#   fetch`, `npm ci`, `pip install`) or the run will fail on downloads rather
#   than on hermeticity.

set -euo pipefail

loopback=1
probe_only=0
cmd=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --probe)       probe_only=1; shift ;;
    --no-loopback) loopback=0; shift ;;
    --)            shift; cmd=("$@"); break ;;
    -h|--help)
      # Print ONLY the leading header block. `grep '^#'` would splice in the
      # shebang (as `!/usr/bin/env bash`) and every internal rationale comment
      # further down the file. Skip line 1 and stop at the first non-`#` line.
      awk 'NR==1{next} /^#/{sub(/^# ?/,"");print;next} {exit}' "$0"
      exit 0
      ;;
    *)
      echo "confine-tests: unknown flag: $1" >&2
      echo "Usage: $0 [--no-loopback] -- <test command...>" >&2
      exit 2
      ;;
  esac
done

# --- preflight: which confinement primitive, if any, do we have? ------------
#
# Only mechanisms that deny egress at the KERNEL are acceptable. An in-process
# blocker or a proxy env var is convention, not enforcement, and would be exactly
# the silent degradation this script exists to refuse.

detect_primitive() {
  if command -v bwrap >/dev/null 2>&1 &&
     bwrap --ro-bind / / --unshare-net -- true >/dev/null 2>&1; then
    echo "bwrap"
    return 0
  fi
  if command -v unshare >/dev/null 2>&1 &&
     unshare -rn true >/dev/null 2>&1; then
    echo "unshare"
    return 0
  fi
  return 1
}

explain_unavailable() {
  cat >&2 <<'EOF'
confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.

  Your tests were NOT run. This is deliberate: running them unconfined here
  would report a green that means nothing, which is the precise failure this
  guard exists to prevent.

  Neither primitive is usable in this environment:
    * bwrap --unshare-net
    * unshare -rn  (unprivileged user namespace + network namespace)

  The usual cause is running inside a hardened container. Check:
    grep CapEff /proc/self/status     # all zeros => no capabilities
    grep Seccomp /proc/self/status    # 2 => filtered; CLONE_NEWUSER often blocked

  This is expected inside the cc-isolated devcontainer (decision 017, finding 1):
  the agent's own session cannot confine itself. Run this on a CI runner or a dev
  host instead, and use scripts/hermeticity-lint for in-session triage.
EOF
}

if ! primitive="$(detect_primitive)"; then
  explain_unavailable
  exit 3
fi

# --- primitive selection ---------------------------------------------------
#
# This runs BEFORE --probe, so the probe vets the primitive the real run will
# actually use. Probing bwrap and then refusing to run under --no-loopback would
# make the probe useless precisely where it is needed: a CI job that gates on it
# would sail through and then die at the next step.
#
# bwrap raises `lo` inside --unshare-net itself and cannot be told not to, so
# --no-loopback can only be served by `unshare -rn`, whose fresh netns leaves lo
# DOWN. That is a REAL trade, not a free upgrade, and it must not be sold as one:
# the unshare path denies the network and nothing else. It has no --ro-bind, no
# tmpfs, no pid namespace, and -r makes the tests uid 0 — so a stray write that
# bwrap would have refused with EROFS lands on the real filesystem as root. Say
# so, loudly, every time.
if [[ "$primitive" == "bwrap" && "$loopback" -eq 0 ]]; then
  if command -v unshare >/dev/null 2>&1 && unshare -rn true >/dev/null 2>&1; then
    primitive="unshare"
    echo "confine-tests: WARNING — --no-loopback forces the unshare primitive." >&2
    echo "  It denies the network and NOTHING ELSE. bwrap's read-only rootfs, its" >&2
    echo "  private /tmp and its pid namespace are all absent, and your tests run" >&2
    echo "  as uid 0 in a user namespace: a stray write that bwrap would refuse" >&2
    echo "  with EROFS will succeed against the real filesystem. Drop the flag to" >&2
    echo "  get the hardened profile (loopback is not egress — the namespace has" >&2
    echo "  no route off the host)." >&2
  else
    echo "confine-tests: --no-loopback is not supported by the bwrap primitive." >&2
    echo "  bwrap brings \`lo\` up inside --unshare-net and cannot be told not to." >&2
    echo "  It needs \`unshare -rn\`, which is unusable here. Re-run without" >&2
    echo "  --no-loopback (loopback is not egress: the namespace has no route off" >&2
    echo "  the host), or run on a host where unshare works." >&2
    exit 2
  fi
fi

# Raising `lo` needs iproute2. If it is missing we cannot honour loopback=1, and
# a suite that binds 127.0.0.1 would fail with a connection error that looks like
# its own bug — while the banner had already announced loopback=1. Refuse instead:
# the whole point of this script is that it never claims a guarantee it is not
# delivering. (Not needed on the bwrap path, which raises lo itself.)
if [[ "$primitive" == "unshare" && "$loopback" -eq 1 ]] && ! command -v ip >/dev/null 2>&1; then
  echo "confine-tests: \`ip\` (iproute2) not found — cannot bring loopback up." >&2
  echo "  Install iproute2, or pass --no-loopback to run with \`lo\` down on purpose." >&2
  exit 3
fi

if [[ "$probe_only" -eq 1 ]]; then
  echo "confine-tests: primitive available: $primitive (loopback=$loopback)"
  echo "  network denial is kernel-enforced and inherited by every child process."
  exit 0
fi

if [[ "${#cmd[@]}" -eq 0 ]]; then
  echo "confine-tests: nothing to run. Usage: $0 -- <test command...>" >&2
  exit 2
fi

# --- run ------------------------------------------------------------------

echo "confine-tests: denying network via $primitive (loopback=$loopback)" >&2

if [[ "$primitive" == "bwrap" ]]; then
  # --dev /dev is mandatory: --ro-bind / / alone leaves /dev/null unwritable and
  # bats dies on it. --proc /proc is needed once --unshare-pid is in play.
  #
  # --tmpfs /tmp is equally mandatory, for the same reason one step later: under
  # --ro-bind / / the whole rootfs is read-only, so bats' own `mktemp -d` for its
  # run dir fails with EROFS and the suite dies before its first test. TMPDIR is
  # pinned to that tmpfs so an inherited TMPDIR cannot point the same mktemp back
  # at the read-only tree. (This is the profile the spike demoed:
  # docs/working/spike-nested-bwrap-fixture-confinement.md, "Known invariants".)
  #
  # Env is INHERITED, not cleared — a deliberate divergence from the spike's
  # --clearenv invariant. That invariant was scoped to a bats-only profile with a
  # known allowlist; a language-agnostic runner cannot --clearenv without
  # reconstructing a per-toolchain allowlist (PATH, HOME, CARGO_HOME, npm/pip/go
  # caches, BATS_*), and a wrong allowlist breaks suites silently (pre-mortem
  # narrative 3). The outer proxy creds that --clearenv would have hidden are dead
  # weight for egress here (the netns has no route and no proxy listener) but stay
  # readable by fixture code, so treat scratch output as untrusted (narrative 4).
  exec bwrap \
    --ro-bind / / \
    --dev /dev \
    --proc /proc \
    --tmpfs /tmp \
    --setenv TMPDIR /tmp \
    --bind "$PWD" "$PWD" \
    --unshare-net \
    --unshare-pid \
    --die-with-parent \
    --chdir "$PWD" \
    -- "${cmd[@]}"
fi

# unshare: `-r` maps us to root inside the new user namespace, which is what
# makes the unprivileged netns creation legal.
#
# The `ip link` failure is NOT swallowed. `|| true` there would let the run
# proceed with `lo` down after the banner had already announced loopback=1 —
# a guard quietly not guarding, which is the one thing this script refuses to do.
if [[ "$loopback" -eq 1 ]]; then
  exec unshare -rn -- sh -c '
    if ! ip link set lo up; then
      echo "confine-tests: failed to bring loopback up inside the namespace." >&2
      exit 3
    fi
    exec "$@"' sh "${cmd[@]}"
fi
exec unshare -rn -- "${cmd[@]}"
