Commit: 65c931e

# Security Review: feat/q102-parallel-gates (Q-102 [1], parallel test gates by default)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-q102-parallel-gates` (HEAD 65c931e6): `scripts/health-check.sh`, `test/scripts/health-check.bats`, `workflows/pr-prep.md`, `docs/roadmap.md`, `docs/working/questions-archive.md`
**Date:** 2026-10-14
**Based on:** Stage-1 merged code-fact-check (`/home/node/.claude/jobs/00bcf178/tmp/shared.md`, Claims 1-5 and escalations)

The goal preamble came from the orchestrator, so the standalone goal-capture step is skipped.

## Trust Boundary Map

```
B1: [invoker env RUN_TESTS_JOBS]               → [check_bats regex ^[1-9][0-9]{0,2}$] → [runner argv --jobs "$jobs"] → [run-tests.sh regex, again] → [bats --jobs / GNU parallel]
B2: [invoker env RUN_TESTS_JOBS (bad value)]   → [fail "...'$jobs'..." via printf '%s\n']  → [gate output / terminal]
B3: [ambient bats/parallel config: BATS_NUMBER_OF_PARALLEL_JOBS, ~/.parallel/config, PARALLEL_HOME] → [run-tests.sh (unsets PARALLEL, PARALLEL_CSH only)] → [bats scheduling and the test-count validator] (scope widened: now on the default gate path)
B4: [concurrent suites' processes, same uid, now live beside each other (new under the default)] → [install.sh procs_in_checkout real /proc scan; timing windows in install-host.bats] → [gate 5 pass/fail verdict]
```

Input-source classification:

```
S1: RUN_TESTS_JOBS                 — deploy-time (invoker's shell env) — UNTRUSTED for argv/format/terminal sinks;
                                                                         trusted for availability (the invoker can
                                                                         stop the gate anyway)
S2: BATS_NUMBER_OF_PARALLEL_JOBS,
    BATS_NO_PARALLELIZE_ACROSS_FILES — deploy-time (ambient env)       — UNTRUSTED for "the gate's isolation
                                                                         guarantee" (not validated or cleared)
S3: GNU parallel config files      — runtime-mutable by any same-uid process (~/.parallel/config) — UNTRUSTED
                                                                         toward the gate verdict; writing it needs
                                                                         same-uid write to $HOME (host-control bar)
S4: concurrent test processes      — request-time (per gate run)      — UNTRUSTED toward install.sh's /proc scan
                                                                         and timing-based assertions
S5: literal 8 default              — code-constant                    — trusted (all sinks)
```

The diff adds one new external input (S1). It is checked with run-tests.sh's own regex, reaches the runner only as a quoted argv element, and reaches output only through `printf '%s\n'`. The larger change is not S1 but B4: every gate now runs about 8 suites at once by default. So suites that relied on running alone, without saying so, now share the uid's process table and CPU with up to 7 other files. The diff assumes that is harmless because run-tests.sh already supported `--jobs`. That holds for shared files and locks. It does not fully hold for one load-sensitive skip of a security test (Finding 1) or for the claim that 1 means serial (Finding 2).

## Findings

#### 1. A load-dependent `skip` lets the Q-064 non-dumpable refusal test drop out of a green gate, and parallel-by-default raises the load it depends on

**Severity:** Medium
**Location:** `test/install-host.bats:1594-1609` (T92), reached via `scripts/health-check.sh:420,428`
**Boundary:** B4
**Move:** 3 (error path), 8 (what if there are many of these)
**Confidence:** Low (mechanism is concrete; how likely it is to trigger at --jobs 8 is unmeasured)
**Legibility-target:** for-author

Evidence (verbatim):
```
  (cd "$S" && exec python3 -c 'import ctypes, time; ctypes.CDLL(None).prctl(4, 0, 0, 0, 0); time.sleep(300)') \
    >/dev/null 2>&1 3>&- &
  local hidden=$!
  for _i in $(seq 50); do readlink "/proc/$hidden/cwd" >/dev/null 2>&1 || break; sleep 0.1; done
  ! readlink "/proc/$hidden/cwd" >/dev/null 2>&1 || { kill "$hidden"; skip "prctl did not hide the cwd here"; }
```
T92 is the gate's only check that install.sh refuses when a same-uid process hides its cwd (Q-064 [2]). It cannot tell "this platform cannot hide a cwd" from "python3 had not reached prctl within 5 s". In the second case it skips. bats counts a skip as `ok ... # skip`, `check_bats` passes on runner exit 0, and nothing in gate 5 reports skips. On a loaded shared host (Stage-1 notes load around 5 during the last gate), with 8 suites now running at once by default and `RUN_TESTS_JOBS` allowed up to 999 (capped at the file count), a slow python3 start silently removes this assertion. The gate would then go green even if a branch broke the non-dumpable refusal in `procs_in_checkout`. A serial gate had the same mechanism, but parallel-by-default makes it more likely. I searched every `skip` in test/ (see the Primitive sweep). T92 is the only skip that depends on timing; the others depend on the platform (root, missing tools).

