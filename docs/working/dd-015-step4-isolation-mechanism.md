# DD: re-run decision 015's step 4 — which isolation mechanism (Q-105 [3])

- **Goal**: Re-run decision 015's step-4 tradeoff (Docker vs podman vs other) with the measured breakage record, and decide whether the isolation mechanism should change or 015 should stand with an amended trigger.
- **Project state**: roadmap Next 5, design only, on `docs/dd-015-step4` (from `merge/ready-2026-10-15` 9660d4f6) · inputs: decision 015 and its dependants (016, 017, 022, 023, 034, 035, 036, 037), Q-105, the breakage commits, `docs/working/research-branch-verify-without-install.md` and `dd-branch-verify-without-install.md` · not blocked; the final choice is the user's
- **Task status**: in-progress (steps 1-4 done; step 4 resolved down Path C with a tentative recommendation; no edit to decision 015 until the user answers)

Workflow: `workflows/divergent-design.md`. Steps 1-3 are written in full here. Step 4 renders the decision block. Step 5 is a draft amendment to 015's Revisit triggers (in §6 of this doc only); decision 015 itself is not edited by this unit.

Everything in this doc was read from the repo with `git log`, `git show` and `rg`. Nothing ran against docker, podman or the host. Claims about podman, rootless Docker, gVisor, micro-VMs and Docker Desktop licensing that do not come from the repo are tagged **[unverified, from memory]**; §7 lists each with the host check that would settle it. This sandbox has no web egress.

## 0. Motive — does any alternative remove the breakage source?

Q-105 asked whether 015's trigger "devcontainer breakage exceeds 1/week over any 2-week window → Revisit" really fired, given that all three cited breakages came from this repo's own boundary changes. The user answered [3] (re-run step 4). Before comparing mechanisms, this section tests whether a mechanism change could remove the cause.

### 0.1 The breakage record

Every commit since 015 shipped (2026-07-13) that fixed a defect which stopped sessions from working, or silently voided a boundary property in a live container. Review-iteration fixes on unmerged branches are excluded (the 2026-10-14 cycle record treats them the same way).

| Commit | Date | What broke | Cause layer | Shipped without a live run? |
|---|---|---|---|---|
| e87e0b54 | 07-13 | `cc-isolated` in a second project: "Dockerfile not found", and in a repo with its own `.devcontainer/` a silent H2 breach (built the repo's Dockerfile) | **devcontainer CLI** semantics: `--override-config` resolves relative build paths against the workspace × our relative paths | no — found by the first live launch (016's post-implementation correction) |
| 03668e48 | 07-30 | the config-audit hook was wired but scanned nothing (resolved its scanner from a host-only path) | ours (payload layout) | no — found by 023's live verification |
| f906b50f | 09-09 | `node` had no DNS and no HTTPS while the boundary reported healthy; six days (log row 45) | **kernel netfilter** semantics (`__ip_local_out` fixes the out-device before nat) × our DNAT steering (log row 44) | **yes** — "this has NOT yet been verified in a live container — the same gap that produced the bug" |
| 95f5a86d | 09-12 | `live-verify-gate.sh` absent from every live session (stale image; the wiring merge also left stale groups) | ours (process: image not rebuilt; merge bug) | **yes** — the image predated the change |
| 6c35e39d | 09-12 | `cc-isolated` refused to start on every healthy container (`PROBE FAIL (firewall)`) | ours (marker directory mode 0700 vs a `node`-run stat) | **yes** — "the check has never been able to observe a pass since it shipped in log 45" |
| 7c970bfe | 09-19 | Artifact reads failed through the filtering resolver; republishing duplicated artifacts | ours (allowlist lacked a zone the 09-03 resolver started blocking) | **yes** — `Live-verified: no` |

Totals: 6 session-breaking fixes in 14 weeks. **0 caused by the Docker engine or Docker Desktop.** 1 caused by the devcontainer CLI, which every OCI-runtime alternative below would keep using. 1 rests on Linux kernel netfilter semantics, which every runtime sharing the WSL2 kernel inherits. 4 of 6 shipped to main without a live run.

Two caveats. (a) The record only sees what was fixed in git. A Docker Desktop outage the user worked around on the host leaves no commit. Q-121's answer (2026-10-07) says the user occasionally runs sessions on the host "when the container image breaks", so some host-side incidents exist that the repo cannot classify. §7 V1 asks for them. (b) The 2026-10-14 cycle found T2 not fired in its window (six fix commits, all review iterations on unmerged branches).

### 0.2 The verification gap, measured

Log row 45 (2026-09-09) added the `Live-verified:` trailer gate exactly because #40 and #41 shipped unverified. Since then, of the 116 non-merge commits touching `devcontainer-config/`, **87 carry `Live-verified: no` and 1 carries a hash** (`git log --since=2026-09-09`; the other 28 carry neither trailer, and were not classified one by one: host-tool commits carry `Host-tool-tested:` since log row 71, and the gate does not apply to every file. A verification recorded outside the commit body, for example in the questions archive, is not counted either). The gate makes the gap visible; it does not close it. The research for the branch-verify DD (`research-branch-verify-without-install.md` §1) explains why: a live run means installing the branch over main's config, which the install agent gate (decision 037, Q-058) refuses while any session runs. So boundary changes queue unverified and are found broken by the next real session.

### 0.3 Verdict on the motive

The breakage source is **unverified boundary-layer changes reaching main**, not the container runtime. No runtime swap touches that source:

- every candidate that keeps an OCI container keeps the same devcontainer CLI, the same kernel, the same `init-firewall.sh` and the same verification gap;
- a migration is itself a large unverified boundary change, so in the short run it adds breakage of exactly the observed kind.

Only two kinds of candidate act on the source: ones that **close the verification gap** (candidate [2]) and ones that **shrink the hand-built boundary layer** where the defects live (candidate [9]). Keeping Docker is therefore a real candidate, not a default to argue against. Q-105's phrase stands as the working hypothesis: *the churn is ours*.

## Step 1 — Diverge

### 1.0 Pre-generation grep

