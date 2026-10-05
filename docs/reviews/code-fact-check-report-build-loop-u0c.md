Commit: d8da1fba
# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** feat/build-loop-u0b..feat/build-loop-u0c (final confirming pass, full unit range)
**Checked:** 2026-10-05
**Total claims checked:** 65 (r1=19, r2=12, r3=34; clustered below for the claims needing attention; Verified claims are in the replicate files)
**Summary:** 0 Incorrect at the cluster level beyond the carried header sentence; 3 Mostly accurate clusters (header omits check_answer from the exiting list; amendment says F11 row is "below"; amendment drops "no untracked instruction files"); 1 Unverifiable note (rollback line outside the diff). No behavioral claim is wrong.
**Commit:** d8da1fba
**Replication:** k=3

Merged most-severe-wins from `code-fact-check-report-build-loop-u0c-r1.md`, `-r2.md`, `-r3.md` (all at Commit d8da1fba). This merge carries every non-Verified cluster with per-replicate verdicts and the union of annotations; clean Verified clusters are listed by subject only.

## Claim 1: Lib header's list of exiting checks omits check_answer

**Location:** `scripts/lib/dev-cycle-read.sh:12-14`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** check_answer calls skipped, so it exits 1 via need_root; captured as `r="$(check_answer …)"` the caller continues with an empty result.
**Verification mode:** executed
**Scope:** covers the wording of this claim against the code at d8da1fba; does not establish anything about behaviour, which the Verified clusters below cover.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "the $(...) warning relies on the list"

## Claim 2: Plan amendment: "F11's row below"

**Location:** `docs/working/plan-build-loop-handoff.md:192`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** The F11 row is at :126, above the amendment; the content claim holds.
**Verification mode:** static
**Scope:** covers the wording of this claim against the code at d8da1fba; does not establish anything about behaviour, which the Verified clusters below cover.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none

## Claim 3: Plan amendment/F11/step 13: gate runs the walk "in a worktree checked out at MAIN_SHA"

**Location:** `docs/working/plan-build-loop-handoff.md:126,192,290`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Evidence:** Architecture finding 4 adds "with no untracked instruction files": the walk lists `--others`, so untracked instruction files in that worktree join the import set. r2 also notes "and test it" is dropped.
**Verification mode:** static
**Scope:** covers the wording of this claim against the code at d8da1fba; does not establish anything about behaviour, which the Verified clusters below cover.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r3: "say a clean worktree at MAIN_SHA"

## Claim 4: Plan rollback step still lists only <U0b> <U0a>

**Location:** `docs/working/plan-build-loop-handoff.md:374`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Evidence:** Outside the diff; noted, not verdicted.
**Verification mode:** static
**Scope:** covers the wording of this claim against the code at d8da1fba; does not establish anything about behaviour, which the Verified clusters below cover.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=—
**Replicate annotations:** none

## Claim 5: Commit 1c7373d3: pre-fix walk behaviour

**Location:** `commit 1c7373d3`
**Type:** Commit message
**Verdict:** Mostly accurate
**Confidence:** Medium
**Evidence:** Settled: override-log row for 1c7373d3 (Won't-Fix).
**Verification mode:** executed
**Scope:** covers the wording of this claim against the code at d8da1fba; does not establish anything about behaviour, which the Verified clusters below cover.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none

## Verified clusters (by subject)

import walk and check_answer moved verbatim; need_root at the walk's top; root-keyed cache (recomputes for another root; one root cached); check_fix unaffected; T29 globals; new walk test fails under each mutation; plan amendment matches architecture findings 1-4 otherwise; step 13 edit; test counts; byte-identical output vs main.

## Escalations

None raised by any replicate beyond the claims above.

## Verdict stability

Non-Verified clusters: 5. Clusters where every reporting replicate agreed: 5. Disagreements are listed in each claim's Replicate verdicts line (U0a/U0b header sentence: Mostly accurate vs Incorrect). Verified clusters agreed across all reporting replicates.
