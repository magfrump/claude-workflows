Commit: 258f9ec4

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-doc-drift (branch fix/doc-drift-cycle1)
**Scope:** `git diff main...HEAD` doc changes (AGENTS.md, GEMINI.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md; docs/reviews/ excluded) plus commit messages 330138d8, 9e0ff1a5, 258f9ec4
**Checked:** 2026-10-15
**Total claims checked:** 22
**Summary:** 21 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 logged patterns, all count/denominator or consumer claims) was read; no claim below matches a logged pattern.

---

## Claim 1: AGENTS.md dev-cycle row: "User-started outer loop over research-plan-implement and pr-prep: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then build briefs for its top items; as orchestrator it also collects, lands and dispatches build loops. Questions for the user go to `docs/working/questions.md`."

**Location:** `AGENTS.md:36`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement of the row's trigger list, step list, "outer loop over" pairing and questions destination with global row 12 and the skill's description; does not establish that the skill body's step semantics (D1-D14, slot logic) are fully summarized.

Global row 12 carries the same triggers and steps: `global-instructions/CLAUDE.md:32` "`run the dev cycle`, `maintenance pass`, `what should we work on next`, `update the roadmap` ... The outer loop over rows 6/9: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then writes build briefs for its top items. User-started, no timer. Output is triage in `docs/working/questions.md`." Rows 6/9 are RPI and pr-prep. The orchestrator clause matches `skills/dev-cycle/SKILL.md:3-4` "then as orchestrator collect build-loop results, write build briefs into free slots, record and land, and dispatch build loops", and the skill body routes questions to `docs/working/questions.md` (`skills/dev-cycle/SKILL.md:92`). "collects ... build loops" abbreviates "collect build-loop results"; not a mismatch.

**Evidence:** `global-instructions/CLAUDE.md:32`, `skills/dev-cycle/SKILL.md:3-4`, `skills/dev-cycle/SKILL.md:92`, `AGENTS.md:36`

---

## Claim 2: GEMINI.md gains the same dev-cycle row, "in sync" (330138d8)

**Location:** `GEMINI.md:36`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers byte-identity of line 36 in the two files at HEAD; does not establish that the rest of the two files are identical or that any script enforces the parity (none found).

`diff <(sed -n '36p' AGENTS.md) <(sed -n '36p' GEMINI.md)` printed no difference (paraphrased — no quote available because the claim is identity of two lines; the diff hunks for both files in the branch diff are textually identical). No test or script checks AGENTS/GEMINI parity (paraphrased — no quote available because claim covers absence of code: `rg GEMINI scripts/ hooks/ test/` hits only fixture files in `test/scripts/*.bats`).

**Evidence:** `AGENTS.md:36`, `GEMINI.md:36`

---

## Claim 3: Brief status "open -> done"

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the status line reads `done` and that items 1-4 (`:18-29`) each have a corresponding diff hunk; does not establish that the brief's acceptance criteria are met beyond the claims verdicted here.

`docs/working/briefs/2026-10-02-doc-drift-cycle1.md:3` reads `Status: done`. Items 1-4 name the PROBE FAIL row, Image lifecycle, the README index line and AGENTS/GEMINI (`:18`, `:25`, `:27`, `:29`), each touched by the diff.

**Evidence:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:3-48`

---

## Claim 4: README index: cc-isolated-usage.md covers "the exit scan of host-git inputs when a session ends, and `cc-push` for pushing a session's commits via a host-only clone"

**Location:** `guides/README.md:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers presence of both topics in the target guide and in cc-push.sh's header; does not establish the guide's accuracy on those topics.

`guides/cc-isolated-usage.md:62-65`: "Before step 4 the launcher snapshots what host git reads to decide what to run ... when claude exits it compares, and exits **3**" (excerpt ends :65; enclosing step 7 continues to :73 — read). `guides/cc-isolated-usage.md:28`: "`cc-push --remote <url> [REPO]     # push a session's commits via a host-only clone`". `devcontainer-config/cc-push.sh:13`: "the real remote, stored in the host-only clone".

