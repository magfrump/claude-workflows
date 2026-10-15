Commit: 258f9ec4

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-doc-drift (branch fix/doc-drift-cycle1)
**Scope:** `git diff main...HEAD` doc changes (AGENTS.md, GEMINI.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md; review artifacts under docs/reviews/ excluded) plus the commit messages of 330138d8, 9e0ff1a5, 258f9ec4. Iteration 3 of 3, replicate r3.
**Checked:** 2026-10-15
**Total claims checked:** 26
**Summary:** 22 verified, 2 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read before checking; no claim below matches a logged pattern (every named symbol, row, flag and file was found by grep).

The brief's `Status: open -> done` change is a status marker, not a checkable claim about code, and is not verdicted.

---

## Claim 1: AGENTS.md dev-cycle row content

> "User-started outer loop over research-plan-implement and pr-prep: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then build briefs for its top items; as orchestrator it also collects, lands and dispatches build loops. Questions for the user go to `docs/working/questions.md`."

**Location:** `AGENTS.md:36`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement of the row's trigger phrases, step list, roadmap path, questions path and orchestrator half with global row 12 and skills/dev-cycle/SKILL.md; does not establish that the row is a complete list of the skill's steps (step 0 "digest" and step 9 "record" are folded/omitted, as in row 12).

Global row 12 carries the same trigger keywords and step list: `global-instructions/CLAUDE.md:32` — "The outer loop over rows 6/9: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then writes build briefs for its top items. User-started, no timer. Output is triage in `docs/working/questions.md`." Rows 6 and 9 are research-plan-implement and pr-prep in the same table. The orchestrator half matches the skill description `skills/dev-cycle/SKILL.md:4` — "then as orchestrator collect build-loop results, write build briefs into free slots, record and land, and dispatch build loops", and its section headings `### 7. Collect` (:548), `### 9. Record and land` (:671), `### 10. Dispatch` (:758). The roadmap path is in the skill: `skills/dev-cycle/SKILL.md:502` — "Update `docs/roadmap.md`, creating it from this template if missing". `questions.md` appears 5 times in the skill (paraphrased — no quote available because the count comes from `grep -c 'questions.md'`, not one snippet).

**Evidence:** `AGENTS.md:36`, `global-instructions/CLAUDE.md:32`, `skills/dev-cycle/SKILL.md:4`, `skills/dev-cycle/SKILL.md:502`, `skills/dev-cycle/SKILL.md:548-758`

---

## Claim 2: AGENTS.md and GEMINI.md rows are kept in sync

> commit 330138d8: "AGENTS.md, GEMINI.md: add a dev-cycle row to the Skills table, in sync."

**Location:** `AGENTS.md:36`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers byte-identity of the two Skills tables (lines 25-45) and the repo's own sync test and cross-reference checks; does not establish the semantic accuracy of the row (Claim 1 covers that).

`diff <(sed -n 25,45p AGENTS.md) <(sed -n 25,45p GEMINI.md)` printed nothing and `SAME` (paraphrased — no quote available because the evidence is an empty diff). The health check run includes `ok 1 AGENTS.md and GEMINI.md content is in sync (ignoring headers)` and `✓ All MD files reference the same workflows` (quoted from the captured log).

