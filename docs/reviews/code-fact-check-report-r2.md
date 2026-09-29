Commit: 3a63c56

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-routers (branch feat/workflow-router-skills)
**Scope:** `git diff main...HEAD` (12 files: 9 new router skills, test/skills/workflow-routers.bats, global-instructions/CLAUDE.md, docs/decisions/log.md row 66) plus the commit message of 3a63c56 (`git log main..HEAD`)
**Checked:** 2026-09-29
**Total claims checked:** 32
**Summary:** 18 verified, 9 mostly accurate, 0 stale, 5 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) was read; no claim below matches a logged pattern. No Incorrect verdict below is a fabricated symbol, so the log is not updated.

Execution logs for executed claims: `docs/reviews/execution-logs/cfc-routers-r2-b/` (`branch-bats.txt`, `mutations.txt`, `mutations2.txt`, `exit-codes.txt`). Mutations ran on copies of `workflows/`, `skills/` and the test file in the session scratchpad (deleted afterwards); no tracked file was modified.

---

## Claim 1: "The only workflow with a router (DD) was opened 15 times in 49 days while RPI, the documented default, was opened zero times (triage 2026-09-17 §2.2)"

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the cited source supports the numbers and the claim that RPI was opened zero times; does not establish how often any workflow was actually opened (the source says the instrument cannot tell).

The numbers are quoted correctly from the cited table:

```
// docs/working/triage-2026-09-17-backlog.md:158-164
| workflow | reads in 49 days |
| `divergent-design` | **15** |
...
| **`research-plan-implement`** | **0** |
```

But the same section withdrew this finding as evidence the same day:

```
// docs/working/triage-2026-09-17-backlog.md:170-178
> **Correction, 2026-09-17 (same day).** The user reports that hook measurement
> has a history of silent under-counting ... **So this finding
> is withdrawn as evidence.** 0 reads is equally consistent with the doc being
> unused and with the instrument not seeing it, and the data cannot separate
> them. The 15:0 contrast goes with it: divergent-design's 15 is a lower bound
> from the same instrument, not a comparable measurement. Recorded as `Q-017`
```

