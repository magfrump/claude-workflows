# Yglesias-Style Critique: Foregrounding Tests in the RPI Workflow

## 1. The Goal vs. the Mechanism

The goal is exactly right: tests are the most precise form of requirements, and getting the human to express intent as test cases before implementation begins is a genuinely good idea. If your problem is "the LLM builds the wrong thing," then having the human specify what the right thing looks like in executable terms is the obvious solution. No disagreement there.

But the mechanism has a structural mismatch with how the goal is supposed to work. The proposal says tests are "the most precise, executable form of requirements" and positions them as an interface between human specification and LLM implementation. Great. But then look at what the human is actually asked to produce: a table with columns for "Test case," "Expected behavior," "Level," and "Diagnostic expectation." That is not an executable specification. That is a requirements document in table form. The LLM still has to translate from the human's prose description of "what scenario" and "what should happen" into actual test code. The translation step — the step where misunderstandings happen — is still there. It has just moved from "translate requirements into implementation" to "translate requirements into tests, then translate tests into implementation."

This is progress! Moving the ambiguity earlier in the pipeline is genuinely cheaper to fix. The test-review gate (step 5) catches mismatches before implementation work is invested. But calling this "tests as a human-LLM interface" overstates what is happening. What is actually happening is "structured requirements with a review checkpoint before implementation." The tests are the checkpoint, not the interface.

The mechanism would match the goal if the human wrote actual test code (or pseudocode close enough to compile). Some humans can do that. Most cannot without deep framework knowledge, and the decision record acknowledges this — "human-designability" was a constraint, meaning "tests must be specifiable without deep framework knowledge." So the mechanism was designed around the constraint that the human cannot actually write executable specifications, which means calling them executable specifications is aspirational rather than descriptive.

## 2. The Boring Lever

The boring lever nobody is pulling: **run the tests continuously during implementation and stop the LLM when they fail.**

The proposal focuses on test *design* (getting the right test cases) and test *review* (confirming tests match intent). These are both valuable. But the highest-value moment for tests is not when they are designed or reviewed — it is when they fail during implementation and provide immediate feedback. The existing RPI refactoring variant already says "run tests after every step." The new proposal could simply extend that principle to all RPI usage (not just refactoring), require that tests are written before implementation (which it does), and emphasize that test failures during implementation are the primary feedback channel (which it does not).

The diagnostic expectations section (line 95 of the RPI workflow) is actually the most important part of this proposal, and it gets the least structural emphasis. It is a bullet point under the test specification table, not a first-class planning concern. If you could only do one thing from this entire proposal, "make test failures informative enough that the human can diagnose without re-running or reading all implementation code" would deliver more value than the test case table.

## 3. Follow the Money (Follow the Tokens/Attention)

Trace where human attention and LLM tokens actually flow in this revised workflow:

1. **Human writes test specification table** — moderate attention cost. The human has to think about test cases, levels, and diagnostic expectations for each case. This is real cognitive work, not ceremony. Good.

2. **LLM translates table into test code** — moderate token cost. The LLM reads the plan's test specification and writes runnable tests. This is a well-constrained generation task. Good.

3. **Human reviews test code** — this is the new checkpoint, and it is where the proposal's economics get questionable. The human specified tests in plain language. Now they have to review those tests in code, in whatever testing framework the project uses. This requires the human to read test code fluently enough to confirm it matches their intent. If the human could do that, they could probably have written the tests themselves. If they cannot, the review checkpoint is a rubber stamp.

4. **LLM implements to make tests pass** — standard TDD. The tests constrain the implementation. Good.

5. **Human reviews implementation** — same as before.

The total attention budget increased by one checkpoint (test review). Whether that checkpoint actually catches mismatches depends entirely on the human's ability to read test code — which is the same ability that would let them skip the prose specification table and write tests directly. The proposal's value is highest for humans who are intermediate: they know enough to read test code and spot mismatches, but not enough to write tests from scratch. That is a real population, but it is worth naming explicitly rather than assuming it is everyone.

