Commit: 9e0ff1a5

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-doc-drift (branch fix/doc-drift-cycle1, HEAD 9e0ff1a5)
**Scope:** `git diff main...HEAD` doc changes (AGENTS.md, GEMINI.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md, the brief), review artifacts under docs/reviews/ excluded; commit messages 330138d8 and 9e0ff1a5. Final confirming pass, iteration 2.
**Checked:** 2026-10-15
**Total claims checked:** 24
**Summary:** 18 verified, 6 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read; no logged pattern matches any claim below (grep for devcontainer/cache/rebuild/launcher/cc-isolated: no hits).

All verdicts are static. No docker or devcontainer command was run (barred by the review brief), so the Docker layer-cache claims rest on the Dockerfile instruction order and Docker's documented cache rules, not on a build.

---

## Claim 1: "User-started outer loop over research-plan-implement and pr-prep: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then build briefs for its top items"

**Location:** `AGENTS.md:36`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step list against global row 12 and the skill's flow headings; does not establish that the row is complete (step 0 "Start and digest" is not named, and global row 12 leaves it out too).
**Legibility-target:** for-orchestrator-synthesis

Global row 12 carries the same list word for word: `global-instructions/CLAUDE.md:32` "The outer loop over rows 6/9: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then writes build briefs for its top items. User-started, no timer." (excerpt ends inside the row; the row continues "Output is triage in `docs/working/questions.md`." — read). Rows 6/9 are RPI and pr-prep, and the skill names the same inner loop: `skills/dev-cycle/SKILL.md:11` "The inner loop (`research-plan-implement` → `pr-prep`, with its review-fix loop) lands one change at a time". The skill's flow headings map to the list: `:371 ### 1. Health and cleanup`, `:409 ### 2. Revisit triggers`, `:428 ### 3. Watched questions`, `:443 ### 4. Claim spot-check`, `:460 ### 4b. Deep-audit check (conditional)`, `:480 ### 5. Brainstorm (conditional)`, `:500 ### 6. Roadmap`, `:638 ### 8. Build briefs`.

**Evidence:** `global-instructions/CLAUDE.md:32`, `skills/dev-cycle/SKILL.md:3`, `skills/dev-cycle/SKILL.md:9-17`, `skills/dev-cycle/SKILL.md:256-758`

---

## Claim 2: "as orchestrator it also collects, lands and dispatches build loops"

**Location:** `AGENTS.md:36`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the skill defines collect, land and dispatch steps for build loops; does not establish how those steps behave.
**Legibility-target:** for-orchestrator-synthesis

`skills/dev-cycle/SKILL.md:13-16` "As the orchestrator it also hands those briefs to autonomous build loops, collects their results and lands what `scripts/build-loop.sh` (the gate) allows". The steps exist as `:548 ### 7. Collect`, `:671 ### 9. Record and land`, `:758 ### 10. Dispatch`. The skill description says the same: `:3` "then as orchestrator collect build-loop results, write build briefs into free slots, record and land, and dispatch build loops".

**Evidence:** `skills/dev-cycle/SKILL.md:3`, `skills/dev-cycle/SKILL.md:13-16`, `skills/dev-cycle/SKILL.md:548`, `skills/dev-cycle/SKILL.md:671`, `skills/dev-cycle/SKILL.md:758`

---

## Claim 3: "Questions for the user go to `docs/working/questions.md`."

**Location:** `AGENTS.md:36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the destination the skill and global row 12 name; does not establish that every question kind (e.g. stop-and-wait ones) goes only there.
**Legibility-target:** for-orchestrator-synthesis

`global-instructions/CLAUDE.md:32` "Output is triage in `docs/working/questions.md`." `skills/dev-cycle/SKILL.md:92` "`docs/working/questions.md` (entry grammar: the global instructions' \"Running questions" (excerpt ends mid-sentence; the bullet continues — read), and `:423` "A fired trigger becomes a questions.md entry that links the decision record".

**Evidence:** `global-instructions/CLAUDE.md:32`, `skills/dev-cycle/SKILL.md:92`, `skills/dev-cycle/SKILL.md:423`

---

## Claim 4: AGENTS.md and GEMINI.md dev-cycle rows are "in sync" (330138d8: "add a dev-cycle row to the Skills table, in sync")

**Location:** `GEMINI.md:36`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers byte equality of the Skills-table region (lines 30-40) of the two files at HEAD; does not establish that the rest of the two files agree.
**Legibility-target:** for-orchestrator-synthesis

`diff <(sed -n 30,40p AGENTS.md) <(sed -n 30,40p GEMINI.md)` printed no difference (paraphrased — no quote available because the claim is about absence of difference; the identical added line appears in both hunks of the diff).

**Evidence:** `AGENTS.md:30-40`, `GEMINI.md:30-40`

---

## Claim 5: "the exit scan of host-git inputs when a session ends, and `cc-push` for pushing a session's commits via a host-only clone"

**Location:** `guides/README.md:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the guide documents both topics and that the code matches the one-line descriptions; does not establish the accuracy of those guide sections.
**Legibility-target:** for-orchestrator-synthesis

