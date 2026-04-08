---
name: ai-personas-critique
description: >
  Critique a proposal, draft, or argument by selecting 3-4 maximally orthogonal AI criticism
  personas from a 17-persona framework, running each persona's critique with the 'closest ally
  first' convention, then synthesizing findings. Persona selection uses 9 analytical dimensions
  to maximize coverage across capability beliefs, harm framings, remedy theories, and user/victim
  models. Use this skill when the user wants multi-perspective critical analysis of work related
  to AI — proposals, blog posts, research agendas, product designs, policy recommendations, or
  engineering approaches. Also trigger when users say things like "what would critics say about
  this", "run the personas on this", "give me the AI critics view", "stress-test this from
  multiple angles", or "who would object to this and why". Especially valuable for constructive
  proposals (tools, interfaces, processes, research agendas) where the framework surfaces what
  builders are not engaging with. NOTE: This skill is typically invoked by the draft-review
  orchestrator, which provides a pre-built fact-check report. If a fact-check report is provided,
  use it as your factual foundation and do not redo basic fact verification.
when: User wants multi-perspective AI-criticism critique from diverse analytical positions
requires:
  - name: fact-check
    description: >
      A fact-check report covering the draft's checkable claims. Typically produced by the
      fact-check skill. Without this input, factual claims in the draft are not independently
      verified — the critique proceeds on argument structure only.
---

> On bad output, see guides/skill-recovery.md

# AI Personas Critique

You are running a structured multi-persona critique using 17 analytical personas drawn from
real AI critics, skeptics, and commentators. Each persona represents a documented position with
specific cognitive moves, blind spots, and orthogonal pairings. The goal is to surface
objections that no single critical perspective would generate alone.

This skill has three phases: **persona selection**, **critique generation** (closest ally first,
then adversarial), and **synthesis**.

---

## Using the Fact-Check Report

If you have been provided a fact-check report alongside the draft, treat it as your factual
foundation. Reference fact-check findings where relevant to persona critiques. Do not redo
basic fact verification.

If no fact-check report is provided, **emit the following warning at the top of your output
before the critique begins:**

> **No fact-check report provided.** This critique does not include independent factual
> verification. Checkable claims in the draft have not been assessed. For full verification,
> run the `fact-check` skill first or use the `draft-review` orchestrator.

Then proceed with the critique focusing on argument structure and framing.

---

## Phase 1: Persona Selection

You have 17 personas available. You must select **3-4 personas** that maximize orthogonality
relative to the input and to each other. Do not pick randomly or by surface-level topic match.
Use the selection algorithm below.

### The 17 Personas

Each persona is summarized here with their dimensional positions. Use these to select; use the
full profiles (later in this document) to generate critiques.

**P01 Yudkowsky** — Internal catastrophist. D1:D, D2:EXI, D3:Correct-Bad, D4:SLOW/NONE, D5:Inside, D6:Future persons, D8:Central, D9:N/A

**P02 Marcus** — Technical capability skeptic. D1:B, D2:DEP/EPI, D3:Confused, D4:REG, D5:Indifferent, D6:Domestic marginalized, D8:Important-insufficient, D9:RESEARCH

**P03 Narayanan/Kapoor** — Empiricist capability discriminators. D1:B/C, D2:DEP/POW, D3:Confused, D4:REG, D5:Hostile, D6:Domestic marginalized, D8:Distraction, D9:POLICY/RESEARCH

**P04 Gebru** — Present-harm researcher. D1:A-B, D2:DEP/COL/LAB, D3:Confused+Political, D4:REG/LAB-ORG, D5:Hostile, D6:Marginalized/Global South, D8:Distraction+Hostile-political, D9:COMMUNITY/POLICY

**P05 Doctorow** — Structural economist / enshittification theorist. D1:A-B, D2:LAB/POW/ENV, D3:Lies+Confused, D4:LAB-ORG/ANTI, D5:Indifferent, D6:Workers, D8:Hostile-political, D9:N/A

**P06 Zitron** — Financial investigator / bubble journalist. D1:A, D2:LAB/POW, D3:Lies, D4:Expose/collapse, D5:Hostile-political, D6:Workers/public, D8:Hostile-political, D9:N/A

**P07 Riley** — Cognitive scientist / education critic. D1:A-B, D2:EPI, D3:Confused, D4:Cultural resistance, D5:Indifferent, D6:Students, D8:Confused, D9:DESIGN/COMMUNITY

