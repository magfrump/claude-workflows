Commit: 330138d8

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-doc-drift (branch fix/doc-drift-cycle1)
**Scope:** branch diff `git diff main...HEAD` (AGENTS.md, GEMINI.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md) plus the commit message of 330138d8; claims traced into devcontainer-config/cc-isolated.sh, init-firewall.sh, devcontainer.json, Dockerfile, skills/dev-cycle/SKILL.md, global-instructions/CLAUDE.md
**Checked:** 2026-10-15
**Total claims checked:** 17
**Summary:** 14 verified, 2 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read; no logged pattern matches any claim below (grep for devcontainer/cache/rebuild/probe in its Patterns section returns nothing).

---

## Claim 1: "Maintenance or planning pass over the repo — "run the dev cycle", "maintenance pass", "what should we work on next", "update the roadmap""

**Location:** `AGENTS.md:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the four trigger phrases match the dev-cycle skill's own trigger list and CLAUDE.md row 12; does not establish that any harness actually routes on these phrases for non-Claude agents.
**Legibility-target:** for-orchestrator-synthesis

The skill's description ends `Triggers: "run the dev cycle", "maintenance pass", "what should we work on next", "update the roadmap".` (`skills/dev-cycle/SKILL.md:4`), and row 12 reads `**Maintenance or planning pass over the repo**, or keywords: "run the dev cycle", "maintenance pass", "what should we work on next", "update the roadmap"` (`global-instructions/CLAUDE.md:32`). The new row's trigger text is the same four phrases.

**Evidence:** `skills/dev-cycle/SKILL.md:4`, `global-instructions/CLAUDE.md:32`

---

## Claim 2: "User-started outer loop over research-plan-implement and pr-prep"

**Location:** `AGENTS.md:36`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that dev-cycle describes itself as the outer loop over the RPI -> pr-prep inner loop and that nothing schedules it (row 12: "User-started, no timer"); does not establish that it stops after one iteration once started (its step 10 "wait or go again" continues itself while build loops run).
**Legibility-target:** for-orchestrator-synthesis

`The outer loop. The inner loop (`research-plan-implement` → `pr-prep`, with its review-fix loop) lands one change at a time` (`skills/dev-cycle/SKILL.md:11-12`). Row 12 says `User-started, no timer.` (`global-instructions/CLAUDE.md:32`). The flow ends `→ 10 dispatch → final message → wait or go again` (`skills/dev-cycle/SKILL.md:264`), so "user-started" describes how a run begins, not that each iteration needs a user prompt.

**Evidence:** `skills/dev-cycle/SKILL.md:11-12`, `skills/dev-cycle/SKILL.md:256-264`, `global-instructions/CLAUDE.md:32`

---

## Claim 3: "health and cleanup, revisit triggers, watched questions, roadmap (`docs/roadmap.md`), then build briefs for its top items. Output is triage in `docs/working/questions.md`."

**Location:** `AGENTS.md:36`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every listed step exists in the skill in that order and that `docs/roadmap.md` is the roadmap path; does not establish that the list is complete (it is not) or that questions.md is the only output.
**Legibility-target:** for-author

Every named step exists: `### 1. Health and cleanup`, `### 2. Revisit triggers`, `### 3. Watched questions`, `### 6. Roadmap`, `### 8. Build briefs` (`skills/dev-cycle/SKILL.md:371,409,428,500,638`), and `Update `docs/roadmap.md`, creating it from this template if missing` (`skills/dev-cycle/SKILL.md:502`). The list is abridged further than row 12, which it otherwise mirrors: row 12 also names `claim spot-check, conditional deep-audit check and brainstorm` (`global-instructions/CLAUDE.md:32`), which the AGENTS row drops (steps 4, 4b, 5 at `skills/dev-cycle/SKILL.md:443,460,480`). Neither row names the orchestrator steps `7 collect → 8 build briefs → 9 record and land → 10 dispatch` (`skills/dev-cycle/SKILL.md:263-264`), so a reader of the AGENTS row would not learn that the cycle lands branches and dispatches build loops. "Output is triage in questions.md" is the row-12 wording; the skill also writes the roadmap, briefs and a cycle record (`cycle records are in docs/working/cycles/`, `skills/dev-cycle/SKILL.md:507-508`). Precise version: copy row 12's step list, and optionally add "collects, lands and dispatches build loops".

**Evidence:** `skills/dev-cycle/SKILL.md:256-264`, `skills/dev-cycle/SKILL.md:500-509`, `global-instructions/CLAUDE.md:32`

