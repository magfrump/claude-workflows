# Document Freshness Tracking

## Overview

Long-lived documents — onboarding guides, spike records, shared thoughts — can go stale when the code they describe changes. This guide defines a lightweight heuristic for detecting staleness using git history.

## Freshness fields

Documents that benefit from freshness tracking include two fields in their header. There are two supported formats:

**Inline bold fields** — used in onboarding docs, spike records, and shared thoughts:

```markdown
**Last verified:** 2026-03-23
**Relevant paths:** src/, lib/auth.ts, configs/
```

**YAML frontmatter** — used in review artifacts (`docs/reviews/`):

```yaml
---
Last verified: 2026-03-23
Relevant paths:
  - skills/draft-review.md
  - skills/fact-check.md
---
```

Both formats carry the same two fields:

- **Last verified** — the date someone (human or agent) last confirmed the document's accuracy against the current codebase.
- **Relevant paths** — repo-relative file paths or directory globs. Changes to these paths are the primary staleness signal.

Use YAML frontmatter for review artifacts (it is parseable by tooling and clearly separated from document content). Use inline bold fields for other document types.

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
| Review artifacts | Yes | Long-lived; stale reviews mislead future sessions |
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

## Review artifact lifecycle

Review artifacts in `docs/reviews/` use the same `Last verified` and `Relevant paths` YAML frontmatter fields as other tracked documents. Because reviews analyze specific code, their freshness is tied to the files they reviewed.

### When to re-run a review

Run the staleness check against the review's `Relevant paths`. If tracked paths have changed since `Last verified`, the review may contain findings that no longer apply or may be missing findings about new code. Re-run the skill or orchestrator that produced the review.

### When to archive a review

If the reviewed content has been deleted or substantially replaced (e.g., a skill was removed from the repo), the review is obsolete. Move it out of `docs/reviews/` or delete it. A review of code that no longer exists actively misleads future sessions.

### When to leave a review alone

If the staleness check returns empty (no changes to tracked paths), the review is fresh. No action needed — update `Last verified` if you've confirmed this.

### Relevant paths for reviews

The `Relevant paths` in a review's YAML frontmatter (see format in [Freshness fields](#freshness-fields)) should list the files the review analyzed -- these are the files whose changes would invalidate the review's findings. Do not include files that merely appeared in the same diff but were not the subject of the review's analysis.
