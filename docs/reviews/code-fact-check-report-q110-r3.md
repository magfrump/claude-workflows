Commit: f84a9dfa

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q110 (claude-workflows, branch `fix/q110-not-run-undercount`)
**Scope:** branch diff `main...HEAD` (2 commits: 70aa3a78, f84a9dfa): `scripts/run-tests.sh`, `test/skills/eval-helpers-gating.bats`, `docs/thoughts/failure-patterns.md`, plus both commit messages
**Checked:** 2026-10-14
**Total claims checked:** 21
**Summary:** 19 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read. None of the claims below matches a logged pattern.

## Execution log

Every execution ran under `timeout`. Raw output is in the scratch directory `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.wzY5dZOofC/` (outside the repo, because the brief allows no repo writes except this report). No process was left running.

| ID | Command (cwd) | UTC | Exit | Output |
|---|---|---|---|---|
| E1 | Two throwaway layouts, `old/` and `new/`. Each holds `test/lib/hermetic-env.bash`, `test/skills/runner-contract.bash` and the branch's `test/skills/eval-helpers-gating.bats`. `old/scripts/run-tests.sh` = `git show main:scripts/run-tests.sh`; `new/` = branch copy. Per layout: `echo SENTINEL > nr-$v; RUN_TESTS_NOT_RUN_FILE=$D/nr-$v timeout 300 bash $D/$v/scripts/run-tests.sh test/skills/eval-helpers-gating.bats` (cwd `$D`) | 04:15:43 (old), 04:15:48 (new) | old 1, new 0 | `run-old.log`, `run-new.log`, `nr-old` (= `4`), `nr-new` (= `0`) |
| E2 | Hand replica of new test 3 (same fixture suites, same stub bats `printf` line) against each runner: `PATH=$T/bin:$PATH timeout 60 env RUN_TESTS_NOT_RUN_FILE=$T/nr bash $T/scripts/run-tests.sh --fast` (cwd `$D`) | 04:16:01 | old 0, new 0 | `t3-old.log`, `t3-new.log`, `t3-old/nr` (= `99`), `t3-old/bats-env` (= the path), `t3-new/nr` (= `4`), `t3-new/bats-env` (= `unset`) |
| E3 | `timeout 300 bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats` (cwd worktree) | 04:16:08 | 1 | `wt-run.log`: `another run-tests.sh run is in progress in this checkout`. Another reviewer held the worktree lock, so E1's `new/` layout stands in for this run. |

E1's old layout fails `not ok 3 … (in test file old/test/skills/eval-helpers-gating.bats, line 84) [ "$(cat "$T/nr")" = 4 ]' failed`. Tests 1, 2 and 4-7 pass. The new layout passes all 7.

---

## Claim 1: "symptom:output-file-env-var-inherited-by-nested-runner-overwrites-caller-count"

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that a nested runner, inheriting the output-file variable, overwrote the caller's count on the pre-fix runner. Does not establish that this was the only writer of the health check's file in the original 4-vs-50 run.
**Legibility-target:** for-orchestrator-synthesis

E1: on the old runner, a caller file seeded with `SENTINEL` read `4` after the run. The parent gates none of its one selected file, so its own write was `0`, and only the nested runs inside the suite write `4`. The nested calls inherit the variable because they pass no override: `run bash "$T/scripts/run-tests.sh" --fast` (`test/skills/eval-helpers-gating.bats:90`, also `:97` and `:105`).

**Evidence:** `docs/thoughts/failure-patterns.md:315`, `test/skills/eval-helpers-gating.bats:90,97,105`, E1 `nr-old`

---

## Claim 2: "cause:boundary-too-wide"

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the token is in the cause vocabulary and that its definition fits an environment variable crossing the runner-to-suite process boundary. Does not establish that it is the only fitting token (`stale-state` or `artifact-lifecycle`, "overwritten … by its own lifecycle", are arguable neighbours).
**Legibility-target:** for-orchestrator-synthesis

The vocabulary row: `| 13 | \`boundary-too-wide\` | a security or isolation boundary admitted more than intended |` (`docs/thoughts/failure-patterns.md:64`). The file says to reuse a category rather than coin one: "The categories below are **the** categories — reuse one rather than coining a new token" (`:52`). The bug is the runner's environment being admitted across the process boundary into the suites, which matches "isolation boundary admitted more than intended".