---

## Claim 4: GEMINI.md gains the same dev-cycle row, kept in sync with AGENTS.md

**Location:** `GEMINI.md:36`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-identity of the two files outside their header line and the no-@-import guard, as the repo's sync test defines them; does not establish the content claims of the row (Claims 1-3 apply equally to GEMINI.md).
**Legibility-target:** for-orchestrator-synthesis

Command `timeout 120 bats test/agents-gemini-sync.bats`, cwd `/workspace/.claude/wt-doc-drift`, started 2026-10-15T07:24:17Z, exit 0. Output: `ok 1 AGENTS.md and GEMINI.md content is in sync (ignoring headers)`, `ok 2 the import finder flags every form ...`, `ok 3 AGENTS.md and the global instructions have no @-imports`. A manual `diff` shows only line 3 (the tool-specific intro sentence) differs.

**Evidence:** `GEMINI.md:36`, `AGENTS.md:36`, captured output `/home/node/.claude/jobs/00bcf178/tmp/doc-drift/cfc-sync-bats.log`

---

## Claim 5: "Status: done"

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that each of the brief's four items has a corresponding edit in the diff and the sync bats passes; does not establish the acceptance criterion "the health check reports no skill divergence" (not run here) or the substantive correctness of item 2 (see Claim 15).
**Legibility-target:** for-orchestrator-synthesis