The row states "was opened zero times" as a fact and uses the 15:0 contrast as rationale; the source it cites says the data cannot support either. The part carrying the verdict is the factual "opened zero times" / 15-vs-0 comparison, not the digits. (The global instructions' running-questions rule also names Q-017 as the example of an under-counting instrument that must be re-validated before its numbers are relied on.) The same claim appears in Claims 23 and 29.

**Evidence:** `docs/working/triage-2026-09-17-backlog.md:152-178`, `docs/decisions/log.md:88`

---

## Claim 2: "pr-prep's advisory Step 0 wrote 1 failure pattern across ~128 fix commits (Q-074)"

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the Q-074 entry; does not independently recount fix commits or failure-pattern entries.

```
// docs/working/questions.md:70
After the Q-018 backfill (164 entries), `docs/thoughts/failure-patterns.md` has gained 1 entry across about 128 `fix` commits. The writer is still pr-prep Step 0, a workflow step that is advisory only.
```

**Evidence:** `docs/working/questions.md:67-72`

---

## Claim 3: "`test/skills/workflow-routers.bats` fails if a workflow lacks a router, a router's body lacks the handoff, or a body passes 45 lines"

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named failure conditions, each exercised by a mutation; does not establish the test's coverage beyond them (it also checks frontmatter and the H1, see Claim 27).

`MAX_BODY_LINES=45` (`test/skills/workflow-routers.bats:20`) with `[ "$n" -le "$MAX_BODY_LINES" ]` (`:98`). Executed: deleting `skills/spike/` fails test 1; deleting or retargeting spike's `Read and follow` line fails test 3; appending 30 lines to spike (body 50) fails test 5 with `routers over 45 body lines (restating the workflow?): spike (50 lines)`.

Command: `timeout 120 bats <scratch>/<mutation>/test/skills/workflow-routers.bats`, cwd `/workspace/.claude/wt-routers`, exit 1 for each of m1, m3, m3b, m5b, 2026-09-29T07:38:38Z-07:38:40Z.

**Evidence:** `test/skills/workflow-routers.bats:38-105`, `docs/reviews/execution-logs/cfc-routers-r2-b/exit-codes.txt`, `docs/reviews/execution-logs/cfc-routers-r2-b/mutations2.txt`

---

## Claim 4: "log 65" (Full Record column of row 66)

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether row 65 exists on this branch, on main, and on local branches; does not establish when row 65 will merge.

Row 65 is not in the log on this branch or on main: the branch's rows run `| 64 |` (`docs/decisions/log.md:87`) then `| 66 |` (`:88`). It exists only on the unmerged local branch `fix/agents-md-no-imports`: `| 65 | 2026-09-28 | **AGENTS.md names workflows by bare filename, never by `@` import.**` (from `git show fix/agents-md-no-imports:docs/decisions/log.md`). The reference resolves once that branch merges; until then it points at nothing in this tree.

**Evidence:** `docs/decisions/log.md:83-88`

---

## Claim 5: "Revisit if ... router invocations stay near zero for RPI and pr-prep (`scripts/skill-usage-report.sh`)"

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the script exists and reports skill and workflow usage; does not establish that it records Skill-tool invocations of routers reliably (it reads the same `usage.jsonl` instrument Claim 1's source flags as under-counting).

```
// scripts/skill-usage-report.sh:2-3
# Reads ~/.claude/logs/usage.jsonl and reports skill/workflow usage frequency,
# recency, and which skills/workflows have never been invoked.
```

**Evidence:** `scripts/skill-usage-report.sh:1-60`

---

## Claim 6a: "Each `workflows/<name>.md` ships a router skill of the same name (`skills/<name>/SKILL.md`)"

**Location:** `global-instructions/CLAUDE.md:13`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all 10 files under `workflows/` on this branch; does not establish that future workflows will get routers (the test enforces that).

Test 1 ("every workflow has a router skill of the same name") passes on the branch. Command `timeout 120 bats test/skills/workflow-routers.bats`, cwd `/workspace/.claude/wt-routers`, exit 0, 2026-09-29T07:37:00Z (re-run exit 0 at 07:38:40Z).

**Evidence:** `test/skills/workflow-routers.bats:38-47`, `docs/reviews/execution-logs/cfc-routers-r2-b/branch-bats.txt`, `docs/reviews/execution-logs/cfc-routers-r2-b/exit-codes.txt`

---

## Claim 6b: "is started with the Skill tool, which loads the workflow"

**Location:** `global-instructions/CLAUDE.md:13`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what a router file contains; does not establish Skill-tool runtime behavior beyond loading SKILL.md.

The Skill tool loads the router's SKILL.md, which then instructs the agent to read the workflow, e.g. `Read and follow **`workflows/spike.md`** end to end` (`skills/spike/SKILL.md:26`). The workflow is loaded by the agent's follow-up Read, not by the Skill call itself. Precise version: "which points the agent at the workflow."

**Evidence:** `skills/spike/SKILL.md:24-29`

---

## Claim 7: "Replacing a shared branch always needs explicit user approval, in any operating mode."

**Location:** `skills/branch-strategy/SKILL.md:29-30`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reset-dev force-push and the integration-refresh promotion; does not establish other shared-branch operations the workflow does not discuss.

```
// workflows/branch-strategy.md:185-187
`git push --force-with-lease origin dev` replaces a shared branch in place — that pointer swap is a
**gated operation requiring explicit human approval** (see Operating Modes in CLAUDE.md), regardless
of away/active mode.
```

The refresh section repeats it ("is gated on human approval (Operating Modes), not done automatically — even in `/away` mode" — paraphrased — no quote available because I located it by reading the "Why this shape" bullets rather than recording a line number).

**Evidence:** `workflows/branch-strategy.md:183-189`

---

## Claim 8: "Not for projects you started from scratch" / "Its output is `docs/working/onboarding-{project}.md`, which later RPI research loads instead of re-exploring."

**Location:** `skills/codebase-onboarding/SKILL.md:23-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the output path, the from-scratch exclusion and the RPI handoff; does not establish the `when:` field's "no docs/thoughts/" condition beyond its match with the global decision tree row 1.

```
// workflows/codebase-onboarding.md:18
**Not a trigger:** from-scratch projects you started yourself
// workflows/codebase-onboarding.md:30
- `docs/working/onboarding-{project}.md` — the orientation document
```

The "When to pivot → RPI" bullet says the onboarding doc's sections "replace the broad exploration part of RPI research" (paraphrased — no quote available because the bullet is long and I am citing its gist).

**Evidence:** `workflows/codebase-onboarding.md:16-30`

---

## Claim 9: "It includes the manual `git worktree add` fallback for when Agent-tool worktree isolation fails."

**Location:** `skills/parallel-worktrees/SKILL.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and trigger of the fallback; does not establish that the fallback commands work.

```
// workflows/parallel-worktrees.md:39-42
Manual fallback. Use it for human-driven sessions, when Agent-tool isolation is not available, or when it **fails or misbehaves**. ...
git worktree add .claude/wt-item-1 -b feat/item-1 main
```

**Evidence:** `workflows/parallel-worktrees.md:37-47`

---

## Claim 10: "size gate, review-fix loop, history cleanup, verification, then a local merge (solo) or a GitHub PR. Runs code-review as one of its steps"

**Location:** `skills/pr-prep/SKILL.md:4-6`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step order and the code-review step; does not establish description-writing (step 6) or the retrospective, which the list omits.

"Runs code-review as one of its steps" holds: `- **Code review** (`/code-review`) — multi-critic structural review of the diff vs main` (`workflows/pr-prep.md:181`, step 3a). The ordering is imprecise for the GitHub path: `#### 2. Open draft PR` (`workflows/pr-prep.md:159`) comes before `#### 3. Review-fix loop` (`:174`), so the PR is opened before the loop, not "then" at the end. Precise version: "…then merge locally, or on the GitHub path mark the draft PR (opened at step 2) ready."

**Evidence:** `workflows/pr-prep.md:159-181`, `workflows/pr-prep.md:293-311`

---

## Claim 11: "The workflow picks the delivery path (local merge vs GitHub PR) in its first step."

**Location:** `skills/pr-prep/SKILL.md:22`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the delivery-path choice sits in the workflow; does not establish anything about the choice's criteria.

```
// workflows/pr-prep.md:18-20
### Delivery path: local merge or GitHub PR

Pick the path before Step 0.
```

It is the first thing done, but it is an unnumbered preamble "before Step 0", not a step. A reader looking for "Step 0/1" will not find it there. Precise version: "before its first step."

**Evidence:** `workflows/pr-prep.md:18-36`

---

## Claim 12: "Its review-fix loop is owned by `workflows/review-fix-loop.md`; its reviews run through the `code-review` skill."

**Location:** `skills/pr-prep/SKILL.md:28-29`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ownership split stated in review-fix-loop.md; does not establish the other review skills step 3a runs (self-eval, manual checks).

```
// workflows/review-fix-loop.md:7
This document owns the review-fix loop's control rules: the iteration cap and its exit conditions, the early split trigger, the fix-drift check, and the two re-fire filters ... [pr-prep Step 3](pr-prep.md#3-review-fix-loop) owns the step sequence of each iteration (generate → triage and fix → test → re-review → exit) and when override-log rows are written.
```

Ownership is split: review-fix-loop.md owns the control rules, pr-prep Step 3 itself owns the iteration sequence. "Reviews run through code-review" is also partial: step 3a runs `/self-eval` and manual documentation, dependency and plan-drift checks too (`workflows/pr-prep.md:181-185`, paraphrased — no quote available because the list spans five bullets).

**Evidence:** `workflows/review-fix-loop.md:7`, `workflows/pr-prep.md:174-190`

---

## Claim 13: "Its outputs are `docs/working/research-{topic}.md`, `plan-{topic}.md` and `checkpoint-{topic}.md`, and its hard gate is plan approval before implementation."

**Location:** `skills/research-plan-implement/SKILL.md:29-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three working docs and the step-4 gate; does not establish the optional handoff doc or the softer test-review checkpoint in step 6.

```
// workflows/research-plan-implement.md:30-32
- `docs/working/research-{topic}.md` — what Claude learned about the relevant codebase
- `docs/working/plan-{topic}.md` — the implementation plan
- `docs/working/checkpoint-{topic}.md` — curated context artifact ...
// workflows/research-plan-implement.md:362
This is the hard gate. Research and planning can proceed speculatively, but **implementation does not begin until the user has reviewed the plan**
```

**Evidence:** `workflows/research-plan-implement.md:26-32`, `workflows/research-plan-implement.md:360-364`

---

## Claim 14a: "Route ... into workflows/review-fix-loop.md: triage by tier, fix, record declined findings in the override log, re-review only the delta"

**Location:** `skills/review-fix-loop/SKILL.md:4-6`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which document owns each listed step; does not establish whether an agent following the router alone would perform them.

Per `workflows/review-fix-loop.md:7` (quoted in Claim 12), the iteration sequence (triage and fix, re-review) and "when override-log rows are written" are owned by pr-prep Step 3, and `--loop-pass` (the delta re-review mechanism) by the code-review skill. review-fix-loop.md itself has the override-log *read* filter (`## Re-flagged settled decisions (override-log filter)`, `:150`) and a tier-order anti-pattern (`:204`). The listed steps exist in the loop as a whole but mostly live in pr-prep Step 3, not in the file the description routes to.

**Evidence:** `workflows/review-fix-loop.md:7`, `workflows/review-fix-loop.md:150-204`, `workflows/pr-prep.md:195-270`

---

## Claim 14b: "stop at 3 iterations"

**Location:** `skills/review-fix-loop/SKILL.md:5-6`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the iteration cap; does not establish the early split trigger.

```
// workflows/review-fix-loop.md:25
The review→fix→re-review loop is bounded at **3 iterations**. This is a hard cap, not a soft ceiling: iteration 4 cannot begin until an explicit `escalate | split | abandon` decision has been recorded in writing.
```

The cap is right; "stop" is loose, since reaching it opens a written escalate/split/abandon gate (`:54-72`) rather than ending the loop.

**Evidence:** `workflows/review-fix-loop.md:23-72`

---

## Claim 14c: "or 2 clean passes"

**Location:** `skills/review-fix-loop/SKILL.md:5-6`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the exit conditions in `workflows/review-fix-loop.md` (the file the description routes into) and where a 2-clean rule does exist; does not establish which branches decision 031 scopes 2-clean to in practice.

review-fix-loop.md's exit conditions need one iteration, not two clean passes:

```
// workflows/review-fix-loop.md:41-44
Exit the loop at the end of any iteration where:
1. **Clean convergence.** No Must Fix items remain and every Must Address item is resolved or acknowledged ...
2. **Ship with documented known issues.** No Must Fix items remain, but Must Address or Consider items persist.
```

`grep -n "clean"` over the workflow finds no 2-clean rule (paraphrased — no quote available because the claim is about an absence). A 2-consecutive-clean rule does exist elsewhere: `(which requires **2 consecutive clean passes** before merge)` (`skills/code-review/SKILL.md:445`), from decision 031, which scopes it: `2-clean is the default only where a missed variance-class red is expensive ... Comment/doc/test-only branches opt down to 1-clean` (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:150-152`). The description credits review-fix-loop.md with a rule it does not contain, drops its "ship with known issues" exit, and leaves out 031's scoping. Medium confidence because the rule is real in the repo, just not in this workflow.

**Evidence:** `workflows/review-fix-loop.md:39-46`, `skills/code-review/SKILL.md:443-456`, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:148-153`

---

## Claim 15: "Usually entered from `pr-prep` step 3, but applies whenever a rubric is being acted on."

**Location:** `skills/review-fix-loop/SKILL.md:21-22`
**Type:** Reference / Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the router's positioning against the workflow's own statement of how it is entered; does not establish whether standalone use is harmful.

"Entered from pr-prep step 3" is right (`#### 3. Review-fix loop`, `workflows/pr-prep.md:174`). "Applies whenever a rubric is being acted on" contradicts the workflow:

```
// workflows/review-fix-loop.md:211
The loop is embedded in pr-prep as a required step (Phase 1, step 3). It should not be run as a standalone workflow — use pr-prep, which sequences it within a two-phase process
```

The router, its `when:` line ("A code-review rubric exists ... and its findings are being fixed or declined", `:8`) and its trigger phrases present the loop as a standalone entry point, which the workflow tells readers not to use. Part carrying the verdict: the standalone "whenever" clause.

**Evidence:** `workflows/review-fix-loop.md:207-211`, `skills/review-fix-loop/SKILL.md:8-22`

---

## Claim 16: "The tier definitions it acts on live in `skills/code-review/references/rubric.md`."

**Location:** `skills/review-fix-loop/SKILL.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ownership statement; does not check the rubric file's tier content.

`The code-review skill owns the tier definitions ([rubric](../skills/code-review/references/rubric.md))` (`workflows/review-fix-loop.md:7`); pr-prep agrees: `The tier definitions are owned by the [code-review rubric](../skills/code-review/references/rubric.md)` (`workflows/pr-prep.md:195`).

**Evidence:** `workflows/review-fix-loop.md:7`, `workflows/pr-prep.md:195`

---

## Claim 17: "Its first step greps `docs/thoughts/spike-graveyard.md` for prior abandoned attempts."

**Location:** `skills/spike/SKILL.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers step 1's action; does not establish that the graveyard file exists in any given project (the workflow says to create it if absent).

```
// workflows/spike.md:22-24
### 1. Check the graveyard (essential)

Before scoping the spike question, grep `docs/thoughts/spike-graveyard.md` for keywords from the question
```

**Evidence:** `workflows/spike.md:22-30`

---

## Claim 18: "Not for several unrelated tasks in one message (that is parallel-worktrees)" / "Implementation stays sequential in the main agent."

**Location:** `skills/task-decomposition/SKILL.md:6-7`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the boundary as both workflows state it; does not establish the boundary in the parallel-worktrees router (consistent, see its line 21-22).

```
// workflows/task-decomposition.md:14
Implementation still happens sequentially in the main agent — sub-agents research and analyze, they don't write code to shared files.
```

parallel-worktrees states the mirror boundary: "*One* task whose research fans out but whose implementation stays sequential → `task-decomposition.md` (row 7)" (paraphrased — no quote available because I am citing its "Not this workflow" bullet from the file's opening list without a recorded line number).

**Evidence:** `workflows/task-decomposition.md:12-16`, `workflows/parallel-worktrees.md:5-9`

---

## Claim 19: "It ends by entering `research-plan-implement` with the synthesized research doc."

**Location:** `skills/task-decomposition/SKILL.md:30-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers step 7; does not establish anything about the RPI loop that follows.

```
// workflows/task-decomposition.md:199, 204
### 7. Plan and implement sequentially
- [ ] The RPI workflow has been entered with the synthesized research doc as input
```

**Evidence:** `workflows/task-decomposition.md:199-205`

---

## Claim 20: "For reviewing a UI's layout without users, use `ui-visual-review` instead."

**Location:** `skills/user-testing-workflow/SKILL.md:22`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sibling skill's stated purpose; does not establish trigger-selection behavior.

ui-visual-review's description is "Review and fix visual/layout issues in any rendered UI (web, Unity C# UI, SwiftUI, mobile, 3D viewports)" (paraphrased — no quote available because I read it from the session's skill listing, not a file line); the user-testing workflow is scoped to tests with participants (`## Phase 0: Scoping`, `workflows/user-testing-workflow.md`).

**Evidence:** `skills/ui-visual-review/SKILL.md:1-10`, `workflows/user-testing-workflow.md:1-20`

---

## Claim 21: "Its findings report lands at `docs/working/testing-findings-{topic}.md`."

**Location:** `skills/user-testing-workflow/SKILL.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Phase 4 save path; does not establish the early DD-pivot version written to the same file.

```
// workflows/user-testing-workflow.md:404
Save the report as `docs/working/testing-findings-{topic}.md` — this is "the findings doc" that the RPI and DD pivots above carry forward.
```

**Evidence:** `workflows/user-testing-workflow.md:402-406`

---

## Claim 22: "(installed copy: `~/.claude/workflows/<name>.md`)" (all nine routers)

**Location:** `skills/research-plan-implement/SKILL.md:27-28`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cc-isolated container layout where the payload is linked in; does not establish the bare-host copy layout beyond install.sh's stated destination list.

`CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`devcontainer-config/install.sh:135`). In this container, `ls -la ~/.claude/` showed `workflows -> /opt/claude-workflows/workflows` and `ls ~/.claude/workflows/` listed `branch-strategy.md`, `codebase-onboarding.md`, `divergent-design.md`… (cwd `/workspace/.claude/wt-routers`, exit 0, 2026-09-29T07:36Z; output not captured to a file, a provenance gap, but the listing is reproducible with the same command).

**Evidence:** `devcontainer-config/install.sh:114-135`, `devcontainer-config/link-claude-home.sh:15-18`

---

## Claim 23: "The one workflow with a router (divergent-design) was opened 15 times in 49 days while research-plan-implement, the documented default, was opened zero times (docs/working/triage-2026-09-17-backlog.md §2.2)."

**Location:** `test/skills/workflow-routers.bats:8-11`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 1: covers what the cited source supports; does not establish real open counts.

Same claim as Claim 1. The cited §2.2 table has these numbers (`docs/working/triage-2026-09-17-backlog.md:158-164`), and the same section withdraws them: `**So this finding is withdrawn as evidence.**` … `The 15:0 contrast goes with it` (`:174-177`). The test header presents it as fact.

**Evidence:** `docs/working/triage-2026-09-17-backlog.md:152-178`

---

## Claim 24: "divergent-design's own, stricter contract lives in divergent-design-router.bats."

**Location:** `test/skills/workflow-routers.bats:12`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the file's existence; does not compare its assertions to this file's to confirm "stricter".

`test/skills/divergent-design-router.bats` exists (paraphrased — no quote available because the claim is about file presence, confirmed by `ls`). divergent-design also passes this file's five generic checks (its body is 37 lines, and its H1 is `# Divergent Design (router)`, `skills/divergent-design/SKILL.md:14`).

**Evidence:** `test/skills/divergent-design-router.bats:1`, `skills/divergent-design/SKILL.md:14-43`

---

## Claim 25: "the workflows it points at run 70-600 lines"

**Location:** `test/skills/workflow-routers.bats:18-19`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers current line counts of `workflows/*.md`; does not establish the 45-line threshold's fitness.

`wc -l workflows/*.md` (cwd `/workspace/.claude/wt-routers`, exit 0, 2026-09-29T07:35Z) gives a minimum of `72 workflows/parallel-worktrees.md` and a maximum of `608 workflows/divergent-design.md`. The top slightly exceeds 600. Precise version: "about 70-610 lines". (Output was read inline, not captured to a file; reproducible with the same command.)

**Evidence:** `workflows/parallel-worktrees.md:1-72`, `workflows/divergent-design.md:1-608`

---

## Claim 26: "Asserted on the body, not the whole file: the description also names the workflow, so a whole-file match survives deleting the handoff."

**Location:** `test/skills/workflow-routers.bats:71-72`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the exact fixed-string pattern the test uses and a filename-only pattern; does not establish other possible patterns.

The descriptions do name the workflow (`Route a feasibility question into workflows/spike.md` at `skills/spike/SKILL.md:4`), so a whole-file match on the *filename* would survive deleting the handoff. But the test's pattern is the full phrase `grep -qF "Read and follow **\`workflows/$name.md\`**"` (`:73`), which no description contains. After deleting spike's handoff line, a whole-file `grep -cF 'Read and follow **`workflows/spike.md`**'` returned `0` (exit 1). So for the pattern actually used, restricting to the body is not what makes the test catch a deleted handoff. The rationale holds only for a looser pattern.

Command run during the mutation pass: cwd `/workspace/.claude/wt-routers`, 2026-09-29T07:37:24Z, grep exit 1.

**Evidence:** `test/skills/workflow-routers.bats:64-78`, `docs/reviews/execution-logs/cfc-routers-r2-b/mutations2.txt`

---

## Claim 27: Each test "fails when its contract breaks" (brief-submitted: the five tests each detect their contract violation)

**Location:** `test/skills/workflow-routers.bats:38-105`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one mutation per test (two for tests 2 and 3), each failing only the targeted test; does not establish detection of every possible violation (e.g. a handoff line present but inside a code fence, or `when:` present but empty).

Mutations, each on a scratch copy, command `timeout 120 bats <scratch>/<m>/test/skills/workflow-routers.bats`, cwd `/workspace/.claude/wt-routers`, 2026-09-29T07:38:37Z-07:38:40Z, all exit 1:
- m1 delete `skills/spike/` → only `not ok 1`
- m2 `name: pr-prepx`, m2b delete `when:` → only `not ok 2` (`bad frontmatter: pr-prep: name` / `: when`)
- m3 delete handoff line, m3b retarget it to `workflows/pr-prep.md` → only `not ok 3`
- m4 drop `(router)` from the H1 → only `not ok 4`
- m5b +30 body lines (50 total) → only `not ok 5`

Unmutated branch: exit 0, 5/5 ok.

**Evidence:** `docs/reviews/execution-logs/cfc-routers-r2-b/exit-codes.txt`, `docs/reviews/execution-logs/cfc-routers-r2-b/mutations.txt`, `docs/reviews/execution-logs/cfc-routers-r2-b/mutations2.txt`, `docs/reviews/execution-logs/cfc-routers-r2-b/branch-bats.txt`

---

## Claim 28: "Verified to fail on main (9 missing routers)." and "each stays a stub (<=45 body lines)"

**Location:** commit `3a63c56` message (`git log main..HEAD`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test run against `git archive main workflows skills` with this branch's test file, and the branch's router body lengths; does not establish behavior on a main that later gains workflows.

Command `timeout 120 bats <scratch>/main/test/skills/workflow-routers.bats`, cwd `/workspace/.claude/wt-routers`, exit 1, 2026-09-29T07:38:37Z. Output: `workflows with no skills/<name>/SKILL.md router: branch-strategy codebase-onboarding parallel-worktrees pr-prep research-plan-implement review-fix-loop spike task-decomposition user-testing-workflow` (9 names). The nine new routers have bodies of 19-22 lines (from the `body()` count in `mutations2.txt`).

**Evidence:** `docs/reviews/execution-logs/cfc-routers-r2-b/mutations.txt`, `docs/reviews/execution-logs/cfc-routers-r2-b/exit-codes.txt`, `docs/reviews/execution-logs/cfc-routers-r2-b/mutations2.txt`

---

## Claim 29: "Takes effect in other projects after install.sh + rebuild (~/.claude/skills links to the installed payload)." and the 15-vs-0 rationale

**Location:** commit `3a63c56` message (`git log main..HEAD`)
**Type:** Architectural / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the install mechanism and the commit's 15:0 citation; does not establish bare-host behavior (copies, not links, per install.sh's header).

The install part holds. `link-claude-home.sh` says `The payload is baked into the image at /opt/claude-workflows ... and symlinked into the volume here, at every container start` (`devcontainer-config/link-claude-home.sh:15-17`), and getting a change in `requires a human on the host: edit the repo, run install.sh, read the diff, bless, rebuild` (`:22-23`). On a bare host install.sh copies instead (`WHY COPIES RATHER THAN SYMLINKS INTO THE REPO`, `devcontainer-config/install.sh:13`), which matches "after install.sh" there too.

The verdict comes from the commit's first paragraph, which repeats Claim 1: "(divergent-design) was opened 15 times in 49 days while research-plan-implement ... was opened zero times (docs/working/triage-2026-09-17-backlog.md §2.2)". The cited section withdrew that finding (`docs/working/triage-2026-09-17-backlog.md:170-178`). Split was not applied because the commit message cannot be amended per claim, and the actionable fix sits with Claims 1 and 23.

**Evidence:** `devcontainer-config/link-claude-home.sh:1-40`, `devcontainer-config/install.sh:1-24`, `docs/working/triage-2026-09-17-backlog.md:170-178`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`docs/decisions/log.md:88`): cites triage §2.2's 15:0 read counts as evidence, but §2.2 withdrew them the same day (Q-017, under-counting instrument); drop them or say they were withdrawn.
- **Claim 14c** (`skills/review-fix-loop/SKILL.md:5-6`): "2 clean passes" is not in review-fix-loop.md (exit is one clean iteration, or ship with known issues); 2-clean is decision 031 / code-review's rule and is scoped. Attribute it correctly or remove it.
- **Claim 15** (`skills/review-fix-loop/SKILL.md:21-22`): "applies whenever a rubric is being acted on" contradicts review-fix-loop.md:211 ("should not be run as a standalone workflow — use pr-prep").
- **Claim 23** (`test/skills/workflow-routers.bats:8-11`): same withdrawn 15:0 evidence as Claim 1 (also repeated in the commit message, Claim 29).
- **Claim 29** (commit `3a63c56` message): install-path part is right, but it repeats the withdrawn 15:0 evidence.

### Mostly Accurate
- **Claim 4** (`docs/decisions/log.md:88`): "log 65" exists only on unmerged `fix/agents-md-no-imports`.
- **Claim 6b** (`global-instructions/CLAUDE.md:13`): the Skill tool loads the router, which points at the workflow; it does not load the workflow itself.
- **Claim 10** (`skills/pr-prep/SKILL.md:4-6`): on the GitHub path the draft PR opens at step 2, before the review-fix loop.
- **Claim 11** (`skills/pr-prep/SKILL.md:22`): the delivery path is picked "before Step 0", in an unnumbered preamble.
- **Claim 12** (`skills/pr-prep/SKILL.md:28-29`): review-fix-loop.md owns only the control rules; pr-prep Step 3 owns the iteration sequence, and step 3a runs self-eval and manual checks besides code-review.
- **Claim 14a** (`skills/review-fix-loop/SKILL.md:4-5`): triage, override-log writes and delta re-review live mainly in pr-prep Step 3 and code-review, not review-fix-loop.md.
- **Claim 14b** (`skills/review-fix-loop/SKILL.md:5`): at 3 iterations the loop hits a written escalate/split/abandon gate; it does not simply stop.
- **Claim 25** (`test/skills/workflow-routers.bats:18-19`): workflows run 72-608 lines, not 70-600.
- **Claim 26** (`test/skills/workflow-routers.bats:71-72`): the body-only rationale holds only for a filename-only pattern; the exact phrase the test greps is not in any description.

### Unverifiable
- (none)

## Goal-Alignment Note
- **Answered:** Checked every router's factual statements against the workflow each one names; the positioning claims (pr-prep vs code-review, task-decomposition vs parallel-worktrees, user-testing vs ui-visual-review, review-fix-loop standalone use); the bats header, run on the branch, against a `main` tree, and under seven scratch mutations (every test fails when its contract breaks); log row 66 and the commit message (Q-074, install path, row-65 reference, the 15:0 citation). Main issues: the 15:0 evidence was withdrawn by its own source, and the review-fix-loop router misstates its workflow's exit rule and standalone status.
- **Out of scope:** Router trigger-phrase quality and whether routers will actually fire (judgment, which row 66's revisit trigger measures); the full test suite and health-check (run separately per the brief); prose-level claims about Claude Code's skill listing.
- **Escalate:** Claim 5's scope note: row 66's revisit trigger reads `usage.jsonl` via `scripts/skill-usage-report.sh`, the same instrument §2.2 withdrew for under-counting, so the revisit signal may inherit that problem. Two executed checks (Claims 22, 25) were read inline rather than captured to a log file; both are reproducible with the one command given.
