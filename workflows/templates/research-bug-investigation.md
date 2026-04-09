# Research Template: Bug Investigation

> **This is a starting point to modify, not a form to fill in.** Delete sections that don't apply, rename headings that don't fit, and add whatever your specific bug needs. The only hard requirement is that the final research doc covers the five RPI sections: Scope, What exists, Invariants, Prior art, and Gotchas. See also the debugging defaults in CLAUDE.md — reproduce first, hypothesize specifically, test don't guess.

## Scope
<!-- One sentence: what bug or unexpected behavior is being investigated? -->

## Reproduction
<!-- How do you trigger the bug? Be specific:
- What are the exact steps or inputs?
- What do you expect to happen vs. what actually happens?
- Is it consistent or intermittent? Under what conditions?
- Can you write a failing test that demonstrates the bug? -->

## What exists

### Relevant code
<!-- Which files, functions, and code paths are involved? Trace the execution path from the trigger to the symptom. -->

### Error evidence
<!-- What do the error messages, stack traces, or logs tell you? Include the actual text — paraphrasing loses signal. -->

## Hypotheses
<!-- State specific, falsifiable hypotheses about the root cause. For each:
- **Hypothesis**: What specifically is wrong, where, and why?
- **Test**: What's the smallest experiment that would confirm or refute this?
- **Result**: Confirmed / Refuted / Untested
- **Notes**: What did you learn?

Start with the hypothesis most directly supported by the error evidence. If 3+ hypotheses are refuted, stop and reassess — you may not understand the code well enough (see debugging defaults). -->

## Invariants
<!-- What must the fix preserve? Tag with [observed], [inferred], or [assumed]. Consider:
- What is the correct behavior? (This is the specification the fix must satisfy.)
- What other code depends on the buggy code's current interface?
- Are there callers that might depend on the buggy behavior? -->

## Prior art
<!-- Has a similar bug been fixed before? Check:
- Git history for related fixes
- Known issues or previous reports
- Similar patterns elsewhere in the codebase that don't have this bug (what's different?) -->

## Gotchas
<!-- What could make the fix harder than it looks? Consider:
- Could fixing this break something else?
- Is the symptom in a different place than the root cause?
- Are there multiple bugs masquerading as one? -->
