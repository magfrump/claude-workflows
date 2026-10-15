Commit: 9e0ff1a5

# Security Review — fix/doc-drift-cycle1 (iteration 2)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-doc-drift, review artifacts under docs/reviews/ excluded: AGENTS.md, GEMINI.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md. Read for context: devcontainer-config/cc-isolated.sh (`set -euo pipefail` :66, rebuild_hint and its comment 534-567, probe_boundary 577-~700, env export 813-821, probe action / main rebuild / exec 879-938), devcontainer-config/init-firewall.sh 330-352, devcontainer-config/devcontainer.json (build 25-29, mounts 77-79), devcontainer-config/Dockerfile (19, 382-383, 403), devcontainer-config/egress/base.txt:81-82, guides H6 text (devcontainer-setup.md:63, :201; cc-isolated-usage.md:800).
**Date:** 2026-10-15
**Based on:** Stage 1 merged code-fact-check summary, iteration 2 (k=3, HEAD 9e0ff1a5); iteration 1 security report docs/reviews/security-review-2026-10-15-doc-drift-cycle1.md

The diff is documentation only. Its guide hunks are operating instructions for the cc-isolated isolation boundary: which recreate command to run, what the bare form does, and how Claude Code gets updated. Its AGENTS.md/GEMINI.md hunk adds a row to files that non-Claude agents load as standing instructions. This pass checks whether any of that advice could leave a user with a weaker boundary or a false belief that they are patched, and whether the iteration 1 findings are resolved.

## Iteration 1 findings: resolution

