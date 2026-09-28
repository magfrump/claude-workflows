Commit: c2322a2

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `u1-run-tests`, branch `feat/u1-run-tests`)
**Scope:** branch diff `main...c2322a2` — `.gitignore`, `scripts/run-tests.sh`, `test/lib/hermetic-env.bash`, `test/scripts/run-tests.bats`, `test/skills/eval-helpers-gating.bats`, and the commit message
**Checked:** 2026-09-28
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 26
**Summary:** 20 verified, 5 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Legibility-target: every claim below is a statement a future maintainer of `run-tests.sh` (or a
user reading `--help`) acts on; verdicts are scoped to what that reader would assume.

Hallucination-pattern log (`/workspace/docs/reviews/hallucination-patterns.md`) was read; no
claim matches a logged pattern.

Execution provenance. All executed probes ran on 2026-09-28 between 18:32:38Z and 18:35:25Z
under bash (not the zsh tool shell), against copies of the worktree's files in throwaway
directories under the scratchpad, never against the real suite. Captured output lives
**outside the worktree** (the brief allows edits only to this report), in
`/tmp/claude-1000/-workspace/fe8d5f41-d34b-4387-9352-6d6b13c2ada9/scratchpad/u1-cfc-logs/`
(abbreviated below as `LOGS/`):

| Log | Command | cwd | Exit |
|---|---|---|---|
| `LOGS/suite.txt` | `LC_ALL=C.UTF-8 timeout 600 bats test/scripts/run-tests.bats` (timed) | worktree | 0 |
| `LOGS/locale.txt` | `timeout 30 bash LOGS/locale-probe.sh` | worktree | 0 |
| `LOGS/probe.txt` | `timeout 120 bash LOGS/probe.sh <worktree>` | throwaway repo | 0 |
| `LOGS/probe2.txt` | `timeout 60 bash LOGS/probe2.sh <worktree> LOGS` | throwaway repo | 0 |
| `LOGS/probe3.txt` | `timeout 60 bash LOGS/probe3.sh <worktree> LOGS` | throwaway repo | 0 |
| `LOGS/probe4.txt` | `timeout 60 bash LOGS/probe4.sh <worktree> LOGS` | throwaway repo | 0 |
| `LOGS/eval-gating.txt` | `LC_ALL=C.UTF-8 timeout 300 bats test/skills/eval-helpers-gating.bats` | worktree | 0 |

The probe scripts themselves are saved next to their logs. The sandbox's ambient
`LC_ALL=en_US.UTF-8` is not installed (`locale -a` lists only `C`, `C.utf8`, `POSIX`), so
it served as a live "broken locale" throughout.

---

## Claim 1: "bats run logs and the runner's log anchor (scripts/run-tests.sh "Run logs"; --failed reads them)"

**Location:** `.gitignore:41-43`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `.bats/` holds exactly the anchor and the run-log tree and that `--failed` reads from it; does not establish that nothing else in the repo writes into `.bats/`.

The ignored path matches the runner's constants, `RUN_LOG_ANCHOR="$REPO_ROOT/.bats/run-log-anchor"`
and `RUN_LOG_DIR="$REPO_ROOT/.bats/.bats/run-logs"` (`scripts/run-tests.sh:63-64`). After a run
the probe repo's `.bats/` held only `run-log-anchor` and `.bats/run-logs/*.log` (paraphrased — no
quote available because the evidence is a directory listing in `LOGS/probe.txt`, "== logs").

**Evidence:** `scripts/run-tests.sh:63-64`, `scripts/run-tests.sh:214-222`, `LOGS/probe.txt`

---

## Claim 2: "RUN_TESTS_NOT_RUN_FILE  When set, the number of report-dependent suites gated out is written to this file" (health-check.sh contract unchanged)

**Location:** `scripts/run-tests.sh:18-20`
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `--fast`/`--slow` are still accepted, the NOT-RUN count is still written before any `--failed`/bats step, and `scripts/health-check.sh` is untouched by the diff; does not establish health-check's end-to-end behaviour (not run, per brief) nor that `--failed` after a health-check run sees fast-gate failures (the `--slow` run's log is the "last run").

The write is unchanged and still precedes the new `--failed` block:

