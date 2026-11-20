> **No fact-check report provided.** Checkable claims have not been independently verified.
> For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# AI Personas Critique

**User goal:** Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
**Proposal:** Support Team Compensation Redesign, H1 2027. Pellucid would replace merit increases with quarterly bonuses based on a single leaderboard metric, tickets resolved per scheduled shift hour, and a bottom-decile PIP trigger.
**Domains:** organizational (primary), economics, policy (internal HR policy). The central decision is to tie pay to one self-reported throughput number and deliberately exclude quality and satisfaction from pay.
**Personas selected:**
- **Incentive Analyst (6):** The proposal is an incentive design, so Goodhart risk is the central question. This persona does not map to a listed dimension pole. It was kept because no lens fits the proposal better.
- **Implementation Engineer (11):** Checks whether the metric can be computed correctly on the stated timeline. Covers evidence, present and builder.
- **Systems Thinker (3):** Traces how the metric interacts with the queue, the customers and attrition over time. Covers future and external.
- **Power Analyst (10):** Examines who controls the metric, the routing and the PIP trigger once lead discretion is removed. Covers values, external and critic.
- **Coverage:** Three of four dimensions are fully spanned. Internal-logic review is not covered (see Blind Spots). The wild-card swap is not triggered.

**Personas in parallel:** none

---

## Persona Critiques

### Incentive Analyst: What do the incentives actually reward?

User goal: Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Incentive Analyst lens — what do the incentives actually reward? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The plan pays for the act of setting a status to Resolved, and the agent being paid is the one who sets it. It explicitly removes CSAT and quality audits from pay. The incentive is to close tickets, not to solve problems.

The escalation rule backfires. A hard escalation ticket can take several times longer than a password reset but earns the same single unit of credit. "Counting the same" therefore guarantees that agents avoid hard work.

The tournament structure adds more pressure in the wrong direction:
- Bonuses and PIPs are relative, so helping a colleague costs you rank.
- Time spent mentoring or writing knowledge-base articles lowers your rate.
- The denominator is *scheduled* hours, so resolving tickets off the clock raises your number. That rewards unpaid overtime, which is also a wage-and-hour exposure.

Expect cherry-picking, early closures, ticket splitting, nudging customers to close, and escalation queue avoidance.

**Severity:** Fatal flaw
**Test/mitigation:** Credit a resolution only after it has stayed closed (no reopen and no same-issue ticket) for 7–14 days. Weight tickets by complexity tier or queue. Require a floor on quality audits and reopen rate before any bonus is paid. Count only activity logged inside scheduled hours.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: legal analysis of off-clock work incentive (regulatory lens not selected)
- Escalate: wage-and-hour risk from scheduled-hours denominator — needs People/legal review
- Decisions I made: Treated "counts the same" as one ticket = one unit regardless of effort, which is the plain reading of the text.

### Implementation Engineer: What's the actual build plan, and where does it break?

User goal: Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Implementation Engineer lens — what's the actual build plan, and where does it break? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The normalization claim is wrong as written. Dividing by *scheduled* hours means time spent in training sits in the denominator and produces no resolutions. That penalizes trainees, which is exactly what the proposal says it avoids. Fixing this requires productive hours, which means integrating the helpdesk with the scheduling or workforce-management system. The proposal never mentions that integration.

Attribution is also undefined:
- Who gets credit for a ticket that was transferred, collaborated on, or escalated and handed back?
- How are ties at quartile boundaries handled?
- How are mid-quarter hires and leave handled?

Each of these will become a pay dispute.

The schedule leaves no slack. The metric must be defined, built, validated and published by a December all-hands, across the holidays. No back-test exists to show what the leaderboard would have looked like last quarter.

**Severity:** Significant weakness
**Test/mitigation:** Back-test the metric on the past two quarters' data. Check whether rank correlates with queue or ticket mix more than with the agent. Run Q1 in shadow mode, with the leaderboard visible and no pay attached. Publish attribution rules and an appeals process before money moves.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: specific helpdesk vendor capabilities (unknown from proposal)
- Escalate: training-time normalization error is a factual correction the author should fix before review
- Decisions I made: Read "scheduled shift hour" literally as including scheduled training time.

### Systems Thinker: What feedback loops and emergent effects does this create?

User goal: Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Systems Thinker lens — what feedback loops and emergent effects does this create? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The plan creates a reinforcing loop that looks good from the inside. Premature closures generate reopens or new tickets from the same customer. That raises volume, which raises everyone's "resolved" count. The leaderboard improves while the customer experience gets worse.

The real problem is enterprise responsiveness on difficult issues, the kind that delayed two renewals. Hard tickets are the ones agents will now avoid, so they will age in the escalation queue. The metric could look better at the same moment the renewal risk grows.

A second loop runs through attrition. Bottom-decile PIPs plus tournament pressure drive exits. New hires ramp slowly, and lost capacity lengthens queues. The plan responds to eleven departures with a mechanism likely to cause more.

The diagnosis also deserves scrutiny. Time to resolution rising from 19 to 31 hours during headcount growth may reflect queue design, routing or product complexity, not agent speed.

The July decision to extend the model to Tier 2 locks the approach in before these loops have had time to show up.

**Severity:** Significant weakness
**Test/mitigation:** Pre-register guardrail metrics before launch: reopen rate, tickets per customer, escalation-queue age, enterprise time to resolution and attrition. Pair them with kill criteria. Defer the Tier 2 decision until two full quarters of guardrail data exist.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: root-cause analysis of the TTR increase (no data in proposal)
- Escalate: proposal lacks any guardrail or rollback criteria — decision-makers should require them
- Decisions I made: Assumed enterprise complaints concentrate on complex tickets, which is plausible but not stated.

