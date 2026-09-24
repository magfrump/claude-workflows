---
name: release-risk-notes
description: >
  Before a production deploy, write a one-page risk note for the on-call
  engineer: what changed since the last deploy, which changes touch payment,
  auth or data-deletion paths, which have no feature flag, and the first three
  dashboards to watch. Use when the user says "write the deploy risk note",
  "what should on-call watch for this release", or "brief on-call before we
  ship".
---

# Release Risk Notes

1. Diff the release candidate against the currently deployed tag.
2. Tag each change: payment / auth / data-deletion / other.
3. For each tagged change, record whether a feature flag guards it.
4. Pick the three dashboards most relevant to the tagged changes.

Output: a note headed `# Deploy risk — <release>` with sections **Changes**,
**Unflagged risky changes**, **Watch first**.
