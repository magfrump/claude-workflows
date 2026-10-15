Commit: 9e0ff1a5

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-doc-drift, branch fix/doc-drift-cycle1)
**Scope:** `git diff main...HEAD` excluding docs/reviews/ (AGENTS.md, GEMINI.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md) plus the commit messages of 330138d8 and 9e0ff1a5
**Checked:** 2026-10-15
**Total claims checked:** 26
**Summary:** 21 verified, 5 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read: its five entries are all count/denominator fabrications in eval tooling and commit test tallies. No claim here matches a logged pattern; the commit messages carry no test counts.

The brief's `Status: open -> done` line is a state change, not a checkable claim, and is not verdicted.

---

## Claim 1: "User-started outer loop over research-plan-implement and pr-prep: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then build briefs for its top items"

**Location:** `AGENTS.md:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step list and trigger phrases against global row 12 and the skill's description; does not establish the skill body's full step numbering (which adds a digest step 0 and steps 7-10 that the row summarises in Claim 2).
**Legibility-target:** for-orchestrator-synthesis

Global row 12 reads `global-instructions/CLAUDE.md:32`: "The outer loop over rows 6/9: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then writes build briefs for its top items. User-started, no timer." Rows 6 and 9 of that table are research-plan-implement and pr-prep, so "over research-plan-implement and pr-prep" is the same statement. The trigger phrases match row 12's keywords and `skills/dev-cycle/SKILL.md:4` ("Triggers: \"run the dev cycle\", \"maintenance pass\", \"what should we work on next\", \"update the roadmap\"").

**Evidence:** `global-instructions/CLAUDE.md:32`, `skills/dev-cycle/SKILL.md:4`

---

## Claim 2: "as orchestrator it also collects, lands and dispatches build loops"

**Location:** `AGENTS.md:36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill's own description of its orchestrator half; does not establish how `scripts/build-loop.sh` behaves.
**Legibility-target:** for-orchestrator-synthesis

`skills/dev-cycle/SKILL.md:4`: "then as orchestrator collect build-loop results, write build briefs into free slots, record and land, and dispatch build loops"; `skills/dev-cycle/SKILL.md:14-15`: "As the orchestrator it also hands those briefs to autonomous build loops, collects their results and lands what `scripts/build-loop.sh` (the" (excerpt ends :15; enclosing paragraph continues — read). The step order at `skills/dev-cycle/SKILL.md:263-264` lists "7 collect → 8 build briefs → 9 record and land → 10 dispatch".

**Evidence:** `skills/dev-cycle/SKILL.md:4`, `skills/dev-cycle/SKILL.md:14-15`, `skills/dev-cycle/SKILL.md:263-264`

---

## Claim 3: "Questions for the user go to `docs/working/questions.md`."

**Location:** `AGENTS.md:36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill's routing of user questions; does not establish the questions-archive handling.
**Legibility-target:** for-orchestrator-synthesis

`skills/dev-cycle/SKILL.md:90-93`: "only real choices become `you: judgment` entries in `docs/working/questions.md` ... Machine-only chores become one `you: terminal` entry." `skills/dev-cycle/SKILL.md:88-89` makes the orchestrator "The only questions writer". Global row 12: "Output is triage in `docs/working/questions.md`."

**Evidence:** `skills/dev-cycle/SKILL.md:88-93`, `global-instructions/CLAUDE.md:32`

---

## Claim 4: AGENTS.md and GEMINI.md dev-cycle rows are in sync

**Location:** `GEMINI.md:36`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers lines 30-40 of both files (the Skills table including the new row); does not establish sync of the rest of the two files.
**Legibility-target:** for-orchestrator-synthesis

`diff <(sed -n 30,40p AGENTS.md) <(sed -n 30,40p GEMINI.md)` printed nothing (paraphrased — no quote available because the claim is the absence of a difference). The diff hunks for the two files add byte-identical lines.

**Evidence:** `AGENTS.md:30-40`, `GEMINI.md:30-40`

---

## Claim 5: "the exit scan of host-git inputs when a session ends, and `cc-push` for pushing a session's commits via a host-only clone"

**Location:** `guides/README.md:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that cc-isolated-usage.md documents both and that the code does what the index line says; does not establish the scan's coverage.
**Legibility-target:** for-orchestrator-synthesis

