> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (quoted TAM/SAM figures, market-growth rates, research firm reports, comparable-company revenue or share figures) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Market-Sizing Critique: Plotwise Pre-Seed Plan

## TAM Definition Assessment

**Verdict:** Not Claimed
**Confidence:** High

The plan deliberately skips a top-down TAM. It argues that the broader field-service software category is dominated by one-off-repair trades like HVAC and plumbing. This is the right call. Most pitches fail this lens by claiming a slice of a category report that doesn't match the product, and Plotwise avoids that trap explicitly.

The cost of that restraint is that the plan never states its own ceiling, and an investor will compute it anyway. The plan's inputs imply a three-tier funnel:

| Layer | Count | × $3,600/yr |
|---|---|---|
| All US employer landscaping firms | 96,000 | $345.6M |
| Two-plus-crew firms (45%) | 43,200 | $155.5M |
| Serviceable: already pays for software (40%) | 17,280 | $62.2M |

At current pricing, the whole addressable universe is about $155M, and the serviceable layer is $62M. Those figures assume 100% share. That is the market story's central fact, and the plan should own it rather than leave the reader to work it out. A $62M ceiling is not disqualifying. But it shapes which investors this plan fits and what expansion story it needs (see Overall Assessment).

Two smaller points:
- **Pricing.** The $300 flat price is applied uniformly to firms ranging from two crews to, presumably, twenty. If pricing scales with crews or visits, the ACV side of the build is understated. That is the cleanest legitimate lever on the ceiling, and it is not adjacency creep.
- **Employee data used as crew data.** The 45% "two-plus-crew" figure is derived from payroll data, which counts employees, not crews. The employees-per-crew conversion is unstated. It also sits awkwardly beside "most are very small: an owner and a truck." 45% is close enough to half that the two claims deserve reconciling.

## SAM Realism Assessment

**Verdict:** Plausible
**Confidence:** Medium

This is the strongest section of the plan. It uses a **behavioral** filter (already paying for scheduling or invoicing software) on top of a descriptive one (two-plus crews), and grounds that filter in observed conversion behavior. Few pre-seed plans do this. The ACV-segment match is also coherent: a single price point sized against a single segment.

Three issues likely mean $62.2M is an upper bound rather than a central estimate.

1. **The 40% ratio comes from a biased sample.** Companies that took a sales call are not a random draw of two-plus-crew firms. They skew toward association members, inbound leads, and owners already thinking about software. The share of the general population paying for software is probably lower than 40%, possibly much lower. The 400 conversations may also include one-crew firms, which would change the base. The plan should say how the 400 were sourced.

2. **The behavioral filter is looser than the buyer description.** The plan says buyers are firms paying for software *and complaining about the gap* between calendar and invoicing. The 40% captures only the first condition. Some of those firms already use an integrated or vertical tool and feel no gap. These are displacement prospects, not easy wins.

3. **The SAM contradicts the plan's own seasonality lesson.** The expansion plan targets the Sun Belt "where the season is long enough that companies run crews year-round." The Snowline comp failed because "the season was too short to keep customers paying year-round." Yet the $62.2M SAM is national and includes every northern firm that mows seven months a year. If seasonality matters enough to drive the expansion map, it belongs in the SAM.
   - I can't verify the Sun Belt share of the 17,280 firms. If it's roughly 40–50%, the near-term SAM is about 7,000–8,500 firms, or $25–31M.
   - The national figure can stay as a long-run number, provided the plan shows how northern firms get retained through winter.

**Estimated contraction:** If the 40% ratio is a moderate overstatement and the SAM is limited to year-round regions, the realistic serviceable market is plausibly 2–3× smaller than the headline, roughly $20–30M. This is not fatal for a beachhead business, but it matters for the ceiling question.

## SOM Achievability Assessment

**Verdict:** Inflated (near-term); year-5 target Plausible
**Confidence:** Medium

**Implied share.**
- **Year 2:** 400 Texas firms out of 1,500 is a 26.7% share. A 20–40% share of a beachhead is achievable in principle, and the association partnership is a real reason Texas could run hot. Note that "1,500 qualifying companies" must be the *serviceable* count, after the software filter, for the "quarter" math to work. If it's actually the two-plus-crew count, serviceable Texas is about 600 firms and the target is 67% share. The plan should state which.
- **Year 5:** 900 firms is 5.2% of national serviceable, as the plan says. But the plan won't be selling nationally by year 5; it will be selling in Texas plus the Sun Belt. Against a Sun Belt-only SAM, year-5 share is probably 10–13%. That is high for five years but plausible given the low absolute numbers. The 900 / $3.24M ARR target is modest, and the modesty is a credibility asset.

**Sales capacity is the binding constraint, and the plan's numbers don't reconcile.**

| | Figure |
|---|---|
| Demonstrated productivity | 58 customers ÷ 2 reps ÷ 9 months ≈ **3.2 closes/rep/month** |
| Assumed productivity at full ramp | **15 closes/rep/month**, about 4.7× demonstrated |
| Required pace to hit 400 in the 18-month runway | 342 net adds ≈ **19/month**, about 3× the current 6.4/month |

With two new reps ramping, the 18-month target needs roughly 1.5–1.7× demonstrated productivity across the team, and that is before any churn. This is a stretch but reachable, and it is the real milestone the raise is buying.

