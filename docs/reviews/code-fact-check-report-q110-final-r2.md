Commit: 16ce27bf

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q110 (claude-workflows, branch `fix/q110-not-run-undercount`)
**Scope:** `git diff main...HEAD -- scripts test docs/thoughts` (scripts/run-tests.sh, test/skills/eval-helpers-gating.bats, docs/thoughts/failure-patterns.md), the commit messages of `git log main..HEAD` (70aa3a78, f84a9dfa, 40f524df, 4b775841, 16ce27bf), and prose in the iteration-1 review artifacts only where it describes this branch's code
**Checked:** 2026-10-14
**Total claims checked:** 23
**Summary:** 19 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination log: `docs/reviews/hallucination-patterns.md` was read; no logged pattern matches any claim below (no env-var or inheritance pattern is logged).

Execution provenance (all runs on 2026-10-15 between 04:40:26Z and 04:43Z UTC, i.e. 2026-10-14 local; outputs captured under `/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.09Bo/`, outside the repo per the brief's write rule):

| Run | Command | cwd | Exit | Output |
|---|---|---|---|---|
| E1 | `timeout 300 bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats` | /workspace/.claude/wt-q110 | 0 (7/7 ok) | `fcr2.09Bo/suite-new.log` |
| E2 | `RUN_TESTS_NOT_RUN_FILE=$d/nr-new timeout 300 bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats; cat $d/nr-new` | /workspace/.claude/wt-q110 | 0; file reads `0` | `fcr2.09Bo/repro-new.log` |
| E3 | same as E2 with `$d/nr-old`, on `git archive main` extracted to `$d/old` | `$d/old` | 0; file reads `4` | `fcr2.09Bo/repro-old.log` |
| E4 | HEAD's `eval-helpers-gating.bats` copied into `$d/old` (main's runner), `timeout 300 bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats` | `$d/old` | 1; only test 3 fails, at line 84 `[ "$(cat "$T/nr")" = 4 ]` | `fcr2.09Bo/newtest-oldrunner.log` |
| E5 | mini layout (one gated suite, one free suite, the test's stub bats on PATH), `RUN_TESTS_NOT_RUN_FILE=$L/nr timeout 60 bash $L/scripts/run-tests.sh --fast` with main's then HEAD's runner | `$d` | 0 / 0; nr `99` / `1`; stub saw the path / `unset` | `fcr2.09Bo/stub-old.log`, `fcr2.09Bo/stub-new.log` |
| E6 | `PARALLEL_ENV='export FOO=injected' timeout 20 parallel --plain 'echo ${FOO-unset}' ::: 1` (GNU parallel 20221122) | `$d` | 0; prints `injected 1` | inline (one line; recorded in this table) |

---

## Claim 1: "the write is now at :359-360" / "→ header, gating comment, :359-368 only"

**Location:** `docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md:88`, `:62`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line numbers the rubric cites for the count write and the unset; does not establish anything about the rubric's findings, which other claims cover.
**Legibility-target:** for-author

The numbers match the rubric's pinned `Commit: f84a9dfa`, where `git show f84a9dfa:scripts/run-tests.sh` puts the write at `359:if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then` and the unset at `368:unset RUN_TESTS_NOT_RUN_FILE`. But 4b775841 added one header line, and the rubric (committed afterwards at 16ce27bf) says "now". At HEAD the write is at:

```bash
# scripts/run-tests.sh:360-361
if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
```

and the unset at `scripts/run-tests.sh:369`. The precise version is ":360-361" and ":360-369" at HEAD (or "at f84a9dfa" attached to the current numbers). This is a one-line offset in a review artifact, and nothing reads it mechanically.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md:1,62,88`, `scripts/run-tests.sh:360-369`

---

## Claim 2: "FP-173 ... cause:boundary-too-wide fix:remove-the-path ref:70aa3a78"

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two tokens being in the vocabulary tables and the ref naming the fix commit; it does not decide whether `boundary-too-wide` is the best category (that is judgment), and it does not establish that the ref resolves on main after landing (that holds only for a history-preserving merge).
**Legibility-target:** for-orchestrator-synthesis

Both tokens are in the tables: `docs/thoughts/failure-patterns.md:64` reads ``| 13 | `boundary-too-wide` | a security or isolation boundary admitted more than intended |`` and `:99` reads ``| 7 | `remove-the-path` | delete the capability rather than guarding it |``. `git log --oneline -1 70aa3a78` prints `70aa3a78 fix(run-tests): stop the suites inheriting RUN_TESTS_NOT_RUN_FILE (Q-110)`, the commit that adds the unset. An env var leaking from the runner into child processes fits "an isolation boundary admitted more than intended", and the fix deletes the inheritance path rather than guarding it.

**Evidence:** `docs/thoughts/failure-patterns.md:64,99,315`

---

## Claim 3: "It is unset before bats runs, so the suites (and any runner a suite starts) do not inherit the caller's value."

**Location:** `scripts/run-tests.sh:19-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every path from the write to `exec bats` (serial, `--jobs` via GNU parallel, `--failed`, the `bats --count` step) and the fact that nothing after the unset reads the variable. It does not cover a value a suite sets itself, or one a caller injects on purpose through `PARALLEL_ENV` code (the wording does not claim either), and it does not establish that early-exit paths write the file (they exit before the write; that is pre-existing).
**Legibility-target:** for-orchestrator-synthesis

The unset follows the write directly. Every bats invocation comes after it:

```bash
# scripts/run-tests.sh:360-369
if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
fi
# The file is this run's answer to its caller, ...
unset RUN_TESTS_NOT_RUN_FILE
```

```bash
# scripts/run-tests.sh:442
  expected="$(bats --count "${files[@]}" 2>/dev/null)" || expected="?"
# scripts/run-tests.sh:453
exec bats "${bats_args[@]}" "${files[@]}"
```

A grep of `bats |exec |exit ` over lines 81-453 shows no bats invocation before :360. The exits before it (:151-308, :357) and the `exit 0` paths at :396 and :402 start no bats. `grep -rn RUN_TESTS_NOT_RUN_FILE scripts test` finds no read after :369. The `--failed` filter (:383-398) and the `--jobs` block (:422-436) both come after the unset. Executed: in E5, HEAD's runner hands the stub bats `unset` and the caller's file keeps its own count (1), while main's runner hands it the path and the file reads 99. E1 and E4 show the regression test passing on HEAD and failing on main.

**Evidence:** `scripts/run-tests.sh:19-23,360-369,383-453`; E1 `fcr2.09Bo/suite-new.log`, E4 `fcr2.09Bo/newtest-oldrunner.log`, E5 `fcr2.09Bo/stub-old.log`, `fcr2.09Bo/stub-new.log`

---

## Claim 4: "a suite that runs the runner again (eval-helpers-gating.bats does, with no override) would otherwise overwrite the caller's count with its fixture's"

**Location:** `scripts/run-tests.sh:364-366`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-override nested calls in eval-helpers-gating.bats and the fixture count being 4. It does not establish that no other suite nests the runner (Claim 20 covers that).
**Legibility-target:** for-orchestrator-synthesis

Tests 4 and 6 run the runner with no `RUN_TESTS_NOT_RUN_FILE` of their own: `run bash "$T/scripts/run-tests.sh" --fast` (`test/skills/eval-helpers-gating.bats:90`, `:105`; test 5 at `:97` exits 1 before the write). The fixture gates four suites (`suite alpha-eval.bats alpha` ... `suite beta/dimensions.bats beta`, `:19-23`). Executed: with main's runner (E3) the caller's file reads `4`, although the parent run gates nothing. With HEAD's runner (E2) it reads `0`.

**Evidence:** `test/skills/eval-helpers-gating.bats:19-26,88-108`; E2 `fcr2.09Bo/repro-new.log`, E3 `fcr2.09Bo/repro-old.log`

---

## Claim 5: "(Q-110: the health check said 4 where this run listed 50)"

**Location:** `scripts/run-tests.sh:366`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the recorded Q-110 observation and the 4 being the fixture's count (reproduced in E3). It does not re-observe the 2026-10-02 run's 50, which depends on that day's report state and exists only as a record.
**Legibility-target:** for-orchestrator-synthesis

`docs/working/questions.md:70` records: "the test runner printed `NOT RUN: 50 report-dependent suite(s)`, but the health check's own summary said `4 report-dependent BATS suite(s) NOT RUN`". The 4 matches the fixture count that E3 reproduces.

**Evidence:** `docs/working/questions.md:67-74`; E3 `fcr2.09Bo/repro-old.log`

---

## Claim 6: "Refusing an inherited value instead cannot work, since the health check itself passes it through the environment."

**Location:** `scripts/run-tests.sh:366-368`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how health-check.sh passes the variable (both runs). It does not cover other possible callers.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/health-check.sh:431
    if ! HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast --jobs "$jobs"; then
# scripts/health-check.sh:439
    if HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/slow" "$runner" --slow --jobs "$jobs"; then
```

A command-prefix assignment reaches the runner as an ordinary exported env var. The runner cannot tell it apart from one inherited through bats, so refusing inherited values would also refuse the health check's.

**Evidence:** `scripts/health-check.sh:424-446`

---

## Claim 7: "the suites do not inherit RUN_TESTS_NOT_RUN_FILE, so a nested run cannot overwrite the caller's count" (test name)

**Location:** `test/skills/eval-helpers-gating.bats:74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's non-vacuity (it fails on main's runner, passes on HEAD's) and the property in its name for inherited values. It does not cover a suite that explicitly sets the caller's path, which no test could rule out.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers-gating.bats:82-85
  run env RUN_TESTS_NOT_RUN_FILE="$T/nr" bash "$T/scripts/run-tests.sh" --fast
  [ "$status" -eq 0 ]
  [ "$(cat "$T/nr")" = 4 ]
  [ "$(cat "$T/bats-env")" = unset ]
```

E1: `ok 3 the suites do not inherit RUN_TESTS_NOT_RUN_FILE, ...`. E4 (main's runner): `not ok 3 ...` with ``# `[ "$(cat "$T/nr")" = 4 ]' failed`` at line 84. The other six tests pass in E4.

**Evidence:** `test/skills/eval-helpers-gating.bats:74-86`; E1 `fcr2.09Bo/suite-new.log`, E4 `fcr2.09Bo/newtest-oldrunner.log`

---

## Claim 8: "a suite that runs the runner again (as this file does below, with no override) inherited the caller's file and overwrote its count: the health check printed 4 where the runner had listed 50"

**Location:** `test/skills/eval-helpers-gating.bats:75-77`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers "below, with no override" (tests at :88-108) and the 4/50 record. The executed overwrite is Claim 4's.
**Legibility-target:** for-orchestrator-synthesis

The calls below the comment run with no override: `run bash "$T/scripts/run-tests.sh" --fast` at `test/skills/eval-helpers-gating.bats:90`, `:97`, `:105`. The tests above it (`:50`, `:63`) set their own value. The 4/50 record is quoted in Claim 5.

**Evidence:** `test/skills/eval-helpers-gating.bats:50,63,88-108`, `docs/working/questions.md:70`

---

## Claim 9: "The stub bats stands in for any such suite: it writes to the inherited path when it has one, and records whether it had one."

**Location:** `test/skills/eval-helpers-gating.bats:77-81`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stub's two behaviours and the reason it can stand in for suites: they are children of bats and inherit only what bats has. It does not cover a suite that exports its own value, or `PARALLEL_ENV` code, which runs inside parallel's job shell rather than through bats' environment.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers-gating.bats:80-81
  printf '#!/usr/bin/env bash\necho "${RUN_TESTS_NOT_RUN_FILE-unset}" > "%s/bats-env"\n[ -z "${RUN_TESTS_NOT_RUN_FILE:-}" ] || echo 99 > "$RUN_TESTS_NOT_RUN_FILE"\n' \
    "$T" > "$T/bin/bats"
```

The stub records the value (or `unset`) and writes 99 only when it inherits a path. E5 shows both: main's runner leaves 99 and a recorded path, and HEAD's leaves the caller's count and `unset`. The stub replaces bats itself, and every suite and nested runner is a descendant of that process, so an unset at the bats level covers them all, apart from the scope residue named above.

**Evidence:** `test/skills/eval-helpers-gating.bats:80-81`, `scripts/run-tests.sh:453`; E5 `fcr2.09Bo/stub-old.log`, `fcr2.09Bo/stub-new.log`

---

## Claim 10: "Reproduction: RUN_TESTS_NOT_RUN_FILE=$d/nr bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats; cat $d/nr -> 4 before (the parent gated none), 0 after."

**Location:** commit 70aa3a78 (body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the documented reproduction on main's and HEAD's trees. It does not establish the full-suite health-check numbers.
**Legibility-target:** for-orchestrator-synthesis

E3 (main tree): exit 0, file reads `4`. E2 (HEAD): exit 0, file reads `0`. The parent gates none because eval-helpers-gating.bats has no `@needs-reports` header (paraphrased — no quote available because the claim is about the absence of a tag in `test/skills/eval-helpers-gating.bats:1-5`, which carry only `# @category fast` and prose).

**Evidence:** `test/skills/eval-helpers-gating.bats:1-5`; E2 `fcr2.09Bo/repro-new.log`, E3 `fcr2.09Bo/repro-old.log`

---

## Claim 11: "on the old runner the caller's file reads 99, now 4"

**Location:** commit 70aa3a78 (body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regression test's stub scenario on both runners. The "4" is the test fixture's count (E5's smaller layout gives 1 for the same reason).
**Legibility-target:** for-orchestrator-synthesis

E5 with main's runner: `nr=99`, stub saw the path. E4 shows the 4-assertion failing on main's runner in the real fixture, and E1 shows it passing on HEAD's.

**Evidence:** E1 `fcr2.09Bo/suite-new.log`, E4 `fcr2.09Bo/newtest-oldrunner.log`, E5 `fcr2.09Bo/stub-old.log`

---

## Claim 12: "so neither bats nor anything a suite starts can see the caller's path"

**Location:** commit 70aa3a78 (body)
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers inheritance through the environment, which the unset closes. Under `--jobs`, the residue is that a caller's `PARALLEL_ENV` code can still set the variable in every job. Later commit 4b775841 already narrows the header and test name to "do not inherit".
**Legibility-target:** for-author

The unset removes inheritance (Claim 3). E6 shows that GNU parallel runs `PARALLEL_ENV` code before each job (`injected 1`). The runner unsets only `PARALLEL PARALLEL_CSH` (`scripts/run-tests.sh:430`), so caller-supplied code can still hand jobs the path. The precise version is "nothing bats starts inherits the caller's path". This commit message cannot be changed; 4b775841's body records the narrowing, so no action is needed beyond that.

**Evidence:** `scripts/run-tests.sh:369,429-433`; E6 (table above)

---

## Claim 13: "(test/scripts/run-tests.bats and others call it too)"

**Location:** commit 70aa3a78 (Notes)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which test files start the real runner. 4b775841's body already corrects "and others".
**Legibility-target:** for-author

Of the files under `test/` that mention `run-tests.sh`, only `test/scripts/run-tests.bats` (`:67 bash "$T/scripts/run-tests.sh" "$@" 3>&-`, also `:84`, `:473`, `:505`) and eval-helpers-gating.bats run it. The rest mention it in comments, or (health-check.bats) reach a runner only through stubs and the `HEALTH_CHECK_SKIP_BATS` guard (paraphrased — no quote available because the claim covers the absence of invocations across 12 files; per-file grep output was reviewed). The precise version is "test/scripts/run-tests.bats calls it too".

**Evidence:** `test/scripts/run-tests.bats:67,84,473,505`, `test/scripts/health-check.bats:19,219,284,492`

---

## Claim 14: "no suite reads the variable from its environment"

**Location:** commit 70aa3a78 (Notes)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers suites' reads of the variable. 4b775841's body already corrects it.
**Legibility-target:** for-author

`test/scripts/health-check.bats:488` contains `[ "$1" = --fast ] && echo 47 > "$RUN_TESTS_NOT_RUN_FILE"`, a stub runner that reads the variable from its environment. health-check.sh sets that value inside the test (`scripts/health-check.sh:431`), not the outer runner, so the conclusion (no suite relies on the inherited value) holds. The precise version is 4b775841's wording.

**Evidence:** `test/scripts/health-check.bats:484-498`, `scripts/health-check.sh:431`

---

## Claim 15: "health-check.sh's comments stay accurate"

**Location:** commit 70aa3a78 (Notes)
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers health-check.sh's comments that mention the variable (:377, :424-427, :453-454). It does not cover the rest of the file.
**Legibility-target:** for-orchestrator-synthesis

`scripts/health-check.sh:376-377` reads "this gate only surfaces how many it left out, as a warning, via RUN_TESTS_NOT_RUN_FILE", and `:424-425` reads "The runner writes how many report-dependent suites it gated out ... to RUN_TESTS_NOT_RUN_FILE". Both still hold: the runner writes before unsetting. Nothing in the comments describes the variable reaching the suites.

**Evidence:** `scripts/health-check.sh:365-460`

---

## Claim 16: "Reused cause:boundary-too-wide and fix:remove-the-path rather than coining new tokens; the count tables above the log are a dated snapshot and were left as is."

**Location:** commit f84a9dfa (Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers token reuse and the snapshot nature of the tables. It does not check the table counts.
**Legibility-target:** for-orchestrator-synthesis

Both tokens appear in earlier entries, for example `- **FP-043** ... cause:boundary-too-wide fix:remove-the-path ref:b7e4595` (`docs/thoughts/failure-patterns.md:185`). `:49-50` reads "164 entries harvested from the 105 `fix(...)` commits on `main` since this file was created (2026-05-18)", which is a dated snapshot. The diff touches only `:315`.

**Evidence:** `docs/thoughts/failure-patterns.md:49-64,99,185,315`

---

## Claim 17: "0 Incorrect/Stale; 2 Mostly accurate on commit 70aa3a78 wording; security, performance clean; api-consistency 1 Informational."

**Location:** commit 40f524df (Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the artifacts that 40f524df committed. The later submitted-claims refutation of a performance endorsement (rubric A4, committed in 4b775841) came after it and is not a performance finding.
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/code-fact-check-report-q110.md:8`: `**Summary:** 20 Verified, 2 Mostly accurate, 0 Incorrect, 0 Stale, 0 Unverifiable`. `docs/reviews/performance-review-2026-10-14-q110.md:18` and `docs/reviews/security-review-2026-10-14-q110.md:38`: `No findings.` The rubric's C1 lists api-consistency F1 as Informational.

**Evidence:** `docs/reviews/code-fact-check-report-q110.md:8`, `docs/reviews/performance-review-2026-10-14-q110.md:18`, `docs/reviews/security-review-2026-10-14-q110.md:38`

---

## Claim 18: "a suite can still set its own value (eval-helpers-gating.bats does)"

**Location:** commit 4b775841 (body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the explicit `env RUN_TESTS_NOT_RUN_FILE=...` calls in that suite.
**Legibility-target:** for-orchestrator-synthesis

`test/skills/eval-helpers-gating.bats:50`: `run env RUN_TESTS_NOT_RUN_FILE="$T/nr" bash "$T/scripts/run-tests.sh" --fast` (also `:63`, `:82`).

**Evidence:** `test/skills/eval-helpers-gating.bats:50,63,82`

---

## Claim 19: "a caller can inject one through PARALLEL_ENV code under --jobs"

**Location:** commit 4b775841 (body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU parallel 20221122 (the installed version) running `PARALLEL_ENV` code before a job, and the runner not unsetting it. It does not run a full bats `--jobs` run with injected code (the iteration-1 submitted Claim 23b reports that run).
**Legibility-target:** for-orchestrator-synthesis

E6 prints `injected 1`. `/usr/bin/parallel` comments "If $PARALLEL_ENV set, put that in front of the command" (line 9825). The runner unsets only `PARALLEL PARALLEL_CSH` (`scripts/run-tests.sh:430`).

**Evidence:** `scripts/run-tests.sh:429-433`, `/usr/bin/parallel:9825`; E6 (table above)

---

## Claim 20: "only test/scripts/run-tests.bats calls the runner besides eval-helpers-gating.bats itself"

**Location:** commit 4b775841 (body)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers suites under `test/` that start the real `scripts/run-tests.sh`. It excludes health-check.bats's runs of health-check.sh, which reach only a stub runner or the skip guard, and non-test callers (health-check.sh).
**Legibility-target:** for-orchestrator-synthesis

See Claim 13's evidence. `test/scripts/health-check.bats:19` exports `HEALTH_CHECK_SKIP_BATS=1`, and every `check_bats` call that unsets it supplies `HEALTH_CHECK_RUN_TESTS="$stub"` (`:219`, `:492`).

**Evidence:** `test/scripts/run-tests.bats:67,84,473,505`, `test/scripts/health-check.bats:19,219,284,492`

---

## Claim 21: "test/scripts/health-check.bats:488's stub reads one health-check.sh sets"

**Location:** commit 4b775841 (body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that line and its setter.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/health-check.bats:488`: `[ "$1" = --fast ] && echo 47 > "$RUN_TESTS_NOT_RUN_FILE"`. The stub runs as `$runner` from `scripts/health-check.sh:431`, which sets `RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast"`.

**Evidence:** `test/scripts/health-check.bats:484-498`, `scripts/health-check.sh:413,431`

---

## Claim 22: "Did not add PARALLEL_ENV to the runner's existing unset of PARALLEL settings"

**Location:** commit 4b775841 (Notes)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the unset line at HEAD. It does not cover whether leaving it out is the right call (judgment).
**Legibility-target:** for-orchestrator-synthesis

`scripts/run-tests.sh:430`: `  unset PARALLEL PARALLEL_CSH`. The line is unchanged by the branch.

**Evidence:** `scripts/run-tests.sh:429-436`

---

## Claim 23: "0 red; 4 amber fixed in 4b775841 or withdrawn (refuted performance endorsement)"

**Location:** commit 16ce27bf (Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between the rubric's tables and 4b775841's diff. It does not re-verdict the findings.
**Legibility-target:** for-orchestrator-synthesis

The rubric's Must Fix table reads `None.`. A1-A3 are `Fixed` and A4 is `Withdrawn` (`docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md:31-34`). 4b775841's diff rewrites the header (`scripts/run-tests.sh:20-23`) and the test name (`test/skills/eval-helpers-gating.bats:74`), and its body carries the A1/A2 corrections.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md:20-34`, `scripts/run-tests.sh:19-23`, `test/skills/eval-helpers-gating.bats:74`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 1** (`docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md:62,88`): line numbers are right for f84a9dfa but "now" at HEAD is :360-361 / :360-369 (one header line was added in 4b775841).
- **Claim 12** (commit 70aa3a78): "neither bats nor anything a suite starts can see the caller's path" overstates. A caller's `PARALLEL_ENV` can still inject it. Already narrowed by 4b775841.
- **Claim 13** (commit 70aa3a78): "and others": only test/scripts/run-tests.bats. Already corrected in 4b775841.
- **Claim 14** (commit 70aa3a78): health-check.bats:488's stub does read the variable, though one health-check.sh sets. Already corrected in 4b775841.

### Unverifiable
None.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved at the output path given in your tail, structured per your skill."
- **Answered:** Yes. The report is at `docs/reviews/code-fact-check-report-q110-final-r2.md` with `Commit: 16ce27bf` first and the skill's header, per-claim fields and attention summary, plus a Legibility-target on each claim. All five brief focus areas are verdicted: header (Claim 3), gating comment (4-6), commit claims (10-23), test non-vacuity (7, 9; executed and failing on main), FP-173 tokens (2).
- **Out of scope:** Code quality and the choice of fix; whether `boundary-too-wide` is the best category; the pre-existing early-exit-leaves-file-unwritten behaviour (rubric escalation, already dispositioned).
- **Escalate:** Q-110 in `docs/working/questions.md:73` still cites `scripts/run-tests.sh:356-357`. The write is at :360-361 at HEAD. This is owned by the orchestrator, as the rubric notes.
- **Questions/Decisions:** None. Execution logs are kept outside the repo (`/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.09Bo/`) because of the brief's write-nothing-else rule, not under `docs/reviews/execution-logs/` as the skill would normally have it. Copy them in if durable provenance is wanted.
