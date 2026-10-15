Commit: 258f9ec4

# Security Review — fix/doc-drift-cycle1 (iteration 3, final confirming pass)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-doc-drift, review artifacts under docs/reviews/ excluded: AGENTS.md, GEMINI.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md (6 files, 25 insertions, 10 deletions). Read for context: devcontainer-config/cc-isolated.sh (`set -euo pipefail` :66, rebuild_hint and its comment 534-567, env export 812-821, probe action / main rebuild / re-assert / exec 879-927), devcontainer-config/init-firewall.sh 335-352, devcontainer-config/devcontainer.json (build 24-29, mounts 73-80), devcontainer-config/Dockerfile (ARG and install-layer order: 14-19, 403, 451-454, 478-527), guides H6 text (devcontainer-setup.md:60-64, :201-202).
**Date:** 2026-10-15
**Based on:** Stage 1 merged code-fact-check summary, iteration 3 (k=3, HEAD 258f9ec4); iteration 1 and 2 security reports (docs/reviews/security-review-2026-10-15-doc-drift-cycle1.md, -i2.md)

The diff is documentation only. The security question is whether its operator advice about the cc-isolated boundary (recreate command, bare-form effects, CC update path) could leave a user with a weaker boundary or a false belief that they are patched, and whether the new AGENTS.md/GEMINI.md row adds instruction-loading risk.

## Prior findings: resolution

| Iter # | Finding | Status at 258f9ec4 | Evidence |
|---|---|---|---|
| i1-1 (Medium) | Bare-form warning omitted shared `~/.claude` volume (H6) and skipped probe | **Resolved** (since 9e0ff1a5; holds) | devcontainer-setup.md:403-404: "them base-only egress, an empty config hash, a `~/.claude` volume shared across projects, and a" / "build pointed at `/Dockerfile`), and the launcher's probe never runs (see the" |
| i1-2 (Low) | "Recreate to pick up a newer CC" gave false patch assurance | **Resolved** (holds) | devcontainer-setup.md:395-397: "change sits above the install layer. Newer CC versions arrive through Claude Code's" / "own auto-update inside the container, or `claude update` there (see the auto-update" / "row in `cc-isolated-usage.md`'s troubleshooting table); a recreated container starts" |
| i1-3 (Low) | dev-cycle row understated dispatch/merge authority | **Resolved** (holds) | AGENTS.md:36 = GEMINI.md:36 (executed `diff`: identical): "…as orchestrator it also collects, lands and dispatches build loops. …" |
| i2-1 (Info) | Shared-volume clause named the mechanism but not "shared with whom"; row pointer wrong | **Resolved** in 258f9ec4 | Both guides now say "a `~/.claude` volume shared across projects"; cc-isolated-usage.md:935 points to "the \"newly registered profile has no effect\" row below", which exists at :941 |
| i2-2 (Info) | No documented refresh path for the cached CC layer | **Deferred (C3)**, not re-filed | — |

## Trust Boundary Map

```
B1: [operator's host shell, following guide text]   → [cc-isolated exports CC_* (cc-isolated.sh:812-821), --probe-only recreates + probe_boundary under set -e] → [container: blessed egress, config hash, per-project ~/.claude volume]
B2 (bypassed path): [operator's host shell, bare `devcontainer up --remove-existing-container`] → [no launcher, no probe] → [container with empty CC_*: base-only egress, empty hash, shared cc--claude-config volume, build at /Dockerfile]
B3: [Claude Code install]                            → [cached image layer (Dockerfile:403) / npm registry via auto-update] → [CC version the session runs]
B4: [AGENTS.md / GEMINI.md row 36]                   → [harness auto-loads as standing instructions] → [agent routes user phrases to dev-cycle]
```