**Evidence:** `docs/thoughts/failure-patterns.md:52,64,315`

---

## Claim 3: "fix:remove-the-path"

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the token is in the fix vocabulary and matches the `unset`. Does not judge whether a different fix category would be more informative.
**Legibility-target:** for-orchestrator-synthesis

The vocabulary row: `| 7 | \`remove-the-path\` | delete the capability rather than guarding it |` (`docs/thoughts/failure-patterns.md:99`). The fix is `unset RUN_TESTS_NOT_RUN_FILE` (`scripts/run-tests.sh:368`). That removes the variable from everything bats starts. It does not add a guard on the write.

**Evidence:** `docs/thoughts/failure-patterns.md:99`, `scripts/run-tests.sh:368`

---

## Claim 4: "ref:70aa3a78" names the fix commit

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the ref resolves to the branch's fix commit. Does not establish whether the 8-character form matters to any tool that reads refs.
**Legibility-target:** for-orchestrator-synthesis

`git cat-file -t 70aa3a78` → `commit`. `git log main..HEAD` lists it as `70aa3a7809844e3bd5dc20fadb52dd67b3eb6a5a … fix(run-tests): stop the suites inheriting RUN_TESTS_NOT_RUN_FILE (Q-110)`. The format line allows a commit SHA: `ref:<diagnosis-doc-or-commit>` (`docs/thoughts/failure-patterns.md:19`). Side note, not a defect: every other `ref:` SHA in the log has 7 characters (e.g. `ref:a2972bf`, `:314`). This is the only 8-character one (`rg -c 'ref:[0-9a-f]{8}\b'` → 1).

**Evidence:** `docs/thoughts/failure-patterns.md:19,314,315`

---

## Claim 5: "It is unset before bats runs, so the suites (and any runner a suite starts) never see it."

**Location:** `scripts/run-tests.sh:20-22`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every bats invocation in the runner (`bats --count` at `:441` and `exec bats` at `:452`, on the serial, `--jobs`/GNU-parallel and `--failed` paths) and that nothing after the unset reads the variable. "Never see it" means the caller's inherited value. A suite that sets its own value explicitly (tests 1-3 of eval-helpers-gating.bats) still sees that value, as intended. Does not cover callers that run bats directly without the runner.
**Legibility-target:** for-orchestrator-synthesis

The write and the unset sit next to each other:

```bash
# scripts/run-tests.sh:359-368
if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
fi
# The file is this run's answer to its caller, ...
unset RUN_TESTS_NOT_RUN_FILE
```

(Excerpt ends :368. The top-level script continues to `exec bats "${bats_args[@]}" "${files[@]}"` at :452, read.) The only bats calls in the script are `expected="$(bats --count "${files[@]}" 2>/dev/null)"` (`:441`) and `exec bats` (`:452`). Both come after `:368`. GNU parallel is started by bats itself, so it inherits the already-unset environment. The `--failed` filtering (`:382-397`) and the early `exit 0` paths (`:395`, `:401`) come after the unset and run no bats. No line after `:368` names the variable: `grep -n RUN_TESTS_NOT_RUN_FILE scripts/run-tests.sh` → `19, 320, 359, 360, 368`. The script sources `test/lib/hermetic-env.bash` and `test/skills/runner-contract.bash` before the write (`:177`, `:325`), but neither is a suite, and neither reads the variable. E2 confirmed this at runtime: the stub bats recorded `unset` on the new runner and the caller's path on the old one.

**Evidence:** `scripts/run-tests.sh:177,325,359-368,382-402,441,452`, E2 `t3-new/bats-env`, `t3-old/bats-env`

---

## Claim 6: "a suite that runs the runner again (eval-helpers-gating.bats does, with no override)"

**Location:** `scripts/run-tests.sh:363-364`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of override-free nested runner calls in that suite. Does not claim every call in the suite lacks the override (tests at :50, :63 and :82 set one).
**Legibility-target:** for-orchestrator-synthesis

`test/skills/eval-helpers-gating.bats:90`, `:97` and `:105` each run `run bash "$T/scripts/run-tests.sh" --fast` with no `RUN_TESTS_NOT_RUN_FILE`. The `:97` run exits 1 at the bad-tag check (`scripts/run-tests.sh:354-357`, `exit 1`) before the write, so `:90` and `:105` are the calls that overwrite.

