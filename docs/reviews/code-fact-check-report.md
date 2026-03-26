# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** Branch feat/foreground-tests vs main
**Checked:** 2026-03-26
**Total claims checked:** 28
**Summary:** 19 verified, 4 mostly accurate, 1 stale, 0 incorrect, 4 unverifiable

---

## Claim 1: "The RPI workflow mentions 'testing strategy' as a one-line plan section"

**Location:** `docs/decisions/006-foregrounding-tests.md:8`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The main branch version of `workflows/research-plan-implement.md` at line 83 contains: `- **Testing strategy**: How to verify the implementation works. Specific test cases, not "add tests."` This is a single bullet point (one line) within the plan section.

**Evidence:** `workflows/research-plan-implement.md:83` (main branch)

---

## Claim 2: "'characterization tests first' in the refactoring variant"

**Location:** `docs/decisions/006-foregrounding-tests.md:8`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The main branch RPI file contains `- **Characterization tests first**: If existing coverage is insufficient, the plan's first steps should add tests that lock in current behavior before any structural changes begin.` at line 168 in the Refactoring variant section.

**Evidence:** `workflows/research-plan-implement.md:168` (main branch)

---

## Claim 3: "neither gives tests a primary role in the human-LLM collaboration loop"

**Location:** `docs/decisions/006-foregrounding-tests.md:8`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

In the main branch RPI, testing appears only as: one bullet in the plan section (line 83), characterization tests as a safety net in the refactoring variant (lines 164, 168), and "run tests after every step" in implementation (line 172). None position tests as a design artifact or human-LLM interface.

**Evidence:** `workflows/research-plan-implement.md:83,164,168,172` (main branch)

---

## Claim 4: "Over a dozen approaches were generated via divergent design"

**Location:** `docs/decisions/006-foregrounding-tests.md:18`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low

Only 6 approaches are listed in the document (including "do nothing"). The remaining approaches are described as explored "in conversation" but no artifact preserves the full list. The phrase "over a dozen" cannot be confirmed or refuted.

**Evidence:** `docs/decisions/006-foregrounding-tests.md:18-25` (only 6 options listed)

---

## Claim 5: "Restructure the RPI Plan phase (step 3)"

**Location:** `docs/decisions/006-foregrounding-tests.md:33`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

Step 3 in RPI is indeed the Plan phase (heading at line 72: `### 3. Plan (essential) -- specify the implementation steps`). The test specification content is within this step (lines 83-101). The parenthetical "step 3" correctly identifies the Plan phase.

**Evidence:** `workflows/research-plan-implement.md:72` (step 3 heading), `workflows/research-plan-implement.md:83-101` (test specification within step 3)

---

## Claim 6: "Combine approaches 1 + 4 + 5, plus diagnostic guidance"

**Location:** `docs/decisions/006-foregrounding-tests.md:29`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The decision claims to combine: (1) test-first plan step, (4) test taxonomy guide, (5) test review checkpoint, plus diagnostic guidance. In RPI: the test specification section replaces the one-liner (approach 1, lines 83-101), inline taxonomy guidance for four test levels (approach 4, lines 89-95), a test-first gate with human checkpoint before implementation (approach 5, lines 123-129), and diagnostic expectations guidance (lines 97-99). All four are present.

**Evidence:** `workflows/research-plan-implement.md:83-101` (approaches 1+4+diagnostic), `workflows/research-plan-implement.md:123-129` (approach 5)

---

## Claim 7: Decision log entry "#6" links to `006-foregrounding-tests.md`

**Location:** `docs/decisions/log.md:10`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The link `[006](006-foregrounding-tests.md)` is a valid relative link. The file `docs/decisions/006-foregrounding-tests.md` exists. Decisions 002-005 exist as full records, consistent with the log noting they do not appear in the lightweight log.

**Evidence:** `docs/decisions/log.md:10`, all four files `docs/decisions/002-005*.md` confirmed to exist

---

## Claim 8: "Tests are a design artifact, not a verification afterthought"

