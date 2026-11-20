> ⚠️ **No fact-check report provided.** This critique does not include independent factual verification. Checkable claims in the draft have not been assessed. For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# Yglesias Critique: One Front Door — A Shared Housing Help Portal for the Lakeshore Region

## The Goal vs. the Mechanism

**The goal is right.** Families facing eviction should reach the help they qualify for in days, not weeks. The $86 million the region already spends should reach people instead of being lost to wrong numbers and dead-end applications. The diagnosis in the first section is the strongest part of the paper. The tenant in Ashby who waits three weeks on the wrong application is a real failure, and it is cheap to fix compared to most housing problems.

**The mechanism is a software front end over 23+ back ends that stay exactly as they are.** It is voluntary, it is governed by committee, and it defers rule alignment to "over time." The paper treats the hard part as finding the door. But the hard part is that each door has different rules, different paperwork, and a different owner. A portal does not remove that complexity. It moves the complexity into a rules engine that someone must keep synchronized with dozens of programs whose eligibility, funding, and forms change every year.

This creates a causal chain that undercuts the goal:

1. **"Apply once, matched to every program" only works if the portal knows every program's current rules.** Without the common eligibility standards the paper postpones, the screener either encodes 20-plus rule sets (expensive and brittle) or approximates them, producing false matches. A false match is the Ashby tenant's problem automated: she is routed confidently to the wrong place.
2. **The portal only removes navigation work if it is comprehensive.** Under voluntary participation, the portal covers some programs. A caseworker still has to ask, "Did the portal check the Corriston city fund, or is Corriston not in yet?" A front door that is one of several doors becomes the 24th door.
3. **Agencies will still require their own documentation.** "Apply once" quietly becomes "apply once, then upload the same pay stubs to four agencies with four verification standards." Residents won't experience that as one front door.

By the paper's own logic, the priority should be **fewer doors and fewer rule sets**, with software following. The paper says "the region does not need more programs," yet the plan adds a new program (the portal) on top of the existing ones. It also leaves the actual consolidation as an unscheduled aspiration. Common eligibility standards do not appear anywhere in the timeline.

## The Boring Lever

Several levers are boring enough that a white paper wouldn't lead with them, and together they probably deliver most of the benefit:

- **Collapse the municipal funds into county administration via MOU.** Nine small municipal grant funds are nine sets of rules, staff, and phone lines. If each municipality kept its money and its say over priorities, but the county ran intake and disbursement, 13 rental-assistance doors would become 4. That needs no vendor, no data-sharing architecture, and no steering committee. It needs four interlocal agreements. In my estimation, this alone eliminates a large share of the "applied to the wrong fund" failures the paper describes.
- **Documentation reciprocity.** Get the four counties and major nonprofits to accept one standard verification packet (ID, income attestation, lease, notice). Allow self-attestation where funder rules permit it; Treasury's emergency rental assistance guidance allowed it, though the region's current funding sources may differ. This captures much of the "tell your story five times" cost without a shared database.
- **A "no wrong door" warm-handoff rule.** If you call the wrong county's shelter line, that line transfers you with your information instead of turning you away. The Corriston father is a policy failure, not a technology failure. A one-page operating agreement fixes it.
- **Put intake where evictions happen.** The fastest route to a family facing eviction is the eviction filing: a navigator at housing court, and a referral insert in the summons or notice. This intercepts people at the moment of crisis without requiring them to find any door.
- **Check what already exists before building anything.** HUD has required Continuums of Care to run coordinated entry for homeless services since roughly 2017. I'm fairly confident of this, though the exact requirements should be checked. The region almost certainly already has a coordinated entry system and HMIS for shelter placement, and probably a 211 line. The paper doesn't mention either. If they exist, the question is why not extend them. If they exist and are failing, that failure is the most important evidence about whether One Front Door would work.

**Rough comparison:** county consolidation of municipal funds, documentation reciprocity, and a courthouse navigator program could plausibly be done for well under $1M a year. They address the two concrete failures in the paper (wrong fund, wrong line) more directly than the $4.5M portal. The portal's distinctive contribution is status tracking and regional data, which are valuable but secondary.

## Follow the Money

The ask is $4.5M to build and $1.8M a year to operate. Over five years that's about $11.7M, roughly 2.7% of the ~$430M of assistance the region would spend in that period at current levels. That's a reasonable overhead ratio *if* it works. Where the money actually goes:

