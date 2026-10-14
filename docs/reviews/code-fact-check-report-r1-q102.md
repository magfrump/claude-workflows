Commit: 65c931e

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-q102-parallel-gates`, branch `feat/q102-parallel-gates`)
**Scope:** `git diff main...HEAD` (docs/roadmap.md, docs/working/questions-archive.md, scripts/health-check.sh, test/scripts/health-check.bats, workflows/pr-prep.md) plus the commit message of 65c931e6
**Checked:** 2026-10-14
**Total claims checked:** 15
**Summary:** 11 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 logged patterns). No claim here matches a logged pattern.

Execution provenance (all commands run from cwd `/workspace/.claude/wt-q102-parallel-gates`; UTC start timestamps in `docs/reviews/execution-logs/cfc-r1-q102-ts.txt`):

- E1 (2026-10-14T19:50:49Z): `for v in 0 08 1000 -1 abc '8 ' 1 999; do timeout 20 bash scripts/run-tests.sh --jobs "$v" --nonexistent-flag-after; done` — the runner's own `--jobs` parse (exits before the run lock). Output: `docs/reviews/execution-logs/cfc-r1-q102-runner-grammar.log`. Each bad value printed `--jobs takes a number from 1 to 999, got: <v>`; 1 and 999 passed the parse and reached `Unknown flag: --nonexistent-flag-after`. (Exit codes did not print: the loop ran under zsh, where `PIPESTATUS` is empty; the messages come from the `exit 2` and `exit 1` branches respectively.)
- E2 (19:50:49Z, same session as E1): `check_bats` sourced from `scripts/health-check.sh` with a stub runner via `HEALTH_CHECK_RUN_TESTS`, for RUN_TESTS_JOBS unset, `''`, `0 08 1000 -1 abc '8 ' 1 16 999`. Every invocation exit 0 (the sourced shell; FAIL is printed). Output: `docs/reviews/execution-logs/cfc-r1-q102-checkbats.log`.
- E3 (19:51:00Z): `RUN_TESTS_JOBS=4 timeout 300 bats --filter 'gate 5' test/scripts/health-check.bats` — exit 124 (timeout). `setup_file` runs the whole health check, whose `take_lock` waits on `health-check.lock` held by the gate already running in this worktree, so no test ran. Output: `docs/reviews/execution-logs/cfc-r1-q102-bats-gate5-ambient4.log`. Replaced by E5.
- E4 (19:53:32Z): `timeout 110 bats --filter 'GNU parallel' test/scripts/run-tests.bats` — exit 0, 3/3 ok (hermetic runner copy, no shared lock). Output: `docs/reviews/execution-logs/cfc-r1-q102-runtests-fallback.log`.
- E5 (timestamp last line of the ts file): with `RUN_TESTS_JOBS=4` exported, `check_bats` run through the test helper's exact `env -u HEALTH_CHECK_SKIP_BATS "${jobs_env[@]}" ...` form with `jobs_env=(-u RUN_TESTS_JOBS)`, and again without the `-u`. Exit 0. Output: `docs/reviews/execution-logs/cfc-r1-q102-helper-ambient.log`.

---

## Claim 1: "Same grammar as run-tests.sh's --jobs (1 to 999, digits only, no leading zero)"

**Location:** `scripts/health-check.sh:29-30`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a gate operator setting RUN_TESTS_JOBS by hand
**Scope:** Covers the regex and accepted/rejected values of both validators; does not establish that run-tests.sh keeps the same regex in future (the two are separate literals, not a shared definition).

The two regexes are byte-identical. health-check.sh:

```bash
# scripts/health-check.sh:408-409
    local jobs="${RUN_TESTS_JOBS:-8}"
    if [[ ! "$jobs" =~ ^[1-9][0-9]{0,2}$ ]]; then
```

run-tests.sh:

```bash
# scripts/run-tests.sh:141-150
    --jobs)
      # At most 3 digits, so the value never overflows bash arithmetic and
      # parallel never sizes thousands of job slots.
      if [[ ! "${2:-}" =~ ^[1-9][0-9]{0,2}$ ]]; then
        echo "--jobs takes a number from 1 to 999, got: ${2:-(nothing)}" >&2
        usage
        exit 2
      fi
      jobs="$2"