**Location:** `workflows/research-plan-implement.md:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The restructured RPI implements this: the test specification section in step 3 asks the human to specify test cases during planning with structured fields (lines 83-101), and step 5 adds a test-first gate where tests are written before feature code (lines 121-129). Tests are positioned as a planning activity.

**Evidence:** `workflows/research-plan-implement.md:83-101` (test specification in plan), `workflows/research-plan-implement.md:121-129` (test-first gate)

---

## Claim 9: "Like the research checkpoint, this should not block progress indefinitely"

**Location:** `workflows/research-plan-implement.md:127`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The research checkpoint at line 68 states: "this checkpoint should not block progress." The test review checkpoint at line 127 uses the same pattern: "this should not block progress indefinitely; if the user doesn't respond promptly, proceed with implementation but flag that tests haven't been reviewed." The analogy is accurate.

**Evidence:** `workflows/research-plan-implement.md:68` (research checkpoint), `workflows/research-plan-implement.md:127` (test review checkpoint)

---

## Claim 10: "see also: Refactoring variant below"

**Location:** `workflows/research-plan-implement.md:92`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The characterization test level description references "Refactoring variant below." The Refactoring variant section exists at line 186.

**Evidence:** `workflows/research-plan-implement.md:92` (reference), `workflows/research-plan-implement.md:186` (Refactoring variant heading)

---

## Claim 11: "the `test-strategy` skill has a full taxonomy"

**Location:** `workflows/research-plan-implement.md:95`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The test-strategy skill at `skills/test-strategy.md:69-93` defines six test types: unit, integration, end-to-end, property-based, snapshot/golden, and contract. This is a superset of the four listed inline in RPI, making "full taxonomy" an accurate characterization.

**Evidence:** `skills/test-strategy.md:69-93` (six test types defined)

---

## Claim 12: "Commit the tests separately: `test: add tests for X (per plan-Y step N)`"

**Location:** `workflows/research-plan-implement.md:125`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

This is a prescriptive instruction defining a commit message format. The format is consistent with the existing commit convention at line 133: `feat: add user model (per plan-inline-edit-api step 1)`. Both use conventional commit prefix + plan reference.

**Evidence:** `workflows/research-plan-implement.md:125,133` (consistent commit message patterns)

---

## Claim 13: "The test specification section adds approximately 15 lines to the plan step"

**Location:** `docs/reviews/performance-review.md:19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The diff shows the plan section grew from 1 line (`- **Testing strategy**: ...`) to approximately 19 lines (lines 83-101 in the new version, accounting for blank lines). Calling this "approximately 15 lines" of net content is accurate.

**Evidence:** `git diff main...HEAD -- workflows/research-plan-implement.md` (plan section diff)

---

## Claim 14: "the test-first gate adds approximately 10 lines to the implementation step"

**Location:** `docs/reviews/performance-review.md:19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The diff shows the implementation step gained: a new heading (line 121), the test-first gate section (lines 123-129), an "Implementation" sub-heading (line 131), totaling approximately 12 net lines including blanks. "Approximately 10 lines" is accurate.

**Evidence:** `git diff main...HEAD -- workflows/research-plan-implement.md` (implementation section diff)

---

## Claim 15: "The RPI document grows from roughly 175 lines to 200 lines"

**Location:** `docs/reviews/performance-review.md:12`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The main branch RPI has 173 lines; the current branch has 202 lines (not 198 as the previous fact-check stated). The claim of "roughly 175 to 200" rounds up the original (173 to 175) and rounds down the new (202 to 200). The actual growth is 29 lines (not 25). The "roughly" qualifier makes this acceptable but the rounding goes in opposite directions.

**Evidence:** `wc -l` on both versions: main=173, branch=202

---

## Claim 16: "A template is available at `templates/gitattributes-snippet.txt` in this repo"

**Location:** `workflows/research-plan-implement.md:35`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `templates/gitattributes-snippet.txt` exists in the repository.

**Evidence:** File existence confirmed

---

## Claim 17: "See `guides/doc-freshness.md` for the freshness tracking heuristic"

**Location:** `workflows/research-plan-implement.md:27`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `guides/doc-freshness.md` exists in the repository.

**Evidence:** File existence confirmed

---

## Claim 18: "invoke the Divergent Design workflow (`divergent-design.md`)"

**Location:** `workflows/research-plan-implement.md:61`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The file `workflows/divergent-design.md` exists in the repository.

**Evidence:** File existence confirmed

---

## Claim 19: "Avoid logging secrets, credentials, or PII in diagnostic output"

**Location:** `workflows/research-plan-implement.md:99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

