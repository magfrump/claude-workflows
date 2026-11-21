# Code Review Rubric — board.sh feedback and weekly lines (brief 2026-11-20-board-pending-feedback)

**Commit:** 9489d532 (pass 1 reviewed) → f934786f (pass 2 reviewed) → fbafd923 (pass 3 reviewed) → c45a2ab3 (pass 3 Considers)
**Scope:** `977c3f70..HEAD`, branch `feat/board-pending-feedback` | **Reviewed:** 2026-11-20 | **Status: ✅ PASSES (pass 3, no Must Fix or Must Address open)**. Single-sample review: no findings is not proof that none exist.

One fresh general-purpose reviewer per pass covered correctness (does `pending` say what `ingest` would do), fail-closed gaps (H2), the trust boundary (H1: nothing from a repo runs on the host; S1: honest slips only), tests, and a code-fact-check of the two guides and comments. Details: `docs/working/research-2026-11-20-board-pending-feedback.md`, "Review record".

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The pre-pass took a harness repo whose main holds one marker file and a non-file at the other as "no harness" (footer, exit 0). `scripts/board.sh` pre-pass | Correctness | Fail-open | Pass 1 | for-author | — | Fixed f934786f | Now NOT COMPARED on every project; bats case. |
| A2 | Keying the harness by `--show-toplevel` skipped a bare harness repo silently. `scripts/board.sh` pre-pass | Correctness | Fail-open | Pass 2 | for-author | — | Fixed fbafd923 | Keyed by `--git-common-dir`; bare and worktree bats case. |
| A3 | `2>/dev/null` on the assignment left git's stderr from inside `$( )` on the output. `scripts/board.sh` pre-pass | Correctness | Noise | Pass 2 | for-author | — | Fixed fbafd923 | Redirect inside the substitution; test asserts no `fatal`. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | A repo registered twice (subdirectory, trailing slash, worktree) counted as two harness repos. | Pass 1, 2 | Low | for-author | — | Fixed f934786f, fbafd923 |
| C2 | Guide called ingesting the checkout's file "harmless"; rename step and `pending stopped` state unnamed; docstring lacked exit 3; "1 entries". | Pass 1 | Low | for-author | — | Fixed f934786f |
| C3 | A vendored guide beside a symlinked `scripts/` refused every project. | Pass 2 | Low | for-author | — | Fixed fbafd923: only notfile, error or badform beside a blob refuse |
| C4 | With two harness repos the last one's own block was skipped; a failed common-dir read was a silent skip; the self-skip had no test. | Pass 3 | Low | for-author | — | Fixed c45a2ab3 |
| C5 | `isweekly` checks the digit shape only, so a mistyped future date would show as latest. | Pass 1 | Low | for-author | — | Won't-Fix: the lib's one grammar for edition names (S3); a lib change for the cycle |
| C6 | With several refusal reasons only the last is printed. | Pass 2 | Informational | for-author | — | Won't-Fix: each still refuses |
| C7 | Outside the diff: `ingest` overwrites a zero-entry stored copy that holds another Project. | Pass 1 | Medium | for-author | — | Won't-Fix here: out of scope (brief); `pending` withholds the command; for the cycle |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| H1 trust boundary | Good | every git call after `git_harden`; `pending` runs no git or subprocess under `python3 -I`; printed paths `shlex.quote`d; odd names reach python as argv | Pass 1 | for-author |
| `pending` against `ingest` | Good | eleven states compared, each equal or stricter; end-to-end bats case runs the real `ingest` | Pass 1 | for-author |
| Common-dir key | Good | same canonical path through symlinks, subdirectories, worktrees, bare clones and `gitdir:` files in both places | Pass 3 | for-author |
| Weekly checks | Good | symlink, non-directory parent and non-file latest edition all UNREADABLE; never an older edition | Pass 1 | for-author |
