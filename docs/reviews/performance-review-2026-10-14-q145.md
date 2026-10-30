Commit: 0d573a7b

# Performance Review — fix/q145-ancestor-vanish (iteration 2)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-q145. Files: `scripts/lib/dev-cycle-read.sh` (config_seeds, new top_files), `test/scripts/build-loop-check.bats` (new Q-145 test), `test/scripts/dev-cycle.bats` (one name added to a declare-F list), `docs/thoughts/failure-patterns.md`
**Date:** 2026-10-14
**Based on:** docs/reviews/code-fact-check-report-2026-10-14-q145-i2.md (0 Incorrect). Measurement baselines: docs/reviews/performance-review-2026-10-14-q102.md (build-loop-check.bats 119.5 s solo) and the walk-cost comment at `scripts/lib/dev-cycle-read.sh:834-836` (2 to 3.5 s per walk, 2026-10-09)

**Measurement conditions:** all timings below were taken while the caller's stress run (bats `--jobs 3` over build-loop-check, build-loop-merge and dev-cycle in this worktree) was running. `uptime` load average was 19 to 24 on 16 CPUs throughout. Absolute numbers are inflated; the ratios are the useful part. Experiments ran on `git archive` copies under /home/node/.claude/jobs/00bcf178/tmp/q145/review/perf/, not in the worktree, and used GNU findutils 4.9.0 (`/usr/bin/find`, which the lib resolves through PATH).

## Data Flow and Hot Paths

`config_seeds` builds the seed list for the import walks: config trees (rules, commands, plugins, memory), then a top-level listing of each "top", meaning each repo ancestor below no reader root plus each existing config dir. The diff changes only that top-level listing:

- It moves the find into `top_files` and adds `-ignore_readdir_race`.
- It wraps the call in a three-try `||` chain. The first two tries drop stderr.
- It adds a `[[ -d ]]` recheck of every top.

Call frequency: `config_seeds` runs once per walk, because the walks cache (`imported_names`, `main_imports`; fact-check Claim 11, Verified). A walk runs once per gate or check invocation. Within that path the listing is cold setup work, not a per-item loop.

Data size: the tops are a handful of directories. On this host they are `/` (22 entries) and `~/.claude` (35 entries), plus `/tmp` (117 entries) when a root sits under it, as in the bats fixtures. `-maxdepth 1` means each try costs one readdir per top and one stat per entry.

