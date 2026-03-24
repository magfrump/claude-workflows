# Spike: What staleness heuristic should doc freshness tracking use?

Date: 2026-03-23
Time spent: ~10 minutes (design exercise, no throwaway code needed)

## Answer

Use a two-part heuristic: (1) a `last_verified` date field in document frontmatter/header, and (2) a `git log --since=<last_verified>` check against a list of `relevant_paths` stored in the document. If commits exist on those paths since the last verification date, the document is potentially stale.

## Key findings

- **Git log is the right primitive.** `git log --since="2026-01-15" -- workflows/ skills/` is cheap, scriptable, and produces a clear yes/no signal. The `--` separator ensures paths are treated as pathspecs, not refs.
- **Path lists must be explicit.** Implicit path inference (e.g., guessing what an onboarding doc covers) is fragile. The document itself should declare what files/directories it describes.
- **Threshold should vary by doc type.** Onboarding docs cover broad codebases — any change in tracked paths makes them potentially stale. Spike records are narrower — only changes to the specific library/API they tested matter.
- **The check is advisory.** "Stale" means "may need re-verification," not "is wrong." The agent or user decides whether to act.

## Heuristic specification

### Fields added to document headers

```markdown
**Last verified:** 2026-03-23
**Relevant paths:** workflows/, skills/fact-check.md
```

- `Last verified` — the date someone (human or agent) last confirmed the document's accuracy
- `Relevant paths` — file paths or glob patterns within the repo; changes to these paths are staleness signals

### Staleness check (for agents to execute)

```bash
# Check if any commits touch relevant paths since last verification
git log --oneline --since="2026-03-23" -- workflows/ skills/fact-check.md
```

- If output is non-empty → document is **potentially stale**
- If output is empty → document is **fresh** (no changes to tracked paths since verification)

### Staleness thresholds by doc type

| Doc type | Default check frequency | Typical relevant paths |
|---|---|---|
| Onboarding docs | Before each use / monthly | Broad: `src/`, `lib/`, top-level configs |
| Spike records | On reference | Narrow: specific libraries, APIs tested |
| Shared thoughts | Monthly or on related task | Medium: subsystem directories |
| Review artifacts | Already have `Checked:` date | Files reviewed |

### When to update `Last verified`

- After re-running the workflow that produced the document
- After manually confirming the document is still accurate
- After an agent checks the git log, reads the changes, and determines none affect the document's claims

## What this does NOT cover

- Automated scheduling of freshness checks (left to agent judgment and session-start habits)
- Staleness of decision records (these use supersession, not verification)
- Cross-repo staleness (documents referencing external systems)

## Recommendation

Proceed to implementation. The heuristic is simple enough that no further spike work is needed.

## RPI seed

- **Scope for RPI**: Add `Last verified` and `Relevant paths` fields to onboarding and research doc templates; document the staleness heuristic in a new guide or in existing workflow docs
- **Known invariants**: Existing templates must gain fields without breaking structure; disposable docs (RPI working docs) should not be burdened with freshness tracking
- **Relevant files/APIs**: `workflows/codebase-onboarding.md`, `workflows/research-plan-implement.md`, `workflows/spike.md`
- **Gotchas to carry forward**: The heuristic needs explicit path lists per document — don't try to infer them
- **What the spike did NOT answer**: Whether agents will reliably check freshness at session start (behavioral, not structural)
