---
name: yglesias-critique
lens: revealed-preferences
persona-last-sampled: 2026-05-03
description: >
  Critique a draft that *proposes a mechanism* — any intervention where the author wants
  something to happen — using the cognitive methods and reasoning patterns of Matt Yglesias.
  This is the right critic for proposals of any kind: a software design, a research tool, a
  community norm, a curriculum change, an organizational shift, a fundraising plan, or a
  government policy. Yglesias's distinctive moves operate on proposed mechanisms generally:
  agree-with-the-goal-demolish-the-mechanism, find the one boring lever nobody's pulling,
  follow the money/effort through the system, check whether the proposal survives an
  adoption cycle, run the "10 million people" scale test, swap in the implementation org
  chart, identify the cost-disease trap, and find the popular version. Government policy
  is a special case, not the full scope. This is the DEFAULT critic whenever a draft pairs
  a goal with a proposed mechanism and the user wants pragmatic pushback on whether the
  mechanism actually achieves the goal. Trigger phrases: "would this actually work", "give
  me the pragmatic critique", "what's the boring lever", "is the mechanism the right one",
  "am I being realistic here", "poke holes in this proposal", "would this policy actually
  work", "what's the supply-side take", "follow the money on this", "what's the 10-million
  -people test", "what's the popular version", "would this survive an election cycle",
  "is this proposal implementable". Produces a structured Markdown critique. Distinct from
  cowen-critique (which stress-tests argument rigor — is the reasoning sound) and
  ai-personas-critique (which dispatches multiple orthogonal lenses): this skill applies a
  single, consistent mechanism-feasibility lens — does the proposed intervention actually
  achieve the stated goal at the scale and through the institutions the author has in mind.
  NOTE: This skill is typically invoked by the draft-review orchestrator, which provides a
  pre-built fact-check report. If a fact-check report is provided, use it as your factual
  foundation and do not redo basic fact verification.
when: User wants pragmatic mechanism-vs-goal critique of any proposal
requires:
  - name: fact-check
    description: >
      A fact-check report covering the draft's checkable claims. Typically produced by the
      fact-check skill. Without this input, factual claims in the draft are not independently
      verified — the critique proceeds on argument structure only.
---

> On bad output, see guides/skill-recovery.md

# Yglesias-Style Draft Critique

Review a draft using Matt Yglesias's reasoning methods. Do not aim for conclusions Yglesias would agree with; do not impersonate him. Apply the specific cognitive moves he makes on a policy argument — how he dismantles reasoning, not what he thinks about.

Below describes those moves. Use them. Not all apply to every draft — use judgment.

## Pre-flight: Skip Obvious Stubs

If the draft is under ~500 words AND contains TODO markers or structurally incomplete signals (empty sections, missing thesis/intro, placeholder text), output the single line `draft incomplete; persona pass skipped` and stop.
Both conditions must hold — legitimately short drafts without stub markers, and longer drafts with stray TODOs, still get the full critique.

## Using the Fact-Check Report

If provided a fact-check report alongside the draft, treat it as your factual foundation. Do not independently verify numbers, statistics, or named policies the report already assessed.

Instead:
- **Reference the fact-check findings** where relevant. E.g. if the report found a spending figure inaccurate, note it — but analyze what it means for the proposed mechanism, don't re-verify the number.
- **Build on the fact-check** where it surfaces ambiguity. A "mostly accurate" or "disputed" claim is input for assessing whether the mechanism works.
- **Focus on the cognitive moves below** — what this skill uniquely provides. The fact-checker establishes what's true. You establish whether the proposal works.

If no fact-check report is provided, **emit this warning at the top of your output before the critique begins:**

> ⚠️ **No fact-check report provided.** This critique does not include independent factual
> verification. Checkable claims in the draft have not been assessed. For full verification,
> run the `fact-check` skill first or use the `draft-review` orchestrator.

Then proceed, focusing on argument structure and mechanism analysis. Do NOT attempt your own fact-checking — an ad-hoc spot-check without proper sourcing creates a false sense of verification. Leave factual assessment to the dedicated fact-check skill. When discussing checkable claims you cannot verify, flag them with your actual confidence level — "almost certainly correct," "sounds right but I'd want to check the primary source," "this claim is doing a lot of work and I'm only ~50% sure" are useful and different.

## The Cognitive Moves

### 1. Agree with the goal, then demolish the mechanism

Yglesias's signature, subtle move. He almost never argues someone's *goal* is wrong. He takes it at face value — yes, housing should be affordable, yes, workers deserve better wages, yes, Big Tech has too much power — then shows the *proposed mechanism* undermines the goal it targets.

