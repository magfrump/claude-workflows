Commit: 3d2d8c44

# Performance Review: feat/build-loop-u2b3a, final confirming pass (full branch)

**Scope:** full branch, `git diff main...HEAD -- scripts test`: `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b3a-final.md` (k=3, Commit 3d2d8c44, 0 Incorrect), the rubric `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b3a.md` (iterations 1-2), my iteration-2 report `performance-review-2026-10-08-u2b3a-i2.md`, and the shared brief `u2b3a-i3/shared.md` with its override rows
**Replication:** k=1 (loop pass, final)

There was one probe, `u2b3a3-perf/p1-failpath.sh` in the session scratchpad, with its log in `p1.log`. It starts with `set -eu`, makes its own `mktemp -d /tmp/u2b3a3-perf-XXXX` and checks `pwd -P`. It runs no `git init`, `commit` or `worktree add`. It runs the walks read-only in this worktree's checkout and `git worktree list` read-only in `/workspace`. Every command ran under `timeout`, and the probe removed its temp dir at the end. No process or dir with my prefix remains.

## Data Flow and Hot Paths

The branch widens the import parser from one root and one home to a reader set:

- **`import_readers`** (`scripts/lib/dev-cycle-read.sh:891-927`) builds the reader set: ROOT_REAL, every registered worktree, the caller's roots, and the homes. It runs one `git worktree list` and one batched `realpath -mz`, and memoizes the result until `import_reset`.
- **The awk parser** (`:711-838`) joins each relative candidate against every root and directory (`:729`). It then projects each resolved spelling against every root (`:755-760`). Every parser process rebuilds the `dotnest` table in BEGIN (`:822-823`).
- **The walks** (`imported_names` `:1045-1078`, `main_imports` `:1094-1187`) call `import_readers` before their cache check and key their caches on the reader set.

Temperatures:

- **Walks:** cold. They run once per gate decision or `--check-fix` run, after `import_reset`.
- **Cached `isimported`/`truthwalk`:** warm. They run once per argument in `--check-fix`, and once per changed path in U2c's floor loop.

Sizes today (fact-check claim 3, executed):

- **Roots:** 24.
- **Names:** 128 per walk, equal to main's set.
- **Honest charged work:** 330,570 per walk, against a 50,000,000 bound.
- **Cached `isimported`:** about 3 ms.
- **Bound spent:** honest walks spend the bound near 570-585 roots.

### Prior findings re-checked

| Prior | Status at 3d2d8c44 | Evidence |
|---|---|---|
| i1 F1 / rubric A3 (reader set recomputed per call) | Holds fixed | One `git worktree list` across 30 calls on the success path (p1). Cached isimported 2.9-3.5 ms [fact-check: claim 3 — Verified] |
| i1 F2 / G5 (uncharged projection loop) | Holds fixed | `work += nr` at `:755`, and the spent bound costs about 9 s at 24 roots [fact-check: claim 2 — Mostly accurate, upper ends held] |
| i2 F1 / H1 (O(nr²) honest work) | Settled. Documented at `:631-635` with `git worktree prune` as the remedy, and no worse than recorded | Bound spent near 570-585 roots (fact-check claim 3) |
| i2 F2 / H2 (dotnest rebuilt per parser process) | Settled. Deferred override row, and no worse than recorded | `:822-823` unchanged since iteration 2 |

## Findings

#### F1. A failed reader set is not cached: each later walk call re-forks `git worktree list` before failing again

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:895-898`, `:1049`, `:1099`
**Move:** Question the cache; Count the hidden multiplications
**Classification:** Micro (one fork of about 1-5 ms per call) / warm path (per-path `isimported`/`truthwalk` calls in one decision), reached only when the reader set cannot be modelled
**Confidence:** High (executed)
**Baseline:** 30 `isimported tree` calls with `IMPORT_READER_ROOTS=rel/cw` forked `git worktree list` 30 times in 151 ms total (about 5 ms per call). The success path forked it once across 30 calls. One `git worktree list` over `/workspace`'s 24-entry registry took 1.15 ms (`u2b3a3-perf/p1-failpath.sh`, `p1.log`, 2026-10-08)
**Legibility-target:** for-author

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:895-898 (inside import_readers :891-927, read whole)
  [[ "$IMPORT_READERS_DONE" != "$IMPORT_READERS_KEY" ]] || return 0
  k="$IMPORT_READERS_KEY"
  IMPORT_READERS_DONE=""
  nul_list rs_l git worktree list --porcelain -z || return 1
# :1049 (imported_names :1045-1078, read whole)
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }
# :1099 (main_imports :1094-1187, read whole)
  import_readers || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; return 1; }
```

