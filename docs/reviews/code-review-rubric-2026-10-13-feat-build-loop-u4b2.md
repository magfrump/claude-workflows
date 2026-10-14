Commit: 9777c1ff
Loop-pass short-circuit: used at 9777c1ff

# Code Review Rubric: feat/build-loop-u4b2

**Scope:** `main...HEAD` (full branch, first pass of the loop) · **Delivery mode:** self-read ·
**Fact-check:** k=1 (loop pass, decision 031) ·
`docs/reviews/code-fact-check-report-2026-10-13-u4b2-i1.md`

## Iteration 1 (9777c1ff): short-circuited at fact-check

Fact-check: 27 claims; 20 Verified, 1 Mostly accurate, 2 Stale, 4 Incorrect (all executed but 23).
Behavioural reds confirmed at Stage 1, so the critic panel was skipped this pass
(decision 032 #4; first use in this loop).

## 🔴 Must Fix

| ID | Finding | Location | Source | Status |
|---|---|---|---|---|
| A1 | A working brief with no live loop (an ended subagent, a stalled loop stopped by step 7) was re-dispatched with `--prompt` and no `--steal`, which refuses "a live loop may hold it" (neither retryable text): it became an agent entry and never re-dispatched (executed, P3) | `skills/dev-cycle/SKILL.md` step 7 working, step 10 | fact-check claim 7b | Fixed in the fix commit: every non-marker tip goes `--prompt --steal` |
| A2 | A self-merge `--merge` run from WT refuses for the checkout (WT is edited by step 7, and an earlier merge moves main), so self-merge never lands (executed, P1) | step 7 ready/self-merge | fact-check claim 8b | Fixed: one detached gate worktree GT at main's commit per call |
| A3 | On the self-merge fall-through the floor prints gate code as a `deny` line; the heading rule read `path` lines only, so it filed `merge-` where `--approved` requires `merge-gate-` (executed, P3/P4) | step 7 merge-entry heading | fact-check claim 9b | Fixed: `path` or `deny` lines |
| A4 | "A stop here loses only those lines; the next iteration writes them": nothing rewrites a lost `Dispatched:` line (static) | step 10 second land | fact-check claim 23 | Fixed: the session keeps N; a session that ends first loses it (Q-103 residual, stated) |

## 🟡 Must Address

| ID | Finding | Location | Source | Status |
|---|---|---|---|---|
| A5 | Rules still say "every build brief (step 6)" | Rules | claim 1 (Stale) | Fixed |
| A6 | "check 1" names a numbered check that no longer exists | Rules, step 6 | claim 2 (Stale) | Fixed |
| A7 | Step 9.3's list of `--cycle-diff` refusals omits several (deletion, non-regular side, refuse index, Asked: deleted/renamed, same-name brief paths, prompt files) | step 9.3 | claim 20 (Mostly accurate; the orchestrator reads it) | Fixed: completed, and pointed at the header |

## ⏭️ Skipped Core Critics

security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review: loop-pass short-circuit (behavioral red confirmed).

## Considered overrides

The rows this unit discharges (266, 269, 623, 673, 674, 680, 683, 701, 706, 714, 719-731, 745-761, 764, 769, 771, 772, 776, 777, 781, 784) were the brief's spec; none was contradicted.

**Status:** iteration 1 not clean (4 red). Single-sample review; absence of findings is not an attestation.
