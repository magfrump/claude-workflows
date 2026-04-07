# User Testing Workflow Prompt

A reusable guide for planning, running, and interpreting usability tests. Grounded in HCI literature (Nielsen, Brooke, Travis, Dumas & Redish) and adapted for small-team/indie contexts.

---

## Phase 0: Scoping (Before Anything Else)

**Fill in these blanks before proceeding. Everything downstream depends on them.**

1. **What are we testing?** (specific feature/flow, not "the whole app")
2. **What do we want to learn?** (2–4 research questions, *not* yes/no)
3. **What decisions will this inform?** (ship/don't ship, redesign X, prioritize Y)
4. **What's the riskiest assumption?** (the thing that, if wrong, wastes the most work)

> **Litmus test**: If you can't name a decision this test will change, you're not ready to test.

### Participant Planning

| Factor | Guidance |
|--------|----------|
| **Per round** | 3–5 for qualitative/formative (Nielsen-Landauer). Plan ≥2 rounds. |
| **Total** | 10+ for confidence; 5 for "find the worst stuff fast" |
| **Distinct groups** | If ≥2 populations, recruit 3–4 per group minimum |
| **Recruitment** | Target actual users. Convenience samples okay for round 1 if bias is flagged. |

### Logistics Checklist

- [ ] Session duration decided (30–45 min; never exceed 60)
- [ ] Recording method chosen (screen + audio minimum)
- [ ] Consent form prepared (recording, data use, right to stop)
- [ ] Compensation decided
- [ ] Note-taker assigned (facilitator should NOT also take notes)
- [ ] Pilot session scheduled before real sessions

---

## Phase 1: Session Design

### Task Construction

**The #1 mistake is writing tasks that describe the UI instead of user goals.**

| ❌ Bad Task | ✅ Good Task |
|------------|-------------|
| "Click 'New Project' and fill in the form" | "You want to start a new proof. Set things up however feels natural." |
| "Navigate to Settings > Preferences > Display" | "You find the text hard to read. See if you can fix that." |

**Task template:**

```
SCENARIO: [1–2 sentences of realistic context]
TASK: [What they're trying to accomplish, in their language]
SUCCESS CRITERIA (internal, not shared):
  - Completed / Partial / Failed
```

**Rules:**
- 3–5 tasks per session (more → fatigue → garbage data)
- Simple → complex order
- Never use UI labels in task wording
- Include at least one task targeting your riskiest assumption from Phase 0

### Moderator Script Template

```
=== INTRODUCTION (5 min) ===
We're testing the design, not you. No wrong answers. If something is
confusing, that's on us. Think out loud as you work — say whatever
comes to mind.
[If recording]: Get consent. Any questions before we start?

=== WARM-UP (3 min) ===
2–3 background questions relevant to your domain. Keep it light.

=== TASKS (25–35 min) ===
Present tasks one at a time (printed/chat, not verbal).

Moderator behavior:
- Stay quiet. Let silence happen.
- If silent >15 sec: "What are you thinking right now?"
- If they ask how-to questions: "What would you do if I weren't here?"
- If stuck >2 min with visible frustration: offer to move on.
- NEVER answer questions about the UI.

After each task:
- "How did that go?" / "Anything surprising?"
- SEQ (1–7 ease rating) for cross-task comparison

=== POST-TEST (5–10 min) ===
Overall impression, frustrations, what worked, one thing to change.
Administer SUS questionnaire (see appendix).

=== WRAP-UP (2 min) ===
Thank participant, deliver compensation, stop recording.
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

One row per task per participant:

```
Participant: ___  Date: ___  Session #: ___

| Task # | Time (sec) | Completed? | Errors/Detours | Notable Quotes | SEQ (1–7) |
|--------|-----------|------------|----------------|----------------|-----------|
| 1      |           |            |                |                |           |
```

### Between-Session Debrief (5 min max)

Immediately after each session, facilitator + note-taker answer:
1. Top 3 issues this participant hit?
2. Anything new we haven't seen before?
3. Any task wording that needs fixing?

---

## Phase 3: Analysis

### Step 1: Compile Raw Data

- Transcribe/timestamp key moments from recordings
- Fill gaps in observation notes
- Calculate SUS scores (see appendix) and aggregate SEQ scores per task

### Step 2: Affinity Clustering

1. Write each distinct observation on a separate note (physical or digital)
2. Silently cluster related notes (no talking — reduces groupthink)
3. Name clusters after clustering, not before
4. Look for clusters spanning multiple tasks — these are systemic issues

### Step 3: Severity Rating

Use the Travis method to classify each problem:

| Severity | Test | Action |
|----------|------|--------|
| **Critical** | User cannot complete the task | Fix before release |
| **Serious** | Frequent task, user won't overcome on retry | Fix soon |
| **Medium** | Infrequent task OR user overcomes on retry | Fix next cycle |
| **Low** | Cosmetic/polish issue | Fix if time allows |

**Also track:** Frequency (n/N participants) and persistence (one-time vs. recurring).

### Step 3.5: Stress-Test Findings

Before prioritizing, pressure-test each finding rated Minor or above:

1. **Boring explanation?** Could this be unfamiliarity, a test artifact, or something that disappears after first use? If so, downgrade.
2. **Who implements the fix?** Name the team, timeline, and skills required. If no plausible team can execute, reframe the recommendation.
3. **Why hasn't it been fixed already?** If known before, the answer (competing priorities, tech debt, disagreement) tells you whether to address organizational friction, not just UI.

### Step 4: Prioritize

Focus on issues that are both high-impact (block tasks) and high-frequency. Top-left quadrant (high-impact, low-frequency) needs more data. Bottom-right (low-impact, high-frequency) is death-by-a-thousand-cuts.

---

## Phase 4: Reporting

### Findings Report Structure

1. **Executive summary** (≤5 sentences: what we tested, top 3 findings, recommended action)
2. **Method** (participants, tasks, metrics — keep brief)
3. **SUS score + interpretation** (number, grade, comparison to prior rounds)
4. **Top findings** (severity-ordered: description, evidence, frequency, recommendation)
5. **Positive findings** (what worked)
6. **Full issue list** (appendix, sortable by severity)
7. **Next steps** (what to fix, when to re-test)

### Presenting to Stakeholders

- Lead with the 2–3 things that most affect the decisions from Phase 0
- Use participant quotes and short video clips — direct exposure to user struggle is the most persuasive artifact
- Frame as "users couldn't do X because of Y" not "we think Z is bad"
- SUS < 68 is below average across all tested products in the literature

---

## Appendix A: System Usability Scale (SUS)

Administer after the last task, before discussion. Replace "system" with your product name.

| # | Statement | 1 (Disagree) → 5 (Agree) |
|---|-----------|---------------------------|
| 1 | I would like to use [system] frequently | 1 2 3 4 5 |
| 2 | I found [system] unnecessarily complex | 1 2 3 4 5 |
| 3 | [system] was easy to use | 1 2 3 4 5 |
| 4 | I would need technical support to use [system] | 1 2 3 4 5 |
| 5 | Functions in [system] were well integrated | 1 2 3 4 5 |
| 6 | Too much inconsistency in [system] | 1 2 3 4 5 |
| 7 | Most people would learn [system] quickly | 1 2 3 4 5 |
| 8 | [system] was very awkward to use | 1 2 3 4 5 |
| 9 | I felt confident using [system] | 1 2 3 4 5 |
| 10 | I needed to learn a lot before using [system] | 1 2 3 4 5 |

**Scoring:** Odd items: response − 1. Even items: 5 − response. Sum all 10, multiply by 2.5 → SUS score (0–100).

| SUS Score | Grade | Interpretation |
|-----------|-------|----------------|
| 84+ | A | Excellent (~96th percentile) |
| 72+ | B | Good (~65th percentile) |
| 52+ | C | OK (~15th percentile) |
| < 52 | D/F | Poor to awful |

**Baseline: 68 is average across all products in the literature.**

---

## Appendix B: Common Moderator Traps

| Trap | Instead |
|------|---------|
| Answering UI questions | "What would you expect?" / "What would you try?" |
| Explaining design rationale | Save for after the session |
| Nodding at "right" actions | Neutral: "mm-hmm, keep going" |
| Leading questions ("Don't you think X is clear?") | "How would you describe X?" |
| Rescuing stuck users too quickly | Wait ≥2 min; ask "what are you thinking?" |
| Testing too many things | Scope to 3–5 tasks |

---

## Appendix C: Adapting for Remote/Async Testing

- **Remote moderated** (Zoom/Meet): Same process. Participant shares screen; send tasks via chat.
- **Unmoderated** (Maze, UserTesting, etc.): Write tasks more precisely. Need ~2× participants. Best for validation, not discovery.
- **Guerrilla** (hallway testing): 1–2 tasks, 10 min. Skip SUS — just ask "what did you expect to happen?"

---

*Last updated: 2026-04-06. Adapt freely. The best test is the one you actually run.*
