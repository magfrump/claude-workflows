# Fact-Check Skill: Evaluation Criteria

Each test case maps a fixture file to expected behavior. An evaluator (human or
automated) runs the skill against the fixture, then checks the report against
these criteria.

Verdict codes: **A** = Accurate, **MA** = Mostly accurate, **D** = Disputed,
**I** = Inaccurate, **U** = Unverified.

---

## Category 1: Claim Type Coverage

| TC | Fixture | Expected Verdict | Key Check |
|----|---------|-----------------|-----------|
| 1.1 | `tc-1.1-specific-numbers.md` | Any (check CMS/BEA data) | Report cites CMS or BEA data with year; verdict includes source citation |
| 1.2 | `tc-1.2-named-policies.md` | Any | Report looks up actual text of Oregon SB 458; verdict describes what the bill actually does |
| 1.3 | `tc-1.3-attributed-facts.md` | A | Correctly confirms MN legalized recreational cannabis in 2023 |
| 1.4 | `tc-1.4-causal-claims.md` | Any | Checks BOTH the magnitude claim (15% drop) AND the causal link separately; cites housing data |
| 1.5 | `tc-1.5-comparisons.md` | MA or D | Checks what fraction of OECD countries actually provide universal pre-K; notes that "most" may be imprecise |
| 1.6 | `tc-1.6-anecdotes.md` | U | Cannot find primary source for the specific anecdote; does not fabricate one |

## Category 2: Verdict Distribution

| TC | Fixture | Expected Verdict | Key Check |
|----|---------|-----------------|-----------|
| 2.1 | `tc-2.1-accurate.md` | A | High confidence; cites Census Bureau |
| 2.2 | `tc-2.2-mostly-accurate.md` | MA | Explains which surveys the "70% / fifth" figure conflates |
| 2.3 | `tc-2.3-disputed.md` | D | Cites BOTH the UW study and the Berkeley study; presents both sides |
| 2.4 | `tc-2.4-inaccurate.md` | I | Explains France restricted (not banned) homeschooling |
| 2.5 | `tc-2.5-unverified.md` | U | Does not fabricate a source for the bakery claim |

## Category 3: Non-Checkable Content

| TC | Fixture | Expected Behavior |
|----|---------|-------------------|
| 3.1 | `tc-3.1-opinions.md` | Few or zero claims checked; does not fact-check value judgments |
| 3.2 | `tc-3.2-predictions.md` | Does not treat forward-looking predictions as checkable facts |
| 3.3 | `tc-3.3-mixed.md` | Report contains only the checkable claims (~4: worker count, median pay, FL waitlist, Denmark spending); skips opinion sentences |

## Category 4: Ambiguity Handling

| TC | Fixture | Expected Behavior |
|----|---------|-------------------|
| 4.1 | `tc-4.1-misleading.md` | Flags ambiguity; checks the most natural reading ("best healthcare" by general metrics); notes narrow readings where the claim is true |
| 4.2 | `tc-4.2-conflated-stats.md` | Detects that "70% of parents" and "fifth of income" come from different surveys; explains the conflation |

## Category 5: Output Format Compliance

| TC | Fixture | Expected Behavior |
|----|---------|-------------------|
| 5.1 | `tc-5.1-multi-claim.md` | Report has: title header, author/date/counts/summary line, claims ordered by appearance, sequential numbering, "Claims Requiring Author Attention" section at end |
| 5.2 | (any standalone run) | Report saved to `docs/reviews/fact-check-report.md` |
| 5.3 | (orchestrated run) | Report follows orchestrator's specified path, not the default |

## Category 6: Behavioral Guardrails

| TC | Fixture | Expected Behavior |
|----|---------|-------------------|
| 6.1 | `tc-6.1-accurate-weak-argument.md` | All fact verdicts are A (or close); skill does NOT comment on argument quality or logical gaps |
| 6.2 | (any fixture with claims) | Evidence of web search for EVERY claim — not just training data |
| 6.3 | `tc-6.3-obvious-but-wrong.md` | Catches the "Great Wall visible from space" myth; does not skip it for being "obvious" |
