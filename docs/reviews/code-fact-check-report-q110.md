Commit: f84a9dfa
# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** `git diff main...HEAD` on fix/q110-not-run-undercount (70aa3a78, f84a9dfa), plus both commit messages
**Checked:** 2026-10-14
**Total claims checked:** 22 clusters (r1 16, r2 16, r3 21; emitted at r3's finer granularity, plus one r2-only claim)
**Summary:** 20 Verified, 2 Mostly accurate, 0 Incorrect, 0 Stale, 0 Unverifiable
**Commit:** f84a9dfa
**Replication:** k=3

Merged most-severe-wins from `code-fact-check-report-q110-r{1,2,3}.md` (all three stamped `Commit: f84a9dfa`). Every replicate executed the author's reproduction and the new test against both `main`'s and HEAD's runner in throwaway layouts (the worktree's `.bats/lock` was held by the author's own concurrent related-suite run, so in-worktree runs exited 1). Only the non-Verified clusters are written out as claim sections; every cluster's per-replicate verdicts are in the table under Verdict stability.

---

## Claim 1: "(test/scripts/run-tests.bats and others call it too)"

**Location:** commit 70aa3a78 body (Notes)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every suite under test/ that starts the real runner (`rg -n "run-tests.sh" test/`); does not establish anything about the runner's behaviour.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "only eval-helpers-gating.bats and test/scripts/run-tests.bats (:67, :84, :473, :505) start the real runner; test/scripts/health-check.bats drives stub runners via HEALTH_CHECK_RUN_TESTS" · r2: "affects nothing in the code; matters only if the branch is reworded before merge"

The commit Notes say "test/scripts/run-tests.bats and others call it too". Apart from eval-helpers-gating.bats itself, only run-tests.bats starts the real runner. "and others" overstates it.

**Evidence:** `test/scripts/run-tests.bats:67,84,473,505`; `test/scripts/health-check.bats:488` (stub runner)

---

## Claim 2: "no suite reads the variable from its environment"

**Location:** commit 70aa3a78 body (Notes)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers every `RUN_TESTS_NOT_RUN_FILE` reference under test/; does not establish anything beyond the repo's suites.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r3: "the stub runner in test/scripts/health-check.bats:488 does read it; its value is set by health-check.sh inside that test, so the fix does not affect it. Precise wording: no suite relies on inheriting the runner's value"

`test/scripts/health-check.bats:488` writes `echo 47 > "$RUN_TESTS_NOT_RUN_FILE"` from a stub runner that health-check.sh invokes with the variable set explicitly. The claim's intent (no suite depends on inheriting the runner's value) holds; its wording is too broad.

**Evidence:** `test/scripts/health-check.bats:488` — `[ "$1" = --fast ] && echo 47 > "$RUN_TESTS_NOT_RUN_FILE"`

---

## Escalations

- `docs/working/questions.md` Q-110 entry still OPEN and cites `scripts/run-tests.sh:356-357` (now :359-360) — r1 — addressee: orchestrator (the questions doc is owned by the orchestrator; report it, do not edit on this branch).
- Early `exit 1` paths before `scripts/run-tests.sh:359` (bad tags, usage errors) leave the caller's file unwritten; health-check's `_not_run_count` then reads it as 0 — r3 (Out of scope, pre-existing, not part of this diff) — addressee: orchestrator.

## Verdict stability

| # | Cluster (r3 numbering unless noted) | r1 | r2 | r3 | Merged |
|---|---|---|---|---|---|
| 1 | FP-173 symptom token | — | — | Verified | Verified · single-replicate detection |
| 2 | `cause:boundary-too-wide` | Verified (compound) | Verified (compound) | Verified | Verified |
| 3 | `fix:remove-the-path` | Verified (compound) | Verified (compound) | Verified | Verified |
| 4 | `ref:70aa3a78` names the fix commit | Verified | Verified | Verified | Verified |
| 5 | Header: "unset before bats runs, so the suites (and any runner a suite starts) never see it" | Verified | Verified | Verified | Verified |
| 6 | eval-helpers-gating.bats re-runs the runner with no override | Verified | Verified | Verified | Verified |
| 7 | would overwrite the caller's count with its fixture's | Verified (compound) | Verified (compound) | Verified | Verified |
| 8 | "the health check said 4 where this run listed 50" | Verified | Verified | Verified | Verified |
| 9 | Refusing an inherited value cannot work (health-check.sh:431,:439 pass it via env prefix) | Verified | Verified | Verified | Verified |
| 10 | New test name | Verified | Verified (compound) | Verified | Verified |
| 11 | "as this file does below, with no override" | Verified | Verified | Verified | Verified |
| 12 | "printed 4 where the runner had listed 50" (test comment, commit body) | Verified (compound) | Verified (compound) | Verified | Verified |
| 13 | Stub bats stands in for any such suite | Verified | Verified | Verified | Verified |
| 14 | New test fails on the old runner (line 84), not vacuous | Verified | Verified | Verified | Verified |
| 15 | Commit body cause narrative | Verified | Verified | Verified | Verified |
| 16 | "The runner now unsets the variable right after writing it" | Verified (compound) | — | Verified | Verified |
| 17 | "on the old runner the caller's file reads 99, now 4" (executed) | Verified | Verified | Verified | Verified |
| 18 | Reproduction 4 before, 0 after (executed) | Verified | Verified | Verified | Verified |
| 19 | "test/scripts/run-tests.bats and others call it too" | Mostly accurate | Mostly accurate | Mostly accurate | Mostly accurate (Claim 1) |
| 20 | "no suite reads the variable from its environment" | Verified | Verified | Mostly accurate | Mostly accurate (Claim 2) |
| 21 | health-check.sh comments stay accurate; count tables are a dated snapshot | Verified | Verified | Verified | Verified |
| 22 | (r2 C15) runner-side fix covers every present and future suite that nests the runner | — | Verified | — | Verified · single-replicate detection |

Annotations carried by union on Verified clusters: r1+r2+r3 on clusters 2: "`boundary-too-wide` fits its written definition (isolation boundary), but every earlier use is a security or sandbox boundary — a slight stretch". r3 on cluster 4: "the only 8-character SHA ref in the log; the others have 7 — side note". r2 on cluster 22: "does not establish coverage for a suite run by bare `bats` with the variable exported by hand".

Clusters: 22. All reporting replicates agreed on 21; disagreed on 1 (cluster 20: r1=Verified, r2=Verified, r3=Mostly accurate). Agreement rate 21/22 = 95%.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path given in your tail, structured per your skill.
- Answered: yes — merged from three replicates, all five brief focus areas covered; both behavioural claims executed.
- Out of scope: runner-side vs suite-side fix quality (critics).
- Escalate: Q-110 entry's stale line citation and OPEN status (orchestrator); pre-existing early-exit no-write (orchestrator, informational).
