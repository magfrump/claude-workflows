# API Consistency Review

**Scope:** Branch feat/foreground-tests vs main
**Reviewed:** 2026-03-26

## Baseline Conventions

Conventions established by reading 5 sibling workflows (divergent-design, spike, pr-prep, codebase-onboarding, task-decomposition) and 5 sibling skills (test-strategy, code-review, self-eval, code-fact-check, draft-review), plus decision records 001-005 and the decision log:

1. **RPI step headings** follow `### N. Name (essential/recommended) — description`. Sub-sections within steps use `####`.
2. **Plan bullet points** use `- **Name**: description` format with bold labels.
3. **Checkpoint pattern** has two variants: (a) soft/non-blocking checkpoints use "should not block progress" language with explicit fallback ("proceed but flag"), (b) hard gates use "does not begin until" language with no fallback.
4. **Decision record structure**: `# NNN: Title` / `## Context` / `## Options Considered` / `## Decision` / `## Consequences` with `### Makes easier` and `### Makes harder` subsections.
5. **Decision log format**: `| # | Date | Decision | Context / Why | Full Record |` table. Entries only appear for decisions that also have a full record OR for lightweight decisions with no full record. Decisions 002-005 have full records but no log entries (the log was created after them).
6. **Cross-reference style**: Workflows reference each other by step number and name (e.g., "see RPI step 2"), by document name, or by section heading (e.g., "see also: Refactoring variant below").
7. **Test level vocabulary**: The refactoring variant already uses "characterization tests." The test-strategy skill uses unit / integration / e2e / property / snapshot / contract as its taxonomy.
8. **Skill-to-RPI integration references**: skills/test-strategy.md:153 references "the testing strategy section of the plan doc" as the RPI integration point.

## Findings

#### 1. Stale consumer reference: test-strategy skill references renamed RPI section

**Severity:** Inconsistent
**Location:** `skills/test-strategy.md:153`
**Move:** #3 (Trace the consumer contract)
**Confidence:** High

The test-strategy skill at line 153 says: "When used as part of RPI, the testing strategy section of the plan doc should follow this skill's structure." The RPI plan section has been renamed from "Testing strategy" to "Test specification." The skill now references a section name that no longer exists in RPI. This is a consumer contract break -- a user or agent following the test-strategy skill's instructions to integrate with RPI would look for a section that has been renamed.

The fact-check report (Claim 19) independently identified this as Stale.

**Recommendation:** Update `skills/test-strategy.md:153` to reference "test specification" instead of "testing strategy." Also consider whether the test-strategy skill's output structure should be explicitly aligned with the new test specification table format (test case / expected behavior / level / diagnostic expectation) since both now serve overlapping purposes.

---

#### 2. Stale consumer reference: full-evaluation.md references old RPI section name

**Severity:** Minor
**Location:** `docs/reviews/full-evaluation.md:211,215`
**Move:** #3 (Trace the consumer contract)
**Confidence:** High

The full-evaluation document references "RPI's testing strategy section" at lines 211 and 215. This document is a review artifact (less actively consumed than a skill), but it creates terminology inconsistency for anyone reading the evaluation to understand the current state of the skill ecosystem.

**Recommendation:** Update references in full-evaluation.md to say "test specification" instead of "testing strategy." Lower priority than Finding 1 since review artifacts are less frequently consumed than skills.

---

#### 3. Test level taxonomy asymmetry between RPI and test-strategy skill

**Severity:** Minor
**Location:** `workflows/research-plan-implement.md:89-93` vs `skills/test-strategy.md:71-93`
**Move:** #7 (Look for asymmetry)
**Confidence:** Medium

The new RPI test specification section defines four test levels: unit, integration, characterization, property. The test-strategy skill defines six: unit, integration, end-to-end, property-based, snapshot/golden, contract. The overlap is partial. RPI includes "characterization" (not in the skill); the skill includes e2e, snapshot, and contract (not in RPI).

This is not necessarily wrong -- RPI's inline taxonomy is meant to be lightweight guidance for the human designing test specs, while the test-strategy skill provides comprehensive analysis. But the asymmetry could confuse a user who uses both: the skill recommends a snapshot test, and then the user cannot express that level in the RPI plan table because it is not one of the four listed options.

**Recommendation:** Add a brief note in the RPI test specification section acknowledging that the four listed levels are the most common, not exhaustive, and that the test-strategy skill provides a complete taxonomy. Alternatively, add "e2e" and "snapshot" to the RPI list (the table already uses a free-text Level column, so this is informational guidance, not a schema constraint).

---

#### 4. Decision record missing Date and Status fields

**Severity:** Minor
**Location:** `docs/decisions/006-foregrounding-tests.md`
**Move:** #1 (Establish baseline conventions)
**Confidence:** High

Existing decision records include `**Date:**` and `**Status:**` fields after the title (see 005-validation-step-self-improvement.md lines 3-4: `**Date:** 2026-03-23` / `**Status:** Accepted (phases 1 and 3 implemented)`). Decision 006 omits both fields. This is a minor structural inconsistency -- the information is available from git history and the decision log, but the pattern break means a reader scanning decision records for status cannot do so uniformly.

**Recommendation:** Add `**Date:** 2026-03-26` and `**Status:** Accepted` after the title heading in 006.

---

#### 5. Decision record "step 3" reference is imprecise

**Severity:** Informational
**Location:** `docs/decisions/006-foregrounding-tests.md:30`
**Move:** #2 (Check naming against the grain)
**Confidence:** Medium

