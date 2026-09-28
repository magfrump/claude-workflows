Commit: c2322a2

# U1 critic report: scripts/run-tests.sh (locale pin, FILE..., --failed)

Branch `feat/u1-run-tests`. Reviewed for correctness and for shell robustness/security. Findings use
the Must Fix / Must Address / Consider tiers. Every finding marked **[probed]** was reproduced in a
throwaway repo under the scratchpad (bats 1.8.2, `LC_ALL=C.UTF-8`). The bats 1.8.2 source
(`/usr/libexec/bats-core/bats-exec-suite`, `bats-exec-test`) was read to check the run-log
semantics the runner mirrors.

This is a developer-run tool. The only inputs are the developer's own argv and repo, so there is no
attacker-controlled trust boundary. The security-shaped items below (symlink escape from `test/`)
are about robustness, not exploitability.

**Summary:** no Must Fix. One Must Address: `--failed` can report a green "nothing to re-run" after a
run that was killed partway. The rest are Consider.

## Must Address

### MA1. `--failed` gives a false green after a run killed by anything other than Ctrl-C [probed]

**Location:** `scripts/run-tests.sh:39` (header claim), `scripts/run-tests.sh:214-239` (file pre-filter)

**Scenario:** bats deletes its run log only when it sees SIGINT (`BATS_INTERRUPTED`,
bats-exec-suite:355-357). A run ended by SIGTERM, `timeout`, SIGKILL/OOM, or a closed terminal
leaves a *partial* log that records only the tests that finished. That log then becomes the "last
recorded run". The runner keeps only files that have a `failed` line in it. A file whose failing
tests never ran is dropped, and the runner prints "no failed tests … nothing to re-run" and
**exits 0**.

Probe: `slow.bats` = {s1: sleep 1, s2: sleep 30, s3: false}. `timeout -s TERM 4 run-tests.sh
slow.bats` left a log holding only `passed … test_s1`. Then `run-tests.sh --failed slow.bats`
printed `--failed: no failed tests in the last recorded run … nothing to re-run` with rc=0.

The pre-filter is also stricter than bats. `--filter-status failed` in bats means "not passed"
(bats-exec-suite:206-208), so bats on its own *would* re-run s2 and s3 as missed tests. The runner
short-circuits before bats sees them. The header's "An interrupted (Ctrl-C) run is not recorded"
is true only for SIGINT, and "last completed run" (line 26) is not what the code checks.

**Suggested fix (either one):**
1. Match bats' semantics. Keep a file unless every test in it has a `passed` line. For example,
   keep a file when the log has a `failed` line for it **or has no `passed` line for it at all**.
   This still misses a file that is only partly logged. The fuller check compares per-file test
   counts via `bats --count` on each file.
2. Mark completed runs. Don't `exec` bats. Run it, capture its status, and append a
   `# run-tests: complete` comment line to the log it just wrote (bats' parser skips `#` lines,
   bats-exec-suite:252). `--failed` then refuses a last log without the marker, with a nonzero exit
   and "last run did not complete; run without --failed". Add a test that kills a fixture run with
   SIGTERM and asserts `--failed` does not exit 0 silently.

## Consider

### C1. The scope of `--failed` is whatever the last run happened to select
**Location:** `scripts/run-tests.sh:214-239`
**Scenario:** health-check runs `--fast` and then `--slow` as two separate runs, so the slow log
always wins. If the fast set was red, health-check skips slow, so the fast log is last; that case
is fine. A more realistic one: a full run fails in `x.bats`. The developer then runs
`run-tests.sh test/y.bats` (green). `--failed` now exits 0 with "nothing to re-run", and the
`x.bats` failure is forgotten. The behaviour matches the documentation, but exit 0 reads as "all
fixed".
**Fix:** print the log's selection (its file list, or at least its timestamp and test count) in the
"nothing to re-run" message. Alternatively, say "last recorded run" in the message rather than
implying a global status. Cheap either way.

### C2. Two `--failed` runs in the same second: bats and the runner both pick the older log [probed]
**Location:** `scripts/run-tests.sh:220` (mirrors bats-exec-suite:227-231)
**Scenario:** when a filtered run starts in the same second as the previous log, bats names the new
log `… UTC-1.log`. `sort -r` / `ls -1r` rank `UTC.log` above `UTC-1.log` (`.` 0x2E > `-` 0x2D),
so the next `--failed` reads the *older* log. The probe produced `18:34:13 UTC.log` and
`18:34:13 UTC-1.log` side by side. Runner and bats agree, so they are consistent, but both are
wrong. Plain (unfiltered) runs in the same second share one log file and append to it; concurrent
runs merged into one log in the probe. Low impact, since it needs sub-second reruns.
**Fix:** accept it as an upstream bats quirk and note it in the "Run logs" header. Alternatively,
sort by mtime in both places. The runner can't change what bats picks, so a note is probably
enough.

