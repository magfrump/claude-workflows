# Decision Log

This log captures **small, self-contained decisions** — each fully expressed in a single table row. Full decision records (`NNN-title.md`) are separate documents for decisions that need structured analysis, multiple options, and tradeoff discussion.

## When to use log vs. full record

| | Log entry (this file) | Full record (`NNN-title.md`) |
|---|---|---|
| **Scope** | Single clear answer, minimal tradeoffs | Multiple viable options with meaningful tradeoffs |
| **Options evaluated** | 1–2 (obvious winner) | 3+ (required deliberation) |
| **Rationale fits in** | A sentence or two | Multiple paragraphs or sections |
| **Consequences** | Straightforward and local | Non-obvious, cross-cutting, or worth revisiting |
| **Process** | Direct decision | Benefits from divergent-design or structured review |

**Rule of thumb:** if you can state the decision, context, and rationale in one table row below, it belongs here. If you find yourself wanting subsections, options lists, or "consequences" — promote it to a full record.

| # | Date | Decision | Context / Why | Full Record |
|---|------|----------|---------------|-------------|
| 1 | 2026-03-23 | Create lightweight decision log | Small decisions were undocumented; full DD records are too heavy for one-line choices | — |
| 6 | 2026-03-26 | Foreground tests as human-LLM interface in RPI | Tests are the most precise form of requirements; restructure RPI to make test design a planning activity | [006](006-foregrounding-tests.md) |