The launcher's snapshot error says `devcontainer-config/cc-isolated.sh:862-863`: "cc-isolated checks at exit that the session changed nothing host git reads to decide what to run". `devcontainer-config/cc-push.sh:13`: "--remote URL     the real remote, stored in the host-only clone"; `cc-push.sh:67`: "git push origin refs/cc/heads/<branch>:refs/heads/<branch>` from the clone." The usage guide covers cc-push at `guides/cc-isolated-usage.md:28` ("push a session's commits via a host-only clone") and the exit scan at `guides/cc-isolated-usage.md:68`.

**Evidence:** `devcontainer-config/cc-isolated.sh:860-866`, `devcontainer-config/cc-push.sh:13-67`, `guides/cc-isolated-usage.md:28-68`

---

## Claim 6: "recreate it from the host with the launcher: `cc-isolated --probe-only <repo>` (recreates the container from the blessed config and re-probes), then `cc-isolated <repo>`"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the probe action's unconditional recreate, the blessed-hash export, the follow-up launch, and agreement with init-firewall.sh's hint; does not establish that a recreate cures every fail-closed cause (a persistent outage would fail again).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:880-885
  if [ "$action" = "probe" ]; then
    # --probe-only is the verification command, so it always rebuilds: probing a
    # container left over from an earlier config would verify the wrong boundary.
    devcontainer up --remove-existing-container "${dc[@]}"
    probe_boundary "$ws"
    exit 0
```

The hash comes from the blessed manifest after `check_manifest` (`cc-isolated.sh:825-832`: `check_manifest` ... `CC_CONFIG_HASH="$(blessed_hash)"` / `export CC_CONFIG_HASH`). The follow-up `cc-isolated <repo>` runs `devcontainer up "${dc[@]}"` on the fresh container, whose hash matches, then probes (`cc-isolated.sh:887-900`). This matches `devcontainer-config/init-firewall.sh:347-350`: "recreate it from the HOST ... cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes" / "cc-isolated <repo>                 # then start the session".

**Evidence:** `devcontainer-config/cc-isolated.sh:825-832`, `devcontainer-config/cc-isolated.sh:880-900`, `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 7: "it drops the variables the launcher exports, and each one dropped has its own effect (base-only egress and an empty config hash ...; the shared `cc--claude-config` volume), and the launcher's probe never runs"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named effects and the probe's absence; does not establish the effect of the two dropped variables the parenthetical leaves out (CC_CONFIG_DIR, which the rebuild_hint comment says "points the build at /Dockerfile", and CC_PROJECT_NAME), nor whether the empty-CC_CONFIG_DIR build path fails before the other effects land.
**Legibility-target:** for-orchestrator-synthesis

The launcher exports them: `cc-isolated.sh:821` "export CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR" and `:832` "export CC_CONFIG_HASH". devcontainer.json reads them through localEnv: `"CC_EGRESS_PROFILE": "${localEnv:CC_EGRESS_PROFILE}"`, `"CC_CONFIG_HASH": "${localEnv:CC_CONFIG_HASH}"`, and `"source=cc-${localEnv:CC_PROJECT_ID}-claude-config,target=/home/node/.claude,type=volume"` (`devcontainer-config/devcontainer.json`, build.args and mounts) — an empty CC_PROJECT_ID yields `cc--claude-config`. The image bakes the values: `Dockerfile:524-526` `printf '%s\n' "${CC_EGRESS_PROFILE}" > /etc/cc-egress-profile` ... `printf '%s\n' "${CC_CONFIG_HASH}" > /etc/cc-config-hash`. The probe runs only from the launcher (`probe_boundary` is called at `cc-isolated.sh:884` and `:906-916`), so a bare `devcontainer up` never runs it (paraphrased — no quote available because the claim is about absence of a call path).

**Evidence:** `devcontainer-config/cc-isolated.sh:536-549`, `devcontainer-config/cc-isolated.sh:813-832`, `devcontainer-config/devcontainer.json:24-55`, `devcontainer-config/devcontainer.json:77-80`, `devcontainer-config/Dockerfile:478-527`

---

## Claim 8: "(base-only egress and an empty config hash, see the row below; ...)"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cross-reference target; does not establish anything about the target row's content beyond its existence.
**Legibility-target:** for-author

The row that explains base-only egress is at `guides/cc-isolated-usage.md:941` ("A newly registered profile has no effect — the container's egress is still base-only ..."), six rows further down. The row immediately below is `guides/cc-isolated-usage.md:936` ("`OAuth error: getaddrinfo …` at `/login`, launch probe passed"). Precise version: "see the 'A newly registered profile has no effect' row below".

**Evidence:** `guides/cc-isolated-usage.md:935-941`

---

