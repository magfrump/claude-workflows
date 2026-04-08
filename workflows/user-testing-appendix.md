# User Testing Workflow — Reference Appendix

Reference templates and supplementary material for [user-testing-workflow.md](user-testing-workflow.md).

---

## Appendix A: Moderator Script Template

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

[Administer the SUS questionnaire — see Appendix C below]

=== WRAP-UP (2 min) ===

Thank you — this was really helpful. [Deliver compensation.]
If anything comes to mind later, feel free to reach out at [contact].

[Stop recording. See participant out.]
```

---

## Appendix B: Observation Template

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

---

## Appendix C: System Usability Scale (SUS)

Administer immediately after the last task, before discussion. Instruct participant to answer quickly with first instinct.

Replace "system" with your product name.

| # | Statement | Strongly Disagree (1) -> Strongly Agree (5) |
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

1. Odd items (1,3,5,7,9): score = response - 1
2. Even items (2,4,6,8,10): score = 5 - response
3. Sum all 10 adjusted scores (range: 0-40)
4. Multiply by 2.5 -> final SUS score (range: 0-100)

### Interpretation

| SUS Score | Grade | Adjective | Percentile |
|-----------|-------|-----------|------------|
| 84.1+ | A | Excellent | ~96th |
| 80.8+ | A- | -- | ~90th |
| 78.9+ | B+ | -- | ~84th |
| 72.6+ | B | Good | ~65th |
| 71.1+ | B- | -- | ~60th |
| 62.7+ | C+ | -- | ~41st |
| 51.7+ | C | OK | ~15th |
| 38.0+ | D | Poor | ~5th |
| < 38.0 | F | Awful | Bottom 2% |

**Average across all products in the literature: 68.** That's your baseline.

---

## Appendix D: Common Moderator Traps

| Trap | Why it's bad | Instead |
|------|-------------|---------|
| Answering user questions about the UI | You learn nothing; they learn the answer | "What would you expect?" / "What would you try?" |
| Explaining design rationale during the test | Primes the user; biases all subsequent tasks | Save for after the session if at all |
| Nodding/affirming when user does "right" thing | Creates observer effect; user starts performing for you | Neutral: "mm-hmm, keep going" |
| Asking leading questions ("Don't you think X is clear?") | Suggests the "right" answer | "How would you describe X?" |
| Rescuing users too quickly when stuck | You miss the failure mode | Wait >=2 min; ask "what are you thinking?" |
| Testing too many things in one session | Fatigue corrupts later data | Ruthlessly scope to 3-5 tasks |

---

## Appendix E: Adapting for Remote/Async Testing

**Remote moderated** (Zoom/Meet): Mostly the same. Have participant share screen. Send tasks via chat. Use "keep talking" in chat as a gentle nudge instead of verbal prompting.

**Unmoderated** (Maze, UserTesting, etc.): Write tasks more precisely since you can't clarify. Expect higher dropout. Need ~2x participants to compensate for lost sessions and inability to probe. Best for validation, not discovery.

**Guerrilla / hallway testing**: Radically shortened version (1-2 tasks, 10 min). Useful for early prototypes. Don't bother with SUS -- just ask "what did you expect to happen?" after each task.

---

*Last updated: 2026-04-08. Adapt freely. The best test is the one you actually run.*
