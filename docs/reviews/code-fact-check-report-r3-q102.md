Commit: 65c931e

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q102-parallel-gates (branch `feat/q102-parallel-gates`)
**Scope:** `git diff main...HEAD` (docs/roadmap.md, docs/working/questions-archive.md, scripts/health-check.sh, test/scripts/health-check.bats, workflows/pr-prep.md) plus the HEAD commit message; claims traced into scripts/run-tests.sh and the Q-090/Q-102 archive entries
**Checked:** 2026-10-14
**Total claims checked:** 12
**Summary:** 10 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern.

Execution note: `timeout 300 bats -f 'gate 5' test/scripts/health-check.bats` (cwd the worktree, started 2026-10-14T19:51:00Z) exited 124 with no test result: that file's `setup_file` runs the whole health-check, and another session's reviewer was running the same file at the same time (seen in `pgrep`). It was not retried. Instead `check_bats` was driven directly with a stub runner, the same way the file's `_run_check_bats` helper does it (log `docs/reviews/execution-logs/r3-q102-checkbats-direct.log`), and the runner's own `--jobs` tests ran (log `docs/reviews/execution-logs/r3-q102-rt-fallback.log`). The timed-out log is kept at `docs/reviews/execution-logs/r3-q102-hc-gate5.log`. No process from these runs was left behind: the bats processes still visible belong to the other session's command line (`q102-r2`).

---

## Claim 1: "6. **Verify a branch without installing it on the host.**" (renumbered from 7 after Q-102's Next #6 was removed; the commit says "roadmap Next #6 is removed")

**Location:** `docs/roadmap.md:50`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Next list's numbering after the removal (1 to 6 with no gap or duplicate) and the absence of any in-repo reference to the old "Next #6/#7" numbers; does not establish that the order of the remaining items is still the one the user wants.
**Legibility-target:** the dev-cycle agent reading the roadmap at its step 6, and the user scanning Next.

The Next list now runs `1. **Q-075 ...` (`docs/roadmap.md:28`), `2. **Q-088 ...`, `3. **Q-089 ...`, `4. **Measure router uptake.**`, `5. **A8 post-restructure token measurement.**` and `6. **Verify a branch without installing it on the host.**` (`docs/roadmap.md:50`), followed by `## Ideas`. Nothing else in the repo points at the old numbers (paraphrased — no quote available because the claim covers absence: `rg 'Next (item )?#?[67]\b|roadmap (item|Next) #?[67]'` over `*.md` outside docs/reviews/ returned nothing).

**Evidence:** `docs/roadmap.md:26-55`

---

## Claim 2: "health-check.sh's gate 5 passes `--jobs "${RUN_TESTS_JOBS:-8}"` to both runs; 1 is serial, a value outside run-tests.sh's `--jobs` grammar fails the gate before any test runs, and the runner still falls back to serial without GNU parallel. pr-prep's step 5a names the default and the override."

**Location:** `docs/working/questions-archive.md:2516`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each part of the Applied note: the expansion passed to both runs, 1 meaning serial, a bad value failing before the runner is called, the runner's fallback, and pr-prep step 5a's wording; does not establish real wall time or flake rate under the new default (see Claims 5 and 9b).
**Legibility-target:** the user and later cycles reading the Q-102 archive entry to learn whether [1] was applied and how.

Each part is checked in a claim below: the expansion and the two runs in Claims 3 and 4 (`local jobs="${RUN_TESTS_JOBS:-8}"`, `scripts/health-check.sh:408`), the grammar check failing before the runner in Claims 3 and 6, the fallback in Claim 6, and pr-prep's line in Claim 9a. "Step 5a" is the right place: the line sits under `#### 5. Verify and annotate (parallelizable)` (`workflows/pr-prep.md:311`) and `**a. Verify CI passes (automated).**` (`workflows/pr-prep.md:315`), before `**b. Annotate the diff.**` (`workflows/pr-prep.md:347`).