## Claim 9: "`CLAUDE_CODE_VERSION=latest` is resolved when the install layer is built, and Docker reuses that cached layer on later rebuilds"

**Location:** `guides/devcontainer-setup.md:387-388`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the install instruction, its constant build arg, and the absence of a no-cache flag; does not establish that the cache survives an edit above the install line, a changed `TZ`, a pulled base image, or a pruned build cache.
**Legibility-target:** for-author

`devcontainer-config/Dockerfile:403`: `RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}`, with `"CLAUDE_CODE_VERSION": "latest"` a constant in devcontainer.json's build args, so the instruction text does not change between builds and its cache key holds. But every layer above line 403 is an input: `Dockerfile:16-17` `ARG TZ` / `ENV TZ="$TZ"` (TZ comes from `${localEnv:TZ:America/Los_Angeles}`), and the toolchain RUNs between lines 22 and 376 use version build args (DOTNET_SDK_VERSION, RUST_VERSION, ANDROID_*). Changing any of them, or editing the Dockerfile above line 403, re-runs the install and resolves `latest` afresh (paraphrased — no quote available because this is Docker's layer-cache rule applied to the file's layer order, not a single snippet). Precise version: "Docker reuses that cached layer on later rebuilds as long as nothing above it in the Dockerfile changes".

**Evidence:** `devcontainer-config/Dockerfile:14-19`, `devcontainer-config/Dockerfile:376-403`, `devcontainer-config/devcontainer.json:24-29`

---

## Claim 10: "nothing in the launcher passes `--build-no-cache`"

**Location:** `guides/devcontainer-setup.md:388-389`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every file under devcontainer-config/ (launcher, install.sh, cc-push.sh, config); does not establish the devcontainer CLI's own defaults.
**Legibility-target:** for-orchestrator-synthesis

`grep -rn -i 'no-cache\|build-no-cache\|--no-cache' devcontainer-config/` returned no lines (paraphrased — no quote available because the claim is absence of matching code). Both `dc` arrays (`cc-isolated.sh:581`, `:834`) carry only `--workspace-folder`, `--override-config` and `--id-label`.

**Evidence:** `devcontainer-config/cc-isolated.sh:581-583`, `devcontainer-config/cc-isolated.sh:834-836`

---

## Claim 11: "the egress profile and the config hash are the *last* layer in the Dockerfile, so projects on different profiles still share every heavy layer"

**Location:** `guides/devcontainer-setup.md:389-391`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the position of the two ARGs and the RUN that writes them; does not establish cache sharing when projects build on different hosts.
**Legibility-target:** for-orchestrator-synthesis

`Dockerfile:473-478`: "# --- Everything below is per-project. Keep it LAST." ... "ARG CC_EGRESS_PROFILE=\"\"", then `ARG CC_CONFIG_HASH=""` at `:484`; the values are written in the final RUN (`Dockerfile:513-529`, ending `chmod 0440 /etc/sudoers.d/node-firewall`), followed only by `USER node` at `:531`.

**Evidence:** `devcontainer-config/Dockerfile:473-531`

---

## Claim 12: "A re-bless changes the baked config hash, so the next launch of each project recreates its container automatically, from those cached layers."

**Location:** `guides/devcontainer-setup.md:391-393`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the hash-mismatch recreate and the tail-only rebuild when only the hash/profile changed; does not establish the cache when the re-bless follows an install.sh that changed the Dockerfile above line 403.
**Legibility-target:** for-author

The recreate part holds: `cc-isolated.sh:897-900` "if ! container_config_matches "${dc[@]}"; then" / "echo \"Blessed config changed since this container was built — rebuilding it.\"" / "devcontainer up --remove-existing-container "${dc[@]}"". The "from those cached layers" part carries the qualifier of Claim 9: a re-bless often follows `install.sh` after a canonical-config change, and if that change touched the Dockerfile above the install line, the CC layer rebuilds and resolves `latest` again (paraphrased — no quote available because it follows from the layer order quoted in Claim 9). The part carrying the verdict is "from those cached layers".

**Evidence:** `devcontainer-config/cc-isolated.sh:893-900`, `devcontainer-config/Dockerfile:403`, `devcontainer-config/Dockerfile:473-531`

---

## Claim 13: "Newer CC versions arrive through Claude Code's own auto-update inside the container, or `claude update` there (see the auto-update row in `cc-isolated-usage.md`'s troubleshooting table)"

