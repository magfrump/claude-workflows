Your goal, as I understand it: stress-test the Brackenridge predictive-scheduling proposal from several independent angles before it reaches the Executive Committee and Medical Staff Council.

> **No fact-check report provided.** Checkable claims have not been independently verified.
> For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.

# AI Personas Critique

**User goal:** stress-test this proposal from several independent angles before it goes to the people who will decide on it.
**Proposal:** Predictive Scheduling for Primary Care. Use a no-show model to double-book high-risk slots at three Brackenridge clinics, then all eleven.
**Domains:** healthcare (primary), AI/ML (primary), organizational (secondary)
**Personas selected:**
- **The Ethicist (2):** The model's top inputs are insurance category and distance, so the question of who bears the cost is central. Covers values and the "should this exist?" side.
- **The Empiricist (1):** The case rests on an AUC comparison and a retrospective simulation. Covers evidence and internal logic.
- **The Systems Thinker (3):** The model is retrained on outcomes its own policy produces. Covers the future and external interaction.
- **The Implementation Engineer (11):** The rollout targets the busiest clinics and depends on overnight scoring and same-day fills. Covers the present and the builder side.

All four orthogonality dimensions are covered, so no wild card was needed.
**Personas in parallel:** none

---

## Persona Critiques

### The Ethicist: Who is harmed, and is that harm justified?

User goal: stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Ethicist lens — who is harmed, and is that harm justified? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The proposal says the three most influential inputs are prior misses, insurance category, and distance. The model will therefore flag public-coverage, self-pay, and far-living patients disproportionately. At a community health center, these are likely the patients with the most transport, work, and childcare barriers.

When those patients do arrive, they are the ones who wait longer, or who are "asked to return for a shorter follow-up later in the week." The document says the burden falls on "the second patient, or sometimes the first." By construction, the first patient is the predicted no-show, the person for whom a second trip is costliest. A patient who took two buses and is sent home is the clearest harm in the document, and nothing measures it.

The benefits go elsewhere. Waitlist and same-day patients get shorter waits, and they are plausibly a more advantaged group. Using payer type to shape a patient's care experience is something many clinicians will object to on principle, however predictive it is.

**Severity:** Significant weakness. It could be decisive at the Medical Staff Council.
**Test/mitigation:**
- Retrain without insurance and distance, and report the AUC cost.
- Adopt a rule that the originally scheduled patient is never the one sent away.
- Report double-booking rates, waits, and sent-away counts broken down by payer, age band, and distance.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: Formal legal analysis.
- Escalate: Legal review before approval. My recollection is that the ACA Section 1557 rule on patient care decision support tools (45 CFR 92.210) requires covered entities to identify and mitigate discrimination risk. Age band is a protected input under that rule, and insurance and distance may proxy for race or national origin. This is unverified.
- Decisions I made: Assumed Brackenridge's patient mix makes insurance category correlate with income and race. The proposal does not say so.

### The Empiricist: What evidence actually supports this claim?

User goal: stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Empiricist lens — what evidence actually supports this claim? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

Four numbers need scrutiny before the committee relies on them.

1. **The 0.81 vs. 0.62 comparison is not like-for-like.** Front-desk staff made yes/no overbooking decisions, which yield a single operating point, not a ranking. Their outcomes were also only observed where staff chose to act.
2. **AUC says nothing about calibration.** The 40% threshold is only meaningful if a predicted 40% is actually about 40%. No calibration result is reported.
3. **The simulation figures don't reconcile.** If flagged slots average around 50% predicted no-show, double arrivals should be roughly as common as fills. The proposal reports 9,200 fills against only 2,100 double arrivals. Either the model is miscalibrated, or the simulation assumes every fill patient shows up, and same-day and waitlist patients also no-show.
4. **"26 days to about 18" has no stated mechanism.** The fills come from same-day and waitlist requests, not necessarily new-patient visits. Each "return later in the week" visit also consumes a future slot.

"On average no session has more than one" double arrival says nothing about the worst sessions.

**Severity:** Significant weakness. The headline benefits may be overstated.
**Test/mitigation:**
- Publish a calibration plot.
- Show the simulation's assumptions about fill-patient show rates.
- Report the distribution of double arrivals per session, not just the mean.
- Model new-patient wait times explicitly.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: Recomputing figures. I had no underlying data.
- Escalate: The 9,200 / 2,100 reconciliation should go back to the analytics team before the meeting.
- Decisions I made: Read "2,100 of them" as double arrivals among double-booked slots. The sentence is ambiguous, and that ambiguity is itself worth fixing.

### The Systems Thinker: What feedback loops and emergent effects does this create?

User goal: stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Systems Thinker lens — what feedback loops and emergent effects does this create? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The policy can create a reinforcing loop:

1. A patient is flagged and double-booked.
2. They wait longer or are sent away.
3. Their trust and motivation drop, and they miss more appointments.
4. Their prior-miss count rises, so they are flagged more often.

The model's top feature then becomes partly a record of the model's own decisions. Quarterly retraining on data generated under the policy bakes this in, because the model starts predicting the effects of its own interventions.

Other inputs will shift too. If waits shorten, the booking-to-appointment lead time changes, and the relationships the model learned drift with it.

Two interactions are unaddressed. First, the proposal doesn't say whether informal front-desk overbooking stops. If it continues alongside the model, sessions exceed the one-arrival tolerance. Second, the clinician opt-out may concentrate double bookings on clinicians less able to refuse, such as junior staff or locums.

