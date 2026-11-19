# Research: parallel-worktrees subagents return reports as text

Brief: `docs/working/briefs/2026-11-19-subagent-report-as-text.md` (at a5223578). Branch: `docs/subagent-report-as-text`.

## What the feedback entries record (criterion 1)

- **philosophy-research F-011** (`docs/working/feedback/philosophy-research.md`, 2026-11-05): a batch fan-out subagent in an isolated worktree was told to write and commit a report under `docs/thoughts/`. The Write tool refused it ("Subagents should return findings as text, not write report files"). The same subagent's handoff under `docs/working/` was accepted. The parent placed the report from the final message; a second unit committed a draft under `docs/working/` and the parent moved it.
- **belegarth-herald F-010** (`docs/working/feedback/belegarth-herald.md`, 2026-11-07): two review subagents (a critic and a fact-check) started by a build loop were refused writing their reports into their own scratch directories. Not a parallel-worktrees run, but the same refusal.

So the refusal covered **report files**, both under `docs/thoughts/` and in a scratch directory. It did **not** cover a handoff under `docs/working/` (accepted). Neither entry mentions code; nothing recorded shows code being refused, so the change leaves code with the subagent as now and claims no more than that.

## Current workflow text

`workflows/parallel-worktrees.md` step 3 tells each implementing subagent to "commit its work inside its worktree"; it has no case for a report deliverable. Step 4 reviews and merges per item. The router `skills/parallel-worktrees/SKILL.md` is a pure pointer and does not restate the rule, so it is unchanged (criterion 3).

Tests that name the workflow: `test/workflow-required-sections.bats` (required sections) and `test/pivot-consistency.bats` (pivot targets). Neither pins step 3 or step 4 text.

Failure-pattern grep: FP-011, FP-013, FP-014, FP-062, FP-068

(grep `-inE 'parallel-worktrees|worktree|subagent|report-file|write-refus|return-findings'`; every hit is worktree-script mechanics, none about subagent writes, so none changes the plan.)

## Design notes (no choice had 3+ viable options)

- Where the parent places the report: in the item's worktree, as the brief requires, so it goes through step 4 like any item. Added: a harness worktree with no changes is auto-cleaned, so a report-only item uses a by-hand worktree (the manual fallback).
- Step 4 placement: a lead paragraph before the numbered list rather than a new list item, so existing references to "step 4.3"/"4.4" in reviews and decision log row 59 keep their meaning.
- The failure-modes "Lost work" bullet is extended to a returned report never written down; no new section.

## Plan

1. Step 3: add a bullet "A report comes back as text", citing the refusal and scoped to report files.
2. Step 4: add a "Place returned reports first" paragraph.
3. Extend "Lost work".
4. Run the two bats files and the health check; review-fix loop; set the brief's Status to done.

## Review

Round 1 (independent general-purpose reviewer, read-only, report returned as text): no Incorrect findings; two Unclear and three Nits. Fixed in 559e7804: the no-worktree rule for read-only items now excepts a report to be committed; the refused path is narrowed to `docs/thoughts/`; code is stated as "no refused write recorded" rather than inferred; the brief names the report's destination path. Nit 5 (the manual-fallback trigger list does not name report-only items) left as is: step 4 points to the fallback directly. Delta re-checked by hand; `test/workflow-required-sections.bats`, `test/pivot-consistency.bats` and `scripts/health-check.sh` pass. No `fix(...)` commits, so no failure-pattern entry is due.
