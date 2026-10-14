Commit: 65c931e
# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** `git diff main...HEAD` on feat/q102-parallel-gates
**Checked:** 2026-10-14
**Total claims checked:** 19 clusters (r1 15, r2 19, r3 12)
**Summary:** 13 Verified, 4 Mostly accurate, 2 Incorrect (medium confidence, doc-only), 0 Stale, 0 Unverifiable
**Commit:** 65c931e
**Replication:** k=3

Merged most-severe-wins from `code-fact-check-report-r{1,2,3}-q102.md`. Only non-Verified clusters are written out; the Verified ones (identical regex grammar at health-check.sh:409 / run-tests.sh:144; serial fallback for missing and moreutils parallel at run-tests.sh:411-420; `--failed` serial by default; health-check.sh:408 the only reader; empty means 8 as the commit Notes say; Q-102 Applied note location; roadmap 1–6 consistent) are in the replicate reports.

## Claim 1: gate timing "about 2.5 min against 7.5 min serial"
**Location:** `workflows/pr-prep.md:331`; commit 65c931e6 body
**Verdict:** Incorrect
**Confidence:** Medium
**Evidence:** 140 s / 451 s come from Q-090's single full-suite run (`docs/working/questions-archive.md:1878`). The gate runs fast then slow as two runs; at 65c931e6 that was 171 s + 154 s of BATS, 6:20 total (loaded host).
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r1+r3: "the gate's own wall time was never measured" · r2: "one run, shared host at load ~5; no serial gate run taken"
**Scope:** covers the provenance of the figures; does not establish the gate's serial time.
**Verification mode:** executed
**Legibility-target:** for-author

## Claim 2: commit message repeats the gate timing
**Location:** commit 65c931e6 body
**Verdict:** Incorrect
**Confidence:** Medium
**Evidence:** same as Claim 1. Merged commit messages cannot be edited once landed; the branch is unmerged, but rewriting is not done here (fix commits carry the correction).
**Replicate verdicts:** r1=Mostly accurate (with claim 12) · r2=Incorrect · r3=Mostly accurate (with 9b)
**Replicate annotations:** none beyond Claim 1
**Scope:** as Claim 1.
**Verification mode:** executed
**Legibility-target:** for-author

## Claim 3: "any other value fails check 5" (header) and the Q-102 Applied note
**Location:** `scripts/health-check.sh:28-32`; `docs/working/questions-archive.md:2516`
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** `RUN_TESTS_JOBS=` (empty) passes `--jobs 8` via `${RUN_TESTS_JOBS:-8}`; executed by r1 and r2.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=—
**Replicate annotations:** r1: "should say unset or empty means 8"
**Scope:** covers the empty case only.
**Verification mode:** executed
**Legibility-target:** for-author

## Claim 4: "140 s against 451 s ... see the Parallel runs section of run-tests.sh"
**Location:** `scripts/health-check.sh:386-388`
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** the numbers are in Q-090 (`questions-archive.md:1878`); run-tests.sh's section holds only the jobs-16-vs-8 ~5% figure. Also a full-run figure, not the gate's.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r3: "say one full run"
**Scope:** pointer and figure provenance.
**Verification mode:** static
**Legibility-target:** for-author

## Claim 5: test helper comment "(the outer gate's own)" and isolation
**Location:** `test/scripts/health-check.bats:203-205`, sibling test at `:466-480`
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** health-check.sh never exports RUN_TESTS_JOBS; a value reaches tests only from whoever launched the gate. The helper strips it, but the report-dependent gate-5 test at :466-480 calls check_bats without `-u RUN_TESTS_JOBS`; with `RUN_TESTS_JOBS=abc` exported it failed (not ok 8, r2 executed).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: "sibling test not isolated — fails under an ambient bad value"
**Scope:** helper and sibling test.
**Verification mode:** executed
**Legibility-target:** for-author

## Escalations
- `test/scripts/health-check.bats:466-480` — sibling gate-5 test not isolated from ambient RUN_TESTS_JOBS (r2) — addressee: orchestrator (fix).
- Override-log row 182's revisit trigger (longest-first ordering) is live with this branch (r2) — addressee: performance-reviewer.

## Verdict stability
19 clusters; 15 agreed across reporting replicates; 4 disagreed (Claim 1: MA/I/MA; Claim 2: MA/I/MA; Claim 5: MA/MA/V; Claim 3 one replicate absent). Agreement 15/19 = 79%.
