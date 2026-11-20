> **No fact-check report provided.** Checkable claims have not been independently verified.
> For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# AI Personas Critique

**User goal:** stress-test this proposal from several independent angles before it goes to the people who will decide on it.
**Proposal:** Keeping Stallbook Personal as We Go National: keep dispute handling fully human, in-house, with the same three specialists and a two-business-day standard, for 18 months after a launch targeting 50x buyers.
**Domains:** marketplace (primary), organizational, strategy
**Personas selected:**
- **Scaling Skeptic (8):** The proposal pairs a fixed team with a 50x growth target, so it is a scale question first. Covers evidence, present feasibility and builder.
- **Systems Thinker (3):** Backlogs, dispute rates and seller trust interact across buyers and sellers. Covers external and future.
- **Sustainability Auditor (14):** The plan rests on three named people and founder cover for 18 months. Covers values and future.
- **Opportunity Cost Accountant (12):** The proposal compares itself only against automation and outsourcing. Covers internal logic and critic ("should this exist").

**Personas in parallel:** none

---

## Persona Critiques

### Scaling Skeptic: What breaks at 100x the current scale?

User goal: stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Scaling Skeptic lens — What breaks at 100x the current scale? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The memo's own numbers do not reach 100x. They fail before 5x.

- **Today:** 40 disputes/week × 45 min = 30 hours/week across three specialists.
- **At the approved target:** The finance model scales orders with buyers. At a constant dispute rate, 50x means about 2,000 disputes/week. With the dashboard's 5-minute saving, that is 2,000 × 40 min ≈ **1,333 hours/week**.
- **Capacity:** Three specialists at 40 hours, doing nothing but disputes, give 120 hours/week. That covers about **180 disputes/week, or 4.5x today**.

At target, the team falls short by about 11x, which is roughly 33 full-time equivalents. Even a modest 10x outcome needs about 267 hours/week.

Once weekly arrivals pass about 180, the queue grows every week and never shrinks. The two-business-day standard fails at that point, probably within the first months of an 18-month ramp. That is exactly the "first impression" window the memo wants to protect.

"Same three specialists," "same service standard" and the 50x target cannot all hold at once.

**Severity:** Fatal flaw
**Test/mitigation:** Build a weekly capacity model from the finance model's order ramp. Identify the week arrivals exceed 180, and set a hiring or triage trigger well before that week.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: the exact ramp shape (not given in proposal)
- Escalate: the capacity gap should lead the synthesis and the board conversation
- Questions I would have asked: What do specialists do with the ~30 non-dispute hours each currently has per week?
- Decisions I made: Assumed disputes per order stay constant; assumed 40-hour weeks at 100% dispute time (generous to the proposal)

### Systems Thinker: What feedback loops and emergent effects does this create?

User goal: stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Systems Thinker lens — What feedback loops and emergent effects does this create? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The memo treats per-dispute time and dispute rate as fixed. Both are likely to get worse.

**Dispute rate.** National shipping distances plausibly mean more breakage and loss than regional orders.

**Per-dispute time.** The 45 minutes reflects a team that "knows our sellers." Thousands of unfamiliar national sellers remove that advantage.

**Reinforcing loop.** A growing backlog makes buyers chase their disputes and open payment-provider disputes. That adds messages and work to every case. Sellers wait longer with funds and reputation in limbo. The 82% who cite "fair, human dispute handling" then experience slow handling instead.

**Balancing loop that goes wrong.** Overloaded specialists will speed up informally. Decision quality drifts, and appeals rise. The memo implies the same team hears appeals, so its load grows again.

**Planning consequence.** The "wait for real data, then adjust" plan means the data arrives as a degraded brand.

**Severity:** Significant weakness
**Test/mitigation:**
- Track weekly dispute rate per order, median handling time and backlog age from day one.
- Pre-commit to an action when any of them crosses a threshold.
- Model a 1.5x dispute-rate scenario for national orders.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: card-network and payment-processor rules on dispute timing (no fact-check available)
- Escalate: the "wait for data" premise; the data will arrive as backlog
- Decisions I made: Inferred that appeals are handled by the same team, since no other reviewer is mentioned

### Sustainability Auditor: Can this be maintained indefinitely, or does it consume its own foundations?

User goal: stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Sustainability Auditor lens — Can this be maintained indefinitely, or does it consume its own foundations? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The memo calls the three specialists the company's "most valuable asset," then plans to run them past capacity for 18 months with no added budget.

**Burnout.** At even 4x today's volume they work at full utilization with no slack. That is a recipe for burnout, and burnout means departures.

**Bus factor.** Each departure removes a third of capacity. Their institutional knowledge, which the memo says nobody could replace, leaves with them. A replacement would then have to be trained during peak load by people with no spare time.

**Founder cover.** "The founders will cover specialist vacations personally" works at 40 disputes a week. During a national launch, founder time goes to fundraising, partnerships and hiring. Founders stuck in the dispute queue is a hidden cost the memo does not count.

**Values.** Asking a small team to absorb a growth plan the board sized for 50x, while their salaries stay flat, raises a fairness question. Their goodwill is part of what is being spent.

**Severity:** Significant weakness
**Test/mitigation:**
- Set a utilization ceiling of about 70%.
- Name a succession and cross-training plan.
- Start hiring and shadowing before March, so the current team trains successors while it still has time.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: compensation benchmarking
- Escalate: retention risk for the three specialists should be raised with the board explicitly
- Decisions I made: Read "salaries stay at their current level" as flat headcount and flat pay

### Opportunity Cost Accountant: What are we NOT doing by pursuing this?