The guide has `guides/cc-isolated-usage.md:185 ## Pushing: cc-push` and `:302 ### The exit scan is a tripwire (Q-069 [3], Q-076)`. The launcher runs the scan after `claude` exits: `devcontainer-config/cc-isolated.sh:928` "git_exit_scan \"$ws\" \"$git_before\" \"$lws\" || scan=$?" and its header `:30` "3  the exit scan found a change the session made to what host git reads". cc-push uses a host-only clone: `devcontainer-config/cc-push.sh:487` "run_vis ngit init -q --bare \"$clone\" >&2 || die \"could not create the host-only clone $clone\"".

**Evidence:** `guides/cc-isolated-usage.md:185`, `guides/cc-isolated-usage.md:302`, `devcontainer-config/cc-isolated.sh:30`, `devcontainer-config/cc-isolated.sh:921-934`, `devcontainer-config/cc-push.sh:483-493`

---

## Claim 6: "`cc-isolated --probe-only <repo>` (recreates the container from the blessed config and re-probes), then `cc-isolated <repo>`"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the probe action's unconditional recreate using the blessed hash, and that it matches init-firewall.sh's hint; does not establish that the recreate succeeds when the outage that bricked the firewall persists (the fresh postStartCommand would fail closed again).
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

The config it builds from is the blessed one: `:831-832` "CC_CONFIG_HASH=\"$(blessed_hash)\"" / "export CC_CONFIG_HASH". The two-step recipe matches init-firewall.sh: `devcontainer-config/init-firewall.sh:349-350` "cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes" and "cc-isolated <repo>                 # then start the session".

