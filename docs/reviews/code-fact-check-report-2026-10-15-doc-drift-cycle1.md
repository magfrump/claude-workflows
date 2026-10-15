Commit: 330138d8

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-doc-drift (branch fix/doc-drift-cycle1)
**Scope:** `git diff main...HEAD` plus the commit message of 330138d8, merged from three replicates (`code-fact-check-report-2026-10-15-doc-drift-cycle1-r{1,2,3}.md`), most-severe-wins on verdicts, union on annotations
**Checked:** 2026-10-15
**Total claims checked:** 12
**Summary:** 8 verified, 3 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable
**Commit:** 330138d8
**Replication:** k=3

---

## Claim 1: cc-isolated-usage.md PROBE FAIL (firewall) row: `cc-isolated --probe-only <repo>` "rebuilds from the blessed config and re-probes"

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the probe action path in cc-isolated.sh (always `--remove-existing-container` with the blessed hash exported, then `probe_boundary`); does not establish a live run (no docker in sandbox).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

`devcontainer up --remove-existing-container "${dc[@]}"` then `probe_boundary "$ws"` (`devcontainer-config/cc-isolated.sh:883-884`).

**Evidence:** `devcontainer-config/cc-isolated.sh:880-885`

---

## Claim 2: "then `cc-isolated <repo>`" starts the session

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main()'s launch path after a probe-only rebuild (hash matches, no second rebuild, claude exec); does not establish a live run.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2 (out of scope): `rebuild_hint`'s first line (`cc-isolated.sh:560`) says a plain `cc-isolated WS` "rebuilds, re-probes, re-launches", but a plain launch recreates only on hash mismatch, so in the firewall-bricked case (`:915`) it does not rebuild; the two-step form in this diff is the one that does.

**Evidence:** `devcontainer-config/cc-isolated.sh:887-927`

---

## Claim 3: "Not a bare `devcontainer up --remove-existing-container …` from your own shell — see the base-only egress row below."

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and content of the referenced row; does not re-verify that row's own measurement.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

The row "A newly registered profile has no effect — the container's egress is still base-only" sits at `guides/cc-isolated-usage.md:941`.

**Evidence:** `guides/cc-isolated-usage.md:941`

---

## Claim 4: Both guides' new advice matches init-firewall.sh's hint (fc3bff82)

**Location:** `guides/cc-isolated-usage.md:935`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers wording parity with init-firewall.sh:343-350 and the commit that brought it to main.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: the hint was written in 48a8200b and reached main through merge fc3bff82, so citing fc3bff82 is fair.

**Evidence:** `devcontainer-config/init-firewall.sh:343-350`

---

## Claim 5: Image lifecycle: "to pick up a newer CC *without* a config change, recreate it with the launcher: `cc-isolated --probe-only <repo>` ..., then `cc-isolated <repo>`"

**Location:** `guides/devcontainer-setup.md:389-391`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the probe-action recreate re-runs the Claude Code install layer; does not establish the devcontainer CLI's build invocation by execution (no docker/devcontainer in sandbox), and does not cover in-container auto-update.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Unverifiable · r3=Incorrect
**Replicate annotations:** r1+r2+r3: pre-existing; the replaced bare advice had the same flaw. r2: "always rebuilds" makes the old premise read more like a fix than it is; newer CC actually arrives by in-container auto-update (`guides/cc-isolated-usage.md:940`). r1: the same reasoning undercuts the unchanged preceding sentence's implication that a re-bless recreate refreshes CC. r1+r3: possible fixes are a pinned/bumped `CLAUDE_CODE_VERSION`, a no-cache path (launcher has none; brief puts scripts out of scope), or pointing at `claude update`.

The probe action adds only `--remove-existing-container` (`cc-isolated.sh:883`), no `--build-no-cache`. `RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}` (`Dockerfile:403`) receives the constant `"CLAUDE_CODE_VERSION": "latest"` (`devcontainer.json:29`) and sits above the per-project args (`Dockerfile:474-484`), so the layer cache keeps the old CC.

**Evidence:** `devcontainer-config/cc-isolated.sh:880-885`, `devcontainer-config/Dockerfile:402-403`, `devcontainer-config/Dockerfile:473-484`, `devcontainer-config/devcontainer.json:29`

---

## Claim 6: "always rebuilds from the blessed config and re-probes"

**Location:** `guides/devcontainer-setup.md:390-391`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the container recreate from the blessed config; does not establish that the image layers are rebuilt rather than reused (see Claim 5).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `devcontainer-config/cc-isolated.sh:880-885`

