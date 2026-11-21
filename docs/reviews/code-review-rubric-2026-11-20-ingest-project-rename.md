# Code Review Rubric — harness-feedback.py ingest and a renamed project (brief 2026-11-20-ingest-project-rename)

**Commit:** 68f98c1a (pass 1 reviewed) → fixes in 6e3e6a86 (pass 2 reviewed) → fixes in cc0db832
**Scope:** `5627e74c..HEAD`, branch `fix/ingest-project-rename` | **Reviewed:** 2026-11-20 | **Status: ✅ PASSES (pass 2 had no reds; its ambers fixed in cc0db832)**. Single-sample review: no findings is not proof that none exist.

One fresh read-only reviewer per pass covered correctness, security (writes, symlinks, regex over another project's text; S1: honest slips only), ingest/pending agreement and test quality, with probes in a scratch directory.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | `pending` reads no idea log, so for seeds of the project's own-name copy under another name it prints a command `ingest` refuses. `scripts/harness-feedback.py` cmd_pending | Correctness | Disagreement | Pass 1 | for-owner | Closing it needs board.sh to extract main's idea log | Won't-Fix: documented residual | Reached only by a hand-made half rename; the miss is a loud refusal that writes nothing. Stated in `guides/harness-feedback.md`. Revisit if a board-printed ingest command is ever refused with the seeds-under-another-name message: then pass main's idea log to `pending`. |
| A2 | A rename match on the first entry's signature alone took two projects with one F-001 heading for one and suggested a harmful rename. `stored_match` | Correctness | False refusal | Pass 1 | for-author | — | Fixed 6e3e6a86 | Match needs leading signatures plus more evidence (see A4). |
| A3 | No test pinned the seed rewrite to its own path or kept a body `Project:` line; rename refusals did not assert the log unchanged. | Tests | Coverage gap | Pass 1 | for-author | — | Fixed 6e3e6a86 | Both new assertions fail under the matching mutation. |
| A4 | Pass 1's fix let a rename that also edited F-001 store a second copy (fail-open). `stored_match` | Correctness | Fail-open | Pass 2 | for-author | — | Fixed cc0db832 | Two or more stored entries, or an unchanged first text; a one-entry copy renamed and edited is a stated residual. |
| A5 | `rename` truncated the idea log before writing, so a write failure partway lost half of it. `cmd_rename` | Correctness | Data loss | Pass 2 | for-author | — | Fixed cc0db832 | Temp file plus `os.replace`; new read-only-dir case. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Docs said every refusal prints a rename command. | Pass 1 | Low | for-author | — | Fixed: guides say which do. |
| C2 | rename's rollback on a failed log write; a symlinked stored copy to the source skipped; rename's source dir unresolved; docstring. | Pass 1 | Low | for-author | — | Fixed 6e3e6a86, tests in cc0db832. |
| C3 | A copy moved by hand with seeds on the old path is re-seeded. | Pass 1 | Low | for-author | — | Won't-Fix: no such state in the repo. |
| C4 | A failed unlink of the old copy after rekeying leaves two copies. | Pass 2 | Low | for-author | — | Won't-Fix: the next ingest refuses that state loudly. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Refusals before writes | Good | every refusal in ingest and rename is decided before the first write | Pass 1 | for-author |
| Seed forgery | Good | `seed_line` neutralises `(signal:` in entry text; probe of a forged signal did not match | Pass 1 | for-author |
| ingest/pending agreement | Good | both call `stored_match` with the same entry texts; all states but A1 agree | Pass 2 | for-author |
