Commit: 33fdfd3

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-routers`, branch `feat/workflow-router-skills`)
**Scope:** `git diff main...HEAD -- . ':(exclude)docs/reviews'` (14 files) plus the messages of `git log main..HEAD` (commits 881762a, 028105b in focus). Replicate r1 of 3, final confirming pass.
**Checked:** 2026-09-29
**Total claims checked:** 31
**Summary:** 28 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The relevant logged class is "a specific measured value quoted from an artifact set that does not contain it" (test counts in commit messages, e.g. the "All 85 tests" and "mode1-equiv 33" entries). Claims 6, 23, 26 and 30 carry counts of that kind; all were re-measured and match.

Execution logs (all under `docs/reviews/execution-logs/`, cwd `/workspace/.claude/wt-routers` unless noted):
- `fc-r1-routers-final-base.txt`: `timeout 120 bats test/skills/workflow-routers.bats`, exit 0, 2026-09-29T08:26:50Z.
- `fc-r1-routers-final-mutations.txt`: `timeout 300 bash <scratchpad>/mutate.txt` (script saved as `fc-r1-routers-final-mutate-script.txt`; it mutates scratch copies of `skills/`, `workflows/` and the test file only), exit 0, 2026-09-29T08:27:06Z.
- `fc-r1-routers-final-mutation-optout.txt`: same scratch-copy method, `router:` line deleted from review-fix-loop.md, exit 0, 2026-09-29T08:28:10Z.
- `fc-r1-routers-final-dd-router.txt`: `timeout 120 bats test/skills/divergent-design-router.bats`, exit 0, 2026-09-29T08:28:10Z.
- `fc-r1-routers-final-frontmatter-fields.txt`: `timeout 120 bats test/skills/frontmatter-fields.bats`, exit 0, 2026-09-29T08:28:17Z.
- `fc-r1-routers-final-desc-lengths.txt`: `timeout 30 python3 -` (joins each folded `description: >` block with single spaces and reports offsets), exit 0, 2026-09-29T08:28:35Z.

---

## Claim 1: "`skills/` holds 33 Claude Code skills ... and a router skill for each workflow except `review-fix-loop` (`divergent-design`, `research-plan-implement`, `pr-prep`, `spike`, …), each of which hands off to its `workflows/` file."

**Location:** `README.md:182`
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill count and the router/workflow correspondence at 33fdfd3; does not establish that install.sh installs every skill (not traced beyond `CLAUDE_HOME_SRC`).

`ls skills | wc -l` prints `33` (paraphrased — no quote available because the claim is about directory layout, not a snippet). `ls workflows` lists 10 files; the 9 other than `review-fix-loop.md` each have a same-named `skills/<name>/SKILL.md`, and there is no `skills/review-fix-loop` (paraphrased — no quote available because the claim is about directory layout). Each router body contains the handoff, e.g. `skills/spike/SKILL.md:19`: ``Read and follow **`workflows/spike.md`** end to end``.

**Evidence:** `README.md:182`, `skills/spike/SKILL.md:19`, `skills/divergent-design/SKILL.md:39`

---

## Claim 2: "Every workflow except `review-fix-loop` ships a router skill of the same name (`skills/<name>/SKILL.md`), a stub modeled on `skills/divergent-design/` that ... hands off with "Read and follow **`workflows/<name>.md`**""

**Location:** `docs/decisions/log.md:89`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers existence of all 9 routers and the handoff phrase in each body; does not establish "modeled on" beyond shared structure (same H1 `(router)` pattern, "Does not re-implement the workflow — routes into it" line, `## Hand off to the workflow` section).

Each of the 8 new routers has the literal handoff at line 19, e.g. `skills/pr-prep/SKILL.md:19`: ``Read and follow **`workflows/pr-prep.md`** end to end``; divergent-design has it at `skills/divergent-design/SKILL.md:39`. Test 4 of `workflow-routers.bats` passes over all of them (`ok 4 each router's body hands off to the installed copy of its own workflow`, base log).

**Evidence:** `skills/*/SKILL.md:19`, `skills/divergent-design/SKILL.md:39`, `docs/reviews/execution-logs/fc-r1-routers-final-base.txt`

---

## Claim 3: "`review-fix-loop` opts out with `router: "none — <reason>"` in its own frontmatter, because it runs only inside pr-prep step 3 (its own "should not be run as a standalone workflow")."

