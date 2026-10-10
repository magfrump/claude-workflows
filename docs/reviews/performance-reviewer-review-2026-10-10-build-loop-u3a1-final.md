Commit: d10cfba8

# Performance Review: feat/build-loop-u3a1 (final confirming pass, full branch)

**Scope:** `git diff main...HEAD` at d10cfba8 (base d5736445; `docs/reviews` excluded): `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, plan step 7 notes.
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u3a1-final-r3.md` (k=3; Claims 1, 3, 11, 17, 18 Verified; Claim 2 Mostly accurate). Prior: `performance-reviewer-review-2026-10-10-build-loop-u3a1.md`, `...-u3a1-i2.md`. Settled: override-log rows 639, 640, 647.

## Data Flow and Hot Paths

`--check BRIEF...` runs `gate_start` once (`scripts/build-loop.sh:854-861`), which calls `store_check "$MAIN_SHA"` and moves the call's verified ids to `$GATE_TMP/main`. `check_line` then runs once per brief (`:947-952`). For each brief that reaches a merge tree, it calls `store_check "$sha" "$tree"` (`:916`). That call re-hashes only ids not in `$GATE_TMP/main`, writes them to a fresh `$GATE_TMP/call`, and scans the store for second copies of main's ids plus this call's ids (`:618-645`). D9 caps the slots at 9, so N ≤ ~9. **Path temperature:** startup is cold. The per-brief call is warm at most, a loop body with N ≤ 9. No finding can clear the hot-path gate for High.

New since iteration 2 (d10cfba8):
- **Per-call id file.** The duplicate join's `want` set is `main` plus `call` (`:645`). In iteration 2 it was the cumulative `checked`. The set is the same size in practice: main's ~3.6k ids plus a brief's ~24.
- **`find -L` listing.** The `.idx` list goes to a file first, and the loose-object find follows links (`:641-644`).
- **`core.multiPackIndex=false`** in harden's pairs (`:273`), so every hardened git call (cat-file, ls-tree, merge-base, merge-tree, diff-tree) looks objects up pack by pack rather than through /workspace's multi-pack-index.

**Measurements.** All were taken 2026-10-10 against a byte copy of /workspace's object store: the packs including `multi-pack-index` and the `.mtimes` cruft pack, plus the loose objects, copied into a throwaway repo under my scratch dir, with main = d5736445. Nothing was written in /workspace. store_check was extracted verbatim from d10cfba8 (`awk` from `store_check() {` to the closing `}`) and run under harden's six pairs and the exported env, `LC_ALL=C`. The machine is shared, so read the numbers as order of magnitude.

| Measurement | Result |
|---|---|
| Store | 21,742 packed ids in 4 packs plus multi-pack-index; 42 loose. `$GATE_TMP/main` = 3,581 ids |
| Startup `store_check main`, `core.multiPackIndex=false` (as shipped) | 246 / 254 / 242 / 250 / 254 / 244 ms |
| Same, `core.multiPackIndex=true` | 247 / 242 / 242 / 245 / 249 / 250 ms |
| Per-brief shape `store_check $TIP $TIP^{tree}` (TIP = d10cfba8; `call` = 24 ids), midx false | 26 / 29 / 24 / 26 / 25 / 24 ms |
| Same, midx true | 26 / 26 / 25 / 23 / 24 / 25 ms |
| `cat-file --batch-check` of all 21,784 ids, midx false / true | 19-20 ms / 18-21 ms |
| Synthetic: 50 packs × 400 blobs plus midx, 20,000 shuffled lookups, midx false / true | 15, 14 ms / 8, 9 ms |
| Whole `build-loop.sh --check` on the copy, one brief that skips before store_check | 321 / 320 / 313 ms (gate_start's store_check is ~245 ms of it) |

## Findings

#### F1. `core.multiPackIndex=false` makes every hardened object lookup scale with the pack count; unmeasurable at 4 packs, ~0.3 µs per lookup at 50

**Severity:** Informational
**Location:** `scripts/build-loop.sh:273` (harden), which reaches store_check's `cat-file --batch` (`:631`) and gate_git's merge-base / merge-tree / diff-tree (`:681-686`, `:887`)
**Move:** Price the deployment environment; check the asymptotic behavior
**Classification:** Micro (a per-lookup constant that grows with the pack count) / Cold to warm (startup plus N ≤ 9 briefs)
**Confidence:** High for /workspace today (measured). Medium for the 50-pack figure (synthetic small blobs)
**Baseline:** startup store_check 242-254 ms with the multi-pack-index off vs 242-250 ms with it on, on a copy of /workspace's 4-pack store, measured 2026-10-10 (this review, 6 runs each)

Evidence (verbatim, `:271-277`, the whole function):

```bash
harden() {
  local c="${GIT_CONFIG_COUNT:-0}" kv
  for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false core.multiPackIndex=false; do
    export "GIT_CONFIG_KEY_$c=${kv%%=*}" "GIT_CONFIG_VALUE_$c=${kv#*=}"; c=$((c + 1))
  done
  export GIT_CONFIG_COUNT="$c"
}
```

Without the multi-pack-index, git finds an object by binary-searching each pack's `.idx` in turn. /workspace's packs carry a midx, so the gate gives up its single lookup. At 4 packs the difference is inside the noise: startup 242-254 ms vs 242-250 ms, per brief 24-29 ms vs 23-26 ms, and 21,784 batch-check lookups at 19-20 ms either way. A synthetic 50-pack store, `gc.autoPackLimit`'s default ceiling, showed 20,000 lookups at 14-15 ms off vs 8-9 ms on, about 0.3 µs extra per lookup. Startup does ~3.6k lookups, so that is ~1 ms. merge-tree's lookups for a brief are of the same order. This is well below the settled scan cost at 50 packs (~45 ms of show-index forks, row 647), and that row's trigger already covers the pack count. Losing midx's lookup speed is the price of the i2 security fix, and at any pack count the gate reaches it is not material.

**Recommendation:** No change. Row 647's 50-pack trigger already covers this. If that trigger ever fires, measure merge-tree with the midx off as well as the scan.
**Legibility-target:** for-orchestrator-synthesis

No other findings. The per-call id file and the `find -L` listing add no measurable cost. Per brief, store_check measured 24-29 ms at d10cfba8 against 21-22 ms at 83f75281 (iteration 2, on /workspace itself). The 3-7 ms difference is within this shared machine's variance plus the slightly larger store (42 loose vs 21), and the `call` set is the same size as before (24 vs 20 ids). The settled rows still stand and are not re-filed: 639 (startup follows main's bytes, still ~0.245 s), 640 (perl holds the largest blob) and 647 (the scan follows the store size, N+1 times).

