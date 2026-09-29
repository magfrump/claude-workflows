Commit: 33fdfd3

# Architecture Review: feat/workflow-router-skills (final confirming pass)

**Scope:** `git diff main...HEAD` at 33fdfd3, full branch. In scope: 8 new `skills/<name>/SKILL.md` routers, the edited `skills/divergent-design/SKILL.md` handoff, `test/skills/workflow-routers.bats`, the `router:` frontmatter key added to `workflows/review-fix-loop.md`, the global-instructions paragraph, decision log row 66, README. Review artifacts under `docs/reviews/` were read as context only.
**Date:** 2026-09-29
**Based on:** the pass-1 architecture review (`docs/reviews/architecture-review-2026-09-29.md`, Commit de96617), fix commit 028105b, `docs/reviews/override-log.md` rows 157-162, and the Stage-1 fact-check summary in the critic brief.

Scope check: in scope under **module structure** (8 new modules; a registration rule linking `workflows/` to `skills/`), **data models** (a new `router:` key in workflow frontmatter that the test reads) and **cross-cutting concerns** (skills load into every session in every project, and the global instructions change how routing works). The trust-boundary cross-reference is a no-op: no finding below is a module-boundary finding on a labeled trust boundary.

## Dependency Map

- **Router → workflow (runtime).** Every router, DD included, now names the installed copy `~/.claude/workflows/<name>.md` and says never to follow a same-named file from another project. The workflow does not know its router. The dependency runs from the volatile trigger layer to the stable procedure. That is the right direction. The routers now also depend on the install layout (`install.sh` `CLAUDE_HOME_SRC` puts `workflows` under `~/.claude/`). The test pins that path, so a layout change would show up as a failing test.
- **workflows/ → skills/ (repo integrity).** `routed_names` lists `workflows/*.md` minus any file whose frontmatter matches `^router:\s*"?none`. Every router assertion loops over that list. The opt-out now lives in the workflow it describes.
- **Routing authority.** The global paragraph now names the decision tree as the tiebreaker: "When more than one router could fire, this table's first-match order still decides". Each router description carries a pairwise "Not for X (use Y)" clause inside its first 250 characters.
- **Two router contracts.** DD is checked by both `divergent-design-router.bats` and the generic suite. Both pass at 33fdfd3 (ran both suites: green).

## Status of pass-1 findings

| Pass-1 # | Finding | Status at 33fdfd3 |
|---|---|---|
| 1 | Skill layer drops first-match precedence | **Holds (resolved).** A single authority is named in `global-instructions/CLAUDE.md:13`, and every broad router defers in its description (RPI → parallel-worktrees, divergent-design; spike → RPI; task-decomposition ↔ parallel-worktrees; pr-prep → code-review; user-testing → ui-visual-review). The second half, a test linking trigger lists to decision-tree rows, is settled Won't-Fix (override-log row 159) and is not re-flagged. |
| 2 | Routers copy workflow internals | **Mostly holds.** Step numbers and output filenames are gone from all 8 new routers. Two gate statements remain (Finding 2 below). The test-level guard was not adopted, so nothing stops reintroduction beyond the 45-line cap. |
| 3 | Exemption policy lives in the test | **Holds (resolved).** `review-fix-loop.md` frontmatter carries `router: "none — …"`, the test reads it and requires a reason, and the missing-router failure message names the opt-out. One gap in discoverability remains (Finding 3). |
| 4 | Relative handoff path; DD differs | **Holds (resolved).** All 9 routers name the installed path, and the test asserts it and the never-follow line. DD's "cannot drift apart" is gone. |
| 5 | Test requires `when:` | **Holds for the generic suite.** DD's own suite still requires it (Informational, Finding 5). |
| 6 | Double counting in usage tooling | Settled Won't-Fix (override-log row 160); not re-flagged. |

## Findings

#### 1. No test catches an orphaned router: every router check iterates from `workflows/`, so a deleted workflow leaves a router pointing at nothing

**Severity:** Minor
**Location:** `test/skills/workflow-routers.bats:36-47` (`opted_out`, `routed_names`), and the loops at `:76-123` that all read `< <(routed_names)`
**Move:** 8 (extension points), 3 (module boundary)
**Confidence:** High
**Legibility-target:** whoever retires or renames a workflow
**Evidence:** `for f in "$REPO_ROOT"/workflows/*.md; do name=$(basename "$f" .md); opted_out "$name" || echo "$name"; done` and, in every router test, `done < <(routed_names)`. By contrast, DD's own suite has "ok 10 the workflow file it routes to actually exists".