Execution provenance: command `timeout 300 bash scripts/health-check.sh`, cwd `/workspace/.claude/wt-doc-drift`, started 2026-10-15T07:46:34Z, exit code 1 (`Some checks failed.`; `exit=1` appended as the log's last line). The single failure is `not ok 972 a copy with this checkout's bytes under a linked directory is read, so its real path is projected (U2b3b2c; i1 security F2)` in the fast bats suites (log line 1174), a test of an import walker that this doc-only diff does not touch; the sync and cross-reference checks quoted above passed. Whether test 972 also fails on main was not checked.

**Evidence:** `AGENTS.md:25-45`, `GEMINI.md:25-45`, `scripts/health-check.sh:50-63`, /home/node/.claude/jobs/00bcf178/tmp/doc-drift/health-check-i3-r3-fc.log

---

## Claim 3: guides/README.md index line

> "the `--probe`/`--bless` boundary checks, the exit scan of host-git inputs when a session ends, and `cc-push` for pushing a session's commits via a host-only clone."

**Location:** `guides/README.md:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that cc-isolated-usage.md has an exit-scan section and a cc-push section matching the description; does not establish that the index line lists every section of the guide.

`guides/cc-isolated-usage.md:185` — "## Pushing: cc-push"; `guides/cc-isolated-usage.md:302-305` — "### The exit scan is a tripwire … `cc-isolated` also snapshots, before the session, what host git reads to decide what to run, compares when claude exits". The host-only clone is cc-push's mechanism: `devcontainer-config/cc-push.sh:18` — "#   --clone DIR      the host-only clone".

**Evidence:** `guides/cc-isolated-usage.md:185`, `guides/cc-isolated-usage.md:302-312`, `devcontainer-config/cc-push.sh:13-20`, `devcontainer-config/cc-push.sh:52-67`

---

## Claim 4: PROBE FAIL row launcher recipe

> "recreate it from the host with the launcher: `cc-isolated --probe-only <repo>` (recreates the container from the blessed config and re-probes), then `cc-isolated <repo>`."

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the probe action's unconditional `--remove-existing-container` and probe, with the launcher-set variables exported first, and consistency with init-firewall.sh's hint; does not establish that the recreate succeeds on a given host (pre-checks such as `check_manifest` and the host-tool gate can refuse first) — no container was started.

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

The variables are exported before this point (`cc-isolated.sh:821` — "export CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR"; `:831-832` — `CC_CONFIG_HASH="$(blessed_hash)"` / `export CC_CONFIG_HASH`). init-firewall.sh gives the same two-step recipe:

```bash
# devcontainer-config/init-firewall.sh:347-350
    echo "       If this container can no longer bootstrap, recreate it from the HOST" >&2
    echo "       with the launcher (the ~/.claude volume and the repo are unaffected):" >&2
    echo "         cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes" >&2
    echo "         cc-isolated <repo>                 # then start the session" >&2
```
(excerpt ends :350; enclosing fail_closed_on_abort() continues to :352 — read)

**Evidence:** `devcontainer-config/cc-isolated.sh:813-832`, `devcontainer-config/cc-isolated.sh:880-886`, `devcontainer-config/init-firewall.sh:335-352`

---

## Claim 5: bare-form effects and probe (cc-isolated-usage.md)

> "it drops the variables the launcher exports, and each one dropped has its own effect (among them base-only egress and an empty config hash, … a `~/.claude` volume shared across projects; and a build pointed at `/Dockerfile`), and the launcher's probe never runs."

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the per-variable consequence of each localEnv read resolving empty, per devcontainer.json and the rebuild_hint comment; does not establish what a fully bare run does end-to-end (an empty CC_CONFIG_DIR may make the build fail before anything is baked — see Claim 26), which "among them … each one dropped has its own effect" does not assert.

```jsonc
// devcontainer-config/devcontainer.json:25-26, 50, 54, 79
    "dockerfile": "${localEnv:CC_CONFIG_DIR}/Dockerfile",
    "context": "${localEnv:CC_CONFIG_DIR}",
      "CC_EGRESS_PROFILE": "${localEnv:CC_EGRESS_PROFILE}",
      "CC_CONFIG_HASH": "${localEnv:CC_CONFIG_HASH}"
    "source=cc-${localEnv:CC_PROJECT_ID}-claude-config,target=/home/node/.claude,type=volume"
```

The rationale comment states all four: `cc-isolated.sh:542-547` — "an empty CC_EGRESS_PROFILE/CC_CONFIG_HASH bakes base-only egress and an empty /etc/cc-config-hash … an empty CC_PROJECT_ID mounts the SHARED `cc--claude-config` volume; an empty CC_CONFIG_DIR points the build at /Dockerfile." `probe_boundary` is called only from the launcher's main (`cc-isolated.sh:884`, `:902`, `:917`), so a bare `devcontainer up` runs no probe (paraphrased — no quote available because the claim covers absence of a probe call outside cc-isolated.sh's main path).