---

## Claim 7: the bare form "drops the launcher's `localEnv` inputs and bakes base-only egress and an empty config hash (see `rebuild_hint` in `cc-isolated.sh`)"

**Location:** `guides/devcontainer-setup.md:391-394`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the egress/hash consequences against rebuild_hint's comment, devcontainer.json's localEnv reads and Dockerfile:524-526; does not establish by execution whether the build completes with an empty CC_CONFIG_DIR.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r2+r3: rebuild_hint names two further consequences the sentence omits: an empty CC_PROJECT_ID mounts the shared `cc--claude-config` volume, and an empty CC_CONFIG_DIR points the build at `/Dockerfile` (r3: the build would most likely fail on that path before anything is baked). The advice not to use the bare form is correct either way.

**Evidence:** `devcontainer-config/cc-isolated.sh:536-547`, `devcontainer-config/Dockerfile:524-526`

---

## Claim 8: guides/README.md: cc-isolated-usage.md covers "the exit scan of host-git inputs when a session ends" and "`cc-push` for pushing a session's commits via a host-only clone"

**Location:** `guides/README.md:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of both topics in the guide.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `guides/cc-isolated-usage.md:28`, `guides/cc-isolated-usage.md:62-72`

---

## Claim 9: dev-cycle row triggers, "User-started outer loop over research-plan-implement and pr-prep", `docs/roadmap.md`

**Location:** `AGENTS.md:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers triggers and framing against skills/dev-cycle/SKILL.md and global-instructions/CLAUDE.md row 12.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `skills/dev-cycle/SKILL.md:1-5`, `global-instructions/CLAUDE.md:32`

---

## Claim 10: dev-cycle row step list and "Output is triage in `docs/working/questions.md`"

**Location:** `AGENTS.md:36`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step list against global row 12 and the skill.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: omits claim spot-check, conditional deep-audit check and brainstorm, which row 12 lists; "Output is triage in questions.md" understates (roadmap, briefs, cycle record also written). r3: also omits the digest and the orchestrator half (collect, land, dispatch), as row 12 does.

**Evidence:** `global-instructions/CLAUDE.md:32`

---

## Claim 11: GEMINI.md carries the same row, in sync with AGENTS.md

**Location:** `GEMINI.md:36`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte parity below the header (bats test/agents-gemini-sync.bats, exit 0, run by all three replicates).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/agents-gemini-sync.bats:15-28`

---

## Claim 12: Commit 330138d8 body: line 58 describes what the launcher does itself; Last verified dates not bumped; brief status open -> done; the PROBE FAIL row points at the row below

**Location:** `guides/cc-isolated-usage.md:57-59`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers each factual statement in the commit body.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1: every listed fact holds, but the Notes line says the edited passages were re-checked against the code, and that re-check missed Claim 5. (Commit message is immutable once merged; a fix commit can correct the record.)

**Evidence:** `devcontainer-config/cc-isolated.sh:892-896`

---

## Claims Requiring Attention

### Incorrect

- Claim 5 (`guides/devcontainer-setup.md:389-391`): recreating via `--probe-only` does not pick up a newer CC; the install layer is cached.

### Mostly Accurate

- Claim 7 (`guides/devcontainer-setup.md:391-394`): omits two of rebuild_hint's bare-form consequences.
- Claim 10 (`AGENTS.md:36`, `GEMINI.md:36`): step list shorter than global row 12; output understated.
- Claim 12 (commit body): "re-checked against the code" missed Claim 5.

## Escalations

- `guides/devcontainer-setup.md:389-391` (Claim 5), raised by r1, r2, r3, addressee: orchestrator/author. Fix here vs follow-up; a no-cache launcher path is out of the brief's scope.
- `devcontainer-config/cc-isolated.sh:560` (Claim 2 annotation), raised by r1, r2 as out of scope, addressee: orchestrator. rebuild_hint's "rebuilds" line is inaccurate in the firewall-bricked case; script change, outside this brief.

## Verdict stability

- Clusters: 12
- All replicates agreed: 9
- Disagreed: 3 (Claim 5: r1=Incorrect, r2=Unverifiable, r3=Incorrect; Claim 7: r1=Verified, r2=Verified, r3=Mostly accurate; Claim 12: r1=Mostly accurate, r2=Verified, r3=Verified)
- Agreement rate: 9/12 = 75%
