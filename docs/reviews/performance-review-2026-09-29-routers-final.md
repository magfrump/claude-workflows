Commit: 33fdfd3

# Performance Review — feat/workflow-router-skills (final confirming pass)

**Scope:** `git diff main...HEAD` at 33fdfd3, full branch: 8 router skills, `skills/divergent-design/SKILL.md`, `test/skills/workflow-routers.bats`, `global-instructions/CLAUDE.md` paragraph, `workflows/review-fix-loop.md` opt-out, decision log row 66, README. Review artifacts under `docs/reviews/` are context only.
**Date:** 2026-09-29
**Based on:** Stage-1 fact-check summary in the critic brief (k=3 on 3a63c56, fixes in 881762a); pass-1 report `docs/reviews/performance-review-2026-09-29-routers-de96617.md`; fix commit 028105b.

> ⚠️ **No code fact-check report provided for 33fdfd3.** This pass relies on the Stage-1 summary for 3a63c56/881762a and on measurements taken in this review. Runtime claims about the harness (description truncation, listing budget) are not independently verified.

"Performance" here means (a) the per-session context cost of skill descriptions and the always-loaded global paragraph, in every project once installed; (b) the cost of a router firing wrongly and pulling a large workflow into context; (c) the extra tool call per router fire; (d) test runtime. The diff has no request path, query or data structure.

## Data Flow and Hot Paths

- **Skill listing (hot: every session, every project).** Each `description` is in every session's skill list once `install.sh` copies `skills/` to `~/.claude/skills`.
- **Global paragraph (hot: every session on an installed host).** `**Every workflow is also a skill.** ...`, measured 622 bytes.
- **Router fire (warm: per matching task).** One Skill call returns the router body (1,056–1,423 bytes), then the agent reads the workflow "end to end" (7,596–68,867 bytes).
- **Test (cold: fast suite only).**

Measured this pass (`python3` over the frontmatter of every `skills/*/SKILL.md` on HEAD and on `main`; `wc -c`; `time`):

