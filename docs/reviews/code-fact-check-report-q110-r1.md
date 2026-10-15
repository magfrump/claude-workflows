Commit: f84a9dfa

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q110 (claude-workflows), branch `fix/q110-not-run-undercount`
**Scope:** branch diff `main...HEAD` (70aa3a78, f84a9dfa): `scripts/run-tests.sh`, `test/skills/eval-helpers-gating.bats`, `docs/thoughts/failure-patterns.md`, plus both commit messages; enclosing context read in full: `scripts/run-tests.sh` (whole file), `test/skills/eval-helpers-gating.bats` (whole file), `scripts/health-check.sh:365-470` (`check_bats`, `_not_run_count`, `_not_run_note`), `test/scripts/health-check.bats:183-290,484-498`, `docs/working/questions.md` Q-110 entry
**Checked:** 2026-10-14
**Total claims checked:** 16
**Summary:** 15 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 8 entries). The nearest logged class is "a specific measured count quoted from an artifact set that does not contain it" (the "All 85 tests" and "mode1-equiv 33" entries). Every number in this diff (4, 50, 99, 0) was therefore re-derived or re-run, not taken on trust (Claims 5, 11, 12). None matched.

Execution logs: the brief forbids writing anywhere in the repo except this report, so captured output lives outside the repo in `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-logs.8cWG/` and not under `docs/reviews/execution-logs/`. The worktree's own `.bats/lock` was held by a concurrent run for more than 2 minutes, and the in-worktree runs logged "another run-tests.sh run is in progress in this checkout" (`new-suite.log`, `repro-new.log`, both exit 1, no test ran). So every executed check ran the runner from a throwaway layout that copies `scripts/run-tests.sh` (HEAD's, or `git show main:scripts/run-tests.sh`), `test/skills/runner-contract.bash`, `test/lib/hermetic-env.bash` and HEAD's `test/skills/eval-helpers-gating.bats`.

---

## Claim 1: "cause:boundary-too-wide fix:remove-the-path"

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both tokens exist in the vocabulary tables and that their definitions fit the fix; does not establish that no better-fitting token exists (picking a category is a judgment call).
**Legibility-target:** for-orchestrator-synthesis

Both tokens are defined in the backfilled vocabulary tables:

```
docs/thoughts/failure-patterns.md:64   | 13 | `boundary-too-wide` | a security or isolation boundary admitted more than intended |
docs/thoughts/failure-patterns.md:99   | 7 | `remove-the-path` | delete the capability rather than guarding it |
```

The fix fits `remove-the-path`: it deletes the variable instead of guarding writes to it (`scripts/run-tests.sh:368` `unset RUN_TESTS_NOT_RUN_FILE`). For `boundary-too-wide`, the "boundary" is the process boundary between the runner and the bats tree, which passed through the caller's output path. That is an isolation boundary admitting more than intended, but not a security one. Every earlier use of the token is a security or sandbox boundary (paraphrased — no quote available because this is a summary of the 13 `cause:boundary-too-wide` lines, e.g. FP-043, FP-128, FP-140 at `:185`, `:270`, `:282`). This entry stretches the token's usual sense but stays inside its written definition.

**Evidence:** `docs/thoughts/failure-patterns.md:64`, `docs/thoughts/failure-patterns.md:99`, `docs/thoughts/failure-patterns.md:185-290`, `scripts/run-tests.sh:368`

---

## Claim 2: "ref:70aa3a78"

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the SHA resolves to the Q-110 fix commit on this branch; does not establish that the SHA survives landing (a rebase or squash at merge would orphan it, whereas a merge commit keeps it).
**Legibility-target:** for-orchestrator-synthesis

`git show --stat 70aa3a78` resolves to `commit 70aa3a7809844e3bd5dc20fadb52dd67b3eb6a5a ... fix(run-tests): stop the suites inheriting RUN_TESTS_NOT_RUN_FILE (Q-110)`. The other `ref:` SHAs in the log are 7 characters, and this one is 8. That is cosmetic and not a claim error.

