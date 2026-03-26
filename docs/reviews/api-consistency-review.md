# API Consistency Review

**Scope:** Branch feat/foreground-tests vs main
**Reviewed:** 2026-03-26 (fresh review, incorporating code fact-check report)

## Baseline Conventions

Conventions established by surveying 5 sibling workflows (divergent-design, spike, pr-prep, codebase-onboarding, task-decomposition) and 5 sibling skills (test-strategy, code-review, self-eval, code-fact-check, draft-review), plus decision records 001-006 and the decision log:

1. **Workflow structure**: `# Title` / `## When to use` / `## When to pivot` / `## Working documents` (if applicable) / `## Process` with numbered steps / `## When to skip or abbreviate` (optional) / `## Variant:` sections (optional). Some workflows include an italicized note referencing the orchestrated-review pattern (DD, pr-prep, codebase-onboarding, task-decomposition do; RPI and spike do not).
2. **RPI step headings** follow `### N. Name (essential/recommended) — description`. Sub-sections within steps use `####`.
3. **Plan bullet points** use `- **Name**: description` format with bold labels.
4. **Checkpoint pattern** has two variants: (a) soft/non-blocking checkpoints use "should not block progress" language with explicit fallback behavior ("proceed but flag"), (b) hard gates use "does not begin until" language with no fallback.
5. **Decision record structure**: `# NNN: Title` / `**Date:**` / `**Status:**` / `## Context` / `## Options Considered` / `## Decision` / `## Consequences` with `### Makes easier` and `### Makes harder` subsections.
6. **Decision log format**: `| # | Date | Decision | Context / Why | Full Record |` table. Numbers are sequential for full records but can have gaps in the lightweight log (e.g., entries 2-5 have full records but no lightweight log entries).
7. **Cross-reference style**: Workflows reference each other by step number and name, by document name, or by section heading. Skills reference RPI section names for integration points.
8. **Test level vocabulary**: RPI inline taxonomy uses unit / integration / characterization / property as the four primary levels. The test-strategy skill uses unit / integration / e2e / property / snapshot / contract as its full taxonomy.
9. **Terminology**: The RPI plan section is "Test specification" (bold label in bullet). The test-strategy skill's frontmatter uses "testing strategy" as a description of user intent, while its line 153 integration reference uses "test specification" to match RPI's section name.
10. **Commit message conventions**: `prefix: description (per plan-X step N)` format, with `test:` for test commits and `feat:` / `fix:` / `refactor:` for implementation commits.

## Findings

#### 1. Decision log numbering gap (1 to 6) is explained by existing convention but not self-documenting

**Severity:** Minor
**Location:** `docs/decisions/log.md:10`
**Move:** #1 (Establish baseline conventions)
**Confidence:** High

The decision log jumps from entry #1 to entry #6. Entries 2-5 exist as full decision records (`002-*.md` through `005-*.md`) but have no lightweight log entries. The log header explains: "Use this for one-line decisions where the context and rationale fit in a sentence or two." Since entries 2-5 warranted full records, omitting them from the lightweight log is consistent with its stated purpose. However, a reader seeing `| 1 | ... |` followed by `| 6 | ... |` might wonder whether entries were deleted. This is pre-existing behavior (the gap between 1 and 6 is not introduced by this branch for entries 2-5), but entry 6 is the first to create a dual record (both a lightweight log entry and a full record), which is a new pattern.

**Recommendation:** Consider adding a note to the log such as "Entries with full decision records are listed when the summary is independently useful; otherwise see `docs/decisions/NNN-*.md` directly." Low priority -- the numbering convention is self-consistent once you understand it.

---

#### 2. Skill frontmatter trigger phrase uses "testing strategy" while RPI uses "test specification"

**Severity:** Minor
**Location:** `skills/test-strategy.md:8-9`
**Move:** #2 (Check naming against the grain)
**Confidence:** Medium

The test-strategy skill's frontmatter description includes the trigger phrase "or when an RPI plan needs a testing strategy." Now that RPI uses "test specification" as the section name, this creates a mild terminology gap. The phrase describes user intent (a need for a strategy) rather than referencing a section name, so it is not technically incorrect. However, line 153 of the same file was updated to use "test specification" for the integration reference, creating an internal inconsistency within the skill file itself: line 9 says "testing strategy" while line 153 says "test specification."

The fact-check report does not flag this, but it is visible in the diff (only line 153 was changed; line 9 was not).

**Recommendation:** Update line 9 to "or when an RPI plan needs a test specification" for internal consistency within the skill file. The line 153 fix already established "test specification" as the correct term in this file.

