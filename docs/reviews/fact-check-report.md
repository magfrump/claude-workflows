# Fact-Check Report: Foregrounding Tests Decision Record

**Checked:** 2026-03-26
**Total claims checked:** 8
**Summary:** 5 accurate, 1 mostly accurate, 1 disputed, 0 inaccurate, 1 unverifiable

---

## Claim 1: "RPI workflow mentions 'testing strategy' as a one-line plan section"

**Verdict:** Accurate
**Confidence:** High

The main branch version of `workflows/research-plan-implement.md` at line 83 contains exactly: `- **Testing strategy**: How to verify the implementation works. Specific test cases, not "add tests."` This is a single bullet point within the Plan section (step 3). Calling it a "one-line plan section" is accurate — it is one line, and it is within the plan section.

**Sources:** `git show main:workflows/research-plan-implement.md` line 83

---

## Claim 2: "'characterization tests first' in the refactoring variant"

**Verdict:** Accurate
**Confidence:** High

The main branch RPI file at line 168 contains: `- **Characterization tests first**: If existing coverage is insufficient, the plan's first steps should add tests that lock in current behavior before any structural changes begin.` This appears in the "Variant: Refactoring" section under "Plan phase additions." The claim accurately describes this content.

**Sources:** `git show main:workflows/research-plan-implement.md` line 168

---

## Claim 3: "neither gives tests a primary role in the human-LLM collaboration loop"

**Verdict:** Accurate
**Confidence:** High

In the main branch RPI, testing appears in three places: (1) a one-line plan bullet about testing strategy, (2) characterization tests as a safety net in the refactoring variant, and (3) "run tests after every step" in the refactoring implementation additions. None of these position tests as a specification mechanism, a design artifact, or an interface between human intent and LLM implementation. The claim is accurate.

**Sources:** `git show main:workflows/research-plan-implement.md` lines 83, 168, 172

---

## Claim 4: "13 approaches were generated via divergent design"

**Verdict:** Unverifiable
**Confidence:** Low

The decision record states "13 approaches were generated via divergent design" but only 6 are listed. The parenthetical "(the full list was explored in conversation; 6 survivors are summarized here)" acknowledges this gap, but no working document or divergent design artifact in `docs/working/` preserves the full list of 13. The number cannot be confirmed or denied from the codebase alone. The claim may well be true — it describes a conversational process — but there is no artifact to verify against.

**Sources:** `docs/decisions/006-foregrounding-tests.md` lines 15-22; searched `docs/working/` for related artifacts (none found)

---

## Claim 5: "6 survivors are summarized here"

**Verdict:** Accurate
**Confidence:** High

The Options Considered section lists exactly 6 numbered items: (1) Test-first plan step, (2) Standalone test-design workflow, (3) Conversational test negotiation, (4) Test taxonomy guide, (5) Test review checkpoint, (6) Do nothing. Count confirmed.

**Sources:** `docs/decisions/006-foregrounding-tests.md` lines 17-22

---

## Claim 6: "Combine approaches 1 + 4 + 5"

**Verdict:** Mostly accurate
**Confidence:** High

The decision says it combines: (1) Test-first plan step, (4) Test taxonomy guide, and (5) Test review checkpoint. Checking the implementation in the updated RPI workflow:

- **Approach 1 (Test-first plan step):** Implemented. The testing bullet in step 3 was restructured from a one-liner into a structured block with a table format, test levels, and diagnostic expectations (lines 83-97).
- **Approach 4 (Test taxonomy guide):** Implemented as inline guidance. Lines 89-93 provide brief descriptions of when to use unit, integration, characterization, and property test levels.
- **Approach 5 (Test review checkpoint):** Implemented. Step 5 now has a "Test-first gate" sub-section (lines 119-125) with a human checkpoint for reviewing test code before implementation.

However, the "Concretely" section of the decision record lists 4 items, not 3: it adds a fourth item ("Diagnostic guidance") that is not one of the numbered approaches. This diagnostic guidance does appear in the implementation (line 95), but it is presented in the decision as a separate concrete element rather than a sub-component of approach 1. This is a minor structural mismatch — the decision says "combine 1 + 4 + 5" but the concrete implementation adds a fourth element that crosscuts approaches 1 and 4.

**Sources:** `docs/decisions/006-foregrounding-tests.md` lines 24-39; `workflows/research-plan-implement.md` lines 83-97, 117-125

---

## Claim 7: "The RPI workflow mentions... 'characterization tests first' in the refactoring variant, but neither gives tests a primary role"

**Verdict:** Accurate
**Confidence:** High

This is a composite claim: (a) the refactoring variant mentions characterization tests first (verified — see Claim 2), and (b) this mention does not give tests a "primary role" in the human-LLM collaboration loop. The refactoring variant treats characterization tests as a safety net ("locks in existing behavior before refactoring"), not as a human-specification mechanism or collaboration interface. The claim is accurate.

**Sources:** `git show main:workflows/research-plan-implement.md` lines 164-172 (refactoring variant)

---

## Claim 8: "The central use case is code development in other repos, not testing workflow prompts in this repo"

**Verdict:** Disputed
**Confidence:** Medium

This claim is a statement of intent rather than a factual claim about the codebase. The implementation is embedded in the RPI workflow, which is a general-purpose development workflow. The test specification guidance (test levels, diagnostic expectations, the table format) is clearly oriented toward code development. However, nothing in the implementation restricts it to external repos, and the RPI workflow is used for work within this repo too. The claim about "central use case" is plausible as a design intention but not enforced or evidenced by the implementation — the workflow applies equally to work in this repo or any other. The word "central" makes this a soft claim about intended primary audience rather than a hard constraint.

**Sources:** `workflows/research-plan-implement.md` (general-purpose workflow, no repo-scoping); `docs/decisions/006-foregrounding-tests.md` line 11

---

## Claims Requiring Author Attention

### Unverifiable
- **Claim 4** ("13 approaches were generated via divergent design"): The number 13 cannot be verified from the codebase. Consider either (a) saving the divergent design working document that lists all 13, (b) softening to "multiple approaches" or "over a dozen approaches", or (c) accepting that the claim relies on conversational context that is no longer available.

### Mostly Accurate
- **Claim 6** ("Combine approaches 1 + 4 + 5"): The "Concretely" section lists 4 implementation elements, not 3. The fourth ("Diagnostic guidance") is not explicitly one of the numbered approaches. Consider either folding diagnostic guidance into approach 1's description or acknowledging it as a fourth element in the decision statement.

### Disputed
- **Claim 8** ("The central use case is code development in other repos"): This is a reasonable design intention but is not reflected in the implementation, which applies to all RPI usage. Consider whether this framing is necessary in the decision record, or whether it could be softened to "the motivating use case" to acknowledge that the implementation is general-purpose.
