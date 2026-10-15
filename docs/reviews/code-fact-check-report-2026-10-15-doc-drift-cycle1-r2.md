Commit: 330138d8

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-doc-drift (branch fix/doc-drift-cycle1)
**Scope:** branch diff `git diff main...HEAD` (AGENTS.md, GEMINI.md, docs/working/briefs/2026-10-02-doc-drift-cycle1.md, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md) plus the commit message of 330138d8; claims traced into devcontainer-config/cc-isolated.sh, init-firewall.sh, devcontainer.json, Dockerfile, skills/dev-cycle/SKILL.md, global-instructions/CLAUDE.md
**Checked:** 2026-10-15
**Total claims checked:** 17
**Summary:** 15 verified, 1 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) was read first; no claim below matches a logged pattern.

---

## Claim 1: "run the dev cycle", "maintenance pass", "what should we work on next", "update the roadmap" (dev-cycle trigger list)

**Location:** `AGENTS.md:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the four trigger phrases match the skill's own description and CLAUDE.md row 12 exactly; does not establish anything about how a harness routes on them.
**Legibility-target:** for-orchestrator-synthesis

The skill description ends: `Triggers: "run the dev cycle", "maintenance pass", "what should we work on next", "update the roadmap".` (`skills/dev-cycle/SKILL.md:4`). CLAUDE.md row 12 lists the same four: `keywords: "run the dev cycle", "maintenance pass", "what should we work on next", "update the roadmap"` (`global-instructions/CLAUDE.md:32`).

**Evidence:** `skills/dev-cycle/SKILL.md:4`, `global-instructions/CLAUDE.md:32`

---

## Claim 2: "User-started outer loop over research-plan-implement and pr-prep"

**Location:** `AGENTS.md:36`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the outer-loop/inner-loop relationship and that row 12 calls it user-started; does not establish that the skill itself forbids scheduled starts (SKILL.md is silent on who starts it; `/loop /dev-cycle` repeats it once started).
**Legibility-target:** for-orchestrator-synthesis

`The outer loop. The inner loop (\`research-plan-implement\` → \`pr-prep\`, with its review-fix loop) lands one change at a time` (`skills/dev-cycle/SKILL.md:11-12`). Row 12: `The outer loop over rows 6/9 … User-started, no timer.` (`global-instructions/CLAUDE.md:32`); rows 6 and 9 are research-plan-implement and pr-prep. SKILL.md contains no cron/timer start (paraphrased — no quote available because the claim covers absence of code: `grep -i "cron\|timer\|schedul"` over SKILL.md returns nothing; the only repetition mechanism named is `` `/loop /dev-cycle` repeats it `` at `:4`).

**Evidence:** `skills/dev-cycle/SKILL.md:4`, `skills/dev-cycle/SKILL.md:11-17`, `global-instructions/CLAUDE.md:32`

---

## Claim 3: "health and cleanup, revisit triggers, watched questions, roadmap (`docs/roadmap.md`), then build briefs for its top items. Output is triage in `docs/working/questions.md`."

**Location:** `AGENTS.md:36`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every listed step and both paths exist in the skill in that order; does not establish completeness — the row omits steps and outputs the skill has.
**Legibility-target:** for-author

Every named step exists, in order: `0 start and digest → 1 health and cleanup → { 2 triggers | 3 questions | 4 spot-check | 4b audit check } → 5 brainstorm (conditional) → 6 roadmap → 7 collect → 8 build briefs → 9 record and land → 10 dispatch` (`skills/dev-cycle/SKILL.md:262-264`); step 6 is `Update \`docs/roadmap.md\`` (`:502`); questions go to `docs/working/questions.md` (`:92`). The row drops the claim spot-check, deep-audit check and brainstorm that CLAUDE.md row 12 keeps (`claim spot-check, conditional deep-audit check and brainstorm` — `global-instructions/CLAUDE.md:32`), and, like row 12, omits the orchestrator steps 7, 9, 10 (collect build-loop results, record and land, dispatch build loops). "Output is triage in questions.md" understates the outputs: the skill also writes the roadmap, the cycle record and build briefs, and lands merges (`write build briefs into free slots, record and land, and dispatch build loops` — `:4`). Precise version: either list "claim spot-check, conditional deep-audit and brainstorm" as row 12 does, or say "steps include". Not misleading for routing.

**Evidence:** `skills/dev-cycle/SKILL.md:4`, `skills/dev-cycle/SKILL.md:92`, `skills/dev-cycle/SKILL.md:262-264`, `skills/dev-cycle/SKILL.md:502`, `global-instructions/CLAUDE.md:32`

---

## Claim 4: GEMINI.md dev-cycle row is kept in sync with AGENTS.md (diff intent; brief acceptance criterion "test/agents-gemini-sync.bats and the AGENTS.md no-import guard pass")

**Location:** `GEMINI.md:36`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-identity of the two rows and the three bats tests passing at HEAD 330138d8; does not establish the brief's separate criterion that the health check reports no skill divergence (not run).
**Legibility-target:** for-orchestrator-synthesis

`GEMINI.md:36` and `AGENTS.md:36` are character-identical (both lines printed by one `grep -n dev-cycle AGENTS.md GEMINI.md`). Executed: `timeout 120 bats test/agents-gemini-sync.bats`, cwd `/workspace/.claude/wt-doc-drift`, 2026-10-15T07:24:01Z, exit 0; output: `ok 1 AGENTS.md and GEMINI.md content is in sync (ignoring headers)`, `ok 2 the import finder flags every form …`, `ok 3 AGENTS.md and the global instructions have no @-imports` (plus locale warnings).

**Evidence:** `AGENTS.md:36`, `GEMINI.md:36`, `test/agents-gemini-sync.bats`, /home/node/.claude/jobs/00bcf178/tmp/doc-drift/cfc-r2-bats.log

---

## Claim 5: "Status: done" (brief items 1-4 completed per acceptance criteria)

**Location:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that each of the four acceptance criteria's doc changes is present in the diff (items 1-2 recommend the launcher, item 3 mentions cc-push and the exit scan, item 4 adds dev-cycle to both files) and that the sync bats pass (Claim 4); does not establish the health-check "no skill divergence" criterion, and does not re-adjudicate whether the item-2 advice actually picks up a newer CC (Claim 13).
**Legibility-target:** for-orchestrator-synthesis

Criteria: `Items 1–2 recommend the launcher (\`cc-isolated --probe-only NAME\`, then \`cc-isolated NAME\`) and do not recommend a bare …` (brief, Acceptance criteria); both guide edits do (`guides/cc-isolated-usage.md:935`, `guides/devcontainer-setup.md:390-392`). `Item 3 mentions cc-push and the exit scan` — `guides/README.md:49` does. Item 4 — Claims 1-4.

**Evidence:** `docs/working/briefs/2026-10-02-doc-drift-cycle1.md:3`, `guides/README.md:49`, `guides/cc-isolated-usage.md:935`, `guides/devcontainer-setup.md:387-397`

---

## Claim 6: cc-isolated-usage.md covers "the exit scan of host-git inputs when a session ends"

**Location:** `guides/README.md:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the guide documents the exit scan and that it compares what host git reads, at session end; does not establish the scan's own correctness.
**Legibility-target:** for-orchestrator-synthesis

The guide: `Before step 4 the launcher snapshots what host git reads to decide what to run (hooks, configs, …); when claude exits it compares, and exits **3** naming anything the session added, removed or` (`guides/cc-isolated-usage.md:57-59`, excerpt ends mid-step 7, which continues to `:68` — read), and a full section `### The exit scan is a tripwire (Q-069 [3], Q-076)` (`:302`). Code: `git_exit_scan "$ws" "$git_before" "$lws"` after `devcontainer exec "${dc[@]}" claude` (`devcontainer-config/cc-isolated.sh:927-932`).

**Evidence:** `guides/cc-isolated-usage.md:57-68`, `guides/cc-isolated-usage.md:302`, `devcontainer-config/cc-isolated.sh:922-940`

---

## Claim 7: cc-isolated-usage.md covers "`cc-push` for pushing a session's commits via a host-only clone"

**Location:** `guides/README.md:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the guide has a cc-push section using the "host-only clone" description; does not establish cc-push.sh's behaviour.
**Legibility-target:** for-orchestrator-synthesis

`## Pushing: cc-push` (`guides/cc-isolated-usage.md:185`); command reference: `cc-push --remote <url> [REPO]     # push a session's commits via a host-only clone; first` (`:28`).

**Evidence:** `guides/cc-isolated-usage.md:28-33`, `guides/cc-isolated-usage.md:185`

---

## Claim 8: "`cc-isolated --probe-only <repo>` (rebuilds from the blessed config and re-probes)"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the launcher's probe action as code: it exports the blessed hash and all localEnv inputs, unconditionally recreates the container, then runs the self-probe; does not establish at runtime that a fresh container gets past a persisting outage (execution blocked: no docker/devcontainer in the sandbox, and starting them is out of bounds), nor that "rebuild" means an uncached image build (see Claim 13).
**Legibility-target:** for-orchestrator-synthesis

Flag parsing: `--probe-only) action="probe"; shift ;;` and `*) ws_arg="$1"; shift ;;` (`devcontainer-config/cc-isolated.sh:735`, `:749`). Before the action branch main exports the inputs: `export CC_PROJECT_ID CC_PROJECT_NAME CC_EGRESS_PROFILE CC_CONFIG_DIR` (`:821`), `CC_CONFIG_HASH="$(blessed_hash)"` / `export CC_CONFIG_HASH` (`:831-832`). Then:

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

Under `set -euo pipefail` (`:66`) a failing `probe_boundary` (`return 1`, `:700`) exits non-zero before `exit 0`. A recreated container runs its postStartCommand, i.e. a fresh init-firewall.sh run (paraphrased — no quote available because postStartCommand is in devcontainer.json and its firing on new containers is devcontainer CLI behaviour; the launcher's own comment at `:898-900` confirms `devcontainer up` on a running container skips it, implying a new one runs it).

**Evidence:** `devcontainer-config/cc-isolated.sh:66`, `devcontainer-config/cc-isolated.sh:729-749`, `devcontainer-config/cc-isolated.sh:803-832`, `devcontainer-config/cc-isolated.sh:880-885`, `devcontainer-config/cc-isolated.sh:697-704`

---

## Claim 9: "then `cc-isolated <repo>`" starts the session

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the launch path after a successful --probe-only: no further rebuild, re-probe, then claude; does not establish that `cc-isolated <repo>` alone (without the preceding --probe-only) would recover a firewall-bricked container — it would not (see Out of scope note).
**Legibility-target:** for-orchestrator-synthesis

Launch path: `devcontainer up "${dc[@]}"` (`devcontainer-config/cc-isolated.sh:887`); rebuild only `if ! container_config_matches "${dc[@]}"` (`:892-895`), which is false right after --probe-only baked the blessed hash; then `if ! probe_boundary "$ws"; then` (re-assert path) (`:901`), then `devcontainer exec "${dc[@]}" claude || rc=$?` (`:927`).

**Evidence:** `devcontainer-config/cc-isolated.sh:887-926`, `devcontainer-config/cc-isolated.sh:570-574`

---

## Claim 10: "Not a bare `devcontainer up --remove-existing-container …` from your own shell — see the base-only egress row below."

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the referenced row exists below (at :941, six rows down) and explains the harm via localEnv; does not establish the row's further claims beyond the egress/hash mechanism.
**Legibility-target:** for-orchestrator-synthesis

`guides/cc-isolated-usage.md:941`: `The container was rebuilt with a bare \`devcontainer up --remove-existing-container …\` from your own shell. \`devcontainer.json\` reads \`CC_EGRESS_PROFILE\` and \`CC_CONFIG_HASH\` via \`${localEnv:…}\`, and only \`cc-isolated\` exports them — run by hand they resolve to the empty string, so the image bakes base-only egress`. Backed by config: `"CC_EGRESS_PROFILE": "${localEnv:CC_EGRESS_PROFILE}"`, `"CC_CONFIG_HASH": "${localEnv:CC_CONFIG_HASH}"` (`devcontainer-config/devcontainer.json:50`, `:54`).

**Evidence:** `guides/cc-isolated-usage.md:941`, `devcontainer-config/devcontainer.json:50-54`

---

## Claim 11: Guide rows match init-firewall.sh's hint

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers wording/command consistency of both guide edits with the hint and its comment; does not establish the hint's runtime emission paths.
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
(excerpt ends :350; enclosing fail_closed_on_abort continues to :352 — read.) Both guide edits use the same two commands in the same order and the devcontainer-setup edit reuses the comment's reasoning nearly verbatim.

**Evidence:** `devcontainer-config/init-firewall.sh:336-352`, `guides/cc-isolated-usage.md:935`, `guides/devcontainer-setup.md:390-394`

---

## Claim 12: "`cc-isolated --probe-only <repo>` (always rebuilds from the blessed config and re-probes)"

**Location:** `guides/devcontainer-setup.md:390-391`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the probe action passes `--remove-existing-container` unconditionally with the blessed hash exported, then probes; does not establish that "rebuilds" means a cache-free image build — it is a normal (cached) build of a new container (see Claim 13).
**Legibility-target:** for-orchestrator-synthesis

Same code as Claim 8: `devcontainer up --remove-existing-container "${dc[@]}"` with no condition inside `if [ "$action" = "probe" ]` (`devcontainer-config/cc-isolated.sh:880-885`); the comment says `--probe-only is the verification command, so it always rebuilds` (`:881`). No `--build-no-cache` anywhere (paraphrased — no quote available because the claim covers absence of code: `grep -n "no-cache"` over cc-isolated.sh returns nothing).

**Evidence:** `devcontainer-config/cc-isolated.sh:880-885`, `devcontainer-config/cc-isolated.sh:831-832`

---

## Claim 13: "to pick up a newer CC *without* a config change, recreate it with the launcher: `cc-isolated --probe-only <repo>` … then `cc-isolated <repo>`"

**Location:** `guides/devcontainer-setup.md:388-392`
**Type:** Behavioral / Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the launcher invokes and what the Dockerfile caches; does not establish the actual build outcome — execution required (a docker build with a warm cache), blocked because neither `docker` nor `devcontainer` exists in the sandbox and the review brief forbids starting them. Static evidence points to the advice NOT achieving its goal.
**Legibility-target:** for-orchestrator-synthesis (static evidence leans Incorrect; see Escalate)

The CC install is an ordinary cached layer keyed on an unchanging argument:

```dockerfile
# devcontainer-config/Dockerfile:19
ARG CLAUDE_CODE_VERSION=latest
# devcontainer-config/Dockerfile:402-403
# Install Claude
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}
```

and devcontainer.json passes the literal `"CLAUDE_CODE_VERSION": "latest"` (`devcontainer-config/devcontainer.json:29`). The only per-launch-varying build args, `CC_EGRESS_PROFILE` and `CC_CONFIG_HASH`, are declared after it (`devcontainer-config/Dockerfile:478`, `:484`), so they cannot invalidate the line-403 layer. The probe action recreates the container via `devcontainer up --remove-existing-container "${dc[@]}"` with no cache-busting flag (`devcontainer-config/cc-isolated.sh:883`). Under Docker's documented build-cache rules (paraphrased — no quote available because this is Docker/BuildKit behaviour, external to the repo: a `RUN` layer is reused when its parent layers, command string and consumed ARG values are unchanged; `@latest` is not re-resolved), the rebuilt image would reuse the old `npm install` layer and bake the same CC version unless an earlier layer changed or the cache was pruned. Doing this needs `devcontainer up --build-no-cache` (or `docker builder prune`) — neither the launcher nor the guide offers that.

This is not a regression: the replaced advice (`devcontainer up --remove-existing-container …` by hand, per the diff's `-` line) had the identical cache gap. The new text adds "always rebuilds", which a reader is more likely to take as "fetches latest". Separately, CC in the container auto-updates at runtime (the guide's own troubleshooting row: `Claude Code auto-update fails every launch in ONE project` — `guides/cc-isolated-usage.md:940`), which is probably how newer CC actually arrives; the guide does not say so here.

**Evidence:** `devcontainer-config/Dockerfile:19`, `devcontainer-config/Dockerfile:402-403`, `devcontainer-config/Dockerfile:474-526`, `devcontainer-config/devcontainer.json:24-54`, `devcontainer-config/cc-isolated.sh:880-885`, `guides/cc-isolated-usage.md:940`

---

## Claim 14: a bare `devcontainer up --remove-existing-container …` "drops the launcher's `localEnv` inputs and bakes base-only egress and an empty config hash (see `rebuild_hint` in `cc-isolated.sh`)"

**Location:** `guides/devcontainer-setup.md:392-394`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the localEnv mechanism, the egress/hash consequence, and that `rebuild_hint` documents it; does not establish the other consequences rebuild_hint lists (shared `cc--claude-config` volume from empty CC_PROJECT_ID, build pointed at /Dockerfile from empty CC_CONFIG_DIR), which the guide omits.
**Legibility-target:** for-orchestrator-synthesis

`rebuild_hint` exists (`rebuild_hint() {`, `devcontainer-config/cc-isolated.sh:557`) and its header says: `devcontainer.json reads CC_PROJECT_ID, CC_PROJECT_NAME, CC_CONFIG_DIR, CC_EGRESS_PROFILE and CC_CONFIG_HASH through \`${localEnv:...}\`, and main() is the only thing that sets them. … an empty CC_EGRESS_PROFILE/CC_CONFIG_HASH bakes base-only egress and an empty /etc/cc-config-hash` (`:537-543`). Config side: `"CC_EGRESS_PROFILE": "${localEnv:CC_EGRESS_PROFILE}"`, `"CC_CONFIG_HASH": "${localEnv:CC_CONFIG_HASH}"` (`devcontainer-config/devcontainer.json:50`, `:54`); Dockerfile bakes them: `printf '%s\n' "${CC_EGRESS_PROFILE}" > /etc/cc-egress-profile` and `printf '%s\n' "${CC_CONFIG_HASH}" > /etc/cc-config-hash` (`devcontainer-config/Dockerfile:524`, `:526`).

**Evidence:** `devcontainer-config/cc-isolated.sh:534-567`, `devcontainer-config/cc-isolated.sh:803-832`, `devcontainer-config/devcontainer.json:20-54`, `devcontainer-config/Dockerfile:478-526`

---

## Claim 15: commit body — the PROBE FAIL row now matches "init-firewall.sh's hint (fc3bff82)"

**Location:** `git:330138d8` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that fc3bff82 is the merge that replaced the bare hint with the launcher hint; does not establish anything about fc3bff82's other changes.
**Legibility-target:** for-orchestrator-synthesis

`git diff fc3bff82^1 fc3bff82 -- devcontainer-config/init-firewall.sh` shows `-         devcontainer up --remove-existing-container --workspace-folder <repo>` replaced by `+         cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes` and `+         cc-isolated <repo>                 # then start the session`. fc3bff82 is `Merge branch 'si4/devc'`.

**Evidence:** `git show fc3bff82`, `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 16: commit body — "Line 58 of cc-isolated-usage.md describes what the launcher does itself, so it is left as is"

**Location:** `git:330138d8` (commit message); `guides/cc-isolated-usage.md:57-59`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that line 58 (step 5 of "What a launch does") describes main()'s automatic hash-mismatch rebuild, not advice to run by hand, and that the diff leaves it untouched; does not establish the rest of that section's accuracy.
**Legibility-target:** for-orchestrator-synthesis

`5. If the running container's baked hash is not the blessed one (you re-blessed since it was built), recreate it with \`--remove-existing-container\`. \`devcontainer up\` alone never rebuilds.` (`guides/cc-isolated-usage.md:57-59`), under `## What a launch does, in order` (`:45`). Code: `if ! container_config_matches "${dc[@]}"; then` … `devcontainer up --remove-existing-container "${dc[@]}"` (`devcontainer-config/cc-isolated.sh:892-895`). The diff touches only line 935 of this file.

**Evidence:** `guides/cc-isolated-usage.md:45-59`, `devcontainer-config/cc-isolated.sh:887-896`

---

## Claim 17: commit body — file-by-file summary, and "The 'Last verified' dates on the two guides are not bumped"

**Location:** `git:330138d8` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the six bullets match the six files in `git diff --stat main...HEAD` and that neither guide's `Last verified` line changed; does not verify the body's claim that "only the edited passages were re-checked" (a process claim).
**Legibility-target:** for-orchestrator-synthesis

`git diff main...HEAD --stat` lists exactly AGENTS.md, GEMINI.md, the brief, guides/README.md, guides/cc-isolated-usage.md, guides/devcontainer-setup.md (`6 files changed, 10 insertions(+), 4 deletions(-)`). Header lines are unchanged: `Last verified: 2026-09-27` (`guides/cc-isolated-usage.md:3`) and `Last verified: 2026-09-09` (`guides/devcontainer-setup.md:3`); no hunk touches line 3 of either.

**Evidence:** `guides/cc-isolated-usage.md:3`, `guides/devcontainer-setup.md:3`, diff.patch

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 3** (`AGENTS.md:36`, same text `GEMINI.md:36`): the step list drops claim spot-check / deep-audit / brainstorm (which CLAUDE.md row 12 keeps) and the orchestrator steps; "Output is triage in questions.md" understates the outputs. Match row 12's list or mark it as a partial list.

### Unverifiable
- **Claim 13** (`guides/devcontainer-setup.md:388-392`): "to pick up a newer CC without a config change, recreate with `--probe-only`". Needs a warm-cache docker build to confirm. Static reading (cached `RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}` with constant `latest`, no `--build-no-cache`) says the rebuilt image likely keeps the old CC. Same gap as the replaced bare advice, so not a regression, but "always rebuilds" makes it read more like a fix than it is.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report on the diff saved to the given path, structured per the code-fact-check skill.
- Answered: All 6 focus areas. (1) The PROBE FAIL row's `--probe-only` → `cc-isolated` sequence and its "base-only egress row below" pointer are Verified against cc-isolated.sh:880-926 and the row at :941. (2) "Always rebuilds and re-probes" is Verified. The load-bearing "picks up a newer CC" is Unverifiable (execution blocked), and static evidence leans Incorrect because of the layer cache. The bare-form harm claim is Verified against rebuild_hint. (3) Both guide edits are consistent with init-firewall.sh:343-350. (4) The README index line is Verified. (5) The dev-cycle row's triggers and "user-started outer loop" are Verified; its step and output list is Mostly accurate. (6) The commit-message claims, including Line 58, are Verified. AGENTS/GEMINI sync bats was executed: exit 0.
- Out of scope: (a) `rebuild_hint`'s first line, `cc-isolated WS # the supported path: rebuilds, re-probes, re-launches` (cc-isolated.sh:560), does not hold in the firewall-bricked case it is printed for at :915. There the hash matches, so the plain launch path does not rebuild and only `--probe-only` recreates. The guide advice in this diff correctly puts `--probe-only` first, but the script's hint, not changed by this diff, is inaccurate. (b) The health-check "no skill divergence" acceptance criterion was not run. (c) The guide omits rebuild_hint's other bare-form consequences: the shared claude-config volume and the build pointed at /Dockerfile.
- Escalate: Claim 13. Should devcontainer-setup.md's Image lifecycle bullet name a cache-busting rebuild (for example `--build-no-cache`, which the launcher does not expose), or say that newer CC arrives through in-container auto-update? As written, the bullet's stated goal probably is not met. This is pre-existing and carried over from the old bare advice, so it is the author's or user's call whether it belongs in this doc-drift PR.
