Commit: 088bc97

# Code Review Rubric — feat/run-tests-jobs (Q-090)

**Scope:** `main...feat/run-tests-jobs` (full branch, loop pass 1, `--loop-pass`). Delivery mode: self-read (each agent ran `git diff main...HEAD`; the diff is 9 KB).
**Status:** Pass 1 found no Must Fix. Every Must Address item is fixed in 084868f/f733a51 or acknowledged in the override log. A final confirming pass is still due.

## Iterations

| Pass | Commit | Scope | Stages | Outcome |
|---|---|---|---|---|
| 1 | 088bc97 | full | fact-check k=1 (opus), security, performance, api-consistency (opus) | 1 Incorrect (comment only), 5 Mostly accurate, security Low + Info, performance 1 Medium + 3 Low + 1 Info, api 3 Minor + 3 Info. Fixed in 084868f; fix-drift lite review of 088bc97..084868f found 1 comment drift, fixed in f733a51. |

## 🔴 Must Fix
None.

## 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| A1 | Header gave install-host.bats' /proc scan as within-file shared state; its real exposure is cross-file (`kind=unknown` for any same-uid process) and `--no-parallelize-within-files` does not remove it | fact-check claim 3 (Incorrect, comment); api F1; performance F3 | ✅ Fixed 084868f |
| A2 | "keeps output together (--keep-order)": grouping is parallel's default `--group`; results appear when the file and every earlier file end | fact-check claim 6 | ✅ Fixed 084868f |
| A3 | Citation-notice sentence: true of upstream, but Debian's build never prints it | fact-check claim 9 | ✅ Fixed 084868f |
| A4 | Test comment "everything except parallel" also drops bats' libexec | fact-check claim 17 | ✅ Fixed 084868f |
| A5 | "runs files through parallel, not tests within a file" checks parallel's args, not serial execution | fact-check claim 12 | Acknowledged (override log): the mutant without the flag fails it |
| A6 | 088bc97's Notes: the `script` tty check cannot show anything on Debian's build | fact-check claim 22 | Accepted-immutable (override log); corrected in 084868f's body and the header |
| A7 | install.sh's /proc scan slows as `--jobs` raises the process count, inside the file that bounds the speedup | performance F1 (Medium) | Acknowledged (override log) with measurements and a revisit trigger |

## 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | `--jobs` had no upper bound: overflow wrap, and parallel forks one slot probe per N (orphans held the run lock after TERM at N=20000) | security F1 (Low), api F3, fact-check E6 | ✅ Fixed 084868f: 1 to 999, lowered to the file count (+ tests) |
| C2 | `$PARALLEL` / parallel config could alter the run (fails closed) | security F2 (Info) | ✅ Fixed 084868f: `unset PARALLEL`, `PARALLEL_HOME=.bats/parallel-home` (+ test) |
| C3 | Fallback accepted any `parallel`, not GNU parallel | api F5 | ✅ Fixed 084868f: `parallel --version` check (+ test) |
| C4 | Timing-based tests and unbounded N under load | performance F4 | ✅ Partly: N capped, header says N above the core count buys nothing |
| C5 | Files not started longest-first | performance F2 | Defer (override log) |
| C6 | Serial `bats --count` step is a larger share of a parallel run | performance F5 | Defer (override log) |
| C7 | Usage-error exit 2 vs unknown-flag exit 1 (`-j 2`, `--jobs=2`) | api F2 | Won't-Fix (override log), pre-existing |
| C8 | bats merges per-file stderr into stdout under `--jobs` | api F4 | Won't-Fix (override log) |
| C9 | No caller passes `--jobs` yet | api F6 | Won't-Fix (override log), intended |

## ✅ Confirmed Good
- bats 1.8.2 aborts on `--jobs 2` without parallel, even for one file. Fact-check E1, executed.
- Each test writes its own run-log line under parallel; `--failed` with `--jobs` and the anchor file handed first works. Fact-check claims, executed; tests 23 and 24.
- The lock fd 9 reaches every test process under parallel; file paths with `$(…)`, backticks and quotes run without injection. Security, executed.
- The fallback and locale tests fail with their guards removed (fact-check E5, executed); the clamp and PARALLEL tests likewise (author, executed at 084868f).

## Coverage and escalations
- install-host.bats under `--jobs` beside other files was not run by any critic (the brief barred the full suite during the timing runs). The author's full-suite runs cover it: see the measurements in the merge notes.
- Pre-existing, outside the diff: with LC_ALL unset, LANG installed and LC_CTYPE uninstalled, the locale pin does not fire and perl still warns (fact-check E7).

## Considered overrides
Matched rows: 2026-09-28 `feat/u1-run-tests` K6 (a leftover process keeps `.bats/lock` held; stands, and the security F1 orphan case is now prevented by the N cap) and K8 (anchor file and `setup_suite.bash`; stands, unaffected).

## 🧩 Composition check
One qualifying cluster: `scripts/run-tests.sh:84-97` (fact-check claim 3, api F1, performance F3). Disposition: distinct defects: all three state the same complete mechanism and fix; nothing composed.

## ⏭️ Skipped Core Critics
None skipped.

## Reports
- `docs/reviews/q090-code-fact-check-report.md` (+ `execution-logs/q090-fc-k1-E1..E7`)
- `docs/reviews/q090-security-review-2026-09-30.md`
- `docs/reviews/q090-performance-review-2026-09-30.md`
- `docs/reviews/q090-api-consistency-review-2026-09-30.md`
