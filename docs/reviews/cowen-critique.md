---
Last verified: 2026-03-26
Relevant paths:
  - docs/decisions/006-foregrounding-tests.md
  - workflows/research-plan-implement.md
---

# Cowen-Style Critique: Foregrounding Tests as a Human-LLM Interface

## 1. The Argument, Decomposed

The decision record's thesis -- "tests should be foregrounded as a human-LLM interface in the RPI workflow" -- decomposes into these distinct sub-claims:

1. **Tests are the most precise, executable form of requirements.** A human who writes test cases has expressed intent in a way that is unambiguous and machine-checkable.

2. **The current RPI workflow under-specifies testing.** A one-line bullet about "testing strategy" is not enough to produce good tests, and in practice gets skipped.

3. **Test design should happen during planning, not after implementation.** Moving test specification earlier in the workflow catches intent mismatches before implementation work is invested.

4. **A test taxonomy helps humans make informed choices.** Non-experts benefit from inline guidance about when to use unit vs. integration vs. characterization vs. property tests.

5. **A test review gate is valuable before implementation begins.** Having the human review test code (the specification) before implementation code (the solution) catches mismatches at the cheapest possible point.

6. **Diagnostic quality matters.** Test failures should be informative enough to diagnose problems without re-running or reading all the implementation code.

7. **This combination of changes (plan restructuring + taxonomy + review gate + diagnostic guidance) is the right synthesis.** The divergent design process evaluated 13 (or at least 6) alternatives and converged on this set.

These are seven distinct claims. The draft treats them as a single package, but they have very different evidentiary bases and very different risk profiles.

---

## 2. What Survives the Inversion

**Inversion: "Tests should remain a verification afterthought, not a specification mechanism."**

Sub-claim 1 (tests as executable requirements) does not survive inversion in the abstract -- of course executable specifications are more precise than prose. But it partially crumbles in practice. Many real test cases are *not* unambiguous specifications. A test that asserts `result.length === 3` specifies a length but says nothing about what those three items should be. A test that asserts the output matches a golden snapshot specifies everything but communicates nothing about intent. The claim that tests are "the most precise form of requirements" is true only for well-designed tests. The workflow implicitly assumes the human will design good test cases, but provides no guidance on what makes a test case a good *specification* as opposed to a good *verification*. These are different skills.

Sub-claim 2 (current RPI under-specifies testing) survives inversion cleanly. The old one-liner was clearly insufficient. Even someone arguing against foregrounding tests would have trouble claiming that a single bullet point was adequate.

Sub-claim 3 (early test design) partially survives inversion. The counter-argument: you often cannot write good test cases until you understand the implementation shape. Especially for integration tests, the test depends on knowing what components exist, what interfaces they expose, and what side effects they produce. The decision record assumes the human can specify behavior-level tests during planning without knowing implementation details. This works for pure-function unit tests and high-level acceptance tests. It works poorly for the messy middle -- integration tests, tests that depend on specific error handling paths, tests that exercise framework-specific behavior. The workflow should acknowledge that some test cases can only be specified after initial implementation, and that is fine.

Sub-claim 5 (test review gate) is the strongest under inversion. A human reviewing test code before implementation is genuinely a different activity from reviewing test code after implementation. After implementation, the tests are read as verification ("do they pass?"). Before implementation, the tests are read as specification ("is this what I want?"). This cognitive reframe has real value.

Sub-claim 6 (diagnostic quality) survives inversion completely. Nobody benefits from opaque test failures.

---

## 3. Factual Foundation

The fact-check report (8 claims, checked 2026-03-26) provides three findings that matter for this critique:

**The "13 approaches" claim is unverifiable.** Only 6 are listed; no artifact preserves the rest. This matters because the decision record uses the number 13 to signal thoroughness of the design process. If the actual number was 6 or 8, the claim still works -- divergent design was used, multiple alternatives were considered. The specific number 13 carries more weight than the argument needs, and it cannot be verified. This is a minor credibility risk.

**"Combine approaches 1 + 4 + 5" under-counts.** The implementation has 4 elements, not 3 -- diagnostic guidance is a separate concrete component not listed in the numbered approaches. This is a bookkeeping error, not a substantive problem, but it suggests the decision was still evolving when the record was written.

**"The central use case is code development in other repos" is disputed.** The implementation applies to all RPI usage. This is the most substantively interesting finding because it reveals a gap between the motivating scenario and the actual scope of the change. The decision was motivated by a specific use case (coding in external repos) but the implementation is general-purpose. This is not necessarily wrong -- a general solution to a specific problem is often better than a narrow one -- but the decision record should be transparent about this expansion of scope.

---

## 4. The Boring Explanation