The registration rule only runs one way, from workflow to skill. If `workflows/spike.md` is deleted, or a workflow gains `router: none` while its router is left in place, then (a) the first test passes because the workflow is no longer listed, and (b) every handoff, title and size check skips `skills/spike`. The only thing that would fail is the opt-out test, and only in case (b). A deleted workflow leaves a live skill, loaded in every session, whose body sends the agent to `~/.claude/workflows/spike.md`. `install.sh` would still have removed that file. Renaming a workflow is caught, because the new name has no router. Deletion is not. With 9 routers this is cheap to close, and the generic suite is meant to be the contract all routers share.

**Recommendation:** Add a test that enumerates `skills/*/SKILL.md` whose H1 matches `\(router\)`, and requires `workflows/<name>.md` to exist without `router: none`. That is the reverse of the first test, and it matches DD's "the workflow file it routes to actually exists".

#### 2. Two routers still restate a workflow gate

**Severity:** Minor
**Location:** `skills/research-plan-implement/SKILL.md:15`, `skills/branch-strategy/SKILL.md:11,15`
**Move:** 3 (module boundary), 7 (content coupling)
**Confidence:** High
**Legibility-target:** whoever edits the RPI annotate gate or branch-strategy's promotion rule
**Evidence:** RPI router: "Its hard gate is plan approval before implementation." Branch-strategy router: "including its approval gate on replacing a shared branch" and "Replacing a shared branch always needs explicit user approval, in any operating mode." Fix commit 028105b: "Copied workflow details removed (architecture Coupling #2)". Each router's closing line: "Do not restate the workflow here; keep this file a pointer."

Step numbers and filenames went, but these are the same kind of copy: facts owned by `workflows/research-plan-implement.md` step 4 and `workflows/branch-strategy.md` refresh step 7 (plus Operating Modes). Both are correct today and unlikely to change. The branch-strategy one also restates a global safety rule, which is fair defence in depth. The cost is small: two more places to update when the gate changes. But the pattern contradicts the rule each router states about itself, and the pr-prep router already shows the cleaner form, a pointer ("follow the Operating Modes approval rules in the global instructions") rather than a restatement.

**Recommendation:** Reword both as pointers ("the workflow's plan-approval gate", "the approval rules in the global Operating Modes"), or accept them in the override log as deliberate safety restatements.

#### 3. The new `router:` workflow-frontmatter key is documented only in the test and the log row, not where workflow frontmatter is described

**Severity:** Minor
**Location:** `workflows/review-fix-loop.md:3`; `guides/skill-creation.md:71`; `global-instructions/CLAUDE.md:13`; `README.md` Skills paragraph
**Move:** 2 (responsibility boundaries), 8
**Confidence:** Medium
**Legibility-target:** the author of the next workflow
**Evidence:** `guides/skill-creation.md:71`: "**Workflows** (`workflows/*.md`) … use `value-justification` frontmatter". It says nothing about a router or `router:`. Global paragraph: "The exception is `review-fix-loop` (frontmatter `router: none`)". README: "a router skill for each workflow except `review-fix-loop`".

Moving the opt-out into frontmatter was the right move. But the rule "a new workflow needs a router or `router: none — <reason>`" is still found mainly by failing the suite. The guide an author reads to learn workflow frontmatter does not mention it. Meanwhile two always-loaded or front-page texts name the single current instance rather than the mechanism, so each future opt-out means editing the global instructions and the README by hand. The failure message softens this, and the policy now has one authority, the frontmatter. What is left is a documentation-placement issue, not coupling.

**Recommendation:** Add one sentence to `guides/skill-creation.md:71` (a workflow ships a same-named router skill unless its frontmatter says `router: "none — <reason>"`). Optionally, phrase the global paragraph and README by mechanism ("workflows whose frontmatter says `router: none`, currently `review-fix-loop`").

#### 4. Pairwise precedence clauses cover the phrase-based rows but not the state-based row 1

**Severity:** Informational
**Location:** `skills/research-plan-implement/SKILL.md:4`, `skills/codebase-onboarding/SKILL.md:4`, `global-instructions/CLAUDE.md:13`
**Move:** 7
**Confidence:** Medium
**Legibility-target:** maintainers tuning router descriptions
**Evidence:** Decision tree row 1: "first session in a project with neither `docs/thoughts/` nor a `docs/working/onboarding-*.md` orientation doc". RPI description: "Not for one-line fixes, several unrelated asks (parallel-worktrees) or choosing among 3+ approaches (divergent-design). Triggers: … \"fix this bug\"."

