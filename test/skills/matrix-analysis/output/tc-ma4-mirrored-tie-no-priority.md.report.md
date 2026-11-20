Stage 2 (evaluation) complete: 3/3 criterion sub-agents returned (6 ratings total) — synthesizing into comparison matrix and recommendation.

# Lumen Search vs Harrow Index

Lumen is ahead on speed and tuning effort; Harrow is cheaper. Neither wins on everything, so the pick depends on whether cost or speed matters more to you this year.

## The Matrix

| | Monthly cost | p95 query latency | Relevance tuning effort |
|---|---|---|---|
| **Lumen Search** | - | ++ | ++ |
| **Harrow Index** | ++ | + | - |

`++` Strong · `+` Adequate · `-` Weak. Criteria are unweighted.

## Key findings

- **Lumen is Strong on 2 of 3 criteria (latency, tuning effort)** and Weak on cost: $3,800/month, about 2.6× Harrow's fee.
- **Harrow is Strong on cost only:** $1,450/month, which saves $28,200 a year.
  - Latency is Adequate: 165 ms is fine for submitted searches but tight for search-as-you-type.
  - Tuning effort is Weak: about four days of custom analysers and boosting rules, roughly eight times Lumen's half day.
- **The two services differ on every criterion.** No criterion fails to separate them.

## Tradeoffs

- **Cost against speed.** You haven't settled this yet, and it's the main tension. Lumen buys about 117 ms of p95 headroom (roughly 3.4× faster) for $2,350/month more.
- **Harrow's tuning cost is small against its saving, if it's one-off.** 3.5 extra days of work is minor next to $28,200 a year. If the custom analysers and boosting rules need retuning whenever the catalogue or query mix changes, that becomes a recurring cost. It's a bigger one if an engineer rather than a merchandiser has to do the work.

## Risks and gaps

- **Harrow's latency figure may be too optimistic.** We don't know if 165 ms was measured before or after its four days of tuning. Custom analysers and boosting rules usually slow queries down. If it was measured before tuning, Harrow's latency at matched relevance may be worse, and its rating could drop to Weak.
- **We don't know who tuned Harrow.** If it was an engineer, Harrow's real running cost includes engineering time.
- **Cost is rated only against each other.** There's no market benchmark for this scale. The trial fees may not match contracted production rates either.
- **We don't know if autocomplete is planned.** That decides whether Harrow's tail latency matters.
- **No "Insufficient information" ratings.** Every cell was scored.

## Recommendation

- **If speed matters more** (search-as-you-type, latency-sensitive conversion): **choose Lumen.** It's the clear pick on latency and on keeping tuning cheap, at about $28k a year extra.
- **If cost matters more** and search is mostly submitted queries: **choose Harrow, after two checks:**
  1. Re-measure p95 latency on the tuned setup.
  2. Confirm that the merchandiser can keep the analysers and boosting rules up to date without regular engineering help.

  If either check fails, Harrow's advantage shrinks a lot.

The data shows a real trade-off, and only you can decide which side matters more.

As requested, the matrix document is printed below instead of being saved to `docs/reviews/matrix-analysis.md`.

---

```markdown
# Matrix Analysis

**Items:** Lumen Search, Harrow Index | **Criteria:** 3 | **Date:** 2026-11-19

---

## Comparison Matrix

| | Monthly cost | p95 query latency | Relevance tuning effort | Overall |
|---|---|---|---|---|
| **Lumen Search** | - $3,800/mo, ~2.6× Harrow | ++ 48 ms, headroom for autocomplete | ++ good out of box; ½ day of synonyms by merchandiser | Strong on speed and tuning effort; costs $28.2k/yr more |
| **Harrow Index** | ++ $1,450/mo, $28.2k/yr cheaper | + 165 ms; fine for submitted searches, tight for autocomplete | - ~4 days of analysers and boosting to reach parity | Cheapest; relevance and speed cost more effort to keep up |

---

## Detailed Evaluations

### Criterion 1: Monthly cost

**Definition:** Recurring monthly service fee for the 2.1M-product catalogue (excludes one-off tuning labour).

| Item | Rating | Rationale |
|---|---|---|
| Lumen Search | Weak | $3,800/month ($45,600/year), about 2.6× Harrow for the same catalogue. Rated against Harrow only; no market benchmark was available. |
| Harrow Index | Strong | $1,450/month ($17,400/year), about 38% of Lumen's fee for the same catalogue and query load. |

**Ranking:** 1. Harrow Index, 2. Lumen Search
**Key differentiator:** Harrow costs $2,350/month ($28,200/year, about 62%) less.

---

### Criterion 2: p95 query latency

**Definition:** 95th-percentile query response time in the trial, judged against what interactive e-commerce search needs, including search-as-you-type.

| Item | Rating | Rationale |
|---|---|---|
| Lumen Search | Strong | 48 ms on the full catalogue and replayed log, well under the ~100 ms that feels instant. That leaves room for network time and per-keystroke queries. About 3.4× faster than Harrow. |
| Harrow Index | Adequate | 165 ms is acceptable for submitted searches (under the ~200 ms users notice) but tight for autocomplete. It's unknown whether this was measured after tuning; if not, latency at matched relevance may be higher. |

**Ranking:** 1. Lumen Search, 2. Harrow Index
**Key differentiator:** About 117 ms at p95. Lumen has room for search-as-you-type; Harrow is tight for it and its figure is less certain.

---

### Criterion 3: Relevance tuning effort

**Definition:** The human effort and skill needed to reach acceptable relevance, plus what the type of tuning suggests about upkeep.

| Item | Rating | Rationale |
|---|---|---|
| Lumen Search | Strong | Good relevance out of the box; about half a day of synonym tuning by a merchandiser. Upkeep looks manageable without engineering. |
| Harrow Index | Weak | About four days (~8× Lumen) of custom analysers and boosting rules, which is specialist work, just to match Lumen. Future catalogue or query changes probably need the same kind of work. |

**Ranking:** 1. Lumen Search, 2. Harrow Index
**Key differentiator:** Lumen needed merchandiser-level synonym edits; Harrow needed four days of specialist configuration to reach the same relevance.

---

## Tradeoff Analysis

The core tension is cost against speed. Lumen buys about 3.4× faster p95 latency and low-effort relevance for $28,200/year more. Harrow's extra 3.5 days of tuning is small next to its saving if it is one-off. It becomes a meaningful recurring cost if retuning is frequent or needs an engineer. Harrow's latency rating also depends on an open question: whether 165 ms reflects the tuned setup.

## Recommendation

- **Speed is the priority** (search-as-you-type, latency-sensitive conversion): choose **Lumen Search**.
- **Cost is the priority** and search is mostly submitted queries: choose **Harrow Index**, but only after (1) re-measuring p95 latency on the tuned setup and (2) confirming that relevance upkeep doesn't need regular engineering time.

The answer flips to Lumen if Harrow's tuned latency comes in well above 165 ms, or if Harrow needs ongoing engineering time for retuning. It favours Harrow more strongly if autocomplete isn't planned and the catalogue rarely changes.

---

## Evaluation Metadata

- **Scoring:** Qualitative (Strong / Adequate / Weak)
- **Weights:** None (cost vs speed priority undecided)
- **Agents dispatched:** 3 criterion evaluators (3/3 returned)
- **Items with data gaps:** None rated "Insufficient information". Open questions: whether Harrow's latency was measured after tuning; who did Harrow's tuning; no market cost benchmark; whether trial fees match contracted production rates.
```
