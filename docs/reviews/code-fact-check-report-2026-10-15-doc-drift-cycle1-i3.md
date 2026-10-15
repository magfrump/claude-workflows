Commit: 258f9ec4

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-doc-drift (branch fix/doc-drift-cycle1)
**Scope:** `git diff main...HEAD` excluding docs/reviews/, plus the commit messages of 330138d8, 9e0ff1a5 and 258f9ec4; merged from `code-fact-check-report-2026-10-15-doc-drift-cycle1-i3-r{1,2,3}.md`, most-severe-wins on verdicts, union on annotations (review iteration 3, the confirming pass)
**Checked:** 2026-10-15
**Total claims checked:** 9
**Summary:** 5 verified, 2 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable
**Commit:** 258f9ec4
**Replication:** k=3

---

## Claim 1: Cached install-layer reuse "until something above it in the Dockerfile changes (the base image, the apt list, a toolchain version, `TZ`, or a pruned build cache)"

**Location:** `guides/devcontainer-setup.md:387-390`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the position of each named input relative to `Dockerfile:403`; does not establish Docker cache behaviour by execution.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: the elan and Lean version args sit below the install layer (`Dockerfile:451`, `:454`), so "a toolchain version" is not true for them. r1+r2: a pruned build cache is not a Dockerfile change. r1: `TZ` and the toolchain versions are effectively set by devcontainer.json `build.args`, which override the Dockerfile `ARG` defaults. r3: every named input is above `:403` (base image :14, TZ :16, apt :22/:198/:223, toolchain args :89-:354); first COPY at :486.

**Evidence:** `devcontainer-config/Dockerfile:14-17`, `devcontainer-config/Dockerfile:403`, `devcontainer-config/Dockerfile:451-454`

---

## Claim 2: No `--build-no-cache`; profile and hash in the last section; a re-bless reinstalls CC only when its change sits above the install layer

**Location:** `guides/devcontainer-setup.md:390-395`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the launcher and install.sh flags, the ARG positions (:478, :484) and the recreate at cc-isolated.sh:893-896.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: the per-project tail is several layers, not one; every heavy layer is still shared.

**Evidence:** `devcontainer-config/Dockerfile:478-484`, `devcontainer-config/cc-isolated.sh:893-896`

---

## Claim 3: Newer CC arrives through in-container auto-update or `claude update`

**Location:** `guides/devcontainer-setup.md:395-397`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the static preconditions (npm prefix owned by node, registry.npmjs.org allowlisted, updater not disabled); does not establish a live update.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Unverifiable
**Replicate annotations:** r3: a live update needs a running container, which the brief forbids. No blocking-grade failure mode attached.

**Evidence:** `devcontainer-config/Dockerfile:382`, `devcontainer-config/egress/base.txt:82`

---

## Claim 4: A recreated container starts again from the image's version; the auto-update row exists

**Location:** `guides/devcontainer-setup.md:396-398`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the npm prefix location and the volume list.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `devcontainer-config/devcontainer.json:78-79`, `guides/cc-isolated-usage.md:940`

---

## Claim 5: Bare-form effects (base-only egress, empty config hash, `~/.claude` volume shared across projects, build pointed at `/Dockerfile`), probe never runs; the named row exists

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each effect against devcontainer.json's localEnv reads and the comment above rebuild_hint, probe_boundary's call sites, and the row at :941; does not establish which effects co-occur in a fully bare run.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: with CC_CONFIG_DIR empty the build probably fails at `/Dockerfile` before anything is baked (needs a host run). Same list at `guides/devcontainer-setup.md:401-405`.

**Evidence:** `devcontainer-config/cc-isolated.sh:534-556`, `devcontainer-config/devcontainer.json:25-26`

---

## Claim 6: `--probe-only` always recreates and re-probes, then `cc-isolated <repo>`; matches init-firewall.sh

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the code path; whether the sequence recovers a failed-closed container end to end needs a host run (r1 Claim 4b, Unverifiable).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (4a) / Unverifiable (4b) · r2=Verified · r3=Verified
**Replicate annotations:** r1: the guides say "recreates", the script hint says "rebuilds" (deferred C4).

**Evidence:** `devcontainer-config/cc-isolated.sh:880-886`, `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 7: guides/README.md index line; AGENTS.md/GEMINI.md dev-cycle row and sync

**Location:** `AGENTS.md:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the README topics, the row against global row 12 and the skill, and parity (bats test/agents-gemini-sync.bats, exit 0, run by r1 and r3).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: the skill's leading "digest" step is missing from both the row and row 12.

**Evidence:** `global-instructions/CLAUDE.md:32`, `guides/cc-isolated-usage.md:28`

---

## Claim 8: Commit bodies of 330138d8 and 9e0ff1a5 (row pointer; unqualified cached-layer line)

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two imprecise statements; both are corrected in the guide and recorded by 258f9ec4 B4 and override-log rows.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1+r3: no action, already corrected.

**Evidence:** `guides/cc-isolated-usage.md:941`

---

## Claim 9: Commit 258f9ec4's Notes: whether a fully bare `devcontainer up` fails at the build needs a host run

**Location:** `guides/devcontainer-setup.md:401-405`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The commit states the open question itself; settling it needs a host run.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Unverifiable · single-replicate detection
**Replicate annotations:** r1+r2 (on Claim 5): r1 also calls B3's "examples, not exhaustive" note imprecise in the same way as Claim 1.

**Evidence:** `devcontainer-config/devcontainer.json:25-26`

---

## Claims Requiring Attention

### Incorrect

(none)

### Mostly Accurate

- Claim 1 (`guides/devcontainer-setup.md:387-390`): the qualifier list mixes a cache prune with Dockerfile inputs, and "a toolchain version" includes elan/Lean, which sit below the install layer.
- Claim 8 (commit bodies): already corrected; no action.

### Unverifiable

- Claim 3 (live auto-update) and Claim 9 (fully bare run): need a host run; static preconditions hold; no blocking-grade failure mode.

## Escalations

- none (r1, r2, r3).

## Verdict stability

- Clusters: 9
- All replicates agreed: 5 (Claims 2, 4, 5, 7, and 6 on its code path)
- Disagreed: 4 (Claim 1: r1=r2=Mostly accurate, r3=Verified; Claim 3: r1=r2=Verified, r3=Unverifiable; Claim 8: r1=r3=Mostly accurate, r2=Verified; Claim 9: single replicate)
- Agreement rate: 5/9 = 56%