**Evidence:** `devcontainer-config/devcontainer.json:20-28`, `devcontainer-config/devcontainer.json:50-54`, `devcontainer-config/devcontainer.json:73-80`, `devcontainer-config/cc-isolated.sh:534-567`, `devcontainer-config/cc-isolated.sh:880-918`

---

## Claim 6: pointer to the "newly registered profile has no effect" row below

> "see the "newly registered profile has no effect" row below"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers existence, position and relevance of the named row; does not establish anything about the rows between.

`guides/cc-isolated-usage.md:941` — "| A newly registered profile has no effect — the container's egress is still base-only (`/etc/cc-egress-profile` empty, `/etc/cc-config-hash` empty, …) | The container was rebuilt with a bare `devcontainer up --remove-existing-container …` from your own shell." Line 941 is in the same table (921-942), six rows below line 935.

**Evidence:** `guides/cc-isolated-usage.md:921-942`

---

## Claim 7: CC version resolved at install-layer build; cached reuse until something above changes; named inputs

> "`CLAUDE_CODE_VERSION=latest` is resolved when the install layer is built, and Docker reuses that cached layer on later rebuilds until something above it in the Dockerfile changes (the base image, the apt list, a toolchain version, `TZ`, or a pruned build cache)"

**Location:** `guides/devcontainer-setup.md:387-390`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that every named input sits above the install layer at Dockerfile:403 and that no COPY or per-project arg precedes it; does not establish an exhaustive list (any other edit above :403, a changed CLAUDE_CODE_VERSION value, or editing :403 itself also invalidates — the commit Notes call the list examples), and does not establish Docker's cache behaviour by execution (no docker allowed).

```dockerfile
# devcontainer-config/Dockerfile:14-22
FROM node:22

ARG TZ
ENV TZ="$TZ"

ARG CLAUDE_CODE_VERSION=latest

# Install basic development tools and iptables/ipset
RUN apt-get update && apt-get install -y --no-install-recommends \
```
(excerpt ends :22; the apt RUN continues to :46 — read)

`devcontainer-config/Dockerfile:403` — "RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}". Further apt lists at `:198` and `:223`; toolchain version args above :403 include `ARG GIT_DELTA_VERSION=0.18.2` (:89), `ARG UV_VERSION=0.11.28` (:115), `ARG SHFMT_VERSION=3.13.1` (:168), `ARG RUST_VERSION=1.83.0` (:301), `ARG DOTNET_SDK_VERSION=10.0.400` (:354). The first COPY is `:486` (`COPY egress/ /usr/local/share/cc-egress/`), below the install layer. TZ's value comes from the host: `devcontainer.json:28` — `"TZ": "${localEnv:TZ:America/Los_Angeles}"`. (ELAN/LEAN args at :451-454 are below :403 and correctly not named.)

**Evidence:** `devcontainer-config/Dockerfile:14-46`, `devcontainer-config/Dockerfile:89-403`, `devcontainer-config/Dockerfile:451-486`, `devcontainer-config/devcontainer.json:27-49`

---

## Claim 8: nothing in the launcher passes --build-no-cache

> "nothing in the launcher passes `--build-no-cache`"

**Location:** `guides/devcontainer-setup.md:390-391`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers cc-isolated.sh's devcontainer invocations (and install.sh, checked additionally); does not establish that the host's Docker never prunes its build cache on its own.

`grep -n 'no-cache\|build-no-cache\|--pull\|rmi\|prune' devcontainer-config/cc-isolated.sh` returned no hits (paraphrased — no quote available because the claim covers absence of code). The only `devcontainer up` calls are `cc-isolated.sh:883`, `:888`, `:895`, with flags `--remove-existing-container` and `"${dc[@]}"` = `--workspace-folder`, `--override-config`, `--id-label` (`:834-836`). install.sh's only "prune" hits are backup-directory pruning (`install.sh:1065-1088`).

**Evidence:** `devcontainer-config/cc-isolated.sh:834-836`, `devcontainer-config/cc-isolated.sh:883-895`, `devcontainer-config/install.sh:1065-1088`

