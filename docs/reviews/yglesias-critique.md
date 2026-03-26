# Yglesias-Style Critique: RPI Workflow + Foregrounding Tests

**Reviewed:** 2026-03-26
**Documents:** `workflows/research-plan-implement.md`, `docs/decisions/006-foregrounding-tests.md`

---

## 1. The Goal vs. the Mechanism

The goal is exactly right: when a human collaborates with an LLM on code, the biggest risk is the LLM building the wrong thing. Tests are a natural place to catch that because they express intent in a checkable form. You want humans to design behavioral constraints and LLMs to translate them into code. No disagreement there.

The mechanism, though, front-loads a significant amount of specification work into the planning phase. The human is now asked to fill out a table with test cases, test levels, diagnostic expectations, and expected behavior — before any code exists. This is the test-driven development pitch repackaged as a workflow artifact, and it has the same adoption problem TDD has always had: most people don't do it, even when they agree it's a good idea. The decision record acknowledges this ("the guidance exists but is a throwaway line that gets skipped in practice"), but the fix is to make the throwaway line into a structured table. That is not obviously more skip-proof; it is just more to skip.

The mechanism also introduces a second human review checkpoint (test code review before implementation). The workflow already has a firm gate at plan review and a soft gate at research review. Adding a third checkpoint means the human is being asked to review *three times* before any feature code is written. That is a lot of gates for a process whose core value proposition is accelerating development.

There is a structural mismatch worth naming: the human writes prose test cases, the LLM translates them into test code, and then the human reviews the test code. The review step requires the human to operate in the LLM's medium (code) rather than their own (prose). The workflow does include a mitigating instruction — "include a bulleted summary of what each test verifies alongside the test code" — which helps, but the underlying dynamic remains: the translation step where misunderstandings happen is still there. It has moved from "translate requirements into implementation" to "translate requirements into tests, then translate tests into implementation." This is progress! Moving the ambiguity earlier in the pipeline is genuinely cheaper to fix. But calling tests "the most precise form of behavioral specification" overstates what is happening when the specification is a prose table that still requires translation.

## 2. The Boring Lever

The boring lever: **just make the LLM write tests first during implementation, without requiring the human to pre-specify them in a structured table format.**

The LLM already has the plan. It already knows what the code should do. Having it write tests first — and having those tests be a separate, reviewable commit — gets you 80% of the "catch mismatches early" benefit without requiring the human to learn a test taxonomy or fill out a diagnostic-expectations column during planning.

The human can review the test commit and say "that's not what I meant" before implementation proceeds. That is the same feedback loop the workflow is trying to create, just without the planning-phase ceremony.

The diagnostic expectations guidance (lines 97-99 of the RPI workflow) is actually the most important part of this proposal, and it gets the least structural emphasis. It is a bullet point under the test specification table, not a first-class concern. If you could only do one thing from this entire proposal, "make test failures informative enough that the human can diagnose without re-running or reading all implementation code" would deliver more value than the test case table.

## 3. Follow the Money (or Effort)

Trace where human attention actually flows in the revised workflow:

1. **Research**: LLM reads code, writes a doc. Low human effort.
2. **Plan + test specification** (expanded): The human now has to think about test cases, pick test levels, and write diagnostic expectations. This is real cognitive work. The question is whether it is the *right* cognitive work at this stage.
3. **Plan approval**: Human reviews. Medium effort.
4. **Test code review** (new): Human reviews LLM-generated test code. Medium effort — or a rubber stamp if the human cannot read test code fluently.
5. **Implementation**: LLM implements. Low human effort.
6. **Implementation review**: Human reviews. Medium effort.

The total attention budget increased by one checkpoint (test review) and one planning section (structured test specification). Whether the test-review checkpoint actually catches mismatches depends on the human's ability to read test code. The proposal is highest-value for humans who are intermediate: they know enough to read test code and spot mismatches, but not enough to write tests from scratch. That is a real population, but the workflow does not name it.

The effort distribution also shifts noticeably toward the human during planning. The whole point of human-LLM collaboration is that the human provides judgment while the LLM provides labor. Asking the human to fill out a structured table with four columns is nudging toward more labor. The judgment version is: "here are the scenarios I care about, in plain language." The labor version is: "here is a table with columns for test level and diagnostic expectation." The workflow defaults to the labor version.

## 4. Factual Foundation

Key findings from the fact-check report:

- The `linguist-generated` gitattributes trick works as described (Claim 1: Accurate). Practical and well-sourced.
- The "full taxonomy" characterization of the test-strategy skill slightly overstates what the skill provides (Claim 4: Mostly accurate). The skill covers multiple test types but does not present them as an organized classification system. This matters because the workflow references it as a comprehensive external resource — it is not quite that.
- "Over a dozen approaches were generated via divergent design" is unverifiable (Claim 7: Unverified). No artifact preserves the full list. The wording was already softened from "13 approaches," but even "over a dozen" relies on conversational context that no longer exists. This is the kind of precision theater that makes readers trust documents less, not more.
- "The human designs behavioral constraints in prose, the LLM translates them into executable test code" describes a designed process, not a verified outcome (Claim 10: Mostly accurate). Nobody has checked whether this translation works reliably in practice.
- The "combine 1 + 4 + 5, plus diagnostic guidance" framing now correctly accounts for all four implementation elements (Claim 9: Accurate, previously flagged discrepancy resolved).

