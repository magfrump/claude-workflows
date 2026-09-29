Commit: 33fdfd3

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-routers, branch feat/workflow-router-skills)
**Scope:** `git diff main...HEAD -- . ':(exclude)docs/reviews'` (README.md, docs/decisions/log.md row 66, global-instructions/CLAUDE.md, 9 router SKILL.md files, test/skills/workflow-routers.bats, workflows/review-fix-loop.md) plus commit messages `git log main..HEAD` (replicate r2 of 3, final confirming pass)
**Checked:** 2026-09-29
**Total claims checked:** 36
**Summary:** 31 verified, 4 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). No claim in scope matches a logged pattern; the nearest class ("a specific measured value quoted from an artifact set that does not contain it") was checked against every number in scope (33 skills, 45 lines, 70–610, 1/~128, 250 chars) and none recurs. Two 3a63c56 commit-message findings are settled `Accepted-immutable` rows (`docs/reviews/override-log.md:157-158`) and are not re-verdicted here.

Execution provenance (all runs cwd `/workspace/.claude/wt-routers`, 2026-09-29, UTC):
- `timeout 20 python3 <scratchpad>/measure.py.txt <9 skill names>` → exit 0, 08:26 UTC; script `docs/reviews/execution-logs/fc-r2-routers-final-measure.py.txt`, output `docs/reviews/execution-logs/fc-r2-routers-final-desc-lengths.txt`. It joins each folded `description: >` block with single spaces (YAML folded-scalar semantics) and reports character offsets.
- Mutation runs: each mutation applied to a scratch copy of `skills/`, `workflows/`, `test/skills/` (scratch dir removed afterwards), then `timeout 60 bats test/skills/workflow-routers.bats` in that copy; per-mutation exit codes in `docs/reviews/execution-logs/fc-r2-routers-final-mutations.txt` (finished 08:27:36 UTC, M8 appended after).
- Suites at HEAD: `timeout 120 bats <suite>` for workflow-routers, divergent-design-router, agents-gemini-sync, frontmatter-fields → all exit 0, 08:28:21 UTC; output `docs/reviews/execution-logs/fc-r2-routers-final-suites.txt`.

---

## Claim 1: "`skills/` holds 33 Claude Code skills"

**Location:** `README.md:182`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count of directories under `skills/` at 33fdfd3; does not establish that every directory holds a loadable SKILL.md beyond the 9 routers checked here.

`ls skills | wc -l` prints 33 (paraphrased — no quote available because the claim is about directory layout, not a snippet): main's 25 (the count main's README states, `divergent-design` among them) plus the 8 new routers, `branch-strategy`, `codebase-onboarding`, `parallel-worktrees`, `pr-prep`, `research-plan-implement`, `spike`, `task-decomposition`, `user-testing-workflow`.

**Evidence:** `README.md:182`, `skills/`

---

## Claim 2: "a router skill for each workflow except `review-fix-loop` (`divergent-design`, `research-plan-implement`, `pr-prep`, `spike`, …), each of which hands off to its `workflows/` file"

**Location:** `README.md:182`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the existence of `skills/<name>/SKILL.md` for the 9 non-opted-out workflows and the handoff line in each body; does not establish that the Skill tool actually surfaces these skills in a live session.

`workflows/` holds 10 files (paraphrased — no quote available because the claim is about directory layout); every one except `review-fix-loop.md` has a same-named skill directory. Test 1 and test 4 of `test/skills/workflow-routers.bats` pass at HEAD (`ok 1 every workflow without router: none has a router skill of the same name`, `ok 4 each router's body hands off to the installed copy of its own workflow`), and each body carries e.g. `Read and follow **\`workflows/spike.md\`** end to end` (`skills/spike/SKILL.md:19`).

**Evidence:** `test/skills/workflow-routers.bats:50-59`, `test/skills/workflow-routers.bats:91-110`, `skills/spike/SKILL.md:19`, `docs/reviews/execution-logs/fc-r2-routers-final-suites.txt`

---

## Claim 3: "Every workflow except `review-fix-loop` ships a router skill of the same name (`skills/<name>/SKILL.md`), a stub modeled on `skills/divergent-design/` that ... hands off with "Read and follow **`workflows/<name>.md`**""