**Evidence:** `guides/cc-isolated-usage.md:28-38`, `guides/cc-isolated-usage.md:62-77`, `devcontainer-config/cc-push.sh:5-20`

---

## Claim 5: PROBE FAIL row: recreate with "`cc-isolated --probe-only <repo>` (recreates the container from the blessed config and re-probes), then `cc-isolated <repo>`"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the probe action's unconditional `--remove-existing-container` and probe call and its consistency with init-firewall.sh's hint; does not establish (no host run) that the recreate succeeds on a bricked container in practice.

```bash
# devcontainer-config/cc-isolated.sh:880-885
  if [ "$action" = "probe" ]; then
    # --probe-only is the verification command, so it always rebuilds: probing a
    # container left over from an earlier config would verify the wrong boundary.
    devcontainer up --remove-existing-container "${dc[@]}"
    probe_boundary "$ws"
    exit 0
  fi
```
`--probe-only` sets `action="probe"` (`devcontainer-config/cc-isolated.sh:735`), and the probe path runs after CC_* are exported (`:821`, `:832`), so the recreate uses the blessed config's hash and profile. Under `set -euo pipefail` (`:66`) a failing probe exits non-zero. The recipe matches `devcontainer-config/init-firewall.sh:347-350`: "`cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes`" / "`cc-isolated <repo>                 # then start the session`".

