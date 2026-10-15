Commit: 16ce27bf
# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-q110, branch fix/q110-not-run-undercount)
**Scope:** `git diff main...HEAD -- scripts test docs/thoughts` (scripts/run-tests.sh, test/skills/eval-helpers-gating.bats, docs/thoughts/failure-patterns.md) plus the five commit messages of `git log main..HEAD` (70aa3a78, f84a9dfa, 40f524df, 4b775841, 16ce27bf); docs/reviews/ prose checked only where it describes this branch's code
**Checked:** 2026-10-15 (UTC; local date 2026-10-14)
**Total claims checked:** 20
**Summary:** 15 verified, 4 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim matches a logged pattern.

Execution provenance (common to every `executed` claim): cwd for the reproductions is a throwaway layout under `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.IAbfP7Zb96/{old,new}` (copies of the worktree's `scripts/`, `test/`, `skills/`; `old/scripts/run-tests.sh` = `git show main:scripts/run-tests.sh`, `new/` = HEAD's); runs started 2026-10-15T04:40:14Z and ended by 04:41:31Z. The brief forbids writes to the repo other than this report, so captured output lives at `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.IAbfP7Zb96/logs/` rather than `docs/reviews/execution-logs/`. Every process ran under `timeout`; none remained afterwards (`ps` checked).

---

## Claim 1: "rg -n RUN_TESTS_NOT_RUN_FILE ... → header, gating comment, :359-368 only" and "the write is now at :359-360"

**Location:** `docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md:79` (Confirmed Good row 3), `:90` (Escalations)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the line numbers the rubric cites for the write and unset in `scripts/run-tests.sh`; does not establish anything about the substance (nothing after the unset needs the variable), which Claim 3 verifies at HEAD.

The rubric is stamped `Commit: f84a9dfa`, and at that commit the numbers were right (`git show f84a9dfa:scripts/run-tests.sh` puts the write at `359:if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then` and `368:unset RUN_TESTS_NOT_RUN_FILE`). Commit 4b775841 then added a header line, so at HEAD the block sits one line lower:

```bash
# scripts/run-tests.sh:360-361, :369
if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
...
unset RUN_TESTS_NOT_RUN_FILE
```

The rubric was committed in 16ce27bf, after 4b775841, so a reader at HEAD gets references that are off by one. Separately, Q-110 (`docs/working/questions.md:73`) cites `scripts/run-tests.sh:356-357`, but on `main` the write is at `357-358` (`git show main:scripts/run-tests.sh` → `357:if [[ -n ...`). That line is not part of this diff, and the rubric already escalates it.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md:79,90`, `scripts/run-tests.sh:360-361,369`, `git show f84a9dfa:scripts/run-tests.sh:359-368`

---

## Claim 2: "FP-173 ... cause:boundary-too-wide fix:remove-the-path ref:70aa3a78"

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that both tokens exist in the vocabulary tables with a fitting meaning and that `ref:` resolves to the fix commit; does not establish that the dated count tables are current (they say 13/7, and the log now holds 14/8, which f84a9dfa leaves alone on purpose).

The vocabulary table has `| 13 | \`boundary-too-wide\` | a security or isolation boundary admitted more than intended |` (`docs/thoughts/failure-patterns.md:64`) and `| 7 | \`remove-the-path\` | delete the capability rather than guarding it |` (`docs/thoughts/failure-patterns.md:99`). Both fit. The environment passed from the runner to its children is an isolation boundary that let the caller's path through, and the fix deletes the path (`unset`) instead of guarding it. Both tokens are already used, e.g. `FP-043 ... cause:boundary-too-wide fix:remove-the-path`. `git cat-file -t 70aa3a78` → `commit`, which is the fix commit.

**Evidence:** `docs/thoughts/failure-patterns.md:64,99,315`, `git log main..HEAD`

---

## Claim 3: "It is unset before bats runs, so the suites (and any runner a suite starts) do not inherit the caller's value."

**Location:** `scripts/run-tests.sh:19-23`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every path from the write to the bats invocations (`--failed`, the two early `exit 0`s, `bats --count`, the serial and `--jobs` `exec bats`) and the absence of any later reader; does not cover a value a suite sets itself, or one a caller deliberately injects through `PARALLEL_ENV` code (see Claim 15), neither of which is inheritance.