**Location:** `guides/devcontainer-setup.md:393-395`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that nothing in the config disables the updater, the install prefix is node-writable, its registry is allowlisted, and the cited row exists; does not establish Claude Code's updater behaviour itself (external) beyond the repo's own record of it.
**Legibility-target:** for-orchestrator-synthesis

No `DISABLE_AUTOUPDATER` or `autoUpdates` setting exists under devcontainer-config/ or global-instructions/ (paraphrased — no quote available because the claim is absence of a grep match). `Dockerfile:69-70` `RUN mkdir -p /usr/local/share/npm-global && \` / `chown -R node:node /usr/local/share/npm-global`, and `Dockerfile:382` `ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global`; `egress/base.txt:82` `registry.npmjs.org`. The row exists: `guides/cc-isolated-usage.md:940` "Claude Code auto-update fails every launch in ONE project ... Inside the container: `rm -rf /usr/local/share/npm-global/lib/node_modules/@anthropic-ai/.claude-code-*`, then `claude update`."

**Evidence:** `devcontainer-config/Dockerfile:69-70`, `devcontainer-config/Dockerfile:382-383`, `devcontainer-config/egress/base.txt:82`, `guides/cc-isolated-usage.md:940`

---

## Claim 14: "a recreated container starts again from the image's version"

**Location:** `guides/devcontainer-setup.md:396-397`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers where an npm-path auto-update writes (container filesystem, not a volume); does not establish behaviour if Claude Code's updater moved to a native or local install under `/home/node/.claude` (the per-project volume), which would persist across recreates.
**Legibility-target:** for-orchestrator-synthesis

The update target is `/usr/local/share/npm-global` (the row at `guides/cc-isolated-usage.md:940` names `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/`). The only volumes are `"source=cc-${localEnv:CC_PROJECT_ID}-bashhistory,target=/commandhistory,type=volume"` and `"source=cc-${localEnv:CC_PROJECT_ID}-claude-config,target=/home/node/.claude,type=volume"` (`devcontainer.json` mounts), plus the repo bind at `/workspace`. An update in the npm prefix lives in the container's writable layer and is discarded by `--remove-existing-container` (paraphrased — no quote available because it is Docker's container-layer semantics applied to the mount list).

**Evidence:** `devcontainer-config/devcontainer.json:77-80`, `devcontainer-config/devcontainer.json:134`, `guides/cc-isolated-usage.md:940`

---

## Claim 15: "`cc-isolated --probe-only <repo>` (always recreates it from the blessed config and re-probes), then `cc-isolated <repo>`"

**Location:** `guides/devcontainer-setup.md:398-399`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 6; does not establish that a recreate cures a persistent cause.
**Legibility-target:** for-orchestrator-synthesis

`cc-isolated.sh:881-883`: "# --probe-only is the verification command, so it always rebuilds" / "devcontainer up --remove-existing-container "${dc[@]}"", unconditional inside `if [ "$action" = "probe" ]`. See Claim 6 for the full quote and the follow-up launch.

**Evidence:** `devcontainer-config/cc-isolated.sh:880-885`

---

## Claim 16: "it drops the variables the launcher exports, and each one dropped has its own effect (base-only egress, an empty config hash, the shared `cc--claude-config` volume), and the launcher's probe never runs"

**Location:** `guides/devcontainer-setup.md:400-403`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 7, including its residue (CC_CONFIG_DIR and CC_PROJECT_NAME effects not listed).
**Legibility-target:** for-orchestrator-synthesis

`cc-isolated.sh:542-545`: "an empty CC_EGRESS_PROFILE/CC_CONFIG_HASH bakes base-only egress and an empty /etc/cc-config-hash ... an empty CC_PROJECT_ID mounts the SHARED `cc--claude-config` volume". Code backing is quoted in Claim 7.

**Evidence:** `devcontainer-config/cc-isolated.sh:536-549`, `devcontainer-config/devcontainer.json:24-55`

---

## Claim 17: "(see the comment above `rebuild_hint` in `cc-isolated.sh`)"

**Location:** `guides/devcontainer-setup.md:403-404`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the comment exists and holds the bare-form rationale; does not endorse the function body's first line (see Claim 25).
**Legibility-target:** for-orchestrator-synthesis

`cc-isolated.sh:536`: "# WHY THIS IS NOT A BARE `devcontainer up` STRING. devcontainer.json reads" (excerpt ends :536; the comment continues to :555, the function to :565 — read). It names all five variables, their empty-value effects, and the launcher as "the path that cannot get this wrong".

**Evidence:** `devcontainer-config/cc-isolated.sh:533-565`

---

## Claim 18: 330138d8: "matching init-firewall.sh's hint (fc3bff82)"

**Location:** commit 330138d8 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that fc3bff82 brought in the launcher hint; does not establish it as the hint's originating commit (that is 48a8200b, merged by fc3bff82).
**Legibility-target:** for-orchestrator-synthesis

`git show fc3bff82 --first-parent -m -- devcontainer-config/init-firewall.sh` removes `echo "         devcontainer up --remove-existing-container --workspace-folder <repo>" >&2` and adds `echo "         cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes" >&2`. `git log -S` names 48a8200b "fix(devcontainer): point init-firewall's fail-closed hint at the launcher" as the commit introducing it.

**Evidence:** `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 19: 330138d8: "and points at the row below that explains why the bare form bakes base-only egress"

