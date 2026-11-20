# AI Personas Critique

**User goal:** Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
**Proposal:** Faster Account Recovery for Tallyfin Wallet. Replace SMS + email + ID/selfie recovery with SMS only, add agent-assisted phone-number changes, and keep full account access immediately after recovery.
**Domains:** finance (primary), technology/security (primary), product (secondary)
**Personas selected:**
- **Security Analyst (7):** account recovery is the main account-takeover path, so this is the central risk lens. *External.*
- **Implementation Engineer (11):** tests whether the rollout can detect the failures that matter. *Evidence, present, builder.*
- **Regulatory Mind (9):** this is a stored-value wallet with P2P transfers, so liability rules decide who pays for takeovers. *Present, external.*
- **Contrarian (15, wild card):** inverts the premise that recovery friction is the problem. *Internal, critic.*

**Personas in parallel:** none

> **No fact-check report provided.** Checkable claims have not been independently verified.
> For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.
> (One internal check: 55,000 × $1.10 × 12 = $726,000/yr, so the stated savings arithmetic is consistent.)

**Selection notes:**
- **Candidate pool:** finance (6, 7, 9, 12), technology (7, 8, 11, 17) and product (1, 5, 8, 11, 12, 13).
- **Initial pick:** 7, 11, 9 and the Empiricist (1).
- **Wild-card check:** counting a dimension as covered only when both of its poles are represented, that set balanced just internal vs. external. That triggered the wild-card rule.
- **Swap:** the Contrarian replaced the Empiricist. It keeps the internal pole and adds the critic pole. The Empiricist's core point, that the test measured completion and not fraud, is carried by the Implementation Engineer and the Contrarian.
- **Gaps:** values and future remain uncovered. They are addressed under Blind Spots.

---

## Persona Critiques

### Security Analyst: How would an adversary exploit this?

User goal: Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Security Analyst lens — how would an adversary exploit this? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The proposal reduces recovery to one factor an attacker can obtain without the customer. "SMS is already our second factor" cuts the wrong way. Today SMS is paired with a password. After this change, an SIM swap or port-out yields the whole account.

Assisted recovery is weaker still. Name, date of birth and the last four card digits leak in breaches, appear on receipts, and are known to partners and family. Passing those checks lets the caller *replace the phone number* and then self-serve. That is a full takeover via one phone call, and the proposal states no notification to the old number or email.

Session continuity then gives the attacker saved payees and the full balance at once. The roughly 6% of accounts above $2,000 become concentrated targets. The five-attempt limit applies per code. Nothing caps code requests or assisted attempts per account.

**Severity:** Fatal flaw (as written)
**Test/mitigation:**
- Require an independent second factor for phone-number changes.
- Notify the old phone and email with a one-tap "this wasn't me" lock.
- Cap or delay transfers to *new* payees after recovery. Allow limited merchant payments so the checkout case still works.
- Risk-score recoveries using carrier SIM-change signals, device and location, and step up high-risk cases to ID verification.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: specific SIM-swap prevalence data (no fact-check available)
- Escalate: assisted recovery as a one-call takeover path. Support Ops should not sign off on that script as written.
- Decisions I made: rated "fatal" for the combination of SMS-only recovery, agent phone change and no hold, not for any one element alone.

### Implementation Engineer: What's the actual build plan, and where does it break?

User goal: Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Implementation Engineer lens — what's the actual build plan, and where does it break? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The rollout monitors completion and contact rate only. It has no fraud metric and no kill criteria, and fraud is the failure mode that matters. Account-takeover signals lag: victims often notice days or weeks later, and disputes arrive after that.

At about 55,000 recoveries a month, the 10% phase sees roughly 2,500 recoveries in two weeks. Fraud at a low rate is statistically invisible at that sample size and timescale. Week 5 then retires the ID-verification integration, removing the fallback before any fraud data has matured.

The 4,000-customer test has the same blind spot. A benign test population contains no adversaries, so a 93% completion rate says nothing about safety.

The hardest 20% of this work is not the simplified UI. It is fraud detection, notification, and agent tooling. "Agents cannot skip any of the three checks" needs to be enforced by the support tool, not just by training.

