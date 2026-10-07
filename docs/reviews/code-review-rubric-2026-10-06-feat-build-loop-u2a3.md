Commit: 34edec56
Loop-pass short-circuit: used at 45ad17b0
# Code Review Rubric

**Scope:** full branch `main...feat/build-loop-u2a3`; iteration 2 at 34edec56 (`--loop-pass --full`: iteration 1's critics never ran), iteration 1 at 45ad17b0 | **Reviewed:** 2026-10-06 | **Status: ❌ iteration 2 found one red (B1) and ambers, fixed or acknowledged in the iteration-2 fix commit; final confirming pass next**

## Iteration 2 of 3 (Commit 34edec56, full branch, --loop-pass --full, k=1, full panel)

Scope: `--full` explicitly, since iteration 1 short-circuited before any critic ran; the short-circuit was already used, so Stage 2 ran in full with amber collected. Delivery mode: self-read. Critics: security, performance, api-consistency, architecture (new lib function and cache), test-strategy (--include). Stage 2.5 skipped (loop pass); the performance endorsement on `ls-files --others` and nested worktrees stays pending execution verification.

Iteration-1 verification: A1 (the `..` after a symlink) resolved — fact-check i2 Claim 1 executed every listed shape, security confirmed, and the checkout half is now pinned (test-strategy G5). A2-A4 resolved. No re-fires of iteration-1 fixed findings (B1 is a different shape: no `..`, flagged against the iteration-1 fix-drift comment).

Reports (all `Commit: 34edec56`): `code-fact-check-report-build-loop-u2a3-i2.md` (k=1, 26 claims: 20 Verified, 2 Mostly accurate, 2 Incorrect, 2 Unverifiable); `security-reviewer-review-2026-10-06-build-loop-u2a3.md` (4 Medium, 1 Informational; Claude Code's side not executed); `performance-reviewer-review-2026-10-06-build-loop-u2a3.md` (1 Low, 1 Informational); `api-consistency-reviewer-review-2026-10-06-build-loop-u2a3.md` (2 Minor, 2 Informational); `architecture-review-review-2026-10-06-build-loop-u2a3.md` (0 Structural, 0 Coupling, 3 Minor, 3 Informational); `test-strategy-review-2026-10-06-build-loop-u2a3.md` (G1-G10, 49 mutants, patch). Iteration-1 fix-drift output: `lite-review-fix-drift-build-loop-u2a3-i1.txt`.

### 🔴 Must Fix

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| B1 | A path main lacks under a directory main stores as a symlink (`ld -> deep`) was read from the checkout; a checkout without `ld` dropped it, so link text `CLAUDE.md -> ld/evil.md`, a chain, or an `@ld/x.md` token answered ok with `deep/secret.md: -`. Breaks the header's "the checkout can only add imports"; 34edec56's comment "(link text is checked above)" was false | Incorrect (contract) / Medium | fact-check i2 Claims 3, 19 (Q10, Q11); security F1 (executed); api 2; test-strategy G8. Convergence | ✅ Fixed | Before queueing a path main lacks, the walk fails if any parent is a symlink on main; comments, A5, F11 say so. Test: the "...under a link main stores" test (link and token forms); mutant killed. |

### 🟡 Must Address

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| B2 | Cache key ignores checkout state (untracked start added later unseen; executed) and MAIN_BY_NAME (G9) | Medium (Low conf.) / Minor | security F4, architecture F1, api 4, test-strategy G7, G9; fact-check escalation | MAIN_BY_NAME ✅ fixed; checkout: Defer (override row) | Comment states the reset contract; trigger U2a4/U2b calling it twice per process. Cache tested (G6). |
| B3 | Symlinked instruction file's imports resolved from the target's directory only | Medium (Low conf.) | security F2 | Defer (override row) | A5 lists it untraced; trigger: a host probe of Claude Code. |
| B4 | `.claude/commands/` `@` references are not starts (B14 candidate) | Medium | security F3 | Defer (override row) | Same trigger; needs a root base. |
| B5 | Lib header listed two checkout inputs; the not-covered list three copies disagree | Minor | api 2, architecture F5 | ✅ Fixed (header names three; lib, A5, F11 agree) | |
| B6 | Commit messages 4f087967 ("resolves") and 34edec56 (subject) | Mostly accurate / Incorrect (commit message) | fact-check i2 Claims 11, 3, 19 | Accepted-immutable (override row) | |
| B7 | D8 row's stated reason (`*) continue`) and its missed exposure | Mostly accurate / Informational | fact-check i2 Claim 22b, security F5 | Superseding row | |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| B8 | Untested: 100755 arm, main blob not checkout, untracked `.claude/rules` starts, link chain, `-L` half, cache (G1-G6) | test-strategy | ✅ Fixed (tests folded into existing ones for the 400 cap; 4 named mutants killed) |
| B9 | Start files answer `-` unless imported | architecture F2 | ✅ Fixed (comment) |
| B10 | errexit off under `isimported main`; IMPORTED_MAIN set before the walk ends | architecture F3 | Defer (override row) |
| B11 | No reason word in IMPORTED_MAIN=error | api 1, 3 | Defer to U2a4 (override row) |
| B12 | Ignored .md files price the walk (~4 s at 100k) | performance F1 | Defer (override row) |
| B13 | ~12 ms per followed symlink | performance F2 | Won't-Fix (override row) |
| B14 | `@ld/../q.md` token lexical vs kernel; "Node's path.resolve" claim | security P15, fact-check i2 Claim 12b | Defer (override row) |
| B15 | link_target helper; three copies; row 351 trigger | architecture F4-F6 | Won't-Fix (override row) |
| B16 | blob+tree name prints git's fatal line | test-strategy G10 | Won't-Fix (override row) |
| B17 | fix-drift artifact missing from the branch | fact-check i2 Claim 20 | ✅ Fixed (committed) |

### Re-flagged settled decisions

- Backslash-escaped space in a token (`@docs/my\ file.md`; fact-check i2 escalation): matches the `feat/build-loop-u2a` "backslash or trailing-`_` token form" row (Defer). No action — see override-log.
- Per-record bash cost (performance, measured 0.46-0.67 s): the B6 row. No action — see override-log.

### 🧩 Composition check (iteration 2)

- lib main_imports' queueing (:612) and link-text arm (:583-603): fact-check Claims 3/19, security F1, api 2, test-strategy G8 — distinct statements of one defect, each complete; no composed row (B1).
- lib cache key (:549-550): architecture F1, api 4, security F4, test-strategy G7/G9 — one defect, stated whole by each; no composed row (B2).

---

## Iteration 1 detail (45ad17b0)

## Iteration 1 of 3 (Commit 45ad17b0, full branch, --loop-pass, k=1)

Delivery mode: self-read (a shared context file, then each agent runs `git diff main...HEAD`; U2a2 precedent). Loop-pass short-circuit: behavioral 🔴 confirmed at fact-check (Claim 11b, P4), so the critics were skipped and the pass returned to the loop for the fix. No enforcement file in the diff (`hooks/live-verify-gate.sh` regex), so mechanic 7 does not force security.

Reports: `code-fact-check-report-build-loop-u2a3.md` (k=1, 32 claims: 24 Verified, 4 Mostly accurate, 3 Incorrect (one defect in three places), 1 Unverifiable; probes in /tmp/u2a3-cfc-i1-S05k/).

Override-log scan: the `feat/build-loop-u2a2` rows dated 2026-10-06 matched: D8 (nested repo / submodule starts, Defer, trigger "U2a3's review") is the same claim as P5; the B6 row (`feat/build-loop-u2a3`, per-record cost) was not re-filed.

## 🔴 Must Fix

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | Symlink text on main is resolved with `realpath -ms` (lib main_imports' 120000 arm), which collapses `ld/..` without reading `ld`; the kernel follows `ld` first. Main with `ld -> deep/inner` and `CLAUDE.md -> ld/../evil.md`: Claude Code loads `deep/evil.md`, the walk read `evil.md` and was ok with `deep/secret.md: -`, with or without `ld` in the checkout. The "Not covered" list's "when the checkout does not have that link" is wrong for link text (executed) | Incorrect (behavioral; fail-open) | fact-check Claim 11b (P4), 2b, 3b | ✅ Fixed (iteration-1 fix commit) | Link text is resolved a component at a time; a `..` after a symlink on main or in the checkout fails the walk. Import tokens stay lexical, as Node's path.resolve is. Test: "main walk fails on symlink text with a .. after a symlink..."; mutant killed. |

## 🟡 Must Address

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A2 | The "Not covered" list, known issue A5 and plan F11 omit start files in a submodule or an untracked nested repo (walk ok, `docs/n.md: -`; executed) | Incorrect (comment/doc omission) | fact-check Claims 11b (P5), 2b, 3b; carries the U2a2 D8 row | ✅ Fixed (docs); code: Defer (override row) | Listed as not covered in all three places; U2b names the checkout. |
| A3 | The return-1 comment omits the short lower-cased start list (`[[ ${#low[@]} -eq ${#cand[@]} ]] \|\| return 1`) | Mostly accurate | fact-check Claim 13 | ✅ Fixed | |
| A4 | Plan's U2a3 bullet omits the leaves-the-repo and unreadable-checkout-file refusals | Mostly accurate | fact-check Claim 4 | ✅ Fixed | |
| A5 | fbeae280's B5 test numbering and its .claude/rules symlink note | Mostly accurate (commit message) | fact-check Claims 22, 27 | Accepted-immutable (override row) | |

## 🟢 Consider

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A6 | "a checkout keeps the last" copy of a doubled name, not executed | Unverifiable | fact-check Claim 14b | Won't-Fix (override row) | The refusal does not depend on it. |

## Escalations carried to iteration 2's critics

- security: P4 (fixed; check the fix) and P5 (documented) — fact-check E-list.
- architecture, security: the cache key (`IMPORTED_MAIN_DONE="$MAIN_SHA $ROOT_REAL"`) ignores checkout state, so an untracked start file added after a successful walk is not seen by a second call in the same shell; it also ignores MAIN_BY_NAME (fails closed only).
- test-strategy: no test of an untracked `.claude/rules` start, a symlink chain on main, or the cache.

## ↩️ Considered Overrides

`feat/build-loop-u2a2` D8 (nested repo / submodule starts): matched P5; its trigger fired here; resolved as documentation plus a new Defer row. `feat/build-loop-u2a3` B6 (per-record cost): not re-filed.

## ⏭️ Skipped Core Critics

| Critic | Reason |
|---|---|
| security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review, test-strategy | loop-pass short-circuit (behavioral red confirmed) |

## 🧩 Composition check

No multi-source co-located clusters qualified (one source this pass).