**Evidence:** `devcontainer-config/cc-isolated.sh:66`, `devcontainer-config/cc-isolated.sh:735`, `devcontainer-config/cc-isolated.sh:813-832`, `devcontainer-config/cc-isolated.sh:880-885`, `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 6: Bare form "drops the variables the launcher exports, and each one dropped has its own effect (among them base-only egress and an empty config hash ...; a `~/.claude` volume shared across projects; and a build pointed at `/Dockerfile`)"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the per-variable mapping from each launcher-exported `localEnv` read in devcontainer.json to its effect; does not establish (needs a host run) which effects co-occur in a fully bare run — with CC_CONFIG_DIR empty the build targets `/Dockerfile` and plausibly fails before anything is baked, as 258f9ec4's Notes acknowledge.

Exports are only in main: `devcontainer-config/cc-isolated.sh:821` "`export CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR`", `:832` "`export CC_CONFIG_HASH`". devcontainer.json reads them: `"dockerfile": "${localEnv:CC_CONFIG_DIR}/Dockerfile"` (empty → `/Dockerfile`), `"CC_EGRESS_PROFILE": "${localEnv:CC_EGRESS_PROFILE}"`, `"CC_CONFIG_HASH": "${localEnv:CC_CONFIG_HASH}"`, and `"source=cc-${localEnv:CC_PROJECT_ID}-claude-config,target=/home/node/.claude,type=volume"` (empty → `cc--claude-config`, the same name for every project run bare). The Dockerfile bakes both args verbatim: `devcontainer-config/Dockerfile:524` "`printf '%s\n' "${CC_EGRESS_PROFILE}" > /etc/cc-egress-profile`", `:526` "`printf '%s\n' "${CC_CONFIG_HASH}" > /etc/cc-config-hash`". The comment above rebuild_hint states the same four effects (`devcontainer-config/cc-isolated.sh:541-547`).

**Evidence:** `devcontainer-config/devcontainer.json` (build.dockerfile, build.args CC_EGRESS_PROFILE/CC_CONFIG_HASH, mounts), `devcontainer-config/Dockerfile:478-529`, `devcontainer-config/cc-isolated.sh:536-552`, `devcontainer-config/cc-isolated.sh:813-832`

---

## Claim 7: "and the launcher's probe never runs"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that `probe_boundary` is invoked only from cc-isolated.sh's main; does not establish anything about devcontainer.json's postStartCommand (init-firewall.sh still runs in a bare recreate).

`probe_boundary` is called only from main's probe and launch paths (`devcontainer-config/cc-isolated.sh:884` "`probe_boundary "$ws"`", and the launch re-probe block from `:907`) (paraphrased — no quote available because claim covers absence of other callers: the probe is a shell function of the launcher, which a bare `devcontainer up` does not execute).

**Evidence:** `devcontainer-config/cc-isolated.sh:880-917`

---

## Claim 8: "see the 'newly registered profile has no effect' row below"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the target row's existence, position and subject; does not establish that row's wider claims.

`guides/cc-isolated-usage.md:941`: "| A newly registered profile has no effect — the container's egress is still base-only (`/etc/cc-egress-profile` empty, `/etc/cc-config-hash` empty, ..." — six rows below line 935 in the same table, explaining both base-only egress and the empty hash.

**Evidence:** `guides/cc-isolated-usage.md:922-943`

---

## Claim 9: "`CLAUDE_CODE_VERSION=latest` is resolved when the install layer is built"

**Location:** `guides/devcontainer-setup.md:387-388`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the arg value and its single use in the npm install layer; does not establish npm's resolution of the `latest` dist-tag at runtime.

`devcontainer-config/Dockerfile:19` "`ARG CLAUDE_CODE_VERSION=latest`"; devcontainer.json passes `"CLAUDE_CODE_VERSION": "latest"`; `devcontainer-config/Dockerfile:403` "`RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}`".

**Evidence:** `devcontainer-config/Dockerfile:19`, `devcontainer-config/Dockerfile:403`, `devcontainer-config/devcontainer.json` (build.args)

---

## Claim 10: "Docker reuses that cached layer on later rebuilds until something above it in the Dockerfile changes (the base image, the apt list, a toolchain version, `TZ`, or a pruned build cache)"

**Location:** `guides/devcontainer-setup.md:388-390`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the position of each named input relative to `Dockerfile:403`; does not establish Docker cache behaviour on the user's host (no build run) or whether the devcontainer CLI ever pulls a newer base image.

Each named Dockerfile input sits above :403: `FROM node:22` (`:14`), `ARG TZ` / `ENV TZ="$TZ"` (`:16-17`), the apt list (`:22-46`, also `:198`, `:223`), and the toolchain version args `GIT_DELTA_VERSION` (`:89`), `UV_VERSION` (`:115`), `SHFMT_VERSION` (`:168`), `ANDROID_*` (`:235-238`), `RUSTUP_VERSION`/`RUST_VERSION` (`:300-301`), `DOTNET_SDK_VERSION` (`:354`), `ZSH_IN_DOCKER_VERSION` (`:393`). Two imprecisions: (a) the Lean toolchain inputs are *below* the install layer — `devcontainer-config/Dockerfile:451` "`ARG ELAN_VERSION=v4.2.4`", `:454` "`ARG LEAN_TOOLCHAINS=""`" — so "a toolchain version" does not hold for elan/Lean, whose change does not reinstall CC; (b) "a pruned build cache" is not something "in the Dockerfile" that changes; it is a separate cache-loss cause grouped under that heading. Precise version: "until a Dockerfile input above it changes (the base image, the apt list, a toolchain version other than elan/Lean, `TZ`), or the build cache is pruned." The mechanism (cached layer, invalidated by earlier inputs) and conclusion (CC is not refreshed by an ordinary rebuild) are right; 258f9ec4's Notes already call the list "examples, not exhaustive".

**Evidence:** `devcontainer-config/Dockerfile:14-46`, `devcontainer-config/Dockerfile:89-403`, `devcontainer-config/Dockerfile:451-471`

---

## Claim 11: "nothing in the launcher passes `--build-no-cache`"

**Location:** `guides/devcontainer-setup.md:390-391`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every file in devcontainer-config/ (launcher, install.sh, devcontainer.json); does not establish devcontainer CLI defaults (e.g. whether it ever adds `--pull`).

`rg -n 'no-cache|build-no-cache|--pull' devcontainer-config/` returned no hits outside untracked `.env*` files (paraphrased — no quote available because claim covers absence of code). Every `devcontainer up` call is `devcontainer up [--remove-existing-container] "${dc[@]}"` with `dc` holding only `--workspace-folder`, `--override-config`, `--id-label` (`devcontainer-config/cc-isolated.sh:834-836`).

**Evidence:** `devcontainer-config/cc-isolated.sh:834-836`, `devcontainer-config/cc-isolated.sh:883`, `devcontainer-config/cc-isolated.sh:887`, `devcontainer-config/cc-isolated.sh:895`

---

## Claim 12: "the egress profile and the config hash are the *last* layer in the Dockerfile, so projects on different profiles still share every heavy layer"

**Location:** `guides/devcontainer-setup.md:391-392`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that both args are declared and first used in the per-project tail after every toolchain layer; does not establish that the tail is literally one layer (it is several COPY/RUN layers).

`devcontainer-config/Dockerfile:473` "`# --- Everything below is per-project. Keep it LAST. ---`", `:478` "`ARG CC_EGRESS_PROFILE=""`", `:484` "`ARG CC_CONFIG_HASH=""`", baked at `:524-527`. The tail is several layers (COPYs `:486-500`, RUN `:515-529`), so "layer" is loose but the sharing conclusion holds.