The decision says "Restructure the RPI Plan phase (step 3)." In RPI, step 3 is the entire "Plan" phase -- the testing section is one bullet point within it. A reader could interpret "step 3" as meaning the third sub-step within the plan. The fact-check report (Claim 5) flagged this as "Mostly accurate" for the same reason.

**Recommendation:** Rephrase to "Restructure the test specification within RPI step 3 (Plan)" for clarity. Low priority.

---

#### 6. Checkpoint pattern consistency is correct

**Severity:** Informational
**Location:** `workflows/research-plan-implement.md:122-123`
**Move:** #1 (Establish baseline conventions)
**Confidence:** High

The new test review checkpoint follows the soft/non-blocking pattern established by the research checkpoint at line 68: explicit non-blocking language ("should not block progress indefinitely"), fallback behavior ("proceed with implementation but flag"), and a recovery path ("revise the tests and update the plan's test specification"). This is well-aligned with the codebase convention.

**Recommendation:** No action needed.

---

#### 7. Step heading format is preserved

**Severity:** Informational
**Location:** `workflows/research-plan-implement.md:117`
**Move:** #2 (Check naming against the grain)
**Confidence:** High

The heading `### 5. Implement (essential) -- tests first, then code` follows the established pattern `### N. Name (essential/recommended) -- description`. The sub-headings `#### Test-first gate` and `#### Implementation` use `####` consistently with other workflow sub-sections (e.g., `#### Stress-test pass` in divergent-design.md, `#### Session handoff` in RPI itself).

**Recommendation:** No action needed.

---

#### 8. Review artifacts overwrite previous branch's content

**Severity:** Informational
**Location:** `docs/reviews/api-consistency-review.md`, `docs/reviews/code-fact-check-report.md`, `docs/reviews/code-review-rubric.md`, `docs/reviews/performance-review.md`, `docs/reviews/security-review.md`, `docs/reviews/self-eval-research-plan-implement.md`
**Move:** #9 (Check idempotency semantics)
**Confidence:** High

All six review artifacts were overwritten with content specific to this branch, replacing content from the previous branch (`feat/r1-skill-output-schema-validation`). The freshness metadata (Last verified, Relevant paths) was stripped from all files. This is consistent with the convention described in CLAUDE.md that review artifacts are "versioned alongside the content they review" and "re-runs overwrite prior artifacts." However, stripping the freshness metadata means these documents no longer participate in the doc-freshness tracking system. Since review artifacts are per-branch snapshots, this may be intentional (they are not long-lived documents), but it is a pattern difference from the previous versions of these files.

**Recommendation:** Clarify whether review artifacts should carry freshness metadata. If they are per-branch snapshots (overwritten each PR), freshness tracking adds no value and the metadata removal is correct. If they are meant to accumulate across branches, the metadata should be preserved. The current behavior (stripped) seems correct given the overwrite convention.

## What Looks Good

- The test specification table format (`Test case | Expected behavior | Level | Diagnostic expectation`) is a clean, scannable structure that follows the codebase's convention of using tables for structured data (see DD's compatibility matrix, tradeoff matrix, and stress-test move table).
- The "for simple features, this section can be brief" escape clause follows the pattern established by "When to skip or abbreviate" -- providing a lightweight path prevents the expanded section from becoming dead weight.
- The test-first gate's commit message convention (`test: add tests for X (per plan-Y step N)`) is consistent with the implementation commit convention (`feat: add user model (per plan-inline-edit-api step 1)`).
- The characterization test level explicitly cross-references the refactoring variant ("see also: Refactoring variant below"), maintaining the established cross-reference style.
- The decision record's Consequences section uses Makes easier / Makes harder subsections, matching all existing records (001-005).
- The decision log entry correctly uses the `[006](006-foregrounding-tests.md)` link format and the numbering gap (1 then 6) is consistent with the log's purpose (lightweight decisions 2-5 have full records and no log entries).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Stale consumer reference in test-strategy skill | Inconsistent | `skills/test-strategy.md:153` | High |
| 2 | Stale consumer reference in full-evaluation.md | Minor | `docs/reviews/full-evaluation.md:211,215` | High |
| 3 | Test level taxonomy asymmetry (RPI 4 levels vs skill 6 levels) | Minor | `workflows/research-plan-implement.md:89-93` | Medium |
| 4 | Decision record missing Date and Status fields | Minor | `docs/decisions/006-foregrounding-tests.md` | High |
| 5 | Imprecise "step 3" reference in decision record | Informational | `docs/decisions/006-foregrounding-tests.md:30` | Medium |
| 6 | Checkpoint pattern correctly follows convention | Informational | `workflows/research-plan-implement.md:122-123` | High |
| 7 | Step heading format correctly preserved | Informational | `workflows/research-plan-implement.md:117` | High |
| 8 | Review artifacts overwrite previous branch content (freshness metadata stripped) | Informational | Multiple review files | High |

## Overall Assessment

The core RPI changes (test specification section, test-first gate, checkpoint pattern) are well-aligned with established conventions. The structural patterns, naming conventions, and checkpoint semantics all follow the baselines set by sibling workflows and existing RPI sections. The most actionable finding is the stale consumer reference in `skills/test-strategy.md:153`, which explicitly references the old "testing strategy" section name as its RPI integration point -- this should be updated on this branch before merge. The decision record is structurally sound but missing the Date/Status fields present in records 001-005. The test level taxonomy asymmetry between RPI (4 levels) and the test-strategy skill (6 levels) is a minor inconsistency worth addressing to prevent user confusion. No breaking changes were found.
