> ⚠️ **No fact-check report provided.** This critique does not include independent factual
> verification. Checkable claims in the draft (market sizes, named partnerships, traction
> figures, competitor counts) have not been assessed. For full verification, run the
> `fact-check` skill first or use the `draft-review` orchestrator.

# Business-Plan Moat & Distribution Critique: Minutely Series A Memo

## Moat Type Assessment

**Verdict:** Plausible
**Confidence:** Medium

The memo claims three layers. Each maps to a different archetype, and they are not equally strong.

- **Sales-specific models = data network effect / data flywheel.** This is the most structurally interesting claim. The loop is real in shape: usage produces rep edits, edits become labelled corrections, monthly retraining improves accuracy, and better accuracy should drive more usage. The 78% → 91% improvement is the right kind of evidence. Two things weaken it:
  - **The accuracy metric is self-referential.** It is measured against rep-edited notes, and reps edit *Minutely's* draft. Their corrections are anchored to what the model produced. A rising score could partly mean reps are editing less, through habit or fatigue, rather than the model getting more correct. A held-out, independently annotated benchmark would make this claim far more credible.
  - **The flywheel's marginal value is flattening.** Going from 78% to 91% is meaningful. Going from 91% to 94% is much less visible to a buyer. General-purpose models are also closing the "trained on sales conversations" gap from below. A data moat only compounds if users *feel* the improvement, and at 91% the felt gap against a competent general model may already be narrow.
- **CRM depth = switching cost** (assessed in lens 3). This is real but moderate.
- **Manager workflows = switching cost / procedural inertia.** This is weaker than stated (see lens 3).

What would need to be true for the moat to compound: the proprietary asset has to be something no one else can assemble. Raw sales-call audio is not that asset, because Convene sees every one of those minutes. The asset that could compound is **the join between call content, rep corrections and CRM deal outcomes**. Neither Convene nor a CRM vendor holds that join alone. The memo's planned forecasting feature points in exactly this direction. It should be framed as the moat, not as a use-of-funds line item.

## Distribution Channel Assessment

**Verdict:** Weak
**Confidence:** High

This is the plan's most serious structural problem. Distribution and the product's operating surface are owned by the same third party.

- **Who owns the demand surface?** Convene, almost entirely:
  - 94% of recorded calls happen on Convene.
  - About 60% of new revenue starts with an install from the Convene app directory.
  - The viral loop ("Minutely is taking notes") runs inside Convene calls.

  Convene therefore controls discovery, the bot's access to calls, recording permissions, and the in-call surface that generates referrals. It can change any of these with a policy update. Possible moves include restricting third-party bots, adding consent friction, charging directory fees, demoting Minutely's listing, or promoting a first-party alternative in the same slot. Any of these hits acquisition and the core product simultaneously.
- **CAC trajectory at scale.** The PLG loop is cheap today because each recorded call advertises to prospects. Penetration within mid-sized Convene-using sales teams will saturate, though. The three-year goal of "the majority of sales calls held on Convene by mid-sized sales teams" describes exactly that saturation point. Beyond it, growth shifts to outbound and to the upmarket motion, both of which carry much higher CAC.
- **Channel concentration.** The memo names three channels, but the dominant one is fully platform-mediated. Outbound and CRM partner referrals make up the remaining ~40%. The memo does not show that either could scale independently if the Convene channel weakened.
- **Channel/deal-size match.** The current motion fits well: $45/seat, bottom-up adoption, sales-assisted conversion at five active reps. The upmarket plan for 200–1,000-rep organisations changes the game. Those buyers run procurement, security review and competitive bake-offs, and they are the home turf of the two larger enterprise-focused competitors. The PLG loop barely helps there. The memo's stated edge, "price and time-to-value for mid-sized teams," does not carry upmarket.

**Single weakness most likely to cap growth:** dependence on Convene for both distribution and call access. Nothing in the plan reduces it. Expanding CRM integrations from two to six diversifies the *write* side; the *capture* side stays at 94% on one platform.

## Switching Cost Assessment

**Verdict:** Plausible
**Confidence:** Medium

Test case: a one-year customer is offered an equivalent tool at 30% less, or a "free AI notes" checkbox inside Convene.

**What concretely holds them:**

- **CRM mapping (structural, modest).** The mapping covers custom fields, workflow triggers and deal-stage definitions, and costs a sales-ops lead about a week to set up. That is real integration depth. It is also a *one-week* cost, and the knowledge sits partly in the sales-ops lead's head. A motivated competitor can offer white-glove migration and absorb that week for the customer. This is friction, not lock-in.
- **Data gravity (weak, but improvable).** Historical summaries live in the CRM, which the customer keeps when they leave. That is good for the customer and bad for lock-in. Minutely does not appear to hold anything the customer would lose by leaving.
- **Manager workflows (overstated).** Forecast calls and coaching reviews consume summaries. They do not depend on Minutely-specific structure that a competitor couldn't reproduce. "Rebuilding the weekly operating rhythm" overstates the effort when the replacement outputs the same fields into the same CRM.

**The retention data:**

- "Under 1% monthly churn for mapped teams" works out to roughly 11% annual logo churn. That is a healthy figure, but not evidence of structural lock-in.
- The cohort is selected for commitment. Teams that invested a week of sales-ops time were already the most committed.
- The memo doesn't say what share of the 2,300 teams have completed mapping, or what unmapped teams churn at. The overall figure is what matters.
- Most importantly, this retention has never been tested against a free, bundled alternative. Until Convene or a CRM vendor ships one, the number measures customers who haven't been pitched hard.

