# Research Template: New Feature

> **This is a starting point to modify, not a form to fill in.** Delete sections that don't apply, rename headings that don't fit, and add whatever your specific feature needs. The only hard requirement is that the final research doc covers the five RPI sections: Scope, What exists, Invariants, Prior art, and Gotchas.

## Scope
<!-- One sentence: what feature is being added? -->

## What exists

### Relevant code
<!-- Which files, functions, and patterns does this feature touch or depend on? Summarize what they do and how they connect — not just names. -->

### Integration points
<!-- Where does the new feature connect to existing code? Consider:
- What existing APIs, hooks, or extension points will you use?
- What data flows into and out of the feature?
- What existing components will the feature need to interact with? -->

### User-facing behavior
<!-- What will the user see or experience? Consider:
- What's the entry point — how does the user trigger this feature?
- What feedback does the user get (success, error, progress)?
- Are there edge cases in user interaction (empty state, error state, concurrent use)? -->

## Invariants
<!-- What must not break? Tag with [observed], [inferred], or [assumed]. Common things to check:
- Existing APIs that other code depends on
- Data contracts or schemas
- Auth/permission boundaries
- Performance characteristics (response times, memory usage)
- Conventions the codebase follows (naming, file organization, error handling) -->

## Prior art
<!-- Does the codebase already solve a similar problem? If so:
- Where is that solution?
- Should the new feature follow the same pattern, or is there a reason to diverge?
- What can you reuse vs. what needs to be new? -->

## Gotchas
<!-- Anything surprising, non-obvious, or fragile. Consider:
- Are there hidden dependencies that aren't obvious from the API surface?
- Are there race conditions, ordering dependencies, or timing issues?
- Is there technical debt in the area that could complicate the feature? -->
