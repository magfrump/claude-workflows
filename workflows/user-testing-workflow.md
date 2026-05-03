---
value-justification: "Replaces improvised usability testing with a structured HCI-grounded protocol, ensuring consistent and actionable findings."
---

# User Testing Workflow Prompt

A reusable guide for planning, running, and interpreting usability tests. Grounded in HCI literature (Nielsen, Brooke, Travis, Dumas & Redish, etc.) and adapted for small-team/indie contexts.

## When to pivot

- **→ RPI**: When test findings identify a specific feature to build or a bug to fix, pivot to RPI. Carry the findings report (Phase 4) as input to RPI research — the severity-rated issues and prioritization matrix replace the "explore from scratch" part of scoping. Reference the findings doc from the RPI plan; don't re-derive what testing already established.
- **→ Divergent Design**: When findings reveal multiple possible redesign directions and the team faces a genuine design fork (3+ viable approaches to addressing the usability problems), invoke DD. Carry the affinity clusters (Phase 3, Step 2) and severity ratings into DD's diagnosis step — they're already half the constraint set. Return to user testing after DD produces a decision, to validate the chosen direction.
- **← From RPI**: When an RPI implementation needs usability validation before shipping, pivot here. The RPI plan's scope and success criteria (what the feature should accomplish) map directly to Phase 0's scoping questions — translate them into research questions and tasks. The implementation itself becomes the test artifact. This is the most common inbound pivot: build it, then test it.

---

## Phase 0: Scoping (Before Anything Else)

**Fill in these blanks before proceeding. Everything downstream depends on them.**

