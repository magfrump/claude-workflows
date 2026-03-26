# Performance Review

**Scope:** Branch feat/foreground-tests vs main
**Reviewed:** 2026-03-26

## Data Flow and Hot Paths

All changes in this branch are to markdown files: one workflow document (`workflows/research-plan-implement.md`), one decision record, one decision log entry, and six review artifacts. There is no executable code. The "hot path" analogy maps to LLM token consumption: every time an agent loads the RPI workflow as instructions, the full document is tokenized and consumes context window budget. The RPI workflow is loaded at the start of most development sessions (it is the default workflow per CLAUDE.md), making it the highest-frequency document in the repo.

## Findings

### 1. RPI document growth: 173 to 198 lines (+14%)

**Severity:** Low
**Location:** `workflows/research-plan-implement.md:83-127`
**Move:** #2 (Ask "what's the size of N?") and #9 (Check asymptotic behavior)
**Confidence:** High

The test specification section replaces a single line (`- **Testing strategy**: ...`) with 15 lines of structured guidance (table template, test level taxonomy, diagnostic expectations explanation). The test-first gate adds 10 lines to the implementation step. Total growth: 25 net lines, from 173 to 198.

**Current impact:** Negligible. At 198 lines of markdown, the full RPI document is roughly 2,000-2,500 tokens -- well under 1% of a typical context window (200K+). The absolute cost of this growth is trivially small.

**Trend concern:** This is the more relevant question. The RPI document has accumulated features across multiple commits: refactoring variant, DD integration, session handoff docs, freshness tracking guidance, size estimates, pivot guidance, and now test foregrounding. Each addition was individually justified and individually small. The self-eval (in this same branch) explicitly asks "Has the workflow grown too heavy?" -- which is the right question to be asking. The current size is fine; the growth *trajectory* is worth monitoring.

**Recommendation:** No action needed now. If RPI crosses ~250 lines in future changes, consider extracting the test level taxonomy and diagnostic expectations guidance into a referenced sub-document (e.g., `guides/test-specification.md`). These sections are reference material that agents could load on demand rather than consuming on every RPI invocation.

### 2. Process overhead: additional human checkpoint in implementation

**Severity:** Low
**Location:** `workflows/research-plan-implement.md:119-125`
**Move:** #3 (Find work moved to the wrong place)
**Confidence:** Medium

The test-first gate introduces a new human checkpoint between plan approval and implementation. In the worst case, this adds a full round-trip of latency (human reviews tests, provides feedback, agent revises, human re-reviews). The workflow mitigates this with "should not block progress indefinitely; if the user doesn't respond promptly, proceed with implementation but flag that tests haven't been reviewed."

This is not a token/compute cost -- it is a wall-clock cost on the development loop. For async workflows (the `/away` mode described in CLAUDE.md), the non-blocking fallback means the agent can continue without waiting. For synchronous sessions, the checkpoint adds ~5-15 minutes of review time for complex features, which is proportional to the value of catching specification mismatches before implementation.

**Recommendation:** No action needed. The non-blocking fallback is the correct design. The self-eval already flags the question of whether this checkpoint is actually followed in practice.

### 3. Plan document size increase for downstream consumers

**Severity:** Informational
**Location:** `workflows/research-plan-implement.md:83-97`
**Move:** #1 (Count hidden multiplications)
**Confidence:** Medium

The structured test specification (table with 4 columns per test case) will make plan documents larger. A feature with 8 test cases would add roughly 15-20 lines to the plan doc. Plan docs are loaded by the implementation session and potentially re-read when context is rebuilt. However, plan docs are already variable-size (a 10-step plan with size estimates and risks is already substantial), and the test specification replaces what would have been a vague one-liner with structured content that the agent actually needs during implementation.

The "for simple features, this section can be brief" escape hatch is the key mitigation -- it prevents the table format from being applied to trivial tasks.

**Recommendation:** No action needed. The structured format replaces unstructured content that the agent would have needed to infer anyway. Net information cost is near zero; the structure just makes it explicit.

### 4. Review artifact churn: 6 review files rewritten

**Severity:** Informational
**Location:** `docs/reviews/*.md` (6 files)
**Move:** #6 (Identify serialization tax)
**Confidence:** High

Six review artifacts were rewritten to reflect the current branch's changes (replacing content from the previous branch `feat/r1-skill-output-schema-validation`). Each rewrite stripped the `Last verified` / `Relevant paths` frontmatter. This is a one-time cost per review cycle, not a recurring performance concern. However, the loss of freshness tracking metadata means these review documents cannot be efficiently checked for staleness using the doc-freshness heuristic described in CLAUDE.md.

**Recommendation:** Consider whether review artifacts should retain freshness metadata. If reviews are always regenerated per-branch (current pattern), the metadata is unnecessary. If reviews are meant to persist and be checked for staleness, the metadata should be restored. This is a process design question, not a performance issue.

## What Looks Good

- The non-blocking fallback on the test review checkpoint prevents the new gate from becoming a bottleneck in async workflows. This is the same pattern used by the research checkpoint, which has been validated by prior usage.
- The "for simple features, this section can be brief" escape hatch in the test specification section prevents the structured format from imposing overhead on trivial tasks. This scales appropriately: simple features get brief specs, complex features get the table.
- The test level taxonomy is inline rather than in a separate referenced document. At current size (~8 lines), this is the right call -- a separate document would add a file-load operation for minimal content savings. This tradeoff should be revisited if the taxonomy grows.
- The test specification replaces ambiguous one-line guidance with structured fields that the agent can act on directly during implementation. This reduces the "interpretation tax" -- the agent spending tokens reasoning about what "testing strategy" means for this specific feature.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | RPI document growth trajectory | Low | `workflows/research-plan-implement.md` (173 -> 198 lines) | High |
| 2 | Additional human checkpoint in implementation | Low | `workflows/research-plan-implement.md:119-125` | Medium |
| 3 | Plan document size increase | Informational | `workflows/research-plan-implement.md:83-97` | Medium |
| 4 | Review artifact churn / lost freshness metadata | Informational | `docs/reviews/*.md` | High |

## Overall Assessment

This branch has no meaningful performance concerns at current scale. The RPI document grows by 14% (25 lines), which adds roughly 200-300 tokens to every session that loads it -- negligible against modern context windows. The new human checkpoint is correctly designed as non-blocking with an explicit fallback. The structured test specification increases plan document size proportionally to feature complexity, which is the right scaling behavior. The only finding worth tracking is the growth trajectory: RPI has accumulated six feature additions across its history, and if this pace continues, a future refactoring to extract reference material into sub-documents would be warranted. No changes needed for merge.
