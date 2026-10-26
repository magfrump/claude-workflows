Commit: e1d7d912

# Code Review Rubric

**Scope:** `fix/exit-scan-r6-hookspath`, d40e4bae..e1d7d912 (pass 2 critics: full branch; pass 2 fact-check: cf15f4f9..e1d7d912) | **Reviewed:** 2026-10-25 | **Status: 🟡 fixes applied after pass 2, awaiting the final confirming pass**

Passes so far (loop passes, k=1 fact-check):
- Pass 1 (cf15f4f9): fact-check only; report `docs/reviews/r6-hookspath-p1-code-fact-check-report.md`. Its behavioral red (an open R6 variant) would have short-circuited the critics; the security critic should still have run (mechanic 7, enforcement file) and ran in pass 2 instead.
- Pass 2 (e1d7d912): fact-check delta (`r6-hookspath-p2-code-fact-check-report.md`), security (`r6-hookspath-p2-security-review-2026-10-25.md`) and performance (`r6-hookspath-p2-performance-review-2026-10-25.md`) on the full branch, dispatched in parallel with pass 1's fact-check as their Stage-1 input.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | Absolute and `~/` include paths were skipped by the per-worktree walk, so a relative hooksPath set in such an include passed the scan in a linked worktree (rc=0, hook ran) | Security | Incorrect (behavioral) | Fact-check p1 | `devcontainer-config/cc-exit-scan.sh` `_snap_tree_hooks` (cf15f4f9) | for-author | — | ✅ Fixed in e1d7d912 (bats case) |
| R2 | A file first reached at depth 10 of an untaken `includeIf` chain was marked seen with its includes cut, then skipped when a taken include reached it (rc=0, hook ran) | Security | Medium (executed bypass of the unit's own goal) | security p2-1 | `cc-exit-scan.sh` `_snap_tree_hooks` (e1d7d912) | for-author | — | ✅ Fixed after pass 2: no depth cap, per-config cache (bats case) |
| R3 | Include walk repeated per `.git` entry: entries x includes forks (100 x 100: 46.6 s vs 2.2 s), past what override-log row 134 accepted | Performance | Medium | performance p2-1 | `cc-exit-scan.sh` `_snap_tree_hooks` dedup key `t:<real>:<wt>` | for-author | Row 134 (linear growth accepted, not this) | ✅ Fixed after pass 2: values cached per config per snapshot (2.71 s) |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Guide boundary paragraph implied in-scope routes (A14, A16, R3 remotes) are closed; A14 executed live | Docs | Incorrect | Fact-check p1 | for-author | — | ✅ Fixed in e1d7d912 | Listed as "not closed yet" |
| A2 | R5/A15 guide bullet described a mechanism only on the held Q-168 branch | Docs | Incorrect | Fact-check p1 | for-author | — | ✅ Fixed in e1d7d912 | Dropped; research doc records why |
| A3 | "Records nothing itself" comment false for configs only this walk reads | Docs | Incorrect | Fact-check p1, p2 | for-author | — | ✅ Fixed | Rewritten after pass 2 |
| A4 | `core.worktree` elsewhere not followed (rc=0, hook ran); needs launch-time state | Security | Medium | security p2-2 | for-author | — | ✅ Documented | Guide known route (out of scope by the sort); revisit trigger: a group-(1) unit that touches per-worktree bases |
| A5 | Absolute hooksPath in a config only this walk reads (container-form git dir) not walked | Security | Mostly accurate (comment) | Fact-check p2 | for-author | — | ✅ Fixed after pass 2 | Walk resolves absolute values too |
| A6 | Container-form guide bullet stale | Docs | Stale | Fact-check p1 | for-author | — | ✅ Fixed in e1d7d912 | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Every hooksPath value walked in every worktree (git takes the last): 100 x 100 values 11.3 s | performance p2-2 | Low | for-author | Row 134 | Won't-Fix: availability only, values need launch state, guide "A slow scan" covers |
| C2 | Empty or non-regular `commondir` now refuses launch | security p2-3 | Informational | for-author | — | Accepted: git dies there too; research doc section 5 |
| C3 | Guide per-repo timing: measurable change (~5 ms per repo) | performance p2-3 | Informational | for-author | Row 134 | Fixed: guide says about 30 ms, names linked worktrees |
| C4 | config.worktree read always; commit message wording; research cost line | Fact-check p1, p2 | Mostly accurate | for-author | — | Fixed |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `integrate/q076` / 2026-09-27 (row 134) | Scan cost grows with embedded repos (~29 ms each) | 🟢 → Defer (documented limit) | Fail-closed by design; numbers in the guide | Applied to C1/C3; R3 exceeded it and was fixed |
| `integrate/q076` / 2026-09-27 (row 135) | Scan reads `commondir`'s first line itself | 🟡 → Acknowledged | Only launch-present state | The new walk uses `gitdir_common` rather than a new raw reader |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| R6 closed for the brief's layout | ✅ Confirmed (executed) | `bats -f R6` passes on HEAD and fails at its first status check on d40e4bae's scan; probe old rc=0 / new rc=1, host commit runs the hook | Fact-check p1 claim 1 | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

- `api-consistency-reviewer`: no public API surface (internal `_snap_*` functions, no flags, no config keys); the guide edits are covered by the fact-check passes.

## 🧩 Composition check

- `cc-exit-scan.sh` `_snap_tree_hooks` (security p2-1, performance p2-1, fact-check p1 R1): distinct defects (seen-set depth interaction, per-worktree dedup key, abs-path skip), one rewrite fixes all three.