**Evidence:** `devcontainer-config/Dockerfile:473-531`

---

## Claim 13: "A re-bless changes the baked config hash, so the next launch of each project recreates its container automatically"

**Location:** `guides/devcontainer-setup.md:393-394`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the launch path's hash comparison and recreate; does not establish that a re-bless of byte-identical config changes the hash.

```bash
# devcontainer-config/cc-isolated.sh:887-896
  devcontainer up "${dc[@]}"
  ...
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
  fi
```
(excerpt elides comment lines :889-891; enclosing main continues to the exit scan — read.) `CC_CONFIG_HASH="$(blessed_hash)"` (`:831`).

**Evidence:** `devcontainer-config/cc-isolated.sh:829-832`, `devcontainer-config/cc-isolated.sh:887-896`

---

## Claim 14: "that reinstalls CC only when the re-blessed change sits above the install layer"

**Location:** `guides/devcontainer-setup.md:394-395`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the hash arg that always changes on a re-bless is declared below :403, so it alone cannot invalidate the install layer; does not establish host cache state (a pruned cache also reinstalls, per Claim 10).

`CC_CONFIG_HASH` is declared at `devcontainer-config/Dockerfile:484`, below `:403`; Docker ARG cache invalidation starts at the arg's first use, so the install layer is reused unless an input above it changed (paraphrased — no quote available because this is Docker build-cache semantics, not repo code).

**Evidence:** `devcontainer-config/Dockerfile:403`, `devcontainer-config/Dockerfile:478-484`

---

## Claim 15: "Newer CC versions arrive through Claude Code's own auto-update inside the container, or `claude update` there (see the auto-update row in `cc-isolated-usage.md`'s troubleshooting table)"

**Location:** `guides/devcontainer-setup.md:395-397`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the row's existence and the static preconditions for in-container npm auto-update (node-owned prefix, registry allowlisted, no updater disable flag); does not establish (needs a live container) that auto-update succeeds.

The row exists: `guides/cc-isolated-usage.md:940` "| Claude Code auto-update fails every launch in ONE project ... then `claude update`. |". Preconditions: `devcontainer-config/Dockerfile:69-70` "`mkdir -p /usr/local/share/npm-global && chown -R node:node /usr/local/share/npm-global`", `:382` "`ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global`", `devcontainer-config/egress/base.txt:82` "`registry.npmjs.org`". No `DISABLE_AUTOUPDATER` in devcontainer.json containerEnv (paraphrased — no quote available because claim covers absence: grep returned no hits).

**Evidence:** `guides/cc-isolated-usage.md:940`, `devcontainer-config/Dockerfile:69-70`, `devcontainer-config/Dockerfile:379-383`, `devcontainer-config/egress/base.txt:47-48`, `devcontainer-config/egress/base.txt:82`

