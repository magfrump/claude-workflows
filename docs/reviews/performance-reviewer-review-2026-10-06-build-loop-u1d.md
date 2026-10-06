Commit: 83cdb005

# Performance Review — feat/build-loop-u1d (U1d)

**Scope:** branch diff `git diff main...HEAD` (one commit, 83cdb005): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats
**Date:** 2026-10-06
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1d.md (merged, k=3)

All numbers below come from measurements on this host (WSL2, bash 5.2, git 2.39.5), run from `.../scratchpad/review-u1d/perf/`. Probes there: `bench.sh` and `bench.log` (per-function timings, main's lib against HEAD's lib, interleaved, 3 rounds); `bl-{main,head}/` (build-loop.sh with a pathform call counter); `blt-{main,head}/` (wall-time copies); `bats-{main,head}-{1,2,3}.tap` (suite timings from `git archive` exports of main and HEAD). No worktree file was changed other than this report.

## Data Flow and Hot Paths

The only code change with any runtime cost is at `scripts/lib/dev-cycle-read.sh:263`. Before reading the tree, `main_entry` now runs `pathform "$1"`. `pathform` (`:141-150`) is pure bash: one regex test, then a loop over the path's `/`-separated parts. It forks nothing. `main_entry` itself forks `git ls-tree` once per call (`:265`), and every caller runs it inside `$(...)`, so each call also costs a subshell.

Callers and how often they run, per `build-loop.sh --status` invocation (CLI, run by hand or by the loop once per poll; a cold path):
- `shared_branches` (build-loop.sh:303-320) runs once. It calls `brief_fields` once for each open brief on main, and `brief_fields` already ran `pathform` before calling `main_entry` (lib `:296`). Each open brief now gets 2 pathform calls where it used to get 1.
- `status_line` → `check_brief` (pathform at `:327`, then main_entry at `:334`, then brief_fields at `:342`) and then `brief_fields` again (build-loop.sh:328), for each queried brief. That was 3 pathform calls per queried brief and is now 6.
- `main_file` (build-loop.sh:121-124) reads `docs/dev-cycle.md` through main_entry. That adds 2 calls per run (0 before).

N here is the number of briefs under `docs/working/briefs/` on main (open ones) plus the number of paths given to `--status`. Both are small and set by hand. Per the goal preamble, U2's `--check` will call `main_entry` once per changed path, so N there is the size of a diff.

## Findings