---

#### 3. Test-first gate introduces a convention of committing known-failing tests

**Severity:** Informational
**Location:** `workflows/research-plan-implement.md:125`
**Move:** #3 (Trace the consumer contract)
**Confidence:** High

The test-first gate prescribes committing tests that "should fail -- they encode the behavior that doesn't exist yet." Step 6 ("Verify and loop") says "Run all project checks (lint, build, tests)." A reader following both instructions sequentially might wonder whether failing tests at the test-first gate violate the verification step. The inline text is clear enough ("These tests should fail") that this is not a contradiction, but consumers of the workflow (both humans and LLMs following the process) need to understand the temporal relationship: tests fail after step 5's test-first gate but should pass after step 5's implementation sub-section, before reaching step 6.

This is also consistent with pr-prep step 2 ("Verify CI passes locally. Run whatever checks the project has") which would only apply after implementation is complete.

**Recommendation:** No action needed. The inline explanation is sufficient, and the step ordering makes the temporal logic clear.

---

#### 4. Checkpoint pattern consistency is correct

**Severity:** Informational
**Location:** `workflows/research-plan-implement.md:127`
**Move:** #1 (Establish baseline conventions)
**Confidence:** High

The test review checkpoint at line 127 follows the soft/non-blocking pattern established by the research checkpoint at line 68. Both use: (a) explicit non-blocking language ("should not block progress indefinitely"), (b) a defined fallback ("proceed with implementation but flag that tests haven't been reviewed"), and (c) a recovery path. The fact-check report (Claim 9) independently verifies this analogy is accurate.

**Recommendation:** No action needed.

---

#### 5. Step heading format is preserved

**Severity:** Informational
**Location:** `workflows/research-plan-implement.md:121`
**Move:** #2 (Check naming against the grain)
**Confidence:** High

The heading `### 5. Implement (essential) -- tests first, then code` follows the established `### N. Name (essential/recommended) -- description` pattern. The sub-headings `#### Test-first gate` and `#### Implementation` use `####` consistently with other workflow sub-sections (e.g., `#### Stress-test pass` and `#### Decision` in divergent-design.md, `#### Session handoff` in RPI itself).

**Recommendation:** No action needed.

---

#### 6. Cross-references between RPI and test-strategy are bidirectional and consistent

**Severity:** Informational
**Location:** `workflows/research-plan-implement.md:95`, `skills/test-strategy.md:153`
**Move:** #3 (Trace the consumer contract), #7 (Look for asymmetry)
**Confidence:** High

RPI line 95 references the skill: "the `test-strategy` skill has a full taxonomy." The test-strategy skill line 153 references RPI: "the test specification section of the plan doc should follow this skill's structure." Both directions use the current "test specification" terminology. The fact-check report (Claims 11, 21) independently verifies both references.

**Recommendation:** No action needed.

---

#### 7. Taxonomy asymmetry is intentional and documented

**Severity:** Informational
**Location:** `workflows/research-plan-implement.md:89-95`
**Move:** #7 (Look for asymmetry)
**Confidence:** High

RPI defines 4 test levels inline (unit, integration, characterization, property) while the test-strategy skill defines 6 (unit, integration, e2e, property, snapshot, contract). The asymmetry is acknowledged at RPI line 95: "Other levels (e.g., end-to-end, snapshot, contract) are valid." This is a sound design choice: RPI provides lightweight inline guidance for the most common levels while pointing to the skill for the full taxonomy.

Note that the vocabularies differ slightly: RPI uses "characterization" (relevant to its refactoring variant) which the test-strategy skill does not list as a named type. The skill has "end-to-end" which RPI lists in its "other levels" acknowledgment. This bidirectional non-overlap is acceptable given the different contexts (planning guidance vs. analytical recommendation).

**Recommendation:** No action needed. The asymmetry serves each document's purpose.

---

#### 8. Decision record follows established structure

**Severity:** Informational
**Location:** `docs/decisions/006-foregrounding-tests.md`
**Move:** #1 (Establish baseline conventions)
**Confidence:** High

The decision record uses the standard structure: `# NNN: Title`, `**Date:**`, `**Status:**`, `## Context`, `## Options Considered`, `## Decision`, `## Consequences` with `### Makes easier` and `### Makes harder`. This matches all existing records (001-005). The Date and Status fields are present (the fact-check report notes these were added during the fix cycle).

**Recommendation:** No action needed.

---

#### 9. Stale line references in review documents

