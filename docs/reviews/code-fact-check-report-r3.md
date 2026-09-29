Commit: 3a63c56

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-routers`, branch `feat/workflow-router-skills`)
**Scope:** `git diff main...HEAD` (12 files: 9 new `skills/<workflow>/SKILL.md` routers, `test/skills/workflow-routers.bats`, `global-instructions/CLAUDE.md`, `docs/decisions/log.md` row 66) plus the commit message of `3a63c56`; replicate 3 of 3
**Checked:** 2026-09-29
**Total claims checked:** 26
**Summary:** 16 verified, 6 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Hallucination-pattern log read (8 entries). No claim below asserts a fabricated symbol; Claims 1/21 resemble the logged class "a specific measured value quoted from a checked-in artifact" but differ in that the artifact does contain the numbers and then withdraws them. No log append.

Execution logs (untracked, created by this run): `docs/reviews/execution-logs/fc-r3-routers-bats.log`, `docs/reviews/execution-logs/fc-r3-mutations.log` (full TAP output of each mutation), `docs/reviews/execution-logs/fc-r3-mutations-exitcodes.log` (exit code, cwd, timestamp per mutation). Mutations ran on copies of `workflows/`, `skills/` and the bats file under the session scratchpad (`.../scratchpad/fcr3/r`, deleted afterwards); no tracked worktree file was modified.

---

## Claim 1: "The only workflow with a router (DD) was opened 15 times in 49 days while RPI, the documented default, was opened zero times (triage 2026-09-17 §2.2)"

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the cited source supports the 15:0 counts as evidence; does not establish the true usage of either workflow (the source says the instrument cannot tell).
**Legibility-target:** for-author

The numbers match the table in the cited section:

```
// docs/working/triage-2026-09-17-backlog.md:158-163
| workflow | reads in 49 days |
| `divergent-design` | **15** |
...
| **`research-plan-implement`** | **0** |
```

But the same section withdraws them as evidence, the same day:

```
// docs/working/triage-2026-09-17-backlog.md:174-178
> to lose faith in the numbers, including after fixes shipped]. **So this finding
> is withdrawn as evidence.** 0 reads is equally consistent with the doc being
> unused and with the instrument not seeing it, and the data cannot separate
> them. The 15:0 contrast goes with it: divergent-design's 15 is a lower bound
```

The row states "was opened zero times" as fact and uses the 15:0 contrast as the rationale, which is exactly what the source says the data cannot support (recorded as Q-017). The same sentence appears in `test/skills/workflow-routers.bats:8-11` (Claim 21) and the commit message body of `3a63c56` (paraphrased — no quote available because the commit message is not a file; `git log -1 3a63c56` shows "was opened 15 times in 49 days while research-plan-implement, the documented default, was opened zero times (docs/working/triage-2026-09-17-backlog.md §2.2)"). The global instructions also prohibit routing a number from an instrument with a known under-counting history without re-validating it (paraphrased — no quote available because the rule lives in the user's global instruction file loaded into this session, "Never route a number from an instrument with a known under-counting history...").

**Evidence:** `docs/decisions/log.md:88`, `docs/working/triage-2026-09-17-backlog.md:152-179`

---

## Claim 2: "pr-prep's advisory Step 0 wrote 1 failure pattern across ~128 fix commits (Q-074)"

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with Q-074's text; does not re-count fix commits or failure-pattern entries independently.
**Legibility-target:** for-orchestrator-synthesis

```
// docs/working/questions.md:70
After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about 128 `fix` commits. The writer is still pr-prep Step 0, a workflow step that is advisory only.
```

**Evidence:** `docs/working/questions.md:67-72`

---

## Claim 3: "`test/skills/workflow-routers.bats` fails if a workflow lacks a router, a router's body lacks the handoff, or a body passes 45 lines."

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named failure conditions on a mutated copy of the tree; does not establish behavior on CRLF frontmatter (`frontmatter()` does not strip `\r`) or on handoffs hidden in comments/code fences.
**Legibility-target:** for-orchestrator-synthesis

Command, per mutation: `timeout 60 bats test/skills/workflow-routers.bats`, cwd `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fcr3/r` (copy of `workflows/`, `skills/`, the bats file), 2026-09-29T07:36:26Z–07:36:28Z. Unmutated copy: exit 0. Deleting `skills/spike/SKILL.md` (M1): exit 1, `not ok 1 ... workflows with no skills/<name>/SKILL.md router: spike`. Replacing the body handoff line (M3): exit 1, `not ok 3`. Appending 30 lines (M5): exit 1, `not ok 5 ... spike (50 lines)`. The limit is the constant:

```
// test/skills/workflow-routers.bats:20
  MAX_BODY_LINES=45