**Evidence:** `test/skills/eval-helpers-gating.bats:50,63,82,90,97,105`, `scripts/run-tests.sh:354-357`

---

## Claim 7: "would otherwise overwrite the caller's count with its fixture's"

**Location:** `scripts/run-tests.sh:364-365`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old runner's behavior with this suite. Does not establish behavior for suites added later.
**Legibility-target:** for-orchestrator-synthesis

E1, old runner: the caller's file read `4`, the fixture's gated count (four tagged suites, `test/skills/eval-helpers-gating.bats:19-23`), where the parent itself gated `0`.

**Evidence:** `test/skills/eval-helpers-gating.bats:19-23`, E1 `nr-old`

---

## Claim 8: "(Q-110: the health check said 4 where this run listed 50)"

**Location:** `scripts/run-tests.sh:365`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the numbers match the documented incident and today's tree (50 tagged suites, all fast; the nested write is 4). Does not re-run the health check, which the brief forbids. The historical `health.txt` output is cited from earlier review reports, not re-observed.
**Legibility-target:** for-orchestrator-synthesis

`rg -l '^# @needs-reports' test | wc -l` → `50`. All 50 carry `# @category fast`, so the fast run lists 50 and the slow run lists none. The health check sums the two files: `warn "$((fast_nr + slow_nr)) report-dependent BATS suite(s) NOT RUN …"` (`scripts/health-check.sh:449-450`). A nested write of 4 into the fast file therefore prints 4. The incident is recorded with the same numbers in `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md:303`: "⚠ 4 report-dependent BATS suite(s) NOT RUN" against "=== NOT RUN: 50 report-dependent suite(s)".

**Evidence:** `scripts/health-check.sh:431-450`, `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md:303`

---

## Claim 9: "Refusing an inherited value instead cannot work, since the health check itself passes it through the environment."

**Location:** `scripts/run-tests.sh:365-367`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the health check's invocation form. Does not consider a marker-variable scheme, which the comment does not address.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/health-check.sh:431
    if ! HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast --jobs "$jobs"; then
```

`:439` uses the same form for `--slow`. An environment prefix is how the runner receives the variable from its legitimate caller. The runner cannot tell that apart from an inherited copy.

**Evidence:** `scripts/health-check.sh:431,439`

---

## Claim 10: test name "the suites never see RUN_TESTS_NOT_RUN_FILE, so a nested run cannot overwrite the caller's count"

**Location:** `test/skills/eval-helpers-gating.bats:74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's assertions (caller's file holds the parent's 4, stub saw `unset`) passing on the new runner. Does not cover nested runs started outside bats.
**Legibility-target:** for-orchestrator-synthesis

The assertions are `[ "$(cat "$T/nr")" = 4 ]` and `[ "$(cat "$T/bats-env")" = unset ]` (`test/skills/eval-helpers-gating.bats:84-85`). E1 new layout: `ok 3`. E2 new: `nr=4`, `bats-env=unset`.

**Evidence:** `test/skills/eval-helpers-gating.bats:74-86`, E1 `run-new.log`, E2

---

## Claim 11: "a suite that runs the runner again (as this file does below, with no override)"

**Location:** `test/skills/eval-helpers-gating.bats:75-76`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that override-free calls exist below line 76. Does not claim all three of them write (`:97` exits before the write).
**Legibility-target:** for-orchestrator-synthesis

Below the comment: `run bash "$T/scripts/run-tests.sh" --fast` at `test/skills/eval-helpers-gating.bats:90`, `:97` and `:105`.

**Evidence:** `test/skills/eval-helpers-gating.bats:90,97,105`

---

## Claim 12: "the health check printed 4 where the runner had listed 50"

**Location:** `test/skills/eval-helpers-gating.bats:77`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Same as Claim 8: the incident numbers checked against recorded reports and today's tree, not a re-run health check.
**Legibility-target:** for-orchestrator-synthesis

Same evidence as Claim 8: 50 tagged fast suites (`rg -l '^# @needs-reports' test | wc -l` → `50`), and the recorded incident in `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md:303`.

**Evidence:** `scripts/health-check.sh:449-450`, `docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02.md:303`

---

## Claim 13: "The stub bats stands in for any such suite: it writes to the inherited path when it has one, and records whether it had one."

