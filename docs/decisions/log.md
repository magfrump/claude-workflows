# Decision Log

This log captures **small, self-contained decisions** — each fully expressed in a single table row. Full decision records (`NNN-title.md`) are separate documents for decisions that need structured analysis, multiple options, and tradeoff discussion.

## When to use log vs. full record

| | Log entry (this file) | Full record (`NNN-title.md`) |
|---|---|---|
| **Scope** | Single clear answer, minimal tradeoffs | Multiple viable options with meaningful tradeoffs |
| **Options evaluated** | 1–2 (obvious winner) | 3+ (required deliberation) |
| **Rationale fits in** | A sentence or two | Multiple paragraphs or sections |
| **Consequences** | Straightforward and local | Non-obvious, cross-cutting, or worth revisiting |
| **Process** | Direct decision | Benefits from [divergent-design](../../workflows/divergent-design.md) or structured review |

**Rule of thumb:** if you can state the decision, context, and rationale in one table row below, it belongs here. If you find yourself wanting subsections, options lists, or "consequences" — promote it to a full record. When in doubt, start with a log entry — you can always promote it later if the rationale turns out to be more nuanced than you thought.

## Cross-referencing

Log entries that later get a full record should link to it in the **Full Record** column (see entry #6 below for an example). Full decision records do not need to back-link here.

| # | Date | Decision | Context / Why | Full Record |
|---|------|----------|---------------|-------------|
| 1 | 2026-03-23 | Create lightweight decision log | Small decisions were undocumented; full DD records are too heavy for one-line choices | — |
| 2 | 2026-03-23 | Critic-style code review via standalone critics then orchestrator | CC/YC prose critic pattern proven effective; apply domain-specific cognitive moves to code diffs | [002](002-critic-style-code-review.md) |
| 3 | 2026-03-20 | Add critic cognitive moves as DD stress-test lenses | DD tradeoff matrix misses failure modes that structured critique catches; two-pass evaluation | [003](003-critic-moves-in-divergent-design.md) |
| 4 | 2026-03-20 | Build 5 complementary skills and workflows from DD gap analysis | Onboarding workflow, test-strategy, tech-debt-triage, dependency-upgrade skills, RPI refactoring variant | [004](004-complementary-skills-and-workflows.md) |
| 5 | 2026-03-23 | Tiered validation pipeline for self-improvement loop | Auto-approving all branches risks poisoning subsequent rounds; need unattended validation | [005](005-validation-step-self-improvement.md) |
| 6 | 2026-03-26 | Foreground tests as human-LLM interface in RPI | Tests are among the most precise forms of behavioral specification; restructure RPI to make test design a planning activity | [006](006-foregrounding-tests.md) |
| 7 | 2026-04-06 | Restructure pr-prep into two phases (content → packaging) | Size check was last (wasted work on split), commit cleanup before review (rebasing unstable code), CI redundant before review-fix loop | [007](007-two-phase-pr-prep.md) |
| 8 | 2026-04-06 | Decouple hypotheses from implementation; screen before building | Features should be validated by external evidence before implementation; most candidates should be filtered out | [008](008-hypothesis-screening-workflow.md) |
| 9 | 2026-04-08 | Replace internal hypothesis optimization with human feedback integration | Hypothesis quality guide optimized for confirmability over value; external impact is the real target; added feedback file + review questionnaire | [009](009-human-feedback-integration.md) |
