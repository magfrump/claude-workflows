# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** Branch feat/foreground-tests vs main
**Checked:** 2026-03-26
**Total claims checked:** 21
**Summary:** 14 verified, 3 mostly accurate, 1 stale, 0 incorrect, 3 unverifiable

---

## Claim 1: "The RPI workflow mentions 'testing strategy' as a one-line plan section"

**Location:** `docs/decisions/006-foregrounding-tests.md:5`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The main branch version of `workflows/research-plan-implement.md` at line 83 contains: `- **Testing strategy**: How to verify the implementation works. Specific test cases, not "add tests."` This is indeed a single bullet point (one line) within the plan section.

**Evidence:** `workflows/research-plan-implement.md:83` (main branch)

---

## Claim 2: "'characterization tests first' in the refactoring variant"

**Location:** `docs/decisions/006-foregrounding-tests.md:5`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The main branch RPI file contains `- **Characterization tests first**: If existing coverage is insufficient, the plan's first steps should add tests that lock in current behavior before any structural changes begin.` in the Refactoring variant section at line 168.

**Evidence:** `workflows/research-plan-implement.md:168` (main branch)

---

## Claim 3: "neither gives tests a primary role in the human-LLM collaboration loop"

**Location:** `docs/decisions/006-foregrounding-tests.md:5`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

In the main branch RPI, testing appears only as a verification concern: one line in the plan section, characterization tests as a safety net in the refactoring variant, and "run tests after every step" in implementation. None of these position tests as a design artifact or human-LLM interface.

**Evidence:** `workflows/research-plan-implement.md:83,164,168,172` (main branch)

---

## Claim 4: "13 approaches were generated via divergent design"

**Location:** `docs/decisions/006-foregrounding-tests.md:15`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low

Only 6 approaches are listed in the document (including "do nothing"). The remaining 7 from the divergent design process are described as pruned but not enumerated. No working document in `docs/working/` preserves the full divergent design output for cross-reference.

**Evidence:** `docs/decisions/006-foregrounding-tests.md:15-22` (only 6 options listed)

---

## Claim 5: "Restructure the RPI Plan phase (step 3)"

**Location:** `docs/decisions/006-foregrounding-tests.md:30`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High

The testing content is indeed within step 3 ("Plan") of RPI. Saying "Plan phase (step 3)" is accurate; the parenthetical in the decision record reads "Restructure the RPI Plan phase (step 3)" which correctly identifies step 3 as the Plan phase. The phrasing is clear enough in context.

**Evidence:** `workflows/research-plan-implement.md:72-99` (step 3 is the Plan phase; testing is a bullet point within it)

---

## Claim 6: "Combine approaches 1 + 4 + 5"

**Location:** `docs/decisions/006-foregrounding-tests.md:26`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The decision claims to combine: (1) test-first plan step, (4) test taxonomy guide, and (5) test review checkpoint. The implemented changes in RPI show: the test specification section replaces the one-liner (approach 1), inline taxonomy guidance for unit/integration/characterization/property (approach 4), and a test-first gate with human checkpoint before implementation (approach 5). All three are present.

**Evidence:** `workflows/research-plan-implement.md:83-97` (approaches 1+4), `workflows/research-plan-implement.md:119-125` (approach 5)

---

## Claim 7: Decision log entry "#6" links to `006-foregrounding-tests.md`

**Location:** `docs/decisions/log.md:10`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The link `[006](006-foregrounding-tests.md)` is a valid relative link. The file `docs/decisions/006-foregrounding-tests.md` exists. The decision log jumps from #1 to #6; entries 2-5 are full records that appropriately do not appear in the lightweight log.

**Evidence:** `docs/decisions/log.md:10`, `docs/decisions/006-foregrounding-tests.md` (file exists), `docs/decisions/002-005` (all exist as full records)

---

## Claim 8: "Tests are a design artifact, not a verification afterthought"

