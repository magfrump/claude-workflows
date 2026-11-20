# AI Personas Critique

> **No fact-check report provided.** Checkable claims have not been independently verified.
> For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

**User goal:** stress-test this proposal from several independent angles before it goes to the people who will decide on it.
**Proposal:** Support Team Compensation Redesign, H1 2027. Replace merit-based differentiation with quarterly bonuses ranked on tickets resolved per scheduled shift hour, and put bottom-decile agents on a PIP.
**Domains:** organizational (primary), economics (secondary), governance (secondary, because it changes who controls pay outcomes)
**Personas selected:**
- **Incentive Analyst (6):** The proposal is an incentive design, so this is the core lens. It runs here because no Cowen critique is in parallel. It covers internal logic.
- **Empiricist (1):** The proposal rests on a causal diagnosis and a numeric forecast (+20%, backlog cleared in six weeks, under 20 hours). It covers evidence and internal logic.
- **Systems Thinker (3):** It examines how the metric interacts with customers, renewals and teamwork over time. It covers future and external effects.
- **Power Analyst (10):** It asks who now controls agents' pay through ticket routing, status changes and PIP triggers. It covers values, external effects and the critic side.

Dimension coverage: evidence and values are both covered. Internal and external are both covered. Future is covered, but present feasibility is not. Critic is covered, but builder only partially. The selection spans all four dimensions, so no wild-card swap was triggered. Builder and present-feasibility gaps are addressed under Blind Spots.

**Personas in parallel:** none

---

## Persona Critiques

### The Incentive Analyst: What do the incentives actually reward?

User goal: stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Incentive Analyst lens (what do the incentives actually reward?) to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The metric rewards *setting a status*, not solving a problem. The proposal says a ticket "counts as resolved when the agent sets its status to Resolved." The person being paid controls the measurement. Premature closure is the obvious response: the customer replies, the ticket reopens or a new one is filed, and both count again.

Counting escalation tickets "the same" also backfires against its own stated intent. A three-hour escalation and a five-minute password reset carry equal credit, so the escalation queue becomes a bonus penalty. Agents who take hard work will rank lower.

Quartile ranking is zero-sum. Time spent helping a colleague, mentoring a new hire, or writing a knowledge-base article directly lowers your rank and raises nobody's. CSAT and quality are collected but "will not affect pay," which tells agents they are optional.

**Severity:** Fatal flaw as designed. Each loophole is cheap to exploit and directly undermines the stated goal.
**Test/mitigation:** Count a ticket only after N days without a reopen or a related follow-up. Weight tickets by queue or complexity, or rank escalation agents separately. Add a quality and CSAT floor as a bonus *gate* rather than a score component. Before launch, red-team the metric with three or four agents.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: whether bonus amounts are large enough to motivate, set aside as secondary to gaming risk
- Escalate: the self-reported "Resolved" definition needs a fix before any approval
- Decisions I made: Treated "fatal" as applying to the metric definition, not to performance pay as a concept.

### The Empiricist: What evidence actually supports this claim?

User goal: stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Empiricist lens (what evidence actually supports this claim?) to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The diagnosis assumes slow resolution reflects effort, which the bonus would then fix. The background points elsewhere. Headcount grew from 30 to 85 in two years, so most agents are recent hires. Ramp-up time, ticket mix, product complexity and routing are all plausible causes, and none is examined.

The forecast extrapolates from the "spread between our fastest and median agents." That spread may reflect easier queues or tenure rather than copyable habits. Throughput and time-to-resolution are also different quantities. Clearing easy tickets faster can raise throughput while hard tickets age, leaving median time to resolution flat or worse.

The noise argument cuts both ways. The proposal rejects CSAT because of a 9% response rate, but never tests whether quarterly resolution rate is stable. Rank on a noisy weekly mix and the quartiles may reshuffle randomly.

The cost arithmetic checks out (21×$1,500 + 21×$600 ≈ $44,100 per quarter). The benefit side is unquantified.

