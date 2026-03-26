# Cowen-Style Critique: RPI Workflow and Foregrounding Tests

**Reviewed:** 2026-03-26
**Documents:** `workflows/research-plan-implement.md`, `docs/decisions/006-foregrounding-tests.md`

---

## 1. The Argument, Decomposed

The combined thesis breaks into these sub-claims:

1. **LLMs produce better code when given structured plans.** The RPI workflow assumes that Research -> Plan -> Implement, with human checkpoints, yields better outcomes than letting the LLM code directly.

2. **Tests are a specification language, not just a verification tool.** Decision 006 argues that tests are "among the most precise forms of behavioral specification in human-LLM collaboration."

3. **Humans should design tests; LLMs should implement them.** The division of labor is: human writes behavioral constraints in prose, LLM translates to executable code.

4. **Catching mismatches at the test-review stage is cheaper than catching them after implementation.** The classic "shift left" argument, applied to human-LLM collaboration.

5. **Diagnostic quality of test failures matters more in LLM workflows than in traditional development.** Because the human may not be able to (or want to) read all the implementation code.

6. **Inline taxonomy guidance is better than a separate reference doc.** Keeping test-level guidance in the workflow rather than in a standalone document.

7. **The existing one-line testing guidance was insufficient.** The "do nothing" option was rejected because the guidance "gets skipped in practice."

These are seven distinct claims. The draft treats them as a single package, but they have very different evidentiary bases and very different risk profiles.

---

## 2. What Survives the Inversion

**Inverting sub-claim 1: "LLMs produce worse code with structured plans."** This doesn't survive well. There's broad consensus that structured prompting improves LLM output. The interesting inversion is weaker: "The overhead of the planning ceremony exceeds the quality improvement for most tasks." This has some force. The workflow's own "when to skip" section implicitly concedes this by carving out trivial changes, urgent hotfixes, and cases where you already understand the code. The question is whether the boundary is drawn in the right place.

**Inverting sub-claim 2: "Tests are not a good specification language for human-LLM collaboration."** This partially survives. Tests specify *what* but not *why*. A human writing "the function should return an empty list when the input is null" has expressed a behavior, but hasn't expressed the design rationale. An LLM implementing to pass that test might produce code that handles the null case but misunderstands the broader design intent. Tests are precise but narrow -- they specify points in the behavior space, not the shape of it.

**Inverting sub-claim 3: "LLMs should design tests; humans should review them."** This is arguably closer to how most human-LLM collaboration actually works today. The human describes the feature, the LLM writes both tests and implementation, the human reviews everything. The RPI workflow's proposed inversion -- human designs, LLM implements -- is the more unusual claim. More on this under "Revealed vs. Stated."

**Inverting sub-claim 5: "Diagnostic quality matters less in LLM workflows."** This doesn't survive at all. If anything, the argument understates the case. When a human developer's tests fail, they can set breakpoints, add logging, inspect state interactively. When an LLM's implementation fails tests, the human's primary interface is the test output. Diagnostic quality is arguably *more* important here than in traditional development. This is the strongest sub-claim in the whole argument.

---

## 3. Factual Foundation

The fact-check report (10 claims checked) provides three findings most relevant to this critique:

**The "over a dozen approaches" claim is unverifiable (Claim 7).** No artifact preserves the full list from the DD session. This matters because the decision record uses the quantity to signal thoroughness of the design process. If the actual number was 6 or 8, the claim still works -- divergent design was used, multiple alternatives were considered. The specific quantity carries more weight than the argument needs, and it cannot be verified. This is a minor credibility risk, and it is somewhat ironic for a workflow system that emphasizes artifact preservation.

**"The human designs behavioral constraints in prose, the LLM translates them into executable test code" is mostly accurate but unverified as practice (Claim 10).** This accurately describes the *designed process* but whether the translation works reliably is a separate question requiring usage data. The entire foregrounding-tests decision rests on this division of labor working in practice, and there's no usage data yet.

**"The test-strategy skill has a full taxonomy" slightly overstates (Claim 4).** The skill covers multiple test types with guidance on when to use each, but does not present them as a formal taxonomy. Minor, but it's the kind of casual inflation that can compound across a document.

---

## 4. The Boring Explanation

The most mundane account: someone using an LLM for coding discovered that test quality matters a lot when you cannot watch the LLM work, got frustrated by vague test guidance in the existing workflow, and added more structured test guidance.

