# Ideas Backlog

Structured backlog for feature ideas surfaced during divergent-design (DD) rounds.
Each idea carries lifecycle metadata so stale entries are pruned automatically.

## Lifecycle Rules

### Statuses

| Status | Meaning |
|--------|---------|
| **active** | Open for consideration in future DD rounds |
| **selected** | Chosen for implementation (link to plan/PR) |
| **deferred** | Intentionally postponed — revisit later |
| **archived** | Pruned as stale or superseded; kept for reference |

### Staleness Rule (round-based)

An idea is **stale** when all of the following are true:
- Its `Last Evaluated Round` is more than **3 rounds** behind the current round
- It has **never** been selected for implementation
- It is still in **active** status

During the DD diverge step, stale ideas MUST be moved to **archived** status
with a note in the `Notes` column (e.g., "archived: stale after 3 rounds").

This rule is enforced by an instruction in the [divergent-design workflow](../../workflows/divergent-design.md) diverge step.

### Measuring staleness reduction

To evaluate whether this lifecycle reduces stale idea carry-over, count the
number of stale ideas (active, >3 rounds old, never selected) present at the
start of each DD round. Compare rounds after this structure was introduced
against the baseline (rounds 1-4 under the flat-file approach). The hypothesis
predicts a ≥50% reduction.

## Current Round

**Round 5** (2026-04-08)

## Backlog

| ID | Idea Summary | Date Added | Status | Last Evaluated Round | Tags | Notes |
|----|-------------|------------|--------|---------------------|------|-------|
| IB-01 | Cross-session handoff doc format for RPI workflow | 2026-03-23 | active | R4 | session-continuity, rpi | Tier 1 priority from R1 DD |
| IB-02 | Retrospective appendix to pr-prep workflow | 2026-03-23 | active | R4 | feedback-loop, pr-prep | Tier 1 priority from R1 DD |
| IB-03 | Self-evaluation skill reading evaluation rubric at runtime | 2026-03-23 | active | R4 | skills, evaluation | Tier 2; needs manual rubric validation first |
| IB-04 | Research doc freshness tracking with "last verified" field | 2026-03-23 | selected | R4 | docs, freshness | Implemented in CLAUDE.md and doc-freshness guide |
| IB-05 | Lightweight decision log at docs/decisions/log.md | 2026-03-23 | selected | R4 | decisions, docs | Done — log.md exists |
| IB-06 | Workflow chaining syntax for multi-step pipelines | 2026-03-20 | archived | R1 | workflows, composition | Rejected R1: prose cross-refs sufficient |
| IB-07 | Diff-aware workflow selector | 2026-03-20 | archived | R1 | workflows, selection | Rejected R1: CLAUDE.md summaries adequate |
| IB-08 | Plan diff tracking for revision visibility | 2026-03-20 | archived | R1 | rpi, plans | Rejected R1: git diff achieves this |
| IB-09 | Workflow templates / scaffolding | 2026-03-20 | archived | R1 | workflows, tooling | Rejected R1: agents generate format from description |
| IB-10 | Parallel session orchestrator skill | 2026-03-20 | archived | R1 | skills, parallelism | Rejected R1: changes repo role to automation tool |
| IB-11 | Pipeline visualization for orchestrator skills | 2026-03-20 | archived | R1 | skills, visualization | Rejected R1: maintenance burden for single maintainer |
| IB-12 | Confidence-calibrated gates in validation pipeline | 2026-03-20 | archived | R1 | workflows, gates | Rejected R1: no demonstrated need beyond active/away |
| IB-13 | Skill composition / piping between skills | 2026-03-20 | archived | R1 | skills, composition | Rejected R1: agent tool limitations make impractical |
| IB-14 | Do-nothing option (status quo baseline) | 2026-03-20 | archived | R1 | meta | Rejected R1: real problems identified |
| IB-15 | Ideas backlog with lifecycle management | 2026-04-08 | selected | R5 | meta, backlog | This task — implementing now |

## Adding New Ideas

When adding a new idea during a DD round:
1. Assign the next `IB-NN` ID
2. Set `Date Added` to today
3. Set `Status` to **active**
4. Set `Last Evaluated Round` to the current round
5. Add 1-3 topic `Tags` (lowercase, hyphenated)
6. Leave `Notes` empty or add brief context