`grep -B1 -A20 "Pruned candidates" docs/decisions/*.md | rg -i "podman|rootless|docker|wsl|distro|bwrap|gvisor|vm|container|runtime"`, plus a scan of `docs/decisions/log.md`. Surfaced:

- **015's own pruned set** ([0/1/14], [13], [9], [11], [5], [12], [10], [2], [8], [6]). Step-4 survivors there were [2] WSL2 distro, [4] podman rootless, [8] bwrap launcher, [6] dedicated user, and the revived [3] Docker. Each is re-entered or carried below.
- **016 [9] micro-VM per project** (ideal-if-free; no provisioning machinery) — carried as [11].
- **016 [4] hybrid / "two code paths and two trust regimes"** — carried as a design rule; it decides [15].
- **016 [11] raw CLI** ("a silently-degrading boundary is worse than none") — carried into hard constraint H7.
- **034** (crb): an `--internal` docker network whose only route out is a proxy. Not a pruned candidate, but prior art: revived as the shape of [9].
- **035 [7] / 037 [8 G]**: installer placement and pinned worktrees; out of scope (this DD does not move the installer).
- **Log rows 44, 45, 55, 71** bound the field: steering by DNAT (44), blessed ≠ verified (45), zone entries (55), host tools as their own trust category (71).

Revive/carry decisions:

- [revived from 015 [4] podman rootless: 015 pre-named it as the Reverse fallback; Q-105 [3] asks for it by name] → [3].
- [revived from 015 [2] WSL2 dedicated distro: the DD's own original recommendation (~70%); re-entered because step 4 is being re-run, and the egress stack it would need is now known in detail] → [6].
- [carried from 015 [8] bwrap whole-process launcher: bind-manifest treadmill, no egress control] → [7], re-scored, still no egress.
- [carried from 015 [6] dedicated unix user: H1 partial] → [8].
- [carried from 015 [12]/[10] remote box / cloud offload] → [12].
- [carried from 015 [0/1/14] host sessions with deny rules] → [14].

### 1.1 Candidates

0. **Status quo**: keep the Docker Desktop–backed devcontainer exactly as 015/016 built it; no amendment.
1. **Status quo + boundary-churn watch**: keep Docker; amend 015's T2 to separate runtime-caused breakage from boundary-layer breakage and add a trigger on the latter (Q-105 [2]).
2. **Status quo + verify-before-merge**: keep Docker; close the gap in §0.2 by giving boundary branches a side-by-side live run that needs no install (the branch-verify DD's `cc-verify`), and refuse `Live-verified: no` on merges of manifest-hashed files once that path exists.
3. **Podman rootless** with the same `devcontainer.json` through the devcontainer CLI's docker-path setting (015's pre-named Reverse).
4. **Rootless Docker Engine** inside the WSL distro (no Desktop, no docker group).
5. **Rootful Docker Engine** (docker-ce) inside the distro, replacing Desktop.
6. **Dedicated WSL2 distro** per session class, with egress enforced outside it.
7. **bwrap whole-process launcher** on the host (015 [8]), now that Q-126 proved bwrap with fresh `/proc` on this kernel.
8. **Dedicated unix user** for agent sessions (015 [6]).
9. **Docker + sidecar egress proxy**: keep the container, delete the in-container netfilter/DNS/marker stack, and put the session on an `--internal` network whose only route out is a proxy container holding the allowlist (decision 034's crb shape).
10. **gVisor (`runsc`) runtime** under Docker, for a user-space kernel. *(Feels wrong: the boundary leans on netfilter.)*
11. **Micro-VM per session** (Kata / Firecracker class). *(Ideal if effort were free.)*
12. **Remote dev box or cloud sandbox.** *(Feels wrong: this host never pushes.)*
13. **Wait for a first-party whole-process sandbox** from Anthropic (015 T3). *(Time-shifted.)*
14. **Back to host sessions** with Claude Code's Bash sandbox and deny rules. *(Naive / regress.)*
15. **Runtime-agnostic launcher**: Docker primary, podman kept tested in CI-less bats as a hot spare.
16. **Drop the devcontainer CLI**: cc-isolated drives `docker build` / `docker run` directly.
17. **Re-converge on Anthropic's reference firewall**: drop the resolver, SNI proxy and port scoping, and let upstream own the egress layer. *(Social: hand ownership back upstream.)*

Health check. *Clustering*: [3], [4], [5], [10] and [15] all assume "the runtime is the lever". [1], [2], [9], [16] and [17] break that assumption by acting on the boundary layer, the process or the tooling; [6], [7], [8], [11], [12] change the isolation primitive entirely. *Missing perspectives*: do-nothing [0], naive [14], ideal-if-free [11], newcomer's suggestion [3] ("why not podman?"). *Dimensional anchoring*: candidates move on five named dimensions — runtime ([3]-[5], [10]), isolation primitive ([6]-[8], [11], [12]), boundary-layer design ([9], [17]), tooling ([15], [16]), and process/time ([1], [2], [13]). Added after the check: [16] and [17], because the first pass had no tooling or ownership lever and §0.1 names the devcontainer CLI as one cause.

## Step 2 — Diagnose

Seeded from 015's two hard constraints (H1, H2), 016's per-project isolation, the hardened egress layer (log rows 39-41, 44, 55), Q-124/Q-125's sandbox, and 015's host facts. "Current investment" is the list in the brief: cc-isolated, the egress allowlist and SNI proxy, the exit scan, cc-push, the Q-125 seccomp/bwrap work, the WSL2 host.

Hard constraints:

- **H1 Credential denial for every tool.** *success:* the launcher's H1 probe passes: `~/.ssh/canary` on the host is unreadable from the session by Read and by Bash.
- **H2 Control plane outside the session.** *success:* the image-provenance probe (`/usr/local/share/cc-egress/`, `/etc/cc-egress-profile`, `/etc/cc-config-hash` equal to the blessed hash) passes, and an edit to the repo's `devcontainer-config/` changes nothing until install + bless.
- **H3 Default-deny egress at today's strength.** Port-scoped allowlist, filtering resolver (no recursive DNS tunnelling), SNI check on 443. *success:* from a session, `curl https://example.com` fails, an allowlisted host returns 200, a non-allowlisted name does not resolve, and `test/init-firewall-rules.bats` (or its replacement) is green.
- **H4 Per-project isolation** (016 H6). *success:* the H6 volume-identity probe passes, and a second registered project's path is absent in the container.
- **H5 The Q-125 Bash sandbox stays possible.** *success:* `live-check-q125.sh` C1-C4 pass on the mechanism (bwrap gets user, mount, pid and net namespaces under the runtime's seccomp; Q-126 passed this under Docker).
- **H6 Runs on this host without a root-equivalent grant to the agent's account.** WSL2 Ubuntu 22.04, kernel 6.18, no systemd bus, no docker group (015's host facts). *success:* `cc-isolated --probe-only <repo>` passes from a host terminal, and `id` for the user shows no `docker` group.
- **H7 No silent boundary loss in transition** (015's failure-driven mitigation; 016 [11]). *success:* every self-probe (H1, provenance, H6, firewall marker or its replacement) runs and passes on the new mechanism before the first real session, recorded as a `Live-verified: <hash>` trailer on the switching commit.

Soft constraints:

- **S1 Acts on the observed breakage source** (the motive, §0). Measured as: of the 6 fixes in §0.1, how many the candidate would have prevented or caught before main.
- **S2 Migration cost against the current investment.** cc-isolated.sh (944 lines), init-firewall.sh (1366), cc-sni-proxy.py (333), Dockerfile (531), install.sh (1355), cc-push.sh (602), cc-exit-scan.sh (1182), the egress lists, ~445 bats tests across six suites (`cc-isolated-functions` 193, `init-firewall-rules` 95, `install-host` 92, `cc-push` 48, `link-claude-home-wiring` 16, `cc-sni-proxy-unittest` 1), and the Q-125 branches. (The matrix-analysis sub-agents were told "~200"; the higher count only widens the gap between the keep-Docker items and the migrations.)
- **S3 Upstream-maintained tooling** (015's reason for Docker: the devcontainer CLI and reference config target Docker first).
- **S4 Verifiable with at most one host paste before commitment** (the sandbox cannot reach docker).
- **S5 Attention**: no new recurring host chores for the user.
- **S6 Smaller privileged trusted dependency** (015 accepted Desktop's privileged daemon).
- **S7 Claude Code currency** (015's other T2 clause: image staleness).

Non-obvious constraints found in research:

- `init-firewall.sh` encodes Docker Desktop's network topology: gateway detection from the default route (:660-671), the container's own bridge address as the DNAT target (log row 44), and comments at :1121-1125 that distinguish Desktop (host not on the bridge) from Engine (host is the gateway). Any runtime with a different network model (rootless slirp4netns/pasta, a podman bridge) changes those assumptions.
- `egress/llm.txt` admits `host.docker.internal:11434`, a Desktop-provided name. **[unverified, from memory]** podman's equivalent is `host.containers.internal`.
- `install.sh:1231-1278` and `cc-push.sh:296-318` call `docker ps --filter label=cc-project` for their agent and running-container checks. A runtime whose CLI is not `docker` must keep those checks honest, or both fail open (install.sh prints a NOTE and treats "no docker" as none running).
- `--id-label` and `--override-config` are devcontainer CLI features (016), so any runtime the CLI drives keeps them; a runtime it does not drive loses them.
- The Q-125 seccomp profile is Docker's default plus `CLONE_NEWUSER`; its meaning under another runtime's default profile is untested.

## Step 3 — Match and prune

| # | Approach | H1 | H2 | H3 | H4 | H5 | H6 | H7 | S1 | S2 | S3 | S4 | S5 | S6 | S7 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | Status quo | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ~ | ~ |
| 1 | Status quo + churn watch | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | ~ | ~ |
| 2 | Status quo + verify-before-merge | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ~ | ~ | ~ | ~ |
| 3 | Podman rootless | ✓ | ✓ | ~ | ✓ | ~ | ✓ | ~ | ✗ | ✗ | ~ | ~ | ~ | ✓ | ~ |
| 4 | Rootless Docker Engine | ✓ | ✓ | ~ | ✓ | ~ | ✓ | ~ | ✗ | ~ | ~ | ~ | ~ | ✓ | ~ |
| 5 | Rootful docker-ce | ✓ | ✓ | ✓ | ✓ | ✓ | ⚠ | ~ | ✗ | ~ | ✓ | ~ | ✗ | ✗ | ~ |
| 6 | Dedicated WSL2 distro | ✓ | ✓ | ✗ | ~ | ✓ | ✓ | ~ | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ |
| 7 | bwrap whole-process launcher | ~ | ~ | ✗ | ~ | ~ | ✓ | ~ | ✗ | ✗ | ✗ | ✓ | ~ | ✓ | ✓ |
| 8 | Dedicated unix user | ~ | ✓ | ✗ | ~ | ✓ | ✓ | ~ | ✗ | ✗ | ✗ | ~ | ~ | ✓ | ✓ |
| 9 | Docker + sidecar egress proxy | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ~ | ~ | ✗ | ✓ | ~ | ✓ | ~ | ~ |
| 10 | gVisor runtime | ✓ | ✓ | ~ | ✓ | ✗ | ~ | ~ | ✗ | ✗ | ~ | ✗ | ~ | ~ | ~ |
| 11 | Micro-VM per session | ✓ | ✓ | ~ | ✓ | ✓ | ✗ | ~ | ✗ | ✗ | ✗ | ✗ | ✗ | ~ | ~ |
| 12 | Remote / cloud box | ✓ | ~ | ~ | ✓ | ~ | ~ | ~ | ✗ | ✗ | ~ | ✗ | ✗ | ~ | ~ |
| 13 | Wait for first-party | — | — | — | — | — | — | — | ✗ | ✓ | ✓ | ✗ | ✓ | — | — |
| 14 | Back to host sessions | ✗ | ✗ | ~ | ✗ | ✓ | ✓ | ⚠ | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 15 | Runtime-agnostic launcher | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✗ | ~ | ~ | ~ | ~ | ~ | ~ |
| 16 | Drop the devcontainer CLI | ✓ | ~ | ✓ | ~ | ✓ | ✓ | ~ | ~ | ✗ | ✗ | ~ | ✓ | ~ | ~ |
| 17 | Re-converge on reference firewall | ✓ | ✓ | ⚠ | ✓ | ✓ | ✓ | ⚠ | ~ | ~ | ✓ | ~ | ✓ | ~ | ~ |

Scoring notes on the cells that decide a prune:

- **[0] vs [1]**: identical on every hard constraint and on cost; [1] adds a trigger that would have classified §0.1 correctly. [0] is **dominated by [1]** and folds into it: "keep Docker" is evaluated as [1].
- **[2] S1 ✓**: 4 of the 6 fixes (f906b50f, 95f5a86d, 6c35e39d, 7c970bfe) shipped without a live run; a merge-time live run would have caught at least f906b50f (no DNS is the first thing any probe sees) and 6c35e39d (every launch failed). 7c970bfe needs an Artifact read in the verify, so it is ~. S2/S4/S5 ~: it depends on the branch-verify DD's `cc-verify` (~250-300 lines, unbuilt) and adds a verify step per boundary merge.
- **[3] / [4] H3 ~, H5 ~, H7 ~**: in a rootless runtime the container's netns is owned by a user namespace. **[unverified, from memory]** iptables/ipset with NET_ADMIN inside it generally work, but the `ip_set` module must already be loaded on the host (rootless cannot modprobe), the network is slirp4netns or pasta rather than a bridge (so the gateway/DNAT assumptions in `init-firewall.sh` change), and nested user namespaces for bwrap depend on the outer mapping. None of that is checkable here. S1 ✗: 0 of 6 fixes were runtime-caused. [3] S2 ✗ (CLI name, `host.docker.internal`, network topology, Desktop-specific comments, every bats stub that fakes `docker`); [4] S2 ~ (same CLI, different topology).
- **[5] ⚠ H6**: the docker group (or a sudo grant to dockerd) is root-equivalent, which 015 chose Desktop to avoid, and 015 records no systemd bus to run dockerd. Pruned.
- **[6] ✗ H3**: a distro has no per-session netns; egress would move to Hyper-V/Windows firewall rules or a proxy, i.e. the egress stack is rebuilt from zero. S2 ✗. Pruned [revived from 015 [2], declined again: the boundary investment since 2026-07 is container-shaped, and the user declined this family in 015's Path B].
- **[7] ✗ H3**: bwrap gives namespaces but no allowlisting egress; building one is [9]'s proxy without the container. Pruned [carried from 015 [8]].
- **[8] H1 ~, H3 ✗**: unchanged from 015 (world-readable `/mnt/c`, shared `/tmp`, procfs). Pruned [carried from 015 [6]].
- **[10] ✗ H5**: **[unverified, from memory]** gVisor implements its own syscall surface; nested bwrap user namespaces and the netfilter features `init-firewall.sh` uses (ipset, nat OUTPUT) are partial or absent there, and installing `runsc` into Desktop's VM is not a supported path. Mostly ✗/~. Pruned.
- **[11] ✗ H6**: no micro-VM machinery on this host; nested virtualisation inside WSL2 is **[unverified, from memory]**. Pruned [carried from 016 [9]: ideal-if-free space-widener].
- **[12]** pruned [carried from 015 [12]/[10]]: relocation, not isolation; this host never pushes.
- **[13]**: not a design. Already 015 T3; kept as a trigger.
- **[14] ✗ H1/H2/H4, ⚠ H7**: pruned [carried from 015 [0/1/14]]. Q-121's occasional host fallback is this candidate happening by accident; it is a reason to keep the container reliable, not an option.
- **[15]**: dominated by [1] + 015's pre-named Reverse. A hot spare pays only when the Reverse trigger fires, and keeping two runtimes tested is two code paths [carried from 016 [4]]. Absorbed: if the Reverse trigger fires, [3] is implemented then.
- **[16] S3 ✗, S2 ✗**: removes one historical cause (e87e0b54) that is already pinned by three bats tests, at the cost of the upstream tool, `--override-config` and `--id-label`. Pruned.
- **[17] ⚠ H3, ⚠ H7**: re-opens recursive DNS tunnelling and port-wide egress that the 2026-08-29/09-03 security reviews closed (log rows 39-41). Pruned.

Survivors: **[1] [2] [9] [4] [3]** (five). [0] is folded into [1].

Fix sketches:

- **[1]**: detects but does not prevent. Fix: pair it with [2] later, or let its own trigger escalate to [2] when it fires (§6 drafts this).
- **[2]**: depends on an unbuilt tool. Fix: its first step is the branch-verify DD's own first step (a ~30-line paste that verifies Q-117 side by side), so it costs nothing until that spike passes.
- **[9]**: H3 ~ because decision 034 already records a residual DNS side channel through docker's embedded resolver on an `--internal` network. Fix: keep the filtering resolver, moved into the proxy container, and point the session's resolv.conf at it.
- **[4]** / **[3]**: H3/H5/H7 ~ are all host facts. Fix: one host probe (the Q-126 probe script, rerun under the candidate runtime, plus `init-firewall.sh` on a throwaway container) before any port. No port before that probe passes.

## Step 4 — Tradeoffs and decision

### 4.1 Calibrated scorecard (`matrix-analysis`)

The effort, risk and coverage cells come from `matrix-analysis` run as a sub-procedure. It used three parallel sub-agents, one per axis, each framed higher-is-better and given the five survivors, their step-3 rows and the §0 motive as the decision intent. Strong → ●, Adequate → ◐, Weak → ○. The per-criterion detail is folded in here instead of a separate `docs/reviews/matrix-analysis-*.md`, so this unit stays one file. No cell came back "Insufficient information".

| # | Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|---|---|---|---|---|
| 2 | Keep Docker + verify-before-merge | ◐ one unit, ~300 lines incl. bats (`cc-verify`, already roadmap Next 3's output) + one host check | ● low-med | ● 7/7 | depends on an unbuilt host tool; a strict merge refusal can stall boundary work if the tool misbehaves |
| 1 | Keep Docker + churn watch | ● 1-2 h, a text amendment | ◐ med | ● 7/7 | detects churn, prevents none of it; Desktop's privileged daemon stays |
| 9 | Docker + sidecar egress proxy | ○ several days, 1000+ lines (firewall, resolver/SNI placement, probes, tests) | ○ med-high | ◐ 5/7 | a large unverified boundary rewrite, the riskiest activity in the record; decision 034's DNS side channel |
| 4 | Rootless Docker Engine | ○ 1+ day host setup and spike, then a likely firewall rework | ○ high | ○ 4/7 | removes 0 of 6 causes; H3/H5 rest on unverified host behaviour |
| 3 | Podman rootless | ○ multi-unit, 1000-2000+ lines, plus a Q-125 seccomp re-proof | ○ high | ○ 4/7 | as [4], plus the CLI rename, test-stub churn, host alias and a different default seccomp |

What the sub-agents agreed on: all three ranked [2] and [1] first (in either order) and [3] last. All three named the same differentiator: *does the item act on where the breakage comes from, and does it migrate the verified boundary?* The coverage scorer weighted H3/H5 partials more heavily than H7, because they are the security-core and Q-125 constraints. The effort scorer ranked [9] above [4] because it is a bounded rewrite with prior art (034), where [4]'s size is unknown. The risk scorer noted that doing [2] first would lower the risk of [9], [4] and [3]; that sequence was not scored as an item of its own.

### 4.2 Falsifiable hypotheses

- **[2]** If chosen, then within 4 weeks of `cc-verify` merging, every merge to main touching a manifest-hashed `devcontainer-config/` file carries `Live-verified: <hash>`, and boundary-layer session breakages fall to at most 1 in any 2-week window. Counter-evidence: a boundary merge with `Live-verified: no` after the gate exists, or 2+ boundary breakages in a window whose fixes were verified (then verification is not the lever, and [9] is).
- **[1]** If chosen, the next cycle record classifies every breakage as runtime or boundary-layer with no "cannot tell" rows, and the runtime count stays at 0-1 per 2 weeks. Counter-evidence: 2+ runtime-caused breakages in a window (then Docker is the problem after all, and 015's Revisit fires as written), or the boundary count keeps firing with nothing changing (then [1] alone is ceremony).
- **[9]** If chosen, then within 3 weeks of the rewrite, no session-breaking fix touches netfilter steering or the firewall marker, and the H3 probes pass. Counter-evidence: the rewrite itself causes a breakage, or the DNS side channel through docker's embedded resolver is shown to carry data.
- **[4]** If chosen, the Q-126 probe and `init-firewall.sh` pass under rootless Docker within one host session, and the probes pass on the migrated config within 2 weeks. Counter-evidence: ipset or nat OUTPUT refused in the rootless netns, or bwrap refused nested user namespaces.
- **[3]** As [4], with podman. Counter-evidence also: the devcontainer CLI's podman path drops `--id-label` or `--override-config` semantics.

### 4.3 Stress-test pass

- **Boring alternative** (on [2]): is [1] enough? It costs an hour and changes nothing that can break. But §0.2's 87-to-1 ratio says the debt list `Live-verified: no` was meant to be is now the norm, not the exception, so a trigger that only counts the result will fire again with nothing to do. *Changed:* [1] is kept as the **trigger text** that ships now, and [2] as the **lever** it escalates to. The recommendation is the pair, with [2]'s cost largely already committed by roadmap Next 3.
- **Invert the thesis** (argue sincerely for [3] podman): no privileged daemon in a Windows-side VM, no Desktop licence, no Desktop update that breaks WSL integration, and 015 already named it as the fallback. What survives: the daemon point is real (S6), and host-side Desktop incidents are *invisible* to this repo (Q-121: the user falls back to host sessions "when the container image breaks"). What does not: none of the 6 recorded fixes is runtime-caused, and the port re-opens H3 and H5, which Q-126 has only proven under Docker. *Changed:* the amendment in §6 makes unclassifiable host-side incidents count as **runtime** breakage, so the podman case gets heard if Desktop is in fact the problem. §7 V1 asks the user for the host-side record.
- **Revealed preferences** (on [3], [4], [9]): the user declined the WSL-distro family in 015 Path B for the committed portable config, and answers terminal entries in batches. Every migration candidate starts with a day of host setup and a spike. *No glyph change:* effort stays ○ for all three.
- **Failure-driven** (on [2]): new failure categories [2] introduces. (a) A merge refusal that stalls boundary work when `cc-verify` itself is broken. (b) The branch's `devcontainer.json` reaching the host daemon without the install diff (`initializeCommand`, `--privileged`, host mounts), which the branch-verify DD's pre-mortem already covers with an allowlist and a diff stop. (c) `live-verify-gate.sh` sees only commits made in hooked sessions (decision 035's residual), so a host-side merge bypasses the refusal. *Changed:* [2]'s refusal must sit at the **merge** step that pr-prep runs, and fail with a named override (`Live-verified: no — <reason>` plus a `docs/reviews/override-log.md` row), not hard-block. [2]'s key downside is tagged (mitig.).
- **What-if** (on [2] and [1], the top two; full analysis in §5). It changed one hypothesis ([1] now names "cannot tell" rows as counter-evidence) and added the volume-migration cliff to [4]'s key downside.

### 4.4 Decision presentation

```
┌─ DECISION: should cc-isolated's isolation mechanism change, given 015's breakage trigger fired? ─┐
│ 5 candidates survived step-3 pruning · scored on the step-4 axes (matrix-analysis calibrated)   │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                           effort          risk        coverage      key downside
  ───  ─────────────────────────────────  ──────────────  ──────────  ────────────  ──────────────────────────────────────────────
   2 ★ keep Docker + verify-before-merge   ◐ 1 unit ~300   ● low-med   ● 7/7 hard    ◐ unbuilt host tool; refusal can stall (mitig.)
   1   keep Docker + churn watch           ● 1-2 h text    ◐ med       ● 7/7 hard    ○ detects churn, prevents none
   9   Docker + sidecar egress proxy       ○ days, 1000+   ○ med-high  ◐ 5/7 hard    ○ large unverified rewrite; 034 DNS residual
   4   rootless Docker Engine              ○ 1+ day+port   ○ high      ○ 4/7 hard    ○ 0/6 causes removed; volume-migration cliff
   3   podman rootless                     ○ multi-unit    ○ high      ○ 4/7 hard    ○ as [4] + CLI, alias, seccomp re-proof
```

```
╭─ [2] keep Docker + verify-before-merge   ★ recommended ──────────────────────────────╮
│ effort    1 unit (~300 lines incl. bats; Next 3's cc-verify) + 1 host check         │
│ risk      low-med · coverage 7/7 hard · 5/7 soft (S2, S4 partial)                   │
│ hypothesis  "If chosen, every boundary merge carries Live-verified: <hash> within 4 │
│             weeks of cc-verify merging, and boundary breakage ≤1 per 2 weeks;       │
│             counter-evidence = a boundary merge with 'no' after the gate, or 2+     │
│             verified-but-broken merges in a window."                                │
│ stress-tests applied                                                                │
│   · Boring alternative → [1] ships now as the trigger text; [2] is its lever        │
│   · Invert the thesis → unclassified host incidents count as runtime breakage       │
│   · Failure-driven → refusal at pr-prep merge with a named, logged override         │
│   · What-if → "cc-verify works without install" is load-bearing; [1] holds if not   │
│ key downside  an unbuilt host tool tied to the launcher; mitigated by the branch-   │
│               verify DD's pin test and allowlist, and by an override, not a block   │
╰─────────────────────────────────────────────────────────────────────────────────────╯
```

Expand any other candidate's card by naming its `#`.

```
▶ recommend [2] keep Docker + verify-before-merge (with [1]'s trigger amendment now) · confidence 80% · runner-up [1], axis = prevention vs zero cost
```

The confidence is split on purpose. **Keep Docker (015 stands)** against any mechanism change: ~90%, because no candidate that changes the runtime removes any recorded cause, and each re-opens H3/H5. **[2] over [1] alone**: ~70%, because [2] rests on the branch-verify spike passing (that research doc's §7 lists four unverified claims). Combined as one recommendation: 80%.

### 4.5 Decision path

**Path C** (no human present). The static block above is the record. The choice goes to the user through the caller's report as an options table, not through `docs/working/questions.md` (this unit may not edit it). Tentative pick: [2] with [1]'s amendment now. Axis of disagreement between [2] and [1]: *prevention vs zero cost*. The project's stated preference on that axis: log row 45 chose to make the verification question *asked* ("the failure to fix is the question going unasked"), and §0.2 shows asking is not enough, which favours [2]. Tiebreaker for the order: [1] costs nothing and ships first; [2] arrives when roadmap Next 3's `cc-verify` lands, so neither waits on the other.

## 5. What-if analysis on the top two ([2], [1])

> No upstream critique provided. This analysis covers the consequence space independently; all findings are [NOVEL] unless tagged [PRIOR CONSIDERATION]. Folded in here rather than written to `docs/reviews/what-if-analysis.md`, so this unit stays one file.

Prior-art check: `rg -il "live-verif|verify|breakage|podman|rootless|volume" docs/decisions docs/working` → log row 45, decision 035, the branch-verify research and DD, 016's post-implementation correction. Cited below where they already cover a finding.

### Assumptions examined

| Assumption | Source | If wrong | Tag |
|---|---|---|---|
| The git record sees all breakage; host-side Docker Desktop incidents are rare | implicit in §0.1 | **redesign**: the motive flips toward [3]/[4] | [UNEXAMINED ASSUMPTION] (partly surfaced by Q-121) |
| `cc-verify` can live-verify a branch with no install | `research-branch-verify-without-install.md` §7 (four unverified claims) | **redesign**: [2] collapses to [1] | [PRIOR CONSIDERATION] the branch-verify DD's first step tests exactly this |
| A live run at merge would have caught the unverified breakages | §0.1 | tweak: 7c970bfe needed an Artifact read, which a probe-only verify misses | [NOVEL] |
| Boundary churn will slow down by itself as the hardening wave ends | implicit in [1] | tweak: [1] fires again and escalates to [2] | [NOVEL] |
| Docker Desktop stays free for this use | 015 T5 | full retreat for Docker: 015's Reverse fires | [PRIOR CONSIDERATION] 015 T5; licence facts **[unverified, from memory]** (§7 V8) |

### Consequence chains

```
→ First-order ([2]): boundary branches get a live run before merging
  → Second-order: each boundary merge costs a verify (minutes, up to ~45 min for an egress pool rotation)
    → Third-order: boundary changes batch into larger merges to amortise the verify → bigger blast radius per merge
    → Third-order: the 87 'Live-verified: no' backlog has to be paid down once, or grandfathered
→ First-order ([2]): `Live-verified: no` becomes an exception with a logged reason
  → Second-order: the override log becomes the real debt list
    → Third-order: if overrides become routine, [2] decays into [1] with more ritual; [1]'s trigger is what notices
→ First-order ([1]): breakages are classified runtime vs boundary-layer
  → Second-order: the dev-cycle trigger step needs a classification rule it can apply from git alone
    → Third-order: host-only incidents need a human input channel (the roadmap idea "usage log records host vs container")
```

### Coupling analysis

- **Visible**: `hooks/live-verify-gate.sh` (log row 45) is the commit-time half; [2] adds a merge-time half. They must agree on which files count (`enforcement_files()` vs `host_tool_files()`, log row 71).
- **Invisible (behaviour)**: the gate sees only commits made in hooked sessions (decision 035's failure-driven residual). A merge made at the host shell bypasses it. [PRIOR CONSIDERATION] 035.
- **Invisible (shared resource)**: per-project `/home/node/.claude` volumes (credentials, memory, history) live in Docker's storage. Under Docker Desktop that is Desktop's own data distro **[unverified, from memory]** (§7 V11). Any runtime switch ([3], [4]) orphans them unless exported. No earlier record names this migration cost. [NOVEL]
- **Invisible (convention)**: `init-firewall.sh` assumes Desktop's topology (host not on the bridge; :1121-1125). Rootless networking breaks that convention silently. [NOVEL]

### Confidence inversions

- *"The churn is ours"* (Q-105). Inverted: Desktop updates break WSL integration monthly, and the user quietly falls back to host sessions (Q-121) without a commit. Then the runtime **is** a cause, invisible to git, and [1]'s runtime count reads 0 falsely. Mitigation: unclassifiable incidents count as runtime (§6), and V1 asks the user.
- *"A merge-time verify catches what broke"*. Inverted: the f906b50f class passed every root-run probe while `node` had no DNS. Log row 45's probe now checks the firewall marker and the baked config hash, but a defect that shows only in use (7c970bfe) still passes a probe-only run. Mitigation: the verify runs one in-session smoke step as `node` (an allowlisted fetch, an Artifact-zone resolution).

### Adversarial scenarios

1. **A Desktop update breaks WSL integration for a week** (likelihood **[unverified, from memory]**). Sessions fall back to the host. Under the amendment that counts as runtime breakage; two such weeks fire 015's Revisit as written, and podman is pre-named. No change needed.
2. **A Q-125-sized boundary branch lands while `cc-verify` is still unbuilt**. [2] cannot help yet; [1]'s trigger is the only guard. Acceptable: the branch-verify DD's first step (a paste) is usable before the tool exists.
3. **`cc-verify`'s spike fails** (the image tag is not path-keyed, or main's launcher refuses a stage). [2] falls back to "verify by install in a quiet window" (the branch-verify DD's [15]), which costs a session stop. [1] still holds.

### Reversibility map

| When | [1] | [2] | [3]/[4], for contrast |
|---|---|---|---|
| 1 week | delete the amendment | stop running the tool; keep the gate warn-only | uninstall the runtime |
| 1 month | same | same; the override log stays as history | per-project volumes now created under the new runtime; Desktop's go stale |
| 6 months | same | same | **cliff**: credentials and memory live in the new runtime's volumes; reverting needs an export, and Desktop may be gone |

[1] and [2] have a flat gradient. [3]/[4] have a cliff at the first volume migration. [REVERSIBILITY CLIFF]

### Cost of success

If [2] works perfectly: every boundary merge waits on a live run, a second host tool sits in row 71's trust category to maintain, and the launcher and `cc-verify` have to keep agreeing on the launcher's layout (the branch-verify DD's pin test). If [1] works perfectly: a classification step in every dev cycle, and an amended 015 carrying two counting rules. [SUCCESS COST] Both are small next to a runtime migration's cost of success: a re-proven boundary exactly as churn-prone as today's.

### Findings summary

- [UNEXAMINED ASSUMPTION] host-side runtime incidents are invisible to the record → §6 counts them as runtime; §7 V1.
- [SECOND-ORDER EFFECT] verify friction batches boundary changes → [2]'s plan should keep one boundary concern per branch (log row 62's cap already pushes this way).
- [HIDDEN COUPLING] per-project `~/.claude` volumes are runtime-owned → named as a migration cost for [3]/[4].
- [HIDDEN COUPLING] [PRIOR CONSIDERATION] decision 035: the gate sees hooked sessions only → [2]'s refusal sits at pr-prep's merge step.
- [REVERSIBILITY CLIFF] a runtime switch at the first volume migration.
- [SUCCESS COST] a second host tool and a cycle classification step.

### Recommendations

- **Must address before proceeding**: none for [1]. For [2]: the branch-verify spike (its research §7 claims) must pass before a merge refusal is turned on.
- **Worth mitigating**: the host-incident blind spot (V1; the usage-log host/container field already on the roadmap Ideas list); an in-session smoke step in the verify.
- **Acknowledged risks**: Desktop's privileged daemon (accepted by 015, unchanged); the devcontainer-CLI and kernel-semantics causes, which every survivor shares.

## 6. Draft amendment to decision 015's Revisit triggers (applied 2026-10-20 on Q-170 [A], branch `docs/decision-015-amendment`)

This text is for the user's approval. This unit does **not** edit `docs/decisions/015-cc-process-isolation-docker-devcontainer.md`.

**1. Replace** this sentence in `## Revisit triggers`:

> If devcontainer breakage exceeds 1/week over any 2-week window → Revisit branch.

**with:**

> If **runtime-caused** devcontainer breakage exceeds 1/week over any 2-week window → Revisit branch (re-run step 4; [4] podman rootless stays the pre-named fallback). Runtime-caused means a session-breaking failure whose fix lies in Docker Desktop, the Docker engine, WSL integration or the devcontainer CLI, not in this repo's files; a host-side incident with no fix commit (a session moved to the host because the container would not start, Q-121) counts as runtime-caused until shown otherwise. If **boundary-layer** breakage — a commit merged to main that touches `devcontainer-config/` and restores a session that could not start, could not reach an allowlisted host, or could not pass its self-probe; review iterations on unmerged branches do not count — reaches 2 or more in any 2-week window → do not re-run step 4. Check how those changes merged: if any carried `Live-verified: no`, raise verify-before-merge (`docs/working/dd-015-step4-isolation-mechanism.md` candidate [2], built on the branch-verify DD's `cc-verify`) to the top of the roadmap; if all were verified live, re-open the boundary-layer design instead (that DD's candidate [9], sidecar egress proxy). The dev-cycle trigger step records each breakage with its fix commit and its class (runtime or boundary-layer).

**2. Replace** the Revisit row's trigger cell in the decision-rule table:

> \>1 Docker/devcontainer breakage per week needing manual fixing, or image staleness pins CC >1 version behind for >2 weeks

**with:**

> \>1 runtime-caused breakage per week (Docker Desktop, engine, WSL integration or devcontainer CLI; see Revisit triggers for the definition, and for boundary-layer breakage, which routes elsewhere), or image staleness pins CC >1 version behind for >2 weeks

**3. Append** to `## Consequences` (a dated note, as 016 and 035 do):

> **Note, 2026-10-15 (Q-105 [3]).** Step 4 was re-run as a divergent design (`docs/working/dd-015-step4-isolation-mechanism.md`). Of the 6 session-breaking fixes since 2026-07-13, none was caused by Docker; 4 came from this repo's boundary changes merged without a live run. Docker stands. The breakage trigger now separates runtime-caused from boundary-layer breakage, and the boundary-layer trigger points at verify-before-merge rather than at a runtime re-run.

This is Q-105's option [2] made precise, plus an escalation path, so a firing boundary trigger points at a lever rather than at a runtime re-run.

## 7. Claims not verified from the repo, and the host check for each

No web egress and no docker here. Each item names the check that would settle it. Run them from a host terminal, never inside a Claude Code session. None blocks the recommendation; V1 is the only one that could change it.

| # | Claim | Source | Host check |
|---|---|---|---|
| V1 | Host-side Docker Desktop incidents (WSL integration loss, Desktop update breakage) have been rare since 2026-07-13 | unknown: the repo cannot see them (Q-121 says some exist) | The user lists the dates sessions moved to the host because the container would not start, and why. Optionally Desktop's own logs (`%LOCALAPPDATA%\Docker\log`, path from memory). |
| V2 | In a rootless container's netns, iptables nat OUTPUT and ipset work with NET_ADMIN, provided `ip_set` is already loaded on the host (rootless cannot modprobe) | memory | `lsmod \| grep ip_set` on the host; then `podman run --rm --cap-add=NET_ADMIN,NET_RAW debian:bookworm sh -c 'apt-get update -qq && apt-get install -y -qq ipset iptables && ipset create t hash:net,port && iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination 127.0.0.1 && echo OK'`, and the same under a rootless `docker`. |
| V3 | Ubuntu 22.04's repo ships an old podman (3.4.x, CNI/slirp4netns); pasta is podman 5's default | memory | `apt-cache policy podman`; after install, `podman info --format '{{.Host.NetworkBackend}}'`. |
| V4 | The devcontainer CLI drives podman through `--docker-path podman` and keeps `--override-config` and `--id-label` | memory | In a scratch clone: `devcontainer up --docker-path podman --workspace-folder <clone> --override-config <installed devcontainer.json> --id-label cc-project=test`, then `podman ps --filter label=cc-project=test`. |
| V5 | podman provides `host.containers.internal` where Desktop provides `host.docker.internal` | memory | `podman run --rm alpine getent hosts host.containers.internal`. |
| V6 | Nested user namespaces for bwrap work inside rootless podman / rootless Docker under the Q-125 profile | memory (Q-126 proved it only under Desktop) | Re-run the Q-126 probe script with `docker` replaced by `podman` (or `DOCKER_HOST` pointed at a rootless daemon); variant A T1 must pass. |
| V7 | Rootless Docker needs `newuidmap`/`newgidmap`, `/etc/subuid` ranges and rootlesskit, and without systemd it needs a manual start | memory | `dockerd-rootless-setuptool.sh check`; `grep "$USER" /etc/subuid /etc/subgid`. |
| V8 | Docker Desktop is free for personal use and for businesses under 250 employees and $10M revenue (015 T5) | memory | Read Docker's current pricing and subscription terms in a host browser. |
| V9 | gVisor lacks the netfilter (ipset, nat OUTPUT) and nested-userns support this boundary needs | memory | Only if [10] is revived: `docker run --runtime=runsc --cap-add=NET_ADMIN ...` with V2's commands. |
| V10 | Nested virtualisation for micro-VMs is not available in this WSL2 distro | memory | `ls -l /dev/kvm` in the distro. |
| V11 | Per-project `/home/node/.claude` volumes live in Docker Desktop's own storage, so a runtime switch orphans them | memory | `docker volume inspect cc-<pid>-claude-config --format '{{.Mountpoint}}'`, and note that the path is inside Desktop's VM, not the Ubuntu distro. |
| V12 | `podman ps --filter label=… --format '{{.Names}}'` behaves like docker's, so install.sh's and cc-push.sh's checks port with only a CLI name change | memory | `podman ps --filter label=cc-project --format '{{.Names}}'` with one labelled container running. |

## 8. The user's decision

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[A] Keep Docker; amend 015 now; verify-before-merge via `cc-verify`** (recommended) | Apply §6's amendment to 015. [2] arrives with roadmap Next 3's `cc-verify`; then pr-prep refuses boundary merges carrying `Live-verified: no` unless a logged override is given. | Approve one text amendment now; the Next 3 answer (already pending) and one host check later. | If Desktop is in fact breaking sessions off the record (V1), the runtime trigger fires and podman is pre-named. Some unverified boundary changes still land until `cc-verify` exists. |
| **[B] Keep Docker; amend 015 only** (Q-105 [2] made precise) | Apply §6's amendment; no merge-time refusal. Boundary churn is watched, not prevented. | Approve one text amendment. | The boundary trigger keeps firing and routes back to [A]; sessions break in the meantime, as in September. |
| **[C] Spike rootless Docker or podman before deciding** | One host paste covering V2-V7 and V12; decide after the results. | One terminal paste (~30 min with image pulls), plus reading the results. | A session spent on a runtime that removes none of the recorded causes. If the spike passes, a migration still costs days and re-opens H3/H5. |
| **[D] Rewrite the egress layer as a sidecar proxy ([9])** | Keep Docker; replace the in-container netfilter/DNS/marker stack with an `--internal` network and a proxy container (034's shape). | Review of a multi-day enforcement rewrite and its live run. | A large unverified boundary change, the activity behind 4 of 6 breakages, plus 034's DNS side-channel residual. |

## Hypothesis

Not emitted: this is a standalone single-shot DD, not a multi-round context.