### C3. Path confinement uses the logical `pwd`: symlinks escape `test/`, and alias paths are rejected [probed]
**Location:** `scripts/run-tests.sh:49`, `scripts/run-tests.sh:104-105`
**Scenario:** (a) `test/link -> /elsewhere`: `run-tests.sh test/link/x.bats` passes the "under
test/" check and runs `/elsewhere/x.bats` (probe: `ok 1 outside`). (b) The runner invoked through a
symlinked repo path (`$ALIAS/scripts/run-tests.sh`) with the physical path of a real test file
gives `ERROR: not under test/`. `..` is handled correctly, because `cd` resolves it.
**Fix:** use `pwd -P` for both `REPO_ROOT` and the per-file resolution, or `realpath -e`. Decide
whether symlinked suites in `test/` should be allowed. Not a security issue (developer-controlled
input).

### C4. Duplicate FILE arguments run the suite once per argument [probed]
**Location:** `scripts/run-tests.sh:98-110`
**Scenario:** `run-tests.sh test/a.bats test/a.bats test/sub/../a.bats` ran `a.bats` three times
(`1..6`), and the failure was reported three times. That is easy to hit with shell globs plus an
explicit name.
**Fix:** dedupe `candidates` after canonicalisation (an associative array, or `sort -u` on the
resolved paths).

### C5. Missing `locale` binary: a working UTF-8 locale is reported "not installed" and downgraded to C [probed]
**Location:** `test/lib/hermetic-env.bash:74`, `scripts/run-tests.sh:85-91`
**Scenario:** with `locale` absent from PATH (minimal/Alpine-style images), `locale -a` fails
silently, so `locale_installed` is false for everything except ""/C/POSIX. With `LC_ALL=C.UTF-8`
(working), the runner printed `Locale C.UTF-8 is not installed; running with LC_ALL=C` and ran the
suite in the non-UTF-8 C locale. The message is false, and suites that handle UTF-8 now run under
a different locale than the developer set. `pin_hermetic_locale` already had this fallback, so the
suites are not affected. The regression is in the runner's new pin.
**Fix:** in `locale_installed`, if `command -v locale` fails, return "unknown". The runner then
leaves the ambient locale alone (or tests it directly: `LC_ALL="$x" bash -c : 2>&1 | grep -q
setlocale`, which checks exactly the warning the pin exists to prevent and needs no `locale`
binary).

### C6. The runner now needs a writable repo root; `mkdir` fails under `set -e` with a raw error
**Location:** `scripts/run-tests.sh:257`
**Scenario:** before this change the runner wrote nothing. Now `mkdir -p .bats/.bats/run-logs` and
`: > anchor` run before bats. A read-only checkout, or `scripts/confine-tests.sh` (bwrap
`--ro-bind / /` with only `$PWD` bind-mounted read-write) invoked from a subdirectory, aborts with
a bare `mkdir: … Read-only file system` before any test runs. health-check calls the runner from
`$REPO_ROOT` (`scripts/health-check.sh:381-389`), so today's gate is unaffected.
**Fix:** if the log directory cannot be created, warn ("run log disabled; --failed unavailable")
and hand bats the files without the anchor. Make `--failed` alone the case that errors.

### C7. Run logs are never pruned
**Location:** `scripts/run-tests.sh:257`, `.gitignore`
**Scenario:** every run now leaves a log, two per health-check. `.bats/.bats/run-logs/` grows
without bound, and `--failed` and bats both list it on every filtered run.
**Fix:** keep the newest N (for example 20) after writing. This fits naturally with MA1 fix 2,
since the runner no longer `exec`s.

### C8. FILE paths are relative to the repo root, not the CWD
**Location:** `scripts/run-tests.sh:30-31`, `scripts/run-tests.sh:101`
**Scenario:** from `test/scripts/`, a tab-completed `run-tests.bats` fails with "no such test
file". A CWD-relative path that happens to exist relative to the repo root selects a *different*
file. This is documented, but surprising.
**Fix:** try the path relative to `$PWD` first, and fall back to the repo root. Alternatively,
error when both exist and differ.

