# 016 — Multi-project isolated sessions: central host-side devcontainer config

- **Goal**: Decide how decision 015's devcontainer boundary is made available to every CC project on this host, rather than only the `claude-workflows` repo.
- **Project state**: standalone follow-on to decision 015 · not blocked · implementation not yet started
- **Task status**: complete (decision made 2026-07-13; DD working doc: `docs/working/dd-multi-project-devcontainer.md`; implementation pending — see Consequences)

## Context

Decision 015 shipped an isolated-session devcontainer for this repo. The user asked whether
`scripts/devcontainer-session.sh` can simply be run from another project's directory. It cannot,
and the failure is silent: the launcher resolves its workspace from `${BASH_SOURCE[0]}`
(`scripts/devcontainer-session.sh:118`), not `$PWD`, so invoking it from repo B builds and enters
a session on `claude-workflows` without any error. Four further couplings block reuse:

1. `devcontainer up --workspace-folder X` expects `X/.devcontainer/`, which other repos lack.
2. `ENFORCEMENT_FILES` lists `scripts/devcontainer-session.sh` as a *workspace-relative* path, so
   `compute_manifest` hard-fails in any repo that doesn't vendor the launcher.
3. `manifest_path()` keys the trust manifest on `basename "$workspace"` (`:42`), so two repos both
   named `app` silently share one blessed manifest.
4. `devcontainer.json:38-39` hardcodes the volumes `claude-workflows-bashhistory` and
   `claude-workflows-claude-config`; the latter mounts `/home/node/.claude`. Copied verbatim into
   other repos, every project would share one credential/memory store, so a compromised session in
   project A could read project B's secrets. The baked egress allowlist
   (`.devcontainer/Dockerfile:93`) is likewise tuned for this repo (openrouter.ai,
   elan.lean-lang.org) and would not serve a Python or Rust project.

The DD surfaced a tension inside 015 itself. That record banks *"the devcontainer config is
committed per-repo and portable to other machines"* as a benefit — but that property is exactly
what places `.devcontainer/` and the launcher inside the container's read-write bind mount, which
is the entire reason the trust manifest had to be built. **Per-repo portability and boundary
integrity pull against each other, and vendoring the config into N repos multiplies the hole N
times rather than closing it.**

A load-bearing capability check (DD → spike, resolved from the `devcontainers/cli` source):
`devcontainer up` supports `--override-config` — *"devcontainer.json path to override any
devcontainer.json in the workspace folder … required when there is no devcontainer.json
otherwise"* — and `--id-label` to control container identity and reuse. Both are exactly the
primitives a repo-external config needs.

## Options considered

15 candidates generated; full list, compatibility matrix, and health check in the working doc.
Step-3 survivors: **[3]** central host-side config + `--override-config`, **[4]** hybrid
central-plus-blessed-override, **[2]** vendor-per-repo, **[8]** OCI devcontainer Feature.
6 hard constraints, 7 soft. The DD recommended [3] at 75% confidence; the user confirmed [3] in
the Path-B consult.

## Decision and rationale

**Adopt a central host-side devcontainer config plus a project-agnostic launcher.** The boundary
definition (`devcontainer.json`, `Dockerfile`, `init-firewall.sh`) is *installed* to
`~/.config/claude-devcontainer/` and passed to the CLI via `--override-config`; target repos get
**zero** new files. A `cc-isolated <repo>` launcher on the host `PATH` takes the target workspace
as an argument (defaulting to the git toplevel of `$PWD`) instead of inferring it from its own
location.

Rationale: this is the only survivor that covers all 6 hard constraints, and it does so by
*retiring* the config-integrity hole rather than gating it. Because the config lives outside every
bind mount, no session can edit the boundary it runs under — the property 015 wanted but could not
have while the config lived in the repo. Onboarding a project becomes one command with nothing to
copy, and a security fix to `init-firewall.sh` (there have been two in the past month — `f3d9c20`,
`3d0c51a`) is written once rather than fanned out to N vendored copies.

