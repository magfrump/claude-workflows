Commit: 9d37c1ac

# Code Review Rubric

**Scope:** test/confine-tests-bats, `a37733cc..9d37c1ac` (full branch) | **Reviewed:** 2026-11-10 | **Status: 🟡 IN LOOP** — 0 red; pass 1's findings fixed in the next commit, final confirming pass still to run

Pass 1 (iteration 1 of 3, `--loop-pass`): k=1 fact-check, then the security and performance critics in parallel, all on opus. Delivery mode: self-read (each agent ran `git diff a37733cc...HEAD`). The file's name ends in the brief's stem, not the branch slug, so the build loop's gate counts it as this brief's own file; passes therefore name their range explicitly.

Fact-check (`code-fact-check-report-2026-11-10-confine-tests-bats.md`): 50 claims; 43 Verified, 6 Mostly accurate, 1 Unverifiable, 0 Incorrect. Critics: security (`security-review-2026-11-10-confine-tests-bats.md`) 2 Medium against the unchanged script, 1 Low against this diff, 2 Informational; performance (`performance-review-2026-11-10-confine-tests-bats.md`) 1 Low, 1 Informational.

Executed evidence outside the critics: the first full `scripts/run-tests.sh` run was red (2005 pass, 3 fail), all three in `test/scripts/health-check.bats`, because the health check's shellcheck gate flagged SC2154 (`stderr_lines`) in the new file. Row A9.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The unshare run test's name says the script "execs the command", but a copy of the script with `"$@"` in place of `exec "$@"` passed all 17 tests. Location: `test/scripts/confine-tests.bats:362`, `scripts/confine-tests.sh:225` | Test | Mostly accurate | code-fact-check claim 44; security F4 | for-author | — | 🟢 Fixed: `same_process` in the three run tests compares the command's pid with the script's; the four exec-to-call mutants now fail | — |
| A2 | "a second `unshare -rn true`": with bwrap detected it is the only unshare probe. Location: research doc :16 | Docs | Mostly accurate | code-fact-check claim 4 | for-author | — | 🟢 Fixed | — |
| A3 | "neither takes a portable `--`": bash's `exec --` works; only dash's fails. Location: research doc :52 | Docs | Mostly accurate | code-fact-check claim 23b | for-author | — | 🟢 Fixed | — |
| A4 | The rollback names "the brief's status change", which the branch did not hold at 9d37c1ac. Location: research doc :145 | Docs | Mostly accurate | code-fact-check claim 27b | for-author | — | 🟢 Fixed by the branch's last change (the brief's status line), which makes the sentence true before merge | — |
| A5 | O1's list of what a run adds over the probe left out `--setenv`, `--die-with-parent`, `--chdir`. Location: research doc :189 | Docs | Mostly accurate | code-fact-check claim 29 | for-author | — | 🟢 Fixed | — |
| A6 | "bats shows only the failing line": bats also shows the test's own stdout; it does not show what `run` captured. Location: `test/scripts/confine-tests.bats:67` | Docs | Mostly accurate | code-fact-check claim 38 | for-author | — | 🟢 Fixed | — |
| A7 | With bash as `sh`, `exec "$@"` reads a leading `-a NAME` as its own option: `-- -a x CMD one` exits 0 having run `CMD`, not the command named. The research doc said defect D1 "fails closed". Location: `scripts/confine-tests.sh:225`, research doc :185 | Security | Medium | security-reviewer F1 | for-author | — | 🟢 Doc fixed (D1 rewritten with the exit-0 case, reproduced). 🟡 Script: deferred, see note | The script is out of this unit by the brief ("do not fix the script here"). follow-up issue filed: defect D1 in the research doc, named in the handoff marker for the dev cycle to file. Revisit trigger: any change to `scripts/confine-tests.sh` |
| A8 | A fallback to unshare (bwrap missing or refused) prints only the banner, not the warning that unshare gives no read-only root, no private `/tmp` and uid 0; the script's own comment says "Say so, loudly, every time". Location: `scripts/confine-tests.sh:178` | Security | Medium | security-reviewer F2 | for-author | — | 🟡 Script: deferred, see note | Out of this unit by the brief. follow-up issue filed: recorded as defect D2 (was observation O2) in the research doc with both readings, named in the handoff marker. Revisit trigger: any change to `scripts/confine-tests.sh` |
| A9 | The health check's shellcheck gate (`-S warning`, `.bats` included) flagged SC2154 on `stderr_lines`; three `test/scripts/health-check.bats` tests failed. Location: `test/scripts/confine-tests.bats` | Test | — | Executed: `scripts/run-tests.sh` (full run) | for-author | — | 🟢 Fixed: file-level `disable=SC2154`, the form other suites use; `scripts/run-tests.sh test/scripts/health-check.bats test/scripts/confine-tests.bats` passes 57 of 57 | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | An exact match on stderr in the unshare run test pinned D2's missing warning, while the doc said it was not pinned. Location: `test/scripts/confine-tests.bats:366` | security-reviewer F3 | Low | for-author | — | 🟢 Fixed: both unshare run tests only require the banner; a copy of the script that adds the warning passes |
| C2 | The one test on the machine's own PATH had no bound on how long a real primitive may stall. Location: `test/scripts/confine-tests.bats:199` | performance-reviewer PERF-1 | Low | for-author | — | 🟢 Fixed: both calls run under `timeout 60` |
| C3 | Per-test `setup()` is about 1 s of the file's 4 s; the critic recommends no change (per-test isolation keeps parallel runs safe) | performance-reviewer PERF-2 | Informational | for-orchestrator-synthesis | — | 🟢 Won't-Fix, on the critic's own recommendation |
| C4 | "16 mutations ... each failed" could not be checked: the list was not in the branch | code-fact-check claim 46b | Unverifiable | for-orchestrator-synthesis | — | 🟢 Fixed: the list is in the research doc ("Mutation run"), re-run at the fixed state |
| C5 | A copy of the script with `set -uo pipefail` passes every test | security-reviewer F4 | Informational | for-orchestrator-synthesis | — | 🟢 Won't-Fix: no test can make a command fail where only errexit stops the script without changing the script; stated under "Not covered" in the research doc |
| C6 | The recorder script had no `set -u`: run without `STUB_LOG` it would write to `/child.N` | security-reviewer (sound-checks note) | Informational | for-author | — | 🟢 Fixed |
| C7 | Not tested: whether `--bind "$PWD" "$PWD"` run from `/` undoes the read-only root | security-reviewer (not tested) | Informational | for-orchestrator-synthesis | — | 🟢 Deferred: recorded as observation O5 for a live run; no bwrap here |

Out of scope, listed once: a fake `bwrap` planted on PATH (security F5) needs a deliberately hostile author (constraints S1).

Override-log rows: none written. `docs/reviews/override-log.md` is not one of this brief's files and sits on the self-merge floor, so a row there would send a test-only branch to the owner's review. The five items not fixed (the script halves of A7 and A8, and C3, C5, C7) are recorded here and, for A7 and A8, in the handoff marker.

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

No rows claimed. The executed results are in the reports: the fact-check reproduced defect D1 and the probe's exit 3, and each reviewer's mutants of the script are listed with what failed.

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| api-consistency-reviewer | No public API surface touched | `git diff --stat a37733cc...9d37c1ac`: one new test file and one working doc; no flag, export, schema or config key |

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/confine-tests.sh:225` | fact-check claim 44, security F1, security F4 | not composed: two separate properties of one line (whether it execs; how bash's `exec` reads the first word). A1 covers the first, A7 the second |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