Brief items 1-4 (`docs/working/briefs/2026-10-02-doc-drift-cycle1.md:17-34`) map to the diff hunks in cc-isolated-usage.md, devcontainer-setup.md, guides/README.md, and AGENTS.md/GEMINI.md respectively (paraphrased — no quote available because the claim is a mapping across five files' hunks, each quoted in its own claim below).

**Evidence:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:17-48`

---

## Claim 6: "the exit scan of host-git inputs when a session ends, and `cc-push` for pushing a session's commits via a host-only clone"

**Location:** `guides/README.md:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that cc-isolated-usage.md has sections on both topics with matching descriptions; does not establish those sections' own accuracy.
**Legibility-target:** for-orchestrator-synthesis

The guide has `## Pushing: cc-push` (`guides/cc-isolated-usage.md:185`) and `### The exit scan is a tripwire (Q-069 [3], Q-076)` (`guides/cc-isolated-usage.md:302`); its command reference says `cc-push --remote <url> [REPO]     # push a session's commits via a host-only clone` (`guides/cc-isolated-usage.md:28`). The launcher header confirms the scan is of what host git reads at session end: `3  the exit scan found a change the session made to what host git reads` (`devcontainer-config/cc-isolated.sh:29-30`).

**Evidence:** `guides/cc-isolated-usage.md:28`, `guides/cc-isolated-usage.md:185`, `guides/cc-isolated-usage.md:302`, `devcontainer-config/cc-isolated.sh:19-31`

---

## Claim 7: "`cc-isolated --probe-only <repo>` (rebuilds from the blessed config and re-probes)"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the probe action's path in main(): manifest check, blessed hash exported, container removed and recreated with the launcher-set localEnv, boundary probe run; does not establish that the recreate picks up newer image layers (Docker layer cache applies — see Claim 15) or that it un-bricks a cause outside the container (e.g. a host network outage).
**Legibility-target:** for-orchestrator-synthesis

`--probe-only) action="probe"; shift ;;` (`devcontainer-config/cc-isolated.sh:735`). Before the action branch, main runs `check_manifest`, sets `CC_CONFIG_HASH="$(blessed_hash)"` and exports `CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR` (`devcontainer-config/cc-isolated.sh:822-834`). Then:

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

A fresh container runs `postStartCommand` `sudo /usr/local/bin/init-firewall.sh && ...` (`devcontainer-config/devcontainer.json`, `postStartCommand`), so the firewall gets a fresh first run; `probe_boundary` includes the `PROBE FAIL (firewall)` sentinel check (`devcontainer-config/cc-isolated.sh:690-695`). Under `set -euo pipefail` (`:66`) a failing probe aborts before `exit 0`.

**Evidence:** `devcontainer-config/cc-isolated.sh:66`, `devcontainer-config/cc-isolated.sh:735`, `devcontainer-config/cc-isolated.sh:822-885`, `devcontainer-config/cc-isolated.sh:685-700`, `devcontainer-config/devcontainer.json`

---

## Claim 8: "then `cc-isolated <repo>`" (starts the session)

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the launch action reuses the container --probe-only just built (hash matches) and starts claude after a passing probe; does not establish the single-step alternative the launcher's own `rebuild_hint` prints ("cc-isolated <ws> ... rebuilds"), which does not recreate a container whose hash already matches.
**Legibility-target:** for-orchestrator-synthesis

The launch path runs `devcontainer up "${dc[@]}"`, recreates only `if ! container_config_matches "${dc[@]}"`, then `probe_boundary`, then `devcontainer exec "${dc[@]}" claude || rc=$?` (`devcontainer-config/cc-isolated.sh:887-922`, read through the exit-scan `case` at `:925-930`). After --probe-only, the container carries the blessed hash, so it is reused and the session starts. Side note (not a doc-diff defect): `rebuild_hint` advertises `cc-isolated $(printf '%q' "$ws")        # the supported path: rebuilds, re-probes, re-launches` (`devcontainer-config/cc-isolated.sh:560`), but plain launch does not rebuild a hash-matching bricked container; the two-step form in the diff is the one that actually rebuilds.

**Evidence:** `devcontainer-config/cc-isolated.sh:556-567`, `devcontainer-config/cc-isolated.sh:887-930`

---

## Claim 9: "Not a bare `devcontainer up --remove-existing-container …` from your own shell — see the base-only egress row below."

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that a row below exists and explains the base-only/empty-hash consequence of the bare form; does not establish the other consequences rebuild_hint names (shared volume from empty CC_PROJECT_ID, /Dockerfile from empty CC_CONFIG_DIR), which that row omits.
**Legibility-target:** for-orchestrator-synthesis

Row at `guides/cc-isolated-usage.md:941`: `The container was rebuilt with a bare `devcontainer up --remove-existing-container …` from your own shell. `devcontainer.json` reads `CC_EGRESS_PROFILE` and `CC_CONFIG_HASH` via `${localEnv:…}`, and only `cc-isolated` exports them — run by hand they resolve to the empty string, so the image bakes base-only egress`. This matches `"CC_EGRESS_PROFILE": "${localEnv:CC_EGRESS_PROFILE}"` and `"CC_CONFIG_HASH": "${localEnv:CC_CONFIG_HASH}"` in `devcontainer-config/devcontainer.json` (build.args).

**Evidence:** `guides/cc-isolated-usage.md:941`, `devcontainer-config/devcontainer.json` (build.args), `devcontainer-config/cc-isolated.sh:536-547`

---

## Claim 10: "Line 58 of cc-isolated-usage.md describes what the launcher does itself, so it is left as is"

**Location:** commit 330138d8 message (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the step-5 text at lines 57-59 describes main()'s automatic hash-mismatch recreate, not advice to run by hand; does not establish the rest of the "What a launch does" list.
**Legibility-target:** for-orchestrator-synthesis

`5. If the running container's baked hash is not the blessed one (you re-blessed since it was built), recreate it with `--remove-existing-container`. `devcontainer up` alone never rebuilds.` (`guides/cc-isolated-usage.md:57-59`) matches:

```bash
# devcontainer-config/cc-isolated.sh:892-896
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
  fi
```

That call runs inside main with the localEnv exports in place, so it is not the hazardous bare form.

**Evidence:** `guides/cc-isolated-usage.md:57-59`, `devcontainer-config/cc-isolated.sh:887-896`

---

## Claim 11: "matching init-firewall.sh's hint (fc3bff82)"

**Location:** commit 330138d8 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the hint exists and reached main via merge fc3bff82; does not establish that fc3bff82 itself authored it (48a8200b did).
**Legibility-target:** for-orchestrator-synthesis

`git log -S'rebuilds from the blessed config, re-probes' -- devcontainer-config/init-firewall.sh` returns `48a8200b fix(devcontainer): point init-firewall's fail-closed hint at the launcher`; 48a8200b is an ancestor of `fc3bff82 Merge branch 'si4/devc'` but not of its first parent c39f66c5, so fc3bff82 is where it landed on main (paraphrased — no quote available because the evidence is git ancestry output, not file text).

**Evidence:** `devcontainer-config/init-firewall.sh:343-350`, git objects 48a8200b, fc3bff82

---

## Claim 12: The two guides' new advice is consistent with init-firewall.sh's hint

**Location:** `guides/cc-isolated-usage.md:935`, `guides/devcontainer-setup.md:390-394`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers wording and command consistency between the two guide passages and the init-firewall hint; does not establish consistency with cc-isolated.sh's `rebuild_hint`, which names a single `cc-isolated <ws>` step instead (Claim 8).
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

(excerpt ends :350; enclosing `fail_closed_on_abort` continues to :352 — read.) Both guides use the same two commands, same order, and the devcontainer-setup wording reuses the comment's phrasing nearly verbatim.

**Evidence:** `devcontainer-config/init-firewall.sh:336-352`

---

## Claim 13: "points at the row below that explains why the bare form bakes base-only egress"

**Location:** commit 330138d8 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 9 (row 941 exists below row 935 and explains it); does not establish more.
**Legibility-target:** for-orchestrator-synthesis

Row 935 ends `see the base-only egress row below.` and row 941 begins `A newly registered profile has no effect — the container's egress is still base-only` (`guides/cc-isolated-usage.md:935,941`).

**Evidence:** `guides/cc-isolated-usage.md:935`, `guides/cc-isolated-usage.md:941`

---

## Claim 14: "`cc-isolated --probe-only <repo>` (always rebuilds from the blessed config and re-probes)"

**Location:** `guides/devcontainer-setup.md:390-391`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the probe action unconditionally passes `--remove-existing-container` with the blessed hash exported and then probes; does not establish that "rebuild" means a cache-free image build (it does not — see Claim 15).
**Legibility-target:** for-orchestrator-synthesis

Same path as Claim 7: `devcontainer up --remove-existing-container "${dc[@]}"` followed by `probe_boundary "$ws"`, unconditional within the `probe` branch (`devcontainer-config/cc-isolated.sh:880-885`), with `CC_CONFIG_HASH="$(blessed_hash)"` exported first (`devcontainer-config/cc-isolated.sh:832-834`).

**Evidence:** `devcontainer-config/cc-isolated.sh:822-885`

---

## Claim 15: "to pick up a newer CC *without* a config change, recreate it with the launcher: `cc-isolated --probe-only <repo>` ..., then `cc-isolated <repo>`"

**Location:** `guides/devcontainer-setup.md:389-391`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether recreating the container through the probe action re-runs the Claude Code install layer; does not establish the devcontainer CLI's exact build invocation by execution (no docker/devcontainer in this sandbox), and does not cover in-container `claude update` / auto-update, which can update CC at runtime regardless of the image.
**Legibility-target:** for-author

The probe action only adds `--remove-existing-container` (`devcontainer-config/cc-isolated.sh:883`); it passes no cache-busting flag and the repo has none anywhere (`grep -rn 'no-cache|build-no-cache|cache-from|CACHEBUST'` over devcontainer-config/, guides/ returns nothing — paraphrased, no quote available because the claim covers absence of code). The CC install layer's cache key never changes: the build arg is a literal `"CLAUDE_CODE_VERSION": "latest"` (`devcontainer-config/devcontainer.json`, build.args) feeding

```dockerfile
# devcontainer-config/Dockerfile:402-403
# Install Claude
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}
```

and the only per-bless/per-project args are declared after it, by design so the earlier layers are reused: `CC_EGRESS_PROFILE is the only build arg that varies between projects, so declaring it here means every layer above is shared across all projects' images` (`devcontainer-config/Dockerfile:474-477`; `ARG CC_CONFIG_HASH=""` at `:484`). A recreate therefore rebuilds the image from Docker's layer cache, and the `@latest` layer (same instruction text, same arg value) is a cache hit that keeps the old CC version (paraphrased — no quote available because this is Docker/devcontainer-CLI build-cache behaviour, external to the repo; the CLI's `up` builds with cache unless `--build-no-cache` is passed — not executed here, hence Medium). This is not a regression: the replaced bare `devcontainer up --remove-existing-container` had the same cache behaviour (and additionally baked base-only egress). The newly added "Not a bare ..." sentence is correct (Claim 16); the error is the goal this remedy is attached to. Fix: say a newer CC needs a cache-busting rebuild (e.g. pin/bump `CLAUDE_CODE_VERSION`, or a no-cache build path the launcher does not currently offer), or rely on in-container `claude update`; the same reasoning also undercuts the unchanged preceding sentence's implication that a re-bless recreate refreshes CC.

**Evidence:** `devcontainer-config/cc-isolated.sh:880-885`, `devcontainer-config/Dockerfile:19`, `devcontainer-config/Dockerfile:402-403`, `devcontainer-config/Dockerfile:473-484`, `devcontainer-config/devcontainer.json` (build.args)

---

## Claim 16: "Not a bare `devcontainer up --remove-existing-container …` from your own shell: it drops the launcher's `localEnv` inputs and bakes base-only egress and an empty config hash (see `rebuild_hint` in `cc-isolated.sh`)"

**Location:** `guides/devcontainer-setup.md:391-394`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the localEnv-to-empty-string mechanism for CC_EGRESS_PROFILE and CC_CONFIG_HASH and that rebuild_hint documents it; does not establish the further harms rebuild_hint lists but the guide omits (shared `cc--claude-config` volume from empty CC_PROJECT_ID; build pointed at /Dockerfile from empty CC_CONFIG_DIR).
**Legibility-target:** for-orchestrator-synthesis

`rebuild_hint`'s comment: `A bare `devcontainer up --remove-existing-container` copied out of an error message and run from your own shell therefore resolves them all to the EMPTY string: an empty CC_EGRESS_PROFILE/CC_CONFIG_HASH bakes base-only egress and an empty /etc/cc-config-hash` (`devcontainer-config/cc-isolated.sh:539-543`). The Dockerfile writes those args verbatim: `printf '%s\n' "${CC_EGRESS_PROFILE}" > /etc/cc-egress-profile` and `printf '%s\n' "${CC_CONFIG_HASH}" > /etc/cc-config-hash` (`devcontainer-config/Dockerfile:524,526`). The exports exist only in main (`devcontainer-config/cc-isolated.sh:822-834`).

**Evidence:** `devcontainer-config/cc-isolated.sh:534-567`, `devcontainer-config/cc-isolated.sh:822-834`, `devcontainer-config/Dockerfile:478-527`, `devcontainer-config/devcontainer.json` (build.args)

---

## Claim 17: "The "Last verified" dates on the two guides are not bumped"

**Location:** commit 330138d8 message (Notes)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the diff touches no Last-verified line; does not establish the accompanying assertion that "only the edited passages were re-checked against the code", which is a process claim and, for devcontainer-setup.md, missed the newer-CC defect (Claim 15).
**Legibility-target:** for-author

The diff's only hunks in the two guides are at `@@ -932,7 +932,7 @@` and `@@ -387,7 +387,11 @@` (diff.patch), neither touching a `Last verified` header (paraphrased — no quote available because the claim is about absence of a change in the diff). The factual part holds; the implied completeness of the re-check of the edited Image-lifecycle passage does not, since its stated goal is not achieved (Claim 15).

**Evidence:** `guides/devcontainer-setup.md:387-397`, `guides/cc-isolated-usage.md:935`

---

## Claims Requiring Attention

### Incorrect
- **Claim 15** (`guides/devcontainer-setup.md:389-391`): `--probe-only` recreates the container but builds with Docker's layer cache; the `npm install -g @anthropic-ai/claude-code@latest` layer (constant arg, declared before the per-project args) is a cache hit, so this does not pick up a newer CC. Inherited from the old bare advice, not introduced. Reword the goal or name a cache-busting path / in-container `claude update`.

### Stale
- (none)

### Mostly Accurate
- **Claim 3** (`AGENTS.md:36`, same in `GEMINI.md:36`): step list drops row 12's "claim spot-check, conditional deep-audit check and brainstorm" and, like row 12, omits collect / record-and-land / dispatch; outputs also include roadmap, briefs, cycle record. Copy row 12's list.
- **Claim 17** (commit 330138d8 Notes): factual part true; the "edited passages were re-checked" assurance missed Claim 15.

### Unverifiable
- (none)

Side note outside the diff (not counted): `rebuild_hint` (`devcontainer-config/cc-isolated.sh:560`) says plain `cc-isolated <ws>` "rebuilds, re-probes, re-launches", but launch only recreates on a hash mismatch; the diff's two-step `--probe-only` then launch is the form that actually rebuilds.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report on the diff saved to the given path, structured per the code-fact-check skill.
- Answered: all six requested claim areas checked (17 claims): probe-only path traced through main(); row-below reference confirmed; init-firewall consistency confirmed; README coverage confirmed; dev-cycle row checked against SKILL.md and row 12; commit-message claims incl. Line 58 confirmed. One Incorrect (newer-CC goal unachievable via cached rebuild), two Mostly accurate.
- Out of scope: running docker/devcontainer (forbidden and absent), so the layer-cache conclusion is static (Medium); the health check's skill-divergence criterion was not run; rebuild_hint's own wording is outside the diff.
- Escalate: Claim 15 — whether to fix the Image-lifecycle sentence in this branch (doc-only, within brief scope) or queue it; the fix needs a decision on the supported way to refresh CC (version pin bump, a no-cache rebuild path, or rely on `claude update`).
