# Test Strategy: fact-check and code-fact-check Skills

These are evaluation scenarios for the two fact-checking skills. Since both are
prompt-based skills (not executable code), test cases are inputs paired with
expected behavior criteria.

---

## fact-check.md

### Category 1: Claim Type Coverage

Each test uses a short draft containing one dominant claim type to verify the
skill correctly identifies and checks it.

**TC-1.1: Specific numbers**
- Input: Draft stating "US healthcare spending reached $4.3 trillion in 2023, or 17.3% of GDP"
- Expected: Skill searches for CMS/BEA data, produces a verdict with source citation and year

**TC-1.2: Named policies/laws**
- Input: Draft stating "Oregon's SB 458 requires sellers to share appreciation with tenants who helped maintain the property"
- Expected: Skill looks up the actual bill, verifies whether this description is accurate

**TC-1.3: Attributed facts**
- Input: Draft stating "Minnesota legalized recreational cannabis in 2023"
- Expected: Verdict with correct date and confirmation (this is accurate -- tests the "Accurate" path)

**TC-1.4: Causal claims**
- Input: Draft stating "Austin rents dropped 15% because a construction boom flooded the market"
- Expected: Skill checks both the magnitude claim AND the causal link separately, cites housing data

**TC-1.5: Comparisons**
- Input: Draft stating "Most OECD countries provide universal pre-K"
- Expected: Skill checks what fraction of OECD countries actually do, may produce "Mostly accurate" or "Disputed"

**TC-1.6: Anecdotes presented as evidence**
- Input: Draft with "One California daycare tried to expand but was blocked by zoning after 18 months of permitting"
- Expected: Skill attempts to verify, likely produces "Unverified" if no primary source found

### Category 2: Verdict Distribution

Tests designed to force each of the five verdicts.

**TC-2.1: Accurate**
- Input: Easily verifiable true claim ("The 2020 US Census counted 331.4 million people")
- Expected: "Accurate" verdict, high confidence, Census Bureau citation

**TC-2.2: Mostly accurate**
- Input: Directionally correct but imprecise claim ("Nearly 70% of parents spend a fifth of their income on childcare" -- conflates two different survey findings)
- Expected: "Mostly accurate" with explanation of which stat is correct and how the draft conflates sources

**TC-2.3: Disputed**
- Input: Claim where sources genuinely disagree ("The minimum wage increase in Seattle reduced hours worked for low-wage employees")
- Expected: "Disputed" citing the UW study vs the Berkeley study, presenting both sides

**TC-2.4: Inaccurate**
- Input: Factually wrong claim ("France banned homeschooling in 2021")
- Expected: "Inaccurate" with explanation of what France actually did (restricted, not banned)

**TC-2.5: Unverified**
- Input: Hyper-specific claim that likely has no accessible source ("A bakery in rural Vermont saved $12,000/year by switching to cooperative childcare")
- Expected: "Unverified" -- skill does not fabricate a source

### Category 3: Non-Checkable Content (Negative Tests)

**TC-3.1: Opinions should be skipped**
- Input: Draft that is primarily opinion ("These reforms won't make childcare cheap. The real problem is deeper.")
- Expected: Skill identifies few or zero checkable claims, does not fact-check value judgments

**TC-3.2: Predictions should be skipped**
- Input: "By 2030, AI will handle 40% of customer service interactions"
- Expected: Skill does not treat forward-looking predictions as checkable facts

**TC-3.3: Mixed draft -- facts and opinions interleaved**
- Input: Draft with 3 checkable claims and 5 opinion sentences
- Expected: Report contains exactly the checkable claims, not the opinions

### Category 4: Ambiguity Handling

**TC-4.1: Technically true but misleading**
- Input: Claim that is true under one definition but false under the common reading ("The US has the best healthcare in the world" -- true by some metrics, false by others)
- Expected: Skill flags the ambiguity, checks the most natural reading, notes the narrow reading

**TC-4.2: Conflated statistics**
- Input: The "70% of parents / fifth of income" example from the skill itself
- Expected: Skill detects the conflation and explains which surveys map to which numbers

### Category 5: Output Format Compliance

**TC-5.1: Full report structure**
- Input: Draft with 5+ checkable claims of varying accuracy
- Expected: Report has correct header (title, author, date, counts, summary), claims ordered by appearance, sequential numbering, "Claims Requiring Author Attention" section at end

**TC-5.2: Output location -- standalone**
- Expected: Saved to `docs/reviews/fact-check-report.md`

**TC-5.3: Output location -- orchestrated**
- Input: Run via draft-review with a specified output path
- Expected: Follows orchestrator's path, not the default

### Category 6: Behavioral Guardrails

**TC-6.1: No critique leakage**
- Input: Draft with weak arguments but accurate facts
- Expected: All verdicts are "Accurate" -- skill does not comment on argument quality

**TC-6.2: Web search usage**
- Input: Any draft with checkable claims
- Expected: Evidence of web search for EVERY claim (not just memory/training data)

**TC-6.3: No skipping "obvious" claims**
- Input: Draft with a claim that seems obviously true but is actually wrong
- Expected: Skill checks it and catches the error

---

## code-fact-check.md

### Category 1: Claim Type Coverage

**TC-C1.1: Behavioral claim**
- Input: Comment `// returns null on empty input` above a function that actually returns `undefined`
- Expected: "Incorrect" -- code returns undefined, not null

**TC-C1.2: Performance claim**
- Input: Comment `// O(n) lookup` above a function with nested loops (actually O(n^2))
- Expected: "Incorrect" with analysis of the nested loop structure