**Evidence:** `docs/working/questions-archive.md:2516`, `scripts/health-check.sh:404-439`, `workflows/pr-prep.md:311-347`, `docs/reviews/execution-logs/r3-q102-checkbats-direct.log`

---

## Claim 3: "RUN_TESTS_JOBS — Test files check 5 runs at once, passed to the runner as --jobs (Q-102 [1]). Default 8; 1 runs serially. Same grammar as run-tests.sh's --jobs (1 to 999, digits only, no leading zero); any other value fails check 5 before it runs a test. Without GNU parallel the runner warns and runs serially."

**Location:** `scripts/health-check.sh:27-33`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default, the grammar being identical to the runner's, a bad value failing gate 5 before the runner starts, and the runner's serial fallback (missing parallel and a non-GNU one first on PATH); does not establish behaviour when `HEALTH_CHECK_SKIP_BATS=1` (the guard returns before the value is read, so a bad value is not reported in a nested run) or when bats is not installed (same early return).
**Legibility-target:** whoever sets RUN_TESTS_JOBS before running the gate, a human or an agent following pr-prep.

The two checks are the same regex. health-check: 

```bash
# scripts/health-check.sh:408-412
    local jobs="${RUN_TESTS_JOBS:-8}"
    if [[ ! "$jobs" =~ ^[1-9][0-9]{0,2}$ ]]; then
        fail "RUN_TESTS_JOBS='$jobs' is not 1 to 999 (digits only, no leading zero; 1 = serial) — BATS suites not run"
        return
    fi
```
(excerpt ends :412; enclosing check_bats() runs :394-439 — read)

run-tests.sh:

```bash
# scripts/run-tests.sh:144-148
      if [[ ! "${2:-}" =~ ^[1-9][0-9]{0,2}$ ]]; then
        echo "--jobs takes a number from 1 to 999, got: ${2:-(nothing)}" >&2
        usage
        exit 2
      fi
```
(excerpt ends :148; enclosing argument loop continues to its `esac`/`done` — read)

A value that passes reaches `--jobs "$jobs"` on both runs (`scripts/health-check.sh:420` and `:428`). `fail` sets `FAIL=1` (`scripts/health-check.sh:83`) and main ends `exit "$FAIL"` (`scripts/health-check.sh:1181`), so the gate fails. Run with a stub runner: unset and `''` gave `--fast --jobs 8;--slow --jobs 8`; `1`, `16` and `999` were passed through unchanged; `0`, `08`, `1000`, `' 8'` and `abc` each printed the RUN_TESTS_JOBS failure line, set FAIL=1 and left the stub log empty. The fallback is in the runner:

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

This covers the moreutils case too, because the test is for the "GNU parallel" banner, not for any `parallel` being present. The runner tests "--jobs with a non-GNU parallel first on PATH warns and runs serially" and "--jobs without GNU parallel on PATH warns and runs serially" both passed, as did "--jobs: a missing, zero, non-numeric or 4-digit N is a usage error" and "--jobs 1 runs serially and needs no parallel".

Commands: (a) a loop running `timeout 30 env -u HEALTH_CHECK_SKIP_BATS <RUN_TESTS_JOBS setting> HEALTH_CHECK_RUN_TESTS=<stub> bash -c 'source "$1"; check_bats; echo "FAIL=$FAIL"' _ scripts/health-check.sh` over 11 values, in a mktemp dir, started 2026-10-14T19:56:16Z, loop exit 0; (b) `timeout 300 bats -f 'warns and runs serially|usage error|--jobs 1 runs serially' test/scripts/run-tests.bats`, cwd the worktree, at about 2026-10-14T19:56Z, exit 0, 5/5 ok.

