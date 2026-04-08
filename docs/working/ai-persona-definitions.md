# AI Personas for Structured Critique

17 distinct critical perspectives designed for maximum orthogonality across analytical dimensions. Each persona represents a cognitive orientation — a habitual way of interrogating proposals — not a character to impersonate.

## How personas are used

The `ai-personas-critique` skill selects 3–4 personas per proposal based on domain relevance and orthogonality. Each persona contributes one focused objection using its signature analytical lens. Personas are ordered "closest ally first" — the most sympathetic persona speaks before the most skeptical.

## Orthogonality dimensions

Personas span these axes:
- **Temporal**: backward-looking (Historian) ↔ forward-looking (Futurist)
- **Scale**: individual experience (End User) ↔ systemic effects (Systems Thinker)
- **Stance**: sympathetic deconstruction (Minimalist) ↔ adversarial stress-test (Adversary)
- **Domain**: technical (Operator, Maintainer) ↔ social (Community Voice, Ethicist)
- **Methodology**: empirical (Empiricist) ↔ structural (Economist, Regulator)

---

## The 17 Personas

### 1. The Empiricist

**Lens:** Evidence quality and inferential validity.

**Signature question:** "What's the evidence, and how strong is it?"

**Cognitive moves:**
- Demand quantitative support for causal claims
- Check for selection bias, survivorship bias, base rate neglect
- Ask whether the cited evidence actually supports the specific claim (not just a related one)
- Flag unfalsifiable assertions and circular reasoning
- Distinguish correlation from causation explicitly

**Typical blind spot:** Can dismiss promising directions that lack formal evidence yet.

---

### 2. The Systems Thinker

**Lens:** Feedback loops, emergent behavior, and unintended consequences.

**Signature question:** "What happens when this interacts with everything else?"

**Cognitive moves:**
- Trace second- and third-order effects through connected systems
- Identify reinforcing and balancing feedback loops the proposal creates or disrupts
- Check for delayed effects that won't manifest during initial evaluation
- Ask where the system will reach a new equilibrium and whether that's desirable
- Look for leverage points vs. low-impact interventions

**Typical blind spot:** Can over-complicate simple proposals with speculative cascades.

---

### 3. The Historian

**Lens:** Precedent, pattern-matching, and institutional memory.

**Signature question:** "When was this tried before, and what happened?"

**Cognitive moves:**
- Find historical analogues (same domain or structural parallels in other domains)
- Identify which failure modes from past attempts the proposal addresses — and which it doesn't
- Check whether the proposal assumes conditions that no longer hold (or never did)
- Note when "unprecedented" claims ignore relevant history
- Distinguish genuinely novel situations from ones that feel novel due to ignorance of history

**Typical blind spot:** Can over-anchor on historical precedent when conditions have genuinely changed.

---

### 4. The End User

**Lens:** Adoption friction, daily experience, and human behavior under real conditions.

**Signature question:** "Would a real person actually do this, repeatedly, without being forced?"

**Cognitive moves:**
- Simulate the proposal's impact on a typical user's daily routine
- Identify steps that require effort, attention, or behavior change — each is a dropout risk
- Check whether the proposal competes with existing habits (which almost always win)
- Ask what happens when users are tired, distracted, or annoyed
- Distinguish "would use if it existed" from "would switch to from current solution"

**Typical blind spot:** Can be parochial — "real users" may differ dramatically by context.

---

### 5. The Adversary

**Lens:** Attack surface, gaming, and perverse incentives.

**Signature question:** "How would a motivated bad actor exploit this?"

**Cognitive moves:**
- Red-team the proposal: identify the cheapest, most obvious exploit
- Check for Goodhart's Law — will optimizing the proposed metric corrupt the underlying goal?
- Ask who benefits from the proposal failing and what tools they have
- Identify information asymmetries the proposal creates or relies on
- Test whether safeguards can be trivially circumvented

**Typical blind spot:** Can generate implausible threat models that paralyze action.

---

### 6. The Ethicist

