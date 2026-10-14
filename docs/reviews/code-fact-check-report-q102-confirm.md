Commit: 57f37e3
# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-q102-parallel-gates`)
**Scope:** fix commits `65c931e6..57f37e3a` on `feat/q102-parallel-gates` (db341cb9, 57f37e3a; review artifacts in 499f62fc excluded except `docs/reviews/override-log.md`): `scripts/health-check.sh`, `scripts/run-tests.sh`, `test/install-host.bats`, `test/scripts/health-check.bats`, `test/scripts/run-tests.bats`, the two retagged files, `docs/working/questions-archive.md`, `docs/reviews/override-log.md`, `workflows/pr-prep.md`, commit messages db341cb9 and 57f37e3a
**Checked:** 2026-10-14
**Total claims checked:** 23
**Summary:** 17 verified, 6 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable
**Replication:** k=1 (confirming pass)

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern (the closest family, "a tally/figure claimed in a commit message", was checked against the source for every number here).

Execution logs are under `docs/reviews/execution-logs/q102-confirm-*.log`. Scratch for the pre-fix runs and the nproc harness was `/tmp/q102cfc.1301885` (untracked; harness script `harness.sh` there).

---

## Claim 1: "Unset or empty: 8, or nproc when that is lower; 1 runs serially. Otherwise the same grammar as run-tests.sh's --jobs (1 to 999, digits only, no leading zero); any other value fails check 5 before it runs a test."

**Location:** `scripts/health-check.sh:27-33`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_bats' choice of `--jobs` for unset, empty, explicit, invalid values and for nproc being 16, 4, 1, 0, junk, empty, failing, absurdly large, or absent from PATH, under the script's own `set -euo pipefail`; does not establish behaviour on a real small host (only stubbed nproc) or the runner's own downstream capping to the file count.

The code:

```bash
# scripts/health-check.sh:413-422
    local jobs="${HEALTH_CHECK_JOBS:-}" cores
    if [[ -z "$jobs" ]]; then
        jobs=8
        cores="$(nproc 2>/dev/null || true)"
        [[ "$cores" =~ ^[1-9][0-9]*$ ]] && (( cores < jobs )) && jobs=$cores
    fi
    if [[ ! "$jobs" =~ ^[1-9][0-9]{0,2}$ ]]; then
        fail "HEALTH_CHECK_JOBS='$jobs' is not 1 to 999 (digits only, no leading zero; 1 = serial) — BATS suites not run"
        return
    fi
(excerpt ends :422; enclosing check_bats() continues to :449 — read)
```

`set -euo pipefail` is at `scripts/health-check.sh:64`. The `&&` list at :417 is safe under `set -e`: a failing `[[ ]]` or `(( ))` that is not the last command of an `&&` list does not trip errexit, and the list is not the function's last command. Executed with a stub runner and a stub `nproc` (harness sourced the script, so `$-` showed `ehuB` with errexit on): nproc 16 → `--jobs 8`; 4 → 4; 1 → 1; 0, `"4 cpus"`, empty output, exit 127, `99999999999999999999` → 8; nproc not on PATH → 8; `HEALTH_CHECK_JOBS=` with nproc 4 → 4; `HEALTH_CHECK_JOBS=16` with nproc 4 → 16 (not capped); `08` and `1000` → `FAIL=1`, the named message, and no runner call. Every case exited 0 from the shell (no errexit abort). One edge beyond the claim: an nproc that prints `3` and exits non-zero yields `--jobs 3`, since the captured output is used whatever the exit status; that still matches "nproc when lower".

**Evidence:** `scripts/health-check.sh:27-35`, `scripts/health-check.sh:64`, `scripts/health-check.sh:413-422`; `docs/reviews/execution-logs/q102-confirm-checkbats-nproc.log` (command: `timeout 200 bash /tmp/q102cfc.1301885/harness.sh "$PWD"`, cwd `/workspace/.claude/wt-q102-parallel-gates`, exit 0, 2026-10-14T20:26:01Z)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "Read here only: run-tests.sh run by hand stays serial unless given --jobs."