```

E1 and E2 agree value for value: `0 08 1000 -1 abc '8 '` rejected by both, `1 999` accepted by both (and `16` by health-check).

**Evidence:** `scripts/health-check.sh:408-412`, `scripts/run-tests.sh:141-151`, `scripts/run-tests.sh:36-40`, `docs/reviews/execution-logs/cfc-r1-q102-runner-grammar.log`, `docs/reviews/execution-logs/cfc-r1-q102-checkbats.log`

---

## Claim 2: "Default 8; 1 runs serially ... any other value fails check 5 before it runs a test."

**Location:** `scripts/health-check.sh:28-32`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a gate operator setting RUN_TESTS_JOBS by hand
**Scope:** Covers default, the serial value and rejection of non-grammar values in `check_bats`; does not establish anything about the empty-string case beyond what E2 ran, nor whether the overall health-check exit code reflects FAIL (not re-read here).

Default and rejection hold: E2 shows unset gives `STUB --fast --jobs 8` / `STUB --slow --jobs 8`, and each bad value prints `✗ RUN_TESTS_JOBS='<v>' is not 1 to 999 ...` with `FAIL=1` and no `STUB` line, from:

```bash
# scripts/health-check.sh:409-412
    if [[ ! "$jobs" =~ ^[1-9][0-9]{0,2}$ ]]; then
        fail "RUN_TESTS_JOBS='$jobs' is not 1 to 999 (digits only, no leading zero; 1 = serial) — BATS suites not run"
        return
    fi
```

The imprecision: an empty `RUN_TESTS_JOBS=` is "another value" in the literal reading but does not fail; `${RUN_TESTS_JOBS:-8}` (`:-`, not `-`) maps empty to 8, and E2 shows `RUN_TESTS_JOBS=[]` → `--jobs 8`, `FAIL=0`. The commit message states this case correctly (Claim 15); the header could say "unset or empty means 8".

**Evidence:** `scripts/health-check.sh:408-412`, `docs/reviews/execution-logs/cfc-r1-q102-checkbats.log`

---

## Claim 3: "Without GNU parallel the runner warns and runs serially."

**Location:** `scripts/health-check.sh:32-33` (same claim at `:388-389` "Falling back to serial without GNU parallel is the runner's job", `workflows/pr-prep.md:331`, and the archive Applied note)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a gate operator on a host without GNU parallel
**Scope:** Covers parallel missing from PATH and a non-GNU (moreutils-style) parallel first on PATH, for runs selecting 2+ files; does not establish behaviour when GNU parallel is present but a config file breaks it (that fails closed per run-tests.sh's header, not serial).

health-check.sh does no parallel check of its own (paraphrased — no quote available because the claim covers absence of code: `git grep -n parallel scripts/health-check.sh` shows only comments). The runner does it:

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

The moreutils case falls in the `else` branch, since its `--version` output does not start with "GNU parallel". E4 ran the two existing tests for these cases (`--jobs with a non-GNU parallel first on PATH warns and runs serially`, `--jobs without GNU parallel on PATH warns and runs serially`): both ok.

**Evidence:** `scripts/run-tests.sh:95-98`, `scripts/run-tests.sh:407-420`, `test/scripts/run-tests.bats:469-500`, `docs/reviews/execution-logs/cfc-r1-q102-runtests-fallback.log`

---

## Claim 4: "5. BATS tests pass: run-tests.sh --fast, then --slow only if fast is green, both with --jobs $RUN_TESTS_JOBS (default 8)"

**Location:** `scripts/health-check.sh:50-51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a reader of the check list in the header
**Scope:** Covers the flags passed on both runs and the fast-gates-slow ordering; does not establish run time.

```bash
# scripts/health-check.sh:420-424
    if ! HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast --jobs "$jobs"; then
        fail "Fast BATS suites failed — slow suites not run (fix fast first)"
        rm -rf "$nr_dir"
        return
    fi
```
(excerpt ends :424; enclosing check_bats() continues to :440 — read)

`:428` passes `--slow --jobs "$jobs"` likewise. E2 shows both stub lines with the same N.

**Evidence:** `scripts/health-check.sh:394-440`, `docs/reviews/execution-logs/cfc-r1-q102-checkbats.log`

---

## Claim 5: "default 8, which measured about 3x faster than serial (140 s against 451 s on 16 cores; see the "Parallel runs" section of run-tests.sh)"

**Location:** `scripts/health-check.sh:386-388`
**Type:** Performance / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** a maintainer weighing whether to change the default
**Scope:** Covers the numbers against the recorded measurement and the pointer's target; does not establish the gate's own wall time (Claim 12), and nothing was re-measured.

The numbers match the Q-090 record: "Wall time on the 16-core sandbox: serial 451 s, `--jobs 8` 140–145 s (3.1×)" (`docs/working/questions-archive.md:1878`); 451/140 = 3.2, so "about 3x" holds. The pointer is off: run-tests.sh's "Parallel runs" section has no 140 s or 451 s figure. Its only measurement is:

```bash
# scripts/run-tests.sh:89-90
# The slowest file bounds the speedup (measured on 16 cores: --jobs 16 was
# only about 5% faster than --jobs 8). Files still share the machine: install.sh's
```

The precise version would cite Q-090 in `docs/working/questions-archive.md` for the 140/451 figures. The measurement was also of one full-suite `--jobs 8` run, not the gate's fast-then-slow pair.

**Evidence:** `scripts/health-check.sh:386-389`, `scripts/run-tests.sh:85-112`, `docs/working/questions-archive.md:1878`, `docs/working/questions-archive.md:2501`

---

## Claim 6: "RUN_TESTS_JOBS=1 runs serially ... The value is checked here with run-tests.sh's own grammar, so a bad one fails the gate by name rather than as the runner's usage error mid-gate."

**Location:** `scripts/health-check.sh:388-391`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a maintainer reading check_bats
**Scope:** Covers that 1 never adds bats `--jobs` and that a bad value stops before the runner; does not establish what the runner's usage error would have looked like in a full gate.

`--jobs 1` leaves `jobs=1`, and `if [[ "$jobs" -gt 1 ]]` (`scripts/run-tests.sh:413`) is false, so no `--jobs` reaches bats. A bad value hits `fail ... return` (`scripts/health-check.sh:409-412`) before `"$runner"` is called; E2 shows no `STUB` line for any rejected value.

**Evidence:** `scripts/run-tests.sh:411-420`, `scripts/health-check.sh:408-412`, `docs/reviews/execution-logs/cfc-r1-q102-checkbats.log`

---

## Claim 7: "The stub logs each invocation's arguments and the HEALTH_CHECK_SKIP_BATS it saw"

**Location:** `test/scripts/health-check.bats:185-186`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** a test maintainer
**Scope:** Covers the stub's log line; does not establish argument quoting (`$*` joins with spaces, so a quoted argument with spaces is not distinguishable).

```bash
# test/scripts/health-check.bats:192
printf '%s skip=%s\n' "$*" "${HEALTH_CHECK_SKIP_BATS:-unset}" >> "$STUB_LOG"
```

**Evidence:** `test/scripts/health-check.bats:188-199`

---

## Claim 8: "Gate-5 guard unset here, and RUN_TESTS_JOBS too unless STUB_JOBS is set, so an ambient value (the outer gate's own) never reaches the gate under test."

**Location:** `test/scripts/health-check.bats:203-205`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a test maintainer
**Scope:** Covers the helper's isolation from an exported RUN_TESTS_JOBS; does not establish anything for tests that bypass `_run_check_bats` (none of the gate-5 tests do).

The mechanism holds:

```bash
# test/scripts/health-check.bats:211-214
  local jobs_env=(-u RUN_TESTS_JOBS)
  [[ -n "${STUB_JOBS+set}" ]] && jobs_env=(RUN_TESTS_JOBS="$STUB_JOBS")
  run env -u HEALTH_CHECK_SKIP_BATS "${jobs_env[@]}" HEALTH_CHECK_RUN_TESTS="$stub" \
    bash -c 'source "$1"; check_bats; echo "FAIL=$FAIL"' _ "$SCRIPT"
```

E5, with `RUN_TESTS_JOBS=4` exported: the helper form gives `--jobs 8`; the form without `-u` gives `--jobs 4`, so the `-u` is what keeps the default-value assertions stable. (E3, the real bats run, could not run: `setup_file` blocks on the health-check lock held by the gate already running.)

The parenthetical is imprecise. The outer gate has no value "of its own": health-check.sh never sets or exports RUN_TESTS_JOBS; it reads it into a `local jobs` (`scripts/health-check.sh:408`), and its only export is `export HEALTH_CHECK_LOCK_HELD=1` (`scripts/health-check.sh:1143`). An ambient value reaches this test only when whoever started the outer gate set RUN_TESTS_JOBS in its environment; it then passes through run-tests.sh and bats by inheritance. A precise version: "an ambient value (one the outer gate was started with) never reaches...".

**Evidence:** `test/scripts/health-check.bats:203-215`, `scripts/health-check.sh:408`, `scripts/health-check.sh:1143`, `docs/reviews/execution-logs/cfc-r1-q102-helper-ambient.log`, `docs/reviews/execution-logs/cfc-r1-q102-bats-gate5-ambient4.log`

---