## Endorsements

- The whole-run cost of store_check at d10cfba8 on a copy of /workspace's store is ~0.245 s at startup plus ~0.025 s per brief that reaches a merge, so about 0.47 s for a 9-brief `--check`. The whole `--check` took 313-321 ms for one brief that skips before store_check. [fact-check: Claim 1 — Verified]
- Judging only one call's ids does not enlarge the join. `want` is `main` (3,581 ids) plus `call` (24 ids), the same size as iteration 2's cumulative `checked`, and the store's id list is still streamed and not held. [read: scripts/build-loop.sh:618-645]
- The `.idx` list goes to `$GATE_TMP/idx` once, followed by one `show-index` fork per pack and one `find -L` over the 256 fan-out dirs (maxdepth 2), so there is still no per-id process. [read: scripts/build-loop.sh:641-645]
- check_line now reads the brief once, through `status_fields`, and takes branch, sha and Paths from `STATUS`/`BRIEF`. In the review's view this removes main's branch and brief re-reads per brief, a small per-brief saving. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | multi-pack-index off: lookups scale with the pack count (no measurable change at 4 packs; ~0.3 µs per lookup at 50, synthetic) | Informational | `scripts/build-loop.sh:273` | High (today) / Medium (50 packs) |

## Overall Assessment

The branch's performance posture is unchanged from iteration 2. A `--check` pays ~0.25 s once to re-hash main and ~25 ms per brief to re-hash the tip and merge objects and scan for second copies. That is about 0.47 s at 9 briefs on /workspace's 3,581-object tree and 21.7k-id, 4-pack store. Iteration 3's changes (the per-call id file, `find -L`, the multi-pack-index off) measured no cost above noise. The midx change is the only one with a scaling term, and that term stays at about a millisecond even at the auto-gc pack ceiling. The settled revisit triggers (rows 639 and 647) remain the right watch points. Nothing here blocks the merge, and no further profiling is needed.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your dispatch names, structured per your skill.
- Answered: yes. I measured the whole branch's per-`--check` cost at d10cfba8 (startup and per brief, extrapolated to N = 9), and the new items: the per-call id file, `find -L`, and `core.multiPackIndex=false` with and without the midx, on a copy of /workspace's store and on a 50-pack synthetic store.
- Out of scope: whether one copy per id is sufficient (security). The per-brief merge-path timing with a real open brief: the copy's three briefs all skip before the merge, so the per-brief figure is store_check's extracted cost with main's tree standing in for the merge tree, as in iterations 1 and 2.
- Escalate: none.
- Decisions I made: I measured on a byte copy of /workspace's objects (with its midx) under my scratch dir rather than in /workspace, so that the full `--check` run's merge-tree would write nothing there. I treated `--check` as warm (N ≤ 9), which caps severity. The copy and the synthetic store are deleted, and no probe process remains.
