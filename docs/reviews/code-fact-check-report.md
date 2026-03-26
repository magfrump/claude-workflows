# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** Branch diff relative to main (`git diff main...HEAD`)
**Checked:** 2026-03-26
**Total claims checked:** 8
**Summary:** 6 verified, 1 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

---

## Claim 1: "The RPI workflow mentions 'testing strategy' as a one-line plan section"

**Location:** `docs/decisions/006-foregrounding-tests.md:5`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The main branch version of `workflows/research-plan-implement.md` at line 83 contains: `- **Testing strategy**: How to verify the implementation works. Specific test cases, not "add tests."` — this is indeed a single bullet point (one line) within the plan section. The characterization of it as a "one-line plan section" is accurate.

**Evidence:** `workflows/research-plan-implement.md:83` (main branch)

---

## Claim 2: "'characterization tests first' in the refactoring variant"

**Location:** `docs/decisions/006-foregrounding-tests.md:5`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The main branch RPI file contains `- **Characterization tests first**: If existing coverage is insufficient, the plan's first steps should add tests that lock in current behavior before any structural changes begin.` in the Refactoring variant section. The claim accurately describes this content.

**Evidence:** `workflows/research-plan-implement.md:168` (main branch)

---

## Claim 3: "neither gives tests a primary role in the human-LLM collaboration loop"

**Location:** `docs/decisions/006-foregrounding-tests.md:5`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

In the main branch RPI, testing appears only as a verification concern (one line in the plan section, characterization tests as a safety net in the refactoring variant, and "run tests after every step" in implementation). None of these position tests as a design artifact, a specification mechanism, or a human-LLM interface. The claim is accurate.

**Evidence:** `workflows/research-plan-implement.md:83,164,168,172` (main branch)

---

## Claim 4: "13 approaches were generated via divergent design"

**Location:** `docs/decisions/006-foregrounding-tests.md:15`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low

The decision record claims 13 approaches were generated, but only 6 are listed (including "do nothing"). The remaining approaches from the divergent design process are not included in the document and cannot be verified from the codebase alone. There is no accompanying divergent design working document in `docs/working/` to cross-reference.

**Evidence:** `docs/decisions/006-foregrounding-tests.md:15-22` (only 6 options listed)

---

## Claim 5: "Restructure RPI plan step 3"

**Location:** `docs/decisions/006-foregrounding-tests.md:30`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High

The decision record says "Restructure RPI plan step 3." The testing strategy content is indeed in step 3 ("Plan") of the RPI workflow, but the testing section is not itself "step 3" — it is a bullet point within step 3. The numbering "step 3" refers to the Plan phase overall. This is directionally correct but slightly imprecise — a reader could interpret "plan step 3" as meaning the third sub-step within the plan section rather than the third step of the RPI process.

**Evidence:** `workflows/research-plan-implement.md:72-99` (step 3 is the "Plan" phase; testing is one of several bullet points within it)

---

## Claim 6: Decision log entry "#6" with date "2026-03-26"

**Location:** `docs/decisions/log.md:10`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The log entry number is 6, and the full decision record file is `006-foregrounding-tests.md`, which exists and matches. The date 2026-03-26 matches the current date. The link `[006](006-foregrounding-tests.md)` is a valid relative link. Note: the decision log jumps from #1 to #6 — entries 2-5 are not in the log but do exist as full records in `docs/decisions/`. This is consistent with the log's own documentation ("Lightweight record for decisions that don't warrant a full decision record") — decisions 2-5 have full records and thus appropriately do not appear in the lightweight log.

**Evidence:** `docs/decisions/log.md:10`, `docs/decisions/006-foregrounding-tests.md` (file exists)

---

## Claim 7: "Tests are a design artifact, not a verification afterthought"

**Location:** `workflows/research-plan-implement.md:83` (new version)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The restructured RPI workflow does implement this claim: the test specification section in step 3 asks the human to specify test cases during planning with structured fields (test case, expected behavior, level, diagnostic expectation), and step 5 adds a "test-first gate" where tests are written before feature code. This matches the claim that tests are treated as a design artifact.

**Evidence:** `workflows/research-plan-implement.md:83-97` (test specification in plan), `workflows/research-plan-implement.md:117-127` (test-first gate in implementation)

---

## Claim 8: "Like the research checkpoint, this should not block progress indefinitely"

**Location:** `workflows/research-plan-implement.md:123`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The RPI workflow's research checkpoint at line 68 states: "this checkpoint should not block progress. Claude should proceed to the plan step immediately after producing the research doc." The new test review checkpoint uses the same pattern: "if the user doesn't respond promptly, proceed with implementation but flag that tests haven't been reviewed." The analogy is accurate.

**Evidence:** `workflows/research-plan-implement.md:68` (research checkpoint), `workflows/research-plan-implement.md:123` (test review checkpoint)

---

## Claims Requiring Attention

### Mostly Accurate
- **Claim 5** (`docs/decisions/006-foregrounding-tests.md:30`): "Restructure RPI plan step 3" — "step 3" refers to the Plan phase of RPI, not a sub-step within it. Minor imprecision in reference.

### Unverifiable
- **Claim 4** (`docs/decisions/006-foregrounding-tests.md:15`): "13 approaches were generated via divergent design" — only 6 are listed; no working document found to verify the full count.
