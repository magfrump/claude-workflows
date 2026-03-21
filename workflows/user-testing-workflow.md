# User Testing Workflow Prompt

A reusable guide for planning, running, and interpreting usability tests. Grounded in HCI literature (Nielsen, Brooke, Travis, Dumas & Redish, etc.) and adapted for small-team/indie contexts.

---

## Phase 0: Scoping (Before Anything Else)

**Fill in these blanks before proceeding. Everything downstream depends on them.**

1. **What are we testing?** (specific feature/flow, not "the whole app")
2. **What do we want to learn?** (2–4 research questions, *not* yes/no)
3. **What decisions will this inform?** (ship/don't ship, redesign X, prioritize Y)
4. **What's the riskiest assumption?** (the thing that, if wrong, wastes the most work)

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
