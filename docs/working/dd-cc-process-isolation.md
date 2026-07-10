# DD: OS-boundary isolation for the whole Claude Code process

- **Goal**: Choose an isolation architecture that places the entire Claude Code process (harness, all tools, agent-writable config) behind an OS-enforced boundary, closing the Read-tool credential-access and self-modification residual vectors at once.
- **Project state**: follows decision 014 (secure-tool guidance layers) and the 2026-07-09 nested-bwrap spike · standalone security-architecture decision · not blocked
- **Task status**: complete (Path-B consult resolved: user chose [3] Docker devcontainer via Desktop, reviving the step-3-pruned candidate; recommendation [2] declined; archived as docs/decisions/015-cc-process-isolation-docker-devcontainer.md)

Date: 2026-07-10
Relevant paths: docs/decisions/014-secure-tool-guidance-layers.md, docs/working/spike-nested-bwrap-fixture-confinement.md, docs/working/dd-secure-tool-guidance.md

---

## Diamond 1 — Purpose (what problem is the VM/devcontainer idea actually solving?)

Entered because trigger (c) applies in spirit: the sandbox-hardening thread keeps producing
constraints that the per-command sandbox structurally cannot satisfy (non-Bash tools run
outside it), and the user's own framing bundles several distinct problems ("credential
access", "self-modification", "stop enumerating deny rules") that deserve explicit
separation before generating designs.

### 1a. Candidate framings

1. **Tool-bypass framing** — the failure is that Read/Edit/Glob/WebFetch execute outside the bwrap sandbox, so file policy on those tools is harness-enforced (deny-list in settings.json), not OS-enforced.
2. **Credential-exposure framing** — the failure is a prompt-injected or misbehaving agent reading host credentials (~/.ssh, ~/.aws, ~/.config/gh, browser profiles) through *any* tool and exfiltrating them through its legitimate network access.
3. **Self-modification framing** — the failure is the agent rewriting its own control plane (~/.claude/settings.json, hooks, CLAUDE.md, deployed hook copies) so that *future* sessions run with weakened enforcement.
4. **Blast-radius framing** — the problem is that the agent runtime shares an OS with everything else the user does; any single policy gap compromises the whole host. Fix: an OS boundary such that worst case = lose what's inside the boundary.
5. **Enforcement-placement framing (meta)** — the problem is *where policy lives*: today the deny rules are evaluated by the same process the untrusted model drives, and stored in files the agent can write. The fix is moving enforcement to a layer the agent cannot reach, whatever that layer is.
6. **Deny-list-treadmill framing** — the failure is maintenance economics: every new secret path needs a new deny rule, forever; default-allow with enumerated denies structurally loses to default-deny with enumerated allows.
7. **Null framing** — the 014 layer stack (bwrap Bash sandbox + permission allowlist + live hooks + guard-trusted-writes) is adequate; residual risk is acceptable for this mostly-solo workflow, and the marginal attacker (prompt injection via fetched web content) is rare here.
8. **Autonomy-scale framing (zoom out)** — the problem is specifically overnight/SI-loop autonomy: unattended multi-hour sessions raise the exposure window; isolation is needed for the autonomous fleet, while interactive sessions can stay on-host.

Health check: framings cover stakeholder = user-as-secret-owner (2), user-as-operator (7, 8), maintainer (5, 6); scope = sub-problem (1, 2, 3), system (4, 5, 6), meta (5) and null (7). No single-axis anchoring.

### 2a. Diagnosis of each framing

| # | Framing | Success criterion | Implied solutions | Leaves out | Stakeholder / scope |
|---|---------|------------------|-------------------|------------|---------------------|
| 1 | Tool-bypass | non-Bash tools subject to same FS policy as Bash | extend sandbox to whole process | exfil, self-mod | maintainer / sub-problem |
| 2 | Credential-exposure | no host credential readable from any tool | boundary **or** secret removal | integrity, self-mod | user / sub-problem |
| 3 | Self-modification | enforcement config immutable from inside a session | root-owned config, out-of-reach control plane | credential reads | maintainer / sub-problem |
| 4 | Blast-radius | host compromise impossible without a boundary escape | VM, container, separate user | in-boundary asset loss | user / system |
| 5 | Enforcement-placement | all load-bearing policy evaluated+stored outside agent reach | any OS boundary; also root-owned config | which assets to protect | maintainer / meta |
| 6 | Deny-treadmill | zero new deny rules needed when a new secret appears on host | default-deny world (boundary) | integrity, self-mod | maintainer / system |
| 7 | Null | (status quo persists; audit stays green) | nothing | both named residual vectors | user-as-operator / system |
| 8 | Autonomy-scale | unattended runs isolated; interactive unchanged | cloud offload, per-fleet VM | interactive-session risk | user-as-operator / sub-problem |

