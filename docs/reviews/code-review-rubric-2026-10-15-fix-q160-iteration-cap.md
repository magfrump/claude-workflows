Commit: 57f4c871
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
| C5 | "Review artifact" record vs artifacts overwritten each loop | self-eval minor | Fixed, then moved in iteration 2 (I1): the count goes in the following commit's body |
| C6 | "Same BASE" stale after the lower stacked unit merges | self-eval minor | Fixed: BASE set as in step 1a, `main` once the lower branch merged |
| C7 | Rule 2's >800 on a `--range` pass has no base | self-eval minor | Moot after R1's fix |
| C8 | Testability: the re-check is by hand; nothing checks the `Size` line | self-eval (Weak) | Won't-Fix here: step 1a is also by hand; scripting both is a separate unit (override row) |

## Considered overrides

Rows 144-145 (`review/q085`: the size gate excludes all of `docs/`; deletions count) still hold and are unchanged by this diff. Rows 479, 486, 488 (`feat/build-loop-u2a4`: unit grew 381→443→540→599 during review, routed to the user) are the growth this change answers.

## Composition check

No multi-source co-located clusters qualified (one source ran, plus self-eval; R1 and C7 share a location and one root, already stated by R1).

## ⏭️ Skipped Core Critics

security-reviewer, performance-reviewer, api-consistency-reviewer: loop-pass short-circuit (behavioral red confirmed).

## Iteration 2 (57f4c871, range a94e01c7..57f4c871): loop pass

Size after iteration 1: 41 code lines against main (step 1a's command). Fact-check k=1 (`code-fact-check-report-q160-i2.md`): 18 claims; 14 Verified, 4 Mostly accurate, 0 Incorrect. Prior R1, A2, A3, C1, C5 resolved; A1 and C6 partly. Short-circuit already used, so the panel ran: api-consistency (`api-consistency-review-2026-10-15-fix-q160-iteration-cap.md`: 1 Inconsistent, 5 Minor, 2 Informational). Security and performance skipped by Stage 1.5: markdown-only diff, no string literal in a shell, regex, auth or path context changed, no fact-check claim in their domains.

| ID | Finding | Source | Tier | Status |
|---|---|---|---|---|
| I1 | The rubric `Size after iteration N` line is not in rubric.md's pinned format; no placement, lost on a new dated file | api F1 (Inconsistent) | 🟡 | Fixed: the count goes in the body of the following commit (`Size: <count> code lines against <BASE>`); rubric format untouched |
| I2 | No limit after a waiver; an open-ended waiver re-opens unbounded growth | api F2 | 🟡 | Fixed: the waiver sets the limit (named, or the count asked about) |
| I3 | "Before merge" is 6c only on the local path; 6c's criteria omit the check | api F3 | 🟡 | Fixed: "before the description is published (local path: before the merge)"; 6c criterion added |
| I4 | Waiver citation wording drifts (quick-ref, completion-signals, "verbatim", entry vs re-check) | api F4 | 🟢 | Fixed |
| I5 | Heading omits the merge-time run | api F5 | 🟢 | Fixed: renamed, anchors updated (pr-prep x4, loop x2) |
| I6 | Row 62's amendment in the Decision column; precedent puts it in Rationale | api F6 | 🟢 | Fixed: moved |
| I7 | completion-signals "≤ 800 lines after review fixes" drops "code lines outside docs/" | api F7 | 🟢 | Fixed |
| I8 | 3c's size re-check and drift check share a slot with no order | api F8 | 🟢 | Fixed: re-check first; past 800 the drift check waits |
| I9 | pr-prep step 3 criterion still says "same BASE" | fact-check Claim 3 | 🟡 | Fixed |
| I10 | Rule 2's "first review" has no stated test | fact-check Claim 11 | 🟡 | Fixed: SKILL.md's first-pass test (no rubric, or only a closed one) |
| I11 | Precedence stated only in the re-check; early split trigger and gate read unqualified; overlap with step 1a at entry | fact-check Claim 16 | 🟡 | Fixed: both qualified with a link; the precedence covers growth during review only, entry stays step 1a's |
| I12 | Log row 61 (early split trigger) reads unqualified | fact-check Claim 16 | 🟢 | Won't-Fix: row 62's amendment and the loop doc carry it (override row) |
| I13 | Override rows appended at the bottom with a verdict outside the reference list | fact-check Claim 9 | 🟢 | Won't-Fix: matches the 2026-10-14 rows' practice (override row) |