Portability, which 015 correctly valued and which a pure `~/.config` design would forfeit, is
preserved by a **commit-here / install-there split**: the canonical config stays committed in this
repo under `devcontainer-config/` where it is version-controlled and code-reviewed, and an explicit
`install` step copies it to `~/.config/claude-devcontainer/`. The trust manifest then guards the
*installed copy* — the one the launcher actually reads — which is outside every target's mount
namespace. Git carries portability; the copy carries integrity.

Three sub-mechanisms are adopted as part of the implementation rather than as alternatives:
a **shared base image** (`claude-base:NNN`, so N projects don't mean N full builds), **per-language
egress profiles** (so a Python project reaches PyPI without opening PyPI to every other project),
and **per-project volume names** derived from the target path (so `~/.claude` is never shared
across projects).

See alternatives considered → Pruned candidates below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent
areas can grep this section to avoid regenerating already-pruned approaches.

[0 status quo / 12 wait-for-upstream]: fail every hard constraint by construction; 12 is a bet already captured as a 015 revisit trigger, not a design. [1 loud-fail guard]: satisfies H1 and nothing else — **absorbed, not discarded**: the guard is a prerequisite component of the chosen candidate. [2 vendor-per-repo]: runner-up, declined — leaves the H2 config-integrity hole open by design (launcher + firewall script sit inside the repo the agent can write) and makes the maintenance cost recurring and per-repo; the *Push to extreme* move (20 projects → 20 drifting copies of `init-firewall.sh`) was decisive. [4 hybrid central + blessed override]: covers 6/6 but pays for two code paths and two trust regimes, and its override path re-opens exactly the agent-writable surface [3] was chosen to eliminate; **deferred, not dead** — revisit if a real project needs a repo-local config (see Revisit triggers). [5 shared workbench container]: ⚠ on H6 — one container seeing every repo means one prompt-injected session reaches all of them; inverts the property 015 was built to buy [same axis as 12 remote-dev-box, carried from 015-cc-process-isolation-docker-devcontainer]. [6 template generator / 13 git submodule]: both are [2] with a propagation mechanism bolted on; they inherit [2]'s H2 hole while adding machinery — folded into [2]/[4] rather than carried. [7 base image + thin overlay / 14 per-language egress profiles]: not standalone alternatives — **adopted as sub-mechanisms** of the winner (S2 and H5 respectively). [8 OCI devcontainer Feature]: the opt-in line still lives in an agent-editable file so H2 is unchanged; adds a registry + auth dependency for a single-user host, and a launcher is still needed for the manifest and probe. [9 micro-VM per project]: ideal-if-free space-widener; scores 6/6 but the provisioning machinery doesn't exist on this host [2 WSL2-distro family carried from 015: declined in that DD's Path-B consult]. [10 symlink farm]: mechanically broken — a symlink across a bind mount points at a path the container's mount namespace doesn't have — and ⚠ on H6. [11 raw CLI]: ⚠ on H2 and H4 — buys portability by deleting the trust manifest and the boundary probe; 015's failure-driven mitigation is explicit that a silently-degrading boundary is worse than none. [6 dedicated unix user, carried from 015]: H1 only partial; not regenerated.

Prior pruning grep: one match (decision 015). Its pruned set is boundary-*technology* choices,
whereas this decision is a boundary-*distribution* choice, so most entries are out of scope rather
than carried; the four that genuinely re-surface are annotated above.

## Stress-test mitigations

- How to read: *Invert the thesis* mitigation — arguing sincerely for vendor-per-repo recovered
  decision 015's portability benefit, which the central-config candidate had under-priced. This
  produced the **commit-here / install-there split** (canonical config committed in this repo, a
  blessed copy installed host-side for the launcher to read), narrowing [3]'s key downside from
  "config isn't portable" to "the install step must be re-run after editing the canonical copy."
- How to read: *Failure-driven* mitigation — enumerating new failure categories the central design
  introduces surfaced **`--id-label` aliasing**: the CLI infers a container's ID label from the
  workspace path, so a mistake there could silently attach two repos to one container, recreating
  the pruned shared-workbench candidate's cross-project leak *without anyone choosing it*. Two
  mitigations adopted: pass `--id-label` explicitly, derived from the absolute repo path; and
  **extend `probe_boundary` to assert the container's `/workspace` identity matches the intended
  target** (git toplevel + remote) and that a second registered project's path is absent. This
  closes the silent-wrong-workspace footgun *inside* the container, not just at the launcher, and
  was the single highest-value addition the stress test produced.
- How to read: *Push to extreme* mitigation — extending to 20 projects re-rated vendor-per-repo's
  risk from "low" to "low today, rising," restated its effort as recurring rather than one-time,
  and made the **shared base image** a required sub-mechanism of any winner (20 containers × a full
  image build is a cost cliff).
- How to read: *Boring alternative* mitigation — confirmed vendor-per-repo is ~80% of the benefit
  for ~40% of the effort *today*; it kept [2] as the runner-up but did not dislodge [3], because
  [3] is only ~2× the one-time effort and retires the H2 hole instead of gating it.

## Consequences

Easier: a new project is onboarded with one command and no files to copy or maintain; the boundary
config becomes genuinely unreachable from inside a session (no bind mount contains it), so the
trust manifest degrades from a load-bearing control to a defence-in-depth check on the installed
copy; firewall and image fixes are written once; per-language egress profiles make non-Node
projects viable without weakening this repo's allowlist.

Harder: an install step now sits between editing the canonical config and it taking effect, and a
stale install is a new (quiet) failure mode — the manifest gate is what catches it. One central
config also means one blast radius: a bad edit breaks every project at once, so a `--probe-only`
smoke check across registered projects becomes part of the edit loop. VS Code's Dev Containers
extension discovers `.devcontainer/devcontainer.json` in the workspace and does **not** consume
`--override-config`, so the IDE-attach path is not covered by this decision (soft constraint S6,
knowingly unmet — the CLI launcher is the supported entry point; candidate [4] is the escape hatch
if this bites).

Implementation is **not yet done**. It is scoped at 4–6 h: retarget the launcher to take a workspace
argument, key the manifest on a hash of the absolute path instead of `basename`, move the
enforcement-file list to absolute installed paths, add `--override-config` + explicit `--id-label`,
parameterize the volume names and the egress profile, extend `probe_boundary` with the
workspace-identity assertion, and update `test/devcontainer-session-functions.bats` and
`guides/devcontainer-setup.md`.

Falsifiable hypothesis: *If we adopt the central host-side config, we expect every CC project on
this host to be launchable with one command and zero repo-side files within 2 weeks, with the
credential-denial and cross-project probes passing per project; counter-evidence would be
`--override-config` failing to resolve the Dockerfile build context (forcing a prebuilt-image
detour), or ≥1 project needing a repo-local `.devcontainer/` anyway within the first month.*

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt re-evaluating this
decision. Future readers can grep this section when their context changes to see whether earlier
decisions still apply.

If `--override-config` cannot resolve the `Dockerfile` build context from outside the workspace → fall back to referencing a prebuilt `claude-base` image by tag (the base-image sub-mechanism makes this a small change, not a redesign). If ≥1 project needs a repo-local `.devcontainer/` (a pre-existing devcontainer, or an IDE-attach workflow that the CLI launcher can't serve) → implement candidate **[4] hybrid**, the pre-named fallback, rather than re-opening the DD. If VS Code Dev Containers attach becomes a required workflow rather than a nice-to-have → same, [4]. If the number of isolated projects exceeds ~10 and per-project image builds exceed ~2 min each → the shared base image is no longer optional; make it a hard prerequisite. If a stale installed config is observed causing a boundary regression more than once → move the install step into the launcher itself (auto-install on hash mismatch, still gated by the manifest). If decision 015's Reverse trigger fires (Docker Desktop unavailable → podman rootless) → the central config must be re-verified against podman's `--override-config` support before assuming this decision carries over.
