# Code Review: Negative Test Fixtures

**Branch:** feat/r3-negative-test-fixtures
**Reviewed:** 2026-03-23
**Status:** PASS (after fixes)

## Summary

This branch adds 8 edge-case negative test fixtures (4 per skill) covering empty files, no-claims/no-comments content, binary data, and extremely short inputs. The fixtures are well-chosen and mirror each other across fact-check and code-fact-check. However, there is a structural issue where `load_eval_report` silently skips tests on empty reports, which could mask failures in exactly these negative test cases.

## Findings

### Must Fix (if any)

_None._

### Must Address (if any)

| # | Finding | Location | Author note |
|---|---|---|---|
| A1 | `load_eval_report` skips on empty report files (`! -s` check, line 28). For tc-7.1-empty.md / tc-c8.1-empty.js, if the LLM returns an empty response, the report file will be 0 bytes, causing the test to `skip` rather than actually asserting `max_claims:0`. The test appears green but the assertion was never executed. Negative tests that silently skip defeat their purpose. Consider either: (a) making `eval_fixture` handle the `max_claims:0` check before the empty-file skip, or (b) treating a 0-byte report as having 0 claims and letting the assertions run. | `test/skills/eval-helpers.bash:26-29` | **FIXED**: Empty reports now set CLAIM_COUNT=0 and return, letting assertions run instead of skipping. |
| A2 | `tc-7.4-extremely-short.md` contains "Healthcare costs are rising." -- this is arguably a checkable factual claim with an empirical direction. A well-behaved fact-checker could reasonably extract and verify it (e.g., citing CMS data on year-over-year spending). Expecting zero claims here is debatable. Consider replacing with something truly non-checkable like "Things are complicated." or "It depends on the situation." -- or change the expected behavior to allow 0-1 claims rather than strictly 0. | `test/skills/fact-check/fixtures/tc-7.4-extremely-short.md` | **FIXED**: Replaced with "It depends on the situation." -- a truly non-checkable vague statement. |

### Consider (if any)

| # | Suggestion |
|---|---|
| C1 | The binary-content fixtures (tc-7.3, tc-c8.3) contain text representations of PNG headers, not actual binary bytes. Since these are `.md` / `.js` files read as text, this is probably fine for the intended test, but a fixture containing actual null bytes would be a stronger edge case (though harder to manage in git). Worth noting in eval-criteria.md that these are "simulated binary" rather than true binary. |
| C2 | Consider adding a fixture for very large files (e.g., thousands of lines of repeated boilerplate) to test timeout/truncation behavior. This is a common real-world edge case not covered by the current set. |
| C3 | The `no-claims` / `no-comments` fixtures are good but could be supplemented with a "comments but no factual claims" variant for code-fact-check (e.g., `// TODO: refactor this`, `// @param name - the user's name`) to verify the skill distinguishes structural comments from checkable claims. |
| C4 | `docs/working/summary-negative-test-fixtures.md` is a single-line file. This is fine as a working note, but its presence as a standalone file adds slight clutter. Could be an entry in an existing log or tasks file instead. |

## What Works Well

- Good parallel structure between fact-check (Category 7) and code-fact-check (Category 8) -- same four edge cases adapted to each domain.
- Category numbering is consistent with existing categories (fact-check had 6, gets 7; code-fact-check had 7, gets 8).
- Expected verdicts use `skip` / `not_applicable` / `max_claims:0` consistently, correctly leveraging the existing `assert_max_claims` infrastructure rather than inventing new assertion types.
- The `no-claims` fixtures (tc-7.2 meeting notes, tc-c8.2 uncommented code) are realistic -- these are inputs a user might actually pass to the skill.
- BATS test descriptions are clear and follow the existing naming conventions.
- eval-criteria.md updates are well-formatted and match the style of existing categories.
