# Code Review Rubric — dev-cycle auto send-back (brief 2026-11-19-auto-send-back)

**Commit:** 244ca278 (pass 1 reviewed) → fixes in ace29e75 (pass 2 reviewed) → fixes in ecde92f1 (pass 3 reviewed)
**Scope:** `a0ef9528..HEAD`, branch `fix/auto-send-back` | **Reviewed:** 2026-11-19 | **Status: ✅ PASSES (pass 3, all Must Address rows resolved)**. Single-sample review: no findings is not proof that none exist.

Fact-check passes: k=1, k=3, k=1. No security, performance or API-consistency critic ran in any pass: the diff is prose in `skills/dev-cycle/SKILL.md` steps 7 and 10, one `sect` text pin and a research doc; it touches no enforcement file and no script reads `Applied:`. That is a coverage gap, stated here.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | "So the owner keeps a re-dispatch under the cap" was false for a sent-back loop ending with no new commit (dispatch 4 via the TIP rule). `skills/dev-cycle/SKILL.md` step 7 | Docs | Incorrect | Fact-check | for-author | — | Fixed ace29e75 | Qualified in the skill and pre-mortem 1. |
| A2 | Research doc linked a nonexistent, non-canonical rubric path. | Docs | Incorrect | Fact-check | for-author | — | Fixed ace29e75 | This file. |
| A3 | Research doc said `--status` enforces the cap; `dispatch()` does. | Docs | Incorrect | Fact-check | for-author | — | Fixed ace29e75 | — |
| A4 | FP-015 (merge-abort failure) not cited beside FP-012. | Docs | Incomplete | Fact-check | for-author | — | Fixed ace29e75 | No new merge or abort site. |
| A5 | The library "is not a regular file" gap was unclassified. `scripts/build-loop.sh:1531` | Docs | Incomplete | Fact-check | for-author | — | Fixed ace29e75, ecde92f1 | Stays stopped, named by path. |
| S1 | Research doc called the spec's `:1530` a slip; it was correct at its commit and moved later. | Docs | Incorrect | Fact-check (pass 2) | for-author | — | Fixed ecde92f1 | — |
| S2 | "A tip already sent back" sat in the stopped list but cannot reach a stopped entry under the TIP rule. | Docs | Incorrect | Fact-check (pass 2) | for-author | — | Fixed ecde92f1 | Own sentence: only re-dispatched, up to the cap. |
| S3 | Research doc said `Q-NNN=redispatch` replaces `noted`; the skill never gives a refused merge `noted`. | Docs | Incorrect | Fact-check (pass 2) | for-author | — | Fixed ecde92f1 | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Pre-mortem 4 said every refused approved merge records `Q-NNN=redispatch`. | Fact-check (pass 3) | Informational | for-author | — | Fixed: "sent back automatically". |
| C2 | Two phrases unpinned: "(an approved merge's: its `Q-NNN=redispatch`)" and the library-path phrase. | Fact-check (pass 3) | Low | for-author | — | Won't-Fix: every trigger and the write instruction are pinned. |
| C3 | The migration gap is labelled the owner's, though its gate text also offers a skip line. | Fact-check (pass 2) | Informational | for-author | — | Won't-Fix: matches the spec. |
| C4 | Pre-existing: a refused approved merge outside this route records no `Applied:` action, so `--check-answer` can read that ID again. | Fact-check (pass 2) | Low | for-author | — | Won't-Fix here: a follow-up for a later cycle. |
| C5 | Self-merge: a checkout refusal still prints `gap` lines. | Fact-check (pass 2) | Low | for-author | — | Fixed ecde92f1: the trigger keys on the `refuse ... failure-pattern gaps` line. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Spec coverage | Good | every "What to write" bullet and acceptance criterion, on all three gate routes | Fact-check | for-author |
| Gate texts | Good | conflict (build-loop.sh:1582), gaps refuse line (:1608), `fp_gaps` (:1511-1564) | Fact-check | for-author |
| Text pin | Good | 52/52; each pinned phrase fails the test when deleted (mutation probe) | Fact-check | for-author |
| Approval tie | Good | no answer written or inferred; new tip gets its own merge entry; `--check-answer` and `--cycle-diff` unaffected by an `auto@` item | Fact-check | for-author |