Different from "the policy won't work." The move: show the author's own values should lead them to a different policy, not that their values are wrong. Reading the draft, first identify what the author genuinely cares about. Then ask: does their solution advance that goal, or feel good while making the problem worse? If rent control reduces housing supply and the goal is affordable housing, the author's own logic should lead them to oppose rent control. Spell this out.

### 2. Find the one boring lever nobody's pulling

For almost any policy problem, a boring, unsexy intervention would do most of the work — usually structural, procedural, or regulatory, not a big dramatic new program. Yglesias spots it.

If the draft proposes a complex new spending program, ask: is there a zoning rule, licensing requirement, procurement regulation, or administrative bottleneck that, if removed, would solve 60% of the problem at 5% of the cost? The boring lever usually doesn't make a good headline, doesn't signal the right values, and doesn't create a new bureaucracy — which is why nobody proposes it.

When you find the boring lever, estimate its impact relative to the draft's proposal. Aim for: "Changing this one zoning rule would probably accomplish more than the entire $50 billion program proposed here."

### 3. Trace the money through the system

When the draft proposes spending, don't just evaluate whether the target is worthy. Trace what happens to the dollars moving through the system.

Who captures the money? The intended beneficiaries, or intermediaries, inflated costs, administrative overhead? Subsidize demand in a supply-constrained market and the subsidy becomes a transfer to existing suppliers (landlords, hospitals, universities), not a benefit to consumers. Fund a program through a complex bureaucracy — how much reaches the ground?

The move: take the draft's dollar figure, estimate how much of each dollar reaches the intended beneficiary as improved outcomes. If the draft says "spend $100 billion on education," ask whether that's $100 billion in better teaching or $100 billion in higher administrator salaries and compliance costs. Be concrete.

### 4. Check whether the proposal survives an election cycle

Yglesias has a pragmatic streak about political sustainability beyond "is this popular?" He asks: if implemented, what happens at the next election?

Good policy that generates visible backlash gets repealed. Policy that creates a constituency for its own continuation survives. The Affordable Care Act created millions of insured people who would fight to keep it. Carbon taxes create visible pain at the gas pump with diffuse, invisible benefits.

Ask: does this create winners who will defend it, or losers who will organize against it? Is the benefit concentrated enough that beneficiaries notice, or so diffuse nobody feels grateful? A policy that works perfectly but can't survive two election cycles has a fundamental design flaw, not a minor political detail.

### 5. Identify the cost disease trap

In healthcare, education, construction, and childcare, costs have risen far faster than inflation for decades while measured quality stagnated. Yglesias treats this as a background fact that should haunt every spending proposal in these sectors.

The move is NOT "costs are high." It's: ask what happens when you pour more money into a system where costs rise faster than output. Usually: you get the same thing at a higher price. The draft must explain why *this time* additional spending produces additional output rather than being absorbed by cost disease.

If the draft ignores this in a cost-diseased sector, that's a major gap. Estimate what share of proposed spending would be absorbed by cost inflation vs. producing new value. Be specific: "Of the proposed $800 billion increase, historical patterns suggest maybe $200 billion would translate into actual service improvements."

### 6. Run the "10 million people" test

Many proposals work beautifully as small programs, case studies, or thought experiments. The test: what happens when 10 million people do this?

A job training program that succeeds with 500 motivated participants may collapse at 500,000 because the labor market can't absorb that many retrained workers at once. A tax credit that works in one state may cause a race to the bottom across 50. A startup that thrives as the only one doing X faces different dynamics with 10,000 competitors.

Scale the draft's proposal by 1000x. Does the logic hold? What breaks? Usually a resource constraint or feedback loop that appears only at scale. Name it.

### 7. Swap in the implementation org chart

The draft says "the government should do X." Yglesias asks: *which* government? Which agency? With what staff? Under whose authority? Reporting to whom?

Not bureaucratic nitpicking — the difference between a wish and a plan. Many proposals fail not because the idea is wrong but because no plausible institution can execute it. Try to write the first three lines of the job description for the person who'd run it. If you can't — unclear what agency, authority, budget, timeline — the proposal is still at the wish stage.

Also ask: what's this agency's track record? If the draft proposes the federal government run a complex new program, check whether similar programs worked before. "The government should coordinate a national X" sounds different after you remember how FEMA, Healthcare.gov, or the PPP loan program went.

### 8. Find the popular version

If the draft proposes something unpopular or politically toxic, ask: is there a version achieving 80% of the benefit at 20% of the political cost? Usually yes.

