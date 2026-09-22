# Code Review Override Log

This file records **overrides** of the code-review pipeline's verdicts.
An override is any case where a human reviewer or author downgraded a
🔴 Must-Fix to 🟢/Won't-Fix, promoted a 🟢 Consider (Nit) to 🟡/🔴, or
otherwise contradicted the automated rubric. One row kind is machine-written:
an `Accepted-immutable` row, which the `code-review` orchestrator appends
without a human decision when a fact-check finds a claim wrong in history no
new commit can edit (see *Accepted-immutable rows* below). The point of
capturing these is twofold:

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
| `Original verdict` | What the pipeline produced — `🔴 Must-Fix`, `🟡 Must-Address`, `🟢 Consider`, or `Nit` (informal Consider-tier wording). For an `Accepted-immutable` row only: `Fact-check Incorrect` (the finding never received a tier). |
| `Override verdict` | What the human decided — `Won't-Fix`, `Defer`, `🟡 Must-Address`, `🔴 Must-Fix`, etc. — or `Accepted-immutable` for the machine-written kind. Use the same vocabulary as `Original verdict` where applicable. |
| `Reason` | Why the human deviated. Be specific enough that a future reader can decide whether the reasoning still applies (e.g., "test-only file, internal-use", "deprecated module — rewrite scheduled in #482", "stylistic Nit; team prefers verbose form here"). |

**`Accepted-immutable` rows (machine-written).** A fact-check Incorrect about
a claim in an already-merged commit message, or any artifact no new commit can
edit, is not tiered (the immutable-history exception in
`skills/code-review/references/rubric.md`, *Unified Severity Mapping*). The
orchestrator appends a row with `Original verdict: Fact-check Incorrect` and
`Override verdict: Accepted-immutable` during the run; it is the only row kind
written without a human decision, and no other verdict is ever written
automatically. The `Reason` cell starts with `[auto: code-review]` followed by
the immutable artifact, and `PR ref` names the run's PR or branch. Step 3.5
treats these rows like a settled `Won't-Fix`: the same immutable claim is not
re-raised. Older `Accepted-immutable` rows below that lack the `[auto: …]`
prefix were written by hand before the kind was formalized. The canonical
definition is `skills/code-review/references/override-log.md#capture-format`.

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
| 2026-09-21 | `answers-2026-09-20` | Commit `4c7a2bb` message: "Global paths are unchanged" (and "matching wiring.json") — fact-check Incorrect (high), Claim 6, r1+r2 Incorrect, r3 Mostly accurate. Refuted at `hooks/guard-trusted-writes.py:56-132`: the Bash HARD tier for the global CLAUDE.md now matches only literal spellings, and nested/`..`/symlinked global paths moved HARD→SOFT. | Fact-check Incorrect | Accepted-immutable | [auto: code-review] merged commit 4c7a2bb message misstates that global path handling is unchanged; cannot be edited. Live defects are R1/R4 in `code-review-rubric-2026-09-21-answers-2026-09-20.md`. |
| 2026-09-12 | `cb5351d` | `skills/ui-visual-review/SKILL.md:58` kept a `## Mandatory Execution Rules` block after prompt-audit F3 rewrote the same-named blocks in the three orchestrators — flagged by api-consistency (naming table) and test-strategy (G13/T9). | 🟢 Consider | Heading renamed; rule body exempt from F3 | Critic, not orchestrator: the five rules are distinct domain guidance, not one contract inflated into MUST-rules, and the block carries none of F3's markers (no absolute-rules preamble, no MUST/No-exceptions, no later restatement). Heading renamed to `## Execution rules` for consistency; prose rewrite declined. |
| 2026-09-12 | `59ca38f` | "All 85 tests across the code-review suites pass" — fact-check Incorrect (high), k=3 unanimous. Real count: 97 across the seven `test/skills/code-review-*.bats` suites, 53 across the four this commit modified. | 🟡 Must-Address | Accepted-immutable | Claim lives in a merged commit message; no new commit can edit it. The editable copy at `docs/reviews/prompt-audit-2026-09-11.md` was corrected. Logged so the miscount is not re-raised as a live finding. |
| 2026-09-12 | `c56be81` | "health-check failures are identical to the pre-change baseline (four, all pre-existing)" — fact-check Incorrect (high), r1+r3. Real count: six (four shellcheck + two MD-consistency). The identity and all-pre-existing halves are both confirmed. | 🟡 Must-Address | Accepted-immutable | Same reason: immutable commit message. The two omitted failures were fixed on 2026-09-12, so the number is now moot as well as unfixable. |
| 2026-06-23 | `feat/batch-feedback-subagent-routing` (#35) | Hook fires on every UserPromptSubmit incl. agent/tool notifications (`hooks/batch-feedback-routing-reminder.sh`, whole script) — security-reviewer Low + orchestrator observation (C1) | 🟢 Consider | Won't-Fix (intended) | Reminder targets the model not the human (no alert-fatigue); non-human submits are valid fan-out points; cost ~85 tok/firing. Broad firing preferred. |
