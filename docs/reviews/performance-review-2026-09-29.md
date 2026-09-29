Commit: de96617

# Performance Review — feat/workflow-router-skills

**Scope:** `git diff main...HEAD` (8 router skills, `test/skills/workflow-routers.bats`, global-instructions paragraph, decision log row 66, README); review artifacts under `docs/reviews/` treated as context only
**Date:** 2026-09-29
**Based on:** Stage-1 code-fact-check summary in the critic brief (k=3 on 3a63c56, fixes in 881762a); `docs/reviews/code-fact-check-report-r{1,2,3}.md`

"Performance" for this diff means (a) per-session context cost of the skill listing and always-loaded global instructions, (b) per-invocation cost of the router hop before the workflow is read, (c) test runtime. There is no request path, query or data structure in the diff.

## Data Flow and Hot Paths

- **Hottest path: the skill listing.** Every skill's `description` is injected into every Claude Code session, in this repo and in every project once `devcontainer-config/install.sh` copies `skills/` into `~/.claude/skills` (`install.sh:135`, `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows ...)`). This is paid per session whether or not any router fires. Path temperature: hot (every session, every project).
- **Always-loaded instructions.** The new paragraph in `global-instructions/CLAUDE.md` is loaded in every session on an installed host. Hot, but small.
- **Router invocation.** When a router fires: one Skill call returns the router body (737–951 bytes measured), then one Read of the workflow (7,596–68,867 bytes measured, `wc -c workflows/<name>.md`). Warm: per task that matches a trigger, not per turn.
- **Test.** `test/skills/workflow-routers.bats` — 6 tests, file-existence checks and `awk`/`grep` over ~9 small files. Cold (CI/health-check only).

Measured sizes (this review, `python3` over frontmatter and `wc -c`):

| Quantity | Value |
|---|---|
| Total `description` chars, all 33 skills | 13,234 |
| `description` chars added by the 8 routers | 3,239 (+32% of the prior 9,995) |
| Router bodies | 737–951 bytes each |
| Workflows routed to | 7,596 (parallel-worktrees) – 68,867 (research-plan-implement) bytes |
| `workflow-routers.bats` wall time | 0.39 s (`time timeout 60 bats test/skills/workflow-routers.bats`, 6/6 ok) |

## Findings

#### 1. research-plan-implement's broad triggers can pull a ~69 KB workflow into trivial tasks

**Severity:** Medium
**Location:** `skills/research-plan-implement/SKILL.md:3-8`
**Move:** Count the hidden multiplications / what's the size of N
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Classification:** Macro (per-task multiplier on a large fixed read) / Warm path (per matching task)
**Legibility-target:** agent selecting a skill from the listing

Evidence (verbatim): `Triggers: "add a feature", "implement X", "fix this bug", "build X", "make X do Y", "change how X works", "refactor X".` and body line 27: `Read and follow **\`workflows/research-plan-implement.md\`** end to end`.

The router's exclusion for trivial edits ("Skip it only for trivial edits (a typo, a config value, a one-line fix whose cause is already known)", body lines 22-23) lives in the body, which the agent sees only after the Skill call has already been made. The description's first clause does say "non-trivial" and "more than one file", but the trigger list names phrasings ("fix this bug", "build X", "refactor X") that users also use for one-line changes. Each mis-fire costs one Skill call plus an "end to end" read of 68,867 bytes — roughly 17k tokens at ~4 chars/token — plus the procedure overhead (research/plan docs) if the agent follows it. Before this branch the same workflow could be reached from the global decision tree, so the delta is the change in firing rate, not the per-fire cost; that firing-rate change is the point of the PR, which is why the risk is on mis-fires rather than fires. The same shape, smaller, applies to `pr-prep` ("ship it", "wrap this up"; 44,652-byte workflow) and `codebase-onboarding` ("where does X live"; 54,996 bytes).

