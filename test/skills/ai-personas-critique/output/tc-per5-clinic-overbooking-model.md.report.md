> **No fact-check report provided.** Checkable claims have not been independently verified.
> For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# AI Personas Critique

**User goal:** Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
**Proposal:** Predictive Scheduling for Primary Care. Brackenridge Community Health proposes to double-book primary care slots that a no-show model scores above 40% risk, starting at three clinics.
**Domains:** healthcare (primary), AI/ML (primary), organizational (secondary). The central design decision is to convert a predicted no-show probability into a double booking, so the patients the model flags carry the cost whenever the prediction is wrong.
**Personas selected:**
- **The Empiricist (1).** The case rests on an AUC comparison and a retrospective simulation. Covers evidence and internal logic.
- **The Ethicist (2).** Insurance category and distance are top model inputs, so the burden is not randomly distributed. Covers values and "should this exist?"
- **The Systems Thinker (3).** The model is retrained on outcomes its own policy shapes. Covers future consequences and external effects.
- **The Implementation Engineer (11).** The operational promise ("no more than one per session, on average") meets the busiest clinics first. Covers present feasibility and "how would this work?"

All four orthogonality dimensions are covered, so no wild card is needed.
**Personas in parallel:** none

---

## Persona Critiques

### The Empiricist: What evidence actually supports this claim?

User goal: Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Empiricist lens — What evidence actually supports this claim? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The 0.81 vs. 0.62 comparison is not like-for-like. Front-desk overbooking is a yes/no decision. A yes/no decision yields one point on an ROC curve, not a ranking, so an "AUC" built from it is a construction. AUC also measures ranking, while the policy depends on calibration at exactly 40%. The simulation numbers need explanation. If 9,200 recovered slots plus 2,100 double arrivals means roughly 11,300 opened slots, then about 81% of flagged appointments were real no-shows. That rate is high for a 40% threshold unless the model is badly miscalibrated or the simulation fills only some opened slots. The simulation also appears to assume every second-booked patient arrives.

Finally, the jump from "9,000 visits" to "new-patient wait drops from 26 to 18 days" is a claim that needs its own support. The extra slots are filled from same-day and waitlist requests, not necessarily new-patient bookings.

**Severity:** Significant weakness
**Test/mitigation:** Publish a calibration curve and the observed no-show rate among appointments scored above 40%. Show how the results change when the second-booked patient's no-show rate is varied. Model the effect on new-patient access explicitly. Replace the retrospective-only evidence with a prospective pilot that has comparison clinics.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: none
- Escalate: the 9,200 / 2,100 arithmetic needs an explanation from the analytics team before the committee meets
- Questions I would have asked: Does the simulation assume every opened slot is filled and every second patient arrives?
- Decisions I made: Interpreted "filled 9,200 slots that went unused" as a subset of opened slots, with double arrivals counted separately.

### The Ethicist: Who is harmed, and is that harm justified?

User goal: Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Ethicist lens — Who is harmed, and is that harm justified? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

Insurance category and distance are two of the three most influential inputs. As a result, publicly insured, self-pay and far-living patients will be flagged far more often. Those flagged patients absorb the costs the proposal describes: longer waits and, on busy days, being "asked to return for a shorter follow-up visit later in the week." That request lands hardest on someone whose original barrier may have been transport or time off work. Published work on overbooking algorithms has reported that similar models disproportionately overbook Black patients (unverified here). For a community health center, this pattern conflicts with the mission.

The proposal also treats a no-show only as wasted capacity. A no-show is often a signal of an unmet need, and the same score could trigger outreach instead.

**Severity:** Significant weakness
**Test/mitigation:**
- Drop insurance category and test whether distance is acting as a proxy for it.
- Audit flag rates, waiting time and send-backs by insurance, race/ethnicity and language.
- Adopt a rule that the flagged patient is never the one asked to return.
- Pair each flag with a reminder call or transport offer.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: legal exposure (e.g., federal nondiscrimination rules on decision-support tools that use age and similar inputs); left to Blind Spots
- Escalate: the governance reporting should add equity breakdowns before approval
- Decisions I made: Rated this "significant" rather than "fatal" because the mitigations are practical and cheap.

### The Systems Thinker: What feedback loops and emergent effects does this create?

User goal: Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Systems Thinker lens — What feedback loops and emergent effects does this create? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

There is a reinforcing loop. A flagged patient who arrives waits longer or is sent home. A worse experience makes a future no-show more likely, and "missed appointments in the past two years" is the top input. The score rises, and the cycle repeats.

Quarterly retraining makes this worse. After the first quarter, the training data reflects the policy's own interventions: double-booked sessions, patients who were deferred, and clinicians choosing which sessions to decline. The model will learn its own effects and present them as patient behaviour. The monthly metrics (no-show rate, fill rate, average wait) cannot detect this, because a rising no-show rate among flagged patients would look like the model working.

There is also a balancing effect worth checking. If access really improves, shorter lead times should reduce no-shows. Fewer slots would then open, so the projected 9,000 visits may shrink over time.