### C9. Portability: GNU `find -printf` and bash-4 features on the runner's path
**Location:** `scripts/run-tests.sh:220` (`-printf`), `test/lib/hermetic-env.bash` (`${codeset,,}`,
now sourced by the runner), `scripts/run-tests.sh` (`mapfile`, empty `"${bats_args[@]}"` under
`set -u` on bash < 4.4)
**Scenario:** on macOS with `/bin/bash` 3.2, or with BSD find, `--failed` or the whole runner
breaks. This matters only if non-GNU hosts are supported; the devcontainer is GNU/bash 5.
**Fix:** `ls -1r "$RUN_LOG_DIR"`, exactly what bats uses, drops `-printf` and removes any
selection mismatch. Otherwise, note GNU/bash ≥ 4.4 as a requirement in the header.

### C10. Test gaps in `test/scripts/run-tests.bats`
**Location:** `test/scripts/run-tests.bats`
- No test for a path with spaces, although dropping the word-split `exec bats $matched` is a main
  point of the change. The probe confirms it works (repo root `my repo/`, file `test/sub dir/…`),
  but nothing guards it.
- No test for `..` escape (`test/../outside.bats`), duplicates (C4), `--` separator, or an
  interrupted/partial log (MA1).
- Line 76 asserts `running with LC_ALL=C.UTF-8`. On a host without C.UTF-8 the runner correctly
  pins `C` and the test fails. `runner()` also hardcodes `LC_ALL=C.UTF-8`. Assert
  `running with LC_ALL=C*`, or compute the expected value with `locale_installed`.

## Verified clean

- **Word-splitting:** `mapfile -t files <<< "$matched"` plus `"${files[@]}"` fixes the old
  `exec bats $matched`. The probe ran suites under a repo root and a subdirectory that both contain
  spaces. Newlines in filenames would still break the newline-joined `matched`; that is acceptable.
- **Anchor:** bats uses `${1%/*}` as the log root (bats-exec-suite:183-186), so the empty anchor
  file first reliably lands logs in `.bats/.bats/run-logs/`. `setup_suite.bash` discovery scans
  every filename (bats:415-428), so the anchor does not hide a future `test/setup_suite.bash`. The
  anchor has no `.bats` extension and lives outside `test/`, so find-based gates (hermeticity-lint,
  the shellcheck gate) do not pick it up.
- **`set -euo pipefail`:** the `grep … | … || true` at :227 and the `[[ … ]] || printf` at :144
  are correct. The empty `bats_args` expansion is fine on bash ≥ 4.4.
- **health-check.sh:** calls `$runner --fast` and then `--slow` from `$REPO_ROOT`. The new stdout
  locale line and the log writes don't affect its exit-status logic or `RUN_TESTS_NOT_RUN_FILE`.
  The other suite that copies the runner, `eval-helpers-gating.bats`, was updated to copy
  `test/lib/hermetic-env.bash`. No other suite copies or invokes the real runner. The caveat is C6
  (unwritable root).
- **Hermeticity of `test/scripts/run-tests.bats`:** ran it once (11/11 ok). It runs a copied runner
  in `$BATS_TEST_TMPDIR/repo` with fixture suites only, and the real suite never runs. `env -i`
  strips inherited bats state, and TMPDIR points inside the bats temp dir (cleaned by bats). No
  network binaries are used. The worktree's `git status` was clean afterward.

## Goal-Alignment Note

- **Answered:** U1 reviewed for correctness and robustness across every focus area requested:
  FILE handling (spaces, globs, `..`, symlinks, absolute paths, duplicates), word-splitting,
  `set -euo pipefail`, `--failed` (stale, different-selection, interrupted logs), concurrent runs,
  a missing `locale`, test hermeticity, and health-check interplay. One Must Address (MA1) blocks a
  clean merge verdict. Everything else is Consider.
- **Out of scope:** did not run the full suite or health-check (as instructed). Did not review the
  other units or commits outside c2322a2. The macOS/BSD portability item (C9) was reasoned from the
  code and not executed.
- **Escalate:** whether `--failed` should ever exit 0 on a partial or foreign-scope log (MA1/C1) is
  a product call for the author. Fix 2 of MA1 (drop `exec`, add a completion marker) changes the
  runner's process model slightly, because bats is no longer the runner's direct replacement.