### Power Analyst: Who gains power, and who loses it?

User goal: Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Power Analyst lens — who gains power, and who loses it? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The proposal frames itself as removing subjectivity. It actually relocates subjectivity somewhere less visible. Ticket mix drives the rate, so whoever controls routing, queue assignment and the definition of "resolved" now effectively sets pay. Favoritism moves out of merit reviews, where it can be seen, and into ticket assignment, where it is hard to detect.

Leads lose their main lever. They still receive CSAT and quality data, but that data "will not affect pay," so their coaching carries no weight. The PIP trigger is automatic, which removes their ability to protect an agent stuck on a brutal queue.

Agents gain clarity but lose voice. No appeal path is described, no process exists for changing the metric, and the bottom decile is publicly visible on a leaderboard. The spring survey asked for *clarity about measurement*. It did not ask for a single public ranking.

**Severity:** Significant weakness
**Test/mitigation:** Publish and audit routing rules. Make the PIP a lead-reviewed flag rather than an automatic trigger. Create a metric-change process that includes agent representation. Consider showing individual standings privately rather than on a public leaderboard.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: employment-law constraints on PIPs or public ranking by jurisdiction
- Escalate: no appeals or governance process for a pay-determining metric
- Decisions I made: Assumed routing is at least partly lead- or rule-controlled rather than pure agent self-selection. If agents self-select, cherry-picking replaces favoritism, and both are covered above.

---

## Synthesis

**Goal-alignment scan:** All four personas answered `yes`.
- **Out of scope:** legal and regulatory questions (raised by two personas), helpdesk vendor specifics, and root-cause data for the TTR increase. These are folded into Blind Spots.
- **Escalate:** the wage-and-hour risk, the training normalization error, the missing guardrails and rollback criteria, and the missing appeals and governance process.
- **Questions to clarify:** none raised.

### Convergent Findings
- **The metric rewards closing, not solving, and penalizes hard work.** All four personas reached this independently. The Incentive Analyst sees gaming. The Implementation Engineer sees a self-set status with undefined attribution. The Systems Thinker sees reopen loops and aging escalations. The Power Analyst sees routing control determining pay. The "escalations count the same" rule produces the opposite of its stated intent.
- **Ticket mix confounds individual performance.** Three personas raised this (Incentive, Implementation, Power). Rank may measure what queue an agent sits in more than how good the agent is. This also undermines the "adopt the habits of top performers" projection.
- **No safety rails.** Three personas raised this (Implementation, Systems, Power). The plan has no shadow period, guardrail metrics, kill criteria or appeals, and it attaches real money and PIPs from day one.

### Tensions
- **Legibility vs. gaming resistance.** The proposal chose a single number because agents want to know what they are measured on. Every mitigation above adds complexity, such as complexity weighting, reopen windows and quality floors. The real tradeoff is how much legibility to sacrifice for a metric that can't be gamed. A middle path is one primary number with a small set of published gates.
- **Removing subjectivity vs. preserving judgment.** The Power Analyst wants lead review restored for PIPs. That reintroduces the subjectivity the proposal set out to eliminate. The defensible position is discretion limited to protecting agents, not to rewarding them.
- **Speed of relief vs. validation.** Enterprise renewals are at risk now. A Q1 shadow mode delays the incentive by a quarter. If the metric is miscalibrated, though, paying on it could worsen the renewal problem it is meant to fix.

### Ranked Concerns
| # | Concern | Raised by | Severity | Convergence |
|---|---------|-----------|----------|-------------|
| 1 | Self-set "Resolved" status plus equal credit per ticket rewards early closure and escalation avoidance | Incentive, Implementation, Systems, Power | Fatal flaw | 4 of 4 |
| 2 | Ticket mix and routing drive rank, so pay reflects queue assignment more than performance | Incentive, Implementation, Power | Significant weakness | 3 of 4 |
| 3 | No shadow period, guardrails, kill criteria or appeals before money and PIPs attach | Implementation, Systems, Power | Significant weakness | 3 of 4 |
| 4 | Tournament pay and automatic PIPs erode collaboration and may increase attrition | Incentive, Systems, Power | Significant weakness | 3 of 4 |
| 5 | Scheduled-hours denominator penalizes training time and rewards unpaid off-clock work | Implementation, Incentive | Significant weakness | 2 of 4 |
| 6 | Tier 2 extension decided in July, before loop effects are observable | Systems | Point to consider | 1 of 4 |

### Blind Spots
- **Internal logic and evidence (Empiricist not selected).** The 20% throughput projection rests on the spread between the fastest and median agents. That assumes the spread reflects habits rather than ticket mix, and no data in the proposal separates the two. The six-week backlog projection depends on that same assumption. The diagnosis that slower agents caused rising TTR is also untested against routing, staffing ratio or product-complexity explanations.
- **Regulatory and legal.** Raised as out of scope by two personas. Open questions include wage-and-hour exposure from off-clock work, documentation standards for automatically triggered PIPs, and pay-transparency or works-council requirements in any non-US jurisdiction.
- **Customer as end user.** An End User Advocate would ask what the customer experiences when a ticket is closed prematurely. It may mean re-explaining the issue to a new agent, which is precisely the enterprise complaint.
- **Cognitive effects.** A Cognitive Scientist would raise the motivational effects of public leaderboards. These include discouragement among people in the middle and lower ranks, and intrinsic motivation being crowded out.
- **Opportunity cost.** The proposal compares $176k only against hiring two agents. It does not compare it against fixing routing, tooling or the knowledge base, any of which might address TTR directly.
