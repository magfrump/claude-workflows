# Code Fact-Check Skill: Evaluation Criteria

Each test case maps a fixture file to expected behavior. An evaluator runs the
skill against the fixture(s), then checks the report against these criteria.

Verdict codes: **V** = Verified, **MA** = Mostly accurate, **S** = Stale,
**I** = Incorrect, **UV** = Unverifiable.

---

## Category 1: Claim Type Coverage

| TC | Fixture | Expected Verdict | Key Check |
|----|---------|-----------------|-----------|
| C1.1 | `tc-c1.1-behavioral.js` | I | Code returns `undefined`, not `null` as docstring claims |
| C1.2 | `tc-c1.2-performance.js` | I | Nested loops make it O(n^2), not O(n) as comment claims |
| C1.3 | `tc-c1.3-architectural.js` | I | `wsAuthHandler` is a second caller of `validateToken()`; "only caller" is false |
| C1.4 | `tc-c1.4-invariant.js` | I | `req.session?.userId` can be `undefined` via optional chaining |
| C1.5 | `tc-c1.5-configuration.js` | V | 300 seconds = 5 minutes; comment matches code |
| C1.6 | `tc-c1.6-reference.js` | V or UV | Skill attempts to check if issue #1234 exists (via `gh` if available) |
| C1.7 | `tc-c1.7-staleness.js` | S | Comment says `validateInput()` but function is now `sanitizeInput()` |

## Category 2: Verdict Distribution

| TC | Fixture | Expected Verdict | Key Check |
|----|---------|-----------------|-----------|
| C2.1 | `tc-c2.1-verified.js` | V | Code does throw TypeError if name is empty — matches comment |
| C2.2 | `tc-c2.2-mostly-accurate.js` | MA | Sort makes it O(n log n), not O(n); directionally right but missing log factor |
| C2.3 | `tc-c2.3-stale.js` | S | Comment says 5 retries but code now does 3 |
| C2.4 | `tc-c2.4-incorrect.js` | I | Code throws on missing directory; does not create it as docstring claims |
| C2.5 | `tc-c2.5-unverifiable.py` | UV | Thread-safety claim cannot be confirmed from static analysis of complex concurrency |

## Category 3: Scoping

These tests require running the skill in different contexts, not against fixture files:

| TC | Setup | Expected Behavior |
|----|-------|-------------------|
| C3.1 | Branch with 3 changed files | Only checks claims in those 3 files (plus docs referencing them) |
| C3.2 | User specifies `src/auth.ts src/middleware.ts` | Only checks claims in those two files |
| C3.3 | User specifies `src/utils/` | Checks all files in that directory |
| C3.4 | User says "check all" | Warns about potential slowness, then checks everything |
| C3.5 | On main with no explicit scope | Falls back to asking user for scope |
| C3.6 | Changed `src/auth.ts`; README describes auth behavior | README claims about auth are also checked |

## Category 4: Non-Checkable Content

| TC | Fixture | Expected Behavior |
|----|---------|-------------------|
| C4.1-4.4 | `tc-c4-skip-targets.js` | Design rationale, TODOs, license headers, and trivial restatements are all skipped; none appear in the report |

## Category 5: Ambiguity Handling

| TC | Fixture | Expected Behavior |
|----|---------|-------------------|
| C5.1 | `tc-c5.1-thread-safety-partial.py` | Reports both findings: function is locally safe but calls shared-state code, making the claim misleading |
| C5.2 | `tc-c5.2-intended-vs-actual.js` | I — checks against actual behavior (2 retries), not intent (3 retries) |

## Category 6: Output Format Compliance

| TC | Fixture | Expected Behavior |
|----|---------|-------------------|
| C6.1 | `tc-c6.1-multi-claim.js` | Report has: header (repo, scope, date, counts, summary), claims ordered by file path then line number, sequential numbering, "Claims Requiring Attention" section with subsections (Incorrect, Stale, Mostly Accurate, Unverifiable) |
| C6.2 | (any standalone run) | Report saved to `docs/reviews/code-fact-check-report.md` |
| C6.3 | (orchestrated run) | Report follows orchestrator's specified path |

## Category 7: Evidence Quality

| TC | Expected Behavior |
|----|-------------------|
| C7.1 | Every claim references `file:line` for both the claim location and the evidence |
| C7.2 | Verdict based on actual implementation, not function name or signature alone |
| C7.3 | Claims near recent changes are checked first or flagged as higher staleness priority |

## Category 8: Edge Cases / Negative Test Fixtures

Tests that the skill gracefully handles degenerate inputs — producing a "nothing to check" response rather than confused analysis.

| TC | Fixture | Expected Behavior |
|----|---------|-------------------|
| C8.1 | `tc-c8.1-empty.js` | Empty file; skill reports zero claims checked |
| C8.2 | `tc-c8.2-no-comments.js` | Code with no comments or docstrings; skill reports zero claims checked |
| C8.3 | `tc-c8.3-binary-content.js` | Binary/garbled content; skill declines gracefully with zero claims |
| C8.4 | `tc-c8.4-extremely-short.js` | Single assignment (`const x = 42;`) with no claims; zero claims |
