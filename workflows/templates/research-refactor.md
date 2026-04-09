# Research Template: Refactor

> **This is a starting point to modify, not a form to fill in.** Delete sections that don't apply, rename headings that don't fit, and add whatever your specific refactor needs. The only hard requirement is that the final research doc covers the five RPI sections: Scope, What exists, Invariants, Prior art, and Gotchas. See also the Refactoring variant in `workflows/research-plan-implement.md` for plan-phase and implementation-phase guidance specific to refactors.

## Scope
<!-- One sentence: what is being refactored and why? A refactor changes structure without changing behavior — if behavior is also changing, this might be a feature instead. -->

## What exists

### Current behavior characterization
<!-- Document what the code does today. This becomes the specification the refactor must preserve:
- What are the inputs, outputs, and side effects?
- What error cases does it handle?
- What are the observable behaviors that callers depend on? -->

### Caller and dependent map
<!-- Map everything that depends on the code being refactored:
- Direct callers (functions, modules, tests)
- Indirect dependents (config files, scripts, documentation that references it)
- External consumers (APIs, CLIs, other repos)
These are the blast radius of a mistake. -->

### Test coverage assessment
<!-- What tests exist for the code being refactored?
- Do they test behavior (safe to keep) or implementation details (may need updating)?
- Are there gaps where behavior is untested? These are the riskiest areas.
- If coverage is insufficient, writing characterization tests becomes step 1 of the plan. -->

## Invariants
<!-- What must not change? Tag with [observed], [inferred], or [assumed]. For refactors, invariants ARE the spec:
- Public API signatures and return types
- Observable side effects (writes, network calls, events emitted)
- Performance characteristics that callers depend on
- Error behavior (which errors are thrown, when, with what messages) -->

## Prior art
<!-- Has similar code been refactored before in this codebase? Consider:
- What pattern did the previous refactor follow?
- Were there lessons learned (check git history, decision docs)?
- Is there a target pattern the codebase is migrating toward? -->

## Gotchas
<!-- What makes this refactor risky or tricky? Consider:
- Are there implicit contracts not captured by tests?
- Is the code used via reflection, dynamic dispatch, or string-based references?
- Are there performance-sensitive paths where structural changes could cause regressions?
- Can the refactor be done incrementally (each step leaves the codebase working), or does it require a big-bang change? -->
