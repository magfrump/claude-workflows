Commit: 330138d8

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-doc-drift (branch fix/doc-drift-cycle1)
**Scope:** branch diff `main...HEAD` (AGENTS.md, GEMINI.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md) plus the commit message of 330138d8; claims traced into devcontainer-config/cc-isolated.sh, init-firewall.sh, devcontainer.json, Dockerfile, skills/dev-cycle/SKILL.md, global-instructions/CLAUDE.md
**Checked:** 2026-10-15
**Total claims checked:** 14
**Summary:** 11 verified, 2 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) read first; no entry resembles any claim below.

---

## Claim 1: "Maintenance or planning pass over the repo — "run the dev cycle", "maintenance pass", "what should we work on next", "update the roadmap" | `dev-cycle` | User-started outer loop over research-plan-implement and pr-prep ... roadmap (`docs/roadmap.md`)"

**Location:** `AGENTS.md:36`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four trigger phrases, the skill name, the "outer loop over research-plan-implement and pr-prep" framing, "user-started", and the roadmap path; does not establish that the row's step list or output line is complete (Claim 2).
**Legibility-target:** for-orchestrator-synthesis

The trigger phrases match the skill's description verbatim: `Triggers: "run the dev cycle", "maintenance pass", "what should we work on next", "update the roadmap".` (`skills/dev-cycle/SKILL.md:4`). The outer-loop framing matches `The outer loop. The inner loop (`research-plan-implement` → `pr-prep`, with its review-fix loop) lands one change at a time` (`skills/dev-cycle/SKILL.md:11-12`). The roadmap path matches `Update `docs/roadmap.md`, creating it from this template if missing` (`skills/dev-cycle/SKILL.md:502`). "User-started" matches row 12 of the global instructions, `User-started, no timer.` (`global-instructions/CLAUDE.md:32`); the skill's own description says `/loop /dev-cycle` repeats it (`skills/dev-cycle/SKILL.md:4`), which is still a user-started repetition (paraphrased — no quote available because the skill names no scheduler or cron path; claim covers absence of code, checked by `grep -i 'timer\|cron\|schedule'` with no hit).

**Evidence:** `skills/dev-cycle/SKILL.md:4`, `skills/dev-cycle/SKILL.md:11-12`, `skills/dev-cycle/SKILL.md:502`, `global-instructions/CLAUDE.md:32`

---

## Claim 2: "health and cleanup, revisit triggers, watched questions, roadmap (`docs/roadmap.md`), then build briefs for its top items. Output is triage in `docs/working/questions.md`."

**Location:** `AGENTS.md:36`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every named step exists in the skill in the stated order and that the skill writes triage to questions.md; does not establish that the list is complete, and it is not.
**Legibility-target:** for-author

Every listed step exists, but the list is a subset. The skill's description runs: `digest, health and cleanup, revisit triggers, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap, then as orchestrator collect build-loop results, write build briefs into free slots, record and land, and dispatch build loops` (`skills/dev-cycle/SKILL.md:4`). The row leaves out the digest, the claim spot-check, the deep-audit/brainstorm step, and the orchestrator half (dispatching build loops, collecting their results, landing). Global row 12 keeps the spot-check and the deep-audit/brainstorm: `health and cleanup, every revisit trigger, watched questions, claim spot-check, conditional deep-audit check and brainstorm, roadmap (`docs/roadmap.md`), then writes build briefs for its top items` (`global-instructions/CLAUDE.md:32`). The AGENTS row trims that further. On "Output is triage in questions.md": the skill also writes the roadmap, cycle records (`cycle records are in docs/working/cycles/`, `skills/dev-cycle/SKILL.md:507-508`) and build briefs, so questions.md is the triage output, not the only output. A tighter row would add the spot-check, the brainstorm, and "dispatches build loops", or say "among others".

**Evidence:** `skills/dev-cycle/SKILL.md:4`, `skills/dev-cycle/SKILL.md:502-509`, `global-instructions/CLAUDE.md:32`

---

## Claim 3: GEMINI.md gains the same dev-cycle row "in sync" with AGENTS.md (commit message: "AGENTS.md, GEMINI.md: add a dev-cycle row to the Skills table, in sync")

**Location:** `GEMINI.md:36`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-identity of the row and the repo's sync and no-import tests passing; Claim 2's content findings apply to this row as well.
**Legibility-target:** for-orchestrator-synthesis

`diff <(sed -n 25,45p AGENTS.md) <(sed -n 25,45p GEMINI.md)` printed nothing (identical). The sync test passed:

```
ok 1 AGENTS.md and GEMINI.md content is in sync (ignoring headers)
ok 2 the import finder flags every form Claude Code imports, and not emails or code spans
ok 3 AGENTS.md and the global instructions have no @-imports
```

Command `timeout 120 bats test/agents-gemini-sync.bats`, cwd `/workspace/.claude/wt-doc-drift`, exit 0, 2026-10-15T07:24:00Z.

**Evidence:** `GEMINI.md:36`, `AGENTS.md:36`, /home/node/.claude/jobs/00bcf178/tmp/doc-drift/cfc-r3-agents-gemini-sync.log

---

## Claim 4: cc-isolated-usage.md covers "the exit scan of host-git inputs when a session ends, and `cc-push` for pushing a session's commits via a host-only clone"

**Location:** `guides/README.md:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the guide has sections on both topics and uses the cited framing; does not establish that those sections are themselves accurate.
**Legibility-target:** for-orchestrator-synthesis

The guide has `## Pushing: cc-push` (`guides/cc-isolated-usage.md:185`) and `### The exit scan is a tripwire (Q-069 [3], Q-076)` (`guides/cc-isolated-usage.md:302`). Its command reference says `cc-push --remote <url> [REPO]     # push a session's commits via a host-only clone` (`guides/cc-isolated-usage.md:28`). The launch steps say the launcher `snapshots what host git reads to decide what to run ... when claude exits it compares` (`guides/cc-isolated-usage.md:62-64`; excerpt ends inside step 7, which continues to the exit-code text — read).

**Evidence:** `guides/cc-isolated-usage.md:28`, `guides/cc-isolated-usage.md:62-64`, `guides/cc-isolated-usage.md:185`, `guides/cc-isolated-usage.md:302`

---

## Claim 5: "recreate it from the host with the launcher: `cc-isolated --probe-only <repo>` (rebuilds from the blessed config and re-probes)"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the probe action always recreates the container with the blessed hash and every launcher localEnv input exported, then runs the self-probe (so a container bricked closed gets a fresh postStartCommand firewall run); does not establish that image layers are rebuilt from scratch (they come from Docker's cache, see Claim 8), and it was not executed.
**Legibility-target:** for-orchestrator-synthesis

Before either action, main() exports every input: `export CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR` (`devcontainer-config/cc-isolated.sh:821`) and `CC_CONFIG_HASH="$(blessed_hash)"` / `export CC_CONFIG_HASH` (`devcontainer-config/cc-isolated.sh:831-832`). The probe action then does:

```bash
# devcontainer-config/cc-isolated.sh:880-885
  if [ "$action" = "probe" ]; then
    # --probe-only is the verification command, so it always rebuilds: probing a
    # container left over from an earlier config would verify the wrong boundary.
    devcontainer up --remove-existing-container "${dc[@]}"
    probe_boundary "$ws"
    exit 0
```

`--probe-only) action="probe"` (`devcontainer-config/cc-isolated.sh:735`). The script runs under `set -euo pipefail` (`devcontainer-config/cc-isolated.sh:66`), so a failing probe exits non-zero before the `exit 0`. A new container runs `"postStartCommand": "sudo /usr/local/bin/init-firewall.sh && ..."` (`devcontainer-config/devcontainer.json`, postStartCommand key), which is what un-bricks a fail-closed container.

**Evidence:** `devcontainer-config/cc-isolated.sh:66`, `devcontainer-config/cc-isolated.sh:735`, `devcontainer-config/cc-isolated.sh:812-832`, `devcontainer-config/cc-isolated.sh:880-885`, `devcontainer-config/devcontainer.json`

---

## Claim 6: "then `cc-isolated <repo>`" (starts the session)

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the launch path after a successful --probe-only (no second rebuild, probe, exec claude, exit scan); does not establish runtime success.
**Legibility-target:** for-orchestrator-synthesis

The launch path runs `devcontainer up "${dc[@]}"` without removal (`devcontainer-config/cc-isolated.sh:887`) and rebuilds only `if ! container_config_matches "${dc[@]}"` (`devcontainer-config/cc-isolated.sh:893`). After --probe-only the baked hash matches, so it re-probes and runs `devcontainer exec "${dc[@]}" claude || rc=$?` (`devcontainer-config/cc-isolated.sh:927`), then the exit scan (`devcontainer-config/cc-isolated.sh:932`; main() continues to its closing `esac` at :938 — read).

**Evidence:** `devcontainer-config/cc-isolated.sh:887-938`

