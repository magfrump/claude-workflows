# Code Review Override Log

This file records **human overrides** of the code-review pipeline's verdicts.
An override is any case where a human reviewer or author downgraded a
🔴 Must-Fix to 🟢/Won't-Fix, promoted a 🟢 Consider (Nit) to 🟡/🔴, or
otherwise contradicted the automated rubric. The point of capturing these is
twofold:

1. **Calibration.** Over time the entries here reveal where the pipeline is
   too noisy (frequent Must-Fix → Won't-Fix on a particular finding category)
   or too lenient (frequent Nit → Must-Fix). That feeds critic skill tuning.
2. **Consistency.** Future runs of `code-review` MUST consult this log
   before rendering findings. If a prior override applies to a finding in
   the current diff (same location, same category, or substantively the
   same claim), the orchestrator surfaces the considered override in its
   output so reviewers see the history rather than re-arguing the same
   call.

## Capture format

Each override is one row in the table below. Required fields:

| Field | Meaning |
|---|---|
| `Date` | ISO date the override was applied (YYYY-MM-DD). |
| `PR ref` | PR number, commit hash, or branch where the override originated. Use `#N` for GitHub PRs, short SHA otherwise. |
| `Finding` | One-line summary of the finding. Include `path/to/file:line` location so future matches can be detected by file/line proximity. Quote the original wording where possible. |
| `Original verdict` | What the pipeline produced — `🔴 Must-Fix`, `🟡 Must-Address`, `🟢 Consider`, or `Nit` (informal Consider-tier wording). |
| `Override verdict` | What the human decided — `Won't-Fix`, `Defer`, `🟡 Must-Address`, `🔴 Must-Fix`, etc. Use the same vocabulary as `Original verdict` where applicable. |
| `Reason` | Why the human deviated. Be specific enough that a future reader can decide whether the reasoning still applies (e.g., "test-only file, internal-use", "deprecated module — rewrite scheduled in #482", "stylistic Nit; team prefers verbose form here"). |

Keep rows short. If a rationale needs more than ~30 words, link to a PR
comment, decision record, or `docs/decisions/NNN-*.md` from the `Reason`
cell rather than expanding the row.

## How `code-review` uses this log

On every run, the `code-review` skill scans this file as part of its
preamble (see `skills/code-review.md` Step 3.5 — "Scan the override log
for prior decisions matching the current diff"). Any entry whose
`Finding` location or category overlaps the current diff is held as a
*considered override* and surfaced in both the chat synthesis (under
`### Considered overrides`) and the structured rubric (in the affected
row's `Author note` / `Considered overrides` column). This prevents the
log from being write-only and forces reviewers to engage with prior
calls rather than silently re-arguing them.

If no prior override matches, the rendered output explicitly states so —
silent absence is not allowed, otherwise readers cannot distinguish
"checked and found nothing" from "forgot to check."

## Entries

<!--
Add new entries at the top so the most recent decisions are easiest to
scan. Preserve the column order. If a finding came from a critic other
than the core trio (e.g., ui-visual-review), name the critic in the
`Finding` cell so domain filters work later.
-->

| Date | PR ref | Finding | Original verdict | Override verdict | Reason |
|---|---|---|---|---|---|
| 2026-06-23 | `feat/batch-feedback-subagent-routing` (#35) | Hook fires on every UserPromptSubmit incl. agent/tool notifications (`hooks/batch-feedback-routing-reminder.sh`, whole script) — security-reviewer Low + orchestrator observation (C1) | 🟢 Consider | Won't-Fix (intended) | Reminder targets the model not the human (no alert-fatigue); non-human submits are valid fan-out points; cost ~85 tok/firing. Broad firing preferred. |
