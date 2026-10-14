Commit: 57f37e3

# Security Review — feat/q102-parallel-gates, confirming pass (fix range 65c931e6..57f37e3a)

**Scope:** fix commits db341cb9 and 57f37e3a (scripts/health-check.sh check_bats, scripts/run-tests.sh bats env unset, test/install-host.bats T92, the fast-to-slow retag of test/cc-isolated-functions.bats and test/scripts/build-loop-check.bats, test/scripts/health-check.bats, test/scripts/run-tests.bats)
**Date:** 2026-10-14
**Based on:** shared context `shared2.md` (goal preamble supplied by the orchestrator); pass-1 rubric docs/reviews/code-review-rubric-2026-10-14-feat-q102-parallel-gates.md

> ⚠️ **No code fact-check report provided for this pass.** Claims in comments were checked against code where they bear on the questions below; the rest are unverified.

## Trust Boundary Map

```
B1: [caller environment: HEALTH_CHECK_JOBS, PATH→nproc] → [check_bats grammar check] → [run-tests.sh --jobs N]
B2: [inherited bats env: BATS_NUMBER_OF_PARALLEL_JOBS, BATS_NO_PARALLELIZE_ACROSS_FILES] → [run-tests.sh unset] → [bats-exec-suite / bats-exec-file scheduling]
B3: [per-file @category tag] → [run-tests.sh collect_tests] → [health-check gate 5: --fast, then --slow if fast is green]
B4: (new) [T92's non-dumpable python3 (same uid, cwd hidden)] → [/proc scan in install.sh procs_in_checkout] → [every install.sh run of this uid that runs while it lives, in any test file]
B5: [marker file $BATS_TEST_TMPDIR/t92-hidden] → [T92 wait loop] → [T92's skip/fail/run decision]
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | HEALTH_CHECK_JOBS | request-time (caller env) | Trusted for availability (the caller already picks the runner via HEALTH_CHECK_RUN_TESTS); validated by grammar before reaching argv |
| S2 | `nproc` output, first on PATH | request-time (caller env) | Same trust as PATH, which already selects bats, git and the runner; checked `^[1-9][0-9]*$` and only lowers |
| S3 | BATS_* parallel env vars | request-time (inherited) | Untrusted for the "1 = serial" guarantee; now unset |
| S4 | `# @category` tags | code-constant (committed) | Trusted; any value other than fast/slow is collected by neither run (pre-existing) |
| S5 | `$BATS_TEST_TMPDIR` marker | per-test tmp dir | Trusted (per-test bats temp dir; same-uid writers are out of scope) |
| S6 | /proc process table | runtime (shared by every concurrent test file) | Shared state: under `--jobs` every file sees every other file's processes |

The diff adds no new privilege boundary: everything S1/S2 can influence was already caller-controlled. The one new crossing is B4: the retag puts cc-isolated-functions.bats in the same (parallel) run as install-host.bats, so T92's deliberately hidden process is now visible to another file's install.sh runs.

## Findings

#### F1. T92's hidden python3 makes cc-isolated-functions.bats' install.sh tests fail when the two overlap; the retag makes them co-scheduled

**Severity:** Low
**Location:** `test/install-host.bats:1602-1608`; `test/cc-isolated-functions.bats:1-2` (retag), `:641-750` (install.sh tests); `devcontainer-config/install.sh:1165-1181,1343`
**Boundary:** B4, B3
**Move:** 4 (shared state between check and use), 8
**Confidence:** High on the mechanism (reproduced); Low on how often it fires in the gate
**Legibility-target:** whoever triages a red slow run under the default `--jobs`

