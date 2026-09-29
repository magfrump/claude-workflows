Commit: de96617

# Architecture Review: feat/workflow-router-skills

**Scope:** `git diff main...HEAD` (3a63c56..de96617). In scope: 8 new `skills/<name>/SKILL.md` routers, `test/skills/workflow-routers.bats`, the global-instructions paragraph, decision log row 66. Review artifacts under `docs/reviews/` were read as context only.
**Date:** 2026-09-29
**Based on:** code-fact-check reports r1–r3 (k=3 on 3a63c56; fixes in 881762a), summarized in the critic brief.

Scope check: in scope under **module structure** (8 new modules, and a new rule coupling the `workflows/` and `skills/` module kinds) and **cross-cutting concerns** (the skill list is loaded into every session in every project, and the global instructions change how routing works). The trust-boundary cross-reference is a no-op: this review files no module-boundary findings that sit on a trust boundary.

## Dependency Map

- **Router → workflow (runtime).** Each `skills/<name>/SKILL.md` names `workflows/<name>.md`, plus `~/.claude/workflows/<name>.md` in every new router. The workflow does not know its router. The dependency runs from the volatile layer (trigger wording, which gets tuned often) to the stable one (the procedure). That is the right direction.
- **workflows/ → skills/ (repo integrity).** `workflow-routers.bats` enumerates `workflows/*.md` and fails when a matching skill is missing. This is a registration rule, not a code dependency. It means adding a workflow now also requires adding a skill, or editing the test's `EXEMPT` table.
- **Routing authority, now two layers.** (a) The ordered, first-match decision tree in `global-instructions/CLAUDE.md` (plus the list in `AGENTS.md`). (b) The unordered skill list, where each router's `description` competes on its own. The new paragraph links (a) to (b) ("When a row below activates a workflow, invoke its skill"). Nothing ties their trigger vocabularies together.
- **Two router contracts.** `divergent-design` is checked by both `divergent-design-router.bats` (stricter, specific to it) and the new generic suite. Its body is 37 lines, so it passes both.
- **Shared name space.** `scripts/lib/skill-paths.sh` and `scripts/skill-usage-report.sh` now see each router name twice, as `skill:<name>` and `workflow:<name>`.

## Findings

#### 1. The skill layer drops the decision tree's first-match precedence, and trigger vocabulary is now kept in three places with no link between them

**Severity:** Coupling
**Location:** `skills/research-plan-implement/SKILL.md:4-7`, `skills/parallel-worktrees/SKILL.md:3-8`, `skills/task-decomposition/SKILL.md:3-7`, `global-instructions/CLAUDE.md:13-15` (new paragraph) against the decision-tree table below it
**Move:** 7 (coupling surface), 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** the maintainer who next edits a trigger row or a router description
**Evidence:** Global instructions: "Evaluate triggers top-to-bottom. Take the **first match**". Paragraph added on this branch: "When a row below activates a workflow, invoke its skill rather than paraphrasing the workflow from memory." RPI router description: "Triggers: \"add a feature\", \"implement X\", \"fix this bug\", \"build X\"". Parallel-worktrees router: "Triggers: \"a few things:\", \"couple of bugs\" … a numbered or bulleted list of asks".

The decision tree is an ordered router: batch detection (row 2) and DD (row 3) come before RPI (row 6) on purpose. Skill selection is a flat match on descriptions. "A few things: fix this bug, build X" matches both the parallel-worktrees and RPI descriptions, and nothing in the skill layer says which one wins. Only task-decomposition writes its precedence into its description ("Not for several unrelated tasks … that is parallel-worktrees"). RPI, the broadest router, does not defer to parallel-worktrees or DD. The same trigger phrases now live in CLAUDE.md, AGENTS.md and eight descriptions. No test or health check ties them together (health-check check 3 compares workflow and skill *names* across the MD files, not triggers). So re-tuning a row in one place silently diverges from the others, and which authority wins depends on which one the model reads first.

**Recommendation:** Name one routing authority. Cheapest option: add one precedence clause to each broad router's description, e.g. for RPI "if the message bundles 2+ independent tasks, or the task is a choice among 3+ options, parallel-worktrees or divergent-design comes first". Add a test that each router's trigger list appears in (or is cited by) its decision-tree row, or drop the trigger lists from one of the two layers.

#### 2. Routers name workflow internals (step numbers, output filenames), which the 45-line cap cannot catch

