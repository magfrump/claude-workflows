Commit: 83f75281

# Performance Review: feat/build-loop-u3a1 (iteration 2, fix range)

**Scope:** `git diff 65007bf8..83f75281` (iteration 1's fix batch; `docs/reviews` excluded). The rest of the branch was reviewed in iteration 1 and is context here.
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u3a1-i2.md` (k=1; Claims 1, 12, 13, 14, 17 and 18 Verified, with no timing claims). Iteration 1: `docs/reviews/performance-reviewer-review-2026-10-10-build-loop-u3a1.md`.

## Data Flow and Hot Paths

`--check BRIEF...` calls `gate_start` once, and gate_start calls `store_check "$MAIN_SHA"` (`scripts/build-loop.sh:854`). After that, `check_line` runs once per brief (`:948-952`) and calls `store_check "$sha" "$tree"` (`:911`) for every brief that reaches a merge tree. D9 caps the slots at 9, so N is at most about 10. **Path temperature:** the startup call is cold. The per-brief call is a loop body with N ≤ ~10, so it is warm at most. No finding here clears the hot-path gate for High.

The fix batch changes store_check (`:614-641`, whole function) in two ways:
- **Skip (performance i1 F1):** the first awk loads `$GATE_TMP/checked` into `seen` and passes on only ids that are not already in it (`:624`). perl appends each id it verifies (`:630-632`), so the per-brief call reads only the objects main does not share.
- **Duplicate scan (security i1 F1):** every call runs one `git show-index` per `pack/*.idx`, one `find` over the loose fan-out dirs, and one awk join against `checked` (`:634-640`). It lists every id in the store, including history, unreachable objects and cruft packs, so its size is not tied to main's tree.

All measurements were read-only against /workspace's objects: `rev-parse`, `ls-tree`, `cat-file --batch`, `show-index` and `find`. Nothing was written there. The probe is store_check extracted verbatim from `:614-641`, run under `bash` with `LC_ALL=C` and `GATE_TMP` in my scratch dir. Probe scripts are in `scratchpad/u3a1-i2/performance/` (`probe2.sh` to `probe4.sh`). The machine is shared, so treat the numbers as order of magnitude.

| Measurement (/workspace, 2026-10-10) | Result |
|---|---|
| Store | 21,742 packed ids in 4 packs (420 / 14,459 / 2,023 / 4,840 ids; one is a cruft pack with `.mtimes`; a `multi-pack-index` is present). 21 loose objects. 21,763 ids listed by the scan, all distinct |
| `store_check $MAIN` (startup, with the scan) | 243 / 244 / 238 ms; `checked` = 3,581 ids; rc 0 |
| `store_check $TIP $MAIN^{tree}` (a brief's shape, run after the startup call) | 21 / 22 / 21 ms (a repeat call: 18 ms); rc 0 |
| Duplicate scan alone (`:634-640`) | 9 / 12 / 8 ms, of which show-index plus awk over 4 packs takes 6-7 ms and find takes 1 ms |
| Per-pack fixed cost (show-index plus awk on the 420-id idx, ×50) | about 0.9 ms per pack |
| Per-id cost (the 14,459-id idx, ×20) | 2.75 ms per pass, about 0.13 µs per id after the fork |
| Awk join at scale (1,000,000 synthetic ids against a 3,691-id `checked`, mawk) | 121 ms (a plain awk print of 1M lines takes 60 ms) |
| Iteration 1 baseline, per-brief call before the skip | 0.237 s (iteration 1 report, measured on d5736445) |

The per-brief saving that iteration 1 measured still holds at HEAD 83f75281. The per-brief call fell from 0.237 s to about 0.021 s. Of that, about 11 ms is the re-hash of the 20 ids that were not skipped (`checked` grew from 3,581 to 3,601), and about 9 ms is the new duplicate scan. Iteration 1 predicted 0.010 s with the skip alone, and that matches. A `--check` of N briefs now costs about 0.24 + 0.02 × N s in store_check, down from 0.24 × (N + 1) s. At 9 slots that is 0.42 s instead of 2.4 s.

Carried over from iteration 1, and unchanged by this batch: F2 (the startup re-hash follows main's blob bytes, still 0.24 s) and F3 (perl's peak memory is the largest blob). Neither is re-filed here.

## Findings

#### F1. The duplicate scan scales with the whole object store, not with main's tree or the brief's diff, and it runs N + 1 times

**Severity:** Low
**Location:** `scripts/build-loop.sh:634-640` (inside store_check, `:614-641`), called at `:854` and `:911`
**Move:** Ask "what's the size of N?"; count the hidden multiplications
**Classification:** Macro (linear in total store ids plus a fork per pack) / warm path (once at startup plus once per brief, N ≤ ~10)
**Confidence:** High for today's cost (measured). Medium for the extrapolation (based on measured per-id and per-pack rates, not on a real large store)
**Baseline:** 9 ms per scan over 21,763 ids in 4 packs on /workspace, measured 2026-10-10 (this review, 3 runs, `probe2.sh`)

Evidence (verbatim, `:633-640`; store_check ends at `:641` with `}`):

```bash
  # Every copy in the store: each pack index's ids, then each loose object file.
  { for p in "$o"/pack/*.idx; do
      [[ -e "$p" ]] || continue
      git show-index --object-format="$fmt" < "$p" | awk '{ print $2 }' || exit 1
    done
    # From inside the store: a -path pattern would read glob characters in its path.
    (cd "$o" && find . -mindepth 2 -maxdepth 2 ! -type d -path './[0123456789abcdef][0123456789abcdef]/*') | awk -F/ '{ print $(NF - 1) $NF }'
  } | awk 'FILENAME != "-" { want[$0]; next } ($0 in want) && n[$0]++ { bad = 1 } END { exit bad }' "$GATE_TMP/checked" -
```

The scan lists every id the store holds. That includes all of history, unreachable objects kept in cruft packs, and every pack's copy. Its cost therefore grows with the repository's lifetime object count and its pack count, not with the 3.6k objects of main's tree. It runs on every store_check call, so N + 1 times per `--check`. The re-hash pass, by contrast, is now incremental. Today the scan is small: 9 ms, which is about 45% of a per-brief call and about 4% of the startup call. The measured rates are about 0.9 ms per pack (one show-index fork) and about 0.25-0.3 µs per id across show-index, awk print and the join (`probe3.sh`, `probe4.sh`). Extrapolated, a store of 1M ids costs about 0.3 s per scan, which is 3 s for a 9-brief `--check`. 50 packs (`gc.autoPackLimit`'s default ceiling before auto-gc consolidates) add about 45 ms per scan. /workspace is two orders of magnitude below that, and iteration 1 measured main's tree growing about 2x a month, so this is a revisit trigger, not a defect. Memory stays bounded: the join holds only `checked` (`want`, `n`), so the full store id list is streamed and never held.

Re-scanning per brief is not pure waste. A second copy of one of main's ids added mid-run is caught at the next brief's scan. Narrowing the per-brief scan to only the newly checked ids would therefore weaken coverage, and I do not recommend it.

**Recommendation:** No change in this unit. Add the store's id count (`git count-objects -v` in-pack plus count) to iteration 1 F2's revisit trigger in the plan's as-built note, for example re-measure when the store passes 500k ids or 50 packs. If it ever matters, list the store once per run into `$GATE_TMP` and re-list only the packs and fan-out dirs whose mtime changed. That keeps the mid-run catch at lower cost.
**Legibility-target:** for-orchestrator-synthesis

## Endorsements

- The per-brief call reads and re-hashes only ids not already in `$GATE_TMP/checked`, which closes iteration 1 F1. Measured: 0.237 s became about 0.021 s per brief at HEAD 83f75281, including the new scan. [fact-check: Claim 12 — Verified]
- The scan uses one `show-index` fork per pack, one `find` and one join awk per call, with no per-id process. The join's memory is the `checked` set (about 3.6k ids), not the store's id list. [read: scripts/build-loop.sh:633-641]
- `checked` stays near main's object count plus each brief's new objects. The skip awk prints an id only when it is not already in `seen`, so a hex id is never read twice. The exception is a `REV^{tree}` name, which is not a hex id and is re-read each call (one tree object per REV). [read: scripts/build-loop.sh:621-632]
- A failed or truncated `.idx` read fails the call rather than skipping that pack, so the scan's speed does not come from silently dropping a pack. [fact-check: Claim 14 — Verified]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The duplicate scan follows total store ids and pack count, N + 1 times per run (9 ms today; about 0.3 s per scan at 1M ids, extrapolated) | Low | `scripts/build-loop.sh:634-640` | High (today) / Medium (extrapolation) |

## Overall Assessment

The fix batch does what iteration 1 F1 asked. Per brief, store_check now costs about 21 ms instead of 237 ms, and about half of that is the new duplicate scan. The startup call is unchanged at about 0.24 s, because the scan adds only about 9 ms. The duplicate scan's cost grows with the whole store, including history and cruft, and it runs N + 1 times. That cost is negligible at /workspace's 21.7k ids and 4 packs, and it is a revisit trigger alongside iteration 1 F2, not a merge blocker. No new profiling is needed. Nothing here blocks the merge.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your dispatch names, structured per your skill.
- Answered: yes. I measured the duplicate scan's cost on /workspace (21,763 ids, 4 packs), its per-pack and per-id rates and its extrapolated scaling, and the checked-file filter's cost within the per-brief call. I confirmed that the i1 per-brief saving holds at 83f75281 (0.237 s became about 0.021 s).
- Out of scope: whether one copy per id is sufficient (midx, cruft, delta bases: security and the fact-check's Claim 13 scope). The availability cost of a legitimate duplicate, such as overlapping packs from an incremental repack, now refusing `--check`: the commit's Notes accept it, and /workspace has none today. Another behaviour for the security and api reviewers: a duplicate found in one brief's call leaves its ids in `checked`, so every later brief's scan also fails with the same reason in that run. That fails closed, but the reason is reported against briefs that do not own the object.
- Escalate: none for performance. The per-brief scan's run-wide failure mentioned above goes to the orchestrator for the security and api critics.
- Decisions I made: I treated `--check` as warm (N ≤ ~10, D9), which caps severity at Low. I used main's tree as the stand-in for the merge tree in the per-brief timing, as in iteration 1. The 1M-id figure comes from synthetic ids through the real awk join, plus the measured show-index rate, not from a real store of that size.
