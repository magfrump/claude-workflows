Commit: be94c871

# Performance Review — feat/build-loop-u2a3b, loop 2 iteration 1 (be94c871, superset parser)

**Scope:** `git diff main...HEAD -- scripts test docs/working skills`. I read the whole IMPORT_AWK program, import_targets, tree_starts, imported_names, main_imports, isimported and blocker/inrepo_here in `scripts/lib/dev-cycle-read.sh`, and check_fix in `scripts/dev-cycle.sh`.
**Date:** 2026-10-06
**Based on:** the Stage-1 summary `fcL2-summary.md` and `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-i1.md` (42 claims). The escalation to performance-reviewer covered two things: splice is quadratic and sits outside the bound, and the bound is per file with no walk-wide limit. Both are actioned below as F1 and F2.

Method. Every probe ran under `timeout` in `/tmp/u2a3b-perfL2-ZD8G`. That directory holds a `git archive be94c871` copy, main's scripts in `main/`, a `git clone` of /workspace at main f6fdda68 in `ws/`, the fixture repos in `p/`, and two mutants, `mutH` (F3) and `mutS` (F1). The tools were mawk 1.3.4 and bash 5.2. No background process outlived its probe, and no worktree file except this report was written. Logs are in `/tmp/u2a3b-perfL2-ZD8G/logs/`.

## Data Flow and Hot Paths

`import_targets` runs once per walked file. It runs sed (NUL and Unicode spaces become blanks), then one awk (IMPORT_AWK). For every `@`, `scan` builds the run to the first blank, capped at 4096 bytes, and calls `emit` on every prefix. `emit` adds `length(c)` to `work`, exits 3 above 50,000,000, splits and normalizes the candidate, and prints it once per file. A line holding `<!--` is scanned a second time after `splice`.

The two walks consume the output in bash:
- `imported_names` (tree walk) does one `lower` per file and appends to IMPORTED. It then runs a `while read` loop with `-f` before `inrepo_here`.
- `main_imports` (main walk) forks `lower` per candidate and, for a candidate that main lacks, probes the checkout with `blocker`.

`check_fix` runs the tree walk once per process (cached) and then calls `isimported tree` once per path. That call is a glob match of `*\n<path>\n*` over the whole IMPORTED string.

The path is cold: it is a CLI run once per dev cycle. But check-fix runs over large data (919 docs paths in /workspace) and blocks the cycle, so the hot-path gate's "runs over large data" exception applies to anything that multiplies per path.

Measured on the clean clone at main f6fdda68, 3 runs each (`logs/measure.txt`):

| | main | be94c871 |
|---|---|---|
| --check-fix, 919 paths | 2.09–2.15 s (first run 4.9 s, cold cache) | 2.31–2.58 s |
| tree walk | 345–367 ms, 3 entries | 439–507 ms, 64 entries |
| main walk | 446–517 ms, 3 entries | 727–824 ms, 64 entries |

The --check-fix outputs are identical. At /workspace's own content the cost is acceptable. The findings below are about inputs the bound was meant to make safe, and they are not safe.

## Findings

