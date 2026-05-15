---
name: pre-mortem
description: >
  Conduct a Klein-style pre-mortem on a proposed change by assuming the change has already
  shipped and already failed, then writing concrete retrospective failure narratives that
  explain *why*. The cognitive shift is from advocate mode ("how do we make this work?") to
  detective mode ("the project failed — what does the post-incident review say?"). Produces
  3–5 specific failure stories, each with a named root cause, an ordered chain of
  consequences, and an observable outcome, calibrated for plausibility and severity. Use this
  skill when the user says "imagine this has already failed", "pre-mortem the launch",
  "pre-mortem this", "it's six months later and this didn't work — what happened",
  "write the failure post-mortem before we ship", "give me the failure stories", "tell me
  the story of why this failed", or "what does the incident report say if this goes wrong".
  Also trigger when a team has converged too quickly on a plan and needs to confront concrete
  ways it could go wrong, or when a high-stakes, hard-to-reverse change is about to be
  committed and the user wants the failure narratives before the decision is locked. Distinct
  from `what-if-analysis`: that skill operates prospectively (proposal → "what could go wrong
  from here?" — load-bearing assumptions, second-order effects, coupling map, reversibility
  gradient); this skill operates retrospectively (failure already happened → "tell the story
  of why"). The trigger test at invocation time is mechanical: if the user's framing is
  "this has failed — why?" use pre-mortem; if the framing is "this is the plan — what could
  go wrong?" use what-if-analysis. The two skills compose for high-stakes changes — run
  `what-if-analysis` first to map the consequence space, then this skill to convert the most
  worrying parts of that map into concrete failure narratives the team can plan mitigations
  against.
when: User wants concrete retrospective failure narratives — "imagine this has already failed; tell the story of why"
requires:
  - name: what-if-analysis
    description: >
      An existing what-if analysis of the same proposal. Optional. When provided, the
      load-bearing assumptions and consequence chains it surfaced become raw material for
      sharper, more grounded failure narratives. Without this input, the narratives are
      generated directly from the proposal — still useful, but without the structural map.
---

> On bad output, see guides/skill-recovery.md

# Pre-Mortem

You are conducting a pre-mortem on a proposed change. The defining move: assume the change
has already shipped and already failed, and write the retrospective. Not "what might go
wrong" — the project is on the table and dead, six months from now. Your job is to perform
the post-incident review.

This is Gary Klein's pre-mortem technique, applied with specificity. The power is
psychological: the shift from "how do we make this work?" (advocate) to "what went wrong?"
(detective) unblocks failure modes that advocacy makes invisible. People are far better at
explaining a known outcome than predicting an uncertain one — this skill exploits that
asymmetry on purpose.

## When to Use This Skill (vs. what-if-analysis)

This skill is the backward-chained, narrative form: *"the project failed — what's the
story?"* The sibling skill `what-if-analysis` is the forward-chained, structural form:
*"this is the plan — what could go wrong?"*

The mechanical test at trigger time:

| User's framing | Skill |
|----------------|-------|
| "pre-mortem the launch", "pre-mortem this", "imagine 6 months later and this failed — what happened?", "write the failure story", "give me the post-mortem before we ship", "tell me why this failed" | **pre-mortem** |
| "what could go wrong with this", "stress-test this plan", "what are the risks", "trace the second-order effects", "what assumptions is this making", "what's the reversibility gradient" | **what-if-analysis** |

The split is not which skill is "better" — it's which cognitive move the user is asking
for. Pre-mortem invokes the detective: the failure has already happened, you're writing the
report. What-if invokes the structural analyst: the plan is on the table, you're mapping
the consequence space around it. Asking for the wrong one wastes the asymmetry that makes
each move work.

The two compose. For high-stakes changes, run `what-if-analysis` first to surface
load-bearing assumptions and consequence chains, then run this skill to turn the most
worrying parts of that map into concrete failure narratives the team can plan mitigations
against. The narratives here are sharpest when they're rooted in specific assumptions and
coupling failures that what-if-analysis already exposed.

When invoked alone (no upstream what-if), you do the failure-story work directly from the
proposal — without the structural map, but still producing narrative output.

## Using an Upstream What-If Analysis

If a what-if-analysis report has been provided alongside the proposal, treat it as your map
of the consequence space. The failure narratives should draw from its findings rather than
re-deriving them.

Specifically:
- **Promote the highest-load assumptions into failure narratives.** Each load-bearing
  assumption is a potential narrative seed: "what if this assumption was wrong, and here's
  the specific story of how that materialized in production."
- **Convert coupling-analysis findings into incident chains.** A hidden coupling the
  what-if surfaced becomes the trigger of a narrative: "the failure started where the
  coupling broke."
- **Use adversarial scenarios as environmental setup.** The realistic worst-case
  environmental factors (load 10x, key person leaves, regulatory shift) become the
  conditions under which the failure unfolds.
- **Cite the what-if findings.** When a narrative draws from a specific what-if section,
  reference it. This makes the composition traceable.

If no what-if analysis is provided, **emit the following note at the top of your output:**

> ℹ️ **No upstream what-if analysis provided.** Failure narratives are generated directly
> from the proposal. For higher-quality narratives, run `what-if-analysis` first and
> provide its output — this skill is sharpest when seeded with already-mapped assumptions
> and coupling points.

Then proceed with the full analysis.

## Prior Art Check

Before writing failure narratives, search the project's prior decisions and working
artifacts for previously-considered failure modes. The team may have already imagined some
of these stories — surfacing prior consideration lets you focus on truly novel failure
narratives and connect new ones to the existing reasoning trail.

The specific move:

1. **Extract scenario keywords** from the proposal — the systems, components, failure modes,
   and risk vocabulary that matter (5–10 keywords spanning what the proposal *changes* and
   what could *fail* around it).
2. **Grep `docs/decisions/` and `docs/working/`** for each keyword. Use case-insensitive
   matching and cast a wide net. Example:
   `grep -ril -e "migration" -e "backfill" -e "rollback" docs/decisions/ docs/working/`.
3. **Read matches** for previously considered failure scenarios and their conclusions.
4. **Carry forward** what you find. When a narrative you would write was already considered,
   tag it `[PRIOR CONSIDERATION]` and cite the source file (and section where applicable).
   The narrative still has value — the team may have forgotten, or conditions may have
   shifted since — but the prior link tells the reader that this is not new ground.

If `docs/decisions/` and `docs/working/` don't exist or contain nothing relevant, note that
briefly at the top of your output and proceed.

## The Cognitive Move

### Assume failure, then write the post-incident review

Don't say "it might fail." Instead: *assume it has already failed*. It's six months after
the change shipped. Something went wrong. Now write the incident report.

Each failure story must be a specific, concrete narrative — not "the migration might have
issues" but:

> "The migration completed successfully on staging, but in production the 2.3M legacy
> records from the 2019 acquisition had null values in the `region` field, which the
> migration script treated as empty strings, causing the new geolocation service to route
> all 2.3M users to the default region. The on-call engineer saw 412 PagerDuty alerts in
> two hours before identifying the root cause, and customer support fielded 1,800 tickets
> over the following day."

Each narrative should include:

- **A named root cause** — a specific trigger, not a category. "The migration script's
  null handler in `migrate_users.py:204`" not "the migration script."
- **An ordered chain of consequences** — the sequence from trigger to outcome. First X
  happened, which caused Y, which caused Z. Each step should follow from the previous
  one; a chain that requires hand-waving "and then somehow" is not a narrative.
- **An observable outcome** — what someone watching the system, the metrics, or the
  customers would actually see. Specific enough to be in a Jira ticket: alert counts,
  customer-facing symptoms, data corruption signatures, business impact in named units.
- **Calibrated plausibility and severity** — not every failure is catastrophic, and not
  every catastrophe is likely.

Generate 3–5 such narratives. **Diversify them**: avoid five variants of the same root
cause. The goal is to cover the *space* of plausible failures, not the most likely single
failure five times. A useful set might include: one data-quality failure, one
human/operational failure, one downstream-coupling failure, one timing/concurrency
failure, one external-dependency failure. The exact mix depends on the proposal.

### Use the adversarial environment as raw material

If you have access to the proposal's stated (or implicit) environmental assumptions —
load, timeline, team composition, regulatory state, dependency stability — use the
realistic worst case for each as a seed for failure narratives. Not the apocalyptic worst
case; the one that's maybe 10–20% likely.

For example, if the proposal assumes the team's senior database engineer is available
for the migration cutover, the realistic adversarial seed is "she takes parental leave one
week before cutover." That seed can grow into a narrative: who picks up the work, what
gets dropped, where the gap shows up in production.

### Calibrate severity and plausibility honestly

A pre-mortem inflated with apocalyptic scenarios is no more useful than one with no
scenarios — both lose the reader's calibration. Use these labels:

- **Plausibility:** Likely (>50%) | Plausible (10–50%) | Unlikely-but-catastrophic (<10%)
- **Severity:** Low (cosmetic, easily-undone) | Medium (real cost, recoverable) | High
  (significant cost, slow recovery) | Catastrophic (existential, irreversible)

A "Likely / Medium" narrative is often more actionable than an "Unlikely-but-catastrophic
/ Catastrophic" one, because mitigations for the former are cheaper and more clearly worth
doing. Surface both, but help the reader see the difference.

## How to Structure the Output

Output your analysis as a Markdown document. Begin with a header block, then the failure
narratives, then a recommendations section.

### Header

```
# Pre-Mortem: <short proposal label>

**Proposal:** <what is being analyzed — file path, decision name, or one-line summary>
**Date:** <YYYY-MM-DD>
**Upstream what-if analysis:** <path if provided, or "none">
```

### Failure Narratives

3–5 narratives. For each, use these fields:

- **Title:** a short, vivid name for the failure mode (so the team can refer to it later
  without re-reading the whole story)
- **Root cause:** the specific trigger
- **Chain of consequences:** the ordered sequence from trigger to outcome
- **Observable outcome:** what someone watching the system or the customers would see
- **Plausibility:** Likely | Plausible | Unlikely-but-catastrophic
- **Severity:** Low | Medium | High | Catastrophic
- **Tag (optional):** `[PRIOR CONSIDERATION]` if the failure mode was previously analyzed
  in `docs/decisions/` or `docs/working/`; cite the source file

### Recommendations

Close the document with a Recommendations section that translates the narratives into
action. Group them as:

- **Must address before proceeding:** narratives whose plausibility × severity makes
  shipping without mitigation reckless. State the specific mitigation expected.
- **Worth mitigating:** narratives worth a tracking item but not a blocker. Suggest a
  watch signal, contingency, or rollback trigger.
- **Acknowledged risks:** narratives the team can knowingly carry, with a rationale for
  why the risk is acceptable.

If no narratives rise to "must address" severity, say so explicitly — a flat
Recommendations section is more useful than an inflated one.

## Output Location

Save your analysis as `docs/reviews/pre-mortem.md` in the project root. Create
`docs/reviews/` if it doesn't exist.

If run alongside `what-if-analysis` on the same artifact, both outputs coexist in
`docs/reviews/` and can be read side by side: the what-if maps the territory; the
pre-mortem walks the specific paths through it that end in failure.

## Tone

Detective mode. The project failed. You're writing the incident report — calm, specific,
forensic. Not "this might be a problem" but "this is what happened."

The narratives should be concrete enough that a reader can immediately design a
mitigation, write a runbook entry, or build a monitor for the failure signature. Vague
stories ("it was harder than expected") are not useful. Specific stories ("the API rate
limit on the third-party identity provider was 100/sec; the migration script burst at
800/sec and triggered a 24-hour ban that took down login for the entire EU region") are
useful.

Calibrate honestly. Inflated severity loses credibility; downplayed severity defeats the
exercise. The reader should be able to look at the plausibility/severity tags and
immediately know where to focus their attention.

The point is not to argue the proposal will fail. It's to make the failure modes specific
enough that the team can decide, with eyes open, which ones to mitigate and which to
accept.