- **Build ($4.5M):** mostly vendor configuration and integration. "Modest customization" of a case management platform against 20-plus eligibility rule sets, several county IT systems, and existing HMIS is the classic underestimate in government technology. Public-sector IT projects of this kind routinely overrun. I'd plan for 1.5–2x on cost or timeline and would not be surprised by worse.
- **Operations ($1.8M/yr):** much of this will be vendor licensing and hosting. The part that actually makes the system work, a staff that keeps eligibility rules current and runs training, is probably underfunded. That staff is what prevents the screener from going stale.
- **The savings case doesn't obviously close on staff time alone.** Here is a hypothetical, since the paper gives no caseworker count. Suppose 100 caseworkers across member agencies at $70K loaded cost spend a third of their time navigating. That's about $2.3M a year. If the portal halves navigation time, it saves about $1.2M a year, less than its operating cost. That's fine: the real return is faster assistance and prevented evictions. But the paper should make that case explicitly instead of implying the portal pays for itself.
- **Money spent on assistance itself.** The paper says "the money is not the main problem." I'm skeptical. Lowering friction raises application volume. With a fixed $86M pool, more complete and faster applications mean funds are exhausted sooner and more applicants hear "no." That's still an improvement, since a fast no beats a three-week wrong no. But the freed caseworker time may be absorbed by higher volume rather than "actual casework." The paper's regional-data benefit will likely reveal a funding gap, and the paper should be ready for that.
- **Who pays the $1.8M every year.** "Shared funding in proportion to capacity" from voluntary participants, plus philanthropy, is a fragile base for a recurring cost. Philanthropy likes to fund builds and pilots, not year-seven hosting bills.

## Factual Foundation

No fact-check report was provided, so none of the paper's claims have been independently verified. The claims that matter most for whether the mechanism works:

- **The $86M regional spending figure.** It carries the "money isn't the problem" argument. It also matters what share is one-time federal pandemic-era funding (ERA) that has wound down or will. If the pool is shrinking, the portal is being built for a smaller system.
- **"Caseworkers estimate they spend a third of their time figuring out where to send people."** This is self-reported and central to the efficiency case. Worth a time study, or at least a structured survey, before it anchors a $4.5M decision.
- **"Similar coordinated-entry systems have been adopted… the technology is mature."** True for homelessness coordinated entry, as best I know. Much less clearly true for multi-jurisdiction, multi-program eligibility screening across rental assistance, utilities, legal aid, and shelter. The paper should name two or three comparable regions and what happened there.
- **"Weeks to days."** An outcome claim with no cited basis. If comparable systems exist, their before-and-after numbers should be here.
- **Existing coordinated entry/HMIS and 211 in the region.** Not a claim the paper makes, but the most important fact it omits.

## The Scale Test

Here, scale means programs times jurisdictions times years, not 10 million users.