**Location:** `docs/decisions/log.md:89`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers presence of the 9 routers and the exact handoff string in each body; does not establish that the routers are "modeled on" DD beyond sharing its H1 `(router)` form, "Exists so..." opening and "Hand off to the workflow" section.

All 9 bodies contain the handoff string (test 4 passes; mutation M4a, which rewrote spike's line to `Read **\`workflows/spike.md\`**`, makes test 4 fail with exit 1). Each router shares DD's shape: `# Spike (router)` (`skills/spike/SKILL.md:9`), `## Hand off to the workflow` (`skills/spike/SKILL.md:17`), matching `skills/divergent-design/SKILL.md:14,37`.

**Evidence:** `skills/*/SKILL.md:9-22`, `skills/divergent-design/SKILL.md:14-45`, `docs/reviews/execution-logs/fc-r2-routers-final-mutations.txt`

---

## Claim 4: "`review-fix-loop` opts out with `router: "none — <reason>"` in its own frontmatter, because it runs only inside pr-prep step 3 (its own "should not be run as a standalone workflow")"

**Location:** `docs/decisions/log.md:89`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the frontmatter line and the quoted workflow sentence; does not establish that no other workflow invokes the loop directly (parallel-worktrees reaches it only via pr-prep, per its step 4).

```
# workflows/review-fix-loop.md:3
router: "none — runs only inside pr-prep step 3, never on its own (see Relationship to other workflows)"
# workflows/review-fix-loop.md:212
The loop is embedded in pr-prep as a required step (Phase 1, step 3). It should not be run as a standalone workflow — use pr-prep, ...
```

**Evidence:** `workflows/review-fix-loop.md:3`, `workflows/review-fix-loop.md:208-212`

---

## Claim 5: "Each router's description puts its "not for X (use Y)" precedence clause and triggers inside the first 250 characters"

**Location:** `docs/decisions/log.md:89`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the character offsets of the precedence clause and the `Triggers:` list in all 9 router descriptions (folded-scalar join); does not establish Claude Code's actual listing cut-off (taken from Q-080's "~250").

Measured (`fc-r2-routers-final-desc-lengths.txt`): every precedence clause ends by char 210 and every `Triggers:` label starts by char 224 (RPI 211, pr-prep 153, spike 177, codebase-onboarding 166, task-decomposition 176, parallel-worktrees 189, branch-strategy 168, user-testing 178, divergent-design 224). But the trigger lists themselves are not all inside 250: descriptions run 249–270 chars (DD 389), and the text past char 250 is `", "fix this bug".` (RPI), `after months".` (codebase-onboarding), `oss-cutting change".` (task-decomposition), `le branches".` (branch-strategy), `pt".` (spike), `".` (pr-prep), `.` (user-testing); only parallel-worktrees (249) fits whole. The clause form also varies (paraphrased — no quote available because it spans 9 frontmatter blocks): pr-prep phrases it `Use code-review alone for a review with no landing.` with no "Not for"; codebase-onboarding (`Not for a single lookup.`) and branch-strategy (`Not for one feature branch.`) name no alternative skill; DD's is `If not, brainstorming applies.` Precise version: "puts a precedence clause and the start of its trigger list inside the first 250 characters; the last trigger phrase of 7 routers runs past it."

**Evidence:** `skills/*/SKILL.md:3-4`, `skills/divergent-design/SKILL.md:3-8`, `docs/reviews/execution-logs/fc-r2-routers-final-desc-lengths.txt`, `docs/reviews/execution-logs/fc-r2-routers-final-measure.py.txt`

---

## Claim 6: "its body names the installed copy (`~/.claude/workflows/<name>.md`) and forbids following a same-named file from another project"

