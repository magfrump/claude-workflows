# Performance Code Review

> **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

**Scope:** fd66df8~1..HEAD (10 commits, 21 files changed, +1680/-12 lines)
**Date:** 2026-03-20

---

## Data Flow and Hot Paths

This is a workflow/skills repository: all files are markdown that get loaded into AI agent context windows at invocation time. There is no runtime code, database, or request pipeline. The "hot path" is context window consumption: every token in a skill file is loaded into a model's context when that skill is invoked, and context window capacity is the primary scarce resource.

The performance-relevant operations in this diff are:
1. **Skill loading** -- skills are read into context when invoked (standalone or via orchestrator)
2. **Orchestrator dispatch** -- draft-review and matrix-analysis spawn sub-agents, each of which receives a copy of skill instructions + input content
3. **Cross-file reading** -- skills instruct agents to read surrounding codebase context beyond the diff

Expected call frequencies: each skill is invoked 1-N times per review session. Orchestrators multiply this: draft-review can spawn 1 fact-checker + N critics, each receiving full skill text + full draft. Matrix-analysis spawns one agent per criterion.

---

## Findings

#### 1. Duplicated "Using the Code Fact-Check Report" section across three code-review critics

**Impact:** Medium
**Location:** `skills/security-reviewer.md:46-65`, `skills/performance-reviewer.md:46-65`, `skills/api-consistency-reviewer.md:54-73`
**Move:** Count the hidden multiplications
**Confidence:** High

The security-reviewer, performance-reviewer, and api-consistency-reviewer each contain a near-identical ~20-line "Using the Code Fact-Check Report" section (including the warning block for when no report is provided). When a future code-review orchestrator dispatches all three in parallel, this duplicated text is loaded into three separate context windows. More critically, any future edit to this shared protocol must be applied in three places.

The same pattern exists for the "Scoping" sections (all three default to `git diff main...HEAD` with similar instructions) and the "How to Structure the Critique" output format sections (each has the same Finding template structure: title, severity/impact, location, move, confidence, recommendation). Together, these repeated sections account for approximately 80-100 lines of near-identical text per skill, or 160-200 duplicated lines across the three.

**Recommendation:** Extract the shared fact-check integration protocol, scoping instructions, and finding output template into a shared pattern file under `patterns/` (e.g., `patterns/code-review-critic.md`). Each skill can reference it and override where domain-specific behavior differs. This would save ~150 tokens per skill invocation and eliminate the three-way maintenance burden.

---

#### 2. Duplicated "Using the Fact-Check Report" section across prose critics

**Impact:** Low
**Location:** `skills/cowen-critique.md:34-59`, `skills/yglesias-critique.md:36-61`
**Move:** Count the hidden multiplications
**Confidence:** High

The same pattern appears in the prose critics: cowen-critique and yglesias-critique each have a ~25-line "Using the Fact-Check Report" section with identical structure (reference findings, build on ambiguity, focus on cognitive moves, emit warning if missing). When draft-review dispatches both, this text is duplicated in two sub-agent contexts. The duplication is smaller here (two copies vs three) but follows the same structural pattern.

**Recommendation:** Same approach -- extract into a shared pattern. Lower priority than Finding 1 because there are only two prose critics currently.

---

#### 3. Orchestrator copies full skill text into every sub-agent prompt

**Impact:** High
**Location:** `skills/draft-review.md:96-98`, `skills/draft-review.md:141-148`, `skills/matrix-analysis.md:110-148`
**Move:** Find the work that moved to the wrong place
**Confidence:** High

Both orchestrators (draft-review and matrix-analysis) instruct the orchestrating agent to "read the full contents of [skill].md" and "paste those contents directly into the Task tool prompt." This means the full text of each critic skill (134-255 lines each) is copied into every sub-agent prompt alongside the full draft/input content.

For a draft-review with fact-check + 2 critics: the orchestrator loads ~320 lines of its own instructions, then copies ~134 lines (fact-check) + ~238 lines (cowen) + ~255 lines (yglesias) into sub-agent prompts, plus the full draft text three times. If the draft is 2000 tokens, total context consumed across all agents is roughly: 320 (orchestrator) + 3 * (200 + 2000) = ~6920 lines of skill+content. The draft text triplication is unavoidable (sub-agents need it), but the skill text is the variable cost.

For matrix-analysis with 5 criteria: the orchestrator spawns 5 sub-agents, each receiving the full item context. If each item description is 500 tokens and there are 4 items, that is 5 * 2000 = 10,000 tokens of duplicated item context alone.

This is architecturally correct (sub-agents cannot read the filesystem), but it is the single largest context multiplier in the system.

