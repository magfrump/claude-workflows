Commit: 088bc97

# Security Review — feat/run-tests-jobs (Q-090, `--jobs N`)

**Scope:** `git diff main...HEAD`: scripts/run-tests.sh (header "Parallel runs", `--jobs` parsing at `:124-132`, `bats_args` block at `:388-396`) and test/scripts/run-tests.bats (`parallel_shim`, 7 new tests). Context read in full: scripts/run-tests.sh `:96-413`, test/scripts/run-tests.bats `:1-120` and `:325-446`, `/usr/bin/parallel:7848-8069` (the job-slot probe), `devcontainer-config/install.sh:1150-1182`.
**Date:** 2026-09-30
**Based on:** docs/reviews/q090-code-fact-check-report.md (k=1, 23 claims: 17 verified, 5 mostly accurate, 1 incorrect)
**User goal:** pinned upstream by the orchestrator's goal preamble (land `--jobs N` for scripts/run-tests.sh after a clean review-fix loop).

No escalation pattern matched (no secrets, no auth surface, no injection into user-facing code, no TLS change, no key material).

All probes ran with `LC_ALL=C.UTF-8`, under `timeout`, in throwaway directories under the session scratchpad (`.../scratchpad/q090sec/`), except the validator probes (P6), which exit at argument parsing before the lock. The full suite was not run. Every process a probe left behind was killed by PID (never by pattern), and a final `ps` check found none left.

| Probe | What | Result |
|---|---|---|
| P1 | `exec 9>lock; bats --jobs 2 --no-parallelize-within-files a.bats b.bats`; each test lists `/proc/self/fd` | fd 9 (the lock) is open in every test process under `parallel`; parallel's `--group` buffer is `/tmp/par*.par (deleted)`, mode `600` |
| P2 | `PARALLEL=--tag bats --jobs 2 ...`; `HOME` with `.parallel/config` = `--dry-run` | `--tag` rewrites every TAP line; `--dry-run` runs 0 tests, `# bats warning: Executed 0 instead of expected 2 tests`, exit 1 |
| P3 | `bats --jobs N ...` with 2 one-test files, N = 2, 50, 200, 1000, 3000, 99999 | wall time 0.25 s, 0.27 s, 0.52 s, 2.6 s, 18.6 s; N=99999 still running at the 60 s timeout, and `parallel` survived it at 99% CPU with 1009 orphaned `sleep 10101` children |
| P4 | Throwaway copy of the runner, `setsid timeout -s TERM 4 bash scripts/run-tests.sh --jobs 20000` | exit 124; 3 s later `parallel` is alive (ppid 1, 102% CPU), 662 `sleep 10101` dummies, the run lock is held, and a new run prints `another run-tests.sh run is in progress in this checkout` |
| P5 | Same copy, `--jobs 20000` in its own session, then `kill -INT -- -<sid>` after 4 s (Ctrl-C) | 1650 processes in the session before the signal, 0 after; lock free |
| P6 | Worktree runner, `--jobs` with `$'2\n'`, `٢`, `２`, `1e3`, `0x10`, `' 2'`, `+2`, under C.UTF-8 and the ambient (broken) locale | exit 2 for every value in both locales |
| P7 | `bats --jobs 2` on files named `x $(touch INJECTED) \`touch INJ2\`;touch INJ3.bats` and `it's "q".bats` | both ran (ok 1, ok 2); no `INJ*` file was created |

---

## Trust Boundary Map

```
B1 (new): [--jobs N argv, invoking user/agent] → [regex ^[1-9][0-9]*$ at run-tests.sh:125] → [bats --jobs N → parallel --jobs N: slot probe + job spawn]
B2 (new): [PATH lookup of `parallel`]          → [command -v parallel at run-tests.sh:391]  → [bats-exec-suite exec's it with full env and lock fd 9]
B3 (new): [ambient PARALLEL / ~/.parallel/*]   → [none (runner does not scrub)]           → [parallel option parsing → TAP stream and run log]
B4:       [test/ file paths (find / FILE...)]  → [realpath under test/ check, :180-186]    → [parallel `{}` substitution → shell → bats-exec-file]
```