## Claim 9: Test names "RUN_TESTS_JOBS sets --jobs for both runs; 1 is serial" and "a RUN_TESTS_JOBS outside run-tests.sh's grammar fails the gate and runs nothing"

**Location:** `test/scripts/health-check.bats:225`, `test/scripts/health-check.bats:234`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** a test maintainer
**Scope:** Covers that the behaviour the names state holds for the same values (E2 replicated the helper invocation); does not establish that the bats tests themselves pass, since E3 could not run while the gate holds the lock. "1 is serial" is asserted only as `--jobs 1` reaching the runner.

E2 ran the values these tests loop over (`0 08 1000 -1 abc '8 '`, plus 1 and 16) through the same `check_bats` call and stub shape: each rejected value gives `FAIL=1`, the message, and no runner call; 1 and 16 reach both runs. `'1;true'` was not in E2 but fails the same anchored regex. Confidence is Medium because the bats file itself was not executed.

**Evidence:** `test/scripts/health-check.bats:225-243`, `docs/reviews/execution-logs/cfc-r1-q102-checkbats.log`

---

## Claim 10: Roadmap Next renumbering (Q-102 item removed; "Verify a branch without installing it" becomes 6)

**Location:** `docs/roadmap.md:26-56`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** the dev cycle reading the roadmap
**Scope:** Covers the Next list's sequence and in-repo numbered references to it; does not establish references in files outside the repo (checkpoints in other worktrees).

Next now runs 1 to 6 with no gap (paraphrased — no quote available because the claim is about list structure: `grep '^[0-9]\.' docs/roadmap.md` gives items 1–6 at lines 28, 32, 35, 39, 46, 50). `git grep -E 'Next #[67]|roadmap.{0,20}#?[67]'` in docs/skills/workflows finds no reference to the old item numbers.

**Evidence:** `docs/roadmap.md:26-56`

---

## Claim 11: Archive "Applied" note: "gate 5 passes `--jobs "${RUN_TESTS_JOBS:-8}"` to both runs; 1 is serial, a value outside run-tests.sh's `--jobs` grammar fails the gate before any test runs, and the runner still falls back to serial without GNU parallel. pr-prep's step 5a names the default and the override."

**Location:** `docs/working/questions-archive.md:2516`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** the user reading the question record
**Scope:** Covers each clause against Claims 1, 3, 4 and 6 and the pr-prep text; does not establish the empty-value nuance (the note does not claim it).

The text at `workflows/pr-prep.md:331` sits under step 5's "**a. Verify CI passes (automated).**" (`workflows/pr-prep.md:315`) and names `--jobs 8`, `RUN_TESTS_JOBS=N` and `RUN_TESTS_JOBS=1`. The other clauses are executed in E1–E4.

**Evidence:** `docs/working/questions-archive.md:2516`, `workflows/pr-prep.md:315-331`, `scripts/health-check.sh:408-428`

---

## Claim 12: "each with `--jobs 8` (Q-102 [1]: about 2.5 min against 7.5 min serial)"

**Location:** `workflows/pr-prep.md:331` (same figures in the 65c931e6 commit message, first paragraph)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** an agent running pr-prep step 5a, judging whether the gate is hung
**Scope:** Covers that the figures match the Q-102/Q-090 record; does not establish the gate's wall time, which was not measured.

The figures are the recorded full-suite measurement rounded: 140 s ≈ 2.3 min, 451 s ≈ 7.5 min (`docs/working/questions-archive.md:1878`), and Q-102's own option row says "about 7.5 min instead of 2.5 min" (`docs/working/questions-archive.md:2509`). But that measurement was one `run-tests.sh --jobs 8` over the full suite. The gate runs two separate runner invocations (fast, then slow, `scripts/health-check.sh:420,428`), each with its own `bats --count` and its own slowest-file bound, plus checks 1–4 and 6+. The gate's time under `--jobs 8` is likely close but is not what was measured. A precise version: "the full suite measured about 2.5 min at `--jobs 8` against 7.5 min serial".

**Evidence:** `workflows/pr-prep.md:331`, `docs/working/questions-archive.md:1878`, `docs/working/questions-archive.md:2501-2509`, `scripts/health-check.sh:420-428`

---

## Claim 13: "`RUN_TESTS_JOBS=N` picks another N, and `RUN_TESTS_JOBS=1` runs serially; without GNU parallel the runner warns and runs serially."

**Location:** `workflows/pr-prep.md:331`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** an agent running pr-prep step 5a
**Scope:** Covers N within the grammar; does not tell the reader that N outside 1–999 fails the gate (an omission, not a misstatement).

