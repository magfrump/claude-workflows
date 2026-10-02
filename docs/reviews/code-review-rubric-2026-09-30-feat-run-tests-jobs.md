Commit: ff99d86
Loop closed at ff99d86

# Code Review Rubric — feat/run-tests-jobs (Q-090)

**Scope:** `main...feat/run-tests-jobs` (full branch, loop pass 1, `--loop-pass`). Delivery mode: self-read (each agent ran `git diff main...HEAD`; the diff is 9 KB).
**Status:** ✅ Mergeable after 3 passes (cap reached; exit condition 2 not needed: every Must Address is fixed in de61bc2 or acknowledged in the override log). No Must Fix at any pass. Single-sample review; absence of findings is not an attestation.

## Iterations

| Pass | Commit | Scope | Stages | Outcome |
|---|---|---|---|---|
| 1 | 088bc97 | full | fact-check k=1 (opus), security, performance, api-consistency (opus) | 1 Incorrect (comment only), 5 Mostly accurate, security Low + Info, performance 1 Medium + 3 Low + 1 Info, api 3 Minor + 3 Info. Fixed in 084868f; fix-drift lite review of 088bc97..084868f found 1 comment drift, fixed in f733a51. |
| 2 | b34a6fe | full | fact-check k=3 (opus) only | 3 Incorrect agreed by all replicates: PARALLEL_HOME did not isolate parallel's config; `unset PARALLEL` ran after the GNU check (unparsable $PARALLEL made the run serial); install-host exposure mechanism ("starting and ending" processes are skipped). Plus a stale comment, weak shim assertions (a mutant never handing bats --jobs passed 3 tests), a weak within-file example and an unmeasured core-count claim. Fixed in 78b3b08; fix-drift lite review: none. Critics deferred to pass 3 on the fixed code. Replicates: `q090-final-code-fact-check-report-r{1,2,3}.md` (not merged into one report; each lists the same three Incorrects). |
| 3 (final, no `--loop-pass`) | ff99d86 | full | fact-check k=3 (opus), security, performance, api-consistency (opus) | No Must Fix. Fact-check: Incorrect only in a test comment (PARALLEL test) and 78b3b08's body; the header's "--failed refuses that log" overclaimed for output-only configs (r2 Incorrect, r1 Mostly accurate, r3 Verified: most-severe wins, 🟡). Mostly accurate: bats runs no test (not abort) with a non-GNU parallel; $PARALLEL_CSH not unset; parallel's usage text cites; killed-run --jobs test never checked parallel was used. Security: 2 Informational. Performance: Low (mechanism of the one flake seen) + 3 Informational. API: 2 Minor (config wording; warning echoed the lowered N) + 1 Informational. All fixed in de61bc2 or logged; fix-drift lite review of ff99d86..de61bc2: none. Reports: `q090-pass3-code-fact-check-report-r{1,2,3}.md`, `q090-final-{security,performance,api-consistency}-review-2026-09-30.md`. |

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

| A8 | Pass 2: PARALLEL_HOME did not isolate parallel's config; `unset PARALLEL` after the GNU check; install-host mechanism; stale comment; shim assertions a no-`--jobs` mutant passed | fact-check pass 2 (k=3) | ✅ Fixed 78b3b08 |
| A9 | Pass 3: PARALLEL test comment; config fail-closed wording; `$PARALLEL_CSH`; non-GNU wording; usage-text citation; killed-run test did not check parallel; warning echoed lowered N; one flake in 12 parallel full runs (run-tests.bats "killed partway": 2 of 3 lines logged under load) | fact-check pass 3, api final F1/F2, performance final F1 | ✅ Fixed de61bc2 |
| A10 | 78b3b08 body claims (mutant note, "--failed refuses"); unset order not pinned by any test | fact-check pass 3 | Accepted-immutable / Acknowledged (override log) |

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
| C10 | User-exported BATS_* parallel variables, bad PARALLEL_SHELL, `--ungroup` config, parallel's cached setpgrp_func | security final F1/F2, fact-check pass 3 residue | Won't-Fix (override log) |
| C11 | Row 166 cited the 179 s run taken under review load | performance final Info 2 | Correction row added (override log) |

## ✅ Confirmed Good
- bats 1.8.2 aborts on `--jobs 2` without parallel, even for one file. Fact-check E1, executed.
- Each test writes its own run-log line under parallel; `--failed` with `--jobs` and the anchor file handed first works. Fact-check claims, executed; tests 23 and 24.
- The lock fd 9 reaches every test process under parallel; file paths with `$(…)`, backticks and quotes run without injection. Security, executed.
- Full gate at de61bc2: `scripts/run-tests.sh --jobs 8`, 1498 tests, 0 failures, 140 s (author, executed).
- The fallback and locale tests fail with their guards removed (fact-check E5, executed); the clamp and PARALLEL tests likewise (author, executed at 084868f).

## Coverage and escalations
- install-host.bats under `--jobs` beside other files was not run by any critic (the brief barred the full suite). The author's 12 full parallel runs cover it: install-host.bats never failed; the one failure was run-tests.bats' "killed partway" test (fixed in de61bc2).
- Pass 2 ran fact-check only (critics moved to pass 3 on the fixed code); pass 2's three replicate reports were not merged into one file.
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