**Severity:** Minor
**Location:** `docs/reviews/security-review.md:25`, `docs/reviews/cowen-critique.md:76`, `docs/reviews/yglesias-critique.md:19`
**Move:** #3 (Trace the consumer contract)
**Confidence:** High

The code fact-check report (Claims 25, 26, 27) identifies several review documents with stale line number references:
- Security review references "line 103" for the hard gate; actual location is line 107.
- Cowen critique references "lines 95-97" for diagnostic expectations; the diagnostic expectations start at line 97 (line 95 is the cross-reference to test-strategy).
- Yglesias critique references "line 95" for diagnostic expectations; same issue.

These are review artifacts (not consumer-facing interfaces), so the impact is limited to readers trying to follow citations. However, since these review documents are committed and versioned, inaccurate line references reduce their usefulness as audit artifacts.

**Recommendation:** Update the stale line references in the three review documents. Low priority since review artifacts are not operationally consumed, but it improves the archival record.

---

#### 10. Performance review growth percentage is slightly off

**Severity:** Informational
**Location:** `docs/reviews/performance-review.md:12`
**Move:** #3 (Trace the consumer contract)
**Confidence:** High

The fact-check report (Claim 28) notes the performance review claims "+14%" growth when the actual is 16.8% (173 to 202 lines). This is a review artifact, not a consumer-facing interface, so the impact is negligible. The "roughly" qualifier makes the original claim defensible.

**Recommendation:** No action needed. The imprecision is within acceptable bounds for a review artifact.

## What Looks Good

- **Test specification table format** (`Test case | Expected behavior | Level | Diagnostic expectation`) is a clean, scannable structure that follows the codebase's convention of using tables for structured data (see DD's compatibility matrix and tradeoff matrix).
- **Escape clause** ("For simple features, this section can be brief") follows the established "When to skip or abbreviate" pattern, preventing the expanded section from becoming dead weight for trivial tasks.
- **Commit message convention** (`test: add tests for X (per plan-Y step N)`) is consistent with the existing implementation convention (`feat: add user model (per plan-inline-edit-api step 1)`).
- **Characterization test cross-reference** ("see also: Refactoring variant below") maintains the established cross-reference style within RPI.
- **Decision record Consequences section** uses Makes easier / Makes harder subsections, matching records 001-005.
- **PII/secrets caveat** (line 99) is a security-conscious addition appropriate for inline guidance.
- **Consumer references updated consistently**: The rename from "testing strategy" to "test specification" is carried through to `skills/test-strategy.md:153` and `docs/reviews/full-evaluation.md:211,215`.
- **Decision log entry** uses the `[006](006-foregrounding-tests.md)` link format, matching the documented convention.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Decision log numbering gap creates dual-record pattern | Minor | `docs/decisions/log.md:10` | High |
| 2 | Skill frontmatter "testing strategy" vs "test specification" internal inconsistency | Minor | `skills/test-strategy.md:9` | Medium |
| 3 | Test-first gate introduces failing-test commit convention | Informational | `workflows/research-plan-implement.md:125` | High |
| 4 | Checkpoint pattern correctly follows convention | Informational | `workflows/research-plan-implement.md:127` | High |
| 5 | Step heading format correctly preserved | Informational | `workflows/research-plan-implement.md:121` | High |
| 6 | Cross-references are bidirectional and consistent | Informational | `workflows/research-plan-implement.md:95`, `skills/test-strategy.md:153` | High |
| 7 | Taxonomy asymmetry is intentional and documented | Informational | `workflows/research-plan-implement.md:89-95` | High |
| 8 | Decision record follows established structure | Informational | `docs/decisions/006-foregrounding-tests.md` | High |
| 9 | Stale line references in review documents | Minor | `docs/reviews/security-review.md`, `cowen-critique.md`, `yglesias-critique.md` | High |
| 10 | Performance review growth percentage slightly off | Informational | `docs/reviews/performance-review.md:12` | High |

## Overall Assessment

The branch is in good shape for API consistency. The primary changes -- expanding the RPI test specification section and adding a test-first gate -- follow established codebase conventions for step headings, checkpoint patterns, plan bullet formatting, and cross-references. The decision record and log entry match the structure of their predecessors. The rename from "testing strategy" to "test specification" has been carried through to all active integration points (test-strategy skill line 153, full-evaluation lines 211/215). Two minor findings warrant attention: the internal terminology inconsistency in `skills/test-strategy.md` (line 9 says "testing strategy" while line 153 says "test specification") and stale line references in three review documents. Neither is breaking, and the frontmatter issue is borderline since it describes user intent rather than referencing a section name. No breaking changes, no inconsistent consumer contracts, no missing versioning considerations.
