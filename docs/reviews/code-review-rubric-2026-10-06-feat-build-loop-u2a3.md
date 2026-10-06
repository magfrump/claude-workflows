Commit: 45ad17b0
Loop-pass short-circuit: used at 45ad17b0
# Code Review Rubric

**Scope:** full branch `main...feat/build-loop-u2a3` at 45ad17b0 (iteration 1, `--loop-pass`); 344 changed code lines by pr-prep 1a | **Reviewed:** 2026-10-06 | **Status: ❌ iteration 1 short-circuited on a behavioral red (A1), fixed in the iteration-1 fix commit**

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
