# Cross-Skill Evaluation: fact-check vs code-fact-check

These tests verify consistency between the two skills. Run both skills, then
compare reports against these criteria.

---

## TC-X1: Parallel verdict scales

Each skill must use its own verdict scale consistently and never borrow from
the other.

| fact-check verdicts | code-fact-check verdicts | Mapping |
|--------------------|-----------------------|---------|
| Accurate | Verified | Both mean "claim is correct" |
| Mostly accurate | Mostly accurate | Shared — same name, same threshold |
| Disputed | *(no equivalent)* | Only fact-check has this |
| Inaccurate | Incorrect | Both mean "claim is wrong" |
| Unverified | Unverifiable | Both mean "cannot confirm" |
| *(none)* | Stale | Only code-fact-check has this |

**Check:** Review all verdict lines in each report. No fact-check report should
contain "Verified", "Incorrect", "Unverifiable", or "Stale". No code-fact-check
report should contain "Accurate", "Disputed", "Inaccurate", or "Unverified".

The BATS format tests (`fact-check-format.bats` and `code-fact-check-format.bats`)
automate the verdict-value checks. This document covers the conceptual mapping.

---

## TC-X2: Same "mostly accurate" threshold

Run both skills on equivalent "directionally correct but imprecise" claims:

- **fact-check:** Use `tc-2.2-mostly-accurate.md` (70%/fifth conflation)
- **code-fact-check:** Use `tc-c2.2-mostly-accurate.js` (O(n) vs O(n log n))

Both should produce "Mostly accurate" verdicts. The threshold of imprecision
should be comparable — neither skill should upgrade to fully correct or
downgrade to inaccurate for the same degree of "almost right."

---

## TC-X3: Both refuse to add critique

Run both skills on inputs that are factually accurate but poorly argued/written:

- **fact-check:** Use `tc-6.1-accurate-weak-argument.md`
- **code-fact-check:** Use `tc-c6.1-multi-claim.js` (focus on the verified claims)

Neither report should contain comments about quality, style, or argumentation.
Verdicts should reflect accuracy only.
