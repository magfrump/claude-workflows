Commit: 3c1cae3

# U1 iteration-3 review: final confirming pass (`feat/u1-run-tests`, full branch vs main)

**Replication:** k=1 (final confirming pass, decision 031)

Scope: the full branch diff vs `main` (`scripts/run-tests.sh`, `test/lib/hermetic-env.bash`,
`test/scripts/run-tests.bats`, `test/skills/eval-helpers-gating.bats`, `.gitignore`, the three
`docs/reviews/override-log.md` rows, and both fix commit messages), with priority on the
iteration-3 delta `07db4c0..3c1cae3`. This is a combined correctness + code-fact-check pass. The
bats 1.8.2 sources (`/usr/libexec/bats-core/bats`, `bats-exec-suite`, `bats-exec-test`,
`bats-preprocess`) were read for run-log naming, `--count`, `--filter-status` carry-over and the
skip/teardown behaviour. `scripts/health-check.sh` gate 5 was read.

**Evidence** (session scratchpad `/tmp/claude-1000/-workspace/fe8d5f41-d34b-4387-9352-6d6b13c2ada9/scratchpad/`):

- `iter3-logs/suite.txt`: `LC_ALL=C.UTF-8 timeout 600 bats test/scripts/run-tests.bats
  test/skills/eval-helpers-gating.bats test/fixture-hermeticity.bats`, cwd = worktree,
  2026-09-28T19:46:14Z, **exit 0, 27/27 ok**. `git status` clean afterwards.
- `iter3-fast.out`: the real runner, `run-tests.sh --fast`, in a `git archive` copy of 3c1cae3
  (`iter3copy/`): **rc=0, `1..1179`**, `.bats/last-run` `expected=1179` (matches), lock free
  immediately after bats exited (no test leaks a process that holds fd 9). A following
  `--failed --fast` accepted the log and said "nothing to re-run (… 58 file(s))", rc=0.
- `bats --count` of all 2,148 tests in the copy: 14.0 s wall (9.6 s user).
- Probes in a throwaway repo `iter3probe/` (copies of the runner, `runner-contract.bash`,
  `hermetic-env.bash`; fixture suites `a.bats` fast, `b.bats` slow, each with one test that fails
  until a marker file exists), all under `timeout`. A `date` shim forced same-second runs. Every
  process started was reaped or killed; a final `ps` check was clean.

**Verdict:** every iteration-2 finding is resolved; the `exec` + sidecar + lock design holds up
under the probes (killed runs, `--failed` runs killed before any test, setup_file failure, parse
error, same-second runs, concurrent runs, read-only lock, real fast suite). One new false-green path
remains, reachable through the documented narrowing flow (**N1, Must Address, blocks merge**), plus
a process gap in the override log (**N2**) and five Considers.

**Counts:** Must Fix 0 · Must Address 2 · Consider 5.

---

## Part A: iteration-2 findings (and iteration-1 leftovers), resolved or open

