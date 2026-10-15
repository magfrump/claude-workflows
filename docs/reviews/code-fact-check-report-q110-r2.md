Commit: f84a9dfa

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q110 (claude-workflows, branch fix/q110-not-run-undercount)
**Scope:** branch diff `main...HEAD` (70aa3a78, f84a9dfa): scripts/run-tests.sh, test/skills/eval-helpers-gating.bats, docs/thoughts/failure-patterns.md, plus both commit messages; health-check.sh / health-check.bats / run-tests.bats read for cross-file claims
**Checked:** 2026-10-14
**Total claims checked:** 16
**Summary:** 15 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination log `docs/reviews/hallucination-patterns.md` read before checking; no claim below matches a logged pattern (no fabricated symbol, flag or API is named anywhere in the diff).

Execution provenance (shared by the executed claims). All logs are outside the repo, under `/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.esPR/` (the brief forbids writing anything but this report into the repo):
- **E-old:** cwd `fcr2.esPR/old` (temp layout: `git show main:scripts/run-tests.sh` + this branch's `test/lib/hermetic-env.bash`, `test/skills/runner-contract.bash`, `test/skills/eval-helpers-gating.bats`); command `RUN_TESTS_NOT_RUN_FILE=$d/nr-old timeout 300 bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats`; exit 1; 2026-10-15T04:15:17Z; output `fcr2.esPR/old.log` (test 3 `not ok` at line 84, `nr-old=4`).
- **E-new:** same layout with HEAD's `scripts/run-tests.sh`, cwd `fcr2.esPR/new`; same command writing `nr-new`; exit 0; 2026-10-15T04:15:31Z; output `fcr2.esPR/new.log` (7/7 ok, `nr-new=0`). (A first attempt in the worktree itself exited 1 with "another run-tests.sh run is in progress in this checkout" because a sibling reviewer held the lock; hence the temp layout.)
- **E-stub:** cwd `fcr2.esPR`; a loop building a minimal layout per runner version (one `@needs-reports alpha` suite, one untagged suite, the new test's exact stub bats) and running `PATH=$T/bin:$PATH RUN_TESTS_NOT_RUN_FILE=$T/nr timeout 60 bash $T/scripts/run-tests.sh --fast`; exit 0 for both; approx. 2026-10-15T04:16Z (not stamped); output `fcr2.esPR/stub99.log`: `old exit=0 nr=99 bats-env=<path>/nr`, `new exit=0 nr=1 bats-env=unset`.

---

## Claim 1: FP-173 `cause:boundary-too-wide` and `fix:remove-the-path` are existing vocabulary tokens that fit

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both tokens exist in the backfilled vocabulary tables and that their definitions can reasonably describe this bug; does not establish that the counts in those tables were updated (the commit says on purpose they were not, see Claim 16).
**Legibility-target:** for-orchestrator-synthesis

Both tokens are defined in the tables the schema says to reuse:

```
docs/thoughts/failure-patterns.md:64
| 13 | `boundary-too-wide` | a security or isolation boundary admitted more than intended |
docs/thoughts/failure-patterns.md:99
| 7 | `remove-the-path` | delete the capability rather than guarding it |
```

The bug is a process boundary (runner -> bats -> nested runner) letting through an environment value meant only for the runner's caller, and the fix deletes the inheritance (`unset`) rather than guarding it (refusing an inherited value). That fits the "isolation boundary" reading of `boundary-too-wide`. Every other use of the token is about security or sandbox boundaries (paraphrased — no quote available because the claim rests on reading the 13 `cause:boundary-too-wide` entries at `:185-290`), so this use stretches it a little, but within its stated definition.

**Evidence:** `docs/thoughts/failure-patterns.md:17-30`, `:62-64`, `:97-99`, `:315`

---

## Claim 2: FP-173 `ref:70aa3a78` names the fix commit; dated 2026-10-14

**Location:** `docs/thoughts/failure-patterns.md:315`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the ref resolves uniquely to the fix commit and that the date matches it; does not establish anything beyond the identity of the commit.
**Legibility-target:** for-orchestrator-synthesis

`git log -1 --format=%H 70aa3a78` resolves to `70aa3a7809844e3bd5dc20fadb52dd67b3eb6a5a`, the commit titled `fix(run-tests): stop the suites inheriting RUN_TESTS_NOT_RUN_FILE (Q-110)`, dated `Wed Oct 14 21:12:26 2026 -0700`, which matches the entry's `2026-10-14`. The entry uses an 8-character SHA where most others use 7 (paraphrased — no quote available because this is a comparison across all FP lines); the schema at `:30` does not fix a length.

**Evidence:** `docs/thoughts/failure-patterns.md:30`, `:315`; `git log main..HEAD`

---

## Claim 3: "It is unset before bats runs, so the suites (and any runner a suite starts) never see it."

**Location:** `scripts/run-tests.sh:19-22`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every path from the count write to bats, including the `bats --count` step, `--failed`, `--jobs`/GNU parallel and the early `exit 0` paths, for the caller's inherited value; does not establish that a suite cannot set the variable itself (tests 1-3 of eval-helpers-gating.bats and health-check.sh's `check_bats` set fresh values on purpose, which is not inheritance).
**Legibility-target:** for-orchestrator-synthesis

The write and the unset sit together, before any bats invocation:

```bash
# scripts/run-tests.sh:359-368
if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
fi
# The file is this run's answer to its caller, ...
unset RUN_TESTS_NOT_RUN_FILE
```

Both bats calls in the script come after that unset: `expected="$(bats --count "${files[@]}" 2>/dev/null)" || expected="?"` (`scripts/run-tests.sh:441`) and `exec bats "${bats_args[@]}" "${files[@]}"` (`scripts/run-tests.sh:452`, the script's last line). Every exit before `:359` comes before any bats call: `-h` at `:156-157`, usage errors at `:150`, `:163`, `:172`, missing files at `:196/:201/:207`, lock at `:235`, `--failed` checks at `:240`, `:251`, `:257`, `:268`, category at `:303`/`:307`, and bad tags at `:356`. The exits after it (`:395`, `:401`) also never reach bats. Under `--jobs` the only extra child is `parallel --plain --version` (`:430`), which also runs after the unset. Nothing after `:368` reads the variable (grep: its only uses in the script are `:19`, `:320`, `:359-360` and `:368`). The variable reaches the runner as an exported environment variable, so the `unset` removes it from every child's environment.

When run (E-stub), a stub bats that records its environment saw `bats-env=unset` under the new runner and the caller's path under the old one.

**Evidence:** `scripts/run-tests.sh:118-452` (whole script read), `/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.esPR/stub99.log`, `/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.esPR/new.log`

---

## Claim 4: "a suite that runs the runner again (eval-helpers-gating.bats does, with no override) would otherwise overwrite the caller's count with its fixture's"

**Location:** `scripts/run-tests.sh:363-365`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers eval-helpers-gating.bats's nested runs with no override, and the value they wrote under the old runner; does not establish which nested test wrote last in the original 2026-10-02 run (in this file both writers produce 4).
**Legibility-target:** for-orchestrator-synthesis

Three tests run the runner without setting the variable: `run bash "$T/scripts/run-tests.sh" --fast` at `test/skills/eval-helpers-gating.bats:90`, `:97` and `:105`. The `:97` one exits 1 at the bad-tag check (`scripts/run-tests.sh:354-357`) before the write. `:90` (stamps are not reports) and `:105` (late tag) both gate out the four tagged fixture suites, so each writes 4. When run against main's runner (E-old), the caller's file read `nr-old=4` after a run whose parent gated none.

**Evidence:** `test/skills/eval-helpers-gating.bats:9-45`, `:88-108`; `/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.esPR/old.log`

---

## Claim 5: "Q-110: the health check said 4 where this run listed 50" (also the test comment and commit body: "printed 4 where the runner had listed 50")

**Location:** `scripts/run-tests.sh:365`; `test/skills/eval-helpers-gating.bats:77-78`; commit 70aa3a78 body
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the Q-110 record; does not re-establish the historical 2026-10-02 run itself, which cannot be replayed (main at 188e0a7d, report state of that day).
**Legibility-target:** for-orchestrator-synthesis

The questions entry records the same numbers: "the test runner printed `NOT RUN: 50 report-dependent suite(s)`, but the health check's own summary said `4 report-dependent BATS suite(s) NOT RUN`" (`docs/working/questions.md:70`). The 4 matches the fixture count in Claim 4. Confidence is Medium only because the numbers rest on that record, not on a replay.

**Evidence:** `docs/working/questions.md:67-75`

---

## Claim 6: "Refusing an inherited value instead cannot work, since the health check itself passes it through the environment."

**Location:** `scripts/run-tests.sh:365-367`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how health-check.sh's gate 5 hands the variable over; does not establish whether some other channel (such as a flag) could replace it, which the comment does not claim.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/health-check.sh:431
    if ! HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast --jobs "$jobs"; then
# scripts/health-check.sh:439
    if HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/slow" "$runner" --slow --jobs "$jobs"; then
```

These are command-prefix assignments, so the value reaches the runner only through its environment. The runner cannot tell that value from one a parent suite left behind.

**Evidence:** `scripts/health-check.sh:398-449` (whole `check_bats`), `:451-457` (`_not_run_count`)

---

## Claim 7: "a suite that runs the runner again (as this file does below, with no override)"

**Location:** `test/skills/eval-helpers-gating.bats:75-76`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tests below line 86 in this file; does not establish anything about other files.
**Legibility-target:** for-orchestrator-synthesis

`test/skills/eval-helpers-gating.bats:90`, `:97` and `:105` each read `run bash "$T/scripts/run-tests.sh" --fast`, with no `RUN_TESTS_NOT_RUN_FILE` override. The tests above, at `:50`, `:63` and `:82`, use `env RUN_TESTS_NOT_RUN_FILE="$T/nr"`.

**Evidence:** `test/skills/eval-helpers-gating.bats:49-108`

---

## Claim 8: test name / "The stub bats stands in for any such suite: it writes to the inherited path when it has one, and records whether it had one."

**Location:** `test/skills/eval-helpers-gating.bats:74-85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the stub sees the environment any suite (and anything it starts) inherits from bats, that it writes when the path is inherited, and that the test fails on main's runner and passes on HEAD's; does not cover the `--jobs N` (GNU parallel) path, because the test runs with the default `--jobs 1` (the static trace in Claim 3 covers that path).
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers-gating.bats:80-85
  printf '#!/usr/bin/env bash\necho "${RUN_TESTS_NOT_RUN_FILE-unset}" > "%s/bats-env"\n[ -z "${RUN_TESTS_NOT_RUN_FILE:-}" ] || echo 99 > "$RUN_TESTS_NOT_RUN_FILE"\n' \
    "$T" > "$T/bin/bats"
  run env RUN_TESTS_NOT_RUN_FILE="$T/nr" bash "$T/scripts/run-tests.sh" --fast
  [ "$status" -eq 0 ]
  [ "$(cat "$T/nr")" = 4 ]
  [ "$(cat "$T/bats-env")" = unset ]
```

The stub replaces the bats that `setup()` made executable (`:27-28`). Redirecting into it with `>` keeps the mode. The stub runs where bats runs, so its environment is the one every suite would inherit. It is called twice per run, for `bats --count` and for the `exec`, and both calls see the same environment. The test is not vacuous. Under E-old it failed at ``# (in test file test/skills/eval-helpers-gating.bats, line 84) `[ "$(cat "$T/nr")" = 4 ]' failed``. Under E-new all 7 tests passed. `-` versus `:-`: the stub records `unset` only when the variable is truly absent, not merely empty, so the `bats-env` assertion checks for a real unset.

**Evidence:** `test/skills/eval-helpers-gating.bats:9-30`, `:74-86`; `/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.esPR/old.log`, `/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.esPR/new.log`

---

## Claim 9: "its nested runs overwrote the caller's count with the fixture's 4"

**Location:** commit 70aa3a78 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main's runner on eval-helpers-gating.bats; same residue as Claim 4.
**Legibility-target:** for-orchestrator-synthesis

E-old: the parent run of `test/skills/eval-helpers-gating.bats` (a suite with no `@needs-reports` tag, so the parent gates out 0) left `nr-old=4` in the caller's file. See Claim 4 for the two nested writers.

**Evidence:** `/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.esPR/old.log`, `test/skills/eval-helpers-gating.bats:88-108`

---

## Claim 10: "on the old runner the caller's file reads 99, now 4"

**Location:** commit 70aa3a78 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regression test's own fixture (four gated suites, giving 4) and a reduced reproduction (one gated suite, giving 1) with the identical stub; does not establish anything beyond that stub.
**Legibility-target:** for-orchestrator-synthesis

E-stub with the test's exact stub: `old exit=0 nr=99` against `new exit=0 nr=1` (one gated suite in the reduced layout). In the test's own four-suite fixture, the new runner's value is the asserted `4` (E-new: test 3 ok), and the old runner fails that assertion (E-old), consistent with 99.

**Evidence:** `/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.esPR/stub99.log`, `/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.esPR/old.log`, `/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.esPR/new.log`

---

## Claim 11: "Reproduction: RUN_TESTS_NOT_RUN_FILE=$d/nr bash scripts/run-tests.sh test/skills/eval-helpers-gating.bats; cat $d/nr -> 4 before (the parent gated none), 0 after."

**Location:** commit 70aa3a78 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reproduction run in a temp layout holding only the files the runner and this suite need; does not cover a run in the worktree itself (blocked by a sibling reviewer's lock at the time).
**Legibility-target:** for-orchestrator-synthesis

E-old gave `nr-old=4`. E-new gave `nr-new=0`. eval-helpers-gating.bats has no `# @needs-reports` line in its header (`test/skills/eval-helpers-gating.bats:1-5`), so the parent gates out none, as the commit says.

**Evidence:** `/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.esPR/old.log`, `/home/node/.claude/jobs/00bcf178/tmp/q110/fcr2.esPR/new.log`, `test/skills/eval-helpers-gating.bats:1-5`

---

## Claim 12: "(test/scripts/run-tests.bats and others call it too)"

**Location:** commit 70aa3a78 body (Notes)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which suites start the real runner; does not establish whether run-tests.bats's nested runs ever overwrote a real caller's file in a past health check.
**Legibility-target:** for-author

`test/scripts/run-tests.bats` does run the real runner, without an override: `bash "$T/scripts/run-tests.sh" "$@" 3>&-` (`test/scripts/run-tests.bats:67`), and again at `:84`, `:473` and `:505`. "and others", though, is plural. The only other suite that starts the real runner is eval-helpers-gating.bats itself, which the sentence is already contrasting against. The other suites that mention run-tests.sh only do so in comments (paraphrased — no quote available because the claim covers absence: `grep -n run-tests.sh` over test/ hits only comments in fixture-hermeticity.bats, hermeticity-lint.bats, cc-sni-proxy-unittest.bats, the skill suites and helpers). test/scripts/health-check.bats drives gate 5 only through a stub runner (`HEALTH_CHECK_RUN_TESTS="$stub"`, `test/scripts/health-check.bats:219`, `:493`). The precise version: "test/scripts/run-tests.bats calls it too".

**Evidence:** `test/scripts/run-tests.bats:19`, `:67`, `:84`, `:473`, `:505`; `test/scripts/health-check.bats:19`, `:183-221`, `:484-498`

---

## Claim 13: "no suite reads the variable from its environment"

**Location:** commit 70aa3a78 body (Notes)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reading the commit intends: no suite relies on the value it inherits from the outer runner. The literal reading does not hold: two stubs read the variable, but only values set explicitly just above them (the gate-5 stub at `test/scripts/health-check.bats:488` and the new test's stub bats), and the unset does not affect either.
**Legibility-target:** for-orchestrator-synthesis

Every `RUN_TESTS_NOT_RUN_FILE` hit in the tree is either the runner, health-check.sh setting it explicitly (`:431`, `:439`), or a test that sets it explicitly with `env RUN_TESTS_NOT_RUN_FILE="$T/nr"` (`test/skills/eval-helpers-gating.bats:50`, `:63`, `:82`) (paraphrased — no quote available because this is a whole-tree grep result). The gate-5 stub's `[ "$1" = --fast ] && echo 47 > "$RUN_TESTS_NOT_RUN_FILE"` (`test/scripts/health-check.bats:488`) reads the value `check_bats` sets at `scripts/health-check.sh:431`, not one inherited from the runner, so it is unaffected by the unset.

**Evidence:** `scripts/health-check.sh:431`, `:439`; `test/scripts/health-check.bats:484-498`; `test/skills/eval-helpers-gating.bats:50`, `:63`, `:80-82`

---

## Claim 14: "Header doc in run-tests.sh updated; health-check.sh's comments stay accurate."

**Location:** commit 70aa3a78 body (Notes)
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers health-check.sh's comments about RUN_TESTS_NOT_RUN_FILE and run-tests.sh's other mention of it (`:320`); does not establish that all of health-check.sh's comments are accurate.
**Legibility-target:** for-orchestrator-synthesis

health-check.sh says the gate "only surfaces how many it left out, as a warning, via RUN_TESTS_NOT_RUN_FILE" (`scripts/health-check.sh:376-377`) and "The runner writes how many report-dependent suites it gated out ... to RUN_TESTS_NOT_RUN_FILE" (`:424-426`). Both still hold: the write at `scripts/run-tests.sh:359-360` is unchanged. run-tests.sh's report-gating comment "the count is written to $RUN_TESTS_NOT_RUN_FILE when that is set (scripts/health-check.sh reads it to warn)" (`scripts/run-tests.sh:320-321`) also still holds. The header gained the unset sentence (`:20-22`).

**Evidence:** `scripts/health-check.sh:365-398`, `:424-457`; `scripts/run-tests.sh:19-22`, `:318-323`

---

## Claim 15: "Chose the runner-side fix over the per-suite setup() unset the entry also offered: it covers every present and future suite that nests the runner"

**Location:** commit 70aa3a78 body (Notes)
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the Q-110 entry offers both fixes and that the runner-side unset reaches every suite bats starts from this runner; does not establish coverage for a suite run directly by bare `bats` with the variable exported by hand (no runner involved, outside the claim).
**Legibility-target:** for-orchestrator-synthesis

The entry reads: "Fix: unset the variable in that suite's `setup()` ... or have the runner stop passing the variable to the bats processes it starts" (`docs/working/questions.md:73`). Coverage follows from Claim 3: every suite is a descendant of the `exec bats` at `scripts/run-tests.sh:452`, which runs after the unset.

**Evidence:** `docs/working/questions.md:73`, `scripts/run-tests.sh:359-368`, `:452`

---

## Claim 16: "Reused cause:boundary-too-wide and fix:remove-the-path rather than coining new tokens; the count tables above the log are a dated snapshot and were left as is."

**Location:** commit f84a9dfa body
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the tokens already existed and that the tables are presented as a dated snapshot and are unchanged in the diff; does not establish whether the snapshot should be refreshed.
**Legibility-target:** for-orchestrator-synthesis

The tables sit under `### Backfilled 2026-09-17 — the vocabulary this corpus actually uses` (`docs/thoughts/failure-patterns.md:47`), and the diff touches only line 315. Both tokens predate the branch (Claim 1). The counts `13` and `7` are unchanged.

**Evidence:** `docs/thoughts/failure-patterns.md:47-50`, `:64`, `:99`; `git diff main...HEAD -- docs/thoughts/failure-patterns.md`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 12** (commit 70aa3a78 Notes): "test/scripts/run-tests.bats and others call it too": only run-tests.bats (besides eval-helpers-gating.bats itself) starts the real runner; health-check.bats uses a stub. Should read "test/scripts/run-tests.bats calls it too". It is a commit message, so it cannot be changed without rewriting history, and it affects no reader acting on the code.

### Unverifiable
(none)

---

## Goal-Alignment Note

**Success criterion (verbatim):** "A markdown report saved at the output path given in your tail, structured per your skill."

**Answered:** Yes. All five claim groups the brief flagged were checked. (1) The header's unset invariant was traced over every path from the write to `exec bats`, and run (Claim 3). (2) The new comment block's three claims are all Verified (Claims 4-6). (3) The commit message claims: reproduction 4 to 0 and 99 to 4 executed and Verified; "and others" is Mostly accurate; "no suite reads" is Verified on the intended reading; "comments stay accurate" is Verified (Claims 9-15). (4) The new test fails on main's runner at line 84, passes on HEAD's, and is not vacuous (Claim 8). (5) The FP-173 tokens and ref are Verified (Claims 1, 2, 16).

**Out of scope:** Code quality and design (whether to also guard against a suite setting the variable deliberately); the `--jobs N` path was traced statically, not executed. The full suite and health-check.sh were not run, per the brief.

**Escalate:** Nothing. No Incorrect or Stale claims.

**Questions/Decisions:** None. The one Mostly-accurate item is in a commit message and needs no action unless the branch is reworded before merge.
