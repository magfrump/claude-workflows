---
name: api-changelog-diff
description: >
  Compare two versions of an OpenAPI spec and list every consumer-visible
  change, classified as breaking (removed endpoint, removed or newly required
  field, narrowed enum, changed type) or non-breaking (new endpoint, new
  optional field, widened enum). Use when the user asks "what changed between
  these two specs", "is this spec change breaking", or before publishing a new
  API version.
---

# API Changelog Diff

1. Load both specs; resolve `$ref`s.
2. Match operations by method + path, schemas by name.
3. Classify each difference as breaking or non-breaking using the table above.

Output: `## Breaking` and `## Non-breaking` sections, one bullet per change,
each citing the JSON pointer of the changed element.