**Evidence:** `git log main..HEAD` (70aa3a78), `docs/thoughts/failure-patterns.md:313-315`

---

## Claim 3: "It is unset before bats runs, so the suites (and any runner a suite starts) never see it."

**Location:** `scripts/run-tests.sh:20-22`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every control path from the count write to each `bats` invocation (`bats --count`, the final `exec bats`, with or without `--failed` and `--jobs`) and that nothing after the unset reads the variable; does not establish anything about a suite that sets the variable explicitly for its own nested runner (it then sees its own value, as the existing tests 1-3 do by design), and the executed check ran the stub bats, not real bats or GNU parallel.
**Legibility-target:** for-orchestrator-synthesis

The write and the unset are adjacent, and nothing in between can exit:

```bash
# scripts/run-tests.sh:359-368
if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
fi
# The file is this run's answer to its caller, ...
unset RUN_TESTS_NOT_RUN_FILE
```

Only two places invoke bats, and both come after line 368: `expected="$(bats --count "${files[@]}" 2>/dev/null)" || expected="?"` (`scripts/run-tests.sh:441`) and `exec bats "${bats_args[@]}" "${files[@]}"` (`scripts/run-tests.sh:452`). Under `--jobs N`, GNU parallel is started by bats (paraphrased — no quote available because the `--jobs` branch at `:428-435` only appends `--jobs "$jobs" --no-parallelize-within-files` to `bats_args`, and no process is started there except `parallel --plain --version`, which runs after the unset). It therefore inherits the already-unset environment. The early `exit 0` paths at `:395` and `:401`, and every exit before `:359` (usage errors, lock contention, bad tags at `:354-357`), start no bats. The only other mention of the variable is the comment at `:316-322`, so nothing after the unset reads it (paraphrased — no quote available because this is a grep result: `grep -rn RUN_TESTS_NOT_RUN_FILE scripts/run-tests.sh` hits only `:19`, `:320`, `:359`, `:360`, `:368`).

Executed: the new test 3, where the stub bats records `${RUN_TESTS_NOT_RUN_FILE-unset}`, passes on HEAD's runner (`ok 3 ...`). The stub is called both for `--count` and for the exec, because the layout records (flock present).

