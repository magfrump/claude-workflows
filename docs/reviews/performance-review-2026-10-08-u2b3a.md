Commit: 5516c6e6

# Performance Review: feat/build-loop-u2b3a (U2b3a reader roots and homes)

**Scope:** branch diff `git diff main...HEAD` (main e50aab35..5516c6e6): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 5516c6e6; 0 Incorrect, 1 Stale, 3 Mostly accurate) and the shared brief `u2b3a-i1/shared.md`
**Replication:** k=1 (loop pass, iteration 1)

Probe scripts are in the session scratchpad (`u2b3a-perf-p1.sh`, `-p2.sh`, `-p3.sh`). Each starts `set -eu`, makes its own `mktemp -d /tmp/u2b3a-perf-XXXX`, checks `pwd -P` and removes the dir at the end. None runs `git init` or `commit`. Runs against `/workspace` only read (the walks and `git worktree list`). Host: 16 cores, load average 0.6 to 1.9 during the runs, mawk. Every timing is one run unless a count is given.

## Data Flow and Hot Paths

The diff changes three things.

- **`reader_set`** (`scripts/lib/dev-cycle-read.sh:852-879`) runs one `git worktree list` and one `realpath -m` fork per root (and per caller home). It also makes two `$(printf)` command substitutions.
- **Both walks** call it before their cache check, at `:1000` (`imported_names`) and `:1050` (`main_imports`), so it runs on every walk call, including cache hits.
- **The awk parser** joins each relative candidate against every root (`:713`). Every `put` then scans every root to find the longest one holding it (`:733`).

Temperatures:

- **The walks themselves:** cold. They run once per gate decision, or once per `--check-fix` run, after `import_reset` (`scripts/build-loop.sh:704`).
- **The cached `isimported`/`truthwalk` call:** warm. The cache exists so it can run once per path. Today that is `check_fix` (`scripts/dev-cycle.sh:181`), once per argument. U2c's `floor` will make it once per changed path of a merge, through `truthwalk main` (`:1234`), which calls `main_imports` twice (truthwalk itself, then `isimported`).

Measured sizes over `/workspace` today:

- **Roots:** 24 (`IMPORT_ROOTS` is 929 bytes). Each worktree path is already real, so the spelled and realpath forms dedup to one root per worktree, not the about 46 spellings the dispatch estimated.
- **Homes:** 1.
- **Names:** 128 per walk.

## Findings

#### F1. reader_set runs on every walk call, cache hit included: a cached truthwalk costs 16 times main's, and the cost grows with paths times roots

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1000`, `:1050`, `:852-879` (fork at `:864`, `:874`, `:877`); callers `:1184-1188`, `:1234`, `scripts/dev-cycle.sh:181`
**Move:** Count the hidden multiplications; Find the work that moved to the wrong place
**Classification:** Micro (a fixed fork count per call, linear in roots) / warm path (per changed path in floor's U2c loop, per argument in --check-fix)
**Confidence:** High
**Baseline:** a cached `truthwalk main` took 89 ms per call on HEAD against 5.5 ms on main's lib (20 calls each, `/workspace`, 24 roots, `u2b3a-perf-p1.sh`, 2026-10-08)
**Legibility-target:** for-author

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:1000-1002
  reader_set || { IMPORTED_DONE=""; IMPORTED=error; return 1; }
  # The roots never hold an empty line, so the blank line ends them.
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES" ]] && { [[ "$IMPORTED" != error ]]; return; }
```
(excerpt ends :1002; enclosing imported_names() continues to :1029, read)
```bash
# scripts/lib/dev-cycle-read.sh:856, 861-864
  nul_list rs_l git worktree list --porcelain -z || return 1
  for i in "${!rs_r[@]}"; do
    p="${rs_r[i]}"; [[ -n "$p" || $i -eq 0 ]] || continue
    [[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1
    r="$(realpath -m -- "$p")" && [[ -n "${r//\//}" ]] || return 1
```
(excerpt ends :864; enclosing reader_set() continues to :879, read)

Before this diff, a cache hit was one string compare. Now every hit forks `git worktree list`, then one `realpath` per root (24 here), then two `$(printf)` substitutions. That is about 27 forks, and one `reader_set` measured 19 ms (399 ms for 20).

`truthwalk` calls the walk twice (directly, then through `isimported`), so one floor question pays two `reader_set` runs.

| Cached call, 20 runs on /workspace | main's lib | HEAD |
|---|---|---|
| `isimported tree` | 48 ms | 586 ms |
| `isimported main` | 68 ms | 791 ms |
| `truthwalk tree` | 56 ms | 966 ms |
| `truthwalk main` | 110 ms | 1787 ms |