Notes: framings 1–3 and 6 have near-nested success criteria — a boundary that satisfies 4/5 satisfies all of them. Framing 7 fails on the triggering evidence: the two residual vectors are documented and real (Read runs outside bwrap by design; ~/.claude is agent-writable — the settings.json sensitive-file guard is itself harness-enforced). Framing 8's "leaves out" list contains interactive-session credential reads, which is a hard concern (prompt injection arrives via WebFetch in interactive sessions too).

### 3a. Chosen framing record

> **Chosen framing**: The failure is enforcement placement — file-access policy for non-Bash tools and the agent's own control plane both live on the host side, inside the agent's reach; the fix is to place the *entire* agent process on the untrusted side of an OS-enforced default-deny boundary, with host secrets and the boundary's own configuration outside it. We selected this (framing 5, absorbing 1/2/3/4/6) over the credential-exposure framing (2) because secret-hiding alone leaves the control plane writable and restarts the deny treadmill for every new asset, and over the autonomy-scale framing (8) because interactive sessions carry the same injection surface. Diamond 2 evaluates designs against this framing; candidates that only hide today's known secrets, or only cover unattended runs, are out-of-scope partial fixes, not alternatives.

Explicitly accepted residuals (out of scope for this decision): the agent's own API credential lives inside the boundary by necessity; exfiltration of *in-boundary* content (repo code) through legitimate network egress is reduced only if a candidate adds egress filtering — tracked as a soft constraint, not hard.

---

## Diamond 2 — Solution

### Step 1.0 Pre-generation grep

`grep -B1 -A20 "Pruned candidates" docs/decisions/*.md | rg -i "sandbox|isolat|vm|container|bwrap|credential"` → one hit, decision **014**:

- `[15 nested per-command sandboxes for re-allowlisting]: WSL2 nested-bwrap fragility + widens surface` — **revived** here as candidate 8 (bwrap whole-process launcher): `[revived from 014-secure-tool-guidance-layers: the 2026-07-09 spike proved nested userns/bwrap works on this host, killing the fragility objection; and this use narrows surface (one launcher) rather than widening it (per-command re-allowlisting)]`.
- 014's `[1 do-nothing]` pruning is **carried forward** — status quo is candidate 0/1 below and is being evaluated as baseline, not re-proposed as fix.

### Step 1 — Candidates

0. **Status quo (014 layers)** — bwrap Bash sandbox + permission allowlist + hooks + guard-trusted-writes; prior decision, baseline.
1. **Do nothing more** — accept the two residual vectors as tolerable for this workflow.
2. **Dedicated WSL2 distro** — a second distro (e.g. `Ubuntu-CC`) holding repo clones and a synthetic $HOME with no real credentials; all CC sessions run there; interop and automount disabled via root-owned `/etc/wsl.conf`; agent user has no sudo.
3. **Docker devcontainer** — CC inside a Docker container (Anthropic publishes a reference devcontainer with a default-deny egress firewall); repo bind-mounted.
4. **Rootless podman container** — same shape as 3 but daemon-free via unprivileged userns (proven available by the spike); optionally driven by the devcontainer CLI.
5. **Full VM (Hyper-V/QEMU)** — separate kernel, SSH in; strongest boundary.
6. **Dedicated Unix user** — run CC as `ccagent` on the existing distro; `chmod 700` the human's $HOME; agent's enforcement config root-owned.
7. *(merged into 4 — devcontainer-CLI-on-podman is a variant, not a distinct boundary)*
8. **bwrap whole-process launcher** — `bwrap`-wrap the `claude` process itself: mount-ns with synthetic home, repo bound rw, ~/.claude selectively bound (settings/hooks ro, projects/todos rw), net shared for API. [revived from 014, see step 1.0]
9. **Secrets hygiene** — remove plaintext credentials from the host entirely (agent-based SSH, OS keychain, short-lived tokens); attack the asset instead of building a boundary.
10. **Cloud offload** — run risky/autonomous work in claude.ai/code remote sandboxes; local sessions unchanged.
11. **Qubes-style disposable VM per session** — throwaway VM per session with policy-mediated file sync (ideal-if-effort-were-free).
12. **Remote dev box** — CC lives on a rented cloud VM/devpod; host keeps only a terminal.
13. **Overlayfs snapshot boundary** — CC runs over an overlay so all writes are staged and reviewable before merging to the real FS.
14. **Keep enumerating** — continue tightening deny rules, plus scheduled `claude_config_audit.py` runs to detect self-modification after the fact.