The unset comes immediately after the write (`scripts/run-tests.sh:360-369`). Everything later is below it: the `--failed` filter and its `exit 0` (`:383-398`), the `No runnable test files` `exit 0` (`:400-403`), `expected="$(bats --count "${files[@]}" 2>/dev/null)"` (`:442`) and `exec bats "${bats_args[@]}" "${files[@]}"` (`:453`). Every exit before `:360` is an error exit (`exit 1`/`exit 2`) and starts no bats. `rg -n RUN_TESTS_NOT_RUN_FILE` over the repo, excluding docs/reviews, finds the runner's only references at `:19`, `:321`, `:360-361` and `:369`, so nothing after the unset reads the variable.

Executed with a stub bats that appends its inherited value to a file and writes 99 to the inherited path (the new test's stub in a hand-built fixture). On HEAD's runner, `--fast` gave `new exit=0 nr=4 bats-env=unset unset`, i.e. both the `--count` call and the exec saw it unset. `--fast --jobs 2` gave `jobs exit=0 nr2=4 env=unset unset`. On main's runner, `old exit=0 nr=99` and both calls saw the caller's path.

Commands (cwd `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.IAbfP7Zb96`, 2026-10-15T04:41Z): `PATH=$L/bin:$PATH RUN_TESTS_NOT_RUN_FILE=$L/nr timeout 60 bash $L/scripts/run-tests.sh --fast` for `L=stub-old` and `L=stub-new`, plus the same with `--jobs 2` on `stub-new`. All exit 0.

**Evidence:** `scripts/run-tests.sh:19-23,360-369,383-403,442,453`; captured output `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.IAbfP7Zb96/logs/stub-old.log`, `.../logs/stub-new.log`, `.../logs/stub-new-jobs.log`

---

## Claim 4: "a suite that runs the runner again (eval-helpers-gating.bats does, with no override) would otherwise overwrite the caller's count with its fixture's"

**Location:** `scripts/run-tests.sh:363-366`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers eval-helpers-gating.bats's runner invocations that pass no value of their own and the resulting overwrite on main's runner; does not cover test/scripts/run-tests.bats's invocations (Claim 16 confirms only that it calls the runner).

Three tests start the runner with no override: `run bash "$T/scripts/run-tests.sh" --fast` (`test/skills/eval-helpers-gating.bats:90`, `:97`, `:105`). Three set their own value: `run env RUN_TESTS_NOT_RUN_FILE="$T/nr" ...` (`:50`, `:63`, `:82`). The no-override fixtures gate out 4 suites, so their write is 4. Running the real suite through main's runner with the caller's file set left `old nr=4` (Claim 11).

**Evidence:** `test/skills/eval-helpers-gating.bats:50,63,82,90,97,105`; captured output `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.IAbfP7Zb96/logs/repro-old.log`

---

## Claim 5: "(Q-110: the health check said 4 where this run listed 50)"

**Location:** `scripts/run-tests.sh:366` (and the same figure at `test/skills/eval-helpers-gating.bats:77`, commit 70aa3a78)
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the Q-110 record and with the reproduced mechanism (which yields 4); does not establish the 2026-10-02 run's output itself, which was not re-run and is not checked in.

Q-110 records it: "the test runner printed `NOT RUN: 50 report-dependent suite(s)`, but the health check's own summary said `4 report-dependent BATS suite(s) NOT RUN`" (`docs/working/questions.md:70`). The 4 matches the fixture count the nested runs write (Claim 4).

**Evidence:** `docs/working/questions.md:70-73`, `scripts/run-tests.sh:366`

---

## Claim 6: "Refusing an inherited value instead cannot work, since the health check itself passes it through the environment."

**Location:** `scripts/run-tests.sh:366-368`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers how health-check.sh passes the variable today; does not establish that no other interface (e.g. a flag) could carry it, which the comment does not claim.

Both invocations pass it as a prefix assignment, so the runner sees it as an inherited environment variable, indistinguishable from any other inherited value: `HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast --jobs "$jobs"` (`scripts/health-check.sh:431`) and the same with `"$nr_dir/slow"` and `--slow` (`scripts/health-check.sh:439`).

**Evidence:** `scripts/health-check.sh:425-445`

---

## Claim 7: Test name "the suites do not inherit RUN_TESTS_NOT_RUN_FILE, so a nested run cannot overwrite the caller's count" and comment "The stub bats stands in for any such suite: it writes to the inherited path when it has one, and records whether it had one."

**Location:** `test/skills/eval-helpers-gating.bats:74-85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stub standing in for the environment bats hands every suite (a suite inherits whatever bats was given), and the test failing on main's runner while passing on HEAD's; does not cover a suite that sets its own value, or a real nested runner (the stub writes directly rather than starting one).

The stub is `echo "${RUN_TESTS_NOT_RUN_FILE-unset}" > ".../bats-env"` followed by `[ -z "${RUN_TESTS_NOT_RUN_FILE:-}" ] || echo 99 > "$RUN_TESTS_NOT_RUN_FILE"` (`:80`). Assertions: `[ "$(cat "$T/nr")" = 4 ]` (`:84`) and `[ "$(cat "$T/bats-env")" = unset ]` (`:85`). The test is not vacuous. Run through main's runner (HEAD's test file) it fails: `not ok 3 ... # (in test file test/skills/eval-helpers-gating.bats, line 84) # \`[ "$(cat "$T/nr")" = 4 ]' failed`, exit 1. Through HEAD's runner, `ok 3 ...` and all 7 pass, exit 0.

Commands (cwd `.../tmp.IAbfP7Zb96/{old,new}`, 2026-10-15T04:40:14Z): `RUN_TESTS_NOT_RUN_FILE=$d/nr-$v timeout 300 bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats`, exit 1 (old) and 0 (new).

**Evidence:** `test/skills/eval-helpers-gating.bats:74-85`; captured output `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.IAbfP7Zb96/logs/repro-old.log`, `.../logs/repro-new.log`

---

## Claim 8: "test/skills/eval-helpers-gating.bats runs the runner again with no override, so its nested runs overwrote the caller's count with the fixture's 4; the health check printed 4 where the runner had listed 50."

**Location:** commit 70aa3a78 body, paragraph 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Same as Claims 4 and 5; does not establish the historical 50.

The same evidence as Claims 4 and 5. Main's runner left the caller's file at 4 (`repro-old.log`).

**Evidence:** `test/skills/eval-helpers-gating.bats:90,97,105`; `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.IAbfP7Zb96/logs/repro-old.log`

---

## Claim 9: "The runner now unsets the variable right after writing it, so neither bats nor anything a suite starts can see the caller's path."

**Location:** commit 70aa3a78 body, paragraph 2
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers inheritance through the environment (closed, per Claim 3); does not cover deliberate injection, which this absolute wording would also exclude.

The mechanism and the main conclusion hold (Claim 3). "Neither ... can see" is wider than what the code guarantees. Under `--jobs`, the runner unsets only `PARALLEL PARALLEL_CSH` (`scripts/run-tests.sh:430`), and GNU parallel evaluates `$PARALLEL_ENV` before each job. Executed: `PARALLEL_ENV='export X=injected' timeout 20 parallel ::: 'echo "X=$X"'` printed `X=injected` (exit 0, GNU parallel 20221122), so a caller can put its path back. A precise version: "the suites do not inherit the caller's path". Commit 4b775841 makes this correction in the header and the test name (Claim 15), but it does not name this sentence of 70aa3a78's body among the claims it corrects. Commit history is immutable, so this is informational only.

**Evidence:** `scripts/run-tests.sh:428-436`; captured output `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.IAbfP7Zb96/logs/parallel-env.log` (cwd `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.IAbfP7Zb96`, 2026-10-15T04:41Z)

---

## Claim 10: "A regression test ... uses a stub bats that writes to the inherited path when it has one: on the old runner the caller's file reads 99, now 4."

**Location:** commit 70aa3a78 body, paragraph 2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stub scenario on both runners; does not establish behavior with a real nested runner (Claim 11 covers that).

The stub fixture gave `old exit=0 nr=99` and `new exit=0 nr=4` (commands under Claim 3).

**Evidence:** `test/skills/eval-helpers-gating.bats:80-84`; `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.IAbfP7Zb96/logs/stub-old.log`, `.../logs/stub-new.log`

---

## Claim 11: "Reproduction: RUN_TESTS_NOT_RUN_FILE=$d/nr bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats; cat $d/nr -> 4 before (the parent gated none), 0 after."

**Location:** commit 70aa3a78 body, Reproduction
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reproduction as written, run from a copy of the tree (HEAD's test file in both layouts; test 6, which writes 4, is the last writer either way); does not establish it in the worktree itself (not run there, to avoid its `.bats/lock`).

Results: `old nr=4` and `new nr=0`. The parent run gates nothing: eval-helpers-gating.bats carries no `@needs-reports` tag (`test/skills/eval-helpers-gating.bats:1-5`).

**Evidence:** `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.IAbfP7Zb96/logs/repro-old.log`, `.../logs/repro-new.log` (commands, cwd, exit codes and timestamp under Claim 7)

---

## Claim 12: "(test/scripts/run-tests.bats and others call it too)"

**Location:** commit 70aa3a78 Notes
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers which suites start the runner directly; does not cover indirect calls through health-check.sh (stubbed or skipped in health-check.bats).

`rg -ln run-tests test` matches 15 test files and helpers (13 besides the two suites below). Apart from `test/scripts/run-tests.bats` (`bash "$T/scripts/run-tests.sh" "$@" 3>&-`, `:67`) and eval-helpers-gating.bats itself, every match is a comment or a stub name. test/scripts/health-check.bats exports `HEALTH_CHECK_SKIP_BATS=1` (`:19`) and otherwise uses `HEALTH_CHECK_RUN_TESTS="$stub"` (`:219`, `:492`). "And others" is wrong; it should say "test/scripts/run-tests.bats calls it too". Commit 4b775841 corrects this (Claim 16).

**Evidence:** `test/scripts/run-tests.bats:67,84,473,505`, `test/scripts/health-check.bats:19,219,284,492`

---

## Claim 13: "no suite reads the variable from its environment"

**Location:** commit 70aa3a78 Notes
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers suites reading the variable; does not cover non-suite readers (health-check.sh only sets it).

A stub runner in a suite reads it from its environment: `[ "$1" = --fast ] && echo 47 > "$RUN_TESTS_NOT_RUN_FILE"` (`test/scripts/health-check.bats:488`). The value comes from health-check.sh inside that test, not from the runner. A precise version: "no suite relies on inheriting the runner's value". Commit 4b775841 corrects this (Claim 16).

**Evidence:** `test/scripts/health-check.bats:483-498`, `scripts/health-check.sh:431`

---

## Claim 14: "health-check.sh's comments stay accurate"

**Location:** commit 70aa3a78 Notes
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the health-check.sh comments that mention the variable or the NOT RUN count (`:377`, `:425-428`, `:450-451`); does not cover other comments in that file.

"this gate only surfaces how many it left out, as a warning, via RUN_TESTS_NOT_RUN_FILE" (`scripts/health-check.sh:376-377`) and "The runner writes how many report-dependent suites it gated out ... to RUN_TESTS_NOT_RUN_FILE" (`:425-426`) both still hold, since the write happens before the unset.

**Evidence:** `scripts/health-check.sh:376-377,425-428,450-451`

---

## Claim 15: "a suite can still set its own value (eval-helpers-gating.bats does), and a caller can inject one through PARALLEL_ENV code under --jobs."

**Location:** commit 4b775841 body, paragraph 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both escape routes and the runner leaving PARALLEL_ENV untouched; does not establish that bats passes PARALLEL_ENV through to parallel end to end (only parallel's own evaluation of it was run).

The suite sets its own value at `test/skills/eval-helpers-gating.bats:50,63,82`. The runner unsets only `PARALLEL PARALLEL_CSH` (`scripts/run-tests.sh:430`). The parallel-level execution in Claim 9 printed `X=injected`.

**Evidence:** `scripts/run-tests.sh:430`, `test/skills/eval-helpers-gating.bats:50,63,82`; `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.IAbfP7Zb96/logs/parallel-env.log`

---

## Claim 16: "only test/scripts/run-tests.bats calls the runner besides eval-helpers-gating.bats itself ... no suite relies on inheriting the runner's value (test/scripts/health-check.bats:488's stub reads one health-check.sh sets)"

**Location:** commit 4b775841 body, paragraph 2
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers direct runner invocations in test/ and the one suite-side reader; does not cover callers outside test/ (health-check.sh, which is not a suite).

This is the evidence from Claims 12 and 13. The corrected statements match the code.

**Evidence:** `test/scripts/run-tests.bats:67`, `test/scripts/health-check.bats:19,488`, `scripts/health-check.sh:431`

---

## Claim 17: "Did not add PARALLEL_ENV to the runner's existing unset of PARALLEL settings"

**Location:** commit 4b775841 Notes
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the runner's unset line; does not judge the decision.

`unset PARALLEL PARALLEL_CSH` (`scripts/run-tests.sh:430`) is unchanged, and the diff does not touch it.

**Evidence:** `scripts/run-tests.sh:428-436`

---

## Claim 18: "Reused cause:boundary-too-wide and fix:remove-the-path rather than coining new tokens; the count tables above the log are a dated snapshot and were left as is."

**Location:** commit f84a9dfa Notes
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers token reuse and the untouched tables; does not establish that the tables were accurate before this branch.

Both tokens predate the branch (Claim 2). The diff to failure-patterns.md is the single added FP-173 line, and the tables still read 13 and 7, while `rg -c` now counts 14 (`cause:boundary-too-wide`) and 8 (`fix:remove-the-path`).

**Evidence:** `docs/thoughts/failure-patterns.md:64,99,315`

---

## Claim 19: "0 Incorrect/Stale; 2 Mostly accurate on commit 70aa3a78 wording; security, performance clean; api-consistency 1 Informational."

**Location:** commit 40f524df Notes
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the committed iteration-1 reports; does not re-verdict them.

The merged report says `**Summary:** 20 Verified, 2 Mostly accurate, 0 Incorrect, 0 Stale, 0 Unverifiable` (`docs/reviews/code-fact-check-report-q110.md:7`). The api-consistency review lists `| 1 | "never see it" reads as a ban ... | Informational |` (`docs/reviews/api-consistency-review-2026-10-14-q110.md:64`).

**Evidence:** `docs/reviews/code-fact-check-report-q110.md:1-9`, `docs/reviews/api-consistency-review-2026-10-14-q110.md:64`

---

## Claim 20: "0 red; 4 amber fixed in 4b775841 or withdrawn (refuted performance endorsement)"

**Location:** commit 16ce27bf Notes
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the rubric and that the three Fixed rows are reflected at HEAD; does not re-assess severities.

The rubric's red table is "None." Amber rows A1-A3 read "Fixed", and A4 (the performance endorsement) reads "Withdrawn" (`docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md:20-37`). At HEAD the header reads "do not inherit the caller's value" (`scripts/run-tests.sh:21-23`), and 4b775841's body carries the A1/A2 corrections (Claim 16).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md:20-37`, `scripts/run-tests.sh:19-23`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
- **Claim 1** (`docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md:79,90`): cites the write/unset as `:359-368` / `:359-360`, which was right at f84a9dfa, but at HEAD they are `:360-361` / `:369` because 4b775841 added a header line. Informational: it is a review artifact stamped f84a9dfa.

### Mostly Accurate
- **Claim 9** (commit 70aa3a78): "neither bats nor anything a suite starts can see the caller's path" should say "do not inherit". A caller's PARALLEL_ENV can put the path back under `--jobs`. 4b775841 fixes the header and test name but does not name this sentence of the body.
- **Claim 12** (commit 70aa3a78 Notes): "and others" should read "test/scripts/run-tests.bats calls it too". Corrected in 4b775841.
- **Claim 13** (commit 70aa3a78 Notes): should be "no suite relies on inheriting the runner's value". Corrected in 4b775841.

### Unverifiable
None. Claim 5's historical 50 is verified only against the Q-110 record.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved at the output path given in your tail, structured per your skill."
- **Answered:** Yes. All five brief items were checked: (1) every path from the write to `exec bats`, executed on serial and `--jobs 2`; (2) the comment block, including health-check.sh's prefix-assignment invocations; (3) all commit-message claims, with the 4/0 reproduction and the 99/4 stub executed on both runners; (4) the test fails on main's runner at `:84` and is not vacuous; (5) FP-173's tokens and ref. The code and the committed docs under review have no Incorrect or Stale claim. The only Stale item is a line-number drift in a docs/reviews artifact.
- **Out of scope:** the other iteration-1 docs/reviews prose that does not describe this branch's code; judging the PARALLEL_ENV decision (fact only); the full suite and health-check.sh (not run, per the brief).
- **Escalate:** (a) The shared brief says the branch is "6 commits ahead"; `git log main..HEAD` shows 5, and the brief itself lists five SHAs. (b) The rubric's line references (Claim 1) are one line off at HEAD; whether to restamp it is the orchestrator's call. (c) Q-110's `:356-357` citation is off by one even on main (the write is at `:357-358` there). It is already escalated in the rubric.
- **Questions/Decisions:** none.