**Lens:** Power dynamics, consent, distributional justice, and moral hazard.

**Signature question:** "Who bears the costs, and did they agree to?"

**Cognitive moves:**
- Map who benefits and who is burdened — check whether they're the same people
- Ask whether affected parties had meaningful input or consent
- Check for moral hazard: does the proposal let decision-makers externalize risk?
- Identify whose voices are absent from the proposal
- Distinguish "fair process" from "fair outcome" — the proposal may have one without the other

**Typical blind spot:** Can prioritize symbolic fairness over practical impact.

---

### 7. The Operator

**Lens:** Production readiness, failure modes, and operational burden.

**Signature question:** "What happens at 3 AM when this breaks?"

**Cognitive moves:**
- Identify the most likely failure mode and ask what the recovery path is
- Check whether the proposal creates on-call burden, monitoring requirements, or manual toil
- Ask what the degraded-service experience looks like (not just the happy path)
- Identify single points of failure and cascading failure risks
- Check whether the proposal is operable by the team that will actually run it (not the team that designed it)

**Typical blind spot:** Can be excessively conservative, vetoing good ideas because they add any operational complexity.

---

### 8. The Regulator

**Lens:** Compliance, liability, jurisdictional variance, and accountability.

**Signature question:** "Is this legal everywhere it needs to be, and who's liable when it goes wrong?"

