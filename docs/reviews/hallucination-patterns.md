# Code Fact-Check: Hallucination Patterns

This file records **confirmed-hallucination patterns** observed by the `code-fact-check` skill in this project. A hallucination pattern is a fabricated claim — a comment, docstring, or doc that asserts the existence of a symbol, method, API, or behavior that does not actually exist in the code, the language, or any imported library.

This log is **project-scoped**: each project keeps its own. It is **append-only** and grows over time as fact-check runs surface repeat fabrications.

## How this log is used

- **Before each fact-check run**, `code-fact-check` reads this file and treats every entry as a known suspect pattern. While checking claims in scope, the skill explicitly flags any claim that matches a logged pattern.
- **After each fact-check run**, when a claim earns an `Incorrect` verdict because a referenced symbol/API/behavior is fabricated (not merely renamed, miscounted, or stale), the skill appends a one-line entry below.

Not every `Incorrect` verdict belongs here. Stale renames, off-by-one complexity claims, and outdated configuration values are tracked in the per-run report only. Reserve this log for fabrications.

## Entry format

```
- **<short pattern>** — <one-line description of why the claim is false>. First seen: YYYY-MM-DD, report: <path/to/report.md>.
```

Keep `<short pattern>` short and normalized so future runs can grep for it (e.g., `Array.prototype.last claimed but does not exist`). Deduplicate by short pattern text — if the same fabrication appears in a new report, update the existing entry's report list rather than adding a duplicate.

## Patterns

<!-- Append entries below this line. -->