**Location:** `workflows/research-plan-implement.md:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The restructured RPI implements this: the test specification section in step 3 asks the human to specify test cases during planning with structured fields, and step 5 adds a test-first gate where tests are written before feature code. Tests are positioned as a planning activity, not an afterthought.

**Evidence:** `workflows/research-plan-implement.md:83-97` (test specification in plan), `workflows/research-plan-implement.md:117-127` (test-first gate)

---

## Claim 9: "Like the research checkpoint, this should not block progress indefinitely"

**Location:** `workflows/research-plan-implement.md:123`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The research checkpoint at line 68 states: "this checkpoint should not block progress. Claude should proceed to the plan step immediately after producing the research doc." The test review checkpoint at line 123 uses the same pattern: "this should not block progress indefinitely; if the user doesn't respond promptly, proceed with implementation but flag that tests haven't been reviewed." The analogy is accurate.

**Evidence:** `workflows/research-plan-implement.md:68` (research checkpoint), `workflows/research-plan-implement.md:123` (test review checkpoint)

---

## Claim 10: "see also: Refactoring variant below"

**Location:** `workflows/research-plan-implement.md:92`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The characterization test level description references "Refactoring variant below." The Refactoring variant section exists at line 182 and includes characterization tests guidance.

**Evidence:** `workflows/research-plan-implement.md:92` (reference), `workflows/research-plan-implement.md:182-198` (Refactoring variant section)

---

## Claim 11: "Commit the tests separately: `test: add tests for X (per plan-Y step N)`"

**Location:** `workflows/research-plan-implement.md:121`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

This is a prescriptive instruction, not a factual claim about existing behavior. It defines a commit message format for the test-first gate. The format is consistent with the existing commit message pattern at line 129: `feat: add user model (per plan-inline-edit-api step 1)`. Both use the conventional commit prefix + plan reference pattern.

**Evidence:** `workflows/research-plan-implement.md:121,129` (consistent commit message patterns)

---

## Claim 12: "The test specification section adds approximately 15 lines to the plan step"

**Location:** `docs/reviews/performance-review.md:22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The diff shows the plan section grew from 1 line (`- **Testing strategy**: ...`) to 16 lines (lines 83-97 in the new version). The claim of "approximately 15 lines" is accurate.

**Evidence:** `git diff main...HEAD -- workflows/research-plan-implement.md` (plan section diff)

---

## Claim 13: "the test-first gate adds approximately 10 lines to the implementation step"

