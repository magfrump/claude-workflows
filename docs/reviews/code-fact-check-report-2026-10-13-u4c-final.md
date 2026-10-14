# Code Fact-Check Report

**Commit:** 43b8d7ed
**Replication:** k=3
**Repository:** claude-workflows
**Scope:** `main...feat/build-loop-u4c` (full branch, final confirming pass)
**Checked:** 2026-10-13
**Total claims checked:** 41 clusters (r1 37, r2 49, r3 41 claims; clustered by file, line range and substance)
**Summary:** 1 Incorrect (new), 1 Incorrect (already Accepted-immutable), 3 Stale, 12 Mostly accurate, 2 Unverifiable, the rest Verified. No behavioural Incorrect.

Merged mechanically from `code-fact-check-report-2026-10-13-u4c-final-r{1,2,3}.md` (most-severe-wins; annotations by union). Only clusters not Verified are listed as claims; Verified clusters are listed in Verdict stability.

## Claim 1: Row 819 / rubric D9: deleting C's objects turns step 0.1 into a record note

**Location:** `docs/reviews/override-log.md:819`, rubric D9
**Type:** Behavioral (doc of behaviour)
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** `SKILL.md:287-288` at 43b8d7ed: a failed `cat-file -e 'C^{commit}'` skips silently; a missing commit exits 128 (executed, r2, r3).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1: "a record note still appears when only C's trees or blobs are gone" · r2: "row 819's fork case files image-lag only when C is on the fork's main, else image-off-main" · all: Won't-Fix reason still holds
**Scope:** covers the stated consequence; does not establish the design choice
**Legibility-target:** for-author

## Claim 2: Commit 1bc823ea cites row 739 for the canonical copy

**Location:** commit 1bc823ea
**Type:** Commit message
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** row 738 is the canonical-copy row; already Accepted-immutable (row 812).
**Replicate verdicts:** r1=Incorrect · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Scope:** message text
**Legibility-target:** for-orchestrator-synthesis

## Claim 3: Plan text still describing main's-copy D6

**Location:** plan :156 (F38 "compares hashes (T36)"), :394 (T27 "refuse from main's copy"), :77 ("never trusts a file the uid can write")
**Type:** Documentation
**Verdict:** Stale
**Confidence:** High
**Evidence:** the hash check and its tests were deleted; T27 refuses from the image copy; the block trusts the `.git` entry and the default branch's ref (`SKILL.md:203-205`).
**Replicate verdicts:** r1=— · r2=Incorrect (:77) · r3=Stale (:156, :394), Mostly accurate (:77)
**Replicate annotations:** none
**Scope:** plan text only
**Legibility-target:** for-author

## Claim 4: Rubric header stamp and Status

**Location:** rubric line 1, Status
**Type:** Documentation
**Verdict:** Stale
**Confidence:** High
**Evidence:** `Commit: f2cc21e6` while recording 43b8d7ed's fixes; architecture i2 tally omits its Informational.
**Replicate verdicts:** r1=Stale · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none
**Scope:** rubric
**Legibility-target:** for-author

## Claim 5: "Image copy built from main"

**Location:** plan :71; `scripts/lib/dev-cycle-read.sh:1962-1963`
**Type:** Documentation
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** install.sh stages the host checkout's `HEAD^{commit}`; step 0.1 checks it is on main.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none
**Scope:** wording
**Legibility-target:** for-author

## Claim 6: Step 0.1 wording and order

**Location:** `SKILL.md:285-299`; plan :432
**Type:** Behavioral (instructions)
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** "was not built here" where the test shows only that the repository does not hold C (r2); with no `commit=` line C is empty, so "skip silently" fires before "a missing line: note it" (r1); plan :432 omits the two earlier conditions (r1, r2).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: "test the manifest first"
**Scope:** text order and wording
**Legibility-target:** for-author

## Claim 7: The pin test's "until both move"

**Location:** `test/scripts/build-loop-orchestrator.bats` (image-lag paths test)
**Type:** Test claim
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** mutation (r1, executed): widening GATE_CODE and its literal in the test passes with the path line unchanged; the test checks each listed path is gate code, not the reverse.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1: `execution-logs/u4c-final-r1-pin-mutation.log`
**Scope:** test strength
**Legibility-target:** for-author

## Claim 8: Smaller wording

**Location:** `SKILL.md:713` (check exit 1 also names a file); row 817 (omits step 9.1); plan :400 T37 "(stubbed)"; commit 33ad1767 "ahead of"
**Type:** Documentation
**Verdict:** Mostly accurate
**Confidence:** Medium
**Evidence:** see replicate reports
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** commits and rows cannot be edited
**Scope:** wording
**Legibility-target:** for-author

## Claim 9: -w test refuses a root run unless read-only; install.sh plus a launch rebuilds /opt

**Location:** D6 block header; step 0.1 paste
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Evidence:** needs root / the host.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** none
**Scope:** none
**Legibility-target:** for-orchestrator-synthesis

## Escalations

- Claim 1 (row 819 / D9): addressee orchestrator; an amending row and D9's wording (r1, r2, r3).

## Verdict stability

41 clusters; 33 agreed across all reporting replicates; 8 disagreed (Claims 2-8 above, by severity grade only: none disagreed between Incorrect and Verified on behaviour). Agreement rate ~80%. Executed by all three: bats 26/26; step 0.1 against /workspace and the real manifest; the extracted D6 block against the real /opt.

## Goal-Alignment Note
- Success criterion (restated verbatim): a merged k=3 fact-check report for the final confirming pass.
- Answered: yes
- Out of scope: design judgments; root and host runs
- Escalate: Claim 1
