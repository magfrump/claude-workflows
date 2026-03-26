# API Consistency Code Review

**Repository:** claude-workflows
**Scope:** Branch diff relative to main (`git diff main...HEAD`)
**Reviewed:** 2026-03-26

## Baseline Conventions

The workflow documents in this repo follow established conventions:

1. **Section naming in RPI**: Steps are numbered and titled with a pattern: `### N. Name (essential/recommended) — description`. Plan bullet points use bold names: `- **Name**: description`.
2. **Checkpoint pattern**: Soft checkpoints use the pattern "should not block progress... proceed but flag" (see research checkpoint at line 68). Hard gates use "does not begin until" language (see implementation gate at step 4).
3. **Decision record format**: Records follow a Context / Options Considered / Decision / Consequences structure with Makes easier / Makes harder subsections.
4. **Decision log format**: Table with columns `# | Date | Decision | Context / Why | Full Record`.
5. **Cross-references**: Workflow sections reference each other by name (e.g., "see also: Refactoring variant below").

## Findings

#### Test specification replaces testing strategy without migration note

**Severity:** Minor
**Location:** `workflows/research-plan-implement.md:83`
**Move:** #3 (Trace the consumer contract)
**Confidence:** Medium

The plan section's bullet point was renamed from `**Testing strategy**` to `**Test specification**`. Any existing plan documents in `docs/working/` that reference "testing strategy" (the old name) would now use terminology inconsistent with the current workflow. Additionally, other documents or CLAUDE.md files that reference "testing strategy" as an RPI concept may become stale. This is not a breaking change (existing plan docs still function), but the terminology shift could cause confusion.

**Recommendation:** This is minor — the rename is an improvement in clarity. If there are existing plan documents referencing "testing strategy," they will naturally be overwritten in future sessions. No immediate action needed, but worth noting the terminology change in a commit message or decision log entry.

---

#### Implementation step heading change maintains consistency

**Severity:** Informational
**Location:** `workflows/research-plan-implement.md:117`
**Move:** #2 (Check naming against the grain)
**Confidence:** High

The step 5 heading changed from `### 5. Implement (essential) — follow the plan` to `### 5. Implement (essential) — tests first, then code`. This follows the established `### N. Name (essential/recommended) — description` pattern. The new description accurately summarizes the changed behavior. The sub-headings (`#### Test-first gate` and `#### Implementation`) are new structural additions within step 5 that are consistent with how other workflow documents use `####` for sub-sections.

**Recommendation:** No action needed. This is well-done.

---

#### Checkpoint pattern consistency

**Severity:** Informational
**Location:** `workflows/research-plan-implement.md:123`
**Move:** #1 (Establish baseline conventions)
**Confidence:** High

The new test review checkpoint at line 123 follows the same pattern as the existing research checkpoint: soft gate, non-blocking, with explicit fallback behavior ("if the user doesn't respond promptly, proceed with implementation but flag that tests haven't been reviewed"). This is consistent with the established checkpoint convention in the workflow. The fact-check report confirmed this consistency (Claim 8: Verified).

**Recommendation:** No action needed. Good pattern adherence.

---

#### Decision record follows established format

**Severity:** Informational
**Location:** `docs/decisions/006-foregrounding-tests.md`
**Move:** #1 (Establish baseline conventions)
**Confidence:** High

The decision record follows the Context / Options Considered / Decision / Consequences format used by existing records (001-005). The Consequences section uses Makes easier / Makes harder subsections, consistent with the established pattern.

**Recommendation:** No action needed.

## What Looks Good

- The checkpoint pattern (soft, non-blocking, with fallback) is applied consistently to the new test review gate, matching the existing research checkpoint convention.
- The step heading format is preserved exactly.
- The decision record format matches all existing records.
- The decision log entry format is correct and the link works.
- The test level taxonomy (unit / integration / characterization / property) is internally consistent and maps to terminology already used in the refactoring variant ("characterization tests").

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Terminology rename (testing strategy -> test specification) | Minor | `workflows/research-plan-implement.md:83` | Medium |
| 2 | Implementation step heading follows convention | Informational | `workflows/research-plan-implement.md:117` | High |
| 3 | Checkpoint pattern is consistent | Informational | `workflows/research-plan-implement.md:123` | High |
| 4 | Decision record follows established format | Informational | `docs/decisions/006-foregrounding-tests.md` | High |

## Overall Assessment

This change is highly consistent with the codebase's established conventions. The section naming, checkpoint patterns, decision record format, and cross-reference style all match existing patterns. The only notable item is the terminology rename from "testing strategy" to "test specification," which is a minor naming evolution that improves clarity but could cause temporary inconsistency with any existing plan documents that reference the old term. Overall, the API consistency is strong.
