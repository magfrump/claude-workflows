Commit: de96617

# API Consistency Review — feat/workflow-router-skills

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-routers` (8 new router skills, `test/skills/workflow-routers.bats`, `global-instructions/CLAUDE.md`, `docs/decisions/log.md` row 66, README). Review artifacts under `docs/reviews/` treated as context only.
**Date:** 2026-09-29
**Based on:** Stage-1 fact-check summary in the critic brief (k=3 on 3a63c56, fixes in 881762a)

The public surface here is the skill set: skill names, frontmatter keys, description conventions and trigger phrases. The consumer is the model reading the skill listing, since every description loads in every session in every project once the skills are installed.

## Baseline Conventions

- **Description shape (Q-073 [1] / Q-080, `guides/skill-format-audit.md:20`).** The purpose comes first. Then, where the skill has a sibling to route to, a "not this, use X" line that ends by character 250. Then the trigger phrases, which start by about char 251. Totals run 364–426 characters. The reason is the listing's 250-character truncation (`guides/skill-format-audit.md:100`).
- **Router precedent (`skills/divergent-design/SKILL.md`).** The description starts "Route … into workflows/<name>.md". The H1 is "<Title> (router)". The body opens with an "Exists so … competes at the skill-selection layer" line, then `## When to use`, then a handoff line: "Read and follow **`workflows/<name>.md`** end to end".
- **Frontmatter keys.** Every skill has `name`, `description` and `when`. Some add `requires`, `lens` and similar. Since 2026-09-26, `when` is deliberately *not* required: the loader ignores it (`test/skills/frontmatter-fields.bats:4`, audit table row F1 at `guides/skill-format-audit.md:197`).
- **Skill names** are kebab-case nouns or noun phrases with no type suffix (`code-review`, `divergent-design`, `test-strategy`).
- **Decision-log rows** are numbered consecutively, and cross-references cite existing rows.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `research-plan-implement` | skill name | `divergent-design`, `code-review`, `test-strategy` | `skills/*/SKILL.md`; `workflows/research-plan-implement.md` | Consistent: kebab-case, matches the workflow basename exactly as DD does |
| `pr-prep` | skill name | `divergent-design`, `code-review` | `workflows/pr-prep.md` | Consistent |
| `spike` | skill name | `divergent-design`, `self-eval` | `workflows/spike.md` | Consistent |
| `parallel-worktrees` | skill name | `divergent-design` | `workflows/parallel-worktrees.md` | Consistent |
| `task-decomposition` | skill name | `divergent-design` | `workflows/task-decomposition.md` | Consistent |
| `branch-strategy` | skill name | `test-strategy`, `divergent-design` | `workflows/branch-strategy.md` | Consistent |
| `codebase-onboarding` | skill name | `divergent-design` | `workflows/codebase-onboarding.md` | Consistent |
| `user-testing-workflow` | skill name | `ui-visual-review`, `test-strategy`, `divergent-design` | `skills/*` (no skill has a type suffix); `workflows/user-testing-workflow.md` | Consistent with the workflow filename, the rule the test enforces. It is the only skill name with a type suffix (`-workflow`); Informational, not filed |
| `# <Title> (router)` ×8 | H1 | `# Divergent Design (router)` | `skills/divergent-design/SKILL.md:14` | Consistent |
| `Route … into workflows/<name>.md` ×8 | description lead | DD's description | `skills/divergent-design/SKILL.md:4` | Consistent |
| `Read and follow **\`workflows/<name>.md\`**` ×8 | body handoff | DD's handoff | `skills/divergent-design/SKILL.md:39` | Consistent in wording. The new routers add an installed-copy path that DD lacks (Finding 8) |
| `when:` ×8 | frontmatter key | `when:` on all 25 existing skills | `skills/*/SKILL.md` | Present everywhere, but the new test *requires* it (Finding 6) |
| row `66` | decision-log row | rows 62, 63, 64 | `docs/decisions/log.md:85-87` | Inconsistent numbering: no row 65 on this branch (Finding 9) |

## Findings

#### 1. Four router descriptions push their disambiguation or triggers past the 250-character truncation point

**Severity:** Inconsistent
**Location:** `skills/task-decomposition/SKILL.md:3-8`, `skills/pr-prep/SKILL.md:3-8`, `skills/parallel-worktrees/SKILL.md:3-8`, `skills/branch-strategy/SKILL.md:3-8`
**Move:** 1 (baseline), 2
**Confidence:** High
**Legibility-target:** the model choosing a skill from the truncated listing

Precedent: "not this" line ends by char 250, triggers start by ~251, used in `skills/*/SKILL.md` (the 25 pre-branch skills; audit record `guides/skill-format-audit.md:20`)