On a failure, `import_readers` leaves `IMPORT_READERS_DONE` empty. The walks also clear their own `*_DONE` keys. So the next `isimported` or `truthwalk` call in the same decision repeats `import_home`'s key check and the registry fork, and fails again in the same place. Most refusals happen after the listing: a relative or `/` caller root, or a newline in a registered path. A `realpath`-stage refusal adds a second fork per call.

The answer is still correct: it fails closed every time, and isimported answers imported. On main, an `import_home` failure after `IMPORTED_DONE` was set was cached as an error, so this case cost no fork per call there.

The cost is negligible. U2c's floor loop over 30 changed paths would spend about 0.15 s, and only on a branch it already refuses whole. The walks' comments say "a cached error returns 1 again". That remains true for parser and budget failures. A reader-set failure is not cached but recomputed, which nothing in the comments states.

**Recommendation:** none needed for the merge. If U2b3b's settings reader makes a malformed caller list plausible, cache the failure under the key: set `IMPORT_READERS_DONE="!$k"` and return 1 on a hit with a leading `!`. Alternatively, validate the caller lists before the `git worktree list` fork.

## Endorsements

- The reader-set memo holds across a decision. The registry is read once, and a cached isimported costs about 3 ms at 24 roots. [fact-check: claim 3 — Verified]
- Over `/workspace`, both walks give main's 128 names at 330,570 charged work. The dotnest projection did not multiply the output, so IMPORT_OUT_MAX's load and the per-name `lower`/`inrepo_here` work downstream are unchanged. [fact-check: claim 3 — Verified]
- The per-file work bound still bounds time with the per-root charge: about 9 s worst shape at 24 roots. [fact-check: claim 2 — Mostly accurate (upper ends held; low end informational)]
- `put`'s `tried` check (`:735-736`) runs before the `work += nr` projection charge (`:755`). A spelling repeated within one file therefore pays only its `length(c)` join charge, not a second nr-root scan. [read: scripts/lib/dev-cycle-read.sh:731-767]
- At 24 roots, the reader-set validation and dedup (`:904-919`) are one pass over 2×(roots + homes) entries with an associative `rs_seen`, run once per decision. [read: scripts/lib/dev-cycle-read.sh:891-927]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | A failed reader set is not cached: each later isimported/truthwalk call in the decision re-forks `git worktree list` (about 5 ms per call), then fails closed again | Informational | `scripts/lib/dev-cycle-read.sh:895-898`, `:1049`, `:1099` | High |

## Overall Assessment

The branch's performance posture is sound for merge. No red or amber finding comes from the performance lens:

- **Earlier fixes hold.** The per-call reader-set cost (A3) and the uncharged projection loop (G5) remain fixed.
- **Settled items are unchanged.** The square-of-roots growth (H1, documented) and the per-process dotnest rebuild (H2, deferred row) measure as recorded: the bound is spent near 570-585 roots, against 24 today.
- **One new item, Informational.** A reader-set failure is recomputed on every call instead of cached. It costs about 5 ms per call, only on a decision that already refuses everything, and it is fixable in place if U2b3b makes such failures likely.

No further profiling is needed before merge.

## Goal-Alignment Note
- **Success criterion** (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/performance-review-2026-10-08-u2b3a-final.md, structured per the performance-reviewer skill, with `Commit: 3d2d8c44` as its first line.
- **Answered:** yes.
- **Out of scope:**
  - The square-of-roots growth and the dotnest rebuild. Both are settled (H1 documented, H2 deferred row), and neither measures worse than recorded.
  - U2b3b's host roots and settings line, and U2c's floor caller (override rows).
  - The correctness of the dotnest rule, which security and architecture own.
  - Fact-check claim 1's wording (empty ROOT_REAL), which is not a performance matter.
- **Escalate:** nothing blocking.
- **Decisions I made:**
  - I probed only the new failure-path question (p1).
  - I relied on the k=3 fact-check's executed figures for the walk work, names, cached-call time and bound point, and did not re-time them.