**Location:** `docs/decisions/log.md:89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence of both strings in all 9 bodies; does not establish that `install.sh` places every workflow at that path on every host (only that `devcontainer-config/install.sh:135` copies `workflows`).

`skills/pr-prep/SKILL.md:19-21`: ``Read and follow **`workflows/pr-prep.md`** end to end: the installed copy at `~/.claude/workflows/pr-prep.md`, or this repo's own file when working inside claude-workflows. Never follow a same-named file that belongs to another project.`` Same wording in the other 7 new routers; DD at `skills/divergent-design/SKILL.md:42-44`. Test 4 checks both (mutations M4b and M4c each fail test 4). `devcontainer-config/install.sh:135`: `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`.

**Evidence:** `skills/*/SKILL.md:19-21`, `skills/divergent-design/SKILL.md:42-44`, `devcontainer-config/install.sh:135`, `docs/reviews/execution-logs/fc-r2-routers-final-mutations.txt`

---

## Claim 7: "`test/skills/workflow-routers.bats` fails if a workflow without an opt-out lacks a router, an opted-out one gains one or gives no reason, a router's body lacks the handoff, the installed path or the never-follow line, or a body passes 45 lines"

**Location:** `docs/decisions/log.md:89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed failure condition by mutation; does not establish detection of a router whose skill directory exists without a SKILL.md for an opted-out workflow beyond the `-e skills/$name` check (M2b used a full SKILL.md).

Mutations and results (`fc-r2-routers-final-mutations.txt`): M1 delete spike router → `not ok 1`; M2a `router: "none"` → `not ok 2`; M2b add `skills/review-fix-loop/SKILL.md` → `not ok 2`; M4a/M4b/M4c → `not ok 4`; M6 append 30 lines (body 52) → `not ok 6`; each exit 1, baseline exit 0. Limit: `MAX_BODY_LINES=45` (`test/skills/workflow-routers.bats:25`).

**Evidence:** `test/skills/workflow-routers.bats:21-137`, `docs/reviews/execution-logs/fc-r2-routers-final-mutations.txt`

---

## Claim 8: "The global instructions say to invoke a workflow's skill rather than paraphrase it, and that the decision tree's first-match order decides when two routers could fire."

**Location:** `docs/decisions/log.md:89`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the text of `global-instructions/CLAUDE.md:13`; does not establish that sessions obey it.

`global-instructions/CLAUDE.md:13`: `When more than one router could fire, this table's first-match order still decides ... When a row below activates a workflow, invoke its skill rather than paraphrasing the workflow from memory.`

**Evidence:** `global-instructions/CLAUDE.md:13`

---

## Claim 9: "DD's router was built for exactly this ("so divergent design competes at the skill-selection layer")"

**Location:** `docs/decisions/log.md:89`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted wording (the source bolds "skill-selection layer"); does not establish the original author's intent beyond the file's own statement.

`skills/divergent-design/SKILL.md:16`: `Exists so divergent design competes at the **skill-selection layer**, where open-ended`. The same quote appears in the test header (`test/skills/workflow-routers.bats:10`).

**Evidence:** `skills/divergent-design/SKILL.md:16-18`, `test/skills/workflow-routers.bats:9-10`

---

## Claim 10: "pr-prep's advisory Step 0 wrote 1 failure pattern across ~128 fix commits as of Q-074"

**Location:** `docs/decisions/log.md:89`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the Q-074 entry; does not re-derive the 128 count from git history.

`docs/working/questions.md:70`: `` `docs/thoughts/failure-patterns.md` has gained 1 entry across about 128 `fix` commits. The writer is still pr-prep Step 0, a workflow step that is advisory only. ``

**Evidence:** `docs/working/questions.md:67-72`

---

## Claim 11: "Hook-based usage counts are not cited: they under-count silently (Q-017, triage 2026-09-17 §2.2 correction)."

**Location:** `docs/decisions/log.md:89`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and content of both cited sources; does not establish the under-count mechanism itself (the user rated it low-confidence).

`docs/working/triage-2026-09-17-backlog.md:170-171`: `> **Correction, 2026-09-17 (same day).** The user reports that hook measurement > has a history of silent under-counting`. `docs/working/questions-archive.md` Q-017: `Answered 2026-09-17: the measurement is not trustworthy, so the finding is withdrawn as evidence.`

**Evidence:** `docs/working/triage-2026-09-17-backlog.md:170-183`, `docs/working/questions-archive.md:218-232`

---

## Claim 12: "Each `workflows/<name>.md` ships a router skill of the same name ... The exception is `review-fix-loop` (frontmatter `router: none`), which runs only inside `pr-prep`."

**Location:** `global-instructions/CLAUDE.md:13`
**Type:** Architectural / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers router coverage and the opt-out's existence; does not establish anything about the value's reason text.

Coverage and the pr-prep-only claim hold (Claims 3–4). The frontmatter value is not literally `router: none`: `workflows/review-fix-loop.md:3` reads `router: "none — runs only inside pr-prep step 3, never on its own ..."`, and the test requires the `— <reason>` form (`test/skills/workflow-routers.bats:66`: `'^router:[[:space:]]*"?none[[:space:]]+—[[:space:]]+[^[:space:]]'`), so copying `router: none` as written into another workflow would fail test 2. Precise version: `router: "none — <reason>"`.

**Evidence:** `global-instructions/CLAUDE.md:13`, `workflows/review-fix-loop.md:3`, `test/skills/workflow-routers.bats:61-74`

---

## Claim 13: "this table's first-match order still decides (a batch is row 2 before any single-task router; a 3+-option choice is row 3 before RPI)"

**Location:** `global-instructions/CLAUDE.md:13`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row numbers in the table below the paragraph; does not establish that row 2 precedes rows 1 (onboarding) — the claim does not say so.

`global-instructions/CLAUDE.md:22`: `| 2 | **Message bundles 2+ independent tasks** ...`; `:23`: `| 3 | **Task involves a design choice** with 3+ viable approaches ...`; `:26`: `| 6 | **Non-trivial feature or bug fix** ... | \`research-plan-implement.md\``; `:19`: `Evaluate triggers top-to-bottom. Take the **first match**`.

**Evidence:** `global-instructions/CLAUDE.md:17-31`

---

## Claim 14: branch-strategy router: "dev integration branch, rebuilding it from open PRs, stale-branch triage" / "Replacing a shared branch always needs explicit user approval, in any operating mode."

**Location:** `skills/branch-strategy/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named sections and the approval rule; does not establish that "a single feature branch needs none of this" (the workflow's daily flow does cover one branch inside the multi-branch model).

`workflows/branch-strategy.md` has `## Integration branch refresh` and `## Stale-branch triage (advisory)` (paraphrased — no quote available because the claim is about section structure); `workflows/branch-strategy.md:187`: `**gated operation requiring explicit human approval** (see Operating Modes in CLAUDE.md), regardless` `of away/active mode`.

**Evidence:** `skills/branch-strategy/SKILL.md:4,15`, `workflows/branch-strategy.md:185-190`

---

## Claim 15: codebase-onboarding router: "producing one reusable orientation doc" / "Not for projects you started from scratch"

**Location:** `skills/codebase-onboarding/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the output artifact and the from-scratch exclusion; does not establish the "single lookup" exclusion, which the workflow does not state (it is a scoping judgment, not a factual claim).

`workflows/codebase-onboarding.md:18`: `**Not a trigger:** from-scratch projects you started yourself`; the workflow produces `docs/working/onboarding-{project}.md` treated as "a living reference" (paraphrased — no quote available because the statement is in the Working documents section, lines 29-33, split over two sentences).

**Evidence:** `skills/codebase-onboarding/SKILL.md:4,15`, `workflows/codebase-onboarding.md:8-33`

---

## Claim 16: "Read the installed copy at `~/.claude/workflows/divergent-design.md`, or this repo's own file when working inside claude-workflows."

**Location:** `skills/divergent-design/SKILL.md:42-43`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the installer copies `workflows` into the Claude home; does not establish the destination on bare hosts other than via `CLAUDE_HOME_SRC`.

`devcontainer-config/install.sh:135`: `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`.

**Evidence:** `skills/divergent-design/SKILL.md:39-45`, `devcontainer-config/install.sh:115-135`

---

## Claim 17: parallel-worktrees router: "Ask: "do these share files or an order?" No → this skill. Yes → one task, so use `research-plan-implement` or `task-decomposition`. Each item that lands still goes through `pr-prep`."

**Location:** `skills/parallel-worktrees/SKILL.md:15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the workflow's routing test and per-item review; does not establish the description's step list beyond "split, route each, build in parallel worktrees", which matches steps 1–3.

`workflows/parallel-worktrees.md:18`: `Ask: "do these share files or an order?" Yes → RPI (row 6) or task-decomposition (row 7). No → this workflow.` Step 4: `Each one runs its own \`pr-prep\``.

**Evidence:** `skills/parallel-worktrees/SKILL.md:4,15`, `workflows/parallel-worktrees.md:18`, `workflows/parallel-worktrees.md:39-45`

---

## Claim 18: pr-prep router: "review-fix loop, cleanup, then local merge or PR" / "Merging into `main`, pushing, and opening a PR follow the Operating Modes approval rules in the global instructions."

**Location:** `skills/pr-prep/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the phase order and the approval pointer; does not establish the omitted gate checks (step 1) and description step (6), which the description does not claim to list exhaustively.

`workflows/pr-prep.md:26`: `Merging into \`main\` follows the Operating Modes in the global instructions: in /active mode, ask first.`; global instructions /active list requires approval before `Pushing to remote` and `Creating or updating pull requests` (paraphrased — no quote available because the list is in the installed global file's Operating Modes section, multiple bullets). Step 3 is the review-fix loop, step 4 cleans up commit history (paraphrased — no quote available because the claim is about section order).

**Evidence:** `skills/pr-prep/SKILL.md:4,15`, `workflows/pr-prep.md:14-28`, `global-instructions/CLAUDE.md` (Operating Modes /active)

---

## Claim 19: "The review-fix loop inside it has no router of its own: it runs only inside this workflow."

**Location:** `skills/pr-prep/SKILL.md:15`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absence of `skills/review-fix-loop/` and the workflow's own statement; does not establish that no instruction text elsewhere tells agents to run the loop standalone.

`skills/review-fix-loop` does not exist (paraphrased — no quote available because the claim covers absence; `ls skills` has no such entry). `workflows/review-fix-loop.md:212`: `It should not be run as a standalone workflow — use pr-prep`.

**Evidence:** `skills/`, `workflows/review-fix-loop.md:212`

---

## Claim 20: RPI router: "Not for trivial edits (a typo, a config value, a one-line fix whose cause is known) ... not for a choice among 3+ approaches (`divergent-design`, which feeds its decision back here). Its hard gate is plan approval before implementation."

**Location:** `skills/research-plan-implement/SKILL.md:15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skip list, the DD feedback, and the gate; does not establish the "several unrelated tasks" exclusion beyond the global table's row 2.

`workflows/research-plan-implement.md:518`: `- **Trivial changes** (typo fixes, config tweaks, single-line bug fixes): Skip entirely`; `:362`: `This is the hard gate. ... **implementation does not begin until the user has reviewed the plan**`; DD pivot: `DD's decision feeds back into your plan` (`:14`).

**Evidence:** `skills/research-plan-implement/SKILL.md:4,15`, `workflows/research-plan-implement.md:14`, `workflows/research-plan-implement.md:362`, `workflows/research-plan-implement.md:518`

---

## Claim 21: spike router: "timeboxed, throwaway branch, recorded verdict" / "cannot be answered by reading the code"

**Location:** `skills/spike/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers steps 3–5 of the workflow and its RPI pivot wording; does not establish that recording is mandatory (the workflow marks step 5 "recommended").

`workflows/spike.md:17`: `question that can't be answered by reading code`; step headings `### 3. Set a timebox`, `### 4. Work in a throwaway space`, `### 5. Record the findings` (paraphrased — no quote available because the claim is about section structure).

**Evidence:** `skills/spike/SKILL.md:4,15`, `workflows/spike.md:17`, `workflows/spike.md` §3–5

---

## Claim 22: task-decomposition router: "parallel research, then sequential build" / "explicit interface contracts"

**Location:** `skills/task-decomposition/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the workflow's research/implementation split and its contracts subsection; does not establish that contracts are always written (they are required only for ≥2 sub-agents or replaced by an escape line).

`workflows/task-decomposition.md:14`: `Implementation still happens sequentially in the main agent — sub-agents research and analyze`; step 1 has `#### Capture interface contracts before dispatch` (paraphrased — no quote available because the claim is about section structure).

**Evidence:** `skills/task-decomposition/SKILL.md:4,11,15`, `workflows/task-decomposition.md:14`, `workflows/task-decomposition.md` §1

---

## Claim 23: user-testing router: "scoping, moderator script, pilot, analysis, findings" / "HCI-grounded protocol" / "For reviewing a UI's layout without users, use `ui-visual-review`."

**Location:** `skills/user-testing-workflow/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the phase list and the sibling skill's existence and remit; does not establish trigger overlap with other skills.

The workflow's phases are `Phase 0: Scoping`, `Phase 1: Session Design` (moderator script, pilot), `Phase 3: Analysis`, `Phase 4: Reporting` (findings) (paraphrased — no quote available because the claim is about section structure); its intro says `Grounded in HCI literature`. `skills/ui-visual-review/` exists; its description is "Review and fix visual/layout issues in any rendered UI" (paraphrased — no quote available because it comes from the session's skill listing).

**Evidence:** `skills/user-testing-workflow/SKILL.md:4,15`, `workflows/user-testing-workflow.md:1-3`, `skills/ui-visual-review/SKILL.md`

---

## Claim 24: "Validates that every workflow has a router skill unless its own frontmatter opts out, and that each router keeps the router contract: it hands off to the installed copy of its workflow and stays a stub."

**Location:** `test/skills/workflow-routers.bats:3-5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the header's summary against tests 1, 4 and 6; does not establish the name/title checks (tests 3, 5), which the header does not mention but which exist.

Tests 1, 4, 6 implement the three named properties and each fails under its mutation (Claim 27).

**Evidence:** `test/skills/workflow-routers.bats:3-5`, `test/skills/workflow-routers.bats:50-137`, `docs/reviews/execution-logs/fc-r2-routers-final-mutations.txt`

---

## Claim 25: "divergent-design's own, stricter contract lives in divergent-design-router.bats."

**Location:** `test/skills/workflow-routers.bats:13`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers comparison of the two suites' assertions on DD; does not establish which suite a maintainer should prefer.

The file exists and adds checks the generic suite lacks: `^(trigger|when):` (`test/skills/divergent-design-router.bats:51`), the `3\+ viable options`/`tradeoff axis` trigger test (`:79-80`), the brainstorming boundary (`:88-89`). It is not stricter on every axis: its stub limit is `[ "$skill_lines" -lt 120 ]` on the whole file (`:101`) vs the generic suite's 45 body lines (`test/skills/workflow-routers.bats:25`), and its handoff regex `'Read and follow[^.]*workflows/divergent-design\.md'` (`:66`) is looser than the generic exact string plus installed path. Precise version: "additional DD-specific checks".

**Evidence:** `test/skills/divergent-design-router.bats:45-110`, `test/skills/workflow-routers.bats:13,25,91-110`

---

## Claim 26: "the workflows it points at run about 70-610 lines"

**Location:** `test/skills/workflow-routers.bats:23-24`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the 9 routed workflows at 33fdfd3; does not establish future sizes.

`wc -l workflows/*.md` (paraphrased — no quote available because the claim is a line count): shortest parallel-worktrees 72, longest divergent-design 608 (review-fix-loop 222 is excluded and within range anyway).

**Evidence:** `workflows/*.md`

---

## Claim 27: each of the six tests fails when its own contract breaks (test names at `:50`, `:61`, `:76`, `:91`, `:112`, `:125`)

**Location:** `test/skills/workflow-routers.bats:50-137`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one or more targeted mutations per test, each failing only its own test; does not establish detection of every conceivable contract break (e.g. a description with no text after `description:`).

From `fc-r2-routers-final-mutations.txt`: test 1 ← M1 (delete spike), M8 (drop the opt-out line: `workflows with no ... router ...: review-fix-loop`); test 2 ← M2a, M2b, M7 (`router: "nonexistent — x"`: prefix-matched as opted out, then rejected for lacking the `none —` form); test 3 ← M3a (`name: spikey`), M3b (no `description:`); test 4 ← M4a/b/c; test 5 ← M5 (H1 without `(router)`); test 6 ← M6. In every run the other five tests stayed `ok`; baseline all six `ok`.

**Evidence:** `test/skills/workflow-routers.bats:28-137`, `docs/reviews/execution-logs/fc-r2-routers-final-mutations.txt`

---

## Claim 28: `router: "none — runs only inside pr-prep step 3, never on its own (see Relationship to other workflows)"`

**Location:** `workflows/review-fix-loop.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the workflow's own section; does not establish anything about pr-prep's step numbering beyond step 3 being the loop.

`workflows/review-fix-loop.md:212`: `The loop is embedded in pr-prep as a required step (Phase 1, step 3). It should not be run as a standalone workflow`, under `## Relationship to other workflows` (`:208`); pr-prep has `#### 3. Review-fix loop`.

**Evidence:** `workflows/review-fix-loop.md:3,208-212`, `workflows/pr-prep.md` §3

---

## Claim 29: Commit 881762a: "the router test now carries an exemption list with reasons and fails if an exempt workflow gains a router or disappears"; "routers now say 'keep this file a pointer and add nothing the workflow does not say'"; pr-prep router delivery-path/control-rules lines; "70-600 -> about 70-610"; "README: 33 skills"

**Location:** `git show 881762a` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message against the tree at 881762a; does not establish the state at HEAD, where 028105b replaced the exemption list and the pointer wording (commit messages describe their own commit).

At 881762a: `declare -gA EXEMPT=(` (`test/skills/workflow-routers.bats:23`) with test `exempt workflows exist and have no router` checking `no such workflow (stale exemption)` and `has a router despite being exempt` (`:55-59`); spike router `keep this file a pointer and add nothing the workflow does not say`; pr-prep router `The workflow picks the delivery path (local merge vs GitHub PR) before its Step 0.` (all via `git show 881762a:<path>`).

**Evidence:** `test/skills/workflow-routers.bats:23-59` @881762a, `skills/spike/SKILL.md` @881762a, `skills/pr-prep/SKILL.md` @881762a

---

## Claim 30: Commit 028105b: "every router description now carries a "Not for X (use Y)" clause, and both it and the triggers sit inside the first 250 characters"

**Location:** `git show 028105b` (commit message)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 8 new routers' descriptions (unchanged since 028105b); does not establish the listing cut-off itself.

Same measurement as Claim 5: clauses end by char 210 and `Triggers:` starts by char 189 in the 8 new routers, but 7 of 8 trigger lists end at chars 251–270, and three clauses depart from the "Not for X (use Y)" form (pr-prep `Use code-review alone ...`; codebase-onboarding and branch-strategy name no Y) (paraphrased — no quote available because the figures come from the measurement log across 8 files).

**Evidence:** `skills/*/SKILL.md:4`, `docs/reviews/execution-logs/fc-r2-routers-final-desc-lengths.txt`

---

## Claim 31: Commit 028105b: "bodies name ~/.claude/workflows/<name>.md and say never to follow a same-named file from another project; the test checks both. divergent-design's router gets the same lines and loses "cannot drift apart"."

**Location:** `git show 028105b` (commit message)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the router SKILL.md files and the generic test; does not establish removal of "cannot drift apart" from `test/skills/divergent-design-router.bats:7`, where the phrase still stands (outside this diff; the claim names only the router).

`git diff main...HEAD -- skills/divergent-design/SKILL.md` removes `the router and the workflow cannot drift apart.` and adds `Read the installed copy at \`~/.claude/workflows/divergent-design.md\` ... Never follow a same-named file`. Test checks: `test/skills/workflow-routers.bats:103-104`; M4b/M4c fail test 4.