```bash
# scripts/run-tests.sh:203-205
if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
fi
```

A FILE-selected gated suite wrote `nr=1` (`LOGS/probe.txt`, "gated FILE, NOT RUN file").
`git diff --stat main...HEAD` lists no change to `scripts/health-check.sh`, which still calls
`HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast`
(`scripts/health-check.sh:389`) and the `--slow` twin (`:397`); `HEALTH_CHECK_SKIP_BATS` is read
only by health-check (`scripts/health-check.sh:371`), not by the runner.

**Evidence:** `scripts/run-tests.sh:203-205`, `scripts/health-check.sh:371-397`, `LOGS/probe.txt`

---

## Claim 3: "Usage: scripts/run-tests.sh [--fast|--slow|--all] [--failed] [FILE...]" and the flag list

**Location:** `scripts/run-tests.sh:16`, `scripts/run-tests.sh:31-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every documented flag is parsed, `--help` prints the new header through the Locale paragraph, unknown `-*` flags exit 1 with the new usage line, and `--` ends flag parsing; does not establish that the undocumented `--` separator is intended API.

Parsing (`scripts/run-tests.sh:78-96`) accepts `--fast|--slow|--all|--failed`, `--) shift; requested+=("$@"); break`,
rejects `-*` with `usage; exit 1`, and treats anything else as a FILE. Executed: `--help` printed
the full header including "Run logs" and "Locale" (exit 0); `--bogus` printed
`Unknown flag: --bogus` + the usage line (exit 1); `--fast -- test/a.bats` ran `a.bats` (exit 0)
(`LOGS/probe.txt`).

**Evidence:** `scripts/run-tests.sh:16`, `scripts/run-tests.sh:66-97`, `LOGS/probe.txt`

---

## Claim 4: "--failed  Re-run only the tests that failed in the last completed run (bats --filter-status failed)."

**Location:** `scripts/run-tests.sh:38-39`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers file selection (only files with a `failed` line in the last log) and bats' per-test filter; does not establish behaviour for test IDs renamed since the last run beyond the new-test case probed.

Within the kept files, bats' `failed` filter keeps every test **not recorded as passed**, not
only recorded failures:

```bash
# /usr/libexec/bats-core/bats-exec-suite:206-209
  failed)
    bats_filter_test_by_status() { # <line>
      ! bats_binary_search "$1" "passed_tests"
    }
```

Executed: after a run where `flaky` failed, appending `@test "brand new"` to the same file and
running `--failed` ran both `flaky` and `brand new` (`1..2 … ok 2 brand new`, `LOGS/probe3.txt`).
Tests in files with no recorded failure are excluded by the runner's own file filter
(`scripts/run-tests.sh:218-235`). Precise version: "re-runs, in the files that had a failure in
the last run, every test that did not pass in it (failures, plus tests added since)."

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:206-209`, `/usr/libexec/bats-core/bats-exec-suite:261-269`, `scripts/run-tests.sh:214-240`, `LOGS/probe3.txt`

---

## Claim 5: "Combines with the category flags and FILE... to narrow further."