**Location:** `scripts/health-check.sh:34-35`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that no script other than health-check.sh reads `HEALTH_CHECK_JOBS`, that run-tests.sh defaults to `jobs=1`, and that inherited bats parallel variables no longer parallelize a run without `--jobs`; does not establish anything about a user's own `bats` invocations outside run-tests.sh.

`scripts/run-tests.sh:132` sets `jobs=1`, and only the `--jobs` branch at `:141-152` changes it. A repo-wide grep for `HEALTH_CHECK_JOBS` outside `docs/reviews` finds readers only in `scripts/health-check.sh:413` (the one in `scripts/run-tests.sh:144` is a comment) and the tests (paraphrased — no quote available because the claim covers absence of code, a grep result). A "stays serial" claim would have been false before this fix if `BATS_NUMBER_OF_PARALLEL_JOBS` was inherited; `scripts/run-tests.sh:416` now unsets it (Claim 9, executed).

**Evidence:** `scripts/run-tests.sh:132`, `scripts/run-tests.sh:141-152`, `scripts/run-tests.sh:416`; `docs/reviews/execution-logs/q102-confirm-runtests-newtest-fixed.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "both with --jobs $HEALTH_CHECK_JOBS (default 8, at most nproc)"

**Location:** `scripts/health-check.sh:53`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parenthetical's reading against check_bats; does not establish anything beyond Claim 1's cases.

"at most nproc" binds to the default only; an explicit value is not capped (`HEALTH_CHECK_JOBS=16` with nproc 4 ran `--jobs 16`, Claim 1 log). The block above (:28-29) and the comment at :388-389 say it precisely ("8, or nproc when lower"). Precise version: "(default 8, or nproc when lower)".

**Evidence:** `scripts/health-check.sh:53`, `scripts/health-check.sh:413-418`; `docs/reviews/execution-logs/q102-confirm-checkbats-nproc.log` ("explicit 16, nproc 4")
**Legibility-target:** for-author

---

## Claim 4: "One full-suite run at --jobs 8 took 140 s against 451 s serial on 16 cores (Q-090, docs/working/questions-archive.md)"

**Location:** `scripts/health-check.sh:389-390`
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the figures' source and attribution; does not re-measure them.

`docs/working/questions-archive.md:1878`, under `### Q-090 · run-tests-jobs` (:1875): "Wall time on the 16-core sandbox: serial 451 s, `--jobs 8` 140–145 s (3.1×)". 140 s is the low end of that range, which "one run ... took 140 s" fits.

**Evidence:** `docs/working/questions-archive.md:1875`, `docs/working/questions-archive.md:1878`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: "each of the gate's two runs is bounded by its slowest file, so the gate gains less than that (first gate at --jobs 8: 171 s fast + 154 s slow, on a loaded host)"

**Location:** `scripts/health-check.sh:390-393`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the 171/154 s figures and the load qualifier against the performance review and the run-log timestamps; does not establish the gate's time after this fix (see Claim 16 for the post-fix run).

`docs/reviews/performance-review-2026-10-14-q102.md:17`: "fast run 19:49:27 to 19:52:18 UTC (171 s), slow run 19:52:20 to 19:54:54 UTC (154 s). The host was at load ~5". The run logs `.bats/.bats/run-logs/2026-10-14 19:49:27 UTC.log` (mtime 12:52:18 -0700) and `... 19:52:20 UTC.log` (mtime 12:54:54 -0700) match; 65c931e6 was committed 12:49:19 -0700, so this was the first gate on the change.

**Evidence:** `docs/reviews/performance-review-2026-10-14-q102.md:17`, `.bats/.bats/run-logs/` (listing), `git log -1 65c931e6`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "The value is checked here with run-tests.sh's --jobs grammar (keep the two regexes equal)" / "health-check.sh checks HEALTH_CHECK_JOBS with this same regex: keep the two equal."

