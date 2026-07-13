# 015 — CC process isolation: Docker devcontainer (Desktop-backed), podman fallback

- **Goal**: Place the entire Claude Code process (harness, all tools, agent-writable config) behind an OS-enforced boundary, closing the Read-tool credential-access and self-modification residual vectors at once.
- **Project state**: standalone security-architecture decision · follows decision 014 and the 2026-07-09 nested-bwrap spike · blocked on one-time host setup (Docker Desktop WSL integration)
- **Task status**: complete (decision made; implementation scaffolded 2026-07-13 — `.devcontainer/`, `scripts/devcontainer-session.sh` with trust-manifest gate + boundary self-probe, `guides/devcontainer-setup.md`; awaiting first launch + H1/H2 canary verification)

## Context

Decision 014's layer stack hardens Bash-tool usage, but two residual vectors are
structural: (1) Read/Edit/Glob execute outside the bwrap sandbox, so file policy on them
is harness-enforced (deny rules in settings.json), not OS-enforced; (2) ~/.claude —
settings, hooks, CLAUDE.md — is writable by the agent, so a misbehaving session can weaken
the enforcement governing future sessions. Enumerating deny rules loses to this
structurally (default-allow + enumerated denies vs. default-deny). A Double Diamond DD was
run (working doc: `docs/working/dd-cc-process-isolation.md`); Diamond 1 chose the
**enforcement-placement framing**: move the whole agent process to the untrusted side of
an OS default-deny boundary, with host secrets and the boundary's own configuration
outside it.

Host facts that shaped the matrix: WSL2 (Ubuntu 22.04), unprivileged user namespaces
proven working (2026-07-09 spike), Docker daemon unreachable from the agent's account
(socket denied, no docker group, no systemd bus) — resolvable via Docker Desktop WSL
integration on the Windows side.

## Options considered

14 candidates generated (full list and compatibility matrix in the working doc). Step-3
survivors: [2] dedicated WSL2 distro, [4] podman rootless container, [8] bwrap
whole-process launcher, [6] dedicated unix user. [3] Docker devcontainer was pruned on
current-host feasibility, then **revived in the Path-B consult** when the user confirmed
the Docker Desktop path (Desktop proxies the socket, so no root-equivalent docker-group
grant is needed in the distro). The DD's tentative recommendation was [2] (WSL2 distro,
~70%); the user chose [3] with Desktop backing.

## Decision and rationale

**Run Claude Code inside a Docker devcontainer backed by Docker Desktop's WSL
integration**, starting from Anthropic's reference devcontainer for Claude Code,
which includes a default-deny egress firewall. Rationale: same OCI boundary as the podman
variant but with the best-maintained toolchain (VS Code Dev Containers targets Docker
first; the reference config works unmodified), zero-sync bind-mounted worktree, and an
inherited — not DIY — egress allowlist. The trust story accepts Docker Desktop's
privileged daemon on the VM side; the agent inside the container never sees the socket.

Both residual vectors close the same way: host credentials are simply not mounted
(H1 — OS-enforced for every tool, since all tools run inside the container's mount
namespace), and the enforcement that matters (the image definition, devcontainer.json,
firewall init) lives host-side outside the agent's reach; the in-container ~/.claude
becomes low-stakes (H2).

Because Docker Desktop's presence/health was not verifiable from inside this session,
the decision carries a **trigger-bound rule** (evidence arrives after commit):

| Branch | Trigger condition | Action |
|--------|------------------|--------|
| **Continue** | Devcontainer sessions become the default within 2 weeks; H1/H2 canary probes pass (planted `~/.ssh/canary` unreadable via Read tool AND Bash; enforcement artifacts unwritable); `bats test/` green inside | proceed; retire host-session use for agent work |
| **Revisit** | >1 Docker/devcontainer breakage per week needing manual fixing, or image staleness pins CC >1 version behind for >2 weeks | re-run the step-4 tradeoff with measured friction before further investment |
| **Reverse** | Docker Desktop unavailable/unlicensed/blocked on this machine, or WSL integration cannot be enabled | implement **[4] podman rootless container** (pre-named step-3 survivor) with the same devcontainer.json |

Currently operating under: **Continue** (pending first setup).