**Recommendation:** This is a known constraint of the sub-agent architecture, not a bug. However, two mitigations are worth considering: (a) add guidance to orchestrators about summarizing or trimming skill instructions before passing to sub-agents (e.g., strip the YAML frontmatter, output location section, and tone section -- the sub-agent only needs the cognitive moves and output format); (b) for matrix-analysis, note that item descriptions should be kept concise because they are duplicated N times where N is the number of criteria.

---

#### 4. Scoping instructions encourage reading "enough surrounding context" without bounds

**Impact:** Medium
**Location:** `skills/security-reviewer.md:42-44`, `skills/performance-reviewer.md:42-45`, `skills/api-consistency-reviewer.md:49-52`
**Move:** Ask "what's the size of N?"
**Confidence:** Medium

All three code-review critics instruct the agent to "read enough surrounding context to understand [trust boundaries / call frequency / existing conventions]." The security reviewer says "a diff alone is rarely sufficient." The API consistency reviewer says "read 3-5 sibling endpoints." These are correct for review quality but provide no upper bound on how much context to read.

On a large codebase, an agent following these instructions could read thousands of lines of surrounding code before beginning the actual review, consuming significant context budget on file reads rather than analysis. The api-consistency-reviewer is the most aggressive: "read 3-5 sibling endpoints, adjacent modules, and existing tests to establish the baseline" could easily consume 500-1500 lines of context on surrounding code.

**Recommendation:** Add a context budget guideline to each scoping section. For example: "Limit surrounding context reads to ~500 lines total. If more context is needed, prioritize call sites and interfaces over implementations. If you cannot establish the baseline within this budget, note the gap rather than reading the entire module."

---

#### 5. matrix-analysis output template duplicates the matrix in two formats

**Impact:** Low
**Location:** `skills/matrix-analysis.md:164-267`
**Move:** Trace the memory lifecycle
**Confidence:** High

Matrix-analysis produces two deliverables: a chat synthesis (with a compact matrix table) and a matrix document (with the same matrix plus detailed evaluations per criterion). The Deliverable 2 template (lines 203-267) includes both a summary matrix table and a detailed evaluation section that repeats every rating and rationale from the subagents.

For a 4-item x 5-criteria matrix, the document includes: one summary table (20 cells with ratings + rationales), five detailed criterion tables (each with 4 rows of ratings + rationales), plus tradeoff analysis and recommendations. The detailed evaluations are essentially the raw subagent outputs reorganized. This means the same information exists three times: in sub-agent output (consumed by orchestrator), in the chat synthesis, and in the document.

The document format is the primary artifact for decision-tracking, so some redundancy is justified. But the template encourages copying subagent rationales verbatim into both the summary table cells and the detailed evaluation tables, doubling the output size.

**Recommendation:** In the summary matrix, use ratings only (++/+/-) without inline rationales. Reserve rationales for the detailed evaluation section only. This halves the document size without losing information.

---

#### 6. draft-review's Stage 2 creates a sequential dependency on Stage 1 with optional gate

**Impact:** Medium
**Location:** `skills/draft-review.md:109-128`
**Move:** Find the work that moved to the wrong place
**Confidence:** Medium

Draft-review enforces a strict sequential pipeline: fact-check must complete before critics can begin. The fact-check gate (lines 109-128) adds an optional human checkpoint between stages. This means the minimum latency for a full review is: fact-check duration + (optional human wait) + max(critic durations) + synthesis.

The sequential dependency is intentional (critics receive fact-check results as input), but the actual dependency is soft. Critic cognitive moves are largely independent of fact-check findings -- the fact-check report is supplementary context, not prerequisite input. The "Using the Fact-Check Report" sections in all critics explicitly handle the "no report provided" case, meaning critics can operate without it.

For users who want faster results and are willing to accept reviews without cross-referencing, the enforced sequencing adds latency. The fact-check gate compounds this: if a user is away, the pipeline stalls at the gate waiting for human input.

**Recommendation:** Consider documenting a "parallel mode" option where fact-check and critics run simultaneously, with the synthesis step noting that cross-referencing was not performed. This is lower quality but faster. The current `--no-gate` flag only skips the human checkpoint, not the sequential dependency itself.

---

#### 7. CLAUDE.md content is duplicated between project file and global user file

**Impact:** Informational
**Location:** `CLAUDE.md` (project root)
**Move:** Count the hidden multiplications
**Confidence:** High

The project's `CLAUDE.md` is identical to the user's global `~/.claude/CLAUDE.md`. When Claude Code loads a project, it reads both the global and project CLAUDE.md files. If both are loaded, the same instructions consume context twice. This is 86 lines / ~1200 tokens of duplication in every session.

