# Code Review Rubric — board.sh weekly line skips a future-dated digest (brief 2026-11-20-board-weekly-future-date)

**Commit:** 799cde84 (pass 1 reviewed) → 49261297 (pass 2 reviewed) → e8e5b76a (pass 2 fixes)
**Scope:** `063a07d9..HEAD`, branch `fix/board-weekly-future-date` | **Reviewed:** 2026-11-20 | **Status: ✅ PASSES (pass 2, all rows resolved)**. Single-sample review: no findings is not proof that none exist.

One fresh read-only reviewer per pass covered code-fact-check (comments, guide and research doc against the code), security and trust boundary (board.sh runs on the host over container-writable repos; S1: honest same-uid slips only), performance of the walk, and test coverage of the brief's three cases.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | `realday` parsed with local `date -d`, which rejects a real day whose local midnight a clock change skips (America/Santiago 2024-09-08), so the board would refuse its whole run that day. `scripts/lib/dev-cycle-read.sh:236` | Correctness | Bug | Pass 1 | for-author | — | Fixed 49261297 | `date -u -d`, and a bats case under TZ=America/Santiago. |
| A2 | The research doc said the digest's brainstorm-age check keeps a local parse because its arithmetic needs it; the local parse is itself faulty across DST. `docs/working/research-2026-11-20-board-weekly-future-date.md` | Docs | Incorrect | Pass 2 | for-author | — | Fixed e8e5b76a | Reworded: a separate digest bug, out of this brief's scope. |
| A3 | The digest's default window (`TODAY - 14 days`, `scripts/dev-cycle.sh:248`) fails on a skipped-midnight TODAY with a misleading --since message; predates this branch. | Correctness | Pre-existing | Pass 2 | for-author | — | Won't-Fix | Out of scope (the brief is the board's weekly line); recorded in the research doc for its own fix. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | --since repeated the date rule inline. | Pass 1 | Low | for-author | — | Fixed 49261297: uses realday. |
| C2 | Fork-cost comment omitted impossible-date names newer than the shown one. | Pass 1 | Informational | for-author | — | Fixed 49261297. |
| C3 | Research doc said the board adds no new requirement; it now needs GNU date on the host. | Pass 1 | Low | for-author | — | Fixed 49261297: guide and doc say so. |
| C4 | Skip note named a repo-relative path while the shown edition is a checkout path. | Pass 1 | Informational | for-author | — | Fixed 49261297: both checkout paths. |
| C5 | `realday` comment said --since also skips a future day. | Pass 2 | Informational | for-author | — | Fixed e8e5b76a. |
| C6 | No test of a well-shaped impossible --since. | Pass 2 | Low | for-author | — | Fixed e8e5b76a: 2026-02-30 case. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Walk order | Good | ls-tree names sort as dates; walking back shows the newest real date on or before TODAY, counts and names future ones, drops impossible ones | Pass 1 | for-author |
| Trust boundary | Good | names reach `date` as one argv element after a digits-only regex; output passes the scrub | Pass 1 | for-author |
| Never an older edition | Good | `main_entry` runs on the chosen name only; the skip note stays on the UNREADABLE line | Pass 1 | for-author |
