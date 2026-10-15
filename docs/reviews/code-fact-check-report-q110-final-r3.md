Commit: 16ce27bf

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q110 (claude-workflows, branch fix/q110-not-run-undercount)
**Scope:** `git diff main...HEAD -- scripts test docs/thoughts` (scripts/run-tests.sh, test/skills/eval-helpers-gating.bats, docs/thoughts/failure-patterns.md) plus the commit messages of `git log main..HEAD` (70aa3a78, f84a9dfa, 40f524df, 4b775841, 16ce27bf); docs/reviews/ artifacts read as context only
**Checked:** 2026-10-14
**Total claims checked:** 25
**Summary:** 23 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 30 lines) read first; no claim below matches a logged pattern.

Execution provenance (shared by every `executed` claim). All logs are under `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.dsSbjgswn5/` (outside the repo, per the brief). The worktree's own `.bats/lock` was held by a concurrent reviewer run (first attempt: `another run-tests.sh run is in progress in this checkout`, exit 1), so runs used `git archive` copies: `new/` = HEAD 16ce27bf, `old/` = main b279a2ba.
- E1 `bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats`, cwd `new/`, exit 0, 2026-10-15T04:40:42Z, log `new-suite.log` (7/7 ok).
- E2 `RUN_TESTS_NOT_RUN_FILE=$d/new-nr bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats`, cwd `new/`, exit 0, 2026-10-15T04:40:42Z, log `new-repro.log` (`nr=0`).
- E3 same as E2 with `$d/old-nr`, cwd `old/`, exit 0, 2026-10-15T04:40:29Z, log `old-repro.log` (`nr=4`).
- E4 HEAD's eval-helpers-gating.bats copied into `old/`, then `bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats`, cwd `old/`, exit 1, 2026-10-15T04:40:29Z, log `old-runner-new-test.log` (`not ok 3 ... line 84 ... [ "$(cat "$T/nr")" = 4 ]' failed`; the other 6 ok).
- E5 hand-built copy of test 3's fixture (stub bats from line 80, the four tagged suites plus one untagged) run with each runner under `RUN_TESTS_NOT_RUN_FILE=$T/nr ... --fast`, cwd a `mktemp -d` under `$d`, both exit 0, 2026-10-15T04:41:11Z, log `probe-99.log`: `old rc=0 nr=99 bats-env=<path>/nr` and `new rc=0 nr=4 bats-env=unset`.
- E6 `PARALLEL_ENV='export X=injected' parallel --plain 'echo X=$X' ::: a` with X unset, GNU parallel 20221122, exit 0, 2026-10-15T04:41:41Z, log `parallel-env.log` (`X=injected a`).

---

## Claim 1: "cause:boundary-too-wide" (FP-173)

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the token is in the cause vocabulary and that its definition fits the defect (an environment variable crossed the caller/nested-process boundary); does not establish that it is the only fitting category (`ordering` or `config-drift` would be weaker fits).

The token exists in the backfilled cause table: `| 13 | \`boundary-too-wide\` | a security or isolation boundary admitted more than intended |` (`docs/thoughts/failure-patterns.md:64`). The defect is that the runner's process boundary let the caller's output path through to bats and nested runners, which is "admitted more than intended". The vocabulary section asks for reuse: "reuse one rather than coining a new token" (`docs/thoughts/failure-patterns.md:52-53`).

**Evidence:** `docs/thoughts/failure-patterns.md:52-53`, `docs/thoughts/failure-patterns.md:64`, `docs/thoughts/failure-patterns.md:315`

---

## Claim 2: "fix:remove-the-path ref:70aa3a78" (FP-173)

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fix token's existence and fit, and that ref names the fix commit; does not establish the symptom token's wording beyond it being one hyphenated token per the schema.

`| 7 | \`remove-the-path\` | delete the capability rather than guarding it |` (`docs/thoughts/failure-patterns.md:99`). The fix deletes the inheritance (`unset RUN_TESTS_NOT_RUN_FILE`, `scripts/run-tests.sh:369`) rather than guarding it, and the code comment explicitly rejects the guard alternative ("Refusing an inherited value instead cannot work", `scripts/run-tests.sh:366-367`). `git show --stat 70aa3a78` heads `fix(run-tests): stop the suites inheriting RUN_TESTS_NOT_RUN_FILE (Q-110)`, the fix commit. The 8-character SHA differs from neighbours' 7 characters (e.g. `ref:a2972bf`, `:314`); the schema allows any SHA (`ref:<path-or-sha>`, `:31`).