**Recommendation:** The project CLAUDE.md should contain only project-specific instructions (or be empty if there are none), deferring shared instructions to the global file. Alternatively, if the project is intended to be portable (usable by other developers who may not have the global file), document this intent so the duplication is deliberate.

---

#### 8. user-testing-workflow is 345 lines with appendices that rarely apply to AI agent tasks

**Impact:** Low
**Location:** `workflows/user-testing-workflow.md`
**Move:** Find the work that moved to the wrong place
**Confidence:** Low

At 345 lines, user-testing-workflow is the longest file in the repository. It includes three appendices (SUS questionnaire, moderator traps, remote/async adaptation) totaling ~100 lines. These appendices contain reference material (the SUS scoring table, the moderator trap table) that is useful when designing a specific test but consumes context on every invocation of the workflow, including invocations that only need the planning or analysis phases.

This is a lower-confidence finding because the workflow is likely invoked infrequently and the 100-line overhead is modest in absolute terms.

**Recommendation:** Consider splitting appendices into a separate reference file (e.g., `guides/usability-testing-reference.md`) that the workflow references but does not include inline. The agent can read it when needed (during session design) rather than loading it unconditionally.

---

## What Looks Good

**Scoping defaults to branch diff.** All code-review critics and code-fact-check default to `git diff main...HEAD`, which limits the input to changed code. This is the right default -- it prevents unbounded context consumption from reviewing entire repositories.

**Orchestrators enforce checkpoint discipline.** Both draft-review and matrix-analysis have explicit checkpoint gates ("Wait for ALL agents to return. Count the results."). This prevents the synthesis step from running on incomplete data, which would waste the synthesis context budget on partial results.

**Skills declare soft dependencies via `requires:`.** The code-review critics declare code-fact-check as an optional input, with graceful degradation (warning + proceed) when it is absent. This allows standalone invocation without the overhead of the full pipeline.

**Decision docs are concise.** The three decision records (001, 002, 003) range from 40-51 lines each. They are compact enough to load as context without significant overhead, which is important since CLAUDE.md instructs agents to check `docs/decisions/` for prior art.

**Parallel dispatch pattern.** Both orchestrators dispatch all same-stage agents simultaneously rather than sequentially. This is the correct approach for context efficiency: it does not reduce total tokens consumed, but it minimizes wall-clock time.

---

## Summary Table

| # | Finding | Impact | Location | Confidence |
|---|---------|--------|----------|------------|
| 1 | Duplicated fact-check integration section across 3 code critics | Medium | `skills/{security,performance,api-consistency}-reviewer.md` | High |
| 2 | Duplicated fact-check integration section across 2 prose critics | Low | `skills/{cowen,yglesias}-critique.md` | High |
| 3 | Full skill text copied into every sub-agent prompt | High | `skills/draft-review.md`, `skills/matrix-analysis.md` | High |
| 4 | Unbounded "read surrounding context" instructions | Medium | `skills/{security,performance,api-consistency}-reviewer.md` | Medium |
| 5 | Matrix document duplicates ratings in summary and detail sections | Low | `skills/matrix-analysis.md:164-267` | High |
| 6 | Sequential fact-check-then-critics dependency is enforced even when optional | Medium | `skills/draft-review.md:109-128` | Medium |
| 7 | Project CLAUDE.md duplicates global CLAUDE.md | Informational | `CLAUDE.md` | High |
| 8 | User testing workflow appendices consume context unconditionally | Low | `workflows/user-testing-workflow.md` | Low |

---

## Overall Assessment

The primary performance concern in this diff is context window efficiency, which is the appropriate scarce resource for a workflow/skills repository. The most impactful finding is the architectural requirement that orchestrators copy full skill text into sub-agent prompts (Finding 3) -- this is inherent to the sub-agent model and cannot be eliminated, but can be mitigated by trimming non-essential sections before dispatch. The most actionable finding is the duplicated text across code-review critics (Finding 1) -- extracting shared patterns into a common file would reduce both context consumption and maintenance burden immediately. The unbounded context reads (Finding 4) are the highest risk for unpredictable performance: on a large codebase, an agent following the current scoping instructions could consume its entire context budget on file reads before beginning analysis.

No profiling or benchmarking is needed -- the findings are structural and visible from the code. The recommended priority order is: Finding 4 (add context bounds to scoping), Finding 1 (extract shared critic patterns), Finding 3 (add guidance on trimming skill text for sub-agents), then the remaining findings as convenience improvements.
