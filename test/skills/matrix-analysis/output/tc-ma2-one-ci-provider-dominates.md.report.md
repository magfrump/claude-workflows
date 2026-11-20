Stage 2 (evaluation) complete: 3/3 criterion sub-agents returned (9 ratings total, no failures) — synthesizing into comparison matrix and recommendation.

# Quarry CI vs. Ferrous Pipelines vs. Tidewater Build

**Choose Quarry CI.** It's the cheapest, the fastest, and the only one of the three with hosted arm64 runners at no extra cost.

## Comparison matrix

| | Monthly cost | Median pipeline time | arm64 runner support |
|---|---|---|---|
| **Quarry CI** | ++ | ++ | ++ |
| **Ferrous Pipelines** | + | - | - |
| **Tidewater Build** | - | + | - |

`++` Strong · `+` Adequate · `-` Weak. All criteria count equally.

## Key findings

- **Quarry CI is strongest on all three criteria.**
  - **Cost:** $1,150/month, which is $750 less than Ferrous and $1,250 less than Tidewater.
  - **Speed:** its 7:40 median is 1:40 faster than Tidewater and 3:25 faster than Ferrous.
  - **arm64:** it's the only provider with native hosted arm64 runners at the x86 price.
- **Ferrous Pipelines** costs less than Tidewater, but it's the slowest (11:05, about 45% slower than Quarry). It also only runs arm64 on a self-hosted runner you would have to maintain.
- **Tidewater Build** is faster than Ferrous but the most expensive ($2,400, about 2.1× Quarry). Its arm64 runners are in beta, cost twice the x86 price, and have a waitlist.
- **Ferrous and Tidewater are close.** Each wins one criterion against the other, and both are weak on arm64.

## Tradeoffs

You don't have to trade anything off to pick the winner. The only real tradeoff is for second place:

- **Ferrous:** about $500/month cheaper and you can run arm64 today, but you'd have to maintain that runner and pipelines take about 1:45 longer.
- **Tidewater:** faster, but costs more, and arm64 may not be available because of the beta and waitlist.

## Risks and gaps

- **Cost on arm64 jobs is uncertain.** The figures may or may not include arm64 usage. Neither Ferrous's self-hosted runner nor Tidewater's 2× arm64 price shows up in the monthly figures, so both would cost more than shown if you run arm64 builds. This only makes Quarry's lead bigger.
- **Quarry's arm64 runners aren't confirmed generally available.** Nothing in the data suggests beta or waitlist status, but check before you commit.
- **Only medians were measured.** There's no p90 or variance data, so slow-run behaviour is unknown.
- **The trial didn't cover everything.** Reliability, support quality, migration effort, and lock-in weren't measured, so the matrix can't speak to them.
- **No criterion is weak or strong for every provider,** so all three criteria help tell the options apart.

## Recommendation

**Adopt Quarry CI.** Two things would change this:

- Quarry's arm64 runners turn out not to be generally available.
- A criterion outside this matrix, such as reliability, support, or a required integration, turns out to matter a lot and Quarry does badly on it.

Before signing, confirm Quarry's arm64 status and look at slow-run (p90) times from the trial data.

If Quarry is ruled out, the choice between the other two depends on what you value more:
- **Cost, and being able to run arm64 now:** choose Ferrous, and accept maintaining a runner.
- **Faster feedback:** choose Tidewater, and accept paying more and waiting on arm64.

As you asked, the full document is printed below rather than saved to `docs/reviews/matrix-analysis.md`.

---

