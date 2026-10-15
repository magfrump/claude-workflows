Commit: c4bab9ca

# Performance Review — fix/q145-ancestor-vanish (final confirming pass)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-q145 (HEAD c4bab9ca). Code files: `scripts/lib/dev-cycle-read.sh` (config_seeds, top_files), `test/scripts/build-loop-check.bats` (Q-145 walk test, new top_files unit test), `test/scripts/dev-cycle.bats` (one name added to a declare-F list), `docs/thoughts/failure-patterns.md` (FP-173)
**Date:** 2026-10-14
**Based on:** final code fact-check (k=3, 0 code defects, as reported by the caller); prior pass docs/reviews/performance-review-2026-10-14-q145.md (iteration 2, at 0d573a7b). Measurement baselines: docs/reviews/performance-review-2026-10-14-q102.md (build-loop-check.bats 119.5 s solo) and the walk-cost comment at `scripts/lib/dev-cycle-read.sh:836-838` (2 to 3.5 s per walk)

**Measurement conditions:** the timings were taken while other bats runs were active on the host. `uptime` load average was 12.4 to 12.7 on 16 CPUs, lower than the 19 to 24 in iteration 2. Absolute numbers are inflated and comparisons across passes are rough. Experiments ran on a `git archive HEAD` copy under /home/node/.claude/jobs/00bcf178/tmp/q145/review/perf-final/, with GNU findutils 4.9.0. Every process ran under `timeout` and had exited before this report was written.

## Data Flow and Hot Paths

Unchanged from iteration 2 apart from one thing: the `[[ -d ]]` recheck has moved inside `top_files`, so each of the three tries rechecks.

- `config_seeds` runs once per walk, because the walks cache.
- Its top-level listing is cold setup work over a handful of tops: `/`, `~/.claude`, and `/tmp` in the fixtures. Each top holds tens to about a hundred entries.
- `top_files` is one `nul_list ... find -H -maxdepth 1` call (one find process) plus a builtin `[[ -d ]]` per top. `nul_list` (`scripts/lib/dev-cycle-read.sh:1649`) is a `mapfile` over a process substitution, with no extra fork per entry.
- The chain at line 1566 starts the next try only when the previous one exits non-zero.

I read all of config_seeds (1508-1582), top_files (1583-1596) and nul_list (1649).

Measured, one `top_files` try over `/` plus `~/.claude`: **6.3 ms** (mean of 30, load 12.4).

## Findings

#### A top that is no longer a directory now costs three listings, not one, before the walk fails

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1566`, `scripts/lib/dev-cycle-read.sh:1593-1596`
**Move:** Find the work that moved to the wrong place (recheck moved inside the retried unit)
**Classification:** Micro (fixed two extra find processes) / Cold path (once per walk, and only when the walk then fails)
**Confidence:** High
**Baseline:** 7.4 ms for one failing try against 19.8 ms for the three-try chain (mean of 30 each, dead-link top, load 12.4 on 16 CPUs). Measured on the archive copy with perf-final/bench.sh

**Evidence:**
```
    top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" || return 1
```
```
  for tf_d in "${@:2}"; do [[ -d "$tf_d" ]] || { local -n tf_a="$1"; tf_a=(); return 1; }; done
