---
Last verified: 2026-03-23
Relevant paths:
  - skills/fact-check.md
  - skills/code-fact-check.md
  - test/
---

# Cowen-Style Critique: Fact-Check Skills Test Strategy

## The Argument, Decomposed

The draft's implicit thesis -- "prompt-based skills can be meaningfully tested through structured evaluation scenarios" -- breaks into these sub-claims:

1. **Format compliance is mechanically testable.** BATS tests can verify that LLM-generated reports conform to a structural specification (headers, verdict scales, sequential numbering, required fields).

2. **Behavioral correctness can be evaluated via fixtures with known answers.** If you feed a fixture containing a deliberately wrong claim (e.g., "returns null" when code returns undefined), you can check whether the skill catches it.

3. **The fixture set covers the relevant claim space.** The categories (claim types, verdict distribution, non-checkable content, ambiguity, guardrails) represent the dimensions that matter for skill quality.

4. **Cross-skill consistency is a meaningful property to test.** The two skills should use their respective verdict scales and apply similar thresholds.

5. **Human evaluation is an acceptable tier for behavioral tests.** The eval-criteria documents are designed for a human (or a second LLM) to judge, not for CI automation.

6. **The test inputs themselves are well-calibrated.** The fixtures contain claims whose ground truth is known and stable enough to serve as reference answers.

---

## What Survives the Inversion

**Inversion: "Prompt-based skills cannot be meaningfully tested through structured evaluation."**

Sub-claim 1 (format compliance) survives inversion easily. The BATS tests are straightforward regex checks against a structured document. If the skill produces a report, these tests tell you whether it followed the template. This is the least interesting part of the suite and also the most robust. It is essentially testing string formatting, which is one of the things LLMs are already quite good at.