**TC-C1.3: Architectural claim**
- Input: Comment `// this is the only caller of validateToken()`
- Expected: Skill greps for all callers, produces "Verified" or "Incorrect" based on actual call sites

**TC-C1.4: Invariant claim**
- Input: Comment `// userId is never null at this point`
- Expected: Skill traces code paths to verify, identifies any path that could produce null

**TC-C1.5: Configuration claim**
- Input: Comment `// cache TTL is 5 minutes` where config shows `ttl: 300` (seconds)
- Expected: "Verified" -- 300 seconds = 5 minutes

**TC-C1.6: Reference claim**
- Input: Comment `// workaround for issue #1234`
- Expected: Skill checks if issue exists (via `gh` if available), reports verdict

**TC-C1.7: Staleness signal**
- Input: Comment referencing `validateInput()` but function has been renamed to `sanitizeInput()`
- Expected: "Stale" -- the referenced function no longer exists under that name

### Category 2: Verdict Distribution

**TC-C2.1: Verified**
- Input: Comment `// throws TypeError if name is empty` above code with `if (!name) throw new TypeError(...)`
- Expected: "Verified", high confidence

**TC-C2.2: Mostly accurate**
- Input: Comment says `// O(n)` but implementation is O(n log n) due to a sort
- Expected: "Mostly accurate" -- directionally right but missing the log factor

**TC-C2.3: Stale**
- Input: Comment describes old behavior that was changed in a recent commit
- Expected: "Stale" with description of current behavior

**TC-C2.4: Incorrect**
- Input: Docstring says function "creates the directory if it doesn't exist" but implementation throws on missing directory
- Expected: "Incorrect" -- code throws, does not create

**TC-C2.5: Unverifiable**
- Input: Comment `// thread-safe due to GIL` in code with complex concurrency patterns
- Expected: "Unverifiable" -- cannot confirm thread safety from static analysis alone

### Category 3: Scoping

**TC-C3.1: Default scope -- branch diff**
- Input: Run on a branch with 3 changed files
- Expected: Only checks claims in those 3 files (plus docs referencing them)

**TC-C3.2: Explicit file list**
- Input: User specifies `src/auth.ts src/middleware.ts`
- Expected: Only checks claims in those two files

**TC-C3.3: Directory scope**
- Input: User specifies `src/utils/`
- Expected: Checks all files in that directory

**TC-C3.4: "all" scope**
- Input: User says "check all"
- Expected: Warns about potential slowness for large repos, then checks everything

**TC-C3.5: No branch diff (on main)**
- Input: Run while on main with no explicit scope
- Expected: Falls back to asking user for scope or using explicit scope

**TC-C3.6: Cross-reference to docs**
- Input: Changed file `src/auth.ts`; `README.md` describes auth behavior
- Expected: README claims about auth are also checked

### Category 4: Non-Checkable Content (Negative Tests)

**TC-C4.1: Design rationale -- skip**
- Input: `// this approach is simpler than using a state machine`
- Expected: Not checked (opinion)

**TC-C4.2: TODO/HACK comments -- skip**
- Input: `// TODO: refactor this` and `// HACK: temporary fix`
- Expected: Not checked

**TC-C4.3: License headers -- skip**
- Input: Standard Apache/MIT license block
- Expected: Not checked

**TC-C4.4: Restating code -- skip**
- Input: `i += 1  // increment i`
- Expected: Not checked (trivial restatement)

### Category 5: Ambiguity Handling

**TC-C5.1: Thread-safety claim with partial truth**
- Input: `// thread-safe` on a function that uses no shared state itself, but calls a function that does
- Expected: Reports both findings -- the function is locally safe but the claim is misleading in context

**TC-C5.2: Documentation describes intended vs actual behavior**
- Input: Docstring says "retries 3 times" but code retries 2 times (off-by-one)
- Expected: "Incorrect" -- checks against actual behavior, not intent

### Category 6: Output Format Compliance

**TC-C6.1: Full report structure**
- Input: Codebase with 8+ checkable claims across multiple files
- Expected: Header (repo, scope, date, counts, summary), claims ordered by file path then line number, sequential numbering, "Claims Requiring Attention" section with subsections (Incorrect, Stale, Mostly Accurate, Unverifiable)

**TC-C6.2: Output location -- standalone**
- Expected: Saved to `docs/reviews/code-fact-check-report.md`

**TC-C6.3: Output location -- orchestrated**
- Expected: Follows orchestrator's specified path

### Category 7: Evidence Quality

**TC-C7.1: Cites specific line numbers**
- Expected: Every claim references `file:line` for both the claim location and the evidence

**TC-C7.2: Reads implementation, not just signatures**
- Input: Function with misleading name but correct docstring (or vice versa)
- Expected: Verdict based on actual implementation, not name/signature

**TC-C7.3: Prioritizes recently changed code**
- Input: Mix of old and new claims
- Expected: Claims near recent changes are checked first (or flagged as higher priority for staleness)

---

## Cross-Skill Tests (fact-check vs code-fact-check consistency)

**TC-X1: Parallel verdict scales**
- Verify the mapping: Accurate <-> Verified, Mostly accurate <-> Mostly accurate, Disputed <-> (no equivalent), Inaccurate <-> Incorrect, Unverified <-> Unverifiable, (none) <-> Stale
- Expected: Each skill uses its own scale consistently, never borrows from the other

**TC-X2: Same "mostly accurate" threshold**
- Input: Equivalent "directionally correct but imprecise" claims in both prose and code contexts
- Expected: Both skills use "Mostly accurate" at a similar threshold of imprecision

**TC-X3: Both refuse to add critique**
- Input: Draft/code with accurate facts but poor quality
- Expected: Neither skill comments on quality -- only accuracy
