Commit: 7d61c39b

# Performance Review — fix/q160-iteration-cap (final confirming pass)

**Scope:** `git diff main...HEAD` at 7d61c39b (markdown only: `workflows/review-fix-loop.md`, `workflows/pr-prep.md`, `guides/pr-prep-quick-ref.md`, `guides/completion-signals.md`, `skills/code-review/references/chat-synthesis.md`, decision log row 62, review artifacts)
**Date:** 2026-10-15
**Based on:** the merged final fact-check (k=3, no Incorrect) summarized in the critic brief; its non-Verified clusters are not re-filed here.

## Data Flow and Hot Paths

The diff adds no executable code. Its "runtime" is the review-fix loop agents follow. It adds three costs:

1. **Machine cost.** One run of pr-prep step 1a's `git diff --numstat … | awk` count after each iteration (pr-prep 3c) and once more at 6c. On this branch, against `main`, the count took 0.007 s wall time and printed 50. It is O(diff size) and runs at most once per iteration (hard cap 3, plus any iterations the user authorizes), so it is negligible.
2. **Bookkeeping cost.** One `Size:` line in a commit body per count. Negligible.
3. **User-attention and latency cost.** This is the real cost. Past ~800 lines the loop stops on the unit until the user answers a `you: judgment` waiver entry, in /away mode too, and the agent may not split on its own to get back under. Every iteration is a hot path in this sense, because the check runs on all of them. The waiver path is cold: of the three growth cases the PR cites, two would have fired it (1861 and 842 lines) and one would not (538).

## Findings

#### A granted waiver with no named limit leaves zero headroom, so each later fix that adds a line costs another blocking question

**Severity:** Medium
**Location:** `workflows/review-fix-loop.md:61` (with `:59`, `:57`)
**Move:** Count the hidden multiplications (user questions per waiver); Find the work that moved to the wrong place
**Classification:** Micro (fixed attention cost per extra question) / Hot path (the check runs after every iteration, and again at 6c)
**Confidence:** Medium
**Baseline:** 61 min of blocked wait for one blocking question in the Q-076 batch (asked 00:09, answered 01:10; `workflows/review-fix-loop.md` § Early split trigger)
**Legibility-target:** the agent applying the waiver limit, and the user writing waiver answers
**Evidence:**
> "A granted waiver sets the limit the re-check uses from then on: the one its answer names, or, when it names none, the count the entry asked about, so any further growth asks again."
> "The entry's options can include splitting the unit, and it proposes the new limit the waiver would grant."

The answer grammar this repo teaches is a bare `Q-NNN: [n]`, and "a bare `[2]` is a complete instruction" (global CLAUDE.md, running questions doc). A bare `[1]` arguably does not "name" a limit. If so, the limit falls back to the exact count asked about, and any later fix that adds even one line triggers a new waiver entry and stops the loop again. Waivers fire while review is still producing fixes: in iteration 1 or 2, Must Fix work is still open, and a fix commit almost always adds lines. One waiver can therefore turn into one question per remaining iteration (up to about 3 under the cap, more with authorized iterations). Each question has the 61-minute wait above, or a whole away period overnight. The text does try to prevent this by having the entry propose a limit, but it never says that choosing the option carrying that proposal counts as naming it. The two readings give different attention costs.

**Recommendation:** State that choosing the waiver option adopts the limit proposed in that option. Have the entry propose headroom above the current count (for example, the current count plus the growth expected from open findings) rather than the bare count. That way one answer covers the rest of the loop unless growth beats the forecast.

#### The /away stop blocks stacked units above the waived one until the user returns

**Severity:** Low
**Location:** `workflows/review-fix-loop.md:59`, `:63`
**Move:** Find the contention point (a serial wait on one shared resource, the user)
**Classification:** Macro (the delay grows with stack depth) / Cold path (only when a unit passes 800 lines; 2 of the 3 cited growth cases)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** the orchestrator scheduling build loops during /away runs
**Evidence:**
> "Past 800, the loop stops on this unit: no further fix commits, drift check, re-review or merge until the user answers … Work on other units goes on."
> "When the unit has grown past 800 during review, the agent does not split on its own to get back under"

"Work on other units goes on" covers independent units. Stacked units are different: pr-prep 1a says they "review against a settled base" and merge in order, so every unit above a stopped one waits too. The early-split rule exists because a blocked loop is expensive ("a split is cheap to undo, a blocked loop is not"). Here the user chose to accept that cost in exchange for control (Q-104 [2]), so this is a deliberate trade, not a defect. The cost is still worth stating: in an /away run, a past-800 stop low in a stack stalls the whole stack for the length of the away period. The memory note "never block on the user; route async" pulls the other way, but Q-104 [2] is the user's own answer.

**Recommendation:** Optional. Add one sentence saying that units stacked above a stopped unit also wait, so orchestrators schedule other work instead of polling. No change to the rule itself.

## Endorsements

- The size count is a single `git diff --numstat` piped to `awk`, run once per iteration and once at 6c. On this branch it took 0.007 s and printed 50, so the re-check adds no measurable machine cost per iteration. [read: workflows/pr-prep.md:91]
- The 6c re-run repeats the last 3c count when no commits landed after the final iteration. The duplication costs a fraction of a second, and it closes the window for commits made after the loop. [read: workflows/review-fix-loop.md:57]
- Limiting chat-synthesis rule 2's `split PR` to the first review means a unit that grew during review no longer gets a split recommendation on every later pass. That removes a repeated recommendation the loop's own rule would override anyway. [read: skills/code-review/references/chat-synthesis.md:140-151]
- The ~800 tolerance (2× the entry cap) means waiver questions fire only on large growth. In the cited history, 538 lines would pass silently while 842 and 1861 would ask, so routine fix growth spends no user attention. [read: workflows/review-fix-loop.md:57,67]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A waiver with no named limit gives zero headroom; each later growing fix asks again | Medium | `workflows/review-fix-loop.md:61` | Medium |
| 2 | The /away stop also stalls units stacked above the stopped one | Low | `workflows/review-fix-loop.md:59,63` | Medium |

## Overall Assessment

The change adds almost no per-iteration cost: one sub-second count and one commit-body line. Its real price is user attention, which is the cost Q-104 [2] chose to pay. The one material inefficiency is in how waiver limits are set. With a bare `[n]` answer the fallback limit is the exact count, so a waived unit that is still taking fixes can ask again on every remaining iteration. That multiplies a cost meant to be "an occasional waiver question" (Q-104 [2]'s own cost column). It can be fixed in place with one sentence about which limit an option answer adopts, plus a headroom default. No profiling is needed. Whether re-asks actually happen can be checked from the `Size:` lines and waiver entries after the next waived unit.

## Goal-Alignment Note

The PR's goal is to write Q-104 [2] into the process: re-check per iteration, tolerate ~800 lines, ask for a waiver past that. The diff does this at negligible machine cost. Finding 1 bears on the goal directly: Q-104 [2] priced its cost to the user as "an occasional waiver question", and the zero-headroom fallback can make it a repeated one within a single unit. Finding 2 is a cost the user accepted, stated here so orchestrators can plan around it. Neither finding blocks the merge.