Evidence (install.sh scans every same-uid process, and an unreadable cwd counts wherever it is):
```
    if cwd="$(readlink "$d/cwd" 2>/dev/null)"; then
      case "$cwd" in "$root"|"$root"/*) kind=in ;; *) continue ;; esac
    else
      kind=unknown
    fi
```
cc-isolated-functions.bats stubs `pgrep` and `docker` but not /proc, and its install.sh tests reach `agent_gate "Nothing was staged or installed."` in `main` before payload assembly. Before this branch that file was `# @category fast` and never ran at the same time as install-host.bats (slow). Now both are slow, so `--jobs N` runs them concurrently. Reproduced: with a same-uid `prctl(4,0)` python3 sleeping in a temp dir, `bats -f 'install.sh assembles the payload when every source is present|install.sh aborts when a payload source is missing' test/cc-isolated-functions.bats` gave `not ok 1 ... 'payload source(s) not found'* ]]' failed` and `not ok 2 ... 'bless it?'* ]]' failed`; both pass without that process. The failures go in the safe direction (the gate goes red, never falsely green), and timing makes overlap unlikely today: T92 sits near the end of a ~141 s file, and the install.sh tests sit about a third of the way into an ~85 s file. But a loaded host, or a reorder, can make them overlap, and the failure looks like an install.sh regression in another file. This is the cross-file stray-process hazard pr-prep step 5a describes, now caused by a test.
Related: if the gate is interrupted while T92 runs (a timeout or SIGINT outside the test's own paths), nothing kills the process. `teardown()` only chmods. It lives up to 300 s and turns every later same-uid install.sh run (and install-host tests in a rerun) into an `unknown` refusal.

**Recommendation:** Keep install-host.bats and any other file that runs install.sh's real /proc scan apart. Either keep cc-isolated-functions.bats' install.sh tests off the real /proc scan (a test seam, as for pgrep), or record the exclusion as a known co-scheduling hazard in run-tests.sh's "Parallel runs" header. Also kill `$hidden` in `teardown()` (store it in a global) and shorten the sleep to what the test needs (e.g. 60 s).

#### F2. The remaining T92 skip covers more than "a kernel where prctl does not hide the cwd", and a skip still passes the gate

**Severity:** Informational
**Location:** `test/install-host.bats:1596-1607`
**Boundary:** B5
**Move:** 3, 11
**Confidence:** Medium
**Legibility-target:** the T92 comment's reader

Evidence:
```
  # loaded host (the gate runs files in parallel, Q-102) waits rather than
  # skipping; the skip is only for a kernel where prctl does not hide the cwd.
...
  ! readlink "/proc/$hidden/cwd" >/dev/null 2>&1 || { kill "$hidden"; skip "prctl did not hide the cwd here"; }
```
python3 ignores prctl's return value and writes the marker either way. So the skip also fires when prctl fails (for example, seccomp returns EPERM) and when the reader can read non-dumpable cwds anyway (root, or CAP_SYS_PTRACE in a container). The pass-1 fix is otherwise sound: a slow start now waits up to 60 s and then fails (`return 1`), never skips. The pre-existing `import ctypes` skip is unchanged. These are environments where the test cannot exercise the refusal, so skipping is defensible. Only the comment's "only for a kernel" overstates it.

**Recommendation:** Reword the comment to say "where the hide does not take effect (kernel, seccomp, or a reader with CAP_SYS_PTRACE)". Optionally, have python3 exit nonzero when prctl returns nonzero, so that case fails instead of skipping.

#### F3. A nproc output past bash's integer range turns into a gate failure that names HEALTH_CHECK_JOBS

**Severity:** Informational
**Location:** `scripts/health-check.sh:413-421`
**Boundary:** B1
**Move:** 2, 11
**Confidence:** High (executed)
**Legibility-target:** the gate-5 failure message

Evidence:
```
        cores="$(nproc 2>/dev/null || true)"
        [[ "$cores" =~ ^[1-9][0-9]*$ ]] && (( cores < jobs )) && jobs=$cores
```
Executed: `9223372036854775808 -> 9223372036854775808` and `18446744073709551617 -> 18446744073709551617`, because the arithmetic wraps negative and the value passes `cores < jobs`. The next grammar check then fails the gate with `HEALTH_CHECK_JOBS='9223372036854775808' is not 1 to 999`, although HEALTH_CHECK_JOBS was unset. This fails closed, and a real nproc never prints such a value. It is a misleading message, not a bypass.

**Recommendation:** Tighten the cores regex to `^[1-9][0-9]{0,2}$`, so an implausible value falls back to 8.

#### F4. (Not security; for the code-review rubric) The "red fast blocks slow" test depends on the host's core count

**Severity:** Informational
**Location:** `test/scripts/health-check.bats:264-270`
**Boundary:** B1
**Move:** 3
**Confidence:** High (read-static)
**Legibility-target:** whoever runs the suite on a host with fewer than 8 cores

Evidence:
```
  STUB_FAST_RC=1 STUB_SLOW_RC=0 _run_check_bats
...
  [ "$(cat "$STUB_LOG")" = "--fast --jobs 8 skip=1" ]
```
No `STUB_NPROC` is set, so the real `nproc` caps jobs. On a host with fewer than 8 cores the log says `--jobs <nproc>` and the test fails. The first gate-5 test was given `STUB_NPROC=16` for this reason, but this one was not.

**Recommendation:** Prefix it with `STUB_NPROC=16`.

## Answers to the focus questions

- **Can T92 still pass without exercising the hidden-cwd refusal?** Not along any path I read. It asserts `status 1`, `"$hidden python3 -c"` and `'working directory cannot be read'`. The last string appears in refusal output only in the `unknown` block (install.sh:1269); the usage-text copy (line 58) is printed for `--help`, which I did not trace to every exit. The readlink precheck guarantees the cwd is already unreadable when install.sh scans, and `PR_SET_DUMPABLE=0` does not revert. If python3 died after writing the marker, install.sh would not list it, and the test fails. Executed: `ok 1 T92 ...` (a pass, not a skip) on this host.
- **Can it skip?** Only through the `import ctypes` precheck (pre-existing) and the readlink-still-works branch (F2). A slow start fails after 60 s instead of skipping.
- **Is the marker path safe?** `$S/t92-hidden` = `$BATS_TEST_TMPDIR/t92-hidden`. It is in a fresh per-test directory, outside `$ROOT` (`$S/repo`), so it does not dirty the fake checkout's git state. It could only exist early if something of the same uid planted it, which would make the test skip. That is out of the threat model.
- **python3 on every path:** fail path `kill "$hidden" 2>/dev/null`; skip path `kill "$hidden"`; pass path `kill "$hidden" 2>/dev/null || true` before the assertions. `$hidden` is the python3 PID itself (the subshell `exec`s). After the executed run, `pgrep -a python3` showed nothing left. The gap is an external interruption, since teardown has no kill (F1).
- **nproc via PATH:** It can only lower jobs (down to 1) or fail the gate (F3). `--jobs` changes concurrency, not which files run, so a hostile PATH cannot make the gate run fewer tests or pass falsely through this lookup. The same PATH already chooses `bats`, and HEALTH_CHECK_RUN_TESTS already chooses the runner, so S2 adds no new capability.
- **Is "1 = serial" complete?** For the installed Bats 1.8.2, yes. `bats-exec-suite` reads `BATS_NUMBER_OF_PARALLEL_JOBS` and `BATS_NO_PARALLELIZE_ACROSS_FILES`; `bats-exec-file` reads `BATS_NUMBER_OF_PARALLEL_JOBS` and `BATS_NO_PARALLELIZE_WITHIN_FILE`, and the last can only reduce parallelism. With `--jobs 1`, run-tests.sh passes no `--jobs` flag, so `num_jobs` falls to 1. Executed: `ok 1 --jobs 1 stays serial when bats' own parallel variables are inherited`. Not verified: newer bats releases (e.g. `BATS_PARALLEL_BINARY_NAME`), which matter only when jobs > 1.
- **Does the retag drop files from a gate?** No. `collect_tests` keeps a `slow` tag for `--slow`, and health-check runs `--slow` whenever `--fast` is green. A grep for `--fast` callers outside docs found only health-check.sh:430 and nested fixtures in test/skills/eval-helpers-gating.bats; hooks/, dev-cycle and build-loop scripts don't call run-tests.sh with a category. scripts/self-improvement.sh runs `bats test/` directly (pre-existing, category-blind). The one behavioural change: when fast is red, those two files no longer run until it is green. Their side effect is F1.

## Endorsement Claims

- **Claim:** With `--jobs 1`, run-tests.sh starts bats with no parallel scheduling even when `BATS_NUMBER_OF_PARALLEL_JOBS=4` is inherited.
  **Location:** `scripts/run-tests.sh:414-424`
  **Evidence:** executed
  **Verified:** the new run-tests.bats test passes, and the parallel shim recorded no call; bats 1.8.2's libexec reads only the variables listed above.
  **Not verified:** bats versions other than 1.8.2; I did not run this test against the pre-fix runner to see it go red.
- **Claim:** T92 passes on this host by reaching install.sh's `unknown` refusal, and leaves no python3 behind.
  **Location:** `test/install-host.bats:1594-1614`
  **Evidence:** executed
  **Verified:** `bats -f 'T92'` gave `ok 1`, and a later `pgrep -a python3` was empty.
  **Not verified:** the 60 s fail path and the skip path were not executed.
  **route: code-fact-check**

## Untested bypass candidates

- The T92 skip under a seccomp profile that denies prctl (F2): not run, because there is no such profile here.
- The fail path when python3 starts slowly (a host that takes over 60 s): not run.

## Primitive sweep

Primitive: process exec / kill by PID

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/install-host.bats:1602` python3 spawn | S5 marker path (argv, not code) | path passed as `sys.argv[1]`, not interpolated into code | cleared |
| `test/install-host.bats:1606,1607,1609` `kill "$hidden"` | `$!` of its own subshell (exec'd) | own child PID | cleared; interrupted path uncovered (F1) |
| `scripts/health-check.sh:415` `nproc` | S2 PATH | output regex, only lowers | F3 (message only) |
| `scripts/health-check.sh:430,437` runner `--jobs "$jobs"` | S1/S2 | `^[1-9][0-9]{0,2}$` | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | T92's hidden process fails co-scheduled cc-isolated install.sh tests (retag makes them concurrent); no teardown kill | Low | B4, B3 | `test/install-host.bats:1602-1608`, `test/cc-isolated-functions.bats:2` | High (mechanism) / Low (frequency) |
| 2 | T92 skip covers prctl failure and CAP_SYS_PTRACE, not only kernels | Informational | B5 | `test/install-host.bats:1596-1607` | Medium |
| 3 | Overflowing nproc output yields a misleading HEALTH_CHECK_JOBS failure | Informational | B1 | `scripts/health-check.sh:415-420` | High |
| 4 | "red fast blocks slow" test hard-codes `--jobs 8` without STUB_NPROC (not security) | Informational | B1 | `test/scripts/health-check.bats:264-270` | High |

## Overall Assessment

The pass-1 fixes do what they claim. T92 now fails instead of skipping on a slow start, and passes only through the `unknown`-cwd refusal. The bats env unset gives a complete "1 = serial" for bats 1.8.2. The nproc cap can only lower concurrency or fail closed. The retag drops neither file from gate 5. Nothing found lets the gate pass falsely. The one thing the fixes introduced is F1: moving cc-isolated-functions.bats into the slow run puts its real-/proc install.sh tests alongside T92's deliberately hidden process. That is a reproduced, fail-direction flake, unlikely with today's timing. It is fixable in place, by keeping those tests off the real /proc scan or killing in teardown. No findings that block a merge within the code paths read; the endorsement claims are scoped above.

## Goal-Alignment Note

The goal is to land Q-102 [1] (parallel gate 5 by default) as one reviewed unit. This pass confirms the fixes serve that goal without weakening the gate's pass condition. F1 is the only item tied to the goal itself: parallel-by-default is what makes cross-file /proc interference possible. Fixing it, or recording it as a known hazard, keeps a red gate under `--jobs` trustworthy, so "rerun with HEALTH_CHECK_JOBS=1" does not become the reflex. F2 to F4 are wording and test-hygiene items that can be fixed in passing or deferred.
