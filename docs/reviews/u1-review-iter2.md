Commit: 07db4c0

# U1 iteration-2 review: fix commit c2322a2..07db4c0 (`scripts/run-tests.sh`)

**Replication:** k=1 (loop pass, decision 031)

Branch `feat/u1-run-tests`. Scope: the delta `c2322a2..07db4c0` (`scripts/run-tests.sh`,
`test/lib/hermetic-env.bash`, `test/scripts/run-tests.bats`, commit message). Full files were read
in the worktree. The bats 1.8.2 sources (`/usr/libexec/bats-core/bats`, `bats-exec-suite`) were
read for the signal and run-log behaviour. This is a combined correctness + code-fact-check pass.

**Evidence files** (outside the worktree, in the session scratchpad
`/tmp/claude-1000/-workspace/fe8d5f41-d34b-4387-9352-6d6b13c2ada9/scratchpad/wt/iter2-logs/`):

- `suite.txt`: `LC_ALL=C.UTF-8 timeout 300 bats test/scripts/run-tests.bats test/skills/eval-helpers-gating.bats`,
  cwd = worktree, 2026-09-28T19:16:57Z, **exit 0, 23/23 ok**. `git status` was clean afterwards, and
  no bats/sleep processes were left behind.
- `probes.txt` (2026-09-28T19:23:33Z) and `probes2.txt` (2026-09-28T19:24:39Z): probes P1–P10, run
  in a throwaway repo `scratchpad/iter2probe` holding copies of the runner at 07db4c0
  (`run-tests.sh`) and at c2322a2 (`run-tests-old.sh`, the `exec bats` version), under
  `LC_ALL=C.UTF-8`. Every process I started was reaped or killed, and a final `ps` check was empty.