**Location:** `scripts/health-check.sh:394-395`; `scripts/run-tests.sh:143-144`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers byte-equality of the two regexes today; does not establish that anything enforces it in future.

`scripts/health-check.sh:419`: `if [[ ! "$jobs" =~ ^[1-9][0-9]{0,2}$ ]]; then`; `scripts/run-tests.sh:145`: `if [[ ! "${2:-}" =~ ^[1-9][0-9]{0,2}$ ]]; then`. Identical.

**Evidence:** `scripts/health-check.sh:419`, `scripts/run-tests.sh:145`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: "Without GNU parallel the runner warns and runs serially." (header, kept)

**Location:** `scripts/health-check.sh:33-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the runner's branch for jobs > 1; does not re-execute it (pass 1 replicates did).

```bash
# scripts/run-tests.sh:417-424
if [[ "$jobs" -gt 1 ]]; then
  unset PARALLEL PARALLEL_CSH
  if [[ "$(parallel --plain --version 2>/dev/null)" == "GNU parallel"* ]]; then
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
  else
    echo "WARNING: --jobs $requested_jobs needs GNU parallel, ...; running serially" >&2
  fi
fi
```

**Evidence:** `scripts/run-tests.sh:417-424`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: "bats reads these when it is given no --jobs flag (or alongside it), so an inherited value would run a --jobs 1 run in parallel, within files too."

**Location:** `scripts/run-tests.sh:414-415`
**Type:** Behavioral (external tool)
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers bats-core 1.8.2 as installed at `/usr/libexec/bats-core`; does not establish other bats versions.

The installed bats (`bats --version`: 1.8.2) reads both at startup:

```bash
# /usr/libexec/bats-core/bats-exec-suite:6-7
num_jobs=${BATS_NUMBER_OF_PARALLEL_JOBS:-1}
bats_no_parallelize_across_files=${BATS_NO_PARALLELIZE_ACROSS_FILES-}
```

but `-j` overwrites `num_jobs` (`bats-exec-suite:32-36`: `-j) shift; num_jobs="$1"; flags+=('-j' "$num_jobs")`), and the same `-j` is forwarded to `bats-exec-file`, whose `num_jobs=${BATS_NUMBER_OF_PARALLEL_JOBS:-1}` (:5) is overwritten the same way (:13-15). So `BATS_NUMBER_OF_PARALLEL_JOBS` is read only when no `--jobs` is given; `BATS_NO_PARALLELIZE_ACROSS_FILES` is read either way, and with `--jobs N` it would disable across-file parallelism (`bats-exec-suite:415`: `if [[ "$num_jobs" -gt 1 ]] && [[ -z "$bats_no_parallelize_across_files" ]]`). "Within files too" holds: `bats-exec-file:294` parallelizes a file's tests when `num_jobs != 1` and no within-file opt-out is set. The conclusion (the unset is needed, and a `--jobs 1` run would otherwise go parallel) is right; "these ... (or alongside it)" applies to only one of the two variables. Precise version: "bats reads BATS_NUMBER_OF_PARALLEL_JOBS when given no --jobs flag, and BATS_NO_PARALLELIZE_ACROSS_FILES either way".

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:6-7,32-36,99-101,415-420`, `/usr/libexec/bats-core/bats-exec-file:5,13-15,294`, `/usr/libexec/bats-core/bats:195-197`
**Legibility-target:** for-author

---

## Claim 9: unsetting the bats variables keeps `--jobs 1` serial; "new test fails without the fix" (db341cb9 body)

**Location:** `scripts/run-tests.sh:416`; `test/scripts/run-tests.bats:382-389`; commit db341cb9 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `BATS_NUMBER_OF_PARALLEL_JOBS=4` inherited case with two fixture files; does not establish an inherited `BATS_NO_PARALLELIZE_ACROSS_FILES` case (no test exercises it; covered statically in Claim 8).