| Item | Status | Evidence |
|---|---|---|
| **F1** (`--failed` false green after setup_file failure / parse error) | **Resolved** (teardown_file residual documented) | `.bats/last-run` holds `bats --count`; `--failed` requires that many distinct result lines. Suite test "--failed refuses the log of a run whose setup_file failed" passes (`recorded 1 of 2 tests`). Parse error probed: `expected=4`, log held 2 → `--failed` rc=1 "recorded 2 of 4 tests". bats gathers the run's own test list with the same `bats-preprocess` pass `--count` uses (`bats-exec-suite:111-181`), so the count is exactly bats' `1..N`, and a skipped test writes a `passed` line (`bats-exec-test:182-186`). Residual: failing `teardown_file` → `--failed` rc=0 "nothing to re-run" (probed), documented as a known limit in the header; no override-log row, see N2. |
| **F2** (overlapping runs mark the wrong log) | **Resolved** | No marks any more; `flock -n` on `.bats/lock` before `--failed` reads anything (`run-tests.sh:161-176`). Suite test "a run while another holds the lock exits 1 and runs nothing" passes; a background `--failed` race probe got "another run-tests.sh run is in progress", rc=1. |
| **F3** (repeated signal ends wait loop) | **Resolved** by construction | `exec bats` again (`:361`); no traps, no child. |
| **F4** (file symlink leads out of `test/`) | **Resolved** | `realpath -e` (`:128`), compared to `realpath -e $TEST_DIR`; test "FILE: a directory or file symlink out of test/ is rejected" covers `flink.bats`. Full-run `find` still includes such a symlink; the commit Notes say so. |
| **F5** (SIGPIPE 141 with ~2,300 logs) | **Resolved** | `newest_log` uses `sort -r | sed -n 1p` (`:150-153`). C7 row trigger now "revisit if log count breaks or slows `--failed`". |
| **K1** (trap windows, stamps) | **Resolved** by construction | No traps or stamps. |
| **K2** (runner-only INT leaves run unmarked) | **Resolved** by construction | No marks. |
| **K3** (locale default in `runner()`, `..` escape) | **Resolved** | `WORKING_LOCALE` via `locale_installed` (`run-tests.bats:12-14`); `test/../outside.bats` asserted (`:167-169`). |
| **K4** (test names overclaim) | **Resolved** | "…killed partway" (TERM claim dropped); "directory or file symlink"; "…runs once, also after --" (now claims only that). |
| **K5** (`set -e` overrides status in marking tail) | **Resolved** by construction | No tail after `exec`. |
| **C3** leftover (file symlink) | **Resolved** | Same as F4. |
| **C10** leftover (`..` escape, locale default) | **Resolved** | Same as K3. |

**Tally:** 12 resolved, 0 open (F1 carries a documented teardown_file residual). C5, C7, C9 are in
the override log and not re-raised.

---

## Part B: new findings

### Must Address

#### N1. A narrowed `--failed` run shrinks the recorded scope; the next `--failed` exits 0 with a suite still red [probed] — **blocks merge**