- **Rule churn at scale.** Twenty-three municipalities, four counties, two utility nonprofits, legal aid, and shelter providers each revise eligibility, income limits, and funding priorities on their own schedules. Every annual change must flow into the screener promptly, or the portal routes people incorrectly. Over a decade, programs will be created, defunded, and renamed. The maintenance burden grows with the number of participants, the opposite of the network effect the paper hopes for.
- **Demand at scale.** If the portal works and becomes the default, application volume rises. Agencies that joined expecting to save staff time may see their intake queues grow. That is the moment some of them reconsider participating.
- **Exception handling at scale.** Most households fit a screener. A meaningful minority, such as mixed-status families, informal tenancies, doubled-up households, and domestic violence survivors, don't. At regional volume, the "doesn't fit the form" cases need a human fallback path. That path looks a lot like the navigation work the portal was meant to eliminate.
- **Data sharing at scale.** "Appropriate privacy safeguards" is carrying an enormous load. Legal aid records are privileged. DV service providers are restricted from entering identifying data into shared systems (the VAWA restrictions on HMIS; I'm fairly confident this applies, though the details should be checked). Some records may touch health information. Each participating entity needs a data-sharing agreement reviewed by its own counsel. Twenty-plus agreements is a year of legal work that the timeline doesn't include.

## The Org Chart

The paper's org chart has one box: a steering committee of counties, municipalities, nonprofits, landlords, and people with lived experience. That's a legitimate advisory body. It is not an operator. The job description test:

> **Director, One Front Door.** Reports to: ___. Employed by: ___. Authority to require participating programs to update eligibility rules in the system: ___.

None of the blanks can be filled from the paper. Concretely:

- **Who signs the vendor contract and owns the data?** The Collaborative? One lead county? A new joint powers authority? Public procurement is legally impossible without a contracting entity. If it's a county, its procurement timeline replaces the paper's, and six months for vendor selection is optimistic for most public bodies.
- **Who has authority over the rules?** No one in this structure can tell a municipal fund to change its eligibility criteria or a county to accept another county's documentation. "Common eligibility standards will be developed by the steering committee" means unanimous consent among parties with no obligation to agree.
- **Who maintains it after the champions leave?** County administrators and nonprofit executive directors rotate. The system needs a named owner with a budget line, not a coalition's goodwill.
- **Track record.** Multi-jurisdictional voluntary data and intake collaboratives often stall in the governance phase. The paper should cite a region where this worked and copy its governance structure, not just its software.

A workable org chart could look like this: one county (or an existing regional body) as fiscal and contracting agent, with interlocal agreements binding participants to specific obligations. Those obligations would include rule-update deadlines, documentation reciprocity, and cost shares. The steering committee would advise, and a small dedicated staff would handle product, rules maintenance, and data stewardship.

## Adoption Survival

The adoption plan is "participation will be voluntary… once the first jurisdictions see the benefits, others will want to join." The incentives point the other way.

- **The benefits go to residents; the costs go to agencies.** Joining means paying a share, ceding control of intake, changing paperwork, and negotiating data agreements. The payoff, faster help for residents, is real but doesn't show up in the joining agency's budget. Diffuse beneficiaries plus concentrated costs is the classic shape of a stalled rollout.
- **Who opts in first.** Small municipalities with tiny grant funds and no staff may eagerly join, since it offloads administration. Large counties with established systems, IT departments, and federal reporting obligations have the least reason to join and the most programs. A pilot without at least one county is a pilot that proves little.
- **Likely defenders:** caseworkers, if it really saves them time; small municipalities; housing advocates. **Likely opponents or quiet resisters:** county IT and program offices protective of their systems, and any agency whose metrics look worse under regional data.
- **Sponsor rotation.** A 30-month timeline spans at least one election cycle for county boards and probably some leadership turnover. Commitments made in months 1–6 need to be contractual to survive.

**The popular version** gets most of the benefit at a fraction of the adoption friction. It is a staffed regional navigator line, possibly built on the existing 211, backed by a maintained eligibility directory, warm-handoff agreements, and documentation reciprocity. Phase two would add county consolidation of municipal funds. Software comes last, once there are fewer rule sets to encode and binding agreements to encode them. That version asks agencies for much less up front, produces visible wins quickly, and creates the trust and rule alignment the portal needs to succeed.

## The Cost Disease Check

This is partly relevant. Caseworker and navigator services are labor-intensive in exactly the way that resists productivity gains, so the paper's hope that software substitutes for navigation labor is reasonable but should be modest. Exceptions and complex cases will still need people.

The more pressing analogue is the government technology cost pattern. Projects scoped as configuration tend to become custom development, and ongoing license costs escalate once the vendor is entrenched. Of the $4.5M build, I'd guess a substantial fraction goes to integration and rework rather than resident-facing features. That's a rough guess, not an estimate from data. The cost disease risk can be reduced by contracting in modular phases, requiring data portability, and keeping the rules engine owned by the region rather than locked inside the vendor's platform.

## Overall Assessment

**Sound:** the diagnosis. Fragmentation is a real, costly, fixable problem. The paper is right that coordination can do more per dollar than new programs. The commitment to status tracking and regional data is valuable, and the cost relative to the assistance pool is reasonable.

**Wish-fulfillment:**
- Voluntary adoption cascading on its own.
- Eligibility harmonization happening "over time" without anyone owning it.
- Data sharing handled by "appropriate safeguards."
- A steering committee standing in for an operating entity.
- The assumption that money isn't a constraint.

**The single most important revision is to reverse the sequence.** Consolidate doors and align rules first, through county administration of municipal funds, documentation reciprocity, and warm-handoff agreements. Secure binding interlocal agreements with at least one county and its municipalities. Then build software for that smaller, harmonized system. Make the pilot a full county stack rather than a scattering of early adopters, so it can actually demonstrate weeks-to-days. And find out what the region's existing coordinated entry system and 211 already do before procuring a new platform.

The underlying idea, one place to start and a system that knows where you belong, is right. The path there runs through interlocal agreements and rule consolidation more than through a vendor contract.

**Load-bearing objection:** The deferred eligibility harmonization combined with voluntary participation is the objection to act on first, because the portal's core promise ("apply once, matched to every program") depends on comprehensive coverage and encodable rules, and fixing it reorders the whole plan. It is followed by (2) the absence of an operating entity with contracting and rule-setting authority, (3) the unexamined assumption that money isn't the constraint (lower friction raises demand against a fixed pool), and (4) the unscoped legal work of multi-party data sharing.