**Location:** `scripts/run-tests.sh:39-40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the category/FILE selection is computed first and `--failed` intersects it; does not establish behaviour when the last run itself was narrower than the current selection (failures outside the last run's selection are invisible, consistent with "last completed run").

The `--failed` block filters `$matched`, which is already the category- and FILE-filtered,
report-gated list (`while IFS= read -r f; do … done <<< "$matched"`, `scripts/run-tests.sh:229-234`).
Suite test 10 (`--failed --slow` after a run whose only failure is fast) passed
(`LOGS/suite.txt`, `ok 10`).

**Evidence:** `scripts/run-tests.sh:217-240`, `test/scripts/run-tests.bats:156-163`, `LOGS/suite.txt`

---

## Claim 6: "Exits 1 when no run is recorded, 0 with a message when the last run had no failures in scope."

**Location:** `scripts/run-tests.sh:40-41`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both documented exits and their messages; does not establish (and the text omits) the case where every selected file is gated out.

Both documented paths hold: fresh repo, `--failed test/a.bats` →
`--failed: no recorded run in .bats/.bats/run-logs; run the tests without --failed first`, exit 1
(`LOGS/probe2.txt`); a log with no in-scope failures → `--failed: no failed tests in the last
recorded run (…) among the selected files; nothing to re-run`, exit 0 (`LOGS/probe.txt`). But the
no-log check only runs when something survived gating:

```bash
# scripts/run-tests.sh:217
if [[ "$failed_only" == true && -n "$matched" ]]; then
```

so on a fresh repo `--failed test/gated.bats` (report-gated) exits **0** with
`No runnable test files after report-gating for category: all` and no mention of a missing
recording (`LOGS/probe2.txt`). Precise version: "Exits 1 when no run is recorded (and some
selected file is runnable)…".

**Evidence:** `scripts/run-tests.sh:217-246`, `LOGS/probe.txt`, `LOGS/probe2.txt`

---

## Claim 7: "FILE...   Run only these .bats files (absolute, or relative to the repo root; each must be under test/). The category flags filter them; the tag check and report gating apply as in a full run."

**Location:** `scripts/run-tests.sh:42-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers absolute and repo-root-relative paths, missing/non-`.bats`/directory arguments (exit 1), paths outside `test/` (exit 1), category filtering, the untagged check, `@needs-reports` gating and the NOT-RUN count for named files; does not establish handling of paths relative to a CWD other than the repo root (they resolve against the root by design) or symlinked path components.

Relative paths are anchored at the repo root, not the CWD:
`[[ "$path" == /* ]] || path="$REPO_ROOT/$path"` (`scripts/run-tests.sh:117`); a non-file or
non-`.bats` path gives `ERROR: no such test file` and `exit 1` (`:118-121`); a path outside
`$TEST_DIR` gives `ERROR: not under test/` and `exit 1` (`:123-126`). The named files feed the
unchanged `collect_tests` (untagged → error) and gating loop. Executed: `test/sub` (directory) and
`scripts/run-tests.sh` (non-.bats) → exit 1 (`LOGS/probe.txt`); a gated named file → NOT RUN,
`nr=1` (`LOGS/probe.txt`); suite tests 4-7 (both path forms, missing/outside, untagged,
`--slow` over two named files) passed (`LOGS/suite.txt`). Note the non-`.bats` case reports "no
such test file" although the file exists (paraphrased — no quote available because this is an
observation about message wording, from `LOGS/probe.txt`).

**Evidence:** `scripts/run-tests.sh:111-160`, `scripts/run-tests.sh:171-212`, `LOGS/probe.txt`, `LOGS/suite.txt`

---

## Claim 8: "bats 1.8.2 puts its run-log directory next to the FIRST file it is handed, and records nothing when that directory is missing … the log then lands in .bats/.bats/run-logs/ whatever the selection."