**Severity:** Significant weakness. The effects compound slowly and are invisible in monthly averages.
**Test/mitigation:**
- Keep a randomized holdout of flagged slots that are not double-booked.
- Track repeat-flag and no-show trajectories for flagged patients.
- Record the policy action as a feature when retraining.
- Formally retire informal overbooking.
- Report opt-out and double-booking load per clinician.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: none
- Escalate: Clarify the future of informal overbooking. It is an operational decision, not a modeling one.

### The Implementation Engineer: What's the actual build plan, and where does it break?

User goal: stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Implementation Engineer lens — what's the actual build plan, and where does it break? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

**The pilot is set up in the hardest conditions.** The three highest no-show clinics are also the busiest, so they have the least slack. The "one double arrival per half-day" tolerance comes from what clinicians said in design sessions, not from measurement. With no comparison group, a bad outcome won't be attributable, and neither will a good one.

**The workflow is under-specified.** Scoring runs each evening, so fills happen the next morning. That favors patients who can come at a few hours' notice, which is another equity filter. The proposal doesn't say:
- who calls patients to fill slots, or when;
- whether patients are told their slot is shared;
- how a clinician's opt-out works once a slot is already filled.

**There are no stop or expansion criteria.** The plan extends to all eleven clinics by midyear on a calendar, not on results. Monthly reports omit the numbers that matter most: session overruns, sent-away counts, and complaints.

**Severity:** Significant weakness. It is fixable before approval.
**Test/mitigation:**
- Run a stepped-wedge rollout or randomize at the session level.
- Include one moderate-volume clinic in the pilot.
- Write the fill and notification workflow.
- Make midyear expansion contingent on pre-agreed thresholds for overruns, sent-away visits, and equity metrics.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: Integration with the scheduling system. The proposal gives no technical detail.
- Escalate: Amend the "Decision requested" section so it includes success and stop criteria.

---

## Synthesis

All four personas answered `yes`, with no partial answers and no missing notes.

### Convergent Findings
- **The "sent away to return later" outcome is unmeasured and unequally distributed.** The Ethicist, Empiricist, and Implementation Engineer all flagged it independently. It is a real cost, it offsets the "recovered visits," and it lands on the predicted no-shows.
- **The governance metrics can't detect the likely failure modes.** All four personas flagged this. Monthly averages of no-show, fill, and wait times miss per-session tails, sent-away counts, breakdowns by payer and distance, and feedback-loop drift.
- **There is no counterfactual.** The Empiricist, Systems Thinker, and Implementation Engineer all flagged it. Without a holdout or randomized rollout, neither the benefit nor the harm can be attributed to the model.

### Tensions
- **Fairness vs. predictive power.** The Ethicist wants insurance and distance removed. Those are two of the three strongest inputs, so removal will cost AUC and some recovered visits. The committee should see that trade quantified rather than choose blind.
- **Who absorbs the double arrival.** Protecting the original patient, as the Ethicist recommends, shifts every overflow onto the waitlist patient. That may reduce the policy's appeal to schedulers and clinicians.
- **Pilot site choice.** The Implementation Engineer wants a less-busy clinic in the pilot for safety and comparison. The busiest clinics are where the no-show problem, and the potential gain, is largest.

### Ranked Concerns
| # | Concern | Raised by | Severity | Convergence |
|---|---------|-----------|----------|-------------|
| 1 | Monitoring omits sent-away visits, per-session tails, equity breakdowns, and drift | All four | Significant | 4 |
| 2 | Burden falls on public, self-pay, and distant patients via model inputs; possible §1557 exposure | Ethicist, Systems Thinker, Implementation Engineer | Significant (possibly decisive) | 3 |
| 3 | No control group, stop rule, or results-gated expansion | Empiricist, Systems Thinker, Implementation Engineer | Significant | 3 |
| 4 | Simulation numbers don't reconcile; calibration and the 26→18 day claim are unsupported | Empiricist | Significant | 1 |
| 5 | Self-reinforcing loop between prior misses and quarterly retraining | Systems Thinker | Significant | 1 (overlaps with #2) |
| 6 | Pilot at the busiest clinics; next-morning fill workflow undefined | Implementation Engineer | Significant | 1 |

**Escalations to action separately:**
- Get a legal and compliance read on 45 CFR 92.210 and on the use of age and insurance as inputs.
- Have the analytics team reconcile the 9,200 / 2,100 figures.
- Decide whether informal overbooking ends.
- Amend the decision request to include success and stop criteria.

### Blind Spots
- **Regulatory (Regulatory Mind, external and present).** Only touched on via escalation. A full pass would check §1557, any state rules on algorithmic tools, payer contract terms, and HRSA/FQHC obligations if Brackenridge is a health center grantee.
- **Opportunity cost (Opportunity Cost Accountant, and the Contrarian on the premise).** No one compared double-booking against reducing no-shows directly. Reminders, transport support, telehealth conversion, and open-access scheduling are all alternatives. The Contrarian would argue that a 17% no-show rate concentrated among distant and publicly insured patients is an access failure, and that double-booking treats the symptom while worsening the cause.
- **Patient experience (End User Advocate).** Two things were set aside: whether patients are told about shared slots, and how the extra 11 minutes and the possibility of being sent home will feel at the front desk.
- **Clinician sustainability (Sustainability Auditor).** "Absorb one per half-day" may hold in month one and not in month nine. Burnout among the absorbing clinicians is unmeasured.
- **Set aside by personas:** formal legal analysis (Ethicist), recomputation from raw data (Empiricist), and scheduling-system integration (Implementation Engineer).
