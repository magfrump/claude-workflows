Commit: 09cb3764

# Security Review — feat/build-loop-u0b, iteration 2 (fix 09cb3764: main_by_name guard in check_brief/check_branch)

**Scope:** `git diff feat/build-loop-u0b~1 feat/build-loop-u0b`; rebase of the move commit via `git range-diff 7cbbe8d2^! feat/build-loop-u0b~1^!` (header comments and the T29 function list only — checked, no code change)
**Date:** 2026-10-05
**Based on:** iteration-1 report docs/reviews/security-reviewer-review-2026-10-04-build-loop-u0b.md; rubric docs/reviews/code-review-rubric-2026-10-04-feat-build-loop-u0b.md

> ⚠️ **No iteration-2 code fact-check report provided.** Claims below rest on executed probes and a mutation run.

## Prior findings

| Iteration-1 finding | Status | Evidence |
|---|---|---|
| 1. Brief/branch readers trust a fallback (non-default) branch; by-name guard left in the caller (Low, B2/B4) | **Resolved** | `check_brief`/`check_branch` now open with `if ! main_by_name; then echo "skip …"; return; fi` (`scripts/lib/dev-cycle-read.sh:229,275`); executed: the iteration-1 probe shape (only branch `feature-x`, brief `Status: done`) now prints `skip …: no default branch found by name` before and after `resolve_main`; the header contract states it (`:12-14`). |

## Trust Boundary Map

```
B1 (unchanged): [origin/HEAD, refs/heads/*, current HEAD]         → [resolve_main: resets MAIN/MAIN_SHA/MAIN_BY_NAME, -* skip, show-ref --verify] → [MAIN / MAIN_SHA / MAIN_BY_NAME]
B4 (moved in):  [MAIN_SHA + MAIN_BY_NAME globals]                 → [main_by_name, first line of check_brief / check_branch]                     → [git reads of MAIN_SHA's tree/history]
```

```
S2: current branch / HEAD — runtime-mutable — UNTRUSTED as a source of brief state
S4: MAIN_BY_NAME / MAIN_SHA — code-set by resolve_main; initialised empty at source time (`:218`), so an exported env value does not survive sourcing
S6: the process's cwd repo at check time vs at resolve time — caller-controlled — trusted only if the caller stays in one repository
```

## Findings

#### 1. A MAIN_SHA resolved in another repository passes main_by_name; check_brief then reports a landed brief as `new` and exits 0

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:219,237-238` (check_branch `:283`)
**Boundary:** B4
**Move:** #3 (error path), #11
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (u0b tip):
```
main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }
```
```
  case "$(git ls-tree "$MAIN_SHA" -- "$a" | cut -c1-6)" in
    '') echo "ok $a new"; return ;;