| Iter-1 # | Finding | Status at 9e0ff1a5 | Evidence |
|---|---|---|---|
| 1 (Medium) | The bare-form warning left out the shared `~/.claude` volume (H6) and the skipped probe | **Resolved.** Both guides now name the shared volume and say the launcher's probe never runs. What remains is legibility only, carried as Finding 1 below (Informational) | devcontainer-setup.md:401-402: "(base-only egress, an empty config hash, the shared `cc--claude-config` volume)," / "and the launcher's probe never runs (see the comment above `rebuild_hint` in"; cc-isolated-usage.md:935: "the shared `cc--claude-config` volume), and the launcher's probe never runs." |
| 2 (Low) | "Recreate to pick up a newer CC" reused the cached CC layer and gave false patch assurance | **Resolved.** The guide no longer says a recreate refreshes CC. It names auto-update and `claude update` as the update path and says a recreate goes back to the image's version. The no-cache follow-up is still open (Finding 2, Informational) | devcontainer-setup.md:393-396: "layers. Newer CC versions arrive through Claude Code's own auto-update inside the" / "container, or `claude update` there (see the auto-update row in" / "`cc-isolated-usage.md`'s troubleshooting table); a recreated container starts" / "again from the image's version." |
| 3 (Low) | The dev-cycle row understated its dispatch and merge authority in auto-loaded files | **Resolved.** The row now states the orchestrator role, and "Output is triage" is gone | AGENTS.md:36 (byte-identical to GEMINI.md:36, checked with `diff`): "…then build briefs for its top items; as orchestrator it also collects, lands and dispatches build loops. Questions for the user go to `docs/working/questions.md`. \|" |

## Trust Boundary Map

```
B1: [user's host shell, following guide text]  → [cc-isolated launcher exports CC_* localEnv (cc-isolated.sh:813-821), runs probe_boundary under set -e] → [container: blessed egress profile, config hash, per-project ~/.claude volume]
B2 (bypassed path): [user's host shell, bare `devcontainer up --remove-existing-container`] → [no launcher, no probe] → [container with empty CC_* localEnv: base-only egress, empty hash, SHARED cc--claude-config volume, build path /Dockerfile]
B3: [Claude Code install inside container] → [npm registry via base egress (egress/base.txt:82) / cached image layer (Dockerfile:403)] → [CC binary version the session runs]
B4: [AGENTS.md / GEMINI.md rows in repo] → [harness auto-loads as instructions (Copilot, Cursor, Cline, Gemini CLI; Gemini `@path` import)] → [agent routes a user phrase to the dev-cycle skill]
```

| Label | Source | Mutability | Trust classification (per sink) |
|---|---|---|---|
| S1 | Guide text in guides/*.md (read by the human operator) | deploy-time (repo content, reviewed on merge) | Trusted as operator guidance for **command-choice** sinks only as far as it matches the code; it is what this review examines |
| S2 | `CC_PROJECT_ID`, `CC_PROJECT_NAME`, `CC_CONFIG_DIR`, `CC_EGRESS_PROFILE`, `CC_CONFIG_HASH` via `${localEnv:…}` | request-time (whatever the invoking shell exports) | Trusted toward the **volume-name / build-path / egress** sinks only when the launcher sets them (B1). On B2 they resolve to the empty string, and devcontainer.json does not reject that |
| S3 | `CLAUDE_CODE_VERSION: "latest"` (devcontainer.json:29) | code-constant | Trusted, but a constant string never changes the layer cache key, so it does not mean "current" toward the **patch-level** sink |
| S4 | AGENTS.md / GEMINI.md row 36 | deploy-time, but agent-writable in a session (the repo is bind-mounted) | Loaded as instructions; UNTRUSTED toward the **file-import** sink (a Gemini CLI `@path` token would pull a file into context) |

What crosses: the guides send the operator to B1, which sets every S2 value and runs the probe under `set -euo pipefail`. They warn against B2 and now list its effects, including the volume share. At B3 the guide now describes the update path accurately. At B4 the row is plain text with no `@` token and states the skill's authority.

## Findings

#### 1. The shared-volume clause names the mechanism but not its consequence, and does not link to H6

**Severity:** Informational
**Location:** `guides/devcontainer-setup.md:401`, `guides/cc-isolated-usage.md:935`
**Boundary:** B2
**Move:** 1 (trace the trust boundaries)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence (guides/devcontainer-setup.md:399-402):
> `` `devcontainer up --remove-existing-container …` from your own shell: it drops the``
> `variables the launcher exports, and each one dropped has its own effect`
> ``(base-only egress, an empty config hash, the shared `cc--claude-config` volume),``
> ``and the launcher's probe never runs (see the comment above `rebuild_hint` in``

Evidence (the consequence, guides/devcontainer-setup.md:63):
> `rebuilds. Each project gets its **own** volume — decision 016 H6 — so a`

The iteration 1 gap is closed: the volume share and the skipped probe are both named. The phrase "the shared `cc--claude-config` volume" still leaves the reader to work out *shared with whom*, and that this is the H6 property (one project's session can read another's credentials, memory and history) that the guide defines at :63 and :201 and the usage guide at :800. A reader who skims the list sees three neutral-sounding effects. This is wording only. The mechanism is stated correctly and the recommended path is the right one, so it rates Informational. The floor rule does not apply because the finding names no new mechanism.

**Recommendation:** Optional. Write "the `cc--claude-config` volume shared across every project rebuilt this way (H6)" in both places. In the same edit, fix FC2-A's "see the row below", which points six rows past the target.

#### 2. There is no documented way to refresh the image's CC layer, so each recreate starts from a CC that can be arbitrarily old

**Severity:** Informational
**Location:** `guides/devcontainer-setup.md:387-396`
**Boundary:** B3
**Move:** 3 (check the error path)
**Confidence:** Low (cache behaviour inferred from FC2-C and Dockerfile:403; no build run; CC auto-update timing not verified)
**Legibility-target:** for-author

Evidence (guides/devcontainer-setup.md:387-389):
> ``- **Image lifecycle:** `CLAUDE_CODE_VERSION=latest` is resolved when the install``
> `layer is built, and Docker reuses that cached layer on later rebuilds: nothing in`
> ``the launcher passes `--build-no-cache`, and the egress profile and the config hash``

Evidence (guides/devcontainer-setup.md:395-396):
> ``  `cc-isolated-usage.md`'s troubleshooting table); a recreated container starts``
> `  again from the image's version. To recreate a container by hand, use the launcher:`

The text is now accurate and it states the rollback, which fixes the iteration 1 false-assurance issue. One gap remains. Every recreate (a re-bless, the `--probe-only` recovery in the firewall row at cc-isolated-usage.md:935) goes back to the cached image CC, and the guide gives no way to move that baseline forward. The first session after a recreate may run that old version until auto-update catches up (registry.npmjs.org is in base egress, egress/base.txt:82). Per FC2-C, the cached-layer claim is conservative: an upstream layer change re-runs the install anyway. So the text errs toward under-promising, which is the safe direction. This is the iteration 1 "no-cache launcher path" follow-up, still out of this brief's scope.

**Recommendation:** No change needed in this diff. Keep the iteration 1 follow-up (a documented or launcher-supported no-cache rebuild, or a version check against the decision-015 staleness trigger) on the roadmap.

### Cleared (no finding)

- **FC2-B, empty `CC_CONFIG_DIR` left out of the effects list.** devcontainer.json:25-26 builds from `${localEnv:CC_CONFIG_DIR}/Dockerfile` with context `${localEnv:CC_CONFIG_DIR}`. Empty, that resolves to `/Dockerfile` with context `/`. A host normally has no `/Dockerfile`, so a fully bare run most likely fails at the build: fail-closed. Leaving it out does not make the bypass look *safer* than it is. If anything it makes the volume-share effect conditional on the build succeeding (for example, when the user set `CC_CONFIG_DIR` but not the others). Whether that happens needs a host run, as FC2-B notes.
- **FC2-A pointer regression.** Navigation only. The target row (cc-isolated-usage.md:941) describes egress and hash symptoms and does not change the safety advice.

## Untested bypass candidates

The diff adds no guardrail. It sends operators to an existing one (`cc-isolated --probe-only` then `cc-isolated`). Candidate ways the recommended path could fail to enforce the probe:

1. *`--probe-only` reports success after a failed probe* (`probe_boundary "$ws"; exit 0` at cc-isolated.sh:883-884). **Tested (read-static):** `set -euo pipefail` at :66 ends the script with a non-zero status when `probe_boundary` returns 1 (its final `return 1`), before `exit 0`.
2. *`cc-isolated <repo>` starts claude after a failed re-probe.* **Tested (read-static):** the second `probe_boundary "$ws"` (:918) runs under the same `set -e`, so a failure exits before `devcontainer exec … claude` (:927).
3. *The operator runs the recommended command inside a Claude Code session.* **Tested (read-static):** the troubleshooting row at cc-isolated-usage.md:939 says docker fails there (AF_UNIX blocked). The failure is loud, not a bypass.
4. *The operator follows the guide but copies the by-hand form from an error message.* **Listed, not tested:** rebuild_hint (:560-566) prints every launcher-set assignment filled in, but the iteration 1 A4 note says its first line still calls plain `cc-isolated WS` a rebuild. That is script text outside this diff and was deferred.

## Endorsement Claims

- **Claim:** Both guides' recreate advice names the launcher path. That path exports `CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR` before any `devcontainer up`, and its `--probe-only` branch recreates and then probes.
  **Location:** `guides/devcontainer-setup.md:397-398`, `guides/cc-isolated-usage.md:935`; `devcontainer-config/cc-isolated.sh:813-821, 879-885`
  **Evidence:** read-static
  **Verified:** the export line at :821, then the `action = probe` branch running `devcontainer up --remove-existing-container "${dc[@]}"` and `probe_boundary "$ws"` (:882-883). The guide text matches init-firewall.sh:343-350.
  **Not verified:** where `CC_CONFIG_HASH` is assigned and exported (between :829 and :875, not read this pass; FC verified it end-to-end), and how the devcontainer CLI resolves a set-but-empty `${localEnv:}`.
  **route: code-fact-check**

- **Claim:** The update path the guide now names is reachable from the boundary: the CC install prefix is in the container filesystem, and the npm registry is on the base allowlist.
  **Location:** `guides/devcontainer-setup.md:393-396`; `devcontainer-config/Dockerfile:382-383, 403`; `devcontainer-config/egress/base.txt:81-82`; `devcontainer-config/devcontainer.json:77-79`
  **Evidence:** read-static
  **Verified:** `NPM_CONFIG_PREFIX=/usr/local/share/npm-global` (Dockerfile:382). The only mounts are `/commandhistory` and `/home/node/.claude` (devcontainer.json:78-79), so a recreate discards an auto-updated CC. `registry.npmjs.org` is at base.txt:82.
  **Not verified:** whether CC's auto-updater applies the update in the running session or on the next start (CC internals, not in the repo).

- **Claim:** The new AGENTS.md/GEMINI.md row has no `@`-prefixed token, so Gemini CLI's `@path` import has nothing to expand from it, and the row is byte-identical in both files.
  **Location:** `AGENTS.md:36`, `GEMINI.md:36`
  **Evidence:** executed (`grep -n "@" AGENTS.md GEMINI.md`: no matches; `diff` of line 36 in both files: identical)
  **Verified:** the grep and diff results at 9e0ff1a5.
  **Not verified:** whether Cursor or Cline auto-read files named in inline code (`docs/roadmap.md`, `docs/working/questions.md`).

- **Claim:** The diff changes no executable code, dependency manifest or lockfile.
  **Location:** all six files in `git diff --stat main...HEAD -- . ':!docs/reviews'`
  **Evidence:** executed (`git diff --stat`: six Markdown files, 23 insertions, 10 deletions)
  **Verified:** the stat output and the full 11 KB diff2.patch.
  **Not verified:** the untracked devcontainer-config/ manifest files in /workspace's own checkout (not on this branch).

## Primitive sweep

Primitive sweep: no dangerous primitives in scope. The diff is Markdown only. The shell commands it quotes (`cc-isolated --probe-only <repo>`, `cc-isolated <repo>`, `devcontainer up --remove-existing-container …`, `claude update`) are operator instructions, not call sites, and are covered under B1-B3 above.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Shared-volume clause names the mechanism but not the H6 consequence | Informational | B2 | `guides/devcontainer-setup.md:401`, `guides/cc-isolated-usage.md:935` | Medium |
| 2 | No documented refresh of the image's cached CC layer (iter-1 follow-up, deferred) | Informational | B3 | `guides/devcontainer-setup.md:387-396` | Low |

## Overall Assessment

All three iteration 1 findings are resolved at 9e0ff1a5. The bare-form warning now names the shared `~/.claude` volume and the skipped probe. The image-lifecycle text no longer says a recreate refreshes CC, and it names the real update path and the rollback. The dev-cycle row states its orchestrator authority. The advice moves users from the bypass (B2) to the launcher (B1). Reading the code statically, that path fails closed on a failed probe (`set -euo pipefail`, :66). Two Informational wording and follow-up items remain, and neither weakens the boundary or overstates patch level. No escalation pattern matched. Verdict: no findings within the code paths read; endorsement claims pending execution verification. The launcher-path claim is routed to code-fact-check, and the read-static claims name the hop they did not reach.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/security-review-2026-10-15-doc-drift-cycle1-i2.md, structured per the security-reviewer skill.
- Answered: Could the advice lead to a weaker boundary? No. It sends users to the launcher, whose probe fails closed (read-static), and it now names the bare form's volume share and skipped probe (Finding 1 is wording only). Could it give a false sense of being patched? No longer. The guide names auto-update or `claude update` and says a recreate goes back to the image version (Finding 2 is the deferred no-cache follow-up). Does the AGENTS/GEMINI row add an instruction-loading risk? No `@` tokens, byte-identical rows, authority now stated. Iteration 1 findings 1-3 are all resolved.
- Out of scope: rebuild_hint's first line calling plain `cc-isolated WS` a rebuild (cc-isolated.sh:560, iteration 1 A4, script change); a no-cache launcher path; CC auto-updater timing; the untracked devcontainer-config/ files in /workspace's checkout; review artifacts under docs/reviews/.
- Escalate: none at HALT level. Whether a fully bare run fails at the build before mounting the shared volume (FC2-B residue) needs a host run with docker, which this review may not start.