B4 exists on main (serial bats used the same paths with no shell in between). The diff moves it: under `--jobs` the paths now pass through `parallel`'s command line and a shell.

Input sources:

```
S1: --jobs N argv                  — request-time (per invocation) — trusted for exec/path sinks (digits only after B1's regex, P6);
                                                                      UNTRUSTED-in-magnitude for resource sinks (no upper bound; the
                                                                      runner is invoked by agents as well as by the user)
S2: PATH                           — deploy-time (session env)       — trusted for exec (whoever sets PATH already runs code as this uid)
S3: PARALLEL env, $HOME/.parallel/ — deploy-time (session env/home)  — trusted for exec; NOT hermetic for the output/run-log sinks the
    config, PARALLEL_HOME                                             runner's checks read (P2)
S4: test/**/*.bats paths           — code-constant (repo content)    — trusted for exec (the same files are executed as tests);
                                                                      treated as untrusted for shell-quoting below only to disposition B4
S5: $T / BATS_TEST_TMPDIR (tests)  — deploy-time                     — trusted (test-only code generation in parallel_shim)
```

What enters from outside is one new argument (S1) and one new executable resolved from the environment (S2), which reads its own ambient configuration (S3). The diff assumes S1 is sane in magnitude once it is syntactically a positive integer. It also assumes S3 is empty; nothing in the runner enforces that, where the neighbouring locale pin does enforce its assumption about the environment. No authentication, secret or network surface is touched.

## Findings

#### 1. An unbounded `--jobs N` makes GNU parallel fork up to N dummy processes; killed by TERM, it orphans, spins, and holds the run lock for hours

**Severity:** Low
**Location:** `scripts/run-tests.sh:124-132`, `scripts/run-tests.sh:390-392`
**Boundary:** B1
**Move:** 8 (what if there are a million of these?), 3 (error path)
**Confidence:** High (executed: P3, P4, P5)
**Legibility-target:** for-author

Evidence (the validator accepts any length of digits, and the string reaches bats unchanged):

```bash
# scripts/run-tests.sh:125 and :130 (excerpt of the --jobs case arm, :124-132 — read)
      if [[ ! "${2:-}" =~ ^[1-9][0-9]*$ ]]; then
      jobs="$2"
```

```bash
# scripts/run-tests.sh:390-392 (excerpt; the else-warning branch runs to :396 — read)
if [[ "$jobs" -gt 1 ]]; then
  if command -v parallel > /dev/null; then
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
```

GNU parallel does not stop at the argument count when sizing its job slots. With a finite `-j` it forks one dummy `sleep 10101` per slot until it reaches N or runs out of processes or file handles:

```perl
# /usr/bin/parallel:7997-7999 and :8000-8017 (excerpt of processes_available_by_system_limit, :7970-8069 — read)
	if($wanted_processes < $Global::infinity) {
	    $Global::dummy_jobs = 1;
	}
	while(1) {
	    $system_limit >= $wanted_processes and last;
	    ...
	    reserve_process();
```

`reserve_process` (`:7885-7902`) is `exec 'sleep', 10101`. The dummies are killed only in `cleanup()` (`:7954-7968`), after the loop ends. The probe's cost grows faster than N: 2.6 s at N=1000, 18.6 s at N=3000, and not finished after 60 s at N=99999 (P3). On this host `ulimit -u` is unlimited and `pid_max` is 4194304, so nothing stops the loop early.

The error path is worse than the cost. Under `timeout -s TERM` (P4), bats exits but `parallel` does not stop its probe loop: it is reparented to init at ~100% CPU and keeps forking. Every dummy inherits fd 9, which the runner flocks and hands to bats. P1 shows fd 9 in `parallel`'s children, and P4 shows the lock still held after the runner is gone. So every later `run-tests.sh` in that checkout is refused with "another run-tests.sh run is in progress". If `parallel` is then SIGKILLed, the orphaned dummies still hold the lock for up to 10101 s (~2.8 h), and they are shared-uid processes that `pkill -f` hygiene rules forbid other sessions from sweeping. Ctrl-C to the whole foreground group (P5) cleans up correctly. So the hazard is specific to TERM-based wrappers (`timeout`, `kill <pid>`), which are what agents use.

