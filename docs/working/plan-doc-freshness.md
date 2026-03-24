# Plan: Document Freshness Tracking

**Scope:** Add "last verified" field and staleness heuristic to research/onboarding doc templates, documented so agents can check freshness.

**Research:** [research-doc-freshness.md](research-doc-freshness.md)
**Spike:** [staleness-heuristic.md](../spikes/staleness-heuristic.md)

## Approach

Add `Last verified` and `Relevant paths` fields to the onboarding doc template and spike record template. Document the staleness heuristic (git log --since check) in a dedicated guide that agents reference at session start. Skip disposable docs (RPI working docs) since they're overwritten per task.

## Steps

1. **Update onboarding workflow template** — Add `Last verified` and `Relevant paths` fields to the orientation document template in `workflows/codebase-onboarding.md`. Add a "Freshness check" subsection to the "When to re-run" section explaining the git log heuristic. (~15 lines added)

2. **Update spike workflow template** — Add `Last verified` and `Relevant paths` fields to the spike record template in `workflows/spike.md`. (~5 lines added)

3. **Update RPI workflow** — Add `Last verified` and `Relevant paths` to the research doc only for long-lived research artifacts (not per-task working docs). Add a note in the "working documents" section about when freshness tracking applies. (~10 lines added)

4. **Create freshness check guide** — New file `guides/doc-freshness.md` documenting the full heuristic: what the fields mean, how to run the check, staleness thresholds by doc type, and when to update `Last verified`. This is the canonical reference. (~60-80 lines)

5. **Update CLAUDE.md and AGENTS.md** — Add a brief mention of doc freshness checking in the "Shared Thoughts" section (or nearby), pointing to the guide. (~3-5 lines each)

## Testing strategy

- Verify all modified templates are syntactically valid markdown
- Confirm the git log command from the guide works on this repo
- Review that field names are consistent across all templates (`Last verified`, `Relevant paths`)

## Risks

- **Adoption risk**: Agents may not check freshness unless explicitly prompted. Mitigated by mentioning it in entry points (CLAUDE.md/AGENTS.md).
- **Overhead risk**: Adding fields to templates adds friction to document creation. Mitigated by keeping it to two fields and making them optional for disposable docs.