This is a prescriptive instruction that exists at line 99 of the current RPI. It was added per security review Finding 2 (C2 in the code review rubric). The instruction is present and functional.

**Evidence:** `workflows/research-plan-implement.md:99`

---

## Claim 20: "Other levels (e.g., end-to-end, snapshot, contract) are valid"

**Location:** `workflows/research-plan-implement.md:95`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

This was added per API consistency review Finding 3 (A2 in the code review rubric) to address the taxonomy asymmetry between RPI (4 levels) and the test-strategy skill (6 levels). The test-strategy skill at lines 78-93 defines end-to-end, snapshot/golden, and contract tests, confirming these are valid levels in the project's test vocabulary.

**Evidence:** `workflows/research-plan-implement.md:95`, `skills/test-strategy.md:78-93`

---

## Claim 21: "When used as part of RPI, the test specification section of the plan doc"

**Location:** `skills/test-strategy.md:153`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The test-strategy skill now correctly references "test specification" at line 153, matching the current RPI section name at line 83. This was updated from the previous stale reference to "testing strategy" per code review rubric item R1.

**Evidence:** `skills/test-strategy.md:153`, `workflows/research-plan-implement.md:83`

---

## Claim 22: "Can plug into RPI as the test specification section"

**Location:** `docs/reviews/full-evaluation.md:211`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The full-evaluation document now correctly references "test specification" at lines 211 and 215, matching the current RPI section name. This was updated from "testing strategy" per code review rubric item A1.

**Evidence:** `docs/reviews/full-evaluation.md:211,215`, `workflows/research-plan-implement.md:83`

---

## Claim 23: "Git history shows 16+ commits directly referencing RPI"

**Location:** `docs/reviews/self-eval-research-plan-implement.md:16`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium

A grep for "RPI" and "research-plan-implement" in git log finds 25 matching commits across all branches. The claim of "16+" is almost certainly met by any reasonable methodology, but the exact threshold depends on what counts as "directly referencing."

**Evidence:** `git log --all --oneline --grep="RPI\|research-plan-implement"` returns 25 results

---

## Claim 24: Cowen critique claims "13 (or at least 6) alternatives" were explored

**Location:** `docs/reviews/cowen-critique.md:26`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium

The decision record says "over a dozen" (not "13"). The Cowen critique parenthetically hedges with "(or at least 6)." The decision record lists 6 approaches. The "13" is the Cowen critique's interpolation of "over a dozen" into a specific number. The hedging "(or at least 6)" is accurate.

**Evidence:** `docs/decisions/006-foregrounding-tests.md:18` (says "over a dozen"), `docs/reviews/cowen-critique.md:26`

---

## Claim 25: Cowen critique claims diagnostic expectations get "the longest explanation (lines 95-97 of the RPI workflow)"