**Severity:** Significant weakness.
**Test/mitigation:** First, decompose the 19→31 hour drift by tenure, queue and ticket type. Measure the quarter-over-quarter rank correlation of the metric on historical data. Pilot with one team against a control group.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: verifying the cited figures (no fact-check available)
- Escalate: the proposal should include a root-cause analysis of the resolution-time drift before deciders accept the diagnosis
- Decisions I made: Took the stated figures (85 agents, 9% response rate, 11 exits) at face value.

### The Systems Thinker: What feedback loops and emergent effects does this create?

User goal: stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Systems Thinker lens (what feedback loops and emergent effects does this create?) to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

Several reinforcing loops could make the presenting problem worse:

- **Reopen spiral.** Premature closures produce repeat contacts, which inflate volume and backlog. That raises pressure to close fast, which produces more premature closures. The leaderboard would show rising "productivity" while customers experience worse service.
- **Hard-ticket aging.** Easy tickets get cherry-picked, so complex enterprise issues sit longer. Those are the issues behind the delayed renewals the proposal cites.
- **Retention.** Exits were driven by "no way to get ahead." Now 75% of agents get no bonus each quarter and a public leaderboard ranks them, so demoralization may rise. Exits would lower average tenure and slow the team further.
- **Knowledge decay.** With mentoring penalized, new hires ramp slower.

The July decision to extend to Tier 2 compounds the risk. It rests on one bonus cycle, which is too early to see lagging effects such as churn signals and attrition.

**Severity:** Significant weakness. It could become fatal if the reopen loop takes hold.
**Test/mitigation:** Track reopen rate, repeat-contact rate, age of the oldest 10% of tickets, enterprise CSAT and attrition as guardrails, with predefined kill criteria. Defer the Tier 2 decision to at least two full quarters of guardrail data.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: effects on other teams (Engineering, Account Management) that receive escalations
- Escalate: rollout plan lacks kill criteria; July Tier 2 decision is premature
- Decisions I made: Assumed tickets are at least partly self-selected from a shared queue; if strictly assigned, cherry-picking shifts to routers (see Power Analyst).

### The Power Analyst: Who gains power, and who loses it?

User goal: stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Power Analyst lens (who gains power, and who loses it?) to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The proposal claims to remove subjectivity, but it mostly moves it. Whoever assigns tickets, schedules shifts and decides who staffs escalations now indirectly sets each agent's bonus. That discretion is now invisible because "the number is objective." Leads lose the formal merit lever and keep a hidden one.

Agents lose voice. The metric is fixed by management, and there is no stated appeal path for misattributed tickets, outages or bad queue assignments.

The bottom-decile PIP rule is structurally guaranteed to target roughly eight or nine people every quarter, regardless of absolute performance. Escalation specialists, trainees (the proposal says normalization protects trainees, but training inside scheduled hours *lowers* resolved-per-hour), and agents handling difficult accounts will be overrepresented.

The leaderboard is public, which turns pay rank into social status and exposure.

**Severity:** Significant weakness.
**Test/mitigation:** Use absolute performance thresholds rather than forced quantiles for PIP triggers. Exclude training and non-ticket duties from the denominator. Publish routing rules and audit assignment fairness. Create a dispute process. Consider showing individuals their own position rather than a public ranking.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: employment-law implications of forced-ranking PIPs (better suited to a Regulatory Mind)
- Escalate: People team should review whether forced-quantile PIPs create legal or discrimination exposure
- Decisions I made: Read "scheduled shift hour" as including training time, since the proposal doesn't say training is excluded.

---

## Synthesis

**Goal-alignment scan:** All four personas answered `yes`.

Escalations:
- Fix the self-reported "Resolved" definition (Incentive Analyst).
- Do a root-cause analysis of the drift (Empiricist).
- Add kill criteria and defer the Tier 2 decision (Systems Thinker).
- Have the People team do a legal review of forced-quantile PIPs (Power Analyst).

Out-of-scope items are folded into Blind Spots below. No clarifying questions were raised.

