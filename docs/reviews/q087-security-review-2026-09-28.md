Commit: 21d4eb8

# Security Review — review/q087, iteration 2 (delta `27d483b..21d4eb8`)

**Scope:** PARTIAL — fix commit `21d4eb8` (`skills/code-review/SKILL.md`, `test/skills/code-review-factcheck-replication.bats`, `docs/decisions/log.md` rows 60/63, `docs/decisions/031-review-loop-tier-and-factcheck-policy.md`, `docs/reviews/override-log.md`). `27d483b` and the `09d62ad` review artifacts are already committed — context only, not under review.
**Date:** 2026-09-28
**Based on:** `docs/reviews/q087-code-fact-check-report.md` (k=1 loop pass, iteration 2)

There is no application trust boundary in this diff: every change is markdown or a bats grep. The security-relevant surface is the review pipeline's own assurance: (a) how many fact-check replicates stand behind the merge gate, and (b) which override-log rows suppress re-flagged findings in later runs.

## Trust Boundary Map

```
B1: orchestrator run flags (--loop-pass present/absent) → Stage 1 k-selection rule   → fact-check replicate count behind the merge gate
B2: docs/reviews/override-log.md rows (author-written)  → Step 3.5 / review-fix-loop "Re-flagged settled decisions" filter → which findings reach triage
B3: test/skills/code-review-factcheck-replication.bats  → grep over SKILL.md Stage 1 → regression guard on the k rule
```

B1 is `(moved)`: the rule no longer reads the rubric's `Loop closed at` line to pick k; the flag alone decides.

```
S1: --loop-pass flag            — request-time (per run, set by the orchestrator) — trusted toward k-selection; the only input now
S2: canonical rubric file state  — runtime-mutable (rewritten each pass)          — no longer an input to k-selection (removed by 21d4eb8); still an input to scope/short-circuit (unchanged)
S3: override-log rows            — runtime-mutable (append-only, author-edited)   — trusted toward noise suppression only when verdict is Won't-Fix / Accepted-immutable
S4: SKILL.md prose               — code-constant for this review                   — input to the bats greps
```

The fix narrows B1's inputs from two (flag + rubric state) to one (flag). Removing S2 from k-selection removes the misclassification path the struck override row described (a standalone re-review of a branch with an unclosed rubric being treated as a loop pass). B2 gains three row changes, of which only one carries a verdict the filter acts on.

## Findings

No findings.

Checks performed, by move:

- **Move 5 (invert the model), B1.** What does the flag-only rule fail to cover? A final confirming pass mistakenly run *with* `--loop-pass` would get k=1. That was equally true before 21d4eb8 (the old rule also required the run to be without `--loop-pass` before consulting the rubric), so no new path is introduced. The default when the flag is absent is k=3, so the fail-safe direction is preserved.
  Evidence: `skills/code-review/SKILL.md:451-453` — "The **k=3 protocol below applies to every run without `--loop-pass`**: standalone single-pass reviews and a loop's final confirming pass, which runs without the flag per [Step 1](#step-1-determine-scope). The flag alone sets k, so no rubric check is needed to tell the two apart." (excerpt ends :453; paragraph continues to :456 — read.)
- **Move 3 (error path), B1.** The short-circuit mechanic still reads the rubric (`skills/code-review/SKILL.md:735-744`), but only for the once-per-loop marker, and it states "The run still implies `--no-gate` and k=1" — i.e., only on `--loop-pass` runs. No remaining rubric-state dependency feeds k. Step 1 (`:126-128`) still ties the final pass to "the one run to declare the branch clean" run without `--loop-pass`, consistent with the new rule.
- **Move 11 (bypasses), B2.** Candidate suppression inputs from the new/struck rows, each traced against `workflows/review-fix-loop.md:161-165` ("A row counts as a match only if its **Override verdict** is `Won't-Fix` or `Accepted-immutable` … Other override verdicts — `Defer` … — do not trigger this filter"):
  1. A3 row (`docs/reviews/override-log.md:80`, verdict `Defer`) — tested: cannot suppress anything; a future Q-087-status finding reaches triage.
  2. Struck u4 row (`docs/reviews/override-log.md:129`, verdict `Defer`) — tested: cannot suppress anything regardless of the strike; the strike follows the documented convention at `skills/code-review/SKILL.md:1260` ("mark them with a `~` strikethrough in the `Finding` cell … but keep the row").
  3. C4 row (`docs/reviews/override-log.md:81`, verdict `Won't-Fix`, location `test/skills/code-review-factcheck-replication.bats:141-161`) — tested: this is the one row the filter acts on. Its match surface is the bats file ±5 lines and the claim "test does not pin absence of stale final-pass k=1 wording". A future prose-drift finding located in `skills/code-review/SKILL.md` (e.g., a reintroduced "final pass runs k=1") does not share its location and is a different claim (prose wrong vs. test coverage), so it would reach triage. What it does settle is the test-coverage gap itself; that is an author decision already recorded, not a new finding.
