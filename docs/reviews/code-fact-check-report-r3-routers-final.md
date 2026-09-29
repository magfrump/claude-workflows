Commit: 33fdfd3

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-routers (branch feat/workflow-router-skills)
**Scope:** `git diff main...HEAD -- . ':(exclude)docs/reviews'` (14 files) plus the messages of `git log main..HEAD` (replicate b of 3, final confirming pass)
**Checked:** 2026-09-29
**Total claims checked:** 27
**Summary:** 25 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). The closest pattern is the class "test tally claimed in a commit message" (`mode1-equiv 33`, `All 85 tests`); Claim 20's "workflow-routers (6)" was checked against it and holds.

Execution logs: `docs/reviews/execution-logs/fc-r3-routers-final-b/` (`probe-commands.txt` lists every command, mutation and exit code).

---

## Claim 1: "`skills/` holds 33 Claude Code skills"

**Location:** `README.md:182`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count of directories under `skills/` at 33fdfd3; does not establish that each has a loadable SKILL.md or that `install.sh` copies all of them.

`ls skills | wc -l` prints `33` (paraphrased — no quote available because the claim is about directory layout, not a snippet): the 25 pre-branch skills plus the 8 new routers.

**Evidence:** `skills/`

---

## Claim 2: "a router skill for each workflow except `review-fix-loop` (`divergent-design`, `research-plan-implement`, `pr-prep`, `spike`, …), each of which hands off to its `workflows/` file"

**Location:** `README.md:182`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the one-to-one match between `workflows/*.md` (10 files) and router directories (9, no `review-fix-loop`), and the handoff line in each router body; does not establish that the routers fire in a live session.

`workflows/` holds 10 files and `skills/` holds a same-named directory for 9 of them, all but `review-fix-loop` (paraphrased — no quote available because the claim is about directory layout). Each router body contains the handoff, e.g. `skills/spike/SKILL.md:19` "Read and follow **`workflows/spike.md`** end to end".

**Evidence:** `workflows/`, `skills/*/SKILL.md:19`, `skills/divergent-design/SKILL.md:39`

---

## Claim 3a: "Every workflow except `review-fix-loop` ships a router skill of the same name (`skills/<name>/SKILL.md`), a stub modeled on `skills/divergent-design/` that says when to use the workflow and hands off with "Read and follow **`workflows/<name>.md`**""

**Location:** `docs/decisions/log.md:89`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence, the `## When to use` section and the exact handoff phrase in all 8 new routers; does not establish "modeled on" beyond shared structure (H1 "(router)", "Does not re-implement the workflow — routes into it", When to use, Hand off).

Each router has `## When to use` at line 13 and `## Hand off to the workflow` at line 17, and line 11 ends "Does not re-implement the workflow — routes into it.", the same sentence as `skills/divergent-design/SKILL.md:17-18` (paraphrased — no quote available because the pattern is identical across 8 files; one instance quoted: `skills/pr-prep/SKILL.md:19` "Read and follow **`workflows/pr-prep.md`** end to end").

**Evidence:** `skills/{research-plan-implement,pr-prep,spike,codebase-onboarding,task-decomposition,parallel-worktrees,branch-strategy,user-testing-workflow}/SKILL.md:9-22`

---

## Claim 3b: "`review-fix-loop` opts out with `router: "none — <reason>"` in its own frontmatter, because it runs only inside pr-prep step 3 (its own "should not be run as a standalone workflow")"

**Location:** `docs/decisions/log.md:89`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the frontmatter line and the quoted sentence; does not establish anything about other consumers of the `router:` key (only the bats test reads it).

`workflows/review-fix-loop.md:3` `router: "none — runs only inside pr-prep step 3, never on its own (see Relationship to other workflows)"`; `workflows/review-fix-loop.md:212` "The loop is embedded in pr-prep as a required step (Phase 1, step 3). It should not be run as a standalone workflow".