**Severity:** Significant weakness
**Test/mitigation:**
- Add takeover-report rate and dispute rate as gating metrics, with thresholds.
- Lengthen each phase to cover dispute latency, likely 30–60 days.
- Keep the ID vendor contract as a step-up for risky recoveries.
- Enforce the check sequence in tooling.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: engineering effort estimates (not provided in proposal)
- Escalate: retiring the ID integration in week 5 should be decoupled from the rollout and decided on fraud data.
- Decisions I made: assumed the 4,000-customer test involved real, non-adversarial users; the proposal does not say how they were selected.

### Regulatory Mind: What legal or compliance barriers exist?

User goal: Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Regulatory Mind lens — what legal or compliance barriers exist? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

Assuming US operation, a stored-value wallet with P2P and merchant payments likely falls under Regulation E, including its prepaid-account provisions. Counsel should confirm this. Under those rules, consumer liability for unauthorized transfers is limited, which means Tallyfin, not the customer, likely absorbs takeover losses. The $726,000 annual saving should therefore be netted against the expected increase in reimbursed fraud. The proposal does not model that.

Federal banking authentication guidance has long been skeptical of knowledge-based questions and single-factor controls for high-risk actions. NIST's digital identity guidelines treat SMS as a restricted authenticator. That the card issuer uses the same knowledge questions does not establish that regulators, or the issuer's own contract with Tallyfin, accept them as sufficient for changing account control.

Removing the ID step may also touch documented controls in the KYC/AML program and in bank-partner or money-transmitter obligations. The Asks list requests sign-off from Risk, but not from Legal or Compliance.

**Severity:** Significant weakness
**Test/mitigation:**
- Add Legal/Compliance and the bank partner to the sign-offs.
- Produce a loss model of expected takeover reimbursements under Reg E against the savings.
- Document a risk assessment for the control change.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: partial (jurisdiction not stated; regulatory specifics unverified without fact-check)
- Out of scope: non-US regimes (e.g., PSD2 strong customer authentication) in case Tallyfin operates in the EU/UK
- Escalate: missing Legal/Compliance sign-off in the Asks
- Questions I would have asked: Which jurisdictions does Tallyfin operate in, and under which license or bank partner?
- Decisions I made: assumed US operation; hedged all regulatory claims as needing counsel confirmation.

### Contrarian: What if the opposite of the core premise is true?

User goal: Stress-test this proposal from several independent angles before it goes to the people who will decide on it.
Current task: Apply the Contrarian lens — what if the opposite of the core premise is true? — to this proposal.
Success criterion: A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.

The premise is that friction is the problem. Consider the opposite: the friction is doing work. The 38% abandonment is counted entirely as failure, but some share of those attempts are impostors who stopped at email or ID. The current flow's abandonment includes prevented fraud, and the proposal does not try to measure it.

Likewise, 93% completion is exactly the number you would see if the flow let attackers through. Completion rate cannot tell a customer from an impostor, so the headline success metric is blind to the headline risk.

The email-step failures point to stale contact data, not a useless check. The better fix may be to refresh factors proactively: prompt for a current email or backup factor at routine sign-in.

The proposal is right that the pain is real. The checkout scenario is credible, and "locked out of my own money" reviews are a genuine cost. But "my money was stolen" reviews are worse. A bounded post-recovery spending allowance serves the checkout case without exposing the full balance.

**Severity:** Significant weakness
**Test/mitigation:**
- Estimate the fraud share of today's abandonment, using risk signals on abandoned attempts and later compromise reports on those accounts.
- Pair the change with factor-hygiene prompts.
- Tier recovery requirements by balance and risk.

#### Goal-Alignment Note
- Success criterion (restated verbatim): A 100-200 word critique grounded in proposal specifics, with severity and a test/mitigation.
- Answered: yes
- Out of scope: none
- Escalate: the decision-makers need a fraud-share estimate for current abandonment before judging the trade-off.
- Decisions I made: argued "friction is protective" sincerely, while crediting the real user pain as a strength of the proposal.

---

## Synthesis

