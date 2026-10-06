Commit: 36b79f72

# Performance Review — feat/build-loop-u2a (U2a, iteration 2)

**Scope:** full branch diff `git diff main...HEAD` (merge base 900c47d0; cfbf34d2, b9ffe7a8, 36b79f72)
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a.md` (at b9ffe7a8; 36b79f72 closes its R1/A1-A4); override-log rows 207, 212, 214, 220, 236, 310
**Legibility-target:** for-orchestrator-synthesis

Measurements: all on this worktree (2,900 tracked entries on main, 45 instruction files on main, 0 untracked .md), bash with `LC_ALL=C`, timings from `$EPOCHREALTIME`. Scripts and logs are under `/tmp/claude-1000/-workspace/f2b09f27-e8e1-48a1-9e62-9ab10d974ed8/scratchpad/review-u2a/perf/` (`walks.sh`, `floor.sh`, `parts.sh`, `mw.sh`, `tw.sh`, `cf.sh`, `tb.sh`, `h1.log`, `h2.log`, `m1.log`). The main comparison used a detached `git worktree add` of main (900c47d0) under that directory, removed afterwards; no process remains.

## Data Flow and Hot Paths

- `floor` (`scripts/lib/dev-cycle-read.sh:573-589`) is called once per changed path by U2c's `--check`, once per merge, in one shell. Its first call that reaches the import arm runs `main_imports` once; later calls read the cache keyed on `MAIN_SHA`. Path temperature: **cold to warm**. It runs once per merge, over N changed paths. N is usually tens and can reach a few hundred.
- `main_imports` (`:496-537`) runs once per process. It does one `git ls-tree -r -z` of main, filtered by `instruction_names`. Then, for each instruction file, it runs one `lower` fork and one `git cat-file blob | import_targets` pipeline. Each distinct import target gets one `realpath` and one `main_entry`, and `untracked_md` runs once. Path temperature: **cold** (once per process).
- `imported_names` (`:474-491`) is the working-tree walk, now built on the shared `import_targets`. `check_fix` (`scripts/dev-cycle.sh:172-186`) now reaches it only through `isimported tree` at `:183`. That is after the cheap arms, so a path refused earlier never runs the walk. Path temperature: **cold** (once per `--check-fix` process).

Measured numbers (median of 3-5 runs):

| What | Branch | Main |
|---|---|---|
| `main_imports`, whole walk | 194-216 ms (`walks.sh`, 5 runs) | n/a |
| of which `ls-tree -r | instruction_names` | 3.4 ms | n/a |
| of which 45 × `cat-file | import_targets` | 90 ms (`mw.sh`) | n/a |
| `imported_names` (tree walk) | 331-345 ms | 336-348 ms (main's lib, same repo) |
| `imported_names` vs `main_imports` result lists | 3 entries each, identical (`diff` → SAME) | |
| `floor`, first call (runs the walk) | 190-211 ms | n/a |
| `floor` over 200 tracked paths (120 refused), cached walk | 741-779 ms, 3.7-3.9 ms/path (one cold first run: 3,472 ms, 17.4 ms/path) | n/a |
| `floor docs/foo.md` (reaches the import arm) | 3.27-3.29 ms/call | n/a |
| `floor scripts/lib/x.sh` (refused at the gate-code arm) | 1.57-1.91 ms/call | n/a |
| `need_root` | 0.34-0.37 ms/call | |
| `lower` in `$(...)` | 1.0-1.3 ms/call | |
| `main_entry docs/working/questions.md` | 2.80-2.82 ms/call | |
| `dev-cycle.sh --check-fix scripts/foo.sh` (early skip) | 14 ms | 348-370 ms |
| `dev-cycle.sh --check-fix docs/thoughts/x.md` (reaches the walk) | 348-365 ms | 353-373 ms |
| `bats dev-cycle.bats build-loop-read.bats` (92 tests) | 26.2-26.3 s, 92 ok | 26.1-26.4 s, 92 ok |
| `bats build-loop-check.bats` (4 tests, new) | 0.7 s, 4 ok | n/a |

The suite time does not change (26.2 s on the branch against 26.1-26.4 s on main, within noise). The refactored tree walk costs the same as main's (about 337 ms against about 340 ms).

## Findings

#### floor lower-cases every path twice: once itself and again inside isimported

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:576`, `scripts/lib/dev-cycle-read.sh:543`, `scripts/lib/dev-cycle-read.sh:580`
**Move:** Count the hidden multiplications
**Classification:** Micro (one redundant fork per call) / Warm path (per changed path in U2c's `--check`, once per merge)
**Confidence:** High
**Baseline:** `floor docs/foo.md` 3.27-3.29 ms/call, of which one `lower` is 1.0-1.3 ms/call (`parts.sh`, this worktree, 2026-10-06)

`floor` sets `lp="$(lower "$1")"` at `:576` and then calls `isimported main "$lp"` at `:580`. `isimported` begins with `lp="$(lower "$2")"` at `:543` and lower-cases the already lower-cased path again, which costs one subshell plus one `tr` exec. Every path that reaches the import arm pays this, and on these measurements that is about a third of `floor`'s per-path cost (1.0-1.3 ms of 3.3 ms). Over the 200-path run, 80 of 200 paths passed the floor and so reached the arm, along with any path refused at the import arm or later. That comes to roughly 0.1-0.3 s per `--check` for a few hundred paths: noticeable, but nowhere near blocking. This is distinct from row 212 (`need_root`'s `pwd -P` fork). `isimported` also runs `main_imports`, which calls `need_root` a second time, but that cost is row 212's and is not re-raised here.

