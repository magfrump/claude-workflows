# Override-Log Format

Reference for the `code-review` skill. Load this file at Step 3.5 (reading the log) and
after the run (appending to it). Extracted from the skill body 2026-09-11 (prompt audit
F8). Edit here, not in the skill.

## Override-Log

The override log (`docs/reviews/override-log.md`) is the persistent record of human overrides on this skill's output. It is both an **input** to every future run (consumed in Step 3.5) and an **output** of any run whose chat synthesis produces a human decision that contradicts the rubric verdict.

### Capture format

Each override is one row in the table at the bottom of `docs/reviews/override-log.md`. The columns are:

| Field | Required | Example |
|---|---|---|
| `Date` | yes | `2026-05-12` (ISO date when the override was applied) |
| `PR ref` | yes | `#482` (GitHub PR), `a1b2c3d` (short SHA), or `feat/auth-tokens` (branch) |
| `Finding` | yes | `Missing null check in auth.ts:42 (security-reviewer)` — include `path:line` and the surfacing critic so future runs can match by location, category, and source |
| `Original verdict` | yes | One of `🔴 Must-Fix`, `🟡 Must-Address`, `🟢 Consider`, `Nit` |
| `Override verdict` | yes | One of `Won't-Fix`, `Defer`, `🟡 Must-Address`, `🔴 Must-Fix` (or comparable shorthand using the same vocabulary as Original) |
| `Reason` | yes | One short sentence on the human's rationale (`"test-only path"`, `"deprecated module, removal scheduled in #501"`, `"team style; verbose form preferred here"`). If longer than ~30 words, link to a PR comment or `docs/decisions/NNN-*.md` instead of expanding the cell. |

Rows are kept in reverse-chronological order (most recent at the top of the table) so that the freshest context is easiest to scan.

### Capturing new overrides

When a human review of this run's output produces a verdict change relative to the rubric — typically a Must-Fix → Won't-Fix or a Nit → Must-Fix promotion — append a row to `docs/reviews/override-log.md` immediately. The append happens:

1. **Inside the same skill run** when the orchestrator records the human's verdict
   in chat (e.g., the user says "this one is fine, skip it" or "actually promote that").
2. **From the review-fix loop** in `workflows/pr-prep.md` when the loop terminates
   with unresolved findings that the human explicitly waived.
3. **Manually by the author** if the override is reached outside a structured run
   (e.g., during PR review on GitHub) — the author writes the row themselves.

In all three paths, fill every required field. Missing fields invalidate the row for future Step 3.5 matching: a row without a location cannot match by location, and a row without a reason cannot be evaluated for staleness.

### Why this isn't write-only

The risk with any "log of decisions" is that nothing reads it, so it grows in storage cost but adds no signal. This skill prevents that failure mode by:

- **Mandatory read in Step 3.5.** The orchestrator MUST read the log before
  rendering findings, on every run.
- **Mandatory citation in deliverables.** Both the chat synthesis
  (`### Considered overrides`) and the rubric (`## ↩️ Considered Overrides`)
  must explicitly state which prior overrides applied — or that none did. The
  "none matched" line is not optional; silent omission is treated as a
  calibration failure in self-eval.
- **Explicit delta on departure.** If the current run flags a finding that a
  prior override marked Won't-Fix, the orchestrator must explain why it is
  re-flagging — new evidence, scope change, or disagreement with the prior
  call. Re-arguing a settled override without acknowledging it is the
  specific failure this section exists to prevent.