Evidence (character offsets measured on the folded description):
- task-decomposition: "Not for" starts at char 246. Its routing target, "that is parallel-worktrees)", ends at 321. "Triggers" starts at 323. The first 250 characters end with `…then plan and implement sequentially. Not `.
- pr-prep: "code-review alone for a review only." ends at 270. "Triggers" starts at 271.
- parallel-worktrees: "Triggers" starts at 260.
- branch-strategy: "Triggers" starts at 256.

The existing skills put their disambiguation inside the visible window, with the latest ending at char 250 (moat). The new routers spend the window on a list of workflow steps ("size gate, review-fix loop, history cleanup, verification…", "split the research…, capture interface contracts, dispatch research subagents, reconcile…"). In the truncated listing, task-decomposition's "Not for several unrelated tasks" and pr-prep's code-review split are cut off. Those are the two disambiguations the brief says matter most. Three descriptions also exceed the existing 364–426 band: codebase-onboarding at 451, task-decomposition at 441, branch-strategy at 427.

**Recommendation:** Reorder each description as purpose → "not this, use X" → triggers, and move the workflow step list into the body's `## When to use`. That is what Q-080 did for the existing skills.

#### 2. pr-prep and code-review both claim the "PR is being prepared" moment, and only the new side disambiguates

**Severity:** Inconsistent
**Location:** `skills/pr-prep/SKILL.md:5-8`, with `skills/code-review/SKILL.md:3-8` (unchanged)
**Move:** 7 (asymmetry), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** skill selector; users typing "ready for review" / "open a PR"

Evidence:
- code-review description (unchanged): `default whenever a PR is prepared or evaluated.`
- pr-prep description: `Triggers: "ready to merge", "open a PR", "ready for review", …`, and `use this for the whole landing, code-review alone for a review only.`

On "open a PR" or "ready for review", both descriptions claim the moment. Only pr-prep says how to split it, and that sentence is past char 250 (Finding 1). code-review still says it is the default whenever a PR is prepared, so the two contracts conflict. Existing sibling pairs route in both directions. For example, fact-check names code-fact-check, and security-reviewer names code-review (`guides/skill-format-audit.md:20`).

**Recommendation:** Change code-review's closing clause to route landing requests to pr-prep, for example: "default for a review of a PR; landing a branch → pr-prep, which runs this". Keep the pr-prep side inside the visible window.

#### 3. Missing or one-way "not this" routing between new sibling pairs

**Severity:** Inconsistent
**Location:** `skills/parallel-worktrees/SKILL.md:3-8`, `skills/user-testing-workflow/SKILL.md:3-8`, `skills/research-plan-implement/SKILL.md:3-7`, `skills/branch-strategy/SKILL.md:3-8`
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** skill selector

Evidence:
- task-decomposition's description: `Not for several unrelated tasks in one message (that is parallel-worktrees).` parallel-worktrees' description has no reverse pointer. Its pointer to task-decomposition and RPI is only in the body: `Yes → one task, so use \`research-plan-implement\` or \`task-decomposition\`.`
- user-testing-workflow points to ui-visual-review only in the body: `For reviewing a UI's layout without users, use \`ui-visual-review\` instead.`
- research-plan-implement's description names no sibling. Its trivial-edit exclusion and the spike boundary are only in bodies: RPI body `Skip it only for trivial edits`, spike body `use \`research-plan-implement\` instead`.
- branch-strategy's trigger `"parallelize 5 features this week"` overlaps parallel-worktrees' fan-out purpose with no pointer either way.