**Goal-alignment scan:**
- Regulatory Mind answered *partial* because jurisdiction is unstated and its claims are unverified.
- Escalations:
  - Assisted-recovery script (Security)
  - Decoupling the ID-vendor retirement (Implementation)
  - Missing Legal/Compliance sign-off (Regulatory)
  - Fraud-share estimate (Contrarian)
- **Questions to clarify:** Which jurisdictions and license or bank-partner structure does Tallyfin operate under? (Regulatory Mind)

### Convergent Findings
1. **The proposal measures only the benefit, never the risk.** Three personas flagged this independently:
   - The Implementation Engineer: no fraud metric in the rollout.
   - The Contrarian: completion rate cannot detect impostors, and abandonment includes prevented fraud.
   - The Regulatory Mind: the savings are not netted against fraud losses Tallyfin likely bears.
2. **Immediate full access after recovery amplifies every weakness.** The Security Analyst sees an instant drain path. The Regulatory Mind sees Tallyfin carrying the liability. The Contrarian proposes a bounded allowance that still satisfies the checkout case.
3. **Agent-assisted phone change is a one-call takeover.** The Security Analyst flags weak, widely known knowledge factors. The Implementation Engineer notes the checks are enforced only by training, not by tooling.

### Tensions
- **Checkout urgency vs. holding period.** The proposal treats this as binary. Both the Security Analyst and the Contrarian point to a middle path: allow merchant payments up to a cap immediately, and delay transfers to new payees and large P2P transfers.
- **Rollout speed vs. fraud latency.** The Implementation Engineer would normally accept a phased rollout as the risk control. Here, a five-week schedule outruns the time it takes takeover signals to surface, so phasing gives false comfort.
- **Vendor savings vs. liability.** The $726k/yr saving is certain and visible. The offsetting fraud cost is uncertain and lagged, which biases the decision toward the visible number.

### Ranked Concerns
| # | Concern | Raised by | Severity | Convergence |
|---|---------|-----------|----------|-------------|
| 1 | No fraud/takeover measurement; success metric is blind to the main risk | Implementation, Contrarian, Regulatory | Significant | 3 |
| 2 | Immediate access to balance and payees after recovery, with no hold or cap | Security, Regulatory, Contrarian | Fatal (with #3) | 3 |
| 3 | Assisted recovery lets knowledge-only callers change the phone number | Security, Implementation | Fatal | 2 |
| 4 | SMS-only recovery is exposed to SIM swap and port-out fraud | Security | Fatal (in combination) | 1 |
| 5 | Savings not netted against likely Reg E reimbursement losses; Legal/Compliance absent from Asks | Regulatory | Significant | 1 |
| 6 | ID integration retired in week 5, before fraud data matures | Implementation | Significant | 1 |

**Bottom line for decision-makers:** the user problem is real and the self-service SMS path may be defensible on its own terms. The combination of agent phone changes on knowledge factors, no post-recovery limits, and a rollout with no fraud gate is not.

A revised version would:
- Add notifications with a one-tap lock.
- Cap or delay new-payee transfers.
- Require step-up verification for phone changes and high-balance or high-risk accounts.
- Gate the rollout on fraud metrics.
- Defer retiring the ID vendor until fraud data has matured.

### Blind Spots
- **Values (uncovered).** An Ethicist would ask who bears the harm. Knowledge-based assisted recovery is especially exploitable by people close to the victim, such as abusive partners or family members, who know a person's date of birth and card digits. Customers who lose phones are also more likely to be the users least able to absorb a loss.
- **Future (uncovered).** A Long-termist would note that retiring the ID integration is easy to do and costly to reverse. It would also flag that the design deepens dependence on phone numbers, a factor whose security is set by carriers outside Tallyfin's control, and that a frictionless recovery flow sets customer expectations that are hard to walk back after a fraud spike.
- **Empirical detail (dropped in wild-card swap).** An Empiricist would ask:
  - How were the 4,000 test users selected?
  - Is the "two thirds fewer contacts" projection consistent with routing every lost-phone customer to support?
  - What is the current takeover base rate?
- **Out-of-scope items carried forward:**
  - SIM-swap prevalence data (unverified)
  - Engineering effort estimates (not provided)
  - Non-US regulatory regimes, if applicable
