Commit: 9e0ff1a5

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-doc-drift (branch fix/doc-drift-cycle1)
**Scope:** `git diff main...HEAD` excluding docs/reviews/, plus the commit messages of 330138d8 and 9e0ff1a5; merged from `code-fact-check-report-2026-10-15-doc-drift-cycle1-final-r{1,2,3}.md`, most-severe-wins on verdicts, union on annotations (review iteration 2)
**Checked:** 2026-10-15
**Total claims checked:** 10
**Summary:** 5 verified, 5 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable
**Commit:** 9e0ff1a5
**Replication:** k=3

---

## Claim 1: Image lifecycle: CLAUDE_CODE_VERSION=latest resolved when the install layer is built, and "Docker reuses that cached layer on later rebuilds: nothing in the launcher passes `--build-no-cache`"

**Location:** `guides/devcontainer-setup.md:387-391`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Dockerfile layer order, the constant build arg and the absence of a no-cache flag; does not establish Docker cache behaviour by execution.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2+r3: reuse holds only while nothing above `Dockerfile:403` changes (TZ arg `Dockerfile:16-17`, apt list, toolchain version args, base image, pruned cache); r2: 1ef3090b re-ran the install that way on 2026-09-28. r1+r2+r3: no `--build-no-cache` anywhere under devcontainer-config/.

**Evidence:** `devcontainer-config/Dockerfile:16-19`, `devcontainer-config/Dockerfile:403`, `devcontainer-config/cc-isolated.sh:883`

---

## Claim 2: "A re-bless changes the baked config hash, so the next launch of each project recreates its container automatically, from those cached layers"

**Location:** `guides/devcontainer-setup.md:391-393`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the automatic recreate on hash mismatch; "from those cached layers" holds only for a tail-only re-bless.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: needs "unless the re-blessed change sits above the install layer"; the same unqualified line is in 9e0ff1a5's body (immutable; fix the guide).

**Evidence:** `devcontainer-config/cc-isolated.sh:892-896`

---

## Claim 3: Newer CC arrives by in-container auto-update or `claude update`; the auto-update row exists; a recreated container starts again from the image's version

**Location:** `guides/devcontainer-setup.md:393-397`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that nothing disables the updater, the npm prefix and its location in the container filesystem, the volume list, and the row at cc-isolated-usage.md:940; does not establish Claude Code's updater behaviour by execution.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: out of scope whether the updater could move to a native install inside the `~/.claude` volume.

**Evidence:** `devcontainer-config/devcontainer.json:78-79`, `guides/cc-isolated-usage.md:940`

---

## Claim 4: `cc-isolated --probe-only <repo>` always recreates the container from the blessed config and re-probes, then `cc-isolated <repo>`; matches init-firewall.sh's hint

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the probe action, the launch path and wording parity with init-firewall.sh:343-350.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `devcontainer-config/cc-isolated.sh:880-886`, `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 5: The bare form "drops the variables the launcher exports, and each one dropped has its own effect (base-only egress, an empty config hash, the shared cc--claude-config volume), and the launcher's probe never runs"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each named effect against devcontainer.json's localEnv reads and rebuild_hint's comment, and that probe_boundary runs only from main(); does not establish whether a fully bare run fails at the build first.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1+r2+r3: omits empty CC_CONFIG_DIR (build pointed at /Dockerfile, `cc-isolated.sh:546-547`); r1+r2: name it or say "among them". r2: whether a fully bare run fails at the build before baking base-only egress needs a host run (the 2026-09-15 measurement predates nothing, CC_CONFIG_DIR existed then). Same list at `guides/devcontainer-setup.md:399-402`.

**Evidence:** `devcontainer-config/cc-isolated.sh:536-555`, `devcontainer-config/devcontainer.json:25-26`

---

## Claim 6: "see the row below" (base-only egress)

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row reference.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: the meant row ("A newly registered profile has no effect") is at :941, six rows down; :936 is the OAuth row. 330138d8 named it ("the base-only egress row below"); 9e0ff1a5 dropped the name.

**Evidence:** `guides/cc-isolated-usage.md:936`, `guides/cc-isolated-usage.md:941`

---

## Claim 7: devcontainer-setup cites "the comment above `rebuild_hint`" for the rationale

**Location:** `guides/devcontainer-setup.md:402-403`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment's content; the comment does not itself say the probe never runs (true from main()).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: the comment backs the effects list, not "the probe never runs".

**Evidence:** `devcontainer-config/cc-isolated.sh:534-555`

---

## Claim 8: guides/README.md index line (exit scan; cc-push via a host-only clone)

**Location:** `guides/README.md:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of both topics in the guide.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `guides/cc-isolated-usage.md:28`

---

## Claim 9: AGENTS.md/GEMINI.md dev-cycle row (row 12's step list; collects, lands and dispatches build loops; questions to questions.md; in sync)

**Location:** `AGENTS.md:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row against global row 12, the skill's description and steps 7, 9, 10, and byte parity with GEMINI.md.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `global-instructions/CLAUDE.md:32`, `skills/dev-cycle/SKILL.md:263-264`

---

## Claim 10: Commit messages of 330138d8 and 9e0ff1a5 (fc3bff82 hint, line 58, Last verified not bumped, A4 note, override rows)

**Location:** `guides/cc-isolated-usage.md:57-59`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each factual statement; the row-pointer and unqualified cached-layer wording are carried by Claims 2 and 6 and fixed in the guide, since the commits are not rewritten.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate (cached-layer line, note only) · r2=Mostly accurate (row pointer; cached-layer line) · r3=Mostly accurate (row pointer; cached-layer line)
**Replicate annotations:** r1+r2+r3: the only imprecisions are those of Claims 2 and 6; each replicate said fix the guide, not the commit.

**Evidence:** `devcontainer-config/cc-isolated.sh:892-896`

---

## Claims Requiring Attention

### Incorrect

(none)

### Mostly Accurate

- Claim 1 (`guides/devcontainer-setup.md:387-391`): cached-layer reuse needs "until something above it changes".
- Claim 2 (`guides/devcontainer-setup.md:391-393`): re-bless "from those cached layers" needs the same qualifier.
- Claim 5 (`guides/cc-isolated-usage.md:935`, `guides/devcontainer-setup.md:399-402`): effects list omits CC_CONFIG_DIR.
- Claim 6 (`guides/cc-isolated-usage.md:935`): "the row below" should name the row.
- Claim 10 (commit bodies): carry the imprecisions of Claims 2 and 6; commits are not rewritten, the guide fix carries the correction.

## Escalations

- none blocking (r1, r2, r3). Residue (r2): a fully bare run's outcome needs a host devcontainer run, addressee orchestrator; not needed for the guides' advice, which is "don't".

## Verdict stability

- Clusters: 10
- All replicates agreed: 7 (Claims 2, 3, 4, 6, 7, 8, 9)
- Disagreed: 3 (Claim 1: r1=Verified, r2=r3=Mostly accurate; Claim 5: r1=r2=Mostly accurate, r3=Verified; Claim 10: r1=Mostly accurate on the cached-layer line only, r2=r3=Mostly accurate on both lines)
- Agreement rate: 7/10 = 70%
