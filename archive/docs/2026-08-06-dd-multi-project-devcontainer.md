# DD — generalizing the isolated-session devcontainer across all CC projects

- **Goal**: Decide how the decision-015 devcontainer boundary is made available to every CC project on this host, not just the `claude-workflows` repo.
- **Project state**: standalone follow-on to decision 015 · not blocked
- **Task status**: complete (Path-B consult resolved to [3]; decision record: `docs/decisions/016-multi-project-devcontainer-central-config.md`)

## Trigger

User asked: "can I just run `devcontainer-session.sh` from a different directory?" Answer is
no, and the failure is silent — `scripts/devcontainer-session.sh:118` resolves the workspace
from `${BASH_SOURCE[0]}`, not `$PWD`, so invoking it from another repo launches a session on
`claude-workflows` without complaint.

---

## Step 1 — Diverge

### 1.0 Pre-generation grep

    grep -A 12 "^## Pruned candidates" docs/decisions/*.md | rg -i "devcontainer|container|per-repo|portable|workspace|launcher|volume|image"

**Prior pruning grep: one match — decision 015.** Its pruned set is boundary-*technology*
choices (which isolation primitive), whereas this DD is a boundary-*distribution* choice
(how the settled primitive reaches N repos). Most entries are therefore out of scope rather
than carried. The ones that genuinely re-surface:

- `[2 WSL2 dedicated distro]` — **carried from 015**: declined in that DD's Path-B consult
  (user preferred the devcontainer's committed config + inherited egress firewall). A
  per-project-distro candidate would re-propose it; not regenerated except as the
  ideal-if-free space-widener (candidate 9).
- `[12 remote dev box]` — **carried from 015**: "solves relocation, not isolation." The
  shared-workbench candidate (5) below is its local cousin and is pruned on the same axis.
- `[6 dedicated unix user]` — **carried from 015**: H1 only partial. Not regenerated.
- `[4 podman rootless]` — not pruned in 015; it is the pre-named Reverse fallback. Whichever
  candidate wins here must not make that reversal harder (tracked as soft constraint S7).

### 1.1 Candidates

| # | Candidate | Lens |
|---|-----------|------|
| 0 | **Status quo** — devcontainer for `claude-workflows` only; other projects run on the host as before. | Reframe |
| 1 | **Minimal change** — leave the launcher single-repo, but make it fail loudly when invoked from outside its own repo. Closes the footgun, delivers no multi-project support. | Technical |
| 2 | **Vendor-per-repo** — copy `.devcontainer/` + `scripts/devcontainer-session.sh` into every project; each repo blesses its own manifest. | Technical |
| 3 | **Central host-side config + `--override-config`** — one `~/.config/claude-devcontainer/` holding `devcontainer.json` + `Dockerfile` + `init-firewall.sh`, plus a `cc-isolated <repo>` launcher on `PATH`. Target repos get **zero** new files; the boundary config is never inside a bind mount. | Technical |
| 4 | **Hybrid** — central default config as in (3), but a repo may ship its own `.devcontainer/` which wins if present *and* blessed. | Technical |
| 5 | **Shared workbench container** — one long-lived container with every repo bind-mounted under `/workspace/*`; pick a project by `cd`. | Technical |
| 6 | **Template generator** — `cc-devc init` scaffolds `.devcontainer/` into a repo from a shared template plus a version stamp; drift detected by comparing against the template hash. | Procedural |
| 7 | **Base image + thin overlay** — publish a `claude-base:NNN` image with CC and the firewall baked in; each repo's `devcontainer.json` is ~5 lines (`"image": "claude-base"` + any extra allowlist domains). | Technical |
| 8 | **Devcontainer Feature** — package CC + firewall as an OCI-published devcontainer Feature; any repo opts in with one line in its own `devcontainer.json`. | Interface |
| 9 | **Ideal-if-free** — a dedicated micro-VM (or WSL2 distro) per project, auto-provisioned; kernel-level isolation, no shared daemon. | Technical |
| 10 | **Symlink farm** *(naive)* — symlink other repos into `/workspace/` so the existing container sees them. | Naive |
| 11 | **Raw CLI** *(naive)* — drop the launcher entirely; run `devcontainer up --workspace-folder .` by hand per repo. Portability by abandoning the trust manifest and the boundary probe. | Naive |
| 12 | **Time-shifted** — do nothing now; adopt per-repo devcontainers if/when Anthropic ships a first-party whole-process sandbox (already a 015 revisit trigger). | Time-shifted |
| 13 | **Git submodule** — publish `.devcontainer/` from this repo as a submodule each project includes; updates flow by submodule bump. (Repo already uses `.gitmodules`.) | Social/org |
| 14 | **Per-language egress profiles** — central config parameterized by an allowlist profile (node / python / rust / lean), selected per project; images tagged per profile. | Technical |

### Generation health check

- **Clustering — triggered.** Candidates 2, 4, 6, 7, 8, 13 are all near-variants of one
  assumption: *the boundary config must be distributed into each repo.* Named the shared
  assumption and generated candidates that violate it — **3** (config never enters the repo),
  **5** (one container, many repos), **9** (different boundary primitive entirely).
- **Dimensional anchoring — addressed.** Dimensions moved: *where the config lives* (2/3/4/13),
  *container topology* (3 vs 5 — N containers vs 1), *boundary primitive* (9), *egress-policy
  granularity* (14), *distribution mechanism* (6/7/8/13).
- **Missing perspectives — present.** Do-nothing (0), minimal-change (1), naive (10, 11),
  ideal-if-free (9).
- **Vagueness — none.** Each candidate names a concrete mechanism testable against step 2.

---

## Step 2 — Diagnose

### Hard constraints

**H1 — No silent wrong-workspace launch.**
The current failure. Invoking the launcher from repo B must never open a session on repo A.
`success:` `cd ~/proj-b && <launcher>` either enters a container whose `/workspace` is
`proj-b`, or exits non-zero naming the mismatch. A bats test asserts the non-zero exit and
the message; a second assertion checks the in-container `/workspace` identity matches the
intended target (git toplevel basename + remote URL).

**H2 — The boundary config must not be silently agent-editable.**
Decision 015's whole trust-manifest apparatus exists because `.devcontainer/` and the launcher
are bind-mounted read-write into the container, so a session *can* rewrite the boundary it
runs under; the manifest catches it at the next rebuild gate. Any multi-project design must
preserve at least that, and preferably remove the hole.
`success:` For every supported project, **either** the enforcement files are outside every
bind mount (`test -e <config-path>` inside the container returns false) **or**
`check_manifest` exits non-zero when any enforcement file is modified (existing bats tests at
`test/devcontainer-session-functions.bats:78,86`, generalized to a per-project workspace).

**H3 — Manifest keys must not collide across projects.**
`manifest_path()` keys on `basename "$workspace"` (`scripts/devcontainer-session.sh:42`), so
`~/work/app` and `~/side/app` share one blessed manifest — blessing one silently blesses the
other.
`success:` A bats test asserts `manifest_path /x/app != manifest_path /y/app`, and that
blessing `/x/app` leaves `/y/app` unblessed (`check_manifest /y/app` still exits non-zero).

**H4 — The boundary self-probe runs per project, before `claude` starts.**
`success:` For each target, `probe_boundary` shows `~/.ssh/canary` invisible and
`https://example.com` unreachable; on failure the launcher exits non-zero and `claude` is
never exec'd (current semantics at `scripts/devcontainer-session.sh:151-156`, retargeted).

**H5 — Per-project egress differs without weakening other projects.**
The allowlist is baked into the image (`.devcontainer/Dockerfile:93`) and is tuned for *this*
repo (openrouter.ai, elan.lean-lang.org). A Python project needs PyPI; a Rust one needs
crates.io.
`success:` A session in a Python project reaches `pypi.org` **and** a concurrent session in
`claude-workflows` still cannot (`curl --connect-timeout 5 https://pypi.org` REJECTs there).

**H6 — Cross-project isolation at least as strong as today's cross-session isolation.**
`devcontainer.json:38-39` hardcodes the volumes `claude-workflows-bashhistory` and
`claude-workflows-claude-config`; the latter mounts to `/home/node/.claude`. Copy that file
verbatim into other repos and every project shares one `~/.claude` — credentials, memory,
session history — so a compromised session in A reads B's secrets.
`success:` From inside project A's container, project B's repo path and B's `~/.claude`
volume are both absent (`test -e` fails for each); asserted by a probe extension.

### Soft constraints

- **S1 — Onboarding cost.** Adding a project should be ≤1 command with no files to copy.
  `success:` new project reaches a running session without editing any file in that repo.
- **S2 — Build cost amortized.** N projects must not mean N full image builds.
  `success:` adding a project reuses a cached base-image layer; only the allowlist layer differs.
- **S3 — Fixes propagate once.** A security fix to `init-firewall.sh` should not require N
  manual edits. (The 2026-07 NXDOMAIN and ipset-duplicate fixes — commits `f3d9c20`, `3d0c51a` —
  are exactly this class, and both would have needed fan-out under a vendored scheme.)
- **S4 — Portability / self-description.** Decision 015 lists "the devcontainer config is
  committed per-repo and portable to other machines" as a *benefit* of the chosen approach.
  **Note the tension:** that property is precisely what puts the config inside the agent's
  bind mount and forces H2's manifest. S4 and H2 pull against each other; the decision has to
  price that.
- **S5 — Coexistence.** Some projects will already have their own `.devcontainer/` for
  non-CC reasons.
- **S6 — IDE story.** VS Code Dev Containers discovers `.devcontainer/devcontainer.json` in
  the workspace; it does not consume `--override-config`.
- **S7 — Don't obstruct the 015 Reverse branch.** Podman rootless is the pre-named fallback;
  the winner should not hard-couple to Docker-only mechanics.

Count: **6 hard · 7 soft.**

---

## Step 3 — Match and prune

| # | Approach | H1 no-silent-launch | H2 config integrity | H3 key collision | H4 probe per project | H5 egress per project | H6 cross-project isolation |
|---|----------|---|---|---|---|---|---|
| 0 | Status quo | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| 1 | Minimal guard | ✓ | ~ | ✗ | ~ | ✗ | ✗ |
| 2 | Vendor-per-repo | ✓ | ~ | ✓* | ✓ | ✓ | ⚠ |
| 3 | Central + `--override-config` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 4 | Hybrid central + blessed override | ✓ | ~ | ✓ | ✓ | ✓ | ✓ |
| 5 | Shared workbench | ✗ | ✗ | n/a | ~ | ✗ | ⚠ |
| 6 | Template generator | ✓ | ~ | ✓* | ✓ | ✓ | ~ |
| 7 | Base image + thin overlay | ✓ | ~ | ✓* | ✓ | ✓ | ~ |
| 8 | Devcontainer Feature | ✓ | ~ | ✓* | ✓ | ✓ | ~ |
| 9 | Micro-VM per project | ✓ | ✓ | n/a | ✓ | ✓ | ✓ |
| 10 | Symlink farm | ✗ | ✗ | n/a | ✗ | ✗ | ⚠ |
| 11 | Raw CLI | ✓ | ⚠ | n/a | ⚠ | ~ | ~ |
| 12 | Time-shifted | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| 13 | Git submodule | ✓ | ~ | ✓* | ✓ | ✓ | ~ |
| 14 | Egress profiles | n/a | n/a | n/a | n/a | ✓ | n/a |

`✓*` = collision fixable with a one-line change (key the manifest on a hash of the absolute
path instead of `basename`); the fix is identical across those candidates and is assumed
applied.

### Pruned

- **[0] / [12]** — fail every hard constraint by construction; [12] is a wait-for-upstream bet
  already captured as a 015 revisit trigger, not a design.
- **[1]** — satisfies H1 and nothing else. **Not discarded so much as absorbed:** the loud-fail
  guard is a prerequisite component of every surviving candidate, not an alternative to them.
- **[5] shared workbench** — ⚠ on H6. One container seeing every repo means one prompt-injected
  session reaches all of them; it inverts the property 015 was built to buy. Same axis as 015's
  pruned `[12 remote dev box]`.
- **[10] symlink farm** — mechanically broken (a symlink across a bind mount points at a path
  the container's mount namespace doesn't have) *and* ⚠ on H6.
- **[11] raw CLI** — ⚠ on H2 and H4: buys portability by deleting the trust manifest and the
  self-probe. 015's failure-driven mitigation is explicit that a silently-degrading boundary is
  worse than none.
- **[9] micro-VM per project** — the ideal-if-free space-widener; scores 6/6 but the
  provisioning machinery doesn't exist on this host and 015 already declined the WSL2-distro
  family in its Path-B consult. Carried, not revived.
- **[6] template generator / [13] git submodule** — both are [2] with a propagation mechanism
  bolted on. They inherit [2]'s H2 hole (config still lands inside the agent-visible repo) while
  adding machinery. Folded into [2]/[4] rather than carried as separate survivors.
- **[7] base image + thin overlay** and **[14] egress profiles** — not standalone alternatives.
  Both are **sub-mechanisms the winner needs anyway**: [7] to satisfy S2, [14] to satisfy H5.
  Adopted by whichever candidate wins.

### Survivors → step 4

**[3]** central host-side config · **[4]** hybrid · **[2]** vendor-per-repo · **[8]** devcontainer Feature

---

## Step 4 — Tradeoff, stress test, decision

### Tradeoff matrix

| # | Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|----------|--------|------|-----------------|--------------|
| 3 | Central + `--override-config` | 4–6 h | med-low | 6/6 | One config = one blast radius; VS Code Dev Containers can't see it (S6) |
| 4 | Hybrid central + blessed override | 6–8 h | med | 6/6 | Two code paths, two trust regimes; the override path re-opens H2 unless blessed |
| 2 | Vendor-per-repo | 2–3 h + ~20 min/repo forever | low today, rising | 4/6 | H2 hole stays open by design; N drifting copies of `init-firewall.sh` |
| 8 | Devcontainer Feature | 8–10 h | med-high | 4/6 | Needs an OCI registry; the opt-in line lives in an agent-editable file |

### Falsifiable hypotheses

- **[3]** If we adopt the central host-side config, we expect every CC project on this host to
  be launchable with one command and zero repo-side files within 2 weeks, with the H1/H6 probes
  passing per project; counter-evidence would be `--override-config` failing to resolve the
  Dockerfile build context (forcing a prebuilt-image detour), or ≥1 project needing a repo-local
  `.devcontainer/` anyway inside the first month.
- **[4]** If we adopt the hybrid, we expect ≥1 project to actually exercise the per-repo override
  path within a month; counter-evidence would be zero overrides in use at 1 month — which would
  mean we paid for two code paths and shipped one.
- **[2]** If we vendor per repo, we expect config drift to stay benign; counter-evidence would be
  any security fix to `init-firewall.sh` landing in fewer than all vendored copies within a week
  of being written (the 2026-07 NXDOMAIN and ipset fixes are the base rate: 2 such fixes in one
  month).
- **[8]** If we ship a Feature, we expect projects with pre-existing devcontainers to adopt it
  with a one-line edit; counter-evidence would be the registry/auth overhead exceeding the
  launcher work it replaces.

### Stress-test pass

**Boring alternative** (applied to the leading [3]) → *Is [2] good enough?* It is ~80% of the
benefit for ~40% of the effort **today**. What it doesn't buy: the H2 hole stays open by
construction (the launcher and the firewall script sit inside the repo the agent can write), and
the recurring cost is per-repo and permanent. Since [3] is only ~2× the one-time effort and
*retires* the hole rather than gating it, [2] survives as runner-up but doesn't dislodge the
recommendation. **Matrix change:** none — but this is the axis the human should be consulted on.

**Invert the thesis** (argue sincerely for [2]) → What survives is **S4**: decision 015 explicitly
banked "config committed per-repo and portable to other machines" as a benefit. A config in
`~/.config/` doesn't travel with the repo, doesn't get code-reviewed, and doesn't exist on a
second machine. That's a real cost of [3] and I nearly under-priced it. **Mitigation (adopted):**
[3] keeps the *canonical* config committed in this repo under `devcontainer-config/`, and the host
launcher runs from a **copy** installed to `~/.config/claude-devcontainer/` by an explicit
`install` step. Portability survives via git; integrity survives because the copy the launcher
actually reads is outside every target's bind mount. The trust manifest then guards the *installed
copy*, not the repo working tree. **Matrix change:** [3]'s key downside narrowed from "config isn't
portable" to "install step must be re-run after editing the canonical copy."

**Push to extreme** (20 projects) → [2] means 20 copies of `init-firewall.sh`; the next NXDOMAIN
fix lands in 3 of them and 17 sessions start failing (or worse, silently degrade). [3] means one
file. Also 20 containers × full image = a build-cost cliff, which is why **[7] base image** is
adopted as a sub-mechanism regardless of winner. **Matrix change:** [2]'s risk re-rated
*low → low-today-rising*; its effort re-stated as recurring rather than one-time.

**Failure-driven** (new failure categories [3] introduces) → three, each with a mitigation now
folded into the design:
1. *Blast radius* — one bad central config breaks every project at once. Mitigation: the manifest
   gate already forces a human review before any rebuild; add a `--probe-only` smoke check across
   registered projects after editing the central config.
2. *`--id-label` aliasing* — the CLI infers the container ID label from the workspace path; a
   mistake there could silently attach two repos to one container, re-creating [5]'s H6 failure
   *without anyone choosing it*. Mitigation: pass `--id-label` explicitly, derived from the
   absolute repo path.
3. *Volume leak* — forgetting to parameterize the `claude-workflows-*` volume names gives every
   project one shared `~/.claude` (H6). Mitigation: **extend `probe_boundary` to assert the
   container's `/workspace` identity matches the intended target** (git toplevel + remote), and to
   assert a second registered project's path is absent. This closes the H1 footgun *inside* the
   container, not just at the launcher, and is the single highest-value addition the stress test
   produced. **Matrix change:** H6 for [3] upgraded from "by construction" to "by construction and
   asserted."

### Axis of disagreement

[3] and [2] score within ~1 cell once effort is weighed as a one-time cost. The axis is
**boundary integrity + zero-touch onboarding (3) vs. per-repo self-description + portability (2)** —
and S4 records that decision 015 already expressed a preference for the *portability* side of that
axis. That prior preference is exactly why this is a Path-B consult rather than a Path-A
documented decision: the stress-test mitigation (canonical config committed here, installed copy
read by the launcher) claims to give both, and the human should decide whether that's convincing or
whether it's having-it-both-ways.

### Decision presentation block

Rendered to console — see the session transcript. Recommendation: **[3]**, confidence **~75%**,
runner-up **[2]**, axis = integrity/zero-touch vs. portability/self-description.

### Outcome

**[3] central host-side config + `--override-config`**, chosen by the user in the Path-B consult
(2026-07-13). Recorded as decision 016. The stress-test mitigations — commit-here/install-there,
explicit `--id-label`, and the in-container workspace-identity assertion — carry into the
implementation scope; [7] base image and [14] egress profiles are adopted as sub-mechanisms;
[4] hybrid is the pre-named fallback if a project turns out to need a repo-local `.devcontainer/`.