**Location:** `test/skills/eval-helpers-gating.bats:77-79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the stub writes 99 to an inherited path and records the value or `unset`, and that any suite or nested runner gets its environment from the bats process the stub replaces. Does not exercise the `--jobs` path, where GNU parallel sits between bats and the suites (it inherits from bats, so the same environment reaches them).
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers-gating.bats:80 (the stub, as printf'd)
echo "${RUN_TESTS_NOT_RUN_FILE-unset}" > "$T/bats-env"
[ -z "${RUN_TESTS_NOT_RUN_FILE:-}" ] || echo 99 > "$RUN_TESTS_NOT_RUN_FILE"
```

Every suite runs as a child of bats, so what the stub sees is what any suite would inherit. E2 old: `bats-env` held the caller's path and `nr=99`. E2 new: `unset` and `4`.

**Evidence:** `test/skills/eval-helpers-gating.bats:80-81`, E2

---

## Claim 14: The new test fails on the old runner (not vacuous)

**Location:** `test/skills/eval-helpers-gating.bats:84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old runner from `main` (b279a2ba) with the branch's test file. Does not cover other regressions, such as a future runner that writes the count after bats.
**Legibility-target:** for-orchestrator-synthesis

E1 old layout: `not ok 3 … line 84) [ "$(cat "$T/nr")" = 4 ]' failed`. The `bats-env` assertion at `:85` would also catch the regression on its own, even if the stub stopped writing 99.

**Evidence:** `test/skills/eval-helpers-gating.bats:84-85`, E1 `run-old.log`

---

## Claim 15: "test/skills/eval-helpers-gating.bats runs the runner again with no override, so its nested runs overwrote the caller's count with the fixture's 4; the health check printed 4 where the runner had listed 50."

**Location:** commit 70aa3a78 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the overwrite mechanism and the value 4 (E1). The 50/4 incident numbers rest on the evidence for Claim 8.
**Legibility-target:** for-orchestrator-synthesis

E1 old: the caller's file read `4`. The override-free calls are at `test/skills/eval-helpers-gating.bats:90,105`. The incident numbers are as in Claim 8.

**Evidence:** `test/skills/eval-helpers-gating.bats:90,105`, E1 `nr-old`

---

## Claim 16: "The runner now unsets the variable right after writing it, so neither bats nor anything a suite starts can see the caller's path."

**Location:** commit 70aa3a78 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 5.
**Legibility-target:** for-orchestrator-synthesis

`unset RUN_TESTS_NOT_RUN_FILE` (`scripts/run-tests.sh:368`) follows the write at `:359-361`, with only comments in between. E2 new: the stub recorded `unset`.

**Evidence:** `scripts/run-tests.sh:359-368`, E2

---

## Claim 17: "on the old runner the caller's file reads 99, now 4"

**Location:** commit 70aa3a78 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new test's scenario run against both runners. Does not cover other fixtures.
**Legibility-target:** for-orchestrator-synthesis

E2: old `nr=99`, new `nr=4`.

**Evidence:** E2 `t3-old/nr`, `t3-new/nr`

---

## Claim 18: "Reproduction: RUN_TESTS_NOT_RUN_FILE=$d/nr bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats; cat $d/nr -> 4 before (the parent gated none), 0 after."