Severity reasoning: the source is whoever invokes the runner. A human typing `--jobs 100000` is self-inflicted. An agent computing N badly (for example from a byte count, or `--jobs $(nproc)000`) is the realistic trigger. That party already runs code as this uid, so the floor rule's reachable-attacker bar is not met, and this stays Low: an availability and lock-integrity defect, not an exploit. The fact-check's overflow residue (Claim 1: `18446744073709551617` wraps to 1 and runs serially) is the same missing bound seen from the other side. The comparison and the value handed on can also disagree: `[[ 18446744073709571616 -gt 1 ]]` sees 20000, but bats receives the 20-digit string.

**Recommendation:** Clamp N before it reaches bats. `parallel` never runs more jobs than there are files, so `(( ${#jobs} > 4 || jobs > ${#files[@]} )) && jobs=${#files[@]}` loses nothing. The length test comes first so that arithmetic never sees an overflowing string. Alternatively, reject N above a small ceiling with exit 2. Add a test that `--jobs 99999` hands bats `--jobs <file count>`.

#### 2. The runner now executes GNU parallel with its ambient configuration unscrubbed (`PARALLEL`, `~/.parallel/config`, `PARALLEL_HOME`)

**Severity:** Informational
**Location:** `scripts/run-tests.sh:390-392`
**Boundary:** B3
**Move:** 1 (trace the trust boundaries), 2 (implicit sanitization assumption)
**Confidence:** High (executed: P2)
**Legibility-target:** for-author

Evidence: the only environment handling in the runner is the locale pin; nothing touches parallel's inputs:

```bash
# scripts/run-tests.sh:156-162 (the locale pin block, complete)
ambient_locale="${LC_ALL:-${LANG:-}}"
if ! locale_installed "$ambient_locale"; then
  pinned=C
  locale_installed C.UTF-8 && pinned=C.UTF-8
  export LC_ALL="$pinned"
  echo "Locale $ambient_locale is not installed; running with LC_ALL=$pinned"
fi
```

GNU parallel prepends `$PARALLEL` and `$PARALLEL_HOME/config` (default `~/.parallel/config`) to its own options. In P2, `PARALLEL=--tag` prefixed every TAP line with the file path, and a config holding `--dry-run` ran zero tests. Both failed closed: bats' count validator reported `Executed 0 instead of expected 2 tests` and exited 1, and a run with no result lines is refused by `--failed` (`:241-247`). So no configuration found here turns failures into passes. It does make `--jobs` output depend on per-user state that the serial path never reads. This is the kind of non-hermeticity the locale pin exists to remove. Options such as `--sshlogin` in a stale config would run the suite on another host. That needs someone who already writes this user's home directory, so it is not a trust violation.

**Recommendation:** Optional hardening, in the `jobs -gt 1` branch: `unset PARALLEL` and `export PARALLEL_HOME="$(mktemp -d)"` (or point it at a repo-local empty directory), with one header sentence saying so. Skip it if you judge per-user parallel configuration to be a feature.

## Untested bypass candidates

Guardrails touched by the diff are the `--jobs` validator (B1) and the `command -v parallel` fallback (B2). Tested candidates for B1: `$'2\n'`, `٢`, `２`, `1e3`, `0x10`, `' 2'`, `+2` all exit 2 (P6). Missing, `0`, `02`, `-1`, `x` and a following flag also exit 2 (fact-check E6). Magnitude (`99999`, overflow) passes and is Finding 1. For B4, shell metacharacters and quotes in file names ran without injection (P7). Not tested:

- **B2, a non-GNU `parallel` first on PATH** (moreutils' binary, which this host's dpkg diversion anticipates at `/usr/bin/parallel.moreutils`). Not installed here, so it could not be run. The expected result is a bats failure on unknown options, which fails closed, but that was not observed.
- **B2, a `parallel` that exists but cannot run** (perl missing or broken). Not constructed. Expected to fail closed through the count validator, not observed.
- **B1, SIGHUP (terminal closed) during a large-N probe.** Not run. Group delivery should kill the dummies as SIGINT did (P5). parallel's own HUP handler (`start_no_new_jobs`, `/usr/bin/parallel:5364`) does not interrupt the probe loop, so the orphan behaviour of P4 may recur.