**Evidence:** `devcontainer-config/cc-isolated.sh:813-886`, `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 7: "it drops the variables the launcher exports, and each one dropped has its own effect (base-only egress and an empty config hash, see the row below; the shared `cc--claude-config` volume)"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the launcher exports five variables devcontainer.json reads via localEnv and that the three named effects follow from empty values; does not establish what a full bare run actually produces end to end (no devcontainer run allowed), in particular whether the empty CC_CONFIG_DIR fails the build before any of the named effects can occur.
**Legibility-target:** for-author

The launcher exports five variables: `devcontainer-config/cc-isolated.sh:821` "export CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR" and `:832` "export CC_CONFIG_HASH". The three named effects are right: `devcontainer-config/devcontainer.json` `"CC_EGRESS_PROFILE": "${localEnv:CC_EGRESS_PROFILE}"`, `"CC_CONFIG_HASH": "${localEnv:CC_CONFIG_HASH}"` and `"source=cc-${localEnv:CC_PROJECT_ID}-claude-config,target=/home/node/.claude,type=volume"` (empty ID gives `cc--claude-config`). But the parenthetical reads as the list of per-variable effects and leaves out CC_CONFIG_DIR, whose effect the cited comment states: `devcontainer-config/cc-isolated.sh:546-547` "an empty CC_CONFIG_DIR / points the build at /Dockerfile" (excerpt ends :547; the comment continues to :555 — read), from `devcontainer.json` `"dockerfile": "${localEnv:CC_CONFIG_DIR}/Dockerfile"`. Precise version: name it ("… the shared volume, a build pointed at /Dockerfile"), or say "among them".

**Evidence:** `devcontainer-config/cc-isolated.sh:534-567`, `devcontainer-config/cc-isolated.sh:813-832`, `devcontainer-config/devcontainer.json:22-55`, `devcontainer-config/devcontainer.json:77-80`

---

## Claim 8: "see the row below" (the row explaining base-only egress and the empty config hash)

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which row the pointer can mean; does not assess the content of that row beyond its topic.
**Legibility-target:** for-author

The row that explains it exists, but it is the sixth row down, not the next one. The next row is `guides/cc-isolated-usage.md:936` "| `OAuth error: getaddrinfo …` at `/login`, launch probe passed | …" (excerpt ends inside the row — read). The row meant is `:941` "| A newly registered profile has no effect — the container's egress is still base-only (`/etc/cc-egress-profile` empty, `/etc/cc-config-hash` empty, …" (excerpt ends inside the row; row continues "The container was rebuilt with a bare `devcontainer up --remove-existing-container …`" — read). Precise version: "see the \"A newly registered profile has no effect\" row further down".

**Evidence:** `guides/cc-isolated-usage.md:923-942`

---

## Claim 9: "and the launcher's probe never runs"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that probe_boundary is only invoked from the launcher's main(); does not establish whether devcontainer's own postStartCommand runs (it does, and it is the firewall, not the probe).
**Legibility-target:** for-orchestrator-synthesis

`probe_boundary` is called only at `devcontainer-config/cc-isolated.sh:884` "probe_boundary \"$ws\"", `:901` "if ! probe_boundary \"$ws\"; then" and `:918` "probe_boundary \"$ws\"", all inside main(). devcontainer.json runs only `"postStartCommand": "sudo /usr/local/bin/init-firewall.sh && /usr/local/bin/link-claude-home.sh"`.

**Evidence:** `devcontainer-config/cc-isolated.sh:577-581`, `devcontainer-config/cc-isolated.sh:880-918`, `devcontainer-config/devcontainer.json:141-142`

---

## Claim 10: "`CLAUDE_CODE_VERSION=latest` is resolved when the install layer is built, and Docker reuses that cached layer on later rebuilds"

**Location:** `guides/devcontainer-setup.md:387-388`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the build arg value, the install instruction, and its cache key under Docker's rules; does not establish behavior after a cache prune, and the reuse holds only while nothing above line 403 changes.
**Legibility-target:** for-author

The arg is the literal string `latest`: `devcontainer-config/devcontainer.json` `"CLAUDE_CODE_VERSION": "latest"`, consumed at `devcontainer-config/Dockerfile:403` "RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}". The instruction text does not change, so the layer is a cache hit and the version resolved at first build is kept. But the layer sits after about 25 instructions that change in normal maintenance: the apt list (`Dockerfile:22`), and the toolchain ARGs `GIT_DELTA_VERSION` (`:89`), `UV_VERSION` (`:115`), `ANDROID_*` (`:235-238`), `RUST*` (`:300-301`), `DOTNET_*` (`:354-356`), `ZSH_IN_DOCKER_VERSION` (`:393`). Each of those is set in devcontainer.json's build args, and a changed value invalidates every later layer, line 403 included. The latest Dockerfile commit did exactly this: `1ef3090b 2026-09-28 build(image): add GNU parallel so bats --jobs can run (Q-086)` (an apt-list change at :22; paraphrased — no quote available because the claim is about git history, from `git log -- devcontainer-config/Dockerfile`). Precise version: "Docker reuses that cached layer on later rebuilds unless something above it in the Dockerfile changes (the apt list, a toolchain version arg)".

**Evidence:** `devcontainer-config/devcontainer.json:29`, `devcontainer-config/Dockerfile:14-403`

---

## Claim 11: "nothing in the launcher passes `--build-no-cache`"

**Location:** `guides/devcontainer-setup.md:388-389`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers cc-isolated.sh and every other file under devcontainer-config/; does not cover a user's own docker settings or manual image removal.
**Legibility-target:** for-orchestrator-synthesis

`grep -rn 'no-cache\|build-no-cache' devcontainer-config/` returned nothing (paraphrased — no quote available because the claim covers absence of code; the only hit across the guides is the claim itself at `guides/devcontainer-setup.md:389`). Each `devcontainer up` the launcher runs passes only `--remove-existing-container` and the `dc` array: `devcontainer-config/cc-isolated.sh:834-836` "local dc=(--workspace-folder \"$ws\" / --override-config \"$(config_dir)/devcontainer.json\" / --id-label \"cc-project=$pid\")". Nor does install.sh build anything (grep for `docker build`/`devcontainer build`/`--pull`: no hits).

**Evidence:** `devcontainer-config/cc-isolated.sh:834-836`, `devcontainer-config/cc-isolated.sh:883`, `devcontainer-config/cc-isolated.sh:887`, `devcontainer-config/cc-isolated.sh:895`

---

## Claim 12: "the egress profile and the config hash are the *last* layer in the Dockerfile, so projects on different profiles still share every heavy layer"

**Location:** `guides/devcontainer-setup.md:389-391`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both ARGs are declared after every heavy layer and written in the final RUN; does not establish "one layer" literally (the per-project tail is two ARGs, five COPYs and a RUN), nor sharing when the tail's COPY sources differ between installs.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/Dockerfile:473-478` "# --- Everything below is per-project. Keep it LAST. ---" … "ARG CC_EGRESS_PROFILE=\"\"", then `:484` "ARG CC_CONFIG_HASH=\"\"". The values are written in the final RUN: `:524` "printf '%s\n' \"${CC_EGRESS_PROFILE}\" > /etc/cc-egress-profile" and `:526` "printf '%s\n' \"${CC_CONFIG_HASH}\" > /etc/cc-config-hash" (excerpts end inside the RUN at :515-529 — read). The heavy layers (toolchains, CC install at :403, elan at :457) all come before :473.