- **Move 11 (bypasses), B3.** The new greps (`test/skills/code-review-factcheck-replication.bats:154-157`) are positive-only. Candidate bypasses: (i) reword the rule away — caught, grep fails; (ii) keep the sentence and add a contradicting k=1 sentence elsewhere in Stage 1 — not caught (this is the C4 gap, settled Won't-Fix); (iii) delete the "every run without" sentence but leave the "standalone single-pass reviews and a loop's final confirming pass" list — caught by the first of the two greps. Executed: `timeout 120 bats test/skills/code-review-factcheck-replication.bats` → all 17 ok, test 13 included. The `.` wildcards around `--loop-pass` in the pattern match the backticks; the pattern starts with `k=3`, so `--loop-pass` is not parsed as a grep option.

## Endorsement Claims

- **Claim:** After 21d4eb8, Stage 1's k-selection reads only the `--loop-pass` flag; the rubric's `Loop closed at` line is no longer an input to k.
  **Location:** `skills/code-review/SKILL.md:451-456`
  **Evidence:** read-static
  **Verified:** the replaced paragraph in the diff, plus grep of `skills/code-review/`, `workflows/`, and `docs/decisions/log.md` for "recognized by" / "no `Loop closed at` line" — no remaining k-selection reference.
  **Not verified:** the orchestrator's actual dispatch code path, if any exists outside the skill prose (the skill is prose-only; an agent's reading is the runtime).
  **route: code-fact-check**
- **Claim:** None of the three override-log row changes in 21d4eb8 widens the Won't-Fix suppression beyond the C4 row's test-coverage claim at `test/skills/code-review-factcheck-replication.bats:141-161`.
  **Location:** `docs/reviews/override-log.md:80-81`, `:129`
  **Evidence:** read-static
  **Verified:** each row's Override verdict against the filter's verdict condition at `workflows/review-fix-loop.md:161-165`.
  **Not verified:** how the code-review skill's own Step 3.5 pre-render read (distinct from the loop filter) weighs `Defer` rows; not read in this pass.
- **Claim:** The replication test's test 13 passes on the branch tip.
  **Location:** `test/skills/code-review-factcheck-replication.bats:141-161`
  **Evidence:** executed
  **Verified:** `timeout 120 bats test/skills/code-review-factcheck-replication.bats` — 17/17 ok.
  **Not verified:** that the greps fail against the pre-fix wording (no mutation run).

## Primitive sweep

Primitive sweep: no dangerous primitives in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

No findings within the code paths read; endorsement claims pending execution verification. The fix commit narrows the fact-check k-selection to a single input (the flag) with k=3 as the absent-flag default, which removes the rubric-state misclassification path rather than adding one. The only override-log change the settled-decision filter acts on is the C4 `Won't-Fix`, whose match surface is limited to test coverage in the bats file and does not mask prose drift in `SKILL.md`. The two `Defer` rows (including the struck one) have no filtering effect. Residual gap, already settled by the author: the test does not catch a contradicting k=1 sentence added alongside the pinned rule.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your role section names, structured per your role skill, every finding/claim carrying verbatim Evidence with `path:line`, and a Goal-Alignment Note appended.
- Answered: yes — no findings; the assurance effects of k-selection and override-log changes were traced and the test executed.
- Out of scope: `27d483b` (original change) and the `09d62ad` review artifacts (context only per the partial-scope label); code-review Step 3.5's pre-render handling of `Defer` rows (not in the diff).
- Escalate: nothing.
- Decisions I made: did not re-raise the C4 absence-grep gap as a finding, since it is a recorded Won't-Fix in this loop; noted it in the Overall Assessment only.