**Evidence:** `docs/thoughts/failure-patterns.md:31`, `docs/thoughts/failure-patterns.md:99`, `docs/thoughts/failure-patterns.md:314-315`, `scripts/run-tests.sh:366-369`

---

## Claim 3: "It is unset before bats runs, so the suites (and any runner a suite starts) do not inherit the caller's value."

**Location:** `scripts/run-tests.sh:19-23`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every path from the write (`:360-361`) to both bats invocations (`bats --count`, `:442`; `exec bats`, `:453`), including `--failed`, the early `exit 0` paths, and `--jobs` (GNU parallel is a child of bats); does not establish that a suite cannot set its own value, or that a caller cannot inject one via PARALLEL_ENV code (Claims 20-21), and says nothing about the early-exit paths *before* the write (`:236`, `:304-308`, `:357`), where no count is written and no bats runs.

```bash
# scripts/run-tests.sh:360-369
if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
fi
# The file is this run's answer to its caller, ...
unset RUN_TESTS_NOT_RUN_FILE
```

Everything after `:369` was read to `:453`: the only bats invocations are `expected="$(bats --count "${files[@]}" 2>/dev/null)" || expected="?"` (`:442`) and `exec bats "${bats_args[@]}" "${files[@]}"` (`:453`), both after the unset; the `--failed` exit (`:394-397`) and the "No runnable test files" exit (`:400-402`) run no bats. `grep -n RUN_TESTS_NOT_RUN_FILE scripts/run-tests.sh` returns only `:19`, `:321`, `:360`, `:361`, `:369`, so nothing after the unset reads the variable. Executed: E5's stub bats recorded `bats-env=unset` under the new runner (the stub is called for both `--count` and the exec), and the old runner showed the path; E1 test 3 passes.

**Evidence:** `scripts/run-tests.sh:19-23`, `scripts/run-tests.sh:360-369`, `scripts/run-tests.sh:394-453`, `probe-99.log`, `new-suite.log`

---

## Claim 4: "a suite that runs the runner again (eval-helpers-gating.bats does, with no override) would otherwise overwrite the caller's count with its fixture's"

**Location:** `scripts/run-tests.sh:363-366`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that eval-helpers-gating.bats nests the runner without an override in three tests and that, on the old runner, this overwrote the caller's count with the fixture's 4; does not establish which other suites nest it (Claim 22).

