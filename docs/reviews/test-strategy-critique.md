---
Last verified: 2026-03-23
Relevant paths:
  - skills/fact-check.md
  - skills/code-fact-check.md
  - test/
---

# Test Strategy Critique: fact-check and code-fact-check Skills

**Reviewed:** 2026-03-23
**Scope:** Branch `chore/cleanup-20260320` — test strategy, BATS format tests, evaluation criteria, fixtures, cross-skill evaluation
**Files reviewed:** 42 files, ~1,191 lines added

---

## What's Good

**1. The two-layer testing architecture is well-conceived.** Separating deterministic format validation (BATS tests on report structure) from non-deterministic behavioral evaluation (eval-criteria docs + human/automated judgment) is the right call for prompt-based skills. The BATS tests can run in CI; the eval criteria serve as a rubric for manual or LLM-graded evaluation runs. This avoids the trap of trying to write brittle assertions against LLM output.

**2. The BATS helpers are well-factored.** `load_report()`, `assert_field_per_claim()`, `assert_field_values()`, and `assert_claims_sequential()` cover the repeated structural checks cleanly. The `skip` behavior when no report exists is a good pattern — it means CI won't fail just because no report has been generated yet, while still running the checks when one is present.

**3. Fixture design for code-fact-check is strong.** The code fixtures are self-contained and unambiguous. Each file contains exactly the contradiction or confirmation it claims to test, making evaluation straightforward. `tc-c1.3-architectural.js` is a particularly good example: it includes both the false "only caller" claim and the contradicting second caller in the same file, so the skill has all the evidence it needs without cross-file reasoning.

**4. The cross-skill evaluation document (cross-skill-eval.md) identifies a real risk.** Verdict scale contamination between the two skills is a plausible failure mode, and the BATS test in `code-fact-check-format.bats` (lines 130-133) that checks for fact-check-only verdicts is a concrete, automatable guard against it. However, the corresponding check is missing from `fact-check-format.bats` (see below).

**5. Category coverage is comprehensive for the documented claim types.** The test strategy covers every claim type listed in both skill prompts, with dedicated fixtures for each. The verdict-distribution tests (Category 2) that aim to elicit each specific verdict are valuable for confirming the skills can produce the full range of outputs.

---

## Coverage Gaps

**1. No fixture for TC-4.2 (conflated statistics) in the fact-check eval criteria, but there IS a fixture file.** The eval-criteria table for Category 4 references `tc-4.2-conflated-stats.md`, which exists on disk. However, the test strategy document (Category 4) describes this scenario but notes it reuses "the '70% of parents / fifth of income' example from the skill itself." This is the same content as TC-2.2. Having two test cases that test the same claim with the same text provides no additional coverage. Either TC-4.2 should use a different conflation example, or it should be explicitly noted as a cross-reference to TC-2.2 rather than an independent test.

**2. Missing verdict-scale isolation test for fact-check.** The `code-fact-check-format.bats` file includes a test (line 130) that verifies the report never uses fact-check-only verdicts ("Accurate", "Disputed", etc.). There is no corresponding test in `fact-check-format.bats` that checks the report never uses code-fact-check-only verdicts ("Verified", "Stale", "Incorrect", "Unverifiable"). This is an asymmetry — TC-X1 specifies the check should go both ways.

**3. No fixtures for Category 3 tests (scoping) in code-fact-check.** The eval-criteria doc acknowledges this: "These tests require running the skill in different contexts, not against fixture files." But there is no guidance on how to set up those contexts. TC-C3.1 needs a branch with exactly 3 changed files; TC-C3.5 needs to be run on main; TC-C3.6 needs a README that references changed code. Without setup scripts or documented procedures, these tests are aspirational rather than runnable. This is the largest gap in practical executability.

**4. No test for multi-file cross-reference in code-fact-check.** All code fixtures are single-file. Real codebases have comments like "called from auth.ts" that require checking a separate file. TC-C1.3 (architectural claim) puts both the claim and the contradiction in the same file. A more realistic test would split `wsAuthHandler` into a separate file and see if the skill still finds the second caller.