**Cognitive moves:**
- Identify which regulatory frameworks apply (and whether the proposal's authors considered them)
- Check for jurisdictional variance — what's allowed in one market may be prohibited in another
- Ask who bears legal liability when the proposal produces harm
- Identify audit trail requirements and whether the proposal satisfies them
- Check whether the proposal creates regulatory precedent (intentionally or not)

**Typical blind spot:** Can treat compliance as a binary when regulators often operate in gray zones.

---

### 9. The Economist

**Lens:** Incentive structures, opportunity costs, and resource allocation efficiency.

**Signature question:** "Compared to what, and at what cost?"

**Cognitive moves:**
- Identify the opportunity cost — what else could these resources accomplish?
- Check whether incentives align: will participants actually behave as the proposal assumes?
- Ask about marginal vs. average effects — the proposal may work at current scale but not at target scale
- Look for deadweight loss, rent-seeking opportunities, or principal-agent problems
- Check whether the proposal prices in its own externalities

**Typical blind spot:** Can reduce human values to utility calculations where that framing doesn't fit.

---

### 10. The Scaling Skeptic

**Lens:** What breaks between prototype and production, between pilot and rollout.

**Signature question:** "This works for 10 users — does it work for 10 million?"

**Cognitive moves:**
- Identify which parts of the proposal rely on artisanal attention that won't survive scaling
- Check for coordination costs that grow super-linearly with team/user/data size
- Ask whether the proposal's success metrics were measured under conditions that won't hold at scale
- Look for Conway's Law effects — will organizational structure distort the proposal's design?
- Distinguish "works at scale" from "has been tested at scale"

**Typical blind spot:** Can dismiss valuable small-scale solutions by insisting everything must scale.

---

### 11. The Domain Outsider

**Lens:** Naive but illuminating questions from adjacent fields.

**Signature question:** "In [unrelated field], we solved a similar problem by doing X — why not here?"

**Cognitive moves:**
- Identify structural parallels in unrelated domains
- Ask basic questions that domain insiders stopped asking years ago
- Challenge domain-specific jargon: does the terminology obscure a simpler underlying concept?
- Import solution patterns from other fields and check whether they transfer
- Notice when the proposal's framing forecloses options that would be obvious in another domain

**Typical blind spot:** Analogies can be superficial; structural similarity ≠ practical transferability.

---

### 12. The Incumbent

**Lens:** Existing solutions, switching costs, and ecosystem dynamics.

**Signature question:** "What does this replace, and why would anyone switch?"

**Cognitive moves:**
- Identify the current solution (even if it's "do nothing" or "use a spreadsheet")
- Calculate switching costs: migration effort, retraining, data portability, integration rewiring
- Ask whether the proposal is 10x better or just 2x — the latter rarely overcomes inertia
- Check for ecosystem lock-in: does the proposal depend on or compete with entrenched platforms?
- Identify who profits from the status quo and what resources they'll deploy to protect it

**Typical blind spot:** Can mistake "hard to displace" for "shouldn't be displaced."

---

### 13. The Futurist

**Lens:** Technology trajectories, paradigm shifts, and obsolescence risk.

**Signature question:** "Will this still matter in 5 years, or is it solving yesterday's problem?"

**Cognitive moves:**
- Identify which technology trends could make the proposal irrelevant before it ships
- Check whether the proposal bets on a technology plateau (stable) or inflection point (risky)
- Ask what happens if a key assumption about future conditions is wrong
- Distinguish trend extrapolation from wishful thinking
- Check whether the proposal builds optionality or locks in a single future

**Typical blind spot:** Can dismiss near-term value by over-weighting speculative futures.

---

### 14. The Minimalist

**Lens:** Essential complexity vs. accidental complexity, core value proposition.

**Signature question:** "What's the simplest version of this that still works?"

**Cognitive moves:**
- Strip the proposal to its minimum viable version and check whether the core value survives
- Identify features, requirements, or constraints that add complexity without proportional value
- Ask which 20% of the proposal delivers 80% of the impact
- Check whether bundled features could be independent, reducing coordination cost
- Distinguish "nice to have" from "essential" — the proposal likely conflates them

**Typical blind spot:** Can over-strip, removing features that seem optional but are load-bearing.

---

### 15. The Community Voice

**Lens:** Affected populations, stakeholder representation, and lived experience.

**Signature question:** "Did anyone ask the people this will actually affect?"

**Cognitive moves:**
- Identify all stakeholder groups affected by the proposal (including indirect ones)
- Check whether the proposal's framers consulted or represented these groups
- Ask whose lived experience contradicts the proposal's assumptions
- Look for proposals that optimize for measurable proxies while ignoring harder-to-measure human impacts
- Distinguish "designed for" from "designed with" — co-design vs. paternalism

**Typical blind spot:** Can treat "community input" as a veto rather than one input among many.

---

### 16. The Maintainer

**Lens:** Long-term sustainability, technical debt, and organizational continuity.

**Signature question:** "Who maintains this after the original team moves on?"

**Cognitive moves:**
- Check the bus factor: what happens when key people leave?
- Ask whether the proposal creates documentation, knowledge transfer, and onboarding requirements
- Identify maintenance costs that grow over time (dependency updates, data migration, schema evolution)
- Check whether the proposal's design allows incremental change or requires coordinated rewrites
- Ask who pays the maintenance cost — it's rarely the people who benefit from the initial build

**Typical blind spot:** Can prioritize long-term maintainability over near-term value delivery.

---

### 17. The Contrarian

**Lens:** Frame inversion and assumption challenging.

**Signature question:** "What if the opposite of your premise is true?"

**Cognitive moves:**
- Invert the proposal's central assumption and explore what follows
- Ask whether the proposal is solving the right problem (vs. a symptom, or a problem that doesn't exist)
- Challenge the framing: what options become visible if you reject the proposal's problem definition?
- Check for consensus bias — is the proposal popular because it's correct, or because questioning it is uncomfortable?
- Identify what would need to be true for the proposal to be actively harmful (not just ineffective)

**Typical blind spot:** Contrarianism for its own sake — not every consensus is wrong.

---

## Persona selection guidance

When selecting personas for a given proposal, maximize orthogonality:

**For technical proposals:** Operator + End User + Scaling Skeptic + Contrarian
**For policy proposals:** Economist + Community Voice + Regulator + Historian
**For product proposals:** End User + Incumbent + Minimalist + Adversary
**For research proposals:** Empiricist + Futurist + Domain Outsider + Historian
**For organizational proposals:** Operator + Maintainer + Community Voice + Economist

These are defaults — the skill should override based on the specific proposal's characteristics.
