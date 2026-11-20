# Business-Plan Moat & Distribution Critique: Checkwise Strategy Brief

> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft (market sizes, named partnerships, traction figures, competitor counts) have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

**Summary:** The brief claims switching costs as its moat, but its own evidence argues against it. Easy export, ten-minute training, month-to-month terms and 2.1% monthly logo churn all point the other way. The real asset is a distribution loop: the landlord sees the report and pulls in more contractors. That loop is not defended yet. The best use of the integrations budget is to turn that landlord-side pull into structural lock-in.

## Moat Type Assessment

**Verdict:** Weak
**Confidence:** High

The brief names **switching costs** as its core defensibility, and the moat archetype is the right one to aim for in workflow SaaS. The problem is that the brief's own evidence takes the claim apart.

- **Templates:** this is the only item that is real today. Rebuilding 10–30 checklists costs a supervisor a day or two. That is friction, not lock-in.
- **History:** the brief says the full archive exports in one click. That is good for trust, but it removes data gravity by design.
- **Technician training:** ten minutes. That is a low retraining cost, and the brief presents it as a selling point.
- **Contracts:** month-to-month with no minimums, so there is no contractual lock-in.
- **Customers expect the reports:** this is the most interesting item, because the expectation sits with a third party (the landlord) rather than the contractor. But a PDF layout can be imitated. As it stands, this is closer to a format habit than a moat.

The asset the brief actually describes is different from the one it names. The report reaches the landlord, the landlord asks for it again, and the contractor upgrades. That is a **distribution advantage that looks like a brand or format standard**. It is valuable, but it is not one of the durable archetypes yet.

**For a moat to compound, one of these would need to be true:**
- (a) Landlords consume Checkwise output in a way they cannot get elsewhere, such as a landlord-side view across all their contractors. This would create a cross-side dependency.
- (b) Contractors' job, billing and ticketing flows run through Checkwise. This is the v3 integrations thesis.

Neither exists today. The honest framing is: *"We have no structural moat yet. We have strong pull-through distribution and roughly an 18-month window to convert it into one."*

## Distribution Channel Assessment

**Verdict:** Plausible
**Confidence:** Medium

This is the strongest part of the plan.

**Free tier / landlord pull-through (≈80% of new paying firms)**
- **Who owns the demand surface:** mostly Checkwise. The report is the advertisement, and it travels through the contractor–landlord relationship, not through Google or an app-store auction. That is unusual and valuable. Mobile app-store dependency for the technician app is a minor exposure.
- **CAC trajectory at scale:** the loop spreads through landlords' contractor rosters, so its reach is bounded by landlord overlap. Once Checkwise saturates the contractors working for already-exposed landlords, the loop needs new landlords to seed it. The brief gives no data on whether growth is broadening (new landlords) or deepening (the same landlords). That split is worth reporting to the board.
- **Concentration:** 80% from one loop is high. It is less dangerous than 80% from a rented channel, but the loop has a single point of failure: **brand visibility on the report**. If paid-tier reports are contractor-branded with little Checkwise attribution, or if a competitor's report looks equivalent, the landlord's request becomes "send reports like these" rather than "use Checkwise." That shift can happen quietly.
- **Deal-size match:** good. Neither motion uses sales effort heavier than a ~$350/month firm can support.

**Inside sales (≈20%, firms with 20+ technicians)**
- About $7K ACV supports a short, demo-led motion, and the team works free-tier-warmed leads. This is coherent and sized correctly.
- The brief rightly says "nothing heavier."

**Single biggest distribution weakness:** the loop's value is captured by a *format* that Checkwise does not control once a competitor copies it. The landlord, the node that actually generates referrals, has no account, no login and no reason to prefer Checkwise specifically. The brief notes this under "Network effect." It is also the main distribution risk.

## Switching Cost Assessment

**Verdict:** Weak
**Confidence:** High

**Test:** a contractor one year in is offered a tool that is 30% cheaper, offers template import, and produces a near-identical report. What stops them switching?

- **Templates:** a day or two of rebuilding, or less if the competitor parses exported Checkwise reports into templates. That is a straightforward feature to build.
- **History:** one-click export, so nothing is lost.
- **Training:** about ten minutes per technician.
- **Contract:** none.
- **Landlord expectation:** met by the cloned layout.

The honest answer is "very little," and the brief's retention numbers agree:
- **2.1% monthly logo churn is about 22% annual logo churn**, an average customer life of roughly four years.
- That is respectable for small-business SaaS, but it is inconsistent with "leaving becomes very painful."
- **118% NRR** is driven by seat expansion within the firms that stay. It shows customers value the product, not that they cannot leave.

The brief's own line, "customers stay because they want to," is the accurate description. That is product satisfaction, which is worth having but is not a moat. Keep the easy export, because it is a real trust asset in sales. Just stop counting it on the defensibility side.

**Is the lock-in available today or only on the roadmap?** The only structural lock-in in the brief is the **v3 integrations module, planned for H2 next year**. Until then the switching-cost moat is hypothetical. There are also two risks with the v3 design itself:
- **Contractor-side integrations:** two-way sync with the field-service suites does raise switching costs. But it also makes Checkwise dependent on APIs controlled by those suites, which are the very competitors the brief names as its most serious threat. See below.
- **Landlord-side integrations:** sync with maintenance-ticket portals is the more interesting half. It is the first point where a party other than the contractor would depend on Checkwise.

