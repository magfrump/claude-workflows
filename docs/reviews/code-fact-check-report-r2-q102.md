Commit: 65c931e

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-q102-parallel-gates`, branch `feat/q102-parallel-gates`)
**Scope:** `git diff main...HEAD` at 65c931e6 (docs/roadmap.md, docs/working/questions-archive.md, scripts/health-check.sh, test/scripts/health-check.bats, workflows/pr-prep.md) plus the commit message of 65c931e6
**Checked:** 2026-10-14
**Total claims checked:** 19
**Summary:** 13 verified, 4 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). No claim below matches a logged fabrication pattern. Claims 13 and 16 resemble the "measured value quoted from an artifact set" family, but the artifact does contain the numbers. The defect is that they are applied to a different run shape, so they are not logged.

Execution provenance (all commands run in `/workspace/.claude/wt-q102-parallel-gates`; logs under `docs/reviews/execution-logs/`):

| Log | Command | Started (UTC) | Exit |
|---|---|---|---|
| `q102-r2-gate5.log` | `env -u RUN_TESTS_JOBS timeout 400 bats --filter 'gate 5' test/scripts/health-check.bats` | 2026-10-14T19:57:52Z | 0 (8/8 ok) |
| `q102-r2-gate5-ambient.log` | `RUN_TESTS_JOBS=abc timeout 300 bats --filter 'gate 5' test/scripts/health-check.bats` | ~2026-10-14T19:55:40Z | 1 (test 8 not ok) |
| `q102-r2-grammar.log` | loop: for each value, `env RUN_TESTS_JOBS=<v> HEALTH_CHECK_RUN_TESTS=/bin/true bash -c 'source scripts/health-check.sh; check_bats; echo FAIL=$FAIL'` beside run-tests.sh's regex | 2026-10-14T19:57:09Z | 0 |
| `q102-r2-fallback.log` | `timeout 300 bats --filter 'parallel.*(warns and runs serially)' test/scripts/run-tests.bats` | 2026-10-14T19:57:47Z | 0 (2/2 ok) |
| `q102-r2-gate-timing.log` | run-log mtimes and the tail of the in-progress gate's own log (`/home/node/.claude/jobs/00bcf178/tmp/hc.log`, `time scripts/health-check.sh` at 65c931e6) | 2026-10-14T19:59:27Z | 0 |

The first attempt at the gate-5 filter (2026-10-14T19:50:40Z, `timeout 300`) exited 124. Its `setup_file` runs the full `health-check.sh`, which waited on `health-check.lock` while the branch gate held it. This was an environmental block, not a defect. The clean rerun above replaced that log.

---

## Claim 1: "6. **Verify a branch without installing it on the host.**" (renumbered from 7 after removing the Q-102 item)

**Location:** `docs/roadmap.md:50`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the Next list is numbered 1–6 with no gap and that no doc under `docs/` (reviews excluded) refers to a roadmap Next item by number 6 or 7; does not establish that no out-of-repo note (checkpoints in other worktrees, session memory) cites "Next #7".
**Legibility-target:** for-orchestrator-synthesis

The Next section now reads `1. **Q-075 …` (`docs/roadmap.md:28`), `2. **Q-088 …` (`:32`), `3. **Q-089 …` (`:35`), `4. **Measure router uptake.**` (`:39`), `5. **A8 post-restructure token measurement.**` (`:46`), `6. **Verify a branch without installing it on the host.**` (`:50`). No reference to Q-102 remains in `docs/roadmap.md` (paraphrased — no quote available because the claim covers absence of code: `rg -n 'Q-102' docs/roadmap.md` returns nothing). A search for `(roadmap|Next)…(#|item )[67]` across `docs/` returned no hits (paraphrased — no quote available because the claim covers absence of matches).

**Evidence:** `docs/roadmap.md:26-55`

---

## Claim 2: "health-check.sh's gate 5 passes `--jobs "${RUN_TESTS_JOBS:-8}"` to both runs; 1 is serial, a value outside run-tests.sh's `--jobs` grammar fails the gate before any test runs, and the runner still falls back to serial without GNU parallel. pr-prep's step 5a names the default and the override."

**Location:** `docs/working/questions-archive.md:2516`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the expansion passed to both runs, the serial meaning of 1, rejection of non-empty out-of-grammar values before the runner is invoked, the runner's fallback, and pr-prep step 5a's text; does not establish the behaviour for an *empty* value, which is outside run-tests.sh's grammar yet does not fail the gate (see Claim 4b).
**Legibility-target:** for-author

Both runs pass the same validated value:

```bash
# scripts/health-check.sh:408-412
    local jobs="${RUN_TESTS_JOBS:-8}"
    if [[ ! "$jobs" =~ ^[1-9][0-9]{0,2}$ ]]; then
        fail "RUN_TESTS_JOBS='$jobs' is not 1 to 999 (digits only, no leading zero; 1 = serial) — BATS suites not run"
        return
    fi
```
(excerpt ends :412; enclosing check_bats() continues to :440 — read)

and `"$runner" --fast --jobs "$jobs"` (`scripts/health-check.sh:420`) / `"$runner" --slow --jobs "$jobs"` (`:428`). The executed gate-5 tests passed, including "a RUN_TESTS_JOBS outside run-tests.sh's grammar fails the gate and runs nothing" (`q102-r2-gate5.log`, ok 4). The imprecision: `RUN_TESTS_JOBS=` (empty) is outside run-tests.sh's `--jobs` grammar (run-tests.sh rejects `--jobs ""` at `scripts/run-tests.sh:144`). Because of `:-`, the gate instead treats it as unset and runs with 8 (`q102-r2-grammar.log`: `''	health-check:FAIL=0	run-tests-regex:reject`). The commit message says this. This entry does not. A precise version would read "a non-empty value outside …". The pr-prep part is Verified in Claims 12 and 14.

**Evidence:** `scripts/health-check.sh:408-412`, `scripts/health-check.sh:420`, `scripts/health-check.sh:428`, `scripts/run-tests.sh:141-150`, `docs/reviews/execution-logs/q102-r2-gate5.log`, `docs/reviews/execution-logs/q102-r2-grammar.log`

---

## Claim 3: "RUN_TESTS_JOBS  Test files check 5 runs at once, passed to the runner as --jobs (Q-102 [1]). Default 8; 1 runs serially."

**Location:** `scripts/health-check.sh:27-29`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default (unset → `--jobs 8` on both runs, seen in the stub log and in the live gate's bats process), and that 1 reaches the runner as `--jobs 1`, which run-tests.sh treats as serial; does not establish that "test files at once" is ever reached for N above the selected file count (the runner lowers N to the file count, `scripts/run-tests.sh:412`).
**Legibility-target:** for-orchestrator-synthesis

`local jobs="${RUN_TESTS_JOBS:-8}"` (`scripts/health-check.sh:408`) is passed as `--jobs "$jobs"` on both runs (`:420`, `:428`). In run-tests.sh, `if [[ "$jobs" -gt 1 ]]; then` (`scripts/run-tests.sh:413`) is the only path that adds `--jobs "$jobs" --no-parallelize-within-files` to bats (`:416`). So 1 runs bats without `--jobs`, which is serial. The executed tests "runs fast then slow when both are green" (stub log `--fast --jobs 8 skip=1` / `--slow --jobs 8 skip=1`) and "RUN_TESTS_JOBS sets --jobs for both runs; 1 is serial" both passed (`q102-r2-gate5.log`, ok 2–3). The in-progress branch gate showed `bats --jobs 8 --no-parallelize-within-files …` and `parallel --keep-order --jobs 8 …` in the process table (paraphrased — no quote available because the evidence is a `ps` snapshot taken during the review, not a file).

**Evidence:** `scripts/health-check.sh:408`, `scripts/health-check.sh:420`, `scripts/health-check.sh:428`, `scripts/run-tests.sh:132`, `scripts/run-tests.sh:411-420`, `test/scripts/health-check.bats:217-232`, `docs/reviews/execution-logs/q102-r2-gate5.log`

---

## Claim 4a: "Same grammar as run-tests.sh's --jobs (1 to 999, digits only, no leading zero)"

**Location:** `scripts/health-check.sh:29-31`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the two regexes are character-identical and accept or reject the same non-empty strings over 14 probe values; does not establish that the two stay in sync. Nothing shares the pattern, and no test compares them directly; the bats test only probes 7 bad values against health-check.
**Legibility-target:** for-orchestrator-synthesis

health-check.sh: `if [[ ! "$jobs" =~ ^[1-9][0-9]{0,2}$ ]]; then` (`scripts/health-check.sh:409`). run-tests.sh: `if [[ ! "${2:-}" =~ ^[1-9][0-9]{0,2}$ ]]; then` (`scripts/run-tests.sh:144`), documented as "N is 1 to 999, digits only, no leading zero; anything else is a usage error (exit 2)" (`scripts/run-tests.sh:36-38`). Executed comparison over `0 1 8 08 999 1000 -1 abc '8 ' $'8\n' '1;true' ' 8' '١'`: every non-empty value got the same accept or reject verdict in both (`q102-r2-grammar.log`).

**Evidence:** `scripts/health-check.sh:409`, `scripts/run-tests.sh:36-38`, `scripts/run-tests.sh:141-150`, `docs/reviews/execution-logs/q102-r2-grammar.log`

---

## Claim 4b: "any other value fails check 5 before it runs a test."

**Location:** `scripts/health-check.sh:31-32`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-empty out-of-grammar values (fail with FAIL=1, runner never invoked); does not cover the empty string, which is "another value" under run-tests.sh's grammar but silently means the default 8 here.
**Legibility-target:** for-author

For a non-empty bad value the check returns before the runner is called: `fail "RUN_TESTS_JOBS='$jobs' is not 1 to 999 …"` then `return` (`scripts/health-check.sh:410-411`). The executed test confirmed an empty stub log for `0 08 1000 -1 abc '8 ' '1;true'` (`q102-r2-gate5.log`, ok 4). An empty `RUN_TESTS_JOBS=` instead becomes 8 through `${RUN_TESTS_JOBS:-8}` (`:408`) and passes (`q102-r2-grammar.log`, `''	health-check:FAIL=0`). The commit message documents this as intended, but the header does not. A precise version would read "Empty or unset means 8; any other value outside that grammar fails check 5 …".

**Evidence:** `scripts/health-check.sh:408-412`, `docs/reviews/execution-logs/q102-r2-gate5.log`, `docs/reviews/execution-logs/q102-r2-grammar.log`

---

## Claim 5: "Without GNU parallel the runner warns and runs serially."

**Location:** `scripts/health-check.sh:32-33`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both no-GNU-parallel cases, `parallel` absent from PATH and a non-GNU (moreutils-style) `parallel` first on PATH, for a run whose effective N > 1; does not establish a warning when N is lowered to 1 by the file count (no warning, because none is needed), nor the case of a GNU parallel whose user config breaks the run (fails closed rather than falling back, `scripts/run-tests.sh:101-104`).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/run-tests.sh:411-420
requested_jobs="$jobs"
(( jobs > ${#files[@]} )) && jobs=${#files[@]}
if [[ "$jobs" -gt 1 ]]; then
  unset PARALLEL PARALLEL_CSH
  if [[ "$(parallel --plain --version 2>/dev/null)" == "GNU parallel"* ]]; then
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
  else
    echo "WARNING: --jobs $requested_jobs needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially" >&2
  fi
fi
```

The `else` branch covers both a missing `parallel` and a moreutils one, since the version string fails to start with `GNU parallel`. Executed: "--jobs with a non-GNU parallel first on PATH warns and runs serially" and "--jobs without GNU parallel on PATH warns and runs serially" both passed (`q102-r2-fallback.log`).

**Evidence:** `scripts/run-tests.sh:95-98`, `scripts/run-tests.sh:411-420`, `test/scripts/run-tests.bats:469-500`, `docs/reviews/execution-logs/q102-r2-fallback.log`

---

## Claim 6: "5. BATS tests pass: run-tests.sh --fast, then --slow only if fast is green, both with --jobs $RUN_TESTS_JOBS (default 8)"

**Location:** `scripts/health-check.sh:50-51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ordering, the fast-red short-circuit, and that both runs carry the same `--jobs`; does not establish the runner-side handling of that value (Claims 3, 5).
**Legibility-target:** for-orchestrator-synthesis

`if ! … "$runner" --fast --jobs "$jobs"; then fail "Fast BATS suites failed — slow suites not run (fix fast first)"; … return` (`scripts/health-check.sh:420-424`), then `if … "$runner" --slow --jobs "$jobs"; then` (`:428`). The executed test "red fast blocks slow and fails the gate" saw the stub log `--fast --jobs 8 skip=1` only (`q102-r2-gate5.log`, ok 5).

**Evidence:** `scripts/health-check.sh:420-434`, `test/scripts/health-check.bats:245-252`, `docs/reviews/execution-logs/q102-r2-gate5.log`

---

## Claim 7: "both runs pass --jobs RUN_TESTS_JOBS, default 8, which measured about 3x faster than serial (140 s against 451 s on 16 cores; see the "Parallel runs" section of run-tests.sh)"

**Location:** `scripts/health-check.sh:386-388`
**Type:** Performance / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the numbers match the recorded Q-090 measurement (a single `run-tests.sh --jobs 8` full run vs serial, 16 cores) and where they are recorded; does not establish the speedup of this gate, which makes two sequential runs (see Claim 13).
**Legibility-target:** for-author

The numbers are real: Q-090 records "Wall time on the 16-core sandbox: serial 451 s, `--jobs 8` 140–145 s (3.1×), `--jobs 16` 137 s" (`docs/working/questions-archive.md:1878`). The rubric records "`scripts/run-tests.sh --jobs 8`, 1498 tests, 0 failures, 140 s" (`docs/reviews/code-review-rubric-2026-09-30-feat-run-tests-jobs.md:56`). The pointer is imprecise. The "Parallel runs" section of run-tests.sh does not contain 140 or 451. Its only measurement is "measured on 16 cores: --jobs 16 was only about 5% faster than --jobs 8" (`scripts/run-tests.sh:89-90`). `rg '451|140' scripts/run-tests.sh` returns nothing (paraphrased — no quote available because the claim covers absence of matches). The numbers also come from one `--all`-style run, not from the fast-then-slow pair this comment sits above. A precise version would cite Q-090 in `docs/working/questions-archive.md` and say "for a full run".

**Evidence:** `scripts/health-check.sh:386-388`, `scripts/run-tests.sh:85-117`, `docs/working/questions-archive.md:1878`, `docs/reviews/code-review-rubric-2026-09-30-feat-run-tests-jobs.md:56`

---

## Claim 8: "RUN_TESTS_JOBS=1 runs serially, for a suspected timing flake. The value is checked here with run-tests.sh's own grammar, so a bad one fails the gate by name rather than as the runner's usage error mid-gate."

**Location:** `scripts/health-check.sh:388-391`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a bad (non-empty) value yields a named `✗ RUN_TESTS_JOBS='…'` line and FAIL=1 with no runner call; does not establish what the gate would have printed without the pre-check (not exercised).
**Legibility-target:** for-orchestrator-synthesis

`fail "RUN_TESTS_JOBS='$jobs' is not 1 to 999 (digits only, no leading zero; 1 = serial) — BATS suites not run"` (`scripts/health-check.sh:410`). Executed output: `✗ RUN_TESTS_JOBS='abc' is not 1 to 999 (digits only, no leading zero; 1 = serial) — BATS suites not run` / `FAIL=1` (`q102-r2-gate5-ambient.log`). The 1 = serial half is covered in Claim 3.

**Evidence:** `scripts/health-check.sh:408-412`, `docs/reviews/execution-logs/q102-r2-gate5.log`, `docs/reviews/execution-logs/q102-r2-gate5-ambient.log`

---

## Claim 9: "Falling back to serial without GNU parallel is the runner's job."

**Location:** `scripts/health-check.sh:391-392`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that check_bats does not probe for parallel and that run-tests.sh does; does not re-establish the fallback's behaviour (Claim 5).
**Legibility-target:** for-orchestrator-synthesis

check_bats checks only `command -v bats` (`scripts/health-check.sh:401`) and the regex, and never names `parallel` (paraphrased — no quote available because the claim covers absence of code in check_bats, `scripts/health-check.sh:394-440`, read in full). The probe lives in run-tests.sh: `if [[ "$(parallel --plain --version 2>/dev/null)" == "GNU parallel"* ]]; then` (`scripts/run-tests.sh:415`).

**Evidence:** `scripts/health-check.sh:394-440`, `scripts/run-tests.sh:411-420`

---

## Claim 10: "The stub logs each invocation's arguments and the HEALTH_CHECK_SKIP_BATS it saw"

**Location:** `test/scripts/health-check.bats:185-186`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the stub written by `_stub_runner`; does not cover the separate `run-tests-nr.sh` stub at `:467-472`, which logs nothing.
**Legibility-target:** for-orchestrator-synthesis

`printf '%s skip=%s\n' "$*" "${HEALTH_CHECK_SKIP_BATS:-unset}" >> "$STUB_LOG"` (`test/scripts/health-check.bats:193`).

**Evidence:** `test/scripts/health-check.bats:188-201`

---

## Claim 11: "Gate-5 guard unset here, and RUN_TESTS_JOBS too unless STUB_JOBS is set, so an ambient value (the outer gate's own) never reaches the gate under test."

**Location:** `test/scripts/health-check.bats:203-205`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `_run_check_bats` helper's env handling; does not cover the sibling gate-5 test at `:466` that calls check_bats directly without unsetting RUN_TESTS_JOBS, and it corrects the "outer gate's own" wording.
**Legibility-target:** for-author

The helper does what it says: `local jobs_env=(-u RUN_TESTS_JOBS)` / `[[ -n "${STUB_JOBS+set}" ]] && jobs_env=(RUN_TESTS_JOBS="$STUB_JOBS")` / `run env -u HEALTH_CHECK_SKIP_BATS "${jobs_env[@]}" …` (`test/scripts/health-check.bats:211-213`). With `RUN_TESTS_JOBS=abc` ambient, tests 2–6, which use the helper, all passed (`q102-r2-gate5-ambient.log`). Two imprecisions:

1. "the outer gate's own": the outer gate never sets or exports RUN_TESTS_JOBS. It only reads it into a `local` (`scripts/health-check.sh:408`). Its only `export` is `export HEALTH_CHECK_LOCK_HELD=1` (`scripts/health-check.sh:1143`). An ambient value comes from whoever launched the outer gate, and nested suites inherit it unchanged. The outer gate rejects bad values before running anything, so a value that reaches a nested suite *through the gate* is always valid.
2. The sibling test "report suites the runner gated out are warned about with their count, never passed" runs `run env -u HEALTH_CHECK_SKIP_BATS HEALTH_CHECK_RUN_TESTS="$stub" bash -c 'source "$1"; check_bats; …'` (`test/scripts/health-check.bats:474-475`) without `-u RUN_TESTS_JOBS`. With an ambient `RUN_TESTS_JOBS=abc` it failed: `not ok 8 … `[[ "$output" == *"FAIL=0"* ]]' failed` (`q102-r2-gate5-ambient.log`). This is reachable only by running the bats file directly with a bad value in the environment, not through the gate.

**Evidence:** `test/scripts/health-check.bats:203-216`, `test/scripts/health-check.bats:466-480`, `scripts/health-check.sh:408`, `scripts/health-check.sh:1143`, `docs/reviews/execution-logs/q102-r2-gate5-ambient.log`

---

## Claim 12: "the gate is `scripts/health-check.sh`, which runs the fast suite and then the slow one, each with `--jobs 8`"

**Location:** `workflows/pr-prep.md:331`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default with RUN_TESTS_JOBS unset; does not establish the effective parallelism after the runner lowers N to the file count or falls back to serial.
**Legibility-target:** for-orchestrator-synthesis

Same evidence as Claims 3 and 6: `local jobs="${RUN_TESTS_JOBS:-8}"` (`scripts/health-check.sh:408`), passed to `--fast` and `--slow` (`:420`, `:428`). The stub log showed `--fast --jobs 8` and `--slow --jobs 8` (`q102-r2-gate5.log`, ok 2).

**Evidence:** `scripts/health-check.sh:408-428`, `docs/reviews/execution-logs/q102-r2-gate5.log`

---

## Claim 13: "(Q-102 [1]: about 2.5 min against 7.5 min serial)"

**Location:** `workflows/pr-prep.md:331`
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the attribution of the 2.5 / 7.5 min figures to *this gate* ("each with `--jobs 8`"), checked against their source and against the one branch gate run observed; does not establish a gate wall time under controlled load. A single run on a shared 16-core machine is not a benchmark, and no serial gate run was taken at this commit.
**Legibility-target:** for-author

The figures come from Q-102: "`scripts/run-tests.sh --jobs 8` runs the full suite about 3× faster (140 s against 451 s serial)" (`docs/working/questions-archive.md:2501`), with option [1] costing "about 7.5 min instead of 2.5 min" (`:2509`). Those are one full-suite run of 1498 tests (`docs/working/questions-archive.md:1878`). The gate makes two sequential runs, fast and then slow, each bounded by its own slowest file. install-host.bats alone takes 105 s, per the same Q-090 entry. The suite has also grown: the branch gate ran `1..1514` fast and `1..298` slow tests. The branch's own gate run (`time scripts/health-check.sh` at 65c931e6) took 171 s for the fast run (run log `19:49:27 UTC`, last written 12:52:18 local) and 154 s for the slow run (`19:52:20 UTC` to 12:54:54). That is about 5.4 min of BATS, and the whole gate reported `6:20.01 total` (`q102-r2-gate-timing.log`). Load average then was about 5 of 16 cores, and the reviewer's own concurrent bats run was blocked on the lock, not using CPU. A reader planning around "2.5 min" for the gate is misled by roughly 2×. A precise version would say "the full suite at `--jobs 8` measured 140 s against 451 s serial (Q-090), and the two-run gate takes longer". It could also quote a measured gate time.

**Evidence:** `workflows/pr-prep.md:331`, `docs/working/questions-archive.md:1878`, `docs/working/questions-archive.md:2501-2510`, `docs/reviews/execution-logs/q102-r2-gate-timing.log`, `/home/node/.claude/jobs/00bcf178/tmp/hc.log`

---

## Claim 14: "`RUN_TESTS_JOBS=N` picks another N, and `RUN_TESTS_JOBS=1` runs serially; without GNU parallel the runner warns and runs serially."

**Location:** `workflows/pr-prep.md:331`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers N in 1–999 reaching both runs, 1 being serial, and the runner fallback in both no-GNU-parallel cases; does not mention that N outside 1–999 fails the gate (an omission rather than an error).
**Legibility-target:** for-orchestrator-synthesis

Executed: `STUB_JOBS=16` produced `--fast --jobs 16 skip=1` / `--slow --jobs 16 skip=1`, and `STUB_JOBS=1` produced `--jobs 1` (`test/scripts/health-check.bats:225-232`, ok 3 in `q102-r2-gate5.log`). Serial for 1 holds by `if [[ "$jobs" -gt 1 ]]; then` (`scripts/run-tests.sh:413`). The fallback is Claim 5 (`q102-r2-fallback.log`).

**Evidence:** `scripts/health-check.sh:408-428`, `scripts/run-tests.sh:411-420`, `docs/reviews/execution-logs/q102-r2-gate5.log`, `docs/reviews/execution-logs/q102-r2-fallback.log`

---

## Claim 15: "(in claude-workflows, `scripts/run-tests.sh --failed`, which runs serially)"

**Location:** `workflows/pr-prep.md:345`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the command as written (no `--jobs`): the runner's default is 1 and it reads no environment variable for parallelism; does not cover `--failed --jobs N`, which run-tests.sh accepts and runs in parallel.
**Legibility-target:** for-orchestrator-synthesis

`jobs=1` (`scripts/run-tests.sh:132`) is changed only by the `--jobs)` case (`:141-150`). The header says "1, the default, runs serially … Combines with every other flag, --failed included" (`scripts/run-tests.sh:38-40`). `rg RUN_TESTS_JOBS` matches only health-check.sh, pr-prep.md, health-check.bats and the archive, never run-tests.sh (paraphrased — no quote available because the claim covers absence of matches). pr-prep's other `--failed` mention (`workflows/pr-prep.md:242`) passes no `--jobs` either.

**Evidence:** `scripts/run-tests.sh:36-40`, `scripts/run-tests.sh:132-150`, `workflows/pr-prep.md:345`

---

## Claim 16: "Gate 5 passes --jobs "${RUN_TESTS_JOBS:-8}" to both the fast and the slow run (about 2.5 min against 7.5 min serial)."

**Location:** commit 65c931e6 message, paragraph 1
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the parenthetical timing as applied to gate 5; the `--jobs` expansion part is Verified (Claim 3). Does not establish a controlled gate benchmark.
**Legibility-target:** for-author

This is the same figure as Claim 13 with the same evidence. 140 s / 451 s is a single full-suite run (`docs/working/questions-archive.md:1878`). The observed branch gate spent about 325 s in BATS, 171 s fast plus 154 s slow (`q102-r2-gate-timing.log`). The commit message cannot be edited without a rewrite. The fix belongs in pr-prep.md (Claim 13), and possibly a note in the merge commit.

**Evidence:** `docs/working/questions-archive.md:1878`, `docs/reviews/execution-logs/q102-r2-gate-timing.log`

---

## Claim 17: "the variable is read by health-check.sh only, not by run-tests.sh, so direct runner calls (and --failed re-runs) stay serial unless --jobs is passed."

**Location:** commit 65c931e6 message, Notes
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every tracked file in the worktree (`rg -n RUN_TESTS_JOBS --hidden -g '!.git'`); does not cover untracked host scripts, aliases or CI outside the repo.
**Legibility-target:** for-orchestrator-synthesis

The only code reader is `local jobs="${RUN_TESTS_JOBS:-8}"` (`scripts/health-check.sh:408`). Other hits are comments or docs in health-check.sh, `workflows/pr-prep.md:331`, `test/scripts/health-check.bats:204-240`, and `docs/working/questions-archive.md:2508,2516` (paraphrased — no quote available because the claim covers absence of further readers across the repo). The default of 1 is at `scripts/run-tests.sh:132`.

**Evidence:** `scripts/health-check.sh:408`, `scripts/run-tests.sh:132`

---

## Claim 18: "An empty RUN_TESTS_JOBS means the default 8, like unset."

**Location:** commit 65c931e6 message, Notes
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_bats's handling of `RUN_TESTS_JOBS=`; does not establish that the header documents this (it does not; see Claim 4b).
**Legibility-target:** for-orchestrator-synthesis

`${RUN_TESTS_JOBS:-8}` (`scripts/health-check.sh:408`). The colon form substitutes for empty as well as unset. Executed: `''	health-check:FAIL=0` (`q102-r2-grammar.log`).

**Evidence:** `scripts/health-check.sh:408`, `docs/reviews/execution-logs/q102-r2-grammar.log`

---

## Claim 19: "a value outside run-tests.sh's --jobs grammar fails the gate by name before any test runs, instead of as the runner's usage error. The serial fallback without GNU parallel stays in run-tests.sh. … roadmap Next #6 is removed."

**Location:** commit 65c931e6 message, paragraph 1
**Type:** Behavioral / Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the named pre-check, that fallback code lives only in run-tests.sh, and the roadmap removal; the empty-value exception is stated in the same message's Notes, so it is not a residue here.
**Legibility-target:** for-orchestrator-synthesis

See Claims 8 and 9 for the pre-check and where the fallback lives, and Claim 1 for the roadmap. The removed item was `-6. **Q-102 [1] — parallel test gates by default.**` (diff of `docs/roadmap.md`, old line 50).

**Evidence:** `scripts/health-check.sh:408-412`, `scripts/run-tests.sh:411-420`, `docs/roadmap.md:26-55`, `docs/reviews/execution-logs/q102-r2-gate5.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 13** (`workflows/pr-prep.md:331`): "about 2.5 min against 7.5 min serial" is a single full-suite run (Q-090), not this two-run gate. The branch gate's BATS took about 5.4 min (171 s fast + 154 s slow). Cite the measurement as a full-run figure, or quote a measured gate time.
- **Claim 16** (commit 65c931e6 message): same timing as Claim 13, attributed to gate 5.

### Mostly Accurate
- **Claim 2** (`docs/working/questions-archive.md:2516`): "a value outside run-tests.sh's `--jobs` grammar fails the gate". The empty value is outside that grammar but means 8. Say "non-empty".
- **Claim 4b** (`scripts/health-check.sh:31-32`): "any other value fails check 5". Same empty-value exception. Add "empty or unset means 8".
- **Claim 7** (`scripts/health-check.sh:386-388`): 140 s / 451 s are from Q-090 (`docs/working/questions-archive.md:1878`), not from run-tests.sh's "Parallel runs" section, and are a full-run figure, not the gate's.
- **Claim 11** (`test/scripts/health-check.bats:203-205`): the outer gate never exports RUN_TESTS_JOBS (the ambient value is the launcher's), and the sibling gate-5 test at `:466-480` does not unset it. It fails under an ambient `RUN_TESTS_JOBS=abc` (executed).

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path named in your tail, structured per your skill, with a Goal-Alignment Note.
- Answered: yes. All 8 focus items checked: grammar identical (4a), fallback including moreutils verified (5), timing numbers source-accurate but misapplied to the gate (7, 13, 16), `--failed` serial verified (15), commit Notes verified (17, 18), test comment mostly accurate with a sibling-test gap (11), archive note mostly accurate (2), roadmap consistent (1).
- Out of scope: running scripts/health-check.sh or the full suite (forbidden by the brief; the timing evidence is the branch gate already run in this worktree); code-quality judgments on the unshared regex.
- Escalate: the gate-time claim (2.5 min) in pr-prep.md and the commit body is contradicted by the branch's own gate run (about 5.4 min BATS, 6:20 overall). The orchestrator may want a performance critic or the author to decide which figure to publish. Row 182's revisit trigger (longest-first order) is now live and bears on this.
- Decisions I made: treated one gate run on a shared machine as sufficient to call the 2.5 min figure Incorrect (Medium confidence) rather than Unverifiable, because the gap is about 2× and the source figure is plainly a different run shape; graded the empty-value wording Mostly accurate rather than Incorrect because the commit documents the behaviour and it is benign.
