# Research: Document Freshness — Round 2

## Scope

Refine freshness tracking across the three declared files: add cross-references from `guides/doc-freshness.md` to the workflow templates, and add a freshness check section to the spike workflow (parity with onboarding).

## What exists

### Current state of the three files

1. **`guides/doc-freshness.md`** — The canonical freshness guide. Documents field formats, staleness check command, which docs to track, and when to check/update. Does NOT reference the workflow templates as the canonical source for field placement. The "Which documents to track" table lists doc types but doesn't link to their templates.

2. **`workflows/codebase-onboarding.md`** — Template (step 6) includes `**Last verified:**` and `**Relevant paths:**` fields. Has a "Freshness check" subsection (lines 137-145) under "When to re-run" explaining the git log heuristic with a code example. Well-integrated.

3. **`workflows/spike.md`** — Template (step 4) includes `Last verified:` and `Relevant paths:` fields in the spike record markdown block. Has NO freshness check section — unlike onboarding, there's no guidance on when/how to check a spike record's freshness before relying on it.

### Gap analysis

- **doc-freshness.md** needs a "Template conventions" note so readers know where the fields are defined
- **spike.md** needs a brief freshness note so agents know to check spike records before citing them (onboarding has this; spike does not)
- **codebase-onboarding.md** is already complete — no changes needed

## Invariants

- Only touch the three declared files
- Don't restructure existing content — additive changes only
- Keep consistency with existing patterns (inline bold for non-review docs, code block for commands)
