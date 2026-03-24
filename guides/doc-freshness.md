# Document Freshness Tracking

## Overview

Long-lived documents — onboarding guides, spike records, shared thoughts — can go stale when the code they describe changes. This guide defines a lightweight heuristic for detecting staleness using git history.

## Freshness fields

Documents that benefit from freshness tracking include two fields in their header:

```markdown
**Last verified:** 2026-03-23
**Relevant paths:** src/, lib/auth.ts, configs/
```

- **Last verified** — the date someone (human or agent) last confirmed the document's accuracy against the current codebase.
- **Relevant paths** — repo-relative file paths or directory globs. Changes to these paths are the primary staleness signal.

## Staleness check

Run this command to see if tracked paths have changed since the document was last verified:

```bash
git log --oneline --since="<Last verified date>" -- <relevant paths>
```

For example, for an onboarding doc verified on 2026-03-23 tracking `workflows/` and `skills/`:

```bash
git log --oneline --since="2026-03-23" -- workflows/ skills/
```

- **Non-empty output** → the document is **potentially stale**. Read the commits to determine if the changes affect the document's claims.
- **Empty output** → the document is **fresh**. No changes to tracked paths since last verification.

## Which documents to track

| Doc type | Track freshness? | Reason |
|---|---|---|
| Onboarding docs | Yes | Long-lived, broad scope, high staleness risk |
| Spike records | Yes | Referenced later; API/library behavior may change |
| Shared thoughts | Yes | Living docs that accumulate assumptions |
| Review artifacts | Already tracked | Use existing `Checked:` date field |
| Decision records | No | Superseded by new decisions, not verified |
| RPI working docs | No | Disposable per-task; overwritten, not maintained |

## When to check freshness

- **At session start**: If loading an onboarding doc or shared thought as context, run the staleness check first.
- **Before referencing a spike**: If citing a spike record's findings, verify the spike hasn't been invalidated.
- **Periodically**: Monthly for frequently-referenced documents.

## When to update `Last verified`

Update the date when:
- You re-run the workflow that produced the document (e.g., re-onboarding)
- You manually confirm the document's claims are still accurate
- You run the staleness check, read the commits, and determine none affect the document's content

Do **not** update the date just because you read the document — only when you've verified its accuracy.

## Updating `Relevant paths`

When a document's scope changes (e.g., it now covers a new subsystem), update the relevant paths list. When files are renamed or moved, update the paths to match.

Paths should be specific enough to produce useful signals but not so narrow that changes slip through. A directory path like `src/auth/` is usually better than listing individual files, unless the document is specifically about one file.
