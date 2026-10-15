Commit: a94e01c7
Loop-pass short-circuit: used at a94e01c7

# Code Review Rubric: fix/q160-iteration-cap

**Scope:** `main...HEAD` (full branch, first pass) · **Delivery mode:** self-read (diff ~33 KB, markdown only; agents read the diff and enclosing files themselves) ·
**Fact-check:** k=1 loop pass, `docs/reviews/code-fact-check-report-q160-i1.md` · **Self-eval:** `docs/reviews/self-eval-review-fix-loop-2026-10-15-fix-q160-iteration-cap.md`

Size after iteration 0 (entry, step 1a): 28 code lines against main.

## Iteration 1 (a94e01c7): loop pass, short-circuited at fact-check

Fact-check: 22 claims; 15 Verified, 5 Mostly accurate, 1 Stale, 1 Incorrect. Claim 15 is an Incorrect on a skill contract (code-review's next-action ladder), so it is a behavioral red under tier policy T and the first-red short-circuit fired (first use in this loop; no enforcement file in the diff, so no forced security pass). Critics skipped. Self-eval ran in parallel per pr-prep 3a.

## 🔴 Must Fix

| ID | Finding | Location | Source | Status |
|---|---|---|---|---|
| R1 | Rule 2 recommended `split PR` for a unit over 800 on a later pass, while review-fix-loop says past 800 the loop stops for the user's waiver; a unit over 800 with no red fell through to `merge` | `skills/code-review/references/chat-synthesis.md:140-147` | fact-check Claim 15 (Incorrect) | Fixed: rule 2 applies on the first review only; later growth is the loop's size re-check, which no next action overrides |

## 🟡 Must Address

| ID | Finding | Location | Source | Status |
|---|---|---|---|---|
| A1 | The /away "agent does not decide" rule and the iteration-4 gate's /away default `split` conflict, with no precedence | `workflows/review-fix-loop.md` § Size re-check | self-eval defect 1 | Fixed: the stop takes precedence; past 800 the agent does not split on its own, splitting is a waiver option |
| A2 | The re-check fires between 3c and 3d and before merge, but pr-prep marks neither point | `workflows/pr-prep.md` 3c, 6c | self-eval defect 2 | Fixed: pointers in 3c and 6c |
| A3 | Details beyond Q-104's text (before merge, /away, entry waivers, rubric line) cited as Q-104 [2] | `review-fix-loop.md`, row 62 | fact-check Claims 9, 21 | Fixed: both now say which parts are Q-104 [2] and which are Q-160's reading |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| C1 | Worked example "1 red, 800-line diff → split PR" true only on a first review | fact-check Claim 16 (Stale) | Fixed: "first review" added |
| C2 | Q-113 called an entry-gate waiver; Q-114 has the same shape | fact-check Claim 8 | Fixed in plan; commit body immutable (override row) |
| C3 | Plan said step 1's criterion would change; it did not | fact-check Claim 10 | Fixed in plan |
| C4 | 157→603 and 392→570 overstate growth during review | fact-check Claim 22 | Shipped text cites only clean cases; commit body (override row) |
| C5 | "Review artifact" record vs artifacts overwritten each loop | self-eval minor | Fixed: one `Size after iteration N` line per iteration in the rubric, kept on in-place updates |
| C6 | "Same BASE" stale after the lower stacked unit merges | self-eval minor | Fixed: BASE set as in step 1a, `main` once the lower branch merged |
| C7 | Rule 2's >800 on a `--range` pass has no base | self-eval minor | Moot after R1's fix |
| C8 | Testability: the re-check is by hand; nothing checks the `Size` line | self-eval (Weak) | Won't-Fix here: step 1a is also by hand; scripting both is a separate unit (override row) |

## Considered overrides

Rows 144-145 (`review/q085`: the size gate excludes all of `docs/`; deletions count) still hold and are unchanged by this diff. Rows 479, 486, 488 (`feat/build-loop-u2a4`: unit grew 381→443→540→599 during review, routed to the user) are the growth this change answers.

## Composition check

No multi-source co-located clusters qualified (one source ran, plus self-eval; R1 and C7 share a location and one root, already stated by R1).

## ⏭️ Skipped Core Critics

security-reviewer, performance-reviewer, api-consistency-reviewer: loop-pass short-circuit (behavioral red confirmed).
