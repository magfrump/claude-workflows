# Code Review Rubric — build-loop.sh --prompt --steal --ended (brief 2026-11-19-steal-ended)

**Commit:** f0df51ba (pass 1 reviewed) → fixes in e2d917cc (pass 2 reviewed)
**Scope:** `04bf7b11..HEAD`, branch `fix/steal-ended` | **Reviewed:** 2026-11-19 | **Status: ✅ PASSES (pass 2, all rows resolved)**. Single-sample review: no findings is not proof that none exist.

One fresh read-only reviewer per pass covered code-fact-check (header, usage, comments and SKILL text against the code), security and trust boundary (S1: honest same-uid slips only), API consistency of the new flag and output line, and test coverage against the Tests bullet of `docs/working/research-2026-11-19-steal-wait-research.md` ("For the dev cycle").

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | A dispatch printed but not started had no `10.` line form carrying ENDTIME, and step 10 gave it no `--ended` route. `skills/dev-cycle/SKILL.md:715` | Docs | Incomplete | Fact-check | for-author | — | Fixed e2d917cc | Not-started form on the `10.` line, in step 7 and in step 10. |
| A2 | The `lock UTC TIME` header said "should this loop end unseen", the opposite of the spec. `scripts/build-loop.sh:540` | Docs | Incorrect (comment) | Fact-check | for-author | — | Fixed e2d917cc | Now "be seen to end with no marker". |
| A3 | The take test's commit predated the lock, so a commit between LOCKTIME and ENDTIME being accepted was not shown. `test/scripts/build-loop-dispatch.bats:197` | Tests | Coverage gap | Test review | for-author | — | Fixed e2d917cc | Hand-set lock at -5 min, commit at -3 min, ENDTIME now. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Research doc's "Inputs read" line numbers are base-commit positions. | Fact-check | Informational | for-author | — | Fixed: "at 04bf7b11" added. |
| C2 | For a not-started dispatch, ENDTIME is when it was not started, which the header's "seen to end" covers only loosely. | Fact-check (pass 2) | Informational | for-author | — | Won't-Fix: the SKILL text names the case. |
| C3 | The unreadable-tip-time branch under `--ended` has no test. | Test review | Low | for-author | — | Won't-Fix: hard to reach hermetically; it fails closed. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| `steal()` correctness | Good | BASH_REMATCH group 3 is the lock time; the empty-t fallback is safe under set -e and pipefail; only a dispatch lock of this brief with the exact LOCKTIME and a tip before ENDTIME is taken | Security + fact-check | for-author |
| Readers of the old line 2 | Good | none missed outside the dispatch tests; the orchestrator pin passes | API consistency | for-author |
| Test flakiness | Good | times minutes apart or hand-set; no same-second race | Test review | for-author |
| Trust boundary | Good | values reach only `[[ ]]` and `date -d` as argv | Security | for-author |