**Recommendation:** Have `floor` test `IMPORTED_MAIN` directly after `main_imports`, or give `isimported` a lower-cased-input contract (the caller lowers). That removes one fork per path. Do not replace `lower` with `${1,,}`, because its ASCII-only folding depends on the locale.

#### The main walk is linear in main's instruction files at about 3-4 ms each

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:509-516`, `scripts/lib/dev-cycle-read.sh:521-536`
**Move:** Ask "what's the size of N?"
**Classification:** Micro (one fork pipeline per instruction file) / Cold path (once per process)
**Confidence:** High
**Baseline:** `main_imports` 194-216 ms with 45 instruction files on main. The `cat-file | import_targets` pipelines are 90 ms of that, the record loop's 45 `lower` forks are about 45-55 ms, and `ls-tree -r` is 3.4 ms (`mw.sh`, `walks.sh`, this worktree, 2026-10-06)

For each regular-file instruction file on main, the walk forks `lower` once in the record loop (`:515`). It then forks one `git cat-file blob | import_targets` pipeline (`:524`). The `listed` and `seen` string scans and `queue=("${queue[@]:1}")` are O(n²) in that count, but at n=45 they are negligible. The `ls-tree -r` over the whole tree is cheap (3.4 ms for 2,900 entries), and the grep cuts the list to instruction files before any fork. At this repo's size the walk is cheaper than the tree walk it mirrors (about 200 ms against about 337 ms). A repo with about 1,000 SKILL.md/CLAUDE.md files would pay about 4 s once per `--check`. That is speculative for this repo and only a trigger to watch.

**Recommendation:** None now. If main's instruction-file count reaches the hundreds, read the blobs through one `git cat-file --batch` and lower-case basenames in one `tr` over the filtered listing.

## Endorsements

- `check_fix` now runs the import walk only when a path reaches the import arm (`isimported tree` at `scripts/dev-cycle.sh:183`), instead of unconditionally before the cheap arms. Measured: `--check-fix scripts/foo.sh` went from 348-370 ms on main to 14 ms on the branch. A path that reaches the walk is unchanged (348-365 ms against 353-373 ms). [read: scripts/dev-cycle.sh:172-186, scripts/lib/dev-cycle-read.sh:474-491, :541-546]
- `main_imports` filters the full `ls-tree -r` through one `grep -z` (`instruction_names`) before any per-record fork. The listing plus filter cost 3.4 ms on 2,900 entries. [read: scripts/lib/dev-cycle-read.sh:470, :508-516]
- `floor` checks the cheap pattern arms (instruction file, dotfile, gate code) before the import arm, so a refusal at those arms costs 1.6-1.9 ms and starts no walk if it is the process's first call. [read: scripts/lib/dev-cycle-read.sh:573-580]
- The main walk caches its result and its error for `MAIN_SHA`, so later `floor` calls in one `--check` process pay only the string test. [fact-check: claim 11c — Verified]
- Sharing `import_targets` did not change the tree walk's cost: `imported_names` took 331-345 ms on the branch against 336-348 ms on main's lib, on the same checkout, and both walks list the same 3 targets. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | floor lower-cases every path twice (about 1.1 ms of 3.3 ms per path) | Low | `scripts/lib/dev-cycle-read.sh:576,543` | High |
| 2 | Main walk is linear in main's instruction files, about 3-4 ms each (200 ms at 45) | Informational | `scripts/lib/dev-cycle-read.sh:509-536` | High |

## Overall Assessment

The branch's performance posture is sound. The main walk runs once per process at about 200 ms. `floor` costs 3.7-3.9 ms per path with the walk cached, or about 0.75 s over 200 changed paths, once per merge. The test suites run the same time as main's. `--check-fix` became about 25× faster for paths refused before the import arm. The only actionable item is the redundant second `lower` in `isimported`, about a third of `floor`'s per-path cost, and it is fixable in place. The rows covering per-path forks and `ls-tree` costs (207, 212, 214, 220, 236, 310) are not re-raised. `floor` itself calls `main_entry` only for import targets during the one walk, never per changed path, so row 310's per-path `main_entry` cost belongs to U2c's caller and can be re-measured there. No profiling beyond these numbers is needed before merge.