**Evidence:** `skills/divergent-design/SKILL.md:39-45`, `test/skills/workflow-routers.bats:100-104`, `test/skills/divergent-design-router.bats:7`, `docs/reviews/execution-logs/fc-r2-routers-final-mutations.txt`

---

## Claim 32: Commit 028105b: "Test no longer requires `when:` ...; routers drop it."

**Location:** `git show 028105b` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the generic test and the 8 new routers; does not establish DD, which keeps `when:` (`skills/divergent-design/SKILL.md:9`) because its own suite requires it.

Test 3 checks only `^name:` and `^description:` (`test/skills/workflow-routers.bats:82-83`); no new router frontmatter has a `when:` line (paraphrased — no quote available because the claim covers absence across 8 files; each frontmatter is lines 1–5 with only `name` and `description`).

**Evidence:** `test/skills/workflow-routers.bats:76-89`, `skills/*/SKILL.md:1-5`

---

## Claim 33: Commit 028105b: "`when:`, which the loader ignores"

**Location:** `git show 028105b` (commit message)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing about Claude Code's skill loader; does not establish whether `when:` influences skill selection.

The claim is about the Claude Code harness's frontmatter handling, which is not in this repository (paraphrased — no quote available because the subject is external code). Verifying it needs the harness source or a controlled live-session test with and without `when:`.