**Severity:** Significant weakness
**Test/mitigation:** Randomly exempt a small fraction of flagged slots from double-booking. This keeps a clean comparison group for retraining and evaluation. Track the later attendance of patients who were flagged versus those who were not, and treat a widening gap as a stop condition.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: none
- Escalate: the retraining design needs a holdout before quarterly retraining begins
- Decisions I made: Assumed the existing informal front-desk overbooking stops; if it continues, the training data is contaminated further.

### The Implementation Engineer: What's the actual build plan, and where does it break?

User goal: Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Implementation Engineer lens — What's the actual build plan, and where does it break? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

"On average, no session has more than one" double arrival is the wrong guarantee. Clinicians said they can absorb one. Averages hide tails, so some sessions will get two or three double arrivals. Those tails will be worst at the three starting clinics, which are the busiest and have the least slack.

Several operational pieces are undefined:
- **Who decides who waits or returns.** The proposal says "the second patient, or sometimes the first," with no protocol.
- **When a clinician can decline.** Scoring runs each evening and schedulers fill slots the next day, so a clinician may have to decline before knowing the day's load.
- **Informal overbooking.** It is unclear whether front-desk staff stop doing it, or whether it stacks on top of the model.
- **Scheduler workload.** Filling flagged slots from same-day lists is new work for each scheduler, every day.

**Severity:** Significant weakness
**Test/mitigation:**
- Set a hard cap per session (enforced in the system, not met on average).
- Write a protocol for double arrivals that names who is seen first.
- Formally retire informal overbooking.
- Pilot at one high-volume and one moderate-volume clinic before expanding.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: scheduling-system integration specifics (vendor not named)
- Escalate: the hard-cap and double-arrival protocol should be conditions of approval
- Decisions I made: Evaluated operational feasibility rather than software build, since the model already exists.

---

## Synthesis

All four personas answered `yes`. There were no missing notes and no `partial` answers.

**Questions to clarify:**
- Does the simulation assume every opened slot is filled and every second patient arrives? (Empiricist)

**Escalations to action separately:**
- The analytics team should explain the 9,200 / 2,100 arithmetic before the committee meets. (Empiricist)
- Governance reporting should add equity breakdowns. (Ethicist)
- Retraining needs a randomized holdout. (Systems Thinker)
- A hard cap and a double-arrival protocol should be conditions of approval. (Implementation Engineer)

### Convergent Findings
- **The burden falls on flagged patients, and nobody tracks it.** The Ethicist sees a distributional harm. The Systems Thinker sees the same harm compounding through the "prior misses" input. The Implementation Engineer notes that no protocol decides who waits or is sent home. All three point to the same gap: the governance metrics measure throughput, not who bears the cost.
- **The evaluation design cannot show whether the policy works.** The Empiricist wants calibration evidence and comparison clinics. The Systems Thinker wants a randomized holdout. Both would be solved by one change: a staggered or partly randomized rollout instead of starting at the three busiest clinics with no comparison.

### Tensions
- **Accuracy vs. fairness.** Insurance category is among the most predictive inputs. Removing it, as the Ethicist recommends, will likely lower the AUC the Empiricist is checking. The committee should decide how much accuracy it will trade for equity, rather than leaving that choice to the analytics team.
- **Throughput vs. outreach.** The proposal turns a predicted no-show into extra capacity. The Ethicist's alternative turns it into outreach, which may reduce no-shows and, through the Systems Thinker's balancing loop, the recoverable visits. These are different goals, and the proposal should say which it serves.
- **Where to pilot.** The busiest clinics offer the biggest gains, but the Implementation Engineer notes they have the least slack to absorb errors.

### Ranked Concerns
| # | Concern | Raised by | Severity | Convergence |
|---|---------|-----------|----------|-------------|
| 1 | Flagged patients (public/self-pay, far-living) bear the waits and send-backs, with no equity monitoring | Ethicist, Systems Thinker, Implementation Engineer | Significant weakness | High (3) |
| 2 | No comparison group: the rollout has no controls, and retraining learns the policy's own effects | Empiricist, Systems Thinker | Significant weakness | Medium (2) |
| 3 | Evidence gaps: the AUC comparison is not like-for-like, the 9,200 / 2,100 arithmetic is unexplained, and the 26→18-day claim is unsupported | Empiricist | Significant weakness | Single |
| 4 | A per-session limit met only "on average," with no double-arrival protocol, starting at the busiest clinics | Implementation Engineer | Significant weakness | Single (partly shared by #1) |

### Blind Spots
- **Regulatory.** The Regulatory Mind was not selected. It would ask whether federal nondiscrimination rules on decision-support tools apply to a scheduling model with an age input. It would also ask about payer-contract or state rules on sending patients home. Recent rules on this point exist but were not verified here, so legal review is advisable.
- **Patient experience.** The End User Advocate was not selected. It would ask how a patient learns they were double-booked or asked to return, and how a patient's wait in the waiting room affects trust in a community health center.
- **Alternatives.** The Opportunity Cost Accountant was not selected. It would compare this proposal with cheaper options: targeted reminders, transport help, or shorter booking lead times (the model's own second input).
- **Power.** The Power Analyst was not selected. It would note that the clinician's right to decline shifts conflict onto schedulers and front-desk staff, who have no equivalent right.