**Location:** commit 330138d8 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the target row's existence and position at 330138d8; does not establish anything else about that commit.
**Legibility-target:** for-author

At 330138d8 the PROBE FAIL row is line 935 and the explaining row ("A newly registered profile has no effect") is line 941 (from `git show 330138d8:guides/cc-isolated-usage.md | grep -n`); "the row below" is not the adjacent row. Same imprecision as Claim 8, now fixed only by editing the guide text (the commit message is immutable).

**Evidence:** `guides/cc-isolated-usage.md:935-941`

---

## Claim 20: 330138d8: "Line 58 of cc-isolated-usage.md describes what the launcher does itself, so it is left as is"

**Location:** commit 330138d8 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line's content on main and its match to the launcher; does not establish the rest of that list.
**Legibility-target:** for-orchestrator-synthesis

`main:guides/cc-isolated-usage.md:57-59`: "5. If the running container's baked hash is not the blessed one (you re-blessed since it was built), recreate it with `--remove-existing-container`. `devcontainer up` alone never rebuilds." That is the launcher's own step at `cc-isolated.sh:897-900` (quoted in Claim 12).

**Evidence:** `guides/cc-isolated-usage.md:57-59`, `devcontainer-config/cc-isolated.sh:897-900`

---

## Claim 21: 330138d8: "The 'Last verified' dates on the two guides are not bumped"

**Location:** commit 330138d8 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the full branch diff of guides/; does not establish whether the dates should be bumped.
**Legibility-target:** for-orchestrator-synthesis

`git diff main...HEAD -- guides | grep -i 'last verified'` printed nothing (paraphrased — no quote available because the claim is absence of a change).

**Evidence:** `guides/cc-isolated-usage.md:1-4`, `guides/devcontainer-setup.md`

---

## Claim 22: 330138d8 file list: README index line, AGENTS/GEMINI row in sync, brief Status open -> done

**Location:** commit 330138d8 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each listed edit is in the branch diff; content accuracy is verdicted in Claims 1-5.
**Legibility-target:** for-orchestrator-synthesis

The diff carries `-Status: open` / `+Status: done` in the brief, the README index line, and identical added rows in AGENTS.md and GEMINI.md (paraphrased — no quote available because the claim is a list of file edits, each quoted in its own claim above).