---

## Claim 9: egress profile and config hash are the last layer

> "the egress profile and the config hash are the *last* layer in the Dockerfile, so projects on different profiles still share every heavy layer."

**Location:** `guides/devcontainer-setup.md:391-392`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the position of the two ARGs and their consuming RUN in the per-project tail; does not establish image-sharing on a real host (not executed).

`devcontainer-config/Dockerfile:473-478` — "# --- Everything below is per-project. Keep it LAST. … ARG CC_EGRESS_PROFILE=\"\"", `:484` — `ARG CC_CONFIG_HASH=""`, consumed at `:524-526` (`printf '%s\n' "${CC_EGRESS_PROFILE}" > /etc/cc-egress-profile` … `"${CC_CONFIG_HASH}" > /etc/cc-config-hash`), which is in the file's final RUN (:515-529).

**Evidence:** `devcontainer-config/Dockerfile:473-529`

---

## Claim 10: a re-bless recreates each project's container on next launch

> "A re-bless changes the baked config hash, so the next launch of each project recreates its container automatically"

**Location:** `guides/devcontainer-setup.md:393-394`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the launch path's hash comparison and recreate; does not establish `container_config_matches`' internals beyond its comment (read at :569-575 region) or behaviour on a live host.

```bash
# devcontainer-config/cc-isolated.sh:888-896
  devcontainer up "${dc[@]}"

  # `devcontainer up` never rebuilds an existing container. If the config was
  # re-blessed since this one was built, it is running the previous boundary;
  # recreate it (the ~/.claude volume and the repo are unaffected).
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
  fi
```

**Evidence:** `devcontainer-config/cc-isolated.sh:569-575`, `devcontainer-config/cc-isolated.sh:831-832`, `devcontainer-config/cc-isolated.sh:888-896`

---

## Claim 11: re-bless reinstalls CC only when the change sits above the install layer

> "that reinstalls CC only when the re-blessed change sits above the install layer."

**Location:** `guides/devcontainer-setup.md:394-395`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the re-bless's own input (CC_CONFIG_HASH) is declared below :403 so a hash-only change leaves the install layer cached; does not establish Docker cache semantics by execution, and "above" loosely includes an edit to :403 itself or to the CLAUDE_CODE_VERSION value (declared at :19).

The hash ARG is declared after the install layer: `Dockerfile:484` — `ARG CC_CONFIG_HASH=""` vs `Dockerfile:403` — `RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}`. Docker invalidates a cached layer only when its instruction, its inputs, or a parent layer change; build args not yet declared are not inputs (paraphrased — no quote available because this is Docker builder semantics, not repo code). Medium because not executed.

**Evidence:** `devcontainer-config/Dockerfile:403`, `devcontainer-config/Dockerfile:478-484`

---

## Claim 12: the auto-update row exists in cc-isolated-usage.md's troubleshooting table

> "(see the auto-update row in `cc-isolated-usage.md`'s troubleshooting table)"

**Location:** `guides/devcontainer-setup.md:397-398`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers existence of the row and that it concerns auto-update and `claude update`; does not establish the row's own fix.

`guides/cc-isolated-usage.md:940` — "| Claude Code auto-update fails every launch in ONE project (`.last-update-result.json` shows `install_failed`; …) | … then `claude update`. |"

**Evidence:** `guides/cc-isolated-usage.md:940`

---

## Claim 13: newer CC versions arrive through in-container auto-update or `claude update`

> "Newer CC versions arrive through Claude Code's own auto-update inside the container, or `claude update` there"

**Location:** `guides/devcontainer-setup.md:395-397`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the static preconditions (node-writable npm prefix, registry allowlisted, no updater-disable env); does not establish that the updater actually runs and succeeds in a live container — execution required, blocked by the brief's no-docker rule.