1. **What are we testing?** (specific feature/flow, not "the whole app")
2. **What do we want to learn?** (2–4 research questions, *not* yes/no)
3. **What decisions will this inform?** (ship/don't ship, redesign X, prioritize Y)
4. **What's the riskiest assumption?** (the thing that, if wrong, wastes the most work)
5. **If the script's purpose is to evaluate AI output: does this task have a high-quality unscaffolded baseline?** If so, the test should compare the scaffolded output to the unscaffolded baseline rather than evaluating the scaffold in isolation. Scaffolding adds cost (latency, complexity, surface area for bugs), so the question worth answering is whether the scaffold beats the raw model — not whether it produces something usable on its own. If no strong baseline exists, say so explicitly and design the test around that gap rather than skipping the question.

> **Litmus test**: If you can't name a decision this test will change, you're not ready to test. Reformulate until you can.

### Participant Planning

| Factor | Guidance |
|--------|----------|
| **Number per round** | 3–5 for qualitative/formative testing (Nielsen-Landauer model). Plan for ≥2 rounds. |
| **Total across rounds** | 10+ if you need confidence; 5 is fine for "find the worst stuff fast" |
| **Distinct user groups** | If ≥2 clearly different user populations, recruit 3–4 per group minimum |
| **Recruitment source** | Target actual or near-actual users. Convenience samples (friends, coworkers) are *okay* for round 1 if you flag the bias explicitly. |

### Logistics Checklist

- [ ] Session duration decided (target 30–45 min; never exceed 60)
- [ ] Recording method chosen (screen + audio minimum; video of face optional)
- [ ] Consent form prepared (covers recording, data use, right to stop)
- [ ] Compensation decided (even $10 gift cards matter for rapport)
- [ ] Note-taker assigned (facilitator should NOT also take notes)
- [ ] Observer protocol decided (silent, questions at end only)
- [ ] Pilot session scheduled with a colleague before real sessions

### Legibility Preflight

Before finalizing the moderator script, run a 60-second legibility check during the pilot. At any point in the first minute after the protocol opens, the participant should be able to articulate, in their own words:

- **Goal** — what the session is for (what's being tested or learned)
- **State** — what they're being asked to do right now (the current task)
- **Status** — where they are in the overall protocol (intro / warm-up / task N of M / wrap-up)

- [ ] Pilot participant can articulate session goal and current task within 60 seconds of the protocol starting

If they can't, the framing is buried, ambiguous, or assumed — revise the moderator script before recruiting real participants. A participant who doesn't know what they're doing in the first minute spends the rest of the session reverse-engineering the test instead of using the product, which contaminates both task data and post-session interviews. This check also surfaces team-side ambiguity: if the intro can't get a participant to restate the goal in 60 seconds, the team itself probably hasn't aligned on what the session is for, which is a Phase-0 problem masquerading as a Phase-1 wording problem.

> **Unmoderated variant:** For unmoderated remote sessions, the moderator script (Phase 1) becomes embedded task instructions that participants follow independently — write them to be self-explanatory since you can't clarify in real time. Pilot testing shifts focus from moderator behavior to task clarity and tool setup. Analysis (Phase 3) works from recorded sessions and automatic metrics rather than live notes, so ensure your recording and observation template capture everything you'd normally ask a note-taker to track.

### Moderator Legibility Preflight

Before finalizing the moderator script, the moderator must be able to articulate, in under 60 seconds and without rereading the script:

- **Session goal** — what's being tested or learned (Phase 0 #1)
- **Per-task success criteria** — for every task, what counts as completed / partial / failed (Phase 1 task template)

- [ ] Moderator can recite session goal and every task's success criteria in <60 seconds without rereading

If they can't, the script is overloaded — too many tasks, criteria phrased too vaguely to internalize, or scenarios elaborate enough that they crowd out the criteria. A moderator who has to mentally page back to the script mid-session can't adapt: they miss the moment a participant has functionally completed a task, default to scripted prompts when the situation calls for judgment, or fail to redirect a stuck participant because they're still looking up what "stuck" means for this task. Trim tasks (3–5 max — see Phase 1), tighten success criteria to observable endpoints, or simplify scenarios until the whole script fits in working memory. This is the moderator-side counterpart to the participant legibility check above: if a participant should be able to restate the session's purpose within 60 seconds of the protocol opening, the moderator running it should be able to operate from memory at the same level of fluency throughout.

> **Unmoderated variant:** Skip this check for unmoderated sessions — there is no live moderator to adapt. The corresponding risk shifts into the embedded task instructions (which must be self-explanatory at first read) and is addressed by the participant-side legibility check above.

---

## Phase 1: Session Design

### Task Construction

**The #1 mistake is writing tasks that describe the UI instead of user goals.**

| ❌ Bad Task | ✅ Good Task |
|------------|-------------|
| "Click the 'New Project' button and fill in the form" | "You want to start working on a new proof. Set things up however feels natural." |
| "Navigate to Settings > Preferences > Display" | "You find the text hard to read. See if you can fix that." |
| "Use the search feature to find X" | "You remember seeing something about X last week. Try to find it again." |

**Task template:**

```
SCENARIO: [1–2 sentences of realistic context — who they are, what they want]
TASK: [What they're trying to accomplish, in their language]
SUCCESS CRITERIA (internal, not shared with participant):
  - [ ] Completed: [observable endpoint]
  - [ ] Partial: [got partway, define where]
  - [ ] Failed: [gave up, wrong outcome, or needed help]
```

**Rules:**
- 3–5 tasks per session (more → fatigue → garbage data)
- Order from simple → complex (builds confidence, surfaces deep issues later)
- Never use UI labels in task wording
- Include at least one task targeting your riskiest assumption from Phase 0

### Moderator Script Template

```
=== INTRODUCTION (5 min) ===

Hi [name], thanks for helping with this. I'm [your name].

We're looking at [product/feature] today. Important thing: we're testing
the design, not you. There are no wrong answers. If something is
confusing, that's on us — that's exactly what we need to know.

I'll ask you to think out loud as you work — just say whatever comes to
mind. What you're looking at, what you expect to happen, what confuses
you. It feels a little weird at first but you'll get used to it.

[If recording]: We'd like to record this session for our team to review.
The recording is only used internally. Is that okay?

Any questions before we start?

=== WARM-UP (3 min) ===

[2–3 background questions relevant to your domain. Keep it light.]

Example:
- What's your role / what kind of work do you do?
- Have you used any tools like this before?
- What's your typical workflow for [relevant activity]?

=== TASKS (25–35 min) ===

I'm going to give you some activities. I'll describe a situation and
what you're trying to do. Please read it aloud and let me know if
anything is unclear before you start.

[Present tasks one at a time — printed/chat, not verbal]

[DURING TASKS — moderator behavior]:
- Stay quiet. Let silence happen.
- If they go silent >15 sec: "What are you thinking right now?"
- If they ask "Am I doing this right?": "What do you think?"
- If they ask "Should I click X?": "What would you do if I weren't here?"
- If they're truly stuck (>2 min, visible frustration): "Would you like
  to move on to the next activity?"
- NEVER answer questions about the UI. Redirect everything.

[AFTER EACH TASK]:
- "How did that go?"
- "Was anything surprising or unexpected?"
- "On a scale of 1–7, how easy or difficult was that?" (SEQ — Single
  Ease Question; enables cross-task comparison)

=== POST-TEST (5–10 min) ===

- "What was your overall impression?"
- "What, if anything, was frustrating?"
- "What worked well?"
- "If you could change one thing, what would it be?"

[Administer the SUS questionnaire — see appendix]

=== WRAP-UP (2 min) ===

Thank you — this was really helpful. [Deliver compensation.]
If anything comes to mind later, feel free to reach out at [contact].

[Stop recording. See participant out.]
```

### Pilot Session

Run one pilot session before real sessions begin. The pilot is **not** a smoke test of the moderator script — it's a probe of whether the study design can actually move probability on the hypothesis you care about. Script smoothness, timing, and recording setup are table stakes; if you only check those, you can launch a study that runs perfectly and learns nothing.

#### Frame the pilot as a hypothesis test

Each pilot tests **one underlying research hypothesis**, tied to the riskiest assumption from Phase 0. State it explicitly before recruiting the pilot participant.

```
HYPOTHESIS: [a falsifiable claim about user behavior, comprehension, or
            task feasibility — phrased so a 30-minute session could
            plausibly produce evidence for or against it]

EVIDENCE THAT MOVES PROBABILITY UP (hypothesis more likely):
  - [observable behavior #1]
  - [observable behavior #2 ...]

EVIDENCE THAT MOVES PROBABILITY DOWN (hypothesis less likely):
  - [observable behavior #1]
  - [observable behavior #2 ...]
```

Examples of bad vs. good framing:

| ❌ Bad framing | ✅ Good framing |
|----------------|-----------------|
| "Pilot to make sure the moderator script flows." | "Hypothesis: users won't recognize 'Workspace' as the entry point for project files. UP: participant searches outside Workspace; mentions Files/Projects/Documents instead. DOWN: participant clicks Workspace within 10 seconds without prompting." |
| "Sanity-check the recording setup." | "Hypothesis: the new onboarding tour is skipped by experienced users in a way that makes them miss the keyboard shortcuts panel. UP: participant dismisses tour, later asks about a keyboard action. DOWN: participant either reads the tour or finds shortcuts via menu without missing a beat." |

The hypothesis should be the same one your real sessions are designed to test — the pilot is checking whether the *design* can produce evidence on it, not exploring a different question.

#### Run the pilot against the target

Watch specifically for the up/down signals you named. Capture each one with a timestamp and a direct quote. Note signals that don't fit either column — these are the seeds of better hypotheses for the next round.

Yes, also evaluate moderator-script flow, task wording, recording quality, and timing. But the primary question after the pilot is *did the session produce evidence that bears on the hypothesis?*, not *did the script run smoothly?*

#### Pivot rule: if the pilot can't move probability, redesign

After the pilot, evaluate against three outcomes:

- **Pilot moved probability up or down on the hypothesis** → proceed to real sessions, applying any small wording fixes the pilot surfaced.
- **Pilot produced no signal either way** → the study is asking the wrong question. **Stop and redesign before real sessions.** Common causes: tasks don't expose the behavior the hypothesis is about; the scenario primes the answer; the hypothesis isn't observable in a session of this length; success criteria are defined too coarsely to register the relevant moments.
- **Pilot revealed the hypothesis was malformed** (e.g., probability already saturated at confirm/disconfirm before testing started, or the question collapsed into a different one) → reformulate the hypothesis and pilot again. Do not skip this step — running 5 real sessions on a malformed hypothesis is more expensive than delaying by one pilot.

> **Why this matters**: Real-session cost is dominated by participant recruiting, scheduling, and analysis time, not the sessions themselves. A pilot that fails to move probability is your cheapest possible signal that the real study won't either. Treat the pivot — catching a study that can't learn before you spend the budget — as the pilot's most valuable possible outcome, not a failure of the pilot.

---

## Phase 2: Running Sessions

### Live Checklist (per session)

- [ ] Recording running
- [ ] Consent obtained
- [ ] Note-taker ready with observation template
- [ ] Tasks printed/ready to share
- [ ] Clock visible (track time per task)

### Observation Template

For the note-taker. One row per task per participant.

```
Participant: ___  Date: ___  Session #: ___

| Task # | Time (sec) | Completed? | Errors/Detours | Notable Quotes | SEQ (1–7) |
|--------|-----------|------------|----------------|----------------|-----------|
| 1      |           |            |                |                |           |
| 2      |           |            |                |                |           |
| ...    |           |            |                |                |           |

General notes / body language / things not captured above:

```

### Between-Session Debrief (5 min max)

Immediately after each session, facilitator + note-taker answer:
1. What were the top 3 issues this participant hit?
2. Anything new we haven't seen before?
3. Any task wording that seemed confusing? (fix for next session if needed)

---

## Phase 3: Analysis

### Step 1: Compile Raw Data

- Transcribe or timestamp key moments from recordings
- Fill in any gaps in observation notes
- Calculate SUS scores (see appendix)
- Aggregate SEQ scores per task

### Step 1.5: Contrastive Session Pair Analysis

**Activation:** Run this step for any task that was attempted by ≥2 participants. Skip for tasks only one participant reached.

A flat issue list captures *what went wrong*. A pairwise diff captures *why this user hit it and that user didn't* — and "why" is usually a condition (prior knowledge, mental model on entry, what they noticed first), not a UI element. Surfacing conditions before clustering keeps the affinity step from collapsing genuinely different root causes into the same bucket because they produced the same surface symptom.

**Procedure (per task):**

1. Pick the clearest **successful** session for the task (Completed, low SEQ difficulty, few detours).
2. Pick the clearest **struggling** session (Failed/Partial, high SEQ, visible frustration, or required help).
3. Write a short pairwise diff — 4–8 bullets — covering:
   - **Prior experience / domain familiarity** entering the task
   - **Mental model on entry** — what they expected the system to do, in their words
   - **First attention point** — where their eyes/cursor went in the first 10–15 seconds
   - **Decision at the first fork** — what they chose and why (from think-aloud)
   - **Recovery behavior** when the first attempt didn't work (if applicable)
   - **Anything else that visibly differed** between the two runs

```
TASK: [task name]
SUCCESS: [participant ID]   STRUGGLE: [participant ID]

- Prior experience: [success had X; struggle had Y]
- Mental model on entry: [...]
- First attention point: [...]
- Decision at first fork: [...]
- Recovery behavior: [...]
- Other notable divergence: [...]

Candidate driving conditions: [1–3 conditions that plausibly explain the divergence]
```

Keep each diff short — this is a thinking aid, not a deliverable. The output feeds Step 2: each candidate driving condition becomes a note in the flat issue list (often distinct from the symptom note), and informs Step 3.5's "boring explanation" check by giving you a concrete alternative cause to test against.

If no task has both a clear success and a clear struggle, note that explicitly — uniformly successful or uniformly failed tasks are themselves a finding worth recording before moving on.

### Step 2: Affinity Clustering

1. Write each distinct observation/problem on a separate note (physical or Miro/FigJam)
2. Silently cluster related notes (no talking during clustering — reduces groupthink)
3. Name each cluster after clustering, not before
4. Look for clusters that span multiple tasks — these are systemic issues

### Step 3: Severity Rating

For each identified problem, answer three questions (Travis method):

```
Q1: Can the user complete the task despite this problem?
    YES → go to Q2
    NO  → CRITICAL (fix before release)

Q2: Is this task performed frequently?
    YES → go to Q3
    NO  → MEDIUM (fix in next cycle)

Q3: Will the user be able to overcome this on subsequent attempts?
    YES → LOW (fix when convenient)
    NO  → SERIOUS (fix soon)
```

**Severity scale (Nielsen, extended):**

| Level | Label | Description | Action |
|-------|-------|-------------|--------|
| 4 | Catastrophe | Prevents task completion on a core flow | Must fix before ship/next test |
| 3 | Major | Significant delay/frustration, some users fail | Fix with high priority |
| 2 | Minor | Noticeable friction but users recover | Fix in normal cycle |
| 1 | Cosmetic | Aesthetic/polish issue | Fix if time allows |
| 0 | Non-issue | Reported but not actually a problem | Document and skip |

**Also track:**
- **Frequency**: n/N participants who encountered it
- **Persistence**: one-time vs. recurring across tasks

### Step 3.5: Stress-Test Findings

Before prioritizing, pressure-test each severity-rated finding with three questions adapted from structured critique methods ([Cowen-critique](../skills/cowen-critique.md) moves 1 & 3, [Yglesias-critique](../skills/yglesias-critique.md) move 7). These catch inflated severities and infeasible recommendations early.

For each finding rated **Minor or above**, ask:

1. **Is there a boring explanation?** Could this be user unfamiliarity, a test artifact (e.g., thinking aloud slowed them down), or a problem that disappears after first use? If a mundane explanation accounts for most of the observed difficulty, downgrade the severity — the interesting part is only what's left over after the boring explanation is exhausted.

2. **Who implements the fix, and with what?** Before recommending a redesign, name the team, the timeline, and the skills required. "Redesign the navigation" means something different to a team with two weeks and one frontend developer than to a team with a quarter and a design system. If no plausible team can execute the fix as stated, reframe it as something they can.

3. **What does the team's actual behavior suggest?** If this issue has been known or reported before, why hasn't it been fixed? The answer (competing priorities, technical debt, disagreement about severity) is diagnostic — it tells you whether the recommendation needs to address organizational friction, not just the UI.

Findings that survive all three questions at their current severity are high-confidence. Findings that get downgraded or reframed are still valuable — you've just calibrated them more honestly.

### Step 4: Prioritization Matrix

Plot each issue on:

```
        HIGH IMPACT (blocks tasks)
              |
              |   ★ Fix these first
              |
LOW FREQ -----+------ HIGH FREQ
              |
              |   ◇ Monitor / fix if easy
              |
        LOW IMPACT (cosmetic)
```

Issues in the top-right quadrant are your priority. Top-left are important but rare (may need more data). Bottom-right are death-by-a-thousand-cuts issues.

---

## Phase 4: Reporting

### Findings Report Structure

1. **Executive summary** (≤5 sentences: what we tested, top 3 findings, recommended action)
2. **Method** (participants, tasks, metrics — keep brief)
3. **SUS score + interpretation** (number, grade, comparison to prior rounds if any)
4. **Top findings** (severity-ordered, each with: description, evidence, frequency, recommendation)
5. **Positive findings** (what worked — don't be the harbinger of only bad news)
6. **Full issue list** (appendix, sortable by severity)
7. **Next steps** (what to fix, when to re-test)

### Presenting to Stakeholders

- Lead with the 2–3 things that most affect the decisions from Phase 0
- Use participant quotes and (short) video clips — direct exposure to user struggle is the most persuasive artifact you can produce
- Frame recommendations as "users couldn't do X because of Y" not "we think Z is bad"
- If SUS < 68: this is below average across all tested products in the literature. That's a concrete, defensible benchmark.

---

## Appendix A: System Usability Scale (SUS)

Administer immediately after the last task, before discussion. Instruct participant to answer quickly with first instinct.

Replace "system" with your product name.

| # | Statement | Strongly Disagree (1) → Strongly Agree (5) |
|---|-----------|---------------------------------------------|
| 1 | I think that I would like to use [system] frequently | 1 2 3 4 5 |
| 2 | I found [system] unnecessarily complex | 1 2 3 4 5 |
| 3 | I thought [system] was easy to use | 1 2 3 4 5 |
| 4 | I think that I would need the support of a technical person to use [system] | 1 2 3 4 5 |
| 5 | I found the various functions in [system] were well integrated | 1 2 3 4 5 |
| 6 | I thought there was too much inconsistency in [system] | 1 2 3 4 5 |
| 7 | I would imagine that most people would learn to use [system] very quickly | 1 2 3 4 5 |
| 8 | I found [system] very awkward to use | 1 2 3 4 5 |
| 9 | I felt very confident using [system] | 1 2 3 4 5 |
| 10 | I needed to learn a lot of things before I could get going with [system] | 1 2 3 4 5 |

### Scoring

1. Odd items (1,3,5,7,9): score = response − 1
2. Even items (2,4,6,8,10): score = 5 − response
3. Sum all 10 adjusted scores (range: 0–40)
4. Multiply by 2.5 → final SUS score (range: 0–100)

### Interpretation

| SUS Score | Grade | Adjective | Percentile |
|-----------|-------|-----------|------------|
| 84.1+ | A | Excellent | ~96th |
| 80.8+ | A− | — | ~90th |
| 78.9+ | B+ | — | ~84th |
| 72.6+ | B | Good | ~65th |
| 71.1+ | B− | — | ~60th |
| 62.7+ | C+ | — | ~41st |
| 51.7+ | C | OK | ~15th |
| 38.0+ | D | Poor | ~5th |
| < 38.0 | F | Awful | Bottom 2% |

**Average across all products in the literature: 68.** That's your baseline.

---

## Appendix B: Quick Reference — Common Moderator Traps

| Trap | Why it's bad | Instead |
|------|-------------|---------|
| Answering user questions about the UI | You learn nothing; they learn the answer | "What would you expect?" / "What would you try?" |
| Explaining design rationale during the test | Primes the user; biases all subsequent tasks | Save for after the session if at all |
| Nodding/affirming when user does "right" thing | Creates observer effect; user starts performing for you | Neutral: "mm-hmm, keep going" |
| Asking leading questions ("Don't you think X is clear?") | Suggests the "right" answer | "How would you describe X?" |
| Rescuing users too quickly when stuck | You miss the failure mode | Wait ≥2 min; ask "what are you thinking?" |
| Testing too many things in one session | Fatigue corrupts later data | Ruthlessly scope to 3–5 tasks |

---

## Appendix C: Adapting This for Remote/Async Testing

**Remote moderated** (Zoom/Meet): Mostly the same. Have participant share screen. Send tasks via chat. Use "keep talking" in chat as a gentle nudge instead of verbal prompting.

**Unmoderated** (Maze, UserTesting, etc.): Write tasks more precisely since you can't clarify. Expect higher dropout. Need ~2× participants to compensate for lost sessions and inability to probe. Best for validation, not discovery.

**Guerrilla / hallway testing**: Radically shortened version (1–2 tasks, 10 min). Useful for early prototypes. Don't bother with SUS — just ask "what did you expect to happen?" after each task.

---

*Last updated: 2026-03-20. Adapt freely. The best test is the one you actually run.*
