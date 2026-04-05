# Performance Review

**Scope:** Branch feat/foreground-tests vs main (15 files, +807 / -593 lines)
**Date:** 2026-03-26
**Fact-check input:** Code fact-check report (28 claims checked; 19 verified, 4 mostly accurate, 1 stale, 4 unverifiable)

## Data Flow and Hot Paths

This branch modifies only markdown files. There is no executable code. The performance-relevant "hot paths" are:

1. **RPI workflow loading** (`workflows/research-plan-implement.md`): This is the default workflow loaded at the start of most development sessions per CLAUDE.md. Every token in this file is consumed on every RPI invocation. Growth here has a direct multiplicative effect: (number of sessions) x (tokens added). The file grew from 173 to 202 lines (+29 lines, +16.8%). The fact-check report (Claim 28) notes the existing performance review's "+14%" figure was calculated against an intermediate version; the actual growth is 16.8%.

2. **Plan documents produced by RPI**: The new test specification section causes plan documents to be larger. Plan docs are loaded by the implementation session, potentially re-loaded on context rebuild, and referenced during each implementation step. A plan with N test cases adds roughly 2N lines (table header + one row per test).

3. **Review artifacts** (`docs/reviews/*.md`): These are consumed once per review cycle, not on hot paths. The large line-count delta (+807/-593) is dominated by review artifact rewrites, which are one-time costs with no recurring performance impact.

4. **Skills file** (`skills/test-strategy.md`): A 2-word change ("testing strategy" -> "test specification"). No size impact.

## Findings

### 1. RPI document growth trajectory

**Severity:** Low
**Location:** `workflows/research-plan-implement.md` (entire file, 173 -> 202 lines)
**Move:** #2 (Ask "what's the size of N?") and #1 (Count the hidden multiplications)
**Confidence:** High

The RPI file grew by 29 lines (16.8%). At 202 lines of markdown, this is roughly 2,000-2,500 tokens -- under 1% of a 200K context window. The absolute cost per session is trivial.

The relevant concern is the growth trend, not the current size. RPI has accumulated: refactoring variant, DD integration, session handoff, freshness tracking, size estimates, pivot guidance, and now test foregrounding. Each addition was individually small. The self-eval on this branch already asks "has the workflow grown too heavy?" -- which is the right question.

The new content breaks into two categories with different extraction potential:
- **Prescriptive process** (test-first gate, checkpoint pattern): ~10 lines. This must remain inline because it changes agent behavior during implementation.
- **Reference material** (test level taxonomy, diagnostic expectations guidance, PII caveat): ~15 lines. This could be extracted to a referenced sub-document without changing agent behavior, since it is consulted during planning, not continuously during implementation.

**Recommendation:** No action needed at current size. If RPI crosses ~250 lines, extract the reference material (test level taxonomy + diagnostic expectations) into `guides/test-specification.md` and replace with a cross-reference. The test-strategy skill cross-reference at line 95 already establishes this pattern.

### 2. Additional human checkpoint adds wall-clock latency

**Severity:** Low
**Location:** `workflows/research-plan-implement.md:123-129`
**Move:** #3 (Find work that moved to the wrong place)
**Confidence:** Medium

The test-first gate introduces a human review round-trip between plan approval and implementation. Worst case: human reviews tests, gives feedback, agent revises, human re-reviews. This could add 10-30 minutes for complex features.

The non-blocking fallback ("if the user doesn't respond promptly, proceed with implementation but flag that tests haven't been reviewed") prevents this from becoming a hard bottleneck. In `/away` mode, the agent will proceed autonomously. In `/active` mode, the checkpoint is proportional -- reviewing 5-10 test stubs is faster than reviewing the eventual implementation, and catching specification mismatches here saves rework later.

**Recommendation:** No action needed. The non-blocking design is correct. The fact-check report (Claim 9) confirmed the fallback language mirrors the research checkpoint at line 68, which has established the pattern.

### 3. Plan document size scales with test case count

**Severity:** Informational
**Location:** `workflows/research-plan-implement.md:83-101`
**Move:** #1 (Count the hidden multiplications)
**Confidence:** Medium

A feature with N test cases adds roughly (N+2) lines to the plan document (table header, separator, N rows). For a typical feature (3-8 test cases), this adds 5-10 lines. Plan documents are loaded by the implementation session and may be re-read during context rebuilds.

The "for simple features, this section can be brief" escape hatch at line 101 is the key scaling control. Without it, every plan would pay the table overhead regardless of complexity. With it, simple features use prose (2-3 lines) while complex features use the table format. This is the correct adaptive scaling behavior.