This boring explanation accounts for roughly 90% of the decision. The "tests as human-LLM interface" framing is doing rhetorical work to make a straightforward improvement sound like a conceptual breakthrough. The actual change is: (a) the plan template now has a table for test cases instead of a one-liner, (b) there is inline guidance on test levels, (c) there is a checkpoint for reviewing tests before implementation, and (d) there is guidance on making test failures informative.

All four of these are good ideas. None of them required the "tests are a specification mechanism" framing to justify. A simpler framing -- "the testing section was too vague, so we made it more structured" -- explains the same changes with less theoretical overhead.

The interesting question the boring explanation raises: will the structured test table actually get filled out in practice, or will it suffer the same fate as the one-liner it replaced? The one-liner was skipped because it was too vague. The table might be skipped because it is too much ceremony. The decision record acknowledges this ("simple features can use minimal test specs") but does not define what "minimal" means or when to invoke the escape hatch.

---

## 5. Revealed vs. Stated

**Stated preference:** "The human designs behavioral constraints in prose, the LLM translates them into executable test code." This frames tests as primarily a *specification* tool.

**Revealed preference:** The diagnostic expectations column -- what should be visible when a test fails -- reveals that the authors care most about tests as a *debugging* tool. If you genuinely believed tests were primarily specifications, the diagnostic column would be secondary to the expected-behavior column. But the diagnostic column gets the longest explanation and the most specific guidance. The real pain point is not "the LLM did not know what I wanted" but "the LLM did something wrong and I could not figure out what from the test output." This is a debugging problem, not a specification problem.

**Stated preference:** The test review gate is positioned as a "human checkpoint" analogous to the plan review gate.

**Revealed preference:** The test review gate has an explicit escape hatch: "if the user doesn't respond promptly, proceed with implementation but flag that tests haven't been reviewed." The plan review gate has no such escape: "implementation does not begin until the user has reviewed the plan." The test gate is softer than the plan gate. This reveals that the authors consider the plan more important than the test specification -- which is in tension with the claim that tests are the primary interface. If tests were truly the specification mechanism, the test gate should be at least as firm as the plan gate.

**Stated preference:** Working documents are "disposable" and "freely overwritten."

**Revealed preference:** The workflow specifies a file naming convention, a directory structure, a `.gitattributes` configuration, freshness tracking rules, and a promotion path to `docs/thoughts/`. That's a lot of infrastructure for something disposable. The documents are treated as disposable in theory but managed as artifacts in practice. This isn't necessarily wrong -- ephemeral artifacts can still benefit from structure -- but the language understates the actual investment.

---

## 6. The Analogy

**Architectural blueprints vs. building codes.**

The decision record frames tests as blueprints -- the detailed specification that the builder follows. But most test cases are actually closer to building codes -- they specify constraints (the load-bearing wall must support X, the exit must be Y width) without specifying the design. A test that says "this function returns a sorted list" constrains the implementation without specifying it.

This distinction matters because blueprints and building codes have different failure modes. A blueprint that is wrong produces a building nobody wanted. A building code that is wrong either constrains too tightly (no building can pass) or too loosely (dangerous buildings pass). The workflow assumes tests work like blueprints -- the human designs the specification, the LLM implements it. But most tests work like building codes -- the human designs constraints, and the LLM has wide latitude in how to satisfy them.

The building code analogy suggests a different risk than the one the decision record anticipates. The decision worries about intent mismatch (the LLM builds the wrong thing). The building code frame worries about constraint adequacy (the tests pass but the implementation is still wrong, because the constraints did not cover the important dimensions). This is the classic problem of high test coverage with low specification power -- all tests green, product still broken.

A secondary analogy worth noting: **contract-first API design.** Teams sometimes write the API contract (OpenAPI spec, protobuf definitions) before implementing the service. The contract serves as both specification and test harness. Decision 006 is essentially proposing contract-first development for human-LLM collaboration, where the "contract" is the test specification. The contract-first analogy illuminates the key risk: contracts written before the implementation is understood tend to be revised heavily during implementation.

---

## 7. Contingent Assumptions

1. **The human has enough technical knowledge to design test cases.** The workflow assumes the human can specify "what should happen" for each scenario, choose appropriate test levels, and describe diagnostic expectations. This works for a senior developer collaborating with an LLM. It may not work for a product manager using an LLM to build a feature, or a junior developer who doesn't yet have mental models for test design. The workflow doesn't discuss who the human is.

2. **The four test levels (unit, integration, characterization, property) are the right taxonomy.** This is a standard taxonomy, but it omits several categories that matter in practice: end-to-end tests, performance tests, contract tests, snapshot tests. The workflow acknowledges this ("Other levels are valid; the test-strategy skill has a full taxonomy") but the inline guidance shapes default choices.