## Network Effect Assessment

**Verdict:** Not Claimed
**Confidence:** High

The brief explicitly and correctly declines to claim one. The landlord referral loop is a growth loop, not a network effect, because landlords gain nothing as more contractors join. (There is a latent opportunity here, covered in the Overall Assessment, but it does not exist today.)

## Competitive Response Assessment

**Verdict:** Weak
**Confidence:** Medium

Assume Checkwise reaches the next milestone, for example 5,000 firms or a visible share of contractors serving large landlords. Three players are best positioned to respond.

**1. Field-service management suites.** The brief names these as its most serious threat but does not name them. Their response is not to cut the price of their full suite. It is to **bundle**: a free or near-free "inspections" tier, or an inspection-only SKU priced to win small firms, built to feed users into the full suite later. These companies already have inspection forms, mobile apps, and brand awareness among contractors. Adding a branded PDF and offline mode is a quarter of engineering work, not two years.

The brief's plan to integrate with all three by then cuts both ways:
- Integration does make Checkwise a partner.
- It also gives each suite a clear view of how many of their customers want lightweight inspections, and it puts Checkwise's v3 moat behind APIs those suites control.
- "Partner rather than target" holds only if Checkwise is more valuable to them as a feeder than as a feature. The brief does not argue that point.

**Most likely pattern: bundling, with distribution preemption through API terms.**

**2. Property-management and maintenance-ticketing platforms on the landlord side.** The brief treats these only as integration targets. These platforms already have vendor portals that contractors log into to close tickets. Their response is to **add inspection capture to the vendor portal** and nudge landlords to require it. Inspections would then arrive in the landlord's system with no PDF at all.

This attacks the loop at the node that generates it. If landlords start saying "submit it through our portal" instead of "send it like Checkwise," the 80% channel weakens without any contractor-side competitor winning. **Pattern: distribution preemption.**

**3. Vertical inspection apps and generic form builders.** These are the most likely to copy the visible differentiators: offline mode, photo annotation, the branded report. Form builders in particular can ship a "contractor inspection report" template and compete on price. Individually they are weaker threats, but they erode the format advantage. **Pattern: price compression.**

**Does the moat survive?** Not as currently built.
- The brief's response thesis rests on "the suites' pricing and sales models make that unlikely within two years." That is a bet on incumbent inaction, with a timeline that roughly matches v3 shipping.
- The stronger response, where incumbent action makes Checkwise more valuable, requires Checkwise to hold something the incumbents need. That would mean the landlord relationship or the cross-contractor inspection record. Today it holds neither.

## Factual Foundation

No fact-check report was provided. These claims carry the most weight and would benefit most from verification:

1. **"Field-service suites cost five to ten times as much per seat and take months to roll out."** This underpins the two-year competitive window. Some field-service products already target small contractors at lower price points and with quick self-serve onboarding. I have not verified pricing for the specific suites the brief means. If any of them already sells to 5–50-person firms, the window is shorter than stated.
2. **The 80% free-tier attribution and the landlord-referral mechanism.** How is "came from a landlord request" measured? Whether the loop is broadening (new landlords) or deepening (the same landlords) determines how durable the main channel is.
3. **The 2.1% monthly logo churn and 118% NRR.** Neither figure is checked. The more useful check is internal: does churn fall for firms with more templates, more seats, or landlord-driven acquisition? That would show whether any switching cost exists today.

## Overall Assessment

- **Strongest lens: distribution.** A pull-through loop where the customer's customer sells the product, with demand Checkwise mostly owns and a sales motion correctly matched to deal size.
- **Weakest lens: switching cost.** This is the moat the brief actually claims. The brief's own facts (one-click export, ten-minute training, month-to-month terms, about 22% annual logo churn) show it is not there yet, and the version that would create it is roadmap-dependent and partly routed through competitors' APIs.

**The single most important revision:** rewrite the moat section to say *"no structural moat yet; strong distribution; here is how we convert it."* Then point the integrations investment at the **landlord side first**:

1. **Give the referral node a reason to prefer Checkwise.** Make the landlord-ticketing sync, or a lightweight landlord view of all inspections across their contractors, the priority deliverable rather than the second half of v3.
2. **Create a real cross-side network effect.** Once landlords consume inspections from several contractors in one place, they benefit as more contractors join.
3. **Move the switching cost to a different party.** A contractor's switching cost then includes "my landlord would have to accept a different system." That is far stickier than template rebuilding.
4. **Pre-empt the landlord-side competitive response.** This blunts the most dangerous response identified above, the ticketing platforms building inspections into their own vendor portals.

The contractor-side suite integrations still matter, but they should come second, with a clear position on API dependency.

When presenting the hiring ask to the board, frame it as a race to convert the format advantage into structural lock-in before the 2-year window closes. That is an honest pitch, and a more fundable one than "switching costs already protect us."

**Out of scope (for the sibling skills):** the $29→$35 price increase and whether seat-based pricing holds up under bundled competition are unit-economics questions for `business-plan-critique-unit-economics`. One note from this lens: raising prices increases the gap a 30%-cheaper competitor can exploit, so the timing relative to v3 matters. The ceiling on landlord-loop reach is a market-sizing question for `business-plan-critique-market-sizing`.