**Location:** `scripts/run-tests.sh:349-357` (last-run written with the *kept* files of a `--failed`
run), `:300-318` (filter), header "Flags: --failed" ("Combines with the category flags and FILE...
to narrow further").

**Scenario:** a full run fails in `a.bats` and `b.bats`. The user fixes `a` and checks it with
`run-tests.sh --failed test/a.bats` (or `--failed --fast`, as the header invites). That run writes
`.bats/last-run` with `a.bats` only, and bats' new log holds only `a`'s lines: bats carries over
earlier `status-filtered` lines, but never earlier `failed` lines for files outside the run
(`bats-exec-suite:237-274`). The next `run-tests.sh --failed` then accepts that log (count
matches), finds no failure in its one file, prints "no failed tests among the selected files in
the last recorded run (…, 1 file(s)); nothing to re-run" and **exits 0**, while `b2` is still red.
Probe (`iter3probe`):

```
full run                         rc=1   (a2, b2 fail)
touch fixa; --failed test/a.bats rc=0   1..1  ok 1 a2
--failed                         rc=0   --failed: no failed tests among the selected files in the
                                        last recorded run (… 19:42:18 UTC.log, 1 file(s)); nothing to re-run
```

bats' own `--filter-status failed` would re-run `b` here (no `passed` line → "not passed"), so the
runner's pre-filter is again stricter than bats. This is the C1 class (scope = last run), but
reached through the tool's own re-run flow rather than an unrelated run, and the header advertises
the narrowing without saying it narrows every later `--failed`. A user following the docs
(`--failed --fast`, then `--failed --slow`) gets a wrong green.

**Fix (any one):**
- Record `narrowed=1` in `.bats/last-run` when a `--failed` run's selection leaves out files that
  have `failed` lines in the log it read; a later `--failed` that would print "nothing to re-run"
  exits 1 instead, naming the failing files outside the scope ("run --failed without FILE/category,
  or the full selection").
- Or, in the narrowed case, print those files before the exec and add a header sentence: "a
  `--failed` run narrowed by FILE or category becomes the new scope; failures outside it are no
  longer seen by `--failed`." (Documentation-only; weaker, but removes the "following the docs"
  trap.)
- Add a test: full run red in two files, `--failed <one>`, then `--failed` must not exit 0.

#### N2. The declined part of F1 has no override-log row — **does not block merge**

**Location:** `docs/reviews/override-log.md`; F1's fix item 2 (teardown_file) and the F4 remark on
the full-run `find`.

F1 (Must Fix) proposed three fixes; item 2 (detect a failing `teardown_file`) was not done and is
recorded only as a header "Known limit" and in the commit body. pr-prep step 3b requires a row for
every declined finding (the commit body "is not a substitute"). Probed: `teardown_file() { false; }`
→ run rc=1, next `--failed` rc=0 "nothing to re-run". Add a row (Must Fix → Won't-Fix/Defer,
reason: undetectable from the log under `exec`; documented in the header; revisit trigger e.g. "a
suite gains a teardown_file that can fail"). Not blocking: the limit is documented where the user
reads it.

### Consider

#### K6. A process a test leaves running keeps the lock, and the message says "another run" [probed]
`@test "d1" { (sleep 7 >/dev/null 2>&1 3>&- 4>&- &); true; }` → the run ends rc=0, then the next two
runs exit 1 "another run-tests.sh run is in progress in this checkout" until the sleep exits. The
header describes this correctly ("held until bats and every process it started have exited"), and
the real fast suite leaks nothing (lock free right after), but health-check would report "Fast/Slow
BATS suites failed" with a misleading reason. Suggest: "…in progress (or a process a test started
still holds .bats/lock; see `fuser .bats/lock`)".

#### K7. Read-only `.bats/lock` is reported as an unwritable log directory [probed]
With `chmod 444 .bats/lock` (uid 1000) the runner prints "WARNING: cannot write
.bats/.bats/run-logs (or flock is missing)", although the log dir is writable. Behaviour is right
(runs unlocked, unrecorded); the message could say "cannot write .bats/ or its lock".

#### K8. The anchor moves bats' `setup_suite.bash` lookup to `.bats/` (latent)
bats looks for `setup_suite.bash` next to the first file (`bats:418-426`), which is now
`.bats/run-log-anchor`. No `test/setup_suite.bash` exists, so nothing breaks today; a future one
would be silently ignored by the runner (but used by plain `bats test/…`). Either pass
`--setup-suite-file test/setup_suite.bash` when it exists, or note it under "Run logs".

#### K9. A previously failing suite that report gating now drops is left out of `--failed` quietly
If a `@needs-reports` suite failed in the last run and its reports are then removed, `--failed`
lists it as NOT RUN and says "nothing to re-run", rc=0. The NOT RUN line makes this visible;
low priority.

#### K10. "about 10 s" for `bats --count`
Measured 14.0 s wall / 9.6 s user for 2,148 tests here. Machine-dependent; "about 10–15 s" is safer.

---

## Part C: code fact-check (full branch; delta first)

Hallucination-pattern log: `docs/reviews/hallucination-patterns.md` checked. The closest logged
patterns are stated test-count denominators in commit messages (59ca38f, 37c5ea9); this branch's
commit messages state no test counts, and every count in this report (27/27, `1..1179`, 2,148) was
measured here. No claim matches a logged pattern.

| # | Claim (location) | Verdict | Evidence |
|---|---|---|---|
| 1 | "bats 1.8.2 puts its run-log directory next to the FIRST file it is handed, and records nothing when that directory is missing" (header, Run logs) | Accurate | `bats-exec-suite:184-196`: `TEST_ROOT=${1%/*}`; missing dir → `BATS_RUNLOG_FILE=/dev/null`. |
| 2 | "the log then lands in .bats/.bats/run-logs/ whatever the selection" | Accurate | Test "a run whose first file is in a subdirectory still records its log under .bats/" passes. |
| 3 | "The runner then execs bats, so bats' exit status and signal handling are the runner's own." | Accurate | `:361` `exec bats`; test asserts rc=1 passthrough and rc=143 under TERM. |
| 4 | "writes .bats/last-run: the selected files, their test count (`bats --count`, which adds about 10 s to a full run) and the name of the newest log before the run" | Mostly accurate | Contents verified (`expected=`, `prev-log=`, files). Measured 14 s wall (K10). |
| 5 | "bats writes a log line per test as the test ends" | Accurate | `bats-exec-test:186` in the exit trap (retries write only the final try). |
| 6 | "--failed accepts the newest log (the one bats' own --filter-status reads)" | Mostly accurate | bats takes the first of `ls -1r` (any entry); runner takes the first `*.log` by `sort -r`. Same file unless a non-log file sorts above. |
| 7 | "…only when it is not that previous log and holds a result (passed, failed or status-filtered) for exactly that many of the selected files' tests" | Accurate | `:192-209`; distinct `file\tid` via `sort -u`. |
| 8 | "A log falls short when the run was killed, is still going, a setup_file failed or a file did not parse" | Accurate | Killed (suite test), setup_file (suite test), parse error (probe: 2 of 4). "Still going" cannot be read under the lock; harmless. |
| 9 | "It is no newer log when the run was killed before any test ended, or started in the same UTC second as the run before it" | Mostly accurate | True for a plain run. A `--failed` run killed before any test ended does leave a new log (its `status-filtered` lines, written up front) and is refused by the count check instead (probed: "recorded 1 of 2"). Outcome the same. |
| 10 | "a run in the same second appends to that log or, with --failed, writes "<time>-1.log", which ranks below "<time>.log"" | Accurate | Date-shim probes: same-second plain run shared the log; same-second `--failed` wrote `…UTC-1.log`; both refused with the "left no log of its own" message. |
| 11 | "Known limit: a failing teardown_file leaves every test's line in place, so --failed then says there is nothing to re-run although the run failed." | Accurate | Probed (rc=1, then `--failed` rc=0). |
| 12 | "bats deletes the log of a Ctrl-C run itself." | Accurate | `bats-exec-suite:354-358` (when `BATS_INTERRUPTED`). |
| 13 | "the runner takes an flock on .bats/lock before reading or writing any of this" | Mostly accurate | Lock precedes every read/write of `last-run` and the logs; `mkdir -p` and the anchor truncation happen just before it (harmless). |
| 14 | "bats inherits the lock's descriptor, so it is held until bats and every process it started have exited. A second run meanwhile exits 1." | Accurate | fd 9 visible in test processes (probe); leaked background process held it (K6). |
| 15 | "When .bats/ cannot be written (or flock is missing), the runner warns and runs without the lock or recording, and --failed exits 1." | Accurate | Suite test (`.bats` as a file); read-only lock also degrades this way (K7 wording). |
| 16 | "--failed … Exits 1 when no run is recorded or the last run's log does not hold a result for every test it selected; 0 with a message naming the last run's scope when it had no failures among the selected files." (Flags) | Mostly accurate | True as stated; the exit-0 branch is also reached when a narrowed `--failed` hid failures outside its scope (N1) and after a failing teardown_file (documented). |
| 17 | "Combines with the category flags and FILE... to narrow further." | Mostly accurate | Narrows this run correctly; omits that it also narrows later `--failed` runs (N1). |
| 18 | "FILE… each must be under test/ once every symlink in its path, the file's own included, is resolved. A file named twice runs once." | Accurate | `realpath -e`; tests for dir/file symlink, `..`, duplicates. |
| 19 | "`sed -n 1p` reads all of its input, so a long listing cannot SIGPIPE sort under pipefail (`head -n1` did)" | Accurate | Consistent with iter-2 P2; `sed -n 1p` reads to EOF. |
| 20 | "bats may repeat a status-filtered line, and carries over ones for files outside this run" | Accurate | `bats-exec-suite:262-274` writes filtered lines in the loop and again for `last_filtered_tests` from all files. |
| 21 | "Its log holds a line for every test of every file it covered (checked above) … So "has a failed line" is exactly bats' "did not pass"." | Mostly accurate | True for covered files; teardown_file residual (documented) aside. |
| 22 | ".gitignore: bats run logs and the runner's log anchor … --failed reads them" | Mostly accurate | `.bats/` now also holds `last-run` and `lock`; the ignore rule covers them. |
| 23 | hermetic-env: "scripts/run-tests.sh also sources this file for `locale_installed`" | Accurate | `run-tests.sh:88-89`. |
| 24 | test comment: "A TERM to timeout reaches its whole process group, so bats' children end too and the run lock is released." (`run-tests.bats:75-78`) | Accurate | `wait_unlocked` succeeds after the kill in both lock tests (suite passes). |
| 25 | test comment: "bats names logs by the second, so two runs within one second would share (or misorder) a log" | Accurate | Same as claim 10. |
| 26 | test names (all 21 in `run-tests.bats`) | Accurate | Each body checked against its name; K4 overclaims gone. |
| 27 | commit 3c1cae3: "removes F3, K1, K2 and K5 by construction; exit status and signals are bats' own" | Accurate | Code has no traps/child/marks. |
| 28 | commit 3c1cae3: "A killed run, a setup_file failure or a parse error falls short and is refused. A failing teardown_file is not detectable from the log" | Accurate | Probed each. |
| 29 | commit 3c1cae3: "the lock lasts until bats and its children exit. A second run exits 1." | Accurate | As claim 14. |
| 30 | commit 3c1cae3 Notes: "`bats --count` adds ~10 s to a full run (measured on the whole suite)" | Mostly accurate | 14 s here (K10). |
| 31 | commit 3c1cae3 Notes: "also refuses a run started in the same UTC second as the previous one, which errs safe" | Accurate | Date-shim probe. |
| 32 | commit 07db4c0 (MA1 design: background child, completion mark, "passes its exit status through") | Accurate for 07db4c0, superseded | Replaced by 3c1cae3; commit is immutable, not re-raised. |
| 33 | override row C5: "`locale` is always in the devcontainer image" | Unverifiable (plausible) | `/usr/bin/locale` present in this sandbox; image contents not checked. |
| 34 | override row C7: "Logs are a few lines per test" | Mostly accurate | One line per test (plus status-filtered repeats). |
| 35 | override row C9: "the runner runs in the GNU/bash 5 devcontainer" | Accurate | GNU `find -printf`, `realpath -e`, `flock` all present. |

**Verdict counts:** Accurate 24 · Mostly accurate 10 · Inaccurate 0 · Unverifiable 1.

### Claims requiring attention
- Claims 16/17 (Mostly accurate): fix with N1.
- Claim 4/30: "about 10 s" → "about 10–15 s" (optional).

### health-check.sh compatibility
Gate 5 calls `run-tests.sh --fast`, then `--slow`, sequentially, with `RUN_TESTS_NOT_RUN_FILE`
and `HEALTH_CHECK_SKIP_BATS=1`. The first run's bats and children exit before the second starts,
so the lock is free (confirmed on the real fast suite). `RUN_TESTS_NOT_RUN_FILE` is still written
before the exec. No nested runner in the real checkout: `health-check.bats` runs health-check with
the skip set, and every other suite that runs the runner uses a copy in a temp repo (own lock).
The only way the gate breaks is K6 (a leaked process holding fd 9).

---

## Goal-Alignment Note
- **Answered:** (a) every iteration-2 finding (F1–F5, K1–K5) and the C3/C10 leftovers is resolved
  with evidence; (b) 35 claims verdicted across header, comments, messages, test names, commit
  messages and override rows; (c) the new design was probed for sidecar/log pairing (same second,
  `--failed` after `--failed`, differing FILE selection, `--count` vs executed count incl. skips and
  gating), lock inheritance/leaks, unwritable lock, `realpath`, exit passthrough and health-check.
  Required suites: 27/27 ok.
- **Out of scope:** `--filter` is not a runner flag, so `--count` vs `--filter` does not arise;
  confine-tests (bwrap read-only rootfs) could not be run in this container.
- **Escalate:** N1 is the one blocker. Merge is safe once it is fixed or, at minimum, documented in
  the header and the "nothing to re-run" path (the author's call, as for C1); N2 is a one-row
  override-log addition.
