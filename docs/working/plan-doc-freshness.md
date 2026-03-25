# Plan: Document Freshness — Round 2

**Scope:** Refine freshness tracking cross-references and add missing freshness check to spike workflow. Strictly scoped to three files.

**Research:** [research-doc-freshness.md](research-doc-freshness.md)

## Approach

Add a "Template conventions" note to the doc-freshness guide pointing readers to the workflow templates where the fields are defined. Add a freshness check section to the spike workflow for parity with the onboarding workflow.

## Steps

1. **Update `guides/doc-freshness.md`** — Add a "Template conventions" subsection after "Freshness fields" that cross-references `workflows/codebase-onboarding.md` and `workflows/spike.md` as canonical examples. (~5-8 lines)

2. **Update `workflows/spike.md`** — Add a brief freshness check note after step 5, consistent with the pattern in onboarding's "Freshness check" subsection. (~8-10 lines)

No changes needed to `workflows/codebase-onboarding.md` — it's already well-integrated.

## Testing strategy

- Verify all cross-references point to real files and sections
- Confirm markdown renders correctly
- Check that field names match across all three files

## Risks

- Minimal — additive documentation changes only