| Quantity | de96617 (pass 1) | 33fdfd3 (now) |
|---|---|---|
| `description` chars, all skills | 13,234 | 12,066 |
| added by the 8 routers | 3,239 (+32%) | 2,071 (+21% of `main`'s 9,995) |
| longest router description | 451 | 270 (task-decomposition) |
| "Not for X (use Y)" clause ends at char | 234–323+ (some past 250) | 152–210 (all inside 250) |
| `Triggers:` starts at char | 232–323 | 153–211 |
| global paragraph | ~450 | 622 bytes |
| router bodies | 737–951 bytes | 1,056–1,423 bytes |
| `workflow-routers.bats` wall time | 0.39 s | 0.58 s (6/6 ok, `time timeout 60 bats test/skills/workflow-routers.bats`) |

## Pass-1 findings: status

| Pass-1 # | Finding | Status at 33fdfd3 | Evidence |
|---|---|---|---|
| 1 (Medium) | RPI's broad triggers could pull a ~69 KB workflow into trivial edits; the exclusion lived only in the body | **Resolved.** The exclusion is now in the description, ahead of the triggers | `skills/research-plan-implement/SKILL.md:4`: `Not for one-line fixes, several unrelated asks (parallel-worktrees) or choosing among 3+ approaches (divergent-design). Triggers: "implement X", "add a feature", "fix this bug".` "build X", "refactor X", "change how X works" were dropped. `codebase-onboarding` dropped "where does X live" and says `Not for a single lookup.` |
| 2 (Low) | Per-session listing cost ~850 tokens | **Reduced** to ~520 tokens for descriptions (2,071 chars) + ~155 for the global paragraph | measurements above |
| 3 (Low) | Relative handoff path costs a failed Read outside this repo | **Mostly resolved**; residual below as Finding 2 | body now names `~/.claude/workflows/<name>.md` and `Never follow a same-named file that belongs to another project.` |
| 4 (Info) | Router hop +1 tool call | Unchanged, still negligible; bodies grew ~300 bytes each | Finding 3 |
| 5 (Info) | Triggers and "not this" clauses past char 250 | **Resolved for the clauses**; the tail of some trigger lists still passes 250 | Finding 1 |

## Findings

#### 1. The last trigger of six router descriptions sits past char 250

**Severity:** Informational
**Location:** `skills/{branch-strategy,codebase-onboarding,pr-prep,research-plan-implement,spike,task-decomposition,user-testing-workflow}/SKILL.md:4`
**Move:** Price the deployment environment
**Classification:** Micro / Hot path (every session's listing)
**Confidence:** Low (depends on whether any harness truncates at 250)
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** maintainer applying the Q-080 250-char convention

Evidence (measured lengths): branch-strategy 263, codebase-onboarding 264, pr-prep 252, research-plan-implement 268, spike 254, task-decomposition 270, user-testing-workflow 251 (parallel-worktrees 249). E.g. task-decomposition ends `... "migrate X, Y and Z", "cross-cutting change".`, where "cross-cutting change" starts past 250.

Every "Not for X (use Y)" clause ends by char 210 and every `Triggers:` list starts by char 211, so the precedence text that pass 1 was worried about is safe under a 250 cut. Only the final one or two quoted phrases could be dropped, and those are examples, not the routing rule. Fix commit 028105b says "both it and the triggers sit inside the first 250 characters", which is true of the clause and the start of the trigger list, not of the list's end.

**Recommendation:** None required. If the convention is meant literally, trim one trigger phrase from each of the seven.

#### 2. The bolded, first-named handoff path is still the relative one

**Severity:** Low
**Location:** handoff line of each router, e.g. `skills/spike/SKILL.md:19-21`
**Move:** Price the deployment environment
**Classification:** Micro (≤1 extra tool call) / Warm path (per router fire in other projects)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** agent executing the handoff outside claude-workflows

Evidence: `Read and follow **\`workflows/spike.md\`** end to end: the installed copy at` / `` `~/.claude/workflows/spike.md`, or this repo's own file when working inside `` / `claude-workflows. Never follow a same-named file that belongs to another project.`

The sentence now resolves the path correctly, and the never-follow line removes the wrong-file risk. What is left is salience: the bold path is the relative one, so an agent skimming may Read `workflows/spike.md` first, get file-not-found in another project, and then read the installed copy. That costs one round-trip per fire at most. The test pins the bolded relative form (`workflow-routers.bats:92`, `grep -qF "Read and follow **\`workflows/$name.md\`**"`), so swapping the order means changing the test too.

**Recommendation:** Accept as is. The fix is cosmetic and not worth another loop iteration.

#### 3. Router hop: +1 tool call and ~260–360 tokens per fire

**Severity:** Informational
**Location:** router bodies, e.g. `skills/research-plan-implement/SKILL.md:7-22`
**Move:** Count the hidden multiplications
**Classification:** Micro / Warm path
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** reviewer weighing router overhead

Evidence: router files measure 1,056–1,423 bytes (about 300 bytes more than at de96617, from the installed-path and never-follow lines). Each fire costs Skill → body → Read workflow, versus a single Read before. That is 2–14% of the smallest workflow (parallel-worktrees, 7,596 bytes) and about 2% of the largest (research-plan-implement, 68,867 bytes). `MAX_BODY_LINES=45` (`workflow-routers.bats:24`) still bounds it, and all routers are 22 lines.

**Recommendation:** None.

#### 4. Fixed per-session cost: ~2.7 KB (~675 tokens) in every installed project

**Severity:** Low
**Location:** 8 router descriptions + `global-instructions/CLAUDE.md` new paragraph
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (constant) / Hot path (every session)
**Confidence:** High on bytes, Medium on tokens (~4 chars/token estimate, no tokenizer)
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** maintainer weighing the listing budget against decision log row 66's Revisit trigger

Evidence: 2,071 description chars + 8 names (~170 chars) + 622-byte global paragraph ≈ 2,860 chars. Down from ~3,850 at de96617. It is paid in projects where `branch-strategy` (multi-PR integration) and `user-testing-workflow` rarely apply. This host is solo with no GitHub routing (user memory), which makes `branch-strategy`'s open-PR triggers mostly idle text here. The global paragraph repeats routing guidance that the decision-tree table right below it already holds, but it adds the first-match precedence rule the routers depend on, so it earns its place.

**Recommendation:** Accept. This is the intended trade and it is smaller than at pass 1. Row 66's artifact-count Revisit trigger is the right way to measure whether it pays off.

## Endorsements

- The pass-1 Medium is fixed where the cost was: RPI's exclusion is now in the description, where the agent reads it *before* paying for the Skill call and the ~69 KB read. [read: skills/research-plan-implement/SKILL.md:1-5]
- The precedence clauses ("Not for X (use Y)") on the colliding pairs (parallel-worktrees ↔ task-decomposition, spike ↔ RPI, pr-prep ↔ code-review, user-testing ↔ ui-visual-review) all end by char 210, which lowers the rate of mis-fires into large workflows. [read: the eight router descriptions, offsets measured by script]
- The contract test stays cheap: 0.58 s wall for 6 tests over ~10 small files, which fits `# @category fast`. The opt-out check adds one `awk` per workflow (10 workflows). [read: test/skills/workflow-routers.bats:1-137]
- Dropping `when:` from the routers removes a field that adds no routing value. [unverified — submitted as claim: the harness triggers on `description` only; repo source `test/skills/frontmatter-fields.bats` comment citing `guides/skill-format-audit.md` F1]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Last trigger phrase of seven descriptions sits past char 250 (the precedence clauses do not) | Informational | 7 router descriptions | Low |
| 2 | Bolded handoff path is still the relative one; ≤1 failed Read per fire outside this repo | Low | router handoff lines | Medium |
| 3 | Router hop: +1 tool call, ~260–360 tokens per fire | Informational | router bodies | High |
| 4 | Fixed per-session cost ~2.9 KB (~675 tokens), every installed project | Low | descriptions + global paragraph | High |

## Overall Assessment

The pass-1 fixes hold. The one Medium (a ~69 KB RPI read on trivial edits, because the exclusion lived only in the body) is resolved: the exclusion now sits in the description at char 91, and the broadest triggers are gone. The per-session listing cost fell from ~3.2k to ~2.1k added description characters. Every precedence clause now fits inside 250 characters. The router hop and test runtime stay negligible, bounded by the 45-line cap. Nothing new of Medium or higher turned up. What is left is Low/Informational and can be accepted without another iteration. No profiling is needed: whether the listing cost buys consistent workflow use is a question for row 66's artifact-count Revisit trigger, not for a benchmark.

## Goal-Alignment Note

- **Answered:** whether the pass-1 performance fixes hold (yes; Finding 1 resolved, others reduced); per-session context cost re-measured (descriptions, global paragraph); mis-fire exposure of the large workflows; extra tool call per fire; test runtime (0.58 s measured).
- **Out of scope:** whether trigger overlaps route correctly beyond their cost (API-consistency/architecture critics); correctness of router facts against workflows (Stage 1).
- **Escalate:** still unverifiable from the sandbox: whether any target harness truncates descriptions at 250 chars, and whether a total skill-listing budget exists. Token figures use ~4 chars/token.