```markdown
# Matrix Analysis

**Items:** Quarry CI, Ferrous Pipelines, Tidewater Build | **Criteria:** 3 | **Date:** 2026-11-19

---

## Comparison Matrix

| | Monthly cost | Median pipeline time | arm64 runner support | Overall |
|---|---|---|---|---|
| **Quarry CI** | ++ $1,150/mo, cheapest by $750+ | ++ 7:40, fastest | ++ native hosted, same price as x86 | Strongest on all three criteria |
| **Ferrous Pipelines** | + $1,900/mo, middle; runner upkeep not included | - 11:05, slowest (~45% slower than Quarry) | - self-hosted only; you maintain the runner | Close to Tidewater; cheaper but slowest |
| **Tidewater Build** | - $2,400/mo, most expensive (~2.1× Quarry) | + 9:20, middle | - beta, 2× price, waitlist | Close to Ferrous; faster but most expensive |

---

## Detailed Evaluations

### Criterion 1: Monthly cost

**Definition:** What the team would actually pay each month at its measured volume. Effects on cost that follow from the data (self-hosted runner upkeep, an arm64 price premium) are noted but not counted in dollars.

| Item | Rating | Rationale |
|---|---|---|
| Quarry CI | Strong | $1,150/month is the cheapest, $750 less than Ferrous and $1,250 less than Tidewater for the same ~1,800-run workload. arm64 is priced the same as x86, so arm64 builds add no premium. |
| Ferrous Pipelines | Adequate | $1,900/month is in the middle: about 65% more than Quarry and about 21% less than Tidewater. The self-hosted arm64 runner's infrastructure and upkeep are not included, so the real cost is higher. |
| Tidewater Build | Weak | $2,400/month is the most expensive, about 2.1× Quarry and about 26% more than Ferrous. arm64 costs twice the x86 price, so arm64 builds would widen the gap. |

**Ranking:** 1. Quarry CI · 2. Ferrous Pipelines · 3. Tidewater Build. Ferrous and Tidewater are closer to each other than either is to Quarry.
**Key differentiator:** Quarry costs $750–$1,250/month less than the others, and it's the only one where arm64 adds no extra price or upkeep.

---

### Criterion 2: Median pipeline time

**Definition:** The measured median wall-clock time of the team's real monorepo pipelines, standing in for how fast developers get feedback. Only medians were provided; no tail data.

| Item | Rating | Rationale |
|---|---|---|
| Quarry CI | Strong | 7 min 40 s is the fastest: 1:40 faster than Tidewater and 3:25 faster than Ferrous over the same ~1,800-run trial. |
| Ferrous Pipelines | Weak | 11 min 5 s is the slowest, about 45% slower than Quarry and about 19% slower than Tidewater. |
| Tidewater Build | Adequate | 9 min 20 s is in the middle. It is about 22% slower than Quarry, too far behind to count as close to the fastest, and about 16% faster than Ferrous. |

**Ranking:** 1. Quarry CI · 2. Tidewater Build · 3. Ferrous Pipelines. The gaps between neighbours are about the same size (1:40 and 1:45); none of the three is close.
**Key differentiator:** Quarry's median is 1:40 to 3:25 shorter than the others, which means faster feedback on every run.

---

### Criterion 3: arm64 runner support

**Definition:** How well each provider lets the team run arm64 builds today: availability (generally available vs. beta vs. waitlist), hosted vs. self-maintained, and price compared with x86.

| Item | Rating | Rationale |
|---|---|---|
| Quarry CI | Strong | Native hosted arm64 runners at the x86 price meet the bar for Strong. General availability isn't stated outright, but nothing suggests beta or waitlist status. |
| Ferrous Pipelines | Weak | arm64 only works on a self-hosted runner the team would maintain, which is a significant operational burden. You could run arm64 today, but only by owning that infrastructure. |
| Tidewater Build | Weak | Beta, twice the x86 price, and a waitlist, so it is neither reliably available now nor affordable. |

**Ranking:** 1. Quarry CI (clearly) · 2. Ferrous Pipelines and Tidewater Build (close, both Weak). Ferrous is slightly ahead because arm64 is at least usable there today.
**Key differentiator:** Quarry is the only provider whose arm64 runners are hosted and usable now at x86 pricing.

---

## Tradeoff Analysis

Choosing the winner involves no tradeoff: Quarry CI is strongest on every criterion. The only tension is between the two runners-up. Ferrous is about $500/month cheaper, and you can run arm64 today if you maintain a runner, but it is about 1:45 slower per pipeline. Tidewater is faster but costs more, and its arm64 may not be available while it is in beta with a waitlist. The two are close, and which one is second depends on whether cost or speed matters more.

## Recommendation

Adopt **Quarry CI**. Two things would change this: Quarry's arm64 runners turn out not to be generally available, or a criterion outside this matrix (reliability, support quality, migration effort, lock-in, required integrations) turns out to matter a lot and Quarry does badly on it. Before committing, confirm Quarry's arm64 status and check slow-run (p90) times from the trial data. If Quarry is ruled out, choose Ferrous if cost and being able to run arm64 now matter most (and accept maintaining a runner), or Tidewater if faster feedback matters most (and accept paying more and waiting on arm64).

---

## Evaluation Metadata

- **Scoring:** Qualitative (Strong / Adequate / Weak)
- **Weights:** None (all criteria count equally)
- **Agents dispatched:** 3 criterion evaluators (3/3 returned)
- **Items with data gaps:** No "Insufficient information" ratings. Gaps noted by evaluators:
  - Quarry's arm64 general availability is not explicitly confirmed.
  - It is unclear whether the monthly cost figures include arm64 usage.
  - Ferrous's self-hosted runner cost is not quantified.
  - Only medians were measured (no tail-latency data).
```