Because of these, neither guardrail appears in Endorsement Claims as a guardrail. The claims below cover properties, not bypass-resistance.

## Endorsement Claims

- **Claim:** Under `--jobs 2 --no-parallelize-within-files`, the runner's lock descriptor (fd 9) is inherited by every test process that `parallel` starts, so the lock covers every process that can write the run log.
  **Location:** `scripts/run-tests.sh:209-215`, `scripts/run-tests.sh:410-413`
  **Evidence:** executed
  **Verified:** P1: with fd 9 open on a lock file, `ls -l /proc/self/fd` inside each test of two files run through `parallel` shows `9 -> …/lock`. P4 shows the lock still held while `parallel` alone survives.
  **Not verified:** the same inheritance through the real runner's `exec bats` with a full suite. P1 used bats directly, and P4 used a runner copy with 2 fixture files.
  **route: code-fact-check**

- **Claim:** File paths handed to `parallel` as `{}` are shell-quoted, so metacharacters in a test file's name do not execute.
  **Location:** `scripts/run-tests.sh:413` (paths flow to `/usr/libexec/bats-core/bats-exec-suite:420`)
  **Evidence:** executed
  **Verified:** P7: files named with `$(…)`, backticks, `;`, single and double quotes ran as tests, and no `INJ*` side-effect file appeared.
  **Not verified:** names containing a newline, which `find … -print0` in the runner would pass but which bats' own file list handling may split. Not constructed.

- **Claim:** The `--jobs` validator admits only ASCII strings `[1-9][0-9]*` before any lock, log or bats step, in both the pinned and the ambient locale.
  **Location:** `scripts/run-tests.sh:124-132`
  **Evidence:** executed
  **Verified:** P6 (7 malformed values, 2 locales, exit 2 each) plus fact-check E6.
  **Not verified:** the upper bound, which the validator does not have (Finding 1).

- **Claim:** parallel's per-job output buffer holds test output in an unlinked file of mode 600 under `$TMPDIR`.
  **Location:** (behaviour of `/usr/bin/parallel` reached via `scripts/run-tests.sh:392`)
  **Evidence:** executed
  **Verified:** P1: `stat -L /proc/self/fd/3` inside a test reports `600 regular empty file`, and the link target is `/tmp/par….par (deleted)`.
  **Not verified:** the mode under a umask other than this session's default.

- **Claim (scoped prose, no rubric row):** the new test helper `parallel_shim` interpolates `$T` and `command -v parallel` into a generated script inside single quotes. It breaks only if the test tmpdir path contains a `'`, which is test-only, deploy-time input (S5). **Evidence:** read-static. **Verified:** `test/scripts/run-tests.bats:331-341`. **Not verified:** a run with a quote in `TMPDIR`.

## Primitive sweep

