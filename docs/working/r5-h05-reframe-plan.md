# R5: H-05 Reframe-or-Retire Plan

## Problem

H-05 as written: "Skills are invoked more frequently than workflows in external projects."

User feedback: the comparison is structurally untestable because the denominators differ. There are 21 skills and 11 workflows on disk today. A raw-total comparison answers "which pile has more events" — which is a function of how many items are in each pile, not which kind of artifact gets used more per item.

Concretely from `~/.claude/logs/usage.jsonl` (2026-05-12 snapshot):
- 2221 skill events / 21 skills = ~105.8 invocations per skill
- 1304 workflow events / 11 workflows = ~118.5 invocations per workflow

Raw totals favor skills (2221 > 1304). Per-item rates favor workflows (118.5 > 105.8). The verdict flips depending on whether you normalize. Both can't be right; the original framing chose neither and is therefore not falsifiable.

## Decision

**Reframe**, not retire. The underlying question ("which kind of artifact gets reached for more readily?") is worth answering — just not with raw counts. Normalize by available-item count and bound the test with a factor and window.

## Reframed hypothesis

> In external projects (project ≠ "claude-workflows"), the mean per-skill invocation rate exceeds the mean per-workflow invocation rate by a factor of ≥1.5 over any 30-day rolling window since the logging fix landed (2026-04-09).

Where:
- **Mean per-skill rate** = skill events in window ÷ count of skills available on disk at window end
- **Mean per-workflow rate** = workflow events in window ÷ count of workflows available on disk at window end
- **Data source**: `~/.claude/logs/usage.jsonl`, filtering `event ∈ {skill, workflow}` and `project != "claude-workflows"`
- **Available counts**: `ls ~/.claude/skills/ | wc -l` and `ls ~/.claude/workflows/ | wc -l` at the window-end date

## Falsification

- **CONFIRMED** if the ratio (skill_rate / workflow_rate) ≥ 1.5 in ≥80% of 30-day rolling windows since 2026-04-09
- **REFUTED** if the ratio < 1.5 in every 30-day window since 2026-04-09 (skills do not dominate per-item)
- **INCONCLUSIVE** if the ratio is mixed (between 1.0 and 1.5, or oscillating across the threshold)

K=1.5 picked as a meaningful effect — anything smaller is likely noise from which category recently shipped new items. W=30d matches the post-fix data we have and absorbs weekly cadence variation.

## Rationale for keeping the rest of the row

- **Evidence Sources**: tighten to specifically reference `usage.jsonl` (it was already there, but the entry-point script is the load-bearing detail)
- **Status**: stays TRACKING — the logging fix unblocked this, but no measurement has been run yet under the new framing
- **Last Checked**: 2026-05-12 (reframe date)
- **Evidence Summary**: replace the "blocked on logging fix" note with a snapshot of why the original framing was untestable plus the current numbers showing the flip

## Files touched

- `docs/working/hypothesis-backlog.md` — replace H-05 row
- `docs/working/r5-h05-reframe-plan.md` — this file (planning artifact)

No other files in scope. The reframing is self-contained.