**Recommendation:** Move the trivial-edit exclusion into the description ahead of the trigger list (e.g. "Not for a one-line fix whose cause is known"), mirroring how `pr-prep` and `task-decomposition` already put their "not this" clause in the description. Consider dropping "where does X live" from `codebase-onboarding`, which is a single lookup, not an onboarding.

#### 2. Every session in every project pays ~850 tokens more for the listing

**Severity:** Low
**Location:** `skills/{branch-strategy,codebase-onboarding,parallel-worktrees,pr-prep,research-plan-implement,spike,task-decomposition,user-testing-workflow}/SKILL.md:3-8`
**Move:** Find the work that moved to the wrong place
**Confidence:** High (on the size), Medium (on the token conversion)
**Baseline:** no baseline available — flagged as speculative
**Classification:** Micro (fixed per-session constant) / Hot path (every session)
**Legibility-target:** repo maintainer weighing listing budget

Evidence: 3,239 description chars added (measured above) plus the eight names, ≈3,400 chars ≈ ~850 tokens per session at ~4 chars/token. The global paragraph adds another ~450 chars (~110 tokens) on installed hosts: `**Every workflow is also a skill.** Each \`workflows/<name>.md\` ships a router skill ...`.

The cost is paid in projects where most of these workflows never apply (e.g. `user-testing-workflow` and `branch-strategy` in a solo repo — the user's memory records "No GitHub routing — solo dev", which makes `branch-strategy`'s open-PR triggers mostly dead weight on this host). The token cost is likely cache-read priced after the first turn, so the money cost is small; the real cost is listing attention (the user's own framing: "Attention is the binding budget"), and some routing text now appears twice per session, once in the global decision tree and once in the descriptions. This is the intended trade and is modest; it is filed so the constant is on record.

**Recommendation:** Accept, but record the measured +3,239 chars in decision log row 66 so a later cycle can price it against the Revisit trigger. If trimming is wanted, `codebase-onboarding` (451) and `task-decomposition` (441) are the longest and can drop their mid-description procedure summaries without losing triggers.

#### 3. Relative handoff path costs one failed Read outside this repo

**Severity:** Low
**Location:** every router, handoff line (e.g. `skills/spike/SKILL.md:26-27`)
**Move:** Price the deployment environment
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Classification:** Micro (one extra tool call) / Warm path (per router fire, other projects only)
**Legibility-target:** agent executing the handoff in a non-claude-workflows project

Evidence: `Read and follow **\`workflows/spike.md\`** end to end (installed copy:
\`~/.claude/workflows/spike.md\`).` The bolded, first-named path does not exist in other projects; only the parenthetical one does. An agent that reads the bolded path first gets a file-not-found and retries — one wasted tool round-trip per fire. The parenthetical mitigates it, so this is not a correctness problem. The test pins the relative form (`workflow-routers.bats:90`), so changing it needs a test change.

**Recommendation:** Optional: phrase it as "`~/.claude/workflows/spike.md` (in the claude-workflows repo: `workflows/spike.md`)", or keep as is and accept one occasional failed Read. Not worth a loop iteration on its own.

#### 4. Router hop adds one tool call and ~200–240 tokens per workflow use

**Severity:** Informational
**Location:** router bodies, e.g. `skills/pr-prep/SKILL.md:12-31`
**Move:** Count the hidden multiplications
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Classification:** Micro / Warm
**Legibility-target:** reviewer weighing router overhead

Evidence: bodies measure 737–951 bytes; each fire is Skill → body → Read workflow, versus a single Read before. That is ~1–1.5% on top of the workflow read itself (7.6–69 KB). Negligible; the body-length cap in the test (`MAX_BODY_LINES=45`, `workflow-routers.bats:20`) keeps it that way.

**Recommendation:** None.

#### 5. Descriptions put triggers after char ~230, past the repo's own 250-char front-load rule

**Severity:** Informational
**Location:** all 8 router descriptions
**Move:** Price the deployment environment
**Confidence:** Low (depends on harness truncation behavior)
**Baseline:** no baseline available — flagged as speculative
**Classification:** Micro / Hot
**Legibility-target:** agent matching triggers from a possibly truncated listing

Evidence: measured `Triggers:` offsets 232 (spike) to 323 (task-decomposition); pr-prep's "not this" clause ("code-review alone for a review only") starts at char 234 and task-decomposition's ("Not for several unrelated tasks") at 246, both ending past 250. `guides/skill-format-audit.md:198` records as done: `every "not this" line ends by char 250`. In this session's own listing, 400+-char descriptions were shown untruncated, so the 250 limit may not currently apply; if it does on some harness, the eight routers pay the listing cost for text the model never sees, including the disambiguation clauses. Mostly a routing concern for the API-consistency/fact-check critics; noted here because it decides whether the ~850 tokens in Finding 2 buy anything.

**Recommendation:** Either front-load the "not this" clauses within 250 chars as the audit row requires, or update the audit row if the harness no longer truncates.

## Endorsements

- The contract test is cheap: 0.39 s wall for 6 tests, no subprocess per router beyond `awk`/`grep`/`wc`, safe to keep in the fast category (`# @category fast`, line 2). [read: test/skills/workflow-routers.bats:1-123]
- `MAX_BODY_LINES=45` bounds the per-fire router cost structurally; a router that grows toward restating its workflow fails the test. [read: test/skills/workflow-routers.bats:18-20,111-123]
- The `when:` fields add no per-session listing cost because the loader ignores them and triggers on `description` only. [unverified — submitted as claim; source is the repo's own `test/skills/frontmatter-fields.bats:4-5` comment citing `guides/skill-format-audit.md` F1]
- Claim for fact-check: Claude Code applies a total character budget to the combined skill listing, and at ~13.2k chars of repo descriptions plus plugin/built-in skills this host may be near it, which could drop skills from the listing. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | RPI broad triggers pull a ~69 KB workflow into trivial tasks; exclusion lives only in the body | Medium | `skills/research-plan-implement/SKILL.md:3-8` | Medium |
| 2 | +3,239 description chars (~850 tokens) per session, every project | Low | 8 router descriptions | High |
| 3 | Relative handoff path → one failed Read outside this repo | Low | router handoff lines | Medium |
| 4 | Router hop: +1 tool call, ~200–240 tokens per fire | Informational | router bodies | High |
| 5 | Triggers/"not this" clauses sit past char 250 | Informational | 8 router descriptions | Low |

## Overall Assessment

The performance posture is sound: the fixed per-session cost (~850 tokens, +32% of the repo's skill-listing text) and the per-fire router hop (~1% of the workflow read) are modest and bounded by the body-length test, and the test itself runs in 0.39 s. The one cost worth fixing before merge is Finding 1: the routers raise the firing rate by design, so the expensive failure mode is a mis-fire, and research-plan-implement — the largest workflow at 68,867 bytes — keeps its trivial-edit exclusion only in the body, where it arrives after the cost is paid. Moving that clause into the description is a one-line fix in place. No profiling is needed; the decision log's Revisit trigger (artifact counts over three dev cycles) is the right measurement for whether the listing cost buys anything.

## Goal-Alignment Note

- **Answered:** per-session context cost (measured chars, estimated tokens), per-invocation router overhead, mis-fire cost on the largest workflows, relative-path extra tool call, test runtime (measured).
- **Out of scope:** whether the trigger overlaps route correctly (API-consistency / fact-check critics); correctness of router facts against workflows (Stage 1 covered).
- **Escalate:** two runtime claims I could not verify from the repo — whether the loader truncates descriptions at 250 chars on the target harness, and whether a total skill-listing budget exists that 33+ skills approach. Token counts use a ~4 chars/token estimate, not a tokenizer.
