Commit: 3a63c56
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-routers (branch feat/workflow-router-skills)
**Scope:** `git diff main...HEAD` (12 files: 9 new `skills/<name>/SKILL.md` routers, `test/skills/workflow-routers.bats`, `global-instructions/CLAUDE.md`, `docs/decisions/log.md`), commit message of 3a63c56, and `README.md` where it describes the changed `skills/` tree
**Checked:** 2026-09-29
**Total claims checked:** 32
**Summary:** 18 verified, 7 mostly accurate, 1 stale, 6 incorrect, 0 unverifiable

Execution provenance (shared by every `executed` claim below). Commands ran at 2026-09-29T00:39:22-07:00; captured output lives in `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/fc-r1-routers-b7/logs/` (`run.txt` holds the exit codes; `main-tree.txt`, `head.txt`, `m1.txt`–`m6.txt` hold each full bats output). The scratch trees were built by `git archive <ref> workflows skills | tar -x` plus a copy of HEAD's `test/skills/workflow-routers.bats`. No tracked file in the worktree was modified, and all scratch trees were deleted afterwards.

- main tree: cwd `<scratch>/main` (main's `workflows/` + `skills/`), `timeout 60 bats test/skills/workflow-routers.bats` gave exit 1
- HEAD: cwd `/workspace/.claude/wt-routers`, same command, exit 0
- Mutations M1–M6: cwd `<scratch>/m` (HEAD tree, one edit to `skills/spike/SKILL.md` each), same command, exit 1 every time. M1 removed the body handoff line, M2 deleted `when:`, M3 renamed to `name: spikes`, M4 removed `(router)` from the H1, M5 appended 30 lines, M6 deleted the file

Hallucination-pattern log read. Claims 4, 7 and 25b are close to the logged class "a specific measured value quoted from a checked-in artifact set": here the quoted value *is* in the artifact, but that artifact withdraws it.

---

## Claim 1: "Verified to fail on main (9 missing routers)."

**Location:** `git log 3a63c56` (commit message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test file run against main's `workflows/` and `skills/` trees. It does not establish that tests 2–5 would fail on main: they `continue` past missing routers, so on main they pass vacuously for the nine missing routers.

Run against main's tree, test 1 failed and named exactly nine workflows: `# workflows with no skills/<name>/SKILL.md router: branch-strategy codebase-onboarding parallel-worktrees pr-prep research-plan-implement review-fix-loop spike task-decomposition user-testing-workflow` (main-tree.txt). Tests 2–5 printed `ok`. Exit code 1.

**Evidence:** `test/skills/workflow-routers.bats:38-48`, `.../fc-r1-routers-b7/logs/main-tree.txt`, `.../fc-r1-routers-b7/logs/run.txt`

---

## Claim 2: "No procedure is restated, so router and workflow cannot drift." (repeated in every router body as "this file is a stub so the router and the workflow cannot drift apart")

**Location:** `git log 3a63c56` (commit message body); also e.g. `skills/review-fix-loop/SKILL.md:27-28`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the routers carry workflow facts that can diverge from the workflow files. It does not judge whether the amount restated is too much, which is a design question.

Each router's `description:` summarizes its workflow's step sequence, and each body states workflow facts: outputs, gates, first steps, ownership. Examples are `skills/review-fix-loop/SKILL.md:4-6` ("triage by tier, fix, record declined findings in the override log, re-review only the delta, stop at 3 iterations or 2 clean passes") and `skills/pr-prep/SKILL.md:4-5` ("size gate, review-fix loop, history cleanup, verification, then a local merge (solo) or a GitHub PR"). At least two of these have already diverged from their workflow, as Claims 19 and 20b show. A maintainer who trusts "cannot drift" would not re-check routers after editing a workflow.

**Evidence:** `skills/review-fix-loop/SKILL.md:4-6,21-22`, `skills/pr-prep/SKILL.md:4-5`, `workflows/review-fix-loop.md:39-46,211`

---

## Claim 3: "Takes effect in other projects after install.sh + rebuild (~/.claude/skills links to the installed payload)."

**Location:** `git log 3a63c56` (commit message body)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the devcontainer route (`link-claude-home.sh`). It does not establish the bare-host route, which copies files (decision 037) instead of linking them, so there "links" does not hold, though the takes-effect-after-install point does.

`devcontainer-config/link-claude-home.sh:50` sets `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)`, and `:59/:64` run `ln -sfn "$SRC/$name" "$target"` with `SRC="${CC_WORKFLOWS_DIR:-/opt/claude-workflows}"` (`:35`). The live volume shows `skills -> /opt/claude-workflows/skills` and `workflows -> /opt/claude-workflows/workflows`. The installed `~/.claude/skills` currently lists the 25 pre-branch skills, which confirms the routers are absent until a rebuild (paraphrased — no quote available because this is a directory listing, not a file snippet). The routers' "installed copy: `~/.claude/workflows/<name>.md`" pointers resolve the same way.

**Evidence:** `devcontainer-config/link-claude-home.sh:35,50,55-66`, `devcontainer-config/install.sh:135`

---

## Claim 4: "The one workflow that had a router (divergent-design) was opened 15 times in 49 days while research-plan-implement, the documented default, was opened zero times (docs/working/triage-2026-09-17-backlog.md §2.2)."

**Location:** `git log 3a63c56` (commit message body)
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Same finding as Claim 25b (see there for the quotes). It covers the use of these numbers as evidence. It does not dispute that the numbers match §2.2's table.

The cited section withdraws these figures as evidence on the day it was written: "**So this finding is withdrawn as evidence.** … The 15:0 contrast goes with it" (`docs/working/triage-2026-09-17-backlog.md:174-177`), confirmed in Q-017 (`docs/working/questions-archive.md:229`, "the measurement is not trustworthy, so the finding is withdrawn as evidence").

**Evidence:** `docs/working/triage-2026-09-17-backlog.md:152-179`, `docs/working/questions-archive.md:218-245`

---

## Claim 5: "`skills/` holds 25 Claude Code skills … process skills (… `divergent-design` router)"

**Location:** `README.md:182`
**Type:** Configuration / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count and the router list in the README. It does not check the README's other category lists.

The README (unchanged on this branch) says `` `skills/` holds 25 Claude Code skills `` (`README.md:182`), which was true on main. With the nine routers this branch adds, `ls -d skills/*/ | wc -l` gives 34, and divergent-design is no longer the only router (paraphrased — no quote available because the count comes from a directory listing).

**Evidence:** `README.md:182`

---

## Claim 6: "`test/skills/workflow-routers.bats` fails if a workflow lacks a router, a router's body lacks the handoff, or a body passes 45 lines."

**Location:** `docs/decisions/log.md:88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named failure conditions (M6, M1, M5). It does not list the test's two other checks (frontmatter and H1 `(router)`), which the row omits but which also exist (Claim 29).

M6 (router deleted) failed test 1 with `router: spike`. M1 (handoff line removed) failed test 3. M5 (30 extra lines) failed test 5 (m6.txt, m1.txt, m5.txt). The threshold is set by `MAX_BODY_LINES=45` (`test/skills/workflow-routers.bats:20`).

**Evidence:** `test/skills/workflow-routers.bats:20,38-105`, `.../fc-r1-routers-b7/logs/m1.txt`, `m5.txt`, `m6.txt`, `run.txt`

---

## Claim 7: "The only workflow with a router (DD) was opened 15 times in 49 days while RPI, the documented default, was opened zero times (triage 2026-09-17 §2.2)"

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Same finding as Claim 25b. It covers the row's use of withdrawn figures as rationale. It does not establish whether RPI is actually under-used.

§2.2 withdraws the figures (`triage-2026-09-17-backlog.md:174`, "**So this finding is withdrawn as evidence.**"). The global instructions' running-questions rules say not to route "a number from an instrument with a known under-counting history" without re-validating it first. That rule came from this exact finding (Q-017).

**Evidence:** `docs/working/triage-2026-09-17-backlog.md:170-187`, `docs/working/questions-archive.md:229-245`

---

## Claim 8: "pr-prep's advisory Step 0 wrote 1 failure pattern across ~128 fix commits (Q-074)"

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the transcription from Q-074 and a recount against git history. It does not establish that Step 0, rather than some other path, wrote the one entry.

Q-074 reads: "`docs/thoughts/failure-patterns.md` has gained 1 entry across about 128 `fix` commits" (`docs/working/questions.md:70`), so the transcription is faithful. The entry count checks out: 164 `FP-` entries at the backfill commit `ff313163` and 165 now. The commit count is low, though. `git log ff313163..main --grep='^fix'` counts 144 commits before Q-074 was opened (2026-09-26 12:00) and 199 on main today (paraphrased — no quote available because these are command outputs, not file text). A precise version is "1 entry across ~144 (now ~199) fix commits". That strengthens the row's point rather than weakening it.

**Evidence:** `docs/working/questions.md:67-72`, `docs/thoughts/failure-patterns.md`

---

## Claim 9: "User request 2026-09-28; log 65" (Full Record column)

**Location:** `docs/decisions/log.md:88`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether row 65 exists. It does not verify the user-request date, which is outside the repo.

`grep -n "^| 6[0-9] " docs/decisions/log.md` on this branch (and on main) jumps from row 64 (`:87`) to 66 (`:88`). Row 65 ("**AGENTS.md names workflows by bare filename, never by `@` import.**") exists only on the unmerged sibling branch `fix/agents-md-no-imports`. The reference dangles until that branch merges, and main's log will have a gap at 65 if this branch merges first.

**Evidence:** `docs/decisions/log.md:87-88`, `fix/agents-md-no-imports:docs/decisions/log.md:88`

---

## Claim 10: "Revisit if, 30 days after install, router invocations stay near zero for RPI and pr-prep (`scripts/skill-usage-report.sh`)"

**Location:** `docs/decisions/log.md:88`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the script exists and reports skill invocations from `usage.jsonl`. It does not establish that the measurement is trustworthy: it is the same `hooks/log-usage.sh` → `usage.jsonl` instrument that Q-017 declared untrustworthy, so "near zero" would be ambiguous in the same way.

`scripts/skill-usage-report.sh:2` states "Reads ~/.claude/logs/usage.jsonl and reports skill/workflow usage frequency", and `hooks/log-usage.sh:33` logs `skill_tool — Skill tool invocation (real use)`. Q-017's answer says "hook measurement problems have recurred often enough that they lost faith in the numbers generally" (`docs/working/questions-archive.md:232-234`).

**Evidence:** `scripts/skill-usage-report.sh:1-35`, `hooks/log-usage.sh:2-68`, `docs/working/questions-archive.md:229-245`

---

## Claim 11a: "Each `workflows/<name>.md` ships a router skill of the same name (`skills/<name>/SKILL.md`)"

**Location:** `global-instructions/CLAUDE.md:13`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repo tree at HEAD (10 workflows, 10 routers). It does not establish that the installed payload has them, which it will not until install + rebuild (Claim 3).

The HEAD run passed `ok 1 every workflow has a router skill of the same name` (head.txt, exit 0). `workflows/` holds 10 files, and each has a `skills/<name>/SKILL.md`.

**Evidence:** `test/skills/workflow-routers.bats:38-48`, `.../fc-r1-routers-b7/logs/head.txt`, `run.txt`

---

## Claim 11b: "…started with the Skill tool, which loads the workflow."

**Location:** `global-instructions/CLAUDE.md:13`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mechanism of what the Skill call loads. It does not check how the harness renders skills.

The Skill tool loads the router's `SKILL.md`, a 19–37-line stub. The workflow is loaded only when the agent then follows the router's instruction, "Read and follow **`workflows/<name>.md`** end to end" (e.g., `skills/spike/SKILL.md:26`). A precise version is "which loads a router that tells the agent to read the workflow". The practical effect is the same if the agent complies.

**Evidence:** `skills/spike/SKILL.md:24-29`

---

## Claim 12: "Replacing a shared branch always needs explicit user approval, in any operating mode."

**Location:** `skills/branch-strategy/SKILL.md:29-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the workflow's force-push/promotion gates. It does not establish that a harness actually enforces it.

The workflow says the `dev` reset push is a "**gated operation requiring explicit human approval** (see Operating Modes in CLAUDE.md), regardless of away/active mode" (`workflows/branch-strategy.md:187-188`). The refresh procedure says "the shared-pointer swap is gated on human approval (Operating Modes), not done automatically — even in `/away` mode" (`:373-376`).

**Evidence:** `workflows/branch-strategy.md:185-190,327-337,373-376`

---

## Claim 13: "Its output is `docs/working/onboarding-{project}.md`, which later RPI research loads instead of re-exploring."

**Location:** `skills/codebase-onboarding/SKILL.md:29-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the output path and the stated RPI handoff. It does not establish that RPI's own text requires loading it; the handoff is stated in onboarding and in RPI's "← From Onboarding" pivot.

`workflows/codebase-onboarding.md:30`: "`docs/working/onboarding-{project}.md` — the orientation document". Step 12 says "Compile steps 1-11 into `docs/working/onboarding-{project}.md`" (`:375`). The RPI pivot text reads "The onboarding doc's architecture map and key flows replace the 'explore from scratch' part of research" (`workflows/research-plan-implement.md`, When to pivot).

**Evidence:** `workflows/codebase-onboarding.md:30,375`, `workflows/research-plan-implement.md:18`

---

## Claim 14: "It includes the manual `git worktree add` fallback for when Agent-tool worktree isolation fails."

**Location:** `skills/parallel-worktrees/SKILL.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the fallback exists and that failure is one of its triggers. It does not cover the other triggers (human-driven sessions, isolation unavailable), which the router leaves out.

`workflows/parallel-worktrees.md:39`: "Manual fallback. Use it for human-driven sessions, when Agent-tool isolation is not available, or when it **fails or misbehaves**", followed by `git worktree add .claude/wt-item-1 -b feat/item-1 main` (`:42`).

**Evidence:** `workflows/parallel-worktrees.md:39-47`

---

## Claim 15: "size gate, review-fix loop, history cleanup, verification, then a local merge (solo) or a GitHub PR. Runs code-review as one of its steps"

**Location:** `skills/pr-prep/SKILL.md:4-6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of the named steps and code-review's place in step 3a. It does not establish the GitHub path's timing: on that path the draft PR opens at step 2, before the loop, not only at the end.

The headings run "#### 1. Gate checks" (`workflows/pr-prep.md:82`, size gate at 1a), "#### 3. Review-fix loop" (`:174`), "#### 4. Clean up commit history" (`:293`) and "#### 5. Verify and annotate" (`:311`). Step 3a lists "**Code review** (`/code-review`) — multi-critic structural review of the diff vs main" (`:181`).

**Evidence:** `workflows/pr-prep.md:18-30,82,159,174,181,293,311`

---

## Claim 16: "The workflow picks the delivery path (local merge vs GitHub PR) in its first step."

**Location:** `skills/pr-prep/SKILL.md:22`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the delivery-path choice sits in the workflow. It does not dispute that the choice is made first.

The choice is an unnumbered section placed before the steps, "### Delivery path: local merge or GitHub PR … Pick the path before Step 0" (`workflows/pr-prep.md:18-20`), and the first numbered step is "### Step 0: Environment scan" (`:32`). A precise version is "before its first step (Step 0)".

**Evidence:** `workflows/pr-prep.md:18-32`

---

## Claim 17: "Its review-fix loop is owned by `workflows/review-fix-loop.md`; its reviews run through the `code-review` skill."

**Location:** `skills/pr-prep/SKILL.md:28-29`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ownership split stated in the two workflows. It does not assess whether the split is a good one.

`workflows/review-fix-loop.md:7` divides ownership: it "owns the review-fix loop's control rules: the iteration cap and its exit conditions, the early split trigger, the fix-drift check, and the two re-fire filters", while "[pr-prep Step 3] owns the step sequence of each iteration (generate → triage and fix → test → re-review → exit) and when override-log rows are written". A precise version is "its loop's control rules are owned by `workflows/review-fix-loop.md`". The code-review half holds (`workflows/pr-prep.md:181`).

**Evidence:** `workflows/review-fix-loop.md:7`, `workflows/pr-prep.md:174-260`

---

## Claim 18: "Its outputs are `docs/working/research-{topic}.md`, `plan-{topic}.md` and `checkpoint-{topic}.md`, and its hard gate is plan approval before implementation."

**Location:** `skills/research-plan-implement/SKILL.md:29-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three working docs and the implementation gate. It does not cover the optional handoff doc (`handoff-{topic}.md`) or the test-first review checkpoint, which the router leaves out.

The workflow lists `docs/working/research-{topic}.md`, `plan-{topic}.md` and `checkpoint-{topic}.md` (`workflows/research-plan-implement.md:30-32`). Step 4 states "This is the hard gate. … **implementation does not begin until the user has reviewed the plan**" (`:362`).

**Evidence:** `workflows/research-plan-implement.md:28-32,117,360-362`

---

## Claim 19: "Route acting on code-review findings into workflows/review-fix-loop.md: triage by tier, fix, record declined findings in the override log, re-review only the delta, stop at 3 iterations or 2 clean passes."

**Location:** `skills/review-fix-loop/SKILL.md:4-6`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the listed rules are the loop's rules and where they live. It does not establish which exit rule prevails when the workflow and code-review's SKILL.md disagree.

The 2-clean requirement is real policy, but not in the named workflow. `skills/code-review/SKILL.md:445` says "(which requires **2 consecutive clean passes** before merge)", from decision 031 C. The workflow's own exit condition is a single clean iteration: "Exit the loop at the end of any iteration where: 1. **Clean convergence.** No Must Fix items remain…" (`workflows/review-fix-loop.md:41-43`). `grep -i "consecutive\|2-clean" workflows/*.md` finds no match (paraphrased — no quote available because this claim concerns absence of a match). Three iterations are also not a stop but a gate: "iteration 4 cannot begin until an explicit `escalate | split | abandon` decision has been recorded" (`:25`). The override-log write and delta re-review are pr-prep Step 3b/3d rules (`workflows/review-fix-loop.md:7`), not this file's. A precise version is "…cap at 3 iterations (then escalate/split/abandon); code-review requires 2 consecutive clean passes before merge".

**Evidence:** `workflows/review-fix-loop.md:7,23-46`, `skills/code-review/SKILL.md:128-129,443-456`, `docs/decisions/log.md:58`

---

## Claim 20a: "Usually entered from `pr-prep` step 3"

**Location:** `skills/review-fix-loop/SKILL.md:22`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pr-prep entry point only.

`workflows/pr-prep.md:174` is headed "#### 3. Review-fix loop", and `workflows/review-fix-loop.md:211` reads "The loop is embedded in pr-prep as a required step (Phase 1, step 3)."

**Evidence:** `workflows/pr-prep.md:174`, `workflows/review-fix-loop.md:211`

---

## Claim 20b: "…but applies whenever a rubric is being acted on." (with `when: A code-review rubric exists for the current branch and its findings are being fixed or declined`)

**Location:** `skills/review-fix-loop/SKILL.md:22` (also `:8`)
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the router's positioning against the workflow's own statement. It does not decide which of the two should change.

The workflow forbids standalone use: "It should not be run as a standalone workflow — use pr-prep, which sequences it within a two-phase process" (`workflows/review-fix-loop.md:211`). The router and its `when:` line advertise standalone entry whenever a rubric exists, so an agent that invokes this skill directly would skip pr-prep's gates (size cap, verification before the critic ensemble).

**Evidence:** `workflows/review-fix-loop.md:207-211`, `skills/review-fix-loop/SKILL.md:8,19-22`

---

## Claim 21: "The tier definitions it acts on live in `skills/code-review/references/rubric.md`."

**Location:** `skills/review-fix-loop/SKILL.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the tier definitions live. It does not cover where the override-log format lives (`references/override-log.md`).

`workflows/review-fix-loop.md:7`: "The code-review skill owns the tier definitions ([rubric](../skills/code-review/references/rubric.md))". The rubric has `## 🔴 Must Fix` (`rubric.md:48`), `## 🟡 Must Address` (`:59`) and `## 🟢 Consider` (`:78`).

**Evidence:** `workflows/review-fix-loop.md:7`, `skills/code-review/references/rubric.md:48,59,78,300-307`

---

## Claim 22: "Its first step greps `docs/thoughts/spike-graveyard.md` for prior abandoned attempts."

**Location:** `skills/spike/SKILL.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers step 1's action. It does not cover step 1's create-if-missing branch.

`workflows/spike.md:22-24`: "### 1. Check the graveyard (essential) … Before scoping the spike question, grep `docs/thoughts/spike-graveyard.md` for keywords from the question".

**Evidence:** `workflows/spike.md:22-54`

---

## Claim 23: "It ends by entering `research-plan-implement` with the synthesized research doc." / "Not for several unrelated tasks in one message (that is parallel-worktrees)."

**Location:** `skills/task-decomposition/SKILL.md:30-31` (and `:6-7`)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the final step and the boundary with parallel-worktrees. It does not cover the description's intermediate step list beyond interface contracts and reconcile, which were spot-checked (`:46`, `:145`).

`workflows/task-decomposition.md:199` reads "### 7. Plan and implement sequentially", and its checklist item reads "The RPI workflow has been entered with the synthesized research doc as input" (`:204`). `workflows/parallel-worktrees.md` lists as "Not this workflow": "*One* task whose research fans out but whose implementation stays sequential → `task-decomposition.md`".

**Evidence:** `workflows/task-decomposition.md:46,145,199-205`, `workflows/parallel-worktrees.md:5-8`

---

## Claim 24: "Its findings report lands at `docs/working/testing-findings-{topic}.md`."

**Location:** `skills/user-testing-workflow/SKILL.md:28-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Phase 4 report path. It does not check the router's `ui-visual-review` positioning beyond its plain reading, which matches that skill's description (layout review of a rendered UI).

`workflows/user-testing-workflow.md:404`: "Save the report as `docs/working/testing-findings-{topic}.md` — this is 'the findings doc'".

**Evidence:** `workflows/user-testing-workflow.md:12,404`

---

## Claim 25a: "divergent-design … was opened 15 times in 49 days while research-plan-implement … was opened zero times" (as a transcription of §2.2's table)

**Location:** `test/skills/workflow-routers.bats:8-11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only that the numbers match the cited table. Claim 25b covers whether that table is valid evidence.

`docs/working/triage-2026-09-17-backlog.md:158-163`: "| `divergent-design` | **15** |" … "| **`research-plan-implement`** | **0** |", with "reads in 49 days".

**Evidence:** `docs/working/triage-2026-09-17-backlog.md:152-165`

---

## Claim 25b: the same sentence, offered as the "Why" for the test and the routers

**Location:** `test/skills/workflow-routers.bats:6-11`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the cited source supports the figures as evidence. It does not establish the true usage of either workflow, which the source says the data cannot determine.

The cited section carries a same-day correction: "**So this finding is withdrawn as evidence.** 0 reads is equally consistent with the doc being unused and with the instrument not seeing it, and the data cannot separate them. The 15:0 contrast goes with it: divergent-design's 15 is a lower bound from the same instrument, not a comparable measurement." (`docs/working/triage-2026-09-17-backlog.md:174-178`). Q-017 was answered the same way (`docs/working/questions-archive.md:229`). The metric also counts `Read`s of workflow files ("logs a `workflow` event on any `Read` of a file under `*/workflows/*`", `:154-155`), not skill openings. The same claim recurs in Claims 4 and 7.

**Evidence:** `docs/working/triage-2026-09-17-backlog.md:152-187`, `docs/working/questions-archive.md:218-245`

---

## Claim 26: "divergent-design's own, stricter contract lives in divergent-design-router.bats."

**Location:** `test/skills/workflow-routers.bats:12`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the file exists and asserts more than this suite does. It does not compare the two suites test by test.

`test/skills/divergent-design-router.bats` has 8 tests, including "the workflow file it routes to actually exists" (`:69`), "skill body states the 3+ tradeoff-bearing options trigger test" (`:75`) and "skill does not restate the full diverge/diagnose/match/decide process inline" (`:105`). None of these are in the generic suite.

**Evidence:** `test/skills/divergent-design-router.bats:45-105`

---

## Claim 27: "the workflows it points at run 70-600 lines"

**Location:** `test/skills/workflow-routers.bats:18-19`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line counts of the 10 files at HEAD, all of which this suite iterates, divergent-design included.

`wc -l workflows/*.md` gives a minimum of 72 (`parallel-worktrees.md`) and a maximum of 608 (`divergent-design.md`) (paraphrased — no quote available because these are command outputs). A precise version is "70–610" or "~70–600". The 45-line rationale is unaffected.

**Evidence:** `workflows/parallel-worktrees.md`, `workflows/divergent-design.md`

---

## Claim 28: "Asserted on the body, not the whole file: the description also names the workflow, so a whole-file match survives deleting the handoff."

**Location:** `test/skills/workflow-routers.bats:70-71`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact string the test greps for. It does not establish the looser case (a pattern of just `workflows/<name>.md`), where the comment would hold.

The assertion greps for `"Read and follow **\`workflows/$name.md\`**"` (`:72`). No router's frontmatter contains `Read and follow`: a loop over all 10 frontmatters found none. The descriptions only say, for example, "into workflows/spike.md". After M1 removed the body handoff, a whole-file `grep -cF 'Read and follow **\`workflows/spike.md\`**'` returned 0 (run.txt: "M1 whole-file grep count after mutation: 0"), so a whole-file match would *not* survive the deletion. Restricting to the body is harmless. The stated reason is just false for this pattern.

**Evidence:** `test/skills/workflow-routers.bats:66-80`, `.../fc-r1-routers-b7/logs/run.txt`, `.../fc-r1-routers-b7/logs/m1.txt`

---

## Claim 29: each test "fails when its contract breaks" (the header's "Validates that every workflow has a router skill, and that each router keeps the router contract")

**Location:** `test/skills/workflow-routers.bats:3-4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one mutation per test on one router (spike) and a clean run at HEAD. It does not establish detection of every possible break. For example, test 4's `grep -qiE '^# .*\(router\)'` would accept `(router)` on any H1-looking body line, and test 2 checks only that `description:`/`when:` keys are present, not what they say.

At HEAD all 5 tests pass (exit 0). Each mutation failed exactly its own test and no other: M6 failed test 1, M2 and M3 failed test 2, M1 failed test 3, M4 failed test 4, M5 failed test 5. Every mutation exited 1 (run.txt, m1–m6.txt).

**Evidence:** `test/skills/workflow-routers.bats:38-105`, `.../fc-r1-routers-b7/logs/run.txt`, `head.txt`, `m1.txt`–`m6.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`git log 3a63c56`; router bodies): "cannot drift". Routers restate workflow facts, and two have already drifted (Claims 19, 20b). Soften it, or drop the restated facts.
- **Claim 4** (`git log 3a63c56`): cites §2.2's 15:0 figures, which §2.2 and Q-017 withdrew as evidence.
- **Claim 7** (`docs/decisions/log.md:88`): the same withdrawn 15:0 figures used as the row's rationale.
- **Claim 20b** (`skills/review-fix-loop/SKILL.md:8,22`): advertises standalone use, while the workflow says "should not be run as a standalone workflow — use pr-prep".
- **Claim 25b** (`test/skills/workflow-routers.bats:6-11`): the header's "Why" rests on the withdrawn 15:0 measurement.
- **Claim 28** (`test/skills/workflow-routers.bats:70-71`): no description contains `Read and follow **…**`, so a whole-file match would not survive deleting the handoff.

### Stale
- **Claim 5** (`README.md:182`): "25 Claude Code skills … `divergent-design` router". The branch makes it 34 skills and 10 routers.

### Mostly Accurate
- **Claim 8** (`docs/decisions/log.md:88`): ~128 fix commits is Q-074's figure. The git count is ~144 at Q-074 and ~199 now.
- **Claim 9** (`docs/decisions/log.md:88`): "log 65" exists only on unmerged `fix/agents-md-no-imports`.
- **Claim 11b** (`global-instructions/CLAUDE.md:13`): the Skill tool loads the router, which then tells the agent to read the workflow.
- **Claim 16** (`skills/pr-prep/SKILL.md:22`): the delivery path is picked "before Step 0", in an unnumbered section.
- **Claim 17** (`skills/pr-prep/SKILL.md:28`): review-fix-loop.md owns the loop's control rules, and pr-prep Step 3 owns its step sequence.
- **Claim 19** (`skills/review-fix-loop/SKILL.md:4-6`): "2 clean passes" comes from code-review/decision 031, not the workflow, whose exit is one clean iteration. The 3-iteration cap is a gate, not a stop.
- **Claim 27** (`test/skills/workflow-routers.bats:18`): workflows run 72–608 lines.

### Unverifiable
- (none)

---

## Goal-Alignment Note
- **Answered:** Every claim the brief flagged. That covers all nine routers' workflow facts against their workflow files, the positioning claims, the bats header (15/0, 70–600, per-test failure via six mutations in a scratch tree), row 66 (Q-074, log 65, revisit instrument), the commit's "fails on main (9 missing)" (executed) and installed-path claims, and the global-instructions paragraph.
- **Out of scope:** I did not run the full suite or health-check, per the brief. I did not check whether other suites (for example README/skill-list sync tests) break on 34 skills; that belongs to the separately run gate. I left description trigger-phrase quality alone as design, not fact.
- **Escalate:** The branch's core motivation (15:0, in the commit, row 66 and the bats header) cites a measurement its own source and Q-017 withdrew. Also, the review-fix-loop router contradicts its workflow's "not standalone" rule. Both likely need an author decision, not a mechanical fix.