`scripts/run-tests.sh:416`: `unset BATS_NUMBER_OF_PARALLEL_JOBS BATS_NO_PARALLELIZE_ACROSS_FILES`. The new test passes at HEAD (`ok 1 --jobs 1 stays serial when bats' own parallel variables are inherited`). With a copy of the same layout whose run-tests.sh drops only that line (`diff` shows the single removed line), the test fails: `` `[ ! -f "$T/parallel.args" ]' failed `` at `test/scripts/run-tests.bats` line 388, i.e. bats invoked GNU parallel.

**Evidence:** `scripts/run-tests.sh:416`, `test/scripts/run-tests.bats:382-389`; `docs/reviews/execution-logs/q102-confirm-runtests-newtest-fixed.log` (command `timeout 200 bats -f "stays serial when bats' own parallel" test/scripts/run-tests.bats`, cwd worktree, exit 0, 2026-10-14T20:25:14Z); `docs/reviews/execution-logs/q102-confirm-runtests-newtest-prefix.log` (same command, cwd `/tmp/q102cfc.1301885/repo`, exit 1, 2026-10-14T20:25:16Z)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: "python3 writes the marker once prctl has returned, so a slow start on a loaded host ... waits rather than skipping"

**Location:** `test/install-host.bats:1598-1600`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers statement order in the python one-liner, the 60 s wait, and the fail-not-skip on timeout; does not establish that 60 s suffices on every loaded host.

```bash
# test/install-host.bats:1602-1606
  (cd "$S" && exec python3 -c 'import ctypes, sys, time; ctypes.CDLL(None).prctl(4, 0, 0, 0, 0); open(sys.argv[1], "w").close(); time.sleep(300)' "$marker") \
    >/dev/null 2>&1 3>&- &
  local hidden=$!
  for _i in $(seq 600); do [ -e "$marker" ] && break; sleep 0.1; done
  [ -e "$marker" ] || { kill "$hidden" 2>/dev/null; echo "python3 did not reach prctl in 60 s" >&2; return 1; }
(excerpt ends :1606; enclosing T92 @test continues to :1615 — read)
```

The marker is created after the `prctl` call statement; 600 × 0.1 s is 60 s; a missing marker returns 1 (test fails). Run alone, T92 passed without a skip (`ok 1 T92 ...`, no `# skip`). Minor wording: the failure message says "did not reach prctl", but the marker is also missing if python3 reached prctl and then died before `open`; "did not get past prctl" would be exact.

**Evidence:** `test/install-host.bats:1594-1615`; `docs/reviews/execution-logs/q102-confirm-t92.log` (command `LC_ALL=C.UTF-8 timeout 250 bats -f 'T92 ' test/install-host.bats`, cwd worktree, exit 0, 2026-10-14T20:27:01Z)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "the skip is only for a kernel where prctl does not hide the cwd"

**Location:** `test/install-host.bats:1600`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the skip condition tests; does not establish which of the alternative causes occur on any host this suite runs on (this sandbox runs as uid 1000 and T92 did not skip).

`test/install-host.bats:1607`: `! readlink "/proc/$hidden/cwd" >/dev/null 2>&1 || { kill "$hidden"; skip "prctl did not hide the cwd here"; }`. The skip fires whenever the cwd is still readable after the marker exists. The python one-liner does not check prctl's return value (`ctypes.CDLL(None).prctl(4, 0, 0, 0, 0)` at :1602, result discarded), so a failed prctl also writes the marker; and a reader with ptrace capability over the process (root, or CAP_SYS_PTRACE) can read a non-dumpable process's cwd (paraphrased — no quote available because this is Linux /proc access-mode behaviour, not repository code). Those cases skip too, not just "a kernel". The point of the change, that load alone no longer causes the skip, holds (Claim 10). Precise version: "the skip is only for a host where the cwd is still readable after prctl returned (a kernel or privilege where the hide does not work)".

