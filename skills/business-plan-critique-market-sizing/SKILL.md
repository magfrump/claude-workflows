---
name: business-plan-critique-market-sizing
lens: market-sizing
description: >
  Critically review a business-plan-shaped draft (founder pitch, investor deck narrative,
  go-to-market strategy doc, fundraising memo, product strategy brief, market-entry analysis,
  or similar) using a focused set of market-sizing lenses: TAM definition and derivation,
  SAM (addressable-segment) realism, SOM (capturable-share) achievability, market timing,
  and comparable-company benchmarks. This skill exists because many early-stage plans pass
  moat and unit-economics scrutiny but quietly fail on the market story — TAM is computed
  top-down from a category report that doesn't match the actual product, the addressable
  segment is defined so loosely it includes customers who would never buy, the captured share
  implied by the revenue plan exceeds what comparable companies have achieved at comparable
  stage, the "why now" rests on a trend that's been true for a decade, or the comp-set
  benchmarks have been cherry-picked to support the model. Use this skill whenever a draft
  proposes a business or product strategy and the author wants pressure on whether the market
  is large enough, addressable enough, capturable enough, and timed right. Also trigger when
  the draft quotes a TAM, SAM, SOM, market-growth rate, addressable-customer count, capturable
  share, "why now" thesis, or comparable-company revenue/share figure the author wants
  pressure-tested. Trigger phrases: "is the market real", "review my TAM", "is the TAM
  defensible", "TAM/SAM/SOM critique", "market-sizing review", "is the market big enough",
  "stress-test the market story", "why-now critique", "market timing review", "is the
  addressable segment realistic", "are the comparable benchmarks right", "is the captured
  share achievable", "review the market opportunity", "critique the addressable market",
  "did I size this market right". Produces a structured Markdown critique with a known
  section layout (TAM Definition, SAM Realism, SOM Achievability, Market Timing, Comparable
  Benchmarks, Factual Foundation, Overall Assessment). Scope is intentionally narrow:
  moat/distribution and unit-economics critiques are explicitly deferred to sibling skills
  (`business-plan-critique-moat` and `business-plan-critique-unit-economics`) so this skill
  stays focused on the market story. This skill is also distinct from `cowen-critique`, which
  applies general argument-rigor moves to any prose argument and may incidentally pressure a
  market claim ("if this market is so large, why isn't there a $1B incumbent already?") but
  does not systematically check TAM derivation, segment definition, capturable share, market
  timing, or comp-set benchmarks. If the draft's biggest weakness is general argument structure
  rather than market sizing specifically, route to `cowen-critique` instead. NOTE: This skill
  is typically invoked by the draft-review orchestrator, which provides a pre-built fact-check
  report. If a fact-check report is provided, use it as your factual foundation and do not redo
  basic fact verification.
when: User wants a market-sizing critique of a business plan, pitch, or strategy doc
requires:
  - name: fact-check
    description: >
      A fact-check report covering the draft's checkable claims (quoted TAM/SAM figures,
      market-growth rates, named research firm reports such as Gartner/IDC/Forrester,
      comparable-company revenue and share figures, customer-count claims, "why now" trend
      data). Typically produced by the fact-check skill. Without this input, market-size
      figures and comp-set claims in the plan are not independently verified — the critique
      proceeds on argument structure and internal consistency only.
---

> On bad output, see guides/skill-recovery.md

# Business-Plan Market-Sizing Critique

You are reviewing a business-plan-shaped draft for one specific question: **is the market
story defensible — large enough, addressable enough, capturable enough, and timed right?**
Many plans that survive moat and unit-economics scrutiny still fail on the market story —
TAM derived from a category report that doesn't match the product, an addressable segment
defined so loosely it includes customers who'd never buy, a capturable share that exceeds
what any comparable company has reached at comparable stage, a "why now" that's been true
for ten years, or a comp set assembled to support the model rather than test it. This skill
applies five lenses scoped to that question.

## Scope (and what's deferred)

This skill covers **market sizing only**. Two adjacent dimensions are explicitly out of scope
and addressed by sibling skills:

- **Moat-and-distribution critique** (moat type, distribution channel, switching cost, network
  effect, competitive response) — handled by the `business-plan-critique-moat` skill.
- **Unit-economics critique** (CAC, LTV, contribution margin, payback period, gross-margin
  trajectory) — handled by the `business-plan-critique-unit-economics` skill.