**Evidence:** `workflows/review-fix-loop.md:3`, `workflows/review-fix-loop.md:212`

---

## Claim 3c: "Each router's description puts its "not for X (use Y)" precedence clause and triggers inside the first 250 characters"

**Location:** `docs/decisions/log.md:89`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the 8 new routers' folded descriptions measured by joining the `>` block's lines with single spaces; does not establish how the live skill listing counts characters (the 250 figure is the Q-080 convention, `docs/working/questions-archive.md:1467`, "first ~250 characters").

Measured (offsets 0-based; paraphrased — no quote available because these are computed offsets across 8 files, method in scope):

| Router | length | "Not for" at | "Triggers:" at | past char 250 |
|---|---|---|---|---|
| research-plan-implement | 268 | 91 | 211 | `", "fix this bug".` |
| pr-prep | 252 | none | 153 | `".` |
| spike | 254 | 101 | 177 | `pt".` |
| codebase-onboarding | 264 | 141 | 166 | `after months".` |
| task-decomposition | 270 | 123 | 176 | `oss-cutting change".` |
| parallel-worktrees | 249 | 130 | 189 | nothing |
| branch-strategy | 263 | 140 | 168 | `le branches".` |
| user-testing-workflow | 251 | 121 | 178 | `.` |

Every precedence sentence ends, and every `Triggers:` label starts, before char 250. Two imprecisions: (1) the clause is not uniformly "not for X (use Y)": pr-prep's is "Use code-review alone for a review with no landing." (`skills/pr-prep/SKILL.md:4`), and codebase-onboarding ("Not for a single lookup.", `:4`) and branch-strategy ("Not for one feature branch.", `:4`) name no Y; (2) "triggers inside" holds for the label and the first phrases only: the last trigger phrase is fully or partly past char 250 in 5 routers (research-plan-implement loses "fix this bug" entirely). Precise version: "puts a precedence sentence and the start of its trigger list inside the first 250 characters."

**Evidence:** `skills/*/SKILL.md:3-4`, `docs/working/questions-archive.md:1467`

---

## Claim 3d: "its body names the installed copy (`~/.claude/workflows/<name>.md`) and forbids following a same-named file from another project"

