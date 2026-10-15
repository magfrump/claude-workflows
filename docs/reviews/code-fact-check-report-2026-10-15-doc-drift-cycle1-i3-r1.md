Commit: 258f9ec4

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-doc-drift (branch `fix/doc-drift-cycle1`)
**Scope:** `git diff main...HEAD` doc changes (AGENTS.md, GEMINI.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md; review artifacts under docs/reviews/ excluded) plus the commit messages of 330138d8, 9e0ff1a5, 258f9ec4
**Checked:** 2026-10-15
**Total claims checked:** 19
**Summary:** 14 verified, 4 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination log (`docs/reviews/hallucination-patterns.md`) read first. No claim below matches a logged pattern (the logged entries are count/denominator fabrications and a non-existent consumer; none concerns the devcontainer launcher, Dockerfile layers, or the Skills table).

---

## Claim 1: AGENTS.md dev-cycle row matches global row 12 and the skill

> "User-started outer loop over research-plan-implement and pr-prep: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then build briefs for its top items; as orchestrator it also collects, lands and dispatches build loops. Questions for the user go to `docs/working/questions.md`."

**Location:** `AGENTS.md:36`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the trigger phrases, the step list, "outer loop over RPI and pr-prep", the roadmap and questions paths, and the orchestrator half against global row 12 and the skill's description; does not establish that the row is complete against the skill body (the leading "digest" step is omitted here, as it is in global row 12).
**Legibility-target:** for-orchestrator-synthesis

Global row 12 carries the same trigger list and step list:

```
// global-instructions/CLAUDE.md:32
| 12 | **Maintenance or planning pass over the repo**, or keywords: "run the dev cycle", "maintenance pass", "what should we work on next", "update the roadmap" | `dev-cycle` skill | ... The outer loop over rows 6/9: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then writes build briefs for its top items. User-started, no timer. Output is triage in `docs/working/questions.md`. |
```

