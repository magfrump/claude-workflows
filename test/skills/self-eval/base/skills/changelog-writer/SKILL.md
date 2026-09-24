---
name: changelog-writer
description: >
  Draft user-facing release notes from the merged pull requests since the last
  tag. Groups changes into Added / Changed / Fixed, rewrites PR titles into
  plain language for end users, and flags breaking changes at the top. Use when
  the user asks to "write the changelog", "draft release notes", or "what
  shipped since v2.3".
---

# Changelog Writer

1. List merged PRs since the last tag with `git log <tag>..HEAD --merges`.
2. Classify each PR as Added, Changed, Fixed or Internal (Internal is omitted).
3. Rewrite each title for an end user: no ticket numbers, no internal names.
4. Put breaking changes in a **Breaking** section at the top.

Output: a Markdown section headed `## <version> — <date>`.