**Evidence:** `test/install-host.bats:1602`, `test/install-host.bats:1607`
**Legibility-target:** for-author

---

## Claim 12: "Gate-5 guard unset here, and HEALTH_CHECK_JOBS too unless STUB_JOBS is set ... STUB_NPROC, when set, puts an nproc printing it first on PATH."

**Location:** `test/scripts/health-check.bats:203-206`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_run_check_bats` and the report-dependent test at :493; does not run the gate-5 tests (their file's setup_file runs the whole health check under the shared lock; Claim 1 executed the same code paths with an equivalent harness).

```bash
# test/scripts/health-check.bats:212-220
  local jobs_env=(-u HEALTH_CHECK_JOBS) path="$PATH"
  [[ -n "${STUB_JOBS+set}" ]] && jobs_env=(HEALTH_CHECK_JOBS="$STUB_JOBS")
  if [[ -n "${STUB_NPROC:-}" ]]; then
    mkdir -p "$BATS_TEST_TMPDIR/nproc-bin"
    printf '#!/bin/sh\necho %s\n' "$STUB_NPROC" > "$BATS_TEST_TMPDIR/nproc-bin/nproc"
    chmod +x "$BATS_TEST_TMPDIR/nproc-bin/nproc"
    path="$BATS_TEST_TMPDIR/nproc-bin:$PATH"
  fi
(excerpt ends :220; enclosing _run_check_bats() continues to :222 — read)
```

`test/scripts/health-check.bats:493` adds `-u HEALTH_CHECK_JOBS` to the report-dependent test, as db341cb9's body says.

**Evidence:** `test/scripts/health-check.bats:203-222`, `test/scripts/health-check.bats:493`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: Applied note: "passes `--jobs` to both runs from `HEALTH_CHECK_JOBS` (named for the script that reads it; run-tests.sh ignores it). Unset or empty means 8, or nproc when lower; 1 is serial; any other value outside run-tests.sh's `--jobs` grammar fails the gate before any test runs, and the runner still falls back to serial without GNU parallel."

**Location:** `docs/working/questions-archive.md:2516`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 1, 2 and 7; does not cover the retag sentence (Claims 14-15).

Same code and harness as Claim 1 (`scripts/health-check.sh:413-422`, both runs at :430 and :438 use `--jobs "$jobs"`); run-tests.sh has no `HEALTH_CHECK_JOBS` reader (Claim 2).

**Evidence:** `scripts/health-check.sh:413-438`; `docs/reviews/execution-logs/q102-confirm-checkbats-nproc.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "build-loop-check.bats and cc-isolated-functions.bats moved from fast to slow, since at 120 s and 85 s they bounded the fast run."

**Location:** `docs/working/questions-archive.md:2516`; same wording in commit db341cb9 body ("they bounded the fast pre-gate, which became the longer run")
**Type:** Performance / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the timings and which file bounded the fast run; the move itself is Claim 15.

`docs/reviews/performance-review-2026-10-14-q102.md:19-20`: `build-loop-check.bats`: 119.5 s, `cc-isolated-functions.bats`: 84.9 s (solo). Only build-loop-check bounded the fast run: ":54 ... It was the last file to finish in the fast run"; cc-isolated-functions was retagged as "the next slowest fast file" (:60), so it would have bounded the fast run only once build-loop-check left. Precise version: "since build-loop-check (120 s) bounded the fast run and cc-isolated-functions (85 s) was the next slowest".

**Evidence:** `docs/reviews/performance-review-2026-10-14-q102.md:19-20,54,60`
**Legibility-target:** for-author

---

## Claim 15: the retag (both files now `# @category slow`)

**Location:** `test/scripts/build-loop-check.bats:2`; `test/cc-isolated-functions.bats:2`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tag lines and the runner's tag read; does not establish that no doc lists these files as fast (grep found none outside reviews/archive).