**Location:** `scripts/run-tests.sh:46-51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers installed bats 1.8.2 (`/usr/libexec/bats-core`) with the anchor as first argument, for first files in `test/` and `test/sub/`; does not establish behaviour of other bats versions or of `--jobs` parallel runs.

```bash
# /usr/libexec/bats-core/bats-exec-suite:184-195
TEST_ROOT=${1-}
TEST_ROOT=${TEST_ROOT%/*}
BATS_RUN_LOGS_DIRECTORY="$TEST_ROOT/.bats/run-logs"
if [[ ! -d "$BATS_RUN_LOGS_DIRECTORY" ]]; then
  if [[ -n "$filter_status" ]]; then
    printf "Error: --filter-status needs '%s/' ..."
    exit 1
  else
    BATS_RUN_LOGS_DIRECTORY=
  fi
  # discard via sink instead of having a conditional later
  export BATS_RUNLOG_FILE='/dev/null'
```

`$1` is the first filename after flag parsing: the `bats` front end passes
`bats-exec-suite "${flags[@]}" "${filenames[@]}"` (`/usr/libexec/bats-core/bats:459`) in
argument order. With `.bats/run-log-anchor` first, `TEST_ROOT` is `$REPO_ROOT/.bats` and logs go to
`$REPO_ROOT/.bats/.bats/run-logs`. Executed: probe runs left logs in `.bats/.bats/run-logs/` and no
`test/.bats` (`LOGS/probe.txt`); a plain `bats test/a.bats` with no `test/.bats/run-logs` created
nothing (`LOGS/probe2.txt`); suite test 8 (first file in `test/sub/`) passed (`LOGS/suite.txt`).
The commit message's matching note ("bats 1.8.2 puts run logs next to the FIRST file it is handed,
not the CWD … logs land in .bats/.bats/run-logs/") is covered by this verdict. `bats --version`
reports `Bats 1.8.2`.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:184-200`, `/usr/libexec/bats-core/bats:414-464`, `scripts/run-tests.sh:214-222`, `LOGS/probe.txt`, `LOGS/probe2.txt`, `LOGS/suite.txt`

---

## Claim 9: "An interrupted (Ctrl-C) run is not recorded."

**Location:** `scripts/run-tests.sh:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers SIGINT delivered to the runner process (which `exec`s bats); does not establish SIGTERM/SIGKILL behaviour (a killed bats leaves a partial log).

```bash
# /usr/libexec/bats-core/bats-exec-suite:355-358
  if [[ -d "$BATS_RUN_LOGS_DIRECTORY" && -n "${BATS_INTERRUPTED:-}" ]]; then
    # aborting a test run with CTRL+C does not save the runlog file
    rm "$BATS_RUNLOG_FILE"
  fi
```

Executed: `timeout -s INT 2 bash scripts/run-tests.sh test/s.bats` printed
`# Received SIGINT, aborting ...` and left `run-logs/` empty; an uninterrupted rerun wrote one log
(`LOGS/probe4.txt`).

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:351-358`, `LOGS/probe4.txt`

---

## Claim 10: "when the ambient locale (LC_ALL, else LANG) is not installed, every bash subprocess prints a setlocale warning to stderr, and bats' `run` folds that into the $output … exports LC_ALL=C.UTF-8 (C when that is missing too) and says so; a working locale is left alone."

**Location:** `scripts/run-tests.sh:53-57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers LC_ALL-broken, LANG-broken (LC_ALL unset), working-locale, and C.UTF-8-missing cases; does not establish handling when only an individual `LC_*` category (e.g. `LC_CTYPE`) is broken — the header's "(LC_ALL, else LANG)" correctly scopes that out.

```bash
# scripts/run-tests.sh:103-109
ambient_locale="${LC_ALL:-${LANG:-}}"
if ! locale_installed "$ambient_locale"; then
  pinned=C
  locale_installed C.UTF-8 && pinned=C.UTF-8
  export LC_ALL="$pinned"
  echo "Locale $ambient_locale is not installed; running with LC_ALL=$pinned"
fi
```

Executed: plain `bats test/gamma.bats` under `LC_ALL=xx_XX.UTF-8` failed `gamma clean output`
because the warning reached `$output` (`LOGS/probe3.txt`); with a fake `locale` printing only
`C`/`POSIX`, the runner printed `…running with LC_ALL=C` and passed (`LOGS/probe.txt`); suite
tests 1-3 (C.UTF-8 pin via LC_ALL and via LANG, working locale untouched) passed
(`LOGS/suite.txt`).

**Evidence:** `scripts/run-tests.sh:100-109`, `LOGS/probe.txt`, `LOGS/probe3.txt`, `LOGS/suite.txt`

---

## Claim 11: "bats picks the previous log as the first of `ls -1r` in the log directory; the same pick here, so the file selection and bats' test filter read one log."

**Location:** `scripts/run-tests.sh:214-216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers a log directory holding only `*.log` files, read by the runner and by the `exec`'d bats under the same environment (same collation); does not establish agreement if a non-`.log` entry sorts last (bats' `ls -1r` would pick it; the runner's `find -name '*.log'` would not).

```bash
# /usr/libexec/bats-core/bats-exec-suite:227
  if IFS='' read -d $'\n' -r BATS_PREVIOUS_RUNLOG_FILE < <(ls -1r "$BATS_RUN_LOGS_DIRECTORY"); then
```

```bash
# scripts/run-tests.sh:220
    last_log="$(find "$RUN_LOG_DIR" -maxdepth 1 -type f -name '*.log' -printf '%f\n' | sort -r | head -n1)"
```

Both are reverse name sorts under the locale the runner `exec`s bats with (paraphrased — no quote
available because "same collation" is an inference from `exec` preserving the environment, not a
single line). Confidence is Medium because the equivalence of `ls -1r` and `sort -r` ordering is
reasoned, not executed across locales.

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:227-228`, `scripts/run-tests.sh:217-222`, `scripts/run-tests.sh:270`

---

## Claim 12: "Log lines are "failed <absolute file>\t<test id>"."

**Location:** `scripts/run-tests.sh:226`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the format written by bats-exec-test and that the file part is absolute for the paths the runner passes; does not establish the format of `status-filtered …` lines (which the runner's `grep '^failed '` correctly ignores).

```bash
# /usr/libexec/bats-core/bats-exec-test:186
    printf "%s %s\t%s\n" "$state" "$BATS_TEST_FILENAME" "$BATS_TEST_NAME" >>"$BATS_RUNLOG_FILE"
```

The runner hands bats absolute paths (`find "$TEST_DIR"` with absolute `TEST_DIR`, or
`$(cd … && pwd)/…` at `scripts/run-tests.sh:122`), and bats' `expand_path` keeps them as
`$PWD`-style logical paths (`/usr/libexec/bats-core/bats:79-92`), matching the runner's own
`cd && pwd` form so the `grep -qxF` comparison lines up.

**Evidence:** `/usr/libexec/bats-core/bats-exec-test:186`, `/usr/libexec/bats-core/bats:79-92`, `scripts/run-tests.sh:122`, `scripts/run-tests.sh:226-235`

---

## Claim 13: "Pass all matched files to bats in a single invocation for proper TAP output, the (test-free) run-log anchor first"

**Location:** `scripts/run-tests.sh:267-269`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the empty anchor contributes no tests to the plan line and that all files go to one bats call; does not establish formatter output other than TAP.

`: > "$RUN_LOG_ANCHOR"` creates an empty file and
`exec bats "${bats_args[@]}" "$RUN_LOG_ANCHOR" "${files[@]}"` (`scripts/run-tests.sh:262-269`) is a
single call. Two named files produced `1..2` (suite test 4, `LOGS/suite.txt`); one file `1..1`
(`LOGS/probe.txt`).

**Evidence:** `scripts/run-tests.sh:260-269`, `LOGS/probe.txt`, `LOGS/suite.txt`

---

## Claim 14: "scripts/run-tests.sh also sources this file for `locale_installed`, so that "installed" has one definition for the runner and the suites."

**Location:** `test/lib/hermetic-env.bash:9-10`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the runner and `pin_hermetic_locale`; does not establish that no other suite has its own `locale -a` check.

`source "$TEST_DIR/lib/hermetic-env.bash"` (`scripts/run-tests.sh:102`) and
`if locale_installed "$candidate"; then` inside `pin_hermetic_locale`
(`test/lib/hermetic-env.bash:30`). The commit message's "now also used by pin_hermetic_locale" is
covered here.

**Evidence:** `scripts/run-tests.sh:101-102`, `test/lib/hermetic-env.bash:27-41`

---

## Claim 15: "_locale_normalize <name>: glibc's codeset normalisation, so "en_US.UTF-8" … and "en_US.utf8" … compare equal: the codeset part is lowercased and stripped of non-alphanumerics."

**Location:** `test/lib/hermetic-env.bash:42-44`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the described lowercase-and-strip behaviour and the UTF-8/utf8 equality; does not establish full parity with glibc's `_nl_normalize_codeset`.

The implementation does what the second half says (`codeset="${codeset,,}"`,
`codeset="${codeset//[^a-z0-9]/}"`, `test/lib/hermetic-env.bash:54-55`), and `C.UTF-8`, `C.Utf-8`,
`C.UTF8` all matched the listed `C.utf8` (`LOGS/locale.txt`). The attribution "glibc's codeset
normalisation" is imprecise: glibc additionally prefixes `iso` to an all-digit codeset, whereas
here `xx.8859-1` → `xx.88591` (`LOGS/locale.txt`) (paraphrased — no quote available because glibc's
source is not in the sandbox; the glibc behaviour is from `intl/l10nflist.c` as known, not read
here — hence Medium). Precise version: "a simplified form of glibc's codeset normalisation".

**Evidence:** `test/lib/hermetic-env.bash:42-62`, `LOGS/locale.txt`

---

## Claim 16: "locale_installed <name>: succeed when setting LC_ALL=<name> would not make bash warn. Empty (unset), C and POSIX always exist; anything else must be in `locale -a`, compared after normalising the codeset."

**Location:** `test/lib/hermetic-env.bash:64-66`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism (short-circuit for ""/C/POSIX, normalised `locale -a` match) and agreement with bash's warning for 11 names; does not establish exact equivalence with bash for names carrying an `@modifier`.

Mechanism matches (`case "$1" in ""|C|POSIX) return 0 ;;` then a normalised loop over
`locale -a`, `test/lib/hermetic-env.bash:67-77`). Against `LC_ALL=<name> bash -c true`, 10 of 11
probed names agreed; `C.utf8@foo` returned not-installed although bash printed no warning
(`[C.utf8@foo] installed=1 bash_warn=[]`, `LOGS/locale.txt`). The mismatch is conservative (it
only causes an unneeded pin), but the "succeed when … would not make bash warn" equivalence is not
exact.

**Evidence:** `test/lib/hermetic-env.bash:64-77`, `LOGS/locale.txt`

---

## Claim 17: "# @category slow"

**Location:** `test/scripts/run-tests.bats:2`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repo's definition of slow ("integration tests, script execution / file I/O", `scripts/run-tests.sh:36`) and measured runtime on this machine; does not establish runtime on other hosts.

Every test runs a copied runner that `exec`s a real bats over fixture files — script execution
and file I/O. Timed: 11 tests in 4.16 s wall (`LOGS/suite.txt`; timing from the probe command),
above the fast tier's "<1s each" pure-function bar for the file as a whole.

**Evidence:** `test/scripts/run-tests.bats:10-17`, `scripts/run-tests.sh:35-36`, `LOGS/suite.txt`

---

## Claim 18: "Runs a copy of the script in a throwaway repo layout whose test/ holds small fixture suites, with the real bats, so --failed reads real bats run logs. The real suite never runs."

**Location:** `test/scripts/run-tests.bats:3-6`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `setup()` copying into `$BATS_TEST_TMPDIR/repo` and every runner call targeting `$T`; does not establish that `bats` on the scrubbed PATH is the same binary as the outer run's.

`T="$BATS_TEST_TMPDIR/repo"` and `cp "$REPO_ROOT/scripts/run-tests.sh" "$T/scripts/"`
(`test/scripts/run-tests.bats:11-13`); every call is `bash "$T/scripts/run-tests.sh" "$@"`
(`:52-53`), whose `REPO_ROOT` derives from `$0`, so only `$T/test` fixtures are found.

**Evidence:** `test/scripts/run-tests.bats:8-28`, `test/scripts/run-tests.bats:44-54`, `scripts/run-tests.sh:61-62`

---

## Claim 19: "Fixture suites are written with printf, not a heredoc: this file's own bats preprocessor would rewrite any line that starts with @test."

**Location:** `test/scripts/run-tests.bats:17-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers bats 1.8.2's line-based test pattern; does not establish whether a quoted `'@test …'` inside a printf argument could ever match (it cannot start a line, so it does not).

```bash
# /usr/libexec/bats-core/bats-preprocess:34
BATS_TEST_PATTERN="^[[:blank:]]*@test[[:blank:]]+(.*[^[:blank:]])[[:blank:]]+\{(.*)\$"
```

The pattern is applied per line with no heredoc awareness (paraphrased — no quote available
because the "no heredoc awareness" point is the absence of any heredoc handling in the file), so a
heredoc body line beginning `@test` would be rewritten.

**Evidence:** `/usr/libexec/bats-core/bats-preprocess:34-35`

---

## Claim 20: "gamma: fails when a bash subprocess prints a setlocale warning into $output."

**Location:** `test/scripts/run-tests.bats:23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture under an uninstalled `LC_ALL` without the runner's pin; does not establish failure for every broken-locale variant.

Executed a byte-identical `gamma.bats` with plain `bats` under `LC_ALL=xx_XX.UTF-8`:
`not ok 1 gamma clean output`, exit 1 (`LOGS/probe3.txt`). This also makes suite test 1
discriminating: without the pin, the fixture would fail.

**Evidence:** `test/scripts/run-tests.bats:23-25`, `LOGS/probe3.txt`

---

## Claim 21: in_runner comment — "bats prepends its libexec dir to PATH (whose `bats` skips the setup the real one does), and fd 3 is this run's TAP stream"

**Location:** `test/scripts/run-tests.bats:37-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the PATH prepend, the exported `BATS_*` state, and `/usr/bin/bats` being a separate wrapper from `libexec/bats-core/bats`; does not establish exactly which wrapper setup the libexec copy skips.

```bash
# /usr/libexec/bats-core/bats:98-101
export BATS_LIBEXEC
export BATS_CWD="$PWD"
export BATS_TEST_FILTER=
export PATH="$BATS_LIBEXEC:$PATH"
```

`/usr/bin/bats` is a distinct bash wrapper (`set -euo pipefail`, `bats_readlinkf` resolution)
(paraphrased — no quote available because the wrapper's setup spans its first ~60 lines). The
helper strips `$BATS_LIBEXEC` from PATH, uses `env -i`, and closes fd 3 (`3>&-`),
`test/scripts/run-tests.bats:45-53`.

**Evidence:** `/usr/libexec/bats-core/bats:98-107`, `/usr/bin/bats:1-40`, `test/scripts/run-tests.bats:44-54`

---

## Claim 22: "bats names logs by the second, so two runs within one second would share (or misorder) a log"

**Location:** `test/scripts/run-tests.bats:59-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the log naming, append-on-same-name, and the `-N` suffix ordering in C.UTF-8; does not establish ordering under other collations.

`BATS_RUNLOG_DATE=$(date -u '+%Y-%m-%d %H:%M:%S UTC')` (`bats-exec-suite:198`) and results are
appended with `>>` (`bats-exec-test:186`), so two plain runs in one second share a file; under
`--filter-status` a collision becomes `${BATS_RUNLOG_DATE}-$count.log` (`bats-exec-suite:231`), and
`printf 'a UTC.log\na UTC-1.log\n' | LC_ALL=C.UTF-8 sort -r` puts `UTC.log` (the older) first —
the misorder (paraphrased — no quote available because this one-liner's output was read inline,
not captured to a file).

**Evidence:** `/usr/libexec/bats-core/bats-exec-suite:198-231`, `/usr/libexec/bats-core/bats-exec-test:186`

---

## Claim 23: test names 1-7 and 9-11 in the new suite describe what they assert

**Location:** `test/scripts/run-tests.bats:63-171` (tests at `:63`, `:70`, `:76`, `:83`, `:92`, `:103`, `:110`, `:126`, `:148`, `:157`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the correspondence of each name to its assertions and that all pass; does not establish the full precision of `--failed` semantics (see Claim 4) — test 9's "only the last run's failures" holds for its fixtures, which add no new tests.

Each body asserts its name: e.g. test 2 asserts `*"Locale xx_XX.UTF-8 is not installed"*` with
`LANG=` only (`:70-74`); test 5 asserts both `no such test file: test/nope.bats` and
`not under test/: outside.bats` with status 1 (`:92-101`); test 9 asserts `1..1`, `ok 1 alpha
flaky`, no `alpha steady`/`beta`, then the "no failed tests" message (`:126-146`); test 11 asserts
status 1 and `--failed: no recorded run` (`:157-161`). All 11 passed (`LOGS/suite.txt`).

**Evidence:** `test/scripts/run-tests.bats:63-171`, `LOGS/suite.txt`

---

## Claim 24: "every run records a log under .bats/ whatever the first file's directory"

**Location:** `test/scripts/run-tests.bats:118`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the test body asserts; does not establish the "whatever the first file's directory" generalisation beyond the single case exercised.

The body exercises one first-file directory (`runner test/sub/beta.bats`) and its load-bearing
assertion is `[ "$(ls "$LOG_DIR" | wc -l)" -eq 1 ]` (`test/scripts/run-tests.bats:122`). The
further check `[ ! -e "$T/test/sub/.bats" ]` (`:123`) cannot fail with or without the anchor,
since bats never creates a missing run-log directory (`BATS_RUNLOG_FILE='/dev/null'`,
`bats-exec-suite:195`; confirmed by `LOGS/probe2.txt`). Precise name: "a run whose first file is
in a subdirectory still records its log under .bats/".

**Evidence:** `test/scripts/run-tests.bats:118-124`, `/usr/libexec/bats-core/bats-exec-suite:187-195`, `LOGS/probe2.txt`

---

## Claim 25: "Fixes the 5 tests whose $output caught bash's setlocale warning."

**Location:** commit message `c2322a2`, "Locale pin" bullet
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about the count; the mechanism is verified in Claim 10.

Verifying "5 tests" requires running the full suite under the broken ambient locale before and
after the change, which the brief forbids (paraphrased — no quote available because the claim
concerns suites not in the diff). Needed: `scripts/run-tests.sh` on `main` vs `c2322a2` with
`LC_ALL=en_US.UTF-8` uninstalled, diffing the `not ok` set.

**Evidence:** commit `c2322a2` message; `scripts/run-tests.sh:100-109`

---

## Claim 26: "No RUN_TESTS_DIR seam was added: the suite copies the script into a throwaway repo layout (REPO_ROOT derives from $0), the pattern eval-helpers-gating already uses." / "eval-helpers-gating.bats now copies hermetic-env.bash into its fixture tree, which the runner sources."

**Location:** commit message `c2322a2`, Notes; `test/skills/eval-helpers-gating.bats:15-16`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absence of a `RUN_TESTS_DIR` variable, `REPO_ROOT` derivation, and that eval-helpers-gating passes with the new copy; does not establish that it would fail without the copy (not executed; follows from `set -e` + `source` at `scripts/run-tests.sh:102`).

`REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"` (`scripts/run-tests.sh:61`); eval-helpers-gating
already did `cp "$REPO_ROOT/scripts/run-tests.sh" "$T/scripts/"` and now adds
`cp "$REPO_ROOT/test/lib/hermetic-env.bash" "$T/test/lib/"`. Executed: 6/6 ok (`LOGS/eval-gating.txt`).

**Evidence:** `scripts/run-tests.sh:61-64`, `test/skills/eval-helpers-gating.bats:13-16`, `LOGS/eval-gating.txt`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 4** (`scripts/run-tests.sh:38-39`): `--failed` re-runs every test in the failing files that did not *pass* last run — including tests added since — not only the recorded failures.
- **Claim 6** (`scripts/run-tests.sh:40-41`): "Exits 1 when no run is recorded" does not hold when every selected file is report-gated; that path exits 0 with "No runnable test files".
- **Claim 15** (`test/lib/hermetic-env.bash:42-44`): simplified, not full, glibc normalisation (no `iso` prefix for all-digit codesets).
- **Claim 16** (`test/lib/hermetic-env.bash:64-66`): not exactly "would not make bash warn" for `@modifier` names (e.g. `C.utf8@foo`: reported missing, bash silent); error is conservative.
- **Claim 24** (`test/scripts/run-tests.bats:118`): name generalises from one case; `[ ! -e "$T/test/sub/.bats" ]` is vacuous.

### Unverifiable
- **Claim 25** (commit message): "5 tests" needs a before/after full-suite run under the broken locale, out of scope for this pass.

## Goal-Alignment Note

- **Answered:** all seven brief items — (1) Claim 8 (bats source :184-195, executed); (2) Claims 4-6 (with two imprecisions); (3) Claims 10, 15, 16; (4) Claims 2-3, 7; (5) Claim 7; (6) Claims 23-24; (7) Claim 17 (4.16 s for 11 tests).
- **Out of scope:** the full suite and health-check were not run (per brief), so Claim 25 stays Unverifiable; captured logs live in the scratchpad, not the worktree, because only this report may be edited.
- **Escalate:** none blocking. Claim 6's gated-only `--failed` exit-0 path and Claim 4's "tests added since also run" are the two a user acting on `--help` could trip on.
