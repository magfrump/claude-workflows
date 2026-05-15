# Checkpoint: rpi-test-strategy-auto-invoke
Date: 2026-05-15
Branch: feat/r1-rpi-test-strategy-auto-invoke
Research: docs/working/research-rpi-test-strategy-auto-invoke.md
Plan: docs/working/plan-rpi-test-strategy-auto-invoke.md

## Project state
- **Branch purpose**: Add auto-invoke of `/test-strategy` at the end of RPI step 3, with a short-circuit when the user has already invoked the skill manually for this loop.
- **Position in larger initiative**: standalone — incremental refinement of the RPI workflow doc; no parent epic, no sibling branches in flight.
- **Blocked on**: nothing.

## Key findings

- The auto-invocation is a procedural addition to RPI step 3, not a new section in the plan-doc template. The plan template's **Test specification** bullet (current format: table of Test case · Expected behavior · Level · Diagnostic expectation) stays as-is; the auto-invocation produces the rows that fill it. [observed in `workflows/research-plan-implement.md` L178–L196]
- The `test-strategy` skill writes its persisted output to `docs/working/test-strategy-{topic}.md` per its SKILL.md L232. The short-circuit must use this exact name — the user described it as `test-plan-*.md` in the task, but using that name would mean the short-circuit never triggers. [observed in `~/.claude/skills/test-strategy/SKILL.md`]
- The skill's gap list (`## Untested Paths Touched by the Change`, numbered G1, G2, …) is the mandatory section of its output. The Recommended Tests rows reference those gaps via `**Closes gaps:** [G1, G3]`. Both flow into the plan's Test specification subsection — gaps are documented and recommended tests become rows in the existing table. [observed in SKILL.md L179–L216]
- Step 2 of RPI already has prior art for auto-invoking another workflow inline: the "Design decisions during research" paragraph (L107) auto-invokes `divergent-design.md` when 3+ approaches surface. The new test-strategy sub-step should use the same shape: short paragraph naming the skill, the trigger, and the output flow. [observed]

## Plan

1. Append a one-line forward pointer to the **Test specification** bullet (~L196) noting that the section is populated by the auto-invoke sub-step.
2. Insert a `#### Test strategy auto-invoke` H4 sub-step between the **Risks** bullet (L217) and the existing `#### Checkpoint generation` H4 (L219). The sub-step body covers: the auto-invocation cue; how the gap list and Recommended Tests rows fold into the Test specification subsection; the short-circuit (`docs/working/test-strategy-{topic}.md` already exists for this loop's `{topic}`); the failure-mode note (no-gaps or skill-fails → author owns the section).
3. Add one bullet to the step 3 **Done when…** checklist (L269–L279) covering the auto-invoke (ran or short-circuited; gap list reflected in the Test specification subsection).

Implementation order: `1 → 2 → 3` — sequencing is for diff readability; the three edits are independent regions of the same file.

## Invariants

- The plan-doc body-section list order and the step 3 Done-when checklist must stay in lockstep — adding a body section without a matching checklist entry (or vice versa) creates silent drift.
- The Test specification bullet's table format is the plan-doc contract; the auto-invocation produces rows for that table, it does not replace the format with the skill's full report.
- Short-circuit uses `docs/working/test-strategy-{topic}.md` (the skill's canonical output name), not `test-plan-*.md`.
- Auto-invocation is an aid, not a gate — if the skill returns no gaps or fails, the plan author owns the Test specification section.

## File map

- `workflows/research-plan-implement.md` — three localized edits per the plan (forward pointer on the Test specification bullet; new H4 sub-step before Checkpoint generation; one Done-when bullet).
- `docs/working/research-rpi-test-strategy-auto-invoke.md` — research artifact (already written).
- `docs/working/plan-rpi-test-strategy-auto-invoke.md` — plan artifact (already written).
- `docs/working/checkpoint-rpi-test-strategy-auto-invoke.md` — this file.

## Open questions

- None. The task description's `test-plan-*.md` phrasing is reconciled to `test-strategy-{topic}.md` in the plan's Risks section; if a reviewer disagrees, the change is a one-string update.