| Label | Source | Mutability | Trust classification (per sink) |
|---|---|---|---|
| S1 | Guide text (guides/*.md) read by the operator | deploy-time (reviewed on merge) | Trusted toward the **command-choice** sink only as far as it matches the code; it is the object under review |
| S2 | `CC_PROJECT_ID`, `CC_PROJECT_NAME`, `CC_CONFIG_DIR`, `CC_EGRESS_PROFILE`, `CC_CONFIG_HASH` via `${localEnv:…}` | request-time (invoking shell's env) | Trusted toward **volume-name / build-path / egress** sinks only when set by the launcher (B1); empty on B2, and devcontainer.json does not reject empty |
| S3 | `CLAUDE_CODE_VERSION: "latest"` (devcontainer.json:29) | code-constant | Trusted, but a constant string does not change the layer cache key, so it does not mean "current" toward the **patch-level** sink |
| S4 | AGENTS.md / GEMINI.md row 36 | deploy-time, agent-writable in-session | Loaded as instructions; UNTRUSTED toward the **file-import** sink (Gemini `@path`) |

What crosses: the guides send the operator to B1 and warn against B2, now naming all four of B2's effects plus the skipped probe, consistent with the rebuild_hint comment (cc-isolated.sh:537-548) and init-firewall.sh:343-350. At B3 the guide names auto-update / `claude update` as the update path and states the rollback on recreate. At B4 the row is plain text with no `@` token.

## Findings

#### 1. The cache-invalidation list includes triggers that do not sit above the CC install layer, so it slightly overstates when a rebuild reinstalls CC

**Severity:** Informational
**Location:** `guides/devcontainer-setup.md:387-390`
**Boundary:** B3
**Move:** 1 (trace the trust boundaries), building on FC3-A
**Confidence:** Medium (layer order read from the Dockerfile; no build run)
**Legibility-target:** for-author

Evidence (guides/devcontainer-setup.md:387-390):
> ``- **Image lifecycle:** `CLAUDE_CODE_VERSION=latest` is resolved when the install layer``
> `  is built, and Docker reuses that cached layer on later rebuilds until something`
> `  above it in the Dockerfile changes (the base image, the apt list, a toolchain`
> ``  version, `TZ`, or a pruned build cache): nothing in the launcher passes``

Evidence (Dockerfile:403, :451, :454):
> `RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}`
> `ARG ELAN_VERSION=v4.2.4`
> `ARG LEAN_TOOLCHAINS=""`

The rule ("something above it") is right. The examples are partly wrong: the Rust, uv, Android and .NET version ARGs sit above :403, but the elan/Lean ones sit below it, and a pruned build cache is not a Dockerfile change. An operator who bumps the Lean toolchain and re-blesses could think the recreate also refreshed CC. The harm is bounded. The same paragraph says the re-bless "reinstalls CC only when the re-blessed change sits above the install layer", names auto-update / `claude update` as the update path, and says a recreated container "starts again from the image's version". So the text does not promise patching, and this stays Informational. The floor rule does not apply: no boundary property is violated, and the patch-level effect is the deferred C3 gap, not a new mechanism.

**Recommendation:** Optional wording fix: "a toolchain version declared above it (Rust, uv, Android, .NET; not elan/Lean)", and move "or a pruned build cache" out of the "something above it changes" list into its own clause.

### Cleared (no finding)

- **Bare-form effects list (both guides).** All four effects match the rebuild_hint comment (cc-isolated.sh:537-548): "an empty CC_EGRESS_PROFILE/CC_CONFIG_HASH bakes base-only egress and an empty /etc/cc-config-hash … an empty CC_PROJECT_ID mounts the SHARED `cc--claude-config` volume; an empty CC_CONFIG_DIR points the build at /Dockerfile." The mounts at devcontainer.json:78-79 confirm the volume key. "Among them" correctly signals the list is not exhaustive (`CC_PROJECT_NAME` is cosmetic).
- **`--probe-only` described as "always recreates it from the blessed config and re-probes".** cc-isolated.sh:880-884 runs `devcontainer up --remove-existing-container "${dc[@]}"` then `probe_boundary "$ws"`, after the export at :821 and `check_manifest`.
- **README index line.** It names features (exit scan, cc-push via a host-only clone). It makes no security claim beyond what the usage guide documents.
- **Brief status open → done.** Not security-relevant.

## Untested bypass candidates

The diff adds no guardrail. It sends operators to an existing one. Candidates for the recommended path failing to enforce the probe:

1. *`--probe-only` exits 0 after a failed probe* (`probe_boundary "$ws"; exit 0`, :883-884). **Tested (read-static):** `set -euo pipefail` (:66) aborts the script non-zero on a failing `probe_boundary` before `exit 0`.
2. *`cc-isolated <repo>` launches claude after a failed re-probe.* **Tested (read-static):** the re-probe at :917 runs under the same `set -e`, before `devcontainer exec … claude` (:925).
3. *Operator runs the recommended command inside a CC session.* **Tested (read-static):** cc-isolated-usage.md:939 documents that docker fails there (AF_UNIX blocked), which is loud, not a bypass.
4. *Operator copies the by-hand form from an error message instead of following the guide.* **Listed, not tested:** rebuild_hint (:560-566) fills in every launcher-set assignment, but its first line calls plain `cc-isolated WS` a rebuild. Deferred as A4 (script change), not re-filed.
5. *A fully bare run actually succeeds and mounts the shared volume.* **Listed, not tested:** an empty `CC_CONFIG_DIR` most likely fails the build at `/Dockerfile` (fail-closed), so the shared-volume effect is reachable only if the operator set `CC_CONFIG_DIR` but not `CC_PROJECT_ID`. Needs a host run with docker, which this review may not start (FC3 Unverifiable).

## Endorsement Claims

- **Claim:** Both guides' recreate advice names the launcher path, which exports `CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR` before its `--probe-only` branch recreates the container and probes it.
  **Location:** `guides/devcontainer-setup.md:399-401`, `guides/cc-isolated-usage.md:935`; `devcontainer-config/cc-isolated.sh:812-821, 879-884`
  **Evidence:** read-static
  **Verified:** the export at :821; the `action = probe` branch at :879-884; guide wording matches init-firewall.sh:347-350.
  **Not verified:** where `CC_CONFIG_HASH` is assigned and exported (between :829 and :870, not read this pass; FC verified end-to-end), and how the devcontainer CLI resolves a set-but-empty `${localEnv:}`.
  **route: code-fact-check**

- **Claim:** The update path the guide names is reachable from inside the boundary, and a recreate discards an auto-updated CC.
  **Location:** `guides/devcontainer-setup.md:395-398`; `devcontainer-config/Dockerfile:403`; `devcontainer-config/devcontainer.json:77-80`
  **Evidence:** read-static
  **Verified:** CC installs into the image via npm at :403. The only volumes are `/commandhistory` and `/home/node/.claude` (devcontainer.json:78-79), so the npm-global prefix is container-layer state. The npm registry was confirmed on base egress in iteration 2 (egress/base.txt:82).
  **Not verified:** whether CC's auto-updater applies in the running session or on next start (CC internals, not in the repo).

- **Claim:** The new AGENTS.md/GEMINI.md row has no `@` token and is byte-identical in both files.
  **Location:** `AGENTS.md:36`, `GEMINI.md:36`
  **Evidence:** executed (`grep -n "@" AGENTS.md GEMINI.md`: no matches; `diff` of line 36: identical)
  **Verified:** the grep and diff at 258f9ec4.
  **Not verified:** whether Cursor or Cline auto-read files named in inline code (`docs/roadmap.md`, `docs/working/questions.md`).

- **Claim:** The diff changes no executable code, dependency manifest or lockfile.
  **Location:** `git diff --stat main...HEAD -- . ':!docs/reviews'`
  **Evidence:** executed
  **Verified:** six Markdown files, 25 insertions, 10 deletions; full diff3.patch read.
  **Not verified:** the untracked devcontainer-config/ manifest files in /workspace's own checkout (not on this branch).

## Primitive sweep

Primitive sweep: no dangerous primitives in scope. The diff is Markdown only. The commands it quotes (`cc-isolated --probe-only <repo>`, `cc-isolated <repo>`, `devcontainer up --remove-existing-container …`, `claude update`, `sudo /usr/local/bin/init-firewall.sh`) are operator instructions, not call sites. They are covered under B1-B3.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Cache-invalidation examples include triggers below the CC install layer (elan/Lean) and a non-Dockerfile cause | Informational | B3 | `guides/devcontainer-setup.md:387-390` | Medium |

## Overall Assessment

All prior findings stay resolved at 258f9ec4. Iteration 1's three and iteration 2's wording item are fixed. Iteration 2's cached-layer refresh gap is deferred as C3. The advice consistently moves operators off the bypass (B2) onto the launcher (B1), whose probe fails closed under `set -euo pipefail` (read-static). It names all four bare-form effects plus the skipped probe, matching the code comment the guides cite, and it does not overstate patch level. The one new item is an Informational example-list inaccuracy (FC3-A) whose surrounding text already prevents a false patch belief. No escalation pattern matched. Verdict: no findings above Informational within the code paths read; endorsement claims pending execution verification (the launcher-path claim is routed to code-fact-check, and read-static claims name their unreached hop).

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/security-review-2026-10-15-doc-drift-cycle1-i3.md, structured per the security-reviewer skill.
- Answered: Prior findings: iteration 1 findings 1-3 and iteration 2 finding 1 are resolved and stay resolved; iteration 2 finding 2 is deferred (C3). Weaker boundary? No: the advice sends operators to the launcher, and the bare-form warning is complete and matches the code. False patch assurance? No: the update path and the rollback are stated. The one new Informational item is the FC3-A example list. Instruction-loading risk from the new row? None found (no `@`, rows identical, authority stated).
- Out of scope: rebuild_hint wording at cc-isolated.sh:560 (A4), no cached-layer refresh path (C3), init-firewall.sh "rebuilds" (C4), all deferred and not re-filed; CC auto-updater timing; untracked devcontainer-config/ files in /workspace's checkout; review artifacts under docs/reviews/.
- Escalate: none at HALT level. Whether a fully bare run fails at the build before mounting the shared volume needs a host run with docker (FC3 Unverifiable). This review was not permitted to start one.
