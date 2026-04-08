# User Testing Workflow Prompt

A reusable guide for planning, running, and interpreting usability tests. Grounded in HCI literature (Nielsen, Brooke, Travis, Dumas & Redish, etc.) and adapted for small-team/indie contexts.

> **Reference material** (templates, SUS questionnaire, moderator traps, remote-testing guidance) lives in [user-testing-appendix.md](user-testing-appendix.md).

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

| Bad Task | Good Task |
|----------|-----------|
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

### Moderator Script

Use the full moderator script template from [Appendix A](user-testing-appendix.md#appendix-a-moderator-script-template). Key sections: introduction (5 min), warm-up (3 min), tasks (25–35 min), post-test (5–10 min), wrap-up (2 min). Review common moderator traps in [Appendix D](user-testing-appendix.md#appendix-d-common-moderator-traps) before your first session.

---

## Phase 2: Running Sessions

### Live Checklist (per session)

- [ ] Recording running
- [ ] Consent obtained
- [ ] Note-taker ready with [observation template](user-testing-appendix.md#appendix-b-observation-template)
- [ ] Tasks printed/ready to share
- [ ] Clock visible (track time per task)

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
- Calculate SUS scores (see [Appendix C](user-testing-appendix.md#appendix-c-system-usability-scale-sus))
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
- For remote/async adaptations, see [Appendix E](user-testing-appendix.md#appendix-e-adapting-for-remoteasync-testing)

---

*Last updated: 2026-04-08. Adapt freely. The best test is the one you actually run.*