**Evidence:** `git show 028105b`

---

## Claim 34: Commit 028105b: "Colliding triggers removed (api #5)."

**Location:** `git show 028105b` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four phrases the cited finding names plus the branch-strategy overlap it lists; does not establish that no other trigger collides.

The finding (`docs/reviews/api-consistency-review-2026-09-29.md:196` @028105b) names `("here's the feedback", "where does X live", "does X support Y", "wrap this up")`; `grep -rni` for those and `parallelize 5` across `skills/*/SKILL.md` returns no match (paraphrased — no quote available because the claim covers absence).

**Evidence:** `docs/reviews/api-consistency-review-2026-09-29.md:87,109-123,196` @028105b, `skills/*/SKILL.md`

---

## Claim 35: Commit 028105b: "Verified: workflow-routers (6), divergent-design-router, frontmatter-fields and agents-gemini-sync suites pass; mutations (drop the opt-out, drop the installed path) fail the intended tests."

**Location:** `git show 028105b` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four suites at HEAD 33fdfd3 (routers unchanged since 028105b) and the two named mutations; does not establish a run at 028105b itself.

Suites: workflow-routers `1..6` exit 0, divergent-design-router `1..8` exit 0, agents-gemini-sync `1..3` exit 0, frontmatter-fields `1..1` exit 0. Mutations: drop the opt-out (M8) → `not ok 1`; drop the installed path (M4b) → `not ok 4`.