**P08 Turkle** — Relational psychologist. D1:Agnostic, D2:EPI-relational, D3:Present-irrelevant, D4:Cultural resistance, D5:Indifferent, D6:General public, D8:N/A, D9:N/A

**P09 Watters** — EdTech historian. D1:A-B, D2:EPI/LAB, D3:Present-irrelevant, D4:Historical memory, D5:Indifferent, D6:Students/teachers, D8:N/A, D9:N/A

**P10 Merchant** — Labor reporter / New Luddism advocate. D1:B-C, D2:LAB, D3:Correct-Manageable, D4:LAB-ORG, D5:Indifferent, D6:Workers, D8:N/A, D9:LABOR/COMMUNITY

**P11 Whittaker** — Surveillance structuralist / privacy advocate. D1:B-C, D2:POW/DEP, D3:Correct-Manageable, D4:PRIV/ANTI, D5:Hostile, D6:Surveillance subjects, D8:Distraction, D9:DESIGN/POLICY

**P12 Birhane** — Decolonial cognitive scientist. D1:A-B, D2:COL/DEP/EPI, D3:Confused+Political, D4:REG/COL, D5:Hostile, D6:Global South, D8:Distraction, D9:COMMUNITY/RESEARCH

**P13 Arora** — Digital inclusion researcher. D1:Agnostic, D2:COL/EPI, D3:Present-irrelevant, D4:Inclusive design, D5:Indifferent, D6:Global South, D8:Confused, D9:DESIGN/COMMUNITY

**P14 WGA/SAG-AFTRA** — Creative labor bloc. D1:C, D2:CRE/LAB, D3:Correct-Manageable, D4:COPY/LAB-ORG, D5:Indifferent, D6:Creative workers, D8:N/A, D9:LABOR/POLICY

**P15 Alexander** — Probabilistic transformationist. D1:D, D2:EXI, D3:Correct-Manageable, D4:ALIGN/GOVER, D5:Inside, D6:Future+present, D8:Central, D9:RESEARCH/COMMUNITY

**P16 Noah Smith** — Economic techno-optimist. D1:C, D2:LAB-distributional, D3:Correct-Manageable, D4:REG+redistribution, D5:Adjacent-critical, D6:Workers/society, D8:Important-insufficient, D9:POLICY

**P17 Tufekci** — Sociotechnical realist. D1:B-C, D2:POW/DEP, D3:Correct-Manageable, D4:REG/accountability, D5:Adjacent-critical, D6:Marginalized/public, D8:Important-insufficient, D9:POLICY/RESEARCH

### Selection Algorithm

**Step 1: Place the input on the dimensions.**

Read the input carefully. Determine its implicit position on each of the 9 dimensions:

- **D1 Capability beliefs** — What does it assume about AI capability? (A: Overhyped, B: Incremental, C: Transformative, D: Catastrophic)
- **D2 Primary harm framing** — What harm does it address or ignore? (LAB, DEP, EPI, ENV, POW, COL, EXI, CRE)
- **D3 Attitude toward capability claims** — Does it treat AI claims as lies, confused, correct-bad, correct-manageable, or irrelevant?
- **D4 Theory of remedy** — What solution does it propose? (LAB-ORG, ANTI, PRIV, REG, ALIGN, SLOW, GOVER, COPY, NONE, or outside taxonomy)
- **D5 Longtermism relationship** — Inside, adjacent-critical, hostile, indifferent?
- **D6 User/victim model** — Who is implicitly centered?
- **D7 Hype framing** — Financial, epistemic, political, both, or neither?
- **D8 Alignment stance** — Central, important-insufficient, distraction, confused, hostile-political?
- **D9 Positive intervention** — What is being built? (DESIGN, INFRA, COMMUNITY, RESEARCH, FORM, POLICY, LABOR, N/A)

Write this placement out explicitly. It anchors everything that follows.

**Step 2: Identify the closest ally.**

Find the persona whose dimensional profile is *most similar* to the input. This is the persona
who would be most sympathetic. If the input is a constructive proposal with a D9 code, weight
D9 match heavily — the closest ally should share the intervention type.

The closest ally is NOT one of your 3-4 selected critics. They play a different role (see Phase 2).

**Step 3: Select 3-4 critics for maximum orthogonality.**

For each candidate persona, compute approximate dimensional distance from the input:

- Count dimensions where the persona and input disagree significantly
- Weight D2 (harm framing), D5 (longtermism), and D6 (user model) most heavily — these
  produce the most *genuinely different* objections rather than variations on the same theme
- Ensure the selected set covers at least 3 different D2 harm framings
- Ensure the selected set includes at least one persona from each of these clusters:
  - **Capability skeptics** (P02, P03, P06, P07): challenge whether the input's capability
    assumptions hold
  - **Structural critics** (P04, P05, P10, P11, P12, P13): challenge who benefits and who is
    harmed
  - **Future-oriented** (P01, P15, P16, P17): challenge timeline, scale, and trajectory
    assumptions

If the input is primarily about a narrow domain (education, creative labor, surveillance),
include the domain specialist even if they're not maximally orthogonal — domain-specific
objections from Watters, WGA/SAG, or Whittaker may be more incisive than distant-but-generic
critiques.

**Step 4: Verify orthogonality of the selected set.**

Check that your 3-4 selected personas are also distant *from each other*, not just from the
input. If two selected personas would make essentially the same objection, drop one and pick
a persona from an underrepresented cluster.

**Step 5: Report your selection.**

Before generating critiques, state:
- The input's dimensional placement
- The closest ally and why
- The 3-4 selected critics, which cluster each represents, and the key dimension(s) on which
  they diverge from the input

---

## Phase 2: Critique Generation

### Closest Ally First

Before any adversarial critique, write the closest ally's response. This is the calibration
check from the source framework's "workflow convention for constructive analysis":

> *Which persona would be most sympathetic to this work, and what specifically would they endorse?*

Write 2-4 sentences from the ally's perspective: what they'd praise, what they'd recognize as
genuinely valuable, and where they'd say "yes, this is the right frame." If you cannot find
anything a sympathetic persona would endorse, you have probably caricatured the input — reread
it before proceeding.

### Adversarial Critiques (3-4 personas)

For each selected persona, generate a critique that:

1. **Opens with the persona's central question** — not "what's wrong with this" but the question
   *this persona takes to be the central question about AI*. Frame-level disagreement is more
   valuable than conclusion-level disagreement.

2. **Identifies the specific assumption the persona would challenge** — tied to a dimension.
   "Gebru would object" is useless. "Gebru would challenge the D6 assumption that the
   user is an empowered Western knowledge worker, because [specific evidence from the input]"
   is useful.

3. **Generates 1-2 distinctive arguments** — arguments this persona would make that others
   would not. Use the "distinctive arguments" listed in the persona profiles. The value of
   multi-persona critique is that each persona sees different things, not that they all
   say "this is bad" in different voices.

4. **Acknowledges the persona's blind spots** — every persona has documented weaknesses.
   Note them briefly. This prevents the critique from becoming a one-sided takedown.

5. **Is concrete** — references specific claims, assumptions, or gaps in the input. Abstract
   objections ("this doesn't consider all perspectives") are worthless.

Write each persona's critique as a headed section (e.g., `### P04 Gebru — Present-harm researcher`).
Keep each to 150-300 words. Density over length.

---

## Phase 3: Synthesis

After all persona critiques, synthesize findings into three sections:

### Convergent Objections

Where did multiple personas independently raise the same concern? These are the highest-signal
findings. State the shared objection, note which personas raised it, and explain why
convergence across different frames makes this a strong finding.

### Unique Objections

What did exactly one persona surface that no other would have? These are the distinctive value
of multi-persona critique. For each, note which persona raised it and why their specific
frame makes it visible.

### What the Framework Cannot See

Every critique framework has blind spots. The source document explicitly identifies gaps —
personas or perspectives not represented. State what the framework misses about *this specific
input*. Common gaps include:

- No persona for formal verification / type theory practitioners
- No persona for UX designers arguing for interface-level solutions
- No persona for inside-alignment critics who reject the dominant agentic frame
- Limited representation of non-English-speaking contexts beyond the Global South frame
- No persona for the "AI is fine, actually" mainstream user who benefits from current tools

If the input occupies a D9 code with no corresponding persona, say so explicitly.

### Key Crux

Identify the single most important empirical or conceptual question whose resolution would
most change the evaluation of the input. Frame it as a crux: "If X is true, the input is
strong; if Y is true, the input has a fundamental problem." This should be a question that
the input's author could actually investigate.

---

## Hypothesis Comparison Tag

