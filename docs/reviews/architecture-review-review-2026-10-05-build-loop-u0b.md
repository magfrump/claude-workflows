Commit: 09cb3764

# Architecture Review — feat/build-loop-u0b, iteration 2 (fix 09cb3764)

**Scope:** `git diff feat/build-loop-u0b~1 feat/build-loop-u0b` (lib, bats); the rebase via `git range-diff 7cbbe8d2^! feat/build-loop-u0b~1^!` (header comments and the T29 list only)
**Date:** 2026-10-05
**Based on:** iteration-1 report `docs/reviews/architecture-review-review-2026-10-04-build-loop-u0b.md`; rubric `docs/reviews/code-review-rubric-2026-10-04-feat-build-loop-u0b.md`; override-log rows dated 2026-10-05.

> ⚠️ **No code fact-check report provided for iteration 2.** Architectural claims in the new comments were checked against the code by this reviewer only.

Scope check: in scope. The fix adds a public predicate (`main_by_name`), moves the declaration of `MAIN`/`MAIN_SHA`/`MAIN_BY_NAME` into the lib, and changes the contract of `check_brief`/`check_branch`. Trust-boundary cross-reference: active. The guard sits on **B5** of `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73` — security review predates this diff; boundary may be stale).

## Status of iteration-1 items

| Item | Status |
|---|---|
| Rubric A1 / Arch finding 1 (Coupling): check_brief/check_branch's precondition enforced only in dev-cycle.sh | **Closed.** Both functions now open with `if ! main_by_name; then echo "skip …: no default branch found by name …"; return; fi` (lib `:229`, `:275`). The predicate checks both conditions iteration 1 named (`[[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]`, `:219`), so the "resolve_main never called" case and the "current-branch fallback" case are both refused. |
| Arch finding 2 (Informational): "once per process" | **Resolved.** Header `:12-13`: "It calls resolve_main once per process (a second call re-reads main)". |
| Rebase conflict resolutions | Comment and T29-list only. No structural change. |

## Dependency Map

```
dev-cycle.sh ──source──▶ lib (declares MAIN, MAIN_SHA, MAIN_BY_NAME at :218)
lib check_brief / check_branch ──▶ main_by_name ──reads──▶ MAIN_SHA, MAIN_BY_NAME
dev-cycle.sh :332 ──reads──▶ MAIN_BY_NAME directly (its own exit-1 policy, unchanged)
```

The verdict functions and their correctness condition are now in the same module, which is the direction iteration 1 asked for. The globals are declared by their owner rather than appearing first as assignments inside `resolve_main`.

## Findings

#### 1. dev-cycle.sh keeps its own spelling of the found-by-name test

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:332`; `scripts/lib/dev-cycle-read.sh:219`
**Move:** 7 (coupling)
**Confidence:** High
**Legibility target:** for-author

Evidence (tip 09cb3764):

```bash
if [[ ( "$CHECK" == --check-brief || "$CHECK" == --check-branch ) && -z "$MAIN_BY_NAME" ]]; then
```
(`scripts/dev-cycle.sh:332`. The `if` continues to `:334` with the exit-1 message; read.)

```bash
main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }
```
(lib `:219`, whole)

Two definitions of one condition now exist. Today they agree: dev-cycle.sh calls `resolve_main` first, and `resolve_main` sets `MAIN_BY_NAME` only together with `MAIN_SHA`. Keeping the script's exit-1 policy separate from the lib's `skip` verdict is right, because each script owns its exit policy. But the *condition* could be shared. If the lib's notion of "found by name" ever changes, dev-cycle.sh's early exit would drift from what the functions it guards actually accept.

**Recommendation:** Optional and behaviour-neutral: `... && ! main_by_name; then` at `:332`. U1 can do it, since build-loop.sh will be the second user of the predicate.

## What Looks Good

- **Fail-closed at B5's transition point, not a moved boundary.** The guard adds a check where the `ls-tree` gate already is, so a gate-side consumer inherits it automatically. **Security implication:** none beyond iteration 1's note. The B5 crossing is not moved, and the `skip` wording is for the security reviewer to confirm against B5's rule.
- **Error channels stay consistent.** A missing default branch is a state of the repo, so the lib answers with a `skip` line, matching the existing check-mode grammar. It does not exit. This keeps the "lib reports, script decides" split that `resolve_main` established (contrast `need_root`, which exits on a caller bug; see the U0a report).
- **Declared by the owner.** Initialising `MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""` at source time (`:218`) makes `set -u` callers safe before `resolve_main`. dev-cycle.sh does not assign these before sourcing, so nothing is clobbered.
- **The test can fail.** The new test covers both the before-`resolve_main` case and the fallback case (4 skips, no `ok`). When I deleted the two guard lines in a scratch worktree, it failed. The `resolve_main` test now pins the return code (`none 1:`), which is what the returns-not-exits contract promises.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | dev-cycle.sh's early exit spells the found-by-name condition itself instead of calling `main_by_name` | Informational | `scripts/dev-cycle.sh:332`; lib `:219` | High |

## Overall Assessment

The iteration-1 Coupling finding is closed: the invariant now lives with the verdicts it protects, it fails closed, it is stated in the header, and a test exercises it. The fix adds no coupling. It removes the one place where a second consumer had to know a rule that only dev-cycle.sh enforced. The remaining item is a one-word deduplication.

## Goal-Alignment Note

The goal is to land U0b after a clean loop. Rubric A1, the only Must Address item, is resolved. No Structural or Coupling finding remains. dev-cycle.sh's output is unchanged, because it exits at `:332-334` before the guard can be reached, and the full suite is 59/59 at the stack tip. From the architecture lens, U0b is ready to land.