Measured cost of one listing try under load: GNU find 4.9 over `/` plus `~/.claude` took 15 to 21 ms per run (mean of 30). Process start dominates that figure. Without `-ignore_readdir_race` (main's expression) it took 20.7 ms, within noise of the new expression. A synthetic 5,000-entry top took 65 ms per run.

## Findings

#### New Q-145 test adds about 7 s to the serially-run build-loop-check.bats

**Severity:** Low
**Location:** `test/scripts/build-loop-check.bats:724-774`
**Move:** Count the hidden multiplications (walks per test)
**Classification:** Micro (fixed per-walk cost, multiplied by 10 walks) / Cold for the product, but on the gate's critical path: build-loop-check.bats runs `--no-parallelize-within-files` and previously bounded the fast run (q102 perf F1)
**Confidence:** High for the measurement. Medium for the unloaded projection.
**Baseline:** build-loop-check.bats 119.5 s solo, measured in docs/reviews/performance-review-2026-10-14-q102.md

**Evidence:**
```
    for w in tree main; do
        # Files: -ignore_readdir_race skips each, so no listing fails and none is retried.
...
    for w in tree main; do
        mkdir -p "$a/.claude" && chmod 000 "$a/.claude"; rm -f "$a/shim/log"; PATH="$a/shim:$PATH" imps "$w" docs/a.md; chmod 755 "$a/.claude"; want walk failed
...
        for m in 1 drop; do
```

The test runs 10 full walks through `imps`: 2 walk kinds times (2 race cases + 1 permission case + 2 vanished-top cases). Measured with bats `--timing -f "Q-145"` on a copy of HEAD: **7,136 ms** (9.9 s wall including bats startup) at load 21 on 16 CPUs. The neighbouring C1 test took 8,876 ms in the same conditions, so the new test is in line with its peers and is not an outlier. That works out to about 0.7 s per walk, consistent with a single-root fixture walk. Against the 119.5 s baseline the test adds about 6% to the file. The baseline was measured unloaded, so the unloaded increment is probably smaller, roughly 3 to 5 s (speculative; not measured unloaded). The three failing walks per kind each run three listing tries. The retries cost only about 2 × 15 ms per failing walk, so the per-walk setup accounts for nearly all of the time, not the retry. The two walk kinds call `config_seeds` through separate cached entry points (`imported_names`, `main_imports`), so testing both is defensible coverage rather than duplication.

**Recommendation:** Accept as is. If the fast-run bound becomes binding again, the cheapest trim is to run the `T_RMTOP=1` case on one walk kind only. It exercises the same `-d` recheck as `drop` once find 4.9 reports the missing start point (fact-check Claim 6), which saves about 1.4 s. Record one gate timing after merge so the file's solo time can be re-baselined.

## Answers to the caller's questions

- **Common-case cost of the retry:** none. With no error, the first `top_files` succeeds and `||` short-circuits, so the walk runs one find, as on main. `-ignore_readdir_race` added no measurable time: 16.7 ms with it against 20.7 ms without, both under load and within noise.
- **Cost on persistent failure:** two extra finds, about 30 to 40 ms measured under load (15 to 21 ms each). A listing that fails because of an unreadable top still took about 15 ms per try. That is about 1 to 2% of the documented 2 to 3.5 s walk, on a path that then fails the walk anyway. The worst realistic case is a large churning top such as a 5,000-entry `/tmp` at about 65 ms per try, about 200 ms in total, still bounded at three tries. The retries are immediate, with no sleep. That is the cheap choice: a backoff would add latency on every transient failure in exchange for decorrelating from churn. The three-try bound keeps the worst case fixed.
- **Does the `-d` recheck loop matter?** No. It is one bash builtin `[[ -d ]]` (a single stat, no fork) per top, with K of about 2 to 4. That is microseconds against a 15 ms find.
- **Hot-path concern:** none. The changed code runs once per walk (fact-check Claim 11), on cold setup data of tens of entries, with a fixed retry bound. No new loops scale with repository or file count. No new process runs per seed.

## Endorsements

- The retry chain adds no process in the success case: `top_files fl "${tops[@]}" 2>/dev/null || ...` runs the next try only on a non-zero exit, and `top_files` is a single `nul_list ... find` call. [read: scripts/lib/dev-cycle-read.sh:1561, 1584, 1637]
- The retry is bounded at three tries, and only an error-free listing is used, so a persistent error costs a fixed two extra finds and does not loop. [fact-check: claim 5 — Verified; claim 6 — Verified]
- The `-d` recheck is a builtin test per top with no subprocess: `for d in "${tops[@]}"; do [[ -d "$d" ]] || return 1; done`. [read: scripts/lib/dev-cycle-read.sh:1562]
- `config_seeds`, and with it the retried listing, runs once per walk because the walks cache. [fact-check: claim 11 — Verified]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | New Q-145 test adds ~7.1 s (measured under load) to the serially-run build-loop-check.bats, ~6% of its 119.5 s baseline | Low | `test/scripts/build-loop-check.bats:724-774` | High |

## Overall Assessment

The performance posture is neutral. In the common case the change runs the same single find as main, and the new flag and recheck cost nothing measurable. On persistent failure it adds a bounded two finds (tens of ms) before the walk fails, as it would have anyway. The only cost worth noting is test time: the new test adds about 7 s, measured under load ~21/16 CPUs, to the file already known to bound the fast run. That is proportionate to its coverage and fixable in place if it ever matters. No profiling is needed before merge. One gate timing after merge would re-baseline build-loop-check.bats.

## Goal-Alignment Note

The PR aims to stop gate walks failing when another process deletes an entry in a shared ancestor such as `/tmp` mid-listing, without weakening fail-closed behaviour. From a performance standpoint the mechanism fits that goal. The race window is one ~15 ms listing, and an immediate bounded retry is the cheapest remedy: it costs nothing when there is no race and a fixed ~30 to 40 ms when an error persists. The production tops (`/`, config dirs) rarely churn. The flake surface is mainly the bats fixtures, whose roots sit under `/tmp`, and there the fix also removes a source of costly gate re-runs. Each re-run repeats a 119.5 s file, which outweighs the ~7 s the new test adds. Residual risk outside this review's mandate: under sustained heavy churn, three back-to-back tries are not independent in time, so a flake rate above zero remains possible. It is lower than before, but it was not measured here.