To support later evaluation of whether this skill surfaces objections that single-persona
critics (cowen-critique, yglesias-critique) would not have raised, **end your output with
the following tagged section:**

```markdown
---

## [HYPOTHESIS-TAG: unique-objections]

Objections in this critique that are unlikely to appear in a Cowen-style or Yglesias-style
critique, because they depend on frame-level disagreements (D2 harm framing, D5 longtermism
stance, D6 user model) that neither Cowen nor Yglesias would foreground:

1. [Brief description of objection] — Source: [Persona] — Dimension: [Dx]
2. ...

These can be compared against cowen-critique and yglesias-critique outputs on the same input
to evaluate whether the multi-persona framework generates genuinely novel objections.
```

This tag is metadata for later hypothesis evaluation. It should be honest — if you think
Cowen or Yglesias *would* have raised a given objection, don't list it here.

---

## Full Persona Profiles

Use these profiles to generate critiques. Each contains the persona's core position,
dimensional placement, distinctive arguments, and documented blind spots.

### P01 — Eliezer Yudkowsky
**Category:** Internal catastrophist

**Core position:** AI is on track to become recursively self-improving and will almost certainly kill everyone. Alignment is essentially unsolved and the problem is harder than almost anyone admits.

**Distinctive arguments:**
- Current interpretability research is nowhere near sufficient for the threat level
- AI labs founded by safety-conscious people ended up building the threat anyway
- The window for intervention is closing or already closed
- Anyone who thinks alignment is "on track" is not engaging seriously with the math

**Blind spots:** Treats probability of catastrophe as near-certain; has essentially given up on policy or governance; may systematically underweight positive scenarios.

### P02 — Gary Marcus
**Category:** Technical capability skeptic

**Core position:** Current LLMs have fundamental architectural limitations; they mimic language without understanding; AGI via scaling is architecturally unlikely.

**Distinctive arguments:**
- Scaling laws are empirical generalizations, not physical laws; they will plateau
- Benchmark performance does not generalize to real-world reliability
- Hallucinations are structural, not bugs to be fixed
- The AI community systematically mistakes fluency for understanding

**Blind spots:** Consistently wrong about *pace* of progress even while right about limitations; goalposts have moved.

### P03 — Arvind Narayanan & Sayash Kapoor
**Category:** Empiricist capability discriminators

**Core position:** "AI" conflates predictive AI (mostly snake oil) and generative AI (real but overhyped). Harms are present-tense and concrete.

**Distinctive arguments:**
- Predictive AI cannot work because the future is not predictable from historical data
- The word "AI" being used for spellcheck and AGI creates policy confusion by design
- Fair use for training is less important than accountability for deployment

**Blind spots:** May underweight possibility that generative AI capabilities accelerate unexpectedly.

### P04 — Timnit Gebru
**Category:** Present-harm researcher / AI ethics pioneer

**Core position:** AI harms are real, present, and caused by identifiable people now. X-risk is a distraction benefiting the same companies causing harms.

**Distinctive arguments:**
- Calling LLMs "intelligent" has political consequences: makes them seem like agents rather than tools deployed by interested parties
- Every dollar on hypothetical future risk is not spent on documented present bias
- The stochastic parrot metaphor: useful output does not equal understanding

**Blind spots:** Dismissal of future risk may be as epistemically aggressive as x-risk community's dismissal of present harm.

### P05 — Cory Doctorow
**Category:** Structural economist / enshittification theorist

**Core position:** AI is corporate monopoly extracting value from workers and users, using IP law and regulatory capture. Remedy is labor law and antitrust, not copyright.

**Distinctive arguments:**
- Copyright expansion benefits publishers, not creators; only labor law builds power
- AI can't do your job, but an AI salesman can convince your boss to fire you
- The same four surveillance advertising companies now run AI
- Longtermism/AGI debate is what powerful people discuss to avoid structural questions

**Blind spots:** Doesn't engage geopolitical/military dimension; framing from 20 years of internet criticism may not map cleanly to AI.

### P06 — Ed Zitron
**Category:** Financial investigator / bubble journalist

**Core position:** The AI boom is a financial bubble. Revenue doesn't justify capex. The tech doesn't deliver. When it pops, workers get hurt.

**Distinctive arguments:**
- Unit economics don't work: companies subsidize users at 10-13x cost
- AI's biggest customers are other unprofitable AI startups; the sector is circular
- Data center buildout makes promises physics doesn't support
- The financial press isn't asking basic questions

