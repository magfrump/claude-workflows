Commit: 27e38dc4

# Performance Review — feat/build-loop-u0c (pure move: INSTRUCTION_FILE, import walk, ANSWER_AWK, check_answer)

**Scope:** `git diff feat/build-loop-u0b..feat/build-loop-u0c` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats)
**Date:** 2026-10-04
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0c.md (Commit 27e38dc4)

## Data Flow and Hot Paths

The unit moves `INSTRUCTION_FILE`, `IMPORTED`/`IMPORTED_DONE`, `IMPORT_RE`, `lower`, `imported_names` (the transitive @-import walk), `ANSWER_AWK` and `check_answer` into the lib. Path temperature: **cold** for the diff itself. The one function with real per-run cost is `imported_names`: one `git ls-files` pair piped to a filtering grep, then per instruction file a `grep -o`, and per import token a `realpath` subshell and a `lower` (`printf | tr`) pipeline. It is memoized per process and called only from `check_fix` (`scripts/dev-cycle.sh:173`).

The things the brief asks about:

- **Memo across parent and child.** `IMPORTED=$'\n'; IMPORTED_DONE=""` now runs at source time (`scripts/lib/dev-cycle-read.sh:316`), i.e. in the parent too, but the parent never calls `imported_names`; the child re-sources and starts with an empty memo, as before. The walk still runs at most once per process. [fact-check: claim 6 — Verified, "Computed once" still holds per process]
- **Extra spawns or file reads from sourcing.** None at source time (T29 now also checks `ANSWER_AWK`, `INSTRUCTION_FILE`, `IMPORT_RE`). Parse cost of the full 447-line lib measured at ≈0.53 ms per process; end-to-end at this tip `--check-path README.md` ran 21.1–21.5 ms/run vs 20.7 ms/run at feat/build-loop-handoff (30-run loops, this reviewer, 2026-10-04), including u0a's start-up constant.
- **Default branch resolution.** Untouched by this unit (`resolve_main` call stays at `scripts/dev-cycle.sh:182`, after `scrub_reexec`).
- **Per-call cost of moved functions for a second caller.** `check_answer` costs one `skipped` walk and one `awk` per questions file (two files), unchanged. `imported_names` is the one to watch, but its memo makes repeated calls in one process free after the first.

## Findings

#### Import-walk memo is per process, so a second script that spawns per item would redo the walk each time

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:316-321`
**Move:** Question the cache
**Classification:** Macro (walk cost grows with the number of instruction files and imports) / Cold path (once per process; no per-item caller exists yet)
**Confidence:** Medium
**Legibility-target:** U1 implementer (build-loop.sh)
**Baseline:** no baseline available — flagged as speculative

Evidence (feat/build-loop-u0c):
```
IMPORTED=$'\n'; IMPORTED_DONE=""
IMPORT_RE='(^|[^[:alnum:]])@[^][:space:]\\#`()]+'
lower() { printf '%s' "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'; }
imported_names() {
  local f t d p seen=$'\n' queue=()
  [[ -n "$IMPORTED_DONE" ]] && return; IMPORTED_DONE=1
  ... [function continues to :345 — the ls-files/grep seed loop and the BFS over imports]
```
The memo lives in shell variables, so it holds for the life of one process. dev-cycle.sh's `check_fix` calls it once per process and benefits fully. The commit says the walk is shared so build-loop.sh can use it; if build-loop.sh calls `imported_names` in-process (sourcing the lib), it gets the same once-per-process cost. If it instead runs `dev-cycle.sh --check-fix` once per changed path, every call re-runs `git ls-files` twice, the grep filter, and the per-import `realpath`/`lower` forks. The moved comment records that an earlier unfiltered version "took seconds", so the walk is not free. Nothing in this diff does that; it is a usage constraint for U1, not a defect here.

**Recommendation:** None for U0c. In U1, call `imported_names` (and `check_fix`'s predicate, if it moves) in-process from the sourced lib, once per `--merge`/`--check` run, rather than spawning dev-cycle.sh per path. A one-line note at the memo saying "per process: callers that need it per item should source the lib" would make the constraint visible.

## Endorsements

- The walk still runs at most once per process after the move, and the child starts with a fresh memo. (basis: fact-check: claim 6 — Verified) [unverified — submitted as claim]
- Moving the memo variables to source time does not trigger any work in the parent: the parent never calls `imported_names` before `scrub_reexec` exits it. (basis: read: scripts/dev-cycle.sh:89-90,173 and scripts/lib/dev-cycle-read.sh:54-59,316-321 at feat/build-loop-u0c) [unverified — submitted as claim]
- `check_answer` still runs one `awk` per questions file with `FENCE_AWK$ANSWER_AWK` concatenated, the same process count as before the move. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Import-walk memo is per process; a per-item spawning caller would redo the walk | Informational | `scripts/lib/dev-cycle-read.sh:316-321` | Medium |

## Overall Assessment

No regression in this unit: the moved code is verbatim, the memo still holds per process, sourcing runs nothing, and the measured end-to-end start-up delta for the whole stack is under 1 ms on a ~21 ms run. The one point worth carrying forward is how U1 consumes the shared walk: in-process via the sourced lib keeps it once per run; spawning dev-cycle.sh per path would multiply it.

## Goal-Alignment Note

The goal is a pure move with dev-cycle.sh's behaviour unchanged and the lib usable by build-loop.sh. Performance-wise dev-cycle.sh is unchanged, and the lib is usable cheaply by a second script as long as that script sources it and calls the functions in-process. The informational note concerns U1's usage, not U0c, and does not block landing.