The 15/rep/month figure also conflicts with the plan's own long-range target. Four reps at 15/month would close 720 firms a year, so years 3–5 alone would add about 2,000 firms, far past the 900 target. Either rep productivity is overstated, or the plan expects heavy churn it hasn't disclosed. One of the two numbers is wrong, and the plan should pick.

A related ambiguity: "end of year two" versus "18 months of runway to 400." Is year two measured from founding (nine months already elapsed) or from the raise? This changes the required monthly pace by about 30%.

**Most constraining bottleneck:** rep productivity outside the association channel. Texas closes may be partly the partnership's effect, and that won't carry into states without one.

## Market Timing Assessment

**Verdict:** Speculative
**Confidence:** High

All three "why now" arguments are persistent trends, not triggers:

| Claim | Problem |
|---|---|
| Smartphones in crew leads' pockets | True for roughly a decade |
| SMBs moving operations to the cloud | A 2010s story |
| A new generation of owners taking over | Ongoing and gradual; no dated inflection |

None answers the core question: **what changed in the last 24 months that makes this viable now and not in 2018?** As written, the section is "why ever," not "why now."

The plan's best timing evidence is actually in the SAM section. Forty percent of target firms already pay for scheduling or invoicing software and complain about the gap. That is revealed preference: the market is already spending money on a workaround. It rules out the "too early" failure mode and should be the lead of this section.

The plan doesn't address the symmetric "too late" risk. If target firms already buy software, some vertical tools probably exist. From general knowledge, I believe products such as Jobber, LMN, Aspire, and Service Autopilot serve landscapers, though I haven't verified their positioning or share. Either the market is earlier than those products suggest, or Plotwise is a late entrant positioning against them. The plan should say which. Possible specific triggers worth investigating, if any are true:
- A labor-cost or crew-shortage shift that makes route efficiency newly valuable
- A pricing change by an incumbent that pushed small firms out
- A recent change in how commercial grounds contracts require proof-of-service (photos, logs)

## Comparable Benchmarks Assessment

**Verdict:** Plausible
**Confidence:** Medium

Credit first: the plan names two negative comps alongside its positive one, which most pitches don't. The Snowline lesson (seasonality kills retention) is genuinely informative.

Problems:

- **Yardly is not a comp.** It is a consumer marketplace, with a different buyer, motion, and economics. Including it pads the negative set with a failure Plotwise trivially avoids, which makes the comp set look more balanced than it is. Drop it or replace it with a vertical B2B failure.
- **Poolroute lacks a denominator.** 3,000 customers in eight years means little without the number of serviceable pool-service firms. If pool-service firms are far fewer than landscapers, Poolroute's share was high and the benchmark is aggressive. If they're comparable, it's ordinary. On trajectory alone, 900 firms at year 5 sits at or below a Poolroute-like path, so this comp supports the plan's numbers rather than stretching them.
- **Snowline signals the outcome ceiling as well as the seasonality risk.** A single-trade route tool that peaked at 600 customers and was folded into a broader suite suggests what exit looks like for this category. The plan should engage with that, since it bears on what the market can support.
- **The most relevant comps are missing.** There are no landscaping-specific software companies, successful or failed, in the set. Analogs in adjacent trades are fine as supplements, but the core comparison should be companies already selling into this exact buyer. Their absence will read to an investor as unresearched or avoided.

## Factual Foundation

No fact-check report was provided. The claims that would most benefit from verification:

1. **96,000 employer firms and the 45% two-plus-crew share.** This is the base of the entire funnel. Check the source (likely Census County Business Patterns or similar) and the employees-per-crew mapping behind "two-plus crews."
2. **The 40% software-adoption ratio.** This is internal data, not external, but it is the single most load-bearing input in the plan. Document the sampling: how the 400 conversations were sourced and how many were two-plus-crew firms.
3. **Comp figures and the competitive landscape.** Verify Poolroute's customer count and the size of its addressable market, Snowline's outcome, and the existence and scale of landscaping-specific competitors not named in the plan.

## Overall Assessment

**Strongest lens: SAM.** The behavioral filter is grounded in sales data, and the plan declines to inflate the market with a mismatched category report. This is a more honest market build than most pre-seed plans offer.

**Weakest lens: Market Timing.** All three timing arguments are decade-old trends. A close second is the sales-capacity assumption inside SOM, where 15 closes/rep/month is about 4.7× demonstrated and doesn't reconcile with the plan's own year-5 target.

**The single most important revision: state the ceiling and show the path past it.**

1. **State the ceiling explicitly.** The honest build implies $62M ARR at 100% serviceable share, and a smaller near-term figure once seasonality is applied. Year 5 is $3.2M.
2. **Address the ceiling with a sized, separately presented expansion case.** Candidates include:
   - Per-crew or per-visit pricing to lift ACV for larger firms
   - Payments or invoicing-processing revenue
   - Adjacent recurring-route trades (pest control, commercial cleaning), each with its own bottom-up build
3. **Or position deliberately.** If the expansion case doesn't hold up, pitch Plotwise as a capital-efficient vertical business to investors who fund that profile.

Either answer is defensible. Leaving the question unanswered is not, because every investor will run the 17,280 × $3,600 math in the first meeting.

Second priority: replace the 15/rep/month assumption with demonstrated productivity plus an explicit ramp, and rebuild the 18-month milestone from that.

**Out of scope, noted for sibling critiques:**
- Seasonal churn and winter retention in northern markets affect LTV (unit-economics critique).
- Displacement of existing vertical tools and the durability of the Texas association partnership as a distribution advantage are moat/distribution questions.