#### F1: pathform now runs twice per brief lookup (brief_fields, check_brief), 6 calls per queried brief where there were 3

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:263` (new), with the existing caller checks at `:296` and `:327`
**Move:** Count the hidden multiplications
**Classification:** Micro (a constant per-call cost, about 33 µs) / Cold path (a CLI invocation over briefs written by hand)
**Confidence:** High
**Baseline:** `build-loop.sh --status` over 6 briefs (6 open on main, all 6 queried) takes a median of 174.3 ms on main's lib and 177.1 ms on HEAD's lib, n=30 interleaved (`scratchpad/review-u1d/perf`, 2026-10-06)
**Legibility-target:** for-orchestrator-synthesis (no fix needed; it prices the redundancy the focus asked about)

Evidence (verbatim):
```
lib/dev-cycle-read.sh:263:  if ! main_by_name || ! pathform "$1"; then echo error; return; fi
lib/dev-cycle-read.sh:296:  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
lib/dev-cycle-read.sh:327:  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"; return; fi
```
Measured (bench.log, LC_ALL=C, path `docs/working/briefs/2026-10-01-a.md`, 3 rounds):
```
pathform_us     main 33.0 / 32.5 / 33.2    head 33.8 / 33.0 / 33.2   (µs per call, 5000 calls)
main_entry_ms   main 1.80 / 2.08 / 1.80    head 1.99 / 1.98 / 1.96   (ms per call in $(), 300 calls)
brief_fields_ms main 3.48 / 3.54 / 3.46    head 3.75 / 3.68 / 3.55
```
Counted pathform calls, using a counter wrapped around pathform:
```
main pathform calls (6 open, 6 queried): 24
head pathform calls (6 open, 6 queried): 50
main pathform calls (6 open briefs, 1 queried): 9
head pathform calls (6 open briefs, 1 queried): 20
```
The formula is open + 3·queried on main and 2·open + 6·queried + 2 on HEAD (the +2 is main_file reading docs/dev-cycle.md). That gives 26 extra calls × 33 µs ≈ 0.86 ms predicted. The measured wall-time difference is 2.8 ms (1.6%) median, which is inside the run-to-run spread (main's min 167.5 ms, HEAD's min 170.7 ms). Each extra call costs about 1.7% of one `main_entry` call, because the `git ls-tree` fork and the subshell dominate. The duplicate is linear in N, with no change in complexity class. It is a cold path, and a brief count large enough for it to be felt (about 30 extra calls per millisecond) is far beyond any realistic one. The redundant check at `:296` could be dropped, since main_entry now refuses the same paths and brief_fields maps any non-blob answer to `BRIEF_ODD=error` either way. The check at `:327` must stay, because it produces the distinct "not an allowed path form" reason.

**Recommendation:** None required. If someone touches brief_fields for another reason, the `pathform "$1" ||` at `:296` can go without any change in behaviour. That claim needs a fact-check before anyone relies on it (see Endorsements). It is not worth a change of its own.

#### F2: U2's per-changed-path main_entry cost is the git fork, not pathform (forward-looking)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:260-276` (main_entry), for U2's planned calls
**Move:** Ask "what's the size of N?"
**Classification:** Micro / Hot for U2 (a per-item loop over a diff's changed paths), cold today
**Confidence:** Medium (U2's call pattern comes from the goal preamble and the override-log row; it is not in this diff)
**Baseline:** main_entry costs 1.96 ms per call at HEAD (median of 3 rounds of 300 calls, bench.log, 2026-10-06)
**Legibility-target:** for-author (U2's plan)

Evidence (verbatim):
```
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }
```
The guard U1d adds costs about 33 µs, roughly 1.7% of the call. What U2 inherits is one `git ls-tree` process plus a subshell per path, about 2 ms each, so a 500-path diff takes about 1 s in main_entry alone. That is acceptable for a check run by hand. It becomes a real cost only if U2 runs on every poll over large diffs. A refused path costs nothing extra: the `||` short-circuit returns before the fork.

**Recommendation:** No action in U1d. If U2's `--check` might see diffs of thousands of paths, its plan should note that one `git ls-tree -t --full-tree "$MAIN_SHA" -- <all paths>` per check would replace N forks. Duplicate detection is per path, so that batching needs its own review.

#### F3: The new tests add about 0.72 s to the two suites (about 3%)

**Severity:** Informational
**Location:** `test/scripts/build-loop-read.bats:402-461` (3 new tests), `test/scripts/dev-cycle.bats:813-823` (loop extended), `:1328-1335` (1 new test)
**Move:** Count the hidden multiplications (each fixture step forks git commits and a script run)
**Classification:** Micro / Cold (test time, not production)
**Confidence:** High
**Baseline:** HEAD's two suites sum to 24,359 / 24,602 / 24,957 ms of per-test time over 3 runs (`bats --timing`, `bats-head-{1,2,3}.tap`, 2026-10-06)
**Legibility-target:** for-orchestrator-synthesis

Evidence (bats --timing, HEAD run 1; runs 2 and 3 sum to 725 and 722 ms for the same four):
```
   259 ms --settings: deferred cases: reasons, review with a malformed never line, the next-line rule, an absent file, a caller's config (U1d)
   25 ms build-loop.sh --help prints the whole header, through its last line (U1d)
   384 ms --status: deferred cases: NUL, F31's open-only filter, no open brief, CRLF, BRIEF kept, an unanchored closed (U1d)
   54 ms main_entry refuses a path pathform refuses, before any read (U1d)
```
All 92 tests pass at HEAD in all three runs (88 at main). The four new tests cost 722-725 ms, about 2.9-3.0% of HEAD's median per-test sum. Adding `--check-answer` to test 66's loop adds one more script run (129 ms for the whole test at HEAD). Main's whole-suite sums were too noisy to subtract (23,377-33,427 ms over 3 runs), so the direct per-test timings above are the measured delta, not a difference of suite totals.

**Recommendation:** None. The two longest new tests are compound tests that share one fixture repo, so they are already cheaper than splitting each case into its own test would be.

## Endorsements

- The guard short-circuits before the `git ls-tree` fork: `main_by_name || pathform` is evaluated first and returns `error` without starting a process, so a refused path costs about 33 µs instead of about 2 ms. `[read: scripts/lib/dev-cycle-read.sh:141-150, :260-265]`
- `pathform` is pure bash (regex test plus a component loop, no command substitution or external command), so its cost is linear in the number of path components. `[read: scripts/lib/dev-cycle-read.sh:140-150]`
- No caller's output changes with the added guard (brief_fields and check_brief already ran pathform first; check_answer and main_file pass fixed names pathform accepts). `[fact-check: claim 12 — Verified]`
- Dropping the `pathform "$1" ||` at lib `:296` would not change brief_fields' result for any input, because main_entry now answers `error` for every path pathform refuses. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | pathform runs twice per brief lookup: 24 → 50 calls for 6 briefs, about +0.9 ms predicted, +2.8 ms (1.6%) median measured | Informational | `scripts/lib/dev-cycle-read.sh:263`, `:296`, `:327` | High |
| 2 | U2's per-path cost is the ls-tree fork (about 2 ms per path), not the guard (33 µs) | Informational | `scripts/lib/dev-cycle-read.sh:260-276` | Medium |
| 3 | New tests add about 0.72 s (about 3%) to the two suites | Informational | `test/scripts/build-loop-read.bats:402-461`, `test/scripts/dev-cycle.bats:1328-1335` | High |

## Overall Assessment

Performance does not change in any way that matters. The added guard is a fork-free bash check costing about 33 µs. It now runs twice for every brief that brief_fields or check_brief reads, which doubles pathform calls (24 → 50 for a 6-brief `--status`). The measured wall time stays within noise (+1.6% median, 174.3 → 177.1 ms) because the per-call `git ls-tree` fork, about 2 ms, dominates. The redundancy is fixable in place and not worth a change of its own. The new tests cost about 0.72 s, about 3% of the suites. For U2, the cost to plan around is one git process per changed path in main_entry. U1d's guard does not change that. No further profiling is needed for U1d.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/performance-reviewer-review-2026-10-06-build-loop-u1d.md (first line `Commit: 83cdb005`), structured per the performance-reviewer skill.
- Answered: yes. The focus questions were measured, not estimated: pathform's per-call cost, main_entry's per-call cost, the twofold pathform count through brief_fields and check_brief, `--status` wall time, and the new tests' runtime.
- Out of scope: the cost of U2's `--check` itself (F2 is forward-looking only); fact-check Claims 17 and 18 (test-wording correctness, not performance).
- Escalate: none. F1's endorsement that "dropping `:296`'s pathform is behaviour-neutral" is submitted as a claim for fact-check if anyone acts on it.