---

## Claim 7: "Not a bare `devcontainer up --remove-existing-container …` from your own shell — see the base-only egress row below."

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that such a row exists later in the same table and gives the reason; does not re-verify that row's own mechanism (see Claim 10 for the same mechanism).
**Legibility-target:** for-orchestrator-synthesis

Line 942 of the same Troubleshooting table: `A newly registered profile has no effect — the container's egress is still base-only ... | The container was rebuilt with a bare `devcontainer up --remove-existing-container …` from your own shell. `devcontainer.json` reads `CC_EGRESS_PROFILE` and `CC_CONFIG_HASH` via `${localEnv:…}`, and only `cc-isolated` exports them` (`guides/cc-isolated-usage.md:942`; excerpt ends mid-row, which continues to "print the assignments inline for the by-hand form" — read).

**Evidence:** `guides/cc-isolated-usage.md:921-943`

---

## Claim 8: "to pick up a newer CC *without* a config change, recreate it with the launcher: `cc-isolated --probe-only <repo>` ..., then `cc-isolated <repo>`"

**Location:** `guides/devcontainer-setup.md:389-391`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the launcher's recreate path, as coded, produces a newer baked Claude Code; does not establish behavior after the Docker build cache is pruned, and does not cover in-container auto-update, which is a separate route.
**Legibility-target:** for-author

The recreate path never asks for a cache-less build. Both rebuild calls are plain `devcontainer up --remove-existing-container "${dc[@]}"` (`devcontainer-config/cc-isolated.sh:883`, `:895`). `dc` holds only `--workspace-folder`, `--override-config` and `--id-label` (`devcontainer-config/cc-isolated.sh:834-836`). Nothing in the launcher passes `--build-no-cache` or prunes (paraphrased — no quote available because the claim covers absence of code; `grep -n 'no-cache' devcontainer-config/cc-isolated.sh` has no hits). The CC layer's cache key never changes. The version arg is the constant `"CLAUDE_CODE_VERSION": "latest"` (`devcontainer-config/devcontainer.json`, build.args), and the layer is:

```dockerfile
# devcontainer-config/Dockerfile:402-403
# Install Claude
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}
```

It sits above the per-project tail, which starts at `ARG CC_EGRESS_PROFILE=""` (`devcontainer-config/Dockerfile:478`) and `ARG CC_CONFIG_HASH=""` (`:484`). The file says so itself: `declaring it here means every layer above is shared across all projects' images` (`devcontainer-config/Dockerfile:475-476`). With the same instruction text and the same arg value, Docker's layer cache reuses the old `npm install` layer. Recreating the container (or rebuilding with only the tail args changed) therefore re-bakes the CC version already cached (paraphrased — no quote available because this rests on Docker BuildKit cache-key semantics, not repo code). The old bare advice had the same flaw, so this branch did not introduce it; it carries the false premise forward with a new mechanism attached. A newer CC actually arrives through in-container auto-update/`claude update` (the guide's own troubleshooting row at `guides/cc-isolated-usage.md:940` presumes it), or through a no-cache rebuild, which no documented path runs. Execution blocker: the brief forbids starting docker/devcontainer, and the CLI is not installed here (`devcontainer not found`). That is why confidence is Medium rather than High.

**Evidence:** `devcontainer-config/cc-isolated.sh:834-836`, `devcontainer-config/cc-isolated.sh:883`, `devcontainer-config/cc-isolated.sh:895`, `devcontainer-config/Dockerfile:19`, `devcontainer-config/Dockerfile:402-403`, `devcontainer-config/Dockerfile:474-484`, `devcontainer-config/devcontainer.json`, `guides/cc-isolated-usage.md:940`

---

## Claim 9: "`cc-isolated --probe-only <repo>` (always rebuilds from the blessed config and re-probes)"