Both files' line 2 is `# @category slow`; the runner reads the first match: `scripts/run-tests.sh:279`: `tag=$(grep -m1 '^# @category ' "$file" 2>/dev/null | sed 's/^# @category //' || true)`.

**Evidence:** `test/scripts/build-loop-check.bats:2`, `test/cc-isolated-functions.bats:2`, `scripts/run-tests.sh:279`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: Override-log row (Amends row 182): "build-loop-check.bats (fast-tagged, 119.5 s solo) started ~51 s late and bounded the fast run (171 s against slow's 154 s) (performance F1/F2, Medium/Low)" · "Fixed by retag; general sort deferred"

**Location:** `docs/reviews/override-log.md:824`
**Type:** Performance / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the row's figures, severities, the row-182 reference, and whether the retag removed build-loop-check as the fast run's bound; does not establish that the gate as a whole got faster.

Row 182 (`docs/reviews/override-log.md:182`) is the longest-first deferral with trigger "Revisit if `--jobs` becomes the default in health-check". F1 is Medium and F2 Low (`performance-review-2026-10-14-q102.md:180-181`). "~51 s late" is an inference, not a measurement: ":82 If its in-run time matched its solo time, it started about 51.5 s into the 171 s run (171 − 119.5)"; the row states it as fact. The retag did remove that bound: the post-fix gate's run logs (`.bats/.bats/run-logs/2026-10-14 20:15:59 UTC.log`, mtime 13:17:48 -0700; `2026-10-14 20:17:52 UTC.log`, mtime 13:21:12 -0700) give about 110 s fast and 201 s slow (paraphrased — no quote available because these are file timestamps from a directory listing). The gate's BATS total moved only from 325 s to about 311 s on a loaded host, against the review's projected 180-200 s (`performance-review-2026-10-14-q102.md:60`, "speculative until re-measured"); the slow run absorbed the moved files. Precise version: "started about 51 s in (estimated from its solo time)".

**Evidence:** `docs/reviews/override-log.md:182`, `docs/reviews/override-log.md:824`, `docs/reviews/performance-review-2026-10-14-q102.md:60,82,180-181`, `.bats/.bats/run-logs/` (listing)
**Legibility-target:** for-author

---

## Claim 17: Override-log row (Amends row 181): "install-host.bats now takes 141.3 s solo (not 105 s), ~154 s inside the slow run (1.09×)" · "revisit if install-host.bats' own in-run duration exceeds 1.5× its solo time (about 212 s)"

**Location:** `docs/reviews/override-log.md:825`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the figures and arithmetic and the row-181 reference; does not establish install-host's in-run duration in the post-fix gate (the slow run took about 201 s, so it is at most that, under 212 s, but its last test was not the run's last line).

Row 181 (`override-log.md:181`) gives "install-host.bats alone 105 s" and the "1.5× install-host.bats' solo time" trigger. `performance-review-2026-10-14-q102.md:21`: "`test/install-host.bats`: 141.3 s"; :137: "154 / 141.3 ≈ 1.09x ... 1.5x trigger (212 s)". python3: 1.5 × 141.3 = 211.95; 154 / 141.3 = 1.0899. "Also matches the fast run, which does not contain install-host" matches :142 ("The fast run, at 171 s, exceeds 157.5 s although it does not contain install-host").

**Evidence:** `docs/reviews/override-log.md:181`, `docs/reviews/override-log.md:825`, `docs/reviews/performance-review-2026-10-14-q102.md:21,137,142`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: Override-log row (T92): "skipped after 5 s of waiting for prctl, and a skip passes the gate" · "python3 writes a marker after prctl returns; the test waits up to 60 s for it and fails if it never appears; it skips only when prctl returned and the cwd is still readable (a kernel where the hide does not work)"

**Location:** `docs/reviews/override-log.md:826`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the old and new waits and the skip condition; the parenthetical carries Claim 11's narrowness.

