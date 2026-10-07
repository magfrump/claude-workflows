Commit: cc1aa864

# Performance Review — feat/build-loop-u2a3 (main_imports, iteration 3, final confirming pass)

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD cc1aa864). Perf-relevant code: `scripts/lib/dev-cycle-read.sh` nul_list (:519), main_imports (:549-618), isimported (:624-633). Focus: what changed since iteration 2 (e7b5d7ed parent-link loop, c42f017f nul_list and process substitution).
**Date:** 2026-10-06
**Based on:** the Stage 1 summary (factcheck-summary-i3, k=3 replicates -f-r1/-r2/-r3), docs/reviews/performance-reviewer-review-2026-10-06-build-loop-u2a3.md (iteration 2), and the settled rows in docs/reviews/override-log.md (:365-381).

## Data Flow and Hot Paths

main_imports runs once per merge-gate check. Nothing calls it until U2a4. Its result is cached per `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"`. **Path temperature: cold.** It runs once per merge and blocks no latency-sensitive operation. Since iteration 2 the walk has gained three things:
- (a) `nul_list` replaces two inline `mapfile ... rc=0` blocks (:556, :564).
- (b) Each queued file's import list is read through `< <(printf '%s\n' "$out")` instead of `<<<"$out"` (:616). That is one more fork per queued file.
- (c) For each newly seen path that main lacks, a loop walks back over every character of the path and looks up each `/`-terminated prefix in `ent` (:614).

All measurements below were taken on this host (WSL2, bash 5.2.15), in my scratch dir `/tmp/u2a3-perf-i3-lNTR`. The libraries compared are cc1aa864 (`new`), 2a3e499f (`old`, before c42f017f), cb4ebbc8 (`preparent`, before e7b5d7ed), and scratch mutants of `new`.
- **This worktree** (2,966 tree entries, 3 imports): the walk takes 394-433 ms over 5 runs. `old` took 395/424 ms, `new` 424/433 ms and the here-string mutant 394 ms, so no change is measurable at real-repo scale.
- **Probe repos:** one AGENTS.md imports 1,000 files. In `rm` they are tracked under `d/e/f/`; in `rt` they are untracked under `d/e/f/`; in `rlong` they are untracked under a 219-character, 20-level directory. Each was run 3x per lib:

| repo | preparent | old | new |
|---|---|---|---|
| rm | 5.98-8.80 s | 5.89-6.26 s | 6.97-9.93 s |
| rt | 10.66-13.39 s | 10.62-13.33 s | 11.92-14.64 s |
| rlong | 42.5-45.2 s | 42.4-45.9 s | 51.3-53.7 s |

  A second, alternating A/B run of the here-string mutant against `new` gave rlong 45.5/43.3 s against 52.0/52.9 s, and rm 6.40/6.23 s against 6.96/7.03 s. The ~6-7 ms per import that all three libraries share is the settled per-edge/per-blob fork cost (rows 346 and 355), and I have not re-filed it.

Settled rows not re-filed, because this diff does not change them: row 365/B6 (per-record cost), row 355 (queue pop and per-edge `lower`), row 346 (one cat-file per blob, batching), row 377 (ignored-.md cost) and row 378 (per-symlink cost).

## Findings