Preconditions hold: `Dockerfile:69-70` — "RUN mkdir -p /usr/local/share/npm-global && \ chown -R node:node /usr/local/share/npm-global"; `Dockerfile:382` — "ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global"; `egress/base.txt:81-82` — "# Node toolchain — CC is an npm package and self-updates from here. / registry.npmjs.org". `grep -rni 'autoupdat\|DISABLE_AUTO' devcontainer-config/` found no updater-disable setting (paraphrased — no quote available because the claim covers absence of code). The auto-update failure row (Claim 12) records the updater having run in a project. Blocker: verifying a live update needs a running container (docker forbidden in this review).

**Evidence:** `devcontainer-config/Dockerfile:69-70`, `devcontainer-config/Dockerfile:382-383`, `devcontainer-config/egress/base.txt:81-82`, `devcontainer-config/devcontainer.json:82-131`, `guides/cc-isolated-usage.md:940`

---

## Claim 14: a recreated container starts again from the image's version

> "a recreated container starts again from the image's version."

**Location:** `guides/devcontainer-setup.md:398-399`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the npm global prefix CC updates into is in the container's writable layer, not a volume; does not establish where a non-npm (native) updater would write (CC here is npm-installed), and was not executed.

The only volumes are `devcontainer.json:78-79` — "target=/commandhistory" and "target=/home/node/.claude"; the install prefix is `/usr/local/share/npm-global` (`Dockerfile:382`), so an in-container update is discarded on `--remove-existing-container` (paraphrased — no quote available because the conclusion is inferred from the absence of a mount for that path).

**Evidence:** `devcontainer-config/devcontainer.json:73-80`, `devcontainer-config/Dockerfile:382`

---

## Claim 15: by-hand recreate recipe in devcontainer-setup.md

> "To recreate a container by hand, use the launcher: `cc-isolated --probe-only <repo>` (always recreates it from the blessed config and re-probes), then `cc-isolated <repo>`."

**Location:** `guides/devcontainer-setup.md:399-401`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Same as Claim 4 (unconditional `--remove-existing-container` + probe in the probe action); "always" holds once the launcher's pre-checks pass — does not establish behaviour when check_manifest or the host-tool gate refuses.

`devcontainer-config/cc-isolated.sh:881-884` — "# --probe-only is the verification command, so it always rebuilds … devcontainer up --remove-existing-container \"${dc[@]}\" / probe_boundary \"$ws\"". Consistent with `init-firewall.sh:346` — "# --probe-only always rebuilds from the blessed config and re-probes."