## 4. Factual Foundation

The fact-check report found 8 claims, with three requiring attention:

**Unverifiable — "13 approaches were generated via divergent design"**: Only 6 are listed, and no artifact preserves the full set. This matters for the decision record's credibility. Claiming 13 options were explored signals thoroughness, but if only 6 survived and the other 7 exist only in a conversation that is no longer accessible, the claim is unfalsifiable. The decision record should either preserve the full list or soften the number. Saying "over a dozen" without a verifiable artifact is the kind of precision theater that makes readers trust documents less, not more.

**Mostly accurate — "Combine approaches 1 + 4 + 5"**: The implementation actually has 4 elements (the fourth being diagnostic guidance). This is a minor bookkeeping error, but in a decision record — a document whose purpose is to record what was decided and why — getting the count wrong undermines the format. Either fold diagnostic guidance into approach 1 or say "1 + 4 + 5, plus diagnostic guidance as a cross-cutting concern."

**Disputed — "The central use case is code development in other repos"**: The implementation applies to all RPI usage, not just external repos. This is the most substantive factual finding because it reveals a gap between the decision's framing and its implementation. The decision record motivates the change as being about code development, but the mechanism is embedded in a general-purpose workflow. If the "central use case" claim is true, there should be guidance about when the test specification section can be abbreviated for non-code tasks. If it is not true, the framing should be honest about the general-purpose scope.

## 5. The Scale Test

What happens when many different humans use this workflow across many different projects?

**Sophisticated developers** will find the test specification table redundant. They already think about test cases during planning. The table adds structure to something they were doing informally, which is mildly useful but not transformative. They will abbreviate it to "a few test cases in prose" (as the workflow allows) and treat the test-review checkpoint as a quick sanity check.

**Less experienced developers** will struggle with the test level taxonomy. The inline guidance is brief — four bullet points defining unit, integration, characterization, and property tests. For someone who does not already have a mental model of test levels, these definitions are not enough to make informed choices. They will default to "unit" for everything or ask the LLM to pick, which defeats the purpose of human-designed test specifications.

**The messy middle** — developers who know their domain but are not testing experts — is where this proposal delivers the most value. Forcing them to think about test cases and expected behavior before implementation will catch requirements gaps. The test level taxonomy will expand their vocabulary even if they do not always choose correctly. The diagnostic expectations section will improve their test failure output incrementally.

The scale concern: the test specification table is mandatory structure for every RPI usage. The workflow says "for simple features, this section can be brief," but the table format with four columns is the default. Mandatory structure that is routinely abbreviated becomes noise — people fill it in with minimal effort to pass the gate, and the gate stops catching anything. A better default might be: require test cases and expected behavior (two columns), make level and diagnostic expectations optional but recommended.

## 6. The Org Chart

Who does what in this revised workflow?

**The human** specifies test cases in prose, chooses test levels, describes diagnostic expectations, and reviews test code. This is a meaningful design role — the human is defining the behavioral contract. But it requires the human to do work they may not have skills for (choosing test levels, specifying diagnostic expectations) and to review artifacts they may not be able to evaluate (test code in a specific framework).

**The LLM** translates prose specifications into runnable test code, then implements code to make those tests pass. This is well-suited to LLM capabilities: structured translation (prose to code) and constrained generation (make tests pass). The test-first gate also gives the LLM a clearer success criterion than "implement the plan" — if the tests pass, the implementation is at least directionally correct.

**The handoff point** is the test specification table, and it is the weakest link. The human writes prose; the LLM writes code; the human reviews code. The review step requires the human to operate in the LLM's medium (code) rather than their own (prose). A stronger handoff would have the LLM produce a prose summary of what its tests actually test, alongside the test code, so the human can review in their own medium and spot-check the code. The proposal does not include this step.

## 7. Political Survival