Falsifiable hypothesis: *If we adopt the Desktop-backed devcontainer, we expect it to be
the default session environment within 2 weeks with both canary probes passing;
counter-evidence would be weekly breakage, fallback to host sessions, or the Reverse
trigger firing.*

See alternatives considered → Pruned candidates below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in
adjacent areas can grep this section to avoid regenerating already-pruned approaches.

[0 status quo / 1 do-nothing / 14 keep-enumerating]: fail both hard constraints structurally — Read runs outside bwrap by design and ~/.claude stays agent-writable [0/1 carried from 014-secure-tool-guidance-layers: do-nothing was the status quo being fixed]. [13 overlayfs]: stages writes but reads still see everything — fails credential denial. [9 secrets hygiene]: asset enumeration restarts the deny treadmill; kept as a *complement* under any boundary. [11 Qubes-style disposable VMs]: no such machinery on this host; served as the ideal-if-free space-widener. [5 full VM]: dominated by the WSL2-distro candidate — equivalent boundary at a fraction of cost/friction. [12 remote dev box]: solves relocation, not isolation; out of scope per chosen framing. [10 cloud offload]: covers unattended runs only; interactive injection surface untouched; kept as complement for high-risk autonomous jobs. [2 WSL2 dedicated distro]: DD's own recommendation, declined in Path-B consult — user preference for the devcontainer's portable committed config, zero-sync worktree, and inherited egress firewall over daemon-free durability. [8 bwrap launcher, revived from 014-secure-tool-guidance-layers: spike killed the fragility objection]: survived to step 4 but declined — bind-manifest gardening recreates the treadmill; no egress control; weak IDE story. [6 dedicated unix user]: /mnt/c world-readable by default plus shared kernel surfaces (/tmp, procfs, WSLg sockets) leave H1 partial; its automount `umask=077` fix is adopted as host hardening regardless. [15-from-014 nested per-command sandboxes]: revived-adjacent via [8]; its narrow fixture-confinement use continues separately under 014 layer 3.

Prior pruning grep: one match (decision 014, entries noted above); no other decisions
mention sandbox/isolation/VM/container/credential pruning.

## Stress-test mitigations

- How to read: *Invert the thesis* mitigation — arguing for the container against the leading WSL-distro candidate surfaced the egress-firewall inheritance as a genuine edge; this became a deciding factor in the user's Path-B choice.
- How to read: *Failure-driven* mitigation — added a session-start boundary self-probe requirement (canary credential read must fail before CC starts) to whatever launcher/attach script wraps sessions; a boundary that silently degrades is worse than none.
- How to read: *Revealed preferences* mitigation — drift-back risk (attach step + image rebuilds) is the chosen candidate's main behavioral hazard; the Continue trigger measures exactly this (devcontainer-as-default within 2 weeks).
- How to read: *Push to extreme* mitigation — the record forbids real host credentials inside the boundary; git uses scoped fine-grained PATs or deploy keys only.

## Consequences

Easier: credential denial and control-plane immutability become default-deny properties
requiring zero per-secret rules; egress filtering comes maintained from upstream; the
devcontainer config is committed per-repo and portable to other machines; worktree is
bind-mounted so no repo-sync workflow change.

Harder: one-time Windows-side setup (Docker Desktop + WSL integration); an image
lifecycle to keep CC current; per-session container attach; Docker Desktop becomes a
trusted dependency (privileged daemon); in-container ~/.claude (memory, skills,
settings) needs a deliberate persistence strategy (named volume or bind of a dedicated,
non-host ~/.claude); SI-loop/cron launch paths must be reworked to `devcontainer exec`
or equivalent (H5 verification pending).

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt
re-evaluating this decision. Future readers can grep this section when their context
changes to see whether earlier decisions still apply.

If the Reverse trigger fires (Desktop unavailable) → implement [4] podman rootless. If devcontainer breakage exceeds 1/week over any 2-week window → Revisit branch. If Anthropic ships a first-party whole-process sandbox for Claude Code (not just Bash) → re-run step 4; this decision may be obsoleted upstream. If CC sessions drift back to running on the host for >20% of work after week 2 → the boundary is failing behaviorally, Revisit. If Docker Desktop licensing changes for this use → Reverse to podman. If the SI loop cannot launch inside the container non-interactively (H5) → Revisit before relying on overnight isolation.
