Commit: d8da1fba

# Performance Review — feat/build-loop-u0c, final confirming pass (full range)

**Scope:** `git diff feat/build-loop-u0b..feat/build-loop-u0c` (41065ce6, 1c7373d3, d8da1fba, incl. the plan amendment) and their commit messages
**Date:** 2026-10-05
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u0c.md` (merged k=3, Commit d8da1fba: root-keyed cache, need_root at the walk's top, verbatim move and byte-identical output all verified by execution)

## Data Flow and Hot Paths

U0c moves the import walk (`imported_names`, `lower`, `INSTRUCTION_FILE`, `IMPORT_RE`) and `ANSWER_AWK`/`check_answer` into the lib, puts `need_root` at the walk's top and keys the walk's cache on `ROOT_REAL`. The walk runs once per process (first `check_fix` call; later calls hit the `IMPORTED_DONE == ROOT_REAL` test). Inside the walk, each instruction file and each resolved `@` import pays `$(lower)`, `inrepo` (now need_root's `$(pwd -P)` + `$(blocker)` + realpath forks) and, for imports, `$(realpath -ms)`. `check_answer` calls `skipped` for two fixed files per ID. The digest calls none of these. Path temperature: cold (once per process, N = instruction files + imports in the checkout).

Measured by this reviewer, 2026-10-05 (scratch worktrees, same target checkout):

- Digest: median main 421 ms vs U0c 423 ms (7 interleaved runs each, U0c `439 421 425 443 816 423 420`); output md5 identical.
- `--check-fix docs/a.md README.md skills/code-review/SKILL.md` (traced, `DEV_CYCLE_SCRUBBED=1 bash -x`): main 1 `pwd -P` / 49 `inrepo`; U0c 54 `pwd -P` / 49 `inrepo`; one walk per process in both. Wall ms, 5 interleaved runs: main 392 368 364 403 369 (median 369); U0c 407 385 417 405 390 (median 405), ~+36 ms (~10%), of which 53 extra forks x ~0.32 ms explain ~17 ms; the remainder is within the spread.
- `--check-answer Q-001 Q-002 Q-003`, 5 runs: main 41 42 40 41 53 (median 41); U0c 45 46 46 45 48 (median 46): 6 extra `pwd -P` forks plus two lib sources.

## Findings

#### The import walk pays need_root's `$(pwd -P)` once per instruction file and per import

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:347-376` (walk; `inrepo` at `:352` and `:373`), via `need_root` `:80-83`
**Move:** Count the hidden multiplications
**Classification:** Micro (one fork per inrepo) / Cold path (once per process), but the multiplier is a repo-growth number (49 on this repo, one per skills/*/SKILL.md and import)
**Confidence:** High
**Baseline:** `--check-fix` median 369 ms on main vs 405 ms at U0c, 5 runs each (this reviewer, 2026-10-05); 53 extra `pwd -P` forks traced per walk
**Evidence:** `    if [[ ! "$(lower "${f##*/}")" =~ $INSTRUCTION_FILE ]] || ! inrepo "$f"; then continue; fi` and `inrepo() { need_root; [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }`
**Legibility-target:** for-author

The walk already called `need_root` once at its top (1c7373d3) and ROOT_REAL cannot change inside it, yet every `inrepo` in its loops re-forks `$(pwd -P)` to re-prove the same fact. The cost is linear in instruction files plus imports (~0.32 ms each, ~17 ms here, ~4% of a `--check-fix` run). It is per process and cached, so it matters only if a caller runs the walk in many processes (deferred C10: build-loop.sh calling dev-cycle.sh per path) or the repo grows to hundreds of SKILL.md files.

**Recommendation:** Not needed to land. If U2's floor makes the walk warmer, have the walk call a non-guarded internal (`blocker` + `-f`) after its own top-level `need_root`, keeping the public `inrepo` guarded; re-measure `--check-fix` against the 369 ms baseline.

## Endorsements

- The root-keyed cache keeps one walk per process for a fixed ROOT_REAL: a second `imported_names` call returns at the cache test, and a different root recomputes. [fact-check: "root-keyed cache (recomputes for another root; one root cached)" — Verified]
- The prefilter grep before the per-path loop keeps forks proportional to instruction files (49), not to all tracked files. [unverified — submitted as claim]
- `IMPORTED` is reset only on a cache miss, so its size is bounded by one root's import set. [read: scripts/lib/dev-cycle-read.sh:350]
- The digest does not call the walk or check_answer; its time and bytes match main (median 423 vs 421 ms). [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Walk re-forks `$(pwd -P)` per instruction file and import | Low | `scripts/lib/dev-cycle-read.sh:347-376` | High |

## Overall Assessment

The move is behaviour-preserving and the cache fix keeps one walk per process. The measurable cost of the unit stack lands here: `--check-fix` is ~36 ms slower than main (median 369 → 405 ms), about half traced to need_root's per-call `$(pwd -P)` inside the walk. That is cold, linear and acceptable to land; it becomes worth the internal non-guarded helper only if U1/U2 run the walk per path or per process at scale (C10 stays with U1/U2).

## Goal-Alignment Note

Serves landing U0c after a clean loop: measured digest, `--check-fix` and `--check-answer` against main and traced how often need_root forks in the walk. The one Low finding is a forward cost, not a blocker; the plan amendment has no performance content. From the performance side U0c is clean to land.
