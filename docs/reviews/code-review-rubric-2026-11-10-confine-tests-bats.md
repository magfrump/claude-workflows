Commit: 7d77df6c
Loop closed at 7d77df6c

# Code Review Rubric

**Scope:** test/confine-tests-bats, `a37733cc..7d77df6c` (full branch at pass 2, the last fix commit at pass 3) | **Reviewed:** 2026-11-10 | **Status: 🟢 PASSES** — 0 red; every amber fixed, except the two against the unchanged script (A7, A8), which are deferred with a follow-up and a revisit trigger. The loop ended at its cap of three iterations; pass 3's own fixes (aa8a818c) were checked by re-running and by the drift check, not by a fourth review pass

The file's name ends in the brief's stem, not the branch slug, so the build loop's gate counts it as this brief's own file; passes therefore name their range explicitly. Delivery mode: self-read (each agent ran its own `git diff` and read the files). All agents ran on opus. Reports are in this directory, named `<kind>-2026-11-10-confine-tests-bats.md`.

**Pass 1** (iteration 1 of 3, `--loop-pass`, at 9d37c1ac): k=1 fact-check (`code-fact-check-report`): 50 claims; 43 Verified, 6 Mostly accurate, 1 Unverifiable, 0 Incorrect. Critics: security (`security-review`): 2 Medium against the unchanged script, 1 Low against this diff, 2 Informational; performance (`performance-review`): 1 Low, 1 Informational. Fixed in f36108e4; the fix-commit drift check over it reported no findings.

**Pass 2** (iteration 2 of 3, the final confirming pass, full branch at 27b5e861, no `--loop-pass`): k=3 fact-check (`code-fact-check-report-final-r1`, `-r2`, `-r3`):

| Replicate | Claims | Verified | Mostly accurate | Stale | Incorrect | Unverifiable |
|---|---|---|---|---|---|---|
| r1 | 55 | 46 | 5 | 0 | 0 | 4 |
| r2 | 42 | 34 | 3 | 1 | 2 | 2 |
| r3 | 52 | 41 | 4 | 1 | 1 | 5 |

No replicate found anything wrong in the test code, and all three found every test name true to its body. Every Incorrect and Stale is in the research doc's prose, so by the tier rule for a fact-check red (the code is right and only a reader is misinformed) they are 🟡, not 🔴. The replicates were merged by most-severe-wins straight into the rows below, with no merged report file. Verdict stability: A10 was Incorrect in r2 and r3 and Mostly accurate in r1; A11 was Incorrect in r2 alone, and the final security critic found it independently. Critics: security (`security-review-final`): 1 Low against this diff, 1 Medium repeat against the unchanged script, 2 Informational; performance (`performance-review-final`): nothing to fix, 1 Informational.