```
Probe (probe2.sh B2: `resolve_main` in repo `named`, `cd` to repo `fallback`, no re-resolve, `set -euo pipefail`):
```
fatal: not a tree object
ok docs/working/briefs/2026-10-02-a-b.md new
fatal: Invalid revision range 790b2b18…..17659d6b…
ok feature-x 17659d6b…  2026-10-05
[exit 0]
```
The guard checks that a by-name resolution happened, not that it happened in the repository now being read; a failed `git ls-tree` inside the `case` word is not seen by errexit, so a git error becomes the verdict `new` (not landed) and a blank commit count. Same root as fact-check E5's empty-MAIN_SHA case, which the guard now closes; the foreign-SHA variant remains. Not reachable: dev-cycle.sh resolves once after `cd "$ROOT"`, and loop worktrees share the repository's objects and refs, so a SHA from one worktree is valid in another. It would need a caller that handles two repositories in one process, which the plan does not have; the header's "calls resolve_main once per process" already implies one repository.

**Recommendation:** None required for U0b. If cheap, make `check_brief` treat a failed `ls-tree` as `skip` (e.g. `git cat-file -e "$MAIN_SHA^{commit}"` in main_by_name, one fork), so a git error can never print `ok … new`.

## Untested bypass candidates

- B1: origin/HEAD naming a branch that exists locally only because a loop created it (e.g. origin/HEAD → `trunk`, loop creates local `trunk`): resolve_main sets MAIN_BY_NAME=1 for it, so main_by_name passes. Pre-existing, moved verbatim, settled; still not tested — the new guard relies on it.

(Tested, all skip: MAIN_BY_NAME=1/MAIN_SHA/MAIN exported in the env before sourcing (B1 in probe2.sh — reset at `:218`); a by-name resolve followed by a failed or fallback re-resolve (B3 — MAIN_BY_NAME reset at `:295`); resolve_main run only inside `$(...)` (B4 — globals do not leave the subshell); calls before resolve_main and after a fallback resolve (the bats case).)

## Endorsement Claims

- **Claim:** check_brief and check_branch print `skip … no default branch found by name` and make no git call on MAIN_SHA when resolve_main has not run, ran only in a subshell, or last resolved to the current-branch fallback.
  **Location:** `scripts/lib/dev-cycle-read.sh:218-219,229,275,295`
  **Evidence:** executed
  **Verified:** probe2.sh B1, B3, B4; bats case `test/scripts/dev-cycle.bats:1073` passes at the tip and fails (`ok … open`, `ok f1 …` printed) when main_by_name is mutated to test only MAIN_SHA (mutate.sh).
  **Not verified:** origin/HEAD pointing at a loop-created local branch (listed above).
  **route: code-fact-check**
- **Claim:** dev-cycle.sh's own early exit for `--check-brief`/`--check-branch` without MAIN_BY_NAME is unchanged, so its CLI behaviour does not change with the lib guard.
  **Location:** `scripts/dev-cycle.sh` (the `-z "$MAIN_BY_NAME"` test before the check loop)
  **Evidence:** read-static
  **Verified:** the test and its message are unchanged in the u0b diff.
  **Not verified:** the full bats suite at the tip (only the new case and its mutation were run).

## Primitive sweep

Primitive: git invocation reading MAIN_SHA
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:237` ls-tree | S3 path, S4 | main_by_name, pathform, isbrief, blocker | prior finding resolved; Finding 1 (foreign SHA → `new`) |
| `:245` cat-file blob | S3, S4 | as above + mode 100644/100755 | cleared — reached only after ls-tree returned a mode |
| `:260-261` git log | S3, S4 | as above, `--` | cleared |
| `:281-283` show-ref / rev-parse / rev-list / log | S3, S4 | main_by_name, NAMECHARS, check-ref-format, show-ref --verify | prior finding resolved; Finding 1 (foreign SHA → blank count) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Foreign-repo MAIN_SHA passes main_by_name; git error becomes `ok … new` | Informational | B4 | `scripts/lib/dev-cycle-read.sh:219,237-238` | High |

## Overall Assessment

The iteration-1 Low finding is closed: the by-name requirement now lives in the two readers that need it, globals are initialised at source time so the environment cannot pre-set them, and the new bats case fails when the guard is weakened. The remaining note is a caller-misuse shape (two repositories in one process) that no planned caller has. No findings within the code paths read; endorsement claims pending execution verification by code-fact-check.

## Goal-Alignment Note
- Success criterion (restated verbatim): one markdown report per unit at OUTPUT_PATTERN (unit = u0a, u0b, u0c), structured per your skill, first line `Commit: <unit tip short SHA>`, ending with the Goal-Alignment Note.
- Answered: yes — prior Low resolved (executed), four main_by_name bypass candidates probed, new test mutation-checked, rebase range-diff checked.
- Out of scope: the `git log -G` cost note (override-log 2026-10-05, deferred to U1); FENCE_AWK semantics.
- Escalate: none.
- Decisions I made: rated Finding 1 Informational — no planned caller spans two repositories.