#### F1. The parent-link loop is quadratic in the length of an imported path main lacks: a single 64 KB `@` token costs 6.1 s (C locale) or 20.5 s (UTF-8), against 0.27 s and 3.8 s before e7b5d7ed

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:614` (excerpt ends :614; the enclosing main_imports() continues to :618, all read. :615 queues `t:$p` and :616 closes the edge loop.)
**Evidence:**
```
      for (( c = ${#p}; c > 0; c-- )); do [[ "${p:c:1}" != / || "${ent[${p:0:c}]:-}" != 120000 ]] || { IMPORTED_MAIN=error; return 1; }; done
```
**Move:** 9 (asymptotic behaviour), 2 (size of N)
**Classification:** Macro (O(L²) per path: L iterations, each taking `${p:c:1}`, and at each `/` a `${p:0:c}` copy plus a hash of a key up to L long; under a UTF-8 locale bash's substring indexing also rescans multibyte text) / Cold path (once per merge gate)
**Confidence:** High (measured)
**Baseline:** Measured in /tmp/u2a3-perf-i3-lNTR on 2026-10-06. Each probe repo held one tracked AGENTS.md with one `@a.../x.md` token that main lacks, and the walk returned ok in every run:

| L | preparent (C) | preparent (C.utf8) | cc1aa864 (C) | cc1aa864 (C.utf8) |
|---|---|---|---|---|
| 4,000 | 21 ms | 24 ms | 51 ms | 102 ms |
| 16,000 | 39 ms | 85 ms | 351 ms | 1,227 ms |
| 64,000 | 268 ms | 3,799 ms | 6,067 ms | 20,517 ms |

The loop alone, timed per path: L=50 is 0.11 ms, L=200 is 0.40 ms, L=1,000 is 3.0 ms (C) or 6.0 ms (UTF-8), and L=4,000 is 24 ms (C) or 96 ms (UTF-8).

**Legibility-target:** for-author

At realistic path lengths (under 250 characters) the loop costs under 0.5 ms per distinct path. The rlong probe shows no difference between `preparent` and `old` (42-46 s each), so normal repos do not pay for it. The cost is unbounded only because the length of an import path is not capped. `realpath -ms` does not touch the filesystem, so a token longer than PATH_MAX reaches :614 as `p`; the 64 KB case above walked ok. The loop runs once per distinct path, behind the `seen` test at :610. The inputs are main's committed instruction files and the checkout's untracked ones, which an agent in the build loop can write. So ten such tokens in one untracked CLAUDE.local.md would hold the gate for about 1-3.5 minutes before it answers. The walk does not fail open; it is only slow. Cold path, so Low.

There is also a forward note. Stage 1's Incorrect verdict (r2 Claims 13/18/27) asks for the parent check to be applied to starts as well. If it is, the same loop would run per start. Starts are real files, so their length is bounded by PATH_MAX: at most 24-96 ms each, which is harmless at typical start counts.

**Recommendation:** If the check stays per character, step over `/` positions only. A scratch mutant with `i="$p"; while [[ "$i" == */* ]]; do i="${i%/*}"; [[ "${ent[$i]:-}" != 120000 ]] || fail; done` measured 2.2 s (C) and 4.2 s (UTF-8) at L=64,000, which is 3-5x better. That mutant was perf-only and was not run against the suite. The linear option is to collect main's 120000 names into a short list during the record loop (:557-563) and test `[[ "$p" == "$link"/* ]]` for each one. That costs O(#links) per path and is usually 0-10 checks [unverified — submitted as claim]. Either rewrite must re-run test 9 and the e7b5d7ed parent-link mutants. If you defer this, record it as an override row with a cap-on-token-length trigger.

#### F2. Process substitution adds one fork per queued file: 0.6-1.0 ms per file on short paths, and 5-9 ms per file end to end on the 219-character-path probe

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:607-616` (excerpt ends :616; the enclosing main_imports() continues to :618, all read.)
**Evidence:**
```
    done < <(printf '%s\n' "$out")
```
**Move:** 1 (hidden multiplication), 3 (work moved to a costlier place)
**Classification:** Micro (one fork per queued file) / Cold path
**Confidence:** Medium. The per-fork cost is High (isolated micro-benchmark). How much of the larger rlong delta is attributable is Low; see below.
**Baseline:** Measured in /tmp/u2a3-perf-i3-lNTR on 2026-10-06:
- Micro-benchmark, 1,000 reads of a 1-line list: here-string 7-8 µs per read; process substitution 283 µs per read with empty shell state and 449 µs with 3 MB of state. Across 3,000 consecutive process substitutions the cost drifted from 463 to 607 µs, and later `$(...)` calls did not slow (258-310 µs before and after).
- Reading a 230 KB list once costs 4 ms with a here-string and 31 ms with process substitution, because `read` from a pipe goes byte by byte.
- End to end on 1,000 imports: rm +0.6-1.0 s, rt +0.5-1.3 s, rlong +5.5-9 s.
- With timers inside the edge loop, the time spent in that loop grew only by 0.6 s (rm), 0.46 s (rt) and 1.1 s (rlong).

**Legibility-target:** for-orchestrator-synthesis

c42f017f traded the here-string's temp file past 64 KiB (the fail-open, I2-C4) for a fork per queued file. On this worktree the walk queues 4 files, and the change is within noise (394-433 ms). At the 1,000-import probe scale it adds roughly 10% (rm), and 12-20% on rlong. My instrumentation does not account for the rest of rlong's end-to-end delta, which is about 4 s. It could be WSL scheduling noise around reaping the children, or the extra fork state, so treat that part as unattributed. This is not the settled per-edge `lower` fork (row 355). It is a new per-node fork that the fail-open fix introduced; the fix is correct, and this only prices it.

**Recommendation:** No change is needed for this unit. If row 355's batching rework ever happens, a fork-free split also avoids the temp file, for example `local IFS=$'\n'; set -f; for p in $out` (`local -` already scopes `set -f`) [unverified — submitted as claim: no temp file and no fork, and fail-closed is kept]. Fold it into that rework instead of spending lines at the 400-line cap.

## Endorsements

- `nul_list` adds no measurable cost over the two inline blocks it replaces. On this worktree, `old` took 395/424 ms and `new` 424/433 ms, inside run-to-run noise. The nameref (`local -n`) leaves `recs` as the same array without a copy [unverified — submitted as claim].
- The parent-link loop runs at most once per distinct import path main lacks, never once per edge. It sits after `[[ -z "${seen[$p]+set}" ]] || continue` and `seen[$p]=1`, and after the `ent` hit's `continue` [read: scripts/lib/dev-cycle-read.sh:607-616].
- The process substitution at :616 reads `$out` through a pipe and writes no temp file at any size, so the size-dependent failure mode is gone from this read. The :596 link-text here-string remains, which Stage 1 notes as Incorrect for correctness and which is not a perf matter [unverified — submitted as claim].

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Parent-link loop is O(L²) per path main lacks; a 64 KB token takes 6.1 s (C) or 20.5 s (UTF-8), against 0.27 s and 3.8 s before; under 0.5 ms at realistic lengths | Low | `scripts/lib/dev-cycle-read.sh:614` | High |
| F2 | Process substitution adds one fork per queued file: +0.6-1.0 ms per file (short paths), +5-9 ms per file end to end (long paths, partly unattributed); no change at real-repo scale | Informational | `scripts/lib/dev-cycle-read.sh:607-616` | Medium |

## Overall Assessment

The changes since iteration 2 are perf-neutral at real-repo scale: 394-433 ms on this worktree with or without them. Both new costs are correctness fixes, and both are priced here, not disputed. F1 is the only one with an unbounded input. Import paths are not capped by PATH_MAX, and the new per-character loop makes a long token quadratic, so a planted multi-KB token can stall the gate for seconds to minutes (not fail it open). Either recommended rewrite fixes that in place without touching the walk's model. F2 is the price of closing I2-C4 and belongs with row 355's batching rework. Neither needs profiling beyond the numbers above to decide. If F1 is fixed with the per-link prefix test, re-time the 64 KB probe and run test 9 and the e7b5d7ed mutants.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/performance-reviewer-review-2026-10-06-final-build-loop-u2a3.md, structured per the performance-reviewer skill."
- **Answered:** This report is saved at that path. Header, Data Flow, Findings with Baseline/Evidence/Severity/Confidence/Legibility-target, Endorsements with evidence tags, Summary Table and Overall Assessment are all present. It covers nul_list, the process substitution and the per-queued-path parent-link loop, all measured.
- **Out of scope:** the correctness findings from Stage 1, namely starts skipping the parent check, unsearchable checkout directories and ls-files exiting 0 with a warning, and the :596 here-string. They are left to fact-check and security, and only their perf implications are noted (F1's forward note). Also out of scope: settled rows 346, 355, 365, 377 and 378, and anything U2a3b changes.
- **Escalate:** F1 goes to the implementer, to fix or to defer with an override row whose trigger caps token length. I have no merge blocker from performance. Probe scratch dir `/tmp/u2a3-perf-i3-lNTR` (repos and lib copies) is left in place; I started no background processes.