The baseline convention puts the "not this" line in the description "where the skill has a sibling to route to", because the description is what decides whether a skill fires. The body is read only after it has fired. (The new test's own comment says the same thing about frontmatter vs body at `workflow-routers.bats:88-89`.)

**Recommendation:** Add a short "not this" clause inside the first 250 characters for each pair: parallel-worktrees → task-decomposition; user-testing-workflow → ui-visual-review; research-plan-implement → spike (feasibility) and trivial edits; branch-strategy → parallel-worktrees (one batch of asks).

#### 4. research-plan-implement's triggers are broad enough to fire on trivial edits and on other skills' requests

**Severity:** Minor
**Location:** `skills/research-plan-implement/SKILL.md:6-7`
**Move:** 2, 3
**Confidence:** Medium
**Legibility-target:** skill selector; user making a one-line change

Precedent: in-description applicability test, used in `skills/divergent-design/SKILL.md:5-6` ("Test: can you name 3+ viable options …? If not, brainstorming applies.")

Evidence: `Triggers: "add a feature", "implement X", "fix this bug", "build X", "make X do Y", "change how X works", "refactor X".` The exclusion only appears in the body: `Skip it only for trivial edits (a typo, a config value, a one-line fix whose cause is already known).`

"make X do Y" and "fix this bug" also cover existing skills' territory. ui-visual-review has `"fix the layout", "make this responsive"`, and tech-debt-triage has `"is this worth refactoring"`. A description that fires on nearly every coding request with no exclusion competes with every specialised skill. It also turns one-line fixes into a research doc, a plan doc and an approval gate. DD's router solved the same problem by putting its applicability test in the description.

**Recommendation:** Put the scope condition in the description ("…touches more than one file or has an unclear root cause; not for one-line fixes"). Drop or narrow the most generic phrases ("make X do Y", "build X").

#### 5. Other trigger phrases collide with existing skills or with ordinary requests

**Severity:** Minor
**Location:** `skills/parallel-worktrees/SKILL.md:7`, `skills/codebase-onboarding/SKILL.md:8`, `skills/spike/SKILL.md:7`, `skills/pr-prep/SKILL.md:8`
**Move:** 2
**Confidence:** Medium
**Legibility-target:** skill selector

Evidence and collision:
- parallel-worktrees `"here's the feedback"` vs draft-review `"give me feedback on this"`. A user pasting reviewer feedback on an essay would match the fan-out router.
- codebase-onboarding `"where does X live"` is an ordinary lookup question in any repo. As a trigger, it starts a 13-step orientation-doc workflow.
- spike `"does X support Y"` is often answerable from the docs. As a trigger, it opens a spike branch and a graveyard entry.
- pr-prep `"wrap this up"` is also how users end a session, which is the RPI handoff-doc case (`workflows/research-plan-implement.md` step 7, Session handoff).

Precedent: the audit notes that phrases shared across skills were left unresolved (`guides/skill-format-audit.md:20`, "No de-overlap"). These are new overlaps, not inherited ones.

**Recommendation:** Replace these with phrases specific to the workflow ("several independent asks", "onboard me to this repo", "spike whether X can…", "land this branch"), or qualify them.

#### 6. The new test requires `when:`, reversing the repo's decision to stop requiring it

**Severity:** Minor
**Location:** `test/skills/workflow-routers.bats:67-81`
**Move:** 1, 3
**Confidence:** High
**Legibility-target:** maintainers resolving audit F1

Evidence:
- New test: `echo "$fm" | grep -qE '^when:' || bad+=("$name: when")`.
- `test/skills/frontmatter-fields.bats:4`: `Not 'when'/'trigger': the skill loader ignores them and triggers on 'description' (guides/skill-format-audit.md F1).`
- Audit row: `Partly done 2026-09-26: \`when\` no longer required by health-check or \`frontmatter-fields.bats\`; the fields remain | F1: Remove \`when\`, merge into \`description\``.

The repo is moving toward removing `when`, and this test adds a new consumer that requires it. Completing F1 would now also mean editing this test. The routers put real routing content in the dead field: codebase-onboarding's `when:` holds the "no docs/working/onboarding-*.md and no docs/thoughts/" condition, which its description only partly repeats ("a first session in a project with no onboarding doc").

**Recommendation:** Drop the `when:` assertion. Check `name` and `description` as `frontmatter-fields.bats` does. Keep any routing content from `when:` in the description.

#### 7. The routers restate facts despite their own "add nothing" line

**Severity:** Informational
**Location:** `skills/pr-prep/SKILL.md:28-31`, `skills/branch-strategy/SKILL.md:29-30`
**Move:** 3 (documentation drift)
**Confidence:** Medium
**Legibility-target:** maintainers of the router contract

Evidence: every router says `keep this file a pointer and add nothing the workflow does not say`. Then pr-prep adds `…\`workflows/review-fix-loop.md\`, which has no router of its own because it runs only inside pr-prep`. That is a statement about the skill set, which no workflow makes. The instruction and the content disagree, and the body-line cap is the only guard against drift.

**Recommendation:** Either allow router-level facts in the contract sentence ("add nothing about the procedure…"), or move the exemption fact to the global CLAUDE.md paragraph, which already states it.

#### 8. The divergent-design router now differs from the eight new ones in its handoff shape

**Severity:** Informational
**Location:** `skills/divergent-design/SKILL.md:39-43` (unchanged) vs the new routers' handoff lines, e.g. `skills/spike/SKILL.md:26-27`
**Move:** 1
**Confidence:** High
**Legibility-target:** agent running a router in a project that is not claude-workflows

Evidence: the new routers say `(installed copy: \`~/.claude/workflows/spike.md\`)`. DD says only `Read and follow **\`workflows/divergent-design.md\`** end to end`, and still says `so the router and the workflow cannot drift apart`. The fact-check reworded that claim in the new routers because it was inaccurate. In other projects the relative path does not exist, so the new routers resolve there and DD's does not. `devcontainer-config/install.sh:135` confirms that `workflows` is copied to `~/.claude/`.

**Recommendation:** Add the installed-copy path to DD's handoff and apply the same "cannot drift" rewording, so all nine routers share one shape.

#### 9. Decision-log row 66 skips 65 and cites a row that is not on this branch or main

**Severity:** Informational
**Location:** `docs/decisions/log.md` (new row 66)
**Move:** 1
**Confidence:** High
**Legibility-target:** reader following the log's cross-references

Evidence: the row before it is `| 64 | 2026-09-28 |`. The new row is `| 66 | 2026-09-29 |` and ends `| User request 2026-09-28; log 65 |`. Row 65 exists only on the unmerged branch `fix/agents-md-no-imports`. If this branch merges first, `log 65` points at nothing, and the table has a gap.

**Recommendation:** Merge `fix/agents-md-no-imports` first, or note the dependency in the merge commit. Alternatively, renumber the row at merge time if 65 does not land.

## What Looks Good

- The eight skill names match their workflow basenames exactly, the same rule DD set, and the test enforces it (`workflow-routers.bats:73`).
- The H1 "(router)", the "Route … into workflows/<name>.md" lead and the "Read and follow" handoff copy the DD precedent faithfully.
- The EXEMPT list with a reason, and the test that an exempt workflow has no router, is a clean way to express the review-fix-loop exception. The global CLAUDE.md paragraph states the same exception.
- task-decomposition and pr-prep do include "not this" lines, just too late in the text. spike's `For "can this work?", not "build this"` sits inside the visible window (ends at char 230).
- The descriptions stay near the existing length band (364–451 characters, against 364–426).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | Disambiguation and triggers past the 250-char truncation point (4 routers) | Inconsistent | `skills/{task-decomposition,pr-prep,parallel-worktrees,branch-strategy}/SKILL.md:3-8` | High |
| 2 | pr-prep and code-review both claim the PR-preparation moment; one-way routing | Inconsistent | `skills/pr-prep/SKILL.md:5-8`, `skills/code-review/SKILL.md:8` | High |
| 3 | Missing or one-way "not this" lines between sibling pairs | Inconsistent | `skills/{parallel-worktrees,user-testing-workflow,research-plan-implement,branch-strategy}/SKILL.md` | Medium |
| 4 | RPI triggers too broad; trivial-edit exclusion only in the body | Minor | `skills/research-plan-implement/SKILL.md:6-7` | Medium |
| 5 | Colliding or ordinary-request triggers ("here's the feedback", "where does X live", "does X support Y", "wrap this up") | Minor | four routers | Medium |
| 6 | New test requires `when:`, reversing audit F1 | Minor | `test/skills/workflow-routers.bats:75` | High |
| 7 | "Add nothing the workflow does not say" contradicted by router-level facts | Informational | `skills/pr-prep/SKILL.md:28-31` | Medium |
| 8 | DD router lacks the installed path and still says "cannot drift" | Informational | `skills/divergent-design/SKILL.md:39-43` | High |
| 9 | Log row 66 skips 65 and cites an unmerged row | Informational | `docs/decisions/log.md` | High |

## Overall Assessment

Structurally, the routers match the DD precedent closely: naming, H1, handoff line and the test contract are all consistent. The inconsistencies are in the description layer, which is the part that decides whether a skill fires. Half of the new descriptions spend their visible 250 characters on the workflow's step list, which cuts off the "not this" routing the repo's description convention puts first. The most important overlap, pr-prep vs code-review, is routed from one side only. RPI's trigger list is broad enough to compete with most specialised skills and to fire on one-line edits, with its exclusion hidden in the body.

All of this can be fixed in place by reordering the descriptions as purpose → "not this" → triggers (the Q-080 recipe), adding the reverse pointers, and narrowing a handful of phrases. None of it requires redesign. On per-session cost: the eight new descriptions total about 3,240 characters, all of it loaded in every project. That is a further reason to spend each description's visible 250 characters on routing rather than restating the workflow's procedure.

## Goal-Alignment Note

- **Answered:** Reviewed skill names, frontmatter keys, description conventions (against the Q-080 front-loading record and the DD router), and trigger overlaps with existing skills, as the prompt asked. There are 9 findings, 3 of them Inconsistent. Checked that the installed-path claim holds (`install.sh:135`) and that the fact-check fixes are present: no review-fix-loop router, and the "cannot drift" wording is removed from the new routers, though it remains in DD.
- **Out of scope:** Accuracy of each router's facts against its workflow (the fact-check covers this). Performance and architecture concerns (other critics). No tests were run.
- **Escalate:** Finding 2 needs an edit to code-review, an existing skill outside the branch's diff. Finding 9 depends on the merge order of `fix/agents-md-no-imports`.