Old loop (db341cb9's removed line): `for _i in $(seq 50); do readlink "/proc/$hidden/cwd" >/dev/null 2>&1 || break; sleep 0.1; done` — 5 s, then the skip line. A bats `skip` reports `ok ... # skip` and does not fail the run (paraphrased — no quote available because this is bats' TAP semantics, not repository code). The new mechanism matches `test/install-host.bats:1602-1607` (Claim 10). "it skips only when prctl returned and the cwd is still readable" is exact; the gloss "(a kernel where the hide does not work)" omits a failed prctl (return unchecked) and a ptrace-capable reader (Claim 11).

**Evidence:** `git show db341cb9 -- test/install-host.bats`, `test/install-host.bats:1602-1607`
**Legibility-target:** for-author

---

## Claim 19: Override-log row (commit timing): "Commit 65c931e6's body cites 'about 2.5 min against 7.5 min serial' as gate 5's time; the figures are one full-suite run's (Q-090), and the gate makes two runs" · "the fix commit's body and the corrected pr-prep and health-check.sh text carry the right figures"

**Location:** `docs/reviews/override-log.md:827`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fix commit's and the two files' figures; "merged locally with its history" is an intent about a future merge and is not checked.

db341cb9's body: "the 140 s / 451 s figures are one full-suite run's (Q-090); the gate's two runs took 171 s + 154 s at 65c931e6 on a loaded host." `workflows/pr-prep.md:331` and `scripts/health-check.sh:388-393` cite the same figures (Claims 4, 5, 20).

**Evidence:** `git show db341cb9` (body), `workflows/pr-prep.md:331`, `scripts/health-check.sh:388-393`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: "each with `--jobs 8`, or nproc when lower (Q-102 [1]; one full-suite run took 140 s at `--jobs 8` against 451 s serial). `HEALTH_CHECK_JOBS=N` picks another N, and `HEALTH_CHECK_JOBS=1` runs serially; without GNU parallel the runner warns and runs serially."

**Location:** `workflows/pr-prep.md:331`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default, override and fallback against the code; the 140/451 figures are Q-090's (also quoted in Q-102's question text at `questions-archive.md:2501`), so the "Q-102 [1]" tag attributes the decision, not the measurement.

Same code paths as Claims 1, 4 and 7. The line sits in step 5a (`workflows/pr-prep.md:315`, "**a. Verify CI passes (automated).**"), matching the Applied note's "pr-prep's step 5a".

**Evidence:** `workflows/pr-prep.md:315,331`, `scripts/health-check.sh:413-422`, `docs/working/questions-archive.md:1878,2501`; `docs/reviews/execution-logs/q102-confirm-checkbats-nproc.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: db341cb9 body, remaining atoms: "`RUN_TESTS_JOBS=8 run-tests.sh` silently ran serially (api F1)"; "Unset or empty means 8, or nproc when lower; an explicit value is not capped"; "Override-log rows for 181/182, T92 and the commit timing"

**Location:** commit db341cb9 body
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these three atoms; the "they bounded" atom is Claim 14 and the "new test fails without the fix" atom is Claim 9.

`git show 65c931e6:scripts/run-tests.sh | grep -c RUN_TESTS_JOBS` prints `0`, while 65c931e6's health-check.sh read it at :408 (`local jobs="${RUN_TESTS_JOBS:-8}"`), so a hand run with only the env var was serial. The cap behaviour is Claim 1's log. Four rows dated 2026-10-14 for the branch are at `override-log.md:824-827`.

**Evidence:** `git show 65c931e6:scripts/run-tests.sh`, `git show 65c931e6:scripts/health-check.sh` (:408), `docs/reviews/override-log.md:824-827`; `docs/reviews/execution-logs/q102-confirm-checkbats-nproc.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: db341cb9 Notes: "the retag and the T92 change go slightly beyond the brief; ... The nproc cap is unmeasured on a small host."