**Recommendation:** Make T92 wait on a signal from python3 after prctl returns (write a marker file, then `sleep`), and skip only when prctl ran and the cwd is still readable. A timeout before the marker appears should fail the test. Alternatively, have gate 5 surface the runner's skip count as a warning, the same way it surfaces `NOT RUN` suites.

#### 2. `RUN_TESTS_JOBS=1` is documented as serial, but an ambient `BATS_NUMBER_OF_PARALLEL_JOBS` still parallelizes, both across and within files

**Severity:** Low
**Location:** `scripts/health-check.sh:27-29,388-389`; `workflows/pr-prep.md:331`; runner behavior at `scripts/run-tests.sh:411-420`
**Boundary:** B3
**Move:** 2 (implicit sanitization assumption), 11
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (verbatim, diff):
```
+#                            runner as --jobs (Q-102 [1]). Default 8; 1 runs
+#                            serially.
```
```
+# cores; see the "Parallel runs" section of run-tests.sh). RUN_TESTS_JOBS=1
+# runs serially, for a suspected timing flake.
```
Evidence (verbatim, runner, unchanged): `if [[ "$jobs" -gt 1 ]]; then ... bats_args+=(--jobs "$jobs" --no-parallelize-within-files)`. With jobs=1, bats gets no `--jobs` flag and no `--no-parallelize-within-files`. bats 1.8.2 then falls back to the environment: `/usr/libexec/bats-core/bats-exec-suite:6: num_jobs=${BATS_NUMBER_OF_PARALLEL_JOBS:-1}` and `bats-exec-file:5` does the same.
Executed: a two-test file with `sleep 2` in each test took 2 s with `BATS_NUMBER_OF_PARALLEL_JOBS=2` and 4 s without it. So with that variable exported, `RUN_TESTS_JOBS=1` runs tests within a file at the same time. The runner header says no suite has been checked for that ("no suite has been checked for tests that interfere when run at once"). This is the escape hatch pr-prep and the code comment recommend for a suspected timing flake, and in that case it does not deliver isolation. A one-file selection lowers jobs to 1 and has the same gap. The default path (`--jobs 8`) is not affected, because the explicit flags override the variable. The usual result is a flaky failure, which fails closed. The rarer result is two tests in one file racing on shared `$BATS_FILE_TMPDIR` state. This was true before the diff (the serial gate passed no `--jobs` at all), so the diff's new claim is what makes it worth fixing now.

**Recommendation:** In run-tests.sh (or in check_bats before invoking the runner), `unset BATS_NUMBER_OF_PARALLEL_JOBS BATS_NO_PARALLELIZE_ACROSS_FILES`, in the same place that already unsets `PARALLEL` and `PARALLEL_CSH`. Then "1 = serial" holds whatever the invoker's environment. Add a stub-free runner test that exports the variable and checks the elapsed time or the order.

#### 3. The sibling gate-5 test reads an ambient `RUN_TESTS_JOBS`, so an outer gate's value leaks into the gate under test

**Severity:** Informational
**Location:** `test/scripts/health-check.bats:466-480` (unchanged by the diff; exposed by it)
**Boundary:** B1
**Move:** 1
**Confidence:** High (Stage-1 r2 executed: `not ok 8` with `RUN_TESTS_JOBS=abc` exported)
**Legibility-target:** for-author

Evidence (verbatim):
```
  run env -u HEALTH_CHECK_SKIP_BATS HEALTH_CHECK_RUN_TESTS="$stub" \
    bash -c 'source "$1"; check_bats; echo "FAIL=$FAIL"' _ "$SCRIPT"
```
The diff isolates `_run_check_bats` (`-u RUN_TESTS_JOBS`) but not this test. A bad ambient value makes it fail, which fails closed. A valid ambient value is harmless because the stub ignores `--jobs`. This is a hermeticity gap with no route to a false pass. It is listed here so it is tracked, and the Stage-1 escalation already routes the fix to the orchestrator.

**Recommendation:** Add `-u RUN_TESTS_JOBS` to that `env` call, or route it through `_run_check_bats`.

## Untested bypass candidates

The guardrail is the RUN_TESTS_JOBS regex plus "an env value cannot make the gate pass while running fewer tests". Tested candidates are in the Endorsement Claims. Not tested:

- `PARALLEL_HOME=<dir>` holding a parallel config: same mechanism as `~/.parallel/config`, and run-tests.sh does not unset it. Not run separately. I expect the same fail-closed result as the `--retries` probe below, but did not observe it.
- A parallel config that rewrites the job command through `--rpl` or a similar option so that it emits fabricated `ok N` lines: not tried. Writing that file needs same-uid write to `$HOME`, which also allows editing the suites or `bats` directly, so it is below the host-control bar.
- `BATS_NO_PARALLELIZE_ACROSS_FILES=1` on the default `--jobs 8` path: traced statically to the serial loop at `bats-exec-suite:425-431` (all files still run). Not executed.

## Endorsement Claims

- **Claim:** For RUN_TESTS_JOBS, the check_bats regex accepts exactly the decimal strings 1-999 with no leading zero. It rejects trailing or leading newlines, spaces, full-width or Arabic-Indic digits, superscripts, `+8`, `0x8`, `1e2`, `099` and `1000` under the locales installed here (C, C.UTF-8, C.utf8).
  **Location:** `scripts/health-check.sh:408-412`
  **Evidence:** executed
  **Verified:** the regex was run in bash under C, C.UTF-8 and C.utf8 against 13 candidates. Only `999` was accepted. The diff's own test covers `0 08 1000 -1 abc '8 ' '1;true'`.
  **Not verified:** behavior under a non-C UTF-8 locale whose collation might widen `[0-9]` (none is installed here, and run-tests.sh pins C when the ambient locale is missing).
  **route: code-fact-check**

- **Claim:** A RUN_TESTS_JOBS value reaches the runner only as one quoted argv element (`--jobs "$jobs"`) and reaches output only as a `%s` argument to `printf`. No `eval`, format-string or shell re-parse of the value occurs in health-check.sh.
  **Location:** `scripts/health-check.sh:410,420,428`; `scripts/lib/log-format.sh:5-14`
  **Evidence:** read-static
  **Verified:** read `fail`/`red` (`printf '%s\n' "$*"` on both the TTY and non-TTY branches) and both runner invocations. `rg RUN_TESTS_JOBS` outside docs finds no other use.
  **Not verified:** how bats-exec-suite quotes `--jobs` into its `parallel` call (`printf "%q "` at `bats-exec-suite:420` quotes flags; `num_jobs` itself is passed as `--jobs "$num_jobs"`). The value is already restricted to 1-999 at that point.
  **route: code-fact-check**

- **Claim:** A GNU parallel config (`--retries 3` in `~/.parallel/config`) cannot turn a failing test into a passing bats run under `--jobs 2 --no-parallelize-within-files`. bats' test-count validator printed `Executed 1 instead of expected 2 tests` and the run exited 1.
  **Location:** `/usr/lib/bats-core/validator.bash:11-32`; `scripts/run-tests.sh:95-104`
  **Evidence:** executed
  **Verified:** a two-file probe with HOME pointed at a scratch dir holding the config. It exited 1, and so did the run without the config (one test really failed).
  **Not verified:** other parallel options (`--rpl`, `--dry-run`, `--halt`), and `PARALLEL_HOME` as the config source.
  **route: code-fact-check**