**Severity:** Coupling
**Location:** `skills/pr-prep/SKILL.md:22,28-31`, `skills/research-plan-implement/SKILL.md:29-31`, `skills/spike/SKILL.md:28-29`, `skills/parallel-worktrees/SKILL.md:28-29`
**Move:** 3 (module boundary), 7 (content coupling)
**Confidence:** High
**Legibility-target:** whoever renumbers or restructures a workflow
**Evidence:** pr-prep router: "The workflow picks the delivery path (local merge vs GitHub PR) before its Step 0." and "Its step 3 is the review-fix loop". RPI router: "Its outputs are `docs/working/research-{topic}.md`, `plan-{topic}.md` and `checkpoint-{topic}.md`, and its hard gate is plan approval before implementation." Every router: "Do not restate it here; keep this file a pointer and add nothing the workflow does not say."

The rule the routers state ("add nothing the workflow does not say") guards against *contradiction* but not *duplication*. Each restated fact is correct today, and Stage 1 verified them. But each is a copy that must change whenever the workflow changes, and nothing checks the copies. The one check the test has, a line cap, measures size and not coupling: a 10-line router can still pin three step numbers. Stage 1 already found one such drift (the removed review-fix-loop router's "2 clean passes"). That is evidence this failure mode is real, not hypothetical. The workflow is the single source of the procedure only while no router quotes it.

**Recommendation:** Keep router bodies to trigger/scope guidance plus the handoff line, and drop statements about the workflow's internals (step numbers, filenames, gates). If one must stay, have it cite a workflow anchor (`workflows/pr-prep.md#3-review-fix-loop`), so a heading rename breaks a link a linter can see. Alternatively, extend the test to reject `[Ss]tep [0-9]` in router bodies.

#### 3. The exemption policy lives in the test file, not with the workflow it describes

**Severity:** Minor
**Location:** `test/skills/workflow-routers.bats:21-25`
**Move:** 8 (extension points), 2
**Confidence:** High
**Legibility-target:** the author of the next sub-procedure workflow
**Evidence:** `declare -gA EXEMPT=( [review-fix-loop]="runs only inside pr-prep step 3 (workflows/review-fix-loop.md: 'should not be run as a standalone workflow')" )`

"This workflow is a sub-procedure and gets no router" is a property of the workflow. It is now written in six places: review-fix-loop.md's prose, the test's `EXEMPT` table, the global-instructions paragraph, the README, the pr-prep router, and log row 66. A new sub-procedure workflow will fail the suite with "workflows with no skills/<name>/SKILL.md router". That pushes the author toward writing a router by default (the wrong fix) rather than toward the exemption, which is only found by reading the test. Workflows already carry frontmatter (`value-justification:`, health-check check 7), so the declaration has a natural home.

**Recommendation:** Declare it in the workflow's frontmatter (e.g. `router: none — runs inside pr-prep step 3`) and have the test read it. At minimum, make the missing-router failure message mention the exemption option.

#### 4. The pinned handoff form is the relative path, which does not resolve outside this repo; divergent-design differs

**Severity:** Minor
**Location:** `test/skills/workflow-routers.bats:83-96`; `skills/divergent-design/SKILL.md` (Hand off section)
**Move:** 3
**Confidence:** Medium
**Legibility-target:** an agent running a router in another project
**Evidence:** Test: `grep -qF "Read and follow **\`workflows/$name.md\`**"`. New routers: "(installed copy: `~/.claude/workflows/pr-prep.md`)". DD router: "Read and follow **`workflows/divergent-design.md`** end to end" (no installed path).

`devcontainer-config/install.sh` installs routers and workflows into `~/.claude/`. In any other project, `workflows/<name>.md` does not exist. The contract the test enforces is the relative form, and the path that actually works there is an unenforced parenthetical. DD, the model the new routers copy, has no installed path at all, so today there are two router shapes. DD's router and its bats header also still say the router and workflow "cannot drift apart", the wording Stage 1 marked INCORRECT and reworded in the new routers only.

**Recommendation:** Have the generic test also require the `~/.claude/workflows/<name>.md` form, bring DD's handoff and "cannot drift" wording into line (or record why DD is left as is), so all nine routers share one contract.

#### 5. The test requires `when:`, a field another suite documents as ignored by the loader

**Severity:** Minor
**Location:** `test/skills/workflow-routers.bats:66-80`
**Move:** 5 (interface segregation)
**Confidence:** Medium
**Legibility-target:** maintainers of the skill frontmatter contract
**Evidence:** New test: `echo "$fm" | grep -qE '^when:' || bad+=("$name: when")`. `test/skills/frontmatter-fields.bats:4-5`: "Not 'when'/'trigger': the skill loader ignores them and triggers on 'description' (guides/skill-format-audit.md F1)."

Two contracts now disagree about whether `when:` matters. Routing happens only through `description`. Requiring `when:` spends effort on a field the model never uses for selection, and it can mislead an author into tuning `when:` while routing misbehaves.

**Recommendation:** Drop the `when:` assertion, or cite the reason it is required for routers (for example, the orchestrator's own `when` selection) in the test comment.

#### 6. Each router name now appears in the usage tooling as both a skill and a workflow

**Severity:** Informational
**Location:** `scripts/skill-usage-report.sh:43-64`, `scripts/lib/skill-paths.sh`
**Move:** 7
**Confidence:** Medium
**Legibility-target:** readers of the usage report
**Evidence:** `known_skills+=("skill:$name")` … `known_workflows+=("workflow:$name")`

The namespaces are distinct, so nothing breaks. But one routed invocation can now log `skill:pr-prep` (the Skill call) and then `workflow:pr-prep` (the read), and each unused router shows up twice under "Never invoked". Row 66 already avoids usage counts as evidence, so this only affects how the report reads.

**Recommendation:** None required. If the report is used again, group each `skill:X` with its `workflow:X` as one row.

## What Looks Good

- **Dependency direction is correct.** Routers depend on workflows and never the reverse. The procedure stays in one module kind, and the trigger layer, which changes more often, points at it.
- **The generic contract test is the right extension mechanism.** It enumerates `workflows/*.md` instead of listing routers by hand, so a new workflow cannot silently go without a router. The mutation logs show each assertion fails only when its own contract breaks.
- **The stale-exemption check** ("exempt workflows exist and have no router") keeps the exemption table from rotting in either direction.
- **Body-only assertions** (handoff, title) follow the lesson from `divergent-design-router.bats`: a frontmatter description cannot satisfy a body contract.
- **Removing the review-fix-loop router** rather than softening it kept the sub-procedure boundary that `review-fix-loop.md` owns ("each rule is stated in one place").

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Skill layer drops first-match precedence; triggers kept in 3 unlinked places | Coupling | `skills/research-plan-implement/SKILL.md:4-7`, `global-instructions/CLAUDE.md:13-15` | Medium |
| 2 | Routers restate workflow internals; line cap doesn't detect it | Coupling | `skills/pr-prep/SKILL.md:22,28-31` et al. | High |
| 3 | Exemption policy lives in the test, not the workflow | Minor | `test/skills/workflow-routers.bats:21-25` | High |
| 4 | Pinned handoff path is repo-relative; DD router differs | Minor | `test/skills/workflow-routers.bats:83-96`, `skills/divergent-design/SKILL.md` | Medium |
| 5 | Test requires `when:`, which frontmatter-fields.bats says the loader ignores | Minor | `test/skills/workflow-routers.bats:66-80` | Medium |
| 6 | Router names appear twice in usage tooling | Informational | `scripts/skill-usage-report.sh:43-64` | Medium |

## Overall Assessment

The structure is sound: a thin, one-way pointer from skill to workflow, enforced by a generic test that scales when workflows are added. No structural (Must Fix) problem. The main concern is routing authority (Finding 1). The branch adds a second, unordered router (skill descriptions) next to the ordered decision tree without saying which one wins, and RPI's broad triggers are the likeliest to take over requests the tree sends elsewhere. Finding 2 is the other half of the same coupling: routers quote workflow internals, and nothing checks the copies. Both can be fixed in place with description and test edits; no restructuring is needed. Findings 3–5 are small contract cleanups worth doing while the pattern has 9 instances rather than 20.

## Goal-Alignment Note

- **Answered:** Architecture review of the full branch diff at de96617, looking at dependency direction, router/workflow duplication, the exemption mechanism, and how new workflows get added. Findings 1–6 each carry Severity, Location, verbatim Evidence, Confidence and Legibility-target. Ran only `bats test/skills/workflow-routers.bats` (green).
- **Out of scope:** The per-session context cost of nine descriptions, and how good each trigger phrase is on its own terms (those belong to a trigger/overlap critic). Security and performance were not reviewed.
- **Escalate:** Log row 66's Source column cites "log 65", but `docs/decisions/log.md` on this branch goes from row 64 to 66. Either a row is missing or the number is wrong. This is a fact-check item, not an architecture one; flagged for the orchestrator.