**Location:** commit db341cb9 body
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that no small-host measurement exists in the branch's artifacts; scope judgments ("beyond the brief") are not checkable and are not verdicted.

No review artifact or run log on the branch records a run with nproc < 8 (paraphrased — no quote available because the claim covers absence, from a grep of `docs/reviews/*q102*` for nproc timings).

**Evidence:** `docs/reviews/performance-review-2026-10-14-q102.md:182` (F3, "Medium / Low" confidence, unmeasured)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: 57f37e3a: "quote the empty STUB_JOBS assignment (SC1007 failed gate 6). Caused by db341cb9; caught by the health check at db341cb9."

**Location:** commit 57f37e3a; `test/scripts/health-check.bats:237`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that db341cb9's file raises SC1007 at warning level, that gate 6 lints .bats files at that level, and that HEAD's file does not; does not establish the gate run's own output (not kept), though a gate did run at db341cb9 (run logs at 20:15:59 and 20:17:52 UTC).

shellcheck 0.9.0 on `db341cb9:test/scripts/health-check.bats`: "line 237: `STUB_NPROC=16 STUB_JOBS= _run_check_bats` ^-- SC1007 (warning)"; on HEAD's file no warning-level finding remains (only info-level SC2016/SC2030/SC2031). Gate 6 includes `.bats` files and fails on warnings:

```bash
# scripts/health-check.sh (check_shellcheck)
        if shellcheck -x -e SC1091 -s bash -S warning "$f" 2>/dev/null; then
```

**Evidence:** `git show 57f37e3a`, `scripts/health-check.sh` check_shellcheck (the `-name '*.bats'` find and the `-S warning` call); `docs/reviews/execution-logs/q102-confirm-sc1007.log` (commands `shellcheck /tmp/q102cfc.1301885/hc-db341.bats` and `shellcheck test/scripts/health-check.bats`, cwd worktree, both exit 1 at default severity, 2026-10-14T20:27:17Z)
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 3** (`scripts/health-check.sh:53`): "(default 8, at most nproc)" reads as a cap on any value; say "(default 8, or nproc when lower)".
- **Claim 8** (`scripts/run-tests.sh:414-415`): only `BATS_NO_PARALLELIZE_ACROSS_FILES` is read alongside `--jobs`; `-j` overrides `BATS_NUMBER_OF_PARALLEL_JOBS`.
- **Claim 11** (`test/install-host.bats:1600`): the skip also fires on a failed prctl (return unchecked) or a ptrace-capable reader, not only "a kernel".
- **Claim 14** (`docs/working/questions-archive.md:2516`, db341cb9 body): only build-loop-check bounded the fast run; cc-isolated-functions was the next slowest.
- **Claim 16** (`docs/reviews/override-log.md:824`): "started ~51 s late" is estimated from solo time, not measured; post-fix gate is about 110 s fast + 201 s slow (about 311 s total vs 325 s), so the retag moved the bound to the slow run rather than shortening the gate much.
- **Claim 18** (`docs/reviews/override-log.md:826`): the "(a kernel where the hide does not work)" gloss shares Claim 11's narrowness.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path named in your tail, structured per your skill, with a Goal-Alignment Note.
- Answered: yes — all seven claim areas in the brief checked; the pass-1 fixes are correct, with six wording imprecisions and no Incorrect verdicts.
- Out of scope: the gate-5 tests in `test/scripts/health-check.bats` were not run (setup_file runs the whole health check under the shared lock); an equivalent sourced harness exercised the same code.
- Escalate: the post-fix gate's run logs show about 110 s fast + 201 s slow (about 311 s) against 325 s before, well above the review's projected 180-200 s; the override-log "Fixed by retag" row and any timing text should not imply a large gate speedup.
- Decisions I made: treated "row 181/182" as override-log file line numbers (they match); counted the db341cb9 body's "they bounded" atom under Claim 14 rather than as a separate claim.
