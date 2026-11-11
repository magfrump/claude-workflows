# Checkpoint: q125-cc-isolated-sandbox
Date: 2026-10-07
Branch: feat/q125-cc-isolated-sandbox (U2), stacked on feat/q125a-seccomp (U1)
Research: docs/working/research-q125-cc-isolated-sandbox.md
Plan: docs/working/plan-q125-cc-isolated-sandbox.md
Note (2026-11-07): the live run now verifies `feat/q125-sandbox-on-main`, which merges this branch with main (docs/working/research-2026-11-07-q125-sandbox-on-main.md).

## Project state
- **Branch purpose**: Claude Code's Bash sandbox in cc-isolated (Q-124 [1] / Q-125).
- **Position in larger initiative**: unblocks Q-098 (global allowlist); amends decision log 53.
- **Blocked on**: Q-126 (host probe), then the live run; Q-127 only if the probe's A/T1 fails.

## Key findings
- Docker's default seccomp blocks the namespace and mount syscalls without CAP_SYS_ADMIN, and it has no `pivot_root` at all [observed].
- Claude Code reads `/etc/claude-code/managed-settings.json`; its seccomp helper unshares PID/NS without NEWUSER and mounts `/proc` [observed, binary].
- A fresh `/proc` mount is probably refused under Docker's masked `/proc` paths [inferred]. The probe decides.

## Plan
Steps 1–4 are done (U1 `6fdd62d6`, U2 on its branch). Next: Q-126 probe → live run (plan step 6) → pr-prep per unit → merge U1 then U2 with `Live-verified: <hash>`.

## Invariants
No capability or broad switch is added. The upstream seccomp rules are preserved (hash-pinned). Boundary files and dirs are root-owned. allowedDomains ⊆ the firewall's parse. New boundary files are installed, hashed and gated together.

## File map
- `devcontainer-config/seccomp-cc-sandbox.json`: the profile (U1)
- `devcontainer-config/devcontainer.json`: runArgs (U1)
- `devcontainer-config/Dockerfile`: bwrap/socat layer (U1); managed-settings render in the tail (U2)
- `devcontainer-config/managed-settings.json`, `cc-sandbox-settings.sh`: template and renderer (U2)
- `devcontainer-config/install.sh`, `cc-isolated.sh`, `hooks/live-verify-gate.sh`: the boundary file lists
- `test/seccomp-cc-sandbox.bats`, `test/cc-sandbox-settings.bats`, plus fixture stubs in `test/cc-isolated-functions.bats` and `test/install-host.bats`
- `docs/working/probe-q125-bwrap.sh`: the host probe

## Open questions
Q-126 (probe), Q-127 (`/proc` fallback). allowWrite coverage for real builds is unverified until the live run.