The fact-check report (Claim 13) confirmed the test specification section adds approximately 15 lines to the *RPI template itself*, not to each plan document. Each plan document's growth depends on the number of test cases specified.

**Recommendation:** No action needed. The escape hatch provides appropriate scaling.

### 4. Diagnostic output guidance: theoretical verbosity risk

**Severity:** Informational
**Location:** `workflows/research-plan-implement.md:97-99`
**Move:** #4 (Trace the memory lifecycle -- adapted to output volume)
**Confidence:** Low

The diagnostic expectations guidance encourages "expected vs. actual values, relevant state at the point of failure, and enough context to diagnose without re-running." For data-heavy test scenarios (large JSON payloads, database state dumps), this could produce verbose test output that consumes CI logs or terminal buffer.

This is speculative -- the guidance is reasonable for typical development. The PII caveat at line 99 provides a natural brake on one class of overly-verbose output (sensitive data). The guidance does not say "dump everything"; it says "enough context to diagnose," which is appropriately bounded.

**Recommendation:** No action needed. If a specific project encounters test output volume problems, that project can constrain the guidance locally.

### 5. Review artifact full rewrites: one-time cost, no recurring impact

**Severity:** Informational
**Location:** `docs/reviews/*.md` (11 files rewritten)
**Move:** #6 (Identify the serialization tax)
**Confidence:** High

The branch rewrites 11 review artifacts, accounting for the majority of the +807/-593 line delta. This is a one-time cost per review cycle. Review artifacts are not on any hot path -- they are generated once, read by humans during review, and overwritten on the next branch.

The freshness metadata (`Last verified`, `Relevant paths`) was stripped from all review files. The fact-check report (Claim 15, Claim 27) notes some line-number references in review artifacts are now stale relative to the current file. This is a correctness issue (covered by the fact-check), not a performance issue.

**Recommendation:** No action needed for performance. The API consistency review's Finding 8 already addresses the freshness metadata question as a process design choice.

## What Looks Good

- **Non-blocking checkpoint design**: The test-first gate mirrors the research checkpoint's non-blocking pattern, preventing a new process step from becoming a latency bottleneck. The fallback behavior is explicit and unambiguous.
- **Adaptive complexity scaling**: The "for simple features, this section can be brief" escape hatch prevents the structured test specification from imposing overhead on trivial tasks. This is the single most important performance-aware design choice in the branch.
- **Inline taxonomy at appropriate size**: The test level taxonomy (~8 lines) is inline rather than in a separate file. At this size, inlining avoids a file-load operation that would cost more than the tokens saved. The cross-reference to the test-strategy skill (line 95) provides the escape hatch to a richer taxonomy without bloating the inline content.
- **Minimal change to the skill file**: The test-strategy.md change is a 2-word rename, adding zero tokens to the skill's load cost.
- **Structured specification reduces interpretation cost**: The test specification table replaces a vague one-liner with structured fields. While this adds ~15 lines to the RPI template, it likely *reduces* total token consumption during implementation by eliminating the agent's need to reason about what "testing strategy" means for each feature.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | RPI document growth trajectory (173 -> 202, +16.8%) | Low | `workflows/research-plan-implement.md` | High |
| 2 | Additional human checkpoint wall-clock latency | Low | `workflows/research-plan-implement.md:123-129` | Medium |
| 3 | Plan document size scales with test case count | Informational | `workflows/research-plan-implement.md:83-101` | Medium |
| 4 | Diagnostic guidance theoretical verbosity risk | Informational | `workflows/research-plan-implement.md:97-99` | Low |
| 5 | Review artifact full rewrites (one-time cost) | Informational | `docs/reviews/*.md` | High |

## Overall Assessment

This branch has no meaningful performance concerns at current scale. All changes are to markdown documentation with no executable code. The primary cost vector -- RPI document token consumption -- increased by 16.8% (29 lines), adding roughly 200-300 tokens per session against context windows of 200K+. The new test-first checkpoint is correctly designed as non-blocking with an explicit fallback, preventing it from becoming a process bottleneck. The structured test specification likely provides a net token reduction during implementation by replacing ambiguous guidance with actionable structure, even though it increases the template size. The only item worth monitoring is the RPI growth trajectory: the file has accumulated multiple feature additions and would benefit from extracting reference material into sub-documents if it approaches ~250 lines in future changes. No changes are needed for this branch to merge.
