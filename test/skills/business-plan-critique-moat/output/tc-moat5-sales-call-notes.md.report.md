> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (market sizes, named partnerships, traction figures, competitor counts) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Business-Plan Moat & Distribution Critique: Minutely Series A Memo

## Moat Type Assessment

**Verdict:** Plausible
**Confidence:** Medium

The memo claims three layers. Each maps to a different archetype, and each is weaker against a different competitor.

1. **Sales-specific models.** This claims a data flywheel: rep edits feed monthly retraining, which improves accuracy, which brings in more users. The mechanism is present. Edits are real labels, and the 78% → 91% gain over 18 months is evidence the loop works. Three problems keep it from being durable:
   - **The scale advantage belongs to someone else.** Nine million minutes is a lot for a startup. But roughly 94% of those minutes ran on Convene's infrastructure, and Convene can see far more sales calls than Minutely does.
   - **The gains are probably flattening.** Going from 78% to 91% is the easy part of the curve. Going from 91% to 95% costs much more, and users may not notice the difference. A data advantage only compounds if users can feel the improvement.
   - **General models are closing the gap.** Recognising pricing objections, competitor mentions and verbal commitments is increasingly something general-purpose models do well with a good prompt and a CRM schema. The memo's comparison is against "generic transcription tools." That is the wrong baseline for 2026. The right baseline is a well-prompted frontier model with CRM field definitions.

2. **CRM depth.** This is switching cost through integration depth and procedural inertia. It is real, and it is the strongest of the three. See the Switching Cost lens.

3. **Manager workflows.** This is also switching cost (procedural inertia). It is real, but it describes behaviour built on summaries, not on Minutely specifically. Any tool that produces equivalent summaries in the same CRM fields keeps the weekly operating rhythm intact.

**What would need to be true for this to compound:** the data advantage has to show up somewhere a competitor can't reproduce cheaply. One example is outcome-linked data: which call patterns predict closed-won deals, by segment and across many customers. The planned forecasting feature points in this direction. If Minutely can show that its deal predictions beat what a new entrant could produce on day one, that is a genuine data moat. Next-step extraction accuracy alone probably is not.

## Distribution Channel Assessment

**Verdict:** Weak
**Confidence:** High

This is the most serious issue in the memo.

- **Who owns the demand surface?** Convene does, almost completely:
  - About 60% of new revenue starts in the Convene app directory.
  - The viral loop ("Minutely is taking notes") depends on Convene letting third-party bots join and record calls.
  - 94% of recorded calls happen on Convene, so even customers won through outbound or CRM referrals depend on Convene's platform at the point of use.

  Convene controls directory ranking, bot permissions, recording and consent APIs, and the in-call user interface. Any of these can change in a single release.

- **CAC trajectory at scale.** The product-led loop is cheap today because the directory is uncrowded and the "taking notes" impression is new to prospects. Both conditions fade:
  - More note-taker apps will compete for directory placement.
  - Prospects who see a bot on every call stop noticing it.
  - Moving upmarket replaces the bottom-up motion with enterprise sales: security reviews, procurement, and multi-quarter cycles.

  The plan to triple the sales team implicitly admits that CAC will rise. The memo does not say so.

- **Channel concentration.** The memo names three channels: the Convene directory, outbound, and CRM partner referrals. In practice it depends on one, and that one is owned by the most likely competitor.

- **Channel/deal-size match.** The product-led loop fits 10–200 rep teams at $45/seat well. It does not fit 200–1,000 rep organisations. Those buyers run vendor selection, are often already under contract with the larger enterprise incumbents the memo describes, and will compare Minutely directly against them. The use of funds pushes the company into the segment where its time-to-value advantage matters least.

**Single weakness most likely to cap growth:** platform dependency on Convene. That dependency is compounded by the three-year goal, which is to record "the majority of sales calls held on Convene by mid-sized sales teams." That goal describes exactly the level of success that makes Convene act.

## Switching Cost Assessment

**Verdict:** Plausible
**Confidence:** Medium

Imagine a customer one year in who is offered a 30%-cheaper alternative. What concretely stops them?

**Structural sources of lock-in that exist today:**
- **Integration depth.** About a week of sales-ops work went into custom-field mapping, workflow triggers and deal-stage definitions.
- **Procedural inertia.** Pipeline reviews and coaching run on the summaries.
- **Data gravity.** The memo doesn't mention it, but the historical archive of call summaries linked to CRM records is valuable and awkward to migrate.

**Why this is weaker than it reads:**
- **The mapping lives in the customer's CRM.** A competitor can offer to import the existing field mapping, or do it for free with a services team. One week of sales-ops time is a real cost, but it is a one-time cost that a motivated competitor can absorb.
- **A bundled competitor removes the price comparison entirely.** If the alternative is free inside Convene or the CRM, the question becomes "is Minutely worth $45 × 50 reps × 12 = $27K a year more than free?" A week of remapping work does not answer that.
- **The <1% monthly churn figure may be a selection effect.** Teams that complete CRM mapping are already the most committed. The low churn may reflect who those teams are, not lock-in caused by the mapping. It also has not been tested against a serious competitive offer, since the memo says no strong mid-market alternative exists.
- **NRR of 131% is about expansion, not lock-in.** It shows teams adding seats. It says nothing about whether they would stay when offered a credible alternative.

**Today or roadmap:** the CRM lock-in exists today but is limited to two CRMs. Expanding to six is on the roadmap. Forecasting features would deepen lock-in, but they are also roadmap.

## Network Effect Assessment

**Verdict:** Weak
**Confidence:** Medium

The memo never uses the phrase "network effect." It implies two:

- **Data flywheel (claimed as a weak data network effect).** More users produce more edits, which produce better models. This only becomes a strong data network effect if users can feel the improvement, and at 91% accuracy the marginal gains are probably invisible to reps (see Moat Type). It is also easy to replicate for anyone with more call data, and Convene has more.
- **"Minutely is taking notes" (a virality loop, not a network effect).** One company's prospects seeing the bot does not make Minutely more valuable to that company. It drives growth, not defensibility. It also runs entirely on Convene's surface.

**Cold start, density and replicability:**
- There is no meaningful cold-start problem, because the product delivers value to a single team.
- Density requirements do not apply.
- An incumbent with distribution, such as Convene, could match whatever network value exists in months. Its own call volume is the starting point.

**What would turn this into a real network effect:** cross-customer benchmarks that each team experiences as better because other teams are on the platform. Examples include win-rate patterns by objection type, or deal-cycle norms by segment. The data to build this exists. The product does not yet.

## Competitive Response Assessment

**Verdict:** Weak
**Confidence:** High

The memo makes all three default failure arguments:
- **"Incumbents won't notice."** It cites Convene's roadmap and ecosystem statements.
- **"Incumbents are too slow."** It argues Convene is a large public company and slow.
- **"Incumbents have other priorities."** It cites the CRM vendors' platform migrations.

It then budgets for no response and holds price at $45/seat for three years. Here is how the best-positioned competitors would most likely respond:

**Convene (most dangerous).** Convene ships native AI notes, with summaries, action items and basic CRM sync, bundled into its business tier at no extra cost. It does not need to match Minutely's sales-specific accuracy. It only needs to be good enough that a head of sales can't justify $45/seat on top. At the same time it can:
- move its own feature to the top of the in-call experience;
- tighten third-party bot policies, framed as "privacy and consent";
- start charging marketplace fees.

Its "healthy ecosystem" statements are cheap to make and cheap to revise. Large video platforms have consistently absorbed AI note-taking once it became table stakes. The trigger is visible in the memo itself: a third-party app recording most mid-market sales calls on Convene's own platform.

**Major CRM vendors.** They own the fields, workflows and deal-stage definitions that form Minutely's strongest moat layer. Writing into their own CRM is trivial for them. Their likely response is to launch or acquire conversation intelligence, then bundle it into a sales-cloud tier. "Historically partnered" describes a market before AI summaries were cheap. If the vendors are busy with platform migrations, that delays their response by quarters, not years.

**The two larger standalone competitors.** These are the most predictable threat. They launch a self-serve mid-market tier with a lighter setup, then compete on price. Their enterprise footprint also blocks Minutely's upmarket push from the other side.

**Most likely pattern:** bundling by Convene, with distribution preemption close behind if Convene restricts bot access or directory placement.

**Does the moat survive?** Partly, against the standalone competitors, on the strength of CRM depth and mid-market time-to-value. Not reliably against Convene, which can undercut on price and restrict distribution at the same time.

**The missing shape: neutrality.** The strongest version of this plan argues that an incumbent's response makes Minutely more valuable. Minutely has a natural argument here that the memo doesn't make:
- A Convene-native tool only covers Convene calls.
- A CRM-native tool only covers that vendor's CRM.
- A neutral layer that works across video platforms and CRMs is the safe choice for companies whose reps run calls on several platforms and whose sales ops teams resist lock-in to one vendor.

Expanding to six CRMs supports this argument. The 94% Convene concentration currently contradicts it.

## Factual Foundation

No fact-check report was provided. These claims carry the most weight for the moat and distribution argument and would benefit most from verification:

1. **The 94% Convene share, and Convene's stated ecosystem commitment.** Check whether Convene leadership has made public commitments about third-party apps, and whether Convene already ships or has announced native AI summaries. If it has, the competitive-response section is already out of date.
2. **The <1% monthly churn for CRM-mapped teams.** Check how the cohort is defined, whether it is measured from mapping completion, and how many teams start mapping but don't finish. This is the main evidence for switching cost.
3. **The 91% next-step extraction accuracy measured against rep-edited notes.** The method may be circular, because reps edit Minutely's own draft. It also needs comparison against a strong general-purpose model baseline, not just against transcription tools.

## Overall Assessment

**Strongest lens:** switching cost, through CRM depth and manager workflows. The lock-in is real today, it is earned through setup work, and it is the best foundation for a durable position.

**Weakest lens:** distribution and competitive response, which share one root cause. The plan's growth engine and its biggest competitive threat are the same company. Convene owns the directory, the bot permissions and the calls. The memo answers this risk with arguments about Convene's priorities and pace rather than with structural protection. It then budgets for no response, which makes the $45/seat three-year pricing assumption fragile.

**Single most important revision:** reposition the moat as **platform-neutral deal intelligence**, and budget explicitly for Convene's response. In practice:
- Set a target to reduce Convene's share of recorded calls. Get the two smaller platforms, plus at least one more, to production quality.
- Make the six-CRM expansion the headline of the use of funds rather than a supporting line.
- Prioritise the forecasting feature as cross-customer, outcome-linked data that a single-platform incumbent can't match.
- Include a scenario where Convene bundles native notes in the next 12–18 months, showing what pricing, churn and new-team acquisition look like in that world.

A memo that says "here is what happens when Convene ships this, and why we still win" will be far more convincing to a Series A investor than one that says it won't happen. The pieces for that story are already in the business.

*Out of scope:* this critique did not assess whether the $45/seat price holds as a matter of unit economics (CAC, payback, NRR mechanics), or whether the $120M three-year target fits the addressable mid-market seat count. Those belong to `business-plan-critique-unit-economics` and `business-plan-critique-market-sizing`.