**Evidence:** `devcontainer-config/cc-isolated.sh:880-886`, `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 16: bare-form effects and probe (devcontainer-setup.md)

> "it drops the variables the launcher exports, and each one dropped has its own effect (among them base-only egress, an empty config hash, a `~/.claude` volume shared across projects, and a build pointed at `/Dockerfile`), and the launcher's probe never runs"

**Location:** `guides/devcontainer-setup.md:401-405`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Same evidence and residue as Claim 5; the two guides now list the same four effects.

`devcontainer-config/cc-isolated.sh:542-547` — "an empty CC_EGRESS_PROFILE/CC_CONFIG_HASH bakes base-only egress and an empty /etc/cc-config-hash … an empty CC_PROJECT_ID mounts the SHARED `cc--claude-config` volume; an empty CC_CONFIG_DIR points the build at /Dockerfile."

**Evidence:** `devcontainer-config/cc-isolated.sh:534-567`, `devcontainer-config/devcontainer.json:25-26`, `devcontainer-config/devcontainer.json:50-54`, `devcontainer-config/devcontainer.json:78-79`

---

## Claim 17: the comment above rebuild_hint holds the rationale

> "(see the comment above `rebuild_hint` in `cc-isolated.sh`)"

**Location:** `guides/devcontainer-setup.md:405`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers existence of the comment and that it explains why the bare form is harmful; does not endorse rebuild_hint's printed text (its line 560 says a plain launch "rebuilds", deferred finding A4/C4).

`devcontainer-config/cc-isolated.sh:537` — "# WHY THIS IS NOT A BARE `devcontainer up` STRING." directly above `rebuild_hint() {` at `:557`.

**Evidence:** `devcontainer-config/cc-isolated.sh:534-567`

---

## Claim 18: decision-015 Revisit trigger

> "Staleness >1 version for >2 weeks is a decision-015 Revisit trigger."

**Location:** `guides/devcontainer-setup.md:405-406`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the decision record's Revisit row; does not establish whether the trigger currently fires.

`docs/decisions/015-cc-process-isolation-docker-devcontainer.md:57` — "| **Revisit** | … or image staleness pins CC >1 version behind for >2 weeks |".

**Evidence:** `docs/decisions/015-cc-process-isolation-docker-devcontainer.md:57`

---

## Claim 19: 330138d8 — matches init-firewall.sh's hint (fc3bff82)

> "matching init-firewall.sh's hint (fc3bff82)"

**Location:** commit 330138d8
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that fc3bff82 (a merge, of 48a8200b) introduced the launcher hint in init-firewall.sh; does not establish anything else that merge changed.

`git diff fc3bff82^1 fc3bff82 -- devcontainer-config/init-firewall.sh` removes `devcontainer up --remove-existing-container --workspace-folder <repo>` and adds `cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes` (quoted from the diff output). `git log -L343,350` attributes the lines to 48a8200b "fix(devcontainer): point init-firewall's fail-closed hint at the launcher" (2026-09-18).

**Evidence:** `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 20: 330138d8 — "points at the row below that explains why the bare form bakes base-only egress"

**Location:** commit 330138d8
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the pointer as written in 330138d8's text; does not re-verdict the current row text (Claim 6).

The target row is below but six rows away (`guides/cc-isolated-usage.md:935` vs `:941`), so the unnamed "row below" read as the adjacent row. Already corrected: 258f9ec4 B1/B4 — "330138d8 called the pointer \"the row below\"" and the row now names its target. Nothing further to fix (commit history is immutable).

**Evidence:** `guides/cc-isolated-usage.md:935`, `guides/cc-isolated-usage.md:941`

---

## Claim 21: 330138d8 Notes — line 58 and Last-verified dates

> "Line 58 of cc-isolated-usage.md describes what the launcher does itself, so it is left as is … The \"Last verified\" dates on the two guides are not bumped"

**Location:** commit 330138d8
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the content of cc-isolated-usage.md:57-59 (unchanged by the branch) and absence of Last-verified edits in the diff; does not assess whether bumping would be warranted.

`guides/cc-isolated-usage.md:57-59` — "5. If the running container's baked hash is not the blessed one (you re-blessed since it was built), recreate it with `--remove-existing-container`. `devcontainer up` alone never rebuilds." — a step in "What a launch does, in order". `git diff main...HEAD -- guides/ | grep -i 'last verified'` is empty (paraphrased — no quote available because the claim covers absence of a diff line).

**Evidence:** `guides/cc-isolated-usage.md:45-60`

---

## Claim 22: 9e0ff1a5 A1 — "a re-bless recreates from cached layers"

**Location:** commit 9e0ff1a5
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the unqualified statement in 9e0ff1a5's body; its "no --build-no-cache anywhere in the launcher" half is Verified (Claim 8).

Correct for a hash-only re-bless (`Dockerfile:484` is below `:403`), but a re-bless whose change sits above :403 rebuilds from that point. Already corrected: 258f9ec4 B4 — "9e0ff1a5 said \"a re-bless recreates from cached layers\" without the qualifier now in the guide."

**Evidence:** `devcontainer-config/Dockerfile:403`, `devcontainer-config/Dockerfile:484`

---

## Claim 23: 9e0ff1a5 — bare form: shared cc--claude-config volume; A4 note on cc-isolated.sh:560

> "the shared cc--claude-config volume" / "A4 (rebuild_hint in cc-isolated.sh:560 says a plain launch rebuilds, which contradicts the guides' recipe for a bricked firewall)"

**Location:** commit 9e0ff1a5
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the volume name and the text at cc-isolated.sh:560 versus main's launch path; does not resolve A4 (deferred, script out of scope).

`devcontainer.json:79` with empty CC_PROJECT_ID yields `cc--claude-config`, as `cc-isolated.sh:546` states. `cc-isolated.sh:560` — `echo "    cc-isolated $(printf '%q' "$ws")        # the supported path: rebuilds, re-probes, re-launches" >&2`; a plain launch recreates only when `container_config_matches` fails (`:893-896`), so in the bricked-firewall case (matching hash) it does not rebuild — the contradiction the note names.

**Evidence:** `devcontainer-config/devcontainer.json:79`, `devcontainer-config/cc-isolated.sh:546`, `devcontainer-config/cc-isolated.sh:557-567`, `devcontainer-config/cc-isolated.sh:888-918`

---

## Claim 24: 258f9ec4 B1 — target row "six rows away"

**Location:** commit 258f9ec4
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the row distance at HEAD; does not establish the distance at 330138d8 (no rows were inserted between by this branch, so it is the same).

PROBE FAIL row at `guides/cc-isolated-usage.md:935`, "A newly registered profile has no effect" row at `:941` (paraphrased — no quote available because the claim is about table layout).

**Evidence:** `guides/cc-isolated-usage.md:935-941`

---

## Claim 25: 258f9ec4 B3/Notes — inputs above Dockerfile:403

> "The qualifier list in B3 names the inputs above Dockerfile:403 … (TZ arg, apt list, toolchain version args, base image, pruned cache); it is a list of examples, not exhaustive."

**Location:** commit 258f9ec4
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Same as Claim 7.

`Dockerfile:403` is the install layer; `FROM node:22` (:14), `ARG TZ` (:16), apt RUNs (:22, :198, :223) and version ARGs (:89-:354) precede it (quoted in Claim 7).

**Evidence:** `devcontainer-config/Dockerfile:14-403`

---

## Claim 26: 258f9ec4 Notes — whether a fully bare `devcontainer up` fails at the build needs a host run

**Location:** commit 258f9ec4
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the hedge itself; does not establish what the devcontainer CLI does with a `/Dockerfile` that is absent.

Static reading supports the hedge: an empty CC_CONFIG_DIR makes `"dockerfile": "${localEnv:CC_CONFIG_DIR}/Dockerfile"` (`devcontainer.json:25`) resolve to `/Dockerfile`, and the comment at `devcontainer.json:14` describes a missing Dockerfile as 'a hard "Dockerfile not found"' for the analogous relative case. Settling it requires running the CLI on a host with docker (forbidden here).

**Evidence:** `devcontainer-config/devcontainer.json:9-26`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 20** (commit 330138d8): "the row below" was six rows away; already corrected by 258f9ec4 (B1, B4). No action.
- **Claim 22** (commit 9e0ff1a5): "a re-bless recreates from cached layers" lacked the above-:403 qualifier; already corrected in the guide and by 258f9ec4 B4. No action.

### Unverifiable
- **Claim 13** (`guides/devcontainer-setup.md:395-397`): live auto-update in the container needs a running container; all static preconditions hold.
- **Claim 26** (commit 258f9ec4 Notes): whether a fully bare `devcontainer up` fails at build needs a host run; the commit says so itself.

No Incorrect verdicts, so no hallucination-pattern entries to add.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report on the diff saved to the given path, structured per the code-fact-check skill.
- Answered: all 26 checkable claims in the doc diff and the three commit messages verdicted (22 Verified, 2 Mostly accurate, 0 Stale, 0 Incorrect, 2 Unverifiable). The six named focus areas all check out against Dockerfile, devcontainer.json, cc-isolated.sh and init-firewall.sh: every named cache input is above Dockerfile:403; nothing passes --build-no-cache; the four bare-form effects and the missing probe match the code; the named row exists six rows below; --probe-only always recreates and re-probes; the index line, dev-cycle row and AGENTS/GEMINI sync hold.
- Out of scope: running docker/devcontainer (forbidden), so live auto-update and the fully bare build's failure mode are left Unverifiable; rebuild_hint's "rebuilds" wording (A4/C4, a deferred script change) is noted but not re-litigated.
- Escalate: nothing. Both Mostly-accurate items are commit-message wording that 258f9ec4 already corrected.
