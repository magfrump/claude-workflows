# Fact-Check Report: RPI Workflow and Foregrounding Tests Decision

**Checked:** 2026-03-26
**Total claims checked:** 10
**Summary:** 7 accurate, 2 mostly accurate, 0 disputed, 0 inaccurate, 1 unverified

---

## Claim 1: "docs/working/** linguist-generated ... This collapses them in GitHub's diff view -- reviewers can still expand them"

**Source:** RPI workflow, lines 32-35
**Verdict:** Accurate
**Confidence:** High

GitHub's documentation and multiple third-party sources confirm that the `linguist-generated` attribute in `.gitattributes` causes files to be collapsed by default in GitHub's diff view (pull requests, commits, compare views). Reviewers can expand collapsed files to view them. The exact `.gitattributes` syntax shown (`docs/working/** linguist-generated`) is valid.

**Sources:** [GitHub Docs -- Customizing how changed files appear on GitHub](https://docs.github.com/en/repositories/working-with-files/managing-files/customizing-how-changed-files-appear-on-github), [Thoughtbot -- Automatically Collapse Generated Files in GitHub Diffs](https://thoughtbot.com/blog/github-diff-supression)

---

## Claim 2: "A template is available at templates/gitattributes-snippet.txt in this repo."

**Source:** RPI workflow, line 35
**Verdict:** Accurate
**Confidence:** High

The file exists at `templates/gitattributes-snippet.txt` and contains the exact `docs/working/** linguist-generated` directive described in the workflow.

**Sources:** Project file `templates/gitattributes-snippet.txt`

---

## Claim 3: "DD's 80% confidence threshold governs whether the design decision can be resolved autonomously"

**Source:** RPI workflow, line 61
**Verdict:** Accurate
**Confidence:** High

The divergent design workflow (`workflows/divergent-design.md`, line 78) states: "If one approach clearly dominates (>80% confidence): document the decision and proceed." This matches the RPI's characterization of an 80% confidence threshold for autonomous resolution.

**Sources:** Project file `workflows/divergent-design.md`, line 78

---

## Claim 4: "the test-strategy skill has a full taxonomy"

**Source:** RPI workflow, line 95
**Verdict:** Mostly accurate
**Confidence:** Medium

The `test-strategy` skill (`skills/test-strategy.md`) references multiple test types -- unit, integration, e2e, property, snapshot, and contract -- and includes guidance on when to use each. However, it does not use the word "taxonomy" and presents these types inline rather than as an organized classification system. Calling it a "full taxonomy" is a reasonable characterization but slightly overstates the formality of what the skill provides.

**Sources:** Project file `skills/test-strategy.md`

---

## Claim 5: "The RPI workflow mentions 'testing strategy' as a one-line plan section"

**Source:** Decision 006, line 8
**Verdict:** Accurate
**Confidence:** High

The pre-foregrounding version of the RPI workflow (verified via `git show bfe83f3:workflows/research-plan-implement.md`) contained a single bullet point: `- **Testing strategy**: How to verify the implementation works. Specific test cases, not "add tests."` This is accurately described as a "one-line plan section."

**Sources:** Git history, commit `bfe83f3`

---

## Claim 6: "[The RPI mentions] 'characterization tests first' in the refactoring variant"

**Source:** Decision 006, line 8
**Verdict:** Accurate
**Confidence:** High

The RPI workflow's Refactoring variant (line 197) includes: "Characterization tests first: If existing coverage is insufficient, the plan's first steps should add tests that lock in current behavior before any structural changes begin." This text exists in both the pre- and post-foregrounding versions of the file.

**Sources:** Project file `workflows/research-plan-implement.md`, line 197; git history confirms pre-existing at commit `bfe83f3`

---

## Claim 7: "Over a dozen approaches were generated via divergent design"

**Source:** Decision 006, line 18
**Verdict:** Unverified
**Confidence:** Low

The decision record states that over a dozen approaches were generated in conversation and that 6 survivors are summarized. No working document or divergent design artifact in `docs/working/` preserves the full list. The claim is plausible given how DD works (it encourages generating many candidates before pruning), but the specific quantity cannot be verified from available evidence. Note: this was previously reported as "13 approaches" in an earlier fact-check; the wording has since been softened to "over a dozen."

**Sources:** None available; the conversational context where DD was conducted is not preserved

---

## Claim 8: "6 survivors are summarized here"

**Source:** Decision 006, line 18
**Verdict:** Accurate
**Confidence:** High

The Options Considered section lists exactly 6 numbered items: (1) Test-first plan step, (2) Standalone test-design workflow, (3) Conversational test negotiation, (4) Test taxonomy guide, (5) Test review checkpoint, (6) Do nothing. Count confirmed.

**Sources:** Project file `docs/decisions/006-foregrounding-tests.md`, lines 20-25

---

## Claim 9: "Combine approaches 1 + 4 + 5, plus diagnostic guidance"

**Source:** Decision 006, line 29
**Verdict:** Accurate
**Confidence:** High

The decision says it combines approaches 1, 4, and 5, plus diagnostic guidance as a fourth element. Checking the implementation in the updated RPI workflow:

- **Approach 1 (Test-first plan step):** Implemented. The testing bullet in step 3 was restructured from a one-liner into a structured block with a table format, test levels, and diagnostic expectations.
- **Approach 4 (Test taxonomy guide):** Implemented as inline guidance. Lines 89-93 provide brief descriptions of when to use unit, integration, characterization, and property test levels.
- **Approach 5 (Test review checkpoint):** Implemented. Step 5 now has a "Test-first gate" sub-section with a human checkpoint for reviewing test code before implementation.
- **Diagnostic guidance:** Implemented. Lines 97-99 cover diagnostic expectations and security considerations for test output.

Note: a previous fact-check flagged a mismatch between "combine 1 + 4 + 5" and the 4-element concrete list. The decision statement now explicitly says "plus diagnostic guidance," resolving that discrepancy.

**Sources:** `docs/decisions/006-foregrounding-tests.md` lines 28-42; `workflows/research-plan-implement.md` lines 83-99, 121-129

---

## Claim 10: "the human designs behavioral constraints in prose, the LLM translates them into executable test code"

**Source:** Decision 006, line 10
**Verdict:** Mostly accurate
**Confidence:** Medium

This accurately describes the intended workflow design: the RPI plan phase (step 3) asks humans to specify test cases with expected behavior in prose, and step 5 has the LLM write test code from those specifications. However, this is a description of a designed process rather than a verified empirical outcome. Whether the translation works reliably in practice is a separate question that would require usage data to verify.

**Sources:** Project file `workflows/research-plan-implement.md`, steps 3 and 5

---

## Claims Requiring Author Attention

### Unverified
- **Claim 7** ("Over a dozen approaches were generated via divergent design"): The quantity cannot be verified from the codebase. The wording has already been softened from a previous version that said "13 approaches." Consider either preserving the DD working document that lists all candidates, or accepting that this claim relies on conversational context that is no longer available.

### Mostly Accurate
- **Claim 4** ("the test-strategy skill has a full taxonomy"): The skill covers multiple test types with guidance on when to use each, but does not present them as a formal taxonomy. Consider whether "a full taxonomy" overpromises what the skill actually organizes.

### Previously Flagged Issues Now Resolved
- The "13 approaches" wording was softened to "over a dozen" (Claim 7).
- The "combine 1 + 4 + 5" framing now explicitly includes "plus diagnostic guidance" (Claim 9).
- The "central use case" language was changed to "motivating use case" (no longer a checkable factual claim).