**Evidence:** `docs/reviews/execution-logs/fc-r2-routers-final-suites.txt`, `docs/reviews/execution-logs/fc-r2-routers-final-mutations.txt`

---

## Claim 36: Merge 33fdfd3: "Review artifacts that share canonical names with fix/agents-md-no-imports keep main's copy; this branch's copies are kept under -routers-<sha> names. Override log: union of both branches' rows. Decision log: rows 65 and 66 both kept."

**Location:** `git show 33fdfd3` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the renamed fact-check/performance/security files, the override-log line sets and log rows 65–66; does not establish, file by file, that every colliding artifact was handled (only the ones visible in the merge's name-status diff).

`git diff --name-status 33fdfd3^1 33fdfd3 -- docs/reviews` adds `code-fact-check-report-r{1,2,3}-routers-3a63c56.md` and modifies the canonical `code-fact-check-report-r{1,2,3}.md` toward main's content; `comm -13` of each parent's `override-log.md` lines against the merge's gives 0 lines missing from either side (paraphrased — no quote available because these are git command results). `docs/decisions/log.md:88-89` hold rows `| 65 |` and `| 66 |`.

**Evidence:** `docs/decisions/log.md:88-89`, `docs/reviews/override-log.md`, `git show 33fdfd3`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 5** (`docs/decisions/log.md:89`): the precedence clause and the `Triggers:` label sit inside 250 chars, but 7 of 9 trigger lists run to chars 251–270, and pr-prep, codebase-onboarding, branch-strategy (and DD) do not use the "not for X (use Y)" form; say "a precedence clause and the start of its triggers".
- **Claim 12** (`global-instructions/CLAUDE.md:13`): the opt-out is `router: "none — <reason>"`, not `router: none`; the bare form fails test 2.
- **Claim 25** (`test/skills/workflow-routers.bats:13`): divergent-design-router.bats adds DD-specific checks but is looser on stub size (120 whole-file lines vs 45 body lines) and handoff wording; "additional" rather than "stricter".
- **Claim 30** (commit 028105b): same gap as Claim 5 for the 8 new routers (commit message, immutable).

### Unverifiable
- **Claim 33** (commit 028105b): "`when:`, which the loader ignores" needs the Claude Code harness source or a controlled live-session test.

---

**Goal-Alignment Note**
- **Answered:** All seven "claims that particularly need checking" were verdicted: every factual statement in the 8 routers and DD's edit against its workflow and sibling skills; description offsets measured by script; the six bats tests each shown to fail under their own mutation (10 mutations, scratch copies only); review-fix-loop's `router:` reason; the global paragraph's first-match examples; README count and router text; row 66 in full; commits 881762a, 028105b and the 33fdfd3 merge.
- **Out of scope:** 3a63c56's withdrawn-evidence and "cannot drift" statements (settled Accepted-immutable rows 157–158); `test/skills/divergent-design-router.bats:7` still says "cannot drift apart" but lies outside the diff (noted in Claim 31's scope). No tracked file edited besides this report; new execution logs under `docs/reviews/execution-logs/fc-r2-routers-final-*`. No health-check or full suite run; no processes left running.
- **Escalate:** None blocking. The one recurring imprecision (Claims 5/30) is whether "triggers inside the first 250 characters" means the label or the whole list; if the whole list, 7 descriptions are 1–20 chars over.