**Verdict:** the MA1 killed-run case is fixed and tested. But the same false green ("nothing to
re-run", exit 0 after a red run) is still reachable in two ways: a suite whose `setup_file` fails or
that does not parse (**Must Fix F1**), and two runs overlapping in one checkout (**Must Address F2**).
The new background-child design also has a signal-loop bug (**F3**). There is also a false
symlink-confinement claim (**F4**), and a latent SIGPIPE exit in the `--failed` log pick that the
C7 decline makes certain to fire eventually (**F5**).

**Counts:** Must Fix 1 · Must Address 4 · Consider 5.

---

## Part A: iteration-1 findings, resolved or open

| Item | Status | Evidence |
|---|---|---|
| Critic **MA1** (false green after a killed run) | **Resolved** (for kill/timeout/TERM) | `run-tests.sh:152-156` refuses a last log without `# run-tests: complete`. Suite test 17 ("--failed refuses the log of a run killed partway") passes (`suite.txt`, `ok 17`). The *class* is not closed: see F1 (setup_file/parse failure) and F2 (concurrent runs), both reproduced. |
| **C1** (scope of `--failed` unclear in "nothing to re-run") | **Resolved** | `run-tests.sh:274` now prints `($last_log, $last_scope file(s))`. Tests 13/14 assert it. |
| **C2** (same-second log naming) | **Resolved** (documented) | Header `:47-50`. Verified: two runs in one second shared a log (probe during setup; claim 8 below). |
| **C3** (symlink escape / alias paths) | **Partly open** | Directory symlinks and alias repo paths are fixed (`pwd -P` at `:61`, `:124`; test 8; probe P6). A **file** symlink in `test/` still escapes: see F4 / P4. |
| **C4** (duplicate FILE args) | **Resolved** | `seen[]` at `:110`, `:129-130`; test 9 (`1..1` for three spellings). |
| **C6** (unwritable repo root aborts) | **Resolved** | `:300-310` warns and runs without the anchor; `--failed` errors instead. Test 12. |
| **C8** (FILE relative to repo root) | **Resolved** (by documentation, the "or document" option) | Header `:32-33` "relative to the repo root, NOT the current directory". Not in override-log, but the fix option was taken. |
| **C10** (test gaps) | **Partly open** | Added: spaces (test 10, plus a spaced repo root for every test), duplicates and `--` (9), symlink (8), partial log (17). Still missing: a `..` escape out of `test/` (`test/../x.bats`; test 9's `..` stays inside `test/`). The locale bullet is only half done: test 1 now skips without C.UTF-8, but `runner()` (`run-tests.bats:69-71`) still hardcodes `LC_ALL=C.UTF-8`, so test 3 ("a working locale is left alone") still fails on a host without C.UTF-8. See Consider K3. |
| Fact-check **claim 4** ("failed" vs "did not pass") | **Resolved** (wording) | Header `:26-27` says "did not pass". The new wording is itself Incorrect in the F1 case: see claim 1 below. |
| Fact-check **claim 6** (gated selection skips the no-log check) | **Resolved** | The check moved before gating (`:143-158`). Test 16 passes. |
| Fact-check **claim 15** (glibc normalisation) | **Resolved** | `hermetic-env.bash:43-47` now says "simplified form" and names the `iso` prefix. |
| Fact-check **claim 16** (`locale_installed` equivalence) | **Resolved** | `hermetic-env.bash:65-69` now says "should not" and lists the over-reporting cases. One residual nuance is in claim 20 below. |
| Fact-check **claim 24** (vacuous log-location test) | **Resolved** | Renamed test 11 now asserts `passed …/sub/beta.bats` and the completion mark. |

**Tally:** 11 resolved, 2 partly open (C3, C10). C5, C7 and C9 were declined in the override log
and are not re-raised. F5 does bear on the C7 row's stated revisit trigger, as noted there.

---

## Part B: new findings

### Must Fix

#### F1. `--failed` gives a false green after a suite fails in `setup_file` or does not parse [probed P1]

**Location:** `scripts/run-tests.sh:257-272` (filter and its comment), header `:26-27`. The claim is
repeated in the commit message.

**Scenario:** when a suite's `setup_file` fails, or the file has a syntax error, bats prints
`not ok N setup_file failed` and exits 1 on its own. It writes **no** `passed`/`failed` line for
that file's tests. The runner sees a normal exit and appends the completion mark. The next
`--failed` keeps only files that have a `failed` line, drops the red suite, prints
"nothing to re-run" and **exits 0**. P1 (`probes.txt`):

```
not ok 2 setup_file failed
rc=1
passed …/test/b.bats	test_b_pass
# run-tests: complete files=2
--failed: no failed tests among the selected files in the last recorded run (… UTC.log, 2 file(s)); nothing to re-run
rc=0
```

The same happens for a parse error (`@test "e2" { exit 0` with no closing brace; probed, same
output). A failing `teardown_file` (all tests `passed`, bats exit 1) also yields exit 0. bats' own
`--filter-status failed` would re-run the setup_file/parse-error tests, because they are "not
passed" (`bats-exec-suite:206-208`). So the runner's file pre-filter is stricter than bats and
hides them. This is the MA1 false green reached without killing anything. The `:257-261` comment
("each test of each file it covered has a line") is what makes it look safe.

**Fix:**
1. Keep a file when the log has a `failed` line for it **or has no `passed` line for it** (the
   first option from iteration 1). This covers setup_file and parse failures.
2. Record bats' status in the mark (`# run-tests: complete files=<n> status=<s>`). When the
   last run's status was nonzero but nothing survives the filter, exit 1 with "the last run failed
   outside any test (setup_file/teardown_file/parse error); re-run without --failed". This covers
   teardown_file.
3. Add a fixture test with `setup_file() { false; }` asserting that `--failed` does not exit 0.

### Must Address

#### F2. Overlapping runs: the completion mark goes on the wrong log, and a killed run's partial log reads as complete [probed P5]

**Location:** `scripts/run-tests.sh:350-352` (log pick), `:298-299` (stamp comment), header `:43-46`.

**Scenario:** the runner marks "the newest `*.log` modified after my stamp". If a second run B
started in a later second is still writing, B's log is usually the newest. Run A's mark then lands
in **B's** log, and A's own log stays unmarked. If B is then killed (timeout/TERM) before writing
another line, B's partial log ends with A's mark. `--failed` accepts it and exits 0. P5
(`probes2.txt`):

```
== …19:24:39 UTC.log          (run A, completed: no mark)
passed …/ca.bats	test_ca1
== …19:24:40 UTC.log          (run B, killed after 4 of 12 tests)
passed …/cb.bats	test_cb1 … test_cb4
# run-tests: complete files=1
--failed: no failed tests among the selected files … nothing to re-run
--failed rc=0
```

This needs two runs in one checkout (for example, a developer's `run-tests.sh test/x.bats` while
health-check runs in another terminal). Parallel worktrees each have their own `.bats/`, so they
are not affected. The header documents same-second sharing but not this case. It defeats MA1's
guarantee.

**Fix (either):**
- Serialise runs with `flock` on `.bats/run.lock` around the bats child. A second run waits, or
  fails with "another run is in progress".
- Or pick the log by name and content: record `date -u '+%Y-%m-%d %H:%M:%S UTC'` before launch,
  consider only logs whose name is at or after it, and require a `passed|failed|status-filtered`
  line for one of `"${files[@]}"`. Don't mark when more than one log qualifies.

Either way, add a sentence on concurrent runs to the "Run logs" header.

#### F3. A repeated signal of the same kind ends the wait loop while bats is still running [probed P9/P10]

**Location:** `scripts/run-tests.sh:335-342`

**Scenario:** the loop re-waits only when `$signalled` *changed* during the `wait`
(`[[ "$signalled" != "$interrupted" ]] || break`). A second INT (or TERM/HUP) repeats the same
name, so the loop breaks. The runner then exits with `wait`'s 128+n while bats is still running.

A plain `kill -INT <runner>` is forwarded to the top-level bats. There it only sets a flag
(`bats:454`), so bats keeps running. A second `kill -INT` then ends the runner. P10: the new
runner returned **rc=130 after 1 s**, and the orphaned bats printed `ok 1..3` into the output
file after that. P9: the old `exec` runner returned **rc=0 after 8 s**, once bats had finished.

At a terminal, pressing Ctrl-C twice while bats winds down (teardown, the suite exit trap) does the
same: the prompt returns while bats is still printing. The caller also gets 130, not bats' status.
The commit message's "passes its exit status through" is false in this case.

**Fix:** loop on liveness instead of on the signal name. A zombie still answers `kill -0`, so the
next `wait` reaps it and returns the real status:

```bash
while :; do
  status=0
  wait "$bats_pid" || status=$?
  kill -0 "$bats_pid" 2>/dev/null || break   # still running (or unreaped): wait again
done
```

Bash 5.2 returns the saved status for a second `wait` on a reaped pid (probed: `(exit 3) & wait;
wait` → 3, 3), so this loop has no status race either.

#### F4. A file-level symlink in `test/` still leads out of `test/`; the header and comment say it cannot [probed P4]

**Location:** `scripts/run-tests.sh:122-124`, header `:33-34`

**Scenario:** `path="$(cd "$(dirname "$path")" && pwd -P)/$(basename "$path")"` resolves only the
directory. With `test/flink.bats -> /elsewhere/x.bats`, `run-tests.sh test/flink.bats` passes the
confinement check and runs the outside suite (P4: `ok 1 outside ran`, rc=0). This makes the
comment "so a symlink cannot lead out of test/" and the header "each must be under test/, after
resolving symlinks" Incorrect. Test 8 covers only a directory symlink.

This is not a security issue (developer-controlled input). The finding is Must Address because the
documented guarantee is false. Note that the full-run `find "$TEST_DIR" -name '*.bats'` also picks
up such a symlink.

**Fix:** use `path="$(realpath -e -- "$path")"` (GNU, like the rest of the runner) and then run the
`$TEST_DIR/*` check. Or narrow both texts to "directory symlinks". Extend test 8 with a file
symlink.

#### F5. `--failed` exits 141 silently once the log directory holds about 2,300 logs (SIGPIPE under `pipefail`) [probed P2]

**Location:** `scripts/run-tests.sh:146`

**Scenario:** `last_log="$(find … -printf '%f\n' | sort -r | head -n1)"`. `head` exits after one
line. Once `sort`'s output exceeds the 64 KiB pipe buffer (log names are about 28 bytes, so
roughly 2,300 logs), `sort` gets SIGPIPE. `pipefail` makes the substitution fail, and `set -e`
ends the runner with **status 141 and no message**, on every `--failed` from then on. P2 (3,000
logs): `rc=141`, with no output.

Logs are never pruned (C7, Won't-Fix), and each health-check adds up to two. So this is a matter
of when, not if. The pipeline was already there in c2322a2; this delta moved it. It is flagged now
because the C7 override row's revisit trigger ("if the directory listing ever slows `--failed`")
assumes a slowdown, not a hard failure.

**Fix:** use a consumer that reads all of its input, for example `sort -r | sed -n 1p` (or
`awk 'NR==1'`). Alternatively, prune logs to the newest N after marking, which reopens C7. Update
the C7 override row's trigger either way.

### Consider

#### K1. Signal windows around the traps, and leaked start stamps
**Location:** `scripts/run-tests.sh:325-334`, `:343-354`
- The traps are installed *after* `bats … &`. A TERM/HUP in that window kills the runner by
  default and leaves bats running unsupervised. Under `exec` this window did not exist. Fix: set
  the traps before the `&`, and have `forward` do nothing while `bats_pid` is empty.
- After `trap - INT TERM HUP` (`:343`), a signal kills the runner before `rm -f "$start_stamp"`.
  SIGKILL or OOM at any point does the same. Stray `.bats/run-start.*` files then pile up (they are
  harmless to `--failed`, which only lists `*.log`). Fix: add an EXIT trap that removes the stamp,
  or keep the stamp in `$TMPDIR` (`-newer` works across filesystems).
- Cosmetic: when `timeout` kills the run, the runner's bash prints a job-status `Terminated` line
  that the `exec` version did not print (seen in the `timeout 1` probe during investigation).

#### K2. An INT sent only to the runner leaves a completed run unmarked
**Location:** `scripts/run-tests.sh:349`
**Scenario:** `kill -INT <runner>` (not the process group) is forwarded to the top-level bats,
which only sets a flag (`bats:454`). The run finishes normally, and bats keeps its log. But
`signalled=INT`, so no mark is written, and the next `--failed` refuses a log that is actually
complete. This errs safe. Either document it ("a log is also left unmarked when the runner was
signalled"), or mark when `status < 128` and the log survived.

#### K3. C10 residue: the locale default in `runner()`, and the `..` escape
**Location:** `test/scripts/run-tests.bats:69-71`, `:97-102`
Test 3 ("a working locale is left alone") uses `runner` with the hardcoded `LC_ALL=C.UTF-8`, so it
fails where C.UTF-8 is not installed. Use `locale_installed C.UTF-8 || skip` there too, or pick the
working locale dynamically. No test covers `test/../outside.bats` (an escape via `..`). It is
correct today, since `cd` resolves `..`.

#### K4. Test names overclaim slightly
**Location:** `test/scripts/run-tests.bats` (tests 8, 9, 17)
- "…(and TERM stops bats)": TERM ends the top-level bats and the runner, but
  `bats-exec-suite`/`-file`/`-test` live on as orphans. The file's own teardown comment says this,
  and the P-probes showed the same as under `exec`. Suggested name: "(and TERM ends the runner)".
- "-- ends the flags" shows only that `--` is accepted. No flag-shaped argument follows it.
- "a symlink out of test/ is rejected" covers directory symlinks only (F4).

#### K5. set -e can override bats' status in the marking tail
**Location:** `scripts/run-tests.sh:350-352`
If `find` fails (for example, `.bats/` was removed mid-run) or the `>> "$log"` append fails, `set -e`
exits with that command's status, not bats'. The stamp is also not removed. This is an edge case.
Wrap the marking step in `{ …; } || true` so `exit "$status"` always runs.

---

## Part C: code fact-check of the delta

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `u1-run-tests`)
**Scope:** delta c2322a2..07db4c0: `scripts/run-tests.sh`, `test/lib/hermetic-env.bash`, `test/scripts/run-tests.bats`, commit message 07db4c0
**Checked:** 2026-09-28
**Total claims checked:** 31
**Summary:** 16 verified, 7 mostly accurate, 0 stale, 8 incorrect, 0 unverifiable

---

## Claim 1: "--failed  Re-run, in the files the last recorded run covered, only the tests that did not pass in it"

**Location:** `scripts/run-tests.sh:26-27`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the setup_file-failure and parse-error cases; does not dispute behaviour for files that have a `failed` line (where bats' "not passed" filter applies as stated).

A file whose tests have no line at all (setup_file failed, or the file did not parse) was covered
by the last run, and its tests did not pass, but it is not re-run. The filter keeps only files
with a failed line: `failed_files="$(grep '^failed ' "$RUN_LOG_DIR/$last_log" | …)"` and
`if grep -qxF "$f" <<< "$failed_files"; then` (`scripts/run-tests.sh:264-268`). Command:
`bash scripts/run-tests.sh test/b.bats test/c.bats; …; bash scripts/run-tests.sh --failed test/b.bats test/c.bats`,
cwd `scratchpad/iter2probe`, 2026-09-28T19:23:33Z. First run exit 1, then `--failed` exit 0 with "nothing to re-run".

**Evidence:** `scripts/run-tests.sh:257-276`, `/usr/libexec/bats-core/bats-exec-suite:206-208`, `iter2-logs/probes.txt` (P1)

---

## Claim 2: "Exits 1 when no run is recorded or the last run did not complete; 0 with a message naming the last run's scope when it had no failures among the selected files."

**Location:** `scripts/run-tests.sh:29-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three exits for sequential runs (suite tests 13-17); does not establish that "did not complete" is detected when runs overlap (F2) or after a setup_file failure (F1).

`echo "--failed: no recorded run …" >&2; exit 1` (`:149-150`), `echo "--failed: the last run ($last_log) did not complete …" >&2; exit 1` (`:154-155`),
and `echo "--failed: no failed tests … ($last_log, $last_scope file(s)); nothing to re-run"; exit 0` (`:274-275`).
Command `LC_ALL=C.UTF-8 timeout 300 bats test/scripts/run-tests.bats test/skills/eval-helpers-gating.bats`, cwd worktree, exit 0, 2026-09-28T19:16:57Z.

**Evidence:** `scripts/run-tests.sh:143-158`, `scripts/run-tests.sh:273-276`, `iter2-logs/suite.txt` (ok 13-17)

---

## Claim 3a: "relative to the repo root, NOT the current directory"

**Location:** `scripts/run-tests.sh:32-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how relative paths are resolved; does not cover symlink handling (3b).

`[[ "$path" == /* ]] || path="$REPO_ROOT/$path"` (`scripts/run-tests.sh:113`).

**Evidence:** `scripts/run-tests.sh:112-113`

---

## Claim 3b: "each must be under test/, after resolving symlinks"

**Location:** `scripts/run-tests.sh:33-34`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a file-level symlink; directory symlinks are resolved as claimed (test 8).

Only the directory is resolved: `path="$(cd "$(dirname "$path")" && pwd -P)/$(basename "$path")"` (`:124`).
Command `bash scripts/run-tests.sh test/flink.bats` with `test/flink.bats -> scratchpad/iter2else/x.bats`, cwd `iter2probe`, 2026-09-28T19:23:33Z: `ok 1 outside ran`, exit 0.

**Evidence:** `scripts/run-tests.sh:122-128`, `iter2-logs/probes.txt` (P4)

---

## Claim 4: "A file named twice runs once."

**Location:** `scripts/run-tests.sh:34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers repeats that resolve to the same physical path; does not cover two different in-tree symlink names for one file.

`[[ -n "${seen[$path]:-}" ]] && continue; seen[$path]=1` (`:129-130`). Suite test 9 passed: three spellings, `1..1`.

**Evidence:** `scripts/run-tests.sh:110-131`, `iter2-logs/suite.txt` (ok 9)

---

## Claim 5a: "When bats exits on its own (pass or fail), the runner appends "# run-tests: complete files=<n>" to the log it wrote" (sequential runs)

**Location:** `scripts/run-tests.sh:43-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one run at a time; does not cover overlapping runs (5b).

`log="$(find "$RUN_LOG_DIR" … -newer "$start_stamp" -printf '%T@ %p\n' | sort -rn | head -n1 | cut -d' ' -f2-)"`, then `echo "$COMPLETE_MARK${#files[@]}" >> "$log"` (`:350-352`). Suite test 11 asserts the mark is the last line.

**Evidence:** `scripts/run-tests.sh:345-355`, `iter2-logs/suite.txt` (ok 11)

---

## Claim 5b: "... to the log it wrote" (when runs overlap)

**Location:** `scripts/run-tests.sh:43-46`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two overlapping runs in one checkout; timing-dependent (reproduced twice).

The pick is "newest log modified after my stamp", which can be another run's log. P5: run A's mark
landed in run B's log. A's log was left unmarked, and B's killed, partial log was accepted by
`--failed` (exit 0). Commands are in `probes2.txt`, cwd `iter2probe`, 2026-09-28T19:24:39Z.

**Evidence:** `scripts/run-tests.sh:350-352`, `iter2-logs/probes2.txt` (P5)

---

## Claim 6: "a log without that last line is from a run that was killed or is still going, and --failed refuses it"

**Location:** `scripts/run-tests.sh:45-46`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal (`:152-156`); does not establish the "killed or still going" cause list as exhaustive.

The refusal is right: `if [[ "$last_line" != "$COMPLETE_MARK"* ]]; then … exit 1` (`:153-155`). A
completed run is also left unmarked when the runner was signalled but bats ran to the end:
`if [[ -z "$signalled" && "$status" -lt 128 ]]` (`:349`), with bats' INT handler being only
`trap 'BATS_INTERRUPTED=true' INT` (`/usr/libexec/bats-core/bats:454`). Precise version: "…killed,
still going, or the runner was signalled".

**Evidence:** `scripts/run-tests.sh:152-156`, `scripts/run-tests.sh:349`, `/usr/libexec/bats-core/bats:454`

---

## Claim 7: "bats deletes the log of a Ctrl-C run itself."

**Location:** `scripts/run-tests.sh:46-47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers SIGINT delivered to the whole process group (a terminal Ctrl-C); does not cover INT sent only to the runner (see claim 6).

`if [[ -d "$BATS_RUN_LOGS_DIRECTORY" && -n "${BATS_INTERRUPTED:-}" ]]; then … rm "$BATS_RUNLOG_FILE"` (`bats-exec-suite:355-357`).
P8 (`setsid` + `kill -INT -- -pgid`): `rc=1`, `logs: 0`, identical for the new and the old runner.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:351-358`, `iter2-logs/probes2.txt` (P8)

---

## Claim 8: "bats names logs by the UTC second: runs started in the same second share one log, or (with --failed) get "<time>-1.log", which both bats and the runner rank below "<time>.log""

**Location:** `scripts/run-tests.sh:47-50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers naming and the ranking under C/C.UTF-8 collation; does not establish the ranking under other LC_COLLATE (only C.UTF-8 is installed here).

`BATS_RUNLOG_DATE=$(date -u '+%Y-%m-%d %H:%M:%S UTC')` (`bats-exec-suite:198`); `…/${BATS_RUNLOG_DATE}-$count.log` only when the previous log equals the new name (`:229-231`).
'.' (0x2E) > '-' (0x2D), so `sort -r`/`ls -1r` put `<time>.log` first. Two back-to-back runs in the
same second shared one log during the probe setup (paraphrased — no quote available because that
output was observed during investigation and not saved to a file; the mechanism is quoted above).

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:196-199`, `/usr/libexec/bats-core/bats-exec-suite:227-231`

---

## Claim 9: "When .bats/ cannot be written the runner warns and runs without recording (--failed then exits 1)."

**Location:** `scripts/run-tests.sh:50-51`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `.bats` path that cannot be a directory (suite test 12) and the `--failed` branch by reading; does not cover a read-only mount.

`echo "WARNING: cannot write …; running without recording …" >&2` (`:309`); for `--failed`, `echo "ERROR: --failed: cannot write the run log …" >&2; exit 1` (`:306-307`).

**Evidence:** `scripts/run-tests.sh:300-310`, `iter2-logs/suite.txt` (ok 12)

---

## Claim 10a: "so a symlink cannot lead out of test/"

**Location:** `scripts/run-tests.sh:122-123`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as claim 3b: a file symlink escapes, a directory symlink does not.

`basename "$path"` is kept unresolved (`:124`); P4 ran an outside suite through `test/flink.bats`.

**Evidence:** `scripts/run-tests.sh:124`, `iter2-logs/probes.txt` (P4)

---

## Claim 10b: "and an alias path to a real suite is accepted"

**Location:** `scripts/run-tests.sh:122-123`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an aliased repo path (symlinked repo root) in both directions; does not cover aliases through a file symlink.

`REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"` (`:61`). P6: runner via alias + physical file, and physical runner + alias file, both `ok 1 b pass`.

**Evidence:** `scripts/run-tests.sh:61`, `scripts/run-tests.sh:124`, `iter2-logs/probes2.txt` (P6)

---

## Claim 11: "--failed needs a completed recorded run, whatever the selection and gating below leave. … the same pick here, so the file selection and bats' test filter read one log."

**Location:** `scripts/run-tests.sh:139-142`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the placement before gating (test 16) and the `ls -1r`-equivalent pick; does not cover the SIGPIPE failure of that pick with very many logs (F5).

The block runs before `collect_tests` (`:143-158` vs `:190`). bats picks with `read … < <(ls -1r "$BATS_RUN_LOGS_DIRECTORY")` (`bats-exec-suite:227`).

**Evidence:** `scripts/run-tests.sh:143-158`, `/usr/libexec/bats-core/bats-exec-suite:227`, `iter2-logs/suite.txt` (ok 16)

---

## Claim 12: "That run completed (checked above), so each test of each file it covered has a line: passed, failed, or status-filtered … So "has a failed line" is exactly bats' "did not pass"."

**Location:** `scripts/run-tests.sh:257-261`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the setup_file-failure and parse-error cases; the invariant holds when every test of a file actually ran.

P1: after a `setup_file` failure the completed, marked log has no line for `c.bats` tests (`passed …/b.bats` then the mark only). See claim 1.

**Evidence:** `scripts/run-tests.sh:257-272`, `iter2-logs/probes.txt` (P1)

---

## Claim 13: "a start stamp that tells this run's log apart from older ones afterwards"

**Location:** `scripts/run-tests.sh:298-299`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers exclusion of logs last modified before the stamp; does not establish that the stamp tells this run's log apart from a concurrent run's newer log (claim 5b).

`start_stamp="$(mktemp "$REPO_ROOT/.bats/run-start.XXXXXX" …)"` and `find … -newer "$start_stamp"` (`:302`, `:350`).

**Evidence:** `scripts/run-tests.sh:300-303`, `scripts/run-tests.sh:350`

---

## Claim 14: "A background child lets the traps below run at once … the runner forwards INT/TERM/HUP to bats, so `timeout` or a kill of the runner still stops bats as it did under exec."

**Location:** `scripts/run-tests.sh:315-319`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `timeout` (P7: 124, both versions), a single TERM to the runner (suite test 17), and a process-group INT (P8); the parity breaks for a repeated signal (P9/P10).

P7: `timeout 1` gives rc=124 for both the new and the old runner. P10: after two `kill -INT` the new
runner exits 130 after 1 s while bats runs on. The old `exec` runner waited (rc 0 after 8 s, P9).
Precise version: "…as it did under exec, except that a second signal of the same kind makes the
runner stop waiting (F3)".

**Evidence:** `scripts/run-tests.sh:324-342`, `iter2-logs/probes2.txt` (P7, P9, P10)

---

## Claim 15: "Without job control a background command ignores SIGINT, so env restores the default before bats sets its own Ctrl-C handler; `<&0` keeps the runner's stdin (a background command otherwise reads /dev/null)."

**Location:** `scripts/run-tests.sh:319-321`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers SIGINT disposition and stdin of the async child; does not establish that tests see the runner's stdin (bats-exec-test gives tests a pipe either way).

`env --default-signal=INT,QUIT bats … <&0 &` (`:325`). Probed: `echo hi | bash -c 'cat & wait'`
prints nothing, and `… 'cat <&0 & wait'` prints `hi` (paraphrased — no quote available because this
one-line probe's output was not saved to a file). P8 shows bats honouring a process-group INT
under the new runner (`# Received SIGINT, aborting ...`).

**Evidence:** `scripts/run-tests.sh:325`, `iter2-logs/probes2.txt` (P8)

---

## Claim 16: "Ctrl-C at a terminal reaches bats twice (directly and forwarded); its handler only sets a flag, so that is harmless."

**Location:** `scripts/run-tests.sh:322-323`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a single Ctrl-C; pressing Ctrl-C twice hits F3 (the loop), not bats' handler.

`trap 'BATS_INTERRUPTED=true' INT # let the lower levels handle the interruption` (`bats:454`). P8: new and old runners behave identically (`rc=1`, log removed).

**Evidence:** `/usr/libexec/bats-core/bats:454`, `iter2-logs/probes2.txt` (P8)

---

## Claim 17: "A trap cuts `wait` short while bats is still running; wait again."

**Location:** `scripts/run-tests.sh:340`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a repeated signal of the same name; the first signal of each kind is re-waited as stated.

The re-wait is conditional on the name changing: `[[ "$signalled" != "$interrupted" ]] || break` (`:341`). A second INT breaks with bats alive (P10).

**Evidence:** `scripts/run-tests.sh:335-342`, `iter2-logs/probes2.txt` (P10)

---

## Claim 18: "bats exited on its own (a status above 128 means a signal ended it): mark the log it wrote. No log newer than the stamp means bats recorded nothing (e.g. it deleted the log of a Ctrl-C run)."

**Location:** `scripts/run-tests.sh:346-348`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the gate and the empty-find branch; "the log it wrote" is qualified by claim 5b.

The example is almost unreachable. On a terminal Ctrl-C the runner also receives INT, so
`signalled` is set and the `if [[ -z "$signalled" && "$status" -lt 128 ]]` branch (`:349`) is
skipped before the find. The real empty-find case is a run that finished before any test completed
(paraphrased — no quote available because this is inferred from the lazy log creation seen in P7,
where no log existed after `timeout 1`).

**Evidence:** `scripts/run-tests.sh:345-354`, `iter2-logs/probes2.txt` (P7)

---

## Claim 19: "_locale_normalize … a simplified form of glibc's codeset normalisation … (glibc also prefixes "iso" to an all-digit codeset; this does not, which only matters for names like "xx.8859-1".)"

**Location:** `test/lib/hermetic-env.bash:43-47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the lowercase/strip behaviour; the glibc `iso` detail rests on iteration 1's claim 15 (glibc source not in the sandbox).

`codeset="${codeset,,}"` and `codeset="${codeset//[^a-z0-9]/}"` (`hermetic-env.bash`, `_locale_normalize`) (paraphrased — no quote available for the glibc side because its source is not in the sandbox).

**Evidence:** `test/lib/hermetic-env.bash:43-64`, `docs/reviews/u1-code-fact-check-report.md` (Claim 15)

---

## Claim 20: "It can report a usable locale as not installed (e.g. an "@modifier" name glibc falls back from, or no `locale` binary on PATH); that errs safe, costing only an unneeded pin."

**Location:** `test/lib/hermetic-env.bash:67-69`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two named over-report cases (probed in iteration 1); "costing only" understates the no-`locale` case.

With no `locale` binary, `C.UTF-8` itself is reported missing, so the runner's
`pinned=C; locale_installed C.UTF-8 && pinned=C.UTF-8` (`scripts/run-tests.sh:100-101`) pins plain
`C`. That replaces a working UTF-8 locale with a non-UTF-8 one, which is more than an unneeded pin
(C5, declined; the wording note only).

**Evidence:** `test/lib/hermetic-env.bash:65-80`, `scripts/run-tests.sh:99-104`

---

## Claim 21: "The repo root has a space in its name, so every test also covers word-splitting of paths."

**Location:** `test/scripts/run-tests.bats:6-7`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every test using `$T`; does not cover spaces in the bats temp dir itself.

`T="$BATS_TEST_TMPDIR/my repo"` (`run-tests.bats:12`); all 17 runner tests passed.

**Evidence:** `test/scripts/run-tests.bats:12`, `iter2-logs/suite.txt`

---

## Claim 22: "The killed-run test leaves a sleep behind (bats' test child outlives a TERM to bats, as it did when the runner exec'd bats)."

**Location:** `test/scripts/run-tests.bats:33-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parity of orphaned bats-exec-* processes after a TERM to the runner; does not cover SIGKILL.

A TERM to the runner left `bats-exec-suite`/`-file`/`-test` and `sleep 3` running under both the
new and the old runner (paraphrased — no quote available because this `ps` probe was run during
investigation and its output was not saved to a file; its result matches P7/P10).

**Evidence:** `test/scripts/run-tests.bats:32-38`

---

## Claim 23: test name "FILE: a symlink out of test/ is rejected"

**Location:** `test/scripts/run-tests.bats:143`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The body uses a directory symlink (`ln -s "$BATS_TEST_TMPDIR/elsewhere" "$T/test/link"`); a file symlink is not rejected (P4).

**Evidence:** `test/scripts/run-tests.bats:143-151`, `iter2-logs/probes.txt` (P4)

---

## Claim 24: test name "FILE: a suite named twice (or via ..) runs once; -- ends the flags"

**Location:** `test/scripts/run-tests.bats:153`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers dedup and that `--` is accepted; does not show that a flag-shaped argument after `--` is treated as a file.

`runner -- test/gamma.bats test/gamma.bats test/sub/../gamma.bats` then `[[ "$output" == *"1..1"* ]]` (`:154-156`).

**Evidence:** `test/scripts/run-tests.bats:153-157`

---

## Claim 25: test name "--failed refuses the log of a run killed partway (and TERM stops bats)"

**Location:** `test/scripts/run-tests.bats:231`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal and the runner exiting ≥128; "stops bats" holds for the top-level bats process only (claim 22).

`[ "$rc" -ge 128 ]` and `[[ "$output" == *"--failed: the last run ("*") did not complete"* ]]` (`:244`, `:253`). Passed (`ok 17`).

**Evidence:** `test/scripts/run-tests.bats:231-254`, `iter2-logs/suite.txt` (ok 17)

---

## Claim 26: other new/renamed test names and inline comments ("a missing file, a non-.bats file or one outside test/ is an error", "paths with spaces in the directory and file name", "a run whose first file is in a subdirectory still records its log under .bats/", "an unwritable .bats/ warns and runs without recording", "--failed with no recorded run is an error even when every selected suite is gated", "# bats' own status, passed through", "(`! grep` would not fail a bats test on a non-final line.)")

**Location:** `test/scripts/run-tests.bats:113`, `:160`, `:168`, `:177`, `:186`, `:221`, `:247`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each body asserts what its name says and passes; does not re-verify the bats `! cmd` semantics beyond bats' documented behaviour.

Each body asserts the named status and message (for example `[[ "$output" == *"not a .bats file: scripts/run-tests.sh"* ]]`, `:121`; `[ "$status" -eq 1 ]   # bats' own status, passed through`, `:186`). All passed.

**Evidence:** `test/scripts/run-tests.bats:113-186`, `test/scripts/run-tests.bats:221-254`, `iter2-logs/suite.txt`

---

## Claim 27: commit message: "It runs bats as a child, forwards INT/TERM/HUP to it, passes its exit status through"

**Location:** commit `07db4c0`, MA1 paragraph
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repeated-signal case; statuses 0/1/124/143 are passed through as stated (suite test 13, P7, test 17).

With two INTs to the runner, it exits 130 while bats later finishes with 0 (P10 vs P9). See F3.

**Evidence:** `scripts/run-tests.sh:335-356`, `iter2-logs/probes2.txt` (P9, P10)

---

## Claim 28: commit message: "With a completed log, "has a failed line" equals bats' "did not pass" for every covered file."

**Location:** commit `07db4c0`, MA1 paragraph
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as claim 12.

See claim 12 / P1.

**Evidence:** `scripts/run-tests.sh:257-272`, `iter2-logs/probes.txt` (P1)

---

## Claims Requiring Attention

- **Incorrect:** 1, 3b, 5b, 10a, 12, 17, 27, 28 → F1 (1, 12, 28), F2 (5b), F3 (17, 27), F4 (3b, 10a).
  (Claims 27 and 28 are the commit-message restatements of 17 and 12, verdicted separately.)
- **Mostly accurate:** 6, 14, 18, 20, 23, 24, 25 → K2, F3, K4.

---

## Goal-Alignment Note

- **Answered:** (a) Every iteration-1 item (MA1, C1–C4, C6, C8, C10; claims 4, 6, 15, 16, 24) is
  marked resolved or partly open, with evidence: 11 resolved, 2 partly open. (b) Every new claim in
  the delta was fact-checked (comments, header, messages, test names, commit message). (c) The
  non-exec design was probed for exit passthrough (0/1/124/143/130), Ctrl-C via a process group,
  INT/TERM sent only to the runner, a repeated signal, orphaned bats, stdin (`<&0`, closed stdin),
  a second `wait` on a reaped pid, same-second and concurrent logs, many logs, and set -e. Both
  required suites pass, 23/23.
- **Out of scope:** did not run the full suite or health-check, and did not review other units. A
  TTY was not available, so the terminal Ctrl-C was simulated with `setsid` plus a process-group
  SIGINT. Collation outside C.UTF-8 was not tested (no other locale is installed). The
  signal-before-trap window (K1) was reasoned from the code, not hit.
- **Escalate:** F1 and F2 mean `--failed` can still report a green "nothing to re-run" after a red
  or partial run. The author should decide between the cheap filter-plus-status fix and a
  serialising lock. The C7 override row's revisit trigger should be rewritten in light of F5
  whichever fix is chosen.