```

At 0d573a7b the recheck ran once, after the chain, so a top that had vanished silently (or a linked top whose target was gone) cost one find before the walk failed. Now the recheck failure makes `top_files` return 1, and the chain runs find twice more. The measured extra cost is about 12 ms. That is under 1% of a 2 to 3.5 s walk, and it is paid only on a path that fails the walk anyway. The upside is that a top that is gone for only a moment gets the same retry as a transient find error. That is the behaviour the PR intends, and it is not waste.

**Recommendation:** Accept as is. No change needed.

#### Prior finding: Q-145 walk test adds time to the serially-run build-loop-check.bats (status: still present, smaller than measured before, accepted)

**Severity:** Low
**Location:** `test/scripts/build-loop-check.bats:724-777`
**Move:** Count the hidden multiplications (walks per test)
**Classification:** Micro (fixed per-walk cost × 10 walks) / Cold for the product, but on the gate's critical path (build-loop-check.bats runs `--no-parallelize-within-files`)
**Confidence:** High for the measurement
**Baseline:** build-loop-check.bats 119.5 s solo, measured in docs/reviews/performance-review-2026-10-14-q102.md

**Evidence:**
```
    for w in tree main; do
        mkdir -p "$a/.claude" && chmod 000 "$a/.claude"; rm -f "$a/shim/log"; PATH="$a/shim:$PATH" imps "$w" docs/a.md; chmod 755 "$a/.claude"; want walk failed
```

The test still runs 10 walks. Measured with `bats --timing -f 'Q-145'` at load 12.5 it took **3,438 ms**, against 7,136 ms at load 21 in iteration 2. The drop tracks the lower load and is not a code change. Since iteration 2 the `drop` case runs three listings per walk instead of one (the finding above). That adds about 4 × 12 ms, which is negligible. Against the 119.5 s baseline the test costs about 3%. The override row in `docs/reviews/override-log.md` still covers it.

**Recommendation:** Keep it accepted. The trim suggested in iteration 2 still applies if the fast-run bound becomes binding: run the `SHIM_RMTOP=1` case on one walk kind only. Re-baseline the file's solo time after merge.

## New test

The `top_files` unit test (`test/scripts/build-loop-check.bats:779-789`) runs one `bash -c` that sources the lib and makes three `top_files` calls over a five-entry fixture. It measured **148 ms**, mostly bash startup and sourcing the lib. It runs no walk and adds no meaningful time to the file.

## Endorsements

- The success path still runs exactly one find: `||` short-circuits, and `top_files` is one `nul_list ... find` plus a builtin loop. [read: scripts/lib/dev-cycle-read.sh:1566, 1593-1596, 1649]
- The retry bound is fixed at three tries, with no sleep and no loop, so the worst case is three listings. On this host that measured 19.8 ms. [read: scripts/lib/dev-cycle-read.sh:1566]
- The `-d` recheck forks nothing. It is a `[[ -d ]]` builtin per top, with K of about 2 to 4. [read: scripts/lib/dev-cycle-read.sh:1595]
- `config_seeds`, and with it the retried listing, runs once per walk because the walks cache. [fact-check: iteration-2 claim 11 — Verified; the final k=3 pass reported 0 code defects]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A top that is no longer a directory now costs three listings (~20 ms) instead of one (~7 ms) before the walk fails | Informational | `scripts/lib/dev-cycle-read.sh:1566,1593-1596` | High |
| 2 | (Prior, accepted) Q-145 walk test adds ~3.4 s at load 12.5 (7.1 s at load 21 before), ~3% of the 119.5 s baseline | Low | `test/scripts/build-loop-check.bats:724-777` | High |

## Overall Assessment

Nothing new of consequence. Moving the recheck into the retried helper adds about 12 ms, and only on a walk that fails anyway. The new unit test costs 148 ms. In the common case the change still runs one find, as main does. The prior Low finding still stands, is smaller at today's load, and remains covered by its override row. No profiling is needed before merge. One solo timing of build-loop-check.bats after merge would re-baseline it.

## Goal-Alignment Note

The PR aims to stop gate walks failing when another process deletes an entry in a shared ancestor such as `/tmp` mid-listing, without weakening fail-closed behaviour. From a performance standpoint the final shape fits that goal:

- One find in the common case.
- A bounded, immediate retry for transient errors, including a top that is gone for a moment, which the moved recheck now also retries.
- A fixed cost of about 20 ms under load before a persistent error fails the walk.

The residual risk noted in iteration 2 still holds, and it is outside this review's mandate: three back-to-back tries are not independent in time, so a nonzero flake rate under sustained heavy churn remains possible. It has not been measured.