**Evidence:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:3`, `guides/README.md:49`, `AGENTS.md:36`, `GEMINI.md:36`

---

## Claim 23: 9e0ff1a5 A1: "The install layer is cached (no --build-no-cache anywhere in the launcher), a re-bless recreates from cached layers, and newer CC arrives through in-container auto-update or `claude update`; a recreate starts again from the image's version."

**Location:** commit 9e0ff1a5 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the four atoms as verdicted in Claims 9, 10, 12, 13, 14; the part carrying the verdict is "a re-bless recreates from cached layers" (true only while nothing above Dockerfile:403 changed).
**Legibility-target:** for-author

"no --build-no-cache anywhere in the launcher" is Verified (Claim 10); auto-update and image-version atoms are Verified (Claims 13-14). "The install layer is cached" and "a re-bless recreates from cached layers" carry Claim 9's qualifier: `Dockerfile:16-17` `ARG TZ` / `ENV TZ="$TZ"` and the toolchain layers above `Dockerfile:403` are cache inputs, so an upstream change re-resolves `latest`.

**Evidence:** `devcontainer-config/Dockerfile:14-19`, `devcontainer-config/Dockerfile:403`, `devcontainer-config/cc-isolated.sh:897-900`

---

## Claim 24: 9e0ff1a5 A2, C1, A3: both guides' warning names each dropped variable's effect and the probe; devcontainer-setup.md cites the comment above rebuild_hint; the dev-cycle row carries global row 12's step list and the orchestrator half

**Location:** commit 9e0ff1a5 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the diff makes each described change; content accuracy is verdicted in Claims 1-2, 7, 16, 17.
**Legibility-target:** for-orchestrator-synthesis

Both guides now read "each one dropped has its own effect (... the shared `cc--claude-config` volume), and the launcher's probe never runs" (`guides/cc-isolated-usage.md:935`, `guides/devcontainer-setup.md:400-403`); devcontainer-setup.md reads "see the comment above `rebuild_hint` in `cc-isolated.sh`" (`:403-404`); the row reads "as orchestrator it also collects, lands and dispatches build loops" (`AGENTS.md:36`).

**Evidence:** `guides/cc-isolated-usage.md:935`, `guides/devcontainer-setup.md:387-404`, `AGENTS.md:36`

---

## Claim 25: 9e0ff1a5 Notes: "A4 (rebuild_hint in cc-isolated.sh:560 says a plain launch rebuilds, which contradicts the guides' recipe for a bricked firewall) is deferred"

**Location:** commit 9e0ff1a5 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line number, its text, and the contradiction with the plain-launch path; does not establish whether the deferral is the right call.
**Legibility-target:** for-orchestrator-synthesis

`cc-isolated.sh:560`: `echo "    cc-isolated $(printf '%q' "$ws")        # the supported path: rebuilds, re-probes, re-launches" >&2`. A plain launch recreates only on a hash mismatch (`cc-isolated.sh:897-900`, quoted in Claim 12), and this hint is printed at `cc-isolated.sh:915` for a bricked firewall whose hash matches, so the plain launch it names would reuse the bricked container. The guides' `--probe-only` recipe recreates unconditionally (Claim 6).

**Evidence:** `devcontainer-config/cc-isolated.sh:557-565`, `devcontainer-config/cc-isolated.sh:897-916`

---

## Claim 26: 9e0ff1a5: "three override-log rows (A4 deferred, C2 won't-fix, A5 corrected here)"

**Location:** commit 9e0ff1a5 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count and disposition of the added rows; does not establish the rows' reasoning.
**Legibility-target:** for-orchestrator-synthesis

`git diff main...HEAD -- docs/reviews/override-log.md` adds exactly three `| 2026-10-15 | \`fix/doc-drift-cycle1\` |` rows: one on `rebuild_hint`'s first line (`cc-isolated.sh:560`), one "Won't-Fix" on the trigger-phrase quoting, one "Corrected in the fi[x]" on 330138d8's Notes.

**Evidence:** `docs/reviews/override-log.md`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 8** (`guides/cc-isolated-usage.md:935`): "see the row below" points at the "A newly registered profile has no effect" row six rows down (line 941), not the adjacent OAuth row; name the row.
- **Claim 9** (`guides/devcontainer-setup.md:387-388`): the CC layer is reused only while nothing above `Dockerfile:403` changes (TZ, toolchain version args, Dockerfile edits, base-image pull, cache prune); add "as long as nothing above it in the Dockerfile changes".
- **Claim 12** (`guides/devcontainer-setup.md:391-393`): "from those cached layers" carries the same qualifier; a re-bless after an install.sh that edited the Dockerfile above the install line re-resolves `latest`.
- **Claim 19** (commit 330138d8): same "the row below" imprecision as Claim 8 (commit message is immutable; fix lands in the guide text if at all).
- **Claim 23** (commit 9e0ff1a5): A1's "a re-bless recreates from cached layers" carries Claim 9's qualifier.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report on the diff saved to the given path, structured per the code-fact-check skill.
- Answered: 26 claims across the five changed doc files and both commit messages, each with the seven mandatory fields plus Legibility-target; 21 Verified, 5 Mostly accurate, none Incorrect/Stale/Unverifiable. All six focus areas from the brief checked against the code that exercises them (cc-isolated.sh probe/launch paths and rebuild_hint, init-firewall.sh:343-350, devcontainer.json mounts/args, Dockerfile layer order and npm prefix, dev-cycle SKILL.md, global row 12).
- Out of scope: Claude Code's own updater behaviour (whether it could switch to a native/local install under the `~/.claude` volume); docs/reviews/ artifacts; whether deferring A4 (the script fix) is right; no execution, because nothing here is an executable guarantee runnable without docker.
- Escalate: none blocking. The two guide-text tightenings (Claims 8, 9/12) are optional for-author fixes; A4 (cc-isolated.sh:560) stays a real script/guide contradiction tracked in override-log.