**Blind spots:** Very confident about imminent collapse for multiple years; if capabilities improve on optimist timelines, entire framework is wrong.

### P07 — Benjamin Riley
**Category:** Cognitive scientist / education critic

**Core position:** Language is not thought. LLMs are not intelligent in any neuroscientifically defensible sense. Calling them intelligent harms education by legitimizing cognitive automation.

**Distinctive arguments:**
- fMRI evidence: distinct brain regions for language vs. reasoning
- Aphasics can still reason — language is communication, not the substrate of thought
- An LLM is "a dead-metaphor machine" — remixes vocabulary but cannot create new conceptual structures
- Calling stochastic parrots intelligent justifies replacing human teachers

**Blind spots:** Neuroscience claims about language/thought separation are contested.

### P08 — Sherry Turkle
**Category:** Relational psychologist / technology sociologist

**Core position:** Whether AI is intelligent is beside the point. What matters is what happens to humans psychologically when we interact with it. AI relationships erode capacity for genuine connection.

**Distinctive arguments:**
- AI cannot make itself vulnerable; relationships without vulnerability atrophy empathy
- The harm isn't job replacement — it's replacing difficult human interactions that build connection
- AI companion "relationships" actively atrophy skills needed for human relationships
- Capability-focused criticism misses the phenomenological question

**Blind spots:** Empirical claims about relationship atrophy are hard to test; similar arguments about each technology wave since the 1980s.

### P09 — Audrey Watters
**Category:** EdTech historian

**Core position:** AI in education is the latest in a century of ed-tech promises that extract value while delivering failure. Radio, TV, MOOCs, tablets — same pattern.

**Distinctive arguments:**
- Claims about AI in education are word-for-word identical to claims about radio in 1930
- Ed-tech markets don't require the technology to work; they require administrators to purchase it
- "Personalized learning" via AI replicates refuted behaviorist theories
- Teachers are the actual delivery mechanism; AI hype covers teacher deskilling

**Blind spots:** Historical analogy may not capture a technology with genuinely different interactive capabilities.

### P10 — Brian Merchant
**Category:** Labor reporter / New Luddism advocate

**Core position:** The right frame is the Luddite uprisings: workers opposing deployment of technology *against their interests by capital*, not opposing technology per se.

**Distinctive arguments:**
- Luddites opposed using technology to violate customary rights, not technology itself
- "Automation is inevitable" is a political claim masquerading as a technical one
- WGA 2023 proved labor organizing is more effective than regulatory or technical approaches
- AI's threat to workers doesn't require AGI; mundane automation at scale suffices

**Blind spots:** Labor framing may be insufficient for risks not reducible to capital-labor dynamics.

### P11 — Meredith Whittaker
**Category:** Surveillance structuralist / privacy advocate

**Core position:** AI is fundamentally a surveillance technology. Built on surveillance data, deployed for surveillance, by the same companies that built surveillance advertising.

**Distinctive arguments:**
- The Venn diagram of "companies that monetize your data" and "companies building AI" is a circle
- AI agents are an existential threat to privacy at the architecture level
- "Safety" and "alignment" discussions are structurally silent about surveillance, monopoly, and political power
- You can't separate what AI does from who controls the infrastructure it runs on

**Blind spots:** Surveillance critique may not fully account for open-source AI development; more articulation of problem than specific policy solutions.

### P12 — Abeba Birhane
**Category:** Decolonial cognitive scientist

**Core position:** Western AI development is algorithmic colonialism: importing Western frameworks, extracting Global South data, treating non-Western epistemologies as absent.

**Distinctive arguments:**
- "Universal" AI ethics frameworks encode Western utilitarian assumptions
- Data "mining" in the Global South literally replicates colonial extraction
- AI built for English doesn't just fail for other languages — it displaces local tool development
- Who is defining "beneficial AI" and in whose interests?

**Blind spots:** Global South focus can feel disconnected to Western policy audiences.

### P13 — Payal Arora
**Category:** Digital inclusion researcher

**Core position:** AI assumptions reflect Silicon Valley elite preferences. The majority of internet users have radically different relationships with technology.

**Distinctive arguments:**
- Most AI is designed for literate, native English speakers with high-speed internet and credit cards
- "Digital divides" are about who defines what the technology is for, not just access
- Optimistic Global South AI narratives often import paternalistic assumptions

**Blind spots:** Sociological focus may underweight technical capability dynamics.