E2: `RUN_TESTS_JOBS=16` → `--jobs 16` on both runs; `=1` → `--jobs 1`, which never adds bats `--jobs` (`scripts/run-tests.sh:413`). Fallback: Claim 3.

**Evidence:** `docs/reviews/execution-logs/cfc-r1-q102-checkbats.log`, `scripts/run-tests.sh:411-420`

---

## Claim 14: "(in claude-workflows, `scripts/run-tests.sh --failed`, which runs serially)"

**Location:** `workflows/pr-prep.md:345`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** an agent re-running failures in step 5a
**Scope:** Covers the command as written (no `--jobs`); does not establish serial behaviour if the reader adds `--jobs`, which `--failed` accepts.

The runner's default is serial, `jobs=1` (`scripts/run-tests.sh:132`), and nothing else sets it: the only assignment is `jobs="$2"` in the `--jobs)` branch (`scripts/run-tests.sh:149`), and run-tests.sh does not read RUN_TESTS_JOBS (paraphrased — no quote available because the claim covers absence of code: `git grep -n RUN_TESTS_JOBS` hits only health-check.sh, health-check.bats, pr-prep.md and the archive). The header notes the residue: "Combines with every other flag, --failed included." (`scripts/run-tests.sh:39-40`).

**Evidence:** `scripts/run-tests.sh:36-40`, `scripts/run-tests.sh:131-150`, `scripts/run-tests.sh:411-420`

---

## Claim 15: Commit 65c931e6 message: "the variable is read by health-check.sh only, not by run-tests.sh, so direct runner calls (and --failed re-runs) stay serial unless --jobs is passed. An empty RUN_TESTS_JOBS means the default 8, like unset." Also "roadmap Next #6 is removed" and "a value outside run-tests.sh's --jobs grammar fails the gate by name before any test runs".

**Location:** commit `65c931e6` message body
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a reviewer reading `git log`
**Scope:** Covers readers of the variable in the tracked tree and the empty/unset runtime effect; does not establish readers outside the repo (user shell profiles, other harnesses), and the "2.5 against 7.5 min" sentence is covered in Claim 12.

`git grep -n RUN_TESTS_JOBS` shows code reads only at `scripts/health-check.sh:408`; the other hits are comments, tests and docs (paraphrased — no quote available because the claim covers absence of code in run-tests.sh). E2: `RUN_TESTS_JOBS=''` → `STUB --fast --jobs 8`, `STUB --slow --jobs 8`, `FAIL=0`, the same as unset. The old Next #6 (Q-102) is the removed roadmap item (diff hunk at `docs/roadmap.md:47`).

**Evidence:** `scripts/health-check.sh:408`, `scripts/run-tests.sh:132`, `docs/roadmap.md:46-56`, `docs/reviews/execution-logs/cfc-r1-q102-checkbats.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2** (`scripts/health-check.sh:28-32`): "any other value fails" does not cover an empty RUN_TESTS_JOBS, which means 8. Say "unset or empty means 8".
- **Claim 5** (`scripts/health-check.sh:386-388`): the 140 s / 451 s figures come from Q-090 in the questions archive, not from run-tests.sh's "Parallel runs" section, which has only the jobs-16-vs-8 figure. Repoint the citation.
- **Claim 8** (`test/scripts/health-check.bats:203-205`): the outer gate has no RUN_TESTS_JOBS "of its own" (it never sets or exports one). The ambient value is whatever the outer gate was started with.
- **Claim 12** (`workflows/pr-prep.md:331`, commit message): 2.5 vs 7.5 min is the full-suite single-run measurement, not the gate's fast+slow pair. Attribute it to the suite, or measure the gate.

### Unverifiable
(none)

## Goal-Alignment Note

The goal was Q-102 [1]: parallel test gates by default, with an env override, 1 meaning serial, and a serial fallback without GNU parallel. The branch does this. Gate 5 passes `--jobs "${RUN_TESTS_JOBS:-8}"` to both runs (E2). Its validator matches the runner's grammar exactly (E1/E2). The fallback is the runner's existing, tested path (E4), and no other reader of the variable exists, so `--failed` and direct runner calls stay serial as the docs say. None of the four Mostly-accurate items misstates behaviour: they are a missing empty-value note, a misdirected citation, an imprecise parenthetical, and a timing figure from a different measurement shape. One limit on this check: the bats file's own gate-5 tests (E3) could not run while the gate in this worktree holds health-check.lock, so Claim 9 rests on replicating the helper's invocation rather than on the bats run. The running gate's result is the direct check.