Fixed in 7d77df6c. The drift check declined that commit (its diff, with the five review reports in it, is 239 KB against the checker's 192 KB limit, and it says to use the full review path), so pass 3 is that fuller path.

**Pass 3** (iteration 3 of 3, `--loop-pass`, scoped to `27b5e861..7d77df6c` in the test file and the research doc): k=1 fact-check (`code-fact-check-report-i3`): 37 claims; 31 Verified, 2 Mostly accurate, 2 Incorrect, 2 Unverifiable. Again nothing wrong in the test code; the two Incorrect are one prose error, stated in the research doc and repeated in the message of 7d77df6c (row A14). No critics ran on this pass: it is a loop pass over a prose-and-comment fix whose only code change loosened two assertions, and the full panel had run one commit earlier. Fixed in aa8a818c. The drift check over aa8a818c alone returned one Low "unverified claim" (that `docs/roadmap.md` holds the `--probe` wording for new briefs); checked against `docs/roadmap.md:48-49`, it holds, so no edit.

This is the cap. No fourth iteration was started, so the cap's decision gate did not arise: at the end of iteration 3 no red and no open amber remained.

Executed evidence outside the critics: the first whole-suite run (at 9d37c1ac) was red, 2005 pass and 3 fail, all in `test/scripts/health-check.bats` (row A9). The whole suite at f36108e4 passed, 2008 of 2008. The last whole-suite run is in the research doc's "Gates" table.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The unshare run test's name says the script "execs the command", but a copy of the script with `"$@"` in place of `exec "$@"` passed all 17 tests. Location: `test/scripts/confine-tests.bats:362`, `scripts/confine-tests.sh:225` | Test | Mostly accurate | pass 1: code-fact-check claim 44; security F4 | for-author | — | 🟢 Fixed in f36108e4: `same_process` in the three run tests compares the command's pid with the script's | — |
| A2 | "a second `unshare -rn true`": with bwrap detected it is the only unshare probe. Location: research doc | Docs | Mostly accurate | pass 1: code-fact-check claim 4 | for-author | — | 🟢 Fixed in f36108e4 | — |
| A3 | "neither takes a portable `--`": bash's `exec --` works; only dash's fails. Location: research doc | Docs | Mostly accurate | pass 1: code-fact-check claim 23b | for-author | — | 🟢 Fixed in f36108e4 | — |
| A4 | The rollback names "the brief's status change", which the branch does not hold until its last commit. Location: research doc | Docs | Mostly accurate | pass 1: claim 27b; pass 2: r1 claim 25 | for-author | — | 🟢 Fixed by the branch's last change (the brief's status line), which makes the sentence true before merge | — |
| A5 | O1's list of what a run adds over the probe left out `--setenv`, `--die-with-parent`, `--chdir`. Location: research doc | Docs | Mostly accurate | pass 1: code-fact-check claim 29 | for-author | — | 🟢 Fixed in f36108e4 | — |
| A6 | "bats shows only the failing line": bats also shows the test's own stdout; it does not show what `run` captured. Location: `test/scripts/confine-tests.bats:67` | Docs | Mostly accurate | pass 1: code-fact-check claim 38 | for-author | — | 🟢 Fixed in f36108e4 | — |
| A7 | With bash as `sh`, `exec "$@"` reads a leading `-a NAME` as its own option: `-- -a x CMD one` exits 0 having run `CMD`, not the command named. The research doc had called defect D1 fail-closed. Location: `scripts/confine-tests.sh:225` | Security | Medium | pass 1: security F1; pass 2: security-final 2 (repeat) | for-author | — | 🟢 Doc fixed in f36108e4 (D1 rewritten with the exit-0 case, reproduced by all three final replicates). 🟡 Script: deferred, see note | The script is out of this unit by the brief ("do not fix the script here"). follow-up issue filed: defect D1 in the research doc, with three candidate fixes, named in the handoff marker for the dev cycle to file. Revisit trigger: any change to `scripts/confine-tests.sh` |
| A8 | A fallback to unshare (bwrap missing or refused) prints only the banner, not the warning that unshare gives no read-only root, no private `/tmp` and uid 0; the script's own comment says "Say so, loudly, every time". Location: `scripts/confine-tests.sh:178` | Security | Medium | pass 1: security F2 | for-author | — | 🟡 Script: deferred, see note | Out of this unit by the brief. follow-up issue filed: defect D2 in the research doc with both readings, named in the handoff marker. Revisit trigger: any change to `scripts/confine-tests.sh` |
| A9 | The health check's shellcheck gate (`-S warning`, `.bats` included) flagged SC2154 on `stderr_lines`; three `test/scripts/health-check.bats` tests failed. Location: `test/scripts/confine-tests.bats` | Test | — | Executed: `scripts/run-tests.sh` (whole suite) at 9d37c1ac | for-author | — | 🟢 Fixed in f36108e4: file-level `disable=SC2154`, the form other suites use; the whole suite then passed | — |
| A10 | The mutation table said all four "exec replaced by a plain call" mutants fail "through `same_process`". Two of them (bwrap, `unshare ... sh -c`) failed earlier, because the script fell through to its next run form. Location: research doc, "Mutation run" | Docs | Incorrect | pass 2: r2 claim 23b, r3 claim 27a (r1 claim 27: Mostly accurate) | for-author | — | 🟢 Fixed: the four mutants are now written so nothing falls through (`exit $?` after the plain call), re-run, and fail only through `same_process`; the fall-through variants are described beside the table | — |
| A11 | "No test pins the warning's absence" (defect D2) was false: the fallback `--probe` test required an empty stderr, and the unshare-without-ip test required the `ip` refusal to be stderr's first line. Location: `test/scripts/confine-tests.bats:349`, `:359`; research doc | Test | Incorrect | pass 2: r2 claim 31; security-final 1 (Low) | for-author | — | 🟢 Fixed: both tests now only require the line they are about; copies of the script that warn at run time and at selection time pass all 17 tests | — |
| A12 | "See observation O2" pointed at nothing: O2 became D2. Location: research doc, "Prior failures" | Docs | Stale | pass 2: r2 claim 12, r3 claim 15 | for-author | — | 🟢 Fixed | — |
| A13 | Six statements that were close but not exact: the Project state and Rollback lines left out the review reports the branch adds; "before it, the sh body mutant survived" (two survived); the `exec` pin at the `sh` body holds only where `sh` is dash; "the dev cycle's brief wording has each loop run `--probe`" (not every brief); `confine()`'s comment said "refused a call" where a mode is also named `refused`; "only the whole suite showed it" (a hand-run shellcheck had shown the warning, and the author took it for advice). Location: research doc; `test/scripts/confine-tests.bats:135` | Docs | Mostly accurate | pass 2: r1 claims 1, 24, 25, 27, 50b; r2 claims 1, 20, 23c; r3 claims 1, 6, 20b, 27b; security-final 3 | for-author | — | 🟢 Fixed in 7d77df6c, each one (two of them corrected again in aa8a818c: see A14, and pass 3 claim 3 on which briefs ask for `--probe`) | — |
| A14 | "Before `same_process` existed, two of the four survived": true of the plain mutants, but the table now defines the four with `exit $?`, and in that form all four passed the test file at 9d37c1ac. The same sentence is in the message of 7d77df6c. Location: research doc, "Mutation run"; commit 7d77df6c | Docs | Incorrect | pass 3: code-fact-check claims 12, 29 | for-author | — | 🟢 Fixed in aa8a818c: the doc gives both counts, re-run. The commit message cannot be edited (the branch only adds commits), so aa8a818c's message carries the correction | — |
| A15 | "No test pins O3" was not quite true: the no-command test counted the probes that ran before the refusal, which fixes the order O3 describes. Location: `test/scripts/confine-tests.bats:248`; research doc, "Not covered" | Test | Mostly accurate | pass 3: code-fact-check claim 15b | for-author | — | 🟢 Fixed in aa8a818c: the count is gone; a copy of the script that refuses an empty command before detection passes all 17 tests, and the copy that runs an empty command still fails | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | An exact match on stderr in the unshare run test pinned D2's missing warning, while the doc said it was not pinned. Location: `test/scripts/confine-tests.bats:366` | pass 1: security F3 | Low | for-author | — | 🟢 Fixed in f36108e4 (and see A11 for the two places pass 1 missed) |
| C2 | The one test on the machine's own PATH had no bound on how long a real primitive may stall. Location: `test/scripts/confine-tests.bats:199` | pass 1: performance PERF-1 | Low | for-author | — | 🟢 Fixed in f36108e4: both calls run under `timeout 60`; the final performance pass checked it with a stalling fake |
| C3 | Per-test `setup()` is about a third of the file's time (about 1.1 s in all on a quiet machine); the critic recommends no change, since per-test isolation keeps parallel runs safe | pass 1: PERF-2; pass 2: repeat | Informational | for-orchestrator-synthesis | — | 🟢 Won't-Fix, on the critic's own recommendation |
| C4 | "16 mutations ... each failed" could not be checked: the list was not in the branch | pass 1: code-fact-check claim 46b | Unverifiable | for-orchestrator-synthesis | — | 🟢 Fixed in f36108e4: the list is in the research doc; all three final replicates rebuilt the 21 mutants from it and got the same results |
| C5 | A copy of the script with `set -uo pipefail` passes every test | pass 1: security F4 | Informational | for-orchestrator-synthesis | — | 🟢 Won't-Fix: no test can make a command fail where only errexit stops the script without changing the script; stated under "Not covered" in the research doc |
| C6 | The recorder script had no `set -u` | pass 1: security (sound-checks note) | Informational | for-author | — | 🟢 Fixed in f36108e4 |
| C7 | Not tested: whether `--bind "$PWD" "$PWD"` run from `/` undoes the read-only root | pass 1: security (not tested) | Informational | for-orchestrator-synthesis | — | 🟢 Deferred: recorded as observation O5 for a live run; no bwrap here |
| C8 | "the real bwrap forks it" in a test comment cannot be checked here | pass 2: r1 claim 51b, r2 claim 35, r3 claim 49 | Unverifiable | for-orchestrator-synthesis | — | 🟢 Fixed: the comment now says what a real primitive does with the command is not tested |
| C9 | The whole-suite counts and the drift check's result cannot be re-run by a reviewer under the review's rules | pass 2: r1 claims 31, 32; r2 claim 26; r3 claims 31, 32, 33; pass 3: claims 5b, 33 (the author's account of their own runs) | Unverifiable | for-orchestrator-synthesis | — | 🟢 Won't-Fix: the run logs are in the session's scratch directory; a log file under `docs/reviews/execution-logs/` is not one of this brief's own paths. What a reviewer could check agreed (r2 ran the two affected suites: 57 pass) |
| C10 | The `bash -c` pid wrapper and `same_process` add about 0.1 s across the file; no hang, race or order dependence | pass 2: performance PERF-F1 | Informational | for-orchestrator-synthesis | — | 🟢 Won't-Fix, on the critic's own recommendation |

Out of scope, listed once: a fake `bwrap` planted on PATH (pass 1 security F5, pass 2 security-final 4) needs a deliberately hostile author (constraints S1).

Override-log rows: none written. `docs/reviews/override-log.md` is not one of this brief's files and sits on the self-merge floor, so a row there would send a test-only branch to the owner's review. The items not fixed (the script halves of A7 and A8, and C3, C5, C7, C9, C10) are recorded here and, for A7 and A8, in the handoff marker.

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

No rows claimed. The executed results are in the reports: every replicate reproduced both of defect D1's cases and the probe's exit 3, and rebuilt the mutation table.

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| api-consistency-reviewer | No public API surface touched (all passes) | `git diff --stat a37733cc...27b5e861` outside `docs/reviews/`: one new test file and one working doc; no flag, export, schema or config key |
| security-reviewer, performance-reviewer (pass 3 only) | Pass 3 was a loop pass over a fix whose delta is prose, comments and two loosened assertions; both critics had run on the full branch one commit earlier, in the final confirming pass | `git diff --stat 27b5e861..7d77df6c -- test/ docs/working/`: 2 files; in the test file, 14 lines added and 7 removed, no new command, path or loop |

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/confine-tests.sh:225` | pass 1 fact-check claim 44, security F1, security F4; pass 2 security-final 2 and 3 | not composed: two separate properties of one line (whether it execs; how bash's `exec` reads the first word). A1 and A13 cover the first, A7 the second |
| 2 | `test/scripts/confine-tests.bats:345-365` | pass 2 r2 claim 31, security-final 1 | composed → A11 (the same two assertions, found by two sources) |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