**Today versus roadmap:** the mapping lock-in exists today. The stronger form, where Minutely becomes the forecasting system of record, depends on the forecasting feature that is still in use of funds. If that feature works, switching would mean losing the predictive model trained on *your own* deal history. That is a genuine switching cost, and it should be built deliberately.

## Network Effect Assessment

**Verdict:** Not Claimed
**Confidence:** High

The memo does not claim a network effect. The "Minutely is taking notes" prospect exposure is a virality loop: useful for growth, but not a structural moat, and it runs on Convene's surface.

## Competitive Response Assessment

**Verdict:** Weak
**Confidence:** High

The memo explicitly bets on incumbent inaction ("our plan does not budget for one"). Its reasons are the default failure modes: incumbents are "slow," have "other priorities," and have publicly said they value their ecosystem.

**Convene (most likely to respond, and most dangerous).** Convene does not need to build sales-specific notes from scratch. A plausible response is to ship generic AI meeting summaries free in its premium tier. A year later, it adds a "sales" template plus native connectors to the two dominant CRMs, priced as a cheap add-on. It doesn't need to match 91% accuracy; 80% at no extra cost is enough for many mid-sized teams. In parallel, it tightens bot-join policies "for privacy and call quality," which adds friction for every third-party recorder. Public statements about a healthy app ecosystem are cheap, and they rarely survive a feature becoming table stakes. If Minutely hits its goal of recording most mid-market sales calls on Convene, at $120M ARR, that is a visible line of value on Convene's own platform. The "0.3% vs 3% of revenue" threshold for incumbent attention is the relevant test, and the plan's success pushes Minutely toward it. **Pattern: bundling, followed by distribution preemption.**

**Major CRM vendors.** The memo notes they have "historically partnered for call recording rather than building it." That history is weak evidence for the next three years, because conversation-derived CRM updates now sit at the centre of how these vendors are pitching AI. A plausible response is to add native call-to-CRM field population inside the CRM, using recordings pulled through Convene's APIs, priced into existing seats. CRM vendors own the destination Minutely writes into. They can also make third-party writes less privileged or more expensive. Minutely's CRM-depth advantage is ultimately rented from the CRM vendor. **Pattern: bundling, plus possibly acquiring a recording player.**

**The two larger standalone competitors.** Today they are enterprise-focused and expensive. A plausible response is to launch a self-serve mid-market tier with aggressive per-seat pricing, funded by their enterprise base. The pressure grows as Minutely moves upmarket into their territory. They would also be logical acquisition targets for Convene or a CRM vendor. **Pattern: price compression, and as acquisition targets.**

**Does the moat survive?** Partially. Mapped, committed teams will likely stay through a first wave of bundling. The PLG funnel is a different story: it depends on Convene's directory and in-call surface, so it is directly exposed. Without new-team inflow, the NRR-driven growth story slows. Pricing also matters here (unit-economics territory, so I'll only flag it): the plan holds $45/seat for three years with no budget for a free bundled alternative. That is the clearest sign of the inaction bet.

The stronger shape would be: "If Convene bundles notes, it validates the category. Our moat is the outcome-trained forecasting layer and multi-platform coverage, which a single-platform bundle can't match." The memo doesn't currently make that argument.

## Factual Foundation

No fact-check report was provided. These three claims carry the most weight for the moat and distribution argument and would most benefit from verification:

1. **Convene's platform posture.** Check the claim that Convene's roadmap excludes AI notes and that its leadership is committed to the app ecosystem. Also check whether Convene already offers, or has announced, native AI summaries, and what its third-party bot and recording policies are. This claim alone determines how exposed the distribution channel is. I haven't verified it, and the competitive-response argument depends on it.
2. **The 91% accuracy figure and how it is measured.** Is it evaluated on held-out data with independent labelling, or against rep edits of Minutely's own drafts? This decides whether the data-flywheel claim is a moat or a marketing number.
3. **Retention by cohort.** Check the <1% monthly churn figure for mapped teams, the share of teams that are mapped, and the churn for unmapped teams. Without these, switching-cost strength can't be judged.

## Overall Assessment

**Strongest lens:** Moat Type. The rep-edit data loop is a genuine, if early, data flywheel. Tied to CRM deal outcomes, it could become a moat incumbents cannot easily copy.

**Weakest lens:** Competitive Response, closely followed by Distribution. Both stem from the same root cause: a single platform owns 94% of capture and about 60% of acquisition, and the plan assumes that platform will stay passive while Minutely builds a large business on top of it.

**Out of scope (for sibling skills):** the $45/seat pricing hold and 131% NRR durability (unit economics), and the realism of the $120M three-year target and the size of the upmarket segment (market sizing).

**The single most important revision:** replace "why incumbents won't catch us" with a plan that assumes Convene bundles AI notes within 18 months, and show why Minutely still wins. In practice:

1. Fund platform diversification as a first-class goal: capture beyond Convene, including phone, the other video platforms, and in-person recording.
2. Reposition the forecasting feature as the core moat. Its value comes from joining call content to CRM deal outcomes, which neither Convene nor a CRM vendor holds alone.
3. Budget a pricing scenario for a free bundled competitor.

The underlying business is strong: fast growth, real engagement, and a real data loop. The memo's job is to show investors that the moat sits in assets Minutely owns, not on infrastructure it rents.