### Convergent Findings
1. **The metric punishes hard work.** Three personas flagged this independently. Equal credit for escalations and self-selection of easy tickets is a perverse incentive (Incentive Analyst). It decouples throughput from time to resolution (Empiricist). It leaves the enterprise issues behind the delayed renewals to age (Systems Thinker). The proposal's own claim that equal counting prevents avoiding hard work is backwards.
2. **Self-reported closure invites gaming.** The Incentive Analyst and Systems Thinker both flagged this, and the reopen spiral could make backlog worse while the leaderboard looks better.
3. **The problem of subjectivity is moved, not solved.** The Power Analyst found discretion shifting into routing. The Empiricist found the "objective" number may itself be noisy. The rejection of the balanced scorecard on noise and legibility grounds applies just as much to the chosen metric.
4. **Forced ranking may worsen the retention problem it targets.** The Systems Thinker and Power Analyst both flagged this. 75% get nothing, about 10% are always at PIP risk, and rankings are public.

### Tensions
- **Legibility vs. gaming resistance.** Agents asked to know exactly what they're measured on. A single transparent number is the easiest to game, while every fix (reopen windows, complexity weights, quality gates) adds complexity. The real decision is how much legibility to trade for robustness, not single number vs. scorecard.
- **Administrative savings vs. oversight.** The proposal sells automation as removing about four lead-hours per agent per year (roughly 340 hours). The Power and Systems critiques imply that audits, disputes and guardrail monitoring are needed, which consumes some of that saving.
- **Differentiation vs. cohesion.** The Incentive Analyst and Power Analyst note that real differentiation for high performers is a legitimate goal. Zero-sum ranking is just one way to get it. Absolute thresholds could provide differentiation without the competition.

### Ranked Concerns
| # | Concern | Raised by | Severity | Convergence |
|---|---------|-----------|----------|-------------|
| 1 | Equal ticket weighting penalizes escalations and hard tickets, undercutting time to resolution and enterprise renewals | Incentive, Empiricist, Systems | Fatal / Significant | 3 |
| 2 | Agent-set "Resolved" status enables premature closure and a reopen spiral | Incentive, Systems | Fatal / Significant | 2 |
| 3 | Forced quartiles and decile PIPs with a public leaderboard may increase attrition | Systems, Power | Significant | 2 |
| 4 | Subjectivity moves into routing and assignment, with no dispute process | Power, Empiricist | Significant | 2 |
| 5 | Causal diagnosis untested; drift may come from tenure, mix or routing; 20% forecast unsupported | Empiricist | Significant | 1 |
| 6 | Training time inside the denominator contradicts the stated normalization | Power | Significant | 1 |
| 7 | No guardrail metrics or kill criteria; Tier 2 extension decided after one cycle | Systems | Significant | 1 |

**Bottom line for deciders:** Differentiated pay for support agents is a reasonable goal. This specific metric, as defined, is likely to make customer-perceived responsiveness worse. The minimum changes before approval:
- Count only tickets that stay closed past a reopen window.
- Weight tickets by complexity or rank queues separately.
- Gate bonuses on quality and CSAT floors.
- Use absolute thresholds for PIPs.
- Exclude training time from the denominator.
- Run a one-team pilot with guardrails and kill criteria.

### Blind Spots
- **Present feasibility / builder (Implementation Engineer, Regulatory Mind).** No persona checked whether the helpdesk can reliably attribute tickets with multiple handlers, detect reopens and related follow-ups, or exclude training hours. December announcement to January launch is a tight window for that tooling. A Regulatory Mind would ask about:
  - wage-and-hour treatment of bonuses for non-exempt agents (in the US, nondiscretionary bonuses can affect overtime calculations)
  - jurisdictions with works-council or consultation requirements
  - disparate-impact exposure from forced-ranking PIPs, which was flagged as out of scope by the Power Analyst
- **The customer as user (End User Advocate).** No persona modeled the customer's experience of a closed-then-reopened ticket or of rushed answers. That is the experience enterprise accounts raised in reviews.
- **Opportunity cost.** The proposal compares $176K to "two additional agents" but not to alternatives such as better self-service or a knowledge base, routing fixes, onboarding investment, or a retention raise for tenured agents. Those could address the diagnosed causes more directly.
- **Cross-team effects (from Systems Thinker out-of-scope).** Engineering and account teams receiving escalations may see more poorly triaged handoffs if agents pass hard tickets along to protect their rate.