```

**Evidence:** `test/skills/workflow-routers.bats:16-105`, `docs/reviews/execution-logs/fc-r3-mutations.log`, `docs/reviews/execution-logs/fc-r3-mutations-exitcodes.log`

---

## Claim 4: "User request 2026-09-28; log 65"

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether log row 65 exists on this branch and main; does not assess the relationship between rows 65 and 66.
**Legibility-target:** for-author

There is no row 65 on this branch: the table goes from 64 to 66 (paraphrased — no quote available because the claim is about an absent row; `grep -n "^| 6[0-9] " docs/decisions/log.md` returns rows 60–64 and 66 only). Row 65 exists only on the unmerged branch `fix/agents-md-no-imports`, commit `5ee83154` ("AGENTS.md names workflows by bare filename, never by `@` import"). The reference resolves only if that branch merges; if this branch lands first, `log 65` dangles.

**Evidence:** `docs/decisions/log.md:83-88`, commit `5ee83154` (`git branch -a --contains 5ee83154` → `fix/agents-md-no-imports`)

---

## Claim 5: "Revisit if, 30 days after install, router invocations stay near zero for RPI and pr-prep (`scripts/skill-usage-report.sh`)"

**Location:** `docs/decisions/log.md:88`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the named script exists and reads skill-invocation events the hook logs on Skill-tool calls; does not establish that the instrument counts reliably (the same hook family has the under-counting history cited in Claim 1).
**Legibility-target:** for-orchestrator-synthesis

```
// scripts/skill-usage-report.sh:2-3
# Reads ~/.claude/logs/usage.jsonl and reports skill/workflow usage frequency,
# recency, and which skills/workflows have never been invoked.
```

```
// hooks/log-usage.sh:55-57
    if [[ -n "$SKILL_NAME" ]]; then
      log_event "skill" "$SKILL_NAME" "$SKILL_ARGS" "skill_tool"
    fi
```

**Evidence:** `scripts/skill-usage-report.sh:1-30`, `hooks/log-usage.sh:55-69`

---

## Claim 6: "Each `workflows/<name>.md` ships a router skill of the same name (`skills/<name>/SKILL.md`)"

**Location:** `global-instructions/CLAUDE.md:13`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all 10 files under `workflows/` at `3a63c56`; does not establish the routers are installed in any given session (needs install.sh + rebuild, Claim 26).
**Legibility-target:** for-orchestrator-synthesis

`timeout 120 bats test/skills/workflow-routers.bats`, cwd `/workspace/.claude/wt-routers`, exit 0, 2026-09-29T07:35:55Z: `ok 1 every workflow has a router skill of the same name` and all 5 tests pass.

**Evidence:** `test/skills/workflow-routers.bats:38-48`, `docs/reviews/execution-logs/fc-r3-routers-bats.log`

---

## Claim 7: "so it appears in the session's skill list and is started with the Skill tool, which loads the workflow"

**Location:** `global-instructions/CLAUDE.md:13`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what a router's content does when loaded; does not establish Skill-tool loading semantics beyond "loads SKILL.md".
**Legibility-target:** for-author

The Skill call loads the router stub, not the workflow. The stub then tells the agent to read the workflow, which takes a separate Read:

```
// skills/spike/SKILL.md:26-27
Read and follow **`workflows/spike.md`** end to end (installed copy:
`~/.claude/workflows/spike.md`).
```

A more precise wording: "which loads a stub that directs reading the workflow."

**Evidence:** `skills/spike/SKILL.md:24-29` (same pattern in all nine routers)

---

## Claim 8: "including its approval gate on force-pushing a shared branch" / "Replacing a shared branch always needs explicit user approval, in any operating mode."

**Location:** `skills/branch-strategy/SKILL.md:16-17`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the workflow's dev reset and integration-refresh promotion paths; does not cover branch deletion, which the workflow gates separately.
**Legibility-target:** for-orchestrator-synthesis

```
// workflows/branch-strategy.md:186-188
`git push --force-with-lease origin dev` replaces a shared branch in place — that pointer swap is a
**gated operation requiring explicit human approval** (see Operating Modes in CLAUDE.md), regardless
of away/active mode.
```

The same gate is restated for refresh promotion at `workflows/branch-strategy.md:373` ("Never force-push over shared branches outside the approval gate").

**Evidence:** `skills/branch-strategy/SKILL.md:16-30`, `workflows/branch-strategy.md:184-190`, `workflows/branch-strategy.md:327-337`, `workflows/branch-strategy.md:373-376`

---

## Claim 9: "Its output is `docs/working/onboarding-{project}.md`, which later RPI research loads instead of re-exploring."

**Location:** `skills/codebase-onboarding/SKILL.md:29-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the output path and the RPI handoff; does not check the description's list of sections.
**Legibility-target:** for-orchestrator-synthesis