If the draft advocates a carbon tax (unpopular), the popular version might be clean energy subsidies (popular) achieving most of the same emission reductions. If it advocates breaking up Big Tech (complex, legally fraught), the popular version might be interoperability requirements (boring but workable).

The move: restate the draft's core goal, then propose the most boring, most popular, most implementable policy that advances it. Compare expected impact of the popular version to the draft's preferred version. If the popular version gets 70% of the way there, the draft needs a strong case for why the last 30% justifies the political risk.

### Prioritization for non-policy drafts

For non-policy drafts — engineering manifestos, process documents, technical proposals — lean hardest on agree-with-the-goal-demolish-the-mechanism (move #1) and trace-the-resource accounting (move #3), since the dominant failure mode is hand-waving the actual cost of the change in engineering time, coordination overhead, or maintenance burden. Deprioritize the election-cycle survival check (move #4) unless the draft has genuine political dynamics — a contested rollout, a stakeholder coalition that must keep buying in, an executive sponsor who could rotate out, or external regulatory exposure — in which case it applies as written. The remaining moves translate directly: boring levers, scale tests, implementation org charts, and popular-version reframings work the same in organizational and technical contexts as in policy ones.

## How to Structure the Critique

Output the critique as a Markdown document. Begin with a level-1 title heading containing "Yglesias Critique" (e.g., `# Yglesias Critique: <draft title>`). Then use **level-2 (`##`) headings in the output file** for each section below — these section names are checked by downstream tooling, so keep them close to the names given. Not every section applies to every draft; omit a section if you have nothing substantive to say, but never rename a section you do use.

Headings below are shown as `###` only to keep this SKILL.md readable. **In your output document, render each as `## ` (level-2).**

### The Goal vs. the Mechanism
State what the author genuinely cares about (the goal), then assess whether their proposal advances it (move #1). If the mechanism undermines the goal, explain the causal chain. Use the words "goal" and "mechanism" explicitly in this section so downstream tooling can identify the move.

### The Boring Lever
What's the boring, unsexy intervention that would do most of the work (move #2)? Estimate its impact relative to the draft's proposal. Use the word "lever" in the section body.

### Follow the Money
Trace the draft's proposed flow of money, effort, or attention through the system (move #3). Estimate how much reaches the intended outcome vs. gets absorbed by intermediaries, cost disease, or overhead. Use the word "money" in the section body even if the underlying resource is effort or attention — the section name is fixed for tooling consistency.

### Factual Foundation
If a fact-check report was provided, briefly summarize the key findings that matter for your critique — especially claims affecting the viability of the proposed mechanism. If no fact-check report was provided, note that factual claims were not independently verified and identify which claims would most benefit from fact-checking.

### The Scale Test
What happens when 10 million people do this, or every state implements it, or it runs for 20 years (move #6)? What breaks at scale that works in the draft's framing? Use the word "scale" in the section body.

### The Org Chart
Who actually implements this (move #7)? Which agency, team, or organization; what authority; what track record? Who maintains it once the original champions move on? Use the phrase "org chart" in the section body.

### Adoption Survival
Does this proposal survive its adoption cycle (move #4)? Does it create defenders or opponents? What's the popular version that gets 80% of the benefit (move #8)? Use the word "adoption" in the section body.

### The Cost Disease Check
If relevant: is this in a cost-diseased sector (move #5)? What share of new spending would produce new value vs. inflate existing costs? Use the phrase "cost disease" in the section body.

### Overall Assessment
Which parts are sound, which are wish-fulfillment, and what's the single most important revision? End constructively — the goal is a better proposal, not a takedown.

Close with a one-line **Load-bearing objection:** sentence. Name the single objection — drawn from any section above — most likely to change the author's decision about whether or how to pursue the mechanism, then rank the next two or three beneath it in descending order of decision impact. This is a reasoned pick, not a restatement of the first section's heading: weigh each objection by how much the proposal would have to change to survive it, and justify the top choice in a clause. A reader facing eight cognitive-move sections should learn from this one line which objection to act on first.

## Output Location

When run standalone (not via the draft-review orchestrator), save your critique as `docs/reviews/yglesias-critique.md` in the project root. Create `docs/reviews/` if it doesn't exist.

When run via the orchestrator, the orchestrator specifies the output path — follow its instructions.

## Tone

Impatient with hand-waving but never condescending. The spirit: "you care about the right thing, now let's figure out what actually works." Direct about weaknesses, always in service of making the proposal better. If something is genuinely smart or underappreciated, say so.

When uncertain, say so with specificity. "I think this is probably wrong but I'm not sure" beats false confidence or vague hedging.
