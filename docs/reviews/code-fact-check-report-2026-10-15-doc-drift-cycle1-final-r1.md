Commit: 9e0ff1a5

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-doc-drift (branch fix/doc-drift-cycle1, HEAD 9e0ff1a5)
**Scope:** `git diff main...HEAD` doc changes (AGENTS.md, GEMINI.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md; docs/reviews/ excluded) plus commit messages 330138d8 and 9e0ff1a5
**Checked:** 2026-10-15
**Total claims checked:** 21
**Summary:** 17 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first: none of its
logged patterns (corpus statistics, golden counts, test tallies, a script consumer) matches any
claim here.

Execution provenance note: the caller allowed this report as the only file I could create, so the
one executed claim (Claim 4) has its output captured inline in this report, not in a separate log
file. The log I first wrote under `docs/reviews/execution-logs/` was deleted. No docker or
devcontainer process was started (the shared context forbids it), so Docker build-cache and
Claude Code auto-update behaviour were checked statically against the inputs that decide them.

---

## Claim 1: "User-started outer loop over research-plan-implement and pr-prep: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then build briefs for its top items"

**Location:** `AGENTS.md:36` (identical at `GEMINI.md:36`)
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the step list and the "outer loop over RPI/pr-prep, user-started" framing against global row 12 and the skill; does not establish that the row lists every skill step (the skill's step 0 "digest" is not named, as in row 12).

Global row 12 carries the same step list word for word:

```
// global-instructions/CLAUDE.md:32
| 12 | ... | `dev-cycle` skill | e.g., "Run the dev cycle" · The outer loop over rows 6/9: health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then writes build briefs for its top items. User-started, no timer. Output is triage in `docs/working/questions.md`. |
```

Rows 6 and 9 are research-plan-implement and pr-prep. The skill text agrees: "The inner loop (`research-plan-implement` → `pr-prep`, with its review-fix loop) lands one change at a time; this skill steps back ... and writes build briefs for its top items" (`skills/dev-cycle/SKILL.md:11-14`).

**Evidence:** `global-instructions/CLAUDE.md:32`, `skills/dev-cycle/SKILL.md:4`, `skills/dev-cycle/SKILL.md:11-14`, `AGENTS.md:36`

---

## Claim 2: "as orchestrator it also collects, lands and dispatches build loops"

**Location:** `AGENTS.md:36` (identical at `GEMINI.md:36`)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of the collect, record-and-land and dispatch steps in the skill; does not establish that the gate (`scripts/build-loop.sh`) lands everything a loop produces ("lands" means it lands what the gate allows).

The skill's description reads "then as orchestrator collect build-loop results, write build briefs into free slots, record and land, and dispatch build loops" (`skills/dev-cycle/SKILL.md:4`). The body says "As the orchestrator it also hands those briefs to autonomous build loops, collects their results and lands what `scripts/build-loop.sh` (the gate) allows" (`skills/dev-cycle/SKILL.md:14-16`), and the flow has `### 7. Collect` (`:548`), `### 9. Record and land` (`:671`) and step 10 dispatch (`:264`, "→ 10 dispatch → final message").

**Evidence:** `skills/dev-cycle/SKILL.md:4`, `skills/dev-cycle/SKILL.md:14-16`, `skills/dev-cycle/SKILL.md:264`, `skills/dev-cycle/SKILL.md:548`, `skills/dev-cycle/SKILL.md:671`

---

## Claim 3: "Questions for the user go to `docs/working/questions.md`."

**Location:** `AGENTS.md:36` (identical at `GEMINI.md:36`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers where the skill files user questions; does not establish that every finding becomes a question (mechanical ones go to `agent` or the roadmap).

`skills/dev-cycle/SKILL.md:91-93`: "only real choices become `you: judgment` entries in `docs/working/questions.md`", and `:88`: "**The only questions writer** (D11)." Row 12 says "Output is triage in `docs/working/questions.md`" (`global-instructions/CLAUDE.md:32`).

**Evidence:** `skills/dev-cycle/SKILL.md:88-94`, `global-instructions/CLAUDE.md:32`

---

## Claim 4: AGENTS.md and GEMINI.md dev-cycle rows are kept in sync (330138d8: "add a dev-cycle row to the Skills table, in sync")

**Location:** `AGENTS.md:36`, `GEMINI.md:36`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the sync test and the no-@-import guard as they stand at HEAD; does not establish the health check's skill-divergence result (not run).

Command: `timeout 120 bats test/agents-gemini-sync.bats`; cwd `/workspace/.claude/wt-doc-drift`; exit 0; run at 2026-10-15T07:36:31Z. Captured output (locale warnings removed):

```
1..3
ok 1 AGENTS.md and GEMINI.md content is in sync (ignoring headers)
ok 2 the import finder flags every form Claude Code imports, and not emails or code spans
ok 3 AGENTS.md and the global instructions have no @-imports
```

`diff AGENTS.md GEMINI.md` differs only on line 3, the header sentence.

**Evidence:** `test/agents-gemini-sync.bats`; output inline above (see the provenance note in the header)

---

## Claim 5: "the exit scan of host-git inputs when a session ends, and `cc-push` for pushing a session's commits via a host-only clone"

**Location:** `guides/README.md:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that cc-isolated-usage.md covers both topics and describes them this way; does not re-verify the guide's own text against the scan or cc-push code.

The guide's synopsis: "cc-push --remote <url> [REPO]     # push a session's commits via a host-only clone" (`guides/cc-isolated-usage.md:28`), and it has a `## Pushing: cc-push` section (`:185`). The exit scan is described at `:68-77` ("It exits 4 when the exit scan cannot list or read any of it ... 3 the exit scan found a change"). The launcher runs it after claude exits: `git_exit_scan "$ws" "$git_before" "$lws" || scan=$?` (`devcontainer-config/cc-isolated.sh:932`), and the header calls a finding "a change the session made to what host git reads" (`cc-isolated.sh:30`; launch error text at `:862`).

**Evidence:** `guides/cc-isolated-usage.md:28`, `guides/cc-isolated-usage.md:68-77`, `guides/cc-isolated-usage.md:185`, `devcontainer-config/cc-isolated.sh:30`, `devcontainer-config/cc-isolated.sh:862`, `devcontainer-config/cc-isolated.sh:932`

---

## Claim 6: "recreate it from the host with the launcher: `cc-isolated --probe-only <repo>` (recreates the container from the blessed config and re-probes), then `cc-isolated <repo>`"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the probe action's unconditional `--remove-existing-container` and the follow-up plain launch reusing that container; does not establish that the recreated container's firewall bootstraps (that depends on network at start), nor the exit status of `--probe-only` when the probe fails.

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

`CC_CONFIG_HASH="$(blessed_hash)"` is exported before this (`:820-821`), so the rebuild bakes the blessed hash. The later plain launch runs `devcontainer up "${dc[@]}"` and recreates only on a hash mismatch (`:887-896`), so it reuses the container `--probe-only` just built. This matches init-firewall.sh's hint:

```bash
# devcontainer-config/init-firewall.sh:347-350
    echo "       If this container can no longer bootstrap, recreate it from the HOST" >&2
    echo "       with the launcher (the ~/.claude volume and the repo are unaffected):" >&2
    echo "         cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes" >&2
    echo "         cc-isolated <repo>                 # then start the session" >&2
```

**Evidence:** `devcontainer-config/cc-isolated.sh:815-821`, `devcontainer-config/cc-isolated.sh:879-896`, `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 7: "Not a bare `devcontainer up --remove-existing-container …` from your own shell: it drops the variables the launcher exports, and each one dropped has its own effect (base-only egress and an empty config hash, see the row below; the shared `cc--claude-config` volume), and the launcher's probe never runs."

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the three listed effects against devcontainer.json's localEnv reads and the rebuild_hint comment; does not establish what a bare run produces at runtime (not executed), in particular whether the build gets past an empty `CC_CONFIG_DIR`.

The three listed effects match the code. devcontainer.json reads all of them via localEnv: `"CC_EGRESS_PROFILE": "${localEnv:CC_EGRESS_PROFILE}"`, `"CC_CONFIG_HASH": "${localEnv:CC_CONFIG_HASH}"` (`devcontainer-config/devcontainer.json:50,54`) and `"source=cc-${localEnv:CC_PROJECT_ID}-claude-config,target=/home/node/.claude,type=volume"` (`:79`). Only `main()` exports them: `export CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR` (`cc-isolated.sh:812`), `export CC_CONFIG_HASH` (`:821`). `probe_boundary` is called only from cc-isolated.sh's `main` (`:884`, `:901`, `:918`), so a bare run skips it.

The imprecision: "each one dropped" covers five variables, and the list leaves out the one whose effect comes first. The rebuild_hint comment says: "an empty CC_CONFIG_DIR points the build at /Dockerfile" (`cc-isolated.sh:550-551`), because `"dockerfile": "${localEnv:CC_CONFIG_DIR}/Dockerfile"` (`devcontainer.json:25`). On a host with no `/Dockerfile` the build presumably fails before any narrower boundary is baked (paraphrased — no quote available because this is the runtime outcome of a devcontainer build that was not executed). The conclusion (do not use the bare form) and each listed mechanism are right. To be precise, the row should list the `CC_CONFIG_DIR` effect too (the build is pointed at `/Dockerfile`) or say "among them".

Separately, "see the row below" points at the base-only egress row, which is row `:941`, six rows down. The row directly below (`:936`) is the `OAuth error` row. 330138d8's wording, "see the base-only egress row below", named it.

**Evidence:** `devcontainer-config/devcontainer.json:25-26`, `devcontainer-config/devcontainer.json:50-54`, `devcontainer-config/devcontainer.json:77-80`, `devcontainer-config/cc-isolated.sh:538-551`, `devcontainer-config/cc-isolated.sh:806-821`, `guides/cc-isolated-usage.md:936`, `guides/cc-isolated-usage.md:941`

---

## Claim 8: "`CLAUDE_CODE_VERSION=latest` is resolved when the install layer is built, and Docker reuses that cached layer on later rebuilds: nothing in the launcher passes `--build-no-cache`"

**Location:** `guides/devcontainer-setup.md:387-389`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the install instruction's cache key (the literal arg value `latest` plus the layers above it) does not change between rebuilds, and that no launcher or install script passes a no-cache flag. Does not establish actual Docker cache retention at runtime (not executed; a `docker builder prune` or a changed layer above `:403` invalidates it).

```dockerfile
# devcontainer-config/Dockerfile:19
ARG CLAUDE_CODE_VERSION=latest
# devcontainer-config/Dockerfile:402-403
# Install Claude
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}
```

devcontainer.json passes the constant `"CLAUDE_CODE_VERSION": "latest"` (`devcontainer-config/devcontainer.json:29`). The arg string never changes, so the cache key is unchanged and npm's resolution of `latest` happens only when the layer actually runs. `grep -rn 'no-cache\|build-no-cache' devcontainer-config/ install.sh` returns no hits (paraphrased — no quote available because the claim covers absence of code). All three `devcontainer up` calls in the launcher (`cc-isolated.sh:883`, `:887`, `:895`) carry only `--remove-existing-container` and `"${dc[@]}"`.

**Evidence:** `devcontainer-config/Dockerfile:19`, `devcontainer-config/Dockerfile:402-403`, `devcontainer-config/devcontainer.json:29`, `devcontainer-config/cc-isolated.sh:879-896`

---

## Claim 9: "the egress profile and the config hash are the *last* layer in the Dockerfile, so projects on different profiles still share every heavy layer"

**Location:** `guides/devcontainer-setup.md:389-391`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the two per-project args are declared after every toolchain and CC install layer. Does not establish a single layer: the per-project tail is several instructions (ARG, COPY ×5, RUN), which the Dockerfile itself also calls the "final layer".

```dockerfile
# devcontainer-config/Dockerfile:473-484
# --- Everything below is per-project. Keep it LAST. -------------------------
# CC_EGRESS_PROFILE is the only build arg that varies between projects, so
# declaring it here means every layer above is shared across all projects'
# images (decision 016, S2: N projects must not mean N full builds — only this
# final layer is rebuilt when a project's egress profile differs).
ARG CC_EGRESS_PROFILE=""
...
ARG CC_CONFIG_HASH=""
```

(excerpt ends :484; the tail continues with COPYs and the RUN writing `/etc/cc-egress-profile` and `/etc/cc-config-hash` at `:524-527`, ending `USER node` at `:531`, the file's last line — read)

**Evidence:** `devcontainer-config/Dockerfile:473-531`

---

## Claim 10: "A re-bless changes the baked config hash, so the next launch of each project recreates its container automatically, from those cached layers."

**Location:** `guides/devcontainer-setup.md:391-393`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the hash-mismatch recreate in main() and cache reuse for a re-bless that changes only per-project-tail inputs. Does not establish cache reuse when the re-bless follows an `install.sh` that changed the Dockerfile above the CC install layer.

The automatic recreate is right:

```bash
# devcontainer-config/cc-isolated.sh:887-896
  devcontainer up "${dc[@]}"

  # `devcontainer up` never rebuilds an existing container. If the config was
  # re-blessed since this one was built, it is running the previous boundary;
  # recreate it (the ~/.claude volume and the repo are unaffected).
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
  fi
```

"From those cached layers" holds when what changed is the hash, the profile, or the COPY'd tail inputs (`Dockerfile:478-531`). It does not hold when a re-bless follows an `install.sh` that changed the Dockerfile above `:403` (for example the `node:22` base bump recorded at `Dockerfile:10-11`). In that case every layer from the change down rebuilds, including the CC install, and `latest` resolves again. The precise version: "from cached layers, unless the Dockerfile changed above the install layer".

**Evidence:** `devcontainer-config/cc-isolated.sh:887-896`, `devcontainer-config/Dockerfile:10-14`, `devcontainer-config/Dockerfile:403`, `devcontainer-config/Dockerfile:473-531`

---

## Claim 11: "Newer CC versions arrive through Claude Code's own auto-update inside the container, or `claude update` there (see the auto-update row in `cc-isolated-usage.md`'s troubleshooting table)"

**Location:** `guides/devcontainer-setup.md:393-395`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the container does not block an npm self-update (registry allowlisted, prefix node-writable, auto-updater not disabled) and that the cited row exists. Does not establish Claude Code's updater behaviour at runtime (not executed), nor the other path to a newer CC: a Dockerfile change above the install layer (Claim 10).

The cited row exists: "| Claude Code auto-update fails every launch in ONE project ... Inside the container: `rm -rf /usr/local/share/npm-global/lib/node_modules/@anthropic-ai/.claude-code-*`, then `claude update`. |" (`guides/cc-isolated-usage.md:940`). The registry is allowlisted: "# Node toolchain — CC is an npm package and self-updates from here." / `registry.npmjs.org` (`devcontainer-config/egress/base.txt:81-82`). The npm prefix belongs to node: `chown -R node:node /usr/local/share/npm-global` (`Dockerfile:69-70`) and `ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global` (`Dockerfile:382`). A grep for `DISABLE_AUTOUPDATER|autoUpdates` in `devcontainer-config/` finds nothing (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `guides/cc-isolated-usage.md:940`, `devcontainer-config/egress/base.txt:81-82`, `devcontainer-config/Dockerfile:69-70`, `devcontainer-config/Dockerfile:382-383`

---

## Claim 12: "a recreated container starts again from the image's version"

**Location:** `guides/devcontainer-setup.md:395-396`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fact that the npm-global prefix, where the auto-update and `claude update` install, is on the container filesystem and not on either mounted volume. Does not establish what happens if a future Claude Code updater installs under `/home/node/.claude` (the per-project volume) instead of the npm prefix.

The only mounts are `"source=cc-${localEnv:CC_PROJECT_ID}-bashhistory,target=/commandhistory,type=volume"` and `"source=cc-${localEnv:CC_PROJECT_ID}-claude-config,target=/home/node/.claude,type=volume"` (`devcontainer-config/devcontainer.json:78-79`), plus the repo at `/workspace` (`:134`). The update target is `/usr/local/share/npm-global` (`Dockerfile:382`; the auto-update row at `guides/cc-isolated-usage.md:940` names `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/`). `--remove-existing-container` discards the container layer, so the update is lost and the image's install is back.

**Evidence:** `devcontainer-config/devcontainer.json:77-80`, `devcontainer-config/devcontainer.json:134`, `devcontainer-config/Dockerfile:382`, `guides/cc-isolated-usage.md:940`

---

## Claim 13: "`cc-isolated --probe-only <repo>` (always recreates it from the blessed config and re-probes), then `cc-isolated <repo>`"

**Location:** `guides/devcontainer-setup.md:396-398`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Same scope as Claim 6, whose quote (`cc-isolated.sh:880-885`) is the evidence; does not establish that the recreated container bootstraps its firewall.

The probe branch calls `devcontainer up --remove-existing-container "${dc[@]}"` unconditionally, then `probe_boundary "$ws"` (`devcontainer-config/cc-isolated.sh:883-884`). This matches `init-firewall.sh:349-350`.

**Evidence:** `devcontainer-config/cc-isolated.sh:879-885`, `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 14: "it drops the variables the launcher exports, and each one dropped has its own effect (base-only egress, an empty config hash, the shared `cc--claude-config` volume), and the launcher's probe never runs (see the comment above `rebuild_hint` in `cc-isolated.sh`)"

**Location:** `guides/devcontainer-setup.md:398-403`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the listed effects and the citation of the comment as the rationale's location; does not establish the runtime outcome of a bare run (not executed).

The comment is where the rationale lives:

```bash
# devcontainer-config/cc-isolated.sh:538-551
# WHY THIS IS NOT A BARE `devcontainer up` STRING. devcontainer.json reads
# CC_PROJECT_ID, CC_PROJECT_NAME, CC_CONFIG_DIR, CC_EGRESS_PROFILE and CC_CONFIG_HASH
# through `${localEnv:...}`, and main() is the only thing that sets them. ...
# CC_EGRESS_PROFILE/CC_CONFIG_HASH bakes base-only egress and an empty
# /etc/cc-config-hash ...; an empty
# CC_PROJECT_ID mounts the SHARED `cc--claude-config` volume; an empty CC_CONFIG_DIR
# points the build at /Dockerfile.
```

(excerpt elides :541-547 and ends :551; the comment continues to :556 and `rebuild_hint()` runs :557-567 — read)

The comment covers the three listed effects. The guide makes the same omission as Claim 7: the comment's fourth effect (`CC_CONFIG_DIR` → build pointed at `/Dockerfile`) is missing, even though "each one dropped has its own effect" reads as a full list. "The launcher's probe never runs" is true (`probe_boundary` is called only from `main`, `cc-isolated.sh:884,901,918`), but the cited comment does not say it, so the parenthetical citation backs the effects list and not that clause.

**Evidence:** `devcontainer-config/cc-isolated.sh:535-567`, `devcontainer-config/cc-isolated.sh:884`, `devcontainer-config/cc-isolated.sh:901`, `devcontainer-config/cc-isolated.sh:918`, `devcontainer-config/devcontainer.json:25`

---

## Claim 15: "Staleness >1 version for >2 weeks is a decision-015 Revisit trigger."

**Location:** `guides/devcontainer-setup.md:403-404`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the trigger's existence and thresholds in decision 015; does not establish whether it has fired.

`docs/decisions/015-cc-process-isolation-docker-devcontainer.md:57`: "| **Revisit** | >1 Docker/devcontainer breakage per week needing manual fixing, or image staleness pins CC >1 version behind for >2 weeks | ..."

**Evidence:** `docs/decisions/015-cc-process-isolation-docker-devcontainer.md:57`

---

## Claim 16: 330138d8: the usage row "now recommends `cc-isolated --probe-only <repo>` then `cc-isolated <repo>`, matching init-firewall.sh's hint (fc3bff82), ... and points at the row below that explains why the bare form bakes base-only egress"

**Location:** commit 330138d8 message (bare locator); `guides/cc-isolated-usage.md:935`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the claim as it describes 330138d8's own text and fc3bff82's change; does not cover HEAD's rewording of the pointer (Claim 7).

`git diff fc3bff82^1 fc3bff82 -- devcontainer-config/init-firewall.sh` replaces `devcontainer up --remove-existing-container --workspace-folder <repo>` with the two `cc-isolated` lines quoted in Claim 6. 330138d8's row ended "— see the base-only egress row below." (`git show 330138d8 -- guides/cc-isolated-usage.md`). That names the row at `:941`.

**Evidence:** `devcontainer-config/init-firewall.sh:343-350`, `guides/cc-isolated-usage.md:941`, commit fc3bff82, commit 330138d8

---

## Claim 17: 330138d8: README index line mentions exit scan and cc-push; dev-cycle row added to AGENTS.md and GEMINI.md; brief Status open -> done

**Location:** commit 330138d8 message; `guides/README.md:49`, `AGENTS.md:36`, `GEMINI.md:36`, `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the commit makes these edits; content accuracy is checked in Claims 1-5.

`git show --stat 330138d8` lists exactly AGENTS.md, GEMINI.md, the brief, guides/README.md, guides/cc-isolated-usage.md and guides/devcontainer-setup.md. The brief's diff is `-Status: open` / `+Status: done`.

**Evidence:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:3`, commit 330138d8

---

## Claim 18: 330138d8 Notes: "Line 58 of cc-isolated-usage.md describes what the launcher does itself, so it is left as is (brief item 1). The 'Last verified' dates on the two guides are not bumped"

**Location:** commit 330138d8 message; `guides/cc-isolated-usage.md:58`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers line 58's content and the absence of Last-verified edits in the diff; does not cover the Notes' process claim that the edited passages were re-checked (9e0ff1a5 A5 corrects that claim).

At 330138d8 and at HEAD, line 58 sits in launcher step 5: "5. If the running container's baked hash is not the blessed one (you re-blessed / since it was built), recreate it with `--remove-existing-container`." (`guides/cc-isolated-usage.md:57-59`). That is main()'s own recreate (`cc-isolated.sh:892-895`), not advice to the reader. The full diff has no `Last verified` line (paraphrased — no quote available because the claim covers absence of a change in the diff).

**Evidence:** `guides/cc-isolated-usage.md:57-59`, `devcontainer-config/cc-isolated.sh:892-895`, `/home/node/.claude/jobs/00bcf178/tmp/doc-drift/diff2.patch`

---

## Claim 19: 9e0ff1a5 A1: "The install layer is cached (no --build-no-cache anywhere in the launcher), a re-bless recreates from cached layers, and newer CC arrives through in-container auto-update or `claude update`; a recreate starts again from the image's version."

**Location:** commit 9e0ff1a5 message (bare locator)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the same four atoms as Claims 8, 10, 11 and 12; does not add evidence beyond them.

Not split, because three of the four parts are Verified (Claims 8, 11, 12). The verdict comes from the "re-bless recreates from cached layers" part, which is Mostly accurate for the reason in Claim 10: it holds unless the re-bless follows a Dockerfile change above `Dockerfile:403`.

**Evidence:** `devcontainer-config/Dockerfile:403`, `devcontainer-config/cc-isolated.sh:879-896`, `devcontainer-config/devcontainer.json:77-80`, `guides/cc-isolated-usage.md:940`

---

## Claim 20: 9e0ff1a5 Notes: "A4 (rebuild_hint in cc-isolated.sh:560 says a plain launch rebuilds, which contradicts the guides' recipe for a bricked firewall) is deferred: the brief puts scripts out of scope"

**Location:** commit 9e0ff1a5 message; `devcontainer-config/cc-isolated.sh:560`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the hint text, the bricked-firewall path that prints it, and the brief's out-of-scope line; does not establish what a user following the hint sees at runtime.

```bash
# devcontainer-config/cc-isolated.sh:560
  echo "    cc-isolated $(printf '%q' "$ws")        # the supported path: rebuilds, re-probes, re-launches" >&2
```

On the bricked path a plain launch reuses the container (`:887`) and recreates only on a hash mismatch (`:892-895`). The bricked container's hash still matches, so after `init-firewall.sh` fails again the launcher prints `rebuild_hint` (`:915`) and `return 1` (`:916`) without rebuilding. The brief: "## Out of scope ... Changing `init-firewall.sh`, `cc-isolated.sh` or any other script." (`docs/working/briefs/2026-10-02-doc-drift-cycle1.md:50-53`).

**Evidence:** `devcontainer-config/cc-isolated.sh:557-567`, `devcontainer-config/cc-isolated.sh:887-918`, `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:50-53`

---

## Claim 21: 9e0ff1a5: A2, A3 and C1 describe the guide and table edits; "Review artifacts for iteration 1 and three override-log rows (A4 deferred, C2 won't-fix, A5 corrected here)"

**Location:** commit 9e0ff1a5 message; `docs/reviews/override-log.md`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the commit contains the described edits and exactly three override rows with those dispositions; content accuracy of the edits is in Claims 1-14.

`git show --stat 9e0ff1a5` shows `docs/reviews/override-log.md | 3 +`, and the three added rows have dispositions `Defer` (rebuild_hint, A4), `Won't-Fix` (trigger quoting, C2) and `Corrected in the fix commit` (330138d8 Notes, A5). The AGENTS.md/GEMINI.md row carries the row-12 step list (Claim 1) and the orchestrator clause (Claim 2). devcontainer-setup.md cites "the comment above `rebuild_hint`" (`guides/devcontainer-setup.md:402`, C1). Both guides list the three effects (A2; Claims 7, 14).

**Evidence:** `docs/reviews/override-log.md`, `guides/devcontainer-setup.md:398-403`, `guides/cc-isolated-usage.md:935`, commit 9e0ff1a5

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 7** (`guides/cc-isolated-usage.md:935`): "each one dropped has its own effect" lists three effects but leaves out the fourth from rebuild_hint's comment (empty `CC_CONFIG_DIR` points the build at `/Dockerfile`). Add it or say "among them". Also "see the row below" points at the row six rows down (`:941`), not the next row (`:936` is the OAuth row); name it, as 330138d8 did ("the base-only egress row below").
- **Claim 10** (`guides/devcontainer-setup.md:391-393`): "recreates ... from those cached layers" needs the qualifier "unless the Dockerfile changed above the CC install layer". In that case the CC install re-runs and `latest` resolves again.
- **Claim 14** (`guides/devcontainer-setup.md:398-403`): same missing `CC_CONFIG_DIR` effect as Claim 7. The cited rebuild_hint comment backs the effects list but does not mention "the launcher's probe never runs" (true, from `main`).
- **Claim 19** (commit 9e0ff1a5, A1): "a re-bless recreates from cached layers" carries the Claim 10 qualifier. Commit text, so this is a note only; no edit is possible without rewriting history.

### Unverifiable
(none; runtime residues are in the Scope fields of Claims 7, 8, 10-12 and 14)

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report on the diff saved to the given path, structured per the code-fact-check skill.
- Answered: all six requested claim groups were checked against the code that exercises them (cc-isolated.sh main/probe/rebuild_hint, init-firewall.sh:343-350, devcontainer.json, Dockerfile, egress/base.txt, dev-cycle SKILL.md, global row 12). Results: 17 Verified, 4 Mostly accurate, 0 Incorrect, 0 Stale, 0 Unverifiable. The sync test was executed (exit 0). The auto-update installs to `/usr/local/share/npm-global` on the container filesystem, not a volume, so "a recreated container starts again from the image's version" holds.
- Out of scope: running docker/devcontainer (forbidden), so Docker cache retention and the outcome of a bare `devcontainer up` are static-only. Code quality and the deferred rebuild_hint script change (A4) are out of scope. Review artifacts under docs/reviews/ are excluded. No hallucination-log entry was added (no Incorrect verdicts).
- Escalate: nothing blocking. The `CC_CONFIG_DIR` omission (Claims 7, 14) and the "row below" pointer (Claim 7) are small for-author tightenings. The orchestrator decides whether they warrant another iteration.