Tests without an override: `run bash "$T/scripts/run-tests.sh" --fast` at `test/skills/eval-helpers-gating.bats:90`, `:97`, `:105`. E3 (old runner, caller's file set, suite run for real): `nr=4` although the parent gated none of its one file; E2 (new runner): `nr=0`.

**Evidence:** `test/skills/eval-helpers-gating.bats:88-108`, `old-repro.log`, `new-repro.log`

---

## Claim 5: "(Q-110: the health check said 4 where this run listed 50)"

**Location:** `scripts/run-tests.sh:366`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the numbers match the Q-110 record and that the 4 is the fixture's count (E3); does not establish the 50 by re-observation (a full health check, which the brief forbids running, on main at 188e0a7d).

Q-110 records: "the test runner printed `NOT RUN: 50 report-dependent suite(s)`, but the health check's own summary said `4 report-dependent BATS suite(s) NOT RUN`" (`docs/working/questions.md:70`). The 4 matches the fixture's four tagged suites (`test/skills/eval-helpers-gating.bats:19-23`) and E3's `nr=4`.

**Evidence:** `docs/working/questions.md:70`, `test/skills/eval-helpers-gating.bats:19-23`, `old-repro.log`

---

## Claim 6: "Refusing an inherited value instead cannot work, since the health check itself passes it through the environment."

**Location:** `scripts/run-tests.sh:366-368`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both of health-check.sh's invocations of the runner; does not establish whether some other inter-process channel (an argument flag) could have been used instead, which is design rationale.

```bash
# scripts/health-check.sh:431
    if ! HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast --jobs "$jobs"; then
# scripts/health-check.sh:439
    if HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/slow" "$runner" --slow --jobs "$jobs"; then
```

Both pass it as an environment prefix assignment, which the runner cannot tell apart from an inherited value (paraphrased — no quote available because this is a property of bash environment semantics, not a line of repo code).

**Evidence:** `scripts/health-check.sh:400-451`

---

## Claim 7: "the suites do not inherit RUN_TESTS_NOT_RUN_FILE, so a nested run cannot overwrite the caller's count" (test name)

**Location:** `test/skills/eval-helpers-gating.bats:74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the caller's value not reaching the bats process (and so its descendants) and the caller's file keeping the runner's count; does not establish behaviour when a suite sets its own value on purpose (as tests 1, 2 and 3 do).

The test asserts `[ "$(cat "$T/nr")" = 4 ]` and `[ "$(cat "$T/bats-env")" = unset ]` (`:84-85`). E1: `ok 3`. E4: the same test against the old runner fails at line 84, so the test is not vacuous; E5 shows the old value read 99.

**Evidence:** `test/skills/eval-helpers-gating.bats:74-86`, `new-suite.log`, `old-runner-new-test.log`, `probe-99.log`

---

## Claim 8: "a suite that runs the runner again (as this file does below, with no override) inherited the caller's file and overwrote its count: the health check printed 4 where the runner had listed 50"

**Location:** `test/skills/eval-helpers-gating.bats:75-77`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers "below" (tests at `:88`, `:95`, `:102` run with no override) and the overwrite (E3); the 50 carries Claim 5's residue.

`run bash "$T/scripts/run-tests.sh" --fast` at `:90`, `:97`, `:105`, all below `:74`. Of these, the stamp test (`:88-93`) and the late-tag test (`:102-108`) reach the write and write 4; the bad-tag test exits 1 at `scripts/run-tests.sh:355-357` before the write.

**Evidence:** `test/skills/eval-helpers-gating.bats:88-108`, `scripts/run-tests.sh:355-361`, `old-repro.log`

---

## Claim 9: "The stub bats stands in for any such suite: it writes to the inherited path when it has one, and records whether it had one."

**Location:** `test/skills/eval-helpers-gating.bats:77-79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stub's two behaviours and why sitting in bats' place stands in for any descendant (a variable absent from bats' environment is absent from everything it starts unless re-set); does not establish anything about a suite that sets its own value, or about PARALLEL_ENV-injected values.

```bash
# test/skills/eval-helpers-gating.bats:80 (printf body, unescaped)
echo "${RUN_TESTS_NOT_RUN_FILE-unset}" > "$T/bats-env"
[ -z "${RUN_TESTS_NOT_RUN_FILE:-}" ] || echo 99 > "$RUN_TESTS_NOT_RUN_FILE"
```

The stub keeps setup()'s exec bit (`chmod +x "$T/bin/bats"`, `:28`) and `$T/bin` is first on PATH (`:29`). E5 shows both behaviours: old runner `nr=99 bats-env=<path>`, new runner `nr=4 bats-env=unset`.

**Evidence:** `test/skills/eval-helpers-gating.bats:27-29`, `test/skills/eval-helpers-gating.bats:80-85`, `probe-99.log`

---

## Claim 10: "The runner wrote its NOT RUN count to $RUN_TESTS_NOT_RUN_FILE and then exec'd bats with the variable still exported."

**Location:** `git log` 70aa3a78 (body, paragraph 1)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main's runner; does not establish anything about runners older than main.

`git diff main...HEAD -- scripts/run-tests.sh` adds the `unset` and changes nothing else in the code; main has the write followed directly by the NOT RUN listing. E5 under main's runner: the stub bats saw `bats-env=<path>/nr`.

**Evidence:** `scripts/run-tests.sh:360-369`, `probe-99.log`

---

## Claim 11: "test/skills/eval-helpers-gating.bats runs the runner again with no override, so its nested runs overwrote the caller's count with the fixture's 4; the health check printed 4 where the runner had listed 50."

**Location:** `git log` 70aa3a78 (body, paragraph 1)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** As Claims 4 and 5 (the 50 is from the Q-110 record, not re-observed).

E3: `nr=4` under the old runner (paraphrased — no quote available because the evidence is the captured run log; the code side is quoted in Claims 4 and 8).

**Evidence:** `test/skills/eval-helpers-gating.bats:88-108`, `docs/working/questions.md:70`, `old-repro.log`

---

## Claim 12: "The runner now unsets the variable right after writing it, so neither bats nor anything a suite starts can see the caller's path."

**Location:** `git log` 70aa3a78 (body, paragraph 2)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers "right after" (`:369` follows `:360-362` with only comments between) and "the caller's path"; same residue as Claim 3.

`unset RUN_TESTS_NOT_RUN_FILE` at `scripts/run-tests.sh:369`, directly after the `fi` at `:362`. E5: `bats-env=unset`.

**Evidence:** `scripts/run-tests.sh:360-369`, `probe-99.log`

---

## Claim 13: "on the old runner the caller's file reads 99, now 4"

**Location:** `git log` 70aa3a78 (body, paragraph 2)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regression test's fixture under both runners; does not establish values under other fixtures.

E5: `old rc=0 nr=99 ...` / `new rc=0 nr=4 ...`. E4 confirms the bats test itself fails on the old runner at the `= 4` assertion (`test/skills/eval-helpers-gating.bats:84`).

**Evidence:** `test/skills/eval-helpers-gating.bats:80-85`, `probe-99.log`, `old-runner-new-test.log`

---

## Claim 14: "Reproduction: RUN_TESTS_NOT_RUN_FILE=$d/nr bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats; cat $d/nr -> 4 before (the parent gated none), 0 after."

**Location:** `git log` 70aa3a78 (body, paragraph 3)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reproduction in archive copies of main and HEAD; does not establish it in the live worktree, whose lock was held by another run at the time.

E3 `nr=4` (main), E2 `nr=0` (HEAD). "The parent gated none": the file's header carries no `# @needs-reports` tag (`test/skills/eval-helpers-gating.bats:1-5`), so the parent's `not_run` is empty, which E2's 0 confirms.

**Evidence:** `test/skills/eval-helpers-gating.bats:1-5`, `old-repro.log`, `new-repro.log`

---

## Claim 15: "it covers every present and future suite that nests the runner (test/scripts/run-tests.bats and others call it too)"

**Location:** `git log` 70aa3a78 (Notes)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers which suites invoke scripts/run-tests.sh; does not establish callers outside test/.

The coverage claim holds (the unset is in the runner, so it applies to every nesting suite). "and others" is imprecise: of the 16 files under test/ that mention `run-tests.sh`, only `test/scripts/run-tests.bats` (e.g. `bash "$T/scripts/run-tests.sh" "$@" 3>&-`, `:67`) and eval-helpers-gating.bats run it; the rest mention it in comments (e.g. `test/fixture-hermeticity.bats:7`, `test/skills/cowen-critique/dimensions.bats:5`), and `test/scripts/health-check.bats` reaches check_bats only through stubs (`HEALTH_CHECK_RUN_TESTS="$stub"`, `:219`, `:492`) with `export HEALTH_CHECK_SKIP_BATS=1` (`:19`). Precise version: "test/scripts/run-tests.bats calls it too". Already corrected in 4b775841's body (Claim 22); a commit message cannot be edited, so no action remains.

**Evidence:** `test/scripts/run-tests.bats:67`, `test/scripts/health-check.bats:19`, `test/scripts/health-check.bats:219`, `test/scripts/health-check.bats:492`, `test/fixture-hermeticity.bats:7`

---

## Claim 16: "no suite reads the variable from its environment"

**Location:** `git log` 70aa3a78 (Notes)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers every reference to RUN_TESTS_NOT_RUN_FILE in scripts/ and test/; does not establish anything about out-of-repo consumers.

`test/scripts/health-check.bats:488`'s stub does read it from its environment: `[ "$1" = --fast ] && echo 47 > "$RUN_TESTS_NOT_RUN_FILE"`; the value comes from health-check.sh (`scripts/health-check.sh:431`), not from the runner. The intended conclusion (no suite relies on inheriting the runner's value, so the unset breaks nothing) holds. Already corrected in 4b775841 (Claim 23).

**Evidence:** `test/scripts/health-check.bats:484-497`, `scripts/health-check.sh:431`

---

## Claim 17: "Header doc in run-tests.sh updated; health-check.sh's comments stay accurate."

**Location:** `git log` 70aa3a78 (Notes)
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers health-check.sh's comments that mention the variable (`:375-377`, `:424-427`, `:453-454`); does not establish other health-check.sh comments, which this branch does not touch.

"this gate only surfaces how many it left out, as a warning, via RUN_TESTS_NOT_RUN_FILE" (`scripts/health-check.sh:376-377`) and "The runner writes how many report-dependent suites it gated out ... to RUN_TESTS_NOT_RUN_FILE" (`:424-425`) still describe the runner, which writes before unsetting. The header gained the lines quoted in Claim 3.

**Evidence:** `scripts/health-check.sh:375-377`, `scripts/health-check.sh:424-427`, `scripts/health-check.sh:453-458`, `scripts/run-tests.sh:19-23`

---

## Claim 18: "Reused cause:boundary-too-wide and fix:remove-the-path rather than coining new tokens; the count tables above the log are a dated snapshot and were left as is."

**Location:** `git log` f84a9dfa (Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers token reuse and that the tables are dated and unchanged by this branch; does not establish whether the snapshot policy is documented elsewhere.

The tables sit under `### Backfilled 2026-09-17 — the vocabulary this corpus actually uses` (`docs/thoughts/failure-patterns.md:47`) and still read `| 13 | \`boundary-too-wide\` |` (`:64`) and `| 7 | \`remove-the-path\` |` (`:99`); the branch diff for this file is the one added FP-173 line.

**Evidence:** `docs/thoughts/failure-patterns.md:47`, `docs/thoughts/failure-patterns.md:64`, `docs/thoughts/failure-patterns.md:99`, `docs/thoughts/failure-patterns.md:315`

---

## Claim 19: "0 Incorrect/Stale; 2 Mostly accurate on commit 70aa3a78 wording" (40f524df) and "0 red; 4 amber fixed in 4b775841 or withdrawn" (16ce27bf)

**Location:** `git log` 40f524df, 16ce27bf (Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the committed artifacts' headline lines; does not re-audit those artifacts' findings.

`**Summary:** 20 Verified, 2 Mostly accurate, 0 Incorrect, 0 Stale, 0 Unverifiable` (`docs/reviews/code-fact-check-report-q110.md:8`); `0 red item(s); 4 amber items fixed or withdrawn` (`docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md:5`).

**Evidence:** `docs/reviews/code-fact-check-report-q110.md:8`, `docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md:5`

---

## Claim 20: "a suite can still set its own value (eval-helpers-gating.bats does)"

**Location:** `git log` 4b775841 (body, paragraph 1)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three set sites in this file; does not establish other suites.

`run env RUN_TESTS_NOT_RUN_FILE="$T/nr" bash "$T/scripts/run-tests.sh" --fast` at `test/skills/eval-helpers-gating.bats:50`, `:63`, `:82`.

**Evidence:** `test/skills/eval-helpers-gating.bats:50`, `test/skills/eval-helpers-gating.bats:63`, `test/skills/eval-helpers-gating.bats:82`

---

## Claim 21: "a caller can inject one through PARALLEL_ENV code under --jobs"

**Location:** `git log` 4b775841 (body, paragraph 1)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the runner leaves PARALLEL_ENV set and that GNU parallel runs PARALLEL_ENV code before each job; does not establish the injection end to end through `bats --jobs` (not run).

`unset PARALLEL PARALLEL_CSH` (`scripts/run-tests.sh:430`) does not touch PARALLEL_ENV, and bats is handed `--jobs "$jobs"` (`:432`). E6: with X unset, `PARALLEL_ENV='export X=injected' parallel --plain 'echo X=$X' ::: a` printed `X=injected a`.

**Evidence:** `scripts/run-tests.sh:428-436`, `parallel-env.log`

---

## Claim 22: "only test/scripts/run-tests.bats calls the runner besides eval-helpers-gating.bats itself (not \"and others\")"

**Location:** `git log` 4b775841 (body, paragraph 2)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers direct and indirect (via health-check.sh) invocation from test/; does not establish callers outside test/.

As traced in Claim 15: only `test/scripts/run-tests.bats` (`:67`, `:84`, `:473`, `:505`) and eval-helpers-gating.bats run it; health-check.bats replaces the runner with stubs (`:219`, `:492`).

**Evidence:** `test/scripts/run-tests.bats:67`, `test/scripts/run-tests.bats:84`, `test/scripts/health-check.bats:219`, `test/scripts/health-check.bats:492`

---

## Claim 23: "no suite relies on inheriting the runner's value (test/scripts/health-check.bats:488's stub reads one health-check.sh sets)"

**Location:** `git log` 4b775841 (body, paragraph 2)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every reader of the variable in scripts/ and test/ (grep: run-tests.sh, health-check.sh, health-check.bats:488, and eval-helpers-gating.bats's stub at :80, which records the value to assert it is absent); does not establish out-of-repo consumers.

`[ "$1" = --fast ] && echo 47 > "$RUN_TESTS_NOT_RUN_FILE"` (`test/scripts/health-check.bats:488`), run as `HEALTH_CHECK_RUN_TESTS="$stub"` under check_bats, which sets the variable at `scripts/health-check.sh:431`.

**Evidence:** `test/scripts/health-check.bats:484-497`, `scripts/health-check.sh:431`, `test/skills/eval-helpers-gating.bats:80`

---

## Claim 24: "Did not add PARALLEL_ENV to the runner's existing unset of PARALLEL settings"

**Location:** `git log` 4b775841 (Notes)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the unset line; does not establish whether leaving it is right (design rationale, out of scope).

`unset PARALLEL PARALLEL_CSH` (`scripts/run-tests.sh:430`), unchanged by the branch.

**Evidence:** `scripts/run-tests.sh:430`

---

## Claim 25: "The new test failed on the old runner at `[ \"$(cat \"$T/nr\")\" = 4 ]` and passes on the new one." (author's reproduction, brief item 4)

**Location:** `test/skills/eval-helpers-gating.bats:84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers non-vacuity of the count assertion; the `bats-env` assertion (`:85`) also distinguishes the runners (E5) but was not reached on the old runner because `:84` fails first.

E4: `not ok 3 ...` `(in test file test/skills/eval-helpers-gating.bats, line 84)` `` `[ "$(cat "$T/nr")" = 4 ]' failed ``; E1: `ok 3`.

**Evidence:** `test/skills/eval-helpers-gating.bats:84-85`, `old-runner-new-test.log`, `new-suite.log`, `probe-99.log`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 15** (`git log` 70aa3a78 Notes): "and others call it too": only test/scripts/run-tests.bats does. Already corrected in 4b775841; nothing left to fix.
- **Claim 16** (`git log` 70aa3a78 Notes): health-check.bats:488's stub reads the variable from its environment (set by health-check.sh); precise form is "no suite relies on inheriting the runner's value". Already corrected in 4b775841.

### Unverifiable
- None. (The "50" in Claims 5, 8 and 11 rests on the Q-110 record and was not re-observed; carried in their Scope residue.)

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved at the output path given in your tail, structured per your skill."
- **Answered:** Yes. All five brief items checked: (1) the unset precedes both bats invocations on every path, and nothing after it reads the variable; (2) the comment block's three assertions hold; (3) the commit claims hold, with 70aa3a78's two loose Notes claims (Mostly accurate) already corrected by 4b775841; (4) the stub stands in for any descendant, and the test fails on the old runner at line 84 (99 instead of 4), so it is not vacuous; (5) FP-173's tokens are in the vocabulary and the ref names the fix commit. 0 Incorrect, 0 Stale.
- **Out of scope:** Whether PARALLEL_ENV should also be unset (design choice; Claim 21 only confirms the stated mechanism); the pre-write early exits (`scripts/run-tests.sh:236`, `:304-308`, `:357`) leave the caller's file unwritten, which the health check reads as 0. This branch did not change that, and it is not a claim the diff makes.
- **Escalate:** Nothing.
- **Questions/Decisions:** The worktree's `.bats/lock` was held by a concurrent run during this pass, so the executed checks used `git archive` copies of HEAD and main. Results are equivalent for the scoped files.