**Location:** `docs/reviews/performance-review.md:22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The diff shows the implementation step gained: a new heading, the test-first gate section, and an "Implementation" sub-heading. Counting the added lines in that section: lines 117-127 replace the old line 100, adding roughly 10 net lines. The claim is accurate.

**Evidence:** `git diff main...HEAD -- workflows/research-plan-implement.md` (implementation section diff)

---

## Claim 14: "The RPI document grows from roughly 175 lines to 200 lines"

**Location:** `docs/reviews/performance-review.md:22`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The main branch RPI has 173 lines; the current branch has 198 lines. The claim of "roughly 175 to 200" is close but slightly rounds up the original (173 vs 175) and slightly rounds up the new (198 vs 200). Both are within reasonable rounding.

**Evidence:** `wc -l` on both versions: main=173, branch=198

---

## Claim 15: "A template is available at `templates/gitattributes-snippet.txt` in this repo"

**Location:** `workflows/research-plan-implement.md:35`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `templates/gitattributes-snippet.txt` exists in the repository.

**Evidence:** File existence confirmed via `test -f templates/gitattributes-snippet.txt`

---

## Claim 16: "See `guides/doc-freshness.md` for the freshness tracking heuristic"

**Location:** `workflows/research-plan-implement.md:27`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `guides/doc-freshness.md` exists in the repository.

**Evidence:** File existence confirmed via `test -f guides/doc-freshness.md`

---

## Claim 17: "invoke the Divergent Design workflow (`divergent-design.md`)"

**Location:** `workflows/research-plan-implement.md:61`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `workflows/divergent-design.md` exists in the repository.

**Evidence:** File existence confirmed via `test -f workflows/divergent-design.md`

---

## Claim 18: "The fact-check report confirmed this consistency (Claim 8: Verified)"

**Location:** `docs/reviews/api-consistency-review.md:52`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium

This is a cross-reference to the previous version of the fact-check report. The previous report's Claim 8 was about the test review checkpoint pattern consistency and was indeed Verified. However, this new fact-check report replaces the previous one, so the specific claim numbering is no longer stable. The substance of the cross-reference is accurate.

**Evidence:** `docs/reviews/code-fact-check-report.md:102-111` (previous version, Claim 8 was about the checkpoint pattern)

---

## Claim 19: "skills/test-strategy.md" references "testing strategy" as RPI terminology

**Location:** `skills/test-strategy.md:153` (not in branch diff, but references changed code)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High

The test-strategy skill at line 153 says: "When used as part of RPI, the testing strategy section of the plan doc should follow this skill's structure." The RPI plan section has been renamed from "Testing strategy" to "Test specification." The skill now references a section name that no longer exists. Similarly, `docs/reviews/full-evaluation.md:211,215` references "RPI's testing strategy section" which is now "test specification."

**Evidence:** `skills/test-strategy.md:153` (references "testing strategy"), `workflows/research-plan-implement.md:83` (now "Test specification")

---

## Claim 20: "The `test/hooks/log-usage.bats` and `test/scripts/skill-usage-report.bats` reference RPI only in the context of usage tracking"

**Location:** `docs/reviews/self-eval-research-plan-implement.md:15`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Low

Both files exist, but I did not read their contents to verify the specific claim about what context they reference RPI in. The claim is plausible given the file names but would require reading the files to fully verify.

**Evidence:** Both files confirmed to exist

---

## Claim 21: "Git history shows 16+ commits directly referencing RPI"

**Location:** `docs/reviews/self-eval-research-plan-implement.md:15`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium

A grep for "RPI" and "research-plan-implement" in git log found 24 matching commits across all branches. The claim of "16+" is likely accurate but the exact methodology (what counts as "directly referencing") is unclear. The count exceeds 16 by any reasonable interpretation.

**Evidence:** `git log --all --oneline --grep="RPI\|research-plan-implement"` returns 24 results

---

## Claims Requiring Attention

### Stale
- **Claim 19** (`skills/test-strategy.md:153`): References "testing strategy" as the RPI section name, but this has been renamed to "test specification." The `docs/reviews/full-evaluation.md:211,215` also references the old name. These files were not changed on the branch but now contain stale terminology.

### Mostly Accurate
- **Claim 5** (`docs/decisions/006-foregrounding-tests.md:30`): "Restructure the RPI Plan phase (step 3)" is directionally correct but could be read as ambiguous about whether "step 3" means the Plan phase or a sub-step within it.
- **Claim 14** (`docs/reviews/performance-review.md:22`): "roughly 175 to 200 lines" is close but the actual numbers are 173 to 198.
- **Claim 18** (`docs/reviews/api-consistency-review.md:52`): Cross-references the previous fact-check report's Claim 8; the substance is correct but the claim numbering is no longer stable since the report has been rewritten.

### Unverifiable
- **Claim 4** (`docs/decisions/006-foregrounding-tests.md:15`): "13 approaches were generated via divergent design" -- only 6 are listed; no working document preserves the full set.
- **Claim 20** (`docs/reviews/self-eval-research-plan-implement.md:15`): Claim about test files referencing RPI only for usage tracking was not fully verified by reading those files.
- **Claim 21** (`docs/reviews/self-eval-research-plan-implement.md:15`): "16+ commits directly referencing RPI" -- the count exceeds 16 but exact methodology is unclear.