**Evidence:** `devcontainer-config/Dockerfile:403-531`

---

## Claim 13: "A re-bless changes the baked config hash, so the next launch of each project recreates its container automatically, from those cached layers."

**Location:** `guides/devcontainer-setup.md:391-393`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the hash-mismatch recreate and the cache behavior for a re-bless whose change is confined to the per-project tail; does not establish behavior when the re-blessed change touches the Dockerfile above line 473 or a pre-403 build arg.
**Legibility-target:** for-author

The recreate is right: `devcontainer-config/cc-isolated.sh:893-896` "if ! container_config_matches \"${dc[@]}\"; then" / "echo \"Blessed config changed since this container was built — rebuilding it.\"" / "devcontainer up --remove-existing-container \"${dc[@]}\"" / "fi". "From those cached layers" holds only when the re-bless covers tail-only changes (profile, hash, the COPYed scripts and payload). The blessed config includes the Dockerfile and devcontainer.json themselves (paraphrased — no quote available because this rests on install.sh copying devcontainer-config/ into the config dir that the manifest hashes, which spans many lines). So a re-bless that follows an edit above line 403, as in Claim 10, rebuilds the CC install layer and installs whatever is `latest` at that moment. Precise version: "…from those cached layers when the re-blessed change is in the per-project tail".

**Evidence:** `devcontainer-config/cc-isolated.sh:569-576`, `devcontainer-config/cc-isolated.sh:887-896`, `devcontainer-config/Dockerfile:14-403`

---

## Claim 14: "Newer CC versions arrive through Claude Code's own auto-update inside the container, or `claude update` there (see the auto-update row in `cc-isolated-usage.md`'s troubleshooting table)"

**Location:** `guides/devcontainer-setup.md:393-395`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the row exists and that the image permits an npm-global self-update (writable prefix, npm registry reachable); does not establish the Claude Code auto-updater's own behavior, which is external to this repo.
**Legibility-target:** for-orchestrator-synthesis

The row exists: `guides/cc-isolated-usage.md:940` "| Claude Code auto-update fails every launch in ONE project (`.last-update-result.json` shows `install_failed`; …" (excerpt ends inside the row; it continues to "then `claude update`. |" — read). The npm prefix is node-writable: `devcontainer-config/Dockerfile:69-70` "RUN mkdir -p /usr/local/share/npm-global && \" / "chown -R node:node /usr/local/share/npm-global", with `:382` "ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global". The registry is in base egress: `devcontainer-config/egress/base.txt:82` "registry.npmjs.org", and `:75` "downloads.claude.ai" (commented at `:47` as the "native installer/auto-updater").