This skill is also distinct from `cowen-critique`, which applies general argument-rigor moves
(boring-explanation-first, invert-the-thesis, revealed preferences, market signals) to any
prose argument. A Cowen critique on a fundraising memo may incidentally pressure the market
claim — for example, asking why no $1B incumbent already exists if the market is genuinely
large — but it does not systematically check TAM derivation, segment realism, capturable
share, "why now," or comparable benchmarks. Cowen pressures the *argument*; this skill
pressures the *market-sizing methodology*. The two are complementary: an orchestrator can
run both for a business-plan draft without the findings collapsing into each other.

If the draft's biggest weakness is in moat/distribution, unit economics, or general argument
structure, name it briefly under "Out of scope" in your Goal-Alignment Note and let the
orchestrator route it. Do not attempt those critiques here — keeping this skill narrow is
what lets it land sharp findings on the market-sizing question without blurring into a
generic business review.

## Pre-flight: Skip Obvious Stubs

If the draft is under ~500 words AND contains TODO markers or structurally incomplete signals
(empty sections, missing thesis/intro, placeholder text), output the single line
`draft incomplete; market-sizing critique skipped` and stop. Both conditions must hold —
legitimately short pitches without stub markers, and longer drafts with stray TODOs, still
get the full critique.

## Using the Fact-Check Report

If you have been provided a fact-check report alongside the draft, treat it as your factual
foundation. You do not need to independently verify quoted TAM/SAM figures, market-growth
rates, named research firm reports, comparable-company revenue or share figures, or
customer-count claims that the fact-check report has already assessed.

Instead:

- **Reference the fact-check findings** where they bear on market sizing. If a quoted TAM
  figure is rated Unverified or Inaccurate, that directly affects the TAM Definition lens.
- **Build on the fact-check** where it surfaces ambiguity. A "Mostly Accurate" finding on a
  comp's revenue at year 5 can still affect the Comparable Benchmarks lens if the comp
  operates in a structurally different segment.
- **Focus your energy on the lenses below** — what this skill uniquely provides is the
  structural assessment of whether the market story holds together end-to-end (definition →
  segment → capture → timing → comparables).

If no fact-check report is provided, **emit the following warning at the top of your output
before the critique begins:**

> ⚠️ **No fact-check report provided.** This critique does not include independent factual
> verification. Checkable claims in the draft (quoted TAM/SAM figures, market-growth rates,
> research firm reports, comparable-company revenue or share figures) have not been
> assessed. For full verification, run the `fact-check` skill first or use the
> `draft-review` orchestrator.

Then proceed with the critique focusing on internal consistency and structural argument. Do
NOT attempt your own fact-checking — an ad-hoc spot-check without proper sourcing creates a
false sense of verification. When discussing numerical claims you cannot verify, flag your
actual confidence: "this $42B TAM figure is doing a lot of work and I haven't verified the
underlying Gartner methodology" beats either false confidence or vague hedging.

## The Five Lenses

### 1. TAM definition and derivation

TAM (Total Addressable Market) is the most rhetorically loaded number in any pitch — it sets
the ceiling on the entire investment thesis, and small definitional changes produce
order-of-magnitude swings. The most common failure mode is reporting a TAM derived top-down
from a research-firm category report that includes adjacent products, channels, or geographies
the company does not actually serve.

The specific moves:

- **Top-down vs bottom-up.** A top-down TAM cites a category total (e.g., "global CRM market
  is $90B per Gartner") and claims a slice. A bottom-up TAM multiplies addressable customers
  by realistic ACV. The two should roughly reconcile; if they diverge by more than ~3×, one
  of them is wrong. Plans that present only one, especially top-down, are skipping the
  reconciliation step.
- **Category-report fit.** When TAM cites a research-firm category, check whether the
  category definition matches the product. A "marketing software" category total bundles
  enterprise marketing clouds, mid-market automation, SMB email tools, and adtech — a SMB
  email product cannot claim the full category. Ask: what fraction of the cited category is
  actually addressable by *this* product?
- **Adjacency creep.** TAMs that include "and we'll expand into X, Y, Z" are mixing today's
  TAM with future-product TAM. Separate the two — investors are funding the wedge product's
  TAM, not the imagined platform's TAM.
- **Geography and segment inclusion.** A "$50B TAM" that includes geographies the company
  cannot legally serve, segments that require certifications it doesn't have, or buyers it
  cannot price to (e.g., government, regulated verticals) is overstated by the inaccessible
  fraction.
- **Methodology disclosure.** If the plan does not disclose how TAM was derived, treat the
  number as opaque and say so. A confident TAM with a hidden derivation is worse than a
  smaller TAM with a transparent build.

If the bottom-up build (realistic addressable customers × realistic ACV) produces a TAM
materially smaller than the top-down headline, that's the headline finding. State both
numbers and the gap.

### 2. SAM realism (addressable segment)

SAM (Serviceable Addressable Market) is the slice of TAM the company can actually serve given
its product, channel, and operational reach. The most common failure mode is defining SAM by
demographic or firmographic filters that don't predict purchase behavior — "all US SMBs with
10-500 employees" includes a vast majority who would never buy this product at this price.

Pressure-test the segment definition:

- **Behavioral vs descriptive segmentation.** Descriptive filters (industry, employee count,
  geography) are easy but weak — they identify *who could be a customer* in principle, not
  *who would buy*. Behavioral filters (current spend on category X, observable pain Y, use
  of substitute Z) better predict conversion. Plans that segment only descriptively are
  almost always overstating SAM.
- **Buyer vs user.** In B2B, the user and the buyer are often different people in different
  parts of the organization. SAM should be sized by *buyer* count, not user count. A plan
  that counts users (e.g., all engineers in target companies) will overstate SAM by the
  user-per-buyer ratio.
- **ACV-segment match.** SAM × stated ACV must produce a coherent revenue ceiling. If SAM is
  100K accounts at $50K ACV, that implies a $5B addressable revenue line — is that plausible
  for the segment, or has ACV been quoted from a few enterprise wins while SAM was sized
  from SMB?
- **Regulatory and certification gates.** Segments that require SOC 2, HIPAA, FedRAMP, ISO
  27001, or industry-specific certifications are not addressable until the certification
  exists. Plans frequently claim healthcare, financial services, or government SAM without
  the gating cert; that fraction is aspirational TAM, not SAM.
- **Wedge vs full segment.** Early-stage companies serve a *wedge* — a narrow beachhead
  within the segment. SAM at year 1 is much smaller than full SAM. Plans that conflate
  steady-state SAM with year-1 addressable are skipping the question of where the company
  *starts*.

If SAM is sized by descriptive filters alone, the most useful intervention is to ask: of the
filtered set, what fraction has the *behavioral* signal that predicts purchase? That ratio
typically reduces SAM by 5-20×.

### 3. SOM achievability (capturable share)

SOM (Serviceable Obtainable Market) is what the company actually projects capturing —
typically a percentage of SAM by some milestone year. The most common failure mode is
projecting a capturable share that exceeds what any comparable company has achieved at
comparable stage, without naming what makes this company an outlier.

Check the capture math:

- **Implied share at milestone.** Back into the share from the revenue plan: if year-5
  revenue is $200M and SAM is $5B, implied share is 4%. Is 4% in 5 years plausible for the
  category? In most B2B SaaS, 1% in 5 years is excellent; >5% requires either category
  disruption or an unusually fragmented incumbent landscape.
- **S-curve vs linear assumptions.** Revenue plans that grow share linearly (1% → 2% → 3% →
  4% → 5%) typically overstate near-term capture and understate the difficulty of the late
  push. Real category capture follows S-curves with a long tail. If the plan's share curve
  is straight, it's almost certainly wrong-shaped, even if the integral is right.
- **Beachhead → expansion logic.** Healthy plans articulate *which sub-segment* they capture
  first (beachhead), what share they take there (often 20-40% of a small wedge is
  achievable), and how they expand outward. Plans that project "X% of SAM" without naming
  the wedge are projecting capture without a path.
- **Competitive density at SOM.** If the projected share requires displacing named
  incumbents, the plan should account for the cost of displacement — switching effort,
  competitive response (incumbent price cuts, bundling), and the realistic share gradient
  (you rarely take >30% from an incumbent that's actively defending). Plans that project
  high share in a defended market without addressing this are projecting wishes.
- **Sales-capacity reality check.** Implied SOM ÷ ACV = customer count needed. Customer
  count ÷ rep-productivity-per-year = sales reps required. Sales reps × ramp time = hiring
  plan. Often the implied sales org is larger than the funding ask supports. If so, SOM is
  either smaller, slower, or requires distribution efficiency the plan hasn't demonstrated.

If projected SOM exceeds the share captured by the most successful comparable company at the
same stage, the plan is implicitly claiming top-decile (or better) execution. State the
implied share, name the comp, and call out the implicit claim.

### 4. Market timing ("why now")

Market timing is the question of whether the conditions that make this product viable are
*newly* present. The most common failure mode is a "why now" that has been true for ten
years — citing trends so persistent they no longer differentiate timing.

Pressure-test the timing thesis:

- **Specific trigger vs persistent trend.** "Cloud adoption is growing" has been true since
  2008. "AI is improving" has been true since 2012. These are not "why now" — they are "why
  ever." A real "why now" names a specific change in the last 1-3 years: a new platform
  primitive (e.g., function-calling LLMs in 2023), a regulatory shift (e.g., a new mandate
  taking effect), a price-curve crossing (e.g., a cost coming below the willingness-to-pay
  threshold), or a behavioral inflection (e.g., remote work becoming permanent post-2020).
- **Adoption-curve placement.** Where on the technology-adoption curve is the market —
  innovators (<2.5%), early adopters (2.5-16%), early majority (16-50%), late? Each phase
  has different sales dynamics, expected ACVs, and time-to-revenue. Plans that pitch
  enterprise SaaS pricing at innovator-stage adoption are mismatched.
- **"Too early" failure mode.** The graveyard of premature category bets is large — the
  product can be right and the market can be too early. Look for evidence the market is
  *currently* spending money on substitutes or workarounds (revealed preference) versus
  evidence the market *will* spend money once educated (assumption). The first is a real
  market; the second is category-creation, which is harder and slower.
- **"Too late" failure mode.** Symmetric: if the timing thesis is "this category is going to
  be huge," but the category already has a $5B incumbent, the plan is either late or
  positioning against an established player. Both are viable, but the plan should
  acknowledge which one and adjust the strategy accordingly.
- **Reversibility of the trigger.** If the timing depends on a single catalyst (a regulation,
  a platform change, a one-time behavioral shift), what happens if the catalyst reverses
  (regulation rolled back, platform changes API, behavior reverts)? Strong timing theses
  rest on multiple reinforcing triggers.

The most useful framing: "Name the specific change in the last 24 months that makes this
product viable now and was not viable before. If you can't name one, the timing thesis is a
trend, not a trigger."

### 5. Comparable benchmarks

Comparable companies (comps) are the most empirical input to a market-sizing argument —
they show what is actually achievable in adjacent or analogous markets. The most common
failure mode is cherry-picking comps that support the model and excluding ones that don't.

Pressure-test the comp set:

- **Comp selection logic.** Why these comps and not others? Plans that name 3 successful
  comps in the category should also name the 3 unsuccessful ones to show the realistic
  range. If the plan only cites successes, the implicit base rate is ~100%, which is wrong.
- **Stage-matching.** Year-5 revenue at a comp founded in 2010 is not directly comparable to
  year-5 revenue at this company unless the market conditions match. Comparing to a comp
  that benefited from a unique tailwind (the iPhone launch, the COVID remote-work shock) is
  comparing to an unrepeatable situation.
- **Segment-matching.** A comp that succeeded selling to enterprise IT is not comparable to a
  plan selling to mid-market marketing. Same category, different buyer, different sales
  motion, different ACV ceiling. Check that the comp set's *go-to-market* matches the plan's.
- **Outcome conditioning.** Citing only comps that *succeeded* survives selection bias. The
  base rate for any specific market entry is dominated by the failures you don't see. The
  realistic comp set includes the median outcome and the failure modes, not just the
  outliers.
- **Implied multiples.** If the comp set implies "companies in this category reach $100M ARR
  by year 5," check whether any did so without unusual conditions (a category-defining
  partnership, a viral consumer moment, an acquired distribution channel). The headline
  number from the comp set may rest on conditions the plan can't replicate.
- **Negative comps.** What companies tried this and failed, and why? A plan that cannot name
  negative comps is either operating in a genuinely new category (rare) or hasn't done the
  research. Either way, name the failures and state which failure modes this plan's strategy
  avoids.

The most useful framing: "If the comp set's median outcome is $X by year Y, and the plan
projects $5X by year Y, what makes this company an outlier? Name the structural advantage,
or revise the projection toward the median."

## How to Structure the Critique

Output your critique as a Markdown document. Use this exact section layout so downstream
consumers (orchestrators, format tests, human readers comparing critiques) can rely on the
structure:

```markdown
# Market-Sizing Critique: <draft title or topic>

## TAM Definition Assessment
## SAM Realism Assessment
## SOM Achievability Assessment
## Market Timing Assessment
## Comparable Benchmarks Assessment
## Factual Foundation
## Overall Assessment
```

If a lens does not apply to the draft (e.g., the plan reports no comp set at all), keep the
section heading and state under it what the plan is missing rather than dropping the section.
The skeleton is fixed; the content adapts.

Each of the five lens-assessment sections MUST include a `**Verdict:**` line whose value is
one of `Defensible`, `Plausible`, `Inflated`, `Speculative`, or `Not Claimed` (use
`Not Claimed` for a lens the plan does not address — for example, no comp set is provided,
or no "why now" is named). Each lens-assessment section MUST also include a `**Confidence:**`
line valued `High`, `Medium`, or `Low`, reflecting how confidently you can land the verdict
given the evidence in the draft (and fact-check report, if provided). Place both fields at
the top of the section, before prose.

### TAM Definition Assessment
Reconcile top-down and bottom-up TAM. Identify category-report misfit, adjacency creep,
geographic/segment over-inclusion, and undisclosed methodology. State the gap between the
plan's headline TAM and the realistic addressable figure.

### SAM Realism Assessment
Distinguish behavioral from descriptive segmentation. Check buyer-vs-user counting, ACV-
segment match, regulatory/certification gates, and wedge-vs-full-segment conflation. Estimate
how much SAM contracts under realistic behavioral filters.

### SOM Achievability Assessment
Compute implied share from the revenue plan ÷ SAM. Compare to comparable-company capture at
similar stage. Check beachhead-and-expansion logic, competitive-displacement realism, and
sales-capacity feasibility. Identify the most constraining bottleneck (capacity, share,
expansion path).

### Market Timing Assessment
Distinguish a specific 1-3-year trigger from a persistent decade-long trend. Place the market
on the adoption curve and check whether the product's pricing/sales motion matches that
phase. Address "too early" and "too late" failure modes. Assess whether the timing rests on
a single catalyst that could reverse.

### Comparable Benchmarks Assessment
Audit the comp-set selection logic — what was included, excluded, and why. Check stage-
matching, segment-matching, and conditioning bias. State whether the implied trajectory
exceeds the comp-set median, and what structural advantage justifies the gap. Surface
negative comps the plan does not name.

### Factual Foundation
If a fact-check report was provided, briefly summarize the findings that bear on market
sizing — especially Unverified or Inaccurate findings about quoted TAM/SAM figures, market-
growth rates, research firm reports, or comparable-company figures. If no fact-check report
was provided, identify the 2-3 numerical claims in the plan that would most benefit from
fact-checking.

### Overall Assessment
Of the five lenses, which surfaces the strongest market-sizing signal and which the weakest?
End with the single most important revision the author should make to the market story. End
constructively — the goal is a more defensible plan, not a takedown.

## Output Location

When run standalone (not via the draft-review orchestrator), save your critique as
`docs/reviews/business-plan-critique-market-sizing.md` in the project root. Create
`docs/reviews/` if it doesn't exist.

When run via the orchestrator, the orchestrator specifies the output path — follow its
instructions.

## Goal-Alignment Note

When dispatched by an orchestrator, append a Goal-Alignment Note at the end of your critique
using the canonical form from
[`patterns/orchestrated-review.md`](../../patterns/orchestrated-review.md):

```markdown
## Goal-Alignment Note
- Answered: [yes / partial / no — one phrase]
- Out of scope: [what was set aside and why, or "none"]
- Escalate: [what the orchestrator should action separately, or "nothing"]
- Questions I would have asked: [1-3 short questions, only if scope was unclear; otherwise omit this bullet]
```

Use the **Out of scope** line specifically to flag moat/distribution or unit-economics
weaknesses you noticed but did not critique (those belong to sibling skills), or general
argument-structure weaknesses better handled by `cowen-critique`. The **Escalate** line is
the right place to surface a finding that crosses into another critic's territory — for
example, a SOM argument that depends on a distribution claim the moat critic should
re-examine, or a comp-set figure that depends on a fact-check claim the orchestrator should
re-examine.

## Tone

Direct but constructive. The spirit is "let's see whether the market story actually holds"
rather than "let me show you why the market isn't there." Founders pitching plans have
already heard generic skepticism on TAM; what they need is structural diagnosis they can act
on. Be specific about which input is doing the load-bearing work in the market story —
which definitional choice, which behavioral filter, which comp — not just what looks
optimistic.

Comfort with uncertainty matters. Many market-sizing questions don't have a clean answer at
early-stage — "the bottom-up build is consistent with the top-down TAM within a 2× factor,
which is acceptable at this stage; the load-bearing assumption is the 30% behavioral
conversion rate, which has not been validated" is a more useful critique than either "TAM
is wrong" or "market looks fine." Calibrate confidence explicitly, and when the plan's
number could be right but the supporting evidence is thin, say that exactly.