The cost is (changed paths) × 2 × (1 + roots) forks. A 30-path merge adds about 2.7 s at today's 24 roots, against first walks of 1.2 s (tree) and 1.4 s (main). The cost grows with every worktree registered. This is the same class as the forks the walks already removed for speed (`instruction_names`' "forking for every tracked file took seconds").

**Recommendation:**
1. Batch the realpaths: `realpath -m -z -- "${rs_r[@]}"` (and the same for the caller homes). One batched call over the 24 worktree paths measured 1.6 ms, against 13.7 ms for 24 forks.
2. Build the two lists with `printf -v` or an IFS join instead of `$(...)`.
3. Memoize `reader_set`'s result on its in-process inputs (ROOT_REAL, IMPORT_HOME_DONE, IMPORT_READER_ROOTS, IMPORT_READER_HOMES) and clear the memo in `import_reset`. Test 6's variable changes would still be caught. A registry change inside one decision is already the Q-103 residual, and contract item 4 already resets between decisions.

Items 1 and 2 alone should bring a cached call to about 4 ms (one git fork plus one realpath fork). Re-measure with p1 after the change.

#### F2. The work bound no longer prices time the same way: one spent 50,000,000 bound costs up to 3.3 times more wall time at 48 roots, and the comment's "about 0.1-4 s" is stale

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:713`, `:718`, `:733`; comment `:617-620`
**Move:** Check the asymptotic behavior; Count the hidden multiplications
**Classification:** Micro to Macro (the uncharged cost per put is linear in the root count) / cold path (one gate decision; adversarial content only, fail-closed)
**Confidence:** High (measured), Medium (on the split between the two mechanisms below)
**Baseline:** the worst shape measured (one distinct `@q<N>/x/x/...` token of 1500 characters per line) spent one 50,000,000 bound in 3.0 s at 1 root, 7.1 s at 24 roots and 9.9 s at 48 roots (`u2b3a-perf-p3.sh`, output bound lifted, HEAD's parser, 2026-10-08)
**Legibility-target:** for-author

Evidence:
```awk
# scripts/lib/dev-cycle-read.sh:713
  for (r = 1; r <= nr; r++) for (i = 0; i <= nd; i++) put(roots[r] "/" dirs[i] "/" c)
# :718
  work += length(c); if (work > wmax) exit 3
# :733
  k = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i]) && length(pre[i]) > k) k = length(pre[i])
