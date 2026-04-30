# R2: Project State header in morning-summary.md

## Goal

Add a `## Project State` section near the top of `morning-summary.md` that surfaces broader cross-round state alongside the existing per-run overview. Section content (per task brief, re-scoped from a separate dashboard file per stress-test):

1. Open-hypothesis count + 1-line summaries
2. In-flight maintenance debt (recurring deferred tasks)
3. Recent rejections by failure mode
4. Broken-pipeline status (e.g., skill-usage TRACKING)
5. Token-burn rate (rendered N/A when token-actuals data is absent — independent of r2-token-tracking-narrow)

Single-file change: `scripts/lib/si-morning-summary.sh`.

## Placement

Insert between `_summary_header` (the existing H1 + `## Run Overview`) and `_summary_whats_new`. Order in document becomes:

1. `# Morning Summary — DATE`
2. `## Run Overview`
3. `## Project State` (new)
4. `## What's New`
5. `## Gate Statistics`
6. `## Deferred Evaluation Questions`
7. `## Recording Your Responses`

Project State is "header"-positioned (above What's New) but lives below Run Overview because Run Overview is run-scoped quick stats. Project State is broader cross-time state and complements rather than replaces the run summary.

## Subsections and data sources

### Open hypotheses
- **Source:** `docs/working/hypothesis-log.md` (markdown table). An "open" hypothesis is one whose Outcome column is empty.
- **Render:** count + per-row `task_id (round R): "first ~80 chars of hypothesis"` bullets.
- **Defensive:** missing log → "Open hypotheses: 0 (no log found)".

### In-flight maintenance debt
- **Source:** `docs/working/round-changelog.md`. Parse `### Tasks deferred` sections; count occurrences of each `- **task-id**` bullet across all rounds.
- **Render:** task IDs that appear in ≥2 rounds, with deferral count.
- **Defensive:** missing changelog → suppress section with "no debt tracked".

### Recent rejections by failure mode
- **Source:** `round-${N}-report.json` for N in `start_round..end_round`. Already iterated by other helpers — reuse the pattern.
- **Render:** group rejections by failing gate name. Output: `gate_name: count (task1, task2)`.
- **Defensive:** zero rejections → render "No rejections this run."

### Broken-pipeline status
- **Source:** `docs/working/hypothesis-backlog.md`. Parse the markdown table for rows with Status containing `TRACKING` (no other modifier).
- **Render:** `H-NN: 1-line hypothesis text`.
- **Defensive:** missing file → suppress section.

### Token-burn rate
- **Source:** `docs/working/token-actuals.json` (does not exist yet — r2-token-tracking-narrow not landed).
- **Render:** When file is absent, single line `Token burn rate: N/A (token-actuals data not available)`. When present (future), the renderer will be updated by that future task; for now the absent branch is the only one needed.

## Implementation shape

Single new function `_summary_project_state()` taking `start_round end_round working_dir`. Called from `generate_morning_summary` between header and whats-new.

Helper sub-functions kept private (underscore prefix) and inlined where small.

Use awk/jq parsers with the same defensive `2>/dev/null || ...` pattern already in this file.

## Out of scope

- Token rate computation (needs r2-token-tracking-narrow to ship first).
- Adding a separate dashboard file (re-scoped away per stress-test).
- Modifying the call site in `self-improvement.sh` — function signature unchanged.
- Tests — this is a single-file render-only change with all data sources already exercised by the existing morning-summary code paths.
