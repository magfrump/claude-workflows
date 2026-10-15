Commit: 16ce27bf
# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** `git diff main...HEAD -- scripts test docs/thoughts` on fix/q110-not-run-undercount (HEAD 16ce27bf), plus all five commit messages; iteration-1 review artifacts read as context where they describe the branch's code
**Checked:** 2026-10-14
**Total claims checked:** 26 clusters (r1 20, r2 23, r3 25)
**Summary:** 21 Verified, 4 Mostly accurate, 1 Stale, 0 Incorrect, 0 Unverifiable
**Commit:** 16ce27bf
**Replication:** k=3

Final confirming pass (iteration 2), merged most-severe-wins from `code-fact-check-report-q110-final-r{1,2,3}.md` (all stamped `Commit: 16ce27bf`). All three replicates re-executed the reproduction (4 on main's runner, 0 on HEAD's), the stub scenario (99 vs 4, stub sees `unset`, serial and `--jobs 2`) and the regression test against both runners (fails on main's at `test/skills/eval-helpers-gating.bats:84`, 7/7 on HEAD's) in throwaway layouts. Only the non-Verified clusters are written out.

---

## Claim 1: "the write is now at :359-360" / "→ header, gating comment, :359-368 only"

**Location:** `docs/reviews/code-review-rubric-2026-10-14-fix-q110-not-run-undercount.md:62,88`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line numbers at HEAD; does not dispute them at the rubric's stamped commit f84a9dfa, where they were correct.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Mostly accurate · r3=—
**Replicate annotations:** r1+r2: "right at f84a9dfa, the rubric's stamp; 4b775841 added one header line, so at HEAD the write is :360-361 and the unset :369" · r1: "informational; a docs/reviews file only"

**Evidence:** `scripts/run-tests.sh:360-361` (write), `:369` (`unset RUN_TESTS_NOT_RUN_FILE`)

---

## Claim 2: "so neither bats nor anything a suite starts can see the caller's path"

**Location:** commit 70aa3a78 body
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed (PARALLEL_ENV at the GNU parallel level)
**Scope:** Covers inheritance (holds) and caller-supplied `PARALLEL_ENV` code under `--jobs` (can set the variable again); does not establish an end-to-end run through `bats --jobs` with PARALLEL_ENV.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: "4b775841 corrects the header and the test name but its body doesn't name this sentence among the ones it corrects" · r2: "4b775841's body already corrects it"

**Evidence:** 4b775841 body: "a caller can inject one through PARALLEL_ENV code under --jobs. What the runner guarantees is that the caller's value is not inherited"

---

## Claim 3: "(test/scripts/run-tests.bats and others call it too)"

**Location:** commit 70aa3a78 body (Notes)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every suite that starts the real runner.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "already corrected in 4b775841's body"

**Evidence:** `test/scripts/run-tests.bats:67,84,473,505` are the only real-runner starts besides eval-helpers-gating.bats

---

## Claim 4: "no suite reads the variable from its environment"

**Location:** commit 70aa3a78 body (Notes)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every reference under test/.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "already corrected in 4b775841's body (no suite relies on inheriting the runner's value)"

**Evidence:** `test/scripts/health-check.bats:488` — `[ "$1" = --fast ] && echo 47 > "$RUN_TESTS_NOT_RUN_FILE"`

---

## Escalations

- `docs/working/questions.md:73` (Q-110) still OPEN and cites `scripts/run-tests.sh:356-357` (off by one even on main, where the write is :357-358) — r1, r2 — addressee: orchestrator.
- Shared brief said "6 commits ahead"; the branch was 5 ahead at 16ce27bf — r1 — addressee: orchestrator (brief typo, no artifact affected).
- Runner exits before the write (lock held, no matched files, bad tag) leave the caller's file unwritten, read as 0 — r3 (pre-existing, out of scope; iteration-1 security traced it: every such exit fails the gate) — addressee: orchestrator.

## Verdict stability

| # | Cluster | r1 | r2 | r3 | Merged |
|---|---|---|---|---|---|
| 1 | Iteration-1 rubric line cites | Stale | Mostly accurate | — | Stale |
| 2 | FP-173 tokens and ref | Verified | Verified | Verified (split) | Verified |
| 3 | Header "do not inherit the caller's value" (unset before `bats --count` :442 and `exec bats` :453, all paths) | Verified | Verified | Verified | Verified |
| 4 | Nested run would overwrite with fixture's count | Verified | Verified | Verified | Verified |
| 5 | "4 where this run listed 50" | Verified | Verified | Verified | Verified |
| 6 | Refusing an inherited value cannot work | Verified | Verified | Verified | Verified |
| 7 | Test name / stub stands in for any such suite | Verified | Verified | Verified | Verified |
| 8 | Commit-body cause narrative | Verified | Verified | Verified | Verified |
| 9 | "neither bats nor anything a suite starts can see" | Mostly accurate | Mostly accurate | Verified | Mostly accurate |
| 10 | 99 before, 4 after (executed) | Verified | Verified | Verified | Verified |
| 11 | Reproduction 4 before, 0 after (executed) | Verified | Verified | Verified | Verified |
| 12 | "and others call it too" | Mostly accurate | Mostly accurate | Mostly accurate | Mostly accurate |
| 13 | "no suite reads the variable" | Mostly accurate | Mostly accurate | Mostly accurate | Mostly accurate |
| 14 | health-check.sh comments stay accurate | Verified | Verified | Verified | Verified |
| 15 | 4b775841: a suite can set its own value | Verified (compound) | Verified | Verified | Verified |
| 16 | 4b775841: PARALLEL_ENV can inject one under --jobs | Verified (compound) | Verified | Verified | Verified |
| 17 | 4b775841: corrections (only run-tests.bats; no suite relies on inheriting) | Verified | Verified (split) | Verified (split) | Verified |
| 18 | 4b775841: did not add PARALLEL_ENV to the unset | Verified | Verified | Verified | Verified |
| 19 | f84a9dfa Notes on tokens and count tables | Verified | Verified | Verified | Verified |
| 20 | 40f524df / 16ce27bf summaries | Verified | Verified | Verified | Verified |
| 21 | New test fails on old runner (executed) | Verified (in 10) | Verified (in 10) | Verified | Verified |
| 22 | Runner wrote count then exec'd bats with it exported | — | — | Verified | Verified · single-replicate detection |

(Clusters 15-17 counted as 5 rows where replicates split; 26 rows in all.) All reporting replicates agreed on 24 of 26 rows; they disagreed on 2 (cluster 1: r1 Stale, r2 Mostly accurate; cluster 9: r1 and r2 Mostly accurate, r3 Verified). Agreement rate 24/26 = 92%.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path given in your tail, structured per your skill.
- Answered: yes — merged from three replicates; behavioural claims re-executed.
- Out of scope: pre-existing early-exit no-write.
- Escalate: Q-110 entry citation and status (orchestrator).