**Evidence:** `guides/cc-isolated-usage.md:940`, `devcontainer-config/Dockerfile:69-70`, `devcontainer-config/Dockerfile:382-383`, `devcontainer-config/egress/base.txt:47-48`, `devcontainer-config/egress/base.txt:75`, `devcontainer-config/egress/base.txt:82`

---

## Claim 15: "a recreated container starts again from the image's version"

**Location:** `guides/devcontainer-setup.md:395-396`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers where the npm-installed CC and an npm self-update live (the container's writable layer, not a volume); does not establish where a future native-installer migration would write, beyond noting that `/home/node/.local` is not a volume either.
**Legibility-target:** for-orchestrator-synthesis

CC is installed to `/usr/local/share/npm-global` (`devcontainer-config/Dockerfile:382`, `:403`), and the auto-update row's fix acts on that same path inside the container: `guides/cc-isolated-usage.md:940` "`rm -rf /usr/local/share/npm-global/lib/node_modules/@anthropic-ai/.claude-code-*`". The only volumes are `devcontainer-config/devcontainer.json` "source=cc-${localEnv:CC_PROJECT_ID}-bashhistory,target=/commandhistory,type=volume" and "source=cc-${localEnv:CC_PROJECT_ID}-claude-config,target=/home/node/.claude,type=volume". So an update written to the npm prefix is discarded when `--remove-existing-container` replaces the container.

**Evidence:** `devcontainer-config/Dockerfile:382-403`, `devcontainer-config/devcontainer.json:77-80`, `guides/cc-isolated-usage.md:940`

---

## Claim 16: "`cc-isolated --probe-only <repo>` (always recreates it from the blessed config and re-probes), then `cc-isolated <repo>`"

**Location:** `guides/devcontainer-setup.md:397-398`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 6. "Always" holds within the probe action once the earlier gates pass (check_manifest and the host-tool check can refuse first); does not establish a successful re-probe.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/cc-isolated.sh:881-883` "# --probe-only is the verification command, so it always rebuilds: …" / "devcontainer up --remove-existing-container \"${dc[@]}\"" (excerpt ends :883; the branch continues to `exit 0` at :885 — read). The same recipe appears at `devcontainer-config/init-firewall.sh:346` "# --probe-only always rebuilds from the blessed config and re-probes."

**Evidence:** `devcontainer-config/cc-isolated.sh:826-886`, `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 17: "it drops the variables the launcher exports, and each one dropped has its own effect (base-only egress, an empty config hash, the shared `cc--claude-config` volume), and the launcher's probe never runs"

**Location:** `guides/devcontainer-setup.md:399-402`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Same finding and residue as Claims 7 and 9: the three effects and "probe never runs" are right; the enumeration leaves out CC_CONFIG_DIR's effect.
**Legibility-target:** for-author

Same evidence as Claim 7: the launcher exports five variables (`devcontainer-config/cc-isolated.sh:821` "export CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR", `:832` "export CC_CONFIG_HASH"). The comment this sentence cites names a fourth effect that the parenthetical leaves out: `:546-547` "an empty CC_CONFIG_DIR / points the build at /Dockerfile" (excerpt ends :547; comment continues to :555 — read). The "probe never runs" part is Verified per Claim 9.

**Evidence:** `devcontainer-config/cc-isolated.sh:534-555`, `devcontainer-config/cc-isolated.sh:813-832`, `devcontainer-config/devcontainer.json:22-55`

---

## Claim 18: "(see the comment above `rebuild_hint` in `cc-isolated.sh`)" — holds the bare-form rationale (also 9e0ff1a5 C1: "cites the comment above rebuild_hint, which holds the rationale, not the function")

**Location:** `guides/devcontainer-setup.md:402-403`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the comment exists and states the rationale; does not establish the accuracy of rebuild_hint's own printed first line (see Claim 23).
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/cc-isolated.sh:537-540` "# WHY THIS IS NOT A BARE `devcontainer up` STRING. devcontainer.json reads / # CC_PROJECT_ID, CC_PROJECT_NAME, CC_CONFIG_DIR, CC_EGRESS_PROFILE and CC_CONFIG_HASH / # through `${localEnv:...}`, and main() is the only thing that sets them. A bare / # `devcontainer up --remove-existing-container` copied out of an error message and" (excerpt ends :540; the comment continues to :555 and `rebuild_hint()` starts at :557 — read).

**Evidence:** `devcontainer-config/cc-isolated.sh:534-567`

---

## Claim 19: "Staleness >1 version for >2 weeks is a decision-015 Revisit trigger."

**Location:** `guides/devcontainer-setup.md:403-404`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the trigger text in decision 015; does not establish whether the trigger has fired.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/015-cc-process-isolation-docker-devcontainer.md:57` "| **Revisit** | >1 Docker/devcontainer breakage per week needing manual fixing, or image staleness pins CC >1 version behind for >2 weeks | …" (excerpt ends inside the row — read).

**Evidence:** `docs/decisions/015-cc-process-isolation-docker-devcontainer.md:57`

---

## Claim 20: 330138d8 — "matching init-firewall.sh's hint (fc3bff82)"

**Location:** commit 330138d8 body
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that fc3bff82 introduced the launcher recipe in init-firewall.sh and that the guides now match it; does not cover the rest of fc3bff82.
**Legibility-target:** for-orchestrator-synthesis

`git diff fc3bff82^1 fc3bff82 -- devcontainer-config/init-firewall.sh` removes `-    echo "         devcontainer up --remove-existing-container --workspace-folder <repo>" >&2` and adds `+    echo "         cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes" >&2`, which is still at `devcontainer-config/init-firewall.sh:349`.

**Evidence:** `devcontainer-config/init-firewall.sh:343-350`, commit fc3bff82

---

## Claim 21: 330138d8 — "points at the row below that explains why the bare form bakes base-only egress"

**Location:** commit 330138d8 body
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 8.
**Legibility-target:** for-author

The explaining row is `guides/cc-isolated-usage.md:941`, six rows below the edited row at `:935`. The row immediately below is the `OAuth error` row at `:936` (paraphrased — no quote available because both rows are quoted in Claim 8). The commit is immutable, so the fix belongs in the guide's pointer (Claim 8).

**Evidence:** `guides/cc-isolated-usage.md:935-941`

---

## Claim 22: 330138d8 — "Line 58 of cc-isolated-usage.md describes what the launcher does itself, so it is left as is"

**Location:** commit 330138d8 body
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that line 58 is in the launch-steps list and matches main(); does not cover other mentions of `--remove-existing-container` in the guide.
**Legibility-target:** for-orchestrator-synthesis

`guides/cc-isolated-usage.md:57-59` "5. If the running container's baked hash is not the blessed one (you re-blessed / since it was built), recreate it with `--remove-existing-container`. `devcontainer / up` alone never rebuilds." It sits under `:45 ## What a launch does, in order` and matches `devcontainer-config/cc-isolated.sh:893-896` (quoted in Claim 13).

**Evidence:** `guides/cc-isolated-usage.md:45-62`, `devcontainer-config/cc-isolated.sh:887-896`

---

## Claim 23: 9e0ff1a5 — "A4 (rebuild_hint in cc-isolated.sh:560 says a plain launch rebuilds, which contradicts the guides' recipe for a bricked firewall) is deferred"

**Location:** commit 9e0ff1a5 body
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line, its wording, and that a plain launch recreates only on a hash mismatch; also covers the deferral row in override-log.md; does not establish whether rebuild_hint should change.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/cc-isolated.sh:560` "echo \"    cc-isolated $(printf '%q' \"$ws\")        # the supported path: rebuilds, re-probes, re-launches\" >&2". A plain launch recreates only on mismatch (`:893-896`, quoted in Claim 13), and the hint is printed in the bricked-firewall branch at `:915` "rebuild_hint \"$ws\" \"${dc[@]}\"". The deferral is recorded in `docs/reviews/override-log.md` (paraphrased — no quote available because the row is long; it is the first of the three rows added on this branch, Status `Defer`).

**Evidence:** `devcontainer-config/cc-isolated.sh:557-567`, `devcontainer-config/cc-isolated.sh:887-916`, `docs/reviews/override-log.md`

---

## Claim 24: 9e0ff1a5 — A1 summary: "The install layer is cached (no --build-no-cache anywhere in the launcher), a re-bless recreates from cached layers, and newer CC arrives through in-container auto-update or `claude update`; a recreate starts again from the image's version." Also "three override-log rows (A4 deferred, C2 won't-fix, A5 corrected here)" and "the AGENTS.md/GEMINI.md dev-cycle row carries global row 12's step list"

**Location:** commit 9e0ff1a5 body
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the commit's restatement of Claims 1, 10, 11, 13-15 and the override-log count; the Mostly-accurate part is the unqualified "a re-bless recreates from cached layers"; the override-log, step-list and no-cache parts are Verified.
**Legibility-target:** for-author

"no --build-no-cache anywhere in the launcher" is Verified (Claim 11). The auto-update and image-version parts are Verified (Claims 14-15). The step list is Verified (Claim 1). The branch adds exactly three override-log rows, with Statuses `Defer`, `Won't-Fix` and `Corrected in the fix commit` (paraphrased — no quote available because the rows are long; from `git diff main...HEAD -- docs/reviews/override-log.md`, which adds 3 lines). "A re-bless recreates from cached layers" carries the same missing qualifier as Claims 10 and 13: a re-bless that follows a Dockerfile or build-arg change above `Dockerfile:403` re-runs the CC install. The commit cannot be amended; the qualifier belongs in the guide.

**Evidence:** `devcontainer-config/Dockerfile:14-403`, `devcontainer-config/cc-isolated.sh:893-896`, `docs/reviews/override-log.md`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 7** (`guides/cc-isolated-usage.md:935`): the per-variable effects list leaves out CC_CONFIG_DIR (empty means a build pointed at /Dockerfile, per `cc-isolated.sh:546-547`). Name it, or write "among them".
- **Claim 8** (`guides/cc-isolated-usage.md:935`): "see the row below" means the "A newly registered profile has no effect" row at :941, six rows down. The adjacent row is the OAuth one. Name the row.
- **Claim 10** (`guides/devcontainer-setup.md:387-388`): the cached CC layer is reused only while nothing above `Dockerfile:403` changes. The apt list or any toolchain version arg changing re-runs the install with the then-current `latest` (1ef3090b did this on 2026-09-28). Add "unless an earlier layer changes".
- **Claim 13** (`guides/devcontainer-setup.md:391-393`): "from those cached layers" holds only for tail-only re-blesses. Add the same qualifier.
- **Claim 17** (`guides/devcontainer-setup.md:399-402`): same omission as Claim 7.
- **Claim 21** (commit 330138d8): same pointer imprecision as Claim 8. The commit is immutable, so fix the guide.
- **Claim 24** (commit 9e0ff1a5): the unqualified "a re-bless recreates from cached layers" (same as Claim 13). The commit is immutable, so fix the guide.

### Unverifiable
(none as verdicts.) Residue, noted in the Scope fields of Claims 7 and 17: whether a fully bare `devcontainer up --remove-existing-container` with an empty CC_CONFIG_DIR fails at the build (no /Dockerfile) before the base-only-egress effect can happen. The 2026-09-15 measurement cited at `cc-isolated.sh:543-545` saw base-only egress, but CC_CONFIG_DIR already existed then (e87e0b54, 2026-07-13). Settling it needs a host devcontainer run with the variables unset, which this review was barred from doing.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report on the diff saved to the given path, structured per the code-fact-check skill.
- Answered: all six requested areas. (1) Image lifecycle: the cached-layer, no-`--build-no-cache`, last-layer, auto-update-row and image-version claims hold; an auto-update writes to the container's npm prefix, not a volume. The cached-layer and re-bless claims miss the "unless an earlier layer changes" qualifier. (2) The bare-form consequences are right but leave out CC_CONFIG_DIR. The comment above rebuild_hint does hold the rationale. (3) `--probe-only` always recreates from the blessed hash, which matches init-firewall.sh:343-350. (4) The README index line is verified. (5) The dev-cycle row matches global row 12 and the skill, and AGENTS.md and GEMINI.md are in sync. (6) The commit claims are verified, except the "row below" pointer (330138d8) and the unqualified cached-layer restatement (9e0ff1a5).
- Out of scope: review artifacts under docs/reviews/; whether rebuild_hint's first line should change (A4, deferred); prose quality; running docker or devcontainer.
- Escalate: none blocking. Four guide wording tightenings (Claims 7/17, 8, 10/13) are for-author. The full-bare-run outcome residue needs a host devcontainer run if anyone wants it settled.