**5. No test for partially correct multi-claim reports.** TC-5.1 and TC-C6.1 test the format of multi-claim reports, but the eval criteria don't specify expected verdicts for each claim in the multi-claim fixtures. For `tc-c6.1-multi-claim.js`, there are 8 claims with a known mix of correct and incorrect comments (helpfully annotated in the code), but `eval-criteria.md` only says to check the format. The per-claim expected verdicts should be documented.

**6. No test for report idempotency or stability.** If you run the skill twice on the same input, do you get structurally equivalent reports? For a format-validation suite, this matters. LLM output variance could cause format tests to pass on one run and fail on another.

**7. No test for empty input.** What happens when the skill is given a draft with zero checkable claims? The `load_report()` helper skips when `CLAIM_COUNT` is 0, but there's no fixture designed to test that the skill handles this gracefully (produces a report saying "no checkable claims found" rather than hallucinating claims).

---

## Fixture Quality Issues

**1. TC-1.1 and TC-1.2 contain factually wrong claims but have no expected verdict.** The eval criteria table says "Any (check CMS/BEA data)" for TC-1.1 and "Any" for TC-1.2. The fact-check report on this branch found that:
- TC-1.1's "$4.3 trillion" figure is wrong (actual 2023 spending was ~$4.9T per CMS).
- TC-1.2's description of Oregon SB 458 is wrong (it's about middle-housing land division, not tenant appreciation-sharing).

These are good test inputs — they contain real factual errors. But the eval criteria should say the expected verdict is Inaccurate (or at least "not Accurate"), not "Any." Leaving the expected verdict open makes the test unfalsifiable: no skill output can fail it. This should be fixed.

**2. TC-3.3 (mixed content) has a known data issue.** The fixture states "the waitlist exceeded 40,000 families in 2023." The fact-check report found this figure unverified — available data shows ~4,200 in 2022 and ~26,000 in 2025. The eval criteria list this as one of the ~4 checkable claims but don't specify what verdict to expect. If the fixture is intended to contain a mix of accurate and inaccurate claims, that should be explicit in the criteria.

**3. TC-C5.1 (thread-safety partial truth) is actually thread-safe.** The fixture has `process_item()` calling `increment_shared()`, which uses a lock. The comment "thread-safe" on `process_item()` is arguably correct — the function IS thread-safe because it delegates to a properly locked function. The eval criteria say the skill should report "both findings: function is locally safe but calls shared-state code, making the claim misleading." But "misleading" is a judgment about documentation quality, not a factual inaccuracy. This test may push the skill toward critique rather than fact-checking, contradicting the guardrail tests.

**4. TC-C4 (skip-targets) bundles four sub-tests into one file.** If the skill incorrectly checks one of the four comment types but correctly skips the other three, the evaluation is ambiguous. Separate fixtures per sub-case would make evaluation cleaner, matching the pattern used everywhere else in the suite.

---

## BATS Test Design Issues

**1. The `assert_field_per_claim` helper has a false-positive risk.** It counts occurrences of `**Field:**` anywhere in the report, including the "Claims Requiring Attention" summary section. If the attention section repeats the verdict for each flagged claim (which is a reasonable format), the count would exceed `CLAIM_COUNT`, causing a spurious failure. The helper should scope its counting to exclude the attention section, or the test should account for repeated fields.

**2. The Sources field check uses a different regex than other field checks.** In `fact-check-format.bats` line 48, the sources check uses `grep -cE '^\*\*Sources?:\*\*'` (note the `?` making the 's' optional), while `assert_field_per_claim` uses the exact field name. This suggests the skill prompt doesn't strictly specify singular vs. plural "Source(s)". The format tests should either enforce one spelling or the skill prompt should specify it.

**3. No test for the Summary line's arithmetic.** The BATS tests check that a Summary line exists with certain keywords, but don't verify that the verdict counts in the summary add up to the total claims checked. For example, a report could say "Total claims checked: 5" and "Summary: 3 accurate, 1 inaccurate" (missing one) and pass all current tests.