**Location:** `docs/decisions/log.md:89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the text of all 9 router bodies; does not establish that `install.sh` places workflows at `~/.claude/workflows/` beyond its source list (`devcontainer-config/install.sh:135` `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`), nor agent compliance.

`skills/spike/SKILL.md:19-21` "the installed copy at `~/.claude/workflows/spike.md`, or this repo's own file when working inside claude-workflows. Never follow a same-named file that belongs to another project." Same lines in the other 7 routers at 19-21 and in `skills/divergent-design/SKILL.md:42-44`.

**Evidence:** `skills/*/SKILL.md:19-21`, `skills/divergent-design/SKILL.md:42-44`, `devcontainer-config/install.sh:135`

---

## Claim 3e: "`test/skills/workflow-routers.bats` fails if a workflow without an opt-out lacks a router, an opted-out one gains one or gives no reason, a router's body lacks the handoff, the installed path or the never-follow line, or a body passes 45 lines"

**Location:** `docs/decisions/log.md:89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed failure condition, each triggered by one mutation of a scratch copy (see Claim 16); does not establish detection of mutations to a router that is not in `routed_names`, or of a body assertion satisfied by text in an unrelated section.

Executed; see Claim 16 for the command, cwd, exit codes and captured logs. `MAX_BODY_LINES=45` at `test/skills/workflow-routers.bats:25`.

**Evidence:** `test/skills/workflow-routers.bats:21-137`, `docs/reviews/execution-logs/fc-r3-routers-final-b/probe-commands.txt`

---

## Claim 3f: "The global instructions say to invoke a workflow's skill rather than paraphrase it, and that the decision tree's first-match order decides when two routers could fire."

**Location:** `docs/decisions/log.md:89`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the paragraph's text; does not establish the first-match claim's accuracy (Claim 5).

`global-instructions/CLAUDE.md:13` "When more than one router could fire, this table's first-match order still decides … When a row below activates a workflow, invoke its skill rather than paraphrasing the workflow from memory."

**Evidence:** `global-instructions/CLAUDE.md:13`

---

## Claim 3g: "DD's router was built for exactly this ("so divergent design competes at the skill-selection layer"). … pr-prep's advisory Step 0 wrote 1 failure pattern across ~128 fix commits as of Q-074. Hook-based usage counts are not cited: they under-count silently (Q-017, triage 2026-09-17 §2.2 correction)."

**Location:** `docs/decisions/log.md:89`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three cited sources as they read at 33fdfd3; does not establish the user's observation that workflows are applied less consistently (not checkable in the codebase).

`skills/divergent-design/SKILL.md:16` "Exists so divergent design competes at the **skill-selection layer**" (the log drops the bold). `docs/working/questions.md:70` "has gained 1 entry across about 128 `fix` commits. The writer is still pr-prep Step 0, a workflow step that is advisory only." `docs/working/triage-2026-09-17-backlog.md:178` "not a comparable measurement. Recorded as `Q-017`" and `:207` "(L3 later withdrawn — see §2.2 — leaving 4)".

**Evidence:** `skills/divergent-design/SKILL.md:16`, `docs/working/questions.md:67-72`, `docs/working/triage-2026-09-17-backlog.md:152-207`

---

## Claim 4: "Each `workflows/<name>.md` ships a router skill of the same name … the Skill tool loads the router, which points at the workflow to read. The exception is `review-fix-loop` (frontmatter `router: none`), which runs only inside `pr-prep`."

**Location:** `global-instructions/CLAUDE.md:13`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file-level correspondence and the frontmatter key; `router: none` abbreviates the actual value `"none — <reason>"`, which the test's `"?none` pattern accepts; does not establish Skill-tool loading behavior beyond what the router bodies say.

Directory match as in Claim 2 (paraphrased — no quote available because it is directory layout). `workflows/review-fix-loop.md:3` `router: "none — runs only inside pr-prep step 3, …"`; `test/skills/workflow-routers.bats:38` `grep -qE '^router:[[:space:]]*"?none'`.

**Evidence:** `workflows/`, `skills/`, `workflows/review-fix-loop.md:3`, `test/skills/workflow-routers.bats:37-39`

---

## Claim 5: "this table's first-match order still decides (a batch is row 2 before any single-task router; a 3+-option choice is row 3 before RPI)"

**Location:** `global-instructions/CLAUDE.md:13`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row numbers of the table immediately below; does not establish that the model applies first-match order when two skills' descriptions both match.

The table below lists row 2 as the batch row (`parallel-worktrees.md`), row 3 as `divergent-design.md`, and row 6 as `research-plan-implement.md`, under "Evaluate triggers top-to-bottom. Take the **first match**" (paraphrased — no quote available because the evidence spans a 12-row table; the header sentence is quoted).

**Evidence:** `global-instructions/CLAUDE.md:15-33`

---

## Claim 6: branch-strategy router — "dev integration branch, rebuilding it from open PRs, stale-branch triage … Replacing a shared branch always needs explicit user approval, in any operating mode."

**Location:** `skills/branch-strategy/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the description's three sections and the body's approval sentence (`:11`, `:15`) against the workflow; does not establish that the trigger phrases are distinct from other skills'.

`workflows/branch-strategy.md` has sections "Integration branch refresh" and "Stale-branch triage (advisory)", and the reset section says the force-push "is a **gated operation requiring explicit human approval** (see Operating Modes in CLAUDE.md), regardless of away/active mode."

**Evidence:** `skills/branch-strategy/SKILL.md:4-15`, `workflows/branch-strategy.md` (Setting up or resetting dev; Integration branch refresh step 7; Stale-branch triage)

---

## Claim 7: codebase-onboarding router — "producing one reusable orientation doc … Not for projects you started from scratch"

**Location:** `skills/codebase-onboarding/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the description and `:15` against the workflow's When to use and Working documents; does not establish the "single lookup" exclusion, which the workflow does not state but does not contradict.

`workflows/codebase-onboarding.md` "**Not a trigger:** from-scratch projects you started yourself", "RPI research is stuck: you can't scope research because you don't even know where to start looking", and "`docs/working/onboarding-{project}.md` — the orientation document … treated as a living reference".

**Evidence:** `skills/codebase-onboarding/SKILL.md:4-15`, `workflows/codebase-onboarding.md` (When to use, Working documents)

---

## Claim 8: divergent-design router — "Read the installed copy at `~/.claude/workflows/divergent-design.md`, or this repo's own file when working inside claude-workflows. Never follow a same-named file that belongs to another project."

**Location:** `skills/divergent-design/SKILL.md:42-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diff's only change to this file (the removed "cannot drift apart" clause and the added lines); does not re-verify the unchanged remainder of the router.

`git diff main...HEAD -- skills/divergent-design/SKILL.md` removes "so the router and the workflow cannot drift apart" and adds the quoted lines; the router still passes `test/skills/divergent-design-router.bats` (8 ok, exit 0, `docs/reviews/execution-logs/fc-r3-routers-final-b/head-divergent-design-router.txt`, run 2026-09-29T08:28Z, cwd the worktree).

**Evidence:** `skills/divergent-design/SKILL.md:39-45`, `docs/reviews/execution-logs/fc-r3-routers-final-b/head-divergent-design-router.txt`

---

## Claim 9: parallel-worktrees router — "Ask: "do these share files or an order?" No → this skill. Yes → one task, so use `research-plan-implement` or `task-decomposition`. Each item that lands still goes through `pr-prep`."

**Location:** `skills/parallel-worktrees/SKILL.md:15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the body and description against the workflow; does not establish trigger-phrase uniqueness.

`workflows/parallel-worktrees.md` "Ask: "do these share files or an order?" Yes → RPI (row 6) or task-decomposition (row 7). No → this workflow." and step 4 "Each one runs its own `pr-prep`".

**Evidence:** `skills/parallel-worktrees/SKILL.md:4-15`, `workflows/parallel-worktrees.md` (When NOT to fan out; step 4)

---

## Claim 10: pr-prep router — "review-fix loop, cleanup, then local merge or PR … Merging into `main`, pushing, and opening a PR follow the Operating Modes approval rules in the global instructions. The review-fix loop inside it has no router of its own: it runs only inside this workflow."

**Location:** `skills/pr-prep/SKILL.md:4-15`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the phase summary, the approval-rule pointer and the no-router statement; does not establish that `code-review` alone is the right tool for every no-landing review (a routing judgment).

`workflows/pr-prep.md` Phase 1 step 3 is the review-fix loop, Phase 2 step 4 "Clean up commit history", and the Delivery path section offers local merge or GitHub PR, with "Merging into `main` follows the Operating Modes in the global instructions". `workflows/review-fix-loop.md:212` "It should not be run as a standalone workflow — use pr-prep"; no `skills/review-fix-loop/` exists.

**Evidence:** `skills/pr-prep/SKILL.md:4-15`, `workflows/pr-prep.md` (Delivery path; steps 3-4), `workflows/review-fix-loop.md:212`

---

## Claim 11: research-plan-implement router — "Not for trivial edits (a typo, a config value, a one-line fix whose cause is known) … `divergent-design`, which feeds its decision back here. Its hard gate is plan approval before implementation."

**Location:** `skills/research-plan-implement/SKILL.md:15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the body against the workflow's When to skip, pivot and step 4 text; does not establish that the triggers avoid firing on trivial edits.

`workflows/research-plan-implement.md` step 4: "This is the hard gate. … implementation does not begin until the user has reviewed the plan"; When to skip: "Trivial changes (typo fixes, config tweaks, single-line bug fixes): Skip entirely"; "DD's decision feeds back into your plan."

**Evidence:** `skills/research-plan-implement/SKILL.md:4-15`, `workflows/research-plan-implement.md` (When to pivot; step 4; When to skip)

---

## Claim 12: spike router — "timeboxed, throwaway branch, recorded verdict … cannot be answered by reading the code"

**Location:** `skills/spike/SKILL.md:4-15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the description and body against spike.md steps 3-5 and the ← From RPI pivot; does not establish trigger uniqueness.

`workflows/spike.md` step 3 "Spikes have a hard time limit", step 4 "Work in a throwaway space", step 5 "Record the findings", and "When RPI research hits a "is this even feasible?" question that can't be answered by reading code, pause RPI and spike it."

**Evidence:** `skills/spike/SKILL.md:4-15`, `workflows/spike.md` (When to pivot; steps 3-5)

---

## Claim 13: task-decomposition router — "parallel research, then sequential build … fans out in parallel with explicit interface contracts"

**Location:** `skills/task-decomposition/SKILL.md:4-15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the body against the workflow's intro and step 1; interface contracts are required only when ≥2 sub-agents are dispatched, which "explicit interface contracts" does not qualify; does not establish trigger uniqueness.

`workflows/task-decomposition.md` "Implementation still happens sequentially in the main agent — sub-agents research and analyze" and "When **two or more sub-agents will be dispatched** in step 3, add an `## Interface contracts` subsection".

**Evidence:** `skills/task-decomposition/SKILL.md:4-15`, `workflows/task-decomposition.md` (intro; step 1)

---

## Claim 14: user-testing-workflow router — "scoping, moderator script, pilot, analysis, findings … HCI-grounded protocol … For reviewing a UI's layout without users, use `ui-visual-review`."

**Location:** `skills/user-testing-workflow/SKILL.md:4-15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the phase list and the HCI claim against the workflow, and the existence of `skills/ui-visual-review/`; does not establish trigger uniqueness.

`workflows/user-testing-workflow.md` "Grounded in HCI literature (Nielsen, Brooke, Travis, Dumas & Redish, etc.)", phases 0-4 (Scoping, Session Design with Pilot Session, Running, Analysis, Reporting). `skills/ui-visual-review/` exists (paraphrased — no quote available because it is directory layout).

**Evidence:** `skills/user-testing-workflow/SKILL.md:4-15`, `workflows/user-testing-workflow.md:3`, `skills/ui-visual-review/`

---

## Claim 15: test header and comments — "Validates that every workflow has a router skill unless its own frontmatter opts out …"; "the workflows it points at run about 70-610 lines"; "Asserted on the body … (same rule as divergent-design-router.bats)"; "divergent-design's own, stricter contract lives in divergent-design-router.bats"

**Location:** `test/skills/workflow-routers.bats:3-24`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header, the MAX_BODY_LINES comment and the body-assertion comment at `:96-97`; does not establish the security rationale at `:100-101` (design rationale, not checked).

`wc -l workflows/*.md` gives 72 (parallel-worktrees) to 608 (divergent-design) (paraphrased — no quote available because it is command output across 10 files). `test/skills/divergent-design-router.bats:20-25` "Assert on the body." and `SKILL_BODY=$(… awk '/^---$/ && n < 2 { n++; next } n >= 2')`, the same awk as `workflow-routers.bats:33`. `divergent-design-router.bats` has 8 tests against this file's 6 generic ones.

**Evidence:** `test/skills/workflow-routers.bats:3-34`, `:96-97`, `test/skills/divergent-design-router.bats:20-26`, `workflows/*.md`

---

## Claim 16: each of the file's 6 tests fails when its own contract breaks

**Location:** `test/skills/workflow-routers.bats:50-137`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 11 single mutations on a scratch copy of `skills/`, `workflows/` and the test (tracked files untouched), each failing exactly its target test and no other; does not establish detection of every possible regression (e.g. a `router: nonesuch` value, or a handoff line placed in the wrong section).

Command per case: `cd $SCRATCH/mut && timeout 60 bats test/skills/workflow-routers.bats > <case>.txt`, scratch = `/tmp/claude-1000/-workspace/fba1bfc0-301f-41fe-8500-89690af4d400/scratchpad/mut` (a copy made from cwd `/workspace/.claude/wt-routers`), finished 2026-09-29T08:27:23Z. Baseline exit 0 (6 ok). Test 1 fails on `rm -r skills/spike` and on a new router-less workflow; test 2 on `router: "none"` and on `mkdir skills/review-fix-loop`; test 3 on `name: spikey` and on a deleted description; test 4 on each of the handoff, installed-path and never-follow lines; test 5 on removing "(router)" from the H1; test 6 on 30 appended body lines; all exit 1 (paraphrased — no quote available because results span 12 log files; listed in `probe-commands.txt`).

**Evidence:** `test/skills/workflow-routers.bats:50-137`, `docs/reviews/execution-logs/fc-r3-routers-final-b/probe-commands.txt`, `docs/reviews/execution-logs/fc-r3-routers-final-b/m*.txt`, `docs/reviews/execution-logs/fc-r3-routers-final-b/baseline.txt`

---

## Claim 17: `router: "none — runs only inside pr-prep step 3, never on its own (see Relationship to other workflows)"`

**Location:** `workflows/review-fix-loop.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reason against the workflow's own section; does not establish that no other document invokes the loop standalone.

`workflows/review-fix-loop.md:208` "## Relationship to other workflows"; `:212` "The loop is embedded in pr-prep as a required step (Phase 1, step 3). It should not be run as a standalone workflow".

**Evidence:** `workflows/review-fix-loop.md:3`, `workflows/review-fix-loop.md:208-212`

---

## Claim 18: commit 881762a — "the router test now carries an exemption list with reasons and fails if an exempt workflow gains a router or disappears"; "routers now say "keep this file a pointer and add nothing the workflow does not say""; "README: 33 skills, routers listed"

**Location:** `881762a` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claims as of 881762a; both the exemption list and the "add nothing" wording were later replaced by 028105b (frontmatter opt-out; "Do not restate the workflow here; keep this file a pointer."), so they describe history, not HEAD; does not re-verify the "delivery path is chosen before Step 0" pr-prep wording, which 028105b removed.

`git show 881762a:test/skills/workflow-routers.bats` has `declare -gA EXEMPT=(` (`:23`) and `@test "exempt workflows exist and have no router"` (`:55`) with `"$name: no such workflow (stale exemption)"`. `git show 881762a:skills/pr-prep/SKILL.md` "keep this file a pointer and add nothing the workflow does not say".

**Evidence:** `881762a:test/skills/workflow-routers.bats:23-60`, `881762a:skills/pr-prep/SKILL.md`, `README.md:182`

---

## Claim 19: commit 028105b — "every router description now carries a "Not for X (use Y)" clause, and both it and the triggers sit inside the first 250 characters"

**Location:** `028105b` (commit message)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the same measurement as Claim 3c (the descriptions are unchanged between 028105b and 33fdfd3 per `git diff 028105b 33fdfd3 -- skills/` touching none of them — paraphrased — no quote available because it is an empty diff); does not establish live-listing truncation behavior.

Same imprecisions as Claim 3c: pr-prep carries "Use code-review alone for a review with no landing." instead of a "Not for" clause, two "Not for" clauses name no Y, and the trigger lists of 5 routers run past char 250 although every `Triggers:` label starts by char 211.

**Evidence:** `skills/*/SKILL.md:3-4`

---

## Claim 20: commit 028105b — "Test no longer requires `when:` … routers drop it"; "Colliding triggers removed (api #5)"; "Verified: workflow-routers (6), divergent-design-router, frontmatter-fields and agents-gemini-sync suites pass; mutations (drop the opt-out, drop the installed path) fail the intended tests."

**Location:** `028105b` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suites and mutations re-run at 33fdfd3 (not at 028105b; the merge brought only main's files) and the absence of `when:` and of the four api #5 phrases; does not establish that no other trigger collides.

`grep -c '^when:'` is 0 in all 8 routers, and the test's frontmatter check has only `name:` and `description:` (`test/skills/workflow-routers.bats:82-83`). api #5 named "here's the feedback", "where does X live", "does X support Y", "wrap this up" (`docs/reviews/api-consistency-review-2026-09-29.md:117-121`); none occurs in any router description. Test count: 6 `@test` blocks. Suites run from cwd `/workspace/.claude/wt-routers` at 2026-09-29T08:28:16Z with `timeout 120 bats <file>`: divergent-design-router exit 0 (8 ok), frontmatter-fields exit 0 (1 ok), agents-gemini-sync exit 0 (3 ok); workflow-routers baseline exit 0 (6 ok); the two mutations correspond to m2a/m4b in Claim 16.

**Evidence:** `test/skills/workflow-routers.bats:76-89`, `docs/reviews/api-consistency-review-2026-09-29.md:109-125`, `docs/reviews/execution-logs/fc-r3-routers-final-b/head-divergent-design-router.txt`, `docs/reviews/execution-logs/fc-r3-routers-final-b/head-frontmatter-fields.txt`, `docs/reviews/execution-logs/fc-r3-routers-final-b/head-agents-gemini-sync.txt`, `docs/reviews/execution-logs/fc-r3-routers-final-b/baseline.txt`

---

## Claim 21: commit 33fdfd3 — "this branch's copies are kept under -routers-<sha> names … Decision log: rows 65 and 66 both kept."

**Location:** `33fdfd3` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the renamed review files and the two log rows; does not establish the "Override log: union of both branches' rows" claim row by row.

`docs/decisions/log.md:88-89` hold rows `| 65 | 2026-09-28 |` and `| 66 | 2026-09-29 |`. The branch diff lists `docs/reviews/performance-review-2026-09-29-routers-de96617.md`, `security-review-2026-09-29-routers-de96617.md` and `code-fact-check-report-r{1,2,3}-routers-3a63c56.md` (paraphrased — no quote available because it is a file listing).

**Evidence:** `docs/decisions/log.md:88-89`, `docs/reviews/`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 3c** (`docs/decisions/log.md:89`): pr-prep has no "not for" clause (it says "Use code-review alone…"), codebase-onboarding and branch-strategy name no Y, and 5 routers' trigger lists run past char 250; tighten to "a precedence sentence and the start of its trigger list".
- **Claim 19** (`028105b` message): same imprecision in the commit message; history only, no fix needed unless the row is reworded.

### Unverifiable
(none)

## Goal-Alignment Note
- **Answered:** every brief item: 9 routers' statements against their workflows and siblings; 250-char measurement for all 8 new descriptions (all "Not for"/precedence sentences end and all `Triggers:` labels start before char 250); header/comments of the bats file and 11 executed mutations covering all 6 tests; review-fix-loop `router:` reason; global paragraph including first-match rows; README count; row 66 in full; messages of 881762a and 028105b (and the merge).
- **Out of scope:** trigger-phrase quality and overlap (a review concern); live skill-listing truncation behavior (needs a fresh session); override-log union in the merge commit, row by row.
- **Escalate:** none blocking. The two Mostly-accurate verdicts are wording precision in row 66 and a commit message; no router states anything its workflow contradicts.
