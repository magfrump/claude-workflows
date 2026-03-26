# Code Review Rubric

**Scope:** feat/foreground-tests vs main | **Reviewed:** 2026-03-26 | **Status: 🟡 CONDITIONAL PASS** — 1 amber item awaiting resolution or justification

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items unresolved.

| # | Finding | Domain | Location | Status |
|---|---|---|---|---|
| R1 | Stale consumer reference: `test-strategy.md` references "testing strategy" but RPI renamed it to "test specification." **Escalated from 🟡**: independently flagged by both API consistency review and code fact-check. | API Consistency + Fact-Check | `skills/test-strategy.md:153` | ✅ Resolved — updated to "test specification" |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they stand. Each must carry a resolution or author note.

| # | Finding | Domain | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | Stale reference in `full-evaluation.md` to old "testing strategy" name | API Consistency | API consistency review | ✅ Resolved — updated both references to "test specification" | — |
| A2 | Test level taxonomy asymmetry: RPI lists 4 levels, test-strategy skill lists 6 | API Consistency | API consistency review | ✅ Resolved — added note that the four levels are not exhaustive and cross-referenced the test-strategy skill for the complete taxonomy | — |
| A3 | Decision record 006 missing Date and Status fields | API Consistency | API consistency review | ✅ Resolved — added `**Date:** 2026-03-26` and `**Status:** Accepted` | — |
| A4 | Review artifact overwrite removes freshness metadata from 6 files. **Escalated from 🟢**: 3 core critics flagged the same observation. | Security + Performance + API Consistency | Cross-critic convergence | 🟡 Open | Reviews are per-branch snapshots that are overwritten each PR cycle. Freshness metadata adds no value for ephemeral artifacts. The overwrite convention is documented in CLAUDE.md ("re-runs overwrite prior artifacts"). No change needed. |
| A5 | Cross-reference to previous fact-check report's "Claim 8" no longer stable | Fact-Check | Code fact-check | ✅ Resolved — the api-consistency-review.md was rewritten by this review cycle and no longer contains the stale reference | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement opportunities. Not required to pass review.

| # | Finding | Source |
|---|---|---|
| C1 | "Test-first gate" terminology implies hard gate but behavior is soft checkpoint. Consider renaming to "Test-first checkpoint" for consistency with the research checkpoint pattern. | Security review |
| C2 | ~~Diagnostic expectations guidance could encourage logging sensitive data.~~ Addressed: added PII/secrets redaction caveat to diagnostic expectations guidance. | Security review |
| C3 | RPI document growth trajectory: 173 to 198 lines (+14%). At current pace, consider extracting reference material if RPI crosses ~250 lines. | Performance review |
| C4 | Additional human checkpoint adds wall-clock cost; mitigated by non-blocking fallback. Monitor whether the gate is routinely bypassed in practice. | Performance review |
| C5 | "Step 3" reference in decision record is imprecise — could be read as third sub-step within the plan rather than the Plan phase itself. | API consistency review |
| C6 | Fact-check: three unverifiable claims (approach count, test file RPI references, git commit count). Low priority. | Code fact-check |

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.

| Item | Verdict | Source |
|---|---|---|
| Test-first gate follows the soft/non-blocking checkpoint pattern established by the research checkpoint | ✅ Confirmed | API consistency + Fact-check |
| Step heading format `### 5. Implement (essential) — tests first, then code` follows established pattern | ✅ Confirmed | API consistency review |
| Commit message convention (`test: add tests for X`) is consistent with existing pattern | ✅ Confirmed | API consistency + Fact-check |
| Hard gate at step 4 (plan approval) is preserved and unweakened | ✅ Confirmed | Security review |
| "Combine approaches 1 + 4 + 5" — all three approaches are implemented in the RPI changes | ✅ Confirmed | Fact-check |
| Decision record Consequences section uses Makes easier / Makes harder format matching records 001-005 | ✅ Confirmed | API consistency review |
| Prior state claims ("one-line testing strategy", "characterization tests first in refactoring variant") are accurate | ✅ Confirmed | Both fact-checks |
| "Simple features can be brief" escape hatch is appropriately scoped | ✅ Confirmed | Security + Performance reviews |
| No executable code, no secrets, no destructive instructions introduced | ✅ Confirmed | Security review |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
