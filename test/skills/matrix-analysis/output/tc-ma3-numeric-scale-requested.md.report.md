Stage 2 (evaluation) complete: 3/3 criterion sub-agents returned (9 scores total, no gaps) — synthesizing into comparison matrix and recommendation.

## Paging tools compared: Beacon, Siren, Klaxon

Beacon has the highest unweighted total at 11 out of 15. Siren scores 10 and Klaxon 9. The totals are close enough that what your team cares about most should decide this, not the sum.

| | Alert routing flexibility | Mobile app reliability | Price per responder | Total (of 15) |
|---|---|---|---|---|
| **Beacon** | 5 | 3 | 3 | **11** |
| **Siren** | 4 | 5 | 1 | **10** |
| **Klaxon** | 2 | 2 | 5 | **9** |

All three criteria count equally. Scores run from 1 to 5, and 5 is best.

### What the scores show

- **Beacon** is the only tool that scores above 2 on every criterion. It wins on routing and is in the middle on reliability and price. It is the most balanced option, but it wins only one criterion outright.
- **Siren** is the best at delivering pages: 200 out of 200. It is also the most expensive at $29.
- **Klaxon** is the cheapest at $9. It has the weakest routing (one global escalation chain) and the weakest delivery (dropped 6 of 200 pages).
- Each tool wins exactly one criterion, so no option beats another on everything.

### Tradeoffs

- **Beacon or Siren is the real choice: routing control against delivery reliability.** Beacon is the only tool with per-service overrides, but it dropped 3 of 200 pages. Siren delivered every page but routes every service the same way. Siren also costs $8 more per responder per month, about 38% more.
- **Klaxon is about price.** It costs less than half as much as Beacon. In return it dropped twice as many pages and offers almost no routing control. Paging tools exist so that alerts get through, so a low price may not make up for that.

### Risks and gaps

- **The reliability test was small.** The reliability sub-agent ran a statistical test (Fisher exact):
  - Siren (0 drops) is clearly better than Klaxon (6 drops); the chance of that gap by luck is about 3%.
  - Siren against Beacon (0 against 3 drops) could be chance; that chance is about 25%.
  - Beacon and Klaxon can't be reliably separated.
  - Even Siren's perfect run only shows its drop rate is probably below about 1.5%.

  If you end up choosing between Beacon and Siren because of reliability, re-test with about 1,000 or more pages per tool.
- **Some scores were close calls:**
  - Klaxon's routing score could have been a 1 instead of a 2.
  - Beacon's price score could have been a 2 instead of a 3. That would tie it with Siren at 10.
- **Cost depends on team size, which I don't have.** For a 20-person rotation, the yearly cost would be:

  | Tool | Yearly cost, 20 responders |
  |---|---|
  | Klaxon | about $2,160 |
  | Beacon | about $5,040 |
  | Siren | about $6,960 |

- **No scores are missing.** No criterion was strong for every tool, and none was weak for every tool.

### Recommendation

**Choose Beacon** if you weight the criteria equally, or if per-service routing matters to you. It is the strongest all-round option and the only one with per-service overrides.
- **If missed pages are the biggest worry, choose Siren.** Its perfect delivery was the clearest single result in the evaluation, and it gives up only per-service overrides. Pay the extra $8 per responder per month.
- **Choose Klaxon only if budget is the deciding constraint** and a single escalation chain is enough. You would also be accepting the highest drop rate measured.

The full matrix document is printed below instead of being saved to `docs/reviews/matrix-analysis.md`, as you asked.

---