**4. The "attention section does not list Accurate claims" test (fact-check-format.bats line 66-69) searches for `**Verdict:** Accurate` within the attention section.** But the attention section format specified in the skill prompt is a one-line summary per claim, not a full claim block with verdict fields. If the skill follows its own prompt correctly, this test would pass vacuously (no verdict lines in the attention section at all). The test should check that claim numbers appearing in the attention section don't correspond to claims with Accurate verdicts earlier in the report.

---

## Practical Concerns

**1. No automation for running skills against fixtures.** The BATS tests validate report format, but there is no script that runs `fact-check` or `code-fact-check` against a fixture and produces a report. The workflow requires: (a) manually invoke the skill on a fixture, (b) save the output to the expected path, (c) run `bats`. Steps (a) and (b) are unscripted. For the fact-check skill, this means using Claude Code to process each fixture, which involves API calls and non-trivial latency. A harness script (even a simple shell loop) would make the evaluation reproducible.

**2. Cost and time of full evaluation runs.** There are 19 fact-check fixtures and 16 code-fact-check fixtures. Each fact-check run requires web search (per the skill prompt: "Use web search for every checkable claim"). A full evaluation pass means 35 skill invocations with web search. At current LLM API pricing and latency, this is expensive and slow. The strategy document doesn't discuss batching, caching, or prioritization for evaluation runs.

**3. BATS dependency is undocumented.** The tests assume `bats` is installed. There is no mention of this dependency in a `package.json`, `Makefile`, or CI configuration. The `bats` framework also needs the `bats-core` package specifically (not the older `bats` npm package). Installation and version requirements should be documented.

**4. The `REPORT_PATH` override mechanism works but is easy to misuse.** The BATS tests default to `docs/reviews/fact-check-report.md` and `docs/reviews/code-fact-check-report.md`. But these are also the paths where real (non-test) reports get saved. Running the skill for production use and then running BATS tests would validate the production report, not a test-specific one. There's no separation between test-generated reports and real reports.

---

## What's Missing (Beyond Coverage Gaps)

**1. No regression tracking.** If a skill passes 30 of 35 eval criteria today, there's no mechanism to record that baseline and detect regressions when the skill prompt is edited. Even a simple score-tracking file (`eval-results.json` with dates and pass/fail per TC) would make this actionable.

**2. No guidance on eval grading rubric.** The eval-criteria documents say what behavior to expect, but not how to score it. Is a partially correct verdict (e.g., "Mostly accurate" when "Inaccurate" was expected) a partial pass or a full fail? How do you handle the skill producing the right verdict but with wrong reasoning? The cross-skill eval doc is the closest thing to a rubric, but it only covers three test cases.

**3. No negative format tests.** All BATS tests verify properties of well-formed reports. There are no tests with intentionally malformed reports to verify that the BATS tests actually catch problems. A small set of "known-bad" report files would validate the test suite itself.

**4. No test for skill behavior when web search is unavailable.** The fact-check skill requires web search. If the tool is unavailable (e.g., in a sandboxed environment), the skill should degrade gracefully. There is no test for this scenario.

---

## Summary

The test strategy is well-structured and covers the right categories. The two-layer architecture (deterministic format tests + non-deterministic behavioral evaluation) is sound. The code-fact-check fixtures are particularly well-designed.

The main weaknesses are:

1. **Several fixtures contain real factual errors but have "Any" as the expected verdict**, making those test cases unfalsifiable. Fix: specify expected verdicts for TC-1.1, TC-1.2, TC-3.3.
2. **No automation for running skills against fixtures**, making the evaluation labor-intensive and non-reproducible.
3. **Missing verdict-scale isolation test** in `fact-check-format.bats` (the reverse of the one in `code-fact-check-format.bats`).
4. **No scoping test setup** for the code-fact-check Category 3 tests, which are documented but not executable.
5. **BATS helpers have subtle scoping issues** (counting fields in the attention section, vacuous attention-section tests).

Priority order for fixes: items 1 and 3 are quick wins (spec corrections and a missing test). Items 2 and 4 require more infrastructure work. Item 5 requires rethinking the helper logic.