User goal: stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Opportunity Cost Accountant lens — What are we NOT doing by pursuing this? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The memo frames the choice as "unchanged" versus "automation or outsourcing." That leaves out the most obvious option: **hire more in-house human specialists.** It keeps every principle the memo defends (human decisions, no bots, no outsourcing, Stallbook's tone) except the "same three" constraint, which is never justified on its own terms.

Other options the memo leaves out:
- **Tiered human review.** Juniors handle clear-cut cases using a playbook written by the senior three. A non-delivery claim with tracking evidence is a typical example. Seniors take the judgment-heavy cases.
- **Seller-side tools** that resolve issues before they become disputes, still human-led.
- **Pre-agreed contingency triggers** instead of an 18-month freeze.

The money also looks lopsided. The Series A funds marketing sized for 50x, but trust gets six weeks of one engineer. That buys an 11% time saving against an 11x capacity gap.

"Don't change during launch" is presented as the safe choice. In practice, keeping the inputs unchanged guarantees the service will change.

**Severity:** Significant weakness
**Test/mitigation:** Bring the board two or three costed options: status quo, in-house hiring and tiered review. For each, show projected service levels against the ramp, so the board chooses on that basis rather than endorsing a principle.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: costing each alternative (no salary data in proposal)
- Escalate: the board ask (endorse a principle for 18 months) should become a choice among costed options
- Decisions I made: Treated "fully human and in-house" as the real principle and "same three" as a separable constraint

---

## Synthesis

All four personas answered `yes`, so none of the critiques needs to be discounted. The escalations are folded into the ranked concerns below.

**Questions to clarify:** What does the trust team spend its remaining time on today? (Scaling Skeptic) At about 10 dispute-hours per specialist per week, either there is slack the memo could cite, or the 45-minute figure undercounts real effort.

### Convergent Findings
- **The fixed team cannot carry the approved growth.** All four lenses reach this independently:
  - Scaling Skeptic: the arithmetic shows a ~11x gap at target and failure near 4.5x.
  - Systems Thinker: the per-case inputs will worsen.
  - Sustainability Auditor: the team burns out before reaching even the ceiling.
  - Opportunity Cost Accountant: the budget doesn't match the target.
- **"Human" and "these three humans" are conflated.** The Opportunity Cost Accountant, Sustainability Auditor and Scaling Skeptic all land on the same fix: in-house hiring preserves the brand promise. The memo's defense of human judgment is sound. Its staffing plan is the weak part.
- **"Wait for data" is backwards.** The Systems Thinker and Opportunity Cost Accountant both note that the data will show up as backlog and brand damage, during the first-impression window the memo wants to protect.

### Tensions
- **Hiring versus continuity.** The Opportunity Cost Accountant says hire. The memo, echoed by the Systems Thinker's point that seller familiarity drives the 45-minute figure, says new people lack the knowledge that makes the model work. The fix is to hire early so the three can train successors before load arrives. It cannot be resolved by staying fixed.
- **Judgment on every case versus triage.** The memo treats every dispute as needing senior judgment. Tiered review assumes many cases are routine. Which is true is an empirical question. The current dispute log can answer it before March.
- **Protecting the brand versus protecting the people.** The founders protect the brand by not changing the model. The Sustainability Auditor argues that this spends down the team that *is* the brand.

### Ranked Concerns
| # | Concern | Raised by | Severity | Convergence |
|---|---------|-----------|----------|-------------|
| 1 | Three specialists cap out at about 4.5x volume. The target is 50x, so the two-day standard fails early in the ramp. | Scaling Skeptic, Systems Thinker, Sustainability Auditor, Opportunity Cost Accountant | Fatal flaw | 4 of 4 |
| 2 | In-house hiring and tiered human review are never considered, even though they preserve the stated principles. | Opportunity Cost Accountant, Sustainability Auditor, Scaling Skeptic | Significant weakness | 3 of 4 |
| 3 | Backlog loops (chasing, payment disputes, appeals, rushed decisions) erode the brand before the "real data" arrives. | Systems Thinker, Opportunity Cost Accountant | Significant weakness | 2 of 4 |
| 4 | Bus factor, burnout and founder time pulled into the queue during launch. | Sustainability Auditor | Significant weakness | 1 of 4 |
| 5 | The board is asked to endorse an 18-month principle with no trigger to revisit it. | Opportunity Cost Accountant, Systems Thinker | Significant weakness | 2 of 4 |

### Blind Spots
- **Evidence for the brand claim (Empiricist, not selected).** The 82% figure comes from sellers who stayed, which is survivorship. Sellers who left are not in it. A sub-3% appeal reversal rate measures consistency, not fairness, especially if the same team hears appeals. Nobody has tested whether the brand value is "a human decides" or "outcomes feel fair and fast." The answer determines whether triage would hurt the brand.
- **Adversarial pressure (Security Analyst).** A national, human-only, no-auto-rule process with a growing queue is an attractive target. Fraud rings could file coordinated disputes, or flood the queue to push hasty decisions.
- **Regulatory and payments exposure (Regulatory Mind).** Consumer-protection and card-network dispute timelines may impose deadlines that a backlog misses. These were not checked because no fact-check was available.
- **Governance (Power Analyst).** Endorsing "the current team" for 18 months limits the board's own room to act. It also gives three individuals considerable leverage over a core function.
- **Present-feasibility coverage.** None of the selected personas sits in the catalog's "present" list (5, 11, 9). The Scaling Skeptic's arithmetic covers current feasibility in practice. An End User Advocate would add what a buyer's experience looks like on day 6 of an unanswered dispute.
- **Out-of-scope items carried forward:** the ramp shape, salary data for costing alternatives, and payment-network rules. Each is needed before the board can compare options.