**Location:** `docs/decisions/log.md:89`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the frontmatter line and the quoted workflow sentence; does not establish that any loader other than the bats test reads `router:`.

`workflows/review-fix-loop.md:3`: `router: "none — runs only inside pr-prep step 3, never on its own (see Relationship to other workflows)"`. `workflows/review-fix-loop.md:212`: `The loop is embedded in pr-prep as a required step (Phase 1, step 3). It should not be run as a standalone workflow — use pr-prep`.

**Evidence:** `workflows/review-fix-loop.md:3`, `workflows/review-fix-loop.md:212`

---

## Claim 4: "Each router's description puts its "not for X (use Y)" precedence clause and triggers inside the first 250 characters"

**Location:** `docs/decisions/log.md:89`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 8 new routers' descriptions as the folded scalar joins them; does not establish how Claude Code's listing actually truncates (the 250 figure is taken as given) and does not cover divergent-design's unchanged description (no "not for" clause; `Triggers:` at 224).

Measured (desc-lengths log): the `Triggers:` label starts before 250 in every router (153–211), and the precedence clause precedes it in all 8. Two imprecisions: (a) the clause is not uniformly "not for X (use Y)": pr-prep has no "Not for" and instead says `Use code-review alone for a review with no landing.` (`skills/pr-prep/SKILL.md:4`), and two clauses name no Y: `Not for a single lookup.` (`skills/codebase-onboarding/SKILL.md:4`), `Not for one feature branch.` (`skills/branch-strategy/SKILL.md:4`); (b) 7 of 8 descriptions run past 250 (251–270 chars), so the tail of the trigger list is past the mark — e.g. research-plan-implement's text after 250 is `", "fix this bug".`, task-decomposition's is `oss-cutting change".` (desc-lengths log). Precise version: "puts a precedence clause and the start of its trigger list inside the first 250 characters".

**Evidence:** `skills/*/SKILL.md:4`, `docs/reviews/execution-logs/fc-r1-routers-final-desc-lengths.txt`

---

## Claim 5: "its body names the installed copy (`~/.claude/workflows/<name>.md`) and forbids following a same-named file from another project."