Sub-claim 2 (behavioral correctness via fixtures) is shakier under inversion. The concern: an LLM-based skill might produce the "right" verdict for wrong reasons (e.g., pattern-matching the fixture's framing rather than actually searching), or produce different verdicts on different runs. The fixtures bake in the assumption that there is a deterministic "correct" answer, but the fact-check report itself shows this is not always true -- Claim 9 (France homeschooling) could defensibly be rated either "Mostly accurate" or "Inaccurate." So the evaluation criteria need to tolerate a range, which they do in some cases (TC-1.1 says "Any verdict" with process checks) but not others (TC-2.4 firmly expects "Inaccurate"). The suite is inconsistent about how much verdict ambiguity it allows.

Sub-claim 3 (coverage of the claim space) partially crumbles. The categories are reasonable but conspicuously omit some real-world scenarios: drafts in languages other than English, claims that require multi-step reasoning chains, claims embedded in complex document structures (tables, footnotes, nested lists), and -- most importantly -- claims where the "right" answer changes over time. All the fixtures feel like undergraduate exam questions: self-contained, with clear answers. Real fact-checking is messier.

Sub-claim 5 (human evaluation is acceptable) survives but raises the question: if a human must evaluate whether the skill identified the right claims and reached the right verdicts, how is this different from just... running the skill and reading the output? The eval criteria add structure, but the actual evaluation loop is still "a person reads the report and judges it." The marginal contribution of the test infrastructure over "just try it" needs to be stated more clearly.

---

## Factual Foundation

The fact-check report found 2 inaccurate claims, 4 mostly accurate, 1 disputed, 3 unverified, and 4 accurate across the 14 claims checked in the fixtures.

Key findings that matter for this critique:

- **The $4.3 trillion healthcare figure (Claim 1) is wrong** -- actual 2023 spending was $4.9 trillion. The test strategy does not specify an expected verdict for TC-1.1, which means it is testing process (did the skill cite CMS data?) rather than outcome. This is fine, but it means a skill could produce "Accurate" on a wrong number and still pass the test. The eval criteria should note the claim is intentionally inaccurate.

- **Oregon SB 458 (Claim 2) is completely misdescribed** -- it is a middle-housing bill, not a tenant appreciation law. Same issue: TC-1.2 checks process, not verdict. But unlike TC-1.1, this is not a matter of being slightly off -- the bill does something entirely different from what the fixture claims. A skill that merely confirms "yes, SB 458 exists" without catching the mismatch would pass the test as written.

- **The France homeschooling claim (Claim 9)** sits in an ambiguity zone where the test expects "Inaccurate" but "Mostly accurate" is also defensible. This is exactly the kind of case where a verdict-based evaluation will produce false negatives.

- **The Florida waitlist figure (Claim 14, 40,000 families)** is unverified and possibly wrong, but it appears in TC-3.3 as one of the claims the skill should identify as checkable. If the skill correctly identifies it as checkable and then correctly reports it as "Unverified," great -- but the eval criteria list it alongside claims with known answers without flagging that this one is different.

---

## The Boring Explanation

The most mundane account of what is happening here: someone is building a test suite for two LLM-based tools and doing it the way software engineers always do -- write some fixtures, check some outputs, organize into categories. The categories mirror the skills' own documentation (claim types, verdict scales, edge cases). The fixtures are hand-crafted to exercise each category.

This boring explanation accounts for nearly everything in the draft. The test strategy is a competent engineering document. It is not advancing a novel theory of LLM evaluation. It is applying the standard "golden test" pattern from conventional software testing to a domain where the outputs are non-deterministic. The interesting question it does not address is: does the standard pattern actually work here?

Most of the value in this suite probably comes from three things: (a) catching regressions in output format after prompt changes, (b) providing a structured way to onboard someone new to what the skills should do, and (c) creating a library of "should we be worried about this?" edge cases. The first is real but narrow. The second is about documentation, not testing. The third is the most genuinely valuable -- the fixture set is a catalog of the hard cases.

---

## Revealed vs. Stated

**Stated preference:** The test strategy treats all six categories as equally important, devoting comparable space to each.

**Revealed preference:** The only tests that actually run in CI are the format compliance tests (Category 5). Everything else is labeled for "human or automated evaluation" -- meaning, in practice, it runs when someone remembers to run it. The architecture reveals that the authors trust format compliance enough to automate it, but do not trust behavioral evaluation enough to automate it. This is an honest assessment of the state of the art, but the test strategy document does not acknowledge this asymmetry. It presents a uniform facade over what is actually a two-tier system with very different reliability characteristics.

**Stated preference:** The skills should use web search for every claim (TC-6.2: "Evidence of web search for EVERY claim").

**Revealed preference:** There is no test that verifies web search was actually used. The BATS tests check output format; the eval criteria check verdicts and explanations. Whether the skill actually searched the web or relied on training data is not observable from the output alone. This is a guardrail that cannot be tested with the testing infrastructure provided. The stated requirement is aspirational rather than enforced.

**Stated preference:** The test suite covers "the relevant claim space" (claim types, verdicts, edge cases).

**Revealed preference:** Every single fact-check fixture is about US domestic policy, and every code fixture is in JavaScript (with two Python files for concurrency). The claim space the authors actually care about is English-language US policy drafts and JS/Node.js codebases. That is fine -- scope limitations are normal -- but the test strategy frames itself as comprehensive without noting these boundaries.

---

## The Analogy

The closest cross-domain parallel is **standardized patient encounters in medical education**. Medical schools use actors who present with scripted symptoms to evaluate whether students reach the right diagnosis. The students know they are being tested; the scenarios are designed to hit specific learning objectives; and the evaluation combines structured checklists (did they check blood pressure? did they ask about family history?) with holistic judgment (was the clinical reasoning sound?).

This test suite is doing the same thing. The fixtures are standardized patients. The BATS tests are the procedural checklist (did the student wash their hands?). The eval criteria are the clinical reasoning rubric.

The analogy is instructive because medical education has learned two things about standardized patients that apply here: (1) performance on scripted scenarios does not reliably predict performance on real patients, because real patients do not organize their symptoms into neat categories; and (2) the checklist items (procedural compliance) are weakly correlated with the holistic judgment (clinical reasoning quality). The best diagnosticians sometimes skip steps. The most thorough step-followers sometimes miss the diagnosis.

Translated: a fact-check skill that produces perfectly formatted reports and catches the "Great Wall from space" myth may still fail on a real draft where claims are embedded in complex arguments, use ambiguous language, and require chaining multiple pieces of evidence together. The test suite can tell you the skill graduated from medical school. It cannot tell you the skill is a good doctor.

---

## Contingent Assumptions

1. **The verdict scales are natural joints.** The five verdicts for fact-check and five for code-fact-check are presented as if they carve reality at its joints. But "Mostly accurate" vs. "Inaccurate" is a judgment call that depends on context (how much does the error matter to the argument?). The France homeschooling case demonstrates this directly. These categories are design choices, not discovered truths.

2. **Single-claim fixtures are representative.** Most fixtures contain exactly one claim type in isolation. Real drafts mix claim types in complex ways. A fixture that tests "can the skill handle a causal claim?" tells you less than you might think, because in practice the skill must distinguish causal claims from opinions and comparisons all in the same paragraph. TC-3.3 (mixed) and TC-5.1 (multi-claim) are the only fixtures that test this, and they are in the minority.

3. **The skills run as isolated passes.** The test strategy assumes each skill runs once on a static input and produces a complete report. But the skill prompts mention orchestration (draft-review), where the fact-check report feeds into downstream critic agents. The test suite does not test the orchestrated case at all beyond verifying the output path. The interaction effects -- does the fact-check report's framing influence the critic's judgment? -- are untested.

4. **Fixture claims have stable ground truth.** The Austin rents claim (15% drop) is a moving target -- the correct figure depends on the time period, source, and methodology. The test suite treats it as having a known answer, but the answer changes. This is a general problem with testing fact-checkers on empirical claims: the facts change, and the test suite becomes stale in exactly the way it is designed to catch.

5. **English, US policy, JavaScript.** The entire fixture set assumes these specific contexts. A fact-check skill deployed on a draft about EU energy policy or a code-fact-check run on a Rust codebase would exercise entirely different capabilities. The test suite's coverage claims are contingent on this narrow scope.

---

## What the Market Says

There is no literal market here, but the revealed behavior of the AI-tools ecosystem is informative. Most LLM-based coding tools do not ship with evaluation suites of this kind. They rely on user feedback, A/B testing, and benchmark datasets. The fact that this project is building bespoke evaluation infrastructure suggests one of two things: either the authors have already experienced the failure mode where skill quality degrades silently after prompt changes (in which case this is battle-tested wisdom), or they are over-engineering for a problem they have not yet encountered (in which case this is premature optimization of the testing layer).

The "market" for LLM evaluation frameworks has settled on a few patterns: reference-based evaluation (compare to gold answers), model-based evaluation (use a second LLM to judge), and human evaluation with structured rubrics. This test suite uses all three but automates only the weakest signal (format compliance). The market is telling you that automating behavioral evaluation of LLM outputs is hard. The test suite implicitly agrees by punting behavioral evaluation to humans.

---

## Overall Assessment

**Strong sub-claims:**
- Format compliance testing via BATS is solid and should catch regressions. (Sub-claim 1)
- Cross-skill verdict scale isolation is a good idea and well-implemented in the BATS tests. (Sub-claim 4)
- The fixture catalog itself is valuable as a reference for what the skills should handle. (Sub-claims 2, 3)

**Weak sub-claims:**
- The behavioral evaluation criteria are structured checklists for manual review, which is barely distinguishable from "just run the skill and read the output." The marginal value over ad-hoc testing is unclear. (Sub-claim 5)
- The fixture set has significant blind spots (non-English content, complex multi-claim documents, orchestrated runs, time-sensitive claims) that the test strategy does not acknowledge. (Sub-claims 3, 6)
- Several fixtures contain claims whose ground truth is itself uncertain or contested, creating evaluation criteria that may produce false negatives. (Sub-claim 6)

**The single most important thing to address:** The test strategy needs to be honest about the two-tier nature of its testing. The automated tier (BATS format tests) is reliable but tests something easy. The manual tier (eval criteria) tests something hard but is not automated and may not run consistently. Right now the document presents both tiers as part of a unified strategy, which obscures the fact that almost all the interesting tests require a human in the loop. If the goal is to catch regressions, the eval criteria need a path toward automation (e.g., using a second LLM as evaluator with structured rubrics). If the goal is to document expected behavior, the eval criteria should be framed as a specification, not a test suite.

Additionally, the factual errors in the fixtures (healthcare spending at $4.3T instead of $4.9T, Oregon SB 458 described completely wrong) are features if they are intentional test inputs but bugs if they are meant to represent accurate drafts. The test strategy is ambiguous about this in several cases. Each fixture should state whether the claims it contains are intentionally accurate, intentionally inaccurate, or unknown -- otherwise an evaluator cannot tell whether the skill's verdict is correct.