Primitive: process exec / shell command construction

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/run-tests.sh:413` `exec bats "${bats_args[@]}" "${files[@]}"` | S1, S4 | array expansion, no shell; S1 digits-only | cleared — no word splitting; the magnitude of S1 is Finding 1 |
| `/usr/libexec/bats-core/bats-exec-suite:420` `parallel … bats-exec-file "$(printf "%q " flags)" "{}" … ::: files` (reached only via `:392`) | S1, S2, S3, S4 | `%q` on flags; parallel quotes `{}` | S4 cleared (P7); S2 cleared (trusted PATH); S3 is Finding 2; S1 is Finding 1 |
| `/usr/bin/parallel:7901` `exec 'sleep', 10101` (slot probe, once per requested slot) | S1 | none (bounded only by N and system limits) | Finding 1 |
| `scripts/run-tests.sh:391` `command -v parallel` | S2 | — | cleared — lookup only, no exec |
| `test/scripts/run-tests.bats:335-337` generated shim script (`exec '$real' "$@"`) | S5 | single quotes | cleared — test-only, deploy-time source |
| `test/scripts/run-tests.bats:437-439` `bash -c 'command -v parallel \|\| bash "$1" …' _ "$T/scripts/run-tests.sh"` | S5 | positional `$1`, not interpolated | cleared |
| `test/scripts/run-tests.bats:433` `ln -s "$f" "$bin/${f##*/}"` over `$PATH` entries | S2 | writes only under `$BATS_TEST_TMPDIR` | cleared — test-only |

Primitive: echo of untrusted text to the terminal

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/run-tests.sh:126` `echo "--jobs takes a positive integer, got: ${2:-(nothing)}" >&2` | S1 (raw, pre-validation) | none | cleared — the text returns to the same party that typed it |
| `scripts/run-tests.sh:394` `echo "WARNING: --jobs $jobs …"` | S1 (validated) | regex | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Unbounded `--jobs N`: parallel's slot probe forks up to N `sleep 10101` dummies; under TERM it orphans at ~100% CPU and it and its dummies hold the run lock (up to ~2.8 h) | Low | B1 | `scripts/run-tests.sh:124-132`, `:390-392` | High |
| 2 | parallel's ambient config (`PARALLEL`, `~/.parallel/config`, `PARALLEL_HOME`) reaches `--jobs` runs unscrubbed; fails closed in every case probed | Informational | B3 | `scripts/run-tests.sh:390-392` | High |

## Overall Assessment

The change adds no exploitable surface. Its only new inputs are an argument from the party that already runs the suite and an executable resolved from that party's own PATH, and the paths it hands `parallel` are quoted (P7). The lock-and-log invariant the header relies on holds under `parallel`, because fd 9 reaches every test process (P1). The one defect worth fixing before merge is Finding 1: `--jobs` has no upper bound, and GNU parallel turns a large N into N forked processes. Under the TERM-based kill that agents' `timeout` wrappers deliver, the process then outlives the runner and holds this checkout's run lock for hours (P4). The fix is a one-line clamp to the file count, in place, and it also removes the fact-check's overflow-wrap residue. Finding 2 is optional hardening. No findings within the code paths read; the endorsement claims are executed but marked `route: code-fact-check` where they could anchor a rubric row, pending that intake's verdict.

Fact-check cross-reference: Claim 3 (Incorrect) says install-host.bats' /proc scan is exposed to concurrent processes from other files under `--jobs`. I checked whether that exposure is a security weakening. It is not: `procs_in_checkout` refuses on `kind=unknown` (`devcontainer-config/install.sh:1157-1161`: "An unreadable cwd is refused, not skipped"), so extra concurrent processes can only make it refuse more, which is a flake. It never lets it proceed past a live agent. That is a correctness and performance concern for the other critics, not a finding here. Claims 6, 9, 12, 17 and 22 (Mostly accurate) concern output mechanics and test naming and have no security implication.

## Goal-Alignment Note

- Success criterion (restated verbatim): "a markdown report saved at the path named below, structured per the skill."
- Answered: yes. The report is saved at `docs/reviews/q090-security-review-2026-09-30.md` with Trust Boundary Map, source table, findings, untested bypass candidates, endorsement claims, primitive sweep, summary and assessment.
- Relevance to the user goal (land `--jobs N` after a clean review-fix loop): Finding 1 is a small in-place fix (clamp N) that the loop can close in one pass. Finding 2 is optional. Nothing here blocks the design.
- Out of scope, per the brief: running the full suite or install-host.bats under `--jobs` (the run lock is held by a timing measurement); non-GNU `parallel` behaviour (not installed).
- Decisions I made: rated Finding 1 Low, not Medium, because its trigger is the invoking user or agent, which fails the floor rule's reachable-attacker bar. The lock-held-for-hours consequence was observed, so Confidence is High. The probes created and then cleaned up processes under this uid. All were killed by explicit PID (including 1009 orphaned `sleep 10101` dummies from P3, filtered to ppid 1 and `cmd == "sleep 10101"`), and none remain.