#### F1. `splice` is quadratic and sits outside the work bound, so a comment-dense line stalls the walk instead of failing it

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:541-549` (whole function read; called from `:549`)
**Move:** Asymptotic behavior / hidden multiplication
**Classification:** Macro (O(L × comments) copying per line) / Cold path, but it blocks check-fix and runs over whatever file is walked
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** 28,371 ms with rc=0 for import_targets on one 2.24 MB line of `<!---->` × 320,000 (`logs/probeS.txt`, 2026-10-06; Stage 1 measured 27.1 s)

Evidence: `r = substr(line, i + 4); j = index(r, "-->"); if (j == 0) break` / `o = o substr(line, 1, i - 1); line = substr(r, j + 3)`. Each comment re-copies the rest of the line, and `work` is only charged in `emit` (`:512 work += length(c); if (work > 50000000) exit 3`).

Other shapes behave the same way:
- `a<!---->` × 280,000 took 25.6 s.
- `<!-- x -->@a ` × 170,000 took 14.5 s. That shape is realistic: a long single line of commented-out content.

The header comment's promise, "(so a pathological file fails the walk rather than stalling it)", is false for this shape (Stage-1 Claim 18b).

**Recommendation:** This is the smallest fix and is tested. Charge the copy to the same bound inside the loop:
```awk
  while ((i = index(line, "<!--")) > 0) {
    work += length(line); if (work > 50000000) exit 3  # each pass copies the rest of the line
```
In mutant `mutS`, the three quadratic shapes drop to 158/165/251 ms with rc=3, so the walk fails closed. The linear shapes are unchanged (unclosed `<!-- ` × 450k: 239 ms, rc=0; one long comment: 213 ms, rc=0), and the 121/121 suite tests pass.

I rejected a gsub alternative, `gsub(/<!--([^-]|-[^-]|--+[^->])*--+>/, "", line)`. It matches `splice` on 600,000 random differential inputs and is linear on closed comments (32–39 ms). But on unclosed `<!-- ` × 450,000 it is quadratic and was still running when killed at 60 s (`logs/splicetime.txt`). Keep the loop and add the counter.

#### F2. The bound is per file and bounds awk only. Output just under it costs bash 10.8 s (tree), 178 s (main) and about 1.2 s per check-fix path, with no walk-wide limit

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:512` (the only bound); `:592-599` (tree consumer); `:667-677` (main consumer); `:691` (isimported); `scripts/dev-cycle.sh:183` (per path)
**Move:** Size of N / hidden multiplication
**Classification:** Macro. Candidate bytes grow with the square of the run length (m prefixes averaging m/2 bytes, plus the dir prefix on each). isimported is a linear scan of IMPORTED per path, so check-fix costs O(paths × IMPORTED bytes). Cold CLI over large data.
**Confidence:** High for the measurements; Medium for how likely the trigger is
**Legibility-target:** for-author
**Baseline:** 10,811 ms tree walk, 178,240 ms main walk, and 11.4 s / 34.8 s for check-fix over 1 / 20 paths. The fixture was a CLAUDE.md of five distinct `@`+4096-byte runs: 41.97 MB of output, rc=0, 323 ms in awk (`logs/probeA2.txt`, `logs/probeB.txt`, `logs/probeB2.txt`).

Evidence: `work += length(c); if (work > 50000000) exit 3` is reset for every awk run (one per file). A sixth run trips it (rc=3 at 50.0 MB, 311 ms), but five runs pass and hand bash 42 MB. Bash then pays for that output in four places:
- `out="$(import_targets …)"` captures it.
- `lower "$out"` runs tr over it.
- The `while IFS= read -r p` loop reads the pipe byte by byte. That alone took 8.4 s for 42 MB (`logs/probeM.txt`).
- `IMPORTED+=` keeps all of it, and then every `[[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]` scans it. In isolation that is 306 ms per lookup at 42 MB.

Inside check-fix the measured per-path cost is about 1.2 s. The rest probably comes from every per-path fork (`tr`, `lower`, check_path's forks) copying a larger process. That part is `[unverified — submitted as claim]`.

The trigger does not need a crafted file. One `@` followed by 5000 non-blank bytes (`Contact me@xxxx…`, or a minified JSON/JS line in any file a prefix candidate names, since the walk follows any file) gives 8.4 MB of IMPORTED. With that, check-fix took 1.73 s for 1 path and 6.43 s for 40 paths, against main's 28 ms and 367 ms (`logs/probeG.txt`). That is about 120 ms per path, so by arithmetic about 1.9 min for /workspace's 919 paths (speculative extrapolation). Walk-wide nothing caps the sum: N walked files each just under the bound cost N × the figures above.

**Recommendation:** The smallest fix that keeps fail-closed is one walk-wide budget instead of a per-file one. Pass the remaining budget in with `-v budget=` (awk exits 3 when `work > budget`), and have each walk subtract `${#out}` after each file, failing with IMPORTED/IMPORTED_MAIN=error when it is spent. Then size the budget against isimported's per-path cost, not awk's speed. /workspace uses 2,020 bytes of IMPORTED_MAIN, so even 4 MB is 2000× headroom (a single maximal 4096 run needs 8.4 MB, which then fails closed). That sizing is the author's call.

If one maximal run must stay admissible, also make the lookup O(1). I measured filling an associative set from 20,480 lines at 711 ms and 20 lookups at 6 ms, against 6.1 s for 20 glob lookups (`logs/probeM.txt`). Keep the IMPORTED string for its raw readers and add the set beside it. I did not test that variant end to end.

#### F3. main_imports still forks `lower` per candidate, which the superset multiplies (the tree walk already hoisted it)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:670`
**Move:** Hidden multiplication (fork per item)
**Classification:** Micro (one fork) × per-candidate loop, where the candidate count is now quadratic in run length → Medium
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** main walk 718–784 ms on the /workspace clone (3 runs) and 11,807 ms on fixture runF (5 runs of 1024 bytes, 5,120 candidates) (`logs/probeH.txt`, `logs/probeB.txt`)

Evidence: `i="$(lower "$p")" || { IMPORTED_MAIN=error; return 1; }; IMPORTED_MAIN+="$i"$'\n'`. That line sits inside `while IFS= read -r p`, while imported_names has `# One lower per file, not per candidate: the superset yields many.` (`:594`).

On the clone the fork costs about 110 ms per walk. On runF it costs about 11 s, and on runC (20,480 candidates) about 165 s of the 178 s.

**Recommendation:** This is tested in mutant `mutH`. Before the read loop, add `[[ -n "$out" ]] || continue` and `i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }; IMPORTED_MAIN+="$i"$'\n'`, and drop the per-candidate lower. Results:
- On the clone the main walk takes 609–679 ms (from 718–784), with an identical IMPORTED_MAIN (md5 c7e4ae76).
- runF drops to 657 ms and runC to 13.2 s.
- The 121/121 suite tests pass.

The symlink case sets `out` to one path and gitlinks `continue` earlier, so per-file lowering covers every branch. The only change is ordering inside IMPORTED_MAIN, and IMPORTED_MAIN is reset to `error` on any later failure anyway.

#### F4. Directory-prefix candidates in the main walk each fork `blocker` (a subshell plus one realpath per path component)

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:676` (U2a3 context code; this branch multiplies its inputs); `:112-124` (blocker), `:104` (plaindir)
**Move:** Hidden multiplication
**Classification:** Micro (forks) × per-candidate, bounded by the number of distinct directories mentioned × depth / Cold
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** main walk 1,299 ms at main vs 6,200 ms at be94c871 on a fixture CLAUDE.md naming 200 distinct `@aN/b/c/d/f.md` (`logs/probeD.txt`). The tree walk is unchanged (1,883 → 1,969 ms) because of `-f` first. /workspace's main walk has 0 directory candidates today.

Evidence: `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }`. Every prefix of a path mention that names a directory (`aN`, `aN/b`, `aN/b/c`, `aN/b/c/d`) is now a candidate main lacks as a file. Each one re-walks its ancestors through plaindir's `realpath -e` fork. In the fixture that was 800 subshells and about 2,000 realpaths. Ordinary nested imports (`@docs/working/plan.md`) are exactly this shape, so the cost scales with import usage.

**Recommendation:** Memoize plain directories in a local associative array, so each directory is realpath'd once and ancestors are not re-walked. A cheaper alternative is to skip the probe for a candidate that main's `dir` map (already built at `:629`) holds as a directory, if the U2a3c design accepts that main's tree vouches for it. That is a design question for the author. Neither change was tested.

#### F5. `scan` visits every byte with `substr` even on lines with no `@`, and the bound does not count it

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:528-539`
**Move:** Constant factor on the per-byte loop
**Classification:** Micro / Cold
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** 1,894 ms for import_targets on a 27.3 MB text file with no `@`, against 12 ms for mawk to read it (`logs/probeL.txt`)

Evidence: `for (i = 1; i <= L; i++) { if (substr(line, i, 1) != "@") continue`. Cost is linear (about 70 ns per byte) and only matters for a large walked file, such as a log or data file named by a prefix candidate.

**Recommendation:** Optionally add `if (!index(line, "@")) return` at the top of `scan`, or jump between `@`s with `index`. The time is linear and not urgent.

## Endorsements

- check_fix's new `elif ! imported_names` cannot repeat the walk per path. imported_names returns early when `IMPORTED_DONE == ROOT_REAL`, and check_fix runs in the main shell inside the `for a` loop. 919 paths took 2.31–2.58 s against main's 2.09–2.15 s. [read: scripts/lib/dev-cycle-read.sh:574-578; scripts/dev-cycle.sh:170-186,195-205]
- The tree walk tests `-f` before `inrepo_here`, so non-file candidates never fork `blocker`, and it lowers once per file. [fact-check: "-f before inrepo_here changes nothing queued" — Verified]
- The work counter charges `scan`'s quadratic name building and `emit`'s per-prefix split. Both are proportional to `length(c)`, which is exactly what `work` sums, so candidate-shaped pathology trips the bound in ≤0.32 s (runD, runE). [read: scripts/lib/dev-cycle-read.sh:511-539]
- Cross-file dedup is not needed for cost at /workspace scale. IMPORTED holds 64 entries (2,020 bytes in the main walk). [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | splice quadratic, outside the bound: stalls instead of failing | Medium | `scripts/lib/dev-cycle-read.sh:541-549` | High |
| F2 | Per-file awk-only bound: 42 MB under it costs 10.8 s / 178 s / ~1.2 s per check-fix path; no walk-wide limit | Medium | `scripts/lib/dev-cycle-read.sh:512,592-599,691` | High (measured) / Medium (trigger) |
| F3 | main_imports forks lower per candidate | Medium | `scripts/lib/dev-cycle-read.sh:670` | High |
| F4 | Directory-prefix candidates fork blocker in the main walk | Low | `scripts/lib/dev-cycle-read.sh:676` | High |
| F5 | scan visits every byte even with no `@` | Informational | `scripts/lib/dev-cycle-read.sh:528-539` | High |

## Overall Assessment

At /workspace's real content the over-approximation's cost is modest and measured: tree walk +100–150 ms, main walk +280 ms, check-fix +0.2–0.4 s over 919 paths, and identical answers. The design's safety claim is the weak point. The 50M work bound is meant to make pathological input fail rather than stall, but it covers only candidate-shaped work inside one awk run.

Two kinds of input get past it:
- **Comment-dense lines (F1)** stall for tens of seconds. This has a one-line fix, tested.
- **Output just under the bound (F2)** costs bash orders of magnitude more than awk: seconds to minutes per walk and over 100 ms per check-fix path. A single `@` followed by 5000 non-blank bytes in any walked file is enough.

F1 and F3 are fixable in place with tested one-to-three-line changes. F2 needs a walk-wide budget sized to the consumers, and possibly a set lookup. F4 is a Low cost from multiplied candidates in U2a3's context code. No profiling is needed beyond the probes above. The F2 per-path figure for /workspace (about 1.9 min) is an extrapolation from 40 paths.

## Goal-Alignment Note

Success criterion: "A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: be94c871` line at the top."

The report is saved at `docs/reviews/performance-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md` with `Commit: be94c871` as its first line, structured per skills/performance-reviewer. It answers the review question's time-cost part: acceptable at /workspace scale, but the bound does not fail pathological files closed (F1, F2). It also actions both Stage-1 escalations addressed to this role (F1 and F2) and the brief's measurement list: walks and check-fix main vs be94c871, IMPORT_AWK per-@ and per-line cost, the bound's coverage, per-file vs walk-wide bounds, and main_imports' lower fork.
