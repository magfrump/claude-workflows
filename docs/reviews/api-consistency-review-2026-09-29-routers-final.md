Commit: 33fdfd3

# API Consistency Review — feat/workflow-router-skills (final confirming pass)

**Scope:** full `git diff main...HEAD` at 33fdfd3 in `/workspace/.claude/wt-routers`: 8 new router skills, the divergent-design router edit, `test/skills/workflow-routers.bats`, the `router:` key in `workflows/review-fix-loop.md`, the global CLAUDE.md paragraph, decision-log row 66 and README. Review artifacts under `docs/reviews/` were read as context only.
**Based on:** the Stage-1 fact-check summary in the critic brief (k=3 on 3a63c56, fixes in 881762a), the pass-1 review `docs/reviews/api-consistency-review-2026-09-29.md` (at de96617), and `docs/reviews/override-log.md`.
**Date:** 2026-09-29

The public surface is the skill set: skill names, frontmatter keys, description conventions and trigger phrases. Its consumer is the model reading the skill listing. Once installed, every description loads in every session in every project, truncated at 250 characters.

## Baseline Conventions

- **Description shape (Q-073 [1] / Q-080, `guides/skill-format-audit.md:20`).** The purpose comes first. Where the skill has a sibling to route to, a "not this, use X" line follows and ends by char 250. Trigger phrases start by about char 251 and may run past the truncation point. The 25 pre-branch skills run 363–426 chars. Each wraps at about 95 columns under a `>` folded scalar.
- **Router precedent (`skills/divergent-design/SKILL.md`).** The description leads with "Route … into workflows/<name>.md". The H1 is "<Title> (router)", followed by `## When to use` and a body handoff "Read and follow **`workflows/<name>.md`**".
- **Frontmatter.** `name` and `description` are required (`test/skills/frontmatter-fields.bats`). `when:` is present on all 25 pre-branch skills but has not been required since 2026-09-26 (audit F1). Workflow frontmatter had only `value-justification` before this branch.
- **Skill names** are kebab-case and carry no type suffix. A router's name equals its workflow's basename.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `research-plan-implement`, `pr-prep`, `spike`, `parallel-worktrees`, `task-decomposition`, `branch-strategy`, `codebase-onboarding` | skill name | `divergent-design`, `code-review`, `test-strategy` | `skills/*/SKILL.md`; `workflows/<name>.md` | Consistent: kebab-case, equal to the workflow basename (test-enforced, `workflow-routers.bats` test 3) |
| `user-testing-workflow` | skill name | `ui-visual-review`, `test-strategy` | `skills/*` | Consistent with the basename rule. It is the only skill name with a type suffix; noted at pass 1 as Informational and not re-filed |
| `# <Title> (router)` ×8 | H1 | `# Divergent Design (router)` | `skills/divergent-design/SKILL.md` | Consistent |
| `Route … into workflows/<name>.md` ×8 | description lead | DD's description | `skills/divergent-design/SKILL.md:4` | Consistent (pr-prep: "Route a finished branch into workflows/pr-prep.md") |
| "Not for X (Y)" / "Use Y alone for …" ×8 | description routing clause | fact-check → code-fact-check, security-reviewer → code-review | `skills/{fact-check,security-reviewer,api-consistency-reviewer}/SKILL.md` | Consistent. Every clause ends by char 210, within the 250 window (measured below) |
| `router:` | workflow frontmatter key | `value-justification:` | `workflows/*.md` | No existing precedent in `workflows/*.md` frontmatter. It is the only opt-out mechanism, test-enforced with a reason. No finding: it establishes a key deliberately, and log row 66 records it |
| row `66` | decision-log row | rows 64, 65 | `docs/decisions/log.md` | Consistent now that the 33fdfd3 merge brings row 65 onto the branch (pass-1 #9 resolved) |

Description offsets were measured with a folded-scalar parser; the probe is at `$SCRATCHPAD/desc.py.txt`:

| Router | Length | "Not"/"Use" clause ends | Triggers start |
|---|---|---|---|
| branch-strategy | 263 | 167 | 168 |
| codebase-onboarding | 264 | 165 | 166 |
| parallel-worktrees | 249 | 188 | 189 |
| pr-prep | 252 | ~152 | 153 |
| research-plan-implement | 268 | 210 | 211 |
| spike | 254 | 176 | 177 |
| task-decomposition | 270 | 175 | 176 |
| user-testing-workflow | 251 | 177 | 178 |

## Status of pass-1 findings (de96617)

| Pass-1 # | Finding | Status at 33fdfd3 |
|---|---|---|
| 1 | Disambiguation and triggers past char 250 | **Fixed.** Every clause ends by 210, and every trigger list starts by 211 (table above) |
| 2 | code-review still claims "default whenever a PR is prepared" | **Settled: Deferred in override-log** (outside the diff). pr-prep's side is now in the window (`Use code-review alone for a review with no landing`). Not re-filed |
| 3 | Missing "not this" lines between siblings | **Fixed** for parallel-worktrees → task-decomposition, user-testing-workflow → ui-visual-review, research-plan-implement → parallel-worktrees and divergent-design, and branch-strategy ("Not for one feature branch"). One gap remains: RPI names no spike boundary (Finding 1) |
| 4 | RPI triggers too broad, exclusion only in body | **Fixed.** Now reads `Not for one-line fixes, …`; "build X" and "make X do Y" were dropped |
| 5 | Colliding triggers ("here's the feedback", "where does X live", "does X support Y", "wrap this up") | **Fixed.** All four removed, replaced by "a few things:", "onboard me", "is X feasible", "land this branch" |
| 6 | Test required `when:` | **Fixed.** Dropped from the test and from the routers (Finding 3 covers the resulting mixed state) |
| 7 | "add nothing the workflow does not say" contradicted | **Fixed.** Now reads `Do not restate the workflow here; keep this file a pointer.` The router-level facts that remain (pr-prep's no-router note) do not restate procedure |
| 8 | DD router lacked the installed path and still said "cannot drift" | **Fixed.** DD now names `~/.claude/workflows/divergent-design.md` and carries the never-follow line. It passes `workflow-routers.bats`, whose `routed_names` includes it |
| 9 | Row 66 skipped 65 | **Resolved** by the merge of main (row 65 at c9a370a) |

Targeted run: `bats test/skills/workflow-routers.bats test/skills/frontmatter-fields.bats test/skills/divergent-design-router.bats` passes all 15 tests.

## Findings

#### 1. research-plan-implement does not route feasibility questions to spike, and the global first-match order puts RPI (row 6) before spike (row 8)

**Severity:** Minor
**Location:** `skills/research-plan-implement/SKILL.md:4`; `global-instructions/CLAUDE.md:13` (new paragraph) and `:26`, `:28` (rows 6 and 8)
**Move:** 7 (asymmetry), 3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** the model choosing between the RPI and spike routers for a request like "can we use WebSockets to add live sync?"

Evidence:
- spike → RPI is stated: `Not for building something already known to work (research-plan-implement).`
- RPI → spike is not. RPI's description names only these exclusions: `Not for one-line fixes, several unrelated asks (parallel-worktrees) or choosing among 3+ approaches (divergent-design).`
- New global paragraph: `When more than one router could fire, this table's first-match order still decides (a batch is row 2 before any single-task router; a 3+-option choice is row 3 before RPI).`
- Row 6 (RPI) sits above row 8 (spike): `| 6 | **Non-trivial feature or bug fix** …` / `| 8 | **Feasibility question**: "can this work?" …`

Every other pair the brief flagged now routes in the description. RPI's two carve-outs, batches and 3+-option choices, are exactly the ones the global paragraph lets win over RPI by table order. Feasibility is the one sibling that sits *below* RPI in the table, so the tie-break rule the paragraph states picks RPI for a feasibility question phrased as a feature ("add live sync with WebSockets — can that work?"). The only thing that routes it to spike is spike's own description. Before this branch the table alone governed, and row 6's "non-trivial feature" wording was read against row 8's example. Now two descriptions compete, and only one of them names the boundary. RPI's routing clause ends at char 210, which leaves about 40 chars of room inside the window.

**Recommendation:** Add "feasibility questions (spike)" to RPI's "Not for" list; it fits inside char 250. Alternatively, have the global paragraph's parenthetical also name the spike case ("a feasibility question goes to spike even though row 8 follows row 6").

#### 2. The eight new descriptions are each one ~250-char physical line, while every existing skill wraps at ~95 columns

**Severity:** Informational
**Location:** `skills/{branch-strategy,codebase-onboarding,parallel-worktrees,pr-prep,research-plan-implement,spike,task-decomposition,user-testing-workflow}/SKILL.md:4`
**Move:** 1 (baseline)
**Confidence:** High
**Legibility-target:** maintainers diffing and editing descriptions, and the char-250 audit in `guides/skill-format-audit.md`

Evidence: the new description is a single line, e.g. `  Route a feature or unclear bug that spans files into workflows/research-plan-implement.md. Not for one-line fixes, …`, while the pre-branch skills wrap it. DD shows the wrapped form: `  Route a decision among 3+ tradeoff-bearing options into workflows/divergent-design.md;` then `  supersedes open-ended brainstorming. Test: can you name …` over 5 lines. The probe counted 5 description lines for 24 of 25 pre-branch skills (self-eval: 4) and 1 for each new router.

Under `>` the folded result is identical, so the loader and the listing see no difference. The cost falls on line-based review, which is how the char-250 rule gets audited: a one-word change shows up as the whole description changing.

**Recommendation:** Rewrap to ~95 columns to match the other 25. This is optional and has no behavioral effect.

#### 3. `when:` is now absent on the 8 new routers but present on all 25 others, including the divergent-design router, whose own test still requires it

**Severity:** Informational
**Location:** new routers' frontmatter (lines 1-5); `skills/divergent-design/SKILL.md:9`; `test/skills/divergent-design-router.bats` (test "skill has required frontmatter fields (name, description, when/trigger)")
**Move:** 1 (baseline)
**Confidence:** High
**Legibility-target:** maintainers finishing audit F1

Evidence: the probe reports `when=False` for all 8 routers and `when=True` for the other 25. DD keeps `when: A creative task has resolved to a choice among 3+ tradeoff-bearing options, …`, and its router test's name still asserts `when/trigger`. Rubric C3 records the drop: `Test required \`when:\`, which the loader ignores and the repo stopped requiring 2026-09-26 … ✅ Fixed (dropped from test and routers)`.

Dropping `when:` follows the direction F1 set, and pass 1 recommended it. The skill set is now split 25/8, and within the routers the split is 8/1. That is harmless because the loader ignores the field. A reader inferring the convention from the nearest router (DD) would add `when:` back.

**Recommendation:** No change needed on this branch. When F1 is finished, remove `when:` repo-wide, including from `divergent-design-router.bats`. Until then, a one-line note in F1's status entry that the routers deliberately omit it would prevent re-adding it.

## What Looks Good

- All nine routers now share one handoff shape: the relative path, the installed `~/.claude/workflows/<name>.md` copy, and "Never follow a same-named file that belongs to another project". The generic test enforces it for DD too.
- Every routing clause sits inside the visible 250-char window, earlier than most pre-branch skills place theirs (latest at 210, against 250 for moat).
- The replacement triggers are workflow-specific ("land this branch", "onboard me", "is X feasible", "stale branches") and no longer collide with draft-review or with ordinary lookup questions.
- The opt-out lives in the exempted workflow's own frontmatter with a required reason, and the global paragraph and log row 66 describe it the same way (`router: none`). One mechanism appears in three places, and all three agree.
- Names, H1s and the "Route … into" lead follow the DD precedent exactly.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | RPI names no spike boundary; the global first-match order favors RPI (row 6) over spike (row 8) | Minor | `skills/research-plan-implement/SKILL.md:4`; `global-instructions/CLAUDE.md:13,26,28` | Medium |
| 2 | New descriptions are one physical line; existing ones wrap at ~95 cols | Informational | 8 new `SKILL.md:4` | High |
| 3 | `when:` split 25/8 across skills (8/1 among routers; DD's test still names it) | Informational | router frontmatter; `skills/divergent-design/SKILL.md:9` | High |

Settled and not re-filed: code-review's "default whenever a PR is prepared" (override-log, Deferred), generic-name shadowing (Won't-Fix), trigger-vs-row consistency check (Won't-Fix).

## Overall Assessment

The fix commit resolved every pass-1 finding in scope: truncation, one-way routing, over-broad and colliding triggers, the `when:` requirement, DD's handoff shape and the log numbering. The new surface is now consistent with the Q-080 description convention and the DD router precedent. What remains is one Minor gap: RPI does not name the spike boundary, and the new tie-break rule favors RPI there. That is a one-clause fix inside the window. The two Informational items are cosmetic and cost consumers nothing. Nothing here is breaking. Consumer impact comes down to the occasional feasibility question routed into the full RPI loop instead of a timeboxed spike.

## Goal-Alignment Note

- **Answered:** full-branch API-consistency review at 33fdfd3. All 9 pass-1 findings were verified as fixed, settled or resolved, with character offsets re-measured. Three new findings (1 Minor, 2 Informational), each with Severity, Location, verbatim Evidence, Confidence and Legibility-target.
- **Out of scope:** the harness's skill-precedence behavior and live triggering accuracy (not testable here); the per-session context cost (performance critic); the contents of review artifacts.
- **Escalate:** none. Finding 1 is a one-clause wording choice the author can make directly.