Rows 6/9 are research-plan-implement and pr-prep (the global table's row 6 and row 9). The orchestrator half matches the skill description: "then as orchestrator collect build-loop results, write build briefs into free slots, record and land, and dispatch build loops" (`skills/dev-cycle/SKILL.md:4`). The skill description's first step, "digest", is absent from both the global row and this row (paraphrased — no quote available because the claim covers an absence from the row text quoted above).

**Evidence:** `global-instructions/CLAUDE.md:32`, `skills/dev-cycle/SKILL.md:4`, `skills/dev-cycle/SKILL.md:9-15`

---

## Claim 2: AGENTS.md and GEMINI.md kept in sync

> Commit 330138d8: "AGENTS.md, GEMINI.md: add a dev-cycle row to the Skills table, in sync."

**Location:** `GEMINI.md:36`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sync bats check and a byte diff of the two Skills sections; does not establish the brief's further acceptance item that the health check reports no skill divergence (not run).
**Legibility-target:** for-orchestrator-synthesis

Command `timeout 120 bats test/agents-gemini-sync.bats`, cwd `/workspace/.claude/wt-doc-drift`, exit 0, 2026-10-15T07:46:50Z. Output: `ok 1 AGENTS.md and GEMINI.md content is in sync (ignoring headers)`, `ok 2 ...`, `ok 3 AGENTS.md and the global instructions have no @-imports`. A `diff` of the `## Skills` through `## Context` sections of the two files printed nothing; the only whole-file difference is line 3, the per-tool intro sentence (paraphrased — no quote available because this is diff output, captured in the log below).

**Evidence:** `test/agents-gemini-sync.bats`, captured output `$TMPDIR/cfc-i3/sync.log` (outside the repo: the brief allows this report as the only created file in the worktree)

---

## Claim 3: guides/README.md index line

> "the `--probe`/`--bless` boundary checks, the exit scan of host-git inputs when a session ends, and `cc-push` for pushing a session's commits via a host-only clone."

**Location:** `guides/README.md:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that cc-isolated-usage.md documents both the exit scan and cc-push in those terms; does not establish the accuracy of those sections themselves.
**Legibility-target:** for-orchestrator-synthesis

`guides/cc-isolated-usage.md:28` reads "`cc-push --remote <url> [REPO]     # push a session's commits via a host-only clone`", and the guide has a section "`### The exit scan is a tripwire (Q-069 [3], Q-076)`" (`guides/cc-isolated-usage.md:302`). The launcher's header documents the scan's exit codes ("`3  the exit scan found a change the session made to what host git reads`", `devcontainer-config/cc-isolated.sh:30`).

**Evidence:** `guides/cc-isolated-usage.md:28-35`, `guides/cc-isolated-usage.md:302`, `devcontainer-config/cc-isolated.sh:19-30`

---

## Claim 4a: `cc-isolated --probe-only <repo>` always recreates from the blessed config and re-probes (code path)

> cc-isolated-usage.md: "`cc-isolated --probe-only <repo>` (recreates the container from the blessed config and re-probes), then `cc-isolated <repo>`." devcontainer-setup.md: "`cc-isolated --probe-only <repo>` (always recreates it from the blessed config and re-probes), then `cc-isolated <repo>`."

**Location:** `guides/cc-isolated-usage.md:935`, `guides/devcontainer-setup.md:398-400`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the launcher's probe action (unconditional `--remove-existing-container`, manifest check refusing a drifted config, launcher-exported build inputs, then the probe) and its agreement with init-firewall.sh:343-350; does not establish that the recreate rebuilds every image layer (it rebuilds only what the build cache does not hold, see Claims 7-8) or that the recreated container's firewall run then succeeds (Claim 4b).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:880-886
  if [ "$action" = "probe" ]; then
    # --probe-only is the verification command, so it always rebuilds: probing a
    # container left over from an earlier config would verify the wrong boundary.
    devcontainer up --remove-existing-container "${dc[@]}"
    probe_boundary "$ws"
    exit 0
  fi
```

Before this, `main` exports the build inputs ("`export CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR`", `:821`; "`CC_CONFIG_HASH="$(blessed_hash)"`", `:831-832`) and runs `check_manifest` (`:828`), which refuses when the installed config differs from the blessed manifest: "`ERROR: installed config changed since last bless — refusing to build/launch.`" (`devcontainer-config/cc-isolated.sh:342`; `set -euo pipefail` at `:66` makes the `return 1` abort). That is what "from the blessed config" rests on. The init-firewall.sh hint gives the same two-step recipe:

```bash
# devcontainer-config/init-firewall.sh:349-350
    echo "         cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes" >&2
    echo "         cc-isolated <repo>                 # then start the session" >&2
```

The guides say "recreates" where init-firewall.sh says "rebuilds"; the code (`--remove-existing-container`) supports "recreates" (the C4 deferral in override-log.md:832 covers the script wording). A plain `cc-isolated <repo>` alone would not recreate a bricked container whose hash matches: it only recreates when `container_config_matches` fails (`:893-896`), then prints `rebuild_hint` again on firewall failure (`:911-916`), which is why the probe-only step is first (paraphrased — no quote available because the path spans `:888-919`, quoted in part in Claim 11).

**Evidence:** `devcontainer-config/cc-isolated.sh:66`, `:332-350`, `:813-836`, `:880-919`, `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 4b: that recipe recovers a container whose firewall "cannot bootstrap any more"

> "If it cannot bootstrap any more, recreate it from the host with the launcher: `cc-isolated --probe-only <repo>` ..., then `cc-isolated <repo>`."

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond Claim 4a's code path; does not establish end-to-end recovery of a fail-closed container, which is a documented dev workflow and so needs execution.
**Legibility-target:** for-orchestrator-synthesis

Execution required, blocked: the review brief forbids starting docker/devcontainer. Statically, a recreated container runs `"postStartCommand": "sudo /usr/local/bin/init-firewall.sh && /usr/local/bin/link-claude-home.sh"` (`devcontainer-config/devcontainer.json`, postStartCommand key) on a fresh network namespace, so the stale DROP state does not carry over; whether the fresh run then succeeds depends on whatever made the first run abort (e.g. a transient outage). Verifying needs a host run: brick a container's firewall, run the two commands, observe a passing probe.

**Evidence:** `devcontainer-config/devcontainer.json` (postStartCommand), `devcontainer-config/cc-isolated.sh:903-917`

---

## Claim 5: bare-form effects and "the launcher's probe never runs" (cc-isolated-usage.md)

> "it drops the variables the launcher exports, and each one dropped has its own effect (among them base-only egress and an empty config hash, see the "newly registered profile has no effect" row below; a `~/.claude` volume shared across projects; and a build pointed at `/Dockerfile`), and the launcher's probe never runs."

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each named per-variable consequence of an empty `${localEnv:...}` and the absence of `probe_boundary` on the bare path; does not establish which of those effects co-occur in one fully bare run (an empty CC_CONFIG_DIR likely fails the build at `/Dockerfile` before anything is baked; 258f9ec4's Notes flag this as needing a host run), and CC_PROJECT_NAME's drop is not given an effect (fine under "among them").
**Legibility-target:** for-orchestrator-synthesis

```json
// devcontainer-config/devcontainer.json (build and mounts)
    "dockerfile": "${localEnv:CC_CONFIG_DIR}/Dockerfile",
    ...
      "CC_EGRESS_PROFILE": "${localEnv:CC_EGRESS_PROFILE}",
      ...
      "CC_CONFIG_HASH": "${localEnv:CC_CONFIG_HASH}"
    ...
    "source=cc-${localEnv:CC_PROJECT_ID}-claude-config,target=/home/node/.claude,type=volume"
```

An empty CC_CONFIG_DIR yields `/Dockerfile`; an empty CC_PROJECT_ID yields the volume name `cc--claude-config`, the same for every project run this way; empty profile and hash are baked by `printf '%s\n' "${CC_EGRESS_PROFILE}" > /etc/cc-egress-profile` and `printf '%s\n' "${CC_CONFIG_HASH}" > /etc/cc-config-hash` (`devcontainer-config/Dockerfile:524-527`). The rationale comment states all four: "an empty CC_PROJECT_ID mounts the SHARED `cc--claude-config` volume; an empty CC_CONFIG_DIR points the build at /Dockerfile." (`devcontainer-config/cc-isolated.sh:546-547`). Only `main` calls `probe_boundary` (`:884`, `:901`, `:918`), so a `devcontainer up` from a shell never probes (paraphrased — no quote available because the claim covers absence of any probe call outside the launcher).

**Evidence:** `devcontainer-config/devcontainer.json` (build, mounts), `devcontainer-config/Dockerfile:478-484`, `:524-527`, `devcontainer-config/cc-isolated.sh:534-567`, `:880-919`

---

## Claim 6: the "newly registered profile has no effect" row exists below PROBE FAIL

> "see the "newly registered profile has no effect" row below"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the named row exists later in the same table and explains base-only egress and an empty hash; does not establish that row's own remedy ("Relaunch with `cc-isolated <repo>`, which rebuilds with both set"), which is outside the diff.
**Legibility-target:** for-orchestrator-synthesis

`guides/cc-isolated-usage.md:941`: "`| A newly registered profile has no effect — the container's egress is still base-only (`/etc/cc-egress-profile` empty, `/etc/cc-config-hash` empty, ...`". PROBE FAIL is at `:935`, so the row is six rows below, in the same table (`:923-942`).

**Evidence:** `guides/cc-isolated-usage.md:923-942`

---

## Claim 7: `latest` is resolved when the install layer is built and the cached layer is reused; no `--build-no-cache`

> "`CLAUDE_CODE_VERSION=latest` is resolved when the install layer is built, and Docker reuses that cached layer on later rebuilds ...: nothing in the launcher passes `--build-no-cache`"

**Location:** `guides/devcontainer-setup.md:387-391`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the install instruction, the constant `latest` arg, and the absence of any no-cache flag in devcontainer-config/ and install.sh; does not establish the devcontainer CLI's own default cache behaviour beyond standard Docker layer caching (no host build run).
**Legibility-target:** for-orchestrator-synthesis

```dockerfile
# devcontainer-config/Dockerfile:402-403
# Install Claude
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}
```

devcontainer.json passes the constant `"CLAUDE_CODE_VERSION": "latest"`, so the instruction text and arg value are unchanged between builds and the cache key matches. `rg 'no-cache' devcontainer-config/ install.sh` returned no hits (paraphrased — no quote available because the claim covers absence of a flag).

**Evidence:** `devcontainer-config/Dockerfile:19`, `:403`, `devcontainer-config/devcontainer.json` (build.args), `devcontainer-config/cc-isolated.sh:883`, `:888`, `:895`

---

## Claim 8: the inputs that invalidate the cached install layer

> "until something above it in the Dockerfile changes (the base image, the apt list, a toolchain version, `TZ`, or a pruned build cache)"

**Location:** `guides/devcontainer-setup.md:387-390`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the position of each named input relative to `Dockerfile:403`; does not establish base-image refresh behaviour (whether the CLI pulls a moved `node:22` tag) or an exhaustive input list.
**Legibility-target:** for-author

Each named input does sit above the install layer: `FROM node:22` (`Dockerfile:14`), `ARG TZ` / `ENV TZ="$TZ"` (`:16-17`), the apt list (`:22-46`), and the toolchain version args (`ARG GIT_DELTA_VERSION=0.18.2` `:89`, `ARG UV_VERSION=0.11.28` `:115`, `ARG SHFMT_VERSION=3.13.1` `:168`, Android `:235-238`, `ARG RUST_VERSION=1.83.0` `:301`, `ARG DOTNET_SDK_VERSION=10.0.400` `:354`, `ARG ZSH_IN_DOCKER_VERSION=1.2.0` `:393`). The Lean/elan args are below `:403` ("a toolchain version" is still right as "some"). Two imprecisions: (1) "a pruned build cache" is not something "in the Dockerfile" that changes; it is a cache-side loss that forces the same rebuild. (2) TZ and the toolchain versions are effectively set outside the Dockerfile: devcontainer.json passes `"TZ": "${localEnv:TZ:America/Los_Angeles}"` and every toolchain version (e.g. `"RUST_VERSION": "1.83.0"`), which override the Dockerfile's `ARG` defaults, so editing only a Dockerfile default changes nothing, while a host `TZ` change or a devcontainer.json arg change does bust the cache. Precise version: "until an input to a layer above it changes (the base image, the apt list, a toolchain version or `TZ` build arg from devcontainer.json), or the build cache is pruned".

**Evidence:** `devcontainer-config/Dockerfile:14-46`, `:89-403`, `devcontainer-config/devcontainer.json` (build.args)

---

## Claim 9: profile and config hash are the last layer, so projects share every heavy layer

> "the egress profile and the config hash are the *last* layer in the Dockerfile, so projects on different profiles still share every heavy layer."

**Location:** `guides/devcontainer-setup.md:391-392`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both per-project args are declared and consumed only in the tail after every toolchain layer; does not establish that the tail is literally one layer (it is two ARGs, four COPYs and one RUN).
**Legibility-target:** for-orchestrator-synthesis

```dockerfile
# devcontainer-config/Dockerfile:473-478
# --- Everything below is per-project. Keep it LAST. -------------------------
# CC_EGRESS_PROFILE is the only build arg that varies between projects, so
# declaring it here means every layer above is shared across all projects'
# images (decision 016, S2: N projects must not mean N full builds — only this
# final layer is rebuilt when a project's egress profile differs).
ARG CC_EGRESS_PROFILE=""
```

(excerpt ends :478; the tail continues with `ARG CC_CONFIG_HASH=""` at `:484` and the baking RUN at `:515-529` — read.)

**Evidence:** `devcontainer-config/Dockerfile:473-531`

---

## Claim 10: a re-bless recreates each project's container at next launch

> "A re-bless changes the baked config hash, so the next launch of each project recreates its container automatically"

**Location:** `guides/devcontainer-setup.md:393-394`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the launch path's hash comparison and recreate; does not establish the `--probe-only` path (Claim 4a) or projects never launched again.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:893-896
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
  fi
```

**Evidence:** `devcontainer-config/cc-isolated.sh:569-576`, `:888-896`, `devcontainer-config/Dockerfile:484`, `:526`

---

## Claim 11: a re-bless reinstalls CC only when the change sits above the install layer

> "that reinstalls CC only when the re-blessed change sits above the install layer."

**Location:** `guides/devcontainer-setup.md:394-395`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the hash arg itself is declared below the install layer, so a re-bless alone leaves line 403 cached; does not establish the converse for every edit above (a comment-only Dockerfile edit above line 403 does not bust the cache), and rests on standard Docker cache semantics, not a host build.
**Legibility-target:** for-orchestrator-synthesis

`ARG CC_CONFIG_HASH=""` is declared at `devcontainer-config/Dockerfile:484`, after `RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}` (`:403`); a build arg affects the cache key only of instructions after its declaration (paraphrased — no quote available because this is Docker's documented build-cache rule, not repo code). Medium confidence because the "above" edge (comment-only edits, devcontainer.json arg edits) is broader than the sentence spells out; see Claim 8.

**Evidence:** `devcontainer-config/Dockerfile:403`, `:478-484`, `:515-529`

---

## Claim 12: newer CC arrives through in-container auto-update or `claude update`; the auto-update row exists

> "Newer CC versions arrive through Claude Code's own auto-update inside the container, or `claude update` there (see the auto-update row in `cc-isolated-usage.md`'s troubleshooting table)"

**Location:** `guides/devcontainer-setup.md:395-397`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the npm global prefix is node-writable, that no auto-update disable switch is set in the config, and that the cited row exists and names `claude update`; does not establish Claude Code's auto-updater behaviour itself (external product, not run).
**Legibility-target:** for-orchestrator-synthesis

```dockerfile
# devcontainer-config/Dockerfile:69-70
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share/npm-global
```

`rg 'AUTOUPDATER|autoUpdates|DISABLE_AUTO' devcontainer-config/` returned no hits (paraphrased — no quote available because the claim covers absence). The row: "`| Claude Code auto-update fails every launch in ONE project (`.last-update-result.json` shows `install_failed`; ...`" ending "then `claude update`. |" (`guides/cc-isolated-usage.md:940`).

**Evidence:** `devcontainer-config/Dockerfile:69-70`, `:382-383`, `guides/cc-isolated-usage.md:940`

---

## Claim 13: a recreated container starts again from the image's version

> "a recreated container starts again from the image's version."

**Location:** `guides/devcontainer-setup.md:397-398`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the CC install location is in the container filesystem, not a mounted volume; does not establish where a future native-installer CC would store versions.
**Legibility-target:** for-orchestrator-synthesis

The only mounts are "`source=cc-${localEnv:CC_PROJECT_ID}-bashhistory,target=/commandhistory,type=volume`" and "`source=cc-${localEnv:CC_PROJECT_ID}-claude-config,target=/home/node/.claude,type=volume`" (`devcontainer.json`, mounts), plus the repo at `/workspace`; CC lives under `NPM_CONFIG_PREFIX=/usr/local/share/npm-global` (`Dockerfile:382`), which none of them covers.

**Evidence:** `devcontainer-config/devcontainer.json` (mounts, workspaceMount), `devcontainer-config/Dockerfile:382-383`, `:403`

---

## Claim 14: bare-form effects, probe, and "the comment above rebuild_hint" (devcontainer-setup.md)

> "each one dropped has its own effect (among them base-only egress, an empty config hash, a `~/.claude` volume shared across projects, and a build pointed at `/Dockerfile`), and the launcher's probe never runs (see the comment above `rebuild_hint` in `cc-isolated.sh`)."

**Location:** `guides/devcontainer-setup.md:401-405`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the same four effects as Claim 5 and that the cited comment exists and holds that rationale; does not establish co-occurrence in one fully bare run (same residue as Claim 5).
**Legibility-target:** for-orchestrator-synthesis

The comment sits directly above the function: "`# WHY THIS IS NOT A BARE `devcontainer up` STRING. devcontainer.json reads`" (`devcontainer-config/cc-isolated.sh:537`) through "`# points the build at /Dockerfile.`" (`:547`), then `rebuild_hint() {` at `:557`. Effects verified as in Claim 5.

**Evidence:** `devcontainer-config/cc-isolated.sh:534-567`

---

## Claim 15: staleness trigger is decision 015's

> "Staleness >1 version for >2 weeks is a decision-015 Revisit trigger."

**Location:** `guides/devcontainer-setup.md:405-406`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the trigger's existence and wording; does not establish whether it is currently firing.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/015-cc-process-isolation-docker-devcontainer.md:57`: "`| **Revisit** | >1 Docker/devcontainer breakage per week needing manual fixing, or image staleness pins CC >1 version behind for >2 weeks | ...`".

**Evidence:** `docs/decisions/015-cc-process-isolation-docker-devcontainer.md:57`

---

## Claim 16: 330138d8 — matches init-firewall.sh's hint (fc3bff82); "the row below"; line 58 left alone

> "now recommends `cc-isolated --probe-only <repo>` then `cc-isolated <repo>`, matching init-firewall.sh's hint (fc3bff82), ... and points at the row below that explains why the bare form bakes base-only egress." Notes: "Line 58 of cc-isolated-usage.md describes what the launcher does itself".

**Location:** commit `330138d8` (message body)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fc3bff82 provenance, the row pointer, and the line-58 note; does not re-litigate the commit's corrections, which 258f9ec4 B4 and override-log.md:833 already record.
**Legibility-target:** for-author

`git log -S'cc-isolated --probe-only <repo>    # rebuilds' -- devcontainer-config/init-firewall.sh` returns 48a8200b, which `git merge-base --is-ancestor` places inside merge fc3bff82 and not in its first parent, so "(fc3bff82)" is right (paraphrased — no quote available because this is git history output). Line 58 of the guide is step 5 of the launcher's own sequence: "recreate it with `--remove-existing-container`. `devcontainer up` alone never rebuilds." (`guides/cc-isolated-usage.md:58-59`), so the note holds. "The row below" was imprecise (the row is six rows down, `:941` vs `:935`); the current text names the row and 258f9ec4 B4 records the correction. Commit messages cannot be amended without a history rewrite; no action beyond that record.

**Evidence:** `devcontainer-config/init-firewall.sh:343-350`, `guides/cc-isolated-usage.md:50-62`, `:935`, `:941`, `docs/reviews/override-log.md:833`

---

## Claim 17: 9e0ff1a5 — cached install layer, A4 characterisation, C1, A3

> "The install layer is cached (no --build-no-cache anywhere in the launcher), a re-bless recreates from cached layers, and newer CC arrives through in-container auto-update or `claude update`" ... "A4 (rebuild_hint in cc-isolated.sh:560 says a plain launch rebuilds, which contradicts the guides' recipe for a bricked firewall)" ... "C1: devcontainer-setup.md cites the comment above rebuild_hint"

**Location:** commit `9e0ff1a5` (message body)
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed item against current code; does not cover the review artifacts it added.
**Legibility-target:** for-author

"a re-bless recreates from cached layers" lacks the qualifier that a change above line 403 rebuilds from there (Claims 8, 11); 258f9ec4 B4 and override-log.md:833 record this. The rest holds: no no-cache flag (Claim 7); `rebuild_hint` line 560 reads "`echo "    cc-isolated $(printf '%q' "$ws")        # the supported path: rebuilds, re-probes, re-launches" >&2`" (`devcontainer-config/cc-isolated.sh:560`), while a plain launch recreates only on a hash mismatch (`:893-896`), so A4's description is accurate; at 9e0ff1a5 the guide said "see the comment above `rebuild_hint`" (`git show 9e0ff1a5:guides/devcontainer-setup.md`, line 402); the AGENTS.md row carries row 12's step list (Claim 1).

**Evidence:** `devcontainer-config/cc-isolated.sh:557-567`, `:888-919`, `docs/reviews/override-log.md:828`, `:833`

---

## Claim 18: 258f9ec4 — B1 "six rows away", B2 four effects in both guides, B4 corrections

> "B1 ...: the PROBE FAIL row names the row it points at ("newly registered profile has no effect") instead of "the row below", which is six rows away." "B2 ...: both guides list the bare form's effects as "among them" base-only egress, an empty config hash, a ~/.claude volume shared across projects, and a build pointed at /Dockerfile". "B4: ... 330138d8 called the pointer "the row below", and 9e0ff1a5 said "a re-bless recreates from cached layers""

**Location:** commit `258f9ec4` (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers B1, B2 and B4 against the guides and the earlier commit bodies; B3 is Claim 19.
**Legibility-target:** for-orchestrator-synthesis

`:935` to `:941` is six rows (Claim 6). Both guides carry all four effects (Claims 5, 14). 330138d8's body says "points at the row below" and 9e0ff1a5's says "a re-bless recreates from cached layers" (quoted in Claims 16-17). Override rows C3/C4/B4 exist at `docs/reviews/override-log.md:831-833`.

**Evidence:** `guides/cc-isolated-usage.md:935`, `:941`, `guides/devcontainer-setup.md:401-404`, `docs/reviews/override-log.md:828-833`

---

## Claim 19: 258f9ec4 — B3 qualifier and its Notes

> "B3 ...: the Image lifecycle paragraph qualifies cached-layer reuse: it holds until something above the install layer changes (base image, apt list, a toolchain version, TZ, a pruned cache)". Notes: "The qualifier list in B3 names the inputs above Dockerfile:403 that the iteration-2 replicates found ...; it is a list of examples, not exhaustive."

**Location:** commit `258f9ec4` (message body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the commit describes the guide's change correctly and that the inputs sit above line 403; inherits Claim 8's imprecision; does not establish base-image pull behaviour.
**Legibility-target:** for-author

The guide's text matches the description (Claim 8). Same tightening applies: "a pruned cache" is not an input "above Dockerfile:403", and TZ and the toolchain versions take effect through devcontainer.json's `build.args` (e.g. `"TZ": "${localEnv:TZ:America/Los_Angeles}"`, `"RUST_VERSION": "1.83.0"`), not through the Dockerfile's `ARG` defaults. The "examples, not exhaustive" framing is accurate.

**Evidence:** `devcontainer-config/Dockerfile:14-403`, `devcontainer-config/devcontainer.json` (build.args)

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 8** (`guides/devcontainer-setup.md:388-390`): "something above it in the Dockerfile changes (... or a pruned build cache)": a pruned cache is not a Dockerfile change, and TZ / toolchain versions are build args set in devcontainer.json (host `TZ`) that override the Dockerfile's `ARG` defaults. Suggested: "until an input to a layer above it changes (the base image, the apt list, or a toolchain-version or `TZ` build arg from devcontainer.json), or the build cache is pruned".
- **Claim 19** (commit `258f9ec4`): B3's description inherits Claim 8's imprecision. Record only; commits are not amended.
- **Claim 16** (commit `330138d8`): "the row below" was six rows away; already corrected in the guide and recorded (258f9ec4 B4, override-log.md:833). No action.
- **Claim 17** (commit `9e0ff1a5`): "a re-bless recreates from cached layers" lacked the qualifier; already recorded (258f9ec4 B4, override-log.md:833). No action.

### Unverifiable
- **Claim 4b** (`guides/cc-isolated-usage.md:935`): that `--probe-only` then a launch actually recovers a fail-closed container needs a host docker run (blocked by the review brief). The code path is Verified (Claim 4a).

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report on the diff saved to the given path, structured per the code-fact-check skill.
- Answered: all 19 checkable claims in the doc diff and the three commit bodies, with verdicts: 14 Verified, 4 Mostly accurate, 1 Unverifiable, 0 Incorrect, 0 Stale. The six focus areas: (1) every named input does sit above Dockerfile:403, though the wording needs tightening (Claim 8); (2) the bare-form effects, the probe, the named row and the rebuild_hint comment are Verified; (3) the `--probe-only` code path is Verified and matches init-firewall.sh:343-350; (4) the README index line is Verified; (5) the dev-cycle row and the sync are Verified, the sync by running the bats test; (6) the commit claims are Verified or Mostly accurate, and the imprecisions are already recorded.
- Out of scope: the review artifacts under docs/reviews/; the brief's acceptance item "health check reports no skill divergence" (not run); end-to-end docker behaviour (forbidden by the brief); the C3/C4/A4 script wording, which override-log.md defers.
- Escalate: none. Claim 8 is a one-sentence doc tightening (for-author); nothing blocks a merge.
