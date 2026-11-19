# Run file templates

Skeletons for the run folder's files. The filled-in originals are in the O20 pilot
(`docs/working/o20-2026-11-17/` in claude-workflows).

## tasks.md

```markdown
# Reader tasks: <post> (<date>)

**Stimulus:** `post.md` (sha256 `…`), title "<title>", attachment `<name>` (sha256 `…`).
**Profile:** `docs/audiences/<venue>.md`. **Key:** `key.md`, never shown to readers.
**Tier:** full | light. **Sections** (at the post's headings): 1 <heading> (lines a–b) · 2 …
**Release groups per archetype** (from the profile's "How they read"; the first group is the blind
cut): <archetype>: [1] · [2, 3] · [4] … **Blind cut:** section 1 (lines a–b), because <it is
where the opening ends>.

## <Archetype> (<reading path, from the profile>)

- **X1.** <goal-level question>
  - Positive signals: <what a reader who got it says or does>
  - Negative signals: <the misreading, the wrong status>
  - Should be answered in: <section>. From the opening alone? <yes/no, graded per element:
    answer · status · conditions>
```

## key.md

```markdown
# Answer key: <post> (<date>)

**Never shown to readers.** Written from <source of truth: research notes, problem page, code>,
not from the draft. **Written by:** <the post's author, or someone else>. If by the author, it
shares the author's frame: <state the frame it assumes>. A reader passes a task when their answer has every ● element, contradicts
none, and gets the status right. ○ elements are credit, not required.

**Intended gist.** Problem: … Insight: … Key move: … Finding: …

## <Archetype>

**X1.** (<source location>)
- ● <required element> ● Status: <proved / numerical / conditional on … / open>
- ○ <credit element>
- Location in post: <filled in during grading>
```

## predictions-<reader>.md

```markdown
# Pre-registered predictions: <reader>'s session

**Do not open until your session is done.** Written and committed <date>, before the session.
Each number is a credence about this one run, not a rate.

**Known contamination:** <what this reader already knows or was told that gives answers away>.

| # | Prediction | Needs | Credence |
|---|---|---|---|
| P1 | <where this reader stops: a section, or "the end"> | — | <n>% |
| P2 | <the first take mentions …> | <the opening> | <n>% |

**Scoring.** Each prediction is checked against the session file, and scores hit, miss, not
reached (the session stopped before the section in "Needs") or not observable. A miss on a
prediction a simulated reader supports is evidence against that simulated finding. A "not reached"
is evidence of nothing.
```

## findings.md

```markdown
# Findings: reader test of <post> (round <n>, <date>)

**Stimulus:** … **Profile:** … **Key:** … **Previous round:** <link or none>.
**Degraded:** <none, or: instruction-only staging · no real reader · grader not fresh · …>

| Session | Kind | Notes |
|---|---|---|
| `sessions/<archetype>.md` | simulated / real | <contamination, brief artifacts> |

Part A lists correctness and fidelity issues. Part B lists exposition. **Part A blocks posting
whatever Part B says.**

## Part A: correctness and fidelity

| # | Finding | Raised by | Verdict (CONFIRMED / PLAUSIBLE / CLEARED) | Where |
|---|---|---|---|---|

## Part B: exposition

### Task results
| Task | Session | Result | Type | Notes |

### Recall

### Findings, most severe first
| # | Sev. | Kind | Type | Finding | Sessions (after the convergent-reasons test) | Calibrated? |

### Calibration

### Across rounds
| Finding | Fixed / Improved / Unchanged / Regressed |

### Where the archetypes conflict

## Revision brief

1. Part A first, with the claims each item changes.
2. The first causal gap.
3. …
N. Re-run: tasks <list>, with fresh readers, not told what changed.

**Claims this revision may change:** <each, with its Part A item>.

## Notes for the skill
```