**Location:** `docs/reviews/cowen-critique.md:76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The diagnostic expectations section starts at line 97 (not 95). Line 95 is the cross-reference to test-strategy. The diagnostic expectations paragraph at line 97 is indeed one of the longer individual explanations in the test specification section, though the test level taxonomy (lines 89-93) spans a comparable number of lines. The "longest explanation" claim is approximately correct.

**Evidence:** `workflows/research-plan-implement.md:95` (cross-reference line, not diagnostic), `workflows/research-plan-implement.md:97` (diagnostic expectations)

---

## Claim 26: Yglesias critique references "line 95 of the RPI workflow" for diagnostic expectations

**Location:** `docs/reviews/yglesias-critique.md:19`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High

The diagnostic expectations section is at line 97, not line 95. Line 95 reads: "Other levels (e.g., end-to-end, snapshot, contract) are valid; the `test-strategy` skill has a full taxonomy." The reference is off by 2 lines.

**Evidence:** `workflows/research-plan-implement.md:95` (cross-reference), `workflows/research-plan-implement.md:97` (actual diagnostic expectations)

---

## Claim 27: Security review claims "line 103" contains the hard gate

**Location:** `docs/reviews/security-review.md:25`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High

The hard gate text ("implementation does not begin until the user has reviewed the plan") is at line 107, not line 103. The security review was likely written against an earlier version of the file or used a different line count. The current file has the hard gate at line 107.

**Evidence:** `workflows/research-plan-implement.md:107` (actual location of hard gate)

---

## Claim 28: Performance review claims "+14%" growth

**Location:** `docs/reviews/performance-review.md:12`
**Type:** Behavioral
**Verdict:** Unverifiable (methodology unclear)
**Confidence:** Medium

Main branch: 173 lines. Current branch: 202 lines. Growth: 29 lines, which is 16.8% (not 14%). If the review was calculated against an intermediate version with 198 lines, then 25/173 = 14.5% which rounds to 14%. The discrepancy suggests the percentage was calculated before the latest commit (which added the PII caveat and taxonomy note, adding ~4 lines).

**Evidence:** `wc -l`: main=173, current=202; 29/173 = 16.8%

---

## Claims Requiring Attention

### Stale
- **Claim 27** (`docs/reviews/security-review.md:25`): References "line 103" for the hard gate, but the hard gate is now at line 107. The security review's line number is off, likely from an earlier version of the file.

### Mostly Accurate
- **Claim 15** (`docs/reviews/performance-review.md:12`): "roughly 175 to 200 lines" -- actual is 173 to 202. The rounding goes in opposite directions and underestimates the growth (29 lines vs implied 25).
- **Claim 24** (`docs/reviews/cowen-critique.md:26`): Interpolates "over a dozen" as "13" -- the hedged "(or at least 6)" saves accuracy.
- **Claim 25** (`docs/reviews/cowen-critique.md:76`): "lines 95-97" should be "line 97" (line 95 is the cross-reference, not diagnostic expectations).
- **Claim 26** (`docs/reviews/yglesias-critique.md:19`): "line 95" should be "line 97" for diagnostic expectations.

### Unverifiable
- **Claim 4** (`docs/decisions/006-foregrounding-tests.md:18`): "Over a dozen approaches" -- only 6 are listed; no artifact preserves the full set.
- **Claim 23** (`docs/reviews/self-eval-research-plan-implement.md:16`): "16+ commits directly referencing RPI" -- count exceeds 16 but exact methodology unclear.
- **Claim 28** (`docs/reviews/performance-review.md:12`): "+14%" growth -- actual is 16.8%; may have been calculated against an intermediate file version.

### Previously Flagged Items Now Resolved
- **Previous Claim 19 (stale test-strategy reference)**: `skills/test-strategy.md:153` now correctly says "test specification" instead of "testing strategy." Resolved.
- **Previous Claim A1 (stale full-evaluation reference)**: `docs/reviews/full-evaluation.md:211,215` now correctly says "test specification." Resolved.
- **Previous Claim A3 (missing Date/Status)**: `docs/decisions/006-foregrounding-tests.md` now includes Date and Status fields. Resolved.
- **Previous Claim A2 (taxonomy asymmetry)**: `workflows/research-plan-implement.md:95` now acknowledges other levels and cross-references the test-strategy skill. Resolved.
- **Previous Claim C2 (PII caveat)**: `workflows/research-plan-implement.md:99` now includes the secrets/PII warning. Resolved.
