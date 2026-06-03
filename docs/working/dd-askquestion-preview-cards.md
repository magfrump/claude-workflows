- **Goal**: Make DD step-4 Path B populate each `AskUserQuestion` option's `preview` field with that candidate's expanded card, so focusing an option natively renders its full evaluation (scorecard row + stress-test moves + verbatim hypothesis) instead of leaving the during-decision matrix as fenced text the user scrolls past.
- **Project state**: feat/r2 branch delivering the Path-B preview-card enrichment · part of the DD AskUserQuestion-rendering line of work · not blocked.
- **Task status**: complete (all 5 plan steps implemented in workflows/divergent-design.md)

## Research

The target file is `workflows/divergent-design.md`. The relevant surfaces:

- **Region 2 — Candidate cards (drill-down target)** (lines ~210–227): already specifies an expanded card carrying the falsifiable hypothesis verbatim, every stress-test move applied and what it changed, and coverage broken out hard/soft. The example card runs ~12 lines (lines 213–224). This is the canonical card render used by the static drill-down (Region 3) on all paths.
- **Region 1 — Scorecard grid** (lines ~193–208): the always-rendered glyph-scored index. This is the "source surface" that must remain guaranteed.
- **`#### Decision` → Path A / B / C** (lines ~243–266):
  - Path A: dominates >80%, render static block, **no** AskUserQuestion.
  - Path B: tradeoff unclear, human present — the **only** path that issues `AskUserQuestion`. Options currently carry `label` + `description` (key downside + verbatim hypothesis). `Other` always appended. ≤4 option cap.
  - Path C: non-interactive (SI loop / overnight) — **no** prompt; static block + `## Round claim`.
- **Step-4 "Done when..."** (line ~337): the checklist item enumerating the three paths and Path B's option construction.

The `AskUserQuestion` tool supports a per-option `preview` field: "Optional preview content rendered when this option is focused." This is exactly the focus-to-expand surface the task wants.

### Invariants to preserve
- Paths A and C and the SI loop never call `AskUserQuestion` — the preview enrichment must be scoped strictly to Path B.
- The fenced scorecard grid (Region 1) stays the guaranteed source surface; the preview is an enhancement, not a relocation of data.
- The ≤4 option cap and `Other` semantics are unchanged.
- The card content == Region 2's card (no new analysis introduced), bounded ~12 lines.

## Plan

1. **Path B options construction** — add a `preview` bullet after `description`: preview = the candidate's expanded card (Region 2 format) carrying exactly its scorecard row (effort/risk/coverage/key-downside), the stress-test moves applied + what each changed, and the verbatim falsifiable hypothesis. Bound to ~12 lines. State the previews are per-option and only the focused one renders. Add a framing line: the during-decision matrix becomes a focus-to-expand surface (grid = index, focused preview = card).
2. **Source-surface guarantee** — add a bullet stating the static fenced scorecard grid (Region 1) remains the guaranteed source surface if the preview pane is unavailable or a card truncates; never move data out of the grid into preview-only.
3. **Path-B-only scope reaffirmation** — explicitly note the preview enrichment is Path B only; Paths A/C/SI loop render only the static fenced scorecard grid and never call `AskUserQuestion`.
4. **Region 2 cross-link** — add one sentence noting the card doubles as the Path B `preview` payload (single source for the card format).
5. **Done-when checklist** — update line ~337 Path B clause to include the `preview = expanded card (~12 lines), grid remains guaranteed source surface` requirement.

File scope: only `workflows/divergent-design.md` (+ this working doc).