**Location:** `docs/decisions/log.md:89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the router text and that install.sh copies `workflows/` into `~/.claude`; does not establish agent compliance.

`skills/spike/SKILL.md:19-21`: ``the installed copy at `~/.claude/workflows/spike.md`, or this repo's own file when working inside claude-workflows. Never follow a same-named file that belongs to another project.`` — the same lines appear in all 8 routers and `skills/divergent-design/SKILL.md:42-44`. `devcontainer-config/install.sh:135`: `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)`, so the named path exists after install.

**Evidence:** `skills/*/SKILL.md:19-21`, `skills/divergent-design/SKILL.md:42-44`, `devcontainer-config/install.sh:135`

---

## Claim 6: "`test/skills/workflow-routers.bats` fails if a workflow without an opt-out lacks a router, an opted-out one gains one or gives no reason, a router's body lacks the handoff, the installed path or the never-follow line, or a body passes 45 lines."

**Location:** `docs/decisions/log.md:89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed failure condition by mutation of scratch copies; does not claim the list is exhaustive (the test also checks name/description and the `(router)` H1, which the row omits).

Base run: all 6 pass. Mutations: deleting `skills/spike` → `not ok 1`; `router: "none"` → `not ok 2`; adding `skills/review-fix-loop` → `not ok 2`; removing "Read and follow" / the `~/.claude/workflows/spike.md` path / the "Never follow a same-named file" phrase → `not ok 4` each; appending 40 lines → `not ok 6` (mutations log). `MAX_BODY_LINES=45` at `test/skills/workflow-routers.bats:25`.

**Evidence:** `test/skills/workflow-routers.bats:25`, `test/skills/workflow-routers.bats:50-137`, `docs/reviews/execution-logs/fc-r1-routers-final-base.txt`, `docs/reviews/execution-logs/fc-r1-routers-final-mutations.txt`

---

## Claim 7: "The global instructions say to invoke a workflow's skill rather than paraphrase it, and that the decision tree's first-match order decides when two routers could fire."

**Location:** `docs/decisions/log.md:89`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of both statements; accuracy of the paragraph itself is Claims 11–12.

`global-instructions/CLAUDE.md:13`: `When more than one router could fire, this table's first-match order still decides ... When a row below activates a workflow, invoke its skill rather than paraphrasing the workflow from memory.`

**Evidence:** `global-instructions/CLAUDE.md:13`

---

## Claim 8: "DD's router was built for exactly this ("so divergent design competes at the skill-selection layer")."

**Location:** `docs/decisions/log.md:89`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quotation (identical apart from bold markup) and its purpose; does not establish that the DD router measurably changed selection.

`skills/divergent-design/SKILL.md:16-17`: `Exists so divergent design competes at the **skill-selection layer**, where open-ended brainstorming otherwise wins by default`. The original competitor was the brainstorming skill, which is the same skill-vs-prose-workflow asymmetry the row describes.

**Evidence:** `skills/divergent-design/SKILL.md:16-18`

---

## Claim 9: "pr-prep's advisory Step 0 wrote 1 failure pattern across ~128 fix commits as of Q-074."

**Location:** `docs/decisions/log.md:89`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with Q-074's recorded figures; does not re-count fix commits or failure-pattern entries, and the attribution of that one entry to Step 0 rests on Q-074 naming Step 0 as the writer.

`docs/working/questions.md:70`: `After the Q-018 backfill (164 entries), docs/thoughts/failure-patterns.md has gained 1 entry across about 128 fix commits. The writer is still pr-prep Step 0, a workflow step that is advisory only.`

**Evidence:** `docs/working/questions.md:67-70`

---

## Claim 10: "Hook-based usage counts are not cited: they under-count silently (Q-017, triage 2026-09-17 §2.2 correction)."

**Location:** `docs/decisions/log.md:89`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two citations existing and saying this; does not establish the under-count mechanism itself (the user rated it low-confidence).

`docs/working/triage-2026-09-17-backlog.md:170-171`: `> **Correction, 2026-09-17 (same day).** The user reports that hook measurement has a history of silent under-counting`, inside §2.2 (heading at `:152`). `docs/working/questions-archive.md:218` is `### Q-017 · rpi-doc-zero-reads`, answered: `the measurement is not trustworthy, so the finding is withdrawn as evidence.` The row no longer cites the withdrawn 15:0 figure.

**Evidence:** `docs/working/triage-2026-09-17-backlog.md:152-179`, `docs/working/questions-archive.md:218-240`

---

## Claim 11: "Each `workflows/<name>.md` ships a router skill of the same name (`skills/<name>/SKILL.md`) ... The exception is `review-fix-loop` (frontmatter `router: none`), which runs only inside `pr-prep`."

**Location:** `global-instructions/CLAUDE.md:13`
**Type:** Configuration / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the router set and the exception; does not establish that the skill list shows routers in a given session.

The router set and exception are right (Claim 1). The frontmatter is abbreviated: the actual value is `router: "none — runs only inside pr-prep step 3, never on its own (see Relationship to other workflows)"` (`workflows/review-fix-loop.md:3`), and a literal `router: none` would fail test 2, which requires a reason: `grep -qE '^router:[[:space:]]*"?none[[:space:]]+—[[:space:]]+[^[:space:]]'` (`test/skills/workflow-routers.bats:66`); the mutations log shows `router: "none"` → `not ok 2`. Precise version: `` (frontmatter `router: "none — <reason>"`) ``.

**Evidence:** `workflows/review-fix-loop.md:3`, `test/skills/workflow-routers.bats:62-72`, `docs/reviews/execution-logs/fc-r1-routers-final-mutations.txt`

---

## Claim 12: "When more than one router could fire, this table's first-match order still decides (a batch is row 2 before any single-task router; a 3+-option choice is row 3 before RPI)."

**Location:** `global-instructions/CLAUDE.md:13`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row numbers against the table that follows; does not establish that row 1 (onboarding) is correctly placed relative to routers.

The table below the paragraph: `| 2 | **Message bundles 2+ independent tasks** ... | parallel-worktrees.md`, `| 3 | **Task involves a design choice** with 3+ viable approaches ... | divergent-design.md`, `| 6 | **Non-trivial feature or bug fix** ... | research-plan-implement.md`, preceded by `Evaluate triggers top-to-bottom. Take the **first match**` (`global-instructions/CLAUDE.md:17`).

**Evidence:** `global-instructions/CLAUDE.md:15-33`

---

## Claim 13: "Route multi-branch integration into workflows/branch-strategy.md: dev integration branch, rebuilding it from open PRs, stale-branch triage ... Replacing a shared branch always needs explicit user approval, in any operating mode."

**Location:** `skills/branch-strategy/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers description and body line 15 against the workflow; does not establish the triggers route correctly in practice.

`workflows/branch-strategy.md` has `## Integration branch refresh` (rebuild from `gh pr list --state open`) and `## Stale-branch triage (advisory)`; on replacing dev: `that pointer swap is a **gated operation requiring explicit human approval** (see Operating Modes in CLAUDE.md), regardless of away/active mode.`

**Evidence:** `skills/branch-strategy/SKILL.md:4`, `skills/branch-strategy/SKILL.md:15`, `workflows/branch-strategy.md` (sections "Setting up or resetting dev", "Integration branch refresh", "Stale-branch triage")

---

## Claim 14: "producing one reusable orientation doc ... Not for projects you started from scratch, and not for answering one "where is X" question."

**Location:** `skills/codebase-onboarding/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers description and body line 15; does not cover the single-lookup exclusion, which the workflow implies (pre-task broad mapping) rather than states.

`workflows/codebase-onboarding.md`: `**Not a trigger:** from-scratch projects you started yourself` and `This workflow produces: docs/working/onboarding-{project}.md — the orientation document ... treated as a living reference.`

**Evidence:** `skills/codebase-onboarding/SKILL.md:4`, `skills/codebase-onboarding/SKILL.md:15`, `workflows/codebase-onboarding.md` ("When to use", "Working documents")

---

## Claim 15: "Read the installed copy at `~/.claude/workflows/divergent-design.md`, or this repo's own file when working inside claude-workflows. Never follow a same-named file that belongs to another project."

**Location:** `skills/divergent-design/SKILL.md:42-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the path being the install destination and the DD router's own suite still passing; does not establish agent compliance.

Install destination per `devcontainer-config/install.sh:135` (quoted in Claim 5). `bats test/skills/divergent-design-router.bats` → `1..8`, 8 `ok` (dd-router log). The diff also removed the former "so the router and the workflow cannot drift apart" wording (`git diff main...HEAD -- skills/divergent-design/SKILL.md`, paraphrased — no quote available because the claim concerns deleted lines).

**Evidence:** `skills/divergent-design/SKILL.md:39-45`, `devcontainer-config/install.sh:135`, `docs/reviews/execution-logs/fc-r1-routers-final-dd-router.txt`

---

## Claim 16: "Ask: "do these share files or an order?" No → this skill. Yes → one task, so use `research-plan-implement` or `task-decomposition`. Each item that lands still goes through `pr-prep`."

**Location:** `skills/parallel-worktrees/SKILL.md:15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the body against the workflow; does not cover trigger quality.

`workflows/parallel-worktrees.md`: `Ask: "do these share files or an order?" Yes → RPI (row 6) or task-decomposition (row 7). No → this workflow.` and step 4: `Each one runs its own pr-prep — review-fix loop, iteration cap and all — and merges as soon as it is clean`.

**Evidence:** `skills/parallel-worktrees/SKILL.md:4`, `skills/parallel-worktrees/SKILL.md:15`, `workflows/parallel-worktrees.md` ("When to use", step 4)

---

## Claim 17: "The review-fix loop inside it has no router of its own: it runs only inside this workflow."

**Location:** `skills/pr-prep/SKILL.md:15`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers absence of a router and the workflow's own statement; does not establish that nothing else ever invokes review-fix-loop.md's rules.

No `skills/review-fix-loop` exists (paraphrased — no quote available because claim covers absence of a directory). `workflows/review-fix-loop.md:212` (quoted in Claim 3) says it should not run standalone.

**Evidence:** `skills/pr-prep/SKILL.md:15`, `workflows/review-fix-loop.md:212`

---

## Claim 18: "Route a finished branch into workflows/pr-prep.md: review-fix loop, cleanup, then local merge or PR ... Merging into `main`, pushing, and opening a PR follow the Operating Modes approval rules in the global instructions."

**Location:** `skills/pr-prep/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the phase order and the approval pointer; does not establish the exact per-mode rule set.

`workflows/pr-prep.md`: Phase 1 step 3 `Review-fix loop`, Phase 2 step 4 `Clean up commit history`, delivery by local merge or GitHub PR; `Merging into main follows the Operating Modes in the global instructions: in /active mode, ask first.` (`workflows/pr-prep.md:26`). The global /active list includes `Pushing to remote` and `Creating or updating pull requests`.

**Evidence:** `skills/pr-prep/SKILL.md:4`, `skills/pr-prep/SKILL.md:15`, `workflows/pr-prep.md:26`, `global-instructions/CLAUDE.md` ("/active")

---

## Claim 19: "Not for one-line fixes ... not for a choice among 3+ approaches (`divergent-design`, which feeds its decision back here). Its hard gate is plan approval before implementation."

**Location:** `skills/research-plan-implement/SKILL.md:15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the gate, the DD feedback, and the trivial-change exclusion against the workflow.

`workflows/research-plan-implement.md` step 4: `This is the hard gate. ... implementation does not begin until the user has reviewed the plan`; `DD's output ... becomes an input to the plan`; `Trivial changes (typo fixes, config tweaks, single-line bug fixes): Skip entirely`.

**Evidence:** `skills/research-plan-implement/SKILL.md:4`, `skills/research-plan-implement/SKILL.md:15`, `workflows/research-plan-implement.md` (steps 2, 4; "When to skip")

---

## Claim 20: "Route a feasibility question into workflows/spike.md: timeboxed, throwaway branch, recorded verdict."

**Location:** `skills/spike/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named properties.

`workflows/spike.md` step 3 `Set a timebox`, step 4 `Work in a throwaway space` (`git checkout -b spike/description-date`), step 5 `Record the findings` with an `## Answer` section.

**Evidence:** `skills/spike/SKILL.md:4`, `skills/spike/SKILL.md:15`, `workflows/spike.md` (steps 3–5)

---

## Claim 21: "Route one task spanning several subsystems into workflows/task-decomposition.md: parallel research, then sequential build ... with explicit interface contracts"

**Location:** `skills/task-decomposition/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers description and body lines 11/15.

`workflows/task-decomposition.md`: `Implementation still happens sequentially in the main agent — sub-agents research and analyze`, and step 1 `#### Capture interface contracts before dispatch`.

**Evidence:** `skills/task-decomposition/SKILL.md:4`, `skills/task-decomposition/SKILL.md:11`, `workflows/task-decomposition.md` ("When to use", step 1)

---

## Claim 22: "Route usability-test work into workflows/user-testing-workflow.md: scoping, moderator script, pilot, analysis, findings."

**Location:** `skills/user-testing-workflow/SKILL.md:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the phase list; does not verify the ui-visual-review exclusion beyond that skill's own description (UI layout review, no users).

`workflows/user-testing-workflow.md` phases: `Phase 0: Scoping`, `Phase 1: Session Design` (`### Moderator Script Template`, `### Pilot Session`), `Phase 3: Analysis`, `Phase 4: Reporting` (`### Findings Report Structure`).

**Evidence:** `skills/user-testing-workflow/SKILL.md:4`, `workflows/user-testing-workflow.md` (Phases 0–4)

---

## Claim 23: "Validates that every workflow has a router skill unless its own frontmatter opts out, and that each router keeps the router contract: it hands off to the installed copy of its workflow and stays a stub."

**Location:** `test/skills/workflow-routers.bats:3-5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the header against the 6 tests' behavior; does not establish frontmatter parsing for CRLF files (`frontmatter()` does not strip `\r`, `body()` does).

See Claim 26 for the mutation matrix. The opt-out is read from the workflow's frontmatter: `frontmatter "$REPO_ROOT/workflows/$1.md" | grep -qE '^router:[[:space:]]*"?none'` (`test/skills/workflow-routers.bats:38`).

**Evidence:** `test/skills/workflow-routers.bats:1-48`, `docs/reviews/execution-logs/fc-r1-routers-final-mutations.txt`

---

## Claim 24: "divergent-design's own, stricter contract lives in divergent-design-router.bats."

**Location:** `test/skills/workflow-routers.bats:13`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers file existence and that it asserts more than the generic suite.

`test/skills/divergent-design-router.bats:45` `@test "skill has required frontmatter fields (name, description, when/trigger)"`, plus `:75` `skill body states the 3+ tradeoff-bearing options trigger test` and `:83` `skill body defines the brainstorming-supersession boundary`, none of which the generic suite checks.

**Evidence:** `test/skills/divergent-design-router.bats:45-90`

---

## Claim 25: "A router body is a short pointer; the workflows it points at run about 70-610 lines."

**Location:** `test/skills/workflow-routers.bats:23-24`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the 9 routed workflows' `wc -l` at 33fdfd3.

`wc -l workflows/*.md`: smallest routed is `72 workflows/parallel-worktrees.md`, largest `608 workflows/divergent-design.md` (paraphrased — no quote available because the values come from command output, not a file).

**Evidence:** `test/skills/workflow-routers.bats:23-25`, `workflows/parallel-worktrees.md`, `workflows/divergent-design.md`

---

## Claim 26: Each of the six test names (e.g. "every workflow without router: none has a router skill of the same name", "each router stays a stub (body at most MAX_BODY_LINES lines)") — each test fails when its own contract breaks.

**Location:** `test/skills/workflow-routers.bats:50-137`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one or more targeted mutations per test, each failing exactly its own test and no other; does not establish resistance to every possible bypass.

Mutations log: test 1 ← spike router deleted (and, separately, `router:` line removed from review-fix-loop.md, mutation-optout log); test 2 ← reason removed, or `skills/review-fix-loop` added; test 3 ← `name: spikey`, or `description:` renamed; test 4 ← handoff, installed path, or never-follow line removed, or all three moved into the frontmatter only (M8); test 5 ← `(router)` dropped from H1; test 6 ← 40 lines appended. Each shows exactly one `not ok` for the intended number. Unmutated base: 6 `ok`.

**Evidence:** `test/skills/workflow-routers.bats:50-137`, `docs/reviews/execution-logs/fc-r1-routers-final-mutations.txt`, `docs/reviews/execution-logs/fc-r1-routers-final-mutation-optout.txt`, `docs/reviews/execution-logs/fc-r1-routers-final-mutate-script.txt`

---

## Claim 27: `router: "none — runs only inside pr-prep step 3, never on its own (see Relationship to other workflows)"`

**Location:** `workflows/review-fix-loop.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reason against the workflow's own text; does not cover pr-prep's step numbering beyond "Phase 1, step 3".

`workflows/review-fix-loop.md:208` `## Relationship to other workflows` exists; `:212`: `The loop is embedded in pr-prep as a required step (Phase 1, step 3). It should not be run as a standalone workflow`. pr-prep's heading is `#### 3. Review-fix loop` under Phase 1.

**Evidence:** `workflows/review-fix-loop.md:3`, `workflows/review-fix-loop.md:208-212`, `workflows/pr-prep.md` ("#### 3. Review-fix loop")

---

## Claim 28: Commit 881762a message ("Now cites the mechanism ... and Q-074's file-based count", "The review-fix-loop router ... Removed; the router test now carries an exemption list with reasons and fails if an exempt workflow gains a router or disappears", "routers now say 'keep this file a pointer and add nothing the workflow does not say'", "'70-600' -> 'about 70-610'", "README: 33 skills")

**Location:** commit 881762a
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message against the tree at 881762a (later superseded by 028105b, e.g. the exemption list became frontmatter); does not re-run that commit's tests.

At 881762a: `git ls-tree --name-only 881762a skills/ | wc -l` → 33; the test has `declare -gA EXEMPT=(` and `@test "exempt workflows exist and have no router"` with `bad+=("$name: no such workflow (stale exemption)")`; `skills/spike/SKILL.md` reads `keep this file a pointer and add nothing the workflow does not say`; the test comment reads `# 70-610 lines.`; log.md at 881762a has 0 matches for "15 times" (paraphrased — no quote available because these are `git show`/`git ls-tree` outputs at a historical commit).

**Evidence:** `git show 881762a:test/skills/workflow-routers.bats`, `git show 881762a:skills/spike/SKILL.md`, `git show 881762a:docs/decisions/log.md`

---

## Claim 29: "every router description now carries a "Not for X (use Y)" clause, and both it and the triggers sit inside the first 250 characters (Q-080 convention; api #1)."

**Location:** commit 028105b
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 8 descriptions, unchanged between 028105b and 33fdfd3 (`git diff 028105b 33fdfd3 --stat -- skills` is empty); does not establish listing truncation behavior.

Same measurement as Claim 4. pr-prep carries no "Not for" (`Use code-review alone for a review with no landing.`), and codebase-onboarding and branch-strategy name no "(use Y)" target. 7 of 8 descriptions are 251–270 characters, so the last trigger phrase or its closing quote falls past 250. The Q-080 convention it cites requires only that the "not this" line end by 250: `every "not this" line ends by character 250` (`docs/working/questions-archive.md:1501`), which all 8 satisfy.

**Evidence:** `skills/*/SKILL.md:4`, `docs/working/questions-archive.md:1501`, `docs/reviews/execution-logs/fc-r1-routers-final-desc-lengths.txt`

---

## Claim 30: "Verified: workflow-routers (6), divergent-design-router, frontmatter-fields and agents-gemini-sync suites pass; mutations (drop the opt-out, drop the installed path) fail the intended tests."

**Location:** commit 028105b
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers workflow-routers (6 tests), divergent-design-router (8) and frontmatter-fields (1) at 33fdfd3, whose tested files match 028105b; does not re-run agents-gemini-sync, which the merge from main changed afterwards.

Base log: `1..6`, all `ok`. dd-router log: `1..8`, 8 `ok`. frontmatter-fields log: `1..1`, 1 `ok`. Dropping the opt-out → `not ok 1` (mutation-optout log); dropping the installed path → `not ok 4` (mutations log, M4b). The count "6" matches the file (6 `@test` blocks).

**Evidence:** `docs/reviews/execution-logs/fc-r1-routers-final-base.txt`, `docs/reviews/execution-logs/fc-r1-routers-final-dd-router.txt`, `docs/reviews/execution-logs/fc-r1-routers-final-frontmatter-fields.txt`, `docs/reviews/execution-logs/fc-r1-routers-final-mutation-optout.txt`, `docs/reviews/execution-logs/fc-r1-routers-final-mutations.txt`

---

## Claim 31: "Colliding triggers removed (api #5)." / "Test no longer requires `when:` ...; routers drop it." / "divergent-design's router gets the same lines and loses 'cannot drift apart'."

**Location:** commit 028105b
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the removed phrases, the missing `when:` in the 8 routers and test, and the DD diff; does not establish the sub-claim that "the loader ignores" `when:` (external to the repo).

`docs/reviews/api-consistency-review-2026-09-29.md:196` lists the colliding phrases `"here's the feedback", "where does X live", "does X support Y", "wrap this up"`; grepping `skills/*/SKILL.md` for them returns exit 1 (no match). None of the 8 routers' frontmatter has `when:` (lines 1–5 of each, quoted above in Claims 13–22 contexts), and the test checks only `^name:` and `^description:` (`test/skills/workflow-routers.bats:82-83`). The DD diff removes `the router and the workflow cannot drift apart.` and adds the installed-path lines.

**Evidence:** `docs/reviews/api-consistency-review-2026-09-29.md:109`, `docs/reviews/api-consistency-review-2026-09-29.md:196`, `test/skills/workflow-routers.bats:76-89`, `skills/divergent-design/SKILL.md:39-45`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 4** (`docs/decisions/log.md:89`): pr-prep's precedence clause is not "not for X", two clauses name no Y, and 7 of 8 descriptions run 1–20 chars past 250 so the last trigger (e.g. RPI's "fix this bug") sits past the mark; say "a precedence clause and the start of the trigger list".
- **Claim 11** (`global-instructions/CLAUDE.md:13`): `router: none` is shorthand; the value the test accepts is `router: "none — <reason>"`, and literal `router: none` fails test 2.
- **Claim 29** (commit 028105b): same imprecision as Claim 4 (commit history; no fix possible short of rewording elsewhere).

### Unverifiable
(none)

---

**Goal-Alignment Note**
- **Answered:** every claim family in the brief — all 8 routers plus the DD edit vs their workflows and sibling skills, description 250-char offsets (measured), the bats header/comments and a per-test mutation matrix (all 6 tests fail only on their own contract), the review-fix-loop `router:` reason, the global paragraph's first-match claim vs the table, README count vs `ls skills`, row 66 in full, and commits 881762a and 028105b. No Incorrect verdicts; 3 Mostly accurate, none blocking.
- **Out of scope:** "the loader ignores `when:`" and the real listing truncation length (external to the repo); agents-gemini-sync suite not re-run (changed by the main merge, not this branch's contract); health-check and full suite not run per brief.
- **Escalate:** none. Whether Claim 4/11 wording needs a fix is a Consider-tier call for the orchestrator.