**Location:** `guides/devcontainer-setup.md:390-391`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every --probe-only run recreates the container with the blessed hash and then probes; does not establish a cache-less image rebuild (the reading this sentence's context invites, refuted in Claim 8).
**Legibility-target:** for-orchestrator-synthesis

`# --probe-only is the verification command, so it always rebuilds` followed by an unconditional `devcontainer up --remove-existing-container "${dc[@]}"` and `probe_boundary "$ws"` (`devcontainer-config/cc-isolated.sh:881-884`), with `CC_CONFIG_HASH="$(blessed_hash)"` exported first (`devcontainer-config/cc-isolated.sh:831-832`). See Claim 5.

**Evidence:** `devcontainer-config/cc-isolated.sh:831-832`, `devcontainer-config/cc-isolated.sh:880-885`

---

## Claim 10: "Not a bare `devcontainer up --remove-existing-container …` from your own shell: it drops the launcher's `localEnv` inputs and bakes base-only egress and an empty config hash (see `rebuild_hint` in `cc-isolated.sh`)."

**Location:** `guides/devcontainer-setup.md:392-394`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the mechanism (the localEnv inputs are unset in a user's shell and resolve empty) and the egress/hash consequence that rebuild_hint names; does not establish what a fully bare run does end to end, where the other empty inputs may change the outcome.
**Legibility-target:** for-author

The mechanism and the cited source match:

```bash
# devcontainer-config/cc-isolated.sh:538-547
# CC_PROJECT_ID, CC_PROJECT_NAME, CC_CONFIG_DIR, CC_EGRESS_PROFILE and CC_CONFIG_HASH
# through `${localEnv:...}`, and main() is the only thing that sets them. A bare
# `devcontainer up --remove-existing-container` copied out of an error message and
# run from your own shell therefore resolves them all to the EMPTY string: an empty
# CC_EGRESS_PROFILE/CC_CONFIG_HASH bakes base-only egress and an empty
# /etc/cc-config-hash (...); an empty
# CC_PROJECT_ID mounts the SHARED `cc--claude-config` volume; an empty CC_CONFIG_DIR
# points the build at /Dockerfile.
```

(excerpt ends :547; the comment continues to :556 and `rebuild_hint()` to :567 — read). The guide names only the egress/hash consequence. The same source lists two more: the shared `cc--claude-config` volume, a cross-project credential exposure, and a build pointed at `/Dockerfile` (`"dockerfile": "${localEnv:CC_CONFIG_DIR}/Dockerfile"`, `devcontainer-config/devcontainer.json` build key). With nothing exported, the build most likely fails on the missing `/Dockerfile` before anything is baked. "Bakes base-only egress" then describes the case where CC_CONFIG_DIR happens to be set, which is how the measured 2026-09-15 incident the comment cites came about (paraphrased — no quote available because the devcontainer CLI's handling of an absent absolute Dockerfile path was not executed: docker/devcontainer are off-limits in this review). The advice ("do not use the bare form") is right. A tighter line would say "bakes base-only egress and an empty config hash, mounts the shared ~/.claude volume, or fails to find its Dockerfile". This is the same mechanism text as the unchanged comment at `devcontainer-config/init-firewall.sh:343-345`.

**Evidence:** `devcontainer-config/cc-isolated.sh:534-567`, `devcontainer-config/devcontainer.json`, `devcontainer-config/init-firewall.sh:343-345`

---

## Claim 11: The two guides' advice matches init-firewall.sh's hint (PR intent; commit: "matching init-firewall.sh's hint (fc3bff82)")

**Location:** `devcontainer-config/init-firewall.sh:343-350`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers wording and command agreement between the hint and both edited guide passages, and that fc3bff82 introduced the hint; does not establish that the hint's own "rebuilds" premise covers CC freshness (Claim 8).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/init-firewall.sh:343-350
    # Not a bare `devcontainer up --remove-existing-container`: run from a normal
    # shell it drops the launcher's localEnv inputs and rebuilds with base-only
    # egress and an empty config hash (see rebuild_hint in cc-isolated.sh).
    # --probe-only always rebuilds from the blessed config and re-probes.
    echo "       If this container can no longer bootstrap, recreate it from the HOST" >&2
    echo "       with the launcher (the ~/.claude volume and the repo are unaffected):" >&2
    echo "         cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes" >&2
    echo "         cc-isolated <repo>                 # then start the session" >&2
```

(excerpt ends :350; the enclosing `fail_closed_on_abort` closes at :352 — read). Both guide passages use the same two commands, the same "rebuilds from the blessed config and re-probes" gloss, and the same base-only-egress/empty-hash reason. `git diff fc3bff82^1 fc3bff82 -- devcontainer-config/init-firewall.sh` adds these lines (`+    # --probe-only always rebuilds from the blessed config and re-probes.`).

**Evidence:** `devcontainer-config/init-firewall.sh:343-352`, `guides/cc-isolated-usage.md:935`, `guides/devcontainer-setup.md:389-394`, git fc3bff82

---

## Claim 12: Commit 330138d8: the PROBE FAIL row "points at the row below that explains why the bare form bakes base-only egress"; devcontainer-setup.md gets the "same fix, with the reason"

**Location:** commit 330138d8 message (body, bullets 1-2)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the diff does what the bullets say; content accuracy of the reason is in Claims 7 and 10.
**Legibility-target:** for-orchestrator-synthesis

The diff adds `— see the base-only egress row below` to the row at `guides/cc-isolated-usage.md:935`, and the row at `:942` exists (Claim 7). The devcontainer-setup hunk adds the launcher commands plus `it drops the launcher's `localEnv` inputs and bakes base-only egress and an empty config hash` (`guides/devcontainer-setup.md:392-394`).

**Evidence:** `guides/cc-isolated-usage.md:935`, `guides/cc-isolated-usage.md:942`, `guides/devcontainer-setup.md:389-394`

---

## Claim 13: Commit 330138d8: "Line 58 of cc-isolated-usage.md describes what the launcher does itself, so it is left as is (brief item 1)."

**Location:** commit 330138d8 message (Notes)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that line 58 describes the launcher's automatic recreate and that this matches the code; does not establish that the rest of that numbered list is current.
**Legibility-target:** for-orchestrator-synthesis

Line 58 is step 5 of "What a launch does, in order": `5. If the running container's baked hash is not the blessed one (you re-blessed since it was built), recreate it with `--remove-existing-container`. `devcontainer up` alone never rebuilds.` (`guides/cc-isolated-usage.md:58-60`). The launcher does this itself:

```bash
# devcontainer-config/cc-isolated.sh:893-896
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
  fi
```

The text describes what the launcher does, not a command for the user to run.

**Evidence:** `guides/cc-isolated-usage.md:58-60`, `devcontainer-config/cc-isolated.sh:887-896`

---

## Claim 14: Commit 330138d8: "The "Last verified" dates on the two guides are not bumped"; "Brief 2026-10-02-doc-drift-cycle1: Status open -> done."

**Location:** commit 330138d8 message (bullets and Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diff content for these two statements; does not judge whether bumping would have been right.
**Legibility-target:** for-orchestrator-synthesis

The guide headers are unchanged in the diff: `Last verified: 2026-09-09` (`guides/devcontainer-setup.md:3`) and `Last verified: 2026-09-27` (`guides/cc-isolated-usage.md:3`). The brief hunk is `-Status: open` / `+Status: done` (`docs/working/briefs/2026-10-02-doc-drift-cycle1.md:3`).

**Evidence:** `guides/devcontainer-setup.md:3`, `guides/cc-isolated-usage.md:3`, `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:3`

---

## Claims Requiring Attention

### Incorrect
- **Claim 8** (`guides/devcontainer-setup.md:389-391`): neither the launcher's `--probe-only` recreate nor the old bare form picks up a newer Claude Code. The `RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}` layer has a constant `latest` arg and sits above the per-project tail, so Docker's layer cache reuses it, and no path passes `--build-no-cache`. This premise predates the branch, which carries it forward. Fix: point at in-container `claude update`/auto-update, or document a no-cache rebuild (which would also need a launcher path).

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`AGENTS.md:36`, `GEMINI.md:36`): the step list leaves out the digest, the claim spot-check, the deep-audit/brainstorm step and the orchestrator half (dispatching build loops, landing). Global row 12 keeps the spot-check and brainstorm. The skill's output also includes the roadmap, cycle records and briefs, not only questions.md triage.
- **Claim 10** (`guides/devcontainer-setup.md:392-394`): the bare form also mounts the shared `cc--claude-config` volume and points the build at `/Dockerfile` (likely failing outright when nothing is exported). "Bakes base-only egress" is one outcome, not the whole consequence.

### Unverifiable
- None. Claims 8 and 10 carry Medium confidence because the devcontainer CLI could not be run (forbidden by the brief; not installed).

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report on the diff saved to the given path, structured per the code-fact-check skill.
- Answered: all 6 requested claim groups checked (14 claims): 11 Verified, 2 Mostly accurate, 1 Incorrect. The load-bearing question in item 2 is answered: `--probe-only` always recreates the container with the blessed config, but it does not pick up a newer CC, because the cached `npm install` layer is reused. The old bare advice had the same flaw.
- Out of scope: runtime execution of devcontainer/docker (forbidden); accuracy of unchanged guide text beyond the rows the new text points to; whether "Last verified" should have been bumped.
- Escalate: Claim 8. The "pick up a newer CC without a config change" sentence is false under either form. Fixing it properly may need a launcher change (e.g. a no-cache rebuild option), which the brief puts out of scope. The author needs to choose between rewording the guide (point at `claude update`) and filing a follow-up.
