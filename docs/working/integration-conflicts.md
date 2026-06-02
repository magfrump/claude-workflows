# Integration-conflict rationale log

This log persists the **rationale** for each conflict resolution made during an
[Integration branch refresh](../../workflows/branch-strategy.md#integration-branch-refresh) — *why* a
hunk was resolved a given way, which the resolved code alone cannot tell you.

## Why this exists

The refresh procedure's step 4 recovers a prior resolution's *code* with
`git show <previous-integration-branch>:<path>`. That shows **what** the merge produced, but not
**why** — which side was authoritative, which change was intentionally dropped, what made the two
sides conflict, or what would make the resolution go stale. Without the *why*, the next refresh either
blind-applies a resolution that may now be wrong, or re-derives it from scratch, repeating reasoning
that was already done. This log closes that gap.

`git show` answers "what code resulted"; this log answers "why that code, and when to distrust it."

## How it's used (refresh step 4)

- **On the next build — grep before resolving.** Before resolving a conflict in `<path>`, grep this
  log for prior rationale on that path:
  ```bash
  grep -n -A8 '<path>' docs/working/integration-conflicts.md
  ```
  Read the rationale to recover the *intent* of the earlier resolution, then re-verify against the
  current two sides — the resolution may have gone stale (see the `staleness signal` field and the
  procedure's re-verify discipline).
- **On each resolution — append after resolving.** Once a conflict is resolved, append an entry
  (template below) recording why you resolved the hunk the way you did.

The grep key is the **file path**, mirroring `git show <previous-integration-branch>:<path>` — the
same handle locates both the prior code and the prior rationale.

## Entry template

Copy this block per resolved conflict. Keep the `path:` line intact and on its own line so
`grep '<path>'` finds it. Newest entries go at the top of **Entries**.

```markdown
### <YYYY-MM-DD> · dev-refresh-<YYYY-MM-DD>

- **path:** `<path>`
- **PR:** #<n> `<headRef>`
- **region:** <function / section / line span that conflicted>
- **ours / theirs:** <one line each: what each side changed>
- **resolution:** <what the merged hunk ended up as>
- **rationale:** <why — which side was authoritative and why, what was intentionally dropped or kept,
  what made the sides diverge>
- **staleness signal:** <what change to either side would make this resolution wrong — e.g. "if PR #<n>
  revises <fn>, re-derive from scratch">
- **origin:** replayed-from-prior | first-principles (no prior reference — step 5)
```

## Entries

<!-- newest first; append new entries directly below this comment -->

_No entries yet — the first Integration branch refresh that resolves a conflict adds the first one._