Health check: includes do-nothing (1), naive/boring (6, 14), ideal-if-free (11); lenses cover technical (2–8, 13), reframe/asset-removal (9, 14), place/time-shifted (10, 12). Initial generation clustered on "Linux namespace tech" (3, 4, 8) — added 6, 9, 10, 12 to break the cluster. No candidate is untestably vague.

### Step 2 — Constraints

Hard:

- **H1 — OS-enforced credential denial for every tool.** From inside a session, reading host credential paths fails at the OS level regardless of tool (Read, Glob, Bash, WebFetch-side file refs). `success:` a probe session attempting to read a planted canary at `~/.ssh/canary` and `~/.aws/canary` via the Read tool AND via Bash gets ENOENT/EACCES in both, and the canary string appears in no tool output.
- **H2 — Self-modification denial for load-bearing enforcement.** The agent cannot alter any config that governs the boundary or future sessions' enforcement (boundary config, launcher, root-owned wsl.conf / image definition / bwrap profile). `success:` in-session Write/Edit/Bash attempts against each enforcement artifact fail with EROFS/EACCES/not-visible, verified by a probe checklist; artifacts are owned outside the agent's uid or outside its mount ns.
- **H3 — CC remains fully functional inside the boundary.** `success:` `bats test/` passes green inside the boundary, a normal RPI session completes end-to-end (API reachable, git commit works, skills/memory load), and CC auto-update either works or is pinned deliberately.
- **H4 — Feasible on this WSL2 host with at most one-time admin steps.** No dependency on services currently broken (Docker daemon is unreachable: socket permission denied, user not in docker group, no systemd bus). `success:` a written setup script/checklist executes to completion on this host, with any admin step listed explicitly and performed once.
- **H5 — Non-interactive compatible.** SI loop / overnight runs launch inside the boundary from a script with no per-session human action. `success:` one cron/scheduled-task-launched session completes inside the boundary unattended.

Soft:

- **S1** — session-start overhead low (< ~5 s perceived).
- **S2** — VS Code integration preserved (Remote-WSL / devcontainer attach / SSH).
- **S3** — low maintenance: survives CC auto-updates; no recurring image-rebuild or bind-list gardening.
- **S4** — git works with *scoped* credentials inside the boundary (fine-grained PAT or deploy key; host's real SSH keys stay outside).
- **S5** — composes with existing 014 layers (per-command bwrap still works inside → requires nested userns, proven).
- **S6** — repo changes flow back to the host worktree with low friction.
- **S7** — egress filtering available (default-deny network allowlist), reducing the exfiltration residual.

### Step 3 — Compatibility matrix

| # | Candidate | H1 creds | H2 self-mod | H3 functional | H4 feasible | H5 non-inter. | S2 IDE | S3 maint | S6 repo | S7 egress |
|---|-----------|----------|-------------|---------------|-------------|----------------|--------|----------|---------|-----------|
| 0 | Status quo | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ |
| 1 | Do nothing | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| 2 | WSL2 distro | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ~ |
| 3 | Docker devcontainer | ✓ | ✓ | ✓ | ✗→~ | ✓ | ✓ | ~ | ✓ | ✓ |
| 4 | Podman rootless | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ~ | ✓ | ✓ |
| 5 | Full VM | ✓ | ✓ | ✓ | ~ | ~ | ~ | ✗ | ✗ | ✓ |
| 6 | Dedicated user | ~ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ~ | ✗ |
| 8 | bwrap launcher | ✓ | ✓ | ~ | ✓ | ✓ | ✗ | ~ | ✓ | ✗ |
| 9 | Secrets hygiene | ~ | ✗ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✗ |
| 10 | Cloud offload | ~ | ~ | ~ | ✓ | ✓ | ~ | ✓ | ~ | ✓ |
| 11 | Qubes-style | ✓ | ✓ | ✓ | ✗ | ~ | ✗ | ✗ | ✗ | ✓ |
| 12 | Remote dev box | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ~ | ~ | ✓ |
| 13 | Overlayfs | ✗ | ~ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✗ |
| 14 | Keep enumerating | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ |

Pruned: **0, 1, 14** fail H1+H2 structurally (Read runs outside bwrap; ~/.claude agent-writable — the exact gap being fixed). **13** fails H1 (overlay stages writes; reads still see everything). **9** fails H2 and only partially H1 (new secrets re-open the treadmill; chosen framing explicitly rejects asset-enumeration) — retained as a *complement*, not an alternative. **11** fails H4 (no such machinery on this host; ideal-if-free candidate did its job widening the space). **5** mostly ~/✗ on soft axes and H4 ~ (second full VM beside WSL2's utility VM; heavy, poor repo flow) — dominated by 2, which delivers a WSL-managed equivalent boundary at a fraction of the cost. **12** solves a relocation problem, not this one (out-of-scope per chosen framing: it moves the whole dev environment; also latency + cost). **10** partial coverage (unattended runs only; interactive injection surface untouched) — retained as a complement for high-risk autonomous jobs. **3** fails H4 *today* (Docker daemon unreachable; fixable but requires Windows-side Docker Desktop + WSL integration, and a docker-group grant is root-equivalent on the host side) — dominated by 4, which is the same boundary daemon-free.

Fixable weaknesses in survivors:
- **2 (WSL distro)** S6: no shared worktree across distros — fix with a bare repo on a shared mount or plain GitHub push/pull; S7: no egress filter by default — fix with a root-owned nftables default-deny unit inside the distro (agent has no sudo, so it can't undo it).
- **4 (podman)** S2/S3: podman 3.4 on Ubuntu 22.04 is old and devcontainer-CLI-on-podman has rough edges — fix by installing podman from a newer channel and pinning a known-good image.
- **6 (dedicated user)** H1 is `~` because `/mnt/c` drvfs mounts are world-readable by default (Windows-side secrets visible to any Linux user) — fix with automount `umask=077` in wsl.conf, plus `chmod 700` on the human's home. Residual shared surfaces remain (/tmp, procfs, WSLg sockets, abstract unix sockets).
- **8 (bwrap launcher)** H3 is `~` because ~/.claude needs selective binds (settings/hooks ro; projects/statsig/todos rw; ~/.claude.json rw for OAuth state) and CC auto-update writes to ~/.claude/local — fiddly but enumerable; fix is a launcher script with an explicit bind manifest, deployed outside the repo (copy-not-symlink rule).

Survivors → step 4: **[2] [4] [6] [8]**.

### Step 4 — Tradeoff matrix

| # | Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|----------|--------|------|------------------|--------------|
| 2 | WSL2 distro | ~4–6 h + one admin step | low | 5/5 | repo sync via git, not shared worktree; egress open by default (mitig. nftables unit) |
| 4 | Podman rootless container | ~5–8 h | medium | 5/5 | podman/devcontainer toolchain friction on Ubuntu 22.04; image maintenance |
| 8 | bwrap launcher | ~3 h | medium | 5/5 (H3 needs bind manifest) | same-kernel namespace only; no egress control; weak IDE story; bind-list gardening |
| 6 | Dedicated user | ~2–3 h | medium | 4/5 (H1 partial until /mnt/c hardened) | leaky shared surfaces (/tmp, procfs, sockets); /mnt/c must be re-masked |

Falsifiable hypotheses:

- **[2]** If chosen, within 2 weeks of cutover 100% of CC sessions run in the dedicated distro with the H1/H2 canary probes passing, and repo-sync overhead stays under ~10 min/day; counter-evidence = drifting back to host-distro sessions for convenience, or interop found re-enabled, or sync friction driving worktree workarounds.
- **[4]** If chosen, within 2 weeks the container is the default session environment with probes passing; counter-evidence = >1 podman/devcontainer breakage per week needing manual fixing, or image staleness pinning CC more than one version behind.
- **[8]** If chosen, within 1 week the launcher wraps every session with probes passing; counter-evidence = a CC update breaking the bind manifest more than once, or weekly discovery of legitimate paths missing from the manifest.
- **[6]** If chosen, within 1 week all sessions run as the agent user with probes passing including a /mnt/c credential-read probe; counter-evidence = any world-readable host secret reachable, or shared-surface interference (X11/WSLg, /tmp) disrupting either user.

Stress-test pass (moves per candidate):

- **Boring alternative** (applied to the field): [6] *is* the boring alternative, and [8] the cheap one. Both survive as candidates precisely because of this move; neither dominates — [6] leaks via shared kernel surfaces and /mnt/c, [8] carries permanent bind-manifest gardening (the treadmill in a new costume, cf. chosen framing).
- **Invert the thesis** (on [2], the leader): argue for [4] — portability (config committed per-repo, works on any machine), upstream reference devcontainer with egress firewall, bind-mounted worktree = zero sync friction. What survives inversion: [2] still wins on daemon-free durability, native IDE support, and no image lifecycle; but the inversion exposes that [2]'s egress filtering is DIY while [4] inherits a maintained pattern. Matrix updated: [4]'s S7 noted as its genuine edge.
- **Organizational survival / revealed preferences** (on [2] and [4]): the boundary only protects if the user actually lives inside it. [2] feels like a normal machine (Remote-WSL, systemd, apt) → lowest drift-back risk. [4] adds a per-session attach step and occasional image rebuilds → moderate drift-back risk. [8] is invisible once scripted → lowest friction but also easiest to silently stop using if it breaks. This move is why [2] outranks [4] despite [4]'s S7 edge.
- **Failure-driven** (new failure modes): [2] — WSL update re-enables interop or resets wsl.conf → mitigate with a session-start self-probe (canary read + `wsl.exe` invocation must fail) that refuses to start CC on failure; repo divergence between distros → mitigate with push-early habit + morning-summary check. [4] — stale image ships an old CC with known bugs; rootless UID-mapping surprises on bind-mounted worktree. [8] — CC update adds a new state path outside the manifest, sessions half-break; launcher itself must live outside any agent-writable path (copy-not-symlink, cf. 014). [6] — audit gap: anything *world-readable* anywhere on the host is in-bounds forever; requires a recurring permissions audit (a new treadmill).
- **Push to extreme** (on [2]): 10 parallel worktree agents + SI loop inside one distro — fine (same UX as today); but if the distro is ever granted a real credential "just this once," the boundary's value collapses silently → mitigate: the decision record forbids real host credentials inside; scoped PATs only (S4).

Stress-test mitigations adopted into the matrix: [2] gains "(mitig.)" on its egress downside via the root-owned nftables default-deny unit; [2] gains a session-start boundary self-probe; [6]'s /mnt/c fix (automount umask=077) is required regardless of chosen candidate — it hardens the host for free.

Axis of disagreement ([2] vs [4], within ~1 cell): **daemon-free durability + native UX (WSL distro) vs. portable committed config + inherited egress firewall + zero-sync worktree (podman devcontainer)**. No stated project preference exists on this axis; recommendation falls to the revealed-preferences/organizational-survival move, which favors [2] for a daily-driver single-host workflow.

**Recommendation: [2] dedicated WSL2 distro, confidence ~70%.** Path B consult issued (user present, tradeoff within 1 cell).

Complements recorded (not alternatives): [9] secrets hygiene and the /mnt/c umask hardening are worth doing under any choice; [10] cloud offload remains the right tool for one-off high-risk autonomous jobs.
