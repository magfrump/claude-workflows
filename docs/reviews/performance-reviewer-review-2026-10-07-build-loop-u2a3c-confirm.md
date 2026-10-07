Commit: 380ed01b

# Performance Review — feat/build-loop-u2a3c (final confirming pass)

**Scope:** `git diff main...HEAD` (HEAD 380ed01b; last code commit 4b7f2357), mainly `scripts/lib/dev-cycle-read.sh` `main_checkout` and `main_imports`
**Date:** 2026-10-07
**Based on:** Stage-1 summary `u2a3c-i4-stage1.md` and the `## Escalations` sections of `docs/reviews/code-fact-check-report-build-loop-u2a3c-r{1,2,3}.md`
**Measurements:** scratch dir `/tmp/u2a3c-i4-perf-Lgkb` (`h.sh` harness, `mk.sh`, `big.sh`, `mkshort.sh`, `attr.sh`, `shift2.sh`, `lib-head.sh` = 4b7f2357's lib, `lib-3a35.sh`, `lib-main.sh`, `lib-qh.sh` = HEAD with an index-based queue). Host: 16 cores. Runs were repeated at load average about 1 where a figure is quoted as "low load".

## Data Flow and Hot Paths

`main_imports` is the gate's @-import walk. It runs once per gate run, so it is a cold path. Its inputs, however, are shaped by the branch: checkout files, and the tokens in them. Per printed candidate that main lacks, it calls `main_checkout ent pok "$p"` (`:877`). Per queued file, it pops `queue` (`:841`), forks a reader, the parser and `lower`, and appends to the queue. Phase 2 moves `tq` (the checkout files that main lacks and that were admitted) into `queue` (`:840`).

The collections that grow per walk are:
- ENT: main's tree.
- MEMO (`pok`): one entry per decided ancestor.
- `seen`: one entry per distinct printed name.
- `queue`/`tq`: one entry per admitted file.

4b7f2357 changed two things in `main_checkout`: the O(1) type check (`:741`) and the PATH guard (`:743`). Both are constant work per call. This pass looked for any other per-call cost that grows with ENT, MEMO, `seen` or the queue, across the shapes the brief names.

## Findings

#### P1. `main_imports` pops its queue with a whole-array copy, so phase 2 is quadratic in admitted checkout files: 5,000 imported untracked files take 85.8 s, against 42.7 s with an index pointer

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:841` (also `:840`; the same pattern in `imported_names` at `:780`)
**Move:** Count the hidden multiplications / check the asymptotic behaviour
**Classification:** Macro (each pop costs O(|queue|), so the walk costs O(N²)) / Cold path. It was not escalated to the hot tier: the input is branch-controlled, but reaching it needs thousands of admitted files, and the walk's linear per-file cost (about 9-14 ms of forks) is already a deferred row.
**Confidence:** High (measured; the same fixture and two libs differing only in the queue lines)
**Legibility-target:** code
**Baseline:** at low load, one main walk over 5,000 untracked `f/x<i>.md` files, all imported from main's `CLAUDE.md`: 85.82 s at HEAD and 42.72 s with an index-based queue (`lib-qh.sh`). Under load (about 12): 2,000 files took 42.32 s against 28.24 s, and 10,000 took 319.51 s against 95.19 s. Measured 2026-10-07 with `h.sh` on `r-files*`.

Evidence (verbatim, `main_imports` `:839-841`; the loop body continues through `:882`):
```
  while [[ ${#queue[@]} -gt 0 || ${#tq[@]} -gt 0 ]]; do
    [[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }  # phase 2: main's walk is done
    f="${queue[0]}"; queue=("${queue[@]:1}")
```

`queue=("${queue[@]:1}")` rebuilds the array on every pop. In isolation, draining N short entries this way costs 1.18 s for N=2,000, 7.28 s for 5,000 and 29.55 s for 10,000 (`shift2.sh`), which is quadratic. Inside the walk the measured gap is larger: 43 s at 5,000 files and 224 s at 10,000. Heap churn appears to make each later fork slower as well. That cause is plausible but was not isolated: only the totals were measured, and only the queue lines differ between the two libs.

The pattern is on main, in both walks. Before this branch, though, main's walk queued only main's own files. The checkout phase sends every admitted checkout file through the same queue, and a branch controls how many there are. The settled per-start row ("Linear in instruction-named files", 2026-10-06) assumed linear cost. Below about 1,000 files that holds: the prior pass measured 1,200 files at 12.7 s. At 5,000 files the shift doubles the walk, and at 10,000 it more than triples it. This is not a regression in `main_checkout`, and it does not touch 4b7f2357. It is the remaining per-call cost that grows with the queue.

**Recommendation:** Pop by index instead: `local qh=0`, test `qh -lt ${#queue[@]}`, read `f="${queue[qh]}"; qh=$((qh + 1))`, and reset `qh=0` where phase 2 copies `tq` in. This is a three-line change; the patch in `lib-qh.sh` walks all three fixtures with the same result. If the loop prefers to defer it, widen the per-start override row: its "linear" premise holds only up to about 1,000 admitted files. `imported_names` (`:780`) has the same shift, and its string `seen` is matched linearly per candidate (`:790`). Both are on main and outside this diff, so they would share the revisit trigger.

## Fixes re-measured (4b7f2357)

- **D1, the type check.** `${m[0]@a}` costs 6.9-7.4 µs per call at 0, 1,000, 10,000 and 100,000 entries. `${m@a}` costs 96 µs, 1.18 ms and 20.6 ms at the same sizes (`attr.sh`). The answers are unchanged:
  - `A` for an empty associative array, one holding key `0`, and one with 50,000 entries.
  - `a` for indexed arrays, empty or not.
  - empty for a scalar and for an unset name.
  - Whether key `0` exists makes no difference under the local `set +u`.
- **Many tokens.** 2,000, 4,000, 8,000 and 16,000 distinct 8-deep absent tokens take 1.67, 3.42, 6.72 and 13.87 s at HEAD, which is linear at about 0.85 ms per token. The previous pass measured 85 s for 4,000 at 3a35c8b9.
- **Many short tokens (the budget ceiling).** 50,000, 100,000 and 200,000 single-component absent tokens take 2.61, 5.31 and 10.58 s, which is linear at about 53 µs per name. Main's lib takes 3.47 s for 200,000. At 300,000 the walk fails in 1.31 s, because a budget trips; at this root's length that is presumably IMPORT_WORK_MAX, but which budget was not isolated. A shorter root fits more names before the budget trips, up to about IMPORT_OUT_MAX / 7 ≈ 570k, so expect at most about 30 s. That ceiling is bounded and linear.
- **Large main tree.** With a 50,000-entry tree, HEAD takes 3.52 s with 1,000 tokens and 5.49 s with 8,000. Main's lib takes 3.38 and 3.94 s. The previous pass measured 33 s at 3a35c8b9 with 1,000 tokens.
- **Deep absent token.** At D=1990, HEAD takes 2.34 s and 3a35c8b9 2.55 s. The cost is linear in printed bytes and unchanged.
- **Many siblings.** 20,000 absent `@d/x<i>.md` take 4.59 s at HEAD and 4.03 s at 3a35c8b9, which is linear.
- **Deep present-directory token.** The settled D³ realpath row stands. 4b7f2357 did not change `rawfile`, `plaindir` or the top-down arm (`:747-755`), so the row's premise is unchanged. Fact-check r1 reproduced it (HEAD 11.7 s, 21b35ebf 31.5 s at D=1000).
- **PATH guard (`:743`).** It is one associative lookup and one regex test per call, so it adds constant work. Its cost is included in the many-token figures above.
- **Test pins.** I concur with the Stage-1 test-strategy escalation: only the 20 s timeout guards D1, and the xtrace-count test does not. A host-independent alternative is to time the same walk at 1,000 and 4,000 tokens and assert that the ratio stays under about 8. That ratio is about 4 when linear and about 16 when quadratic. This is a test-strategy item, not filed here.

## Endorsements

- `${mc_e[0]@a}` costs about 7 µs per call whatever the array size (0 to 100,000 entries), where `${m@a}` costs 20.6 ms at 100,000. It gives the same type answer as `${x@a}` for empty, keyed, 50,000-entry, indexed, scalar and unset variables [unverified — submitted as claim]
- At HEAD the checkout phase is linear in distinct absent tokens: 1.67, 3.42, 6.72 and 13.87 s for 2,000, 4,000, 8,000 and 16,000 8-deep tokens [unverified — submitted as claim]
- With a 50,000-entry main tree, HEAD's walk costs 3.52 s with 1,000 absent tokens and 5.49 s with 8,000, within 1.6 s of main's lib (3.38 and 3.94 s) [unverified — submitted as claim]
- A deep absent token at D=1990 walks in 2.34 s, and 20,000 absent siblings walk in 4.59 s at HEAD, both unchanged from 3a35c8b9 [unverified — submitted as claim]
- The budgets cap the cheapest-per-byte shape: 200,000 single-component absent tokens walk in 10.58 s, and 300,000 fail in 1.31 s [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| P1 | Queue pop copies the whole array, so phase 2 is quadratic in admitted checkout files: 5,000 files take 85.8 s, against 42.7 s with an index pointer (10,000: 319.5 s against 95.2 s, under load) | Low | `dev-cycle-read.sh:841` (`:840`, `:780`) | High |

## Overall Assessment

4b7f2357's performance fix is right and complete for the shape it targeted. The type check is O(1) at every array size measured, and the walk is now linear in tokens, in absent depth, in siblings, and on a 50,000-entry main tree. The new PATH guard adds constant work.

The one per-call cost left that grows with a walk collection is the queue pop. It predates this branch, but this branch now feeds checkout files through it. It is quadratic, with a crossover near 1,000 to 2,000 admitted files, and doubles the walk at 5,000. Reaching it needs thousands of committed files, and the linear floor at that scale is already a deferred row, so it is Low and fixable in place with three lines. No structural problem remains. The settled D³ row for deep present directories is unchanged.

## Goal-Alignment Note

The goal is to land `feat/build-loop-u2a3c` once its review-fix loop is clean. This pass found no regression in 4b7f2357 and no new cost in `main_checkout`. Its one finding, P1, is new to the reports but not new code: the shift is on main, and an earlier pass mentioned it in passing as "quadratic in principle" without measuring it at scale. P1 is Low and Macro × Cold, and does not block merging on its merits.

Per the brief ("any new finding goes back to the user"), P1 is the item to route. Option [1] is the three-line index pop now. Option [2] is to widen the per-start override row: its "linear" premise holds only to about 1,000 admitted files. Option [2] could share the revisit trigger of the first real caller of `main_imports` (U2a4/U2b).

Nothing here re-files a settled row. The D³ realpath row, the uncharged drain and @-less scan, and the two-walk bound stand as decided.