- **Claim:** A bad RUN_TESTS_JOBS fails gate 5 before any runner invocation (the stub log is empty), so an invalid value cannot skip to a pass.
  **Location:** `scripts/health-check.sh:409-412`; `test/scripts/health-check.bats:234-243`
  **Evidence:** read-static (the diff's own test asserts `[ ! -s "$STUB_LOG" ]` and `FAIL=1`; I did not run it here)
  **Verified:** read the early `return` after `fail` (which sets FAIL=1) and the test loop.
  **Not verified:** the empty-string case. `${RUN_TESTS_JOBS:-8}` maps it to 8 (Stage-1 Claim 3), which runs the full suite, so it is not a fewer-tests route.
  **route: code-fact-check**

- **Claim:** The suites sampled for shared-path writes (install-host, run-tests, generate-reports, health-check negatives, build-loop-*, self-improvement-*, hooks/guard-trusted-writes, live-verify-gate) write under `$BATS_TEST_TMPDIR`/`$BATS_FILE_TMPDIR` or copies there, not into the shared worktree or fixed `/tmp` names. The two `/tmp/...-$$` paths are read-only "nonexistent" probes.
  **Location:** `test/**` (rg sweep for redirects, mkdir, cp, rm and git writes on `$REPO_ROOT`-style paths, and literal `/tmp/`)
  **Evidence:** read-static
  **Verified:** the rg hits listed above and their enclosing setup functions in run-tests.bats, generate-reports.bats and health-check.bats (`_fixture_repo`).
  **Not verified:** writes made through helper libraries under `test/skills/*.bash` and through `$HOME` in suites that do not pin HOME. The sweep did not cover those.

- **Claim:** install.sh's real `/proc` scan, when concurrent suites are running, can add refusals (`unknown`/`in` lines) but cannot remove one. install-host's refusal tests (T88, T91, T92) assert a specific PID and command line, not only `status 1`, so a concurrent process cannot satisfy them in place of their own planted process.
  **Location:** `devcontainer-config/install.sh:1165-1182,1203`; `test/install-host.bats:1529-1609`
  **Evidence:** read-static
  **Verified:** read `procs_in_checkout`, the `agent_gate` scan handling, and T88/T91/T92 in full.
  **Not verified:** refusal tests elsewhere in install-host.bats (T50-T53 and T60s) that stub pgrep. I did not check each one for a PID-specific assertion.

## Primitive sweep

Primitive: process exec with an env-derived argument (runner invocation)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/health-check.sh:420` `"$runner" --fast --jobs "$jobs"` | S1 | regex at :409, quoted argv | cleared: digits only, one argv element |
| `scripts/health-check.sh:428` `"$runner" --slow --jobs "$jobs"` | S1 | same | cleared: same |
| `scripts/run-tests.sh:416` `bats_args+=(--jobs "$jobs" ...)` | S1 (re-validated at run-tests.sh:144) | regex + cap to file count | cleared |
| `scripts/run-tests.sh:440` `exec bats ...` with jobs=1 | S2 | none (env not cleared) | Finding 2 |

Primitive: output interpolation of env value
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/health-check.sh:410` `fail "RUN_TESTS_JOBS='$jobs' ..."` | S1 | `printf '%s\n'` | cleared: no format injection. Raw control bytes reach the invoker's own terminal, and only the invoker can set them. |

Load-dependent `skip` (swept: every `skip` in `test/**/*.bats`)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/install-host.bats:1602` | S4 | 5 s poll | Finding 1 |
| `test/install-host.bats:81,676,1596`; `cc-isolated-functions.bats:1495`; `build-loop-check.bats:674,867,877,2290`; `guard-trusted-writes.bats:889`; `health-check.bats:350,362,391`; `run-tests.bats:122,337`; `live-verify-gate.bats:249-251`; `build-loop-orchestrator.bats:314`; `lever-measurement-drift.bats:21`; `sandbox-tool-map-drift.bats:49`; `arithmetic-eval-eval.bats:50` | platform/tool/uid | n/a | cleared: these depend on the platform, not on load |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | T92's load-dependent skip drops the Q-064 refusal test from a green gate; parallel default raises the load | Medium | B4 | `test/install-host.bats:1594-1609` | Low |
| 2 | `RUN_TESTS_JOBS=1` is not serial when `BATS_NUMBER_OF_PARALLEL_JOBS` is exported | Low | B3 | `scripts/health-check.sh:27-29,388-389`; `scripts/run-tests.sh:411-420` | High |
| 3 | Sibling gate-5 test not isolated from ambient RUN_TESTS_JOBS | Informational | B1 | `test/scripts/health-check.bats:466-480` | High |

## Overall Assessment

The new input itself is handled well. RUN_TESTS_JOBS is validated with the runner's grammar before anything runs, passed as a quoted argv element, and printed with `%s`. No value I tried got past the regex, and the parallel-config route I executed fails closed through bats' test-count validator. I found no way for an env value alone to make the gate pass on a full run while fewer tests run. Shared files and locks look isolated in the suites I sampled. The real exposure is the load-dependent skip in T92 (Finding 1), which can let a merge-gating security test drop out without any signal. Parallel-by-default makes that more likely. It is fixable in place, in the test, by waiting on a marker instead of a timer, or by having gate 5 report skips. Finding 2 is a small fix in the runner (unset the bats env knobs) that makes the new "1 = serial" documentation true. Assessment: no findings that block on exploitability within the code paths read; the endorsement claims are pending execution verification where they are read-static.

## Goal-Alignment Note

The goal is to land Q-102 [1], parallel gates by default, as one reviewed unit. Nothing here argues against parallelism. Findings 2 and 3 are one-line fixes that belong in this unit, because the diff introduces the "1 = serial" claim and the RUN_TESTS_JOBS variable. Finding 1 lives in install-host.bats, outside the diff. It is a pre-existing weakness whose likelihood this change raises. It is the one item worth landing alongside, or recording as a revisit trigger next to override-log rows 93 and 181 (install-host under --jobs), if the author wants to keep this unit small. Nothing found suggests the default of 8 should be lower.