## 5. The Scale Test

What happens when many different humans use this across many projects?

**Sophisticated developers** will find the table redundant. They already think about test cases during planning. They will abbreviate to "a few test cases in prose" (as explicitly permitted) and treat the test-review checkpoint as a quick sanity check.

**Less experienced developers** will struggle with the test level taxonomy. Four bullet points defining unit, integration, characterization, and property tests are not enough for someone without an existing mental model. They will default to "unit" for everything or ask the LLM to pick, defeating the purpose of human-designed test specifications.

**The messy middle** — developers who know their domain but are not testing experts — is where this delivers the most value. But at scale, the structured table becomes a compliance burden. Early adopters fill it out thoughtfully. Later adopters treat it like a form. "Diagnostic expectation: show the error" appears in every row. The "simple features can be brief" escape hatch becomes the universal default, because at scale everything is a "simple feature" when the alternative is filling out a table.

The two new review stages (test specification during planning, test code review during implementation) will get rubber-stamped as fatigue sets in. The more review stages you add, the less attention each one gets.

## 6. The Org Chart

The workflow is designed for a single human working with a single LLM session. But the broader workflow system includes parallel-sessions guides and branch-strategy workflows for concurrent feature development. If someone is running three parallel feature branches with three LLM sessions, they are now doing test specification and test code review for three concurrent workstreams. That is where the per-feature overhead compounds.

The handoff point between human and LLM is the test specification table, and it is the weakest link. The human writes prose; the LLM writes code; the human reviews code. The prose summary instruction helps bridge this, but the fundamental medium mismatch remains. A stronger design would make the prose-to-prose review the primary path and code review the spot-check.

The decision record does not address who maintains the test taxonomy guidance over time. Since it is inline in the RPI workflow (not a separate doc), updating it means modifying the core workflow document. For a workflow that is already approaching process-manual complexity, this matters.

## 7. Political Survival

**What will stick:** The test-first gate — write tests before implementation, commit them separately, human can review. This is a genuinely good practice with a clear benefit. Developers who have been burned by intent mismatches will adopt it.

**What will not stick:** The four-column test specification table as a planning default. The test level taxonomy for non-expert users. The diagnostic expectations column for anyone who has not experienced the pain of uninformative test failures.

**The popular version:** Keep the test-first gate. Drop the structured table as the default format. Let the human write test cases however they want — prose bullet points are fine. Move the test level taxonomy and diagnostic expectations to optional guidance rather than table columns. Add one line of implementation instruction: "When writing test code, include descriptive failure messages with expected-vs-actual values." That is a code-generation instruction, not a planning artifact.

This gets the core benefit (tests as a specification checkpoint between human and LLM) without the planning overhead that kills adoption.

## 8. The Cost Disease Check

The RPI workflow started as a simple research-plan-implement loop. It now includes: pivot guidance, working document conventions, freshness tracking, design decision integration via DD, plan annotation conventions, file size discipline, context management guidance, session handoff docs, abbreviation rules, a refactoring variant, and now a structured test specification table, inline taxonomy, a review gate, and diagnostic guidance.

Each addition is individually justified. But the cumulative effect is a workflow document approaching the complexity of a process manual. At some point, the workflow document itself needs the "file size discipline" treatment it prescribes for code — splitting into a core loop and supplementary guides. The test specification table and taxonomy, for example, could be a reference appendix rather than inline content, reducing the cognitive weight of the main flow while preserving access for those who need it.

The trajectory concern is real: if each iteration adds another gate or structured section, you are on the escalator. The check against this is whether each addition reduces total time-to-working-code. The test-first gate probably does (catching specification mismatches early is genuinely cheaper). The structured test specification table probably does not — it adds planning time without a proportional reduction in downstream cost, because the LLM can infer most of what the table asks for from the plan's approach and steps sections.

## 9. Overall Assessment

This is a good idea with a somewhat overengineered implementation. The core insight — make tests a first-class part of the workflow so the human specifies behavior before the LLM implements it — is sound and addresses a real failure mode in human-LLM collaboration.

**Sound parts:**
- Test-first during implementation is a genuinely good default. The separate test commit is the strongest idea here.
- The insight that test failures are the human's primary debugging interface is correct and underappreciated.
- Inline test-level guidance is better than pointing to an external reference doc.
- The prose summary alongside test code bridges the medium gap between human and LLM.

**Wish-fulfillment parts:**
- The structured test specification table assumes humans will do upfront specification work they historically do not do, even when they agree it is valuable.
- Three human review checkpoints before feature code exists assumes sustained reviewer attention that erodes at scale.
- "Diagnostic expectations" as a planning-phase column assumes the human knows enough about failure modes to specify diagnostics before the code exists.

**Most important revision:**
Separate the *implementation instruction* ("write tests first, commit them separately, include good failure messages") from the *planning artifact* ("fill out this table with four columns"). The former is high-value and low-cost. The latter is the part that will be abandoned, and when it is, people will feel like they are "not doing the workflow right" and stop doing any of it. Make the high-value part the unambiguous default and the structured planning table an optional practice for complex features, rather than the other way around.