```markdown
# Matrix Analysis

**Items:** Beacon, Siren, Klaxon | **Criteria:** 3 | **Date:** 2026-11-19

---

## Comparison Matrix

| | Alert routing flexibility | Mobile app reliability | Price per responder | Overall |
|---|---|---|---|---|
| **Beacon** | 5: schedules, escalation, per-service overrides | 3: dropped 3 of 200 (98.5%) | 3: $21/month | 11/15: best balance, wins routing |
| **Siren** | 4: schedules and escalation, no per-service overrides | 5: delivered 200 of 200 | 1: $29/month, highest | 10/15: most reliable, most expensive |
| **Klaxon** | 2: one global escalation chain only | 2: delivered 194 of 200 (97.0%) | 5: $9/month, lowest | 9/15: cheapest, weakest on features |

Scores: 1–5, where 5 is best. All criteria count equally (unweighted).

---

## Detailed Evaluations

### Criterion 1: Alert routing flexibility

**Definition:** How well routing rules send each alert to the right responder at the right time. A 5 means on-call schedules, multi-step escalation chains and per-service overrides are all supported. A 1 means a single fixed routing path.

| Item | Rating | Rationale |
|---|---|---|
| Beacon | 5 | Supports schedules, escalation chains and per-service overrides. That covers all three capabilities needed for a 5. |
| Siren | 4 | Supports schedules and escalation but not per-service overrides, so every service has to follow the same routing logic. |
| Klaxon | 2 | One global escalation chain only. No schedules or per-service overrides appear in the evidence. Rated 2 rather than 1 because an escalation chain still allows some step-by-step routing. |

**Ranking:** Beacon > Siren > Klaxon. Beacon and Siren are a moderate gap apart. Klaxon's own score was a close call between 1 and 2.
**Key differentiator:** Only Beacon has per-service overrides, which let different services route differently.

---

### Criterion 2: Mobile app reliability

**Definition:** How dependably the mobile app delivers pages to responders. A 5 means no pages were dropped in testing. A 1 means it drops pages often enough that responders can't rely on it. Small drop rates still count heavily, because a missed page can mean a missed incident.

| Item | Rating | Rationale |
|---|---|---|
| Beacon | 3 | Dropped 3 of 200 test pages (98.5% delivered), about one missed page in every 67. For a paging tool that is a real reliability gap. |
| Siren | 5 | Delivered 200 of 200 test pages (100%). This meets the definition of a 5. |
| Klaxon | 2 | Dropped 6 of 200 (97.0% delivered), about one missed page in every 33 and twice Beacon's drop count. That would seriously undermine trust, though it falls short of a 1. |

**Ranking:** Siren > Beacon > Klaxon.
- Siren against Klaxon is a reasonably clear difference (Fisher exact test, p ≈ 0.03).
- Siren against Beacon is not statistically clear (p ≈ 0.25).
- Beacon and Klaxon can't be reliably separated with this sample.
- Siren's 0 drops in 200 only shows its true drop rate is probably below about 1.5%.

**Key differentiator:** Siren was the only tool that delivered every test page.

---

### Criterion 3: Price per responder

**Definition:** Monthly cost per responder seat, where lower is better. A 5 means cheapest by a meaningful margin; a 1 means most expensive by a meaningful margin. Scored on price only.

| Item | Rating | Rationale |
|---|---|---|
| Beacon | 3 | $21 per month. Placing it on a straight line between $9 (scored 5) and $29 (scored 1) gives 2.6, which rounds to 3. A 2 would also be defensible. |
| Siren | 1 | $29 per month, the highest. That is about 38% more than Beacon and more than three times Klaxon's price. |
| Klaxon | 5 | $9 per month, the lowest. That is about 57% cheaper than Beacon and $20 cheaper than Siren. |

**Ranking:** Klaxon > Beacon > Siren. None of the gaps is close; the smallest is $8, between Beacon and Siren.
**Key differentiator:** Klaxon costs less than half of Beacon's price and less than a third of Siren's.

---

## Tradeoff Analysis

- **Beacon against Siren:** routing control against delivery reliability. Beacon has per-service overrides but dropped 3 of 200 pages. Siren delivered every page, has no per-service overrides, and costs $8 more per responder per month.
- **Klaxon against the others:** a large saving (less than half of Beacon's price) in exchange for the weakest routing and the highest drop rate. For a paging tool, a high drop rate is hard to accept at any price.
- **No tool dominates.** Each one wins exactly one criterion, and the totals are within 2 points of each other (11, 10, 9).

## Recommendation

- **Equal weights:** Beacon (11 of 15) is the most balanced option. It is the only tool with no score below 3, and the only one with per-service routing.
- **Missed pages are the top risk:** choose Siren. Its perfect delivery is the clearest result in the evaluation. The price is $8 more per responder per month and no per-service overrides.
- **Budget is the hard constraint and a single escalation chain is enough:** choose Klaxon, and accept the highest measured drop rate.

These assumptions could change the answer:
- A larger reliability test could narrow or widen the 3-drop gap between Beacon and Siren.
- Scoring Beacon's price as a 2 would tie Beacon and Siren at 10.
- Weighting reliability more heavily would favour Siren.

---

## Evaluation Metadata

- **Scoring:** Numeric 1–5 (5 = best)
- **Weights:** None (equal weighting)
- **Agents dispatched:** 3 criterion evaluators (3 of 3 returned)
- **Items with data gaps:** None. Note that the reliability sample (200 pages per tool) is too small to separate Beacon from Siren, or Beacon from Klaxon, with statistical confidence.
```