Row 1 fires on repository state, not on wording, so no description can express it. In a fresh repo, "fix this bug" matches RPI's description, and only the global paragraph ("this table's first-match order still decides") sends it to onboarding. That is the designed behaviour: the table is the named authority, and it ships alongside the routers through the same `install.sh`. This is noted so that a future trim of the global paragraph does not assume the descriptions carry the full order. No action needed.

#### 5. DD's own suite still requires `when:`/`trigger`, which the generic suite dropped as ignored by the loader

**Severity:** Informational
**Location:** `test/skills/divergent-design-router.bats` (test "skill has required frontmatter fields (name, description, when/trigger)"); `skills/divergent-design/SKILL.md:9`
**Move:** 5
**Confidence:** Medium
**Legibility-target:** maintainers of the router contract
**Evidence:** Generic suite (028105b): "Test no longer requires `when:`, which the loader ignores … routers drop it." DD suite output: "ok 7 skill has required frontmatter fields (name, description, when/trigger)". DD frontmatter: "when: A creative task has resolved to a choice among 3+ tradeoff-bearing options…"

This is residual from pass-1 #5, in a file outside this diff. The nine routers now come in two frontmatter shapes, and the two suites disagree on whether `when:` matters. It is harmless at runtime and worth aligning the next time DD's suite is touched.

## What Looks Good

- **One named routing authority.** The global paragraph says the table's first-match order decides and gives the two cases that matter (row 2 before single-task routers, row 3 before RPI). The descriptions carry matching deferrals within the listing's first 250 characters. This closes pass-1 #1 without a second copy of the tree.
- **The opt-out is data on the workflow it describes.** `router: "none — <reason>"` lives in `review-fix-loop.md`. The test requires a reason and rejects a router that coexists with the opt-out, and the missing-router message names the escape hatch. This is the right extension point, and it removed the test-local `EXEMPT` table.
- **The handoff contract now matches deployment.** All nine routers, DD included, name `~/.claude/workflows/<name>.md` and refuse a same-named file from another project. The test asserts both, so one router shape is enforced.
- **Routers are pointers again.** No step numbers or output filenames remain in the 8 new routers. pr-prep refers to Operating Modes instead of restating them.
- **Dependency direction unchanged and correct.** The procedure stays in `workflows/`, and the more volatile trigger layer points at it.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | No test catches an orphaned router (deleted workflow) | Minor | `test/skills/workflow-routers.bats:36-47` | High |
| 2 | RPI and branch-strategy routers still restate a workflow gate | Minor | `skills/research-plan-implement/SKILL.md:15`, `skills/branch-strategy/SKILL.md:11,15` | High |
| 3 | `router:` key undocumented in `guides/skill-creation.md`; global/README name the instance, not the mechanism | Minor | `guides/skill-creation.md:71`, `global-instructions/CLAUDE.md:13` | Medium |
| 4 | State-based row 1 precedence lives only in the global paragraph | Informational | `skills/research-plan-implement/SKILL.md:4` | Medium |
| 5 | DD suite still requires `when:`/`trigger` | Informational | `test/skills/divergent-design-router.bats` | Medium |

## Overall Assessment

The fixes in 028105b hold. The two pass-1 Coupling findings are resolved: routing precedence has one named authority with matching deferrals in the descriptions, and routers no longer quote step numbers or filenames. The move of the opt-out into workflow frontmatter is sound. It puts the policy on the module it describes, fails closed (a missing reason, or an opted-out workflow that still has a router, both fail), and scales to further sub-procedure workflows. No Structural or Coupling findings remain. Everything left is a Minor or Informational cleanup (rubric: 🟢 Consider). The most useful of them is Finding 1: the registration check only runs from workflow to skill, so deleting a workflow can leave a router loaded in every session that points at a missing file. A reverse-direction test closes that for a few lines.

## Goal-Alignment Note

- **Answered:** Full-branch architecture review at 33fdfd3, the confirming pass. Checked that pass-1 Coupling #1 (precedence) and #2 (copied workflow details) and the frontmatter opt-out change hold up: #1 is resolved; #2 is mostly resolved (two gate restatements remain, Finding 2); the opt-out is sound. New: orphaned-router gap (Finding 1), `router:` key missing from the workflow-frontmatter guide (Finding 3). Ran only `bats test/skills/workflow-routers.bats test/skills/divergent-design-router.bats` (green, under `timeout`). No processes left running, no tracked file edited except this report.
- **Out of scope:** Trigger-phrase quality, per-session context cost, and security/performance. Override-log rows 159 and 160 are settled and were not re-flagged. Row 161 (code-review description overlap) is deferred outside the diff.
- **Escalate:** None blocking. Finding 2 is a judgment call (keep the safety restatement vs. pointer form) that the author can settle with an override row.
