Commit: c9197fd2

# Performance Review: feat/build-loop-u2b3a, iteration 2 (fix range 5516c6e6..HEAD)

**Scope:** partial, `git diff 5516c6e6..HEAD -- scripts test` (fix commits 4dba56dc, c9197fd2): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b3a-i2.md` (Commit c9197fd2; 0 Incorrect), the iteration-1 rubric `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b3a.md`, my iteration-1 report `docs/reviews/performance-review-2026-10-08-u2b3a.md`, and the shared brief `u2b3a-i2/shared.md`
**Replication:** k=1 (loop pass, iteration 2)

Probe scripts and logs are in the session scratchpad under `u2b3a2-perf/` (`p1-begin.sh`, `p2-walk.sh`, `p3-big.sh`, `p4-bound.sh`, `p5-cached.sh`; logs `p1.log`, `p2.log`, `p4.log`, `p5.log`, and the p3 runs quoted below). Each script starts `set -eu`, makes its own `mktemp -d /tmp/u2b3a2-perf-XXXX`, checks `pwd -P` and removes the dir at the end. None runs `git init`, `commit` or `worktree add`. The runs against `/workspace` only read it (the walks and `git worktree list`). Extra roots are passed as synthetic caller `IMPORT_READER_ROOTS` (nonexistent host-like paths, `/home/magfrump/host-checkout-N/claude-workflows`, about 47 characters; or dot-nested `/workspace/.claude/fake-unit-N`), so the root count is the only variable. Host: 16 cores, load average about 0.4, mawk. Timings are one run unless a count is given. One early probe run aborted before cleanup and left an empty `/tmp/u2b3a2-perf-82Sx`. I removed it, and no process or dir with my prefix remains.

## Data Flow and Hot Paths

The fix range changes the cost model in four places.

- **`import_readers`** (`scripts/lib/dev-cycle-read.sh:881-917`) now memoizes on `READERS_KEY` (ROOT_REAL, HOME's key, the two caller lists) until `import_reset`. It runs one `git worktree list` and one batched `realpath -mz` per decision instead of per call.
- **The awk BEGIN block** (`:805-817`) builds the `dotnest` table: an nr × nr loop of `length`/`index`/`substr` calls. It runs once per parser process, and the walks start one parser per file they read: **80 per walk over `/workspace`** (p2).
- **`put`** (`:722-751`) is called once per root per directory for every relative candidate (`:720`). Each call scans all nr roots for holders (`:746`), then does an nho × nho `dotnest` lookup over the holders (`:747-750`). G5 added `work += nr` per projected spelling (`:745`).
- **`show`** (`:752-757`) is the old tail of `put`, unchanged.

Temperatures are as in iteration 1:

- **The walks:** cold. They run once per gate decision or `--check-fix` run, after `import_reset`.
- **Cached `isimported`/`truthwalk`:** warm. They run per argument in `--check-fix` today, and per changed path in U2c's floor loop.

Sizes today:

- **Roots:** 24 (`git worktree list` gives 24 lines, ROOT_REAL among them, and the spelled and real forms dedup).
- **Names:** 128 per walk.
- **Honest charged work:** 330,570 per walk.

Root count is the scaling input this iteration asks about. The brief notes the user's host checkout can register more, and prunable entries stay listed until `git worktree prune`.

### Iteration-1 findings against the fix range

| i1 | Status | Evidence |
|---|---|---|
| F1 (reader_set per cached call; rubric A3) | **Resolved** | Cached `isimported` took 3.1 ms (tree) and 3.5 ms (main) per call at 24 roots, and 2.6 ms and 3.8 ms at 200. Cached `truthwalk` took 4.1 to 5.7 ms. 20 calls each (p5). `git worktree list` ran once across 41 calls per walk, at both root counts (p5). The cost no longer depends on roots or on calls. |
| F2 (uncharged projection loop; rubric G5) | **Resolved as charged.** The comment figure is stale (fact-check Claim 6). | `:745` charges `nr` per projected spelling. One spent bound still bounds time at any root count I ran: worst shape (`slashuniq`) 9.0 s at 24 roots, 13.8 s at 100, 13.2 s at 300; the other shapes 1.2 to 6.4 s (p4). Growth beyond 24 roots is sublinear. |
| F3 (honest work comment; rubric G4) | **Resolved**, apart from "8,600 with one" (fact-check Claim 7b: 8,240) | 330,570 per walk at 24 roots (p2), matching the comment's "about 330,600". |

## Findings

#### F1. The G5 charge makes honest charged work quadratic in the root count: honest walks now fail closed at about 570 roots, against about 4,200 at 5516c6e6

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:720`, `:745-746`; budget `:635`; comment `:622-629`
**Move:** Check the asymptotic behavior; Count the hidden multiplications; Ask "what's the size of N?"
**Classification:** Macro (charged work and time per relative candidate are O(nr²)) / cold path (once per walk per gate decision; fails closed)
**Confidence:** High (measured)
**Baseline:** honest `/workspace` walks charged 330,570 work units at 24 roots, 7,565,970 at 200, 38,486,970 at 500 and 47,479,170 at 560, then failed at 580 and 600 roots. At 5516c6e6 the same walks charged 5,986,970 at 500 roots and 7,193,970 at 600 (`u2b3a2-perf/p2-walk.sh`, `p3-big.sh`, 2026-10-08)
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```awk
# scripts/lib/dev-cycle-read.sh:720
  for (r = 1; r <= nr; r++) for (i = 0; i <= nd; i++) put(roots[r] "/" dirs[i] "/" c)
# :745-746
  work += nr; if (work > wmax) exit 3
  nho = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i])) h[++nho] = i
```
(excerpts inside `emit()` :703-721 and `put()` :722-751, both read whole; `put`'s output goes to `show` at :752-757, read)
```bash
# scripts/lib/dev-cycle-read.sh:635
IMPORT_WORK_MAX=50000000
```

Every relative candidate makes nr spellings, one per root, and `tried` cannot dedup them because each starts with a different root. Before the fix, each spelling was charged `length(c)`, which grows linearly in nr. G5 adds `nr` to each spelling's charge, so the candidate now costs nr × nr units. The scan at `:746` makes the wall time quadratic as well; it was already there at 5516c6e6, only uncharged. The charge therefore tracks time correctly. The quadratic algorithm is the actual problem.

Honest charged work per walk over `/workspace`, both walks equal:

| Total roots | HEAD work | HEAD tree / main time | 5516c6e6 work |
|---|---|---|---|
| 24 | 330,570 | 1.13 s / 1.48 s | 255,690 (i1) |
| 48 | 840,600 | 1.27 s / 1.42 s | |
| 100 | 2,461,960 | 1.37 s / 1.58 s | |
| 200 | 7,565,970 | 1.79 s / 2.74 s | |
| 400 | 25,579,970 | 3.59 s / 3.81 s | |
| 500 | 38,486,970 | 5.15 s / 5.31 s | 5,986,970 (4.07 s / 4.31 s) |
| 560 | 47,479,170 | 6.19 s / 6.16 s | |
| 580, 600 | walk failed (bound spent) | | 7,193,970 at 600 |

Dot-nested extra roots behave the same: 7,177,010 at 200 (p2).

The 5516c6e6 figures are linear in nr, so that branch would reach the bound at about 4,200 roots. HEAD reaches it at about 570, which is 23 times today's count. Reaching the bound fails closed: every path reads as imported, so floor refuses every branch. That is an outage rather than a hole, and it would hit an honest repo whose registry accumulates unpruned worktrees.

The work comment at `:626-629` gives figures for 24 roots only. It does not say that honest work grows with the square of the root count, so a future budget decision would not see this.

Nothing is at risk at today's 24 roots: headroom is 151 times in work, and the walk times are unchanged from iteration 1. That is why this finding is Low.

**Recommendation:**
1. **Minimum:** state the scaling in the IMPORT_WORK_MAX comment. Honest work is about quadratic in the reader-root count, and honest walks spend the bound at about 570 roots, so pruning the registry (or raising the bound) is the remedy.
2. **Optional fix in place:** do the per-root join only for names that need it. When `dirs[i]/c` resolves lexically without climbing above its directory's root, every root yields the same relative tail. The only per-root question left is which roots nested in or around root r also hold the spelling. Precompute each root's ancestors and descendants in BEGIN, and scan only those instead of all nr. Names with a `..` that leaves the root keep the full join. This brings an honest candidate back to about nr work. Confidence: Medium, because it changes which spellings `tried` sees and needs the dotnest tests re-run.

#### F2. The dotnest table is rebuilt by every parser process: nr² uncharged BEGIN work, 80 times per walk, about 1.2 s per walk at 500 roots

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:812-813` (BEGIN); per-file parser launch at `:1057`, `:1132`, `:1134`
**Move:** Find the work that moved to the wrong place; Count the hidden multiplications
**Classification:** Micro at today's size, Macro in nr (O(nr²) per process, times the files read) / cold path (per walk)
**Confidence:** High (measured)
**Baseline:** one parser process on empty input took 1.69 ms at 24 roots, 2.18 ms at 100, 7.06 ms at 300, 16.1 ms at 500 and 56.9 ms at 1,000, against 1.59 ms at 1 root and 0.8 ms for a trivial awk (50 runs each, 10 at 300 and above; `u2b3a2-perf/p1-begin.sh`, 2026-10-08)
**Legibility-target:** for-author

Evidence:
```awk
# scripts/lib/dev-cycle-read.sh:812-813
  for (i = 1; i <= nr; i++) for (j = 1; j <= nr; j++)
    if (length(pre[j]) > length(pre[i]) && index(pre[j], pre[i]) == 1 && index("/" substr(pre[j], length(pre[i]) + 1), "/.")) dotnest[i, j] = 1
```
(excerpt inside BEGIN :805-817, read whole)

The table depends only on the root list. That list is fixed for a decision, because `import_readers` memoizes it. Even so, the table is rebuilt in each of the 80 parser processes a `/workspace` walk starts. The work is uncharged, but it depends only on the root count and not on file content, so it cannot be inflated adversarially.

Cost per walk at 80 parser calls:

| Roots | Added BEGIN time per walk | Share of walk time |
|---|---|---|
| 24 | about 8 ms | noise |
| 100 | about 50 ms | small |
| 500 | about 1.2 s | about 23% of the 5.1 s walk |

F1's bound fails honest walks at about 570 roots, so F2 cannot grow past about 1.4 s per walk before F1 stops the walk. The table itself is small: an entry exists only for a dot-nested pair, 23 at `/workspace`.

**Recommendation:** none needed at today's size. If F1's fix raises the usable root count, compute the dotnest pairs once in `import_readers`, which is already memoized per decision. For example, emit them as an `IT_NEST` list of `i j` pairs for BEGIN to load, so each parser process does O(pairs) work instead of O(nr²).

## Endorsements

- The memo removes all per-call forks of the reader set. The registry is read once per decision, and cached calls cost about 3 ms independent of the root count (p5: 2.6 to 3.8 ms at 24 and 200 roots, one `git worktree list` across 41 calls). [fact-check: claim 15a — Verified]
- One batched `realpath -mz` replaced the per-root forks: 1.3 ms against 13.9 ms over 24 roots. [fact-check: claim 17 — Verified]
- The dotnest projection keeps the honest output at main's 128 names over `/workspace`, so IMPORT_OUT_MAX's load and the downstream per-name `lower`/`inrepo_here` work are unchanged. A non-dot nested root adds names rather than multiplying them. [fact-check: claim 26b — Verified]
- `put`'s nho × nho holder loop (`:747-750`) is uncharged, but nho is the number of roots holding one spelling: 1 or 2 in an honest layout, and at most the depth of a chain of nested registered worktrees. That would take a registry rewrite, the Q-103 residual. [read: scripts/lib/dev-cycle-read.sh:722-751, :805-817]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | G5's `work += nr` per projected spelling makes honest charged work O(nr²) per relative candidate: 330,570 at 24 roots, 38.5 M at 500; honest walks fail closed at about 570 roots (5516c6e6: about 4,200). The comment does not name the scaling | Low | `scripts/lib/dev-cycle-read.sh:720`, `:745-746`, `:635` | High |
| F2 | dotnest table rebuilt in every one of a walk's 80 parser processes: O(nr²) uncharged BEGIN, about 8 ms per walk at 24 roots, about 1.2 s at 500 | Informational | `scripts/lib/dev-cycle-read.sh:812-813` | High |

## Overall Assessment

The fixes did what iteration 1 asked:

- **i1 F1, the Medium:** fully resolved. A cached call is about 3 ms and no longer depends on roots or on how often it runs, so U2c's per-path floor loop is no longer exposed.
- **i1 F2:** the spent bound again bounds time, at 9 to 14 s worst shape between 24 and 300 roots.
- **i1 F3:** the honest-work figure is current.

The new cost is in how both mechanisms scale with the root count, and none of it matters at today's 24 roots.

- **F1 (Low):** the charge that fixed i1 F2 is correct, but it makes the existing quadratic join visible. Honest walks spend IMPORT_WORK_MAX at about 570 roots, so a big enough unpruned registry would turn the floor into a refuse-everything outage. The cheap fix is one comment line naming the scaling and the pruning remedy. The structural fix, scanning only related roots, is optional and can wait for a reason to expect hundreds of roots.
- **F2 (Informational):** capped by F1's failure point.

No further profiling is needed. If the optional F1 fix lands, re-run `p2-walk.sh` and `p3-big.sh`.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/performance-review-2026-10-08-u2b3a-i2.md, structured per the performance-reviewer skill, with `Commit: c9197fd2` as its first line.
- Answered: yes
- Out of scope: the stale "0.1-4 s ... about 7 s with 24" and "8,600 with one" comment figures and commit 4dba56dc's figures. Fact-check Claims 6, 7b, 26c and 26d already carry them; I added only the bound times at 100 and 300 roots. Also out of scope: U2b3b's host roots and settings line (override rows), and correctness of the dotnest rule (security and architecture own it).
- Escalate: nothing blocking. F1's comment line is worth folding into the same fix commit that rewords the fact-check's Claim 6 and 7b figures.
- Decisions I made: I scaled the root count with synthetic caller roots, mostly non-nesting host-like paths, plus one dot-nested series, over the real `/workspace` walks, so content stayed fixed. I timed the 5516c6e6 lib (a `git show` copy in my scratch dir) only at 500 and 600 roots, for the failure-point contrast.
