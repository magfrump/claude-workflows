Commit: 39ed1d53
Loop-pass short-circuit: used at 39ed1d53
# Code Review Rubric

**Scope:** full branch `main...feat/build-loop-u2a2` at 39ed1d53 (no prior rubric for this slug); 347 changed code lines by pr-prep 1a | **Reviewed:** 2026-10-06 | **Status: 🔴 BLOCKED**

## Iteration 1 of 3 (Commit 39ed1d53, full branch, --loop-pass, k=1)

Delivery mode: self-read. Loop-pass short-circuit: behavioral 🔴 confirmed at fact-check (Claim 7) — critics skipped, returning to the loop for the fix. No enforcement file in the diff (hooks/live-verify-gate.sh regex), so mechanic 7 does not force security.

Reports: `code-fact-check-report-build-loop-u2a2.md` (k=1, 43 claims: 31 Verified, 6 Mostly accurate, 2 Stale, 4 Incorrect, 0 Unverifiable; probes in /tmp/u2a2-cfc-RrAi/).

Override-log scan: rows dated 2026-10-06 for `feat/build-loop-u2a` and `feat/build-loop-u2a1` matched (A5 gaps, walk naming, per-blob cost, start-file rule in both walks, C12-C16). Claim 7's two shapes are not among A5's settled gaps (fact-check E1), so they are not filtered.

## 🔴 Must Fix

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | main_imports passes two shapes it does not model, against its "refuses what it does not model": a main symlink whose text holds a NUL (`$(...)` drops it, so the walk follows `docs/rules.mdzzz` while the checkout links `docs/rules.md`; executed) and a checkout symlink at an import target main lacks (`inrepo_here "$f" \|\| continue`, lib:555; executed). Imported files answer `-`. | Incorrect (behavioral) | fact-check Claim 7, E1 | ✅ Fixed (iteration-1 fix commit) | Checkout path that exists but is not plain fails the walk (a plain directory reads nothing); link text NULs counted before the read. Tests: build-loop-check.bats "...NUL, and on a checkout symlink..." |

## 🟡 Must Address

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A2 | A failing `git ls-tree` or `untracked_md` ends the process (errexit in `< <(...)`, then `${recs[-1]}` on an empty array) instead of returning 1 with IMPORTED_MAIN=error; isimported's "answers imported" and U2a3's worded refusal never happen there (lib:529-530, :539-540; executed) | Incorrect (contract; fails closed) | fact-check Claim 13a, E2 | ✅ Fixed | `cmd && printf rc=0 \|\| printf rc=1`, plus an empty-array guard; test "...returns, not exits..." |
| A3 | The symlink read's `if ! out="$(...; printf x)"` guard never fires (the status is printf's) | Verified-with-caveat | fact-check Claim 7 note | ✅ Fixed | `&& printf x` |
| A4 | main_imports' return-1 list omits main not found by name, the untracked listing failing, a record failing the regex, empty link text; "git would read the first copy" holds for lookups, while checkout keeps the last | Mostly accurate | fact-check | ✅ Fixed | comment lists every return-1 case |
| A5 | plan :275 still calls U2a2 "the floor" and says a `..` name is refused; no U2a3 entry | Stale | fact-check | ✅ Fixed | plan U2a2/U2a3 bullets; F11 and A5 updated too |
| A6 | Commit messages: d8003fbf's "53a6912b, kept on feat/build-loop-u2a2-full" (the branch holds its rebase 6c41aea2), "each command's exit status after its last NUL" (A2), the R2-R4 citation (R4 was fixed by following), "two listings both walks use" (only the tree walk uses instruction_names) | Incorrect / Mostly accurate (commit messages) | fact-check Claims 21, 22 | Accepted-immutable (override row) | |
| A7 | Override row at :339 cites `:13` and `:25`; at HEAD they are `:18` and `:21` | Stale | fact-check | Won't-Fix (override row; log is append-only) | |

## ⏭️ Skipped Core Critics

| Critic | Reason |
|---|---|
| security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review, test-strategy | loop-pass short-circuit (behavioral red confirmed) |

## 🧩 Composition check

No multi-source co-located clusters qualified (one source this pass).