---

## Claim 16: "a recreated container starts again from the image's version"

**Location:** `guides/devcontainer-setup.md:397-398`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the npm-global install path, which is in the container's writable layer and on no volume; does not establish whether a CC native-installer path writing under `/home/node/.claude` (a volume) could persist a newer binary across recreates.

The only volumes are `/commandhistory` and `/home/node/.claude` (devcontainer.json `"mounts"`), while CC lives under `/usr/local/share/npm-global` (`devcontainer-config/Dockerfile:382`), which `--remove-existing-container` discards with the container.

**Evidence:** `devcontainer-config/devcontainer.json` (mounts), `devcontainer-config/Dockerfile:382-403`

---

## Claim 17: "`cc-isolated --probe-only <repo>` (always recreates it from the blessed config and re-probes), then `cc-isolated <repo>`"

**Location:** `guides/devcontainer-setup.md:398-400`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Same as Claim 5 ("always" holds: the probe branch has no condition before `--remove-existing-container`); does not establish success on a host.

See Claim 5: `devcontainer-config/cc-isolated.sh:881-883` "`# --probe-only is the verification command, so it always rebuilds` ... `devcontainer up --remove-existing-container "${dc[@]}"`".

**Evidence:** `devcontainer-config/cc-isolated.sh:880-885`, `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 18: Bare form effects "base-only egress, an empty config hash, a `~/.claude` volume shared across projects, and a build pointed at `/Dockerfile`), and the launcher's probe never runs (see the comment above `rebuild_hint` in `cc-isolated.sh`)"

**Location:** `guides/devcontainer-setup.md:400-405`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four effects (per Claims 6-7) and that the cited comment exists above `rebuild_hint` and names them; does not establish co-occurrence in a fully bare run (see Claim 6), and the comment does not itself state "the probe never runs".

```bash
# devcontainer-config/cc-isolated.sh:542-547
# run from your own shell therefore resolves them all to the EMPTY string: an empty
# CC_EGRESS_PROFILE/CC_CONFIG_HASH bakes base-only egress and an empty
# /etc/cc-config-hash (a silently NARROWER boundary — ...
# CC_PROJECT_ID mounts the SHARED `cc--claude-config` volume; an empty CC_CONFIG_DIR
# points the build at /Dockerfile.
```
(excerpt elides :545-546; enclosing comment block runs :534-556 — read; `rebuild_hint()` starts :557.)

**Evidence:** `devcontainer-config/cc-isolated.sh:534-567`

---

## Claim 19: "Staleness >1 version for >2 weeks is a decision-015 Revisit trigger"

**Location:** `guides/devcontainer-setup.md:405-406`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the trigger text in decision 015; does not establish whether the trigger is currently tripped.

`docs/decisions/015-cc-process-isolation-docker-devcontainer.md:57`: "| **Revisit** | ... or image staleness pins CC >1 version behind for >2 weeks |".

**Evidence:** `docs/decisions/015-cc-process-isolation-docker-devcontainer.md:57`

---

## Claim 20: Commit 330138d8: the PROBE FAIL row now matches "init-firewall.sh's hint (fc3bff82)"; "Line 58 of cc-isolated-usage.md describes what the launcher does itself"; "Last verified" dates not bumped

**Location:** commit 330138d8 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three factual statements; its "points at the row below" wording is superseded by 258f9ec4 (B1/B4) and verdicted there; does not establish its Notes' re-check completeness (already corrected by 9e0ff1a5 A5).

The hint was introduced by 48a8200b ("fix(devcontainer): point init-firewall's fail-closed hint at the launcher"), an ancestor of merge fc3bff82 (`git merge-base --is-ancestor` succeeded). `guides/cc-isolated-usage.md:57-59` is launcher step 5: "If the running container's baked hash is not the blessed one ..., recreate it with `--remove-existing-container`." Last-verified lines remain `2026-09-09` (`guides/devcontainer-setup.md:3`) and `2026-09-27` (`guides/cc-isolated-usage.md:3`).

**Evidence:** `devcontainer-config/init-firewall.sh:343-350`, `guides/cc-isolated-usage.md:3`, `guides/cc-isolated-usage.md:57-59`, `guides/devcontainer-setup.md:3`

---

## Claim 21: Commit 9e0ff1a5: "no --build-no-cache anywhere in the launcher"; "rebuild_hint in cc-isolated.sh:560 says a plain launch rebuilds"; C1 "devcontainer-setup.md cites the comment above rebuild_hint"

**Location:** commit 9e0ff1a5 message
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers these three statements; its "a re-bless recreates from cached layers" (unqualified) is corrected by 258f9ec4 B4 and the guide now carries the qualifier (Claim 14); does not establish the deferred A4 fix.

`devcontainer-config/cc-isolated.sh:560`: "`echo "    cc-isolated $(printf '%q' "$ws")        # the supported path: rebuilds, re-probes, re-launches" >&2`" — a plain launch rebuilds only on a hash mismatch (`:893-896`), so A4's description is accurate. `--build-no-cache`: see Claim 11. The citation: `guides/devcontainer-setup.md:405` "comment above `rebuild_hint`".

**Evidence:** `devcontainer-config/cc-isolated.sh:557-567`, `devcontainer-config/cc-isolated.sh:887-896`, `guides/devcontainer-setup.md:405`

---

## Claim 22: Commit 258f9ec4: B1 target row "six rows away"; B2 four effects in both guides; B3 qualifier list "names the inputs above Dockerfile:403 ... (TZ arg, apt list, toolchain version args, base image, pruned cache)"; B4 "330138d8 called the pointer 'the row below', and 9e0ff1a5 said 'a re-bless recreates from cached layers'"

**Location:** commit 258f9ec4 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers row distance (935 → 941), presence of all four effects in both guides, and the quoted wording of the earlier commit bodies; the B3 list's elan/Lean and "pruned cache is not above :403" imprecision is carried by Claim 10, which the Notes' "examples, not exhaustive" partly anticipates.

Row distance: PROBE FAIL at `guides/cc-isolated-usage.md:935`, target at `:941`. Both guides list the four effects (`guides/cc-isolated-usage.md:935`, `guides/devcontainer-setup.md:403-404`). 330138d8's body reads "points at the row below that explains why the bare form bakes base-only egress"; 9e0ff1a5's reads "a re-bless recreates from cached layers" (paraphrased — no quote available because these are commit bodies, read via `git log -3 --format=%B`, not files).

**Evidence:** `guides/cc-isolated-usage.md:935-941`, `guides/devcontainer-setup.md:387-406`, `devcontainer-config/Dockerfile:14-403`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 10** (`guides/devcontainer-setup.md:388-390`): the example list falls under "something above it in the Dockerfile changes", but elan/Lean versions (`Dockerfile:451-454`) sit *below* the install layer, and "a pruned build cache" is not a Dockerfile input. To tighten: "until a Dockerfile input above it changes (base image, apt list, a toolchain version other than elan/Lean, `TZ`), or the build cache is pruned".

### Unverifiable
(none). Residues needing a host run are named in the Scope fields of Claims 5, 6, 15, 16 and 18.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report on the diff saved to the given path, structured per the code-fact-check skill.
- Answered: 22 claims checked across all six doc files and three commit messages, including the six focus areas. Result: 21 Verified, 1 Mostly accurate (Claim 10, the cached-layer example list), 0 Stale, 0 Incorrect, 0 Unverifiable.
- Out of scope: review artifacts under docs/reviews/, and the deferred script items (A4: rebuild_hint "rebuilds" at cc-isolated.sh:560; C3; C4: init-firewall.sh:343-345 says "rebuilds"). These were read only to check whether they are consistent with the guides. No host or docker run was done.
- Escalate: none. Claim 10 can be fixed with a one-line wording change, or accepted as is under the "examples, not exhaustive" note in 258f9ec4.