**Evidence:** `scripts/health-check.sh:27-33`, `scripts/health-check.sh:83`, `scripts/health-check.sh:404-439`, `scripts/health-check.sh:1176-1181`, `scripts/run-tests.sh:141-150`, `scripts/run-tests.sh:405-420`, `docs/reviews/execution-logs/r3-q102-checkbats-direct.log`, `docs/reviews/execution-logs/r3-q102-rt-fallback.log`

---

## Claim 4: "5. BATS tests pass: run-tests.sh --fast, then --slow only if fast is green, both with --jobs $RUN_TESTS_JOBS (default 8)"

**Location:** `scripts/health-check.sh:50-51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order, the slow run being skipped after a red fast run, and the same `--jobs` value on both; does not establish the actual concurrency, which the runner lowers to the number of selected files and drops to 1 without GNU parallel.
**Legibility-target:** a maintainer reading the gate list at the top of health-check.sh.

The fast call is `"$runner" --fast --jobs "$jobs"`; when it fails, the code runs `fail "Fast BATS suites failed — slow suites not run (fix fast first)"` and `return` (`scripts/health-check.sh:420-424`). The slow call is `"$runner" --slow --jobs "$jobs"` (`scripts/health-check.sh:428`). The stub run in Claim 3 logged both calls with the same value every time.

**Evidence:** `scripts/health-check.sh:50-51`, `scripts/health-check.sh:420-434`, `docs/reviews/execution-logs/r3-q102-checkbats-direct.log`

---

## Claim 5: "both runs pass --jobs RUN_TESTS_JOBS, default 8, which measured about 3x faster than serial (140 s against 451 s on 16 cores; see the "Parallel runs" section of run-tests.sh)"

**Location:** `scripts/health-check.sh:386-388`
**Type:** Performance / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the figures against their source (Q-090) and what the cited run-tests.sh section contains; does not establish the wall time of the gate as it now runs (two runs, fast then slow), which nobody has measured.
**Legibility-target:** a maintainer deciding whether to keep the default 8 or to lower it.

The numbers match Q-090: "Wall time on the 16-core sandbox: serial 451 s, `--jobs 8` 140–145 s (3.1×), `--jobs 16` 137 s" (`docs/working/questions-archive.md:1878`). Q-102 also says "about 3× faster (140 s against 451 s serial)" (`docs/working/questions-archive.md:2501`). 451/140 = 3.2 and 451/145 = 3.1. Two things need tightening:
- The figures came from one full `--jobs 8` run, not from the gate's two runs (paraphrased — no quote available because the claim is about which run was measured; Q-090 reports one run with no category flag). Each of the gate's runs is bounded by its own slowest file and does its own `bats --count`. Expect roughly the same ratio, but it is not what was measured.
- The pointer is half right. The "Parallel runs" section of run-tests.sh gives only the `--jobs 16` against `--jobs 8` comparison, "measured on 16 cores: --jobs 16 was only about 5% faster than --jobs 8" (`scripts/run-tests.sh:89-90`). The 140 s and 451 s figures are not in it. They are in Q-090 in `docs/working/questions-archive.md`.

Precise version: "...measured about 3x faster than serial for one full run (140 s against 451 s on 16 cores; Q-090 in docs/working/questions-archive.md)".

**Evidence:** `scripts/health-check.sh:386-388`, `scripts/run-tests.sh:85-91`, `docs/working/questions-archive.md:1878`, `docs/working/questions-archive.md:2501`

---

## Claim 6: "RUN_TESTS_JOBS=1 runs serially, for a suspected timing flake. The value is checked here with run-tests.sh's own grammar, so a bad one fails the gate by name rather than as the runner's usage error mid-gate. Falling back to serial without GNU parallel is the runner's job."

**Location:** `scripts/health-check.sh:388-392`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 1 meaning serial in the runner, the check running before the runner and naming the variable, and the fallback being in run-tests.sh and nowhere in health-check.sh; does not establish that serial removes every timing flake (a judgment about the suites, not a code property).
**Legibility-target:** a maintainer tempted to add a GNU parallel check to health-check.sh.

With `--jobs 1` the runner skips the parallel branch (`if [[ "$jobs" -gt 1 ]]`, `scripts/run-tests.sh:413`), so bats gets no `--jobs` and runs files serially. The runner test "--jobs 1 runs serially and needs no parallel" passed. The check sits before both runner calls (Claim 3 excerpt, `scripts/health-check.sh:408-412`) and its message starts `RUN_TESTS_JOBS='$jobs'`. Without the check, the runner would print `--jobs takes a number from 1 to 999` and `exit 2` (`scripts/run-tests.sh:145-147`). health-check.sh has no check of its own for `parallel` (paraphrased — no quote available because the claim covers absence: `rg -n 'parallel' scripts/health-check.sh` finds only comments in the new block and in the RUN_TESTS_JOBS header).

**Evidence:** `scripts/health-check.sh:388-392`, `scripts/health-check.sh:404-439`, `scripts/run-tests.sh:141-150`, `scripts/run-tests.sh:411-420`, `docs/reviews/execution-logs/r3-q102-rt-fallback.log`

---

## Claim 7: "Gate-5 guard unset here, and RUN_TESTS_JOBS too unless STUB_JOBS is set, so an ambient value (the outer gate's own) never reaches the gate under test."

**Location:** `test/scripts/health-check.bats:203-205`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helper removing an inherited RUN_TESTS_JOBS (or replacing it with STUB_JOBS), and an inherited value being able to reach this test in the first place; does not establish that the outer gate exports a value of its own (it does not, see below).
**Legibility-target:** a test maintainer working out why `_run_check_bats` builds `jobs_env`.

The helper does what the comment says:

```bash
# test/scripts/health-check.bats:211-214
  local jobs_env=(-u RUN_TESTS_JOBS)
  [[ -n "${STUB_JOBS+set}" ]] && jobs_env=(RUN_TESTS_JOBS="$STUB_JOBS")
  run env -u HEALTH_CHECK_SKIP_BATS "${jobs_env[@]}" HEALTH_CHECK_RUN_TESTS="$stub" \
    bash -c 'source "$1"; check_bats; echo "FAIL=$FAIL"' _ "$SCRIPT"