**Location:** commit 70aa3a78 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reproduction in throwaway layouts that mirror the repo paths the runner and the suite use. It was not run in the worktree itself (E3 was blocked by another reviewer's lock). The "before" run used the branch's test file, so its exit status was 1 (test 3 fails), but the count value does not depend on that.
**Legibility-target:** for-orchestrator-synthesis

E1: old `nr=4`, new `nr=0`. The suite carries no `@needs-reports` tag, so the parent gates none.

**Evidence:** E1 `nr-old`, `nr-new`, `run-old.log`, `run-new.log`

---

## Claim 19: "(test/scripts/run-tests.bats and others call it too)"

**Location:** commit 70aa3a78 message
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which suites run `scripts/run-tests.sh`. Does not cover scripts that wrap the runner outside bats (e.g. `scripts/confine-tests.sh`).
**Legibility-target:** for-author

`test/scripts/run-tests.bats` does run it, with no `RUN_TESTS_NOT_RUN_FILE` override: `bash "$T/scripts/run-tests.sh" "$@" 3>&-` (`test/scripts/run-tests.bats:67`, also `:84`). No other suite does (paraphrased — no quote available because the claim concerns an absence: `rg -n 'run-tests\.sh' test -g '*.bats' -g '*.bash'`, with comment lines and these two suites excluded, leaves only the test name at `test/scripts/health-check.bats:252`, which runs a stub). The precise version is "test/scripts/run-tests.bats calls it too". There is no third caller.

**Evidence:** `test/scripts/run-tests.bats:67,84`, `test/scripts/health-check.bats:252`

---

## Claim 20: "no suite reads the variable from its environment"

**Location:** commit 70aa3a78 message
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `RUN_TESTS_NOT_RUN_FILE` reference under `test/`. The conclusion (no suite depends on inheriting the runner's value, so the unset breaks nothing) holds. The literal wording does not.
**Legibility-target:** for-author

One suite's stub reads the variable from its environment: `[ "$1" = --fast ] && echo 47 > "$RUN_TESTS_NOT_RUN_FILE"` (`test/scripts/health-check.bats:488`). Its value comes from `check_bats` inside the test (`scripts/health-check.sh:431`), not from the outer runner, so the unset does not affect it. The new test's own stub (`test/skills/eval-helpers-gating.bats:80`) also reads it, by design. The precise version is "no suite relies on inheriting the runner's value".

**Evidence:** `test/scripts/health-check.bats:484-497`, `scripts/health-check.sh:431`, `test/skills/eval-helpers-gating.bats:80`

---

## Claim 21: "health-check.sh's comments stay accurate" / "the count tables above the log are a dated snapshot"

**Location:** commit 70aa3a78 message; commit f84a9dfa message
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two health-check comments that mention the variable, and the failure-patterns table header. Does not review other health-check comments.
**Legibility-target:** for-orchestrator-synthesis

Both health-check comments that mention the variable are still true. The first says the gate "only surfaces how many it left out, as a warning, via RUN_TESTS_NOT_RUN_FILE." (`scripts/health-check.sh:376-377`). The second says "The runner writes how many report-dependent suites it gated out … to RUN_TESTS_NOT_RUN_FILE." (`:424-425`). The runner still writes before unsetting. The failure-patterns tables are dated: "### Backfilled 2026-09-17 — the vocabulary this corpus actually uses" / "164 entries harvested" (`docs/thoughts/failure-patterns.md:47-49`), and the log now holds 166 `- **FP-` lines.

**Evidence:** `scripts/health-check.sh:376-377,424-425`, `docs/thoughts/failure-patterns.md:47-49`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 19** (commit 70aa3a78 message): "test/scripts/run-tests.bats and others call it too". Only run-tests.bats (and eval-helpers-gating.bats itself) run the runner, so drop "and others".
- **Claim 20** (commit 70aa3a78 message): "no suite reads the variable from its environment". `test/scripts/health-check.bats:488`'s stub does read it, though the value is set by health-check.sh inside the test. Say "no suite relies on inheriting it".

### Unverifiable
(none)

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved at the output path given in your tail, structured per your skill."
- **Answered:** All five brief focus areas. (1) The header unset claim holds on every path to `bats --count` and `exec bats`, and nothing after the unset needs the variable (Claim 5). (2) The comment block's three claims are verified (Claims 6-9). (3) The commit-message claims: the reproduction (4 → 0) and 99 → 4 were executed and verified. "and others" and "no suite reads …" are wording-loose but harmless (Claims 19-20). "health-check.sh's comments stay accurate" is verified. (4) The new test fails on the old runner at line 84 and is not vacuous. Its stub legitimately stands in for any child of bats (Claims 13-14). (5) FP-173's tokens are both in the vocabulary and fit. `ref:70aa3a78` resolves to the fix commit (Claims 2-4).
- **Out of scope:** Code quality and whether runner-side vs suite-side is the better fix (sibling critics). The pre-existing behavior that early `exit 1` paths before `:359` leave the caller's file unwritten (the health check reads that as 0 via `_not_run_count`) is not part of this diff.
- **Escalate:** None blocking. Both Mostly-accurate items are commit-message wording and need no code change.
- **Questions/Decisions:** E3 (the in-worktree run) was blocked by a concurrent run-tests.sh lock held by another reviewer. The equivalent throwaway-layout run (E1) stands in for it.