- Command: `env RUN_TESTS_NOT_RUN_FILE=$d/nr bash $N/scripts/run-tests.sh test/skills/eval-helpers-gating.bats` ($N = throwaway layout holding HEAD's runner)
- cwd: `/workspace/.claude/wt-q110`
- Exit code: 0 (7/7 ok)
- Ran 2026-10-15T04:20:07Z to 04:20:13Z (UTC)

**Evidence:** `scripts/run-tests.sh:319-322`, `scripts/run-tests.sh:354-368`, `scripts/run-tests.sh:382-452`, `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-logs.8cWG/new-layout.log`

---

## Claim 4: "a suite that runs the runner again (eval-helpers-gating.bats does, with no override)"

**Location:** `scripts/run-tests.sh:363-364`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that eval-helpers-gating.bats starts `run-tests.sh` without setting the variable in tests 4-6; does not establish that every one of those calls writes a count (test 5 exits before the write).
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers-gating.bats:90 (test 4), :97 (test 5), :105 (test 6)
  run bash "$T/scripts/run-tests.sh" --fast
```

On the old runner, tests 4 and 6 reach the write with 4 gated suites (fixture `setup()` at `:19-23` creates four `@needs-reports` suites and no reports). Test 5 exits 1 at the bad-tag check before the write (`scripts/run-tests.sh:354-357`, which comes before `:359`). Tests 1-3 pass an explicit override (`run env RUN_TESTS_NOT_RUN_FILE="$T/nr" ...`, `:50`, `:63`, `:82`).

**Evidence:** `test/skills/eval-helpers-gating.bats:9-30`, `test/skills/eval-helpers-gating.bats:88-108`, `scripts/run-tests.sh:354-361`

---

## Claim 5: "(Q-110: the health check said 4 where this run listed 50)"

**Location:** `scripts/run-tests.sh:365`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers agreement with the Q-110 record and that both numbers can be reproduced from today's tree (50 gated fast suites; a nested fixture run writes 4); does not establish the 2026-10-02 health-check output itself, which was not re-run (the brief forbids running health-check.sh).
**Legibility-target:** for-orchestrator-synthesis

The Q-110 entry records the run:

```
docs/working/questions.md:73-75 (Q-110): the test runner printed `NOT RUN: 50 report-dependent suite(s)`, but the health check's own summary said `4 report-dependent BATS suite(s) NOT RUN`.
```

Re-derived 50: counting `@category fast` suites with a `# @needs-reports <skill>` header and no reports under `skill_has_reports` gives `fast 50`, `slow 0`. The command was a one-off bash loop over `find test -name '*.bats'` that sources `test/skills/runner-contract.bash` and is run from the worktree root (output printed inline, not captured to a file: `fast 50 / slow 0`). The 50 lands in the fast file, and the leak comes from a fast suite. Re-derived 4: the old runner leaves the caller's file at 4 after running this suite (Claim 11).

**Evidence:** `docs/working/questions.md:73-75`, `scripts/run-tests.sh:338-351`, `test/skills/runner-contract.bash`, `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-logs.8cWG/old-suite.log`

---

## Claim 6: "Refusing an inherited value instead cannot work, since the health check itself passes it through the environment."

**Location:** `scripts/run-tests.sh:365-367`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how health-check.sh hands the variable to the runner (as an environment prefix on the command, so to the runner it looks like any inherited value); does not establish whether some other signalling channel (a flag, say) could have replaced it, which is design rationale.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/health-check.sh:431
    if ! HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast --jobs "$jobs"; then
# scripts/health-check.sh:439
    if HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/slow" "$runner" --slow --jobs "$jobs"; then
```

A `VAR=value cmd` prefix puts the value in `cmd`'s environment the same way a nested suite's leaked export does. The runner has no way to tell the two apart.

**Evidence:** `scripts/health-check.sh:401-451`

---

## Claim 7: "the suites never see RUN_TESTS_NOT_RUN_FILE, so a nested run cannot overwrite the caller's count"

**Location:** `test/skills/eval-helpers-gating.bats:74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test asserts both halves (the stub saw `unset` and the caller's file still holds 4) and that it fails on the old runner and passes on the new one; does not establish the same through real bats or GNU parallel.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers-gating.bats:82-85
  run env RUN_TESTS_NOT_RUN_FILE="$T/nr" bash "$T/scripts/run-tests.sh" --fast
  [ "$status" -eq 0 ]
  [ "$(cat "$T/nr")" = 4 ]
  [ "$(cat "$T/bats-env")" = unset ]
```

Old runner: `not ok 3 ...` at `` `[ "$(cat "$T/nr")" = 4 ]' failed `` (line 84), the failure point the author named. New runner: `ok 3`.

- Old runner. Command: `env RUN_TESTS_NOT_RUN_FILE=$d2/nr bash $O/scripts/run-tests.sh test/skills/eval-helpers-gating.bats` ($O = throwaway layout with `git show main:scripts/run-tests.sh` and HEAD's suite). cwd `/workspace/.claude/wt-q110`. Exit 1. Ran 2026-10-15T04:15:31Z to 04:15:36Z.
- New runner: as in Claim 3, exit 0, 2026-10-15T04:20:13Z.

The test is not vacuous. It needs the caller to write first (4 gated fixtures) and needs the stub to find the variable unset. If the runner unset the variable *before* the write, the `= 4` check would fail. If the variable leaked, both checks would fail.

**Evidence:** `test/skills/eval-helpers-gating.bats:74-86`, `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-logs.8cWG/old-suite.log`, `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-logs.8cWG/new-layout.log`

---

## Claim 8: "a suite that runs the runner again (as this file does below, with no override)"

**Location:** `test/skills/eval-helpers-gating.bats:75-76`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the tests after line 86 call the runner without an override; does not establish anything beyond Claim 4, which it restates from inside the suite.
**Legibility-target:** for-orchestrator-synthesis

The tests after line 86 call the runner as `run bash "$T/scripts/run-tests.sh" --fast` (`test/skills/eval-helpers-gating.bats:90`, `:97`, `:105`), with no `RUN_TESTS_NOT_RUN_FILE` prefix. This is the same as Claim 4.

**Evidence:** `test/skills/eval-helpers-gating.bats:88-108`

---

## Claim 9: "The stub bats stands in for any such suite: it writes to the inherited path when it has one, and records whether it had one."

**Location:** `test/skills/eval-helpers-gating.bats:77-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the stub is a direct child of the runner, receives the environment that any suite under bats would inherit, writes 99 to an inherited path and records the value; does not establish that real bats passes the environment through unchanged (it does not scrub, but that was not run here), nor does it model a suite on the `--jobs` path.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers-gating.bats:80 (printf body, unescaped)
echo "${RUN_TESTS_NOT_RUN_FILE-unset}" > "$T/bats-env"
[ -z "${RUN_TESTS_NOT_RUN_FILE:-}" ] || echo 99 > "$RUN_TESTS_NOT_RUN_FILE"
```

The file keeps the executable bit that `setup()` set (`chmod +x "$T/bin/bats"`, `:28`), because the printf only rewrites its contents. Probe on the old runner, using a copy of the suite with an added `echo "NR=... ENV=..." >&3` before the `= 4` check: `NR=99 ENV=/tmp/tmp.NwiYu8ikEp/nr`. This shows the stub received the inherited path and wrote it. The stand-in works because real suites are children of bats in the same way.

- Command: `env RUN_TESTS_NOT_RUN_FILE=$d2/nr bash $O/scripts/run-tests.sh test/skills/eval-helpers-gating.bats` (probe copy of the suite in $O). cwd `/workspace/.claude/wt-q110`. Exit 1. Ended 2026-10-15T04:20:18Z.

**Evidence:** `test/skills/eval-helpers-gating.bats:27-29`, `test/skills/eval-helpers-gating.bats:80-81`, `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-logs.8cWG/old-probe99.log`

---

## Claim 10: "The runner wrote its NOT RUN count to $RUN_TESTS_NOT_RUN_FILE and then exec'd bats with the variable still exported. test/skills/eval-helpers-gating.bats runs the runner again with no override, so its nested runs overwrote the caller's count with the fixture's 4"

**Location:** commit `70aa3a78` message, paragraph 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old runner's write-then-exec order with no unset, and the overwrite by this suite; does not establish whether other suites on main also overwrote (see Claim 13 for `test/scripts/run-tests.bats`, a slow suite whose fixture count would land in the slow file).
**Legibility-target:** for-orchestrator-synthesis

`git show main:scripts/run-tests.sh` has the write followed directly by the NOT RUN listing and then `exec bats`, with no unset (paraphrased — no quote available because this describes the absence of a line in main's version; the diff hunk at `@@ -357,6 +359,13 @@` adds the only unset). Running this suite under the old runner leaves the caller's file at 4, even though the parent gated 0 (Claim 11).

**Evidence:** `git diff main...HEAD -- scripts/run-tests.sh`, `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-logs.8cWG/old-suite.log`

---

## Claim 11: "Reproduction: RUN_TESTS_NOT_RUN_FILE=$d/nr bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats; cat $d/nr  -> 4 before (the parent gated none), 0 after."

**Location:** commit `70aa3a78` message, paragraph 3
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both numbers, using runners copied into throwaway layouts with HEAD's suite; does not establish the reproduction in the worktree itself (blocked by a concurrent run holding `.bats/lock`), and "before" used HEAD's suite (which contains the new failing test 3) rather than main's suite. Tests 4 and 6 alone already write 4.
**Legibility-target:** for-orchestrator-synthesis

- Before (main's runner): `rc=1 nr=4` (`old-suite.log`). The parent gated none, because `eval-helpers-gating.bats` has no `@needs-reports` header (`test/skills/eval-helpers-gating.bats:1-5`). The rc is 1 only because test 3 fails on the old runner.
- After (HEAD's runner): `rc=0 nr=0` (`new-layout.log`).
- Commands, cwd and timestamps are as in Claims 3 and 7.

**Evidence:** `test/skills/eval-helpers-gating.bats:1-5`, `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-logs.8cWG/old-suite.log`, `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-logs.8cWG/new-layout.log`

---

## Claim 12: "on the old runner the caller's file reads 99, now 4"

**Location:** commit `70aa3a78` message, paragraph 2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the value in the new test's caller file (`$T/nr`) under both runners; does not establish anything about the outer reproduction file (that is Claim 11).
**Legibility-target:** for-orchestrator-synthesis

The old-runner probe printed `NR=99` for test 3 (`old-probe99.log` line 10). The new runner passes `[ "$(cat "$T/nr")" = 4 ]` (`test/skills/eval-helpers-gating.bats:84`, `ok 3` in `new-layout.log`).

**Evidence:** `test/skills/eval-helpers-gating.bats:84`, `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-logs.8cWG/old-probe99.log`, `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-logs.8cWG/new-layout.log`

---

## Claim 13: "(test/scripts/run-tests.bats and others call it too)"

**Location:** commit `70aa3a78` message, Notes
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which suites start the real runner script; does not establish what count `test/scripts/run-tests.bats`'s nested runs would have written on main.
**Legibility-target:** for-author

`test/scripts/run-tests.bats` does call the runner: `bash "$T/scripts/run-tests.sh" "$@" 3>&-` (`test/scripts/run-tests.bats:67`, also `:84`, `:473`, `:505`). But apart from it and eval-helpers-gating.bats, no other suite starts the runner. `test/scripts/health-check.bats` only drives stub runners through the `HEALTH_CHECK_RUN_TESTS` seam (`local stub="$BATS_TEST_TMPDIR/run-tests-stub.sh"`, `:189`; `local stub="$BATS_TEST_TMPDIR/run-tests-nr.sh"`, `:485`), and it sets `export HEALTH_CHECK_SKIP_BATS=1` at file level (`:19`). The remaining hits are comments (paraphrased — no quote available because this summarizes a grep: non-comment `run-tests` hits in `test/**/*.bats|*.bash` outside these two suites are only health-check.bats `:189`, `:252` (a test name), `:485`). A precise version would read "test/scripts/run-tests.bats calls it too". The conclusion still holds: the runner-side fix covers both nesting suites and any future one.

**Evidence:** `test/scripts/run-tests.bats:2`, `test/scripts/run-tests.bats:67`, `test/scripts/run-tests.bats:84`, `test/scripts/health-check.bats:19`, `test/scripts/health-check.bats:189`, `test/scripts/health-check.bats:485`

---

## Claim 14: "no suite reads the variable from its environment"

**Location:** commit `70aa3a78` message, Notes
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every reference to `RUN_TESTS_NOT_RUN_FILE` under `test/`: none depends on a value inherited from the runner; does not establish anything about suites outside the repo or uncommitted ones.
**Legibility-target:** for-orchestrator-synthesis

The only suite-side reads are stubs that receive an explicitly set value. The first is `[ "$1" = --fast ] && echo 47 > "$RUN_TESTS_NOT_RUN_FILE"` (`test/scripts/health-check.bats:488`). It is invoked by `check_bats`, which sets the variable on the command (`scripts/health-check.sh:431`), so it does not rely on what bats inherited. The second is the new test's stub (`test/skills/eval-helpers-gating.bats:80`), which reads it on purpose to detect a leak. Tests 1-3 set it explicitly with `run env RUN_TESTS_NOT_RUN_FILE="$T/nr" ...` (`:50`, `:63`, `:82`). No other reference exists (paraphrased — no quote available because this is a grep result: `grep -rn RUN_TESTS_NOT_RUN_FILE . --exclude-dir=.git` outside `docs/` hits only the lines cited here and in `scripts/`).

**Evidence:** `test/scripts/health-check.bats:484-497`, `test/skills/eval-helpers-gating.bats:50`, `test/skills/eval-helpers-gating.bats:63`, `test/skills/eval-helpers-gating.bats:80-82`, `scripts/health-check.sh:431`

---

## Claim 15: "health-check.sh's comments stay accurate"

**Location:** commit `70aa3a78` message, Notes
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the health-check.sh comments that describe RUN_TESTS_NOT_RUN_FILE and the count (gate-5 header, the in-function comment, `_not_run_count`); does not establish the accuracy of unrelated health-check.sh comments.
**Legibility-target:** for-orchestrator-synthesis

```
scripts/health-check.sh:376-377  owned by run-tests.sh; this gate only surfaces how many it left out, as a warning, via RUN_TESTS_NOT_RUN_FILE.
scripts/health-check.sh:424-425  # The runner writes how many report-dependent suites it gated out (no generated reports for their skill) to RUN_TESTS_NOT_RUN_FILE.
scripts/health-check.sh:453-454  # _not_run_count <file>: the gated-out count run-tests.sh wrote, or 0 when it wrote none (an older or stub runner) or wrote something that is not a number.
```

All three still describe the runner's behavior, which writes before the unset (`scripts/run-tests.sh:359-368`). None claims the variable reaches the suites.

**Evidence:** `scripts/health-check.sh:365-398`, `scripts/health-check.sh:421-469`, `scripts/run-tests.sh:359-368`

---

## Claim 16: "the count tables above the log are a dated snapshot and were left as is"

**Location:** commit `f84a9dfa` message, Notes
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the tables are dated and unchanged by the branch; does not establish whether they should be refreshed.
**Legibility-target:** for-orchestrator-synthesis

The tables sit under `### Backfilled 2026-09-17 — the vocabulary this corpus actually uses` (`docs/thoughts/failure-patterns.md:47`), with count columns such as `| 13 | \`boundary-too-wide\` |` (`:64`). The branch diff for this file is the single added FP-173 line (`@@ -312,3 +312,4 @@`).

**Evidence:** `docs/thoughts/failure-patterns.md:47-99`, `git diff main...HEAD -- docs/thoughts/failure-patterns.md`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 13** (commit `70aa3a78`, Notes): "test/scripts/run-tests.bats and others call it too". Besides eval-helpers-gating.bats, only test/scripts/run-tests.bats starts the real runner. health-check.bats drives stubs only. Drop "and others".

### Unverifiable
(none)

---

## Goal-Alignment Note

**Success criterion (verbatim):** "A markdown report saved at the output path given in your tail, structured per your skill."

**Answered:** Yes. All five claim groups in the brief are verdicted. (1) Header unset claim, every path checked: Claim 3. (2) Comment-block claims: Claims 4-6. (3) Commit-message claims: Claims 10-15. (4) Test name, stub stand-in, old-runner failure and non-vacuity: Claims 7-9, 12; the test was executed against main's runner and fails at line 84 as stated. (5) FP-173 tokens and ref: Claims 1-2.

**Out of scope:** Code quality and whether a per-suite `setup()` unset would also be wise, which are design matters for the other critics. Running health-check.sh or the full suite, which the brief forbids.

**Escalate:**
- The worktree's `.bats/lock` was held by another process for more than 2 minutes at 2026-10-15T04:15-04:20Z, and the in-worktree runner calls exited 1 with "another run-tests.sh run is in progress". The executed checks therefore used throwaway layouts. If no reviewer was meant to be running the suite then, someone should check for an orphaned run in `/workspace/.claude/wt-q110` (see the memory note on load probes).
- `docs/working/questions.md` Q-110 is still `Status: OPEN` on this branch and cites `scripts/run-tests.sh:356-357`, which is now `:359-360`. Presumably that gets fixed at landing (answer and archive), but the branch does not do it.

**Questions/Decisions:** In FP-173, `cause:boundary-too-wide` stretches a token every earlier entry uses for security or sandbox boundaries (Claim 1). It is acceptable under the written definition, and the author chose to reuse a token rather than coin one. This is noted for the orchestrator, not filed as a defect.