Will users actually adopt this? The proposal has several things going for it:

- It is embedded in the existing RPI workflow, not a separate process. Users do not have to remember to invoke it.
- The "simple features can be brief" escape valve prevents it from being onerous for small changes.
- The test-review checkpoint provides a visible benefit: catching intent mismatches before implementation.

And several things working against it:

- **The test specification table is front-loaded work.** Users have to do more thinking during planning, which is the phase where they are most eager to move forward. The temptation to dash off minimal test specs and move to implementation is strong.
- **The test-review checkpoint is a second gate.** The workflow already has a plan-review gate (step 4). Adding a test-review gate (step 5) means two pauses before implementation. Users who were already impatient with one gate will resent two.
- **The taxonomy is jargon.** "Characterization test" and "property test" are terms of art that many working developers do not use. The inline guidance helps, but seeing unfamiliar vocabulary in a planning template creates a "this is not for me" reaction.

Prediction: the test specification section will be widely adopted in abbreviated form (a few test cases in prose, skipping the table format). The test-review gate will be adopted by users who have been burned by intent mismatches and skipped by everyone else. The taxonomy will be ignored by most users and valued by the minority who already understand it. The diagnostic expectations section will be the sleeper hit — the users who adopt it will see immediate quality improvements in their test failure output, but most users will not bother until they have experienced the pain of uninformative failures.

## 8. The Cost Disease Check

The proposal adds structure to a workflow that was already the most structured process in this repo. RPI is 6 steps with sub-steps, variants, and escape hatches. This change adds:

- A structured table format to one existing bullet point (test specification)
- A new taxonomy section within the plan phase
- A new checkpoint between planning and implementation
- Diagnostic guidance as inline content

This is moderate structural growth, not runaway cost disease. The concern is not this change in isolation but the trajectory. The RPI workflow started as a simple research-plan-implement loop. It now has: pivot guidance, working document conventions, freshness tracking, design decision integration via divergent design, plan annotation conventions, file size discipline, context management guidance, session handoff docs, abbreviation rules, and a refactoring variant. Adding test specification structure, a taxonomy, a review gate, and diagnostic guidance continues this accretion pattern.

Each addition is individually justified. But the cumulative effect is a workflow document that is approaching the complexity of a process manual. At some point, the workflow document itself needs the "file size discipline" treatment it prescribes — splitting into a core loop and supplementary guides. The test specification table and taxonomy, for example, could be a reference appendix rather than inline content, reducing the cognitive weight of the main workflow while preserving access.

## 9. Overall Assessment

This is a good idea with a slightly overengineered implementation. The core insight — make tests a first-class planning artifact so the human specifies behavior before the LLM implements it — is sound and addresses a real failure mode in human-LLM collaboration. The test-review gate is the mechanism's strongest feature: it creates a cheap checkpoint that catches intent mismatches before implementation work is invested.

Three adjustments would make this more likely to succeed:

1. **Simplify the default table.** Require test cases and expected behavior. Make test level and diagnostic expectations recommended columns, not default ones. This lowers the barrier for simple features and reserves the full table for complex ones where the taxonomy and diagnostics actually matter.

2. **Add a prose summary step to the test-review gate.** When the LLM writes test code, have it also produce a plain-language summary: "Here is what these tests verify: [bulleted list]." This lets the human review in their own medium (prose) and spot-check the code, rather than requiring fluent code reading to confirm intent.

3. **Move the taxonomy and diagnostic guidance to an appendix or reference section.** Keep the main workflow lean — "specify test cases during planning, write tests before implementation, review tests before proceeding." Put the test level definitions and diagnostic patterns somewhere accessible but not inline. The users who need them will look them up; the users who do not will not be intimidated by them.

The proposal is net positive. It moves the RPI workflow in the right direction. The risk is that it adds enough structural weight to push the workflow past the point where users read it carefully, which would ironically undermine the test specification section's goal of getting humans to think carefully about behavior before implementation.