```
// workflows/codebase-onboarding.md:30
- `docs/working/onboarding-{project}.md` — the orientation document
```

The "→ RPI" pivot says the onboarding doc's architecture map, key flows and conventions "replace the broad exploration part of RPI research" (paraphrased — no quote available because the sentence is long; it is in the "When to pivot" section of `workflows/codebase-onboarding.md`). The router's "Not for projects you started from scratch" matches the workflow's "Not a trigger: from-scratch projects you started yourself".

**Evidence:** `workflows/codebase-onboarding.md:30`, `workflows/codebase-onboarding.md:375`

---

## Claim 10: "It includes the manual `git worktree add` fallback for when Agent-tool worktree isolation fails."

**Location:** `skills/parallel-worktrees/SKILL.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fallback's existence and one trigger; the workflow also uses it for human-driven sessions and when isolation is unavailable.
**Legibility-target:** for-orchestrator-synthesis

```
// workflows/parallel-worktrees.md:42-43
git worktree add .claude/wt-item-1 -b feat/item-1 main   # inside the project, so sandbox writes are allowed
git worktree add .claude/wt-item-2 -b feat/item-2 main
```

The router's "do these share files or an order?" test and the task-decomposition boundary match the workflow's "When NOT to fan out" paragraph.

**Evidence:** `workflows/parallel-worktrees.md:36-47`

---

## Claim 11: "Runs code-review as one of its steps; use this for the whole landing, code-review alone for a review only."

**Location:** `skills/pr-prep/SKILL.md:5-6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that pr-prep step 3a invokes code-review; does not check the description's stage order (on the GitHub path the draft PR opens at step 2, before the loop).
**Legibility-target:** for-orchestrator-synthesis

pr-prep step 3a lists "**Code review** (`/code-review`) — multi-critic structural review of the diff vs main" (paraphrased — no quote available because the line number shifted in the reviewed tree; `grep -n "Code review\*\* (\`/code-review\`)" workflows/pr-prep.md` finds it under "#### 3. Review-fix loop").

**Evidence:** `workflows/pr-prep.md` step 3a (under the heading at `#### 3. Review-fix loop`)

---

## Claim 12: "The workflow picks the delivery path (local merge vs GitHub PR) in its first step."

**Location:** `skills/pr-prep/SKILL.md:21-22`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the delivery-path choice sits in the workflow; does not assess the choice criteria.
**Legibility-target:** for-author

The choice is a section placed before the numbered steps, not the first step:

```
// workflows/pr-prep.md:18-20
### Delivery path: local merge or GitHub PR

Pick the path before Step 0.
```

Precise version: "picks the delivery path before Step 0."

**Evidence:** `workflows/pr-prep.md:18-32`

---

## Claim 13: "Its review-fix loop is owned by `workflows/review-fix-loop.md`"

**Location:** `skills/pr-prep/SKILL.md:28-29`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ownership split both docs state; does not check further cross-references.
**Legibility-target:** for-author

review-fix-loop.md owns the loop's control rules only. pr-prep step 3 owns the per-iteration sequence and when override-log rows are written:

```
// workflows/review-fix-loop.md:7
This document owns the review-fix loop's control rules: the iteration cap and its exit conditions, the early split trigger, the fix-drift check, and the two re-fire filters ... [pr-prep Step 3](pr-prep.md#3-review-fix-loop) owns the step sequence of each iteration (generate → triage and fix → test → re-review → exit) and when override-log rows are written.
```

Precise version: "its loop's control rules (cap, exits, re-fire filters) are owned by `workflows/review-fix-loop.md`."

**Evidence:** `workflows/review-fix-loop.md:7`

---

## Claim 14: "Its outputs are `docs/working/research-{topic}.md`, `plan-{topic}.md` and `checkpoint-{topic}.md`, and its hard gate is plan approval before implementation."

**Location:** `skills/research-plan-implement/SKILL.md:29-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three working docs and the step-4 gate; does not cover the optional handoff doc or the test-review checkpoint in step 6.
**Legibility-target:** for-orchestrator-synthesis

RPI's "Working documents" section lists `docs/working/research-{topic}.md`, `plan-{topic}.md` and `checkpoint-{topic}.md`, and step 4 opens with "This is the hard gate. ... **implementation does not begin until the user has reviewed the plan**" (paraphrased — no quote available because the line numbers were read from the section headings rather than a numbered dump; both are under `## Working documents` and `### 4. Annotate` in `workflows/research-plan-implement.md`). The description's sequence (research doc, plan doc, plan approval, tests first, implement) matches steps 2–6.

**Evidence:** `workflows/research-plan-implement.md` (`## Working documents`, `### 4. Annotate`, `#### Test-first gate`)

---

## Claim 15: "triage by tier, fix, record declined findings in the override log, re-review only the delta, stop at 3 iterations or 2 clean passes"

**Location:** `skills/review-fix-loop/SKILL.md:4-6`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what `workflows/review-fix-loop.md` (the file the router says to read) states about these steps and its stop rule; does not adjudicate the existing tension between that file's single-clean exit and code-review's 2-clean rule.
**Legibility-target:** for-author

Three imprecisions, same verdict, so not split:

- The triage, override-log writing and delta re-review steps are pr-prep step 3's, not this workflow's (see Claim 13's quote of `workflows/review-fix-loop.md:7`). A reader who follows only the workflow file will not find the delta rule there.
- At 3 iterations the loop does not stop. It reaches a written decision gate:

```
// workflows/review-fix-loop.md:25
iteration 4 cannot begin until an explicit `escalate | split | abandon` decision has been recorded in writing.
```

- "2 clean passes" is not in the workflow. Its exit is one clean iteration, or shipping with documented known issues and no Must Fix left:

```
// workflows/review-fix-loop.md:43-44
1. **Clean convergence.** No Must Fix items remain and every Must Address item is resolved ...
2. **Ship with documented known issues.** No Must Fix items remain, but Must Address or Consider items persist.
```

The 2-clean rule lives in `skills/code-review/SKILL.md:445` ("which requires **2 consecutive clean passes** before merge"). Decision 031 limits it to branches that touch behavior, security or a consumer contract. Comment/doc/test-only branches use 1-clean (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:148-152`).

**Evidence:** `workflows/review-fix-loop.md:7`, `workflows/review-fix-loop.md:23-46`, `skills/code-review/SKILL.md:443-446`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:148-152`

---

## Claim 16: "Usually entered from `pr-prep` step 3, but applies whenever a rubric is being acted on."

**Location:** `skills/review-fix-loop/SKILL.md:21-22`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the target workflow says about standalone use; does not establish whether standalone use would be harmful.
**Legibility-target:** for-author

The workflow the router hands off to forbids standalone use:

```
// workflows/review-fix-loop.md:211
The loop is embedded in pr-prep as a required step (Phase 1, step 3). It should not be run as a standalone workflow — use pr-prep, which sequences it within a two-phase process
```

The router's `when:` ("A code-review rubric exists ... and its findings are being fixed or declined"), its description triggers ("fix the review findings", "re-review") and this line all send an agent into the loop on its own. The workflow says to go through pr-prep instead.

**Evidence:** `skills/review-fix-loop/SKILL.md:6-8`, `skills/review-fix-loop/SKILL.md:19-22`, `workflows/review-fix-loop.md:207-211`

---

## Claim 17: "The tier definitions it acts on live in `skills/code-review/references/rubric.md`."

**Location:** `skills/review-fix-loop/SKILL.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the tier definitions are declared to live; does not verify the rubric's contents.
**Legibility-target:** for-orchestrator-synthesis

```
// workflows/review-fix-loop.md:7
The code-review skill owns the tier definitions ([rubric](../skills/code-review/references/rubric.md))
```

The file exists and defines the tiers (`skills/code-review/references/rubric.md:48` `## 🔴 Must Fix`).

**Evidence:** `workflows/review-fix-loop.md:7`, `skills/code-review/references/rubric.md:48`

---

## Claim 18: "Its first step greps `docs/thoughts/spike-graveyard.md` for prior abandoned attempts."

**Location:** `skills/spike/SKILL.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers step 1 of the spike workflow; does not check the description's later steps in detail (they match the step headings).
**Legibility-target:** for-orchestrator-synthesis

```
// workflows/spike.md:22-24
### 1. Check the graveyard (essential)

Before scoping the spike question, grep `docs/thoughts/spike-graveyard.md` for keywords from the question
```

**Evidence:** `workflows/spike.md:22-32`

---

## Claim 19: "It ends by entering `research-plan-implement` with the synthesized research doc." / "Not for several unrelated tasks in one message (that is parallel-worktrees)."

**Location:** `skills/task-decomposition/SKILL.md:30-31`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers step 7 and the row-2/row-7 boundary; does not check the interface-contract step in detail.
**Legibility-target:** for-orchestrator-synthesis

Step 7's Done-when is "The RPI workflow has been entered with the synthesized research doc as input", and parallel-worktrees says it is not for "*One* task whose research fans out but whose implementation stays sequential → `task-decomposition.md` (row 7)" (paraphrased — no quote available because both lines were checked against the workflow texts by heading, not a numbered dump: `### 7. Plan and implement sequentially` in `workflows/task-decomposition.md` and "Not this workflow" in `workflows/parallel-worktrees.md:5-8`).

**Evidence:** `workflows/task-decomposition.md` (`### 7.`), `workflows/parallel-worktrees.md:5-8`

---

## Claim 20: "Its findings report lands at `docs/working/testing-findings-{topic}.md`." / "For reviewing a UI's layout without users, use `ui-visual-review` instead."

**Location:** `skills/user-testing-workflow/SKILL.md:21-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Phase 4 output path and the sibling boundary; does not check the description's phase list in detail.
**Legibility-target:** for-orchestrator-synthesis

```
// workflows/user-testing-workflow.md:404
Save the report as `docs/working/testing-findings-{topic}.md` — this is "the findings doc" that the RPI and DD pivots above carry forward.
```

The `ui-visual-review` skill describes itself as reviewing rendered UI layout issues (cut-off, overlap, overflow), with no users involved (paraphrased — no quote available because the description comes from this session's skill listing, not a file in scope).

**Evidence:** `workflows/user-testing-workflow.md:404`

---

## Claim 21: "The one workflow with a router (divergent-design) was opened 15 times in 49 days while research-plan-implement, the documented default, was opened zero times (docs/working/triage-2026-09-17-backlog.md §2.2)."

**Location:** `test/skills/workflow-routers.bats:8-11`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 1: covers whether the cited source supports the counts as evidence; does not establish actual usage.
**Legibility-target:** for-author

```
// test/skills/workflow-routers.bats:8-11
# instruction prose. The one workflow with a router (divergent-design) was
# opened 15 times in 49 days while research-plan-implement, the documented
# default, was opened zero times (docs/working/triage-2026-09-17-backlog.md
# §2.2).
```

The cited section withdraws these numbers as evidence (`docs/working/triage-2026-09-17-backlog.md:174-178`, quoted in Claim 1).

**Evidence:** `test/skills/workflow-routers.bats:6-12`, `docs/working/triage-2026-09-17-backlog.md:152-179`

---

## Claim 22: "A router body is a short pointer; the workflows it points at run 70-600 lines."

**Location:** `test/skills/workflow-routers.bats:18-19`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line counts of the 10 workflow files at `3a63c56`; does not bear on whether 45 is the right limit.
**Legibility-target:** for-author

`wc -l workflows/*.md`, cwd `/workspace/.claude/wt-routers`, exit 0, 2026-09-29T07:35Z: the smallest is `72 workflows/parallel-worktrees.md` and the largest is `608 workflows/divergent-design.md`. Precise range: 72–608. The loose upper bound is harmless for the 45-line limit. Output was read inline and not captured to a file (paraphrased — no quote available because `wc` output is not a source file).

**Evidence:** `workflows/*.md` (wc -l), `test/skills/workflow-routers.bats:18-20`

---

## Claim 23: "Asserted on the body, not the whole file: the description also names the workflow, so a whole-file match survives deleting the handoff."

**Location:** `test/skills/workflow-routers.bats:71-72`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers a whole-file match of the same fixed string the test asserts; does not cover looser patterns (a bare `workflows/<name>.md` grep would survive, since the description contains that path).
**Legibility-target:** for-author

The asserted string is the full handoff phrase:

```
// test/skills/workflow-routers.bats:73
    body "$skill" | grep -qF "Read and follow **\`workflows/$name.md\`**" || bad+=("$name")
```

The descriptions contain `workflows/spike.md` but never `Read and follow **`. After mutation M3 removed the body handoff from a copy of `skills/spike/SKILL.md`, `grep -c "Read and follow"` on the whole file returned `0`. So a whole-file match of this string would also fail, and the stated reason for body-scoping does not hold (logged in `docs/reviews/execution-logs/fc-r3-mutations.log`, line before the "M3" heading; cwd scratchpad copy, 2026-09-29T07:36:11Z). Body-scoping is harmless. Only the comment's rationale is wrong. Medium confidence because "whole-file match" could mean a looser pattern than the one the test uses.

**Evidence:** `test/skills/workflow-routers.bats:66-80`, `skills/spike/SKILL.md:3-8`, `docs/reviews/execution-logs/fc-r3-mutations.log`

---

## Claim 24: Each test's name/claim that it fails when its contract breaks (router present; `name`/`description`/`when` frontmatter; body handoff; `(router)` in H1; body ≤ `MAX_BODY_LINES`)

**Location:** `test/skills/workflow-routers.bats:38-105`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one mutation per test on the `spike` router (plus a `when:` deletion for test 2); does not establish detection of CRLF-encoded frontmatter, a missing `description:` (not mutated), or handoffs placed inside comments.
**Legibility-target:** for-orchestrator-synthesis

Command, each run: `timeout 60 bats test/skills/workflow-routers.bats`, cwd scratchpad copy `.../scratchpad/fcr3/r`, 2026-09-29T07:36:26Z–07:36:28Z. Baseline M0 exited 0. Every mutation exited 1, and only the targeted test failed. M1 (delete router) → `not ok 1`. M2 (`name: spikex`) → `not ok 2 ... spike: name`. M2b (delete `when:`) → `not ok 2 ... spike: when`. M3 (remove handoff) → `not ok 3`. M4 (drop `(router)` from H1) → `not ok 4`. M5 (+30 lines) → `not ok 5 ... spike (50 lines)`. Current body lengths are 19–22 lines for the nine new routers and 37 for divergent-design, all under 45.

**Evidence:** `test/skills/workflow-routers.bats:38-105`, `docs/reviews/execution-logs/fc-r3-mutations.log`, `docs/reviews/execution-logs/fc-r3-mutations-exitcodes.log`

---

## Claim 25: "Verified to fail on main (9 missing routers)."

**Location:** commit `3a63c56` message body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test file run against `git archive main`; does not show which other tests would fail on main (tests 2–5 skip missing routers by design and pass).
**Legibility-target:** for-orchestrator-synthesis

`git archive main | tar -x`, then the branch's bats file was copied in, then `timeout 60 bats test/skills/workflow-routers.bats` ran in cwd `.../scratchpad/fcr3/r` at 2026-09-29T07:36:28Z. Exit 1: `not ok 1 ... workflows with no skills/<name>/SKILL.md router: branch-strategy codebase-onboarding parallel-worktrees pr-prep research-plan-implement review-fix-loop spike task-decomposition user-testing-workflow`. That lists 9 missing routers.

**Evidence:** `docs/reviews/execution-logs/fc-r3-mutations.log` (M6), `docs/reviews/execution-logs/fc-r3-mutations-exitcodes.log` (M6-main)

---

## Claim 26: "Takes effect in other projects after install.sh + rebuild (~/.claude/skills links to the installed payload)."

**Location:** commit `3a63c56` message body
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cc-isolated image path (staging in install.sh, symlink in this container); does not cover the bare-host copy install (decision 037).
**Legibility-target:** for-orchestrator-synthesis

```
// devcontainer-config/install.sh:115-117
# The skills/workflows/guides/patterns/hooks and the global CLAUDE.md are baked
# into the image so that EVERY cc-isolated session gets this repo's process, not
# just sessions that happen to be editing this repo.
```

```
// devcontainer-config/install.sh:135
CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)
```

In this container, `~/.claude/skills -> /opt/claude-workflows/skills` and `~/.claude/workflows -> /opt/claude-workflows/workflows` (paraphrased — no quote available because this is `ls -la` output of the live container, not a file).

**Evidence:** `devcontainer-config/install.sh:110-135`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`docs/decisions/log.md:88`): the 15-vs-0 workflow-open counts come from triage §2.2, and that section withdraws them as evidence (instrument under-counts; Q-017). Drop the counts or state the withdrawal.
- **Claim 16** (`skills/review-fix-loop/SKILL.md:21-22`): "applies whenever a rubric is being acted on" contradicts `workflows/review-fix-loop.md:211` ("should not be run as a standalone workflow — use pr-prep"). Align the router (and its `when:`/triggers) with the workflow, or change the workflow.
- **Claim 21** (`test/skills/workflow-routers.bats:8-11`): same withdrawn 15:0 evidence as Claim 1. The commit message repeats it too.
- **Claim 23** (`test/skills/workflow-routers.bats:71-72`): the descriptions never contain `Read and follow **`, so a whole-file match of the asserted string would not survive deleting the handoff. Fix the comment's rationale.

### Mostly Accurate
- **Claim 4** (`docs/decisions/log.md:88`): "log 65" exists only on unmerged `fix/agents-md-no-imports` (5ee83154). It dangles if this branch lands first.
- **Claim 7** (`global-instructions/CLAUDE.md:13`): the Skill tool loads the router stub, which then directs a Read of the workflow. It does not load the workflow itself.
- **Claim 12** (`skills/pr-prep/SKILL.md:21-22`): the delivery path is picked "before Step 0", in a pre-step section, not in the first step.
- **Claim 13** (`skills/pr-prep/SKILL.md:28-29`): review-fix-loop.md owns only the loop's control rules. pr-prep step 3 owns the iteration sequence and override-log writing.
- **Claim 15** (`skills/review-fix-loop/SKILL.md:4-6`): the delta re-review and override-log writing are pr-prep step 3's. At 3 iterations the loop reaches a written gate rather than stopping. "2 clean passes" is code-review's rule, scoped by decision 031, and not in the workflow, whose exit is one clean iteration or shipping with known issues.
- **Claim 22** (`test/skills/workflow-routers.bats:18-19`): the workflows run 72–608 lines, not 70–600.

---

## Goal-Alignment Note
- **Answered:** Every "claims that particularly need checking" item in the brief. Router-vs-workflow facts for all nine routers (Claims 8–20). Sibling positioning (11, 16, 19, 20). The bats header (21, 22), per-test failure on mutation (24), and verified-on-main (25). Log row 66 and commit claims (1–5, 25, 26). The global-instructions paragraph (6, 7).
- **Out of scope:** I did not run health-check.sh or the full suite, per the brief. I did not check divergent-design's existing router beyond its handoff/H1 matching the generic contract. I did not assess router trigger-phrase quality, which is judgment, not a checkable claim.
- **Escalate:** Claim 16 is a real routing conflict between the new router and its workflow. Claim 1/21 reuses evidence the source withdrew, and it is the headline rationale of row 66 and the commit. Also, I added three untracked execution-log files under `docs/reviews/execution-logs/` in the worktree, as the skill's provenance rule requires. Delete them if the orchestrator wants only the report. The brief mentions legibility-target tags, and code-fact-check's SKILL.md does not define them. I applied `patterns/orchestrated-review.md`'s three values as an extra per-claim line.
