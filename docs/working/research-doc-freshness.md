# Research: Document Freshness Tracking

## Scope

Add a "last verified" field and staleness heuristic to research and onboarding doc templates, so that documents signal when they may be outdated.

## What exists

### Document templates with freshness concerns

1. **Onboarding docs** (`workflows/codebase-onboarding.md`):
   - Template includes `**Date:** {date}` and `**Scope:** {what was covered}` fields
   - "When to re-run" section lists triggers (long absence, major refactoring, resolved unknowns) but no automated staleness signal
   - Explicitly says "If it grows stale, re-run the workflow rather than patching incrementally"

2. **RPI research docs** (`workflows/research-plan-implement.md`):
   - Working docs in `docs/working/research-{topic}.md`
   - Treated as disposable per-task artifacts — freshness is less of a concern since they're overwritten
   - No date or verification field in the template

3. **Spike records** (`workflows/spike.md`):
   - Template includes `Date: [date]`
   - Saved to `docs/spikes/` — these are reference material that can go stale

4. **Review artifacts** (`docs/reviews/`):
   - Include `**Checked:** {date}` fields
   - Explicitly designed to be re-run, overwriting prior versions

5. **Decision records** (`docs/decisions/`):
   - Numbered, final — staleness handled by superseding with a new decision
   - Not candidates for freshness tracking

6. **Shared thoughts** (`docs/thoughts/`):
   - Living documents updated as understanding deepens
   - No date field — staleness risk is real but currently untracked

### Existing freshness signals

- `code-fact-check` skill targets stale comments as a claim type ("Staleness signals")
- Evaluation rubric has periodic re-evaluation concept but no automated trigger
- Review artifacts have dated headers for manual recency checks
- CLAUDE.md notes context budget awareness but not doc staleness

### Git-based staleness detection

The task specifically mentions `git log --since` on relevant file paths. This is a sound approach because:
- Workflow/skill files are committed to the repo
- Changes to the files a doc describes are the primary staleness signal
- `git log --since` can check if source files have changed since a doc was last verified

## Invariants

- Existing document templates must remain backward-compatible (adding fields, not restructuring)
- The staleness heuristic should be advisory, not blocking — documents don't stop working when stale
- Must work for AI agents executing workflows, not just human readers

## Prior art

- Review artifacts already use `**Checked:** {date}` — the freshness field should be consistent with this pattern
- The evaluation rubric's "periodic re-evaluation" concept is analogous but for skills, not docs

## Gotchas

- `docs/working/` files are disposable per-task — freshness tracking adds overhead to inherently ephemeral documents. Only onboarding docs (which live longer) and spike records benefit meaningfully.
- Git log checks require knowing which file paths a document covers — this mapping isn't always explicit in current templates
- The heuristic needs to work across different doc types with different staleness thresholds