The most mundane account of what happened: someone using an LLM for coding discovered that test quality matters a lot when you cannot watch the LLM work, got frustrated by vague test guidance in the existing workflow, and added more structured test guidance.

This boring explanation accounts for roughly 90% of the decision. The "tests as human-LLM interface" framing is doing rhetorical work to make a straightforward improvement sound like a conceptual breakthrough. The actual change is: (a) the plan template now has a table for test cases instead of a one-liner, (b) there is inline guidance on test levels, (c) there is a checkpoint for reviewing tests before implementation, and (d) there is guidance on making test failures informative.

All four of these are good ideas. None of them required the "tests are a specification mechanism" framing to justify. A simpler framing -- "the testing section was too vague, so we made it more structured" -- explains the same changes with less theoretical overhead.

The interesting question the boring explanation raises: will the structured test table actually get filled out in practice, or will it suffer the same fate as the one-liner it replaced? The one-liner was skipped because it was too vague. The table might be skipped because it is too much ceremony. The decision record acknowledges this ("simple features can use minimal test specs") but does not define what "minimal" means or when to invoke the escape hatch.

---

## 5. Revealed vs. Stated

**Stated preference:** "Tests are the most precise, executable form of requirements." This frames tests as primarily a *specification* tool.

**Revealed preference:** The diagnostic expectations column -- what should be visible when a test fails -- reveals that the authors care most about tests as a *debugging* tool. If you genuinely believed tests were primarily specifications, the diagnostic column would be secondary to the expected-behavior column. But the diagnostic column gets the longest explanation (lines 95-97 of the RPI workflow) and the most specific guidance. The real pain point is not "the LLM did not know what I wanted" but "the LLM did something wrong and I could not figure out what from the test output." This is a debugging problem, not a specification problem.

**Stated preference:** "The central use case is code development in other repos" (decision record, line 11).

**Revealed preference:** The implementation lives in the RPI workflow, which governs all development work including work on this repo. The authors chose to embed the change in the most general-purpose workflow rather than creating a variant or a conditional section for "when coding in external repos." The revealed preference is for universal application -- the "external repos" framing is a motivating anecdote, not a scope constraint.

**Stated preference:** The test review gate is positioned as a "human checkpoint" (line 122-123 of RPI) analogous to the plan review gate.

**Revealed preference:** The test review gate has an explicit escape hatch: "if the user doesn't respond promptly, proceed with implementation but flag that tests haven't been reviewed." The plan review gate has no such escape: "implementation does not begin until the user has reviewed the plan." The test gate is softer than the plan gate. This reveals that the authors consider the plan more important than the test specification -- which is in tension with the claim that tests are the primary interface. If tests were truly the specification mechanism, the test gate should be at least as firm as the plan gate.

---

## 6. The Analogy

The analogy nobody is making: **architectural blueprints vs. building codes.**

The decision record frames tests as blueprints -- the detailed specification that the builder follows. But most test cases are actually closer to building codes -- they specify constraints (the load-bearing wall must support X, the exit must be Y width) without specifying the design. A test that says "this function returns a sorted list" constrains the implementation without specifying it.

This distinction matters because blueprints and building codes have different failure modes. A blueprint that is wrong produces a building nobody wanted. A building code that is wrong either constrains too tightly (no building can pass) or too loosely (dangerous buildings pass). The workflow assumes tests work like blueprints -- the human designs the specification, the LLM implements it. But most tests work like building codes -- the human designs constraints, and the LLM has wide latitude in how to satisfy them.

The building code analogy suggests a different risk than the one the decision record anticipates. The decision worries about intent mismatch (the LLM builds the wrong thing). The building code frame worries about constraint adequacy (the tests pass but the implementation is still wrong, because the constraints did not cover the important dimensions). This is the classic problem of high test coverage with low specification power -- all tests green, product still broken.

The workflow's diagnostic expectations partially address this by asking the human to think about *what information matters on failure*, which is a proxy for *what dimensions of behavior do I care about*. But this is a workaround for the deeper issue: behavior-level test cases are constraints, not blueprints, and the gap between them is where implementation mismatches hide.

---

## 7. Contingent Assumptions

1. **Humans can design good test cases during planning without deep implementation knowledge.** This is true for pure functions and acceptance tests. It is not true for integration tests, concurrency tests, or tests that exercise framework-specific behavior. The workflow treats human test design as uniformly applicable, but the skill required varies enormously by test level. A human who can design a good unit test case in prose may not be able to design a good property test without understanding the domain's invariants at a technical level.

2. **The four test levels (unit, integration, characterization, property) are the right taxonomy.** This is a standard taxonomy, but it omits several categories that matter in practice: end-to-end tests, performance tests, contract tests (for service boundaries), and approval/snapshot tests. The taxonomy is presented as if it covers the space. It covers the most common cases but may mislead users into thinking they have chosen from the full menu.

