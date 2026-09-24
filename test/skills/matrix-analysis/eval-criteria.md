# Matrix Analysis — Evaluation Criteria

Synthetic comparisons with items, criteria and measured facts given inline.
Every fixture checks the orchestration itself (one sub-agent per criterion,
from the transcript), and each plants one thing the matrix must get right.

## Fixture → Expected Behavior Map

| Fixture | Criteria (= sub-agents) | Planted | Must show |
|---|---|---|---|
| tc-ma1-agpl-library-in-closed-saas.md | 4 | Kestrel leads rendering, throughput and maintenance but is AGPL-3.0 with no commercial licence, in a closed SaaS used over the network where Legal forbids publishing source | ≥4 dispatches; Kestrel's row weak / AGPL tied to the network or source obligation; recommends Folio or Parchment |
| tc-ma2-one-ci-provider-dominates.md | 3 | Quarry CI is cheapest ($1,150), fastest (7 m 40 s) and the only one with native arm64 at x86 price | ≥3 dispatches; recommends Quarry |
| tc-ma3-numeric-scale-requested.md | 3 | the user asks for 1-5 scores "not words" | ≥3 dispatches; numeric item cells; no Strong/Adequate/Weak cells |
| tc-ma4-mirrored-tie-no-priority.md | 3 | (negative) Lumen wins latency and tuning, Harrow is 2.6x cheaper, and the user has not ranked cost against speed | ≥3 dispatches; a conditional recommendation ("if cost matters most, Harrow"); no "is the clear winner" claim |

All four also run `format_check` (matrix-analysis-format.bats, which now honors
`REPORT_PATH`). Its rating check accepts numeric cells, so tc-ma3 runs it too.

## Notes

- **Why subagents_min.** SKILL.md: "Dispatch every evaluation to a sub-agent via
  the Agent tool. Scoring items yourself defeats the point of the matrix." A
  single agent can write a perfect-looking matrix. Only the transcript shows
  whether the cells came from independent passes. The count is top-level Agent
  calls, so a model that batches criteria into one sub-agent fails, correctly.
- **Ratings are cells.** The Comparison Matrix uses `++/+/-/?` and the Detailed
  Evaluations tables use Strong/Adequate/Weak (SKILL.md uses both), so ma1's row
  check accepts either.
- **ma1 has two ways to pass the reason check.** Either Kestrel's row is weak/`-`
  or AGPL is tied to the network/source obligation; `cites_pattern:agpl` then
  insists the licence is named at all.
- **Claim-forbidding in ma4.** "There is no clear winner" is the right answer,
  so the negative forbids "is the clear winner" / "as the obvious choice", not
  the words.
- **No Read.** Inline mode runs in the real repo; sub-agents inherit the tool
  list, so neither can read expected-verdicts.
- Planted figures were checked: $3,800 / $1,450 ≈ 2.6x (ma4).
- **Likely to move on the first real run:** ma3's numeric-cell pattern (a model
  may write "4/5 — rationale"), and ma4's conditional pattern.