3. **Test-first is always feasible.** Some tests cannot be written before the code they test exists -- particularly tests that depend on generated types, database schemas, or API response shapes that emerge during implementation. The refactoring variant handles this well (characterization tests first is natural), but the general case assumes a level of specification completeness that green-field features often lack.

4. **A human reviewing test code can assess specification quality.** The test review gate assumes the human can read test code and judge whether it captures their intent. This requires fluency in the test framework. For many human-LLM collaboration scenarios, the human is not a proficient reader of the test framework -- that is part of why they are using an LLM.

5. **Sessions are relatively short and context-limited.** The handoff doc mechanism, context budget awareness, and "fresh session for implementation" advice all assume meaningful context limits. This is true today but is a rapidly moving target. A workflow designed for 2026 context windows may be over-engineering session management.

6. **Markdown artifacts are the right medium.** The entire system communicates via committed markdown files. This works well for async collaboration and version control, but some kinds of understanding resist documentation. This is a specific choice that is treated as natural.

---

## 8. What the Market Says

The "market" here is the revealed behavior of human-LLM coding workflows in practice. Several signals:

**Test-driven development has been advocated for decades but never achieved majority adoption among human developers.** The reasons are well-studied: test-first requires knowing the interface before designing it, which is often circular; writing tests for exploratory code feels wasteful; the discipline breaks down under time pressure. If TDD struggles with human-only development, the claim that it works *better* in human-LLM collaboration needs an argument for why the LLM context changes the calculus. The decision record makes this argument implicitly (the LLM is better at translating test specs into code than at inferring intent from prose), but does not engage with TDD's long history of adoption challenges.

**The most successful LLM coding tools do not foreground tests as a specification mechanism.** They use natural language as the primary interface. This does not mean the test-specification approach is wrong -- the market could be under-exploring it -- but it does mean this workflow is making a contrarian bet. Contrarian bets should be explicit about what they think the market is missing.

**Where test-first has gained traction, it is in domains with formal specifications** -- protocol conformance, mathematical properties, data serialization round-trips. These are exactly the domains where the "test as specification" metaphor works best. For vaguer, more judgment-laden tasks ("build a settings page", "add error handling"), tests-as-specification is weaker because the interesting requirements are the ones hardest to express as test cases.

The market signal is: test-first works well in a narrow band (formal, well-specified domains) and struggles everywhere else. The workflow applies it universally. This may be right -- the structured template may help humans specify things they would otherwise leave vague -- but it is a bet against the base rate.

---

## 9. Overall Assessment

**The change is good; the framing oversells it.** The four concrete improvements (structured test section, inline taxonomy, test review gate, diagnostic guidance) are all individually defensible and collectively make the RPI workflow better. The weakest link is the structured test table, which may face the same adoption problem as the one-liner it replaced -- not because it is too vague, but because it demands too much ceremony for simple tasks.

**The strongest contribution** is the diagnostic expectations guidance. This is genuinely novel in the context of workflow documentation and addresses a real pain point (opaque test failures in LLM-generated code). If I had to keep one element and cut the rest, I would keep this.

**The weakest contribution** is the theoretical framing of tests as "the most precise, executable form of requirements." This is true in the limit but misleading in practice. Most test cases are constraints, not specifications. The framing sets up an expectation that designing test cases is equivalent to specifying behavior, which it is not.

**The single most important thing to address:** The gap between the stated division of labor (human designs tests, LLM implements) and the likely actual division of labor (LLM proposes tests, human reviews). The workflow should either provide guidance for the "LLM proposes, human reviews" path -- which is what will happen most of the time -- or make a stronger case for why the human-designs path is worth the extra effort. Right now it quietly assumes the human-designs path without defending it against the more common alternative. The revealed-preference analysis (the soft test gate, the emphasis on diagnostic output over specification output) suggests the authors already suspect the human-reviews path is more realistic.

**Fact-check items to address:** The unverifiable "over a dozen approaches" claim should either be backed by a preserved artifact or accepted as imprecise. The "full taxonomy" characterization of the test-strategy skill slightly overpromises.

**Confidence in this assessment:** Moderate-high. The decomposition and inversion moves are straightforward; the market analysis draws on well-documented patterns (TDD adoption rates, LLM tool design trends). The main uncertainty is whether the structured test table will see better adoption than the one-liner -- this is an empirical question that cannot be resolved by argument alone.