```
(excerpt ends :214; enclosing _run_check_bats() ends at :215 — read)

Does the outer gate export RUN_TESTS_JOBS? Not by itself. health-check.sh only reads it into `local jobs` (`scripts/health-check.sh:408`), and its one `export` is `export HEALTH_CHECK_LOCK_HELD=1` (`scripts/health-check.sh:1143`). The default 8 therefore never reaches the tests. A value the outer gate was started with does reach them, for example `RUN_TESTS_JOBS=1 scripts/health-check.sh` or an exported shell variable (paraphrased — no quote available because this is ordinary environment inheritance through health-check.sh → run-tests.sh → `exec bats` → test, with nothing on that path unsetting the variable). So "the outer gate's own" is accurate when it means the value the outer gate was run with. Without the `-u`, the test that pins `--jobs 8` would fail under `RUN_TESTS_JOBS=1`. A reader could take "the outer gate's own" to mean a value the gate exports. No such value exists, but that does not change what the guard protects against.

**Evidence:** `test/scripts/health-check.bats:203-215`, `scripts/health-check.sh:408`, `scripts/health-check.sh:1143`, `scripts/run-tests.sh:437`

---

## Claim 8: "a RUN_TESTS_JOBS outside run-tests.sh's grammar fails the gate and runs nothing" (test name, with the bad values `0 08 1000 -1 abc '8 ' '1;true'`)

**Location:** `test/scripts/health-check.bats:234-243`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed value being outside the runner's regex and the gate failing without calling the runner; does not establish that the bats test itself passes here (that run timed out in `setup_file` while another session used the file; see the execution note).
**Legibility-target:** a test maintainer.

Every listed value fails `^[1-9][0-9]{0,2}$`: leading zero, four digits, sign, letters, trailing space, shell metacharacters. The direct `check_bats` run in Claim 3 gave FAIL=1 and an empty stub log for `0`, `08`, `1000`, `' 8'` and `abc`. The others fail the same anchored regex (paraphrased — no quote available because this is reasoning over the regex quoted in Claim 3, not a separate code path).

**Evidence:** `test/scripts/health-check.bats:234-243`, `scripts/health-check.sh:409`, `scripts/run-tests.sh:144`, `docs/reviews/execution-logs/r3-q102-checkbats-direct.log`

---

## Claim 9a: "the gate is `scripts/health-check.sh`, which runs the fast suite and then the slow one, each with `--jobs 8` ... `RUN_TESTS_JOBS=N` picks another N, and `RUN_TESTS_JOBS=1` runs serially; without GNU parallel the runner warns and runs serially."

**Location:** `workflows/pr-prep.md:331`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default, the override and the fallback as health-check.sh and run-tests.sh implement them; does not establish that N is only accepted from 1 to 999 (the sentence leaves the grammar out, and any other value fails the gate, Claim 3).
**Legibility-target:** an agent running pr-prep step 5a who needs to know how to make the gate serial.

Same evidence as Claims 3, 4 and 6: `--fast --jobs "$jobs"` then `--slow --jobs "$jobs"` with `jobs="${RUN_TESTS_JOBS:-8}"` (`scripts/health-check.sh:408`, `:420`, `:428`), and the runner's warning `running serially` (`scripts/run-tests.sh:418`).

**Evidence:** `workflows/pr-prep.md:331`, `scripts/health-check.sh:404-439`, `scripts/run-tests.sh:411-420`, `docs/reviews/execution-logs/r3-q102-checkbats-direct.log`

---

## Claim 9b: "(Q-102 [1]: about 2.5 min against 7.5 min serial)" (the commit message body says the same: "about 2.5 min against 7.5 min serial")

**Location:** `workflows/pr-prep.md:331`
**Type:** Performance / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the figures against Q-102 and Q-090; does not establish the gate's wall time, because the figures are for the whole suite in one run and the gate runs two runs plus gates 1-4 and 6-8.
**Legibility-target:** an agent or the user planning how long a gate run takes.

Q-102's own table says "Every gate keeps costing about 7.5 min instead of 2.5 min" (`docs/working/questions-archive.md:2509`), so the line quotes its source faithfully. That source comes from Q-090's single full run: "serial 451 s, `--jobs 8` 140–145 s" (`docs/working/questions-archive.md:1878`), that is 7.5 min against 2.3 to 2.4 min. Calling that "the gate" overstates what was measured. The gate's two runs have each been timed only inside one full run, never split, and gates 6 (shellcheck) and the rest add time on top (paraphrased — no quote available because this is about how the measurement was taken; Q-090 does not record per-category timings). Precise version: "the suites take about 2.5 min at --jobs 8 against 7.5 min serial (Q-090, one full run)".

**Evidence:** `workflows/pr-prep.md:331`, `docs/working/questions-archive.md:1878`, `docs/working/questions-archive.md:2501-2509`

---

## Claim 10: "`scripts/run-tests.sh --failed`, which runs serially"

**Location:** `workflows/pr-prep.md:345`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the command exactly as written (no `--jobs`) under any environment, RUN_TESTS_JOBS included; does not cover `--failed --jobs N`, which the runner accepts and which runs in parallel.
**Legibility-target:** an agent re-running failures after a red gate, who might otherwise assume the new parallel default applies.

`jobs=1` is the runner's default (`scripts/run-tests.sh:132`), and only `--jobs` sets it (`jobs="$2"`, `scripts/run-tests.sh:149`). The runner reads no RUN_TESTS_JOBS (paraphrased — no quote available because the claim covers absence: `rg -n RUN_TESTS_JOBS` over the repo finds only scripts/health-check.sh, test/scripts/health-check.bats, docs/working/questions-archive.md and workflows/pr-prep.md). No other script calls `run-tests.sh --failed` with `--jobs`: the only call in a `.sh` file is health-check.sh's gate 5. The runner header says `--jobs` "Combines with every other flag, --failed included" (`scripts/run-tests.sh:40`), and that explicit form is the residue named in Scope.

**Evidence:** `workflows/pr-prep.md:345`, `scripts/run-tests.sh:36-40`, `scripts/run-tests.sh:128-150`

---

## Claim 11: "An empty RUN_TESTS_JOBS means the default 8, like unset."

**Location:** commit `65c931e6` message body (Notes)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers empty and unset in check_bats; does not cover whitespace-only values, which fail the grammar check (`' 8'` was tested).
**Legibility-target:** the reviewer of the commit, and anyone running `RUN_TESTS_JOBS= scripts/health-check.sh`.

The `:-` expansion in `local jobs="${RUN_TESTS_JOBS:-8}"` (`scripts/health-check.sh:408`) substitutes 8 for an empty value as well as for an unset one. In the direct run, `RUN_TESTS_JOBS=''` and an unset variable both gave `--fast --jobs 8;--slow --jobs 8` and FAIL=0 (command and timestamp in Claim 3).

**Evidence:** `scripts/health-check.sh:408`, `docs/reviews/execution-logs/r3-q102-checkbats-direct.log`

---

## Claim 12: "the variable is read by health-check.sh only, not by run-tests.sh, so direct runner calls (and --failed re-runs) stay serial unless --jobs is passed."

**Location:** commit `65c931e6` message body (Notes)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every reader of RUN_TESTS_JOBS in the tracked tree at HEAD; does not cover readers outside the repo (host scripts, hooks installed from older images), which this checkout cannot see.
**Legibility-target:** the reviewer of the commit, and a user who expects `RUN_TESTS_JOBS=8 scripts/run-tests.sh` to run in parallel (it will not).

Code reads the variable in one place, `local jobs="${RUN_TESTS_JOBS:-8}"` (`scripts/health-check.sh:408`). The test only sets it or unsets it for its subject (`test/scripts/health-check.bats:211-212`). Everything else is prose (paraphrased — no quote available because the claim covers absence; the `rg` result is listed in Claim 10). The runner's default is `jobs=1` (`scripts/run-tests.sh:132`).

**Evidence:** `scripts/health-check.sh:408`, `scripts/run-tests.sh:132`, `test/scripts/health-check.bats:211-212`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 5** (`scripts/health-check.sh:386-388`): 140 s and 451 s are from one full run, and they are in Q-090 (questions-archive), not in run-tests.sh's "Parallel runs" section. Point at Q-090 and say "one full run".
- **Claim 9b** (`workflows/pr-prep.md:331`, also the commit body): "2.5 min against 7.5 min" is the whole suite in one run (Q-090), not the gate's wall time. Say "the suites" rather than implying the gate.

### Unverifiable
(none)

## Goal-Alignment Note

The goal is to land Q-102 [1] as one reviewed unit: the gate runs in parallel by default, RUN_TESTS_JOBS overrides it, 1 means serial, and the runner falls back to serial without GNU parallel. Every behavioural claim the branch makes about that holds, and it was run here, not only read: the default and the empty value give 8, the override is passed to both runs, a bad value fails the gate before any test, the grammar matches the runner byte for byte, and the moreutils and missing-parallel fallbacks are tested and pass. The two non-Verified verdicts are about where the timing figures come from, not about behaviour. Neither should block the merge; each is a one-phrase fix. One limit of this pass: the new health-check.bats gate-5 tests were not run as bats tests, because another session was using the file and its `setup_file` runs the whole health-check. The same `check_bats` paths were run directly with a stub instead, so the branch's own gate run remains the evidence that those tests pass.
