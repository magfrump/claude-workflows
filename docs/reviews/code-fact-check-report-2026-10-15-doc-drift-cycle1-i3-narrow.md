Commit: ec1ea297

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-doc-drift (branch fix/doc-drift-cycle1)
**Scope:** Narrow: `git diff 258f9ec4..ec1ea297 -- guides/` (the reworded qualifier in `guides/devcontainer-setup.md`'s Image lifecycle bullet, lines 387-391; the other hunk, lines 402-405, is a pure re-wrap with no wording change) and the commit message of ec1ea297. Verified against `devcontainer-config/Dockerfile` and `devcontainer-config/devcontainer.json` build.args at ec1ea297.
**Checked:** 2026-10-15
**Total claims checked:** 12
**Summary:** 8 verified, 2 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read. No logged pattern concerns Dockerfile layer order, toolchains or install layers, and no claim below matches one.

Reference point for every placement claim: the CC install layer is

```dockerfile
# devcontainer-config/Dockerfile:402-403
# Install Claude
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}
```

---

## Claim 1: "Docker reuses that cached layer on later rebuilds until an input to a layer above it changes (...) or the build cache is pruned"

**Location:** `guides/devcontainer-setup.md:387-391`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether the install instruction's own text stays constant across rebuilds; does not establish Docker's runtime cache behavior (reuse, invalidation by an upstream ARG/instruction change, loss on prune), which needs an actual build.

The install instruction's own inputs do not vary: its only variable is `CLAUDE_CODE_VERSION`, declared `ARG CLAUDE_CODE_VERSION=latest` (`devcontainer-config/Dockerfile:19`) and passed as the constant `"CLAUDE_CODE_VERSION": "latest"` (`devcontainer-config/devcontainer.json:29`). So under Docker's documented cache rule, only an upstream change or a missing cache would force the layer to rebuild. That rule is an executable guarantee about `docker build` (paraphrased — no quote available because the behavior belongs to Docker's builder, not this repo). The brief rules out running docker or devcontainer, so per the mandatory-execution rule the verdict stays Unverifiable. Blocker: docker execution is excluded by the brief. To verify: build twice with the same args, confirm the `npm install` step reports `CACHED`, then bump an upstream ARG (e.g. `UV_VERSION`) and confirm it re-runs. This rule was already in the text before the fix; the fix changed only the qualifier's examples.

**Evidence:** `devcontainer-config/Dockerfile:19`, `devcontainer-config/Dockerfile:403`, `devcontainer-config/devcontainer.json:29`

---

## Claim 2: base image, apt list and `TZ` are inputs to layers above the install layer

**Location:** `guides/devcontainer-setup.md:389`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the line positions of FROM, every `apt-get install` RUN and the TZ ARG/ENV relative to :403; does not establish whether `node:22` is re-pulled on a rebuild (a moving tag, so "the base image changes" depends on pull behavior).

```dockerfile
# devcontainer-config/Dockerfile:14-17
FROM node:22

ARG TZ
ENV TZ="$TZ"
```

The `apt-get install` lines are at `devcontainer-config/Dockerfile:22`, `:198` and `:223` (`RUN apt-get update && apt-get install -y --no-install-recommends \`), and a grep of the file finds no others. All three are above :403. `TZ` is a build arg: `"TZ": "${localEnv:TZ:America/Los_Angeles}"` (`devcontainer-config/devcontainer.json:28`).

**Evidence:** `devcontainer-config/Dockerfile:14-17`, `devcontainer-config/Dockerfile:22`, `devcontainer-config/Dockerfile:198`, `devcontainer-config/Dockerfile:223`, `devcontainer-config/devcontainer.json:28`

---

## Claim 3: uv, Rust, Android and .NET are toolchains installed above the install layer

**Location:** `guides/devcontainer-setup.md:389-390`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the version ARGs and install RUNs of the four named toolchains (all above :403, all passed from devcontainer.json); does not establish completeness of the list (see Claim 5).

```dockerfile
# devcontainer-config/Dockerfile:115-116
ARG UV_VERSION=0.11.28
RUN case "$(dpkg --print-architecture)" in \
```

```dockerfile
# devcontainer-config/Dockerfile:235-238
ARG ANDROID_CMDLINE_TOOLS_VERSION=11076708
ARG ANDROID_CMDLINE_TOOLS_SHA256=2d2d50857e4eb553af5a6dc3ad507a17adf43d115264b1afc116f95c92e5e258
ARG ANDROID_PLATFORM=android-35
ARG ANDROID_BUILD_TOOLS=35.0.0
```

```dockerfile
# devcontainer-config/Dockerfile:300-301
ARG RUSTUP_VERSION=1.27.1
ARG RUST_VERSION=1.83.0
```

```dockerfile
# devcontainer-config/Dockerfile:354
ARG DOTNET_SDK_VERSION=10.0.400
```

The matching build args are in `devcontainer-config/devcontainer.json:32-39` (`"UV_VERSION": "0.11.28"`, `"RUSTUP_VERSION": "1.27.1"`, `"RUST_VERSION": "1.83.0"`, `"ANDROID_CMDLINE_TOOLS_VERSION": "11076708"`, ..., `"DOTNET_SDK_VERSION": "10.0.400"`).

**Evidence:** `devcontainer-config/Dockerfile:115-129`, `devcontainer-config/Dockerfile:235-255`, `devcontainer-config/Dockerfile:300-324`, `devcontainer-config/Dockerfile:354-363`, `devcontainer-config/devcontainer.json:32-41`

---

## Claim 4: "elan and Lean sit below it"

**Location:** `guides/devcontainer-setup.md:390-391`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the elan/Lean ARGs and their install RUN (all below :403); does not establish anything about the per-project tail (`CC_EGRESS_PROFILE`, `CC_CONFIG_HASH`, :478-484), which also sits below.

```dockerfile
# devcontainer-config/Dockerfile:451-457
ARG ELAN_VERSION=v4.2.4
ARG ELAN_SHA256_AMD64=42b94d4244e8353142c456ec0e4ca6528fd898a6c604d4059f494e706e431f63
ARG ELAN_SHA256_ARM64=05febd124d84ebf994b2e7479922a5650b1e950c17ae3bd1ddd776b65bb72bf9
ARG LEAN_TOOLCHAINS=""
ENV ELAN_HOME=/home/node/.elan \
    PATH=/home/node/.elan/bin:$PATH
RUN case "$(dpkg --print-architecture)" in \
```

(excerpt ends :457; enclosing elan RUN continues past :457 — read the ARG/ENV/RUN boundaries only, which is all the placement claim needs.) Passed as `"ELAN_VERSION": "v4.2.4"` and `"LEAN_TOOLCHAINS": ""` in `devcontainer-config/devcontainer.json:42-49`.

**Evidence:** `devcontainer-config/Dockerfile:451-457`, `devcontainer-config/devcontainer.json:42-49`

---

## Claim 5: the parenthetical "(the base image, the apt list, `TZ`, or the version of a toolchain installed above it, such as uv, Rust, Android or .NET ...)" as the set of upstream inputs

**Location:** `guides/devcontainer-setup.md:388-391`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether the parenthetical's classes cover the versioned inputs above :403; does not establish that any reader is misled (the lead clause "an input to a layer above it" already states the general rule, and only the toolchain item carries "such as").

The rule is right and every listed item is correct (Claims 2-4). But read as an enumeration, the parenthetical leaves out three version inputs above :403 that are tools, not toolchains, plus edits to the instructions themselves:

```dockerfile
# devcontainer-config/Dockerfile:89
ARG GIT_DELTA_VERSION=0.18.2
```

```dockerfile
# devcontainer-config/Dockerfile:168
ARG SHFMT_VERSION=3.13.1
```

```dockerfile
# devcontainer-config/Dockerfile:393
ARG ZSH_IN_DOCKER_VERSION=1.2.0
```

`GIT_DELTA_VERSION` and `ZSH_IN_DOCKER_VERSION` are also passed from `devcontainer-config/devcontainer.json:30-31`. A more precise version would mark the whole parenthetical as examples ("for example the base image, ..."). Low stakes: getting this wrong only means a CC reinstall the reader did not expect. The opposite error, expecting a refresh that never happens, was the elan/Lean case, and the fix removed it.

**Evidence:** `devcontainer-config/Dockerfile:89-93`, `devcontainer-config/Dockerfile:168-170`, `devcontainer-config/Dockerfile:393-394`, `devcontainer-config/devcontainer.json:30-31`

---

## Claim 6: "D1 (fact-check i3 Claim 1, Mostly accurate; security i3 Informational)"

**Location:** commit ec1ea297 message, body bullet 1
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the source attribution and verdicts; does not re-adjudicate those reports' findings.

`docs/reviews/code-fact-check-report-2026-10-15-doc-drift-cycle1-i3.md:15-19`: "## Claim 1: Cached install-layer reuse ... **Verdict:** Mostly accurate". `docs/reviews/security-review-2026-10-15-doc-drift-cycle1-i3.md:43`: "**Severity:** Informational", and its summary row at `:117` reads "Cache-invalidation examples include triggers below the CC install layer (elan/Lean) and a non-Dockerfile cause | Informational".

**Evidence:** `docs/reviews/code-fact-check-report-2026-10-15-doc-drift-cycle1-i3.md:15-21`, `docs/reviews/security-review-2026-10-15-doc-drift-cycle1-i3.md:43-63`, `docs/reviews/security-review-2026-10-15-doc-drift-cycle1-i3.md:117`

---

## Claim 7: the qualifier "no longer lists 'a pruned build cache' as a Dockerfile change or implies every toolchain version sits above the CC install layer. It now reads: ..."

**Location:** commit ec1ea297 message, body bullet 1
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the before/after wording in the diff and the commit's quotation of the new text; does not establish the new text's accuracy (Claims 1-5).

The diff replaces "until something / above it in the Dockerfile changes (the base image, the apt list, a toolchain / version, `TZ`, or a pruned build cache)" with "until an input to a / layer above it changes (the base image, the apt list, `TZ`, or the version of a / toolchain installed above it, such as uv, Rust, Android or .NET; elan and Lean sit / below it) or the build cache is pruned" (`guides/devcontainer-setup.md:387-391` at ec1ea297). The commit's quotation matches word for word, apart from dropping the backticks around TZ.

**Evidence:** `guides/devcontainer-setup.md:387-391`

---

## Claim 8: "This also corrects the 'examples, not exhaustive' list in 258f9ec4's Notes."

**Location:** commit ec1ea297 message, body bullet 1
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that 258f9ec4's Notes carried the same two errors the fix removes; does not establish that the history itself is altered (it is not; the correction is recorded forward).

258f9ec4's body Notes: "The qualifier list in B3 names the inputs above Dockerfile:403 that the iteration-2 replicates found (TZ arg, apt list, toolchain version args, base image, pruned cache); it is a list of examples, not exhaustive." That puts "pruned cache" and all toolchain version args (elan/Lean included, :451-454) "above Dockerfile:403". Both are corrected by the new guide text and by this commit's body.

**Evidence:** `git log -1 --format=%B 258f9ec4`, `devcontainer-config/Dockerfile:451-454`

---

## Claim 9: the iteration-3 artifacts list ("merged and replicate fact-check reports, security and api-consistency reports, the Stage 2.5 submitted-claims report (2 security endorsements, Verified, executed), the final rubric, and an override-log row (C5 deferred)")

**Location:** commit ec1ea297 message, body bullet 2
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers presence of each artifact in the commit and the submitted-claims counts; does not re-verify those reports' contents.

`git diff --name-only 258f9ec4..ec1ea297` lists the merged `code-fact-check-report-...-i3.md` plus `-i3-r1/-r2/-r3`, `security-review-...-i3.md`, `api-consistency-review-...-i3.md`, `code-fact-check-submitted-claims-...-cycle1.md`, the rubric and `override-log.md`. The submitted-claims report header reads "**Summary:** 2 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable" (`docs/reviews/code-fact-check-submitted-claims-2026-10-15-doc-drift-cycle1.md:9`). Both entries carry "**Submitted by:** security-reviewer" and "**Verification mode:** executed" (`:21,:26` and `:65,:70`). The one added override-log row is the C5 deferral ("still say \"rebuild\" where the new prose says \"recreates\" ... Defer", `docs/reviews/override-log.md:834`).

**Evidence:** `docs/reviews/code-fact-check-submitted-claims-2026-10-15-doc-drift-cycle1.md:9-70`, `docs/reviews/override-log.md:834`, `docs/reviews/code-review-rubric-2026-10-15-fix-doc-drift-cycle1.md:7`

---

## Claim 10: "D1 was fixed after the iteration-3 confirming pass, so it was not re-reviewed by a k=3 panel"

**Location:** commit ec1ea297 message, Notes
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that every iteration-3 report is stamped at the pre-fix commit; does not establish what any later review covered (Claim 11).

Each iteration-3 report's first line is `Commit: 258f9ec4` (merged fact-check, security, api-consistency). The rubric says "Iteration 3 of 3 (stamp 258f9ec4, the confirming pass) ... fact-check k=3" (`docs/reviews/code-review-rubric-2026-10-15-fix-doc-drift-cycle1.md:7`). The D1 rewording first appears in ec1ea297.

**Evidence:** `docs/reviews/code-fact-check-report-2026-10-15-doc-drift-cycle1-i3.md:1`, `docs/reviews/security-review-2026-10-15-doc-drift-cycle1-i3.md:1`, `docs/reviews/api-consistency-review-2026-10-15-doc-drift-cycle1-i3.md:1`, `docs/reviews/code-review-rubric-2026-10-15-fix-doc-drift-cycle1.md:7`

---

## Claim 11: "the fix-drift lite review and a narrow fact-check of the reworded sentence cover it (iteration-3 narrow report)"

**Location:** commit ec1ea297 message, Notes (echoed in `docs/reviews/code-review-rubric-2026-10-15-fix-doc-drift-cycle1.md:5` and its D1 row, `:37`)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether a record of either review exists in the tree at ec1ea297; does not establish whether a lite review was actually run (it may have been, with its output kept outside the tree).

At ec1ea297 neither review is recorded. No `lite-review-*` file in `docs/reviews/` covers 258f9ec4..ec1ea297 or fix/doc-drift-cycle1. The `lite-review-fix-drift-build-loop-u2a3-*` files belong to another unit; for example, `-i3.txt` reports a finding in `scripts/lib/dev-cycle-read.sh:537-548`. The rubric logs earlier lite checks only as inline text ("Fix-drift lite check on 9e0ff1a5..258f9ec4: FINDINGS: NONE", `:7`), with no line for ec1ea297. The "iteration-3 narrow report" is this report, written after the commit. So the claim was prospective when committed. Its narrow-fact-check half is satisfied once this file exists. To verify the lite-review half: the lite review's output for 258f9ec4..ec1ea297, or an inline rubric line like the earlier ones.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-15-fix-doc-drift-cycle1.md:5-9`, `docs/reviews/code-review-rubric-2026-10-15-fix-doc-drift-cycle1.md:37`, `docs/reviews/lite-review-fix-drift-build-loop-u2a3-i3.txt:1-3`

---

## Claim 12: "Deferred, all script/launcher changes outside the brief: A4 rebuild_hint's 'rebuilds' line, C3 no cached-layer refresh path, C4 init-firewall.sh 'rebuilds', C5 the two 'rebuild' lines outside the diff."

**Location:** commit ec1ea297 message, Notes
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers that all four items are Deferred in the rubric and that A4, C3 and C4 are script/launcher changes; does not establish whether the brief's scope excludes C5's lines (the override log says it does).

All four are Deferred: A4 at `docs/reviews/code-review-rubric-2026-10-15-fix-doc-drift-cycle1.md:31` ("Out of the brief's scope (scripts)"), C3 at `:47` ("launcher change, out of scope"), C4 at `:48` (`init-firewall.sh:346,349`) and C5 at `:49`. But C5 is not a script or launcher change. Its row reads "`guides/cc-isolated-usage.md:25` and `:941` still say \"rebuild\" where the new prose says \"recreates\" (outside the diff)" (`:49`), which is guide prose. Its override-log row gives the reason as "outside the brief's lines" (`docs/reviews/override-log.md:834`). The precise version: "Deferred, all outside the brief: A4/C3/C4 script and launcher changes, C5 two guide lines outside the diff."

**Evidence:** `docs/reviews/code-review-rubric-2026-10-15-fix-doc-drift-cycle1.md:31`, `docs/reviews/code-review-rubric-2026-10-15-fix-doc-drift-cycle1.md:47-49`, `docs/reviews/override-log.md:834`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 5** (`guides/devcontainer-setup.md:388-391`): read as a list, the parenthetical leaves out the git-delta (:89), shfmt (:168) and zsh-in-docker (:393) version inputs above :403. Optional: mark the whole parenthetical as examples. Low stakes, because the lead clause states the general rule.
- **Claim 12** (commit ec1ea297 Notes): C5 is two guide lines (`guides/cc-isolated-usage.md:25,:941`), not a script/launcher change. Commit history can't be edited after a local merge, so record any correction forward (e.g. an override-log note), as was done for B4.

### Unverifiable
- **Claim 1** (`guides/devcontainer-setup.md:387-391`): Docker cache reuse/invalidation/prune behavior is an executable guarantee, and running docker is excluded by the brief. Verifying it needs two builds with an upstream ARG bump. The rule predates the fix.
- **Claim 11** (commit ec1ea297 Notes; rubric `:5`, `:37`): no record of a fix-drift lite review of 258f9ec4..ec1ea297 exists in the tree. The narrow-fact-check half is met by this report. Verifying the lite-review half needs its output, or an inline rubric line.

No Incorrect verdicts, so nothing qualifies for `docs/reviews/hallucination-patterns.md`.

## Goal-Alignment Note
- Success criterion (restated verbatim): A narrow code-fact-check report on the D1 fix saved to the given path.
- Answered: The D1 rewording is accurate on every placement it states. The base image, apt lists, TZ, uv, Rust, Android and .NET are above the CC install layer (`Dockerfile:403`), and elan/Lean are below it (`:451-457`). "A pruned build cache" now sits in its own clause, outside the list of layer inputs. The commit message's references hold, with two exceptions: C5 is mislabelled as a script/launcher change (Mostly accurate), and the lite review it cites has no record in the tree (Unverifiable). 12 claims: 8 Verified, 2 Mostly accurate, 2 Unverifiable. Saved with `Commit: ec1ea297` first.
- Out of scope: the rest of the branch diff and other review artifacts beyond the commit message's references to them; running docker/devcontainer to confirm cache behavior; the deferred A4/C3/C4/C5 items themselves.
- Escalate: None blocking. If the orchestrator wants Claim 11 cleared, it should record the lite-review result for 258f9ec4..ec1ea297 in the rubric. Claims 5 and 12 are optional tightenings.