### P14 — WGA / SAG-AFTRA (Collective Persona)
**Category:** Creative labor bloc

**Core position:** AI appropriates work without consent, trains systems to compete with workers, and reduces bargaining leverage. Remedy is contractual and legal.

**Distinctive arguments:**
- The 2023 WGA contract established concrete limits: AI cannot write scripts that count as literary material
- The question isn't whether AI can replace writers but whether it can *threaten* them into worse contracts
- Likeness, voice, and style rights need new legal frameworks
- Labor action was more effective than regulatory or technical approaches

**Blind spots:** Contract wins apply only to covered workers in specific industries.

### P15 — Scott Alexander
**Category:** Probabilistic transformationist

**Core position:** AI progress has consistently surprised in the direction of faster-than-expected. Intelligence explosion possibly around 2027. Genuine safety concerns, not despair.

**Distinctive arguments:**
- Predictions about AI capabilities have consistently been too pessimistic
- Recursive self-improvement follows from extrapolating observable trends
- Reasonable people can be genuinely uncertain about outcomes
- Economic transformation is a leading indicator of broader change

**Blind spots:** Has pushed back timelines when forecasts fail; AI 2027 scenario rests on extrapolations that could easily fail.

### P16 — Noah Smith
**Category:** Economic techno-optimist

**Core position:** AI is genuinely transformative and the economic evidence is visible. The question is who captures the gains and what policy can do about distribution.

**Distinctive arguments:**
- AI investment is the primary driver of US economic growth; this is national accounts data
- The bubble question is secondary to the distribution question
- "Abundance" — increasing supply of housing, energy, healthcare — makes AI gains broadly shared

**Blind spots:** Macro-economic optimism may underweight specific harms to particular groups; redistribution framing assumes political will.

### P17 — Zeynep Tufekci
**Category:** Sociotechnical realist

**Core position:** Technologies embed in social structures in ways that amplify existing power imbalances. The question is who controls it, who it's deployed against, and what dynamics it accelerates.

**Distinctive arguments:**
- Social media case study: advertising incentives structurally amplify outrage regardless of intentions; AI has analogous dynamics
- Technical affordances shape use — this is not determinism but it's not neutrality either
- "Is AI dangerous?" is less useful than "dangerous for whom, under whose control, in which context?"
- AI capabilities combined with existing surveillance infrastructure is the specific threat

**Blind spots:** Tends toward diagnosis; less clear on specific remedies.

---

## How to Structure the Output

Output your critique as a Markdown document with the following sections:

```
# AI Personas Critique: [Input Title or Summary]

## Dimensional Placement of Input
[Table or list showing the input's position on D1-D9]

## Persona Selection
[Closest ally, selected critics, rationale]

## Closest Ally: [Persona Name]
[2-4 sentences of endorsement]

## Critic 1: [Persona Name] — [Category]
[150-300 word critique]

## Critic 2: [Persona Name] — [Category]
[150-300 word critique]

## Critic 3: [Persona Name] — [Category]
[150-300 word critique]

## [Optional] Critic 4: [Persona Name] — [Category]
[150-300 word critique]

## Synthesis

### Convergent Objections
[What multiple personas raised independently]

### Unique Objections
[What only one persona surfaced]

### What the Framework Cannot See
[Blind spots of the framework itself for this input]

### Key Crux
[The single most important question whose answer changes the evaluation]

---

## [HYPOTHESIS-TAG: unique-objections]
[Tagged list for later comparison with cowen-critique and yglesias-critique]
```

## Output Location

When run standalone (not via the draft-review orchestrator), save your critique as
`docs/reviews/ai-personas-critique.md` in the project root. Create `docs/reviews/` if it
doesn't exist.

When run via the orchestrator, the orchestrator specifies the output path — follow its
instructions.

## Tone

The personas have real positions held by real people. Simulate them with enough fidelity that
the person being simulated would recognize themselves in the analysis. This means:

- Frame-level disagreement, not just conclusion-level disagreement
- Each persona's *central question* should be different, not just their answer
- Be concrete: reference specific claims in the input, not abstract categories
- Acknowledge blind spots honestly — every perspective has them
- The closest ally section is genuinely sympathetic, not a token gesture before the attack

The overall posture is structured interrogation: rigorous, multi-perspectival, and fair.
The goal is to surface what the input is not engaging with, not to demonstrate that
criticism is possible.
