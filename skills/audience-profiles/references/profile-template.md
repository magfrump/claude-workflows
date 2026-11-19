# Audience profile template

Copy this into `docs/audiences/<venue>.md` and fill in every field. The pilot this template came
from lacked the stake, patience, pain-trigger and wins fields, so no existing profile shows every
field yet. Within the claude-workflows repo the pilot is `docs/working/mais.md`.

```markdown
# Audience profile: <venue>

**Status:** draft | ratified by the author <date> [· no thread evidence]. **Last verified:** <date>.
**Changes:** <date: what a refresh changed, and why>, or "none".
**Venue:** <where posts appear, and what kinds of post>. **Evidence read:** <files with commit
hashes; threads with dates and counts; the author's notes>.

**Refresh this profile when** <the venue's guides change · a reader does something this profile
did not predict · a reader-testing run's simulated reader disagrees with a real one · the
author's own knowledge moves>.

This profile describes archetypes, never named people.

**Scope.** <"Whole venue", or for a layered profile: which roles live here, which in the other
layer, and a link to it.>

## The venue

**What a post is for.** <What the post asks for (a verdict, a merge, a citation), and what record
it becomes. Which paragraph should be liftable into that record as it stands.>

**Declared reader.** <Quote the venue's own statement of its reader, or "none declared; the
author's primary reader is <…>">.
**Rule:** write for the declared reader (or the author's primary reader) and test against the
archetypes. When two archetypes conflict, that reader decides, and the other need moves to a layer.

**Register.** <Pointer to the venue's style guide and the rules that matter most. Don't restate it.>

**Norms that change how a post is read.** <The screen a post must pass and how long it takes;
labelling and status rules; queue order; where negative outcomes go.>

**What has actually happened on threads** (<date>). <Counts, verdict formats, what readers asked
for or found missing. Cite threads. Note where practice breaks the venue's own rules.>

## Archetype N: <role name>

**Who.** <The role, and the groups of people who fill it, cited as evidence.>

**The question they bring.** <In their own words or notation.>

**Stake.** <One sentence: what they lose if they misread this or waste the time.>

**What they know** (as of <date>). <Documents they know, documents they don't. Not a symbol list.>

**How they read.** <Their reading path: which parts, in what order, how many passes. When they stop.>

**Patience budget.** <A time or a section count, and its source: an observed stop, or the interview. Never inferred from the reader's own questions.> **Pain triggers:** <what makes them close the
tab.> **Wins:** <what makes them come back.>

**What they do next.** <The action the post should enable.>

**The worst misreading.** <The specific wrong conclusion that would cost the most, for this post type.>

**Success test.** <Observable: what they can do or answer, and from which part of the post.>

**Task templates.** <3–5 goal-level questions this archetype would bring, phrased so a key can be
written for them. reader-testing instantiates these per post.>

**Real readers available before posting.** <Who, or "none". A stand-in is not a calibration.>

## Predictions to score against reads the reader does anyway

<Optional, for a reader who is always available. Each prediction is a credence about their next N
answers or actions, and is scored at the next refresh.>

## Interview answers (<date>)

1. <question>: <answer>

## Calls for the author

<Non-interactive runs only: each question, its options (one departing from the draft), and the
interim answer this draft uses.>

## Notes for the skill

<What this run showed that audience-profiles should change.>
```