```
(excerpts inside emit() :696-714 and put() :715-740, both read whole)

Two mechanisms raise the time per unit of charged work.

1. **Emit's share of the charge shrinks.** `emit` charges each candidate once, and that charge is cheap per unit. Every `put` is charged `length(c)`, and its split, stack and concatenation are the expensive part. With one root, emit's charge is about half the bound. With N roots it is about 1/(N+1), so nearly the whole bound goes to expensive puts. That alone is up to about 2 times.
2. **The projection loop is not charged.** It runs N `index` calls per put. Its share is about 0.12 s per root per bound: 9.9 s against 7.1 s between 48 and 24 roots.

Time to spend one bound, by root count:

| Shape | 1 root | 24 roots | 48 roots |
|---|---|---|---|
| slash | 3.0 s | 7.1 s | 9.9 s |
| a | 0.7 s | 0.7 s | 0.8 s |
| root-like | 1.0 s | 1.5 s | 2.0 s |

The bound is per walk, and the gate runs both walks. So the worst adversarial decision rises from about 6 s to about 14 s at today's root count, and keeps rising by about 0.25 s per added worktree.

Impact is limited: the security model assumes honest loops, the walk still fails closed, and the bound still bounds time. It no longer bounds it to the documented figure.

**Recommendation:**
1. Charge the projection: add `work += nr` (or the summed `length(pre[i])`) in `put` before the loop. The bound then keeps its time meaning as roots grow.
2. Update `:620`'s "about 0.1-4 s here" to the measured range at the current root count.

#### F3. The honest walks' work grew 31.5 times and keeps growing with each worktree; the comment's "about 8,100 each" is stale

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:713`; comment `:622`; budget `:628`
**Move:** Ask "what's the size of N?"
**Classification:** Macro (the work is linear in roots × candidates × path length) / cold path (once per walk)
**Confidence:** High
**Baseline:** `/workspace`'s walks spent 8,110 work units each on main's lib and 255,690 each on HEAD, with output 5,596 characters in both (`u2b3a-perf-p2.sh`, 24 roots, 2026-10-08)
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:622
# of @-less lines (but those read while a quote is open) are not charged (L2-C7, U2a3c i2 performance F3). /workspace's walks spend about 8,100 each (2026-10-07).
```

**Work bound.** Every relative candidate now costs about one join per root, each charged with the root's length. Honest work is about 10.7 K units per root here. Headroom under IMPORT_WORK_MAX fell from about 6,165 times to about 195 times.

`/workspace` will not hit the bound: that needs about 4,600 roots. But the budget now scales with a factor (registered worktrees) that has nothing to do with content. A denser repo with many worktrees could fail its honest walk, and a failed walk makes every path read as imported. The floor would then refuse every path. That fails closed, but it is a false-positive outage.

**Output bound.** IMPORT_OUT_MAX does not scale with roots for honest names. The longest-root projection maps every root's copy of a name to one repo path, and `seen` dedups it: output was 5,596 characters on both libs. A `..` name that re-enters different worktrees can print up to N distinct names per candidate. Each also costs N charged joins, so output per unit of work does not rise.

**Recommendation:**
1. Update `:622` to the HEAD figure and note that the figure scales with the root count.
2. If F2's charge fix lands, re-measure, since it adds about N per put.
3. Optional: name the root count in the IMPORT_WORK_MAX comment as a scaling input, so a future budget decision sees it.

## Endorsements

- The longest-root projection keeps the walks' output flat. Every-root projection measured 211,499 bytes against 5,607 over `/workspace`, and HEAD's output equals main's. [fact-check: claim 17 — Verified]
- Both walks yield the same name set as main's lib over `/workspace`, so the per-file `lower` and `inrepo_here` work downstream of the parser is unchanged. [fact-check: claim 22a — Verified]
- The removed per-walk `import_home || return 1` is not replaced by an extra call: `reader_set` calls `import_home` once, and `import_home` returns early on an unchanged HOME key. [read: scripts/lib/dev-cycle-read.sh:821-827, :852-856, :1000, :1050]
- The first walks are about as fast as before: tree 1,096 to 1,167 ms and main 1,313 to 1,428 ms on one run each (`u2b3a-perf-p1.sh`). The commit's "1.33 s against 1.31 s" pair is not reproducible exactly. [fact-check: claim 22c — Unverifiable]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | reader_set on every cached walk call: cached truthwalk 5.5 ms to 89 ms, times changed paths times roots | Medium | `scripts/lib/dev-cycle-read.sh:1000`, `:1050`, `:864` | High |
| F2 | Uncharged per-root projection: one spent work bound costs 3.0 s to 9.9 s worst case (1 to 48 roots); comment `:620` stale | Low | `scripts/lib/dev-cycle-read.sh:713`, `:733` | High |
| F3 | Honest work 8,110 to 255,690 (31.5 times), linear in roots; output unchanged; comment `:622` stale | Low | `scripts/lib/dev-cycle-read.sh:713`, `:622` | High |

## Overall Assessment

The parser change is sound for output: the longest-root projection keeps IMPORT_OUT_MAX's load flat and the name sets identical. The cold walks cost about the same.

The main cost is F1. Calling `reader_set` before the cache check makes every cached call fork about 27 processes, which defeats the cache's purpose for U2c's per-changed-path floor loop. The cost multiplies changed paths by registered worktrees. It is fixable in place: batch realpath, use `printf -v`, and memoize on in-process inputs cleared by `import_reset`. It should be fixed before U2c wires the floor.

F2 and F3 are calibration drift. Work per candidate is now linear in the root count, both in charged work (honest headroom fell 32 times) and in uncharged time (the projection loop). Charging the loop and refreshing the two comment figures keeps IMPORT_WORK_MAX meaningful as worktrees accumulate. No further profiling is needed beyond re-running p1 and p3 after a fix.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/performance-review-2026-10-08-u2b3a.md, structured per the performance-reviewer skill, with `Commit: 5516c6e6` as its first line.
- Answered: yes
- Out of scope: U2b3b's outside-repo starts and host settings line (rows 431, 477). Correctness of reader_set's refusals belongs to the fact-check (Claim 18) and security. U2c's floor loop is not wired yet, so its per-path cost is projected from the cached truthwalk measurement, not run end to end.
- Escalate: F1 should be fixed before U2c lands the per-path floor loop. The root count measured 24, not the about 46 the dispatch estimated, because worktree paths are already real and dedup.
- Decisions I made: I measured time to spend one full 50,000,000 bound with the output bound lifted, using synthetic roots of /workspace-like length, so that the root count is the only variable. I wrote probe scripts and logs only to the scratchpad, per the write-one-file rule.