3. **Test-first is always feasible.** The workflow says "write the tests specified in the plan's test specification section" before implementation. But some tests cannot be written before the code they test exists -- particularly tests that depend on generated types, database schemas, or API response shapes that emerge during implementation. The refactoring variant handles this well (characterization tests first is natural), but the general case assumes a level of specification completeness that green-field features often lack.

4. **A human reviewing test code can assess specification quality.** The test review gate assumes the human can read test code and judge whether it captures their intent. This requires the human to be fluent enough in the test framework to read tests as specifications. For many human-LLM collaboration scenarios, the human is not a proficient reader of the test framework -- that is part of why they are using an LLM. The review gate may be less effective than assumed for users who are not experienced developers.

5. **The RPI workflow is the right place for this guidance.** The decision record rejected a standalone test-design workflow as "too much ceremony." But embedding detailed test guidance in RPI makes the plan section significantly longer and more complex. The plan template went from a one-liner to a 15-line section with a table, a taxonomy, and diagnostic guidance. At some point, embedding becomes its own form of ceremony -- the test section is now the longest part of the plan template, longer than the approach, steps, or risks sections.

---

## 8. What the Market Says

The "market" here is the revealed behavior of human-LLM coding workflows in practice. Several signals:

**Test-driven development has been advocated for decades but never achieved majority adoption among human developers.** The reasons are well-studied: test-first requires knowing the interface before designing it, which is often circular; writing tests for exploratory code feels wasteful; and the discipline breaks down under time pressure. If TDD struggles with human-only development, the claim that it works *better* in human-LLM collaboration needs an argument for why the LLM context changes the calculus. The decision record makes this argument implicitly (the LLM is better at writing code to satisfy tests than at inferring intent from prose), but does not engage with TDD's long history of adoption challenges.

**The most successful LLM coding tools (Cursor, Copilot, Claude Code itself) do not foreground tests as a specification mechanism.** They use natural language as the primary interface. This does not mean the test-specification approach is wrong -- the market could be under-exploring it -- but it does mean this workflow is making a contrarian bet. Contrarian bets should be explicit about what they think the market is missing. The decision record does not engage with why mainstream LLM tooling has not converged on this pattern.

**Where test-first *has* gained traction, it is in domains with formal specifications** -- protocol conformance, mathematical properties, data serialization round-trips. These are exactly the domains where the "test as specification" metaphor works best, because the specification is precise and complete. For the vaguer, more judgment-laden tasks that make up most software development ("build a settings page", "add error handling"), tests-as-specification is weaker because the interesting requirements are the ones hardest to express as test cases.

The market signal is: test-first works well in a narrow band (formal, well-specified domains) and struggles everywhere else. The workflow applies it universally. This may be right -- the structured template may help humans specify things they would otherwise leave vague -- but it is a bet against the base rate.

---

## 9. Overall Assessment

**The change is good; the framing oversells it.** The four concrete improvements (structured test section, inline taxonomy, test review gate, diagnostic guidance) are all individually defensible and collectively make the RPI workflow better. The weakest link is the structured test table, which may face the same adoption problem as the one-liner it replaced -- not because it is too vague, but because it demands too much ceremony for simple tasks.

**The strongest contribution** is the diagnostic expectations guidance. This is genuinely novel in the context of workflow documentation and addresses a real pain point (opaque test failures in LLM-generated code). If I had to keep one element and cut the rest, I would keep this.

**The weakest contribution** is the theoretical framing of tests as "the most precise, executable form of requirements." This is true in the limit but misleading in practice. Most test cases are constraints, not specifications. The framing sets up an expectation that designing test cases is equivalent to specifying behavior, which it is not -- the gap between the two is where most implementation mismatches occur.

**What to watch for:** The test review gate has an escape hatch that the plan review gate does not. If in practice the test gate is routinely bypassed ("user didn't respond promptly, proceeding"), then tests have not actually been foregrounded -- they have been given a more prominent *template position* without a more prominent *process position*. The real test of this decision is whether test review actually happens before implementation in typical usage. If it does not, the change is cosmetic.

**Fact-check items to address:** The unverifiable "13 approaches" claim should be softened or documented. The "1 + 4 + 5" framing should acknowledge the fourth element. The "central use case is external repos" framing should either be dropped (the implementation is general-purpose) or the decision record should explain why the motivating use case is stated narrowly while the implementation applies broadly.

**Confidence in this assessment:** Moderate-high. The decomposition and inversion moves are straightforward; the market analysis draws on well-documented patterns (TDD adoption rates, LLM tool design trends). The main uncertainty is whether the structured test table will see better adoption than the one-liner -- this is an empirical question that cannot be resolved by argument alone.
